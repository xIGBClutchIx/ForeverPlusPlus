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
L.CATEGORY_OTHER = "Other"
L.DEBUG = "Debug"
L.SETTINGS_AFTER_COMBAT = "Settings open after combat."
L.MODULES = "Modules" -- the page with every module's checkbox, and a button to it
-- The gear beside a module's checkbox: module title
L.SETTINGS_SHOW_OPTIONS = "Show %s Options"
L.SETTINGS_HIDE_OPTIONS = "Hide %s Options"
L.SETTINGS_OPEN_PAGE = "Open %s" -- for a module with a page of its own
L.SETTINGS_TURN_ON = "Turn On" -- the button on a "Blizzard's ... is off" row

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
L.HOME_GAME_BUILD = "Game %s (build %s, interface %s)" -- version, build, interface
L.HOME_LINKS = "Links"
L.HOME_WEBSITE = "Website"
L.HOME_ISSUES = "Feedback"
L.HOME_COPY = "Select the link and press Ctrl+C to copy it."
L.HOME_REQUESTS = "Want something changed or a new feature? Ask for it at the link above."
L.HOME_COMMANDS = "Commands"

-- Friendly nameplates (Lib/PlateLabel.lua and both plate modules)
L.PLATES_BLIZZARD_OFF = "Blizzard's nameplates are off" -- a gray row atop the page, with a button
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
L.PLAYERPLATES_RECENT_ALLIES = "Color Recent Allies"
L.PLAYERPLATES_RECENT_ALLIES_DESC = "Show the names of players on your Recent Allies list in "
    .. "the game's light blue, instead of the Name Color."
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
L.FASTLOOT_BLIZZARD_OFF = "Blizzard's auto loot is off" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "Blizzard's auto loot is off, so only loot you take while holding "
    .. "the auto loot key (Shift) is fast. Turn it on here or in Blizzard's Controls options."

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

-- BagSlots
L.BAGSLOTS_TITLE = "Bag Slot Counter"
L.BAGSLOTS_DESC = "Show how many bag slots are free on the bag buttons."
L.BAGSLOTS_SECTION_COUNT = "Free Slots"
L.BAGSLOTS_SECTION_TEXT = "Text"
L.BAGSLOTS_SHOW = "Show Free Slots"
L.BAGSLOTS_SHOW_DESC = "The total on the backpack button, or each bag's own count on its button."
L.BAGSLOTS_SHOW_BACKPACK = "All on Backpack"
L.BAGSLOTS_SHOW_EACH = "Per Bag"
L.BAGSLOTS_SPECIAL = "Count Special Bags"
L.BAGSLOTS_SPECIAL_DESC = "Also count bags that only hold some items, such as quivers, ammo "
    .. "pouches, soul bags, and herb bags."
L.BAGSLOTS_REAGENT = "Reagent Bag"
L.BAGSLOTS_REAGENT_DESC = "Where the reagent bag's free slots show: on its own button, added to "
    .. "the backpack's count, or not at all."
L.BAGSLOTS_REAGENT_OWN = "On Its Own Button"
L.BAGSLOTS_REAGENT_TOTAL = "Added to the Backpack"
L.BAGSLOTS_REAGENT_OFF = "Hidden"
L.BAGSLOTS_SIZE = "Text Size"
L.BAGSLOTS_SIZE_DESC = "How big the count is, in the game's own number fonts."
L.BAGSLOTS_SIZE_SMALL = "Small"
L.BAGSLOTS_SIZE_NORMAL = "Normal"
L.BAGSLOTS_SIZE_LARGE = "Large"
L.BAGSLOTS_SIZE_HUGE = "Huge"
L.BAGSLOTS_POSITION = "Text Position"
L.BAGSLOTS_POSITION_DESC = "Where on the bag button the count sits."
L.BAGSLOTS_POSITION_BOTTOMRIGHT = "Bottom Right"
L.BAGSLOTS_POSITION_BOTTOMLEFT = "Bottom Left"
L.BAGSLOTS_POSITION_TOPRIGHT = "Top Right"
L.BAGSLOTS_POSITION_TOPLEFT = "Top Left"
L.BAGSLOTS_POSITION_BOTTOM = "Bottom"
L.BAGSLOTS_POSITION_TOP = "Top"
L.BAGSLOTS_POSITION_CENTER = "Center"

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

-- GatherTooltips
L.GATHERTOOLTIPS_TITLE = "Gathering Tooltips"
L.GATHERTOOLTIPS_DESC = "Show the skill a herb, ore, or skinnable creature needs, colored by how "
    .. "hard it is for you, like recipes at a trainer."
L.GATHERTOOLTIPS_SHOW = "Show"
L.GATHERTOOLTIPS_SHOW_DESC = "Show the skill only for professions you have, or always. Without "
    .. "the profession it shows in red."
L.GATHERTOOLTIPS_SHOW_KNOWN = "With the Profession"
L.GATHERTOOLTIPS_SHOW_ALWAYS = "Always"
L.GATHERTOOLTIPS_HERBALISM = "Herbs"
L.GATHERTOOLTIPS_HERBALISM_DESC = "Show the Herbalism skill a herb needs when you point at it, in "
    .. "the world or on the minimap."
L.GATHERTOOLTIPS_MINING = "Ore"
L.GATHERTOOLTIPS_MINING_DESC = "Show the Mining skill a vein or deposit needs when you point at "
    .. "it, in the world or on the minimap."
L.GATHERTOOLTIPS_SKINNING = "Creatures"
L.GATHERTOOLTIPS_SKINNING_DESC = "Show the Skinning skill a beast needs, from its level."
L.GATHERTOOLTIPS_ITEMS = "Items"
L.GATHERTOOLTIPS_ITEMS_DESC = "Show in herb, ore, and stone tooltips the skill needed to gather "
    .. "them."
L.GATHERTOOLTIPS_REQUIRES = "Requires %s (%d)" -- profession, skill
L.GATHERTOOLTIPS_GATHERED = "Gathered with %s (%d)" -- profession, skill
L.GATHERTOOLTIPS_NAMED = "%s: %s" -- node name, "Requires Herbalism (70)"
L.GATHERTOOLTIPS_HERBALISM_NAME = "Herbalism" -- until the client gives its own name
L.GATHERTOOLTIPS_MINING_NAME = "Mining"
L.GATHERTOOLTIPS_SKINNING_NAME = "Skinning"
-- Creature types that can be skinned, exactly as the game names them.
L.GATHERTOOLTIPS_BEAST = "Beast"
L.GATHERTOOLTIPS_DRAGONKIN = "Dragonkin"

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

-- AutoDismount
L.AUTODISMOUNT_TITLE = "Auto Dismount"
L.AUTODISMOUNT_DESC = "Get off your mount or stand up when something fails because you're "
    .. "mounted or sitting, like casting a spell, taking a flight, or looting."
L.AUTODISMOUNT_DISMOUNT = "Dismount"
L.AUTODISMOUNT_DISMOUNT_DESC = "Get off your mount when you cast a spell, talk to a flight master, "
    .. "or attack while mounted."
L.AUTODISMOUNT_STAND = "Stand Up"
L.AUTODISMOUNT_STAND_DESC = "Stand up when you cast a spell, loot, or attack while sitting."
L.AUTODISMOUNT_UNSHIFT = "Leave Shapeshift Form"
L.AUTODISMOUNT_UNSHIFT_DESC = "Leave a shapeshift form, like a druid's Bear or Cat Form, when you "
    .. "cast a spell that can't be cast in it."

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

-- AutoDecline
L.AUTODECLINE_TITLE = "Auto Decline"
L.AUTODECLINE_DESC = "Turn down duel requests as they arrive, so the popup never gets in your way."
L.AUTODECLINE_ALLOW_FRIENDS = "Allow Friends and Guild"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "Let duels from your friends, Battle.net friends, and guildmates "
    .. "through."
L.AUTODECLINE_CHAT_DESC = "Say in chat whose duel was turned down."
L.AUTODECLINE_DECLINED = "Declined a duel from %s." -- player nameL.AUTODECLINE_SOMEONE = "someone"

-- AutoRelease
L.AUTORELEASE_TITLE = "Auto Release"
L.AUTORELEASE_DESC = "Release your spirit when you die in a battleground, unless you can "
    .. "resurrect yourself or someone is resurrecting you."
L.AUTORELEASE_DELAY = "Delay"
L.AUTORELEASE_DELAY_DESC = "How long after dying to wait before releasing."
L.AUTORELEASE_NOW = "Right Away"
L.AUTORELEASE_SECONDS = "%d Seconds" -- number of seconds
L.AUTORELEASE_CHAT_DESC = "Say in chat when your spirit was released, or why it wasn't."
L.AUTORELEASE_RELEASED = "Released your spirit."
L.AUTORELEASE_SELF_RES = "Didn't release: you can resurrect yourself."
L.AUTORELEASE_RES_OFFER = "Didn't release: someone is resurrecting you."

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "Skip Cinematics"
L.SKIPCINEMATICS_DESC = "Skip the game's cinematics and movies, every one or only ones you've "
    .. "already seen."
L.SKIPCINEMATICS_SKIP = "Skip"
L.SKIPCINEMATICS_SKIP_DESC = "Which cinematics and movies to skip. Seen ones count across all your "
    .. "characters."
L.SKIPCINEMATICS_SKIP_SEEN = "Only Seen"
L.SKIPCINEMATICS_SKIP_ALL = "All"
L.SKIPCINEMATICS_SHIFT = "Hold Shift to Watch"
L.SKIPCINEMATICS_SHIFT_DESC = "Holding Shift as a cinematic or movie starts lets it play."
L.SKIPCINEMATICS_CHAT_DESC = "Say in chat when a cinematic or movie is skipped."
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "Skipped a cinematic."
L.SKIPCINEMATICS_SKIPPED_MOVIE = "Skipped a movie."
L.SKIPCINEMATICS_RESET = "Seen Cinematics"
L.SKIPCINEMATICS_RESET_BUTTON = "Forget"
L.SKIPCINEMATICS_RESET_DESC = "Forget which cinematics and movies you've seen, so each plays once "
    .. "more."
L.SKIPCINEMATICS_RESET_DONE = "Seen cinematics forgotten."
L.SKIPCINEMATICS_PRINT = "Print Cinematic Keys"
L.SKIPCINEMATICS_PRINT_DESC = "Print each cinematic's or movie's key in chat as it starts, with "
    .. "whether it was seen and skipped."
L.SKIPCINEMATICS_PRINT_LINE = "Cinematic %s: seen=%s skip=%s" -- key (movie ID or map:subzone), seen, skip

-- AutoScreenshot
L.AUTOSCREENSHOT_TITLE = "Auto Screenshot"
L.AUTOSCREENSHOT_DESC = "Take a screenshot when you level up, earn an achievement, or defeat a "
    .. "boss, and at other moments worth keeping."
L.AUTOSCREENSHOT_SECTION_GENERAL = "General"
L.AUTOSCREENSHOT_SECTION_EVENTS = "Take a Screenshot When"
L.AUTOSCREENSHOT_HIDE_UI = "Hide Interface"
L.AUTOSCREENSHOT_HIDE_UI_DESC = "Hide the interface for the screenshot, the way Alt-Z does. Not in "
    .. "combat, where the game doesn't allow it."
L.AUTOSCREENSHOT_CHAT_DESC = "Say in chat why a screenshot was taken."
L.AUTOSCREENSHOT_TAKEN = "Screenshot taken: %s." -- the checkbox's name, such as Level Up
L.AUTOSCREENSHOT_LEVEL_UP = "Level Up"
L.AUTOSCREENSHOT_LEVEL_UP_DESC = "When you reach a new level."
L.AUTOSCREENSHOT_ACHIEVEMENT = "Achievement"
L.AUTOSCREENSHOT_ACHIEVEMENT_DESC = "When you earn an achievement you didn't already have on another "
    .. "character."
L.AUTOSCREENSHOT_LOOT = "Loot"
L.AUTOSCREENSHOT_LOOT_DESC = "When you receive an item of the quality below or better."
L.AUTOSCREENSHOT_LOOT_QUALITY = "Loot Quality"
L.AUTOSCREENSHOT_LOOT_QUALITY_DESC = "The lowest item quality that takes a screenshot."
L.AUTOSCREENSHOT_QUALITY_RARE = "Rare"
L.AUTOSCREENSHOT_QUALITY_EPIC = "Epic"
L.AUTOSCREENSHOT_QUALITY_LEGENDARY = "Legendary"
L.AUTOSCREENSHOT_BOSS_KILL = "Boss Kill"
L.AUTOSCREENSHOT_BOSS_KILL_DESC = "When your group defeats a dungeon or raid boss."
L.AUTOSCREENSHOT_REPUTATION = "Reputation"
L.AUTOSCREENSHOT_REPUTATION_DESC = "When you reach Friendly, Honored, Revered, or Exalted with a "
    .. "faction."
L.AUTOSCREENSHOT_PVP_RANK = "PvP Rank"
L.AUTOSCREENSHOT_PVP_RANK_DESC = "When you reach a new PvP rank."
L.AUTOSCREENSHOT_NEW_TITLE = "New Title"
L.AUTOSCREENSHOT_NEW_TITLE_DESC = "When you earn a new title."
L.AUTOSCREENSHOT_BATTLEGROUND = "Battleground Ends"
L.AUTOSCREENSHOT_BATTLEGROUND_DESC = "When a battleground ends, with the scoreboard up."
L.AUTOSCREENSHOT_DEATH = "Death"
L.AUTOSCREENSHOT_DEATH_DESC = "When you die."

-- ClassColors
L.CLASSCOLORS_TITLE = "Class Colors"
L.CLASSCOLORS_DESC = "Show players' health bars and names in their class color on the player, "
    .. "target, focus, party, and target-of-target frames, and hostile and neutral NPCs' health "
    .. "bars in red and yellow."
L.CLASSCOLORS_SECTION_PARTS = "Color"
L.CLASSCOLORS_SECTION_FRAMES = "Frames"
L.CLASSCOLORS_BARS = "Health Bars"
L.CLASSCOLORS_BARS_DESC = "Color a player's health bar by their class."
L.CLASSCOLORS_NPC_BARS = "NPC Health Bars"
L.CLASSCOLORS_NPC_BARS_DESC = "Color an NPC's health bar red when it's hostile, yellow when it's "
    .. "neutral, and gray when someone else has tagged it. Friendly NPCs stay green."
L.CLASSCOLORS_NAMES = "Names"
L.CLASSCOLORS_NAMES_DESC = "Color a player's name by their class."
L.CLASSCOLORS_PLAYER = "Player"
L.CLASSCOLORS_PLAYER_DESC = "Your own frame."
L.CLASSCOLORS_TARGET = "Target"
L.CLASSCOLORS_TARGET_DESC = "Your target's frame."
L.CLASSCOLORS_FOCUS = "Focus"
L.CLASSCOLORS_FOCUS_DESC = "Your focus's frame."
L.CLASSCOLORS_PARTY = "Party"
L.CLASSCOLORS_PARTY_DESC = "Your party members' frames. Raid-style party frames have their own "
    .. "class color setting in Blizzard's options."
L.CLASSCOLORS_TOT = "Target of Target"
L.CLASSCOLORS_TOT_DESC = "The small frames for your target's target and your focus's target."

-- PointsOfInterest. Place names on the map come from the game, or from Data.lua.
L.POI_TITLE = "Points of Interest"
L.POI_DESC = "Show dungeons, raids, capital cities, flight masters, boats, zeppelins, and spirit "
    .. "healers on the world map."
L.POI_DUNGEONS = "Dungeons"
L.POI_DUNGEONS_DESC = "Dungeon entrances, with their level range colored against yours."
L.POI_RAIDS = "Raids"
L.POI_RAIDS_DESC = "Raid entrances."
L.POI_CAPITALS = "Capital Cities"
L.POI_CAPITALS_DESC = "Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, and the "
    .. "Undercity, on the zone around each."
L.POI_FLIGHT = "Flight Masters"
L.POI_FLIGHT_DESC = "Flight masters of your faction, and ones that fly for both."
L.POI_SHIPS = "Boats"
L.POI_SHIPS_DESC = "Boat docks, with where the boat goes."
L.POI_ZEPPELINS = "Zeppelins"
L.POI_ZEPPELINS_DESC = "Zeppelin towers, with where the zeppelin goes."
L.POI_SPIRIT = "Spirit Healers"
L.POI_SPIRIT_DESC = "Spirit healers, where you can come back to life after dying."
L.POI_SIZE = "Icon Size"
L.POI_SIZE_DESC = "How big the icons are, compared with their normal size."
L.POI_WORLD = "On Continent Maps"
L.POI_WORLD_DESC = "Also show them on the continent and world maps, not just zone maps."
L.POI_OTHER_FACTION = "Other Faction"
L.POI_OTHER_FACTION_DESC = "Also show the other faction's flight masters, boats, and zeppelins."
-- Tooltips
L.POI_DUNGEON = "Dungeon"
L.POI_RAID = "Raid"
L.POI_CAPITAL = "Capital City"
L.POI_LEVEL = "Level %d"
L.POI_LEVELS = "Level %d-%d" -- lowest, highest
L.POI_PART = "%s (%s)" -- an instance, which entrance
L.POI_MAIN_GATE = "Main Gate"
L.POI_SERVICE_GATE = "Service Gate"
L.POI_NORTH = "North"
L.POI_EAST = "East"
L.POI_WEST = "West"
L.POI_FLIGHT_MASTER = "Flight Master"
L.POI_FLIGHT_UNLEARNED = "Not learned yet"
L.POI_SHIP_TO = "Boat to %s" -- a place
L.POI_ZEPPELIN_TO = "Zeppelin to %s" -- a place
L.POI_SPIRIT_HEALER = "Spirit Healer"

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
