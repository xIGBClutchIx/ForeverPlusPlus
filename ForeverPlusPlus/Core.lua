-- Forever++ core: the shared namespace, events, saved settings, modules and the /fpp command.
-- Every other file gets the same `ns` table through `...`.
local addonName, ns = ...

local pairs, ipairs, type, print, format, tostring = pairs, ipairs, type, print, string.format, tostring
local concat, strsplit, strtrim = table.concat, strsplit, strtrim
local InCombatLockdown, GetLocale = InCombatLockdown, GetLocale

ns.name = addonName
ns.title = "Forever++"
ns.modules = {} -- name -> module, in ns.order
ns.order = {}

---Prints a line in chat with the addon's name in front.
---@param message string
function ns.Print(message)
    print(format("|cff33d0ffForever++|r %s", message))
end

-- Locale --------------------------------------------------------------------------------------
-- ns.L.KEY is player-facing text in the client's language. Every key is in Locales/enUS.lua;
-- another locale's file sets only what it translates, and the rest falls back to enUS.

local enUS = {}
local L = setmetatable({}, {
    __index = function(_, key)
        return enUS[key] or key -- a missing key shows as itself instead of erroring
    end,
})
ns.L = L

---Returns the table a locale file fills with its strings, or nil when the client uses another
---language (the file then stops). enUS is always filled, since it's the fallback.
---@param locale string a GetLocale() code, such as "enUS" or "deDE"
---@return table|nil
function ns.NewLocale(locale)
    if locale == "enUS" then
        return enUS
    elseif locale == GetLocale() then
        return L
    end
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

-- Combat --------------------------------------------------------------------------------------
-- Protected frames and many CVars can't change in combat; changes made then wait for it to end.

local afterCombat = {} -- functions waiting, in order

local function runAfterCombat()
    ns.Off("PLAYER_REGEN_ENABLED", runAfterCombat)
    local waiting = afterCombat
    afterCombat = {}
    for i = 1, #waiting do
        waiting[i]()
    end
end

---Calls `fn` now, or once combat ends if the player is in combat. Calls run in the order made.
---@param fn function
function ns.AfterCombat(fn)
    if not InCombatLockdown() then
        fn()
        return
    end
    if #afterCombat == 0 then
        ns.On("PLAYER_REGEN_ENABLED", runAfterCombat)
    end
    afterCombat[#afterCombat + 1] = fn
end

-- Saved settings ------------------------------------------------------------------------------
-- ForeverPlusPlusDB = { modules = { [name] = { enabled = bool, ... } } }. Missing values are
-- filled from each module's defaults when the addon loads, and settings no module defines any
-- more (a removed module or option) are dropped.

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

-- Resets dropdown settings whose saved value is no longer one of the choices.
local function checkChoices(module)
    for _, option in pairs(module.options or {}) do
        if option.choices then
            local valid = false
            for _, choice in pairs(option.choices) do
                valid = valid or choice[1] == module.db[option.key]
            end
            if not valid then
                module.db[option.key] = module.defaults[option.key]
            end
        end
    end
end

-- Drops a module's top-level settings that its defaults no longer have. Only the top level:
-- tables inside (like a module's saved CVars) hold data, not settings.
local function prune(target, defaults)
    for key in pairs(target) do
        if defaults[key] == nil then
            target[key] = nil
        end
    end
end

-- Modules -------------------------------------------------------------------------------------

---Creates a module: one change to the game's UI, switched on and off on its own. Give it
---`OnEnable` (and `OnDisable` if it can undo itself) and put its settings in `defaults`. Set
---`module.title` for a friendlier name in Settings (the name stays the /fpp key).
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
        ns.Print(format(L.OFF_AFTER_RELOAD, module.name))
    end
end

---Loads the saved settings and enables every module that is on (called once, at PLAYER_LOGIN).
function ns.Start()
    ForeverPlusPlusDB = type(ForeverPlusPlusDB) == "table" and ForeverPlusPlusDB or {}
    ns.db = ForeverPlusPlusDB
    ns.db.modules = ns.db.modules or {}
    for name in pairs(ns.db.modules) do
        if not ns.modules[name] then
            ns.db.modules[name] = nil
        end
    end
    for _, name in pairs(ns.order) do
        local module = ns.modules[name]
        ns.db.modules[name] = ns.db.modules[name] or {}
        prune(ns.db.modules[name], module.defaults)
        fill(ns.db.modules[name], module.defaults)
        module.db = ns.db.modules[name]
        checkChoices(module)
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

---Changes one of a module's options (from `module.options`) and tells the module.
---@param name string
---@param key string
---@param value any
function ns.SetOption(name, key, value)
    local module = ns.modules[name]
    module.db[key] = value
    if module.OnOptionChanged then
        module:OnOptionChanged(key)
    end
end

-- /fpp ----------------------------------------------------------------------------------------

local commands, commandOrder = {}, {} -- name -> { usage, description, fn }, and their order

---Adds `/fpp <name>`, for a module's own command. `fn` gets the text typed after the name.
---@param name string one lowercase word
---@param usage string what follows the name in /fpp help, or ""
---@param description string one line for /fpp help
---@param fn fun(rest: string)
function ns.AddCommand(name, usage, description, fn)
    commands[name] = { usage = usage, description = description, fn = fn }
    commandOrder[#commandOrder + 1] = name
end

local function findModule(query)
    query = query:lower()
    for _, name in pairs(ns.order) do
        if name:lower() == query then
            return ns.modules[name]
        end
    end
end

local function list()
    ns.Print(L.SLASH_MODULES)
    for _, name in pairs(ns.order) do
        local module = ns.modules[name]
        local state = module.db.enabled and format("|cff44dd44%s|r", L.ON)
            or format("|cffdd4444%s|r", L.OFF)
        print(format("  %s  %s  |cff999999%s|r", state, name, module.description))
    end
end

-- /fpp options and /fpp set work on any module's `module.options`: a checkbox takes on/off, a
-- dropdown takes one of its choice keys. `enabled` is the module's own on/off.

local booleans = { on = true, off = false, ["true"] = true, ["false"] = false, yes = true,
    no = false, ["1"] = true, ["0"] = false }

local function findOption(module, query)
    query = query:lower()
    for _, option in ipairs(module.options or {}) do
        if option.key:lower() == query then
            return option
        end
    end
end

-- "on", "off", or the choice key, and what it may be set to.
local function describe(module, option)
    local value = module.db[option.key]
    if not option.choices then
        return value and "on" or "off", "on, off"
    end
    local keys = {}
    for i, choice in ipairs(option.choices) do
        keys[i] = choice[1]
    end
    return tostring(value), concat(keys, ", ")
end

local function listOptions(module)
    ns.Print(format(L.OPTIONS_HEADER, module.name, module.db.enabled and L.ON or L.OFF,
        module.name))
    if not module.options or #module.options == 0 then
        print(format("  |cff999999%s|r", L.OPTIONS_NONE))
    end
    for _, option in ipairs(module.options or {}) do
        local value, allowed = describe(module, option)
        print(format("  %s = |cffffd100%s|r  |cff999999%s (%s)%s|r", option.key, value, option.name,
            allowed, option.debug and L.OPTIONS_DEBUG or ""))
    end
end

-- /fpp set <module> <option> [value]. Without a value it only shows the current one and what it
-- can be, and changes nothing.
local function set(rest)
    local moduleName, key, value = strsplit(" ", rest or "", 3)
    local module = moduleName and moduleName ~= "" and findModule(moduleName)
    if not module then
        ns.Print(moduleName and moduleName ~= "" and format(L.NO_MODULE, moduleName)
            or L.SET_USAGE)
        return
    end
    if not key or key == "" then
        listOptions(module)
        return
    end
    value = value and strtrim(value):lower()
    if key:lower() == "enabled" then
        local on = booleans[value or ""]
        if on == nil then
            ns.Print(format(L.MODULE_STATE_ALLOWED, module.name,
                module.db.enabled and L.ON or L.OFF))
            return
        end
        ns.SetEnabled(module.name, on)
        ns.RefreshSetting(module.name)
        ns.Print(format(L.MODULE_STATE, module.name, on and L.ON or L.OFF))
        return
    end
    local option = findOption(module, key)
    if not option then
        ns.Print(format(L.NO_OPTION, module.name, key, module.name))
        return
    end
    local new
    if option.choices then
        for _, choice in ipairs(option.choices) do
            if choice[1]:lower() == value then
                new = choice[1]
            end
        end
    elseif value then
        new = booleans[value]
    end
    if new == nil then
        local current, allowed = describe(module, option)
        ns.Print(format(L.OPTION_STATE_ALLOWED, module.name, option.key, current, allowed))
        if option.description then
            print(format("  |cff999999%s: %s|r", option.name, option.description))
        end
        return
    end
    ns.SetOption(module.name, option.key, new)
    ns.RefreshSetting(module.name)
    ns.Print(format(L.OPTION_STATE, module.name, option.key, (describe(module, option))))
end

SLASH_FOREVERPLUSPLUS1 = "/fpp"
SLASH_FOREVERPLUSPLUS2 = "/forever++"
SlashCmdList.FOREVERPLUSPLUS = function(message)
    local command, rest = strsplit(" ", strtrim(message or ""), 2)
    command = (command or ""):lower()
    if commands[command] then
        commands[command].fn(rest or "")
    elseif command == "toggle" and rest and rest:find(" ") then
        set(rest) -- /fpp toggle <module> <option> [value]
    elseif command == "toggle" and rest then
        local module = findModule(rest)
        if not module then
            ns.Print(format(L.NO_MODULE, rest))
            return
        end
        ns.SetEnabled(module.name, not module.db.enabled)
        ns.RefreshSetting(module.name)
        ns.Print(format(L.MODULE_STATE, module.name, module.db.enabled and L.ON or L.OFF))
    elseif command == "set" then
        set(rest)
    elseif command == "options" and rest then
        local module = findModule(rest)
        if module then
            listOptions(module)
        else
            ns.Print(format(L.NO_MODULE, rest))
        end
    elseif command == "reset" then
        ForeverPlusPlusDB = nil
        ReloadUI()
    elseif command == "list" or command == "help" or not ns.OpenSettings() then
        list()
        for _, line in ipairs(ns.Commands()) do
            print(format("  %s  |cff999999%s|r", line[1], line[2]))
        end
    end
end

---Every /fpp command, built in and added by modules, for help text and the About page.
---@return table lines { { "/fpp ...", description }, ... }
function ns.Commands()
    local lines = {
        { "/fpp", L.SLASH_OPEN },
        { "/fpp list", L.SLASH_LIST },
        { "/fpp toggle <module>", L.SLASH_TOGGLE },
        { "/fpp options <module>", L.SLASH_OPTIONS },
        { "/fpp set <module> <option> <value>", L.SLASH_SET },
        { "/fpp reset", L.SLASH_RESET },
    }
    for _, name in ipairs(commandOrder) do
        local info = commands[name]
        local usage = info.usage ~= "" and " " .. info.usage or ""
        lines[#lines + 1] = { format("/fpp %s%s", name, usage), info.description }
    end
    return lines
end
