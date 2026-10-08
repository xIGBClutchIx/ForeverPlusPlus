-- English text, and the fallback for every other language: every key the addon uses is in a file
-- under Locales/enUS/. Another language gets a folder of its own (Locales/deDE/, ...) whose files
-- start the same way with its own code, set only the keys they translate, and go in the TOC after
-- these. Splitting by category, as the modules are, is a choice: one file per language works too.
-- This file has the core's own text: the Lib helpers, /fpp, and the Settings pages.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- Lib/Text.lua: lengths of time, for slider labels and price lines
L.TEXT_ONE_SECOND = "1 Second"
L.TEXT_SECONDS = "%d Seconds" -- number of seconds, more than one
L.TEXT_ONE_HOUR = "1 Hour"
L.TEXT_HOURS = "%d Hours" -- hours, more than one
L.TEXT_AGO_NOW = "just now"
L.TEXT_AGO_MINUTES = "%dm ago" -- minutes
L.TEXT_AGO_HOURS = "%dh ago" -- hours
L.TEXT_AGO_DAYS = "%dd ago" -- days

-- Core: /fpp and chat
L.ON = "on"
L.OFF = "off"
L.MODULE_STATE = "%s is %s." -- module name, on/off
L.NO_MODULE = "no module called %s"
L.SLASH_MODULES = "modules (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "open the settings"
L.SLASH_LIST = "list the modules and whether each is on"
L.SLASH_TOGGLE = "turn a module, or one of its checkboxes, on or off"
L.SLASH_RESET = "all settings back to defaults (reloads)"
L.SLASH_OPTIONS = "list its options and their values"
L.SLASH_SET = "change one (on/off, a choice, or a number)"

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s is %s. Options (/fpp set %s <option> <value>):" -- module, on/off, module
L.OPTIONS_NONE = "none"
L.OPTIONS_DEBUG = ", debug"
L.SET_USAGE = "usage: /fpp set <module> <option> <value>"
L.MODULE_STATE_ALLOWED = "%s is %s (on, off)." -- module name, on/off
L.NO_OPTION = "%s has no option %s. /fpp options %s lists them." -- module, option, module
L.OPTION_STATE = "%s %s is %s." -- module, option, value
L.OPTION_STATE_ALLOWED = "%s %s is |cffffd100%s|r (%s)." -- module, option, value, allowed values
L.CHAT_MESSAGES = "Chat Messages" -- a module's checkbox for what it says in chat by itself

-- Settings
-- The main Settings page's groups of modules.
L.CATEGORY_AUTOMATION = "Automation"
L.CATEGORY_ITEMS = "Items"
L.CATEGORY_INTERFACE = "Interface"
L.CATEGORY_MAP = "Map"
L.CATEGORY_UNITFRAMES = "Unit Frames"
L.CATEGORY_NAMEPLATES = "Nameplates"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_OTHER = "Other"
L.DEBUG = "Debug"
L.SETTINGS_AFTER_COMBAT = "Settings open after combat."
L.MODULES = "Modules" -- the page with every module's checkbox, and a button to it
-- The gear beside a module's checkbox: module title
L.SETTINGS_SHOW_OPTIONS = "Show %s Options"
L.SETTINGS_HIDE_OPTIONS = "Hide %s Options"
L.SETTINGS_OPEN_PAGE = "Open %s" -- for a module with a page of its own
L.SETTINGS_TURN_ON = "Turn On" -- the button on a "Blizzard's ... is off" row
L.SETTINGS_SEARCH = "Search modules" -- gray text in the Modules page's empty search box

-- Settings: Changelog page. The notes themselves are in Changelog.lua.
L.CHANGELOG = "Changelog"
L.CHANGELOG_RELEASE = "%s (%s)" -- version, date
L.CHANGELOG_UNRELEASED = "Unreleased"
L.CHANGELOG_ADDED = "Added"
L.CHANGELOG_CHANGED = "Changed"
L.CHANGELOG_FIXED = "Fixed"
L.CHANGELOG_SETTINGS = "Settings"
L.CHANGELOG_COMMANDS = "Commands"

-- Settings: the welcome page (the top Forever++ page)
L.HOME_WELCOME = "Welcome to %s" -- addon title
L.HOME_TAGLINE = "Small additions and changes to the default UI for WoW Forever."
L.HOME_VERSION = "Version %s by %s" -- version, author
L.HOME_INTRO = "Each module is one small change to Blizzard's interface, made to look like it "
    .. "shipped with the game. Turn them on and off on the Modules page; the gear beside a "
    .. "module shows its options. Settings are saved for your whole account."
L.HOME_MODULES_ON = "%d of %d modules on" -- on, total
L.HOME_DEFAULTS = "Defaults"
L.HOME_DEFAULTS_TIP = "Puts every module's settings back to how they start for a new player."
L.HOME_DEFAULTS_ASK = "Put all Forever++ settings back to their defaults?"
L.HOME_CLUTCH = "Clutch's Default"
L.HOME_CLUTCH_TIP = "The defaults, plus the extra modules the author turns on: %s. Zone Info "
    .. "also shows Dungeons and Fishing only while you hold its detail key." -- module titles
L.HOME_LIST_SEPARATOR = ", " -- between module titles in a list
-- The popup of the Defaults button at the top right of the Modules and Debug pages
L.DEFAULTS_ASK = "Put all Forever++ settings back to defaults? This replaces your current "
    .. "Forever++ settings. The rest of the game's settings stay as they are."
L.DEFAULTS_CLUTCH = "Clutch's Defaults"
L.DEFAULTS_RECOMMENDED = "Recommended Defaults"
L.HOME_CLUTCH_ASK = "Use Clutch's recommended settings? This replaces your current Forever++ settings."
L.HOME_GAME_BUILD = "Game %s (build %s, interface %s)" -- version, build, interface
L.HOME_LINKS = "Links"
L.HOME_WEBSITE = "Website"
L.HOME_ISSUES = "Feedback"
L.HOME_COPY = "Select the link and press Ctrl+C to copy it."
L.HOME_REQUESTS = "Want something changed or a new feature? Ask for it at the link above."
L.HOME_COMMANDS = "Commands"

-- Edit Mode dialog for our own frames (Lib/EditMode.lua)
L.EDITMODE_SCALE = "Scale"
L.EDITMODE_CLICK_TO_EDIT = "Click To Edit"
L.EDITMODE_RESET_POSITION = "Reset To Default Position"
