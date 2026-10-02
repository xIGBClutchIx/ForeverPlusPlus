-- Auto Sell Junk: sells the gray items in your bags when a merchant opens, and says in chat what
-- they sold for. Hold Shift while opening the merchant to skip it.
local _, ns = ...

local format, select = string.format, select
local C_Container, C_Item = C_Container, C_Item
local IsShiftKeyDown = IsShiftKeyDown

local L = ns.L
local money = ns.Money

local LAST_BAG = 5
local BUYBACK_SLOTS = 12 -- the merchant's buyback list holds this many; older sales fall off it

local module = ns.NewModule("AutoSellJunk", L.AUTOSELLJUNK_DESC, {
    enabled = false,
    buybackOnly = true,
    shiftSkips = true,
    chat = true,
})
module.title = L.AUTOSELLJUNK_TITLE
module.category = "automation"

module.options = {
    {
        key = "buybackOnly",
        name = L.AUTOSELLJUNK_BUYBACK,
        description = L.AUTOSELLJUNK_BUYBACK_DESC,
    },
    { key = "shiftSkips", name = L.AUTOSELLJUNK_SHIFT, description = L.AUTOSELLJUNK_SHIFT_DESC },
    ns.ChatOption(L.AUTOSELLJUNK_CHAT_DESC),
}

local function onMerchantShow()
    if module.db.shiftSkips and IsShiftKeyDown() then
        return
    end
    local limit = module.db.buybackOnly and BUYBACK_SLOTS or nil
    local sold, total = 0, 0
    for bag = 0, LAST_BAG do -- backpack, four bags, and the reagent bag
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue
                and not info.isLocked then
                if limit and sold >= limit then
                    break
                end
                local price = select(11, C_Item.GetItemInfo(info.hyperlink)) or 0
                total = total + price * (info.stackCount or 1)
                sold = sold + 1
                C_Container.UseContainerItem(bag, slot)
            end
        end
        if limit and sold >= limit then
            break
        end
    end
    if sold > 0 then
        module:Print(format(L.AUTOSELLJUNK_SOLD, sold, money(total)))
    end
end

function module:OnEnable()
    self:On("MERCHANT_SHOW", onMerchantShow)
end
