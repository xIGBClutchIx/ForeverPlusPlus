-- Item Tooltips: lines in item tooltips, each with its own checkbox: the vendor price of the whole
-- stack (SellPrice.lua), how many you own (ItemCount.lua), and the lowest auction house buyout,
-- with crafting costs in the professions window (AuctionPrices.lua). This file has the settings
-- and turns each part on and off; the parts share module.internal.
local _, ns = ...

local ipairs = ipairs

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local module = ns.NewModule("ItemTooltips", L.ITEMTOOLTIPS_DESC, {
    enabled = true,
    -- Every price line
    mode = "stack", -- "stack" (Shift for one) or "one" (Shift for the stack)
    align = "right", -- "right" (at the tooltip's edge) or "inline" (after the label), counts too
    -- Sell Price
    sellPrice = true,
    sellPriceColor = "white", -- the quantity's color: "gray", "white", or "gold"
    -- Item Count
    itemCount = false,
    bank = true,
    labels = "icons", -- "icons" (Blizzard's bag and bank icons) or "words"
    -- Auction Prices
    auction = true,
    auctionColor = "gold",
    scanAge = "right", -- "right", "inline" (like the price line's alignment), or "off"
    scanAgeColor = "age", -- "age" (green when fresh to red when old), "gray", "white", or "gold"
    scanAgeRedHours = 12, -- hours old at which "age" is fully red
    crafting = true, -- costs, value, and profit under a recipe's reagents
    scanOnOpen = true,
    chat = true,
    -- Data, not settings: they aren't in module.options.
    -- What merchants charge for one of an item: { [itemID] = copper }, learned at each visit.
    vendor = {},
    -- Per auction house ("Realm-Faction"): { scannedAt = time(), items = { [itemID] = { price =
    -- copper, seenAt = time() } } }. scannedAt is the last full scan and decides when to scan
    -- again; seenAt is when that item's price was last seen, which the tooltip's age shows, since
    -- an item missing from a scan keeps its older price.
    houses = {},
    -- Per character ("Realm-Name"): { [itemID] = count } in the bank when it was last open.
    banks = {},
})
module.title = L.ITEMTOOLTIPS_TITLE
module.category = "items"
module.internal = {}
local internal = module.internal

local COLORS = {
    { "gray", L.PRICE_COLOR_GRAY },
    { "white", L.PRICE_COLOR_WHITE },
    { "gold", L.PRICE_COLOR_GOLD },
}
local ALIGN = { { "right", L.PRICE_ALIGN_RIGHT }, { "inline", L.PRICE_ALIGN_INLINE } }

local GENERAL, SELL, COUNT, AUCTION = L.ITEMTOOLTIPS_SECTION_GENERAL, L.SELLPRICE_TITLE,
    L.ITEMCOUNT_TITLE, L.AUCTIONPRICES_TITLE

-- Price lines first, each part's checkbox heading its section with its options under it, and
-- Auction Prices last for its Chat Messages.
module.options = {
    {
        key = "mode", name = L.PRICE_MODE, description = L.PRICE_MODE_DESC, section = GENERAL,
        choices = { { "stack", L.PRICE_MODE_STACK }, { "one", L.PRICE_MODE_ONE } },
    },
    { key = "align", name = L.PRICE_ALIGN, description = L.PRICE_ALIGN_DESC, section = GENERAL, choices = ALIGN },

    { key = "sellPrice", name = L.ITEMTOOLTIPS_SELLPRICE, description = L.SELLPRICE_DESC, section = SELL },
    {
        key = "sellPriceColor", name = L.PRICE_COLOR, description = L.PRICE_COLOR_DESC, section = SELL,
        requires = "sellPrice", choices = COLORS,
    },

    { key = "itemCount", name = L.ITEMTOOLTIPS_ITEMCOUNT, description = L.ITEMCOUNT_DESC, section = COUNT },
    {
        key = "bank", name = L.ITEMCOUNT_BANK, description = L.ITEMCOUNT_BANK_DESC, section = COUNT,
        requires = "itemCount",
    },
    {
        key = "labels", name = L.ITEMCOUNT_LABELS, description = L.ITEMCOUNT_LABELS_DESC, section = COUNT,
        requires = "itemCount",
        choices = { { "icons", L.ITEMCOUNT_LABELS_ICONS }, { "words", L.ITEMCOUNT_LABELS_WORDS } },
    },

    { key = "auction", name = L.ITEMTOOLTIPS_AUCTION, description = L.AUCTIONPRICES_DESC, section = AUCTION },
    {
        key = "auctionColor", name = L.PRICE_COLOR, description = L.PRICE_COLOR_DESC, section = AUCTION,
        requires = "auction", choices = COLORS,
    },
    {
        key = "scanAge", name = L.AUCTIONPRICES_SCAN_AGE, description = L.AUCTIONPRICES_SCAN_AGE_DESC,
        section = AUCTION, requires = "auction",
        choices = {
            { "right", L.PRICE_ALIGN_RIGHT },
            { "inline", L.PRICE_ALIGN_INLINE },
            { "off", L.AUCTIONPRICES_SCAN_AGE_OFF },
        },
    },
    {
        key = "scanAgeColor", name = L.AUCTIONPRICES_SCAN_AGE_COLOR,
        description = L.AUCTIONPRICES_SCAN_AGE_COLOR_DESC, section = AUCTION, requires = "scanAge",
        choices = {
            { "age", L.AUCTIONPRICES_SCAN_AGE_COLOR_AGE },
            { "gray", L.PRICE_COLOR_GRAY },
            { "white", L.PRICE_COLOR_WHITE },
            { "gold", L.PRICE_COLOR_GOLD },
        },
    },
    {
        key = "scanAgeRedHours", name = L.AUCTIONPRICES_SCAN_AGE_RED,
        description = L.AUCTIONPRICES_SCAN_AGE_RED_DESC, section = AUCTION, requires = "scanAge",
        min = 1, max = 48, step = 1, format = ns.Text.Hours,
    },
    {
        key = "crafting", name = L.AUCTIONPRICES_CRAFTING, description = L.AUCTIONPRICES_CRAFTING_DESC,
        section = AUCTION, requires = "auction",
    },
    {
        key = "scanOnOpen", name = L.AUCTIONPRICES_SCAN_ON_OPEN, description = L.AUCTIONPRICES_SCAN_ON_OPEN_DESC,
        section = AUCTION, requires = "auction",
    },
}
local chat = ns.ChatOption(L.AUCTIONPRICES_CHAT_DESC, AUCTION)
chat.requires = "auction"
module.options[#module.options + 1] = chat

-- Parts ----------------------------------------------------------------------------------------
-- Each part is on while the module and its checkbox are: `enable` and `disable` undo each other,
-- and `optionChanged(key)` hears about the module's other options while it's on.

local parts = {} -- { key, enable, disable, optionChanged?, on }

---Adds a part, turned on and off by the checkbox option `key`.
---@param key string
---@param part table { enable = fn, disable = fn, optionChanged? = fn(key) }
function internal.AddPart(key, part)
    part.key = key
    parts[#parts + 1] = part
end

---Whether the part with checkbox `key` is on. Hooks can't be removed, so theirs ask this.
---@param key string
---@return boolean
function internal.Active(key)
    return module.enabled and module.db[key] and true or false
end

local function sync()
    for _, part in ipairs(parts) do
        local on = internal.Active(part.key)
        if on ~= (part.on or false) then
            part.on = on
            if on then
                part.enable()
            else
                part.disable()
            end
        end
    end
    -- Both price lines change with Shift.
    ItemTooltip.RedrawOnShift(module, internal.Active("sellPrice") or internal.Active("auction"))
end

function module:OnEnable()
    sync()
end

function module:OnDisable()
    sync()
end

function module:OnOptionChanged(key)
    sync()
    for _, part in ipairs(parts) do
        if part.on and part.optionChanged then
            part.optionChanged(key)
        end
    end
end
