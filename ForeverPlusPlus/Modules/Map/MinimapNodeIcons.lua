-- Minimap Node Icons: the herb or ore a tracking dot on the minimap stands for, as that item's
-- icon over the dot, optionally red while the player's skill is too low to gather it and gray once
-- gathering it no longer raises the skill. The game draws
-- the dots itself and lists them nowhere an addon can read, but Forever's minimap has
-- UpdateMouseoverAtPoint, which points its mouseover at a spot as if the cursor were there, and the
-- tooltip data for the mouseover names what is under that spot. So while Find Herbs or Find
-- Minerals is on, the minimap is swept with probes a few times a second, out of combat and while
-- the cursor isn't on it. Each node found is kept as a spot on the zone map, so its icon follows
-- the minimap between sweeps as the player moves and turns.
--
-- Names are matched in English through Professions.NODES. Any other name is learned the first
-- time the player gathers it: the spell's target, then the first item in the loot window; a
-- learned node has no known skill, so it's never tinted. Ideas from NodeSight; none of its code.
local _, ns = ...

local ipairs, type, pcall, floor, sin, cos = ipairs, type, pcall, math.floor, math.sin, math.cos
local gmatch, match, tostring, format = string.gmatch, string.match, tostring, string.format
local min, max, huge, concat = math.min, math.max, math.huge, table.concat
local CreateFrame, Minimap, GetTime, C_Timer = CreateFrame, Minimap, GetTime, C_Timer
local GetCursorPosition = GetCursorPosition
local C_Map, C_Minimap, C_TooltipInfo, C_Item = C_Map, C_Minimap, C_TooltipInfo, C_Item
local InCombatLockdown, GetPlayerFacing, GetCVarBool = InCombatLockdown, GetPlayerFacing, GetCVarBool
local GetNumLootItems, GetLootSlotInfo = GetNumLootItems, GetLootSlotInfo

local L = ns.L
local readable = ns.IsReadable
local plain = ns.Text.Plain
local Professions = ns.Professions
local NODES = Professions.NODES

local module = ns.NewModule("MinimapNodeIcons", L.MINIMAPNODEICONS_DESC, {
    enabled = true,
    size = 8, -- icon size on the minimap
    border = true, -- a gold ring around each icon
    tint = false, -- red while the skill is too low
    gray = false, -- gray once gathering no longer raises the skill
    detail = "medium", -- a key of STEPS
    chat = true,
    -- Node name -> icon, for names not in NODES, from what gathering them gave. Data, not a setting.
    learned = {},
    -- { space = a key of SPACES }, once a sweep has found a node with it. Data, not a setting.
    calibration = {},
})
module.title = L.MINIMAPNODEICONS_TITLE
module.category = "map"
module.added = "0.9.0"

module.options = {
    {
        key = "size", name = L.MINIMAPNODEICONS_SIZE, description = L.MINIMAPNODEICONS_SIZE_DESC,
        min = 5, max = 20, step = 1, format = "%d",
    },
    { key = "border", name = L.MINIMAPNODEICONS_BORDER, description = L.MINIMAPNODEICONS_BORDER_DESC },
    { key = "tint", name = L.MINIMAPNODEICONS_TINT, description = L.MINIMAPNODEICONS_TINT_DESC },
    { key = "gray", name = L.MINIMAPNODEICONS_GRAY, description = L.MINIMAPNODEICONS_GRAY_DESC },
    {
        key = "detail", name = L.MINIMAPNODEICONS_DETAIL, description = L.MINIMAPNODEICONS_DETAIL_DESC,
        choices = {
            { "low", L.MINIMAPNODEICONS_DETAIL_LOW },
            { "medium", L.MINIMAPNODEICONS_DETAIL_MEDIUM },
            { "high", L.MINIMAPNODEICONS_DETAIL_HIGH },
        },
    },
    ns.ChatOption(L.MINIMAPNODEICONS_CHAT_DESC),
}

module.actions = {
    {
        name = L.MINIMAPNODEICONS_CLEAR,
        button = L.MINIMAPNODEICONS_CLEAR_BUTTON,
        description = L.MINIMAPNODEICONS_CLEAR_DESC,
        confirm = L.MINIMAPNODEICONS_CLEAR_CONFIRM,
        fn = function()
            module.db.learned = {}
            ns.Print(L.MINIMAPNODEICONS_CLEAR_DONE)
        end,
    },
}

-- Forever only: the minimap's UpdateMouseoverAtPoint is in its API docs (1.60.1).
function module:IsAvailable()
    return Minimap and Minimap.UpdateMouseoverAtPoint and C_TooltipInfo
        and C_TooltipInfo.GetMinimapMouseover and true or false
end

local HERBS, MINERALS = 2383, 2580 -- Find Herbs, Find Minerals

local STEPS = { low = 8, medium = 6, high = 4 } -- minimap units between probes
local PER_FRAME = 60 -- probes each frame, so a sweep is spread over a few frames
local REST = 0.4 -- seconds between sweeps
local REACH = 1.5 -- hits this many probe spacings apart touch (diagonal neighbors are 1.41)
local EDGE = 2 -- keep probes and icons this far inside the minimap's edge
local LEARN_WAIT = 10 -- seconds from a cast to its loot window that still count as one gather
local RED = { 1, 0.25, 0.25 } -- the icon's vertex color while the skill is too low
local GRAY = { 0.7, 0.7, 0.7 } -- dims a gray (desaturated) icon, for nodes that give no skill

-- The icon for a node's name, or nil for a name that isn't a node we know.
local function iconFor(name)
    local learned = module.db.learned[name]
    if learned then
        return learned
    end
    local node = NODES[name]
    return node and C_Item.GetItemIconByID(node[3])
end

-- How the player's skill stands against the node named `name`: "low" when it's too low to gather
-- (or they lack the profession), "gray" when gathering it no longer raises the skill, else nil,
-- as for a node whose skill isn't known.
local function standing(name)
    local node = NODES[name]
    if not node then
        return nil
    end
    local rank = Professions.Rank(node[1])
    if not rank or rank < node[2] then
        return "low"
    elseif Professions.Difficulty(rank, node[2]) == Professions.TRIVIAL then
        return "gray"
    end
end

-- Where the player is ---------------------------------------------------------------------------

-- The minimap's view right now: the player's zone map and spot on it, the map's size in yards,
-- minimap units per yard, and the angle the minimap is turned by (0 unless it rotates). Nil when
-- any of it can't be read, as in an instance.
local view = {}

local function readView()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not (mapID and readable(mapID)) then
        return nil
    end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y = pos and pos.x, pos and pos.y
    if not (x and y and readable(x) and readable(y)) then
        return nil
    end
    local width, height = C_Map.GetMapWorldSize(mapID)
    if not (width and height and readable(width) and width > 0 and height > 0) then
        return nil
    end
    local radius = C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if not (radius and readable(radius) and radius > 0) then
        return nil
    end
    local angle = 0
    if GetCVarBool("rotateMinimap") then
        angle = GetPlayerFacing and GetPlayerFacing()
        if not (angle and readable(angle)) then
            return nil
        end
    end
    view.mapID, view.x, view.y, view.width, view.height = mapID, x, y, width, height
    view.half = Minimap:GetWidth() / 2
    view.scale = view.half / radius
    view.angle = angle
    return view
end

-- A spot on the zone map as minimap units right and up of its center.
local function toMinimap(v, x, y)
    local east = (x - v.x) * v.width * v.scale
    local north = (v.y - y) * v.height * v.scale
    local c, s = cos(v.angle), sin(v.angle)
    return east * c + north * s, north * c - east * s
end

-- Minimap units right and up of its center as a spot on the zone map.
local function fromMinimap(v, right, up)
    local c, s = cos(v.angle), sin(v.angle)
    local east, north = right * c - up * s, right * s + up * c
    return v.x + east / (v.width * v.scale), v.y - north / (v.height * v.scale)
end

-- Probing ---------------------------------------------------------------------------------------

local blocked = false -- the client refused a probe; stop until /reload

-- What UpdateMouseoverAtPoint's point is measured in isn't documented (see docs/forever-api.md), so
-- each way it could be is tried until a sweep finds a node, and the one that does is saved. Each
-- turns minimap units right and up of its center into that space.
local SPACES = {
    -- Screen pixels from the bottom left, like GetCursorPosition.
    cursor = function(right, up)
        local cx, cy = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        return (cx + right) * scale, (cy + up) * scale
    end,
    -- Minimap units from its center.
    center = function(right, up)
        return right, up
    end,
    -- Minimap units from its bottom left.
    corner = function(right, up)
        return Minimap:GetWidth() / 2 + right, Minimap:GetHeight() / 2 + up
    end,
    -- 0 to 1 across and up the minimap.
    unit = function(right, up)
        return 0.5 + right / Minimap:GetWidth(), 0.5 + up / Minimap:GetHeight()
    end,
}
local ORDER = { "cursor", "center", "corner", "unit" }
local trying = 1 -- the space in ORDER tried while none is saved

local function currentSpace()
    return module.db.calibration.space or ORDER[trying]
end

-- Points the minimap's mouseover at a spot right and up of its center and returns the text the
-- tooltip there would show, its lines joined by newlines. Call between startProbing and
-- stopProbing.
local function probe(right, up, space)
    local x, y = (SPACES[space] or SPACES.cursor)(right, up)
    local ok, err = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, x, y)
    if not ok then
        blocked = true
        module:Print(format(L.MINIMAPNODEICONS_FAILED, tostring(err)))
        return nil
    end
    local data = C_TooltipInfo.GetMinimapMouseover()
    local lines = data and data.lines
    if not (lines and readable(lines) and type(lines) == "table") then
        return nil
    end
    local text
    for _, line in ipairs(lines) do
        local left = line.leftText
        if readable(left) and type(left) == "string" and left ~= "" then
            text = text and (text .. "\n" .. left) or left
        end
    end
    return text
end

-- The minimap takes a probe's point only in soft cursor mode (a controller's cursor); otherwise
-- the mouse's spot wins and every probe reads nothing (in game, 2026-10-13). So probes run between
-- these two: on, then the point off the minimap and back to the mouse. This would also end a real
-- controller's soft cursor on the minimap; it takes it up again as it moves.
local function startProbing()
    if Minimap.SetUsingSoftCursor then
        pcall(Minimap.SetUsingSoftCursor, Minimap, true)
    end
end

local function stopProbing()
    pcall(Minimap.UpdateMouseoverAtPoint, Minimap, -10000, -10000)
    if Minimap.SetUsingSoftCursor then
        pcall(Minimap.SetUsingSoftCursor, Minimap, false)
    end
end

-- The names in a probe's text, one per row (overlapping dots each add one), without the color
-- codes and spaces the game may wrap them in.
local function namesIn(text)
    local list = {}
    for row in gmatch(plain(text), "[^\n]+") do
        local name = match(row, "^%s*(.-)%s*$")
        if name ~= "" then
            list[#list + 1] = name
        end
    end
    return list
end

-- The spots a sweep probes, right and up of the minimap's center, inside its circle.
local points, pointsFor

local function grid(half, step)
    local key = half .. ":" .. step
    if pointsFor == key then
        return points
    end
    points, pointsFor = {}, key
    local radius = half - EDGE
    local n = floor(radius / step)
    for i = -n, n do
        for j = -n, n do
            local right, up = i * step, j * step
            if right * right + up * up <= radius * radius then
                points[#points + 1] = { right, up }
            end
        end
    end
    return points
end

-- Sweeping ---------------------------------------------------------------------------------------

local nodes = {} -- the last sweep's nodes: { x, y, icon, standing } on the zone map `nodesMap`
local nodesMap
local seen = {} -- names the minimap showed that aren't nodes we know, for learning

local sweep -- the sweep under way: { mapID, index, hits }, or nil
local nextSweep = 0
local tracking = false -- Find Herbs or Find Minerals is on

local function readTracking()
    tracking = false
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(i)
        if type(info) == "table" and info.active and (info.spellID == HERBS or info.spellID == MINERALS) then
            tracking = true
            return
        end
    end
end

-- Records a probe that read a node's name. Spots are kept on the zone map, so hits from frames
-- apart still line up while the player moves.
local function addHit(hits, v, name, icon, right, up)
    local x, y = fromMinimap(v, right, up)
    hits[#hits + 1] = { name = name, icon = icon, x = x, y = y }
end

-- A dot answers to every probe near it, so one dot gives a patch of hits. Hits of one name that
-- touch (within `reach` minimap units, a probe's neighbors) are one dot, at the middle of them.
local function group(hits, v, reach)
    for _, hit in ipairs(hits) do
        hit.right, hit.up = toMinimap(v, hit.x, hit.y)
    end
    local result, taken = {}, {}
    for i, first in ipairs(hits) do
        if not taken[i] then
            taken[i] = true
            local queue, at = { first }, 1
            local sumX, sumY = 0, 0
            while at <= #queue do
                local a = queue[at]
                at = at + 1
                sumX, sumY = sumX + a.x, sumY + a.y
                for j, b in ipairs(hits) do
                    if not taken[j] and b.name == a.name then
                        local dr, du = a.right - b.right, a.up - b.up
                        if dr * dr + du * du <= reach * reach then
                            taken[j] = true
                            queue[#queue + 1] = b
                        end
                    end
                end
            end
            result[#result + 1] = { x = sumX / #queue, y = sumY / #queue, icon = first.icon,
                standing = standing(first.name) }
        end
    end
    return result
end

local function finish(v)
    if not module.db.calibration.space then
        if #sweep.hits > 0 then
            module.db.calibration.space = sweep.space
        else
            trying = trying % #ORDER + 1
        end
    end
    nodes, nodesMap = group(sweep.hits, v, sweep.step * REACH), sweep.mapID
    sweep = nil
    nextSweep = GetTime() + REST
end

-- Probes the next few spots of the sweep, or starts one when it's time.
local function step(v)
    if not sweep then
        if GetTime() < nextSweep then
            return
        end
        local spacing = STEPS[module.db.detail] or STEPS.medium
        sweep = { mapID = v.mapID, index = 1, hits = {}, space = currentSpace(), step = spacing,
            points = grid(v.half, spacing) }
    elseif sweep.mapID ~= v.mapID then
        sweep = nil -- a new zone map; start over
        return
    end
    local list = sweep.points
    local last = sweep.index + PER_FRAME - 1
    if last > #list then
        last = #list
    end
    startProbing()
    for i = sweep.index, last do
        local right, up = list[i][1], list[i][2]
        local text = probe(right, up, sweep.space)
        if blocked then
            break
        end
        if text then
            -- Overlapping dots put several names in the line, one per row.
            for _, name in ipairs(namesIn(text)) do
                local icon = iconFor(name)
                if icon then
                    addHit(sweep.hits, v, name, icon, right, up)
                else
                    seen[name] = true
                end
            end
        end
    end
    stopProbing()
    if blocked then
        sweep = nil
        return
    end
    sweep.index = last + 1
    if sweep.index > #list then
        finish(v)
    end
end

-- Drawing ---------------------------------------------------------------------------------------

local frame -- over the minimap; holds the icons and runs the sweeps
local icons, rings = {}, {}

-- The gold ring of the minimap's tracking button, which Blizzard also puts around a 24 pixel spec
-- icon (ItemDisplay.xml): the 64 pixel file with the icon's center 19 right and 18 down of its
-- corner. Scaled to the icon here.
local RING = "Interface\\Minimap\\MiniMap-TrackingBorder"
local RING_ICON, RING_FILE, RING_X, RING_Y = 24, 64, 19, 18

local function getIcon(i)
    local icon = icons[i]
    if not icon then
        icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- A round icon, like the minimap's own. Probe: the mask is Mainline's portrait mask.
        local mask = frame:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE",
            "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
        icons[i] = icon
        local ring = frame:CreateTexture(nil, "OVERLAY")
        ring:SetTexture(RING)
        rings[i] = ring
    end
    return icon, rings[i]
end

local function hideIcons(from)
    for i = from or 1, #icons do
        icons[i]:Hide()
        rings[i]:Hide()
    end
end

-- Puts the ring around an icon of `size`, or hides it.
local function placeRing(ring, icon, size, shown)
    if not shown then
        ring:Hide()
        return
    end
    local k = size / RING_ICON
    ring:SetSize(RING_FILE * k, RING_FILE * k)
    ring:ClearAllPoints()
    ring:SetPoint("TOPLEFT", icon, "CENTER", -RING_X * k, RING_Y * k)
    ring:Show()
end

local function draw(v)
    local shown = 0
    if v and v.mapID == nodesMap then
        local size, tint, gray, border = module.db.size, module.db.tint, module.db.gray, module.db.border
        local limit = v.half - EDGE - size / 4
        for _, node in ipairs(nodes) do
            local right, up = toMinimap(v, node.x, node.y)
            if right * right + up * up <= limit * limit then
                shown = shown + 1
                local icon, ring = getIcon(shown)
                icon:SetTexture(node.icon)
                local grayed = gray and node.standing == "gray"
                icon:SetDesaturated(grayed)
                if tint and node.standing == "low" then
                    icon:SetVertexColor(RED[1], RED[2], RED[3])
                elseif grayed then
                    icon:SetVertexColor(GRAY[1], GRAY[2], GRAY[3])
                else
                    icon:SetVertexColor(1, 1, 1)
                end
                icon:SetSize(size, size)
                icon:SetPoint("CENTER", Minimap, "CENTER", right, up)
                icon:Show()
                placeRing(ring, icon, size, border)
            end
        end
    end
    hideIcons(shown + 1)
end

local function onUpdate()
    if not tracking then
        hideIcons()
        return
    end
    local v = readView()
    draw(v)
    -- Sweeping would take over the tooltip of a cursor on the minimap, and isn't worth it in combat.
    if v and not blocked and not InCombatLockdown() and not Minimap:IsMouseOver() then
        step(v)
    end
end

-- Learning names ----------------------------------------------------------------------------------

local pending, pendingAt -- the name the player last cast a spell at, and when

local function onCastSent(_, unit, target)
    if unit == "player" and target and readable(target) and seen[target] then
        pending, pendingAt = target, GetTime()
    end
end

local function onLootOpened()
    if not (pending and GetTime() - pendingAt <= LEARN_WAIT) then
        return
    end
    local name = pending
    pending = nil
    for slot = 1, GetNumLootItems() do
        local icon = GetLootSlotInfo(slot)
        if icon and readable(icon) then
            module.db.learned[name] = icon
            seen[name] = nil
            return
        end
    end
end

-- A skill-up can lift the tint: sweep again now, which reads the skill again.
local function onSkill()
    nextSweep = 0
end

-- A zoom moves every dot; rather than show icons where they were, drop them and sweep again now.
local function onZoom()
    nodes, sweep, nextSweep = {}, nil, 0
end

-- /fpp nodes ----------------------------------------------------------------------------------------
-- What the sweep sees, for finding out in game why no icons show: whether tracking is on, whether
-- the player's spot can be read, and a whole sweep in each space with the names it found. The
-- space whose sweep finds the most nodes is saved.

local REPORT_NAMES = 4 -- names listed for each space

local function report()
    if not module:IsAvailable() then
        ns.Print(L.MINIMAPNODEICONS_REPORT_UNAVAILABLE)
        return
    end
    if InCombatLockdown() then
        ns.Print(L.MINIMAPNODEICONS_REPORT_COMBAT)
        return
    end
    readTracking()
    local v = readView()
    ns.Print(format(L.MINIMAPNODEICONS_REPORT_STATE,
        tracking and L.MINIMAPNODEICONS_REPORT_YES or L.MINIMAPNODEICONS_REPORT_NO,
        v and L.MINIMAPNODEICONS_REPORT_YES or L.MINIMAPNODEICONS_REPORT_NO,
        floor(Minimap:GetWidth() + 0.5), tostring(C_Minimap.GetViewRadius and C_Minimap.GetViewRadius())))
    local list = grid(Minimap:GetWidth() / 2, STEPS.high)
    local best, bestCount = nil, 0
    for _, space in ipairs(ORDER) do
        local names, order, known = {}, {}, 0
        startProbing()
        for _, point in ipairs(list) do
            local text = probe(point[1], point[2], space)
            if blocked then
                stopProbing()
                return
            end
            if text then
                for _, name in ipairs(namesIn(text)) do
                    if not names[name] then
                        names[name] = true
                        order[#order + 1] = name
                        if iconFor(name) then
                            known = known + 1
                        end
                    end
                end
            end
        end
        stopProbing()
        local shown = {}
        for i = 1, min(#order, REPORT_NAMES) do
            shown[i] = order[i]
        end
        ns.Print(format(L.MINIMAPNODEICONS_REPORT_SPACE, space, #order, known,
            #shown > 0 and concat(shown, ", ") or L.MINIMAPNODEICONS_REPORT_NONE))
        if known > bestCount then
            best, bestCount = space, known
        end
    end
    if best then
        module.db.calibration.space = best
        ns.Print(format(L.MINIMAPNODEICONS_REPORT_SAVED, best))
    else
        module.db.calibration.space = nil
        ns.Print(L.MINIMAPNODEICONS_REPORT_NOTHING)
    end
    sweep, nextSweep = nil, 0
end

-- /fpp nodes here: where the dot under the cursor is against where a sweep puts it. After a few
-- seconds to point at a dot, the cursor's spot and the name the game shows there are read; then a
-- sweep finds that name's patch of hits nearest the cursor and prints its middle and edges, all in
-- minimap units right and up of its center, with the zoom and the view radius.
local HERE_WAIT = 3 -- seconds to put the cursor on a dot

local function measure()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = Minimap:GetCenter()
    local right, up = x / scale - cx, y / scale - cy
    local data = C_TooltipInfo.GetMinimapMouseover()
    local line = data and data.lines and data.lines[1]
    local text = line and line.leftText
    local name = text and readable(text) and namesIn(text)[1]
    if not name then
        ns.Print(L.MINIMAPNODEICONS_HERE_NONE)
        return
    end
    local list = grid(Minimap:GetWidth() / 2, STEPS.high)
    local space = currentSpace()
    local hits = {}
    startProbing()
    for _, point in ipairs(list) do
        local found = probe(point[1], point[2], space)
        if blocked then
            break
        end
        if found then
            for _, other in ipairs(namesIn(found)) do
                if other == name then
                    hits[#hits + 1] = { right = point[1], up = point[2] }
                end
            end
        end
    end
    stopProbing()
    -- The patch: hits that touch, grown from the hit nearest the cursor.
    local nearest, best
    for i, hit in ipairs(hits) do
        local dr, du = hit.right - right, hit.up - up
        local d = dr * dr + du * du
        if not best or d < best then
            nearest, best = i, d
        end
    end
    local reach = STEPS.high * REACH
    local patch, taken = {}, {}
    if nearest then
        patch[1], taken[nearest] = hits[nearest], true
        local at = 1
        while at <= #patch do
            local a = patch[at]
            at = at + 1
            for j, b in ipairs(hits) do
                local dr, du = a.right - b.right, a.up - b.up
                if not taken[j] and dr * dr + du * du <= reach * reach then
                    taken[j] = true
                    patch[#patch + 1] = b
                end
            end
        end
    end
    local sumR, sumU, minR, maxR, minU, maxU = 0, 0, huge, -huge, huge, -huge
    for _, hit in ipairs(patch) do
        sumR, sumU = sumR + hit.right, sumU + hit.up
        minR, maxR = min(minR, hit.right), max(maxR, hit.right)
        minU, maxU = min(minU, hit.up), max(maxU, hit.up)
    end
    ns.Print(format(L.MINIMAPNODEICONS_HERE_CURSOR, name, right, up, Minimap:GetZoom(),
        tostring(C_Minimap.GetViewRadius and C_Minimap.GetViewRadius())))
    if #patch == 0 then
        ns.Print(L.MINIMAPNODEICONS_HERE_MISSED)
        return
    end
    ns.Print(format(L.MINIMAPNODEICONS_HERE_PATCH, #patch, sumR / #patch, sumU / #patch, minR, maxR,
        minU, maxU))
end

ns.AddCommand("nodes", "[here]", L.MINIMAPNODEICONS_COMMAND, function(rest)
    if rest and rest:lower():match("^%s*here") then
        if not module:IsAvailable() or InCombatLockdown() then
            ns.Print(L.MINIMAPNODEICONS_REPORT_COMBAT)
            return
        end
        ns.Print(format(L.MINIMAPNODEICONS_HERE_START, HERE_WAIT))
        C_Timer.After(HERE_WAIT, measure)
        return
    end
    report()
end)

-- Turning on and off ------------------------------------------------------------------------------

function module:OnEnable()
    if not frame then
        frame = CreateFrame("Frame", nil, Minimap)
        frame:SetAllPoints(Minimap)
        frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    end
    frame:Show()
    frame:SetScript("OnUpdate", onUpdate)
    readTracking()
    self:On("MINIMAP_UPDATE_TRACKING", readTracking)
    self:On("PLAYER_ENTERING_WORLD", readTracking)
    self:On("UNIT_SPELLCAST_SENT", onCastSent)
    self:On("LOOT_OPENED", onLootOpened)
    self:On("SKILL_LINES_CHANGED", onSkill)
    self:On("MINIMAP_UPDATE_ZOOM", onZoom)
end

function module:OnDisable()
    if frame then
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
    nodes, nodesMap, sweep, pending = {}, nil, nil, nil
end

function module:OnOptionChanged(key)
    if key == "detail" then
        sweep = nil
    end
end
