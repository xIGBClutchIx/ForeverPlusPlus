-- Auto Weapon Buff: when you use a sharpening stone, weightstone, oil, poison, or fishing lure, it
-- goes straight onto your weapon instead of waiting for you to click the weapon on the character
-- window. Using the item still takes your own click (from bags, an action button, or /use); this
-- only answers the targeting cursor that follows, with the same PickupInventoryItem call the
-- character window's weapon slot makes when clicked, inside that same click.
--
-- The game decides which weapons the item can go on (C_Item.DoesItemMatch*), so armor kits,
-- scopes, and anything else that can't go on a weapon are left to the cursor as before. Main hand
-- first; the off hand when only it can take the item, when the main hand already has a buff and
-- the off hand doesn't, or when the off hand's buff runs out sooner. A modifier key can't choose
-- the hand: any modified click on a bag item does something else (link, split) and never uses it.
local _, ns = ...

local C_Item, C_Spell, C_Container, C_PaperDollInfo = C_Item, C_Spell, C_Container, C_PaperDollInfo
local GetInventoryItemID, GetActionInfo, GetWeaponEnchantInfo = GetInventoryItemID, GetActionInfo, GetWeaponEnchantInfo
local SpellIsTargeting, CursorHasItem, PickupInventoryItem = SpellIsTargeting, CursorHasItem, PickupInventoryItem
local ItemLocation, pairs, tostring = ItemLocation, pairs, tostring

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

-- The two ways the client says which items a targeting spell can go on, as Blizzard's bags use
-- them to dim the rest: enchanting spells, and spells with an item condition. Which one a weapon
-- buff counts as on Forever is Unverified (the Debug option prints both).
local function canCheck()
    return C_Spell and C_Item and ItemLocation
        and ((C_Spell.TargetSpellIsEnchanting and C_Item.DoesItemMatchTargetEnchantingSpell)
            or (C_Spell.TargetSpellChecksItemCondition and C_Item.DoesItemMatchSpellItemCondition))
end

function module:IsAvailable()
    return canCheck() and SpellIsTargeting and PickupInventoryItem and GetInventoryItemID and true or false
end

local function isEnchanting()
    return C_Spell.TargetSpellIsEnchanting and C_Spell.TargetSpellIsEnchanting() or false
end

local function checksCondition()
    return C_Spell.TargetSpellChecksItemCondition and C_Spell.TargetSpellChecksItemCondition() or false
end

-- Whether the item waiting on the cursor can go on the weapon in this slot.
local function fits(slot)
    if not GetInventoryItemID("player", slot) then
        return false
    end
    local location = ItemLocation:CreateFromEquipmentSlot(slot)
    if isEnchanting() and C_Item.DoesItemMatchTargetEnchantingSpell then
        return C_Item.DoesItemMatchTargetEnchantingSpell(location) and true or false
    elseif checksCondition() and C_Item.DoesItemMatchSpellItemCondition then
        return C_Item.DoesItemMatchSpellItemCondition(location) and true or false
    end
    return false
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

-- The slot to put the item on, or nil when neither weapon can take it.
local function pickSlot(main, off)
    if main and off then
        local mainLeft, offLeft = buffLeft(MAINHAND), buffLeft(OFFHAND)
        if mainLeft and (not offLeft or offLeft < mainLeft) then
            return OFFHAND
        end
        return MAINHAND
    end
    return main and MAINHAND or off and OFFHAND or nil
end

-- Runs right after an item is used, still inside the player's click.
local function afterUse()
    if not SpellIsTargeting() or (CursorHasItem and CursorHasItem()) then
        return
    end
    local main, off = fits(MAINHAND), fits(OFFHAND)
    local slot = pickSlot(main, off)
    if module.db.printSteps then
        ns.Print(L.AUTOWEAPONBUFF_PRINT_LINE:format(tostring(isEnchanting()), tostring(checksCondition()),
            tostring(main), tostring(off), tostring(slot)))
    end
    if slot then
        -- The same call the character window's weapon slot makes when clicked while targeting.
        -- If the weapon already has a buff, the game asks before replacing it.
        PickupInventoryItem(slot)
    end
end

-- An action button only counts when it holds an item, so a spell put there (an enchanter's
-- Enchant Weapon) is never placed for the player.
local function afterAction(action)
    if GetActionInfo(action) == "item" then
        afterUse()
    end
end

function module:OnEnable()
    -- From bags, and from bag addons that use the same call.
    if C_Container and C_Container.UseContainerItem then
        self:Hook(C_Container, "UseContainerItem", afterUse)
    end
    -- From /use, which uses an item by name when no bag slot is given.
    if C_Item and C_Item.UseItemByName then
        self:Hook(C_Item, "UseItemByName", afterUse)
    elseif UseItemByName then
        self:Hook("UseItemByName", afterUse)
    end
    -- From an action button.
    if UseAction and GetActionInfo then
        self:Hook("UseAction", afterAction)
    end
end

-- The hooks stop by themselves (module:Hook).
