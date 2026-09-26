-- Sell Price: the vendor price in item tooltips counts the whole stack, and Shift shows one item
-- (or the other way round). Forever's own line prices one item only.
local _, ns = ...

local select = select
local C_Item = C_Item
local SELL_PRICE = SELL_PRICE

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local module = ns.NewModule("SellPrice", L.SELLPRICE_DESC, {
    enabled = true,
    mode = "stack", -- "stack" (Shift for one) or "one" (Shift for the stack)
    align = "right", -- "right" (coins at the tooltip's edge) or "inline" (after the label)
})
module.title = L.SELLPRICE_TITLE

module.options = {
    {
        key = "mode",
        name = L.SELLPRICE_MODE,
        description = L.SELLPRICE_MODE_DESC,
        choices = {
            { "stack", L.PRICE_MODE_STACK },
            { "one", L.PRICE_MODE_ONE },
        },
    },
    {
        key = "align",
        name = L.SELLPRICE_ALIGN,
        description = L.SELLPRICE_ALIGN_DESC,
        choices = {
            { "right", L.SELLPRICE_ALIGN_RIGHT },
            { "inline", L.SELLPRICE_ALIGN_INLINE },
        },
    },
}

ItemTooltip.AddName(SELL_PRICE)

-- One item's vendor price. Item info has it per item; the line's own price is the fallback
-- while item info isn't cached (Forever's line prices one item).
local function unitPrice(data, lineData)
    local price = select(11, C_Item.GetItemInfo(data.id))
    return price or lineData.price
end

local function drawSellPrice(tooltip, data, lineData)
    if not module.enabled or not ns.IsReadable(data.id) or not data.id then
        return false
    end
    local price = unitPrice(data, lineData)
    if not price or price <= 0 then
        return false
    end
    local count = ItemTooltip.PriceCount(data, module.db.mode)
    ItemTooltip.AddPrice(tooltip, SELL_PRICE, price * count, count)
    return true
end

local hooked = false

function module:OnEnable()
    -- The hook can't be removed; drawSellPrice checks module.enabled and lets Blizzard's line
    -- show when off.
    if not hooked then
        hooked = true
        ItemTooltip.ReplaceSellPrice(drawSellPrice)
    end
    ItemTooltip.SetAlignment(self.db.align)
end

function module:OnOptionChanged(key)
    if key == "align" and self.enabled then
        ItemTooltip.SetAlignment(self.db.align)
    end
end

function module:OnDisable()
    ItemTooltip.SetAlignment("right")
end
