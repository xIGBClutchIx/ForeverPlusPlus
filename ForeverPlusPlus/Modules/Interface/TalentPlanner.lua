-- Talent Planner: a Plan Talents button on the talent window. While planning, clicking a talent
-- adds a point to a saved plan instead of learning it, in the order clicked, and a level box limits
-- the plan to the points a character has at that level (the beta stops at 30). Out of planning, the
-- plan's next talent glows when you have a point to spend, and talent tooltips say at which levels
-- the plan takes it. Blizzard's tree still draws the talents; while planning, our own buttons sit
-- over its buttons (theirs go transparent) and show the plan's ranks with Blizzard's own art. The
-- tree's data comes from C_Traits (docs/forever-api.md, Talents); nothing here learns a talent.
local _, ns = ...

local ipairs, pairs, format, tonumber, tostring, concat, sort = ipairs, pairs, string.format,
    tonumber, tostring, table.concat, table.sort
local max, min, floor, setmetatable, tremove = math.max, math.min, math.floor, setmetatable,
    table.remove
local CreateFrame, C_Traits, C_Spell, UnitLevel, UnitGUID, IsShiftKeyDown, PlaySound = CreateFrame,
    C_Traits, C_Spell, UnitLevel, UnitGUID, IsShiftKeyDown, PlaySound
local GameTooltip, EventRegistry, UIErrorsFrame = GameTooltip, EventRegistry, UIErrorsFrame

local L = ns.L
local Plan = ns.TalentPlan
local readable = ns.IsReadable

local module = ns.NewModule("TalentPlanner", L.TALENTPLANNER_DESC, {
    enabled = true,
    glow = true, -- the plan's next talent glows
    tooltip = true, -- talent tooltips say when the plan takes them
    -- "<player GUID>-<spec tab>" -> { active = index, list = { { name, level, picks }, ... } },
    -- where picks are nodeIDs in order and level is the plan's level cap.
    builds = {},
})
module.title = L.TALENTPLANNER_TITLE
module.category = "interface"
module.added = "0.8.0"

module.options = {
    { key = "glow", name = L.TALENTPLANNER_GLOW, description = L.TALENTPLANNER_GLOW_DESC },
    { key = "tooltip", name = L.TALENTPLANNER_TOOLTIP, description = L.TALENTPLANNER_TOOLTIP_DESC },
}

local ADDON = "Blizzard_PlayerSpells" -- the talent window's load-on-demand addon
local POINTS_PER_ROW = 5 -- Classic: each row opens after 5 more points in its tab
local GLOW_SIZE = 62 / 40 -- Blizzard's node glow is 62 across on a 40 button

-- Blizzard's square talent node art (TalentButtonArtMixin.ArtSet.Square), which Forever's
-- Classic-style trees use.
local ATLAS_MAXED = "talents-node-square-yellow"
local ATLAS_OPEN = "talents-node-square-green"
local ATLAS_CLOSED = "talents-node-square-gray"
local ATLAS_SHADOW = "talents-node-square-shadow"
local ATLAS_GLOW = "talents-node-square-greenglow"

-- Enum.TraitEdgeType, with Mainline's values when the enum is missing.
local EdgeType = Enum and Enum.TraitEdgeType or {}
local EDGE_REQUIRED = EdgeType.RequiredForAvailability or 3
local EDGE_SUFFICIENT = EdgeType.SufficientForAvailability or 2

local frame -- PlayerSpellsFrame.TalentsFrame, once its addon loads
local ui -- our frames on it
local planning = false
local tree -- the shown tree for ns.TalentPlan, with names and ranks; rebuilt on every refresh
local overlays = {} -- nodeID -> our button over Blizzard's
local labels = {} -- header -> our point count over a tab header's
local faded = setmetatable({}, { __mode = "k" }) -- Blizzard regions we set to alpha 0 -> true

-- Data ----------------------------------------------------------------------------------------

local function maxLevel()
    local level = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion()
    return level and readable(level) and level > 0 and level or 60
end

-- Points spent and unspent in the shown tree, staged changes included.
local function currency()
    local info = C_Traits.GetTreeCurrencyInfo(tree.configID, tree.treeID, false)
    local points = info and info[1]
    if not points then
        return 0, 0
    end
    return points.spent or 0, points.quantity or 0
end

local function firstLevel()
    local spent, unspent = currency()
    return Plan.FirstLevel(UnitLevel("player"), spent + unspent)
end

-- A new plan starts from the talents already learned.
local function newPlan(name)
    return { name = name, level = maxLevel(), picks = tree and Plan.FromRanks(tree, tree.ranks) or {} }
end

-- The saved plans for this character and the shown spec tab, made when `create` is true.
local function getBuilds(create)
    local guid = UnitGUID("player")
    if not (guid and readable(guid)) then
        return nil
    end
    local key = guid .. "-" .. tostring(frame.GetTab and frame:GetTab() or 1)
    local builds = module.db.builds[key]
    if not builds and create then
        builds = { active = 1, list = { newPlan(format(L.TALENTPLANNER_PLAN_NAME, 1)) } }
        module.db.builds[key] = builds
    end
    if builds and not builds.list[builds.active] then
        builds.active = 1
    end
    return builds
end

-- The plan picked in the dropdown.
local function getPlan(create)
    local builds = getBuilds(create)
    return builds and builds.list[builds.active]
end

-- The points a plan may hold at its level.
local function pointsOf(plan)
    return Plan.PointsAt(plan.level, firstLevel())
end

-- Reads the shown tree from C_Traits. A node's tab is whichever of its groups is a tab
-- (docs/forever-api.md). The points a row needs come from the node's gate condition, or else
-- from its row, counted from the tree's top.
local function buildTree()
    local configID = frame:GetConfigID()
    local treeID = frame:GetTalentTreeID()
    if not (configID and treeID) then
        return nil
    end
    local tabs, tabList = {}, {}
    for _, info in ipairs(C_Traits.GetGroupDisplayInfoByTreeID(treeID) or {}) do
        tabs[info.groupID] = info
        tabList[#tabList + 1] = info
    end
    sort(tabList, function(a, b)
        return (a.orderIndex or 0) < (b.orderIndex or 0)
    end)
    local treeInfo = C_Traits.GetTreeInfo(configID, treeID)
    local built = { nodes = {}, order = {}, ranks = {}, tabs = tabs, tabList = tabList,
        configID = configID, treeID = treeID,
        hideSingle = treeInfo and treeInfo.hideSingleRankNumbers }
    local incoming, ys = {}, {}
    for _, id in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
        local info = C_Traits.GetNodeInfo(configID, id)
        local tab
        for _, group in ipairs(info and info.groupIDs or {}) do
            tab = tab or (tabs[group] and group)
        end
        -- Choice nodes (more than one entry) aren't in Classic trees, so they aren't planned.
        if tab and info.isVisible and (info.maxRanks or 0) > 0 and #info.entryIDs == 1 then
            local req
            for _, condID in ipairs(info.conditionIDs or {}) do
                local cond = C_Traits.GetConditionInfo(configID, condID)
                if cond and cond.isGate and cond.spentAmountRequired then
                    req = max(req or 0, cond.spentAmountRequired)
                end
            end
            built.nodes[id] = { id = id, max = info.maxRanks, tab = tab, req = req, prereqs = {},
                x = info.posX or 0, y = info.posY or 0, entryID = info.entryIDs[1] }
            built.order[#built.order + 1] = id
            built.ranks[id] = info.ranksPurchased or 0
            ys[#ys + 1] = info.posY or 0
            for _, edge in ipairs(info.visibleEdges or {}) do
                if edge.type == EDGE_REQUIRED or edge.type == EDGE_SUFFICIENT then
                    local list = incoming[edge.targetNode] or {}
                    incoming[edge.targetNode] = list
                    list[#list + 1] = { id = id, required = edge.type == EDGE_REQUIRED }
                end
            end
        end
    end
    for target, list in pairs(incoming) do
        local node = built.nodes[target]
        for _, pre in ipairs(node and list or {}) do
            if built.nodes[pre.id] then
                node.prereqs[#node.prereqs + 1] = pre
            end
        end
    end
    -- Rows: the gap between rows is the smallest gap between two nodes' heights.
    sort(ys)
    local spacing
    for i = 2, #ys do
        local gap = ys[i] - ys[i - 1]
        if gap > 1 and (not spacing or gap < spacing) then
            spacing = gap
        end
    end
    for _, node in pairs(built.nodes) do
        if not node.req then
            local row = spacing and floor((node.y - ys[1]) / spacing + 0.5) or 0
            node.req = row * POINTS_PER_ROW
        end
    end
    sort(built.order, function(a, b)
        local na, nb = built.nodes[a], built.nodes[b]
        if na.y ~= nb.y then
            return na.y < nb.y
        end
        return na.x < nb.x
    end)
    return built
end

-- A node's name, icon, and spell, read when first needed.
local function describe(node)
    if node.name then
        return node
    end
    local entry = C_Traits.GetEntryInfo(tree.configID, node.entryID)
    local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
    local spellID = def and (def.overriddenSpellID or def.spellID)
    node.name = def and def.overrideName and def.overrideName ~= "" and def.overrideName
        or spellID and C_Spell.GetSpellName(spellID) or ""
    node.icon = def and def.overrideIcon and def.overrideIcon ~= 0 and def.overrideIcon
        or spellID and C_Spell.GetSpellTexture(spellID) or 134400 -- the question mark
    return node
end

local function tabName(group)
    local info = tree.tabs[group]
    return info and info.displayName or ""
end

-- Why a point can't be added or removed, for the error line and the tooltip.
local function reasonText(reason, node, plan)
    if reason == "points" then
        return format(L.TALENTPLANNER_NO_POINTS, plan.level)
    elseif reason == "max" then
        return L.TALENTPLANNER_MAXED
    elseif reason == "tier" then
        return format(L.TALENTPLANNER_TIER, node.req, tabName(node.tab))
    elseif reason == "prereq" then
        local names = {}
        for _, pre in ipairs(node.prereqs) do
            names[#names + 1] = describe(tree.nodes[pre.id]).name
        end
        return format(L.TALENTPLANNER_PREREQ, concat(names, ", "))
    elseif reason == "needed" then
        return L.TALENTPLANNER_NEEDED
    end
end

-- The levels at which the plan's first `points` points put ranks in a node, leaving out ranks
-- already learned (the plan's first ranks in a node count as the learned ones).
local function levelsFor(plan, id, points, first)
    local levels, skip = {}, tree.ranks[id] or 0
    for i = 1, min(#plan.picks, points) do
        if plan.picks[i] == id then
            if skip > 0 then
                skip = skip - 1
            else
                levels[#levels + 1] = Plan.LevelOf(i, first)
            end
        end
    end
    return levels
end

local function showError(text)
    if not (text and UIErrorsFrame) then
        return
    end
    if UIErrorsFrame.AddExternalErrorMessage then
        UIErrorsFrame:AddExternalErrorMessage(text)
    else
        UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1)
    end
end

local function playSound(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit and PlaySound then
        PlaySound(kit)
    end
end

-- Showing Blizzard's parts again ---------------------------------------------------------------

local INVISIBLE = TalentButtonUtil and TalentButtonUtil.BaseVisualState
    and TalentButtonUtil.BaseVisualState.Invisible

local function fade(region)
    faded[region] = true
    region:SetAlpha(0)
end

-- Puts back the alpha of everything we faded. A talent button Blizzard keeps invisible (alpha 0
-- is how it hides nodes) stays that way.
local function unfadeAll()
    for region in pairs(faded) do
        local hiddenNode = INVISIBLE and region.GetVisualState and region:GetVisualState() == INVISIBLE
        region:SetAlpha(hiddenNode and 0 or 1)
    end
    faded = setmetatable({}, { __mode = "k" })
end

-- Takes the plan off the tree: our buttons and counts go, Blizzard's come back.
local function clearPlanVisuals()
    unfadeAll()
    for _, overlay in pairs(overlays) do
        overlay:Hide()
    end
    for _, label in pairs(labels) do
        label:Hide()
    end
end

-- Drawing -------------------------------------------------------------------------------------

local refresh -- forward

local function onNodeClick(self, mouse)
    local plan = getPlan(true)
    local node = plan and tree and tree.nodes[self.nodeID]
    if not node then
        return
    end
    local points = pointsOf(plan)
    local times = IsShiftKeyDown() and node.max or 1
    local changed, reason = false, nil
    for _ = 1, times do
        local ok
        if mouse == "RightButton" then
            ok, reason = Plan.Remove(tree, plan.picks, node.id, points)
        else
            ok, reason = Plan.Add(tree, plan.picks, node.id, points)
        end
        if not ok then
            break
        end
        changed = true
    end
    if changed then
        playSound(mouse == "RightButton" and "UI_CLASS_TALENT_NODE_REFUND" or "UI_CLASS_TALENT_NODE_SPEND")
        refresh()
        if GameTooltip:IsOwned(self) then
            self:GetScript("OnEnter")(self)
        end
    elseif reason ~= "none" then
        showError(reasonText(reason, node, plan))
    end
end

local function onNodeEnter(self)
    local plan = getPlan(true)
    local node = plan and tree and tree.nodes[self.nodeID]
    if not node then
        return
    end
    describe(node)
    local first = firstLevel()
    local points = Plan.PointsAt(plan.level, first)
    local counts, tabs = Plan.Simulate(tree, plan.picks, points)
    local count = counts[node.id] or 0
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(node.name, 1, 1, 1)
    GameTooltip:AddLine(format(L.TALENTPLANNER_RANK, count, node.max), 1, 1, 1)
    -- Blizzard's own description of the rank, as its talent tooltips show it.
    if GameTooltip.AppendInfo then
        GameTooltip:AddLine(" ")
        GameTooltip:AppendInfo("GetTraitEntry", node.entryID, max(count, 1))
        if count > 0 and count < node.max then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(TALENT_BUTTON_TOOLTIP_NEXT_RANK or L.TALENTPLANNER_NEXT_RANK, 1, 1, 1)
            GameTooltip:AppendInfo("GetTraitEntry", node.entryID, count + 1)
        end
    end
    local levels = levelsFor(plan, node.id, points, first)
    if #levels > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L.TALENTPLANNER_PLANNED, concat(levels, ", "), 1, 1, 1, 1, 1, 1)
    end
    if count < node.max then
        local ok, reason = Plan.CanTake(tree, counts, tabs, node.id)
        if ok and min(#plan.picks, points) >= points then
            reason = "points"
        end
        if reason then
            GameTooltip:AddLine(reasonText(reason, node, plan), 1, 0.125, 0.125, true)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TALENTPLANNER_CLICK, 0, 1, 0, true)
    GameTooltip:Show()
end

local function onLeave()
    GameTooltip:Hide()
end

local function makeOverlay(id)
    local button = CreateFrame("Button", nil, ui.nodes)
    button.nodeID = id
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.Shadow = button:CreateTexture(nil, "BACKGROUND")
    button.Shadow:SetPoint("CENTER")
    button.Shadow:SetAtlas(ATLAS_SHADOW, true)
    button.Icon = button:CreateTexture(nil, "BORDER")
    button.Icon:SetPoint("CENTER")
    button.Border = button:CreateTexture(nil, "ARTWORK")
    button.Border:SetPoint("CENTER")
    button.Hover = button:CreateTexture(nil, "HIGHLIGHT")
    button.Hover:SetPoint("CENTER")
    button.Hover:SetBlendMode("ADD")
    button.Hover:SetAlpha(0.4)
    -- Where and how Blizzard's talent buttons write their rank (TalentButtonArtTemplate).
    button.Text = button:CreateFontString(nil, "OVERLAY", "SystemFont16_Shadow_ThickOutline")
    button.Text:SetPoint("BOTTOM", 11, 4)
    button:SetScript("OnClick", onNodeClick)
    button:SetScript("OnEnter", onNodeEnter)
    button:SetScript("OnLeave", onLeave)
    overlays[id] = button
    return button
end

-- Copies the size of a Blizzard region onto ours, so our art matches theirs at any button size.
local function sizeLike(ours, theirs, fallback)
    if theirs and theirs.GetSize then
        ours:SetSize(theirs:GetSize())
    else
        ours:SetSize(fallback, fallback)
    end
end

local function drawOverlays(plan)
    for _, overlay in pairs(overlays) do
        overlay:Hide()
    end
    if not planning then
        return
    end
    local points = pointsOf(plan)
    local counts, tabs = Plan.Simulate(tree, plan.picks, points)
    local full = min(#plan.picks, points) >= points
    for button in frame:EnumerateAllTalentButtons() do
        local node = tree.nodes[button:GetNodeID()]
        if node then
            describe(node)
            fade(button)
            local overlay = overlays[node.id] or makeOverlay(node.id)
            overlay:ClearAllPoints()
            overlay:SetAllPoints(button)
            overlay:SetFrameLevel(button:GetFrameLevel() + 2)
            local width = button:GetWidth()
            sizeLike(overlay.Icon, button.Icon, width * 0.9)
            sizeLike(overlay.Border, button.StateBorder, width * 1.2)
            sizeLike(overlay.Hover, button.StateBorder, width * 1.2)
            overlay.Icon:SetTexture(node.icon)
            local count = counts[node.id] or 0
            local open = not full and Plan.CanTake(tree, counts, tabs, node.id)
            local atlas, color
            -- Gold only once it's learned: a talent maxed in the plan alone stays green, so the
            -- tree shows what's still to learn.
            if count >= node.max and (tree.ranks[node.id] or 0) >= node.max then
                atlas, color = ATLAS_MAXED, YELLOW_FONT_COLOR
            elseif count > 0 or open then
                atlas, color = ATLAS_OPEN, GREEN_FONT_COLOR
            else
                atlas, color = ATLAS_CLOSED, DISABLED_FONT_COLOR
            end
            overlay.Border:SetAtlas(atlas)
            overlay.Hover:SetAtlas(atlas)
            overlay.Icon:SetDesaturated(count == 0 and not open)
            overlay.Text:SetText(format("%d/%d", count, node.max))
            overlay.Text:SetShown(not (node.max == 1 and tree.hideSingle))
            if color then
                overlay.Text:SetTextColor(color:GetRGB())
            end
            overlay:Show()
        end
    end
end

-- While planning, each tab header shows the plan's points in that tab instead of the spent ones.
local function drawHeaders(plan)
    for _, label in pairs(labels) do
        label:Hide()
    end
    if not (planning and plan and frame.treeHeaders) then
        return
    end
    local _, tabs = Plan.Simulate(tree, plan.picks, pointsOf(plan))
    for _, header in ipairs(frame.treeHeaders) do
        local info = header.displayInfo
        if info and header.Text then
            fade(header.Text)
            local label = labels[header]
            if not label then
                label = CreateFrame("Frame", nil, ui.bar)
                label:SetAllPoints(header.Text)
                label.Text = label:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label.Text:SetPoint("CENTER")
                labels[header] = label
            end
            label:SetFrameLevel(header:GetFrameLevel() + 1)
            label.Text:SetText(tabs[info.groupID] or 0)
            label:Show()
        end
    end
end

-- Blizzard's row gates say how many points the learned talents still need; the plan has its own.
local function drawGates()
    if planning and frame.gatePool then
        for gate in frame.gatePool:EnumerateActive() do
            fade(gate)
        end
    end
end

local function drawGlow(plan)
    ui.glow:Hide()
    if planning or not (module.db.glow and plan) then
        return
    end
    local index, id = Plan.Next(plan.picks, tree.ranks)
    local _, unspent = currency()
    if not index or index > pointsOf(plan) or unspent <= 0 then
        return
    end
    local button = frame:GetTalentButtonByNodeID(id)
    if button then
        local size = button:GetWidth() * GLOW_SIZE
        ui.glow:ClearAllPoints()
        ui.glow:SetPoint("CENTER", button)
        ui.glow:SetSize(size, size)
        ui.glow:SetFrameLevel(button:GetFrameLevel() + 2)
        ui.glow:Show()
    end
end

local function withIcon(node)
    return format("|T%s:0|t %s", tostring(node.icon), node.name)
end

local ORDER_LINES = 20 -- runs listed before "...and N more"

-- The plan in order, a line for each run of points in one talent: its ranks on the left and their
-- levels on the right, green once you're that level. Out of planning, only what's left to learn.
local function orderTooltip(owner)
    local plan = tree and getPlan(false)
    if not (plan and #plan.picks > 0) then
        return
    end
    local first = firstLevel()
    local points = Plan.PointsAt(plan.level, first)
    local level = UnitLevel("player")
    local runs, counts = {}, {}
    for i = 1, min(#plan.picks, points) do
        local id = plan.picks[i]
        counts[id] = (counts[id] or 0) + 1
        if planning or counts[id] > (tree.ranks[id] or 0) then
            local run = runs[#runs]
            if run and run.id == id and run.last == i - 1 then
                run.last, run.toRank = i, counts[id]
            else
                runs[#runs + 1] = { id = id, first = i, last = i, fromRank = counts[id],
                    toRank = counts[id] }
            end
        end
    end
    if #runs == 0 then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(planning and L.TALENTPLANNER_ORDER or L.TALENTPLANNER_UPCOMING, 1, 1, 1)
    for i, run in ipairs(runs) do
        if i > ORDER_LINES then
            GameTooltip:AddLine(format(L.TALENTPLANNER_MORE_LINES, #runs - ORDER_LINES), 0.5, 0.5, 0.5)
            break
        end
        local node = describe(tree.nodes[run.id])
        local ranks = run.fromRank == run.toRank and format("%d/%d", run.toRank, node.max)
            or format("%d-%d/%d", run.fromRank, run.toRank, node.max)
        local from, to = Plan.LevelOf(run.first, first), Plan.LevelOf(run.last, first)
        local levels = from == to and format(L.TALENTPLANNER_LEVEL_ONE, from)
            or format(L.TALENTPLANNER_LEVEL_RANGE, from, to)
        local ready = not planning and from <= level
        GameTooltip:AddDoubleLine(withIcon(node) .. " |cff808080" .. ranks .. "|r", levels,
            1, 1, 1, ready and 0.1 or 1, 1, ready and 0.1 or 1)
    end
    GameTooltip:Show()
end

local function drawBar(plan)
    ui.planButton:SetText(planning and L.TALENTPLANNER_DONE or L.TALENTPLANNER_PLAN)
    ui.controls:SetShown(planning)
    if ui.dropdown then
        ui.dropdown:GenerateMenu() -- shows the picked plan's name, for this spec tab
    end
    if planning then
        local points = pointsOf(plan)
        local text = format(L.TALENTPLANNER_POINTS, min(#plan.picks, points), points)
        if #plan.picks > points then
            text = text .. " " .. format(L.TALENTPLANNER_MORE, #plan.picks - points)
        end
        ui.summary:SetText(text)
        if not ui.level:HasFocus() then
            ui.level:SetText(tostring(plan.level))
        end
        return
    end
    local index, id = Plan.Next(plan and plan.picks or {}, tree.ranks)
    if plan and index and index <= pointsOf(plan) then
        ui.summary:SetText(format(L.TALENTPLANNER_NEXT, withIcon(describe(tree.nodes[id])),
            Plan.LevelOf(index, firstLevel())))
    elseif plan and #plan.picks > 0 then
        ui.summary:SetText(L.TALENTPLANNER_COMPLETE)
    else
        ui.summary:SetText("")
    end
end

refresh = function()
    if not (module.enabled and frame and ui and frame:IsVisible()) then
        return
    end
    local inspecting = frame.IsInspecting and frame:IsInspecting()
    tree = not inspecting and buildTree() or nil
    if not (tree and #tree.order > 0) then
        planning = false
        clearPlanVisuals()
        ui.bar:Hide()
        return
    end
    ui.bar:Show()
    local plan = getPlan(planning)
    if plan then
        -- A patch can change node IDs; drop the points the tree no longer has.
        local picks = {}
        for _, id in ipairs(plan.picks) do
            if tree.nodes[id] then
                picks[#picks + 1] = id
            end
        end
        plan.picks = picks
    end
    drawOverlays(plan)
    drawHeaders(plan)
    drawGates()
    drawGlow(plan)
    drawBar(plan)
end

local function setPlanning(on)
    if planning == on then
        return
    end
    planning = on
    if not on then
        clearPlanVisuals()
        ui.level:ClearFocus()
    end
    refresh()
end

-- Our frames ----------------------------------------------------------------------------------

local function simpleTooltip(owner, title, text)
    owner:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:AddLine(text, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", onLeave)
end

local function trim(text)
    return (text or ""):match("^%s*(.-)%s*$")
end

-- Adds a plan to this character's list and picks it.
local function addPlan(plan)
    local builds = getBuilds(true)
    if builds then
        builds.list[#builds.list + 1] = plan
        builds.active = #builds.list
        refresh()
    end
end

local function promptNew()
    local builds = getBuilds(true)
    ns.Prompt("TALENTPLANNER_NEW", L.TALENTPLANNER_NEW_PROMPT,
        format(L.TALENTPLANNER_PLAN_NAME, builds and #builds.list + 1 or 1), function(text)
            if trim(text) ~= "" then
                addPlan(newPlan(trim(text)))
            end
        end)
end

local function promptRename()
    local plan = getPlan(true)
    ns.Prompt("TALENTPLANNER_RENAME", L.TALENTPLANNER_RENAME_PROMPT, plan and plan.name,
        function(text)
            local current = getPlan(true)
            if current and trim(text) ~= "" then
                current.name = trim(text)
                refresh()
            end
        end)
end

local function share()
    local plan = getPlan(true)
    if plan and tree then
        ns.Prompt("TALENTPLANNER_SHARE", L.TALENTPLANNER_SHARE_PROMPT, Plan.Encode(tree.treeID, plan))
    end
end

-- Reads a pasted share string into a new plan, if it's this class's and fits this tree.
local function import(text)
    local data = Plan.Decode(text)
    if not (data and tree) then
        showError(L.TALENTPLANNER_IMPORT_BAD)
        return
    end
    if data.treeID ~= tree.treeID then
        showError(L.TALENTPLANNER_IMPORT_CLASS)
        return
    end
    local _, _, bad = Plan.Simulate(tree, data.picks)
    if bad then
        showError(L.TALENTPLANNER_IMPORT_INVALID)
        return
    end
    local builds = getBuilds(true)
    local name = data.name ~= "" and data.name
        or format(L.TALENTPLANNER_PLAN_NAME, builds and #builds.list + 1 or 1)
    addPlan({ name = name, level = max(firstLevel(), min(maxLevel(), data.level)), picks = data.picks })
end

local function promptImport()
    ns.Prompt("TALENTPLANNER_IMPORT", L.TALENTPLANNER_IMPORT_PROMPT, "", import)
end

local function deletePlan()
    ns.Confirm("TALENTPLANNER_DELETE", L.TALENTPLANNER_DELETE_CONFIRM, function()
        local builds = getBuilds(true)
        if not builds then
            return
        end
        tremove(builds.list, builds.active)
        if #builds.list == 0 then
            builds.list[1] = newPlan(format(L.TALENTPLANNER_PLAN_NAME, 1))
        end
        builds.active = min(builds.active, #builds.list)
        refresh()
    end)
end

local function setupMenu(_, root)
    local builds = frame and tree and getBuilds(true)
    if not builds then
        return
    end
    for index, plan in ipairs(builds.list) do
        root:CreateRadio(plan.name, function(i)
            return builds.active == i
        end, function(i)
            builds.active = i
            refresh()
        end, index)
    end
    root:CreateDivider()
    root:CreateButton(L.TALENTPLANNER_NEW, promptNew)
    root:CreateButton(L.TALENTPLANNER_RENAME, promptRename)
    root:CreateButton(L.TALENTPLANNER_SHARE, share)
    root:CreateButton(L.TALENTPLANNER_IMPORT, promptImport)
    root:CreateButton(L.TALENTPLANNER_DELETE, deletePlan)
end

local function applyLevel(box)
    local plan = getPlan(true)
    local value = tonumber(box:GetText())
    if plan and value then
        plan.level = max(firstLevel(), min(maxLevel(), floor(value)))
    end
    box:ClearFocus()
    refresh()
end

local function createUI()
    ui = {}
    local anchor = frame.Background or frame
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetAllPoints(anchor)
    bar:SetFrameLevel(frame:GetFrameLevel() + 1010) -- with Blizzard's tabs and headers
    ui.bar = bar

    -- Where Blizzard's loadout dropdown sits on Mainline; Forever hides it.
    local planButton = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    planButton:SetSize(150, 22)
    planButton:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 48, 8)
    planButton:SetScript("OnClick", function()
        setPlanning(not planning)
    end)
    simpleTooltip(planButton, L.TALENTPLANNER_TITLE, L.TALENTPLANNER_PLAN_DESC)
    ui.planButton = planButton

    -- One line between our button and Blizzard's Apply Changes, cut short with "..." when the
    -- talent's name is long; hovering it lists the plan in order.
    local info = CreateFrame("Frame", nil, bar)
    info:SetHeight(22)
    info:SetPoint("LEFT", planButton, "RIGHT", 12, 0)
    if frame.ApplyButton then
        info:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -12, 0)
    else
        info:SetWidth(260)
    end
    info:SetScript("OnEnter", orderTooltip)
    info:SetScript("OnLeave", onLeave)
    local summary = info:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summary:SetPoint("LEFT")
    summary:SetPoint("RIGHT")
    summary:SetJustifyH("LEFT")
    summary:SetWordWrap(false)
    ui.summary = summary

    -- The plans of this character and spec, in Blizzard's dropdown, with what can be done to them.
    -- Probe: WowStyle1DropdownTemplate is Mainline's menu dropdown.
    local dropdown
    if WowStyle1DropdownMixin then
        dropdown = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
        dropdown:SetWidth(170)
        dropdown:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -48, 8)
        dropdown:SetupMenu(setupMenu)
        ui.dropdown = dropdown
    end

    local controls = CreateFrame("Frame", nil, bar)
    controls:SetAllPoints()
    controls:Hide()
    ui.controls = controls

    local clear = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    clear:SetSize(90, 22)
    if dropdown then
        clear:SetPoint("RIGHT", dropdown, "LEFT", -12, 0)
    else
        clear:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -48, 8)
    end
    clear:SetText(L.TALENTPLANNER_CLEAR)
    clear:SetScript("OnClick", function()
        ns.Confirm("TALENTPLANNER_CLEAR", L.TALENTPLANNER_CLEAR_CONFIRM, function()
            local plan = getPlan(true)
            if plan then
                plan.picks = {}
                refresh()
            end
        end)
    end)
    simpleTooltip(clear, L.TALENTPLANNER_CLEAR, L.TALENTPLANNER_CLEAR_DESC)

    local reset = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    reset:SetSize(90, 22)
    reset:SetPoint("RIGHT", clear, "LEFT", -6, 0)
    reset:SetText(L.TALENTPLANNER_RESET)
    reset:SetScript("OnClick", function()
        ns.Confirm("TALENTPLANNER_RESET", L.TALENTPLANNER_RESET_CONFIRM, function()
            local plan = getPlan(true)
            if plan and tree then
                plan.picks = Plan.FromRanks(tree, tree.ranks)
                refresh()
            end
        end)
    end)
    simpleTooltip(reset, L.TALENTPLANNER_RESET, L.TALENTPLANNER_RESET_DESC)

    local level = CreateFrame("EditBox", nil, controls, "InputBoxTemplate")
    level:SetSize(28, 20)
    level:SetPoint("RIGHT", reset, "LEFT", -16, 0)
    level:SetAutoFocus(false)
    level:SetNumeric(true)
    level:SetMaxLetters(2)
    level:SetJustifyH("CENTER")
    level:SetScript("OnEnterPressed", applyLevel)
    level:SetScript("OnEditFocusLost", applyLevel)
    level:SetScript("OnEscapePressed", function(self)
        self:SetText("") -- refresh puts the saved level back
        self:ClearFocus()
    end)
    simpleTooltip(level, L.TALENTPLANNER_LEVEL, L.TALENTPLANNER_LEVEL_DESC)
    ui.level = level

    local levelLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelLabel:SetPoint("RIGHT", level, "LEFT", -8, 0)
    levelLabel:SetText(L.TALENTPLANNER_LEVEL)

    -- Our buttons go in the tree's own panel so they scale and move with Blizzard's.
    local nodes = CreateFrame("Frame", nil, frame.ButtonsParent or frame)
    nodes:SetAllPoints()
    ui.nodes = nodes

    -- The next planned talent's glow: Blizzard's node glow, gold so it stands out from the green
    -- one Blizzard gives every talent you can learn.
    local glow = CreateFrame("Frame", nil, nodes)
    glow:Hide()
    local texture = glow:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetAtlas(ATLAS_GLOW)
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(1, 0.82, 0)
    local pulse = texture:CreateAnimationGroup()
    pulse:SetLooping("REPEAT")
    local fadeIn = pulse:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.2)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.6)
    fadeIn:SetOrder(1)
    local fadeOut = pulse:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.2)
    fadeOut:SetDuration(0.6)
    fadeOut:SetOrder(2)
    glow:SetScript("OnShow", function()
        pulse:Play()
    end)
    glow:SetScript("OnHide", function()
        pulse:Stop()
    end)
    ui.glow = glow
end

-- Hooks ---------------------------------------------------------------------------------------

local function onButtonsUpdated()
    refresh()
end

local function onTreeParts()
    if planning and tree then
        local plan = getPlan(true)
        drawHeaders(plan)
        drawGates()
    end
end

local function onHide()
    setPlanning(false)
end

-- Adds the plan's levels to Blizzard's tooltip for a talent in this window.
local function onTalentTooltip(_, button, tooltip)
    if not (module.enabled and module.db.tooltip and frame and tree and not planning) then
        return
    end
    if not (button.GetTalentFrame and button:GetTalentFrame() == frame and button.GetNodeID) then
        return
    end
    local plan = getPlan(false)
    local id = button:GetNodeID()
    if not (plan and id and tree.nodes[id]) then
        return
    end
    local first = firstLevel()
    local levels = levelsFor(plan, id, Plan.PointsAt(plan.level, first), first)
    if #levels > 0 then
        tooltip:AddDoubleLine(L.TALENTPLANNER_PLANNED, concat(levels, ", "), 1, 1, 1, 1, 1, 1)
        tooltip:Show()
    end
end

local function start()
    frame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not (frame and frame.GetConfigID and frame.EnumerateAllTalentButtons
        and frame.GetTalentButtonByNodeID) then
        frame = nil
        return
    end
    -- The talent window may be protected in combat; make our children of it after.
    ns.AfterCombat(function()
        if not module.enabled then
            return
        end
        if not ui then
            createUI()
        end
        module:HookScript(frame, "OnShow", refresh)
        module:HookScript(frame, "OnHide", onHide)
        if frame.RefreshTreeHeaders then
            module:Hook(frame, "RefreshTreeHeaders", onTreeParts)
        end
        if frame.RefreshGates then
            module:Hook(frame, "RefreshGates", onTreeParts)
        end
        if EventRegistry then
            EventRegistry:RegisterCallback("TalentFrameBase.ButtonsUpdated", onButtonsUpdated, module)
            EventRegistry:RegisterCallback("TalentDisplay.TooltipCreated", onTalentTooltip, module)
        end
        refresh()
    end)
end

function module:OnEnable()
    if not (C_Traits and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo
        and C_Traits.GetGroupDisplayInfoByTreeID) then
        return
    end
    self:On("PLAYER_LEVEL_UP", refresh)
    self:On("TRAIT_CONFIG_UPDATED", refresh)
    ns.AddOns.WhenLoaded(ADDON, start)
end

function module:OnDisable()
    ns.AddOns.Cancel(ADDON, start)
    if EventRegistry then
        EventRegistry:UnregisterCallback("TalentFrameBase.ButtonsUpdated", module)
        EventRegistry:UnregisterCallback("TalentDisplay.TooltipCreated", module)
    end
    if ui then
        setPlanning(false)
        ui.glow:Hide()
        ui.bar:Hide()
    end
    planning = false
    clearPlanVisuals()
end

function module:OnOptionChanged()
    refresh()
end
