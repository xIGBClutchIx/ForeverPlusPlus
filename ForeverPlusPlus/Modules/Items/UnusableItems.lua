-- Unusable Items Tint: tints red the icons of items you can't use, in your bags, the bank, and
-- at merchants, the way Blizzard tints them in a merchant's list.
--
-- "Can't use" is what the game's own item tooltip says: any line in Blizzard's red, such as a
-- class, armor or weapon type, level, profession skill, or reputation you don't have. That
-- covers more than C_PlayerInfo.CanUseItem, which doesn't say whether it checks level. "Already
-- known" is red too but left out: that's Already Known's mark, not "can't use".
--
-- The tint is our own texture over the icon, multiplying it (MOD blend), so it looks like
-- Blizzard's red vertex color without touching the icon: bags set the icon's color themselves
-- on every cooldown update, which would wipe a color we set.
local _, ns = ...

local _G, ipairs, pairs, type, wipe = _G, ipairs, pairs, type, wipe
local setmetatable = setmetatable
local C_Item, C_TooltipInfo, C_Container, C_Timer = C_Item, C_TooltipInfo, C_Container, C_Timer

local L = ns.L

local module = ns.NewModule("UnusableItems", L.UNUSABLEITEMS_DESC, {
    enabled = false,
    bags = true,
    bank = true,
    merchant = true,
})
module.title = L.UNUSABLEITEMS_TITLE
module.category = "items"
module.added = "0.8.0"

module.options = {
    { key = "bags", name = L.UNUSABLEITEMS_BAGS, description = L.UNUSABLEITEMS_BAGS_DESC },
    { key = "bank", name = L.UNUSABLEITEMS_BANK, description = L.UNUSABLEITEMS_BANK_DESC },
    { key = "merchant", name = L.UNUSABLEITEMS_MERCHANT, description = L.UNUSABLEITEMS_MERCHANT_DESC },
}

local TINT = { 0.9, 0, 0 } -- Blizzard's merchant tint for an item you can't use

-- Is it usable ------------------------------------------------------------------------------------

local RED = _G.RED_FONT_COLOR

-- Blizzard's red (1, 0.125, 0.125), with room for rounding.
local function isRed(color)
    if not (color and ns.IsReadable(color)) then
        return false
    end
    local r, g, b = color.r, color.g, color.b
    if not (ns.IsReadable(r) and type(r) == "number" and type(g) == "number" and type(b) == "number") then
        return false
    end
    local rr, rg, rb = 1, 0.125, 0.125
    if RED then
        rr, rg, rb = RED.r, RED.g, RED.b
    end
    return r > rr - 0.05 and g < rg + 0.05 and b < rb + 0.05
end

-- True when a line is red, false when none is, nil while the game has no tooltip for the item
-- yet (not cached), so that isn't taken for "usable".
local function tooltipUnusable(link)
    local data = C_TooltipInfo and C_TooltipInfo.GetHyperlink(link)
    local lines = data and data.lines
    if not lines or #lines == 0 then
        return nil
    end
    local alreadyKnown = _G.ITEM_SPELL_KNOWN
    for i = 2, #lines do -- line 1 is the name, in its quality color
        local line = lines[i]
        local text = line.leftText
        if not (alreadyKnown and ns.IsReadable(text) and text == alreadyKnown)
            and (isRed(line.leftColor) or (line.rightText and isRed(line.rightColor))) then
            return true
        end
    end
    return false
end

local results = {} -- itemID -> true (can't use) or false, until the player changes

---Whether an item link is one the player can't use. False for no item, or one not loaded yet.
local function unusable(link)
    if not link then
        return false
    end
    local itemID = C_Item.GetItemInfoInstant(link)
    if not itemID then
        return false
    end
    local result = results[itemID]
    if result == nil then
        result = tooltipUnusable(link)
        results[itemID] = result
    end
    return result or false
end

-- Tints -----------------------------------------------------------------------------------------

local tints = setmetatable({}, { __mode = "k" }) -- icon texture -> our tint texture

-- Shows or hides our tint over an icon. Does nothing for an icon that was never tinted.
local function setTint(icon, on)
    if not icon then
        return
    end
    local tint = tints[icon]
    if not on then
        if tint then
            tint:Hide()
        end
        return
    end
    if not tint then
        local layer, sublevel = icon:GetDrawLayer()
        tint = icon:GetParent():CreateTexture(nil, layer, nil, (sublevel or 0) < 7 and (sublevel or 0) + 1 or 7)
        tint:SetColorTexture(TINT[1], TINT[2], TINT[3])
        tint:SetBlendMode("MOD")
        tint:SetAllPoints(icon)
        tints[icon] = tint
    end
    tint:Show()
end

local function clearTints()
    for icon in pairs(tints) do
        setTint(icon, false)
    end
end

-- Bags ------------------------------------------------------------------------------------------

local function bagFrames()
    local list = { _G.ContainerFrameCombinedBags }
    for i = 1, _G.NUM_CONTAINER_FRAMES or 13 do
        list[#list + 1] = _G["ContainerFrame" .. i]
    end
    return list
end

local function updateBag(frame)
    if not frame.EnumerateValidItems then
        return
    end
    local on = module.db.bags
    for _, button in frame:EnumerateValidItems() do
        local bag = button.GetBagID and button:GetBagID() or button:GetParent():GetID()
        local link = on and C_Container.GetContainerItemLink(bag, button:GetID())
        setTint(button.icon or button.Icon, link and unusable(link))
    end
end

local function hookBags()
    for _, frame in ipairs(bagFrames()) do
        if type(frame.UpdateItems) == "function" then
            module:Hook(frame, "UpdateItems", updateBag)
        end
    end
end

-- Bank ------------------------------------------------------------------------------------------

-- Forever's bank is Blizzard's BankPanel with tabs (Blizzard_UIPanels_Game, Camelot BankFrame).
local function updateBank()
    local panel = _G.BankPanel
    if not (panel and panel.EnumerateValidItems) then
        return
    end
    local on = module.db.bank
    for button in panel:EnumerateValidItems() do
        local link
        if on and button.GetBankTabID and button.GetContainerSlotID then
            link = C_Container.GetContainerItemLink(button:GetBankTabID(), button:GetContainerSlotID())
        end
        setTint(button.icon, link and unusable(link))
    end
end

local function hookBank()
    local panel = _G.BankPanel
    if not panel then
        return
    end
    for _, method in ipairs({ "RefreshAllItemsForSelectedTab", "GenerateItemSlotsForSelectedTab" }) do
        if type(panel[method]) == "function" then
            module:Hook(panel, method, updateBank)
        end
    end
end

-- Merchants -------------------------------------------------------------------------------------

local function merchantIcon(i)
    local button = _G["MerchantItem" .. i .. "ItemButton"]
    return button and (button.icon or _G["MerchantItem" .. i .. "ItemButtonIconTexture"])
end

-- Whether Blizzard already tints this merchant item red, so ours isn't laid on top of it.
local function blizzardTinted(index)
    local info = _G.C_MerchantFrame and _G.C_MerchantFrame.GetItemInfo
        and _G.C_MerchantFrame.GetItemInfo(index)
    return info and (info.isPurchasable == false or info.isUsable == false)
end

local function updateMerchant()
    local frame = _G.MerchantFrame
    if not (frame and _G.GetMerchantItemLink) then
        return
    end
    local perPage = _G.MERCHANT_ITEMS_PER_PAGE or 10
    local on = module.db.merchant
    for i = 1, perPage do
        local index = ((frame.page or 1) - 1) * perPage + i
        local link = on and _G.GetMerchantItemLink(index)
        setTint(merchantIcon(i), link and not blizzardTinted(index) and unusable(link))
    end
end

-- The buyback tab reuses the same buttons, and Blizzard tints those itself.
local function clearMerchant()
    for i = 1, _G.MERCHANT_ITEMS_PER_PAGE or 10 do
        setTint(merchantIcon(i), false)
    end
end

-- Module ----------------------------------------------------------------------------------------

local function refresh()
    for _, frame in ipairs(bagFrames()) do
        if frame:IsShown() then
            updateBag(frame)
        end
    end
    local bank = _G.BankFrame
    if bank and bank:IsShown() then
        updateBank()
    end
    local merchant = _G.MerchantFrame
    if merchant and merchant:IsShown() and (merchant.selectedTab or 1) == 1 then
        updateMerchant()
    end
end

local refreshTimer

-- Item data arrives a little after a window opens, and what you can use changes as you level
-- and train: look again shortly, once for a burst of events.
local function refreshSoon()
    if refreshTimer then
        return
    end
    refreshTimer = C_Timer.NewTimer(0.5, function()
        refreshTimer = nil
        if module.enabled then
            refresh()
        end
    end)
end

local function onPlayerChanged()
    wipe(results)
    refreshSoon()
end

local function hookGlobal(name, fn)
    if type(_G[name]) == "function" then
        module:Hook(name, fn)
    end
end

function module:OnEnable()
    hookGlobal("MerchantFrame_UpdateMerchantInfo", updateMerchant)
    hookGlobal("MerchantFrame_UpdateBuybackInfo", clearMerchant)
    hookBags()
    hookBank()
    self:On("GET_ITEM_INFO_RECEIVED", refreshSoon) -- items without a tooltip yet weren't kept
    self:On("PLAYER_LEVEL_UP", onPlayerChanged)
    self:On("SKILL_LINES_CHANGED", onPlayerChanged)
    self:On("LEARNED_SPELL_IN_SKILL_LINE", onPlayerChanged)
    refresh()
end

function module:OnDisable()
    if refreshTimer then
        refreshTimer:Cancel()
        refreshTimer = nil
    end
    clearTints()
end

function module:OnOptionChanged()
    if self.enabled then
        refresh()
    end
end
