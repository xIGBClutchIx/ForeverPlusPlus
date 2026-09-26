-- English text, and the fallback for every other language: every key the addon uses is here.
-- Another language gets its own file (Locales/deDE.lua, ...) that starts the same way with its
-- own code, sets only the keys it translates, and goes in the TOC after this one.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- Core: /fpp and chat
L.ON = "on"
L.OFF = "off"
L.MODULE_STATE = "%s is %s." -- module name, on/off
L.NO_MODULE = "no module called %s"
L.OFF_AFTER_RELOAD = "%s turns fully off after /reload."
L.SLASH_MODULES = "modules (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "open the settings"
L.SLASH_RESET = "all settings back to defaults (reloads)"
L.SLASH_OPTIONS = "list its options and their values"
L.SLASH_SET = "change one (on/off, or a choice)"

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s is %s. Options (/fpp set %s <option> <value>):" -- module, on/off, module
L.OPTIONS_NONE = "none"
L.OPTIONS_DEBUG = ", debug"
L.SET_USAGE = "usage: /fpp set <module> <option> <value>"
L.MODULE_STATE_ALLOWED = "%s is %s (on, off)." -- module name, on/off
L.NO_OPTION = "%s has no option %s. /fpp options %s lists them." -- module, option, module
L.OPTION_STATE = "%s %s is %s." -- module, option, value
L.OPTION_STATE_ALLOWED = "%s %s is |cffffd100%s|r (%s)." -- module, option, value, allowed values

-- Settings
L.MODULES = "Modules"
L.DEBUG = "Debug"
L.SETTINGS_AFTER_COMBAT = "Settings open after combat."

-- FriendlyPlates
L.FRIENDLYPLATES_TITLE = "Friendly Player Nameplates"
L.FRIENDLYPLATES_DESC = "Always show friendly players' names. Their health bar appears only when "
    .. "they're hurt or in combat."
L.FRIENDLYPLATES_BAR_WHEN_HURT = "Health Bar When Hurt"
L.FRIENDLYPLATES_BAR_WHEN_HURT_DESC = "Show the health bar when a friendly player is missing "
    .. "health. When off, it only shows in combat."
L.FRIENDLYPLATES_NPCS = "Friendly NPCs"
L.FRIENDLYPLATES_NPCS_DESC = "Give friendly NPCs the same nameplates: name always, health bar "
    .. "when hurt or in combat."
L.FRIENDLYPLATES_CLASS_COLOR = "Class Colors"
L.FRIENDLYPLATES_CLASS_COLOR_DESC = "Color names by class while the health bar is hidden."
L.FRIENDLYPLATES_GUILD_NAMES = "Guild Names"
L.FRIENDLYPLATES_GUILD_NAMES_DESC = "Show the player's <Guild> under their name."
L.FRIENDLYPLATES_GUILD_NAMES_HIDDEN = "Without Health Bar"
L.FRIENDLYPLATES_GUILD_NAMES_ALWAYS = "Always"
L.FRIENDLYPLATES_GUILD_NAMES_OFF = "Never"
L.FRIENDLYPLATES_LEVEL = "Level"
L.FRIENDLYPLATES_LEVEL_DESC = "Where the level shows while the health bar is hidden."
L.FRIENDLYPLATES_LEVEL_BEFORE = "Before Name"
L.FRIENDLYPLATES_LEVEL_AFTER = "After Name"
L.FRIENDLYPLATES_LEVEL_OFF = "Hidden"
L.FRIENDLYPLATES_GUILD_HIGHLIGHT = "Highlight Guildmates"
L.FRIENDLYPLATES_GUILD_HIGHLIGHT_DESC = "Show the <Guild> line of players in your own guild in "
    .. "guild chat green."
L.FRIENDLYPLATES_SOCIAL_ICONS = "Group and Friend Icons"
L.FRIENDLYPLATES_SOCIAL_ICONS_DESC = "Show an icon beside the names of your group members, and "
    .. "the Battle.net logo beside your friends, while the health bar is hidden."
L.FRIENDLYPLATES_GROUP_ICON = "Group Icon"
L.FRIENDLYPLATES_GROUP_ICON_DESC = "Which icon group members get."
L.FRIENDLYPLATES_GROUP_ICON_ROLE = "Their Role (Tank, Healer, Damage)"
L.FRIENDLYPLATES_GROUP_ICON_LOOKING = "Looking for Group"
L.FRIENDLYPLATES_TEST_ICONS = "Test Group and Friend Icons"
L.FRIENDLYPLATES_TEST_ICONS_DESC = "Show an icon on every friendly player, as if they were all "
    .. "in your group or all your friends, to check how the icons look."
L.FRIENDLYPLATES_TEST_ICONS_OFF = "Off"
L.FRIENDLYPLATES_TEST_ICONS_GROUP = "Everyone in Group"
L.FRIENDLYPLATES_TEST_ICONS_FRIEND = "Everyone a Friend"

-- FastLoot
L.FASTLOOT_TITLE = "Fast Loot"
L.FASTLOOT_DESC = "With auto loot on, take everything at once instead of waiting for the loot "
    .. "window."

-- AutoRepair
L.AUTOREPAIR_TITLE = "Auto Repair"
L.AUTOREPAIR_DESC = "Repair all your gear when you talk to a merchant who repairs, and say in chat "
    .. "what it cost. Hold Shift to skip it."
L.AUTOREPAIR_FUNDS = "Pay With"
L.AUTOREPAIR_FUNDS_DESC = "Whose money pays for repairs."
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "Guild Bank, Then Your Own"
L.AUTOREPAIR_FUNDS_GUILD = "Guild Bank Only"
L.AUTOREPAIR_FUNDS_OWN = "Your Own Money Only"
L.AUTOREPAIR_REPAIRED = "Repaired for %s." -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "Repaired for %s from the guild bank." -- cost
L.AUTOREPAIR_NO_MONEY = "Not enough money to repair (%s)." -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "The guild bank can't pay for repairs (%s)." -- cost

-- AuctionPrices
L.AUCTIONPRICES_TITLE = "Auction Prices"
L.AUCTIONPRICES_DESC = "Scan the auction house when you open it, and show the lowest buyout in "
    .. "item tooltips. Hold Shift to see the price of the whole stack."
L.AUCTIONPRICES_SCAN_ON_OPEN = "Scan When Opened"
L.AUCTIONPRICES_SCAN_ON_OPEN_DESC = "Scan the whole auction house when you open it, at most "
    .. "every 15 minutes. When off, prices still update from your own searches."
L.AUCTIONPRICES_SCANNED = "Auction prices updated for %d items." -- count
L.AUCTIONPRICES_LINE = "Auction:"
L.AUCTIONPRICES_STACK_LINE = "Auction (%d):" -- stack size

-- CVarBrowser
L.CVARBROWSER_TITLE = "Console Variables"
L.CVARBROWSER_DESC = "Browse the game's console variables (CVars) on a page in Settings, and "
    .. "change them."
L.CVARBROWSER_COMMAND = "open Console Variables, searching for [search]"
L.CVARBROWSER_IS_OFF = "Console Variables is off (/fpp toggle CVarBrowser)."
L.CVARBROWSER_PAGE_OFF = "Console Variables is off. Turn it on on the Forever++ page."
L.CVARBROWSER_NO_PAGE = "This client's Settings can't open the Console Variables page."
L.CVARBROWSER_AFTER_COMBAT = "%s changes after combat." -- CVar name
L.CVARBROWSER_REFUSED = "%s can't be changed." -- CVar name
L.CVARBROWSER_COUNT = "%d of %d" -- shown, total
L.CVARBROWSER_CHANGED_ONLY = "Changed Only"
L.CVARBROWSER_NAME = "Name"
L.CVARBROWSER_VALUE = "Value"
L.CVARBROWSER_DEFAULT = "Default"
L.CVARBROWSER_VALUE_IS = "Value: %s"
L.CVARBROWSER_DEFAULT_IS = "Default: %s"
L.CVARBROWSER_ACCOUNT = "Saved for your account."
L.CVARBROWSER_CHARACTER = "Saved for this character."
L.CVARBROWSER_READ_ONLY = "Can't be changed."
L.CVARBROWSER_SECURE = "Protected: changes wait until combat ends."
