-- Fishing Cast: right-click twice quickly in the world with a fishing pole equipped to cast
-- Fishing. Casting a spell is protected, so the second click doesn't cast from our code: it puts a
-- temporary override binding for the right mouse button on our own secure button, which casts the
-- spell when the click goes through. That can't be changed in combat, so nothing is armed then,
-- and the binding comes off again on the next click so a right-click on the bobber still loots.
local _, ns = ...

local GetTime, InCombatLockdown, CreateFrame = GetTime, InCombatLockdown, CreateFrame
local SetOverrideBindingSpell, ClearOverrideBindings = SetOverrideBindingSpell, ClearOverrideBindings
local GetInventoryItemID, UnitExists, GetUnitSpeed = GetInventoryItemID, UnitExists, GetUnitSpeed
local C_Item, C_Spell, C_Timer, WorldFrame = C_Item, C_Spell, C_Timer, WorldFrame
local UIErrorsFrame = UIErrorsFrame
local GetMouseFoci, GetMouseFocus, UnitChannelInfo = GetMouseFoci, GetMouseFocus, UnitChannelInfo

local L = ns.L

local module = ns.NewModule("FishingCast", L.FISHINGCAST_DESC, {
    enabled = false,
    speed = 400, -- milliseconds allowed between the two clicks
    combatWarning = true,
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
    { key = "combatWarning", name = L.FISHINGCAST_COMBAT, description = L.FISHINGCAST_COMBAT_DESC },
}

local MAINHAND = 16
local POLE_CLASS, POLE_SUBCLASS = 2, 20 -- weapons: fishing poles
local FISHING = 131474 -- the Fishing spell; 7620 is the older ID for it

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
        -- Forever returns an empty list over the bare world, not WorldFrame.
        local foci = GetMouseFoci()
        return not foci or foci[1] == nil or foci[1] == WorldFrame
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

-- The first right-click is only noted; the binding goes on when it is released, so it is already
-- in place when the second press comes (arming during the press itself was too late for the game
-- to see it). A timer takes it off again if no second click follows.
local function onMouseDown(_, buttonName)
    if InCombatLockdown() then
        return
    end
    if armed then
        -- This is the second click: leave the binding for it; the cast start removes it.
        lastClick = 0
        return
    end
    if buttonName ~= "RightButton" then
        lastClick = 0
        return
    end
    if not overWorld() or UnitExists("mouseover") or GetUnitSpeed("player") > 0
        or UnitChannelInfo("player") or not poleEquipped() then
        lastClick = 0
        return
    end
    lastClick = GetTime()
end

local function onMouseUp(_, buttonName)
    if InCombatLockdown() or armed or buttonName ~= "RightButton" or lastClick == 0 then
        return
    end
    local window = module.db.speed / 1000
    if GetTime() - lastClick >= window then
        lastClick = 0
        return
    end
    arm()
    C_Timer.After(window, function()
        lastClick = 0
        disarm()
    end)
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
    self:On("GLOBAL_MOUSE_UP", onMouseUp)
    self:On("UNIT_SPELLCAST_CHANNEL_START", onCastStart)
    self:On("UNIT_SPELLCAST_START", onCastStart)
    -- Combat starts: never leave a right-click casting Fishing; if the lockdown already began,
    -- wait for it to end.
    self:On("PLAYER_REGEN_DISABLED", function()
        if armed then
            ns.AfterCombat(disarm)
        end
        lastClick = 0
        -- Combat with a pole still in hand: one red line where Blizzard's own errors show.
        if module.db.combatWarning and poleEquipped() and UIErrorsFrame then
            local red = ns.Colors.RED
            UIErrorsFrame:AddMessage(L.FISHINGCAST_COMBAT_TEXT, red[1], red[2], red[3])
        end
    end)
end

function module:OnDisable()
    if armed then
        ns.AfterCombat(disarm)
    end
end
