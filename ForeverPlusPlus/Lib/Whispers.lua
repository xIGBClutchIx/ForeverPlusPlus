-- What Whisper Window shares while it's on, so another module (the minimap button) can open it and
-- count unread whispers without reaching into it. Whisper Window provides; others read and listen.
-- Nothing is provided while Whisper Window is off.
local _, ns = ...

local ipairs = ipairs

local call = ns.Call -- so one listener's error doesn't stop the others

local Whispers = {}
ns.Whispers = Whispers

local source -- { toggle, unread } functions while Whisper Window is on
local listeners = {}

---Tells the listeners that the unread count changed, or that Whisper Window came or went.
function Whispers.Changed()
    for _, fn in ipairs(listeners) do
        call(fn)
    end
end

---Whisper Window's side: its window and unread count while it's on, or nil when it turns off.
---@param provider? { toggle: fun(), unread: fun(): number }
function Whispers.Provide(provider)
    source = provider
    Whispers.Changed()
end

---Whether Whisper Window is on.
---@return boolean
function Whispers.IsOn()
    return source ~= nil
end

---How many whispers wait unread, or 0 with Whisper Window off.
---@return number
function Whispers.Unread()
    return source and source.unread() or 0
end

---Opens or closes Whisper Window, if it's on.
function Whispers.Toggle()
    if source then
        source.toggle()
    end
end

---Calls `fn()` whenever the unread count changes or Whisper Window turns on or off. Add it once.
---@param fn fun()
function Whispers.OnChanged(fn)
    listeners[#listeners + 1] = fn
end
