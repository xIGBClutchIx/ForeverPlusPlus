-- Plugins: modules another addon adds to Forever++ through the public API (API.lua's
-- RegisterModule and GetPluginKit; docs/api.md is the contract). A plugin's module shows on the
-- Modules page with its options, follows profiles, and turns on and off like ours.
--
-- A plugin never gets our own module table. It gets a handle: a table that takes only the fields
-- the contract names (a title, options, the functions Core calls), checks them as they're set, and
-- passes them on. So how our modules are written can keep changing, as it does, and only this file
-- has to keep the handle meaning what docs/api.md says. Options and buttons are copied field by
-- field for the same reason: a plugin can't reach what only our own modules may use (an option
-- that sets a CVar, a debug option).
--
-- The same goes for everything else it's handed: its settings, a timer, and a map layer are small
-- tables of their own over ours, never our objects. Three rules hold all the way through:
--   * What a plugin gives us is checked where it's given. A mistake of its own (a wrong type, a
--     missing argument) raises an error there, in its code, naming the mistake.
--   * Every function it gives us is called guarded (`guarded`), so its error is reported and
--     never stops what called it.
--   * Our own work behind a call runs protected (`safe`): an error of ours is reported and the
--     call returns nil.
--
-- Core is told which modules are plugins' (`Remember`), so the settings of one whose addon is off
-- or gone for a session aren't cleared with those of modules that no longer exist.
local addonName, ns = ...

local type, pairs, ipairs, error, setmetatable, match = type, pairs, ipairs, error, setmetatable, string.match
local pcall, tostring, format, huge, min, max = pcall, tostring, string.format, math.huge, math.min, math.max

local L = ns.L

local Plugins = {}
ns.Plugins = Plugins

local NAME = "^[%a][%w_]*$"

local handles = setmetatable({}, { __mode = "k" }) -- handle -> its module
local modules = setmetatable({}, { __mode = "k" }) -- module -> its handle
-- Module -> what this file keeps for it: the plugin's OnDisable, and its map layers, taken off
-- the map when it turns off.
local states = setmetatable({}, { __mode = "k" })

local function fail(message, level)
    error(addonName .. ": " .. message, (level or 1) + 1)
end

-- A plugin's function, wrapped so an error in it is reported (ns.Call) and answers `fallback`
-- instead of stopping what called it. Core and Settings call these in the middle of their own
-- work: login, laying out the Modules page. A plugin's mistake mustn't cost the player those.
local function guarded(fn, fallback)
    return function(...)
        local done, result = false, nil
        ns.Call(function(...)
            result = fn(...)
            done = true
        end, ...)
        if done then
            return result
        end
        return fallback
    end
end

local function finish(ok, ...)
    if ok then
        return ...
    end
    local handler = geterrorhandler and geterrorhandler()
    if handler then
        handler(...)
    end
    return nil
end

-- Our half of a call a plugin makes: an error of ours is reported and the call returns nil, as
-- every v1 function does (API.lua's `export`).
local function safe(fn, ...)
    return finish(pcall(fn, ...))
end

-- A number that is one: not NaN and not infinite. Either would break arithmetic it reaches, and
-- written to the saved variables it makes a file the game can't read back.
local function finite(value)
    return type(value) == "number" and value == value and value ~= huge and value ~= -huge
end

-- Whether Forever++ has read the saved settings (PLAYER_LOGIN): too late for a new module, and
-- for what Core reads only then.
local function started()
    return ns.db ~= nil
end

-- A read-only table over `contents`, with a metatable the plugin can't read or replace.
local function readOnly(contents, label)
    return setmetatable({}, {
        __index = contents,
        __newindex = function()
            error(label .. " is read only", 2)
        end,
        __metatable = false,
    })
end

-- Defaults ---------------------------------------------------------------------------------------

local DEPTH = 8 -- how deep a table default may nest: a table inside itself would never end

-- A copy of a default's value, and whether it's something the saved variables can hold: true or
-- false, text, a number, or a table of those under text and number keys. The copy is ours, so
-- nothing the plugin does to its table later reaches what Store reads.
local function copyData(value, depth)
    local kind = type(value)
    if kind == "boolean" or kind == "string" then
        return value, true
    elseif kind == "number" then
        return value, finite(value)
    elseif kind ~= "table" or depth > DEPTH then
        return nil, false
    end
    local copy = {}
    for key, inner in pairs(value) do
        local keyKind = type(key)
        if keyKind ~= "string" and not (keyKind == "number" and finite(key)) then
            return nil, false
        end
        local innerCopy, ok = copyData(inner, depth + 1)
        if not ok then
            return nil, false
        end
        copy[key] = innerCopy
    end
    return copy, true
end

-- Options ----------------------------------------------------------------------------------------

-- The option fields a plugin may set, and each one's type ("any" for a value of the option's own
-- kind). Anything else is left out of the copy.
local OPTION_FIELDS = {
    key = "string", name = "string", description = "string", section = "string", added = "string",
    requires = "string", slider = "string", choices = "table", shown = "function",
    min = "number", max = "number", step = "number", format = "string",
}

-- A copy of one option with only the fields above, checked against the module's defaults.
local function copyOption(option, defaults, index)
    if type(option) ~= "table" then
        fail("option " .. index .. " isn't a table", 4)
    end
    local copy = {}
    for field, kind in pairs(OPTION_FIELDS) do
        local value = option[field]
        if value ~= nil then
            if type(value) ~= kind then
                fail("option " .. index .. ": " .. field .. " must be a " .. kind, 4)
            end
            copy[field] = value
        end
    end
    if copy.shown then
        copy.shown = guarded(copy.shown, true) -- an option whose test broke still shows
    end
    local key = copy.key
    if not key or not copy.name then
        fail("option " .. index .. " needs a key and a name", 4)
    end
    local default = defaults[key]
    if key == "enabled" or default == nil or type(default) == "table" then
        fail("option " .. key .. " needs a default that isn't a table, and can't be \"enabled\"", 4)
    end
    if copy.choices then
        local choices, found = {}, false
        for i, choice in ipairs(copy.choices) do
            if type(choice) ~= "table" or type(choice[1]) ~= "string" or type(choice[2]) ~= "string" then
                fail("option " .. key .. ": each choice is { value, name }, both text", 4)
            end
            choices[i] = { choice[1], choice[2] }
            found = found or choice[1] == default
        end
        if not found then
            fail("option " .. key .. ": its default isn't one of its choices", 4)
        end
        copy.choices = choices
    elseif copy.min or copy.max then
        -- Settings does arithmetic on all of these as it lays the page out.
        if not (finite(copy.min) and finite(copy.max) and copy.min < copy.max and finite(default)
            and default >= copy.min and default <= copy.max) then
            fail("option " .. key .. ": a slider needs min under max and a default between them", 4)
        end
        if copy.step and not (finite(copy.step) and copy.step > 0) then
            fail("option " .. key .. ": a slider's step is a number above 0", 4)
        end
        -- Settings formats the value with it on every draw; one that can't would break the page.
        if copy.format and not pcall(format, copy.format, default) then
            fail("option " .. key .. ": its format doesn't take a number", 4)
        end
    elseif type(default) ~= "boolean" then
        fail("option " .. key .. ": a checkbox needs true or false for its default", 4)
    end
    return copy
end

local function copyOptions(options, defaults)
    local copies, keys = {}, {}
    for index, option in ipairs(options) do
        local copy = copyOption(option, defaults, index)
        if keys[copy.key] then
            fail("two options are called " .. copy.key, 3)
        end
        keys[copy.key] = copy
        copies[index] = copy
    end
    -- An option another one names must be there.
    for _, copy in ipairs(copies) do
        for _, field in ipairs({ "requires", "slider" }) do
            if copy[field] and not keys[copy[field]] then
                fail("option " .. copy.key .. ": no option called " .. copy[field], 3)
            end
        end
    end
    -- Settings walks up `requires` until it ends, so a ring of them would never return.
    for _, copy in ipairs(copies) do
        local up, steps = copy, 0
        while up.requires do
            up, steps = keys[up.requires], steps + 1
            if steps > #copies then
                fail("option " .. copy.key .. ": its requires leads back to itself", 3)
            end
        end
    end
    return copies
end

-- Buttons: `{ name, button, description, section, confirm, fn }`.
local function copyActions(actions)
    local copies = {}
    for index, action in ipairs(actions) do
        if type(action) ~= "table" or type(action.name) ~= "string" or type(action.button) ~= "string"
            or type(action.fn) ~= "function" then
            fail("button " .. index .. " needs a name, a button text, and a function", 3)
        end
        copies[index] = { name = action.name, button = action.button, fn = guarded(action.fn),
            description = type(action.description) == "string" and action.description or nil,
            section = type(action.section) == "string" and action.section or nil,
            confirm = type(action.confirm) == "string" and action.confirm or nil }
    end
    return copies
end

-- Notices: gray rows above the options, `{ text, description, shown }`, one or a list. They say
-- something; a button on one is for our own modules.
local function copyNotices(notice, own)
    local list = notice[1] and notice or { notice }
    local copies = { own }
    for index, row in ipairs(list) do
        if type(row) ~= "table" or type(row.text) ~= "string" then
            fail("notice " .. index .. " needs a text", 3)
        end
        copies[#copies + 1] = { text = row.text,
            description = type(row.description) == "string" and row.description or nil,
            shown = type(row.shown) == "function" and guarded(row.shown, true) or nil }
    end
    return copies
end

-- The handle -------------------------------------------------------------------------------------

-- What a plugin may set on its handle: the type each takes.
local FIELDS = {
    title = "string", category = "string", added = "string",
    options = "table", actions = "table", notice = "table", perCharacter = "table",
    OnEnable = "function", OnDisable = "function", OnOptionChanged = "function",
    IsAvailable = "function", Problem = "function",
}

local function setField(handle, key, value)
    local module = handles[handle]
    local kind = FIELDS[key]
    if not kind then
        fail("a plugin's module has no \"" .. tostring(key) .. "\" to set", 2)
    end
    if type(value) ~= kind then
        fail(key .. " must be a " .. kind, 2)
    end
    if kind == "function" then
        -- Core calls it with our module; the plugin's function gets its handle. Guarded: one that
        -- errors answers false (not available, no problem) and the rest of login goes on.
        local run = guarded(value, false)
        if key == "OnDisable" then
            states[module].OnDisable = run -- the module's own OnDisable calls it (Register)
            return
        end
        module[key] = function(_, ...)
            return run(handle, ...)
        end
        return
    end
    if started() and (key == "options" or key == "perCharacter") then
        fail(key .. " is set while the plugin loads, before PLAYER_LOGIN", 2)
    end
    if key == "options" then
        module.options = copyOptions(value, module.defaults)
    elseif key == "actions" then
        module.actions = copyActions(value)
    elseif key == "notice" then
        module.notice = copyNotices(value, module.pluginNotice)
    elseif key == "perCharacter" then
        local keys = {}
        for name, on in pairs(value) do
            if type(name) ~= "string" or type(module.defaults[name]) ~= "table" then
                fail("perCharacter names defaults that are tables", 2)
            end
            keys[name] = on and true or nil
        end
        module.perCharacter = keys
    else
        module[key] = value
    end
end

-- A plugin's settings: its own table over the module's `db`, which is Store's and Core reads too.
-- It reads and sets only what the plugin's defaults name, and a value of the default's own type.
-- It looks `module.db` up each time, so it stays right through a profile switch.
local views = setmetatable({}, { __mode = "k" }) -- module -> its view

local function settingsView(module)
    local view = views[module]
    if view then
        return view
    end
    local defaults = module.defaults
    view = setmetatable({}, {
        __index = function(_, key)
            if module.db and type(key) == "string" and defaults[key] ~= nil then
                return module.db[key]
            end
            return nil
        end,
        __newindex = function(_, key, value)
            local default
            if type(key) == "string" then
                default = defaults[key]
            end
            if default == nil then
                fail("db has no \"" .. tostring(key) .. "\": a setting is one of the module's defaults", 2)
            end
            if key == "enabled" then
                fail("db.enabled is the player's to set, on the Modules page", 2)
            end
            if not module.db then
                fail("db is there from PLAYER_LOGIN on", 2)
            end
            if value ~= nil and (type(value) ~= type(default) or type(value) == "number" and not finite(value)) then
                fail("db." .. key .. " takes a " .. type(default) .. ", or nil for its default", 2)
            end
            module.db[key] = value
        end,
        __metatable = false,
    })
    views[module] = view
    return view
end

local function getField(handle, key)
    local module = handles[handle]
    if key == "name" then
        return module.name
    elseif key == "db" then
        return module.db and settingsView(module) or nil
    elseif key == "enabled" then
        return module.enabled and true or false
    end
    return nil
end

local function listen(module, event, fn)
    module:On(event, fn)
    return true
end

-- The module methods a handle has, with the handle in the module's place. Each checks what it's
-- given before Core sees it: Core trusts our own modules with these, and a wrong value would
-- error deep in it, or sit in a list it walks on every event.
local function addMethods(handle, module)
    local function check(self, ok, usage)
        if self ~= handle or not ok then
            fail("call it as module:" .. usage, 3)
        end
    end

    -- Only while the module is on, as ours listen from OnEnable: Core stops a module's events as
    -- it turns off, so one added while it's off would be heard until the next time it did.
    function handle.On(self, event, fn)
        check(self, type(event) == "string" and type(fn) == "function", "On(event, fn)")
        if not module.enabled or not safe(ns.HasEvent, event) then
            return false
        end
        return safe(listen, module, event, fn) or false
    end

    function handle.Hook(self, target, method, fn)
        if type(target) == "string" then
            check(self, type(method) == "function", "Hook(name, fn) for a global function")
        else
            check(self, type(target) == "table" and type(method) == "string" and type(fn) == "function",
                "Hook(target, method, fn)")
        end
        safe(module.Hook, module, target, method, fn)
    end

    function handle.HookScript(self, frame, script, fn)
        check(self, (frame == nil or type(frame) == "table") and type(script) == "string"
            and type(fn) == "function", "HookScript(frame, script, fn)")
        safe(module.HookScript, module, frame, script, fn)
    end

    function handle.TooltipPostCall(self, kind, fn)
        check(self, kind ~= nil and type(fn) == "function", "TooltipPostCall(kind, fn)")
        safe(module.TooltipPostCall, module, kind, fn)
    end

    function handle.Print(self, message)
        check(self, type(message) == "string", "Print(message)")
        if module.db then -- its Chat Messages setting isn't read before PLAYER_LOGIN
            safe(module.Print, module, message)
        end
    end
end

---Makes a module for a plugin and returns its handle. Called while the plugin's files load,
---before PLAYER_LOGIN. Errors on a mistake (a name taken, defaults that aren't a table).
---@param name string letters, digits, and underscores, starting with a letter
---@param description string
---@param defaults table its settings and their defaults; `enabled` false unless given
---@param addon? string the plugin's addon folder, named in the module's notice
---@return table handle
function Plugins.Register(name, description, defaults, addon)
    if type(name) ~= "string" or not match(name, NAME) then
        fail("RegisterModule needs a name of letters, digits, and underscores", 2)
    end
    if type(description) ~= "string" or type(defaults) ~= "table" then
        fail("RegisterModule(name, description, defaults)", 2)
    end
    if started() then
        fail("RegisterModule is for the time a plugin loads, before PLAYER_LOGIN", 2)
    end
    if ns.modules[name] then
        fail("there is already a module called " .. name, 2)
    end
    local own = {}
    for key, value in pairs(defaults) do
        if type(key) ~= "string" then
            fail("a default's key must be text", 2)
        end
        -- Store fills saved data from these at login, tables inside tables too.
        local copy, ok = copyData(value, 1)
        if not ok then
            fail("the default " .. key .. " must be true or false, text, a number, or a table of those", 2)
        end
        own[key] = copy
    end
    -- Off until the player turns it on, unless the plugin says otherwise: ours default to on only
    -- for what nearly everyone wants.
    if own.enabled == nil then
        own.enabled = false
    elseif type(own.enabled) ~= "boolean" then
        fail("the default enabled must be true or false", 2)
    end
    local module = ns.NewModule(name, description, own)
    module.plugin = type(addon) == "string" and addon ~= "" and addon or true
    -- Whose it is, always shown: problems with it aren't ours to fix.
    module.pluginNotice = {
        text = module.plugin == true and L.PLUGIN_NOTICE or L.PLUGIN_NOTICE_ADDON:format(module.plugin),
        description = L.PLUGIN_NOTICE_DESC,
    }
    module.notice = { module.pluginNotice }

    local handle = {}
    addMethods(handle, module)
    local state = { layers = {} }
    states[module] = state
    -- The plugin's OnDisable, then what the kit put up for it: a map layer left on would show
    -- while the module is off, with nothing for the player to turn it off with.
    function module.OnDisable()
        if state.OnDisable then
            state.OnDisable(handle)
        end
        for _, layer in ipairs(state.layers) do
            safe(layer.Disable, layer)
        end
    end
    handles[handle], modules[module] = module, handle
    return setmetatable(handle, { __index = getField, __newindex = setField, __metatable = false })
end

---The module behind a plugin's handle, for the kit's helpers that take one; nil for anything else.
---@param handle any
---@return table|nil
function Plugins.Module(handle)
    if handle == nil then
        return nil
    end
    return handles[handle]
end

---Notes the plugins' modules in the saved variables and adds every plugin module ever seen there
---to `known`, so Store.Prune keeps the settings of one whose addon isn't loaded this session.
---@param db table ForeverPlusPlusDB
---@param known table<string, boolean>
function Plugins.Remember(db, known)
    if type(db.plugins) ~= "table" then
        db.plugins = {}
    end
    for name, module in pairs(ns.modules) do
        if module.plugin then
            db.plugins[name] = true
        end
    end
    for name in pairs(db.plugins) do
        known[name] = true
    end
end

-- The kit ----------------------------------------------------------------------------------------

-- The module a timer or a map layer is made for. Each is made once, while the plugin loads, as
-- Core has our own modules make theirs at file load: one made in OnEnable would be made again
-- every time the module turned on, and none of them can be freed. Without a module there would be
-- nothing to stop it with when the plugin's module turns off.
local function ownerAtLoad(handle, what)
    local module = Plugins.Module(handle)
    if not module then
        fail(what .. " needs your module, as RegisterModule returned it", 3)
    end
    if started() then
        fail(what .. " is made once, while the plugin loads (before PLAYER_LOGIN), not in OnEnable", 3)
    end
    return module
end

-- Timers ---------------------------------------------------------------------------------------

local function startTimer(timer, seconds, fn)
    timer:Start(seconds, fn)
    return true
end

-- A plugin's timer: its three methods over one of ours (Frames.Timer), which stays out of reach.
local function newTimer(module)
    local timer = ns.Frames.Timer(module)
    local wrapper
    local function check(self, ok, usage)
        if self ~= wrapper or not ok then
            fail("call it as timer:" .. usage, 3)
        end
    end
    wrapper = readOnly({
        -- Nothing starts while the module is off: a run waiting from then would happen once it
        -- turned on again.
        Start = function(self, seconds, fn)
            check(self, finite(seconds) and seconds >= 0 and type(fn) == "function", "Start(seconds, fn)")
            if not module.enabled then
                return false
            end
            return safe(startTimer, timer, seconds, guarded(fn)) or false
        end,
        Cancel = function(self)
            check(self, true, "Cancel()")
            safe(timer.Cancel, timer)
        end,
        IsPending = function(self)
            check(self, true, "IsPending()")
            return safe(timer.IsPending, timer) or false
        end,
    }, "a plugin's timer")
    return wrapper
end

-- The world map --------------------------------------------------------------------------------

local SIZE_MIN, SIZE_MAX = 4, 128 -- an icon's size in pixels: one that can be seen, and no wall

-- A tooltip line as MapTooltip.AddLines takes it, or nil for anything else: text, or a table of
-- text, a color with r, g, and b, and optionally `right`. Copied, so the tooltip never reads a
-- table the plugin still holds.
local function copyLine(line)
    if type(line) == "string" then
        return line
    end
    if type(line) ~= "table" or type(line[1]) ~= "string" then
        return nil
    end
    local color = line[2]
    if type(color) ~= "table" or not (finite(color.r) and finite(color.g) and finite(color.b)) then
        return line[1]
    end
    return { line[1], { r = color.r, g = color.g, b = color.b },
        right = type(line.right) == "string" and line.right or nil }
end

local function copyLines(lines)
    local copies = {}
    if type(lines) == "table" then
        for _, line in ipairs(lines) do
            copies[#copies + 1] = copyLine(line)
        end
    end
    return copies
end

-- The functions a plugin's icon may have for clicks, each called with what `fn(pin, button)` got.
local CLICKS = { "click", "ctrlClick", "shiftClick" }
-- Its text fields; `title` it must have, since the tooltip is drawn from it.
local TEXTS = { "title", "kind", "clickHint", "shiftHint" }

-- An icon as MapPins takes it, made from what a plugin gave `add`: only the fields docs/api.md
-- names, each checked, since MapPins trusts our own modules with them and reads them later, as
-- the map zooms and the mouse moves. Returns nil and what's wrong with it.
local function copyIcon(x, y, info)
    if not (finite(x) and finite(y)) then
        return nil, "x and y are numbers"
    end
    if type(info) ~= "table" then
        return nil, "info is a table"
    end
    local atlas, texture = info.atlas, info.texture
    if type(atlas) ~= "string" and type(texture) ~= "string" and not finite(texture) then
        return nil, "info needs an atlas or a texture"
    end
    if not finite(info.size) then
        return nil, "info.size is a number"
    end
    local icon = {
        atlas = type(atlas) == "string" and atlas or nil,
        size = max(SIZE_MIN, min(SIZE_MAX, info.size)),
        desaturated = info.desaturated and true or false,
        round = info.round and true or nil,
        waypoint = info.waypoint and true or nil,
    }
    if not icon.atlas then
        icon.texture = texture
    end
    for _, field in ipairs(TEXTS) do
        local value = info[field]
        if value ~= nil and type(value) ~= "string" then
            return nil, "info." .. field .. " is text"
        end
        icon[field] = value
    end
    if not icon.title then
        return nil, "info needs a title"
    end
    local color = info.color
    if color ~= nil then
        if type(color) ~= "table" or not (finite(color[1]) and finite(color[2]) and finite(color[3])) then
            return nil, "info.color is { r, g, b }"
        end
        icon.color = { color[1], color[2], color[3] }
    end
    if info.alpha ~= nil then
        if not finite(info.alpha) then
            return nil, "info.alpha is a number"
        end
        icon.alpha = max(0, min(1, info.alpha))
    end
    -- The plugin's functions get its own `info` back, with whatever else it keeps there, and for
    -- a click a plain table saying where the icon is: never our icon, nor the pin's frame.
    local lines = info.lines
    if type(lines) == "function" then
        local run = guarded(lines)
        icon.lines = function()
            return copyLines(run(info))
        end
    elseif lines ~= nil then
        if type(lines) ~= "table" then
            return nil, "info.lines is a list, or a function giving one"
        end
        icon.lines = copyLines(lines)
    end
    for _, field in ipairs(CLICKS) do
        local fn = info[field]
        if fn ~= nil then
            if type(fn) ~= "function" then
                return nil, "info." .. field .. " is a function"
            end
            local run = guarded(fn)
            icon[field] = function(pin, button)
                run({ x = x, y = y, mapID = pin.mapID, info = info }, button)
            end
        end
    end
    return icon
end

-- A plugin's map layer: three methods over one of ours (MapPins.New), which stays out of reach.
local function newLayer(module, fill)
    local run = guarded(fill)
    local layer = ns.MapPins.New(function(mapID, add)
        -- `add` works only while `fill` runs: kept and called later, it would put an icon on
        -- whatever map is showing by then.
        local open = true
        run(mapID, function(x, y, info)
            if not open then
                fail("add is for inside fill", 2)
            end
            local icon, problem = copyIcon(x, y, info)
            if not icon then
                fail("add(x, y, info): " .. problem, 2)
            end
            safe(add, x, y, icon)
        end)
        open = false
    end)
    local layers = states[module].layers
    layers[#layers + 1] = layer
    local wrapper
    local function check(self, usage)
        if self ~= wrapper then
            fail("call it as layer:" .. usage, 3)
        end
    end
    wrapper = readOnly({
        -- Only while the module is on; it comes off by itself when the module turns off.
        Enable = function(self)
            check(self, "Enable()")
            if not module.enabled then
                return false
            end
            safe(layer.Enable, layer)
            return true
        end,
        Disable = function(self)
            check(self, "Disable()")
            safe(layer.Disable, layer)
        end,
        Refresh = function(self)
            check(self, "Refresh()")
            safe(layer.Refresh, layer)
        end,
    }, "a plugin's map layer")
    return wrapper
end

-- The rest -------------------------------------------------------------------------------------

-- A read-only table of some of a library's functions, by name, each called protected. The
-- library is looked up when one is called, so a function it lacks answers nil.
local function pick(library, names, label, checks)
    local contents = {}
    for _, name in ipairs(names) do
        contents[name] = checks and checks[name] or function(...)
            return safe(ns[library][name], ...)
        end
    end
    return readOnly(contents, label)
end

-- A tooltip line's text, from text or a number.
local function lineText(value, usage)
    if type(value) == "number" then
        return tostring(value)
    elseif type(value) ~= "string" then
        fail("Tooltip." .. usage, 3)
    end
    return value
end

-- The plugin's function -> the guarded one QuestieDB waits with, so Cancel finds it. Weak both
-- ways: QuestieDB holds the guarded one while it waits, and nothing needs it after.
local readyFns = setmetatable({}, { __mode = "kv" })

local kit

---The helpers a plugin's module uses, as a read-only table (docs/api.md lists them). Built once.
---@return table kit
function Plugins.Kit()
    if kit then
        return kit
    end
    kit = readOnly({
        -- Combat and timing
        AfterCombat = function(fn)
            if type(fn) ~= "function" then
                fail("AfterCombat(fn)", 2)
            end
            safe(ns.AfterCombat, guarded(fn))
        end,
        Coalesce = function(fn, delay, handle)
            if type(fn) ~= "function" or delay ~= nil and not (finite(delay) and delay >= 0) then
                fail("Coalesce(fn, delay, module)", 2)
            end
            local module = ownerAtLoad(handle, "Coalesce")
            local queue, cancel = ns.Frames.Coalesce(guarded(fn), delay, module)
            -- Nothing is queued while the module is off, as with a timer.
            return function()
                if module.enabled then
                    safe(queue)
                end
            end, function()
                safe(cancel)
            end
        end,
        Timer = function(handle)
            return newTimer(ownerAtLoad(handle, "Timer"))
        end,
        HasEvent = function(event)
            return type(event) == "string" and safe(ns.HasEvent, event) or false
        end,
        -- Secret values
        IsReadable = ns.IsReadable,
        IsText = ns.IsText,
        IsNumber = ns.IsNumber,
        -- The world map
        NewMapLayer = function(fill, handle)
            if type(fill) ~= "function" then
                fail("NewMapLayer(fill, module)", 2)
            end
            return newLayer(ownerAtLoad(handle, "NewMapLayer"), fill)
        end,
        SetWaypoint = function(map, x, y, name)
            if not (finite(x) and finite(y)) then
                return false, "range"
            elseif not finite(map) then
                return false, "zone"
            end
            return safe(ns.WorldMap.SetWaypoint, map, x, y, type(name) == "string" and name or nil)
        end,
        IsContinent = function(info, cosmic)
            return type(info) == "table" and safe(ns.WorldMap.IsContinent, info, cosmic) or false
        end,
        Tooltip = pick("MapTooltip", { "Note", "Detail", "Pair" }, "the kit's Tooltip", {
            Note = function(text)
                return safe(ns.MapTooltip.Note, lineText(text, "Note(text)"))
            end,
            Detail = function(text)
                return safe(ns.MapTooltip.Detail, lineText(text, "Detail(text)"))
            end,
            Pair = function(label, value)
                return safe(ns.MapTooltip.Pair, lineText(label, "Pair(label, value)"),
                    lineText(value, "Pair(label, value)"))
            end,
        }),
        -- The QuestieDB addon's data, in our shapes
        QuestieDB = pick("QuestieDB", { "Status", "IsAvailable", "IsReady", "OnReady", "Cancel", "Ids",
            "IdsByName", "Quest", "Npc", "Item", "Object", "UiMapID" }, "the kit's QuestieDB", {
            OnReady = function(fn)
                if type(fn) ~= "function" then
                    fail("QuestieDB.OnReady(fn)", 2)
                end
                local run = readyFns[fn] or guarded(fn)
                readyFns[fn] = run
                safe(ns.QuestieDB.OnReady, run)
            end,
            Cancel = function(fn)
                local run = fn ~= nil and readyFns[fn]
                if run then
                    safe(ns.QuestieDB.Cancel, run)
                end
            end,
        }),
    }, "the plugin kit")
    return kit
end
