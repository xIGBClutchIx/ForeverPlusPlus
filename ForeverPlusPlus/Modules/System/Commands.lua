-- Commands: short slash commands players expect from other games' addons, each its own checkbox.
-- /rl reloads the UI; /clear empties a chat window; /kb opens Quick Keybind Mode; /pull starts
-- the game's own pull countdown. A command another addon already has is left to that addon
-- (Lib/Slash), so a boss mod's /pull stays the boss mod's. /fpp is the addon's own (Commands.lua
-- at the top) and is always there, whatever this module does. /way is the Waypoints module's.
local _, ns = ...

local ipairs, tonumber, floor = ipairs, tonumber, math.floor

local L = ns.L

local module = ns.NewModule("Commands", L.COMMANDS_DESC, {
    enabled = true,
    reload = true,
    clear = true,
    keybind = true,
    pull = true,
})
module.title = L.COMMANDS_TITLE
module.category = "system"
module.added = "0.8.0"

-- Probes: Blizzard_QuickKeybind loads with the action bars, and the countdown is Mainline's.
local function hasKeybind()
    return QuickKeybindFrame ~= nil
end

local function hasCountdown()
    return C_PartyInfo ~= nil and C_PartyInfo.DoCountdown ~= nil
end

module.options = {
    { key = "reload", name = L.COMMANDS_RELOAD, description = L.COMMANDS_RELOAD_DESC },
    { key = "clear", name = L.COMMANDS_CLEAR, description = L.COMMANDS_CLEAR_DESC },
    { key = "keybind", name = L.COMMANDS_KEYBIND, description = L.COMMANDS_KEYBIND_DESC, added = "1.10.0",
        available = hasKeybind, needs = L.SETTINGS_NEEDS_CLIENT },
    { key = "pull", name = L.COMMANDS_PULL, description = L.COMMANDS_PULL_DESC, added = "1.10.0",
        available = hasCountdown, needs = L.SETTINGS_NEEDS_CLIENT },
}

-- /rl -----------------------------------------------------------------------------------------

local function reload()
    if module.enabled and module.db.reload then
        ReloadUI()
    end
end

-- /clear --------------------------------------------------------------------------------------

-- Empties the chat window the command was typed in: the edit box's own window, else the one
-- selected, else the main one. Only its lines go; Chat History's saved lines stay.
local function clear(_, editBox)
    if not (module.enabled and module.db.clear) then
        return
    end
    local frame = editBox and editBox.chatFrame or SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
    if frame and frame.Clear then
        frame:Clear()
    end
end

-- /kb -----------------------------------------------------------------------------------------

-- Opens Quick Keybind Mode, as the button in the game's Keybindings settings does. The frame is
-- protected, so it can't be shown in combat. Blizzard's own buttons close Edit Mode first, but
-- calling Edit Mode's functions from here would taint it, so with Edit Mode open it only says so.
-- Closing it opens the game's Settings, as it does when opened from there (its OnHide).
local function keybind()
    if not (module.enabled and module.db.keybind and hasKeybind()) then
        return
    end
    local editMode = EditModeManagerFrame
    if InCombatLockdown() or (editMode and editMode.IsEditModeActive and editMode:IsEditModeActive()) then
        ns.Print(L.COMMANDS_KEYBIND_BLOCKED)
        return
    end
    QuickKeybindFrame:Show()
end

-- /pull ---------------------------------------------------------------------------------------

local PULL_SECONDS = 10 -- with no number, as boss mods' /pull

-- Starts the game's pull countdown, the one /countdown starts, for the seconds given; 0 stops one
-- that's running. The game says who may start one in a group and shows the timer to everyone.
local function pull(message)
    if not (module.enabled and module.db.pull and hasCountdown()) then
        return
    end
    local text = message and message:match("^%s*(.-)%s*$") or ""
    local seconds = text == "" and PULL_SECONDS or tonumber(text)
    local most = Constants and Constants.PartyCountdownConstants
        and Constants.PartyCountdownConstants.MaxCountdownSeconds or 3600
    if not seconds or seconds < 0 or seconds > most then
        ns.Print(L.COMMANDS_PULL_USAGE)
        return
    end
    C_PartyInfo.DoCountdown(floor(seconds))
end

-- The commands, each behind the option with its key.
local COMMANDS = {
    { option = "reload", key = "FOREVERPLUSPLUS_RELOAD", slash = "/rl", fn = reload,
        help = { description = L.COMMANDS_RELOAD_HELP, owner = "Commands" } },
    { option = "clear", key = "FOREVERPLUSPLUS_CLEAR", slash = "/clear", fn = clear,
        help = { description = L.COMMANDS_CLEAR_HELP, owner = "Commands" } },
    { option = "keybind", key = "FOREVERPLUSPLUS_KEYBIND", slash = "/kb", fn = keybind, available = hasKeybind,
        help = { description = L.COMMANDS_KEYBIND_HELP, owner = "Commands" } },
    { option = "pull", key = "FOREVERPLUSPLUS_PULL", slash = "/pull", fn = pull, available = hasCountdown,
        help = { usage = "[seconds]", description = L.COMMANDS_PULL_HELP, owner = "Commands" } },
}

local function sync()
    for _, command in ipairs(COMMANDS) do
        if module.enabled and module.db[command.option] and (not command.available or command.available()) then
            ns.Slash.Add(command.key, command.slash, command.fn, command.help)
        else
            ns.Slash.Remove(command.key, command.slash)
        end
    end
end

function module:OnEnable()
    sync()
end

function module:OnDisable()
    sync()
end

function module:OnOptionChanged()
    sync()
end
