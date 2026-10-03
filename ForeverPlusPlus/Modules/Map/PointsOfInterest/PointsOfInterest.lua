-- Points of Interest: icons on the world map for dungeons, raids, capital cities, flight
-- masters, boats, zeppelins, and spirit healers, each with a tooltip saying what and where it is.
-- Every kind has its own checkbox, icon size, and whether it also shows on the continent and
-- world maps, not just zone maps. Travel points of the other faction are off unless asked for.
-- Where the points are is in Data.lua, except Skyborne ley lines, saved as they're found.
local _, ns = ...

local ipairs, pairs, format, rawget, unpack, abs = ipairs, pairs, string.format, rawget, unpack,
    math.abs
local select, type, floor = select, type, math.floor
local C_Map, C_EncounterJournal, C_TaxiMap, Enum = C_Map, C_EncounterJournal, C_TaxiMap, Enum
local C_Spell, C_UnitAuras, C_Timer = C_Spell, C_UnitAuras, C_Timer
local UnitName, UnitRace, GetRealmName = UnitName, UnitRace, GetRealmName

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
    leyLines = "skyborne", -- who sees ley lines: "skyborne" (their own kind), "everyone", or "off"
    leyLineSize = 80,
    leyLinesWorld = false,
    chat = true, -- say so in chat when a ley line is saved
    -- Flight points seen learned at a flight master, by character then node ID. Data, not a
    -- setting.
    learnedNodes = {},
    -- Ley lines and elemental convergences found, by map ID: { kind, x, y } in percent. For the
    -- whole account, so every character sees what one found. Data, not a setting.
    leyLineSpots = {},
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
    -- Who sees them, so like Capital Cities there's no checkbox.
    { {
        key = "leyLines", name = L.POI_LEYLINES, description = L.POI_LEYLINES_DESC,
        choices = {
            { "skyborne", L.POI_LEYLINES_SKYBORNE },
            { "everyone", L.POI_LEYLINES_EVERYONE },
            { "off", L.POI_LEYLINES_OFF },
        },
    }, select(2, kind("leyLines", "leyLineSize")) },
    { ns.ChatOption(L.POI_CHAT_DESC) },
}) do
    for _, option in ipairs(rows) do
        module.options[#module.options + 1] = option
    end
end

module.actions = {
    {
        name = L.POI_LEYLINES_FORGET,
        button = L.POI_LEYLINES_FORGET_BUTTON,
        description = L.POI_LEYLINES_FORGET_DESC,
        confirm = L.POI_LEYLINES_FORGET_CONFIRM,
        fn = function()
            module.db.leyLineSpots = {}
            if module.enabled then
                module.internal.refresh()
            end
            ns.Print(L.POI_LEYLINES_FORGET_DONE)
        end,
    },
}

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
    -- Skyborne spots: ley lines purple, like the game's own ley line icon, convergences orange.
    -- Both are Kotmogu balls like the cyan and green ones, but Unverified on Forever.
    leyline = { show = "leyLines", size = "leyLineSize", pixels = 18,
        atlases = { "Vehicle-TempleofKotmogu-PurpleBall", "Vehicle-TempleofKotmogu-CyanBall" } },
    convergence = { show = "leyLines", size = "leyLineSize", pixels = 18,
        atlases = { "Vehicle-TempleofKotmogu-OrangeBall", "Vehicle-TempleofKotmogu-PurpleBall",
            "Vehicle-TempleofKotmogu-CyanBall" } },
}
for _, kindInfo in pairs(KINDS) do
    kindInfo.world = kindInfo.show .. "World" -- the kind's On Continent Maps checkbox
end

-- A flight master not learned yet (or not known to be): the flight point icon in its faction's
-- color, which on Forever is bronze.
local TAXI = { A = "TaxiNode_Alliance", H = "TaxiNode_Horde", N = "TaxiNode_Neutral" }

-- A learned one: the white flight master icon the minimap shows, or the faction's icon without
-- it. In Retail's atlas list; Unverified on Forever.
local learnedIcon
local function learnedAtlas(faction)
    if learnedIcon == nil then
        learnedIcon = ns.MapPins.Atlas("FlightMaster", "") ~= "" and "FlightMaster" or false
    end
    return learnedIcon or TAXI[faction]
end

local function atlasOf(kindInfo)
    if not kindInfo.atlas then
        kindInfo.atlas = ns.MapPins.Atlas(unpack(kindInfo.atlases))
    end
    return kindInfo.atlas
end

-- A place name from Data.lua, in the player's language when a locale file translates it
-- (L["Booty Bay"] = ...). Place names aren't in Locales/enUS/: the English is the name itself.
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

local MapTooltip = ns.MapTooltip

-- The lines of a tooltip from the ones given, leaving out the nils.
local function linesOf(...)
    local lines = {}
    for i = 1, select("#", ...) do
        local line = select(i, ...)
        if line then
            lines[#lines + 1] = line
        end
    end
    return lines
end

-- The tooltip of a dungeon or raid: one instance (its kind, then its level range colored against
-- the player's), or a place with several (Blackrock Mountain), a row each. Also the rows alone,
-- for a city's tooltip that takes them in.
local function instanceTooltip(kindName, key)
    local instance = internal.instances[key]
    if not instance.parts then
        local row = MapTooltip.Detail(ns.Instances.Line(instance, instanceName(instance)))
        return instanceName(instance), { kindName, MapTooltip.Detail(ns.Instances.Levels(instance)) },
            { row }
    end
    local rows = {}
    for _, partKey in ipairs(instance.parts) do
        local part = internal.instances[partKey]
        rows[#rows + 1] = MapTooltip.Detail(ns.Instances.Line(part, instanceName(part)))
    end
    return place(instance.name), rows, rows
end

-- Whether a travel point of this faction shows for the player.
local function forPlayer(faction)
    return faction == "N" or faction == ns.WorldMap.PlayerSide() or module.db.otherFaction
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

-- The flight points this character has seen as learned at a flight master, by the game's node ID
-- (names repeat: Light's Hope Chapel has one per faction, and the game's names are in the
-- player's language), saved per character. The map list above may not have them on Forever, so
-- this is the other way to know.
local function characterKey()
    return format("%s-%s", UnitName("player") or "", GetRealmName() or "")
end

local function seenLearned()
    local known = module.db.learnedNodes
    local key = characterKey()
    known[key] = known[key] or {}
    return known[key]
end

-- At a flight master, remembers which of the flight points it lists are learned, by node ID.
-- Mainline's C_TaxiMap.GetAllTaxiNodes: ones the master can't fly to are Unreachable.
local function rememberLearned()
    if not (C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and GetTaxiMapID and Enum.FlightPathState) then
        return
    end
    local seen = seenLearned()
    local mapID = GetTaxiMapID()
    for _, node in ipairs(mapID and C_TaxiMap.GetAllTaxiNodes(mapID) or {}) do
        if node.nodeID and node.state ~= Enum.FlightPathState.Unreachable then
            seen[node.nodeID] = true
        end
    end
end

-- The game's flight point for one of Data.lua's, by place: the closest on the map. The node
-- carries the ID.
local function nodeOf(point)
    local best, bestDistance
    for _, node in ipairs(taxiNodes) do
        local x, y = node.position:GetXY()
        local dx, dy = abs(x * 100 - point[2]), abs(y * 100 - point[3])
        if dx < NEAR and dy < NEAR and (not bestDistance or dx + dy < bestDistance) then
            best, bestDistance = node, dx + dy
        end
    end
    return best
end

-- Whether the character has learned the flight master at this point: true when a flight master
-- visit saw its node learned, false when the game's map list calls it undiscovered, else nil.
-- The map list can't say one is learned: on Forever (2026-09-28) it lists the whole continent
-- for a zone (36 for Silverpine) and calls ones never visited discovered.
local function learned(point)
    local node = nodeOf(point)
    if not (node and node.nodeID) then
        return nil
    end
    if seenLearned()[node.nodeID] then
        return true
    end
    if node.isUndiscovered then
        return false
    end
end

-- Whether a kind shows, on a continent map (`world`) or a zone map.
local function shows(kindInfo, world)
    local db = module.db
    local on = db[kindInfo.show]
    return (on == true or on == "ours") and (not world or db[kindInfo.world])
end

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
        info.lines = linesOf(L.POI_CAPITAL, MapTooltip.Side(city.faction))
    elseif kindName == "dungeon" or kindName == "raid" then
        info.atlas = kindInfo.atlas
        info.title, info.lines, info.rows = instanceTooltip(
            kindName == "raid" and L.POI_RAID or L.POI_DUNGEON, point[4])
    elseif kindName == "flight" then
        if not forPlayer(point[4]) then
            return nil
        end
        info.title = place(point[5])
        info.lines = linesOf(L.POI_FLIGHT_MASTER, MapTooltip.Side(point[4]),
            MapTooltip.Detail(zoneName(mapID)))
        -- Learned ones look like the minimap's; the rest keep the bronze flight point icon.
        local state = learned(point)
        if state then
            info.atlas = learnedAtlas(point[4])
        else
            info.atlas = TAXI[point[4]]
            if state == false then
                info.lines[#info.lines + 1] = MapTooltip.Note(L.POI_FLIGHT_UNLEARNED)
            end
        end
    elseif kindName == "ship" or kindName == "zeppelin" then
        if not forPlayer(point[4]) then
            return nil
        end
        info.atlas = atlasOf(kindInfo)
        info.title = format(kindName == "ship" and L.POI_SHIP_TO or L.POI_ZEPPELIN_TO,
            place(point[5]))
        info.lines = linesOf(MapTooltip.Side(point[4]), MapTooltip.Detail(zoneName(point[6] or mapID)),
            point.via and MapTooltip.Note(format(L.POI_VIA, place(point.via))))
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

-- The instances Data.lua places somewhere, by their entry in Lib/Instances.lua, once asked. The
-- rest (Forever dungeons whose entrance isn't known) are left to the game's own icons.
local placed

local function placedByUs(name)
    if not placed then
        placed = {}
        for _, points in pairs(internal.points) do
            for _, point in ipairs(points) do
                if point[1] == "dungeon" or point[1] == "raid" then
                    local instance = internal.instances[point[4]]
                    for _, key in ipairs(instance.parts or { point[4] }) do
                        local found = ns.Instances.ByName(internal.instances[key][2])
                        if found then
                            placed[found] = true
                        end
                    end
                end
            end
        end
    end
    local instance = ns.Instances.ByName(name)
    return instance ~= nil and placed[instance] == true, instance
end

-- Dungeon and raid entrances the game itself has for the map (Blizzard's own entrance list, which
-- its map hides behind a CVar), for ones Data.lua doesn't place, such as Forever's new dungeons.
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
        -- Not one Data.lua has, by place or by name: the Ruins of Lordaeron's entrance is listed
        -- on the Undercity's map, so the game's, on Tirisfal Glades, would be a second icon.
        local ours, instance = placedByUs(entrance.name)
        if db[kindInfo.show] and not listedNear(listed, x * 100, y * 100) and not ours then
            local lines = { raid and L.POI_RAID or L.POI_DUNGEON }
            if instance then
                lines[2] = MapTooltip.Detail(ns.Instances.Levels(instance))
            elseif entrance.description and entrance.description ~= "" then
                lines[2] = MapTooltip.Detail(entrance.description)
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
                for _, row in ipairs(info.rows) do
                    capital.lines[#capital.lines + 1] = row
                end
            else
                add(x, y, info)
            end
        end
    end
    if cx then
        add(cx, cy, capital)
    end
end

-- Ley lines -----------------------------------------------------------------------------------
-- Skyborne racials: High Order Skyborne (Alliance) cast Read Ley Line on a ley line, Windshapers
-- (Horde) cast Skysight on an elemental convergence, and get a 15-minute buff there instead of a
-- few seconds. The server places them: the client's tables don't have them and Wowhead lists them
-- without a place (2026-10-03, build 70205). So a spot is saved where a cast gave the long buff.

-- Each kind: the cast, the spell whose name the buff has, and the side whose Skyborne use it.
-- From the client's SpellName, SpellMisc, and SpellEffect tables (wago.tools, build 70205).
local SKYBORNE = {
    leyline = { cast = 1259705, buff = 1259691, side = "A" }, -- Read Ley Line, Energized
    convergence = { cast = 1259686, buff = 1259688, side = "H" }, -- Skysight, Elemental Blessing
}

-- The kind each Skyborne race uses, by race ID (ChrRaces): 95 High Order, 96 Windshaper.
local RACES = { [95] = "leyline", [96] = "convergence" }

local function spellName(id)
    return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or nil
end

-- The kind this character uses, or nil when it isn't Skyborne.
local function ownKind()
    local _, raceFile, raceID = UnitRace("player")
    if RACES[raceID] then
        return RACES[raceID]
    end
    if raceFile == "Skyborne" then
        return ns.WorldMap.PlayerSide() == "H" and "convergence" or "leyline"
    end
end

-- Whether saved spots of this kind show, on a continent map (`world`) or a zone map.
local function showsSpot(kindName, world)
    local db = module.db
    if db.leyLines == "off" or (world and not db.leyLinesWorld) then
        return false
    end
    return db.leyLines == "everyone" or kindName == ownKind()
end

local function spotInfo(kindName, fromMap)
    local kindInfo, skyborne = KINDS[kindName], SKYBORNE[kindName]
    local cast = spellName(skyborne.cast)
    return {
        atlas = atlasOf(kindInfo),
        size = kindInfo.pixels * module.db[kindInfo.size] / 100,
        title = kindName == "leyline" and L.POI_LEYLINE or L.POI_CONVERGENCE,
        lines = linesOf(MapTooltip.Side(skyborne.side), MapTooltip.Detail(zoneName(fromMap)),
            cast and MapTooltip.Note(format(L.POI_LEYLINE_CAST, cast))),
    }
end

-- The saved spots that fall on the map being drawn, from whichever map each was saved on.
local function addSpots(mapID, world, add)
    for fromMap, spots in pairs(module.db.leyLineSpots) do
        for _, spot in ipairs(spots) do
            if SKYBORNE[spot[1]] and showsSpot(spot[1], world) then
                local x, y = spot[2] / 100, spot[3] / 100
                if fromMap ~= mapID then
                    x, y = translate(fromMap, mapID, x, y)
                end
                if x then
                    add(x, y, spotInfo(spot[1], fromMap))
                end
            end
        end
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
    addSpots(mapID, false, add)
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
    addSpots(mapID, true, add)
end

local function isContinent(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return ns.WorldMap.IsContinent(info)
end

local function fill(mapID, add)
    if isContinent(mapID) then
        fillContinent(mapID, add)
    else
        fillZone(mapID, add)
    end
end

-- Blizzard's own icons ------------------------------------------------------------------------
-- Blizzard marks the capitals on continent maps, and may mark dungeon entrances anywhere, with
-- pins of its own. Wherever ours show for the same place, theirs are hidden so there's one icon,
-- not two (Undercity's, and the Ruins of Lordaeron's beside it). Capital Cities set to Off hides
-- Blizzard's too, like Leatrix Maps' Hide Town and City Icons, but told apart by the name
-- instead of the icon's place in its texture.

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
    return cityNames[name] == true or cityNames[(name:gsub("^[Tt]he ", ""))] == true
end

-- Whether ours replace Blizzard's pin with this name on the map now: a city's (ours, or none at
-- all), or a dungeon's or raid's, where its kind shows. Ours show on zone maps whenever their
-- checkbox is on, and on continents with On Continent Maps.
local function hidesBlizzard(mapID, name)
    if not module.enabled then
        return false
    end
    local db, world = module.db, isContinent(mapID)
    if isCity(name) then
        return db.capitals == "off" or (db.capitals == "ours" and (not world or db.capitalsWorld))
    end
    local ours, instance = placedByUs(name)
    if not instance then
        return false
    end
    local kindInfo = KINDS[instance[5] and "raid" or "dungeon"]
    if ours then
        return shows(kindInfo, world) and true or false
    end
    -- One we don't place: gameEntrances draws it on zone maps, and on a continent the game's icon
    -- is the only one.
    return not world and shows(kindInfo) and true or false
end

-- After the world map acquires a pin of its own. The pin is hidden, not faded, so its tooltip
-- goes too; the map shows it again when it reuses the pin.
local BLIZZARD_TEMPLATES = { AreaPOIPinTemplate = true, DungeonEntrancePinTemplate = true }

local function onAcquire(map, template, poiInfo)
    if not BLIZZARD_TEMPLATES[template] or type(poiInfo) ~= "table" or type(poiInfo.name) ~= "string"
        or not hidesBlizzard(map:GetMapID(), poiInfo.name) then
        return
    end
    for pin in map:EnumeratePinsByTemplate(template) do
        if pin.poiInfo == poiInfo or pin.dungeonEntranceInfo == poiInfo or pin.name == poiInfo.name then
            pin:Hide()
        end
    end
end

local layer

-- Saving ley lines ----------------------------------------------------------------------------

-- How close (in percent of the map) a spot is to a saved one of its kind to be the same.
local SAME_SPOT = 2

-- A buff at least this long (seconds) is the one a spot gives; elsewhere it's 15 or 30 seconds.
local LONG = 600

-- Whether the player has the long buff of this kind, found by its name: the 15-minute Energized
-- is in the client's tables, the 15-minute Elemental Blessing isn't (only the 30-second one), so
-- that one is assumed to share the name. Unverified in game. Secret aura fields count as no.
local function hasLongBuff(kindName)
    local name = spellName(SKYBORNE[kindName].buff)
    if not (name and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
        return false
    end
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then
            return false
        end
        local auraName, duration = aura.name, aura.duration
        if ns.IsReadable(auraName) and ns.IsReadable(duration) and auraName == name
            and duration and duration >= LONG then
            return true
        end
    end
    return false
end

-- After a cast: when it gave the long buff, saves where the player stands, unless a spot of the
-- kind is already saved there.
local function saveSpot(kindName)
    if not (module.enabled and hasLongBuff(kindName)) then
        return
    end
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local position = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        return
    end
    local x, y = position:GetXY()
    if not (ns.IsReadable(x) and ns.IsReadable(y) and x and y) then
        return
    end
    x, y = floor(x * 1000 + 0.5) / 10, floor(y * 1000 + 0.5) / 10
    local all = module.db.leyLineSpots
    local spots = all[mapID] or {}
    for _, spot in ipairs(spots) do
        if spot[1] == kindName and abs(spot[2] - x) < SAME_SPOT and abs(spot[3] - y) < SAME_SPOT then
            return
        end
    end
    spots[#spots + 1] = { kindName, x, y }
    all[mapID] = spots
    module:Print(format(kindName == "leyline" and L.POI_LEYLINE_SAVED or L.POI_CONVERGENCE_SAVED,
        zoneName(mapID)))
    layer:Refresh()
end

local function onCast(_, unit, _, spellID)
    if not (ns.IsReadable(unit) and ns.IsReadable(spellID)) or unit ~= "player" then
        return
    end
    for kindName, skyborne in pairs(SKYBORNE) do
        if spellID == skyborne.cast then
            -- The buff lands after the cast; give the server a moment.
            C_Timer.After(1, function() saveSpot(kindName) end)
        end
    end
end

internal.refresh = function()
    layer:Refresh()
end

function module:OnEnable()
    layer = layer or ns.MapPins.New(fill)
    layer:Enable()
    ns.MapPins.OnAcquire(onAcquire)
    ns.MapPins.RefreshMap() -- hide Blizzard's city icons already on it
    -- A flight master's map: which flight points are learned, and new ones learned there.
    self:On("TAXIMAP_OPENED", rememberLearned)
    self:On("TAXIMAP_CLOSED", function() layer:Refresh() end)
    -- Only Skyborne can find ley lines.
    if ownKind() then
        self:On("UNIT_SPELLCAST_SUCCEEDED", onCast)
    end
end

function module:OnDisable()
    layer:Disable()
    ns.MapPins.RefreshMap() -- Blizzard's city icons back
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key:find("^capital") or key:find("^dungeon") or key:find("^raid") then
        ns.MapPins.RefreshMap() -- ours and Blizzard's, both redrawn
    else
        layer:Refresh()
    end
end
