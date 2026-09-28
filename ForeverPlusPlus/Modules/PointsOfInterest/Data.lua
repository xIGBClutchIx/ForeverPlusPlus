-- Where Points of Interest puts its icons, by zone map ID. Coordinates are percent across and
-- down the zone map, as the game's /way coordinates. Leatrix Maps' point list was the reference
-- for them. Each point is one of:
--   { "dungeon" or "raid", x, y, instance key }
--   { "flight", x, y, faction, place }
--   { "ship" or "zeppelin", x, y, faction, destination place, destination map ID (or this map) }
--   { "spirit", x, y }
-- Factions are "A" (Alliance), "H" (Horde), and "N" (both). Places are English; a locale file can
-- translate one with L["Booty Bay"] = "...". Dungeons the game's own entrance list has and this
-- list doesn't (Forever's new ones) are added from the game; see gameEntrances.
local _, ns = ...

local L = ns.L

local internal = ns.modules.PointsOfInterest.internal

-- Dungeons and raids: instance ID (the game names it in the player's language), English name if
-- it can't, and level range. `part` tells apart entrances of one instance. A place with several
-- instances lists them in `parts`, and `raids` when some are raids.
internal.instances = {
    ahnqiraj = { name = "Ahn'Qiraj", parts = { "aq20", "aq40" } },
    aq20 = { 509, "Ruins of Ahn'Qiraj", 60, 60 },
    aq40 = { 531, "Temple of Ahn'Qiraj", 60, 60 },
    blackfathom = { 48, "Blackfathom Deeps", 24, 32 },
    blackrock = { name = "Blackrock Mountain", parts = { "brd", "brs", "mc", "bwl" }, raids = true },
    brd = { 230, "Blackrock Depths", 52, 60 },
    brs = { 229, "Blackrock Spire", 55, 60 },
    bwl = { 469, "Blackwing Lair", 60, 60 },
    deadmines = { 36, "The Deadmines", 17, 26 },
    diremaulEast = { 429, "Dire Maul", 56, 60, part = L.POI_EAST },
    diremaulNorth = { 429, "Dire Maul", 56, 60, part = L.POI_NORTH },
    diremaulWest = { 429, "Dire Maul", 56, 60, part = L.POI_WEST },
    gnomeregan = { 90, "Gnomeregan", 29, 38 },
    -- Forever's. Its instance ID isn't known yet, so the name is the English one.
    hallOfThanes = { nil, "The Hall of Thanes", 13, 18 },
    maraudon = { 349, "Maraudon", 46, 55 },
    mc = { 409, "Molten Core", 60, 60 },
    naxxramas = { 533, "Naxxramas", 60, 60 },
    onyxia = { 249, "Onyxia's Lair", 60, 60 },
    ragefire = { 389, "Ragefire Chasm", 13, 18 },
    razorfenDowns = { 129, "Razorfen Downs", 37, 46 },
    razorfenKraul = { 47, "Razorfen Kraul", 29, 38 },
    scarlet = { 189, "Scarlet Monastery", 34, 45 },
    scholomance = { 289, "Scholomance", 58, 60 },
    shadowfang = { 33, "Shadowfang Keep", 22, 30 },
    stockade = { 34, "The Stockade", 22, 30 },
    stratholmeMain = { 329, "Stratholme", 58, 60, part = L.POI_MAIN_GATE },
    stratholmeService = { 329, "Stratholme", 58, 60, part = L.POI_SERVICE_GATE },
    sunkenTemple = { 109, "The Temple of Atal'Hakkar", 50, 60 },
    uldaman = { 70, "Uldaman", 41, 51 },
    wailing = { 43, "Wailing Caverns", 17, 24 },
    zulfarrak = { 209, "Zul'Farrak", 44, 54 },
    zulgurub = { 309, "Zul'Gurub", 60, 60 },
}

internal.points = {
    -- Eastern Kingdoms -------------------------------------------------------------------------
    [1416] = { -- Alterac Mountains
        { "spirit", 42.9, 38.0 },
    },
    [1417] = { -- Arathi Highlands
        { "flight", 45.8, 46.1, "A", "Refuge Pointe" },
        { "flight", 73.1, 32.7, "H", "Hammerfall" },
        { "spirit", 48.8, 55.6 },
    },
    [1418] = { -- Badlands
        { "dungeon", 44.6, 12.1, "uldaman" },
        { "flight", 4.0, 44.8, "H", "Kargath" },
        { "spirit", 56.7, 23.7 },
        { "spirit", 8.4, 55.3 },
    },
    [1419] = { -- Blasted Lands
        { "flight", 65.4, 24.4, "A", "Nethergarde Keep" },
        { "spirit", 51.0, 12.2 },
    },
    [1420] = { -- Tirisfal Glades
        { "dungeon", 82.6, 33.8, "scarlet" },
        { "zeppelin", 60.7, 58.8, "H", "Orgrimmar", 1411 },
        { "zeppelin", 61.9, 59.1, "H", "Grom'gol Base Camp", 1434 },
        { "spirit", 30.8, 64.9 },
        { "spirit", 56.2, 49.4 },
        { "spirit", 79.0, 41.0 },
        { "spirit", 62.3, 67.0 },
        { "spirit", 82.0, 69.6 },
    },
    [1421] = { -- Silverpine Forest
        { "dungeon", 44.8, 67.8, "shadowfang" },
        { "flight", 45.6, 42.6, "H", "The Sepulcher" },
        { "spirit", 44.1, 42.5 },
        { "spirit", 55.6, 73.2 },
    },
    [1422] = { -- Western Plaguelands
        { "dungeon", 69.7, 73.2, "scholomance" },
        { "flight", 42.9, 85.1, "A", "Chillwind Camp" },
        { "spirit", 59.7, 53.2 },
        { "spirit", 65.8, 74.2 },
        { "spirit", 45.0, 86.0 },
    },
    [1423] = { -- Eastern Plaguelands
        { "dungeon", 27.8, 11.6, "stratholmeMain" },
        { "dungeon", 43.6, 19.5, "stratholmeService" },
        { "raid", 33.7, 20.7, "naxxramas" },
        { "flight", 81.6, 59.2, "A", "Light's Hope Chapel" },
        { "flight", 80.2, 57.0, "H", "Light's Hope Chapel" },
        { "spirit", 47.2, 44.2 },
        { "spirit", 38.2, 70.4 },
        { "spirit", 39.0, 92.4 },
        { "spirit", 80.0, 64.4 },
    },
    [1424] = { -- Hillsbrad Foothills
        { "flight", 49.3, 52.3, "A", "Southshore" },
        { "flight", 60.1, 18.6, "H", "Tarren Mill" },
        { "spirit", 64.5, 19.7 },
        { "spirit", 51.8, 52.5 },
    },
    [1425] = { -- The Hinterlands
        { "flight", 11.1, 46.2, "A", "Aerie Peak" },
        { "flight", 81.7, 81.8, "H", "Revantusk Village" },
        { "spirit", 16.9, 44.5 },
        { "spirit", 73.1, 68.2 },
    },
    [1426] = { -- Dun Morogh
        { "dungeon", 24.3, 39.8, "gnomeregan" },
        { "spirit", 30.0, 69.5 },
        { "spirit", 47.3, 54.6 },
        { "spirit", 54.4, 39.2 },
    },
    [1427] = { -- Searing Gorge
        { "dungeon", 34.8, 85.3, "blackrock" },
        { "flight", 37.9, 30.8, "A", "Thorium Point" },
        { "flight", 34.8, 30.9, "H", "Thorium Point" },
        { "spirit", 35.5, 22.8 },
        { "spirit", 54.4, 51.3 },
    },
    [1428] = { -- Burning Steppes
        { "dungeon", 29.4, 38.3, "blackrock" },
        { "flight", 84.3, 68.3, "A", "Morgan's Vigil" },
        { "flight", 65.7, 24.2, "H", "Flame Crest" },
        { "spirit", 64.1, 24.1 },
    },
    [1429] = { -- Elwynn Forest
        { "spirit", 39.5, 60.5 },
        { "spirit", 49.7, 42.5 },
        { "spirit", 83.6, 69.8 },
    },
    [1430] = { -- Deadwind Pass
        { "spirit", 40.0, 74.2 },
    },
    [1431] = { -- Duskwood
        { "flight", 77.5, 44.3, "A", "Darkshire" },
        { "spirit", 20.0, 49.2 },
        { "spirit", 75.1, 59.0 },
    },
    [1432] = { -- Loch Modan
        { "flight", 33.9, 50.9, "A", "Thelsamar" },
        { "spirit", 32.6, 47.0 },
    },
    [1433] = { -- Redridge Mountains
        { "flight", 25.5, 59.4, "A", "Lake Everstill" },
    },
    [1434] = { -- Stranglethorn Vale
        { "raid", 53.9, 17.6, "zulgurub" },
        { "flight", 27.5, 77.8, "A", "Booty Bay" },
        { "flight", 26.9, 77.1, "H", "Booty Bay" },
        { "flight", 32.5, 29.4, "H", "Grom'gol Base Camp" },
        { "ship", 25.9, 73.1, "N", "Ratchet", 1413 },
        { "zeppelin", 31.4, 30.2, "H", "Orgrimmar", 1411 },
        { "zeppelin", 31.6, 29.1, "H", "Undercity", 1420 },
        { "spirit", 38.4, 9.0 },
        { "spirit", 30.4, 73.3 },
    },
    [1435] = { -- Swamp of Sorrows
        { "dungeon", 69.9, 53.6, "sunkenTemple" },
        { "flight", 46.1, 54.8, "H", "Stonard" },
        { "spirit", 50.3, 62.4 },
    },
    [1436] = { -- Westfall
        { "dungeon", 42.5, 71.7, "deadmines" },
        { "flight", 56.6, 52.6, "A", "Sentinel Hill" },
        { "spirit", 51.7, 49.7 },
    },
    [1437] = { -- Wetlands
        { "flight", 9.5, 59.7, "A", "Menethil Harbor" },
        { "ship", 5.0, 63.5, "A", "Theramore Isle", 1445 },
        { "ship", 4.6, 57.1, "A", "Auberdine", 1439 },
        { "spirit", 11.0, 43.8 },
        { "spirit", 49.3, 41.8 },
    },
    [1453] = { -- Stormwind City
        { "dungeon", 52.4, 70.0, "stockade" },
        { "flight", 70.9, 72.5, "A", "Trade District" },
    },
    [1455] = { -- Ironforge
        -- The webbed stairs down, left of the High Seat. From Warcraft Tavern's and Wowhead
        -- commenters' coordinates (43.5, 52.0 and 43, 51), not checked in game.
        { "dungeon", 43.5, 52.0, "hallOfThanes" },
        { "flight", 55.5, 47.8, "A", "The Great Forge" },
    },
    [1458] = { -- Undercity
        { "flight", 63.3, 48.5, "H", "Trade Quarter" },
        { "spirit", 67.9, 14.0 },
    },

    -- Kalimdor ---------------------------------------------------------------------------------
    [1411] = { -- Durotar
        { "zeppelin", 50.9, 13.9, "H", "Undercity", 1420 },
        { "zeppelin", 50.6, 12.6, "H", "Grom'gol Base Camp", 1434 },
        { "spirit", 47.4, 17.9 },
        { "spirit", 53.5, 44.5 },
        { "spirit", 44.2, 69.4 },
        { "spirit", 57.2, 73.3 },
    },
    [1413] = { -- The Barrens
        { "dungeon", 46.0, 36.4, "wailing" },
        { "dungeon", 42.9, 90.2, "razorfenKraul" },
        { "dungeon", 49.0, 93.9, "razorfenDowns" },
        { "flight", 63.1, 37.2, "N", "Ratchet" },
        { "flight", 51.5, 30.3, "H", "The Crossroads" },
        { "flight", 44.4, 59.2, "H", "Camp Taurajo" },
        { "ship", 63.7, 38.6, "N", "Booty Bay", 1434 },
        { "spirit", 50.7, 32.6 },
        { "spirit", 60.2, 39.7 },
        { "spirit", 45.3, 61.0 },
        { "spirit", 45.8, 82.7 },
    },
    [1438] = { -- Teldrassil
        { "flight", 58.4, 94.0, "A", "Rut'theran Village" },
        { "ship", 54.9, 96.8, "A", "Auberdine", 1439 },
        { "spirit", 58.7, 42.3 },
        { "spirit", 56.2, 63.3 },
    },
    [1439] = { -- Darkshore
        { "flight", 36.3, 45.6, "A", "Auberdine" },
        { "ship", 32.4, 43.8, "A", "Menethil Harbor", 1437 },
        { "ship", 33.2, 40.1, "A", "Rut'theran Village", 1438 },
        { "spirit", 41.8, 36.6 },
        { "spirit", 43.6, 92.4 },
    },
    [1440] = { -- Ashenvale
        { "dungeon", 14.5, 14.2, "blackfathom" },
        { "flight", 34.4, 48.0, "A", "Astranaar" },
        { "flight", 73.2, 61.6, "H", "Splintertree Post" },
        { "flight", 12.2, 33.8, "H", "Zoram'gar Outpost" },
        { "spirit", 40.5, 52.8 },
        { "spirit", 80.7, 58.4 },
    },
    [1441] = { -- Thousand Needles
        { "flight", 45.1, 49.1, "H", "Freewind Post" },
        { "spirit", 30.6, 23.0 },
        { "spirit", 68.7, 53.3 },
    },
    [1442] = { -- Stonetalon Mountains
        { "flight", 36.4, 7.2, "A", "Stonetalon Peak" },
        { "flight", 45.1, 59.8, "H", "Sun Rock Retreat" },
        { "spirit", 40.3, 5.6 },
        { "spirit", 36.4, 75.2 },
        { "spirit", 57.5, 61.3 },
    },
    [1443] = { -- Desolace
        { "dungeon", 29.1, 62.5, "maraudon" },
        { "flight", 64.7, 10.5, "A", "Nijel's Point" },
        { "flight", 21.6, 74.1, "H", "Shadowprey Village" },
        { "spirit", 50.4, 62.9 },
    },
    [1444] = { -- Feralas
        { "dungeon", 62.5, 24.9, "diremaulNorth" },
        { "dungeon", 60.3, 30.2, "diremaulWest" },
        { "dungeon", 64.8, 30.2, "diremaulEast" },
        { "flight", 30.2, 43.2, "A", "Feathermoon Stronghold" },
        { "flight", 75.4, 44.4, "H", "Camp Mojache" },
        { "flight", 89.5, 45.9, "A", "Thalanaar" },
        { "ship", 43.3, 42.8, "A", "Feathermoon Stronghold" },
        { "ship", 31.0, 39.8, "A", "The Forgotten Coast" },
        { "spirit", 31.8, 48.2 },
        { "spirit", 54.8, 48.1 },
        { "spirit", 73.0, 44.5 },
    },
    [1445] = { -- Dustwallow Marsh
        { "raid", 52.6, 76.8, "onyxia" },
        { "flight", 67.5, 51.3, "A", "Theramore Isle" },
        { "flight", 35.6, 31.9, "H", "Brackenwall Village" },
        { "ship", 71.6, 56.4, "A", "Menethil Harbor", 1437 },
        { "spirit", 39.5, 31.4 },
        { "spirit", 46.6, 57.1 },
        { "spirit", 41.2, 74.4 },
        { "spirit", 63.6, 42.4 },
    },
    [1446] = { -- Tanaris
        { "dungeon", 38.7, 20.0, "zulfarrak" },
        { "flight", 51.0, 29.3, "A", "Gadgetzan" },
        { "flight", 51.6, 25.4, "H", "Gadgetzan" },
        { "spirit", 53.9, 28.8 },
        { "spirit", 49.4, 59.0 },
        { "spirit", 69.0, 40.7 },
    },
    [1447] = { -- Azshara
        { "flight", 11.9, 77.6, "A", "Talrendis Point" },
        { "flight", 22.0, 49.6, "H", "Valormok" },
        { "spirit", 70.4, 16.1 },
        { "spirit", 54.3, 71.5 },
        { "spirit", 14.0, 78.6 },
    },
    [1448] = { -- Felwood
        { "flight", 62.5, 24.2, "A", "Talonbranch Glade" },
        { "flight", 34.4, 54.0, "H", "Bloodvenom Post" },
        { "spirit", 49.5, 31.1 },
        { "spirit", 56.8, 87.0 },
    },
    [1449] = { -- Un'Goro Crater
        { "flight", 45.2, 5.8, "N", "Marshal's Refuge" },
        { "spirit", 45.3, 7.6 },
        { "spirit", 50.0, 56.0 },
        { "spirit", 80.3, 50.3 },
    },
    [1450] = { -- Moonglade
        { "flight", 48.1, 67.4, "A", "Lake Elune'ara" },
        { "flight", 32.1, 66.6, "H", "Moonglade" },
        { "spirit", 62.2, 70.1 },
    },
    [1451] = { -- Silithus
        { "raid", 28.6, 92.4, "ahnqiraj" },
        { "flight", 50.6, 34.5, "A", "Cenarion Hold" },
        { "flight", 48.7, 36.7, "H", "Cenarion Hold" },
        { "spirit", 47.2, 37.3 },
        { "spirit", 28.2, 87.1 },
        { "spirit", 81.2, 20.8 },
    },
    [1452] = { -- Winterspring
        { "flight", 62.3, 36.6, "A", "Everlook" },
        { "flight", 60.5, 36.3, "H", "Everlook" },
        { "spirit", 61.5, 35.4 },
        { "spirit", 62.7, 61.3 },
    },
    [1454] = { -- Orgrimmar
        { "dungeon", 52.6, 49.0, "ragefire" },
        { "flight", 45.1, 63.9, "H", "Valley of Strength" },
    },
    [1456] = { -- Thunder Bluff
        { "flight", 47.0, 49.8, "H", "Central Mesa" },
        { "spirit", 56.7, 19.1 },
    },
    [1457] = { -- Darnassus
        { "spirit", 77.7, 25.9 },
    },

    -- Added in Forever -------------------------------------------------------------------------
    [2482] = { -- Hyjal
        { "flight", 68.6, 44.0, "N", "Fayran Elthas" },
        { "flight", 55.0, 82.8, "N", "Bluebell" },
        { "spirit", 9.4, 47.0 },
        { "spirit", 81.2, 44.0 },
        { "spirit", 85.6, 68.8 },
    },
    [2521] = { -- Zephras Isle
        { "spirit", 41.0, 22.4 },
        { "spirit", 55.4, 45.0 },
        { "spirit", 68.8, 50.2 },
        { "spirit", 40.2, 63.6 },
        { "spirit", 55.0, 68.2 },
    },
    [2548] = { -- Riverglades
        { "flight", 60.6, 81.4, "A", "Gretchen Mayberry" },
        { "flight", 59.6, 45.2, "H", "Grakna" },
    },
}
