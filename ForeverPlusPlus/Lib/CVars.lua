-- Changing game settings (CVars) from a module, and putting the player's own values back.
-- Each module keeps the originals in its own saved table (usually a field of module.db), so they
-- survive a reload and two modules don't lose each other's. Many CVars (nameplates among them)
-- can't change in combat, so changes made then wait for it to end, in order.
local _, ns = ...

local type, pairs, InCombatLockdown, C_CVar = type, pairs, InCombatLockdown, C_CVar

local CVars = {}
ns.CVars = CVars

local queue = {} -- functions waiting for combat to end

local function flush()
    ns.Off("PLAYER_REGEN_ENABLED", flush)
    local waiting = queue
    queue = {}
    for i = 1, #waiting do
        waiting[i]()
    end
end

local function run(fn)
    if InCombatLockdown() then
        if #queue == 0 then
            ns.On("PLAYER_REGEN_ENABLED", flush)
        end
        queue[#queue + 1] = fn
    else
        fn()
    end
end

-- The first of `names` this client knows. CVars get renamed between patches, so callers can list
-- the names a setting has had, newest first.
local function find(names)
    if type(names) == "string" then
        names = { names }
    end
    for i = 1, #names do
        if C_CVar.GetCVar(names[i]) ~= nil then
            return names[i]
        end
    end
end

---Sets a CVar, remembering the player's value in `saved` the first time.
---@param saved table the owner's saved originals (CVar -> value)
---@param names string|string[] the CVar, or its names newest first
---@param value string
function CVars.Set(saved, names, value)
    run(function()
        local name = find(names)
        if not name then
            return
        end
        local current = C_CVar.GetCVar(name)
        if current ~= value then
            if saved[name] == nil then
                saved[name] = current
            end
            C_CVar.SetCVar(name, value)
        end
    end)
end

---Puts one CVar back to the player's value, if `saved` changed it.
---@param saved table
---@param names string|string[]
function CVars.Restore(saved, names)
    run(function()
        local name = find(names)
        if name and saved[name] ~= nil then
            C_CVar.SetCVar(name, saved[name])
            saved[name] = nil
        end
    end)
end

---Puts back every CVar in `saved`.
---@param saved table
function CVars.RestoreAll(saved)
    run(function()
        for name, value in pairs(saved) do
            C_CVar.SetCVar(name, value)
            saved[name] = nil
        end
    end)
end
