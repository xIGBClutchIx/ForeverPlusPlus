-- Auto Stow: puts a ranged weapon away a few seconds after combat ends, with one toggle. The game
-- sheathes by itself within a few seconds of combat, and with a ranged weapon equipped the
-- Sheath key cycles away, melee, ranged, so a toggle with melee out would draw the ranged weapon:
-- melee drawn is left to the game (Cameron's log, 2026-10-22). What a toggle from ranged drawn
-- does isn't measured yet; Log Sheath State (Debug page) prints it. Nothing happens if they're
-- already away, if combat starts again first, or if you draw or stow them yourself meanwhile.
local _, ns = ...

-- The original ToggleSheath, from before the hook below, so our own stow doesn't look like the
-- player pressing the key.
local GetSheathState, ToggleSheath = GetSheathState, ToggleSheath
local UnitAffectingCombat, UnitIsDeadOrGhost = UnitAffectingCombat, UnitIsDeadOrGhost
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local IsInInstance, GetTime = IsInInstance, GetTime
local format, tostring = string.format, tostring

local L = ns.L

local module = ns.NewModule("AutoStow", L.AUTOSTOW_DESC, {
    enabled = true,
    delay = 5, -- seconds
    outsideOnly = false, -- leave weapons out in dungeons and raids
    logSheath = false,
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
    {
        key = "logSheath",
        name = L.AUTOSTOW_LOG,
        description = L.AUTOSTOW_LOG_DESC,
        debug = true,
        section = L.DEBUG_SECTION_LOGGING,
        added = "0.10.0",
    },
}

-- GetSheathState: 1 is nothing drawn, 2 melee drawn, 3 ranged drawn.
local SHEATHED, MELEE = 1, 2
local RETRY = 1 -- seconds to wait while casting before trying again

local timer = ns.Frames.Timer(module) -- the pending stow

-- Log Sheath State --------------------------------------------------------------------------
-- From combat's end until a few seconds after our toggle, the sheath state every quarter
-- second, printed when it changes, and what we and the player did, with GetTime() stamps.

local SAMPLE = 0.25 -- seconds between looks
local AFTER = 4 -- seconds to keep looking after our toggle (or after the stow was dropped)

local sampler = ns.Frames.Timer(module)
local lastSeen, stopAt

local function log(text)
    if module.db.logSheath then
        ns.Print(format(L.AUTOSTOW_LOG_LINE, GetTime(), text))
    end
end

local function sample()
    local state = GetSheathState()
    if state ~= lastSeen then
        log(format(L.AUTOSTOW_LOG_STATE, tostring(state)))
        lastSeen = state
    end
    if stopAt and GetTime() >= stopAt then
        log(L.AUTOSTOW_LOG_DONE)
        stopAt = nil
        return
    end
    sampler:Start(SAMPLE, sample)
end

-- Keeps looking for AFTER seconds from now (or, with `open`, until told otherwise).
local function watch(open)
    if not module.db.logSheath then
        return
    end
    stopAt = not open and GetTime() + AFTER or nil
    if not sampler:IsPending() then
        lastSeen = nil
        sample()
    end
end

-- Stowing -------------------------------------------------------------------------------------

local function cancel()
    timer:Cancel()
end

local function stow()
    -- Melee drawn is left to the game, which sheathes it by itself, since a toggle there draws
    -- the ranged weapon instead.
    local state = GetSheathState()
    if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player")
        or state == SHEATHED or state == MELEE then
        log(format(L.AUTOSTOW_LOG_SKIPPED, tostring(GetSheathState())))
        watch()
        return
    end
    -- Sheathing mid-cast can interrupt it; wait for the cast to finish. The player's own cast,
    -- out of combat, isn't secret.
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        timer:Start(RETRY, stow)
        return
    end
    log(format(L.AUTOSTOW_LOG_TOGGLE, tostring(GetSheathState())))
    ToggleSheath()
    log(format(L.AUTOSTOW_LOG_TOGGLED, tostring(GetSheathState())))
    watch()
end

-- A dungeon, raid, battleground or arena.
local function inInstance()
    local inside, kind = IsInInstance()
    return inside and kind ~= "none"
end

local function onCombatEnd()
    cancel()
    log(format(L.AUTOSTOW_LOG_COMBAT_END, tostring(GetSheathState())))
    if module.db.outsideOnly and inInstance() then
        watch()
        return
    end
    watch(true)
    timer:Start(module.db.delay, stow)
end

local function onCombatStart()
    cancel()
    if sampler:IsPending() then
        log(L.AUTOSTOW_LOG_COMBAT_START)
        watch()
    end
end

-- Drawing or stowing by hand (the Sheath/Unsheath key) is the player's choice; leave it.
local function onPlayerToggle()
    if timer:IsPending() or sampler:IsPending() then
        log(format(L.AUTOSTOW_LOG_PLAYER, tostring(GetSheathState())))
        watch()
    end
    cancel()
end

function module:OnEnable()
    self:On("PLAYER_REGEN_ENABLED", onCombatEnd)
    self:On("PLAYER_REGEN_DISABLED", onCombatStart)
    self:Hook("ToggleSheath", onPlayerToggle)
end

function module:OnOptionChanged(key)
    if key == "logSheath" and not module.db.logSheath then
        sampler:Cancel()
        stopAt = nil
    end
end
