-- How Forever++'s saved variables are laid out, the steps that bring an older layout up to date,
-- and the table each module reads its settings and data through (`module.db`).
--
--   ForeverPlusPlusDB = {
--       version = 4,            -- the layout, so each step below runs once
--       settings = { [module] = { [key] = value } },  -- only what the player changed
--       data = { [module] = { [key] = table } },      -- what modules collect: prices, flight times
--       unclaimed = { [module] = { [key] = table } }, -- per-character data from version 1, until
--                                                     -- each character logs in and takes its own
--       gameData = { [set] = { values, build } },     -- what play taught Lib/GameData.lua
--       seenVersion, seenModules, welcome, showTags, changelogByModule, selfTest, ...
--                                                     -- the core's own
--   }
--   ForeverPlusPlusCharDB = { version = 4, data = { [module] = { [key] = table } } }
--
-- A module's settings are its scalar defaults: a value equal to the default isn't saved, so a
-- better default reaches everyone who never changed it. Its data is every default that is a table;
-- presets and Defaults never touch it. Keys listed in `module.perCharacter` keep their data in the
-- character's table instead of the account's.
local _, ns = ...

local pairs, ipairs, type, next, setmetatable, sort = pairs, ipairs, type, next, setmetatable, table.sort

local Store = {}
ns.Store = Store

Store.VERSION = 4

-- `t[key]`, made a table first when it isn't one.
local function child(t, key)
    local value = t[key]
    if type(value) ~= "table" then
        value = {}
        t[key] = value
    end
    return value
end

-- Steps -----------------------------------------------------------------------------------------
-- A step brings the saved variables from the version before its own to its own. Each runs once:
-- the version saved says which have run.

local steps, characterSteps = {}, {}

local function add(list, version, fn)
    list[#list + 1] = { version = version, fn = fn, order = #list }
end

local function run(list, from, ...)
    local due = {}
    for _, step in ipairs(list) do
        if step.version > from then
            due[#due + 1] = step
        end
    end
    sort(due, function(a, b)
        if a.version ~= b.version then
            return a.version < b.version
        end
        return a.order < b.order
    end)
    for _, step in ipairs(due) do
        -- Through ns.Call when the core is there, so one broken step doesn't stop the others.
        if ns.Call then
            ns.Call(step.fn, ...)
        else
            step.fn(...)
        end
    end
end

---Adds a step for the account's saved variables: `fn(db)` gets ForeverPlusPlusDB once, when the
---saved version is older than `version`. Version 1 steps work on the 0.8 layout (`db.modules`,
---every module's settings and data by module name); later ones on the layout above.
---@param version integer
---@param fn fun(db: table)
function Store.Step(version, fn)
    add(steps, version, fn)
end

---Adds a step for a character's saved variables: `fn(char, db)` gets ForeverPlusPlusCharDB and
---ForeverPlusPlusDB once per character, when its saved version is older than `version`. Use it to
---take this character's part of `db.unclaimed`.
---@param version integer
---@param fn fun(char: table, db: table)
function Store.CharacterStep(version, fn)
    add(characterSteps, version, fn)
end

---Runs the steps the saved variables haven't had and marks them current. A fresh install (an empty
---table) has nothing to bring up to date.
---@param db table ForeverPlusPlusDB
---@param char table ForeverPlusPlusCharDB
---@return boolean fresh true when `db` was empty
function Store.Upgrade(db, char)
    local fresh = next(db) == nil
    if fresh then
        db.version = Store.VERSION
    end
    run(steps, db.version or 0, db)
    db.version = Store.VERSION
    run(characterSteps, char.version or 0, char, db)
    char.version = Store.VERSION
    return fresh
end

-- Version 2: settings apart from data -------------------------------------------------------------

---Splits the 0.8 layout's `db.modules` into `settings` and `data`: tables are data, the rest
---settings. Per-character data (`perCharacter[module][key]`, keyed by character inside) goes to
---`unclaimed` for each character to take. Settings equal to their default are dropped later, by
---Store.Load, which knows the defaults.
---@param db table
---@param perCharacter table<string, table<string, boolean>>
function Store.Split(db, perCharacter)
    db.settings, db.data, db.unclaimed = db.settings or {}, db.data or {}, db.unclaimed or {}
    for name, saved in pairs(db.modules or {}) do
        if type(saved) == "table" then
            for key, value in pairs(saved) do
                local into = db.settings
                if type(value) == "table" and next(value) == nil then
                    into = nil -- nothing collected yet; Store.Load makes it again
                elseif type(value) == "table" then
                    into = perCharacter[name] and perCharacter[name][key] and db.unclaimed or db.data
                end
                if into then
                    into[name] = into[name] or {}
                    into[name][key] = value
                end
            end
        end
    end
    db.modules = nil
end

---Renames modules everywhere the account keeps them by name: settings, data, unclaimed data, and
---the version each was last seen in. `names` is { [old] = new }.
---@param db table
---@param names table<string, string>
function Store.Rename(db, names)
    for _, part in ipairs({ "settings", "data", "unclaimed", "seenModules" }) do
        local byName = db[part]
        if type(byName) == "table" then
            for old, new in pairs(names) do
                if byName[old] ~= nil and byName[new] == nil then
                    byName[new] = byName[old]
                end
                byName[old] = nil
            end
        end
    end
end

---For a character step: takes this character's part of `db.unclaimed[name][key]` (data version 1
---kept for every character, by a key of each) into the character's own data, and drops what's
---left empty. `take(entries)` removes this character's entries and returns them as the table the
---module now keeps, or nil when it had none.
---@param char table
---@param db table
---@param name string the module
---@param key string its per-character data
---@param take fun(entries: table): table?
function Store.Claim(char, db, name, key, take)
    local byKey = db.unclaimed and db.unclaimed[name]
    local entries = byKey and byKey[key]
    if type(entries) ~= "table" then
        return
    end
    local part = take(entries)
    if type(part) == "table" then
        local own = child(child(char, "data"), name)
        own[key] = part
    end
    if next(entries) == nil then
        byKey[key] = nil
        if next(byKey) == nil then
            db.unclaimed[name] = nil
        end
    end
end

-- Loading -----------------------------------------------------------------------------------------

local function isData(defaults, key)
    return type(defaults[key]) == "table"
end

-- Fills `target` with what it lacks of `defaults`, tables inside too.
local function fill(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            fill(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

---Gets a module's saved settings and data ready and returns the table it reads them through:
---a setting reads what the player chose or else its default, and setting it back to the default
---forgets the choice; a data key reads its table, in the account's or the character's saved
---variables. Settings and data the defaults no longer have are dropped, and so are settings equal
---to their default.
---@param db table ForeverPlusPlusDB
---@param char table ForeverPlusPlusCharDB
---@param name string
---@param defaults table
---@param perCharacter? table<string, boolean>
---@return table view
function Store.Load(db, char, name, defaults, perCharacter)
    perCharacter = perCharacter or {}
    -- Looked up on each use, not kept: Store.Tidy drops empty tables before the game saves, and
    -- a write after it (a module saving at logout) makes them again.
    local function settingsTable()
        return child(child(db, "settings"), name)
    end
    local function dataTable(key)
        return child(child(perCharacter[key] and char or db, "data"), name)
    end
    local function dataFor(key)
        local store = dataTable(key)
        if type(store[key]) ~= "table" then
            store[key] = {}
        end
        fill(store[key], defaults[key])
        return store[key]
    end
    local settings = settingsTable()
    for key, value in pairs(settings) do
        if defaults[key] == nil or isData(defaults, key) or value == defaults[key] then
            settings[key] = nil
        end
    end
    for _, store in ipairs({ child(child(db, "data"), name), child(child(char, "data"), name) }) do
        for key in pairs(store) do
            if not isData(defaults, key) or dataTable(key) ~= store then
                store[key] = nil
            end
        end
    end
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            dataFor(key)
        end
    end
    return setmetatable({}, {
        __index = function(_, key)
            if isData(defaults, key) then
                local store = dataTable(key)
                return type(store[key]) == "table" and store[key] or dataFor(key)
            end
            local value = settingsTable()[key]
            if value == nil then
                return defaults[key]
            end
            return value
        end,
        __newindex = function(_, key, value)
            if isData(defaults, key) then
                dataTable(key)[key] = value
            elseif value == defaults[key] then
                settingsTable()[key] = nil
            else
                settingsTable()[key] = value
            end
        end,
    })
end

-- Whether a table holds nothing but empty tables, all the way down.
local function hollow(t)
    for _, value in pairs(t) do
        if type(value) ~= "table" or not hollow(value) then
            return false
        end
    end
    return true
end

---Drops what's left empty before the game writes the saved variables (at logout or /reload):
---a module with no changed settings, and data with nothing collected, which Store.Load makes
---again. Keeps the file to what was actually saved.
---@param db table
---@param char table
function Store.Tidy(db, char)
    for _, byName in ipairs({ db.settings or {}, db.data or {}, db.unclaimed or {}, char.data or {} }) do
        for name, byKey in pairs(byName) do
            for key, value in pairs(byKey) do
                if type(value) == "table" and hollow(value) then
                    byKey[key] = nil
                end
            end
            if next(byKey) == nil then
                byName[name] = nil
            end
        end
    end
end

---Drops the settings and data of modules that no longer exist. `known` is { [name] = true }.
---@param db table
---@param char table
---@param known table<string, boolean>
function Store.Prune(db, char, known)
    for _, byName in ipairs({ db.settings or {}, db.data or {}, char.data or {} }) do
        for name in pairs(byName) do
            if not known[name] then
                byName[name] = nil
            end
        end
    end
end
