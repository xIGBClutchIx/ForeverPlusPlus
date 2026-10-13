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
game.cachedItems = {}
C_Item = {
    GetItemInfoInstant = function(name)
        return game.cachedItems[name]
    end,
}

local ns = {}
ns.NewLocale = function()
    return ns.L
end
ns.L = {}
ns.Call = function(fn, ...)
    return fn(...)
end

local function load(path)
    local chunk, err = loadfile(path)
    assert(chunk, err)
    chunk(ADDON, ns)
end

for _, file in ipairs({ "Core", "Map" }) do
    load("ForeverPlusPlus/Locales/enUS/" .. file .. ".lua")
end
for _, file in ipairs({ "Secret", "Colors", "Text", "WorldMap", "Instances", "Chat",
    "TalentPlan", "Errors", "Prices", "Store", "Keys" }) do
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
eq(ns.Colors.ClassToken(nil), nil, "no class token, no color")

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
eq(ns.Text.Clock(3599.6), "1:00:00", "Clock rounds up to an hour")
eq(ns.Text.Clock(3725), "1:02:05", "Clock hours")
eq(ns.Text.Clock(-0.6), "0:00", "Clock never goes below zero")
eq(ns.Text.Seconds(1), "1 Second", "one second")
eq(ns.Text.Seconds(5), "5 Seconds", "seconds")
eq(ns.Text.Hours(1), "1 Hour", "one hour")
eq(ns.Text.Hours(12), "12 Hours", "hours")
eq(ns.Text.NewerVersion("0.8.0", "0.7.0"), true, "newer version")
eq(ns.Text.NewerVersion("0.10.0", "0.9.2"), true, "newer version by number, not text")
eq(ns.Text.NewerVersion("0.7.0", "0.7.0"), false, "same version")
eq(ns.Text.NewerVersion("0.7", "0.7.0"), false, "missing part is zero")
eq(ns.Text.NewerVersion("0.7.0", "0"), true, "anything after 0")
eq(ns.Text.Ago(5), "just now", "ago now")
eq(ns.Text.Ago(60), "1m ago", "ago minute")
eq(ns.Text.Ago(3599), "59m ago", "ago last minute")
eq(ns.Text.Ago(3600), "1h ago", "ago hour")
eq(ns.Text.Ago(86400 * 2 + 5), "2d ago", "ago days")
eq(ns.Text.Plain("|cffff0000red|r text"), "red text", "plain color")
eq(ns.Text.Plain("|cnCOLOR:named|r"), "named", "plain named color")
eq(ns.Text.Plain("|Hplayer:Bob:1|h[Bob]|h: hi"), "[Bob]: hi", "plain link keeps its text")
eq(ns.Text.Plain("a |TInterface\\Icon:0|t b |A:Raid:14:14|a c"), "a  b  c", "plain textures")
eq(ns.Text.Plain("100||"), "100|", "plain escaped pipe")
eq(ns.Text.Plain("a||rb ||cffffffffc |cff00ff00d|r"), "a|rb |cffffffffc d",
    "plain escaped pipe before a code letter")

local function matches(formatString, text, capture)
    return text:match("^" .. ns.Text.FormatPattern(formatString, capture) .. "$")
end
eq(matches("Requires %s (%d)", "Requires Mining (75)", true), "Mining", "format pattern captures")
eq(select(2, matches("Requires %s (%d)", "Requires Mining (75)", true)), "75",
    "format pattern captures numbers")
eq(matches("%2$s from %1$s.", "Axe from Bob.", true), "Axe", "format pattern reordered")
eq(matches("Collected (%d/%d)", "Collected (1/3)") ~= nil, true, "format pattern without captures")
eq(matches("Collected (%d/%d)", "Collected (a/3)"), nil, "format pattern %d needs digits")
eq(matches("Press %s to submit", "Press [F1] to submit") ~= nil, true, "format pattern escapes")

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

-- Toward: on a 1000 by 500 yard map, from the middle.
local function near(got, want, what)
    eq(math.abs(got - want) < 1e-9, true, what .. " (" .. tostring(got) .. ")")
end
local yards, angle = WorldMap.Toward(1000, 500, 0.5, 0.5, 0.5, 0.3)
near(yards, 100, "north distance")
near(angle, 0, "north is 0")
yards, angle = WorldMap.Toward(1000, 500, 0.5, 0.5, 0.4, 0.5)
near(yards, 100, "west distance uses width")
near(angle, math.pi / 2, "west is a quarter turn left")
_, angle = WorldMap.Toward(1000, 500, 0.5, 0.5, 0.5, 0.7)
near(angle, math.pi, "south is half a turn")
_, angle = WorldMap.Toward(1000, 500, 0.5, 0.5, 0.6, 0.5)
near(angle, 3 * math.pi / 2, "east is three quarters")
yards = WorldMap.Toward(1000, 500, 0.2, 0.2, 0.2, 0.2)
near(yards, 0, "same spot")

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


-- Chat.Colored, Chat.Uncolor, and offsets between them
local Chat = ns.Chat
eq(Chat.Colored("hi", 1, 0, 0), "|cffff0000hi|r", "colored line")
eq(Chat.Colored("hi"), "hi", "colored without a color")
eq(Chat.Colored("[|cff00ff00Bob|r]: hi", 0, 0, 1),
    "|cff0000ff[|r|cff00ff00Bob|r|cff0000ff]: hi|r", "colored keeps a name's color apart from the line's")
eq(Chat.Colored("|Hplayer:Bob|h[|cff00ff00Bob|r]|h: |cnIQ4:|Hitem:1|h[Axe]|h|r", 1, 1, 1),
    "|cffffffff[|r|cff00ff00Bob|r|cffffffff]: |r|cnIQ4:[Axe]|r|cffffffff|r",
    "colored keeps link colors apart from the line's")
ITEM_QUALITY_COLORS = { [4] = { r = 1, g = 0.5, b = 0 } }
eq(Chat.Colored("|cnIQ4:[Axe]|r |cnIQ9:[Odd]|r"), "|cffff8000[Axe]|r |cnIQ9:[Odd]|r",
    "colored turns item quality into a color code")
ITEM_QUALITY_COLORS = nil
eq(Chat.Colored("|Hplayer:Bob|h[Bob]|h |TIcon:0|tx", 1, 1, 1), "|cffffffff[Bob] x|r",
    "colored drops links and textures")
eq(Chat.Colored("a||rb", 1, 1, 1), "|cffffffffa||rb|r", "colored keeps an escaped pipe")
local colored = "|cffff0000ab|cnRED:cd|r||e|r"
eq(Chat.Uncolor(colored), "abcd|e", "uncolor")
eq(Chat.Uncolor(Chat.Colored("[|cff00ff00Bob|r]: 5||6", 1, 0, 0)), "[Bob]: 5|6", "uncolor colored")
eq(Chat.PlainOffset(colored, 0), 0, "plain offset start")
eq(Chat.PlainOffset(colored, 12), 2, "plain offset after ab")
eq(Chat.PlainOffset(colored, 5), 0, "plain offset inside a code")
eq(Chat.PlainOffset(colored, #colored), 6, "plain offset end")
eq(Chat.ColoredOffset(colored, 0), 0, "colored offset start")
eq(Chat.ColoredOffset(colored, 2), 12, "colored offset after ab")
eq(Chat.ColoredOffset(colored, 3), 20, "colored offset after a code")
eq(Chat.ColoredOffset(colored, 5), 25, "colored offset after an escaped pipe")
eq(Chat.ColoredOffset(colored, 6), 26, "colored offset end, before the last code")

-- Chat.TimestampPattern
local function stamp(format, line)
    local _, finish = line:find(Chat.TimestampPattern(format))
    return finish and line:sub(1, finish)
end
eq(stamp("%I:%M ", "09:41 [Bob]: hi"), "09:41 ", "timestamp hours and minutes")
eq(stamp("[%H:%M:%S] ", "[21:05:09] hi"), "[21:05:09] ", "timestamp in brackets")
eq(stamp("%I:%M %p ", "9:41 PM hi"), "9:41 PM ", "timestamp with AM or PM")
eq(stamp("%I:%M ", "|Haddon:x|h09:41 |h hi"), nil, "timestamp not inside a link")
eq(stamp("%H:%M ", "[Bob]: 12:30 tonight"), nil, "timestamp only at the start")

-- TalentPlan ------------------------------------------------------------------------------------

local Plan = ns.TalentPlan
-- Two tabs. Tab 1: a (5 ranks, row 0), b (3, row 1, needs 5), c (1, row 1, needs a maxed).
-- Tab 2: d (5, row 0), e (1, row 0, needs d or a maxed: Sufficient edges).
local talents = {
    nodes = {
        a = { max = 5, tab = 1, req = 0, prereqs = {} },
        b = { max = 3, tab = 1, req = 5, prereqs = {} },
        c = { max = 1, tab = 1, req = 5, prereqs = { { id = "a", required = true } } },
        d = { max = 5, tab = 2, req = 0, prereqs = {} },
        e = { max = 1, tab = 2, req = 0, prereqs = { { id = "d" }, { id = "a" } } },
    },
    order = { "a", "d", "e", "b", "c" },
}

local picks = {}
eq(Plan.Add(talents, picks, "b", 10), false, "row 1 needs 5 points in the tab")
eq(select(2, Plan.Add(talents, picks, "b", 10)), "tier", "tier reason")
for _ = 1, 4 do
    Plan.Add(talents, picks, "a", 10)
end
eq(select(2, Plan.Add(talents, picks, "c", 10)), "tier", "4 points aren't 5")
eq(select(2, Plan.Add(talents, picks, "e", 10)), "prereq", "sufficient edge unmet")
eq(Plan.Add(talents, picks, "a", 10), true, "fifth rank")
eq(select(2, Plan.Add(talents, picks, "a", 10)), "max", "no sixth rank")
eq(Plan.Add(talents, picks, "c", 10), true, "prerequisite maxed")
eq(Plan.Add(talents, picks, "e", 10), true, "any sufficient edge is enough")
eq(#picks, 7, "seven points")
eq(select(2, Plan.Add(talents, picks, "d", 7)), "points", "no points left at the cap")

eq(select(2, Plan.Remove(talents, picks, "a")), "needed", "c and e need the fifth a")
eq(Plan.Remove(talents, picks, "e"), true, "remove the last point")
eq(Plan.Remove(talents, picks, "c"), true, "then c")
eq(Plan.Remove(talents, picks, "a"), true, "then a is free")
eq(#picks, 4, "four points left")
eq(select(2, Plan.Remove(talents, picks, "d")), "none", "nothing in d")
eq(select(2, Plan.Remove(talents, { "a", "a", "d" }, "d", 2)), "none", "remove looks under the cap")

local counts, tabs, bad, why = Plan.Simulate(talents, { "a", "b" })
eq(bad, 2, "simulate finds the bad point")
eq(why, "tier", "and why")
eq(counts.a, 1, "counts before it")
eq(tabs[1], 1, "tab points before it")
eq(select(3, Plan.Simulate(talents, { "a", "b" }, 1)), nil, "limit stops before it")

local order = Plan.FromRanks(talents, { a = 5, c = 1, e = 1, d = 2 })
eq(#order, 9, "learned points all placed")
eq(select(3, Plan.Simulate(talents, order)), nil, "learned order is valid")
eq(order[1], "a", "top row first")

eq(select(2, Plan.Next({ "a", "a", "d", "a" }, { a = 2 })), "d", "next unlearned point")
eq(Plan.Next({ "a", "a", "d", "a" }, { a = 2 }), 3, "its place")
eq(Plan.Next({ "a" }, { a = 1 }), nil, "plan done")

local shared = Plan.Encode(1117, { name = "Arms: Leveling|x", level = 30, picks = { 101, 101, 101, 102, 101 } })
eq(shared, "FPP:1:1117:30:Arms Levelingx:101*3,102,101", "encode runs, strip : and |")
local back = Plan.Decode("  " .. shared .. " ")
eq(back and back.treeID, 1117, "decode tree")
eq(back and back.level, 30, "decode level")
eq(back and back.name, "Arms Levelingx", "decode name")
eq(back and #back.picks, 5, "decode points")
eq(back and back.picks[3], 101, "decode run")
eq(back and back.picks[4], 102, "decode single")
eq(#Plan.Decode("FPP:1:5:10::").picks, 0, "decode empty plan")
eq(Plan.Decode("hello"), nil, "decode junk")
eq(Plan.Decode("FPP:1:5:10:x:1**2"), nil, "decode bad run")
eq(Plan.Decode("FPP:1:5:60::1*999999999"), nil, "decode refuses a huge run")
eq(Plan.Decode("FPP:1:5:60::1*50,2*2"), nil, "decode refuses more than 51 points")
eq(#Plan.Decode("FPP:1:5:60::1*50,2").picks, 51, "decode takes 51 points")
eq(Plan.Decode("FPP:1:5:60:|cffff0000Red|r:1").name, "cffff0000Redr", "decode drops | from names")

eq(Plan.FirstLevel(30, 21), 10, "first point at 10")
eq(Plan.FirstLevel(5, 0), 10, "none earned yet: Classic's 10")
eq(Plan.PointsAt(30, 10), 21, "21 points at 30")
eq(Plan.PointsAt(9, 10), 0, "none before 10")
eq(Plan.LevelOf(21, 10), 30, "21st point at 30")
eq(Plan.FirstLevel(30, 26, 5), 5, "talented: counted from points earned")
eq(Plan.FirstLevel(4, 0, 5), 5, "talented, none earned yet: level 5")
eq(Plan.FirstLevel(60, 51, 5), 5, "talented, all 51 earned: level 5")
eq(Plan.FirstLevel(60, 51), 10, "all 51 earned: level 10")
eq(Plan.PointsAt(60, 5), 51, "never more than 51")
eq(Plan.PointsAt(30, 5), 26, "talented: 26 points at 30")

-- Errors ----------------------------------------------------------------------------------------

local Errors = ns.Errors
local heard, toggled = 0, 0
Errors.OnChanged(function()
    heard = heard + 1
end)
eq(Errors.IsOn(), false, "errors off at first")
eq(Errors.SessionCount(), 0, "no count while off")
Errors.Toggle() -- does nothing while off
Errors.Provide({
    session = function() return 3 end,
    saved = function() return 7 end,
    toggle = function() toggled = toggled + 1 end,
    clearSession = function() toggled = toggled + 10 end,
})
eq(Errors.IsOn(), true, "errors on once provided")
eq(heard, 1, "providing tells listeners")
eq(Errors.SessionCount(), 3, "session count")
eq(Errors.SavedCount(), 7, "saved count")
Errors.Toggle()
eq(toggled, 1, "toggle opens the window")
Errors.ClearSession()
eq(toggled, 11, "clear session reaches error catcher")
Errors.Changed()
eq(heard, 2, "changes tell listeners")
Errors.Provide(nil)
eq(Errors.IsOn(), false, "errors off again")
eq(Errors.SavedCount(), 0, "no saved count while off")
eq(heard, 3, "turning off tells listeners")

-- Prices ----------------------------------------------------------------------------------------

local Prices = ns.Prices
game.cachedItems["Strange Dust"] = 10940
eq(Prices.Available(), false, "no prices without a source")
eq(Prices.Auction(10940), nil, "no auction price without a source")
eq(Prices.ItemByName("Strange Dust"), 10940, "item cache finds a name without a source")
eq(Prices.ItemByName("Bolt of Silk Cloth"), nil, "unknown name without a source")
eq(Prices.Inline(), false, "price lines at the edge without a source")
Prices.SetSource({
    price = function(itemID)
        return itemID == 4305 and 120 or nil
    end,
    itemByName = function(name)
        return name == "Bolt of Silk Cloth" and 4305 or nil
    end,
    inline = function()
        return true
    end,
})
eq(Prices.Available(), true, "prices with a source")
eq(Prices.Auction(4305), 120, "source's price")
eq(Prices.Auction(10940), nil, "item the source has no price for")
eq(Prices.ItemByName("Bolt of Silk Cloth"), 4305, "source finds a name the cache doesn't")
eq(Prices.ItemByName("Strange Dust"), 10940, "item cache first")
eq(Prices.Inline(), true, "source's alignment")
Prices.SetSource(nil)
eq(Prices.Auction(4305), nil, "no prices once the source goes")

-- Saved prices ------------------------------------------------------------------------------------

local packed = Prices.Pack(4800, 1791836472)
eq(packed, "4800,1530607", "prices: a saved price is copper and minutes")
local copper, seenAt = Prices.Unpack(packed)
eq(copper, 4800, "prices: unpacked copper")
eq(seenAt, 1791836420, "prices: unpacked time, to the minute")
eq(Prices.Unpack(nil), nil, "prices: nothing saved")
eq(Prices.Unpack({ price = 1 }), nil, "prices: an old table isn't a saved price")
copper, seenAt = Prices.Unpack(Prices.Pack(700, 0))
eq(copper, 700, "prices: a price seen before the epoch keeps its copper")
eq(seenAt <= 0, true, "prices: and a time before the epoch")

-- A house from 0.7.0 to 0.8.4, and one from before 0.7.0.
local newer = { scannedAt = 1791836000, items = { [1] = { price = 50, seenAt = 1791836472 },
    [2] = "60,1530600", [3] = { broken = true } } }
Prices.PackHouse(newer)
eq(newer.items[1], Prices.Pack(50, 1791836472), "prices: a saved table is packed")
eq(newer.items[2], "60,1530600", "prices: a packed price stays")
eq(newer.items[3], nil, "prices: a broken entry goes")
local older = { scannedAt = 1790781485, prices = { [7] = 4800, [8] = 700 } }
Prices.PackHouse(older)
eq(older.prices, nil, "prices: the old price list goes")
copper, seenAt = Prices.Unpack(older.items[7])
eq(copper, 4800, "prices: an old price is kept")
eq(math.abs(seenAt - 1790781485) < 60, true, "prices: aged from the house's scan")
local unscanned = { prices = { [7] = 4800 } }
Prices.PackHouse(unscanned)
eq(unscanned.prices, nil, "prices: an unscanned house's old list goes")
eq(unscanned.items[7], nil, "prices: and its prices with it, having no age")
local zeroScan = { scannedAt = 0, prices = { [7] = 4800 } }
Prices.PackHouse(zeroScan)
eq(zeroScan.items[7], nil, "prices: a house scanned at 0 drops its old prices")

-- Hold Shift to Skip checkboxes become key dropdowns.
local shiftSaved = { AutoGossip = { shiftSkips = false }, AutoRepair = { shiftSkips = true } }
ns.Keys.MigrateShift(shiftSaved, "AutoGossip", "shiftSkips", "skipKey")
ns.Keys.MigrateShift(shiftSaved, "AutoRepair", "shiftSkips", "skipKey")
ns.Keys.MigrateShift(shiftSaved, "AutoSellJunk", "shiftSkips", "skipKey")
eq(shiftSaved.AutoGossip.skipKey, "none", "keys: an unticked checkbox is None")
eq(shiftSaved.AutoRepair.skipKey, "shift", "keys: a ticked checkbox is Shift")
eq(shiftSaved.AutoRepair.shiftSkips, nil, "keys: the checkbox goes")
eq(shiftSaved.AutoSellJunk, nil, "keys: nothing saved, nothing made")

-- Store -----------------------------------------------------------------------------------------

local Store = ns.Store

-- A fresh install is current at once and runs no steps.
local ran = {}
Store.Step(1, function(db) ran[#ran + 1] = "1:" .. tostring(db.modules ~= nil) end)
Store.Step(2, function(db)
    ran[#ran + 1] = "2"
    Store.Split(db, { TalentPlanner = { builds = true } })
end)
Store.Step(3, function(db)
    ran[#ran + 1] = "3"
    Store.Rename(db, { BagSlots = "BagSlotCounter" })
end)
Store.CharacterStep(2, function(char, db)
    Store.Claim(char, db, "TalentPlanner", "builds", function(entries)
        local mine = entries["G-1"] and { [1] = entries["G-1"] }
        entries["G-1"] = nil
        return mine
    end)
end)
local freshDB, freshChar = {}, {}
eq(Store.Upgrade(freshDB, freshChar), true, "store: empty saved variables are a fresh install")
eq(#ran, 0, "store: a fresh install runs no account steps")
eq(freshDB.version, Store.VERSION, "store: a fresh install is current")
eq(freshChar.version, Store.VERSION, "store: a fresh character is current")

-- The 0.8 layout: every setting and table in `modules`, under the old names.
local oldDB = { seenModules = { BagSlots = "0.8.2" }, modules = {
    BagSlots = { enabled = true, size = "large", position = "top" },
    TalentPlanner = { enabled = true, builds = { ["G-1"] = { active = 1 }, ["H-1"] = { active = 2 } } },
} }
local oldChar = {}
eq(Store.Upgrade(oldDB, oldChar), false, "store: saved settings aren't a fresh install")
eq(table.concat(ran, ","), "1:true,2,3", "store: steps run in version order, version 1 on the old layout")
eq(oldDB.modules, nil, "store: the old layout is gone")
eq(oldDB.settings.BagSlotCounter.position, "top", "store: settings follow a renamed module")
eq(oldDB.settings.BagSlots, nil, "store: the old name is gone")
eq(oldDB.seenModules.BagSlotCounter, "0.8.2", "store: the version a module was seen in follows it")
eq(oldChar.data.TalentPlanner.builds[1].active, 1, "store: a character takes its own data")
eq(oldDB.unclaimed.TalentPlanner.builds["H-1"].active, 2, "store: another character's data waits")
ran = {}
Store.Upgrade(oldDB, oldChar)
eq(#ran, 0, "store: each step runs once")

-- What a module reads and writes.
local defaults = { enabled = true, size = "large", position = "bottomright", banks = {}, seen = { list = {} } }
oldDB.settings.BagSlotCounter.stale = 5
oldDB.data.BagSlotCounter = { gone = {} }
local view = Store.Load(oldDB, oldChar, "BagSlotCounter", defaults)
local settings = oldDB.settings.BagSlotCounter
eq(view.size, "large", "store: a setting reads its default")
eq(settings.size, nil, "store: a setting equal to its default isn't saved")
eq(settings.stale, nil, "store: a setting the defaults dropped is cleared")
eq(view.position, "top", "store: a changed setting reads what was chosen")
view.position = "bottomright"
eq(settings.position, nil, "store: setting a value back to its default forgets it")
view.size = "huge"
eq(settings.size, "huge", "store: a changed setting is saved")
eq(type(view.banks), "table", "store: data reads its table")
eq(oldDB.data.BagSlotCounter.banks, view.banks, "store: data is saved apart from settings")
eq(type(view.seen.list), "table", "store: data is filled with its default tables")
eq(oldDB.data.BagSlotCounter.gone, nil, "store: data the defaults dropped is cleared")
local plans = Store.Load(oldDB, oldChar, "TalentPlanner", { enabled = true, builds = {} }, { builds = true })
eq(plans.builds[1].active, 1, "store: per-character data reads the character's table")
plans.builds[2] = { active = 3 }
eq(oldChar.data.TalentPlanner.builds[2].active, 3, "store: per-character data is saved for the character")
Store.Prune(oldDB, oldChar, { BagSlotCounter = true })
eq(oldDB.settings.TalentPlanner, nil, "store: a module that's gone loses its settings")
view.size = "large"
Store.Tidy(oldDB, oldChar)
eq(oldDB.settings.BagSlotCounter, nil, "store: tidy drops a module with no changed settings")
eq(oldDB.data.BagSlotCounter, nil, "store: tidy drops data with nothing collected")
view.position = "top"
eq(oldDB.settings.BagSlotCounter.position, "top", "store: a write after tidy is saved again")
eq(type(view.seen.list), "table", "store: data after tidy is made again")
view.banks.x = 1
eq(oldDB.data.BagSlotCounter.banks.x, 1, "store: data made again is saved")

-- Done ------------------------------------------------------------------------------------------

print(("%d checks, %d failed"):format(count, failures))
os.exit(failures == 0 and 0 or 1)
