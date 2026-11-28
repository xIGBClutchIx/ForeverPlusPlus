-- Item Levels: the level of weapons and armor on their icons, in the color of their quality, in
-- your bags and bank (a bag addon's too), at merchants, in the auction house, and in the loot
-- window and loot rolls, each with its own checkbox. Top left by default, as most item level
-- addons put it, where Upgrade Arrows' arrow also goes (it's off by default; a conflict row says
-- so). Off by default.
--
-- What counts as gear and its level are Lib/Equipment.lua's (`Equipment.ItemLevel`), which the
-- Character Window's item levels read too. No enchant mark here: an item in the bags is rarely
-- enchanted, so nearly every piece would be marked, and a merchant's items never are.
-- Nothing is written onto Blizzard's frames: our own font string sits on the icon.
local _, ns = ...

local _G, wipe = _G, wipe
local C_Item = C_Item

local L = ns.L
local ItemButtons = ns.ItemButtons

local module = ns.NewModule("ItemLevels", L.ITEMLEVELS_DESC, {
    enabled = false,
    corner = "TOPLEFT", -- clear of Appearance Icons (top right) and a stack's count (bottom right)
    padding = 1, -- how far the level sits in from its corner, in pixels
    size = 14, -- the text's height in pixels; Blizzard's number font is 14
    bags = true,
    bank = true,
    merchant = true,
    auction = false, -- its icons are small
    loot = true,
})
module.title = L.ITEMLEVELS_TITLE
module.presets = { developer = { options = { corner = "BOTTOMLEFT" } } }
module.category = "items"
module.added = "1.10.0"

module.options = {
    ItemButtons.CornerOption(L.ITEMLEVELS_CORNER_DESC, nil, {
        -- Other modules' marks on gear in the same corner. Settings reads their settings and shows
        -- these only while that module is on. Already Known marks no gear, so it never overlaps.
        conflicts = {
            {
                module = "UpgradeArrows", key = "corner", text = L.ICONMARK_CONFLICT_ARROW,
                when = function(db, other)
                    return db.corner == other.corner
                end,
            },
            {
                module = "UpgradeArrows", key = "downCorner", text = L.ICONMARK_CONFLICT_DOWN,
                when = function(db, other)
                    return other.downgrades and db.corner == other.downCorner and other.downCorner ~= other.corner
                end,
            },
            {
                module = "AppearanceIcons", key = "corner", text = L.ITEMLEVELS_CONFLICT_APPEARANCE,
                when = function(db, other)
                    return db.corner == other.corner
                end,
            },
            {
                module = "DisenchantIcons", key = "corner", text = L.ITEMLEVELS_CONFLICT_DISENCHANT,
                when = function(db, other)
                    return db.corner == other.corner
                end,
            },
        },
    }),
    ItemButtons.PaddingOption(),
    ItemButtons.SizeOption(L.ITEMLEVELS_SIZE, L.ITEMLEVELS_SIZE_DESC),
    ItemButtons.PlaceOption("bags", L.ITEMLEVELS_BAGS_DESC),
    ItemButtons.PlaceOption("bank", L.ITEMLEVELS_BANK_DESC),
    ItemButtons.PlaceOption("merchant", L.ITEMLEVELS_MERCHANT_DESC),
    ItemButtons.PlaceOption("auction", L.ITEMLEVELS_AUCTION_DESC),
    ItemButtons.PlaceOption("loot", L.ITEMLEVELS_LOOT_DESC),
}

-- Below this width an icon gets text two pixels smaller: the auction house's list icons.
local SMALL_ICON = 30
local SMALLEST = 8 -- the least a small icon's text shrinks to, the slider's own least

local waiting = {} -- itemID -> true while the game doesn't have the item yet

-- Marks -----------------------------------------------------------------------------------------

-- Blizzard's number font, over the icon and its quality border.
local marks = ItemButtons.Overlays(function(icon)
    local text = icon:GetParent():CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    text:SetDrawLayer("OVERLAY", 7)
    return text
end)

local walk = ItemButtons.Walk(module, function(icon, link)
    local level, quality
    if link then
        level, quality = ns.Equipment.ItemLevel(link)
        if level == nil then
            local itemID = C_Item.GetItemInfoInstant(link)
            if itemID then
                waiting[itemID] = true
            end
        end
    end
    local text = marks:Set(icon, level)
    if not text then
        return
    end
    local width = icon:GetWidth()
    local small = ns.IsNumber(width) and width > 0 and width < SMALL_ICON
    -- Blizzard's number font and its outline, at the player's size.
    local size = module.db.size
    if small and size - 2 >= SMALLEST then
        size = size - 2
    end
    local path, _, flags = text:GetFont()
    if path then
        text:SetFont(path, size, flags)
    end
    local color = ns.Colors.Quality(quality)
    text:SetTextColor(color.r, color.g, color.b)
    text:SetText(level)
    ItemButtons.PlaceInCorner(text, icon, module.db.corner, module.db.padding)
end)

-- Module ----------------------------------------------------------------------------------------

local function refresh()
    walk:Refresh()
end

local refreshSoon = ns.Frames.Coalesce(function()
    if module.enabled then
        refresh()
    end
end, 0.5, module)

-- Item data arrives a little after a window opens; look again once it has, only for an item we
-- couldn't answer for yet, or while a merchant is open, whose links are missing until it loads.
local function onItemInfo(_, itemID)
    local merchant = _G.MerchantFrame
    if not ((itemID and waiting[itemID]) or (merchant and merchant:IsShown())) then
        return
    end
    if itemID then
        waiting[itemID] = nil
    end
    refreshSoon()
end

function module:OnEnable()
    walk:Hook()
    self:On("GET_ITEM_INFO_RECEIVED", onItemInfo)
    refresh()
end

function module:OnDisable()
    walk:Stop()
    marks:HideAll()
    wipe(waiting)
end

function module:OnOptionChanged()
    if self.enabled then
        refresh()
    end
end
