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
-- Handler -> the module that added it with module:On, for the Profiler page (Lib/Profiler.lua).
local owners = setmetatable({}, { __mode = "k" })

events:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then
        return
    end
    local profiler = ns.Profiler
    if profiler and profiler.recording then
        for i = 1, #list do
            local fn = list[i]
            profiler.Call(owners[fn], call, fn, event, ...)
        end
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

---Whether this client has `event`. Registering one it doesn't have is an error, and Forever is a
---beta, so check an event a patch may add or drop before `ns.On` or `module:On`. Probe: without
---C_EventUtils.IsEventValid, every event counts as there.
---@param event string
---@return boolean
function ns.HasEvent(event)
    local utils = C_EventUtils
    return not (utils and utils.IsEventValid) or utils.IsEventValid(event) and true or false
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
-- Lib/Store.lua lays out ForeverPlusPlusDB and ForeverPlusPlusCharDB: each module's settings
-- (only what the player changed) apart from what it collects, and a version so the steps that
-- bring an older layout up to date each run once. `module.db` reads and writes both.

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

-- Moving settings -----------------------------------------------------------------------------
-- When a release renames, merges, or moves a module, setting, or data between modules, a step
-- moves what the player saved to where it now goes, once, at the first login with that release,
-- before settings and data no module has are cleared.

---Adds a step that moves saved settings from where an older version kept them, run once when the
---saved layout is older than `version`. Give a new step the next version (Store.VERSION + 1, and
---raise Store.VERSION to it). Version 1 steps work on the 0.8 layout, `db.modules`; later ones on
---`db.settings[module]` and `db.data[module]` (see Lib/Store.lua).
---@param version integer
---@param fn fun(db: table) ForeverPlusPlusDB
function ns.Migrate(version, fn)
    ns.Store.Step(version, fn)
end

---Like ns.Migrate, for a character's own saved variables: `fn(char, db)` runs once per character.
---@param version integer
---@param fn fun(char: table, db: table) ForeverPlusPlusCharDB, ForeverPlusPlusDB
function ns.MigrateCharacter(version, fn)
    ns.Store.CharacterStep(version, fn)
end

---Copies saved values from `from` to `to`. `keys` lists them: a plain entry keeps its name, and
---`new = "old"` renames one. Values `from` doesn't have leave `to` as it is.
---@param from table
---@param to table
---@param keys table
function ns.MoveSettings(from, to, keys)
    for new, old in pairs(keys) do
        if type(new) == "number" then
            new = old
        end
        if from[old] ~= nil then
            to[new] = from[old]
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
    owners[fn] = owners[fn] or self
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
local function child(t, key)
    local value = t[key]
    if not value then
        value = {}
        t[key] = value
    end
    return value
end

local function hookOnce(module, target, method, fn, install)
    local byFn = child(child(child(module, "hooked"), target), method)
    if not byFn[fn] then
        byFn[fn] = true
        install(function(...)
            if module.enabled then
                local profiler = ns.Profiler
                if profiler and profiler.recording then
                    profiler.Call(module, call, fn, ...)
                else
                    fn(...)
                end
            end
        end)
    end
end

---Calls `fn` after a function or method of a Blizzard object runs (`hooksecurefunc`), but only
---while the module is on, and hooks it just once however often this is called. Use it in
---`OnEnable` instead of a `hooked` flag: `module:Hook("ToggleSheath", fn)` for a global function,
---or `module:Hook(object, "Method", fn)`. `fn` gets the same arguments the hooked function did.
---Does nothing when the object or function isn't on this client, so callers needn't probe first.
---@param target table|string|nil an object, or the name of a global function
---@param method string|function the method's name, or `fn` when `target` is a global's name
---@param fn? function
function Module:Hook(target, method, fn)
    if type(target) == "string" then
        target, method, fn = _G, target, method
    end
    if type(target) ~= "table" or type(target[method]) ~= "function" then
        return
    end
    hookOnce(self, target, method, fn, function(hook)
        hooksecurefunc(target, method, hook)
    end)
end

---Like `module:Hook`, for a frame's script: `frame:HookScript(script, fn)` that runs only while
---the module is on, hooked once. Does nothing when the frame isn't there.
---@param frame table?
---@param script string such as "OnEvent"
---@param fn function
function Module:HookScript(frame, script, fn)
    if not frame then
        return
    end
    hookOnce(self, frame, "script:" .. script, fn, function(hook)
        frame:HookScript(script, hook)
    end)
end

---Like `module:Hook`, for every tooltip of one kind (`TooltipDataProcessor.AddTooltipPostCall`):
---`fn(tooltip, data)` runs after the game fills one in, while the module is on. Does nothing on a
---client without TooltipDataProcessor.
---@param kind any such as Enum.TooltipDataType.Item, or TooltipDataProcessor.AllTypes
---@param fn function
function Module:TooltipPostCall(kind, fn)
    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and kind) then
        return
    end
    hookOnce(self, TooltipDataProcessor, kind, fn, function(hook)
        TooltipDataProcessor.AddTooltipPostCall(kind, hook)
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
---`module.category` for its group on the Modules page (see Settings/Settings.lua). A tool with
---nothing to turn off sets `module.alwaysOn`: it has no toggle and stays on. A module only for
---some clients gives `module:IsAvailable()`; when it returns false at login, the module stays off
---and out of Settings and /fpp list. A default that is a table is data the module collects, not a
---setting; one kept for each character on its own goes in `module.perCharacter` ({ [key] = true }).
---@param name string shown in /fpp
---@param description string one line for /fpp
---@param defaults? table its settings and data; `enabled` defaults to true
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

-- Parts -----------------------------------------------------------------------------------------
-- A module can be made of parts that the player turns on and off one by one inside it, like the
-- World Map module's layers. Each part is written like a module of its own, in its own file.

---Adds a part to a module: a piece of it with its own checkbox, the option `toggle.key`, that heads
---its section in Settings. A part is written like a module: `OnEnable`, an `OnDisable` that undoes
---it, `OnOptionChanged`, `part:On`, `part:Hook` and `part:Print` all work the same, and it is on
---while both the module and its checkbox are. Its settings go in `defaults` and its options in
---`part:AddOptions`; both join the module's, so their keys must differ from the other parts'.
---Its `db` is the module's.
---@param toggle table the checkbox option: `key`, `name`, `description`, and `section`, the header its options go under
---@param defaults? table its settings; its checkbox defaults to on
---@return table part
function Module:NewPart(toggle, defaults)
    local part = setmetatable({ name = self.name, module = self, key = toggle.key,
        section = toggle.section, own = {} }, Module)
    toggle.toggle = true
    if defaults and defaults[toggle.key] == nil then
        defaults[toggle.key] = true
    end
    for key, value in pairs(defaults or { [toggle.key] = true }) do
        if self.defaults[key] ~= nil then
            error("Forever++: " .. self.name .. " already has a setting called " .. key, 2)
        end
        self.defaults[key] = value
    end
    self.parts = self.parts or {}
    self.parts[#self.parts + 1] = part
    self.options = self.options or {}
    self.options[#self.options + 1] = toggle
    return part
end

---Adds a part's options to its module's, under the part's section and greyed out in Settings while
---its checkbox is off. An option's own `section` becomes a smaller header inside the part's. The
---part hears about them in its `OnOptionChanged`.
---@param options table[] options, as in `module.options`
function Module:AddOptions(options)
    local module = self.module
    for _, option in ipairs(options) do
        option.subsection = option.section
        option.section = self.section
        option.part = self.key
        self.own[option.key] = true
        module.options[#module.options + 1] = option
    end
end

local function enable(module)
    if module.enabled then
        return
    end
    module.enabled = true
    if module.OnEnable then
        call(module.OnEnable, module) -- an error here must not stop the modules after it
    end
    for _, part in ipairs(module.parts or {}) do
        if module.db[part.key] then
            enable(part)
        end
    end
end

local function disable(module)
    if not module.enabled then
        return
    end
    for _, part in ipairs(module.parts or {}) do
        disable(part)
    end
    module.enabled = false
    if module.OnDisable then
        call(module.OnDisable, module)
    end
    offAll(module)
end

-- Tells a module one of its options changed. A part's checkbox turns it on or off, and a part
-- hears about its own options while it's on.
local function optionChanged(module, key)
    if module.OnOptionChanged then
        module:OnOptionChanged(key)
    end
    for _, part in ipairs(module.parts or {}) do
        if key == part.key then
            if module.enabled and module.db[key] then
                enable(part)
            else
                disable(part)
            end
        elseif part.own[key] and part.enabled and part.OnOptionChanged then
            call(part.OnOptionChanged, part, key)
        end
    end
end

local welcomed = {} -- functions to call when the welcome is seen, or reset to show again

---True from a fresh install until the player first sees the About page.
---@return boolean
function ns.WelcomePending()
    return ns.db and ns.db.welcome == true or false
end

---Calls fn once the player has seen the About page after a fresh install, and again whenever the
---welcome is reset (the Debug page), so it can show and hide what offers it.
---@param fn function
function ns.OnWelcomed(fn)
    welcomed[#welcomed + 1] = fn
end

---Marks the About page seen (false, from Settings/About.lua when it's first shown), or offers it
---again as on a fresh install, keeping every setting (true, from the Debug page).
---@param pending boolean
function ns.SetWelcome(pending)
    if ns.WelcomePending() == pending then
        return
    end
    ns.db.welcome = pending or nil
    for _, fn in ipairs(welcomed) do
        call(fn)
    end
end

---A field from the TOC, such as "Notes", or "" when it has none.
---@param field string
---@return string
function ns.Metadata(field)
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get(addonName, field) or ""
end

---The modules the player has on, by their internal names (what the code and issues call them),
---leaving out tools that are always on.
---@return string[]
function ns.ModulesOn()
    local names = {}
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if module.enabled and not module.alwaysOn then
            names[#names + 1] = name
        end
    end
    return names
end

-- Modules renamed in layout version 3 so their names match their titles: old -> new.
local RENAMED = {
    GatherTracking = "GatheringTracking",
    CharacterFrame = "CharacterWindow",
    ChannelNames = "ShortChannelNames",
    ChatFading = "PersistentChat",
    BagSlots = "BagSlotCounter",
    UnusableItems = "UnusableItemsTint",
    BestReward = "BestQuestReward",
    QuestIcons = "ForeverQuestIcons",
    QuestPlates = "QuestNameplates",
    AddOnList = "AddOnsList",
    Framerate = "MovableFramerate",
    HideFeedback = "HideBetaFeedback",
    CVarBrowser = "ConsoleVariables",
    NpcPlates = "NpcNameplates",
    PlayerPlates = "PlayerNameplates",
}

-- The core's own steps. Version 2 splits the 0.8 layout into settings, data, and per-character
-- data each character takes when it logs in; version 3 renames modules to match their titles.
local function addCoreSteps()
    local Store = ns.Store
    Store.Step(2, function(db)
        local perCharacter = {}
        for name, module in pairs(ns.modules) do
            perCharacter[name] = module.perCharacter
        end
        -- Version 1 still had the old names.
        for old, new in pairs(RENAMED) do
            perCharacter[old] = perCharacter[new]
        end
        Store.Split(db, perCharacter)
    end)
    Store.Step(3, function(db)
        Store.Rename(db, RENAMED)
    end)
end

---Loads the saved settings and enables every module that is on (called once, at PLAYER_LOGIN).
function ns.Start()
    local Store = ns.Store
    ForeverPlusPlusDB = type(ForeverPlusPlusDB) == "table" and ForeverPlusPlusDB or {}
    ForeverPlusPlusCharDB = type(ForeverPlusPlusCharDB) == "table" and ForeverPlusPlusCharDB or {}
    ns.db, ns.charDB = ForeverPlusPlusDB, ForeverPlusPlusCharDB
    addCoreSteps()
    local fresh = Store.Upgrade(ns.db, ns.charDB)
    -- The last version whose Modules page the player has seen all of, and the version each module
    -- clicked since was seen in; Settings/Settings.lua marks what's added or changed after them as
    -- new. A fresh install has nothing to catch up on; saved settings from before this was kept
    -- have seen none of them.
    ns.version = ns.Metadata("Version")
    if type(ns.db.seenVersion) ~= "string" then
        ns.db.seenVersion = fresh and ns.version or "0"
    end
    if type(ns.db.seenModules) ~= "table" then
        ns.db.seenModules = {}
    end
    -- A fresh install has the About page to see, which the Minimap Button offers once.
    if fresh then
        ns.db.welcome = true
    end
    local known = {}
    for _, name in ipairs(ns.order) do
        known[name] = true
    end
    Store.Prune(ns.db, ns.charDB, known)
    -- Before the game writes the saved variables, drop what's empty so the file holds only what
    -- was saved. module.db makes it again if a module saves at logout after this.
    ns.On("PLAYER_LOGOUT", function()
        Store.Tidy(ns.db, ns.charDB)
    end)
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        module.db = Store.Load(ns.db, ns.charDB, name, module.defaults, module.perCharacter)
        for _, part in ipairs(module.parts or {}) do
            part.db = module.db
        end
        checkValues(module)
        if module.OnLoad then
            call(module.OnLoad, module)
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
    optionChanged(module, key)
end

-- Presets -------------------------------------------------------------------------------------

-- Modules the Developer's Defaults preset turns on, on top of every module's default settings.
local developerEnables = { "FishingCast", "SkipCinematics", "AutoScreenshot", "CurrencyBar",
    "HideBetaFeedback", "ShortChannelNames", "EasyDelete", "AutoWeaponBuff", "MinimapNodeIcons",
    "AutoGossip", "WhisperWindow" }

-- Options the Developer's Defaults preset sets differently from the module's default.
local developerOptions = {
    WorldMap = { zoneDungeons = "key", fishing = "key" },
    ChatHistory = { divider = true },
    QuestTracker = { sort = "low" },
    AutoGossip = { other = true },
    MinimapButton = { swapClicks = true },
}

---Puts every module's options (`module.options`) back to their defaults, then turns on the
---modules in `enable`. Everything else a module saves stays: data (prices, seen cinematics, chat
---history) and what's set in Edit Mode (positions and scale).
---Modules that are always on have nothing to reset. Applies live, like the checkboxes do.
---@param enable? string[] module names to turn on whatever their default is
---@param options? table<string, table<string, any>> per module, option values used instead of its defaults
function ns.ApplyPreset(enable, options)
    local wanted = {}
    for _, name in ipairs(enable or {}) do
        wanted[name] = true
    end
    local changed = {}
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if not (module.alwaysOn or module.unavailable) then
            local overrides = options and options[name]
            for _, option in ipairs(module.options or {}) do
                local key = option.key
                local value = module.defaults[key]
                if overrides and overrides[key] ~= nil then
                    value = overrides[key]
                end
                if type(value) ~= "table" and module.db[key] ~= value then
                    module.db[key] = value
                    changed[#changed + 1] = { module, key }
                end
            end
        end
    end
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        ns.SetEnabled(name, wanted[name] or module.defaults.enabled)
    end
    for _, entry in ipairs(changed) do
        local module, key = entry[1], entry[2]
        if module.enabled then
            optionChanged(module, key)
        end
    end
    for _, name in ipairs(ns.order) do
        ns.RefreshSetting(name)
    end
end

---Defaults plus the modules the developer turns on (Developer's Defaults in the Defaults popup).
function ns.ApplyDeveloperDefaults()
    ns.ApplyPreset(developerEnables, developerOptions)
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
        if module.alwaysOn then
            ns.Print(format(L.MODULE_ALWAYS_ON, module.title or module.name))
            return
        end
        local on = booleans[value or ""]
        if on == nil and flip and not value then
            on = not module.db.enabled
        end
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
    elseif command == "toggle" and rest then
        -- /fpp toggle <module> [option] [value]: the module itself when no option is named.
        set(rest:find(" ") and rest or rest .. " enabled", true)
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
        -- It throws away saved data too (prices, flight times, chat history), so it asks first.
        ns.Confirm("RESET_ALL", L.RESET_CONFIRM, function()
            ForeverPlusPlusDB, ForeverPlusPlusCharDB = nil, nil
            ReloadUI()
        end)
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
