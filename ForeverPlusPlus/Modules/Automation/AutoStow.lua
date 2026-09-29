-- Auto Stow: puts your weapons away a few seconds after combat ends. One sheath puts away
-- everything drawn (a sword and a gun alike), so it's one toggle. Nothing happens if they're
-- already away, if combat starts again first, or if you draw or stow them yourself meanwhile.
local _, ns = ...

-- The original ToggleSheath, from before the hook below, so our own stow doesn't look like the
-- player pressing the key.
local GetSheathState, ToggleSheath = GetSheathState, ToggleSheath
local UnitAffectingCombat, UnitIsDeadOrGhost = UnitAffectingCombat, UnitIsDeadOrGhost
local UnitCastingInfo, UnitChannelInfo, C_Timer = UnitCastingInfo, UnitChannelInfo, C_Timer
local IsInInstance = IsInInstance

local L = ns.L

local module = ns.NewModule("AutoStow", L.AUTOSTOW_DESC, {
    enabled = true,
    delay = 5, -- seconds
    outsideOnly = false, -- leave weapons out in dungeons and raids
})
module.title = L.AUTOSTOW_TITLE
module.category = "automation"

module.options = {
    {
        key = "delay",
        name = L.AUTOSTOW_DELAY,
        description = L.AUTOSTOW_DELAY_DESC,
        min = 3, max = 30, step = 1, format = ns.Text.Seconds,
    },
    {
        key = "outsideOnly",
        name = L.AUTOSTOW_OUTSIDE_ONLY,
        description = L.AUTOSTOW_OUTSIDE_ONLY_DESC,
    },
}

-- GetSheathState: 1 is nothing drawn, 2 melee drawn, 3 ranged drawn.
local SHEATHED = 1
local RETRY = 1 -- seconds to wait while casting before trying again

local timer -- the pending stow, or nil

local function cancel()
    if timer then
        timer:Cancel()
        timer = nil
    end
end

local function stow()
    timer = nil
    if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player")
        or GetSheathState() == SHEATHED then
        return
    end
    -- Sheathing mid-cast can interrupt it; wait for the cast to finish. The player's own cast,
    -- out of combat, isn't secret.
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        timer = C_Timer.NewTimer(RETRY, stow)
        return
    end
    ToggleSheath()
end

-- A dungeon, raid, battleground or arena.
local function inInstance()
    local inside, kind = IsInInstance()
    return inside and kind ~= "none"
end

local function onCombatEnd()
    cancel()
    if module.db.outsideOnly and inInstance() then
        return
    end
    timer = C_Timer.NewTimer(module.db.delay, stow)
end

function module:OnEnable()
    self:On("PLAYER_REGEN_ENABLED", onCombatEnd)
    self:On("PLAYER_REGEN_DISABLED", cancel)
    -- Drawing or stowing by hand (the Sheath/Unsheath key) is the player's choice; leave it.
    self:Hook("ToggleSheath", cancel)
end

function module:OnDisable()
    cancel()
end
