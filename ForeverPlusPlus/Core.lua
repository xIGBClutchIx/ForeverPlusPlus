-- Forever++ core: the shared namespace, events, saved settings, modules and the /fpp command.
-- Every other file gets the same `ns` table through `...`.
local addonName, ns = ...

local pairs, ipairs, type, print, format, tostring = pairs, ipairs, type, print, string.format, tostring
local tonumber, floor, min, max = tonumber, math.floor, math.min, math.max
local concat, strsplit, strtrim, setmetatable = table.concat, strsplit, strtrim, setmetatable
local InCombatLockdown, GetLocale, hooksecurefunc, _G = InCombatLockdown, GetLocale, hooksecurefunc, _G

-- Calls a function so that an error in it is reported but doesn't stop the caller, so one broken
-- handler can't stop the others. Probe: securecallfunction is Mainline's; without it, call plainly.
local call = securecallfunction or function(fn, ...)
    return fn(...)
end
ns.Call = call -- for the Lib files that run other files' callbacks

ns.name = addonName
ns.title = "Forever++"
ns.icon = "Interface\\AddOns\\" .. addonName .. "\\Media\\Icon" -- also the TOC's IconTexture
ns.modules = {} -- name -> module, in ns.order
ns.order = {}

---Prints a line in chat with the addon's name in front.
---@param message string
function ns.Print(message)
    print(format("|cff33d0ffForever++|r %s", message))
end

---"On" in green or "Off" in red, for a module's state.
---@param on boolean
---@return string
function ns.StateText(on)
    return on and format("|cff44dd44%s|r", ns.L.ON) or format("|cffdd4444%s|r", ns.L.OFF)
end

-- Locale --------------------------------------------------------------------------------------
-- ns.L.KEY is player-facing text in the client's language. Every key is in Locales/enUS/;
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
        call(list[i], event, ...)
    end
end)

---Calls `fn(event, ...)` whenever `event` fires. Adding the same `fn` twice changes nothing.
---@param event string
---@param fn fun(event: string, ...)
function ns.On(event, fn)
    local list = handlers[event]
    if not list then
        list = {}
        handlers[event] = list
        events:RegisterEvent(event)
    end
    for i = 1, #list do
        if list[i] == fn then
            return
        end
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
        call(waiting[i])
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

---A slider option's value brought into its range and onto its steps, or nil when it isn't a
---number.
---@param option table an option with `min`, `max` and `step`
---@param value any
---@return number?
function ns.SliderValue(option, value)
    value = tonumber(value)
    if not value then
        return nil
    end
    local step = option.step or 1
    value = option.min + floor((value - option.min) / step + 0.5) * step
    return max(option.min, min(option.max, value))
end

-- Resets dropdown settings whose saved value is no longer one of the choices, and brings slider
-- settings back into their range.
local function checkValues(module)
    for _, option in pairs(module.options or {}) do
        local value = module.db[option.key]
        if option.choices then
            local valid = false
            for _, choice in pairs(option.choices) do
                valid = valid or choice[1] == value
            end
            if not valid then
                module.db[option.key] = module.defaults[option.key]
            end
        elseif option.min then
            module.db[option.key] = ns.SliderValue(option, value) or module.defaults[option.key]
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

-- Methods every module has.
local Module = {}
Module.__index = Module

---Like ns.On, but the module remembers it and turns it off by itself when the module turns off.
---Use it for events the module listens to while it's on.
---@param event string
---@param fn fun(event: string, ...)
function Module:On(event, fn)
    self.events = self.events or {}
    self.events[#self.events + 1] = { event, fn }
    ns.On(event, fn)
end

---Stops one event added with `module:On` before the module turns off.
---@param event string
---@param fn function
function Module:Off(event, fn)
    ns.Off(event, fn)
    local list = {}
    for _, entry in ipairs(self.events or {}) do
        if entry[1] ~= event or entry[2] ~= fn then
            list[#list + 1] = entry
        end
    end
    self.events = list
end

-- Hooks once per module, target, method and function, so `OnEnable` can ask for them every time
-- it runs. The hook itself can't come off, so it does nothing while the module is off.
local function hookOnce(module, target, method, fn, install)
    local hooked = module.hooked
    if not hooked then
        hooked = {}
        module.hooked = hooked
    end
    local byMethod = hooked[target]
    if not byMethod then
        byMethod = {}
        hooked[target] = byMethod
    end
    local byFn = byMethod[method]
    if not byFn then
        byFn = {}
        byMethod[method] = byFn
    end
    if not byFn[fn] then
        byFn[fn] = true
        install(function(...)
            if module.enabled then
                fn(...)
            end
        end)
    end
end

---Calls `fn` after a function or method of a Blizzard object runs (`hooksecurefunc`), but only
---while the module is on, and hooks it just once however often this is called. Use it in
---`OnEnable` instead of a `hooked` flag: `module:Hook("ToggleSheath", fn)` for a global function,
---or `module:Hook(object, "Method", fn)`. `fn` gets the same arguments the hooked function did.
---@param target table|string an object, or the name of a global function
---@param method string|function the method's name, or `fn` when `target` is a global's name
---@param fn? function
function Module:Hook(target, method, fn)
    if type(target) == "string" then
        target, method, fn = _G, target, method
    end
    hookOnce(self, target, method, fn, function(hook)
        hooksecurefunc(target, method, hook)
    end)
end

---Like `module:Hook`, for a frame's script: `frame:HookScript(script, fn)` that runs only while
---the module is on, hooked once.
---@param frame table
---@param script string such as "OnEvent"
---@param fn function
function Module:HookScript(frame, script, fn)
    hookOnce(self, frame, "script:" .. script, fn, function(hook)
        frame:HookScript(script, hook)
    end)
end

---Prints a line in chat that the module shows by itself (not in reply to a command), unless the
---player turned its chat messages off. A module that prints these puts `chat = true` in its
---defaults and `ns.ChatOption(...)` in its options.
---@param message string
function Module:Print(message)
    if self.db.chat ~= false then
        ns.Print(message)
    end
end

---The "Chat Messages" checkbox for a module that uses `module:Print`.
---@param description string what the module says in chat
---@param section? string its Settings header, on a page with sections
---@return table option for `module.options`
function ns.ChatOption(description, section)
    return { key = "chat", name = ns.L.CHAT_MESSAGES, description = description, section = section }
end

-- Stops every event the module added with `module:On`.
local function offAll(module)
    for _, entry in ipairs(module.events or {}) do
        ns.Off(entry[1], entry[2])
    end
    module.events = nil
end

---Creates a module: one change to the game's UI, switched on and off on its own. Give it
---`OnEnable` and an `OnDisable` that undoes it, and put its settings in `defaults`. Events
---added with `module:On` and hooks added with `module:Hook` stop by themselves when it turns
---off, so a module that only does those needs no `OnDisable`; anything else `OnEnable` changes
---(a frame, a CVar, a timer) `OnDisable` must put back. Set
---`module.title` for a friendlier name in Settings (the name stays the /fpp key), and
---`module.category` for its group on the main Settings page (see Settings.lua). A tool with
---nothing to turn off sets `module.alwaysOn`: it has no toggle and stays on. A module only for
---some clients gives `module:IsAvailable()`; when it returns false at login, the module stays off
---and out of Settings and /fpp list.
---@param name string shown in /fpp
---@param description string one line for /fpp
---@param defaults? table its settings; `enabled` defaults to true
---@return table module with .db (its saved settings) once the addon has loaded
function ns.NewModule(name, description, defaults)
    if ns.modules[name] then
        error("Forever++: a module called " .. name .. " already exists", 2)
    end
    local module = setmetatable({ name = name, description = description,
        defaults = defaults or {} }, Module)
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
    if module.OnEnable then
        module:OnEnable()
    end
end

local function disable(module)
    if not module.enabled then
        return
    end
    module.enabled = false
    if module.OnDisable then
        module:OnDisable()
    end
    offAll(module)
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
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        ns.db.modules[name] = ns.db.modules[name] or {}
        prune(ns.db.modules[name], module.defaults)
        fill(ns.db.modules[name], module.defaults)
        module.db = ns.db.modules[name]
        checkValues(module)
        if module.OnLoad then
            module:OnLoad()
        end
        if module.alwaysOn then
            module.db.enabled = true
        end
        -- A module only for some clients (IsAvailable false) stays off and out of sight.
        module.unavailable = module.IsAvailable and not module:IsAvailable() or nil
        if module.db.enabled and not module.unavailable then
            enable(module)
        end
    end
end

---Turns a module on or off and remembers it.
---@param name string
---@param on boolean
function ns.SetEnabled(name, on)
    local module = ns.modules[name]
    if module.alwaysOn or module.unavailable then
        return -- a tool that's always there, or a module this client doesn't get
    end
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
    for _, name in ipairs(ns.order) do
        if name:lower() == query and not ns.modules[name].unavailable then
            return ns.modules[name]
        end
    end
end

local function list()
    ns.Print(L.SLASH_MODULES)
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if not (module.alwaysOn or module.unavailable) then
            print(format("  %s  %s  |cff999999%s|r", ns.StateText(module.db.enabled), name,
                module.description))
        end
    end
end

-- /fpp options and /fpp set work on any module's `module.options`: a checkbox takes on/off, a
-- dropdown takes one of its choice keys, a slider a number. `enabled` is the module's own on/off.

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

-- "on", "off", the choice key, or the number, and what it may be set to.
local function describe(module, option)
    local value = module.db[option.key]
    if option.min then
        return tostring(value), format("%s-%s", option.min, option.max)
    elseif not option.choices then
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
-- can be, and changes nothing, unless `flip` (/fpp toggle) turns a checkbox the other way.
local function set(rest, flip)
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
    if option.min then
        new = ns.SliderValue(option, value)
    elseif option.choices then
        for _, choice in ipairs(option.choices) do
            if choice[1]:lower() == value then
                new = choice[1]
            end
        end
    elseif value then
        new = booleans[value]
    elseif flip then
        new = not module.db[option.key]
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
        set(rest, true) -- /fpp toggle <module> <option> [value]
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
        { "/fpp, /forever++", L.SLASH_OPEN },
        { "/fpp list", L.SLASH_LIST },
        { "/fpp toggle <module> [option]", L.SLASH_TOGGLE },
        { "/fpp options <module>", L.SLASH_OPTIONS },
        { "/fpp set <module> <option> [value]", L.SLASH_SET },
        { "/fpp reset", L.SLASH_RESET },
    }
    for _, name in ipairs(commandOrder) do
        local info = commands[name]
        local usage = info.usage ~= "" and " " .. info.usage or ""
        lines[#lines + 1] = { format("/fpp %s%s", name, usage), info.description }
    end
    return lines
end
