-- Disenchant Icons: marks the items you can disenchant with the Disenchant spell's icon in a
-- corner of the item's icon (bottom right by default: gear doesn't stack, so no count sits
-- there), in your bags and bank, in the auction house, and in the loot window and loot rolls,
-- each with its own checkbox. Off by default, and by default only on a character who knows
-- Enchanting.
--
-- "Can be disenchanted" is the game's own rule, from Lib/Disenchant.lua: a green, blue, or purple
-- weapon or armor piece in one of the client's brackets. The few items the game flags as not
-- disenchantable aren't told apart by item info, so the item's tooltip has the last word: its
-- "Cannot be disenchanted" line (ITEM_DISENCHANT_NOT_DISENCHANTABLE), or a "Disenchanting requires
-- Enchanting (225)" line (ITEM_DISENCHANT_MIN_SKILL) in red while the skill is too low. Probe:
-- those strings are Mainline's; whether Forever's tooltips carry either line is unverified, and
-- without them the rule alone decides. The client's tables give no skill a bracket needs
-- (ItemDisenchantLoot's SkillRequired is 0 on every row, build 70888).
-- Nothing is written onto Blizzard's frames: our own texture sits on the icon.
local _, ns = ...

local _G, pairs, wipe, strfind = _G, pairs, wipe, strfind
local C_Item, C_Spell = C_Item, C_Spell

local L = ns.L
local ItemButtons = ns.ItemButtons
local Disenchant = ns.Disenchant
local Prices = ns.Prices

local module = ns.NewModule("DisenchantIcons", L.DISENCHANTICONS_DESC, {
    enabled = false,
    enchanter = true, -- only on a character who knows Enchanting
    skipSold = false, -- leave out an item a vendor pays more for than its materials are worth
    corner = "BOTTOMRIGHT", -- free of Upgrade Arrows (top left), Appearance Icons (top right), Already Known (bottom left)
    size = 18, -- in the bags; other places scale from it
    padding = 1, -- how far the icon sits in from its corner, in pixels
    bags = true,
    bank = true,
    auction = false,
    loot = true,
})
module.title = L.DISENCHANTICONS_TITLE
module.category = "items"
module.added = "1.10.0"

local SECTION_ITEMS, SECTION_ICON = L.DISENCHANTICONS_SECTION_ITEMS, L.DISENCHANTICONS_SECTION_ICON

module.options = {
    {
        key = "enchanter", name = L.DISENCHANTICONS_ENCHANTER, description = L.DISENCHANTICONS_ENCHANTER_DESC,
        section = SECTION_ITEMS,
    },
    {
        key = "skipSold", name = L.DISENCHANTICONS_SKIP_SOLD, description = L.DISENCHANTICONS_SKIP_SOLD_DESC,
        section = SECTION_ITEMS,
        available = function()
            return Prices.Available()
        end,
        needs = L.DISENCHANTICONS_NEEDS_PRICES,
    },
    ItemButtons.CornerOption(L.DISENCHANTICONS_CORNER_DESC, SECTION_ICON, {
        -- Other modules' marks on gear in the same corner. Settings reads their settings and shows
        -- these only while that module is on. Already Known marks no gear, so it never overlaps.
        conflicts = {
            {
                module = "UpgradeArrows", key = "corner", text = L.DISENCHANTICONS_CONFLICT_ARROW,
                when = function(db, other)
                    return db.corner == other.corner
                end,
            },
            {
                module = "UpgradeArrows", key = "downCorner", text = L.DISENCHANTICONS_CONFLICT_DOWN,
                when = function(db, other)
                    return other.downgrades and db.corner == other.downCorner and other.downCorner ~= other.corner
                end,
            },
            {
                module = "AppearanceIcons", key = "corner", text = L.DISENCHANTICONS_CONFLICT_APPEARANCE,
                when = function(db, other)
                    return db.corner == other.corner
                end,
            },
        },
    }),
    ItemButtons.SizeOption(L.DISENCHANTICONS_SIZE, L.DISENCHANTICONS_SIZE_DESC, SECTION_ICON),
    ItemButtons.PaddingOption(SECTION_ICON),
    ItemButtons.PlaceOption("bags", L.DISENCHANTICONS_BAGS_DESC),
    ItemButtons.PlaceOption("bank", L.DISENCHANTICONS_BANK_DESC),
    ItemButtons.PlaceOption("auction", L.DISENCHANTICONS_AUCTION_DESC),
    ItemButtons.PlaceOption("loot", L.DISENCHANTICONS_LOOT_DESC),
}

local DISENCHANT = ns.Data.Spell("DISENCHANT")
local ICON = "Interface\\Icons\\INV_Enchant_Disenchant" -- the spell's icon, should the client not say

-- Does the tooltip allow it ----------------------------------------------------------------------

local knowsEnchanting = false

-- "Disenchanting requires %s (%d)" as a pattern. Probe: the string is the client's.
local minSkill = _G.ITEM_DISENCHANT_MIN_SKILL and ns.Text.FormatPattern(_G.ITEM_DISENCHANT_MIN_SKILL)

-- False when the tooltip says it can't be disenchanted (or, for an enchanter, not with this skill
-- yet), true when it doesn't, nil while the game has no tooltip for the item yet (not cached).
-- Without Enchanting the skill line says nothing of the item, which Only With Enchanting off is for.
local function tooltipAllows(link)
    local lines = ItemButtons.TooltipLines(link)
    if not lines then
        return nil
    end
    local never = _G.ITEM_DISENCHANT_NOT_DISENCHANTABLE
    for i = 2, #lines do -- line 1 is the name
        local text = lines[i].leftText
        if ns.IsText(text) then
            if never and text == never then
                return false
            end
            if knowsEnchanting and minSkill and strfind(text, minSkill) and ItemButtons.IsRedLine(lines[i]) then
                return false
            end
        end
    end
    return true
end

-- The lookups' own row on the Profiler page: reading an item's tooltip is the costly part.
local Profiler = ns.Profiler
local PART_LOOKUP = Profiler.Part(module, L.DISENCHANTICONS_PART_LOOKUP)

-- itemID -> false (can't be disenchanted), or { itemID, outcomes } for one that can, with what it
-- gives (nil while that isn't known yet). Until the skill changes.
local results = {}
local waiting = {} -- itemID -> true while the game has no item info or tooltip for it yet

-- What we know of an item that can be disenchanted, or false.
local function lookup(link)
    local itemID = C_Item.GetItemInfoInstant(link)
    if not itemID then
        return false
    end
    local result = results[itemID]
    if result ~= nil then
        return result
    end
    local _, _, quality, itemLevel, _, _, _, _, equipLoc, _, _, classID = C_Item.GetItemInfo(itemID)
    if not quality then
        waiting[itemID] = true
        return false
    end
    local outcomes, bracket = Disenchant.ForItem(classID, quality, equipLoc, itemLevel)
    if not bracket then
        results[itemID] = false
        return false
    end
    result = { itemID = itemID, outcomes = outcomes }
    local allows = Profiler.Call(PART_LOOKUP, tooltipAllows, link)
    if allows == nil then
        -- The rule says yes; the tooltip may still say no once it loads, so nothing is kept.
        waiting[itemID] = true
        return result
    end
    results[itemID] = allows and result
    return results[itemID]
end

-- Skip Better Sold: whether a vendor pays more than the materials are worth on average at auction
-- prices. Not while what it gives, or a price for each, isn't known: then it's marked.
local function soldBetter(result)
    if not (module.db.skipSold and Prices.Available() and result.outcomes) then
        return false
    end
    local sell = Prices.Vendor(result.itemID)
    if not (sell and sell > 0) then
        return false
    end
    local value, missing = Disenchant.Value(result.outcomes, Prices.Auction)
    return missing == 0 and sell > value
end

local function disenchantable(link)
    if not link then
        return false
    end
    local result = lookup(link)
    return result and not soldBetter(result) or false
end

-- Marks -----------------------------------------------------------------------------------------

local function iconTexture()
    local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(DISENCHANT)
    return texture or ICON
end

local marks = ItemButtons.Overlays(function(icon)
    local mark = icon:GetParent():CreateTexture(nil, "OVERLAY", nil, 7)
    mark:SetTexture(iconTexture())
    mark:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- the icon without its border, as Blizzard's buff icons
    return mark
end)

-- Bags, bank, the auction house, loot, and loot rolls ---------------------------------------------

local walk = ItemButtons.Walk(module, function(icon, link, place, a)
    if place == "auction" then
        -- Whether it disenchants is the item's, whatever its random suffix.
        link = link and a and "item:" .. a
    end
    local mark = marks:Set(icon, link and disenchantable(link))
    if mark then
        ItemButtons.PlaceMark(mark, icon, module.db)
    end
end, {
    places = { "bags", "bank", "auction", "loot" },
    shows = function(place)
        local db = module.db
        return db[place] and (knowsEnchanting or not db.enchanter)
    end,
})

-- Module ----------------------------------------------------------------------------------------

local function refresh()
    walk:Refresh()
end

local forget

-- A tooltip's skill line turns white as the skill rises, so only the "no" answers can be wrong now.
local function forgetNo()
    for itemID, result in pairs(results) do
        if not result then
            results[itemID] = nil
        end
    end
end

-- Item data arrives a little after a window opens, and the skill changes as you craft: look again
-- shortly, once for a burst of events.
local refreshSoon = ns.Frames.Coalesce(function()
    if forget then
        forget = false
        forgetNo()
    end
    if module.enabled then
        refresh()
    end
end, 0.5, module)

local function onSkillChanged()
    knowsEnchanting = ns.Spellbook.IsKnown(DISENCHANT)
    forget = true
    refreshSoon()
end

-- Only items we couldn't answer for yet are worth another look; this fires for every item.
local function onItemInfo(_, itemID)
    if itemID and waiting[itemID] then
        waiting[itemID] = nil
        refreshSoon()
    end
end

-- Registered once; does nothing while the module or Skip Better Sold is off.
Prices.OnChanged(function()
    if module.enabled and module.db.skipSold then
        refreshSoon()
    end
end)

function module:OnEnable()
    knowsEnchanting = ns.Spellbook.IsKnown(DISENCHANT)
    walk:Hook()
    self:On("GET_ITEM_INFO_RECEIVED", onItemInfo)
    self:On("SKILL_LINES_CHANGED", onSkillChanged) -- learning, unlearning, and skill points
    self:On("LEARNED_SPELL_IN_SKILL_LINE", onSkillChanged)
    refresh()
end

function module:OnDisable()
    walk:Stop()
    forget = false
    wipe(results) -- the skill may change while it's off
    wipe(waiting)
    marks:HideAll()
end

function module:OnOptionChanged()
    if self.enabled then
        refresh()
    end
end
