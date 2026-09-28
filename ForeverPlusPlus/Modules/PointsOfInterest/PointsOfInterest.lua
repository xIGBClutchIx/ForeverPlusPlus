-- Points of Interest: icons on the world map for dungeons, raids, capital cities, flight
-- masters, boats, zeppelins, and spirit healers, each with a tooltip saying what and where it is.
-- Every kind has its own checkbox, icon size, and whether it also shows on the continent and
-- world maps, not just zone maps. Travel points of the other faction are off unless asked for.
-- Where the points are is in Data.lua.
local _, ns = ...

local ipairs, pairs, format, rawget, unpack, abs = ipairs, pairs, string.format, rawget, unpack,
    math.abs
local select, type = select, type
local C_Map, C_EncounterJournal, C_TaxiMap, UnitFactionGroup, UnitLevel =
    C_Map, C_EncounterJournal, C_TaxiMap, UnitFactionGroup, UnitLevel
local GetQuestDifficultyColor = GetQuestDifficultyColor
local QuestDifficultyColors, Enum = QuestDifficultyColors, Enum

local L = ns.L

local module = ns.NewModule("PointsOfInterest", L.POI_DESC, {
    enabled = true,
    -- For each kind: shown, its size in percent of normal, and shown on continent maps too.
    dungeons = true,
    dungeonSize = 90,
    dungeonsWorld = true,
    raids = true,
    raidSize = 80,
    raidsWorld = true,
    capitals = "ours", -- "ours" (and Blizzard's city icons hidden), "blizzard", or "off"
    capitalSize = 50,
    capitalsWorld = true,
    flightMasters = true,
    flightSize = 80,
    flightMastersWorld = false,
    ships = true,
    shipSize = 80,
    shipsWorld = false,
    zeppelins = true,
    zeppelinSize = 80,
    zeppelinsWorld = false,
    spiritHealers = true,
    spiritSize = 70,
    spiritHealersWorld = false,
    otherFaction = false, -- also the other faction's flight masters, boats, and zeppelins
})
module.title = L.POI_TITLE
module.category = "map"

-- Shared with Data.lua: `points` (by map ID), `instances` (by key), and `cities` (by map ID).
module.internal = {}
local internal = module.internal

-- A checkbox for a kind with the slider for its size in the same row, and under it whether it
-- shows on continents.
local function kind(key, sizeKey, name, description)
    return { key = key, name = name, description = description, slider = sizeKey },
        {
            key = sizeKey, name = L.POI_SIZE, description = L.POI_SIZE_DESC, requires = key,
            min = 50, max = 200, step = 10, format = "%d%%",
        },
        { key = key .. "World", name = L.POI_WORLD, description = L.POI_WORLD_DESC, requires = key }
end

module.options = {}
for _, rows in ipairs({
    { kind("dungeons", "dungeonSize", L.POI_DUNGEONS, L.POI_DUNGEONS_DESC) },
    { kind("raids", "raidSize", L.POI_RAIDS, L.POI_RAIDS_DESC) },
    -- Ours, Blizzard's, or none: ours hide Blizzard's city icons, so there's no checkbox.
    { {
        key = "capitals", name = L.POI_CAPITALS, description = L.POI_CAPITALS_DESC,
        choices = {
            { "ours", L.POI_CAPITALS_OURS },
            { "blizzard", L.POI_CAPITALS_BLIZZARD },
            { "off", L.POI_CAPITALS_OFF },
        },
    }, select(2, kind("capitals", "capitalSize")) },
    { kind("flightMasters", "flightSize", L.POI_FLIGHT, L.POI_FLIGHT_DESC) },
    { kind("ships", "shipSize", L.POI_SHIPS, L.POI_SHIPS_DESC) },
    { kind("zeppelins", "zeppelinSize", L.POI_ZEPPELINS, L.POI_ZEPPELINS_DESC) },
    -- After the travel points it's about.
    { { key = "otherFaction", name = L.POI_OTHER_FACTION, description = L.POI_OTHER_FACTION_DESC } },
    { kind("spiritHealers", "spiritSize", L.POI_SPIRIT, L.POI_SPIRIT_DESC) },
}) do
    for _, option in ipairs(rows) do
        module.options[#module.options + 1] = option
    end
end

-- Each kind of point: the checkbox, size, and continent settings for it, its normal size in
-- pixels, and its icon. The boat, zeppelin, graveyard, and town icons are in Retail's atlas list,
-- but not confirmed on Forever, so the first the client has is chosen the first time the map
-- draws; the plain colored balls after them are ones Leatrix Maps uses on Forever.
local KINDS = {
    dungeon = { show = "dungeons", size = "dungeonSize", pixels = 24, atlas = "Dungeon" },
    raid = { show = "raids", size = "raidSize", pixels = 24, atlas = "Raid" },
    capital = { show = "capitals", size = "capitalSize", pixels = 28,
        atlases = { "poi-town", "Vehicle-TempleofKotmogu-PurpleBall" } },
    flight = { show = "flightMasters", size = "flightSize", pixels = 18 },
    ship = { show = "ships", size = "shipSize", pixels = 22,
        atlases = { "FlightMasterFerry", "Vehicle-TempleofKotmogu-CyanBall" } },
    zeppelin = { show = "zeppelins", size = "zeppelinSize", pixels = 24,
        atlases = { "Vehicle-Air-Horde", "Vehicle-TempleofKotmogu-CyanBall" } },
    spirit = { show = "spiritHealers", size = "spiritSize", pixels = 20,
        atlases = { "poi-graveyard-neutral", "Vehicle-TempleofKotmogu-GreenBall" } },
}
for _, kindInfo in pairs(KINDS) do
    kindInfo.world = kindInfo.show .. "World" -- the kind's On Continent Maps checkbox
end

-- The flight master icon in each faction's color.
local TAXI = { A = "TaxiNode_Alliance", H = "TaxiNode_Horde", N = "TaxiNode_Neutral" }

local GRAY = ns.Colors.Code(unpack(ns.Colors.GRAY))

-- Blizzard's gray icon for a flight point not learned yet, or nil without it (the faction's icon
-- is then shown grayed out). In Retail's atlas list; Unverified on Forever.
local unlearned
local function unlearnedAtlas()
    if unlearned == nil then
        unlearned = ns.MapPins.Atlas("TaxiNode_Undiscovered", "") ~= "" and "TaxiNode_Undiscovered"
            or false
    end
    return unlearned or nil
end

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

-- An instance's name in the player's language, and which entrance it is.
local function instanceName(instance)
    local name = ns.Instances.Name(instance)
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

-- How close (in percent of the map) a point the game knows is to one in Data.lua for the two to
-- be the same.
local NEAR = 3

-- The game's flight points on the map being drawn, with whether this character has learned each.
-- Probe: Forever's world map doesn't show them, so whether it lists them is Unverified.
local taxiNodes = {}

local function readTaxiNodes(mapID)
    taxiNodes = C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap
        and C_TaxiMap.GetTaxiNodesForMap(mapID) or {}
end

-- Whether the character has learned the flight master at this point: true, false, or nil when
-- the game doesn't say.
local function learned(point)
    for _, node in ipairs(taxiNodes) do
        local x, y = node.position:GetXY()
        if abs(x * 100 - point[2]) < NEAR and abs(y * 100 - point[3]) < NEAR then
            return not node.isUndiscovered
        end
    end
end

-- Whether a kind shows, on a continent map (`world`) or a zone map.
local function shows(kindInfo, world)
    local db = module.db
    local on = db[kindInfo.show]
    return (on == true or on == "ours") and (not world or db[kindInfo.world])
end

local FACTION_NAMES = { A = FACTION_ALLIANCE, H = FACTION_HORDE }

-- The pin for one point of Data.lua on the map `mapID` it's listed for, or nil when its settings
-- hide it. `world` when it's being drawn on a continent map.
local function pinFor(point, mapID, world)
    local kindName = point[1]
    local kindInfo = KINDS[kindName]
    local db = module.db
    -- A place with dungeons and raids (Blackrock Mountain) shows with either.
    local mixed = kindName == "dungeon" and internal.instances[point[4]].raids
    if not (shows(kindInfo, world) or (mixed and shows(KINDS.raid, world))) then
        return nil
    end
    local info = { size = kindInfo.pixels * db[kindInfo.size] / 100 }
    if kindName == "capital" then
        local city = internal.cities[point[4]]
        info.atlas = atlasOf(kindInfo)
        info.title = zoneName(point[4])
        info.lines = { L.POI_CAPITAL, FACTION_NAMES[city.faction] }
    elseif kindName == "dungeon" or kindName == "raid" then
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
        -- One not learned yet is gray, like Blizzard's undiscovered flight points.
        if learned(point) == false then
            local gray = unlearnedAtlas()
            info.atlas = gray or info.atlas
            info.desaturated = not gray
            info.lines[#info.lines + 1] = GRAY .. L.POI_FLIGHT_UNLEARNED .. "|r"
        end
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

-- A point on one map (0 to 1) as a point on another that shows it: a city on its zone, or a zone
-- or city on a continent. For a city the game can't place, the place Data.lua gives it on its
-- zone.
local function translate(fromMap, toMap, x, y)
    local tx, ty = ns.MapPins.Translate(fromMap, toMap, x, y)
    local city = internal.cities[fromMap]
    if tx or not (city and city.rect) then
        return tx, ty
    end
    local rect = city.rect
    x, y = rect[1] + (rect[2] - rect[1]) * x, rect[3] + (rect[4] - rect[3]) * y
    if city.zone == toMap then
        return x, y
    end
    return ns.MapPins.Translate(city.zone, toMap, x, y)
end

-- A capital's icon, in the middle of its own map.
local function capitalPoint(cityMap)
    return { "capital", 50, 50, cityMap }
end

-- A point listed for `fromMap`, drawn on `mapID`.
local function addFrom(fromMap, mapID, point, world, add)
    local info = pinFor(point, fromMap, world)
    if not info then
        return
    end
    local x, y = translate(fromMap, mapID, point[2] / 100, point[3] / 100)
    if x then
        add(x, y, info)
    end
end

local function isInstance(point)
    return point[1] == "dungeon" or point[1] == "raid"
end

-- How close (in percent of the map) a city's dungeon is to the city's own icon for the dungeon to
-- go in the city's tooltip instead of on top of it (the Hall of Thanes under Ironforge).
local MERGE = 2

-- A capital's icon and its dungeons, on a map outside the city.
local function addCity(cityMap, mapID, world, add, listed)
    local capital = pinFor(capitalPoint(cityMap), cityMap, world)
    local cx, cy
    if capital then
        cx, cy = translate(cityMap, mapID, 0.5, 0.5)
    end
    for _, point in ipairs(internal.points[cityMap] or {}) do
        local info = isInstance(point) and pinFor(point, cityMap, world)
        local x, y
        if info then
            x, y = translate(cityMap, mapID, point[2] / 100, point[3] / 100)
        end
        if x then
            if listed then
                listed[#listed + 1] = { point[1], x * 100, y * 100 }
            end
            if cx and abs(x - cx) * 100 < MERGE and abs(y - cy) * 100 < MERGE then
                capital.lines[#capital.lines + 1] =
                    format("%s  %s", info.title, info.lines[#info.lines])
            else
                add(x, y, info)
            end
        end
    end
    if cx then
        add(cx, cy, capital)
    end
end

-- A zone map: its own points, and the capitals in it with their dungeons.
local function fillZone(mapID, add)
    readTaxiNodes(mapID)
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
    for cityMap, city in pairs(internal.cities) do
        if city.zone == mapID then
            addCity(cityMap, mapID, false, add, listed)
        end
    end
    gameEntrances(mapID, listed, add)
end

-- A continent or world map: every kind whose On Continent Maps is on, from every zone and city
-- the game can place on it.
local function fillContinent(mapID, add)
    local flights = shows(KINDS.flight, true)
    for fromMap, points in pairs(internal.points) do
        if flights then
            readTaxiNodes(fromMap)
        end
        for _, point in ipairs(points) do
            -- A city's dungeons come with the city, below.
            if not (internal.cities[fromMap] and isInstance(point)) then
                addFrom(fromMap, mapID, point, true, add)
            end
        end
    end
    for cityMap in pairs(internal.cities) do
        addCity(cityMap, mapID, true, add)
    end
end

local function isContinent(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local types = Enum and Enum.UIMapType
    return info and types and (info.mapType == types.Continent or info.mapType == types.World)
end

local function fill(mapID, add)
    if isContinent(mapID) then
        fillContinent(mapID, add)
    else
        fillZone(mapID, add)
    end
end

-- Blizzard's city icons -----------------------------------------------------------------------
-- Blizzard marks the capitals on continent maps with area POIs. With Capital Cities set to Off,
-- or to ours on continent maps, they're hidden, like Leatrix Maps' Hide Town and City Icons, but
-- told apart by the city's name instead of the icon's place in its texture.

local cityNames

local function isCity(name)
    if not cityNames then
        cityNames = {}
        for cityMap in pairs(internal.cities) do
            local cityName = zoneName(cityMap)
            if cityName ~= "" then
                cityNames[cityName] = true
                cityNames[(cityName:gsub(" City$", ""))] = true -- "Stormwind City" as "Stormwind"
            end
        end
    end
    return cityNames[name] == true
end

-- After the world map acquires a pin of its own. The pin is hidden, not faded, so its tooltip
-- goes too; the map shows it again when it reuses the pin.
local function hidesBlizzard()
    local db = module.db
    -- Ours replace them only where ours show: on continents, with On Continent Maps.
    return module.enabled and (db.capitals == "off" or (db.capitals == "ours" and db.capitalsWorld))
end

local function onAcquire(map, template, poiInfo)
    if not hidesBlizzard() or template ~= "AreaPOIPinTemplate" or type(poiInfo) ~= "table"
        or not isCity(poiInfo.name) then
        return
    end
    for pin in map:EnumeratePinsByTemplate(template) do
        if pin.poiInfo == poiInfo then
            pin:Hide()
        end
    end
end

local layer
local hooked = false

function module:OnEnable()
    layer = layer or ns.MapPins.New(fill)
    layer:Enable()
    if not hooked then
        hooked = true
        ns.MapPins.OnAcquire(onAcquire)
    end
    ns.MapPins.RefreshMap() -- hide Blizzard's city icons already on it
    -- A flight master's map, where a new flight point is learned.
    self:On("TAXIMAP_CLOSED", function() layer:Refresh() end)
end

function module:OnDisable()
    layer:Disable()
    ns.MapPins.RefreshMap() -- Blizzard's city icons back
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "capitals" or key == "capitalsWorld" then
        ns.MapPins.RefreshMap() -- ours and Blizzard's, both redrawn
    else
        layer:Refresh()
    end
end
