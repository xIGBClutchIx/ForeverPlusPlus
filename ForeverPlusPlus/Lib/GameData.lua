-- Game data a client patch can change: item, spell, and map IDs, and facts about them (the skill
-- a node needs, the weapons an oil goes on). Each set starts from a seed written in the addon and
-- adds what the game showed in play, saved for the account in ForeverPlusPlusDB.gameData, so a
-- patch that renames or adds things mends itself once a player meets them. What was learned wins
-- over the seed. Self Test lists the seed IDs the client no longer has.
--
--   local SCROLLS = ns.GameData.New("comprehendScrolls", { [211780] = true, ... }, { kind = "item" })
--   SCROLLS:Get(itemID)          -- learned value, else the seed's, else nil
--   SCROLLS:Learn(itemID, true)  -- remembered for every character
--   local PICK_LOCK = ns.GameData.Spell(1804, "Pick Lock") -- one ID Self Test checks
--
-- Learning is the module's job (from a tooltip line, the loot window, a cast); `Requires` reads
-- Blizzard's "Requires Herbalism (75)" line in any language. A helper a second module needs goes
-- here too.
local _, ns = ...

local pairs, ipairs, type, next, tonumber, tostring = pairs, ipairs, type, next, tonumber, tostring
local pcall, assert, setmetatable = pcall, assert, setmetatable
local match, sort = string.match, table.sort

local GameData = {}
ns.GameData = GameData

local sets, order = {}, {} -- name -> set; names in the order made
local singles = {} -- { kind, id, label } for GameData.Item/Spell/Map

-- Whether an ID of each kind is in this client's data. Probes: each call is Mainline's.
local EXISTS = {
    item = function(id)
        return C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(id) ~= nil
    end,
    spell = function(id)
        if C_Spell and C_Spell.DoesSpellExist then
            return C_Spell.DoesSpellExist(id)
        end
        return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) ~= nil
    end,
    map = function(id)
        return C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id) ~= nil
    end,
}

-- The client build, to tag what was learned with.
local function build()
    local _, number = GetBuildInfo and GetBuildInfo()
    return number
end

-- Whether two values are the same: scalars, or tables with the same scalars (one level deep).
local function same(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    for key, value in pairs(a) do
        if b[key] ~= value then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

local Set = {}
Set.__index = Set

local EMPTY = {} -- what a set that has learned nothing reads; never written to

-- The set's learned values (and the saved table holding them): saved once the saved variables are
-- loaded, kept in memory before (anything learned that early moves into the saved table on the
-- next call). A set gets a saved table only once it has something to keep, or with `create`.
local function store(set, create)
    local db = ns.db
    if not db then
        return set.early
    end
    local all = db.gameData
    local saved = type(all) == "table" and type(all[set.name]) == "table" and all[set.name] or nil
    if not saved and (create or next(set.early)) then
        if type(all) ~= "table" then
            all = {}
            db.gameData = all
        end
        saved = { values = {} }
        all[set.name] = saved
    end
    if not saved then
        return EMPTY
    end
    if type(saved.values) ~= "table" then
        saved.values = {}
    end
    if next(set.early) then
        for key, value in pairs(set.early) do
            saved.values[key] = value
        end
        set.early = {}
        saved.build = build()
    end
    return saved.values, saved
end

---A set of game data: `seed` is what the addon ships (key -> value), and what was learned in game
---is added on top. With `kind` ("item", "spell", or "map"), the seed's keys are IDs of that kind
---and Self Test checks the client still has them. Names are unique across the addon.
---@param name string the set's name in the saved variables, such as "comprehendScrolls"
---@param seed table key -> value
---@param options? table { kind = "item"|"spell"|"map", label = string for Self Test }
---@return table set
function GameData.New(name, seed, options)
    assert(not sets[name], "GameData set made twice: " .. tostring(name))
    options = options or {}
    local set = setmetatable({
        name = name,
        seed = seed or {},
        kind = options.kind,
        label = options.label or name,
        early = {},
    }, Set)
    sets[name] = set
    order[#order + 1] = name
    return set
end

---The value for `key`: what was learned, else the seed's, else nil.
---@param key any
---@return any
function Set:Get(key)
    local learned = store(self)[key]
    if learned ~= nil then
        return learned
    end
    return self.seed[key]
end

---Remembers `value` for `key` for every character. A value the seed already has isn't saved (and
---drops an older learned one), so a seed fixed in a later release takes over again.
---@param key any
---@param value any a scalar, or a table of scalars
---@return boolean changed whether Get gives something new now
function Set:Learn(key, value)
    if key == nil or value == nil then
        return false
    end
    local values, saved = store(self, true)
    local before = self:Get(key)
    if same(value, self.seed[key]) then
        values[key] = nil
    else
        values[key] = value
        if saved then
            saved.build = build()
        end
    end
    return not same(before, value)
end

---Forgets what was learned for `key`, or for every key without one.
---@param key any
function Set:Forget(key)
    local values = store(self)
    if key == nil then
        for k in pairs(values) do
            values[k] = nil
        end
    else
        values[key] = nil
    end
end

---Every key and value, learned ones over the seed's, in no order.
---@return function iterator
---@return table state
function Set:Pairs()
    local merged = {}
    for key, value in pairs(self.seed) do
        merged[key] = value
    end
    for key, value in pairs(store(self)) do
        merged[key] = value
    end
    return next, merged
end

---How many values were learned.
---@return number
function Set:Learned()
    local count = 0
    for _ in pairs(store(self)) do
        count = count + 1
    end
    return count
end

-- Single IDs ------------------------------------------------------------------------------------

local function single(kind, id, label)
    singles[#singles + 1] = { kind = kind, id = id, label = label }
    return id
end

---An item ID the addon depends on, for Self Test to check. Returns `id`.
---@param id number
---@param label string what it is, in English (Self Test's log)
---@return number
function GameData.Item(id, label)
    return single("item", id, label)
end

---A spell ID the addon depends on, for Self Test to check. Returns `id`.
---@param id number
---@param label string
---@return number
function GameData.Spell(id, label)
    return single("spell", id, label)
end

---A map ID the addon depends on, for Self Test to check. Returns `id`.
---@param id number
---@param label string
---@return number
function GameData.Map(id, label)
    return single("map", id, label)
end

-- Reading the game ------------------------------------------------------------------------------

local requires -- the pattern for Blizzard's "Requires %s (%d)", made on first use

---The skill and rank in Blizzard's requirement line ("Requires Herbalism (75)", "Requires
---Lockpicking (25)"), in the client's language, or nil when `text` isn't one. `text` should be
---plain (ns.Text.Plain) and readable.
---@param text string
---@return string? skill its name as the client writes it
---@return number? rank
function GameData.Requires(text)
    if type(text) ~= "string" then
        return nil
    end
    if not requires then
        requires = "^%s*" .. ns.Text.FormatPattern(ITEM_MIN_SKILL or "Requires %s (%d)", true) .. "%s*$"
    end
    local skill, rank = match(text, requires)
    rank = tonumber(rank)
    if skill and rank then
        return skill, rank
    end
end

---The first requirement line in tooltip data (C_TooltipInfo's), after the title: its skill, rank,
---and line index, or nil.
---@param data table?
---@return string? skill
---@return number? rank
---@return number? index
function GameData.TooltipRequires(data)
    local lines = data and ns.IsReadable(data.lines) and data.lines
    if type(lines) ~= "table" then
        return nil
    end
    for i = 2, #lines do
        local text = lines[i] and lines[i].leftText
        if ns.IsReadable(text) and type(text) == "string" then
            local skill, rank = GameData.Requires(ns.Text.Plain(text))
            if skill then
                return skill, rank, i
            end
        end
    end
end

-- Self Test ----------------------------------------------------------------------------------------

local function exists(kind, id)
    local check = EXISTS[kind]
    if not check or type(id) ~= "number" then
        return nil
    end
    local ok, found = pcall(check, id)
    if not ok or not ns.IsReadable(found) then
        return nil
    end
    return found and true or false
end

---What Self Test reports: for each set, its seed IDs the client doesn't have and how many values
---were learned, then every single ID that's missing.
---@return table sets { { label, kind, size, learned, build, missing = { id, ... } }, ... }
---@return table singles { { kind, id, label, found = true|false|nil }, ... }
function GameData.Audit()
    local report = {}
    for _, name in ipairs(order) do
        local set = sets[name]
        local missing, size = {}, 0
        for key in pairs(set.seed) do
            size = size + 1
            if set.kind and exists(set.kind, key) == false then
                missing[#missing + 1] = key
            end
        end
        sort(missing)
        local _, saved = store(set)
        report[#report + 1] = {
            label = set.label, kind = set.kind, size = size, learned = set:Learned(),
            build = saved and saved.build, missing = missing,
        }
    end
    local ids = {}
    for _, entry in ipairs(singles) do
        ids[#ids + 1] = { kind = entry.kind, id = entry.id, label = entry.label,
            found = exists(entry.kind, entry.id) }
    end
    return report, ids
end

---Forgets everything learned, in every set.
function GameData.ForgetAll()
    for _, name in ipairs(order) do
        sets[name]:Forget()
    end
    if ns.db then
        ns.db.gameData = nil
    end
end
