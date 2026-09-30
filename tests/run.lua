-- Offline tests for the pure-logic Lib code. Plain Lua 5.1, no WoW client: run from the repo root
-- with `lua tests/run.lua`. Each Lib file is loaded the way the client does (with the addon name
-- and a shared `ns`), against a few stubbed WoW globals. No frame or UI code is tested here.
local ADDON = "ForeverPlusPlus"

-- Stubs -----------------------------------------------------------------------------------------

local player = { level = 30, faction = "Horde" }

UnitLevel = function()
    return player.level
end
UnitFactionGroup = function()
    return player.faction
end
GetQuestDifficultyColor = function(level)
    -- Marks the level asked about, so tests can tell which one the code picked.
    return { r = level, g = 0, b = 0 }
end
QuestDifficultyColors = { difficult = { r = "difficult", g = 0, b = 0 } }
FACTION_ALLIANCE, FACTION_HORDE = "Alliance", "Horde"
Enum = { UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3 } }
-- The Lib files cache these globals at load, so the stubs are fixed and read a table.
local game = { secret = nil, zoneNames = {} }
issecretvalue = function(value)
    return value == game.secret
end
GetRealZoneText = function(id)
    return game.zoneNames[id] or ""
end

local ns = {}
ns.NewLocale = function()
    return ns.L
end
ns.L = {}

local function load(path)
    local chunk, err = loadfile(path)
    assert(chunk, err)
    chunk(ADDON, ns)
end

for _, file in ipairs({ "Core", "Map" }) do
    load("ForeverPlusPlus/Locales/enUS/" .. file .. ".lua")
end
for _, file in ipairs({ "Secret", "Colors", "Text", "WorldMap", "Instances", "Chat" }) do
    load("ForeverPlusPlus/Lib/" .. file .. ".lua")
end

-- Harness ---------------------------------------------------------------------------------------

local failures, count = 0, 0

local function eq(got, want, what)
    count = count + 1
    if got ~= want then
        failures = failures + 1
        print(("FAIL %s: got %s, wanted %s"):format(what, tostring(got), tostring(want)))
    end
end

-- Colors ----------------------------------------------------------------------------------------

eq(ns.Colors.Code(1, 0, 0), "|cffff0000", "Code red")
eq(ns.Colors.Code(0.5, 0.5, 0.5), "|cff808080", "Code rounds")
eq(ns.Colors.Text({ r = 0, g = 1, b = 0 }, "hi"), "|cff00ff00hi|r", "Text wraps")
eq(ns.Colors.Faction("H"), ns.Colors.Faction("H"), "Faction stable")
eq(ns.Colors.Faction("A").b > ns.Colors.Faction("A").r, true, "Alliance is blue")
eq(ns.Colors.Faction("H").r > ns.Colors.Faction("H").b, true, "Horde is red")
eq(ns.Colors.Faction("?"), ns.Colors.Faction(nil), "unknown side is neutral")

player.level = 10 -- below the range: colored by its low end
eq(ns.Colors.LevelRange(20, 30).r, 20, "range above you uses low")
player.level = 25 -- inside
eq(ns.Colors.LevelRange(20, 30).r, "difficult", "range you are in")
player.level = 40 -- outleveled: two below the top
eq(ns.Colors.LevelRange(20, 30).r, 28, "outleveled uses high - 2")
eq(ns.Colors.LevelRange(29, 30).r, 29, "outleveled never goes under low")

-- Text ------------------------------------------------------------------------------------------

eq(ns.Text.Clock(0), "0:00", "Clock zero")
eq(ns.Text.Clock(42), "0:42", "Clock seconds")
eq(ns.Text.Clock(725), "12:05", "Clock minutes")
eq(ns.Text.Clock(41.6), "0:42", "Clock rounds")
eq(ns.Text.Seconds(1), "1 Second", "one second")
eq(ns.Text.Seconds(5), "5 Seconds", "seconds")
eq(ns.Text.Hours(1), "1 Hour", "one hour")
eq(ns.Text.Hours(12), "12 Hours", "hours")
eq(ns.Text.Ago(5), "just now", "ago now")
eq(ns.Text.Ago(60), "1m ago", "ago minute")
eq(ns.Text.Ago(3599), "59m ago", "ago last minute")
eq(ns.Text.Ago(3600), "1h ago", "ago hour")
eq(ns.Text.Ago(86400 * 2 + 5), "2d ago", "ago days")

-- Secret ----------------------------------------------------------------------------------------

eq(ns.IsReadable(5), true, "readable without issecretvalue")
game.secret = "secret"
eq(ns.IsReadable("secret"), false, "secret is unreadable")
game.secret = nil

-- WorldMap --------------------------------------------------------------------------------------

local WorldMap = ns.WorldMap
eq(WorldMap.IsContinent({ mapType = 2 }), true, "continent")
eq(WorldMap.IsContinent({ mapType = 1 }), true, "world")
eq(WorldMap.IsContinent({ mapType = 3 }), false, "zone")
eq(WorldMap.IsContinent({ mapType = 0 }), false, "cosmic off by default")
eq(WorldMap.IsContinent({ mapType = 0 }, true), true, "cosmic when asked")
eq(WorldMap.IsContinent(nil), false, "no info")
eq(WorldMap.PlayerSide(), "H", "Horde side")
player.faction = "Alliance"
eq(WorldMap.PlayerSide(), "A", "Alliance side")
player.faction = "Pandaren"
eq(WorldMap.PlayerSide(), nil, "neutral side")
eq(WorldMap.SideName("A"), "Alliance", "side name")
eq(WorldMap.SideName("X"), nil, "unknown side name")

-- Instances -------------------------------------------------------------------------------------

local Instances = ns.Instances
local ids = {}
for key, inst in pairs(Instances.byKey) do
    eq(type(inst[2]) == "string" and inst[2] ~= "", true, key .. " has an English name")
    eq(inst[3] <= inst[4], true, key .. " levels in order")
    if inst[1] then
        eq(ids[inst[1]], nil, key .. " instance id is unique")
        ids[inst[1]] = key
    end
end

player.level = 30
eq(Instances.Name(Instances.byKey.mc), "Molten Core", "name falls back to English")
game.zoneNames[409] = "Kern des Feuers"
eq(Instances.Name(Instances.byKey.mc), "Kern des Feuers", "name from the game")
eq(Instances.Name(Instances.byKey.brd), "Blackrock Depths", "empty game name falls back")
game.zoneNames[409] = nil

eq(Instances.ByName("molten core"), Instances.byKey.mc, "ByName is case-insensitive")
eq(Instances.ByName("Nowhere"), nil, "ByName unknown")
eq(Instances.ByName(nil), nil, "ByName nil")

ns.Colors.LevelRange = function()
    return nil
end
eq(Instances.Levels(Instances.byKey.mc), "Level 60", "single level")
eq(Instances.Levels(Instances.byKey.brd), "Level 52-60", "level range")
eq(Instances.Levels(Instances.byKey.brd, true), "52-60", "compact range")
eq(Instances.Levels(Instances.byKey.mc, true), "60", "compact single")
eq(Instances.Icon(Instances.byKey.mc, 14), "|A:Raid:14:14|a", "raid icon")
eq(Instances.Icon(Instances.byKey.brd, 14), "|A:Dungeon:14:14|a", "dungeon icon")

-- Chat.Plain
eq(ns.Chat.Plain("|cffff0000red|r text"), "red text", "plain color")
eq(ns.Chat.Plain("|cnCOLOR:named|r"), "named", "plain named color")
eq(ns.Chat.Plain("|Hplayer:Bob:1|h[Bob]|h: hi"), "[Bob]: hi", "plain link keeps its text")
eq(ns.Chat.Plain("a |TInterface\\Icon:0|t b |A:Raid:14:14|a c"), "a  b  c", "plain textures")
eq(ns.Chat.Plain("100||"), "100|", "plain escaped pipe")

-- Done ------------------------------------------------------------------------------------------

print(("%d checks, %d failed"):format(count, failures))
os.exit(failures == 0 and 0 or 1)
