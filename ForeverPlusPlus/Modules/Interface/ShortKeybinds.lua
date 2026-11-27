-- Short Keybinds: the key label in the corner of each action button in short, so it fits: "SC" in
-- place of "s-C", "MMB" in place of "Middle Mouse", "N1" in place of "Num Pad 1". The usual
-- action bars, the pet bar, and the extra action button.
--
-- Blizzard writes the label each time the bindings change, in the button's own UpdateHotkeys
-- (SetHotkeys on the pet bar), as GetBindingText(key, 1) on its HotKey font string
-- (Blizzard_ActionBar's ActionButton.lua and PetActionBar.lua, build 70205). Each button carries
-- its own copy of the method (a mixin is copied into it), so each is hooked, and after Blizzard's
-- the label gets the short text, built from the binding's raw key ("SHIFT-C") by ns.Keys.Short
-- rather than from the game's text, which differs in every language. A font string isn't
-- protected, so this works in combat too. Only the label's text is ours: Blizzard's range check
-- reads it back only to compare it with its range dot, which a button with no key shows, and
-- those are left alone. Controller buttons keep the game's own icons.
--
-- The stance bar has no key labels, and the controller interface's own bars draw icons.
local _, ns = ...

local _G, pairs, setmetatable = _G, pairs, setmetatable
local GetBindingKey, GetBindingText = GetBindingKey, GetBindingText

local L = ns.L
local Keys = ns.Keys

local module = ns.NewModule("ShortKeybinds", L.SHORTKEYBINDS_DESC, {
    enabled = false,
})
module.title = L.SHORTKEYBINDS_TITLE
module.presets = { developer = { enabled = true } }
module.category = "interface"
module.added = "1.10.0"

local PET_BUTTONS = 10 -- PetActionBar's numButtons (NUM_PET_ACTION_SLOTS)

local pet = setmetatable({}, { __mode = "k" }) -- the pet bar's buttons
local shortened = setmetatable({}, { __mode = "k" }) -- buttons whose label is ours now

-- The raw key bound to a button ("SHIFT-C"), looked up as Blizzard looks it up for the label.
local function bindingKey(button)
    if pet[button] then
        return GetBindingKey("BONUSACTIONBUTTON" .. button:GetID())
    end
    local action = button.bindingAction
    local key = action and GetBindingKey(action)
    if not key then
        local name = button:GetName()
        key = name and GetBindingKey("CLICK " .. name .. ":LeftButton")
    end
    return key
end

local function isPadKey(key)
    local forPad = _G.IsBindingForGamePad
    return forPad and forPad(key) and true or false
end

-- After Blizzard has written the button's label: the short text in its place.
local function shorten(button)
    local hotkey = button.HotKey
    local key = hotkey and bindingKey(button)
    local short = key and not isPadKey(key) and Keys.Short(key)
    if short then
        hotkey:SetText(short)
        shortened[button] = true
    else
        shortened[button] = nil
    end
end

local function eachButton(fn)
    ns.ActionButtons.EachBar(function(button)
        fn(button, "UpdateHotkeys")
    end)
    if _G.ExtraActionButton1 then
        fn(_G.ExtraActionButton1, "UpdateHotkeys")
    end
    for index = 1, PET_BUTTONS do
        local button = _G["PetActionButton" .. index]
        if button then
            pet[button] = true
            fn(button, "SetHotkeys")
        end
    end
end

function module:OnEnable()
    eachButton(function(button, method)
        self:Hook(button, method, shorten)
        shorten(button)
    end)
end

-- Blizzard's own text back, as its method writes it, on the labels we changed. GetBindingText is
-- called with 1 as Blizzard's UpdateHotkeys calls it (wowlua-ls expects a string there), which
-- gives the abbreviated "s-C".
function module:OnDisable()
    for button in pairs(shortened) do
        local key = bindingKey(button)
        if key then
            button.HotKey:SetText(GetBindingText(key, 1))
        end
        shortened[button] = nil
    end
end
