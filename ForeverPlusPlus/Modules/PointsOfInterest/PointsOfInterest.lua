-- Points of Interest: icons on the world map's zone maps for dungeons, raids, flight masters,
-- boats, zeppelins, and spirit healers, each with a tooltip saying what and where it is. Every
-- kind has its own checkbox and icon size. Travel points of the other faction are off unless
-- asked for. Where the points are is in Data.lua.
local _, ns = ...

local ipairs, format, rawget, unpack, abs = ipairs, string.format, rawget, unpack, math.abs
local C_Map, C_EncounterJournal, UnitFactionGroup, UnitLevel =
    C_Map, C_EncounterJournal, UnitFactionGroup, UnitLevel
local GetRealZoneText, GetQuestDifficultyColor = GetRealZoneText, GetQuestDifficultyColor
local QuestDifficultyColors = QuestDifficultyColors

local L = ns.L

local module = ns.NewModule("PointsOfInterest", L.POI_DESC, {
    enabled = false,
    dungeons = true,
    dungeonSize = 100, -- percent of the kind's normal size, here and below
    raids = true,
    raidSize = 100,
    flightMasters = true,
    flightSize = 100,
    ships = true,
    shipSize = 100,
    zeppelins = true,
    zeppelinSize = 100,
    spiritHealers = true,
    spiritSize = 100,
    otherFaction = false, -- also the other faction's flight masters, boats, and zeppelins
})
module.title = L.POI_TITLE
module.category = "map"

-- Shared with Data.lua: `points` (by map ID) and `instances` (by key).
module.internal = {}
local internal = module.internal

-- A checkbox for a kind, and the slider for its size under it.
local function kind(key, sizeKey, name, description)
    return { key = key, name = name, description = description },
        {
            key = sizeKey, name = L.POI_SIZE, description = L.POI_SIZE_DESC, requires = key,
            min = 50, max = 200, step = 10, format = "%d%%",
        }
end

module.options = {}
for _, pair in ipairs({
    { kind("dungeons", "dungeonSize", L.POI_DUNGEONS, L.POI_DUNGEONS_DESC) },
    { kind("raids", "raidSize", L.POI_RAIDS, L.POI_RAIDS_DESC) },
    { kind("flightMasters", "flightSize", L.POI_FLIGHT, L.POI_FLIGHT_DESC) },
    { kind("ships", "shipSize", L.POI_SHIPS, L.POI_SHIPS_DESC) },
    { kind("zeppelins", "zeppelinSize", L.POI_ZEPPELINS, L.POI_ZEPPELINS_DESC) },
    { kind("spiritHealers", "spiritSize", L.POI_SPIRIT, L.POI_SPIRIT_DESC) },
}) do
    module.options[#module.options + 1] = pair[1]
    module.options[#module.options + 1] = pair[2]
end
module.options[#module.options + 1] =
    { key = "otherFaction", name = L.POI_OTHER_FACTION, description = L.POI_OTHER_FACTION_DESC }

-- Each kind of point: the checkbox and size settings that show it, its normal size in pixels,
-- and its icon. The boat, zeppelin, and graveyard icons are in Retail's atlas list, but not
-- confirmed on Forever, so the first the client has is chosen the first time the map draws; the
-- plain colored balls after them are ones Leatrix Maps uses on Forever.
local KINDS = {
    dungeon = { show = "dungeons", size = "dungeonSize", pixels = 24, atlas = "Dungeon" },
    raid = { show = "raids", size = "raidSize", pixels = 24, atlas = "Raid" },
    flight = { show = "flightMasters", size = "flightSize", pixels = 18 },
    ship = { show = "ships", size = "shipSize", pixels = 22,
        atlases = { "FlightMasterFerry", "Vehicle-TempleofKotmogu-CyanBall" } },
    zeppelin = { show = "zeppelins", size = "zeppelinSize", pixels = 24,
        atlases = { "Vehicle-Air-Horde", "Vehicle-TempleofKotmogu-CyanBall" } },
    spirit = { show = "spiritHealers", size = "spiritSize", pixels = 20,
        atlases = { "poi-graveyard-neutral", "Vehicle-TempleofKotmogu-GreenBall" } },
}

-- The flight master icon in each faction's color.
local TAXI = { A = "TaxiNode_Alliance", H = "TaxiNode_Horde", N = "TaxiNode_Neutral" }

local function atlasOf(kindInfo)
    if not kindInfo.atlas then
        kindInfo.atlas = ns.MapPins.Atlas(unpack(kindInfo.atlases))
    end
    return kindInfo.atlas
end

-- A place name from Data.lua, in the player's language when a locale file translates it
-- (L["Booty Bay"] = ...). Place names aren't in enUS.lua: the English is the name itself.
local function place(name)
    return rawget(L, name) or name
end

-- A zone's name in the player's language, from the game.
local function zoneName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and info.name or ""
end

-- An instance's name in the player's language from the game, or the English from Data.lua.
local function instanceName(instance)
    local name = instance[1] and GetRealZoneText and GetRealZoneText(instance[1])
    if not name or name == "" then
        name = instance[2]
    end
    if instance.part then
        name = format(L.POI_PART, name, instance.part)
    end
    return name
end

-- "Level 41-51", colored against the player's level like quests: red or orange when too high,
-- yellow within it, green or gray below it.
local function levels(instance)
    local low, high = instance[3], instance[4]
    local text = low == high and format(L.POI_LEVEL, low) or format(L.POI_LEVELS, low, high)
    if not (GetQuestDifficultyColor and QuestDifficultyColors) then
        return text
    end
    local level = UnitLevel("player")
    local color
    if level < low then
        color = GetQuestDifficultyColor(low)
    elseif level > high then
        color = GetQuestDifficultyColor(high)
    else
        color = QuestDifficultyColors.standard
    end
    if not color then
        return text
    end
    return ns.Colors.Code(color.r, color.g, color.b) .. text .. "|r"
end

-- The tooltip of a dungeon or raid: one instance, or a place with several (Blackrock Mountain).
local function instanceTooltip(kindName, key)
    local instance = internal.instances[key]
    if not instance.parts then
        return instanceName(instance), { kindName, levels(instance) }
    end
    local lines = {}
    for _, partKey in ipairs(instance.parts) do
        local part = internal.instances[partKey]
        lines[#lines + 1] = format("%s  %s", instanceName(part), levels(part))
    end
    return place(instance.name), lines
end

local FACTIONS = { Alliance = "A", Horde = "H" }

-- Whether a travel point of this faction shows for the player.
local function forPlayer(faction)
    local mine = FACTIONS[UnitFactionGroup("player") or ""]
    return faction == "N" or faction == mine or module.db.otherFaction
end

-- The pin for one point of Data.lua, or nil when its settings hide it.
local function pinFor(point, mapID)
    local kindName = point[1]
    local kindInfo = KINDS[kindName]
    local db = module.db
    -- A place with dungeons and raids (Blackrock Mountain) shows with either.
    local mixed = kindName == "dungeon" and internal.instances[point[4]].raids
    if not (db[kindInfo.show] or (mixed and db.raids)) then
        return nil
    end
    local info = { size = kindInfo.pixels * db[kindInfo.size] / 100 }
    if kindName == "dungeon" or kindName == "raid" then
        info.atlas = kindInfo.atlas
        info.title, info.lines = instanceTooltip(
            kindName == "raid" and L.POI_RAID or L.POI_DUNGEON, point[4])
    elseif kindName == "flight" then
        if not forPlayer(point[4]) then
            return nil
        end
        info.atlas = TAXI[point[4]]
        info.title = place(point[5])
        info.lines = { L.POI_FLIGHT_MASTER, zoneName(mapID) }
    elseif kindName == "ship" or kindName == "zeppelin" then
        if not forPlayer(point[4]) then
            return nil
        end
        info.atlas = atlasOf(kindInfo)
        info.title = format(kindName == "ship" and L.POI_SHIP_TO or L.POI_ZEPPELIN_TO,
            place(point[5]))
        info.lines = { zoneName(point[6] or mapID) }
    else
        info.atlas = atlasOf(kindInfo)
        info.title = L.POI_SPIRIT_HEALER
    end
    return info
end

-- How close (in percent of the map) an entrance the game knows is to one in Data.lua for the two
-- to be the same.
local NEAR = 3

local function listedNear(listed, x, y)
    for _, point in ipairs(listed) do
        if abs(point[2] - x) < NEAR and abs(point[3] - y) < NEAR then
            return true
        end
    end
    return false
end

-- Dungeon and raid entrances the game itself has for the map (Blizzard's own entrance list, which
-- its map hides behind a CVar), for ones Data.lua doesn't have, such as Forever's new dungeons.
-- Probe: which entrances Forever lists there is Unverified.
local function gameEntrances(mapID, listed, add)
    if not (C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap) then
        return
    end
    local db = module.db
    for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(mapID) or {}) do
        local x, y = entrance.position:GetXY()
        local raid = (entrance.atlasName or ""):lower():find("raid") ~= nil
        local kindInfo = KINDS[raid and "raid" or "dungeon"]
        if db[kindInfo.show] and not listedNear(listed, x * 100, y * 100) then
            local lines = { raid and L.POI_RAID or L.POI_DUNGEON }
            if entrance.description and entrance.description ~= "" then
                lines[2] = entrance.description
            end
            add(x, y, {
                atlas = entrance.atlasName ~= "" and entrance.atlasName or kindInfo.atlas,
                size = kindInfo.pixels * db[kindInfo.size] / 100,
                title = entrance.name,
                lines = lines,
            })
        end
    end
end

local function fill(mapID, add)
    local listed = {} -- this map's dungeons and raids in Data.lua, shown or not
    for _, point in ipairs(internal.points[mapID] or {}) do
        if point[1] == "dungeon" or point[1] == "raid" then
            listed[#listed + 1] = point
        end
        local info = pinFor(point, mapID)
        if info then
            add(point[2] / 100, point[3] / 100, info)
        end
    end
    -- A city's dungeons on the zone around it, where the city sits on that zone's map. Probe:
    -- GetMapRectOnMap returns nothing when the city isn't on it.
    for _, city in ipairs(internal.cities[mapID] or {}) do
        local minX, maxX, minY, maxY
        if C_Map and C_Map.GetMapRectOnMap then
            minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(city, mapID)
        end
        if minX then
            for _, point in ipairs(internal.points[city] or {}) do
                local info = (point[1] == "dungeon" or point[1] == "raid") and pinFor(point, city)
                if info then
                    local x = minX + (maxX - minX) * point[2] / 100
                    local y = minY + (maxY - minY) * point[3] / 100
                    listed[#listed + 1] = { point[1], x * 100, y * 100 }
                    add(x, y, info)
                end
            end
        end
    end
    gameEntrances(mapID, listed, add)
end

local layer

function module:OnEnable()
    layer = layer or ns.MapPins.New(fill)
    layer:Enable()
end

function module:OnDisable()
    layer:Disable()
end

function module:OnOptionChanged()
    if self.enabled then
        layer:Refresh()
    end
end
