-- Item Tooltips' sell price: the vendor price in item tooltips counts the whole stack, and Shift
-- shows one item (or the other way round). Forever's own line prices one item only.
local _, ns = ...

local select = select
local C_Item = C_Item
local SELL_PRICE = SELL_PRICE

local ItemTooltip = ns.ItemTooltip

local module = ns.modules.ItemTooltips
local internal = module.internal

-- One item's vendor price. Item info has it per item; the line's own price is the fallback
-- while item info isn't cached (Forever's line prices one item).
local function unitPrice(data, lineData)
    local price = select(11, C_Item.GetItemInfo(data.id))
    return price or lineData.price
end

local function drawSellPrice(tooltip, data, lineData)
    if not internal.Active("sellPrice") or not ItemTooltip.ItemID(data) then
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

internal.AddPart("sellPrice", {
    enable = function()
        -- The hook can't be removed; drawSellPrice checks the part is on and lets Blizzard's line
        -- show when it's off.
        ItemTooltip.ReplaceSellPrice(drawSellPrice)
    end,
    disable = function() end,
})
