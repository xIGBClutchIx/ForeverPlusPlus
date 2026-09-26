-- Forever++ core: the shared namespace, events, saved settings, modules and the /fpp command.
-- Every other file gets the same `ns` table through `...`.
local addonName, ns = ...

local pairs, type, print, format = pairs, type, print, string.format

ns.name = addonName
ns.title = "Forever++"
ns.modules = {} -- name -> module, in ns.order
ns.order = {}

---Prints a line in chat with the addon's name in front.
---@param message string
function ns.Print(message)
    print(format("|cff33d0ffForever++|r %s", message))
end

-- Events --------------------------------------------------------------------------------------
-- One frame for the whole addon. Handlers get (event, ...).

local events = CreateFrame("Frame")
local handlers = {} -- event -> list of functions

events:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then
        return
    end
    for i = 1, #list do
        list[i](event, ...)
    end
end)

---Calls `fn(event, ...)` whenever `event` fires.
---@param event string
---@param fn fun(event: string, ...)
function ns.On(event, fn)
    local list = handlers[event]
    if not list then
        list = {}
        handlers[event] = list
        events:RegisterEvent(event)
    end
    list[#list + 1] = fn
end

---Stops calling `fn` for `event`.
---@param event string
---@param fn function
function ns.Off(event, fn)
    local old = handlers[event]
    if not old then
        return
    end
    -- Build a new list instead of removing in place: a handler may call this while OnEvent is
    -- still looping over the old one, and shifting it would skip or call a missing entry.
    local list = {}
    for i = 1, #old do
        if old[i] ~= fn then
            list[#list + 1] = old[i]
        end
    end
    handlers[event] = list
    if #list == 0 then
        handlers[event] = nil
        events:UnregisterEvent(event)
    end
end

-- Saved settings ------------------------------------------------------------------------------
-- ForeverPlusPlusDB = { modules = { [name] = { enabled = bool, ... } } }. Missing values are
-- filled from each module's defaults when the addon loads.

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

-- Modules -------------------------------------------------------------------------------------

---Creates a module: one change to the game's UI, switched on and off on its own. Give it
---`OnEnable` (and `OnDisable` if it can undo itself) and put its settings in `defaults`.
---@param name string shown in /fpp
---@param description string one line for /fpp
---@param defaults? table its settings; `enabled` defaults to true
---@return table module with .db (its saved settings) once the addon has loaded
function ns.NewModule(name, description, defaults)
    if ns.modules[name] then
        error("Forever++: a module called " .. name .. " already exists", 2)
    end
    local module = { name = name, description = description, defaults = defaults or {} }
    if module.defaults.enabled == nil then
        module.defaults.enabled = true
    end
    ns.modules[name] = module
    ns.order[#ns.order + 1] = name
    return module
end

local function enable(module)
    if module.enabled then
        return
    end
    module.enabled = true
    -- A module without OnDisable stays applied after it turns off, so don't apply it twice.
    if module.OnEnable and not module.applied then
        module:OnEnable()
    end
    module.applied = true
end

local function disable(module)
    if not module.enabled then
        return
    end
    module.enabled = false
    if module.OnDisable then
        module:OnDisable()
        module.applied = false
    else
        ns.Print(format("%s turns fully off after /reload.", module.name))
    end
end

---Loads the saved settings and enables every module that is on (called once, at PLAYER_LOGIN).
function ns.Start()
    ForeverPlusPlusDB = type(ForeverPlusPlusDB) == "table" and ForeverPlusPlusDB or {}
    ns.db = ForeverPlusPlusDB
    ns.db.modules = ns.db.modules or {}
    for _, name in pairs(ns.order) do
        local module = ns.modules[name]
        ns.db.modules[name] = ns.db.modules[name] or {}
        fill(ns.db.modules[name], module.defaults)
        module.db = ns.db.modules[name]
        if module.OnLoad then
            module:OnLoad()
        end
        if module.db.enabled then
            enable(module)
        end
    end
end

---Turns a module on or off and remembers it.
---@param name string
---@param on boolean
function ns.SetEnabled(name, on)
    local module = ns.modules[name]
    module.db.enabled = on
    if on then
        enable(module)
    else
        disable(module)
    end
end

-- /fpp ----------------------------------------------------------------------------------------

local function findModule(query)
    query = query:lower()
    for _, name in pairs(ns.order) do
        if name:lower() == query then
            return ns.modules[name]
        end
    end
end

local function list()
    ns.Print("modules (/fpp toggle <name>):")
    for _, name in pairs(ns.order) do
        local module = ns.modules[name]
        local state = module.db.enabled and "|cff44dd44on|r" or "|cffdd4444off|r"
        print(format("  %s  %s  |cff999999%s|r", state, name, module.description))
    end
end

SLASH_FOREVERPLUSPLUS1 = "/fpp"
SLASH_FOREVERPLUSPLUS2 = "/forever++"
SlashCmdList.FOREVERPLUSPLUS = function(message)
    local command, rest = strsplit(" ", strtrim(message or ""), 2)
    command = (command or ""):lower()
    if command == "toggle" and rest then
        local module = findModule(rest)
        if not module then
            ns.Print("no module called " .. rest)
            return
        end
        ns.SetEnabled(module.name, not module.db.enabled)
        ns.Print(format("%s is %s.", module.name, module.db.enabled and "on" or "off"))
    elseif command == "reset" then
        ForeverPlusPlusDB = nil
        ReloadUI()
    else
        list()
        print("  /fpp reset  |cff999999all settings back to defaults (reloads)|r")
    end
end
