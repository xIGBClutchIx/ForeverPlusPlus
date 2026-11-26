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

local _G, pairs, ipairs, wipe, strfind, setmetatable = _G, pairs, ipairs, wipe, strfind, setmetatable
local C_Item, C_Spell, GetFileIDFromPath = C_Item, C_Spell, GetFileIDFromPath

local L = ns.L
local ItemButtons = ns.ItemButtons
local Disenchant = ns.Disenchant
local Prices = ns.Prices

local module = ns.NewModule("DisenchantIcons", L.DISENCHANTICONS_DESC, {
    enabled = false,
    enchanter = true, -- only on a character who knows Enchanting
    skipSold = false, -- leave out an item a vendor pays more for than its materials are worth
    icon = "roll", -- a key of ICONS, or "none"; set below to one this client has
    opacity = 100, -- percent, of the icon
    border = "none", -- a key of COLORS: a color for the item's border, or "none"
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

local DISENCHANT = ns.Data.Spell("DISENCHANT")

-- The icons, in the order the dropdown lists them: Blizzard's own marks for disenchanting, as
-- atlases from build 1.60.1.71139's UiTextureAtlasMember (wago.tools, 2026-11-26): the loot roll's
-- Disenchant button (32 by 32) and the world map's Enchanting quest icon (16 by 16). The
-- Disenchant spell's icon, with its border cut off as Blizzard's buff icons, is offered only on a
-- client with neither atlas, so the dropdown is never empty.
local SPELL_ICON = { "spell", L.DISENCHANTICONS_ICON_SPELL, spell = DISENCHANT,
    file = "Interface\\Icons\\INV_Enchant_Disenchant", crop = { 0.08, 0.92, 0.08, 0.92 } }
local ICONS = {
    { "roll", L.DISENCHANTICONS_ICON_ROLL, atlas = "lootroll-toast-icon-disenchant-up" },
    { "rune", L.DISENCHANTICONS_ICON_RUNE, atlas = "worldquest-icon-enchanting" },
}
local ICON_BY_KEY, ICON_CHOICES = {}, {}
for _, icon in ipairs(ICONS) do
    if ns.Frames.HasAtlas(icon.atlas) then -- probe: only the art this client has
        ICON_BY_KEY[icon[1]] = icon
        ICON_CHOICES[#ICON_CHOICES + 1] = { icon[1], icon[2] }
    end
end
if not ICON_CHOICES[1] then
    ICON_BY_KEY.spell = SPELL_ICON
    ICON_CHOICES[1] = { SPELL_ICON[1], SPELL_ICON[2] }
end
module.defaults.icon = ICON_CHOICES[1][1]
ICON_CHOICES[#ICON_CHOICES + 1] = { "none", L.DISENCHANTICONS_ICON_NONE } -- the border alone

-- The border's colors: Blizzard's own quality and text colors. The border is the art Blizzard
-- draws an item's quality with (WhiteIconFrame), drawn over the item's own so it reads as the
-- item's border in another color. Blizzard's border itself is left alone: ours covers it.
local BORDER_FILE = "Interface\\Common\\WhiteIconFrame"
local COLORS = {
    purple = { 0.64, 0.21, 0.93 }, -- epic quality
    blue = { 0, 0.44, 0.87 }, -- rare quality
    green = { 0.12, 1, 0 }, -- uncommon quality
    gold = { 1, 0.82, 0 }, -- NORMAL_FONT_COLOR
    white = { 1, 1, 1 },
}
local hasBorder = not GetFileIDFromPath or GetFileIDFromPath(BORDER_FILE) ~= nil

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
    {
        key = "icon", name = L.DISENCHANTICONS_ICON, description = L.DISENCHANTICONS_ICON_DESC,
        section = SECTION_ICON, choices = ICON_CHOICES,
    },
    {
        key = "opacity", name = L.DISENCHANTICONS_OPACITY, description = L.DISENCHANTICONS_OPACITY_DESC,
        section = SECTION_ICON, min = 10, max = 100, step = 5, format = "%d%%",
        shown = function(db)
            return db.icon ~= "none"
        end,
    },
    {
        key = "border", name = L.DISENCHANTICONS_BORDER, description = L.DISENCHANTICONS_BORDER_DESC,
        section = SECTION_ICON,
        choices = {
            { "none", L.DISENCHANTICONS_BORDER_NONE },
            { "purple", L.DISENCHANTICONS_COLOR_PURPLE },
            { "blue", L.DISENCHANTICONS_COLOR_BLUE },
            { "green", L.DISENCHANTICONS_COLOR_GREEN },
            { "gold", L.DISENCHANTICONS_COLOR_GOLD },
            { "white", L.DISENCHANTICONS_COLOR_WHITE },
        },
        available = function()
            return hasBorder
        end,
        needs = L.SETTINGS_NEEDS_CLIENT,
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

local marks = ItemButtons.Overlays(function(icon)
    return icon:GetParent():CreateTexture(nil, "OVERLAY", nil, 7)
end)

-- The border, one sublevel under the icon mark so the mark sits on it.
local borders = ItemButtons.Overlays(function(icon)
    local border = icon:GetParent():CreateTexture(nil, "OVERLAY", nil, 6)
    border:SetTexture(BORDER_FILE)
    return border
end)

-- The chosen art and opacity on a mark. Kept per mark so a change shows at the next pass.
local styled = setmetatable({}, { __mode = "k" }) -- mark -> the settings it was drawn with

local function style(mark)
    local db = module.db
    local key = db.icon .. "|" .. db.opacity
    if styled[mark] == key then
        return
    end
    styled[mark] = key
    local icon = ICON_BY_KEY[db.icon] or ICON_BY_KEY[module.defaults.icon]
    if icon.atlas then
        mark:SetAtlas(icon.atlas)
        mark:SetTexCoord(0, 1, 0, 1)
    else
        local texture = icon.spell and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(icon.spell)
        mark:SetTexture(texture or icon.file)
        mark:SetTexCoord(icon.crop[1], icon.crop[2], icon.crop[3], icon.crop[4])
    end
    mark:SetAlpha(db.opacity / 100)
end

-- The border in its color, over the item's own quality border (which fills the icon, as ours).
local function placeBorder(border, icon, color)
    border:SetAllPoints(icon)
    border:SetVertexColor(color[1], color[2], color[3])
end

-- Bags, bank, the auction house, loot, and loot rolls ---------------------------------------------

local walk = ItemButtons.Walk(module, function(icon, link, place, a)
    if place == "auction" then
        -- Whether it disenchants is the item's, whatever its random suffix.
        link = link and a and "item:" .. a
    end
    local db = module.db
    local can = link and disenchantable(link) or false
    local mark = marks:Set(icon, can and db.icon ~= "none")
    if mark then
        style(mark)
        ItemButtons.PlaceMark(mark, icon, db)
    end
    local color = hasBorder and COLORS[db.border]
    local border = borders:Set(icon, can and color and true or false)
    if border then
        placeBorder(border, icon, color)
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
    borders:HideAll()
end

function module:OnOptionChanged()
    if self.enabled then
        refresh()
    end
end
