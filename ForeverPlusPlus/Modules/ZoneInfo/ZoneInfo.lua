-- Zone Info: a small panel in a bottom corner of the world map about the zone it shows, or on a
-- continent map the zone under the cursor: its level range colored against yours, the Fishing
-- skill its waters need, and the herbs, ore, and skinning it has for the gathering professions
-- you have. Ideas from Leatrix Maps' zone levels; none of its code. The zones are in Data.lua.
local _, ns = ...

local ipairs, tostring, format, concat, max = ipairs, tostring, string.format, table.concat, math.max
local CreateFrame, C_AddOns, C_Map, C_Item, C_XMLUtil = CreateFrame, C_AddOns, C_Map, C_Item, C_XMLUtil
local Enum, UnitLevel, GetQuestDifficultyColor = Enum, UnitLevel, GetQuestDifficultyColor
local QuestDifficultyColors, NORMAL_FONT_COLOR = QuestDifficultyColors, NORMAL_FONT_COLOR

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
local WIDTH = 250 -- the panel's width; lines wrap inside it
local PADDING = 10
local THROTTLE = 0.1 -- seconds between looks at where the cursor is

local NORMAL = NORMAL_FONT_COLOR and Code(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
    NORMAL_FONT_COLOR.b) or "|cffffd100"

local function colored(color, text)
    return Code(color.r, color.g, color.b) .. text .. "|r"
end

-- Text ----------------------------------------------------------------------------------------

-- "Level 10-20", colored like a quest of that level: red or orange when it's above you, yellow
-- while you're in it, green or gray once you've outleveled it. Two below the top counts as
-- outleveled, so a zone you've finished isn't yellow.
local function levelText(low, high)
    local text = low == high and format(L.ZONEINFO_LEVEL, low) or format(L.ZONEINFO_LEVEL_RANGE, low, high)
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

-- "Name: text", with the name in the game's gold.
local function labeled(name, text)
    return format(L.ZONEINFO_LINE, NORMAL .. name .. "|r", text)
end

-- A skill the player needs: red while below it, white once there.
local function needText(rank, need)
    if rank and rank < need then
        return colored(Professions.Difficulty(rank, need), need)
    end
    return tostring(need)
end

local function fishingLine(zone)
    local rank, name = Professions.Rank(Professions.FISHING)
    local text = needText(rank, zone.fish)
    if zone.fishHigh then
        text = format(L.ZONEINFO_RANGE, text, needText(rank, zone.fishHigh))
    end
    return labeled(name or L.ZONEINFO_FISHING_NAME, text)
end

-- An item's name in the player's language, or the English from Data.lua until the game has it.
local function itemName(id, english)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(id)
    end
    return name or english
end

-- The herbs or ores of a zone, each colored by how hard it is at the player's skill, or nil when
-- the player doesn't have the profession.
local function gatherLine(line, ids, items)
    local rank, name = Professions.Rank(line)
    if not (rank and ids and #ids > 0) then
        return nil
    end
    local names = {}
    for i, id in ipairs(ids) do
        local item = items[id]
        names[i] = colored(Professions.Difficulty(rank, item[1]), itemName(id, item[2]))
    end
    return labeled(name, concat(names, L.ZONEINFO_LIST_SEPARATOR))
end

-- The Skinning skill the zone's beasts need, from its level range.
local function skinningLine(zone)
    local rank, name = Professions.Rank(Professions.SKINNING)
    if not (rank and zone[1]) then
        return nil
    end
    local low, high = Professions.SkinningNeed(zone[1]), Professions.SkinningNeed(zone[2])
    local text = colored(Professions.Difficulty(rank, low), low)
    if high ~= low then
        text = format(L.ZONEINFO_RANGE, text, colored(Professions.Difficulty(rank, high), high))
    end
    return labeled(name, text)
end

-- The lines under the zone's name, in order.
local function lines(zone)
    local db, list = module.db, {}
    if db.fishing and zone.fish then
        list[#list + 1] = fishingLine(zone)
    end
    if db.gathering then
        list[#list + 1] = gatherLine(Professions.HERBALISM, zone.herbs, internal.herbs)
        list[#list + 1] = gatherLine(Professions.MINING, zone.ores, internal.ores)
        list[#list + 1] = skinningLine(zone)
    end
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
    frame:SetWidth(WIDTH)
    -- Over the map's pins, which sit on the canvas inside the same container.
    frame:SetFrameLevel(parent:GetFrameLevel() + 2000)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetWidth(WIDTH - PADDING * 2)
    frame.title:SetJustifyH("LEFT")
    frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.body:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.body:SetWidth(WIDTH - PADDING * 2)
    frame.body:SetJustifyH("LEFT")
    frame.body:SetSpacing(2)
    frame:Hide()
    return frame
end

local function anchor()
    local parent = panel:GetParent()
    panel:ClearAllPoints()
    if module.db.corner == "BOTTOMRIGHT" then
        panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    else
        panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 8)
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
    local body = lines(zone)
    panel.title:SetText(title)
    panel.body:SetText(concat(body, "\n"))
    panel.body:SetShown(#body > 0)
    local height = PADDING * 2 + panel.title:GetStringHeight()
    if #body > 0 then
        height = height + 4 + panel.body:GetStringHeight()
    end
    panel:SetHeight(height)
    panel:Show()
end

local elapsed = 0
local function onUpdate(_, delta)
    elapsed = elapsed + delta
    if elapsed < THROTTLE then
        return
    end
    elapsed = 0
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
