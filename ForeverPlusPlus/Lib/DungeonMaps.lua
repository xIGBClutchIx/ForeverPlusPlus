-- Dungeon maps another addon has, for a module that wants to open one: the client has none of its
-- own (no dungeon-type UiMap, build 70938). DungeonJournal (ForeverDungeonJournal, 2.0.2) draws
-- them. It has no public API, so it's reached through what it leaves in reach, read when called
-- and every call protected: an update of its that moves things makes this say "can't", never an
-- error. Its shared table ForeverDungeonJournal_NS has DungeonFromInstanceName (its key for an
-- English name), DUNGEON_MAPS (which keys have a map), and OpenDungeonMap (selects the dungeon and
-- shows its map), which needs its window open first (ForeverDungeonJournal_Toggle while
-- ForeverDungeonJournalFrame isn't shown).
--
-- Leatrix Maps draws them too, but only its slash command reaches in ("/ltm dun <word>", which
-- writes to chat and turns on its arrow keys), so it's left out.
local _, ns = ...

local type, pcall, rawget = type, pcall, rawget

local DungeonMaps = {}
ns.DungeonMaps = DungeonMaps

-- A global of another addon, or nil. rawget, so a strict _G of someone's doesn't complain.
local function global(name)
    return rawget(_G, name)
end

local function journal()
    local shared = global("ForeverDungeonJournal_NS")
    if type(shared) == "table" and type(shared.OpenDungeonMap) == "function"
        and type(shared.DungeonFromInstanceName) == "function" and type(shared.DUNGEON_MAPS) == "table"
        and type(global("ForeverDungeonJournal_Toggle")) == "function" then
        return shared
    end
end

-- DungeonJournal's key for an instance that has a map there, or nil.
local function journalKey(shared, name)
    local ok, key = pcall(shared.DungeonFromInstanceName, name)
    if ok and key ~= nil and shared.DUNGEON_MAPS[key] then
        return key
    end
end

---Whether DungeonJournal is there, whatever it has maps of.
---@return boolean
function DungeonMaps.Has()
    return journal() ~= nil
end

---Whether it can show an instance's map.
---@param name string? the instance's English name
---@return boolean
function DungeonMaps.Can(name)
    local shared = journal()
    return shared ~= nil and type(name) == "string" and journalKey(shared, name) ~= nil
end

---Shows an instance's map in DungeonJournal. Not in combat: it draws frames of its own, and wasn't
---written to be driven by another addon there.
---@param name string? the instance's English name
---@return boolean asked whether it was asked (not whether it then drew it)
function DungeonMaps.Open(name)
    if InCombatLockdown() or not DungeonMaps.Can(name) then
        return false
    end
    local shared = journal()
    local key = journalKey(shared, name)
    local window = global("ForeverDungeonJournalFrame")
    local shown = type(window) == "table" and window.IsShown and window:IsShown()
    if not shown and not pcall(global("ForeverDungeonJournal_Toggle")) then
        return false
    end
    return (pcall(shared.OpenDungeonMap, key))
end
