-- Zone Info: a small panel in a bottom corner of the world map about the zone it shows, or on a
-- continent map the zone under the cursor: its level range colored against yours, the Fishing
-- skill its waters need, and the herbs, ore, and skinning it has for the gathering professions
-- you have. Ideas from Leatrix Maps' zone levels; none of its code. The zones are in Data.lua.
local _, ns = ...

local ipairs, tostring, format, concat = ipairs, tostring, string.format, table.concat
local min, max, GetLocale = math.min, math.max, GetLocale
local CreateFrame, C_AddOns, C_Map, C_Item, C_XMLUtil = CreateFrame, C_AddOns, C_Map, C_Item, C_XMLUtil
local Enum, UnitLevel, GetQuestDifficultyColor = Enum, UnitLevel, GetQuestDifficultyColor
local QuestDifficultyColors = QuestDifficultyColors

local L = ns.L
local Professions = ns.Professions
local Code = ns.Colors.Code

local module = ns.NewModule("ZoneInfo", L.ZONEINFO_DESC, {
    enabled = false,
    corner = "BOTTOMLEFT",
    hover = true, -- on continent maps, the zone under the cursor
    levels = true,
    fishing = true,
    gathering = true,
})
module.title = L.ZONEINFO_TITLE
module.category = "map"

module.options = {
    {
        key = "corner", name = L.ZONEINFO_CORNER, description = L.ZONEINFO_CORNER_DESC,
        choices = {
            { "BOTTOMLEFT", L.ZONEINFO_BOTTOMLEFT },
            { "BOTTOMRIGHT", L.ZONEINFO_BOTTOMRIGHT },
        },
    },
    { key = "hover", name = L.ZONEINFO_HOVER, description = L.ZONEINFO_HOVER_DESC },
    { key = "levels", name = L.ZONEINFO_LEVELS, description = L.ZONEINFO_LEVELS_DESC },
    { key = "fishing", name = L.ZONEINFO_FISHING, description = L.ZONEINFO_FISHING_DESC },
    { key = "gathering", name = L.ZONEINFO_GATHERING, description = L.ZONEINFO_GATHERING_DESC },
}

-- Shared with Data.lua: `zones` (by map ID), `herbs` and `ores` (by item ID).
module.internal = {}
local internal = module.internal

local MAP_ADDON = "Blizzard_WorldMap"
local MAX_WIDTH = 300 -- the widest the text gets; longer lines wrap
local PADDING = 8
local GAP = 3 -- between rows
local ROWS = 3
local ICON_SIZE = 16 -- pixels
local THROTTLE = 0.1 -- seconds between looks at where the cursor is

local function colored(color, text)
    return Code(color.r, color.g, color.b) .. text .. "|r"
end

-- Text ----------------------------------------------------------------------------------------

-- The panel is a title and up to three short rows, each led by its profession's icon:
--   Silverpine Forest  10-20
--   [fishing] Fishing 1    [skinning] Skinning 1-100
--   [herbalism] Peacebloom, Silverleaf, Earthroot
--   [mining] Copper, Tin, Silver

-- Each profession's icon, for when the player doesn't have it (Fishing still shows then).
local ICONS = {
    [Professions.FISHING] = "Interface\\Icons\\Trade_Fishing",
    [Professions.SKINNING] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    [Professions.HERBALISM] = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    [Professions.MINING] = "Interface\\Icons\\Trade_Mining",
}

-- "10-20", colored like a quest of that level: red or orange when it's above you, yellow while
-- you're in it, green or gray once you've outleveled it. Two below the top counts as outleveled,
-- so a zone you've finished isn't yellow.
local function levelText(low, high)
    local text = low == high and tostring(low) or format(L.ZONEINFO_RANGE, low, high)
    if not (GetQuestDifficultyColor and QuestDifficultyColors) then
        return text
    end
    local level = UnitLevel("player")
    local color
    if level < low then
        color = GetQuestDifficultyColor(low)
    elseif level > high then
        color = GetQuestDifficultyColor(max(low, high - 2))
    else
        color = QuestDifficultyColors.difficult
    end
    return color and colored(color, text) or text
end

-- A profession's icon in text, bigger than the small font so it reads at a glance.
local function icon(line, own)
    return format("|T%s:%d:%d|t ", own or ICONS[line], ICON_SIZE, ICON_SIZE)
end

-- A skill the zone needs, colored by how hard it is at the player's rank. Fishing has no
-- difficulty, only enough or not: red while below it, white once there.
local function skill(rank, need, fishing)
    if fishing and not (rank and rank < need) then
        return tostring(need)
    end
    return colored(Professions.Difficulty(rank, need), need)
end

local function range(rank, low, high, fishing)
    local text = skill(rank, low, fishing)
    if high and high ~= low then
        text = format(L.ZONEINFO_RANGE, text, skill(rank, high, fishing))
    end
    return text
end

-- Fishing, whether or not the player has it, and Skinning, from the zone's level range, when the
-- player has it; together in one row.
local function skillsRow(zone)
    local db, parts = module.db, {}
    if db.fishing and zone.fish then
        local rank, name, own = Professions.Rank(Professions.FISHING)
        parts[#parts + 1] = icon(Professions.FISHING, own) .. format(L.ZONEINFO_SKILL,
            name or L.ZONEINFO_FISHING_NAME, range(rank, zone.fish, zone.fishHigh, true))
    end
    local rank, name, own = Professions.Rank(Professions.SKINNING)
    if db.gathering and rank and zone[1] then
        parts[#parts + 1] = icon(Professions.SKINNING, own) .. format(L.ZONEINFO_SKILL,
            name or L.ZONEINFO_SKINNING_NAME, range(rank, Professions.SkinningNeed(zone[1]),
                Professions.SkinningNeed(zone[2])))
    end
    if #parts > 0 then
        return concat(parts, "    ")
    end
end

-- An item's name: the short English one from Data.lua in English, else the game's own (which
-- keeps "Ore"), or the English until the game has loaded it.
local english = GetLocale() == "enUS"
local function itemName(id, name)
    if english or not (C_Item and C_Item.GetItemNameByID) then
        return name
    end
    local own = C_Item.GetItemNameByID(id)
    if not own and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(id)
    end
    return own or name
end

-- The zone's herbs or ores, each colored by how hard it is at the player's skill, or nil when the
-- player doesn't have the profession.
local function gatherRow(line, ids, items)
    local rank, _, own = Professions.Rank(line)
    if not (module.db.gathering and rank and ids and #ids > 0) then
        return nil
    end
    local names = {}
    for i, id in ipairs(ids) do
        local item = items[id]
        names[i] = colored(Professions.Difficulty(rank, item[1]), itemName(id, item[2]))
    end
    return icon(line, own) .. concat(names, L.ZONEINFO_LIST_SEPARATOR)
end

-- The rows under the zone's name, in order.
local function rows(zone)
    local list = {}
    list[#list + 1] = skillsRow(zone)
    list[#list + 1] = gatherRow(Professions.HERBALISM, zone.herbs, internal.herbs)
    list[#list + 1] = gatherRow(Professions.MINING, zone.ores, internal.ores)
    return list
end

-- Which zone ----------------------------------------------------------------------------------

local function isContinent(info)
    local types = Enum and Enum.UIMapType
    return types and (info.mapType == types.Continent or info.mapType == types.World
        or info.mapType == types.Cosmic)
end

-- The zone in Data.lua a map is, or is inside (a cave or a town's own map), or nil.
local function zoneOf(mapID)
    while mapID and mapID > 0 do
        if internal.zones[mapID] then
            return mapID
        end
        local info = C_Map.GetMapInfo(mapID)
        if not info or isContinent(info) then
            return nil
        end
        mapID = info.parentMapID
    end
end

-- The zone the panel is about: the map's own, or on a continent the one under the cursor.
local function target(map)
    local mapID = map:GetMapID()
    local info = mapID and C_Map.GetMapInfo(mapID)
    if not info then
        return nil
    end
    if not isContinent(info) then
        return zoneOf(mapID)
    end
    if not (module.db.hover and map.IsCanvasMouseFocus and map:IsCanvasMouseFocus()) then
        return nil
    end
    local x, y = map:GetNormalizedCursorPosition()
    local under = x and C_Map.GetMapInfoAtPosition and C_Map.GetMapInfoAtPosition(mapID, x, y)
    if under and under.mapID ~= mapID then
        return zoneOf(under.mapID)
    end
end

-- The panel -----------------------------------------------------------------------------------

local panel, driver
local shown -- the zone the panel shows now, or false for none; nil to draw again

-- A tooltip's look, which Blizzard uses for small boxes over the map. Probe: the template is
-- Mainline's; without it, the plain backdrop template and its tooltip backdrop.
local function newPanel(parent)
    local hasTemplate = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("TooltipBackdropTemplate")
    local frame = CreateFrame("Frame", nil, parent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    if not hasTemplate and frame.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        frame:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        frame:SetBackdropColor(0, 0, 0, 0.8)
    end
    -- Over the map's pins, which sit on the canvas inside the same container.
    frame:SetFrameLevel(parent:GetFrameLevel() + 2000)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetJustifyH("LEFT")
    frame.rows = {}
    local above = frame.title
    for i = 1, ROWS do
        local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -GAP)
        row:SetJustifyH("LEFT")
        frame.rows[i] = row
        above = row
    end
    frame:Hide()
    return frame
end

-- How wide a line is unwrapped. Probe: GetUnboundedStringWidth is Mainline's.
local function textWidth(text)
    return text.GetUnboundedStringWidth and text:GetUnboundedStringWidth() or text:GetStringWidth()
end

-- Blizzard's own coordinates, a row each for the cursor and the player, sit in the bottom left
-- corner from 2 pixels up, each row 15 tall, while their Settings checkboxes (these CVars) are on.
local COORDS_CVARS = { "worldMapShowCursorCoords", "worldMapShowPlayerCoords" }
local COORDS_BOTTOM, COORDS_ROW = 2, 15

-- Blizzard's coordinates panel: the map's overlay frame with a cursor row and a player row. It
-- has no name, so it's found by its parts. False once looked for and not there.
local coords
local function coordsPanel()
    if coords == nil then
        coords = false
        for _, frame in ipairs(WorldMapFrame.overlayFrames or {}) do
            if frame.CursorCoords and frame.PlayerCoords then
                coords = frame
            end
        end
    end
    return coords or nil
end

-- How far up the panel sits in the bottom left corner: over Blizzard's coordinates when they
-- show. By the checkboxes, not the rows, so the panel doesn't jump as the cursor row comes and
-- goes. Not when something has faded Blizzard's panel out to show the coordinates elsewhere
-- (such as our Coordinates module in the title bar): only the panel's own state is read.
local function bottomLeftOffset()
    local blizzard = coordsPanel()
    if blizzard and not (blizzard:IsShown() and blizzard:GetAlpha() > 0) then
        return 8
    end
    local rows = 0
    for _, name in ipairs(COORDS_CVARS) do
        if ns.CVars.IsOn(name) then
            rows = rows + 1
        end
    end
    if rows == 0 then
        return 8
    end
    return COORDS_BOTTOM + rows * COORDS_ROW + 8
end

local anchored -- where the panel sits now: the corner and how far up, or nil to place it again

local function anchor()
    local corner = module.db.corner
    local offset = corner == "BOTTOMRIGHT" and 8 or bottomLeftOffset()
    local key = corner .. offset
    if key == anchored then
        return
    end
    anchored = key
    panel:ClearAllPoints()
    if corner == "BOTTOMRIGHT" then
        panel:SetPoint("BOTTOMRIGHT", panel:GetParent(), "BOTTOMRIGHT", -8, offset)
    else
        panel:SetPoint("BOTTOMLEFT", panel:GetParent(), "BOTTOMLEFT", 8, offset)
    end
end

local function draw(mapID)
    shown = mapID or false
    local zone = mapID and internal.zones[mapID]
    if not zone then
        panel:Hide()
        return
    end
    local info = C_Map.GetMapInfo(mapID)
    local title = info and info.name or ""
    if module.db.levels and zone[1] then
        title = format(L.ZONEINFO_TITLE_LEVELS, title, levelText(zone[1], zone[2]))
    end
    local list = rows(zone)
    -- As wide as the longest line, up to MAX_WIDTH; longer lines wrap.
    panel.title:SetWidth(0)
    panel.title:SetText(title)
    local width = textWidth(panel.title)
    for i, row in ipairs(panel.rows) do
        row:SetWidth(0)
        row:SetText(list[i] or "")
        row:SetShown(list[i] ~= nil)
        if list[i] then
            width = max(width, textWidth(row))
        end
    end
    width = min(width, MAX_WIDTH)
    panel.title:SetWidth(width)
    local height = PADDING * 2 + panel.title:GetStringHeight()
    for i, row in ipairs(panel.rows) do
        if list[i] then
            row:SetWidth(width)
            height = height + GAP + row:GetStringHeight()
        end
    end
    panel:SetSize(width + PADDING * 2, height)
    panel:Show()
end

local elapsed = 0
local function onUpdate(_, delta)
    elapsed = elapsed + delta
    if elapsed < THROTTLE then
        return
    end
    elapsed = 0
    -- Blizzard's coordinates can be turned on, off, or faded out at any time, with no event for
    -- the fading; this only moves the panel when that changed.
    anchor()
    local mapID = target(WorldMapFrame) or false
    if mapID ~= shown then
        draw(mapID or nil)
    end
end

-- Draws the panel again on the next update, after something it shows changed.
local function redraw()
    shown = nil
end

local waiting

-- Makes the panel on the world map, once the map has loaded. The driver looks at the map a few
-- times a second while it's open; it's the map's child, so it stops while the map is closed.
local function attach()
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    if not driver then
        local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
        panel = newPanel(parent)
        driver = CreateFrame("Frame", nil, parent)
        driver:SetScript("OnUpdate", onUpdate)
    end
    anchor()
    redraw()
    driver:Show()
end

local function mapLoaded()
    return (not C_AddOns or C_AddOns.IsAddOnLoaded(MAP_ADDON)) and WorldMapFrame
end

function module:OnEnable()
    if mapLoaded() then
        attach()
    else
        waiting = function(_, name)
            if name == MAP_ADDON then
                attach()
            end
        end
        ns.On("ADDON_LOADED", waiting)
    end
    -- What the colors are measured against.
    self:On("PLAYER_LEVEL_UP", redraw)
    self:On("SKILL_LINES_CHANGED", redraw)
    self:On("CHAT_MSG_SKILL", redraw)
end

function module:OnDisable()
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    if driver then
        driver:Hide()
        panel:Hide()
    end
end

function module:OnOptionChanged()
    if panel then
        anchor()
        redraw()
    end
end
