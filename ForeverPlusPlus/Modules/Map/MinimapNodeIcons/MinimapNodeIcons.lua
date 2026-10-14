-- Minimap Node Icons: the herb or ore a tracking dot on the minimap stands for, as that item's
-- icon over the dot, optionally gray for a node on another level (as in a cave), red while the
-- player's skill is too low to gather it, or gray once gathering it no longer raises the skill.
--
-- The game draws the dots itself, lists them nowhere an addon can read, and has no way to change
-- or hide one (Forever's minimap has no SetBlipTexture). But its minimap has UpdateMouseoverAtPoint,
-- which points its mouseover at a spot as if a controller's cursor were there, and the tooltip
-- data for the mouseover names what is under that spot. Where a dot answers lags behind where it's
-- drawn while the player moves, and catches up once they stop (in game, 2026-10-13), so probes
-- can't place an icon frame by frame. Instead:
--   - Every frame, each icon is drawn from its node's spot on the zone map and the player's own
--     (C_Map.GetPlayerMapPosition), the minimap's view radius, and its rotation. That's exact
--     through moving, turning, and zooming, and costs no probes.
--   - A few times a second, the whole minimap is looked over for new dots on a grid, a part at a
--     time, and each node known is looked for again where its dot should be: a line of probes
--     across it and one up through it. While the player stands still the answer is exact and fixes
--     the node's spot; while they move the answer's lag is measured instead, and taken off new
--     dots found. A node that stops answering (gathered, out of range) loses its icon.
-- Probing stops in combat and while the cursor is on the minimap, where the game's own mouseover
-- and tooltip (which the icons let through) are the player's; icons keep moving meanwhile.
-- Where the player's spot can't be read (an instance), icons sit where the dots answered.
--
-- Names are matched through Professions.Node: Classic's English names, and those learned in game.
-- A node whose item isn't known gets it the first time the player gathers it: the spell's target,
-- then the first item in the loot window. Its skill is learned from Blizzard's "Requires Herbalism
-- (N)" line where the minimap's tooltip shows one under its name (or Profession Tooltips sees one);
-- until then it's never tinted. Ideas from NodeSight; none of its code.
--
-- This file holds the module, its options, reading the view, and drawing the icons. Probe.lua
-- asks the minimap what is under a spot, Nodes.lua follows and finds the dots, Learn.lua learns
-- a node's item from gathering it, and Report.lua has /fpp nodes. They share module.internal.
local _, ns = ...

local ipairs, type, sin, cos = ipairs, type, math.sin, math.cos
local CreateFrame, Minimap = CreateFrame, Minimap
local GetPlayerFacing, GetCVarBool = GetPlayerFacing, GetCVarBool
local C_Map, C_Minimap, C_TooltipInfo, C_Item = C_Map, C_Minimap, C_TooltipInfo, C_Item

local L = ns.L
local readable = ns.IsReadable
local Professions = ns.Professions
local Node = Professions.Node

local module = ns.NewModule("MinimapNodeIcons", L.MINIMAPNODEICONS_DESC, {
    enabled = false,
    size = 8, -- icon size on the minimap
    border = true, -- a gold ring around each icon
    levels = true, -- gray while the minimap names the node in gray (another level)
    tint = false, -- red while the skill is too low
    gray = false, -- gray once gathering no longer raises the skill
    detail = "medium", -- a key of STEPS
    chat = true,
    -- Node name -> icon, for nodes whose item couldn't be read from the loot window (and every
    -- one learned before items were). Data, not a setting.
    learned = {},
    -- { space = a key of SPACES }, once a pass has found a node with it. Data, not a setting.
    calibration = {},
})
module.title = L.MINIMAPNODEICONS_TITLE
module.category = "map"
module.added = "0.9.0"
module.internal = {}
local internal = module.internal
-- Honest about what probing costs and misses (see the top of this file); a notice with no button.
module.notice = {
    text = L.MINIMAPNODEICONS_NOTICE,
    description = L.MINIMAPNODEICONS_NOTICE_DESC,
    shown = function()
        return true
    end,
}

module.options = {
    {
        key = "size", name = L.MINIMAPNODEICONS_SIZE, description = L.MINIMAPNODEICONS_SIZE_DESC,
        min = 5, max = 20, step = 1, format = "%d",
    },
    { key = "border", name = L.MINIMAPNODEICONS_BORDER, description = L.MINIMAPNODEICONS_BORDER_DESC },
    { key = "levels", name = L.MINIMAPNODEICONS_LEVELS, description = L.MINIMAPNODEICONS_LEVELS_DESC },
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
            Professions.ForgetNodes()
            ns.Print(L.MINIMAPNODEICONS_CLEAR_DONE)
        end,
    },
}

-- Forever only: the minimap's UpdateMouseoverAtPoint is in its API docs (1.60.1).
function module:IsAvailable()
    return Minimap and Minimap.UpdateMouseoverAtPoint and C_TooltipInfo
        and C_TooltipInfo.GetMinimapMouseover and true or false
end

local HERBS = ns.GameData.Spell(2383, "Find Herbs")
local MINERALS = ns.GameData.Spell(2580, "Find Minerals")

-- Its parts' own rows on the Profiler page, so its time can be told apart. While not recording,
-- Profiler.Call just calls through. Probes are only counted (PART_ASK), not timed: a stopwatch
-- around each of hundreds a second costs more than the probe.
local Profiler = ns.Profiler
-- The other parts are made in the files that time them.
local PART_VIEW = Profiler.Part(module, L.MINIMAPNODEICONS_PART_VIEW)
local PART_DRAW = Profiler.Part(module, L.MINIMAPNODEICONS_PART_DRAW)

local TICK = 0.1 -- seconds between rounds of probes; icons are drawn every frame regardless
local EDGE = 2 -- keep probes and icons this far inside the minimap's edge
local RED = { 1, 0.25, 0.25 } -- the icon's vertex color while the skill is too low
local GRAY = { 0.7, 0.7, 0.7 } -- dims a gray (desaturated) icon
internal.TICK = TICK
internal.EDGE = EDGE
internal.STEPS = { low = 8, medium = 6, high = 4 } -- minimap units between finding probes
internal.NONE = {}

-- State the files share, on internal since some of it is replaced whole (internal.nodes = {}).
-- The nodes with an icon: { name, icon, standing, level, misses, right, up, x, y }. `right` and
-- `up` are where the dot answered last, in minimap units from the center; `x` and `y` its spot on
-- the zone map `nodesMap`, set when the view could be read, and what the icon is drawn from.
-- `level` is true while the minimap names it in gray (on another level).
internal.nodes = {}
internal.seen = {} -- names the minimap showed that aren't nodes we know, for learning
internal.tracking = false -- Find Herbs or Find Minerals is on
internal.blocked = false -- the client refused a probe; stop until /reload
internal.findAll = false -- find every dot at the next tick, after a zoom or a reset
internal.pass = nil -- the finding pass under way (Nodes.lua)
internal.pending = nil -- the name the player last cast a spell at (Learn.lua)
local nodesMap

-- The icon for a node's name, or nil for a name that isn't a node we know.
function internal.iconFor(name)
    local node = Node(name)
    local icon = node and node[3] and C_Item.GetItemIconByID(node[3])
    return icon or module.db.learned[name]
end

-- How the player's skill stands against the node named `name`: "low" when it's too low to gather
-- (or they lack the profession), "gray" when gathering it no longer raises the skill, else nil,
-- as for a node whose skill isn't known.
local function standing(name)
    local node = Node(name)
    if not (node and node[1] and node[2]) then
        return nil
    end
    local rank = Professions.Rank(node[1])
    if not rank or rank < node[2] then
        return "low"
    elseif Professions.Difficulty(rank, node[2]) == Professions.TRIVIAL then
        return "gray"
    end
end
internal.standing = standing

-- The view ----------------------------------------------------------------------------------------

-- What the minimap shows right now: the player's zone map and spot on it, the map's size in
-- yards, minimap units per yard, and the angle the minimap is turned by (0 unless it rotates).
-- Nil when any of it can't be read, as in an instance.
local view = {}

local function readView()
    local mapID, x, y = ns.WorldMap.PlayerPosition()
    if not mapID then
        return nil
    end
    local width, height = C_Map.GetMapWorldSize(mapID)
    if not (width and height and readable(width) and readable(height) and width > 0 and height > 0) then
        return nil
    end
    local radius = C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if not (radius and readable(radius) and type(radius) == "number" and radius > 0) then
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
    view.scale = view.half / radius -- minimap units per yard
    view.angle = angle
    return view
end
internal.readView = readView

-- A spot on the zone map as minimap units right and up of its center.
local function toMinimap(v, x, y)
    local east = (x - v.x) * v.width * v.scale
    local north = (v.y - y) * v.height * v.scale
    local c, s = cos(v.angle), sin(v.angle)
    return east * c + north * s, north * c - east * s
end

-- Minimap units right and up of its center as a spot on the zone map.
function internal.fromMinimap(v, right, up)
    local c, s = cos(v.angle), sin(v.angle)
    local east, north = right * c - up * s, right * s + up * c
    return v.x + east / (v.width * v.scale), v.y - north / (v.height * v.scale)
end

local function inside(right, up)
    local radius = Minimap:GetWidth() / 2 - EDGE
    return right * right + up * up <= radius * radius
end
internal.inside = inside

-- Nodes -------------------------------------------------------------------------------------------

local function readTracking()
    internal.tracking = false
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(i)
        if type(info) == "table" and info.active and (info.spellID == HERBS or info.spellID == MINERALS) then
            internal.tracking = true
            return
        end
    end
    internal.nodes = {}
end
internal.readTracking = readTracking

-- Where a node's icon belongs right now, from its map spot when there is a view, else where it
-- answered last.
local function drawnAt(node, v)
    if v and node.x and v.mapID == nodesMap then
        return toMinimap(v, node.x, node.y)
    end
    return node.right, node.up
end
internal.drawnAt = drawnAt

-- Drawing ---------------------------------------------------------------------------------------

local frame -- over the minimap; holds the icons and runs the probes
local pins = {}
local sinceTick = 0

-- The gold ring of the minimap's tracking button, which Blizzard also puts around a 24 pixel spec
-- icon (ItemDisplay.xml): the 64 pixel file with the icon's center 19 right and 18 down of its
-- corner. Scaled to the icon here.
local RING = "Interface\\Minimap\\MiniMap-TrackingBorder"
local RING_ICON, RING_FILE, RING_X, RING_Y = 24, 64, 19, 18

-- A pin: the icon, round, with the ring around it. It takes no mouse, so the minimap's own
-- tooltip for the dot under it shows, with whatever other addons (Profession Tooltips) add.
local function getPin(i)
    local pin = pins[i]
    if not pin then
        pin = CreateFrame("Frame", nil, frame)
        local icon = pin:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- A round icon, like the minimap's own. Probe: the mask is Mainline's portrait mask.
        local mask = pin:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE",
            "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
        local ring = pin:CreateTexture(nil, "OVERLAY")
        ring:SetTexture(RING)
        pin.icon, pin.ring = icon, ring
        pins[i] = pin
    end
    return pin
end

local function hidePins(from)
    for i = from or 1, #pins do
        pins[i]:Hide()
    end
end

-- Puts the ring around a pin of `size`, or hides it.
local function placeRing(pin, size, shown)
    local ring = pin.ring
    if not shown then
        ring:Hide()
        return
    end
    local k = size / RING_ICON
    ring:SetSize(RING_FILE * k, RING_FILE * k)
    ring:ClearAllPoints()
    ring:SetPoint("TOPLEFT", pin, "CENTER", -RING_X * k, RING_Y * k)
    ring:Show()
end

local function draw(v)
    local db = module.db
    local size = db.size
    local shown = 0
    for _, node in ipairs(internal.nodes) do
        local right, up = drawnAt(node, v)
        if inside(right, up) then
            shown = shown + 1
            local pin = getPin(shown)
            local icon = pin.icon
            icon:SetTexture(node.icon)
            local grayed = (db.gray and node.standing == "gray") or (db.levels and node.level) or false
            icon:SetDesaturated(grayed)
            if db.tint and node.standing == "low" then
                icon:SetVertexColor(RED[1], RED[2], RED[3])
            elseif grayed then
                icon:SetVertexColor(GRAY[1], GRAY[2], GRAY[3])
            else
                icon:SetVertexColor(1, 1, 1)
            end
            pin:SetSize(size, size)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", Minimap, "CENTER", right, up)
            pin:Show()
            placeRing(pin, size, db.border)
        end
    end
    hidePins(shown + 1)
end

local function onUpdate(_, elapsed)
    if not internal.tracking then
        hidePins()
        return
    end
    local v = Profiler.Call(PART_VIEW, readView)
    -- A new zone map: the nodes' spots were on the old one.
    if v and v.mapID ~= nodesMap then
        internal.nodes, nodesMap, internal.pass, internal.findAll = {}, v.mapID, nil, true
        internal.forgetSpot()
    end
    sinceTick = sinceTick + elapsed
    if sinceTick >= TICK then
        sinceTick = 0
        internal.tick(v)
    end
    Profiler.Call(PART_DRAW, draw, v)
end

-- A skill-up can lift the tint.
local function onSkill()
    for _, node in ipairs(internal.nodes) do
        node.standing = standing(node.name)
    end
end

-- A zoom: icons drawn from map spots move with it by themselves; look over the minimap for dots it
-- brought in. Without a view, where the dots answered is all there is, so start over.
local function onZoom()
    internal.findAll = true
    if not readView() then
        internal.nodes = {}
    end
end

-- Turning on and off ------------------------------------------------------------------------------

function module:OnEnable()
    if not frame then
        frame = CreateFrame("Frame", nil, Minimap)
        frame:SetAllPoints(Minimap)
        frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    end
    frame:Show()
    frame:SetScript("OnUpdate", ns.Profiler.Wrap(self, onUpdate)) -- timed while the Profiler records
    readTracking()
    internal.findAll = true
    self:On("MINIMAP_UPDATE_TRACKING", readTracking)
    self:On("PLAYER_ENTERING_WORLD", readTracking)
    self:On("UNIT_SPELLCAST_SENT", internal.onCastSent)
    self:On("LOOT_OPENED", internal.onLootOpened)
    self:On("SKILL_LINES_CHANGED", onSkill)
    self:On("MINIMAP_UPDATE_ZOOM", onZoom)
end

function module:OnDisable()
    if frame then
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
    internal.nodes, nodesMap, internal.pass, internal.pending = {}, nil, nil, nil
end

function module:OnOptionChanged(key)
    if key == "detail" then
        internal.pass = nil
    end
end
