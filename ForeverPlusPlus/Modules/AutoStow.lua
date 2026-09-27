-- Auto Stow: puts your weapons away a few seconds after combat ends. One sheath puts away
-- everything drawn (a sword and a gun alike), so it's one toggle. Nothing happens if they're
-- already away, if combat starts again first, or if you draw or stow them yourself meanwhile.
local _, ns = ...

local ipairs, tonumber, format = ipairs, tonumber, string.format
-- The original ToggleSheath, from before the hook below, so our own stow doesn't look like the
-- player pressing the key.
local GetSheathState, ToggleSheath, hooksecurefunc = GetSheathState, ToggleSheath, hooksecurefunc
local UnitAffectingCombat, UnitIsDeadOrGhost = UnitAffectingCombat, UnitIsDeadOrGhost
local UnitCastingInfo, UnitChannelInfo, C_Timer = UnitCastingInfo, UnitChannelInfo, C_Timer

local L = ns.L

local DELAYS = { "3", "5", "10", "15", "30" } -- seconds

local module = ns.NewModule("AutoStow", L.AUTOSTOW_DESC, {
    enabled = true,
    delay = "5",
})
module.title = L.AUTOSTOW_TITLE
module.category = "automation"

local choices = {}
for i, seconds in ipairs(DELAYS) do
    choices[i] = { seconds, format(L.AUTOSTOW_SECONDS, tonumber(seconds)) }
end

module.options = {
    {
        key = "delay",
        name = L.AUTOSTOW_DELAY,
        description = L.AUTOSTOW_DELAY_DESC,
        choices = choices,
    },
}

-- GetSheathState: 1 is nothing drawn, 2 melee drawn, 3 ranged drawn.
local SHEATHED = 1
local RETRY = 1 -- seconds to wait while casting before trying again

local timer -- the pending stow, or nil
local hooked = false

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

local function onCombatEnd()
    cancel()
    timer = C_Timer.NewTimer(tonumber(module.db.delay) or 5, stow)
end

function module:OnEnable()
    self:On("PLAYER_REGEN_ENABLED", onCombatEnd)
    self:On("PLAYER_REGEN_DISABLED", cancel)
    -- Drawing or stowing by hand (the Sheath/Unsheath key) is the player's choice; leave it.
    -- Hooks can't be removed, but this one only cancels a pending stow, and while the module is
    -- off there never is one.
    if not hooked then
        hooked = true
        hooksecurefunc("ToggleSheath", cancel)
    end
end

function module:OnDisable()
    cancel()
end
