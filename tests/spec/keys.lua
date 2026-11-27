-- Keys: the modifier key a module lets the player hold, its dropdown, and old Hold Shift to Skip
-- checkboxes becoming key dropdowns.
local T = ...
local ns, eq = T.ns, T.eq

-- Which keys are held.
local held = {}
IsShiftKeyDown = function() return held.shift end
IsControlKeyDown = function() return held.ctrl end
IsAltKeyDown = function() return held.alt end
-- The controller interface, and whether a trigger is held (Lib/Gamepad.lua; which triggers count
-- is tested in the gamepad spec).
local pad = { on = false }
ns.IsTrue = function(value) return value == true end
GamepadMode = {
    IsHUDBindingModifierDown = function() return pad.hud end,
}
T.load("Locales/enUS/Automation")
T.load("Lib/Gamepad")
ns.Gamepad.On = function() return pad.on end
T.load("Lib/Keys") -- it caches the three
local Keys = ns.Keys

eq(Keys.IsDown("shift"), false, "keys: nothing held")
held.shift = true
eq(Keys.IsDown("shift"), true, "keys: shift held")
eq(Keys.IsDown("ctrl"), false, "keys: another key isn't")
held.shift, held.alt = nil, 1
eq(Keys.IsDown("alt"), true, "keys: any true answer is held")
eq(Keys.IsDown("none"), false, "keys: None is never held")
eq(Keys.IsDown("nonsense"), false, "keys: an unknown key isn't held")

-- With the controller interface on, a held trigger stands in for the key.
held.alt = nil
pad.hud = true
eq(Keys.IsDown("shift"), false, "keys: a trigger means nothing without the controller interface")
eq(Keys.Detail(), false, "keys: nor are Shift's details shown")
pad.on = true
eq(Keys.IsDown("shift"), true, "keys: a held trigger is the key with the controller interface on")
eq(Keys.IsDown("none"), false, "keys: None still is never held")
pad.hud = false
eq(Keys.Detail(), true, "keys: Shift's details always show with the controller interface on")
pad.on = false
held.shift = true
eq(Keys.Detail(), true, "keys: and with Shift held without it")
held.shift = nil

local option = Keys.Option("skipKey", "Skip Key", "Hold it to skip.", "General", "1.0.0")
eq(option.key == "skipKey" and option.section == "General" and option.changed, "1.0.0",
    "keys: the dropdown option")
eq(option.choices, Keys.CHOICES, "keys: with the same choices as every other")
local values = {}
for _, choice in ipairs(Keys.CHOICES) do
    values[#values + 1] = choice[1]
    eq(type(choice[2]) == "string" and choice[2] ~= "", true, "keys: " .. choice[1] .. " has a name")
end
eq(table.concat(values, ","), "shift,ctrl,alt,none", "keys: the choices, in order")

-- A key binding in short, from its raw key names. A key with a long name of its own the game
-- names in the player's language, which stands in here for anything not shortened.
GetBindingText = function(key) return key == "PRINTSCREEN" and "Print Screen" or "" end
local short = Keys.Short
eq(short("SHIFT-C"), "SC", "keys: Shift and a letter")
eq(short("C"), "C", "keys: a letter alone")
eq(short("CTRL-SHIFT-1"), "CS1", "keys: two modifiers, in the binding's order")
eq(short("ALT-F12"), "AF12", "keys: a function key")
eq(short("BUTTON3"), "MMB", "keys: the middle mouse button")
eq(short("SHIFT-BUTTON4"), "SM4", "keys: another mouse button, by number")
eq(short("MOUSEWHEELUP"), "WU", "keys: the mouse wheel")
eq(short("CTRL-NUMPAD7"), "CN7", "keys: a number pad digit")
eq(short("NUMPADPLUS"), "N+", "keys: a number pad sign")
eq(short("SHIFT--"), "S-", "keys: the minus key after a modifier")
eq(short("-"), "-", "keys: the minus key alone")
eq(short("LSHIFT-SPACE"), "SSpc", "keys: a left or right modifier, and a long key name")
eq(short("ALT-\195\150"), "A\195\150", "keys: a letter of another keyboard's layout, whole")
eq(short("PRINTSCREEN"), "Print Screen", "keys: a key with no short form, as the game names it")
eq(short("NUMPADENTER"), "NUMPADENTER", "keys: one the game has no text for, as it is")
eq(short("PAD1"), nil, "keys: a controller button is left to the game")
eq(short("SHIFT-PADLTRIGGER"), nil, "keys: also after a modifier")
eq(short(nil), nil, "keys: nothing bound")
eq(short(""), nil, "keys: nothing bound, as an empty string")

-- Hold Shift to Skip checkboxes become key dropdowns.
local shiftSaved = { AutoGossip = { shiftSkips = false }, AutoRepair = { shiftSkips = true },
    AutoQuest = { shiftSkips = "odd" } }
Keys.MigrateShift(shiftSaved, "AutoGossip", "shiftSkips", "skipKey")
Keys.MigrateShift(shiftSaved, "AutoRepair", "shiftSkips", "skipKey")
Keys.MigrateShift(shiftSaved, "AutoSellJunk", "shiftSkips", "skipKey")
Keys.MigrateShift(shiftSaved, "AutoQuest", "shiftSkips", "skipKey")
eq(shiftSaved.AutoGossip.skipKey, "none", "keys: an unticked checkbox is None")
eq(shiftSaved.AutoRepair.skipKey, "shift", "keys: a ticked checkbox is Shift")
eq(shiftSaved.AutoRepair.shiftSkips, nil, "keys: the checkbox goes")
eq(shiftSaved.AutoSellJunk, nil, "keys: nothing saved, nothing made")
eq(shiftSaved.AutoQuest.skipKey == nil and shiftSaved.AutoQuest.shiftSkips, "odd",
    "keys: a value that isn't a checkbox's is left alone")
