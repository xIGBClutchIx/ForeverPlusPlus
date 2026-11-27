-- The modifier key a module lets the player hold to skip what it does (Auto Quest, Auto Gossip,
-- Auto Repair, Auto Sell Junk, Auto Release), to let something through (Skip Cinematics), to
-- pick another action (Minimap Button, World Map's Zone Info), or to drag (Movable Windows), so
-- each offers the same choices under the same names. And a key binding in short, for a label on a
-- small button (Short Keybinds).
local _, ns = ...

local type, concat, _G = type, table.concat, _G
local IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown = IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown
local L = ns.L

local Keys = {}
ns.Keys = Keys

-- Key, then name, as a dropdown's `choices` take them.
Keys.CHOICES = {
    { "shift", L.KEY_SHIFT },
    { "ctrl", L.KEY_CTRL },
    { "alt", L.KEY_ALT },
    { "none", L.KEY_NONE },
}

local DOWN = { shift = IsShiftKeyDown, ctrl = IsControlKeyDown, alt = IsAltKeyDown }

---Whether `key` (a key of `Keys.CHOICES`) is held down. Always false for "none" or a key not
---listed. With the controller interface on there's no keyboard, so a held trigger stands in for
---whichever key is set.
---@param key string
---@return boolean
function Keys.IsDown(key)
    local down = DOWN[key]
    if down == nil then
        return false
    end
    return down() and true or ns.Gamepad.TriggerHeld()
end

---Whether lines and details shown only while Shift is held show now: Shift, or always with the
---controller interface on, where nothing can be held over a tooltip.
---@return boolean
function Keys.Detail()
    return IsShiftKeyDown() and true or ns.Gamepad.On()
end

---A dropdown option for the key setting `key` (such as "skipKey"); its default, such as "shift",
---goes in the module's defaults.
---@param key string the setting
---@param name string
---@param description string
---@param section? string
---@param changed? string the version it last changed in, for its NEW tag
---@return table option
function Keys.Option(key, name, description, section, changed)
    -- With the controller interface on (which takes a reload to change) a trigger is the key,
    -- whichever is picked: say so, with the triggers as the player's controller shows them.
    local Gamepad = ns.Gamepad
    if Gamepad and Gamepad.On() then -- Gamepad isn't there in every offline spec
        description = description .. " " .. L.KEY_PAD_NOTE:format(Gamepad.Label(Gamepad.BUTTON.LEFT_TRIGGER),
            Gamepad.Label(Gamepad.BUTTON.RIGHT_TRIGGER))
    end
    return { key = key, name = name, description = description, choices = Keys.CHOICES,
        section = section, changed = changed }
end

-- A key binding's parts in short, for Keys.Short. Modifiers by the game's names for them in a
-- binding (a left or right one counts as the key itself), then the keys whose names are long.
local SHORT_MODIFIERS = {
    SHIFT = L.KEY_SHORT_SHIFT, LSHIFT = L.KEY_SHORT_SHIFT, RSHIFT = L.KEY_SHORT_SHIFT,
    CTRL = L.KEY_SHORT_CTRL, LCTRL = L.KEY_SHORT_CTRL, RCTRL = L.KEY_SHORT_CTRL,
    ALT = L.KEY_SHORT_ALT, LALT = L.KEY_SHORT_ALT, RALT = L.KEY_SHORT_ALT,
    META = L.KEY_SHORT_META, LMETA = L.KEY_SHORT_META, RMETA = L.KEY_SHORT_META,
}
local SHORT_KEYS = {
    BUTTON3 = L.KEY_SHORT_MOUSE_MIDDLE,
    MOUSEWHEELUP = L.KEY_SHORT_WHEEL_UP, MOUSEWHEELDOWN = L.KEY_SHORT_WHEEL_DOWN,
    SPACE = L.KEY_SHORT_SPACE, PAGEUP = L.KEY_SHORT_PAGEUP, PAGEDOWN = L.KEY_SHORT_PAGEDOWN,
    INSERT = L.KEY_SHORT_INSERT, DELETE = L.KEY_SHORT_DELETE, HOME = L.KEY_SHORT_HOME,
    END = L.KEY_SHORT_END, BACKSPACE = L.KEY_SHORT_BACKSPACE, ESCAPE = L.KEY_SHORT_ESCAPE,
    ENTER = L.KEY_SHORT_ENTER, TAB = L.KEY_SHORT_TAB, CAPSLOCK = L.KEY_SHORT_CAPSLOCK,
    UP = L.KEY_SHORT_UP, DOWN = L.KEY_SHORT_DOWN, LEFT = L.KEY_SHORT_LEFT, RIGHT = L.KEY_SHORT_RIGHT,
}
-- The number pad's keys that aren't a digit, as the sign on them.
local NUMPAD_SIGNS = { PLUS = "+", MINUS = "-", MULTIPLY = "*", DIVIDE = "/", DECIMAL = "." }
-- One character, whole, even when it takes several bytes (UTF-8): a letter, digit, or sign key.
local ONE_CHARACTER = "^[%z\1-\127\194-\244][\128-\191]*$"

-- A binding's key without its modifiers, in short, or nil for a controller button.
local function shortKey(key)
    if key:find("^PAD") then
        return nil
    end
    if key:find(ONE_CHARACTER) or key:find("^F%d+$") then
        return key
    end
    local short = SHORT_KEYS[key]
    if short then
        return short
    end
    local button = key:match("^BUTTON(%d+)$")
    if button then
        return L.KEY_SHORT_MOUSE:format(button)
    end
    local pad = key:match("^NUMPAD(.+)$")
    if pad then
        local sign = NUMPAD_SIGNS[pad] or (pad:find("^%d$") and pad)
        if sign then
            return L.KEY_SHORT_NUMPAD:format(sign)
        end
    end
    -- Anything else (Print Screen, Num Lock) as the game names it in the player's language.
    local getText = _G.GetBindingText
    local text = getText and getText(key)
    return type(text) == "string" and text ~= "" and text or key
end

---A key binding as the game stores it ("SHIFT-C", "CTRL-BUTTON4", "ALT-NUMPAD1") in short, for a
---key label on a small button: "SC", "CM4", "AN1". Built from the binding's own key names, never
---from the game's text for it, so it reads the same in every language (the letters are each
---language's own). Nil for nothing bound, and for a controller button, whose label is the game's
---own icon for it and is left as the game draws it.
---@param binding string?
---@return string?
function Keys.Short(binding)
    if type(binding) ~= "string" or binding == "" then
        return nil
    end
    local modifiers, rest = {}, binding
    while true do
        -- The key itself can be "-": "SHIFT--" is Shift and the minus key.
        local modifier, after = rest:match("^(%u+)%-(.+)$")
        local short = modifier and SHORT_MODIFIERS[modifier]
        if not short then
            break
        end
        modifiers[#modifiers + 1] = short
        rest = after
    end
    local key = shortKey(rest)
    if not key then
        return nil
    end
    return concat(modifiers) .. key
end

---Moves an old "hold Shift" checkbox setting of `saved[module]` to a key setting: Shift while it
---was on, None while it was off. For ns.Migrate.
---@param saved table every module's saved settings
---@param module string
---@param old string the checkbox's setting
---@param new string the key's setting
function Keys.MigrateShift(saved, module, old, new)
    local db = saved[module]
    if not (db and type(db[old]) == "boolean") then
        return
    end
    db[new] = db[old] and "shift" or "none"
    db[old] = nil
end
