-- Another player's item level and talents, from the server's answer to an inspect. NotifyInspect
-- asks, INSPECT_READY (with the player's GUID) says the answer is in, and then the unit's gear
-- reads through GetInventoryItemLink and its talents through the inspect trait config. Answers
-- are kept by GUID for a few minutes, so pointing at the same player again asks nothing.
--
-- The server drops inspects sent too fast (Blizzard's own comment in Blizzard_InspectUI), and
-- answers only the last one sent, so: one request at a time, a pause between them, none in
-- combat, and none while Blizzard's inspect window has one of its own on the way or open. We never
-- call ClearInspectPlayer, which would take the data from under that window or another addon.
-- Nothing is registered until the first request, and INSPECT_READY only while one waits.
local _, ns = ...

local GetTime, C_Timer, C_Item, C_PaperDollInfo = GetTime, C_Timer, C_Item, C_PaperDollInfo
local UnitGUID, UnitIsPlayer, UnitIsUnit, CanInspect = UnitGUID, UnitIsPlayer, UnitIsUnit, CanInspect
local NotifyInspect, GetInventoryItemLink, InCombatLockdown = NotifyInspect, GetInventoryItemLink, InCombatLockdown
local CheckInteractDistance = CheckInteractDistance
local _G, pairs, ipairs, pcall, select, tonumber, floor = _G, pairs, ipairs, pcall, select, tonumber, math.floor

local Inspect = {}
ns.Inspect = Inspect

local readable = ns.IsReadable

local KEEP = 300 -- seconds an answer stays good
local KEEP_PARTIAL = 10 -- an answer with an item the client hadn't loaded: asked again soon
local GAP = 1.5 -- seconds between two of our requests
local WAIT = 4 -- seconds before a request with no answer is given up

-- The slots an average counts, as Blizzard's character sheet does: every worn slot but the shirt
-- (4) and tabard (19). The ranged slot (18) counts only with something in it, since Forever's
-- inspect window has no ranged slot (Blizzard_InspectUI/Camelot, INSPECTPAPERDOLLFRAME_SLOTS).
local SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
local RANGED, MAIN_HAND, OFF_HAND = 18, 16, 17

---The average item level of a set of worn items, from the level in each slot (`levels[slot]`,
---nil for an empty one): every slot of the 16 counted, an empty one as 0, and a two-handed main
---hand with nothing in the off hand counted twice. A ranged item adds a slot. Rounded down, as
---the character sheet shows it. Nil with nothing worn.
---@param levels table<number, number>
---@param twoHanded boolean? the main hand holds a two-handed weapon
---@return number?
function Inspect.Average(levels, twoHanded)
    local sum, slots, any = 0, #SLOTS, false
    for _, slot in ipairs(SLOTS) do
        local level = levels[slot]
        if level then
            sum, any = sum + level, true
        end
    end
    if twoHanded and levels[MAIN_HAND] and not levels[OFF_HAND] then
        sum = sum + levels[MAIN_HAND]
    end
    if levels[RANGED] then
        sum, slots, any = sum + levels[RANGED], slots + 1, true
    end
    if not any then
        return nil
    end
    return floor(sum / slots)
end

---The quality a set of worn items is mostly of: the middle one of `qualities` in order (the lower
---of the two middle ones for an even count), so a few better or worse pieces don't move it. For
---coloring an average item level as an item is colored, with no item levels kept by hand that a
---patch would raise. Nil for none.
---@param qualities number[] Enum.ItemQuality values
---@return number?
function Inspect.TypicalQuality(qualities)
    local sorted = {}
    for i, quality in ipairs(qualities) do
        sorted[i] = quality
    end
    if #sorted == 0 then
        return nil
    end
    table.sort(sorted)
    return sorted[floor((#sorted + 1) / 2)]
end

---The quality most of what `unit` wears is of (`TypicalQuality`), for the player or a unit whose
---inspect answer is in. Nil when nothing can be read.
---@param unit string
---@return number?
function Inspect.UnitQuality(unit)
    local get = _G.GetInventoryItemQuality
    if not get then
        return nil
    end
    local qualities = {}
    local function add(slot)
        local quality = get(unit, slot)
        if ns.IsNumber(quality) then
            qualities[#qualities + 1] = quality
        end
    end
    for _, slot in ipairs(SLOTS) do
        add(slot)
    end
    add(RANGED)
    return Inspect.TypicalQuality(qualities)
end

-- The item level of what `unit` wears, and whether every item could be read. Blizzard's own number
-- first (C_PaperDollInfo.GetInspectItemLevel, in this build's API docs but unseen in game), and
-- otherwise worked out from the items' links.
local function itemLevel(unit)
    local get = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel
    if get then
        local ok, level = pcall(get, unit)
        level = ok and ns.IsNumber(level) and tonumber(level) or 0
        if level > 0 then
            return floor(level), true
        end
    end
    if not (GetInventoryItemLink and C_Item and C_Item.GetDetailedItemLevelInfo) then
        return nil, true
    end
    local levels, whole, twoHanded = {}, true, false
    local slots = { RANGED }
    for _, slot in ipairs(SLOTS) do
        slots[#slots + 1] = slot
    end
    for _, slot in ipairs(slots) do
        local link = GetInventoryItemLink(unit, slot)
        if ns.IsText(link, true) then
            local level = C_Item.GetDetailedItemLevelInfo(link)
            if ns.IsNumber(level) then
                levels[slot] = level
            else
                whole = false -- not loaded yet
            end
            if slot == MAIN_HAND and C_Item.GetItemInfoInstant then
                local equipLoc = select(4, C_Item.GetItemInfoInstant(link))
                twoHanded = equipLoc == "INVTYPE_2HWEAPON"
            end
        end
    end
    return Inspect.Average(levels, twoHanded), whole
end

local cache = {} -- GUID -> { itemLevel, tabs, time, keep }
local pending -- { guid, unit, time, callbacks = { fn, ... } }, while a request waits
local lastSent = -GAP
local listening = false

local function fresh(entry)
    return entry and GetTime() - entry.time < entry.keep
end

---The answer kept for a player's GUID: `{ itemLevel, quality, tabs }` (any may be nil), or nil when
---there's none or it's too old.
---@param guid string
---@return table?
function Inspect.Get(guid)
    local entry = readable(guid) and guid and cache[guid]
    if fresh(entry) then
        return entry
    end
end

-- Blizzard's inspect window is waiting for its own answer, or shows one, or its talent window
-- shows another player's talents: leave the inspect to them.
local function blizzardInspecting()
    local frame = _G.InspectFrame
    if frame and (frame.unit or frame:IsShown()) then
        return true
    end
    local spells = _G.PlayerSpellsFrame
    return spells and spells.IsInspecting and spells:IsInspecting() and true or false
end

local onReady

local function stopListening()
    if listening then
        listening = false
        ns.Off("INSPECT_READY", onReady)
    end
end

local function finish(entry)
    local callbacks = pending and pending.callbacks or {}
    local guid = pending and pending.guid
    pending = nil
    stopListening()
    for _, fn in ipairs(callbacks) do
        fn(entry, guid)
    end
end

onReady = function(_, guid)
    if not (pending and readable(guid) and guid == pending.guid) then
        return -- someone else's inspect: Blizzard's window, or another addon's
    end
    local unit = pending.unit
    local now = UnitGUID(unit)
    if not (readable(now) and now == guid) then
        finish(nil) -- the unit is someone else now, and the answer can't be read by it
        return
    end
    local level, whole = itemLevel(unit)
    local entry = {
        itemLevel = level,
        quality = Inspect.UnitQuality(unit),
        tabs = ns.Talents and ns.Talents.Tabs(ns.Talents.INSPECT) or nil,
        time = GetTime(),
        keep = whole and KEEP or KEEP_PARTIAL,
    }
    cache[guid] = entry
    finish(entry)
end

-- Whether `unit` is a player we may inspect now: not in combat, and close enough. Probe:
-- CheckInteractDistance may be restricted for addons; when it can't say, the server decides.
local function inspectable(unit)
    if InCombatLockdown() or not (NotifyInspect and CanInspect) then
        return false
    end
    local isPlayer = UnitIsPlayer(unit)
    if not (readable(isPlayer) and isPlayer) then
        return false
    end
    local isSelf = UnitIsUnit(unit, "player")
    if not readable(isSelf) or isSelf then
        return false
    end
    local can = CanInspect(unit)
    if not (readable(can) and can) then
        return false
    end
    if CheckInteractDistance then
        local ok, near = pcall(CheckInteractDistance, unit, 1)
        if ok and readable(near) and near == false then
            return false
        end
    end
    return true
end

local queued -- { unit, guid, fn }: the request that waits out the pause, the latest one only
local timerSet = false

local function addCallback(fn)
    for _, known in ipairs(pending.callbacks) do
        if known == fn then
            return
        end
    end
    pending.callbacks[#pending.callbacks + 1] = fn
end

---Asks the server for `unit`'s gear and talents, and calls `fn(entry, guid)` when it answers:
---`entry` the same table Get returns, or nil when the answer couldn't be had. Returns the answer
---kept for the unit, if there is one (and then asks nothing), or nil. Asks nothing for the player,
---a unit that isn't a player, in combat, out of range, or while Blizzard's inspect window has one
---going. A request made during the pause after the last one waits for it, and goes only if it's
---still the latest and `unit` is still the same player then. The same `fn` given again for the
---same player is called once.
---@param unit string a unit token: "mouseover", "target", ...
---@param fn fun(entry: table?, guid: string)
---@return table?
function Inspect.Request(unit, fn)
    local guid = UnitGUID(unit)
    if not (readable(guid) and guid) then
        return nil
    end
    local kept = Inspect.Get(guid)
    if kept then
        return kept
    end
    if pending and GetTime() - pending.time > WAIT then
        finish(nil)
    end
    if pending then
        if pending.guid == guid then
            addCallback(fn)
        end
        return nil -- one at a time; the next hover asks again
    end
    if not inspectable(unit) or blizzardInspecting() then
        return nil
    end
    local wait = lastSent + GAP - GetTime()
    if wait > 0 then
        queued = { unit = unit, guid = guid, fn = fn }
        if not timerSet then
            timerSet = true
            C_Timer.After(wait, function()
                timerSet = false
                local waiting = queued
                queued = nil
                local now = waiting and UnitGUID(waiting.unit)
                if waiting and not pending and readable(now) and now == waiting.guid then
                    Inspect.Request(waiting.unit, waiting.fn)
                end
            end)
        end
        return nil
    end
    pending = { guid = guid, unit = unit, time = GetTime(), callbacks = { fn } }
    lastSent = pending.time
    if not listening then
        listening = true
        ns.On("INSPECT_READY", onReady)
    end
    NotifyInspect(unit)
    return nil
end

---Forgets every answer kept past its time, for a module that turns off and won't ask again soon.
function Inspect.Prune()
    for guid, entry in pairs(cache) do
        if not fresh(entry) then
            cache[guid] = nil
        end
    end
end
