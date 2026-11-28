-- Junk Delete Button: while the loot window still holds an item the bags have no room for, a
-- button on it destroys the gray stack worth least to a vendor (ns.Bags.CheapestJunk), so there's
-- room to take the loot. By default it's a small red button in the loot window's top left corner, the
-- mirror of its close button, in Blizzard's own delete button art. Or a panel button below the
-- window: short, no wider than the loot window (Item on the Button writes the stack and its value
-- on its face instead, as wide as they need). Either one's tooltip, above it, names the stack
-- and its value. One click destroys that stack and no other: the slot is read again at the
-- click, and nothing happens if it changed.
--
-- DeleteCursorItem has restrictions (Blizzard_APIDocumentationGenerated/GameCursorDocumentation.lua,
-- wow-ui-source `forever` branch): it needs a click, so it runs only from the button's own OnClick,
-- or the Yes of the popup the Confirm Before Deleting option asks first, as Blizzard's own delete
-- popup does. It isn't protected, so a plain button may call it. **Unverified** in game.
local _, ns = ...

local _G, format, min, max, select = _G, string.format, math.min, math.max, select
local C_Container, C_Item, CreateFrame = C_Container, C_Item, CreateFrame
local GetNumLootItems, GetLootSlotType = GetNumLootItems, GetLootSlotType
local GetLootSlotLink, GetLootSlotInfo = GetLootSlotLink, GetLootSlotInfo
local GetCursorInfo, CursorHasItem, ClearCursor = GetCursorInfo, CursorHasItem, ClearCursor
local DeleteCursorItem, InCombatLockdown, GameTooltip = DeleteCursorItem, InCombatLockdown, GameTooltip

local L = ns.L

local module = ns.NewModule("JunkDelete", L.JUNKDELETE_DESC, {
    enabled = false,
    confirm = true,
    place = "corner", -- "corner" (the loot window's top left) or "below" it
    onButton = false,
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
    {
        key = "place", name = L.JUNKDELETE_PLACE, description = L.JUNKDELETE_PLACE_DESC,
        choices = {
            { "corner", L.JUNKDELETE_PLACE_CORNER },
            { "below", L.JUNKDELETE_PLACE_BELOW },
        },
    },
    {
        key = "onButton", name = L.JUNKDELETE_ONBUTTON, description = L.JUNKDELETE_ONBUTTON_DESC,
        shown = function(db)
            return db.place == "below"
        end,
    },
    ns.ChatOption(L.JUNKDELETE_CHAT_DESC),
}

-- MAX_WIDTH is Item on the Button's; the short label is kept to the loot window's width, or
-- LOOT_WIDTH when that can't be read.
local MIN_WIDTH, MAX_WIDTH, LOOT_WIDTH, PADDING = 100, 320, 200, 40

-- Blizzard's red square button with a delete mark (the character list's, buttonArtKit
-- "128-redbutton-delete"), in Forever's own gold-edged drawing of it where the client has that.
local ART = "128-redbutton-delete"
local CORNER_SIZE = 24 -- the close button's, when its own size can't be read
-- How the corner button differs from a plain mirror of the close button, so the two look alike
-- (see placeCorner): how much bigger its frame is, and how far right and up it sits.
local FIT, NUDGE_X, NUDGE_Y = 1.08, 3.6, 2.3

local button -- ours, below the loot window, made the first time it's needed
local corner -- ours, in the loot window's top left corner, made with it
local target -- { bag, slot, link, count, itemID, value, name }: the stack the button names, or nil

local function poor()
    return Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0
end

-- Whether the bags take the item in a loot slot: true or false, or nil when the game doesn't
-- say what it is yet. By the item, not by a count of free slots: a stack of the same thing with
-- room takes it with no slot free, a quiver or a herb bag takes only its own kind, and the
-- reagent bag takes a reagent (ns.Bags.Room).
local function lootFits(index)
    local link = GetLootSlotLink and GetLootSlotLink(index)
    if not ns.IsText(link, true) then
        return nil
    end
    local itemID = C_Item.GetItemInfoInstant(link)
    -- Probe: GetItemMaxStackSizeByID is Mainline's; GetItemInfo's eighth value is the same.
    local stack = itemID and (C_Item.GetItemMaxStackSizeByID and C_Item.GetItemMaxStackSizeByID(itemID)
        or select(8, C_Item.GetItemInfo(link)))
    if not (itemID and ns.IsNumber(stack) and stack > 0) then
        return nil
    end
    local quantity = GetLootSlotInfo and select(3, GetLootSlotInfo(index))
    if not (ns.IsNumber(quantity) and quantity > 0) then
        quantity = 1
    end
    return ns.Bags.Room(itemID, stack) >= quantity
end

-- Whether the loot window still holds an item the bags won't take, which is when deleting junk
-- helps. Money and currency need no room. An item the game doesn't name yet goes by whether any
-- slot is free at all. The button showed with free slots when this only asked whether the
-- ordinary bags had none (reported 2026-11-27): they can have none while the loot still fits.
local function lootNeedsRoom()
    local kind = Enum and Enum.LootSlotType and Enum.LootSlotType.Item
    local count = GetNumLootItems()
    if not (kind and ns.IsNumber(count)) then
        return false
    end
    local full -- no free slot in the ordinary bags; asked once, and only when it's needed
    for i = 1, count do
        if GetLootSlotType(i) == kind then
            local fits = lootFits(i)
            if fits == nil then
                if full == nil then
                    full = ns.Bags.FreeSlots() == 0
                end
                fits = not full
            end
            if not fits then
                return true
            end
        end
    end
    return false
end

local function wanted()
    local loot = _G.LootFrame
    return module.enabled and loot ~= nil and loot:IsShown() and not InCombatLockdown()
        and not ns.Gamepad.On() and lootNeedsRoom()
end

local function showTooltip(self)
    if not target then
        return
    end
    -- Above the button, so it covers neither the loot window nor the button.
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(target.name)
    -- Item Tooltips' price line: "Sell Price x3:" in white, the whole stack's value at the right.
    local quantity = GRAY_FONT_COLOR:WrapTextInColorCode(format(L.PRICE_QUANTITY, target.count))
    GameTooltip:AddDoubleLine(format(L.PRICE_LINE, L.SELLPRICE_TITLE, quantity), ns.Money(target.value),
        1, 1, 1, 1, 1, 1)
    local green = GREEN_FONT_COLOR
    GameTooltip:AddLine(L.JUNKDELETE_HINT, green.r, green.g, green.b)
    GameTooltip:Show()
end

-- Puts the corner button where the close button is, mirrored: as big on screen, as far in from
-- the window's left edge as the close button is from its right, and level with it. Read from
-- where the close button is on screen each time, since the window places it.
--
-- A plain mirror (the close button's own size, the same distance from the frame's edge) doesn't
-- look like one. Measured on screenshots of this client, pixel by pixel (2026-11-27):
--   - at the same frame size the delete art's button is 29 by 28 pixels where the close art's is
--     32 by 30: it has a wider clear margin in its image. So ours is FIT times the size;
--   - the plain mirror's button began 2 pixels outside the window's left border and 2 below the
--     close button's top, where the close button ends 1 inside the right border: the window's
--     art doesn't sit the same on both sides of its frame. So ours goes NUDGE_X right and
--     NUDGE_Y up, which also takes back what the bigger frame adds to its margins.
-- A nudge of 8 right was 6 pixels too many (in game, 2026-11-27). At 2.7 the two red faces were
-- exact mirrors and the same size, top and bottom on the same rows, but our lit left edge stood
-- a pixel outside the window border's own lit line: one more pixel right (about 0.9 here, a unit
-- being some 1.15 pixels in those screenshots) puts it on that line, as the close button's
-- right edge sits on the border's pixels.
local function placeCorner()
    local loot = _G.LootFrame
    local close = loot and loot.ClosePanelButton
    if not (close and close:IsShown()) then
        return
    end
    -- Its art where that has a place of its own, else its frame: they measured the same here.
    local art = close.GetNormalTexture and close:GetNormalTexture()
    local shown = art and art:GetRight() and art or close
    local scale, closeScale = loot:GetEffectiveScale(), close:GetEffectiveScale()
    local right, top = loot:GetRight(), loot:GetTop()
    local closeRight, closeTop = shown:GetRight(), shown:GetTop()
    local width, height = shown:GetSize()
    if not (scale and scale > 0 and closeScale and right and top and closeRight and closeTop
        and width and width > 0 and height and height > 0) then
        return
    end
    -- The close button's edges and size in the loot window's own units.
    local ratio = closeScale / scale
    corner:SetSize(width * ratio * FIT, height * ratio * FIT)
    corner:ClearAllPoints()
    corner:SetPoint("TOPLEFT", loot, "TOPLEFT", right - closeRight * ratio + NUDGE_X,
        closeTop * ratio - top + NUDGE_Y)
end

local function refresh()
    if not button then
        return
    end
    target = nil
    if wanted() then
        local bag, slot, info, value = ns.Bags.CheapestJunk(ns.Prices.Vendor)
        if bag then
            -- The name in gray, after its icon: the tooltip's title, and the button's face with
            -- Item on the Button on.
            local name = C_Item.GetItemNameByID(info.itemID) or info.hyperlink
            local color = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[poor()]
            if color and color.hex then
                name = color.hex .. name .. "|r"
            end
            if info.iconFileID then
                name = format("|T%s:0|t %s", info.iconFileID, name)
            end
            target = {
                bag = bag, slot = slot, link = info.hyperlink, count = info.stackCount,
                itemID = info.itemID, value = value, name = name,
            }
            local widest = MAX_WIDTH
            if module.db.place ~= "below" then
                widest = MIN_WIDTH -- unseen: the corner button is the one showing
            elseif module.db.onButton then
                button:SetText(format(L.JUNKDELETE_BUTTON, name, ns.Money(value)))
            else
                button:SetText(L.JUNKDELETE_LABEL)
                local lootWidth = _G.LootFrame:GetWidth()
                widest = ns.IsNumber(lootWidth) and lootWidth > MIN_WIDTH and lootWidth or LOOT_WIDTH
            end
            button:SetWidth(min(widest, max(MIN_WIDTH, button:GetTextWidth() + PADDING)))
        end
    end
    local below = module.db.place == "below"
    button:SetShown(target ~= nil and below)
    if target and not below then
        placeCorner()
    end
    corner:SetShown(target ~= nil and not below)
    local owner = GameTooltip:GetOwner()
    if owner == button or owner == corner then
        if target and owner:IsShown() then
            showTooltip(owner)
        else
            GameTooltip:Hide()
        end
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
    corner:Hide()
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

    -- The corner button: the close button's mirror. Placed each time it shows (placeCorner).
    corner = CreateFrame("Button", nil, loot)
    local close = loot.ClosePanelButton
    if close then
        corner:SetFrameLevel(close:GetFrameLevel())
    end
    corner:SetSize(CORNER_SIZE, CORNER_SIZE)
    corner:SetPoint("TOPLEFT", loot, "TOPLEFT", 2, 1)
    local own = ns.Frames.HasAtlas(ART .. "-c60") and "-c60" or ""
    corner:SetNormalAtlas(ART .. own)
    corner:SetPushedAtlas(ART .. "-pressed" .. own)
    corner:SetHighlightAtlas(ART .. "-highlight", "ADD")
    corner:SetScript("OnClick", onClick)
    corner:SetScript("OnEnter", showTooltip)
    corner:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    corner:Hide()
end

local function onLoot()
    build()
    refresh()
end

function module:IsAvailable()
    return DeleteCursorItem ~= nil and C_Container ~= nil and C_Container.PickupContainerItem ~= nil
        and GetNumLootItems ~= nil
end

function module:OnOptionChanged()
    refresh()
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
            corner:Hide()
        end
    end)
    self:On("PLAYER_REGEN_ENABLED", refresh)
    onLoot()
end

function module:OnDisable()
    target = nil
    if button then
        button:Hide()
        corner:Hide()
    end
end
