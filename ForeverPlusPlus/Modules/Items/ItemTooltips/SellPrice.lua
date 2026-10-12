-- Item Tooltips' sell price: the vendor price in item tooltips counts the whole stack, and Shift
-- shows one item (or the other way round). Forever's own line prices one item only.
local _, ns = ...

local select = select
local C_Item = C_Item
local SELL_PRICE = SELL_PRICE

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local itemTooltips = ns.modules.ItemTooltips
local module = itemTooltips:NewPart({
    key = "sellPrice", name = L.ITEMTOOLTIPS_SELLPRICE, description = L.SELLPRICE_DESC,
    section = L.SELLPRICE_TITLE,
}, {
    sellPrice = true,
    sellPriceColor = "white", -- the quantity's color: "gray", "white", or "gold"
})

module:AddOptions({
    {
        key = "sellPriceColor", name = L.PRICE_COLOR, description = L.PRICE_COLOR_DESC,
        choices = itemTooltips.internal.COLORS,
    },
})

-- One item's vendor price. Item info has it per item; the line's own price is the fallback
-- while item info isn't cached (Forever's line prices one item).
local function unitPrice(data, lineData)
    local price = select(11, C_Item.GetItemInfo(data.id))
    return price or lineData.price
end

local function drawSellPrice(tooltip, data, lineData)
    if not module.enabled or not ItemTooltip.ItemID(data) then
        return false
    end
    local price = unitPrice(data, lineData)
    if not price or price <= 0 then
        return false
    end
    local db = module.db
    ItemTooltip.AddPrice(tooltip, data, SELL_PRICE, price, db.mode, db.align, db.sellPriceColor)
    return true
end

function module:OnEnable()
    -- The hook can't be removed; drawSellPrice checks the part is on and lets Blizzard's line
    -- show when it's off.
    ItemTooltip.ReplaceSellPrice(drawSellPrice)
    -- The price changes from the stack to one item with Shift.
    ItemTooltip.RedrawOnShift(self, true)
end

function module:OnDisable()
    ItemTooltip.RedrawOnShift(self, false)
end
