-- Keep Audio Synced: when the computer's default sound device changes (headphones plugged in, a
-- headset turned on), restarts the game's sound so it plays on the new device. Without it the
-- game keeps playing on the device it started with.
--
-- The game's own sound devices have no event Blizzard's UI uses, but voice chat's device list
-- (C_VoiceChat) is the system's, and VOICE_CHAT_OUTPUT_DEVICES_UPDATED fires when it changes:
-- Blizzard's Audio settings refresh their voice dropdown on it, and other addons with this
-- feature (EnhanceQoL's Forever port, TurboFace) listen to it too. SOUND_DEVICE_UPDATE is in the API docs but nothing
-- of Blizzard's uses it, and it may be the game's own restart reporting back, so it's left alone.
-- Sound_GameSystem_RestartSoundSystem is in Mainline's global API (Blizzard's old Audio options
-- called it after a device change) and isn't protected, so it works in combat.
--
-- Restarts can't loop: the device list is compared with the last one, so the event firing for
-- anything else (voice chat starting at login, our own restart) changes nothing. A restart stops
-- the sound that's playing, so one that falls in a cinematic, a movie, or a loading screen waits
-- for it to end.
--
-- Following the system's default only means something while the game's Output Device is System
-- Default (Sound_OutputDriverIndex 0); set to a named device, the game stays on that one. That
-- setting is the player's, so a notice says so, with a button, instead of changing it.
local _, ns = ...

local ipairs, type, tostring, sort, concat = ipairs, type, tostring, table.sort, table.concat
local GetTime = GetTime
local C_CVar, C_VoiceChat = C_CVar, C_VoiceChat
local RestartSoundSystem = Sound_GameSystem_RestartSoundSystem

local L = ns.L

local CVAR = "Sound_OutputDriverIndex"
local SYSTEM_DEFAULT = "0"
local DEVICES_EVENT = "VOICE_CHAT_OUTPUT_DEVICES_UPDATED"
-- How long to let a burst of device events settle (Windows reports a headset as several devices).
local SETTLE = 1
-- With no device list to compare, the least time between two restarts, and how long after the
-- module turns on (at login, while voice chat starts) events are only taken as the starting list.
local COOLDOWN, WARMUP = 5, 15

local module = ns.NewModule("KeepAudioSynced", L.KEEPAUDIOSYNCED_DESC, {
    enabled = true,
})
module.title = L.KEEPAUDIOSYNCED_TITLE
module.category = "system"
module.added = "1.10.0"

function module:IsAvailable()
    return RestartSoundSystem ~= nil and C_VoiceChat ~= nil and C_VoiceChat.GetAvailableOutputDevices ~= nil
        and ns.HasEvent(DEVICES_EVENT) and C_CVar.GetCVar(CVAR) ~= nil
end

local function onSystemDefault()
    return C_CVar.GetCVar(CVAR) == SYSTEM_DEFAULT
end

module.notice = {
    text = L.KEEPAUDIOSYNCED_NOT_DEFAULT,
    description = L.KEEPAUDIOSYNCED_NOT_DEFAULT_DESC,
    button = L.KEEPAUDIOSYNCED_USE_DEFAULT,
    fn = function()
        ns.CVars.Apply(CVAR, SYSTEM_DEFAULT)
    end,
    shown = function()
        return module.db.enabled and C_CVar.GetCVar(CVAR) ~= nil and not onSystemDefault()
    end,
}

-- The output devices as one string, or nil while voice chat has no list.
local function deviceList()
    local devices = C_VoiceChat.GetAvailableOutputDevices()
    if type(devices) ~= "table" then
        return nil
    end
    local parts = {}
    for _, device in ipairs(devices) do
        if type(device) == "table" then
            parts[#parts + 1] = tostring(device.deviceID) .. (device.isSystemDefault and "*" or "")
        end
    end
    sort(parts)
    return concat(parts, "\n")
end

local last -- the device list the game's sound last followed
local enabledAt, restartedAt = 0, nil
local busy = { cinematic = false, movie = false, loading = false }
local pending = false

local function isBusy()
    return busy.cinematic or busy.movie or busy.loading
end

local function doRestart()
    if isBusy() then
        pending = true
        return
    end
    pending = false
    if not onSystemDefault() then
        return
    end
    restartedAt = GetTime()
    RestartSoundSystem()
end

local settled = ns.Frames.Coalesce(function()
    local now = deviceList()
    if now then
        local before = last
        last = now
        -- The first list seen is the one the game started on.
        if before ~= nil and before ~= now then
            doRestart()
        end
    elseif GetTime() - enabledAt > WARMUP
        and (restartedAt == nil or GetTime() - restartedAt > COOLDOWN) then
        doRestart()
    end
end, SETTLE, module)

local function setBusy(kind, on)
    busy[kind] = on
    if not on and pending then
        doRestart()
    end
end

function module:OnEnable()
    last = deviceList()
    enabledAt, restartedAt, pending = GetTime(), nil, false
    self:On(DEVICES_EVENT, settled)
    self:On("CINEMATIC_START", function() setBusy("cinematic", true) end)
    self:On("CINEMATIC_STOP", function() setBusy("cinematic", false) end)
    self:On("PLAY_MOVIE", function() setBusy("movie", true) end)
    self:On("STOP_MOVIE", function() setBusy("movie", false) end)
    self:On("LOADING_SCREEN_ENABLED", function() setBusy("loading", true) end)
    self:On("LOADING_SCREEN_DISABLED", function() setBusy("loading", false) end)
    -- The notice follows the Output Device as the player changes it.
    self:On("CVAR_UPDATE", function(_, name)
        if name == CVAR and ns.RefreshSetting then
            ns.RefreshSetting(module.name)
        end
    end)
end

function module:OnDisable()
    last, pending = nil, false
    busy.cinematic, busy.movie, busy.loading = false, false, false
end
