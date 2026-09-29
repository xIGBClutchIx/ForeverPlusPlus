-- Load-on-demand Blizzard addons: whether one has loaded, and code to run once it has. Nothing is
-- listened to until something waits.
local _, ns = ...

local pairs, next, C_AddOns = pairs, next, C_AddOns

local call = ns.Call -- so one waiter's error doesn't stop the others

local AddOns = {}
ns.AddOns = AddOns

---Whether an addon has loaded. Probe: without C_AddOns, everything counts as loaded.
---@param name string
---@return boolean
function AddOns.IsLoaded(name)
    return not C_AddOns or (C_AddOns.IsAddOnLoaded(name) and true or false)
end

local waiting = {} -- addon name -> { fn = true }

local function onLoaded(_, name)
    local fns = waiting[name]
    if not fns then
        return
    end
    waiting[name] = nil
    if not next(waiting) then
        ns.Off("ADDON_LOADED", onLoaded)
    end
    for fn in pairs(fns) do
        call(fn, name)
    end
end

---Calls `fn(name)` now if the addon has loaded, or else once it does. Waiting with the same `fn`
---again doesn't call it twice; `AddOns.Cancel` stops the wait, for a module turned off first.
---@param name string
---@param fn fun(name: string)
function AddOns.WhenLoaded(name, fn)
    if AddOns.IsLoaded(name) then
        fn(name)
        return
    end
    if not next(waiting) then
        ns.On("ADDON_LOADED", onLoaded)
    end
    waiting[name] = waiting[name] or {}
    waiting[name][fn] = true
end

---Stops waiting to call `fn` when the addon loads.
---@param name string
---@param fn function
function AddOns.Cancel(name, fn)
    local fns = waiting[name]
    if not (fns and fns[fn]) then
        return
    end
    fns[fn] = nil
    if not next(fns) then
        waiting[name] = nil
    end
    if not next(waiting) then
        ns.Off("ADDON_LOADED", onLoaded)
    end
end
