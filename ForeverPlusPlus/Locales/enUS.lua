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
L.SLASH_MODULES = "modules (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "open the settings"
L.SLASH_LIST = "list the modules and whether each is on"
L.SLASH_TOGGLE = "turn a module on or off"
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
L.CHAT_MESSAGES = "Chat Messages" -- a module's checkbox for what it says in chat by itself

-- Settings
-- The main Settings page's groups of modules.
L.CATEGORY_AUTOMATION = "Automation"
L.CATEGORY_ITEMS = "Items"
L.CATEGORY_INTERFACE = "Interface"
L.CATEGORY_NAMEPLATES = "Nameplates"
L.CATEGORY_OTHER = "Other"
L.DEBUG = "Debug"
L.SETTINGS_AFTER_COMBAT = "Settings open after combat."
L.SETTINGS_MODULE_OFF = "Module is disabled: turn it on from the Forever++ page" -- atop its page
L.SETTINGS_OPEN_PAGE = "%s Options" -- the gear beside a module's checkbox: module title

-- Settings: About page
L.ABOUT = "About"
L.ABOUT_TAGLINE = "Small additions and changes to the default UI for WoW Forever."
L.ABOUT_VERSION = "Version"
L.ABOUT_AUTHOR = "Author"
L.ABOUT_GAME = "Game"
L.ABOUT_GAME_BUILD = "%s (build %s, interface %s)" -- version, build, interface
L.ABOUT_WEBSITE = "Website"
L.ABOUT_ISSUES = "Feedback"
L.ABOUT_COPY = "Select the link and press Ctrl+C to copy it."
L.ABOUT_REQUESTS = "Want something changed or a new feature? Ask for it at the link above."
L.ABOUT_COMMANDS = "Commands"

-- Friendly nameplates (Lib/PlateLabel.lua and both plate modules)
L.PLATES_BLIZZARD_OFF = "Blizzard's nameplates are off" -- a gray row atop the page, with a button
L.PLATES_TURN_ON = "Turn On"
L.PLATES_BAR_WHEN_HURT = "Health Bar When Hurt"
L.PLATES_NAME_COLOR = "Name Color"
L.PLATES_LEVEL = "Level"
L.PLATES_LEVEL_DESC = "Where the level shows while the health bar is hidden."
L.PLATES_LEVEL_BEFORE = "Before Name"
L.PLATES_LEVEL_AFTER = "After Name"
L.PLATES_LEVEL_OFF = "Hidden"
-- When a <Guild> or <Title> line shows.
L.PLATES_SUBTITLE_ALWAYS = "Always"
L.PLATES_SUBTITLE_HIDDEN = "Without Health Bar"
L.PLATES_SUBTITLE_OFF = "Never"
L.PLATES_COLOR_WHITE = "White"
L.PLATES_COLOR_GRAY = "Gray"
L.PLATES_COLOR_GREEN = "Green"
L.PLATES_CENTER_LINE = "Show Plate Center"
L.PLATES_CENTER_LINE_DESC = "Draw a thin red line through the middle of each nameplate, to check "
    .. "the name sits centered over the unit."

-- PlayerPlates
L.PLAYERPLATES_TITLE = "Player Nameplates"
L.PLAYERPLATES_BLIZZARD_OFF_DESC = "Blizzard's friendly player nameplates are off, so there's "
    .. "nothing to show. Turn them on here, in Blizzard's Nameplates options, or with their keybind "
    .. "(Shift-V)."
L.PLAYERPLATES_DESC = "Always show friendly players' names, with their guild. Their health bar "
    .. "appears only when they're hurt or in combat."
L.PLAYERPLATES_BAR_WHEN_HURT_DESC = "Show a player's health bar while they're missing health. "
    .. "When off, it only shows in combat."
L.PLAYERPLATES_NAME_COLOR_DESC = "The color of a player's name while the health bar is hidden."
L.PLAYERPLATES_NAME_COLOR_CLASS = "Class"
L.PLAYERPLATES_GUILD_NAMES = "Guild Names"
L.PLAYERPLATES_GUILD_NAMES_DESC = "When to show a player's <Guild> under their name."
L.PLAYERPLATES_GUILD_COLOR = "Guild Name Color"
L.PLAYERPLATES_GUILD_COLOR_DESC = "The color of a player's <Guild> line."
L.PLAYERPLATES_GUILD_HIGHLIGHT = "Highlight Guildmates"
L.PLAYERPLATES_GUILD_HIGHLIGHT_DESC = "Show the <Guild> line of players in your own guild in "
    .. "guild chat green. With Guild Name Color on Green, your guild shows in white instead."
L.PLAYERPLATES_SOCIAL_ICONS = "Group and Friend Icons"
L.PLAYERPLATES_SOCIAL_ICONS_DESC = "Show an icon beside the names of your group members, and "
    .. "the Battle.net logo beside your friends, while the health bar is hidden."
L.PLAYERPLATES_GROUP_ICON = "Group Icon"
L.PLAYERPLATES_GROUP_ICON_DESC = "Which icon group members get. With roles, members who have "
    .. "none get the Looking for Group icon."
L.PLAYERPLATES_GROUP_ICON_ROLE = "Their Role (Tank, Healer, Damage)"
L.PLAYERPLATES_GROUP_ICON_LOOKING = "Looking for Group"
L.PLAYERPLATES_TEST_ICONS = "Test Group and Friend Icons"
L.PLAYERPLATES_TEST_ICONS_DESC = "Show an icon on every friendly player, as if they were all "
    .. "in your group or all your friends, to check how the icons look."
L.PLAYERPLATES_TEST_ICONS_OFF = "Off"
L.PLAYERPLATES_TEST_ICONS_GROUP = "Everyone in Group"
L.PLAYERPLATES_TEST_ICONS_FRIEND = "Everyone a Friend"

-- NpcPlates
L.NPCPLATES_TITLE = "NPC Nameplates"
L.NPCPLATES_BLIZZARD_OFF_DESC = "Blizzard's friendly NPC nameplates are off, so there's nothing "
    .. "to show. Turn them on here or in Blizzard's Nameplates options."
L.NPCPLATES_DESC = "Always show friendly NPCs' names, with their title. Their health bar appears "
    .. "only when they're hurt or in combat."
L.NPCPLATES_BAR_WHEN_HURT_DESC = "Show an NPC's health bar while it's missing health. When off, "
    .. "it only shows in combat."
L.NPCPLATES_NAME_COLOR_DESC = "The color of an NPC's name while the health bar is hidden. Green "
    .. "matches friendly NPC names in the world."
L.NPCPLATES_TITLES = "Titles"
L.NPCPLATES_TITLES_DESC = "When to show an NPC's title, like <Innkeeper>, under its name."
L.NPCPLATES_TITLE_COLOR = "Title Color"
L.NPCPLATES_TITLE_COLOR_DESC = "The color of an NPC's <Title> line."
L.NPCPLATES_TITLE_COLOR_NAME = "Same as Name"

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
L.AUTOREPAIR_MIN_COST = "Minimum Cost"
L.AUTOREPAIR_MIN_COST_DESC = "Only repair when it costs at least this much, so a quick stop at a "
    .. "merchant doesn't spend a few copper each time."
L.AUTOREPAIR_MIN_COST_ANY = "Any Cost"
L.AUTOREPAIR_CHAT_DESC = "Say in chat what repairs cost, or why they couldn't be paid for."
L.AUTOREPAIR_REPAIRED = "Repaired for %s." -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "Repaired for %s from the guild bank." -- cost
L.AUTOREPAIR_NO_MONEY = "Not enough money to repair (%s)." -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "The guild bank can't pay for repairs (%s)." -- cost

-- AuctionPrices
L.AUCTIONPRICES_TITLE = "Auction Prices"
L.AUCTIONPRICES_DESC = "Scan the auction house when you open it, and show the lowest buyout in "
    .. "item tooltips, under the sell price."
L.AUCTIONPRICES_SCAN_ON_OPEN = "Scan When Opened"
L.AUCTIONPRICES_SCAN_ON_OPEN_DESC = "Scan the whole auction house when you open it, at most "
    .. "every 15 minutes. When off, prices still update from your own searches, and /fpp scan "
    .. "scans now."
L.AUCTIONPRICES_SECTION_TOOLTIP = "Tooltip"
L.AUCTIONPRICES_SCAN_AGE = "Scan Age"
L.AUCTIONPRICES_SCAN_AGE_DESC = "A line under the auction price with how long ago the auction "
    .. "house was last scanned, and where its text goes."
L.AUCTIONPRICES_SCAN_AGE_OFF = "Hidden"
L.AUCTIONPRICES_SCAN_AGE_COLOR = "Scan Age Color"
L.AUCTIONPRICES_SCAN_AGE_COLOR_DESC = "The color of the scan age. By Age goes from green when "
    .. "just scanned, through yellow, to red at the Red After age."
L.AUCTIONPRICES_SCAN_AGE_COLOR_AGE = "By Age"
L.AUCTIONPRICES_SCAN_AGE_RED = "Red After"
L.AUCTIONPRICES_SCAN_AGE_RED_DESC = "With Scan Age Color on By Age, how old a scan is when its age "
    .. "turns fully red. It's yellow at half that."
L.AUCTIONPRICES_ONE_HOUR = "1 Hour"
L.AUCTIONPRICES_HOURS = "%d Hours" -- hours, more than one
L.AUCTIONPRICES_SCAN_AGE_LINE = "Scanned"
L.AUCTIONPRICES_AGO_NOW = "just now"
L.AUCTIONPRICES_AGO_MINUTES = "%dm ago" -- minutes
L.AUCTIONPRICES_AGO_HOURS = "%dh ago" -- hours
L.AUCTIONPRICES_AGO_DAYS = "%dd ago" -- days
L.AUCTIONPRICES_SECTION_SCANNING = "Scanning"
L.AUCTIONPRICES_CHAT_DESC = "Say in chat when a scan finishes after the auction house closed."
L.AUCTIONPRICES_SCANNING = "Scanning prices... %d items" -- count so far
L.AUCTIONPRICES_SCANNED = "Prices updated for %d items" -- count
L.AUCTIONPRICES_AGE = "Prices scanned %d min ago" -- minutes
L.AUCTIONPRICES_COMMAND = "scan the open auction house now"
L.AUCTIONPRICES_IS_OFF = "Auction Prices is off (/fpp toggle AuctionPrices)."
L.AUCTIONPRICES_NOT_OPEN = "Open the auction house first."
L.AUCTIONPRICES_LINE = "Auction"
L.AUCTIONPRICES_RESET = "Saved Prices"
L.AUCTIONPRICES_RESET_BUTTON = "Reset"
L.AUCTIONPRICES_RESET_DESC = "Forget every auction price saved for this realm and faction. The "
    .. "next visit to the auction house scans again."
L.AUCTIONPRICES_RESET_CONFIRM = "Forget all saved auction prices for this realm and faction?"
L.AUCTIONPRICES_RESET_DONE = "Auction prices reset."
L.AUCTIONPRICES_RESET_COMMAND = "forget the saved auction prices"

-- SellPrice
L.SELLPRICE_TITLE = "Sell Price"
L.SELLPRICE_DESC = "Show the vendor price of the whole stack in item tooltips. Hold Shift to see "
    .. "one item."

-- Price lines in item tooltips (SellPrice and AuctionPrices each have these options)
L.PRICE_MODE = "Price For"
L.PRICE_MODE_DESC = "Whether this price counts the whole stack or one item, and what holding "
    .. "Shift shows."
L.PRICE_MODE_STACK = "Whole Stack, Shift for One"
L.PRICE_MODE_ONE = "One Item, Shift for Stack"
L.PRICE_ALIGN = "Price Alignment"
L.PRICE_ALIGN_DESC = "Where this line's coins go. Price lines set to the same alignment line up "
    .. "with each other."
L.PRICE_ALIGN_RIGHT = "Right Edge"
L.PRICE_ALIGN_INLINE = "After the Label"
L.PRICE_COLOR = "Quantity Color"
L.PRICE_COLOR_DESC = "The color of the x20 quantity on this line."
L.PRICE_COLOR_GRAY = "Gray"
L.PRICE_COLOR_WHITE = "White"
L.PRICE_COLOR_GOLD = "Gold"
L.PRICE_LINE = "%s %s:" -- line name, quantity
L.PRICE_QUANTITY = "x%d" -- how many items the price is for
L.PRICE_INLINE = "%s  %s" -- padded label, coins
L.PRICE_INFO_LINE = "%s:" -- line name, on a price-style line with text instead of coins

-- DurabilityBars
L.DURABILITYBARS_TITLE = "Durability Bars"
L.DURABILITYBARS_DESC = "Show a small bar beside each item on the character window with how "
    .. "worn it is, from green to red."
L.DURABILITYBARS_SHOW = "Show Bars"
L.DURABILITYBARS_SHOW_DESC = "Which items get a bar. Items without durability never do."
L.DURABILITYBARS_SHOW_ALWAYS = "Always"
L.DURABILITYBARS_SHOW_WORN = "Only When Worn"
L.DURABILITYBARS_SHOW_HALF = "Below 50%"
L.DURABILITYBARS_SHOW_QUARTER = "Below 25%"

-- Tooltips
L.TOOLTIPS_TITLE = "Tooltips"
L.TOOLTIPS_DESC = "Color unit and item tooltips: borders and names by class, reaction, or "
    .. "quality, with colored guild, level, and class, player titles, and who a unit is targeting."
L.TOOLTIPS_COLOR_CLASS = "Class (Reaction for NPCs)"
L.TOOLTIPS_COLOR_REACTION = "Reaction"
L.TOOLTIPS_COLOR_OFF = "Blizzard Default"
L.TOOLTIPS_SECTION_BORDERS = "Borders"
L.TOOLTIPS_SECTION_TEXT = "Text Colors"
L.TOOLTIPS_SECTION_LINES = "Extra Lines"
L.TOOLTIPS_BORDER = "Unit Border Color"
L.TOOLTIPS_BORDER_DESC = "Color the border of player and NPC tooltips by class, or by whether "
    .. "they're hostile, neutral, or friendly."
L.TOOLTIPS_ITEM_BORDER = "Item Quality Border"
L.TOOLTIPS_ITEM_BORDER_DESC = "Color the border of item tooltips by the item's quality."
L.TOOLTIPS_NAME_COLOR = "Name Color"
L.TOOLTIPS_NAME_COLOR_DESC = "Color the name in player and NPC tooltips by class, or by whether "
    .. "they're hostile, neutral, or friendly. Item names already show their quality."
L.TOOLTIPS_GUILD_COLOR = "Guild Name Color"
L.TOOLTIPS_GUILD_COLOR_DESC = "Color a player's <Guild> line: your own guild in guild chat "
    .. "green, and optionally other guilds gray."
L.TOOLTIPS_GUILD_COLOR_MINE = "Your Guild Green"
L.TOOLTIPS_GUILD_COLOR_ALL = "Your Guild Green, Others Gray"
L.TOOLTIPS_LEVEL_COLOR = "Level Color"
L.TOOLTIPS_LEVEL_COLOR_DESC = "Color the level by how hard the unit is for you, as quest levels "
    .. "are colored."
L.TOOLTIPS_CLASS_COLOR = "Class Name Color"
L.TOOLTIPS_CLASS_COLOR_DESC = "Color a player's class name in its class color."
L.TOOLTIPS_PLAYER_TITLE = "Player Titles"
L.TOOLTIPS_PLAYER_TITLE_DESC = "Show a player's title with their name."
L.TOOLTIPS_TARGET = "Target"
L.TOOLTIPS_TARGET_DESC = "Add a line with who the unit is targeting, colored by class or "
    .. "reaction, or \"You\" in red when it's you."
L.TOOLTIPS_TARGET_LINE = "Target:"
L.TOOLTIPS_TARGET_YOU = "You"
L.TOOLTIPS_SECTION_BEHAVIOR = "Behavior"
L.TOOLTIPS_ANCHOR_CURSOR = "Anchor to Cursor"
L.TOOLTIPS_ANCHOR_CURSOR_DESC = "Show tooltips at your mouse instead of their usual spot in the "
    .. "corner."
L.TOOLTIPS_HIDE_IN_COMBAT = "Hide Unit Tooltips in Combat"
L.TOOLTIPS_HIDE_IN_COMBAT_DESC = "Don't show player and NPC tooltips while you're in combat. Item "
    .. "and spell tooltips still show."

-- HideFeedback
L.HIDEFEEDBACK_TITLE = "Hide Beta Feedback"
L.HIDEFEEDBACK_DESC = "Hide the beta's \"Press F6 to submit an issue\" line on tooltips and its "
    .. "bug report button. F6 still reports an issue."
L.HIDEFEEDBACK_TOOLTIP = "Hide Tooltip Reminder"
L.HIDEFEEDBACK_TOOLTIP_DESC = "Hide the \"Press F6 to submit an issue\" line on tooltips."
L.HIDEFEEDBACK_BUTTON = "Hide Bug Report Button"
L.HIDEFEEDBACK_BUTTON_DESC = "Hide the floating bug report button."

-- GatherTracking
L.GATHERTRACKING_TITLE = "Gathering Tracking"
L.GATHERTRACKING_DESC = "Keep Find Minerals or Find Herbs on: turn it back on after logging in, "
    .. "zoning, or dying, and swap between the two if you like."
L.GATHERTRACKING_TRACK = "Track"
L.GATHERTRACKING_TRACK_DESC = "Which tracking to keep on. Only one tracks at a time, so with "
    .. "both, swapping shows each in turn."
L.GATHERTRACKING_TRACK_BOTH = "Minerals and Herbs"
L.GATHERTRACKING_TRACK_MINERALS = "Minerals Only"
L.GATHERTRACKING_TRACK_HERBS = "Herbs Only"
L.GATHERTRACKING_REAPPLY = "Turn Back On"
L.GATHERTRACKING_REAPPLY_DESC = "After logging in, zoning, or coming back to life, turn tracking "
    .. "back on if nothing is being tracked. Turning it off yourself lasts until then."
L.GATHERTRACKING_SWAP = "Swap"
L.GATHERTRACKING_SWAP_DESC = "With both chosen, swap between Find Minerals and Find Herbs while "
    .. "one of them is on. Waits during combat, casting, and flights."
L.GATHERTRACKING_SWAP_OFF = "Never"
L.GATHERTRACKING_SWAP_EVERY = "Every %d Seconds" -- seconds
L.GATHERTRACKING_CHAT_DESC = "Say in chat when the game stops Gathering Tracking from changing "
    .. "tracking."
L.GATHERTRACKING_FAILED = "Gathering Tracking couldn't change tracking: %s" -- error
L.GATHERTRACKING_BLOCKED = "The game blocked Gathering Tracking from changing tracking. It stops "
    .. "until /reload."

-- AutoStow
L.AUTOSTOW_TITLE = "Auto Stow"
L.AUTOSTOW_DESC = "Put your weapons away a few seconds after combat ends, unless you draw or "
    .. "stow them yourself first."
L.AUTOSTOW_DELAY = "Delay"
L.AUTOSTOW_DELAY_DESC = "How long after combat to wait before putting your weapons away."
L.AUTOSTOW_SECONDS = "%d Seconds" -- number of seconds
L.AUTOSTOW_OUTSIDE_ONLY = "Only Out of Instances"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "Leave your weapons out in dungeons, raids and battlegrounds, where "
    .. "the next pull is never far off."

-- AutoGossip
L.AUTOGOSSIP_TITLE = "Auto Gossip"
L.AUTOGOSSIP_DESC = "When an NPC has only one thing to say and no quests, pick it for you, so "
    .. "the bank, shop, or flight map opens straight away."
L.AUTOGOSSIP_SECTION_GENERAL = "General"
L.AUTOGOSSIP_SECTION_NPCS = "Pick For"
L.AUTOGOSSIP_BANKER = "Bankers"
L.AUTOGOSSIP_BANKER_DESC = "Open the bank."
L.AUTOGOSSIP_VENDOR = "Vendors and Repairs"
L.AUTOGOSSIP_VENDOR_DESC = "Open the shop."
L.AUTOGOSSIP_TRAINER = "Trainers"
L.AUTOGOSSIP_TRAINER_DESC = "Open the trainer's list."
L.AUTOGOSSIP_TAXI = "Flight Masters"
L.AUTOGOSSIP_TAXI_DESC = "Open the flight map."
L.AUTOGOSSIP_STABLE = "Stable Masters"
L.AUTOGOSSIP_STABLE_DESC = "Open the stable."
L.AUTOGOSSIP_OTHER = "Other NPCs"
L.AUTOGOSSIP_OTHER_DESC = "Pick the only option of any other NPC, unless the game asks you to "
    .. "read its text first."
L.AUTOGOSSIP_SHIFT = "Hold Shift to Skip"
L.AUTOGOSSIP_SHIFT_DESC = "Holding Shift while you talk to an NPC leaves its options for you to "
    .. "pick."
L.AUTOGOSSIP_PRINT = "Print Gossip Options"
L.AUTOGOSSIP_PRINT_DESC = "Print every gossip option in chat with its icon and status, to check "
    .. "which kind of NPC it counts as."
L.AUTOGOSSIP_PRINT_HEADER = "Gossip options (title: %s):" -- NPC's title under the name
L.AUTOGOSSIP_PRINT_LINE = "  %s  icon=%s status=%s flags=%s  %s" -- id, icon, status, flags, name
L.AUTOGOSSIP_PRINT_RESULT = "  -> %s" -- the kind picked, or why not (debug codes)
-- The title under a stable master's name, exactly as the game shows it.
L.AUTOGOSSIP_TITLE_STABLE = "Stable Master"

-- CVarBrowser
L.CVARBROWSER_TITLE = "Console Variables"
L.CVARBROWSER_DESC = "Browse the game's console variables (CVars) on a page in Settings, and "
    .. "change them."
L.CVARBROWSER_COMMAND = "open Console Variables, searching for [search]"
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
