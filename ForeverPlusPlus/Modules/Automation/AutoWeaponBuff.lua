-- Auto Weapon Buff: right-clicking a sharpening stone, weightstone, oil, poison, or fishing lure in
-- your bags puts it straight onto your weapon instead of waiting for you to click the weapon.
--
-- Forever forbids addons from answering the targeting cursor themselves (PickupInventoryItem is
-- ADDON_ACTION_FORBIDDEN there), so this lays an invisible secure item button over each such
-- item in Blizzard's bags. Its right-click uses the item and then the weapon slot through
-- Blizzard's own `target-slot` attribute; every other click, drag, and the tooltip go through to
-- the bag slot as before. Secure buttons can't be placed in combat, so the overlays leave when
-- combat starts and the bags work as Blizzard's until it ends. Bag addons that replace Blizzard's
-- bags get no overlays.
--
-- Which items count, and which weapons they go on, comes from the table below, since the game only
-- says what an item fits once its cursor is up. Main hand first; the off hand when only it can
-- take the item, when the main hand already has a buff and the off hand doesn't, or when the off
-- hand's buff runs out sooner.
local _, ns = ...

local C_Item, C_Container, C_PaperDollInfo, C_Timer = C_Item, C_Container, C_PaperDollInfo, C_Timer
local GetInventoryItemID, GetWeaponEnchantInfo = GetInventoryItemID, GetWeaponEnchantInfo
local CreateFrame, InCombatLockdown, IsModifierKeyDown = CreateFrame, InCombatLockdown, IsModifierKeyDown
local GameTooltip, UIParent, pairs, select, tostring, _G = GameTooltip, UIParent, pairs, select, tostring, _G
local tremove = table.remove

local L = ns.L

local module = ns.NewModule("AutoWeaponBuff", L.AUTOWEAPONBUFF_DESC, {
    enabled = false,
    printSteps = false,
})
module.title = L.AUTOWEAPONBUFF_TITLE
module.category = "automation"
module.added = "0.8.0"

module.options = {
    {
        key = "printSteps",
        name = L.AUTOWEAPONBUFF_PRINT,
        description = L.AUTOWEAPONBUFF_PRINT_DESC,
        debug = true,
    },
}

local MAINHAND, OFFHAND = 16, 17
local WEAPON, FISHING_POLE = 2, 20 -- Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Fishingpole

-- Weapon subclasses a sharpening stone ("sharp") or weightstone ("blunt") goes on. Fist weapons
-- are in neither: which stone they take is Unverified, so they're left to the cursor.
local SHARP = { [0] = true, [1] = true, [6] = true, [7] = true, [8] = true, [15] = true }
local BLUNT = { [4] = true, [5] = true, [10] = true }

-- Item ID to the weapons it goes on: "sharp", "blunt", "melee" (oils and poisons, any weapon but
-- a fishing pole), or "pole" (fishing lures).
local KINDS = {}
local function add(kind, ...)
    for i = 1, select("#", ...) do
        KINDS[select(i, ...)] = kind
    end
end
-- Sharpening stones: Rough, Coarse, Heavy, Solid, Dense, Elemental, Consecrated.
add("sharp", 2862, 2863, 2871, 7964, 12404, 18262, 23122)
-- Weightstones: Rough, Coarse, Heavy, Solid, Dense.
add("blunt", 3239, 3240, 3241, 7965, 12643)
-- Wizard and mana oils, Blessed Wizard Oil, Shadow Oil, Frost Oil.
add("melee", 20744, 20746, 20750, 20749, 20745, 20747, 20748, 23123, 3824, 3829)
-- Poisons: Instant I-VI, Deadly I-V, Crippling I-II, Mind-numbing I-III, Wound I-IV.
add("melee", 6947, 6949, 6950, 8926, 8927, 8928, 2892, 2893, 8984, 8985, 20844, 3775, 3776,
    5237, 6951, 9186, 10918, 10920, 10921, 10922)
-- Lures: Shiny Bauble, Nightcrawlers, Bright Baubles, Aquadynamic Fish Attractor, Flesh Eating
-- Worm, Aquadynamic Fish Lens.
add("pole", 6529, 6530, 6532, 6533, 7307, 6811)

function module:IsAvailable()
    return C_Container and C_Container.GetContainerItemID and C_Container.PickupContainerItem
        and C_Item and C_Item.GetItemInfoInstant and GetInventoryItemID and _G.ContainerFrame1
        and true or false
end

-- Whether an item of this kind can go on the weapon in this slot.
local function fits(kind, slot)
    local itemID = GetInventoryItemID("player", slot)
    if not itemID then
        return false
    end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    if classID ~= WEAPON then
        return false
    end
    if kind == "pole" then
        return slot == MAINHAND and subclassID == FISHING_POLE
    elseif subclassID == FISHING_POLE then
        return false
    elseif kind == "sharp" then
        return SHARP[subclassID] or false
    elseif kind == "blunt" then
        return BLUNT[subclassID] or false
    end
    return true
end

-- Milliseconds left on the slot's temporary buff, or nil when it has none.
local function buffLeft(slot)
    local left
    if C_Item.GetWeaponEnchantInfo then
        -- Forever's buff frame reads it this way: a list per weapon slot, 0 for the main hand.
        local enchants = C_Item.GetWeaponEnchantInfo(slot - MAINHAND)
        for _, enchant in pairs(enchants or {}) do
            if enchant.hasEnchant then
                local timeLeft = enchant.timeLeft or 0
                if not ns.IsReadable(timeLeft) then
                    return 0 -- there is a buff, but not how long it has
                end
                if not left or timeLeft < left then
                    left = timeLeft
                end
            end
        end
    elseif C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo then
        local info = C_PaperDollInfo.GetTemporaryEnchantmentInfo(slot)
        left = info and (info.remainingTimeMs or 0)
    elseif GetWeaponEnchantInfo then
        local hasMain, mainLeft, _, _, hasOff, offLeft = GetWeaponEnchantInfo()
        if slot == MAINHAND then
            left = hasMain and (mainLeft or 0) or nil
        else
            left = hasOff and (offLeft or 0) or nil
        end
    end
    if left ~= nil and not ns.IsReadable(left) then
        return 0 -- there is a buff, but not how long it has
    end
    return left
end

-- The slot to put an item of this kind on, or nil when neither weapon can take it.
local function pickSlot(kind)
    local main, off = fits(kind, MAINHAND), fits(kind, OFFHAND)
    if main and off then
        local mainLeft, offLeft = buffLeft(MAINHAND), buffLeft(OFFHAND)
        if mainLeft and (not offLeft or offLeft < mainLeft) then
            return OFFHAND
        end
        return MAINHAND
    end
    return main and MAINHAND or off and OFFHAND or nil
end

-- A right-click in the bags means something else while one of these is open (sell, deposit,
-- attach, trade, auction), so it goes to Blizzard's button then.
local function busy()
    local frames = { _G.MerchantFrame, _G.BankFrame, _G.SendMailFrame, _G.TradeFrame, _G.AuctionHouseFrame }
    for i = 1, 5 do
        if frames[i] and frames[i]:IsShown() then
            return true
        end
    end
    return false
end

-- Overlays ------------------------------------------------------------------------------------

local ABOVE = { BACKGROUND = "LOW", LOW = "MEDIUM", MEDIUM = "HIGH", HIGH = "DIALOG" }

local active, spare = {}, {}
local info = {} -- overlay -> { bag, slot, button, kind, handled }

-- Clicks come on both press and release (the secure template acts on whichever the client's
-- ActionButtonUseKeyDown setting says); everything is worked out again for each.
local function onPreClick(self, mouseButton, down)
    local data = info[self]
    local slot
    if not InCombatLockdown() and mouseButton == "RightButton" and not IsModifierKeyDown() and not busy() then
        slot = pickSlot(data.kind)
    end
    data.handled = slot ~= nil
    if not InCombatLockdown() then
        self:SetAttribute("type2", slot and "item" or nil)
        self:SetAttribute("target-slot", slot)
    end
    if mouseButton == "RightButton" and not down and module.db.printSteps then
        ns.Print(L.AUTOWEAPONBUFF_PRINT_LINE:format(tostring(C_Container.GetContainerItemLink(data.bag, data.slot)),
            data.kind, tostring(slot)))
    end
end

-- Anything the secure click didn't do goes to Blizzard's bag button, as if it had been clicked,
-- once, on release like Blizzard's.
local function onPostClick(self, mouseButton, down)
    local data = info[self]
    if not down and not data.handled then
        data.button:Click(mouseButton)
    end
end

local function onDrag(self)
    local data = info[self]
    C_Container.PickupContainerItem(data.bag, data.slot)
end

local function onEnter(self)
    local data = info[self]
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    if ContainerFrameItemButton_CalculateItemTooltipAnchors then
        ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
    else
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    end
    GameTooltip:SetBagItem(data.bag, data.slot)
    GameTooltip:Show()
end

local function onLeave(self)
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end

local function newOverlay()
    local overlay = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    overlay:RegisterForClicks("AnyUp", "AnyDown")
    overlay:RegisterForDrag("LeftButton")
    overlay:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    overlay:SetScript("PreClick", onPreClick)
    overlay:SetScript("PostClick", onPostClick)
    overlay:SetScript("OnDragStart", onDrag)
    overlay:SetScript("OnReceiveDrag", onDrag)
    overlay:SetScript("OnEnter", onEnter)
    overlay:SetScript("OnLeave", onLeave)
    info[overlay] = {}
    return overlay
end

-- Takes every overlay away. Only out of combat (or at PLAYER_REGEN_DISABLED, just before it).
local function clear()
    for i = #active, 1, -1 do
        local overlay = active[i]
        overlay:Hide()
        overlay:ClearAllPoints()
        active[i] = nil
        spare[#spare + 1] = overlay
    end
end

local function place(button, bag, slot, kind)
    local overlay = tremove(spare) or newOverlay()
    local data = info[overlay]
    data.bag, data.slot, data.button, data.kind, data.handled = bag, slot, button, kind, false
    overlay:SetAttribute("item", bag .. " " .. slot)
    overlay:SetAttribute("type2", "item")
    -- A strata above the bag's: bags are top-level frames, and raising one when it's clicked or
    -- opened lifts its buttons over anything at their own strata.
    overlay:SetFrameStrata(ABOVE[button:GetFrameStrata()] or "DIALOG")
    overlay:SetAllPoints(button)
    overlay:Show()
    active[#active + 1] = overlay
end

local function containerFrames()
    local frames = {}
    if ContainerFrameCombinedBags then
        frames[1] = ContainerFrameCombinedBags
    end
    for i = 1, NUM_CONTAINER_FRAMES or 13 do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            frames[#frames + 1] = frame
        end
    end
    return frames
end

local function refresh()
    if InCombatLockdown() then
        return
    end
    clear()
    if not module.enabled then
        return
    end
    for _, frame in pairs(containerFrames()) do
        if frame:IsShown() and frame.EnumerateValidItems then
            for _, button in frame:EnumerateValidItems() do
                if button:IsShown() then
                    local bag, slot = button:GetBagID(), button:GetID()
                    local kind = KINDS[C_Container.GetContainerItemID(bag, slot)]
                    if kind and (fits(kind, MAINHAND) or fits(kind, OFFHAND)) then
                        place(button, bag, slot, kind)
                    end
                end
            end
        end
    end
end

-- Bags call UpdateItems once per bag, so many changes in one frame refresh once.
local pending = false
local function schedule()
    if pending then
        return
    end
    pending = true
    C_Timer.After(0, function()
        pending = false
        refresh()
    end)
end

function module:OnEnable()
    for _, frame in pairs(containerFrames()) do
        if frame.UpdateItems then
            self:Hook(frame, "UpdateItems", schedule)
        end
        self:HookScript(frame, "OnShow", schedule)
        self:HookScript(frame, "OnHide", schedule)
    end
    self:On("BAG_UPDATE_DELAYED", schedule)
    self:On("PLAYER_EQUIPMENT_CHANGED", schedule)
    self:On("PLAYER_REGEN_ENABLED", schedule)
    -- Fires just before combat lockdown starts, the last moment secure buttons can move.
    self:On("PLAYER_REGEN_DISABLED", clear)
    schedule()
end

function module:OnDisable()
    ns.AfterCombat(clear)
end
