-- What Error Catcher shares while it's on, so another module (the minimap button) can show its
-- counts and open its window without reaching into it. Error Catcher provides; others read and
-- listen. Nothing is provided while Error Catcher is off.
local _, ns = ...

local ipairs = ipairs

local call = ns.Call -- so one listener's error doesn't stop the others

local Errors = {}
ns.Errors = Errors

local source -- { session = fn, saved = fn, toggle = fn } while Error Catcher is on
local listeners = {}

---Tells the listeners that the counts changed, or that Error Catcher came or went.
function Errors.Changed()
    for _, fn in ipairs(listeners) do
        call(fn)
    end
end

---Error Catcher's side: its counts and window while it's on, or nil when it turns off.
---@param provider? { session: fun(): number, saved: fun(): number, toggle: fun() }
function Errors.Provide(provider)
    source = provider
    Errors.Changed()
end

---Whether Error Catcher is on to show errors.
---@return boolean
function Errors.IsOn()
    return source ~= nil
end

---How many different errors this session caught, or 0 with Error Catcher off.
---@return number
function Errors.SessionCount()
    return source and source.session() or 0
end

---How many errors are saved, from every session, or 0 with Error Catcher off.
---@return number
function Errors.SavedCount()
    return source and source.saved() or 0
end

---Opens or closes Error Catcher's window, if it's on.
function Errors.Toggle()
    if source then
        source.toggle()
    end
end

---Calls `fn()` whenever the counts change or Error Catcher turns on or off. Add it once.
---@param fn fun()
function Errors.OnChanged(fn)
    listeners[#listeners + 1] = fn
end
