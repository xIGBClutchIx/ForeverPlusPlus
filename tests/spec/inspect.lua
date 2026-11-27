-- Inspect: another player's item level and talents from the server's answer to an inspect. One
-- request at a time, a pause between them, none in combat or while Blizzard's window inspects,
-- answers kept by GUID, and an average item level worked out from the worn items' levels.
local T = ...
local ns, eq, same, ok = T.ns, T.eq, T.same, T.ok

local now = 100
local combat = false
local sent = {}
local handlers = {}
local timers = {}
local units = { mouseover = "Player-1", target = "Player-2" }
local links = {}
local inspectLevel = 0

GetTime = function() return now end
C_Timer = { After = function(delay, fn) timers[#timers + 1] = { delay = delay, fn = fn } end }
InCombatLockdown = function() return combat end
UnitGUID = function(unit) return units[unit] end
UnitIsPlayer = function(unit) return units[unit] ~= nil end
UnitIsUnit = function() return false end
CanInspect = function() return true end
NotifyInspect = function(unit) sent[#sent + 1] = unit end
GetInventoryItemLink = function(_, slot) return links[slot] end
C_PaperDollInfo = { GetInspectItemLevel = function() return inspectLevel end }
C_Item = {
    GetDetailedItemLevelInfo = function(link) return tonumber(link:match("level(%d+)")) end,
    GetItemInfoInstant = function(link)
        return nil, nil, nil, link:find("2h") and "INVTYPE_2HWEAPON" or "INVTYPE_WEAPON"
    end,
}
-- The inspect config: three tabs, Fury the most.
C_ClassTalents = { GetActiveConfigID = function() return 7 end }
local spent = { [10] = 5, [20] = 31, [30] = 15 }
C_Traits = {
    GetConfigInfo = function(id) return id == -1 and { treeIDs = { 1117 } } or nil end,
    GetGroupDisplayInfoByTreeID = function()
        return {
            { groupID = 10, displayName = "Arms", orderIndex = 1 },
            { groupID = 20, displayName = "Fury", orderIndex = 2 },
            { groupID = 30, displayName = "Protection", orderIndex = 3 },
        }
    end,
    GetGroupCurrencyInfo = function(_, ids)
        return { { currencyInfos = { { spent = spent[ids[1]] } } } }
    end,
}
ns.On = function(event, fn) handlers[event] = fn end
ns.Off = function(event) handlers[event] = nil end
T.load("Lib/Talents")
T.load("Lib/Inspect")
local Inspect = ns.Inspect

-- The average.
local full = {}
for _, slot in ipairs({ 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }) do
    full[slot] = 60
end
eq(Inspect.Average(full), 60, "inspect: sixteen slots at 60 average 60")
full[17] = nil
eq(Inspect.Average(full), 56, "inspect: an empty off hand counts as 0 (900 / 16)")
eq(Inspect.Average(full, true), 60, "inspect: a two-hander counts twice with nothing in the off hand")
full[18] = 77
eq(Inspect.Average(full, true), 61, "inspect: a ranged item adds a slot (1037 / 17)")
eq(Inspect.Average({}), nil, "inspect: nothing worn, no average")

-- A request, and its answer.
local got = {}
local function remember(entry, guid)
    got[#got + 1] = { entry = entry, guid = guid }
end
links[16] = "item:2h:level50"
links[1] = "item:level40"
eq(Inspect.Request("mouseover", remember), nil, "inspect: nothing kept yet")
same(sent, { "mouseover" }, "inspect: the server is asked")
ok(handlers.INSPECT_READY, "inspect: INSPECT_READY heard while a request waits")
Inspect.Request("mouseover", remember)
eq(#sent, 1, "inspect: the same player isn't asked twice while it waits")
handlers.INSPECT_READY("INSPECT_READY", "Player-9")
eq(#got, 0, "inspect: someone else's answer is left alone")
handlers.INSPECT_READY("INSPECT_READY", "Player-1")
eq(#got, 1, "inspect: the same callback given twice is called once")
eq(got[1].guid, "Player-1", "inspect: with the player's GUID")
local entry = got[1].entry
eq(entry and entry.itemLevel, 8, "inspect: worked out from the links when the game gives 0 (140 / 16)")
eq(entry and entry.tabs and #entry.tabs, 3, "inspect: the talent tabs of the inspect config")
local best = ns.Talents.Dominant(nil, entry and entry.tabs)
eq(best and best.name, "Fury", "inspect: the tree with the most points")
eq(handlers.INSPECT_READY, nil, "inspect: INSPECT_READY let go once answered")
eq(Inspect.Get("Player-1"), entry, "inspect: the answer is kept by GUID")
eq(Inspect.Request("mouseover", remember), entry, "inspect: a kept answer asks nothing")
eq(#sent, 1, "inspect: still one request")

-- The pause between requests, and Blizzard's own number.
inspectLevel = 58.7
Inspect.Request("target", remember)
eq(#sent, 1, "inspect: a request in the pause waits")
eq(#timers, 1, "inspect: for a timer")
Inspect.Request("target", remember)
eq(#timers, 1, "inspect: one timer however often it's asked")
now = now + 2
timers[1].fn()
same(sent, { "mouseover", "target" }, "inspect: sent once the pause is over")
handlers.INSPECT_READY("INSPECT_READY", "Player-2")
eq(Inspect.Get("Player-2").itemLevel, 58, "inspect: the game's own number when it has one")

-- When not to ask.
units.focus = "Player-3"
now = now + 5
combat = true
Inspect.Request("focus", remember)
eq(#sent, 2, "inspect: nothing in combat")
combat = false
InspectFrame = { unit = "target", IsShown = function() return false end }
Inspect.Request("focus", remember)
eq(#sent, 2, "inspect: nothing while Blizzard's window waits for its own")
InspectFrame = nil

-- An answer that never comes, and one kept too long.
Inspect.Request("focus", remember)
eq(#sent, 3, "inspect: asked")
units.party1 = "Player-4"
now = now + 2
Inspect.Request("party1", remember)
eq(#sent, 3, "inspect: one at a time")
now = now + 5
Inspect.Request("party1", remember)
eq(got[#got].entry, nil, "inspect: a request with no answer is given up")
eq(#sent, 4, "inspect: and the next one goes")
now = now + 400
eq(Inspect.Get("Player-1"), nil, "inspect: an old answer isn't kept")
