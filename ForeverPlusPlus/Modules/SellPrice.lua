-- Sell Price: the vendor price in item tooltips counts the whole stack, and Shift shows one item
-- (or the other way round). Forever's own line prices one item only.
local _, ns = ...

local select = select
local C_Item = C_Item
local SELL_PRICE = SELL_PRICE

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local module = ns.NewModule("SellPrice", L.SELLPRICE_DESC,
    ItemTooltip.PriceDefaults({ enabled = true }, "white"))
module.title = L.SELLPRICE_TITLE
module.options = ItemTooltip.PriceOptions({})

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
    ItemTooltip.AddPrice(tooltip, SELL_PRICE, price * count, count, module.db)
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
end

function module:OnDisable()
end
