-- Bulk Buy: Shift+click an item at a merchant for a buying popup of our own in place of Blizzard's
-- stack split: type an amount, or press Stack or Max, and buy more than the merchant sells at once.
-- A big amount is bought a lot at a time, each lot once the one before has reached the bags.
--
-- Blizzard's popup (StackSplitFrame) keeps its amount in fields of its own, and setting one from
-- here would taint what its Okay button buys with. So ours is a frame of our own in the same art,
-- and Blizzard's is hidden the moment it opens for a merchant item. That Hide runs its OnHide in our
-- call, which sets the merchant button's hasStackSplit to 0; Blizzard's next OpenStackSplitFrame
-- sets it again from its own code, and nothing protected reads it (MerchantFrame.xml, ContainerFrame
-- and Blizzard_GuildBankUI only, Gethe `forever` branch). Items bought with tokens or other items,
-- and everything while the controller interface is on, keep Blizzard's popup.
local _, ns = ...

local floor, min, max, tonumber, tostring, select = math.floor, math.min, math.max, tonumber, tostring, select
local CreateFrame, GetMoney = CreateFrame, GetMoney
local C_Item, C_MerchantFrame = C_Item, C_MerchantFrame
local GetMerchantItemLink, GetMerchantItemMaxStack = GetMerchantItemLink, GetMerchantItemMaxStack
local BuyMerchantItem = BuyMerchantItem

local L = ns.L

local module = ns.NewModule("BulkBuy", L.BULKBUY_DESC, {
    enabled = false,
})
module.title = L.BULKBUY_TITLE
module.category = "items"
module.added = "1.10.0"
module.notice = {
    { text = L.BULKBUY_NOTICE, description = L.BULKBUY_NOTICE_DESC },
    ns.Gamepad.LimitedNotice(), -- the popup is the mouse's; Blizzard's has the controller's buttons
}

local WAIT = 5 -- seconds a lot may take to reach the bags before buying stops
local GAP = 0.2 -- seconds between one lot arriving and buying the next

local timer = ns.Frames.Timer(module)

local popup -- our frame, made the first time it opens
local offer -- what the popup is buying: { index, link, itemID, bundle, stack, lot, price }
local order -- a purchase under way: { offer, left, pending, before }

-- The item at a merchant slot, when the popup can buy it: priced in gold only, and stackable at
-- this merchant (the most one purchase takes is more than one). `bundle` is how many come in one
-- purchase of it, `stack` how many make a stack in the bags, and `lot` the most one purchase takes.
local function read(index)
    local link = GetMerchantItemLink and GetMerchantItemLink(index)
    local info = link and C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(index)
    if not (info and info.isPurchasable) or info.hasExtendedCost then
        return nil
    end
    local itemID = C_Item.GetItemInfoInstant(link)
    -- Probe: GetItemMaxStackSizeByID is Mainline's; GetItemInfo's eighth value is the same.
    local stack = itemID and (C_Item.GetItemMaxStackSizeByID and C_Item.GetItemMaxStackSizeByID(itemID)
        or select(8, C_Item.GetItemInfo(link)))
    local bundle = max(info.stackCount or 1, 1)
    local lot = GetMerchantItemMaxStack and GetMerchantItemMaxStack(index) or 0
    lot = floor(lot / bundle) * bundle
    if not stack or lot < 2 then
        return nil
    end
    return {
        index = index, link = link, itemID = itemID, bundle = bundle, stack = max(stack, 1), lot = lot,
        price = info.price or 0, available = info.numAvailable or 0,
    }
end

-- The most of it the player can buy now, in whole bundles: what their money pays for, what fits in
-- their bags, and what the merchant has left of a limited item.
local function most(item)
    local limit = ns.Bags.Room(item.itemID, item.stack)
    if item.price > 0 then
        limit = min(limit, floor(GetMoney() / item.price) * item.bundle)
    end
    if item.available > 0 then
        limit = min(limit, item.available * item.bundle)
    end
    return floor(limit / item.bundle) * item.bundle
end

-- The same item still at the same slot: a page turn or a restock can move it.
local function same(a, b)
    return a and b and a.index == b.index and a.link == b.link and a.price == b.price
end

local function count(itemID)
    return C_Item.GetItemCount(itemID, false, false, true) or 0
end

-- Buying ------------------------------------------------------------------------------------------

local function stop()
    order = nil
    timer:Cancel()
end

-- Buys the next lot of the order, after checking the item is still the one the player chose.
local function nextLot()
    if not order then
        return
    end
    local fresh = read(order.offer.index)
    if not same(order.offer, fresh) or order.left < fresh.bundle then
        stop()
        return
    end
    local amount = min(order.left, fresh.lot)
    order.pending, order.before = amount, count(fresh.itemID)
    BuyMerchantItem(fresh.index, amount)
    timer:Start(WAIT, stop)
end

-- A lot arrived once the bags hold that many more of the item.
local function onBagUpdate()
    if not (order and order.pending) or count(order.offer.itemID) - order.before < order.pending then
        return
    end
    order.left = order.left - order.pending
    order.pending = nil
    if order.left > 0 then
        timer:Start(GAP, nextLot)
    else
        stop()
    end
end

local function buy(item, amount)
    stop()
    order = { offer = item, left = amount }
    nextLot()
end

-- The popup ---------------------------------------------------------------------------------------

local function close()
    if popup then
        popup:Hide()
    end
    offer = nil
end

-- Shows `amount`, held between one bundle and the most, and what it costs.
local function setAmount(amount)
    local limit = popup.limit
    amount = floor((tonumber(amount) or 0) / offer.bundle) * offer.bundle
    amount = max(offer.bundle, min(amount, limit))
    popup.amount = amount
    popup.box:SetText(tostring(amount))
    popup.box:SetCursorPosition(#tostring(amount))
    popup.left:SetEnabled(amount > offer.bundle)
    popup.right:SetEnabled(amount < limit)
    popup.cost:SetText(offer.price > 0 and ns.Money(offer.price * amount / offer.bundle) or "")
end

local function step(direction)
    if offer then
        setAmount(popup.amount + direction * offer.bundle)
    end
end

-- Okay: buys what the box says, rounded to whole bundles, or less when money or bag room has gone
-- down since the popup opened.
local function accept()
    if not offer then
        return
    end
    setAmount(popup.box:GetText())
    local item, amount = offer, popup.amount
    close()
    local fresh = item and read(item.index)
    if not same(item, fresh) then
        return
    end
    amount = min(amount, most(fresh))
    if amount >= fresh.bundle then
        buy(fresh, amount)
    end
end

local function arrow(side)
    local button = CreateFrame("Button", nil, popup)
    button:SetSize(16, 16)
    local base = "Interface\\MoneyFrame\\Arrow-" .. side
    button:SetNormalTexture(base .. "-Up")
    button:SetPushedTexture(base .. "-Down")
    button:SetDisabledTexture(base .. "-Disabled")
    return button
end

local function button(text, onClick, tip)
    local b = ns.Frames.Button(popup, text, 64, onClick)
    b:SetHeight(24)
    if tip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return b
end

-- Blizzard's split popup, made taller for a row of buttons and a line for the cost: its art
-- stretched to fit, its arrows, and its buttons' size (Blizzard_FrameXML/Camelot/StackSplitFrame.xml).
local function makePopup()
    popup = CreateFrame("Frame", nil, MerchantFrame)
    popup:SetSize(172, 146)
    popup:SetFrameStrata("HIGH")
    popup:SetToplevel(true)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:EnableMouseWheel(true)
    popup:Hide()
    local art = popup:CreateTexture(nil, "BACKGROUND")
    art:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame")
    art:SetTexCoord(0, 0.671875, 0, 0.75)
    art:SetAllPoints()

    -- The stretched art's inset box is about 46 tall, from 23 to 69 below the top: the amount in
    -- its upper half and the cost in its lower, both centered.
    popup.left = arrow("Left")
    popup.left:SetPoint("RIGHT", popup, "TOPLEFT", 27, -38)
    popup.left:SetScript("OnClick", function()
        step(-1)
    end)
    popup.right = arrow("Right")
    popup.right:SetPoint("LEFT", popup, "TOPLEFT", 150, -38)
    popup.right:SetScript("OnClick", function()
        step(1)
    end)

    local box = CreateFrame("EditBox", nil, popup)
    box:SetPoint("LEFT", popup.left, "RIGHT", 4, 0)
    box:SetPoint("RIGHT", popup.right, "LEFT", -4, 0)
    box:SetHeight(20)
    box:SetFontObject("GameFontHighlight")
    box:SetJustifyH("CENTER")
    box:SetNumeric(true)
    box:SetMaxLetters(5)
    box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", accept)
    box:SetScript("OnEscapePressed", close)
    box:SetScript("OnEditFocusLost", function()
        if offer then
            setAmount(box:GetText())
        end
    end)
    box:SetScript("OnTextChanged", function(_, typed)
        -- What the player types is held to the most as they type; a bundle's rounding waits.
        local amount = typed and offer and tonumber(box:GetText())
        if amount and amount > popup.limit then
            setAmount(popup.limit)
        elseif amount then
            popup.amount = amount
            popup.cost:SetText(offer.price > 0 and ns.Money(offer.price * floor(amount / offer.bundle)) or "")
        end
    end)
    popup.box = box

    popup.cost = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    popup.cost:SetPoint("CENTER", popup, "TOP", 0, -57)

    local stackButton = button(L.BULKBUY_STACK, function()
        if offer then
            setAmount(offer.stack)
        end
    end, L.BULKBUY_STACK_DESC)
    stackButton:SetPoint("TOPRIGHT", popup, "TOP", -3, -78)
    local maxButton = button(L.BULKBUY_MAX, function()
        if offer then
            setAmount(popup.limit)
        end
    end, L.BULKBUY_MAX_DESC)
    maxButton:SetPoint("TOPLEFT", popup, "TOP", 5, -78)
    local okay = button(OKAY, accept)
    okay:SetPoint("TOPRIGHT", popup, "TOP", -3, -102)
    local cancel = button(CANCEL, close)
    cancel:SetPoint("TOPLEFT", popup, "TOP", 5, -102)

    popup:SetScript("OnMouseWheel", function(_, delta)
        step(delta > 0 and 1 or -1)
    end)
    popup:SetScript("OnHide", function()
        offer = nil
        box:ClearFocus()
    end)
end

local function open(itemButton, item, limit)
    if not popup then
        makePopup()
    end
    offer = item
    popup.limit = limit
    popup:ClearAllPoints()
    popup:SetPoint("BOTTOMLEFT", itemButton, "TOPLEFT", 0, 0) -- where Blizzard's opens
    popup:Show()
    setAmount(item.bundle)
    popup.box:SetFocus()
    popup.box:HighlightText()
end

-- After Blizzard's Shift+click on a merchant item: when it opened its split popup for the item and
-- ours can buy it, ours takes its place. Otherwise (a link into chat, a token's price, bags too full
-- for one) Blizzard's stays.
local function onModifiedClick(itemButton)
    local split = StackSplitFrame
    if not (split and split:IsShown() and split.owner == itemButton) or ns.Gamepad.On() then
        return
    end
    local item = read(itemButton:GetID())
    local limit = item and most(item)
    if not (limit and limit >= item.bundle) then
        return
    end
    split:Hide()
    open(itemButton, item, limit)
end

function module:OnEnable()
    self:Hook("MerchantItemButton_OnModifiedClick", onModifiedClick)
    self:Hook("MerchantFrame_CloseStackSplitFrame", close) -- a page turn or the buyback tab
    self:On("MERCHANT_CLOSED", function()
        close()
        stop()
    end)
    self:On("BAG_UPDATE_DELAYED", onBagUpdate)
    self:On("UI_ERROR_MESSAGE", function() -- "Inventory is full", "You don't have enough money"
        if order then
            stop()
        end
    end)
end

function module:OnDisable()
    close()
    stop()
end
