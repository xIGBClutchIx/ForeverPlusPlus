-- Dungeon maps other addons have, for a module that wants to open one: the client has none of its
-- own (no dungeon-type UiMap, build 70938). Two addons draw them, and neither has a public API, so
-- each is reached the one way it can be from outside, read when called and every call protected:
-- an update of theirs that moves things makes this say "can't", never an error.
--
-- DungeonJournal (ForeverDungeonJournal, 2.0.2): its shared table ForeverDungeonJournal_NS has
-- DungeonFromInstanceName (its key for an English name), DUNGEON_MAPS (which keys have a map), and
-- OpenDungeonMap (selects the dungeon and shows its map), which needs its window open first
-- (ForeverDungeonJournal_Toggle while ForeverDungeonJournalFrame isn't shown).
--
-- Leatrix Maps (the Forever build, 1.60.31): only its slash command reaches in. "/ltm dun <word>"
-- shows the first map in its list whose English name has that word, over the world map, which must
-- be open; it says so in chat and lets the arrow keys step through its maps. Only while its Show
-- dungeon maps setting is on (LeaMapsDB, as it was at login: the setting needs a reload).
local _, ns = ...

local type, pcall, ipairs, rawget = type, pcall, ipairs, rawget

local DungeonMaps = {}
ns.DungeonMaps = DungeonMaps

---The addons that can show a map, in the order "auto" tries them.
DungeonMaps.ORDER = { "journal", "leatrix" }

-- The word that finds each instance (by instance ID) in Leatrix Maps' list: one word of its English
-- name that no earlier entry of the list has. Temple of Ahn'Qiraj has none (every word of it finds
-- the Temple of Atal'Hakkar or the Ruins first), and Blackmaw Hold isn't in the list.
local LEATRIX_WORDS = {
    [389] = "ragefire", [36] = "deadmines", [43] = "wailing", [33] = "shadowfang", [34] = "stockade",
    [48] = "blackfathom", [90] = "gnomeregan", [47] = "kraul", [189] = "monastery", [129] = "downs",
    [70] = "uldaman", [209] = "zul'farrak", [349] = "maraudon", [109] = "atal'hakkar",
    [230] = "depths", [229] = "spire", [409] = "molten", [469] = "blackwing", [429] = "dire",
    [289] = "scholomance", [329] = "stratholme", [309] = "zul'gurub", [249] = "onyxia",
    [509] = "ruins", [533] = "naxxramas", [2959] = "dalaran", [2998] = "wetlands",
    [2999] = "lordaeron", [3065] = "thanes", [2970] = "drowned", [3039] = "krol'dok",
    [2994] = "alcaz", [3001] = "shaper's",
}

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

local function leatrix()
    local saved = global("LeaMapsDB")
    local handler = type(SlashCmdList) == "table" and SlashCmdList["Leatrix_Maps"]
    if type(handler) == "function" and type(saved) == "table" and saved.ShowDungeonMaps == "On" then
        return handler
    end
end

---Whether one of the addons is there at all, whatever it has maps of.
---@param provider string "journal" or "leatrix"
---@return boolean
function DungeonMaps.Has(provider)
    if provider == "journal" then
        return journal() ~= nil
    elseif provider == "leatrix" then
        return leatrix() ~= nil
    end
    return false
end

---Whether an addon can show an instance's map.
---@param provider string "journal" or "leatrix"
---@param instanceID number? the instance's ID (389 for Ragefire Chasm)
---@param name string? its English name
---@return boolean
function DungeonMaps.Can(provider, instanceID, name)
    if provider == "journal" then
        local shared = journal()
        return shared ~= nil and type(name) == "string" and journalKey(shared, name) ~= nil
    elseif provider == "leatrix" then
        return leatrix() ~= nil and LEATRIX_WORDS[instanceID] ~= nil
    end
    return false
end

---The addon that would show an instance's map: `choice` itself, or with "auto" the first in ORDER
---that can. Nil when none can (or `choice` is "off").
---@param choice string "auto", "journal", "leatrix", or "off"
---@param instanceID number?
---@param name string?
---@return string? provider
function DungeonMaps.Which(choice, instanceID, name)
    if choice == "auto" then
        for _, provider in ipairs(DungeonMaps.ORDER) do
            if DungeonMaps.Can(provider, instanceID, name) then
                return provider
            end
        end
        return nil
    end
    return DungeonMaps.Can(choice, instanceID, name) and choice or nil
end

---Shows an instance's map in an addon. Not in combat: both draw frames of their own, and neither
---was written to be driven by another addon there.
---@param provider string "journal" or "leatrix"
---@param instanceID number?
---@param name string?
---@return boolean shown whether the addon was asked (not whether it then drew it)
function DungeonMaps.Open(provider, instanceID, name)
    if InCombatLockdown() or not DungeonMaps.Can(provider, instanceID, name) then
        return false
    end
    if provider == "journal" then
        local shared = journal()
        local key = journalKey(shared, name)
        local window = global("ForeverDungeonJournalFrame")
        local shown = type(window) == "table" and window.IsShown and window:IsShown()
        if not shown and not pcall(global("ForeverDungeonJournal_Toggle")) then
            return false
        end
        return (pcall(shared.OpenDungeonMap, key))
    end
    return (pcall(leatrix(), "dun " .. LEATRIX_WORDS[instanceID]))
end
