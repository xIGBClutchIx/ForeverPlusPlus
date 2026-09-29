-- English text for the item modules. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

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
L.AUCTIONPRICES_SCAN_AGE_LINE = "Scanned"
L.AUCTIONPRICES_SECTION_SCANNING = "Scanning"
L.AUCTIONPRICES_CHAT_DESC = "Say in chat when a scan finishes after the auction house closed."
L.AUCTIONPRICES_SCANNING = "Scanning prices... %d items" -- count so far
L.AUCTIONPRICES_SCANNED = "Prices updated for %d items" -- count
L.AUCTIONPRICES_PAUSED = "Scan paused while you sell... %d items" -- count so far
L.AUCTIONPRICES_STOPPED = "Scan stopped by a search at %d items" -- count
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

-- ProfessionTooltips
L.PROFTOOLTIPS_TITLE = "Profession Tooltips"
L.PROFTOOLTIPS_DESC = "Show the skill a herb, ore, skinnable creature, or locked box or chest "
    .. "needs, colored by how hard it is for you, like recipes at a trainer."
L.PROFTOOLTIPS_SHOW = "Show Gathering"
L.PROFTOOLTIPS_SHOW_DESC = "Show the gathering skills only for professions you have, or always. "
    .. "Without the profession it shows in red. Lockpicking only shows for characters who can "
    .. "pick locks."
L.PROFTOOLTIPS_SHOW_KNOWN = "With the Profession"
L.PROFTOOLTIPS_SHOW_ALWAYS = "Always"
L.PROFTOOLTIPS_HERBALISM = "Herbs"
L.PROFTOOLTIPS_HERBALISM_DESC = "Show the Herbalism skill a herb needs when you point at it, in "
    .. "the world or on the minimap."
L.PROFTOOLTIPS_MINING = "Ore"
L.PROFTOOLTIPS_MINING_DESC = "Show the Mining skill a vein or deposit needs when you point at "
    .. "it, in the world or on the minimap."
L.PROFTOOLTIPS_SKINNING = "Creatures"
L.PROFTOOLTIPS_SKINNING_DESC = "Show the Skinning skill a beast needs, from its level."
L.PROFTOOLTIPS_LOCKPICKING = "Locks"
L.PROFTOOLTIPS_LOCKPICKING_DESC = "Show the Lockpicking skill a locked lockbox or chest needs, "
    .. "if you can pick locks."
L.PROFTOOLTIPS_BLACKSMITHING = "Skeleton Keys"
L.PROFTOOLTIPS_BLACKSMITHING_DESC = "Blacksmiths can open locks with the skeleton keys they make. "
    .. "Show the lock skill to blacksmiths too, colored against their best key, and the skill "
    .. "each skeleton key opens in its own tooltip."
L.PROFTOOLTIPS_KEY = "Opens locks up to %s (%d)" -- profession, skill
L.PROFTOOLTIPS_ITEMS = "Items"
L.PROFTOOLTIPS_ITEMS_DESC = "Show in herb, ore, stone, and lockbox tooltips the skill needed to "
    .. "gather or open them."
L.PROFTOOLTIPS_REQUIRES = "Requires %s (%d)" -- profession, skill
L.PROFTOOLTIPS_GATHERED = "Gathered with %s (%d)" -- profession, skill
L.PROFTOOLTIPS_HERBALISM_NAME = "Herbalism" -- until the client gives its own name
L.PROFTOOLTIPS_MINING_NAME = "Mining"
L.PROFTOOLTIPS_SKINNING_NAME = "Skinning"
L.PROFTOOLTIPS_LOCKPICKING_NAME = "Lockpicking"
-- Creature types that can be skinned, exactly as the game names them.
L.PROFTOOLTIPS_BEAST = "Beast"
L.PROFTOOLTIPS_DRAGONKIN = "Dragonkin"

