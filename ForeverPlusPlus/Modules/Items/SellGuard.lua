-- Sell Guard: asks before a good or valuable item is sold to a merchant. Selling can't be stopped
-- before it happens without replacing Blizzard's code, so a guarded sale is bought straight back
-- (for the same money) and Yes sells it again. Holding Shift sells without asking, and gray items
-- are never asked about, so Auto Sell Junk runs as before.
local _, ns = ...

local select, wipe, tremove = select, wipe, table.remove
local C_Container, C_Item = C_Container, C_Item
local IsShiftKeyDown = IsShiftKeyDown
local GetNumBuybackItems, GetBuybackItemLink, BuybackItem =
    GetNumBuybackItems, GetBuybackItemLink, BuybackItem

local L = ns.L
local money = ns.Money

local POPUP = "SELLGUARD"
local LAST_BAG = 5
local COPPER_PER_GOLD = 10000

local module = ns.NewModule("SellGuard", L.SELLGUARD_DESC, {
    enabled = false,
    quality = "rare",
    price = 1,
})
module.title = L.SELLGUARD_TITLE
module.category = "items"
module.added = "0.8.0"

-- Enum.ItemQuality's values, which match the item qualities in every client.
local QUALITY = { uncommon = 2, rare = 3, epic = 4 }

module.options = {
    {
        key = "quality", name = L.SELLGUARD_QUALITY, description = L.SELLGUARD_QUALITY_DESC,
        choices = {
            { "uncommon", L.SELLGUARD_UNCOMMON },
            { "rare", L.SELLGUARD_RARE },
            { "epic", L.SELLGUARD_EPIC },
        },
    },
    {
        key = "price", name = L.SELLGUARD_PRICE, description = L.SELLGUARD_PRICE_DESC,
        min = 0, max = 50, step = 1,
        format = function(gold)
            return gold == 0 and L.SELLGUARD_PRICE_OFF or money(gold * COPPER_PER_GOLD)
        end,
    },
}

local atMerchant = false
local resell = false -- true while Yes sells the item again, so the hook lets it through
local pending = {} -- links of guarded sales, waiting to be bought back

-- Whether selling this bag item needs a Yes. Gray items never do.
local function guarded(info)
    local quality = info.quality
    if not quality or quality < 1 or info.hasNoValue then
        return false
    end
    if quality >= (QUALITY[module.db.quality] or QUALITY.rare) then
        return true
    end
    local threshold = (module.db.price or 0) * COPPER_PER_GOLD
    if threshold <= 0 then
        return false
    end
    local each = select(11, C_Item.GetItemInfo(info.hyperlink)) or 0
    return each * (info.stackCount or 1) >= threshold
end

-- After a bag item is used at a merchant, which sells it. The item is still in its slot (locked)
-- until the server answers, so it can be read here.
local function onUse(bag, slot)
    if not atMerchant or resell or IsShiftKeyDown() then
        return
    end
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and info.hyperlink and guarded(info) then
        pending[#pending + 1] = info.hyperlink
    end
end

local function sellAgain(link)
    for i = #pending, 1, -1 do
        if pending[i] == link then
            -- Yes came before the buyback: leave it sold.
            tremove(pending, i)
            return
        end
    end
    if not atMerchant then
        return -- using the item away from a merchant would equip or use it instead
    end
    for bag = 0, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink == link and not info.isLocked then
                resell = true
                C_Container.UseContainerItem(bag, slot)
                resell = false
                return
            end
        end
    end
end

-- The sale reached the buyback list: buy the guarded ones back and ask. The newest sale is last.
local function onMerchantUpdate()
    if #pending == 0 then
        return
    end
    for index = GetNumBuybackItems(), 1, -1 do
        local link = GetBuybackItemLink(index)
        for i = #pending, 1, -1 do
            if pending[i] == link then
                tremove(pending, i)
                BuybackItem(index)
                ns.Confirm(POPUP, L.SELLGUARD_CONFIRM, sellAgain, link)
                break
            end
        end
        if #pending == 0 then
            return
        end
    end
end

local function onMerchantClosed()
    atMerchant = false
    wipe(pending)
    ns.ConfirmHide(POPUP)
end

function module:OnEnable()
    self:On("MERCHANT_SHOW", function()
        atMerchant = true
    end)
    self:On("MERCHANT_CLOSED", onMerchantClosed)
    self:On("MERCHANT_UPDATE", onMerchantUpdate)
    self:Hook(C_Container, "UseContainerItem", onUse)
end

function module:OnDisable()
    onMerchantClosed()
end
