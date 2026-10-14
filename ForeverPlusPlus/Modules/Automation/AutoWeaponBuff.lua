-- Auto Weapon Buff: right-clicking a sharpening stone, weightstone, oil, poison, or fishing lure in
-- your bags puts it straight onto your weapon instead of waiting for you to click the weapon.
--
-- Forever forbids addons from answering the targeting cursor themselves, so each such item in
-- Blizzard's bags gets a secure overlay (ns.BagClicks) whose right-click uses the item and then the
-- weapon slot through Blizzard's own `target-slot` attribute. Not in combat, when the bags work as
-- Blizzard's.
--
-- Which items count, and which weapons they go on, comes from the table below, since the game only
-- says what an item fits once its cursor is up. Main hand first; the off hand when only it can
-- take the item, when the main hand already has a buff and the off hand doesn't, or when the off
-- hand's buff runs out sooner. When no equipped weapon can take the item (a weightstone with only
-- blades), the right-click says so in red at the top of the screen, like Blizzard's own errors,
-- instead of bringing up a cursor nothing will take.
local _, ns = ...

local C_Item, C_Container, C_PaperDollInfo = C_Item, C_Container, C_PaperDollInfo
local GetInventoryItemID, GetWeaponEnchantInfo = GetInventoryItemID, GetWeaponEnchantInfo
local pairs, select, tostring = pairs, select, tostring

local L = ns.L

local module = ns.NewModule("AutoWeaponBuff", L.AUTOWEAPONBUFF_DESC, {
    enabled = false,
    warnNoFit = true,
    printSteps = false,
})
module.title = L.AUTOWEAPONBUFF_TITLE
module.category = "automation"
module.added = "0.8.0"

module.options = {
    {
        key = "warnNoFit",
        name = L.AUTOWEAPONBUFF_WARN,
        description = L.AUTOWEAPONBUFF_WARN_DESC,
        added = "0.8.2",
    },
    {
        key = "printSteps",
        name = L.AUTOWEAPONBUFF_PRINT,
        description = L.AUTOWEAPONBUFF_PRINT_DESC,
        debug = true,
        section = L.DEBUG_SECTION_LOGGING,
    },
}

local MAINHAND, OFFHAND = 16, 17
local WEAPON, FISHING_POLE = 2, 20 -- Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Fishingpole
local FIST = 13 -- Enum.ItemWeaponSubclass.Unarmed

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
    return ns.BagClicks.IsAvailable() and C_Item and C_Item.GetItemInfoInstant and GetInventoryItemID
        and true or false
end

-- Whether an item of this kind can go on the weapon in this slot: true, false, or nil when we
-- don't know (a stone on a fist weapon).
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
    elseif subclassID == FIST and (kind == "sharp" or kind == "blunt") then
        return nil
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

-- Whether we know neither weapon can take an item of this kind.
local function noneFits(kind)
    return fits(kind, MAINHAND) == false and fits(kind, OFFHAND) == false
end

local function warnNoFit(bag, slot)
    local itemID = C_Container.GetContainerItemID(bag, slot)
    local name = itemID and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    ns.Frames.ErrorMessage(name and L.AUTOWEAPONBUFF_WARN_TEXT:format(name) or L.AUTOWEAPONBUFF_WARN_TEXT_ANY)
end

-- Overlays ------------------------------------------------------------------------------------

-- An overlay for each item with a weapon that takes it, or none when Warn says so.
local function match(itemID)
    local kind = KINDS[itemID]
    if kind and (fits(kind, MAINHAND) or fits(kind, OFFHAND) or module.db.warnNoFit and noneFits(kind)) then
        return kind
    end
end

local function click(overlay, kind, bag, slot, down)
    local target = pickSlot(kind)
    local warn = not target and module.db.warnNoFit and noneFits(kind)
    if target then
        overlay:SetAttribute("type2", "item")
        overlay:SetAttribute("item", bag .. " " .. slot)
    end
    overlay:SetAttribute("target-slot", target)
    if warn and not down then
        warnNoFit(bag, slot)
    end
    if not down and module.db.printSteps then
        ns.Print(L.AUTOWEAPONBUFF_PRINT_LINE:format(tostring(C_Container.GetContainerItemLink(bag, slot)),
            kind, tostring(target)))
    end
    -- A warning takes the click: nothing goes to the bag button, so no cursor comes up.
    return target ~= nil or warn
end

local overlays = ns.BagClicks.New(module, match, click)

function module:OnEnable()
    overlays:Enable()
    self:On("PLAYER_EQUIPMENT_CHANGED", overlays.refresh)
end

function module:OnOptionChanged(key)
    if key == "warnNoFit" then
        overlays:Refresh()
    end
end

function module:OnDisable()
    overlays:Disable()
end
