-- Auto Repair: repairs all gear when a merchant who can repair opens, from the guild bank, the
-- player's own money, or the guild bank first, and says in chat what it cost. Hold Shift while
-- opening the merchant to skip it.
local _, ns = ...

local format = string.format
local CanMerchantRepair, GetRepairAllCost, RepairAllItems = CanMerchantRepair, GetRepairAllCost, RepairAllItems
local IsInGuild, CanGuildBankRepair, GetGuildBankWithdrawMoney = IsInGuild, CanGuildBankRepair, GetGuildBankWithdrawMoney
local GetMoney, IsShiftKeyDown, C_Timer = GetMoney, IsShiftKeyDown, C_Timer

local L = ns.L
local money = ns.Money

local module = ns.NewModule("AutoRepair", L.AUTOREPAIR_DESC, {
    enabled = true,
    funds = "guildFirst", -- "guildFirst", "guild", or "own"
    chat = true,
})
module.title = L.AUTOREPAIR_TITLE
module.category = "automation"

module.options = {
    {
        key = "funds",
        name = L.AUTOREPAIR_FUNDS,
        description = L.AUTOREPAIR_FUNDS_DESC,
        choices = {
            { "guildFirst", L.AUTOREPAIR_FUNDS_GUILD_FIRST },
            { "guild", L.AUTOREPAIR_FUNDS_GUILD },
            { "own", L.AUTOREPAIR_FUNDS_OWN },
        },
    },
    ns.ChatOption(L.AUTOREPAIR_CHAT_DESC),
}

-- The server says whether a guild bank repair worked only afterwards: durability updates when it
-- did, and an error shows when it didn't (not enough in the bank, or over the daily limit).
local pending -- the cost of the guild bank repair waiting for an answer
local onDurability, onError

local function stopWaiting()
    pending = nil
    ns.Off("UPDATE_INVENTORY_DURABILITY", onDurability)
    ns.Off("UI_ERROR_MESSAGE", onError)
end

local function repairOwn(cost)
    if GetMoney() < cost then
        module:Print(format(L.AUTOREPAIR_NO_MONEY, money(cost)))
        return
    end
    RepairAllItems()
    module:Print(format(L.AUTOREPAIR_REPAIRED, money(cost)))
end

function onDurability()
    module:Print(format(L.AUTOREPAIR_REPAIRED_GUILD, money(pending)))
    stopWaiting()
end

function onError()
    local cost = pending
    stopWaiting()
    if module.db.funds == "guildFirst" then
        repairOwn(cost)
    else
        module:Print(format(L.AUTOREPAIR_NO_GUILD_MONEY, money(cost)))
    end
end

-- The guild bank can pay: in a guild, allowed to repair with it, and under today's limit
-- (-1 means no limit).
local function guildCanPay(cost)
    if not (IsInGuild() and CanGuildBankRepair()) then
        return false
    end
    local limit = GetGuildBankWithdrawMoney()
    return limit == -1 or limit >= cost
end

local function repairGuild(cost)
    stopWaiting()
    pending = cost
    ns.On("UPDATE_INVENTORY_DURABILITY", onDurability)
    ns.On("UI_ERROR_MESSAGE", onError)
    RepairAllItems(true)
    -- No answer means nothing changed; stop listening so a later error isn't taken for this.
    C_Timer.After(3, function()
        if pending == cost then
            stopWaiting()
        end
    end)
end

local function onMerchantShow()
    if IsShiftKeyDown() or not CanMerchantRepair() then
        return
    end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or cost <= 0 then
        return
    end
    local funds = module.db.funds
    if funds ~= "own" and guildCanPay(cost) then
        repairGuild(cost)
    elseif funds == "guild" then
        module:Print(format(L.AUTOREPAIR_NO_GUILD_MONEY, money(cost)))
    else
        repairOwn(cost)
    end
end

function module:OnEnable()
    self:On("MERCHANT_SHOW", onMerchantShow)
end

function module:OnDisable()
    stopWaiting()
end
