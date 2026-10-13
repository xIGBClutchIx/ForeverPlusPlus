-- Minimap Node Icons: the herb or ore a tracking dot on the minimap stands for, as that item's
-- icon over the dot, tinted red while the player's skill is too low to gather it. The game draws
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
local gmatch, tostring, format = string.gmatch, tostring, string.format
local CreateFrame, Minimap, GetTime = CreateFrame, Minimap, GetTime
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
    size = 16, -- icon size on the minimap
    tint = true, -- red while the skill is too low
    detail = "medium", -- a key of STEPS
    chat = true,
    -- Node name -> icon, for names not in NODES, from what gathering them gave. Data, not a setting.
    learned = {},
})
module.title = L.MINIMAPNODEICONS_TITLE
module.category = "map"
module.added = "0.9.0"

module.options = {
    {
        key = "size", name = L.MINIMAPNODEICONS_SIZE, description = L.MINIMAPNODEICONS_SIZE_DESC,
        min = 10, max = 24, step = 1, format = "%d",
    },
    { key = "tint", name = L.MINIMAPNODEICONS_TINT, description = L.MINIMAPNODEICONS_TINT_DESC },
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
local SAME = 9 -- hits of one name this close (minimap units) are one node
local EDGE = 2 -- keep probes and icons this far inside the minimap's edge
local LEARN_WAIT = 10 -- seconds from a cast to its loot window that still count as one gather
local RED = { 1, 0.25, 0.25 } -- the icon's vertex color while the skill is too low

-- The icon for a node's name, or nil for a name that isn't a node we know.
local function iconFor(name)
    local learned = module.db.learned[name]
    if learned then
        return learned
    end
    local node = NODES[name]
    return node and C_Item.GetItemIconByID(node[3])
end

-- Whether the player's skill is too low to gather the node named `name` (or they lack the
-- profession). False for a node whose skill isn't known.
local function tooLow(name)
    local node = NODES[name]
    if not node then
        return false
    end
    local rank = Professions.Rank(node[1])
    return not rank or rank < node[2]
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

-- Points the minimap's mouseover at a spot right and up of its center and returns the text the
-- tooltip there would show. Its points are taken to be the cursor's (GetCursorPosition): screen
-- pixels from the bottom left. Unverified on Forever; see docs/forever-api.md.
local function probe(right, up)
    local cx, cy = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local ok, err = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, (cx + right) * scale, (cy + up) * scale)
    if not ok then
        blocked = true
        module:Print(format(L.MINIMAPNODEICONS_FAILED, tostring(err)))
        return nil
    end
    local data = C_TooltipInfo.GetMinimapMouseover()
    local line = data and data.lines and data.lines[1]
    local text = line and line.leftText
    if text and readable(text) and text ~= "" then
        return text
    end
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

local nodes = {} -- the last sweep's nodes: { x, y, icon, low } on the zone map `nodesMap`
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

-- Adds a hit to the node of that name it is close to, or starts a node. Spots are kept on the zone
-- map, so hits from frames apart still meet while the player moves.
local function addHit(hits, v, name, icon, right, up)
    for _, hit in ipairs(hits) do
        if hit.name == name then
            local r, u = toMinimap(v, hit.x / hit.n, hit.y / hit.n)
            local dr, du = r - right, u - up
            if dr * dr + du * du <= SAME * SAME then
                local x, y = fromMinimap(v, right, up)
                hit.x, hit.y, hit.n = hit.x + x, hit.y + y, hit.n + 1
                return
            end
        end
    end
    local x, y = fromMinimap(v, right, up)
    hits[#hits + 1] = { name = name, icon = icon, x = x, y = y, n = 1 }
end

local function finish()
    nodes, nodesMap = {}, sweep.mapID
    for _, hit in ipairs(sweep.hits) do
        nodes[#nodes + 1] = { x = hit.x / hit.n, y = hit.y / hit.n, icon = hit.icon, low = tooLow(hit.name) }
    end
    sweep = nil
    nextSweep = GetTime() + REST
end

-- Probes the next few spots of the sweep, or starts one when it's time.
local function step(v)
    if not sweep then
        if GetTime() < nextSweep then
            return
        end
        sweep = { mapID = v.mapID, index = 1, hits = {},
            points = grid(v.half, STEPS[module.db.detail] or STEPS.medium) }
    elseif sweep.mapID ~= v.mapID then
        sweep = nil -- a new zone map; start over
        return
    end
    local list = sweep.points
    local last = sweep.index + PER_FRAME - 1
    if last > #list then
        last = #list
    end
    for i = sweep.index, last do
        local right, up = list[i][1], list[i][2]
        local text = probe(right, up)
        if blocked then
            sweep = nil
            return
        end
        if text then
            -- Overlapping dots put several names in the line, one per row.
            for name in gmatch(plain(text), "[^\n]+") do
                local icon = iconFor(name)
                if icon then
                    addHit(sweep.hits, v, name, icon, right, up)
                else
                    seen[name] = true
                end
            end
        end
    end
    sweep.index = last + 1
    if sweep.index > #list then
        finish()
    end
end

-- Drawing ---------------------------------------------------------------------------------------

local frame -- over the minimap; holds the icons and runs the sweeps
local icons = {}

local function getIcon(i)
    local icon = icons[i]
    if not icon then
        icon = frame:CreateTexture(nil, "OVERLAY")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- A round icon, like the minimap's own. Probe: the mask is Mainline's portrait mask.
        local mask = frame:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE",
            "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
        icons[i] = icon
    end
    return icon
end

local function hideIcons(from)
    for i = from or 1, #icons do
        icons[i]:Hide()
    end
end

local function draw(v)
    local shown = 0
    if v and v.mapID == nodesMap then
        local size, tint = module.db.size, module.db.tint
        local limit = v.half - EDGE - size / 4
        for _, node in ipairs(nodes) do
            local right, up = toMinimap(v, node.x, node.y)
            if right * right + up * up <= limit * limit then
                shown = shown + 1
                local icon = getIcon(shown)
                icon:SetTexture(node.icon)
                if tint and node.low then
                    icon:SetVertexColor(RED[1], RED[2], RED[3])
                else
                    icon:SetVertexColor(1, 1, 1)
                end
                icon:SetSize(size, size)
                icon:SetPoint("CENTER", Minimap, "CENTER", right, up)
                icon:Show()
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
