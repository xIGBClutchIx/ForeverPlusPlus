-- Fishing Cast: right-click twice quickly in the world with a fishing pole equipped to cast
-- Fishing. Casting a spell is protected, so the second click doesn't cast from our code: it puts a
-- temporary override binding for the right mouse button on our own secure button, which casts the
-- spell when the click goes through. That can't be changed in combat, so nothing is armed then,
-- and the binding comes off again on the next click so a right-click on the bobber still loots.
local _, ns = ...

local GetTime, InCombatLockdown, CreateFrame = GetTime, InCombatLockdown, CreateFrame
local SetOverrideBindingSpell, ClearOverrideBindings = SetOverrideBindingSpell, ClearOverrideBindings
local GetInventoryItemID, UnitExists, GetUnitSpeed = GetInventoryItemID, UnitExists, GetUnitSpeed
local C_Item, C_Spell, WorldFrame = C_Item, C_Spell, WorldFrame
local GetMouseFoci, GetMouseFocus, UnitChannelInfo = GetMouseFoci, GetMouseFocus, UnitChannelInfo

local L = ns.L

local module = ns.NewModule("FishingCast", L.FISHINGCAST_DESC, {
    enabled = false,
    speed = 400, -- milliseconds allowed between the two clicks
})
module.title = L.FISHINGCAST_TITLE
module.category = "automation"

module.options = {
    {
        key = "speed",
        name = L.FISHINGCAST_SPEED,
        description = L.FISHINGCAST_SPEED_DESC,
        min = 200, max = 600, step = 50, format = function(ms) return L.FISHINGCAST_MS:format(ms) end,
    },
}

local MAINHAND = 16
local POLE_CLASS, POLE_SUBCLASS = 2, 20 -- weapons: fishing poles
local FISHING = 131474 -- the Fishing spell; 7620 is the older ID for it
local MIN_GAP = 0.05 -- seconds; a faster second click is a bounce, not a double click

local button -- our secure button, made on first enable (a frame can't be removed)
local lastClick = 0
local armed = false

local function poleEquipped()
    local id = GetInventoryItemID("player", MAINHAND)
    if not id or not C_Item.GetItemInfoInstant then
        return false
    end
    local _, _, _, _, _, class, subclass = C_Item.GetItemInfoInstant(id)
    return class == POLE_CLASS and subclass == POLE_SUBCLASS
end

-- Whether the mouse is over the world and not a window or button.
local function overWorld()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return foci and foci[1] == WorldFrame
    end
    return GetMouseFocus and GetMouseFocus() == WorldFrame
end

local function disarm()
    if armed and button and not InCombatLockdown() then
        ClearOverrideBindings(button)
        armed = false
    end
end

local function arm()
    local name = C_Spell.GetSpellName(FISHING) or C_Spell.GetSpellName(7620)
    if name then
        SetOverrideBindingSpell(button, true, "BUTTON2", name)
        armed = true
    end
end

-- Runs before the game handles the click, so arming here catches this same second click.
local function onMouseDown(_, buttonName)
    if InCombatLockdown() then
        return
    end
    disarm()
    if buttonName ~= "RightButton" then
        lastClick = 0
        return
    end
    if not overWorld() or UnitExists("mouseover") or GetUnitSpeed("player") > 0
        or UnitChannelInfo("player") or not poleEquipped() then
        lastClick = 0
        return
    end
    local now = GetTime()
    local gap = now - lastClick
    if gap > MIN_GAP and gap < module.db.speed / 1000 then
        lastClick = 0
        arm()
    else
        lastClick = now
    end
end

-- The cast has started: take the binding off so the next right-click is an ordinary one.
local function onCastStart(_, unit)
    if unit == "player" then
        disarm()
    end
end

function module:OnEnable()
    if not button then
        button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    end
    lastClick = 0
    self:On("GLOBAL_MOUSE_DOWN", onMouseDown)
    self:On("UNIT_SPELLCAST_CHANNEL_START", onCastStart)
    self:On("UNIT_SPELLCAST_START", onCastStart)
    -- Combat starts: never leave a right-click casting Fishing; if the lockdown already began,
    -- wait for it to end.
    self:On("PLAYER_REGEN_DISABLED", function()
        if armed then
            ns.AfterCombat(disarm)
        end
        lastClick = 0
    end)
end

function module:OnDisable()
    if armed then
        ns.AfterCombat(disarm)
    end
end
