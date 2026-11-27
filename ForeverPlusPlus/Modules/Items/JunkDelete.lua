-- Junk Delete Button: while the bags are full and the loot window still holds an item, a button
-- below it destroys the gray stack worth least to a vendor (ns.Bags.CheapestJunk), so there's room
-- to take the loot. The button names the stack and its value, and one click destroys that stack
-- and no other: the slot is read again at the click, and nothing happens if it changed.
--
-- DeleteCursorItem has restrictions (Blizzard_APIDocumentationGenerated/GameCursorDocumentation.lua,
-- wow-ui-source `forever` branch): it needs a click, so it runs only from the button's own OnClick,
-- or the Yes of the popup the Confirm Before Deleting option asks first, as Blizzard's own delete
-- popup does. It isn't protected, so a plain button may call it. **Unverified** in game.
local _, ns = ...

local _G, format, min, max = _G, string.format, math.min, math.max
local C_Container, C_Item = C_Container, C_Item
local GetNumLootItems, GetLootSlotType = GetNumLootItems, GetLootSlotType
local GetCursorInfo, CursorHasItem, ClearCursor = GetCursorInfo, CursorHasItem, ClearCursor
local DeleteCursorItem, InCombatLockdown, GameTooltip = DeleteCursorItem, InCombatLockdown, GameTooltip

local L = ns.L

local module = ns.NewModule("JunkDelete", L.JUNKDELETE_DESC, {
    enabled = false,
    confirm = true,
    chat = true,
})
module.title = L.JUNKDELETE_TITLE
module.presets = { developer = { enabled = true } }
module.category = "items"
module.added = "1.10.0"
module.quickToggle = "loot"
module.notice = {
    { text = L.JUNKDELETE_NOTICE, description = L.JUNKDELETE_NOTICE_DESC },
    ns.Gamepad.LimitedNotice(), -- a plain button the controller's cursor doesn't reach
}

module.options = {
    { key = "confirm", name = L.JUNKDELETE_CONFIRM, description = L.JUNKDELETE_CONFIRM_DESC },
    ns.ChatOption(L.JUNKDELETE_CHAT_DESC),
}

local MIN_WIDTH, MAX_WIDTH, PADDING = 120, 320, 40

local button -- ours, below the loot window, made the first time it's needed
local target -- { bag, slot, link, count, itemID, value }: the stack the button names, or nil

local function poor()
    return Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0
end

-- Whether the loot window still holds an item, which needs a bag slot. Money and currency don't.
local function itemLeft()
    local kind = Enum and Enum.LootSlotType and Enum.LootSlotType.Item
    local count = GetNumLootItems()
    if not (kind and ns.IsNumber(count)) then
        return false
    end
    for i = 1, count do
        if GetLootSlotType(i) == kind then
            return true
        end
    end
    return false
end

local function wanted()
    local loot = _G.LootFrame
    return module.enabled and loot ~= nil and loot:IsShown() and not InCombatLockdown()
        and not ns.Gamepad.On() and ns.Bags.FreeSlots() == 0 and itemLeft()
end

local function showTooltip(self)
    if not target then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(target.bag, target.slot) -- Blizzard's own, with its Sell Price line
    local green = GREEN_FONT_COLOR
    GameTooltip:AddLine(L.JUNKDELETE_HINT, green.r, green.g, green.b)
    GameTooltip:Show()
end

local function refresh()
    if not button then
        return
    end
    target = nil
    if wanted() then
        local bag, slot, info, value = ns.Bags.CheapestJunk(ns.Prices.Vendor)
        if bag then
            target = {
                bag = bag, slot = slot, link = info.hyperlink, count = info.stackCount,
                itemID = info.itemID, value = value,
            }
            local name = C_Item.GetItemNameByID(info.itemID) or info.hyperlink
            local color = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[poor()]
            if color and color.hex then
                name = color.hex .. name .. "|r"
            end
            if info.iconFileID then
                name = format("|T%s:0|t %s", info.iconFileID, name)
            end
            button:SetText(format(L.JUNKDELETE_BUTTON, name, ns.Money(value)))
            button:SetWidth(min(MAX_WIDTH, max(MIN_WIDTH, button:GetTextWidth() + PADDING)))
        end
    end
    button:SetShown(target ~= nil)
    if target and GameTooltip:GetOwner() == button then
        showTooltip(button)
    end
end

-- Destroys the stack the button names, only if its slot still holds it, unlocked, and it's what
-- lands on the cursor. Anything else puts it back and looks again. It runs from a click: the
-- button's, or the Yes of the popup the Confirm option asks first.
local function destroy(want)
    target = nil
    if not module.enabled or InCombatLockdown() or CursorHasItem() then
        refresh()
        return
    end
    local info = C_Container.GetContainerItemInfo(want.bag, want.slot)
    if not info or info.isLocked or info.quality ~= poor() or info.hyperlink ~= want.link
        or info.stackCount ~= want.count then
        refresh()
        return
    end
    C_Container.PickupContainerItem(want.bag, want.slot)
    local kind, itemID = GetCursorInfo()
    if kind ~= "item" or itemID ~= want.itemID then
        ClearCursor()
        refresh()
        return
    end
    DeleteCursorItem()
    if CursorHasItem() then
        -- The game refused it: put the stack back where it was.
        ClearCursor()
        refresh()
        return
    end
    button:Hide() -- until the bags answer (BAG_UPDATE_DELAYED)
    module:Print(format(L.JUNKDELETE_DELETED, want.link, ns.Money(want.value)))
end

local function onClick()
    local want = target
    if not want then
        refresh()
        return
    end
    if module.db.confirm then
        -- The popup names the stack asked about; destroy() checks the slot still holds it.
        ns.Confirm("JUNKDELETE_CONFIRM", L.JUNKDELETE_CONFIRM_TEXT, function()
            destroy(want)
        end, want.link)
        return
    end
    destroy(want)
end

local function build()
    local loot = _G.LootFrame
    if button or not loot then
        return
    end
    -- A child of the loot window, so it shows and hides with it.
    button = ns.Frames.Button(loot, nil, MIN_WIDTH, onClick)
    button:SetPoint("TOP", loot, "BOTTOM", 0, -4)
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:Hide()
end

local function onLoot()
    build()
    refresh()
end

function module:IsAvailable()
    return DeleteCursorItem ~= nil and C_Container ~= nil and C_Container.PickupContainerItem ~= nil
        and GetNumLootItems ~= nil
end

function module:OnEnable()
    self:On("LOOT_OPENED", onLoot)
    self:On("LOOT_SLOT_CLEARED", refresh)
    self:On("LOOT_SLOT_CHANGED", refresh)
    self:On("LOOT_CLOSED", refresh)
    self:On("BAG_UPDATE_DELAYED", refresh)
    -- Before the lockdown starts, so InCombatLockdown is still false here.
    self:On("PLAYER_REGEN_DISABLED", function()
        target = nil
        if button then
            button:Hide()
        end
    end)
    self:On("PLAYER_REGEN_ENABLED", refresh)
    onLoot()
end

function module:OnDisable()
    target = nil
    if button then
        button:Hide()
    end
end
