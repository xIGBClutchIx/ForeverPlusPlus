-- Item Tooltips' crate shopping list: a crate button beside the auction house's Favorites star
-- that fills Blizzard's browse list with every item the Waylaid Crates in your bags still need,
-- one row each, the way the star lists your favorites. A crate's tooltip lists the bundles it
-- takes ("- 6 Bolt of Woolen Cloth"); what's still needed is every crate's bundles added up, less
-- what's already in your bags. Items are found by name, as Waylaid Crate Costs finds them.
--
-- The rows come from C_AuctionHouse.SearchForItemKeys: Blizzard's browse list shows whatever
-- browse results arrive, whoever asked for them. A category in Blizzard's list would mean adding
-- to its AuctionCategories table, which would taint the auction house, so it's our own button.
local _, ns = ...

local _G, ipairs, pairs, sort, format, wipe = _G, ipairs, pairs, table.sort, string.format, wipe
local CreateFrame, GameTooltip, Enum = CreateFrame, GameTooltip, Enum
local C_Container, C_Item, C_TooltipInfo, C_AuctionHouse = C_Container, C_Item, C_TooltipInfo, C_AuctionHouse
local GRAY_FONT_COLOR, HIGHLIGHT_FONT_COLOR, GREEN_FONT_COLOR = GRAY_FONT_COLOR, HIGHLIGHT_FONT_COLOR,
    GREEN_FONT_COLOR

local L = ns.L

local module = ns.modules.ItemTooltips
local internal = module.internal

local LAST_BAG = 5 -- backpack, four bags, and the reagent bag
local CRATE_ICON = "Interface\\Icons\\INV_Crate_01" -- until a crate in the bags gives its own

local button
local crates = 0 -- crates in the bags when last read
local needs = {} -- what they still need, by name: { name, count, itemID? }
local listed -- itemIDs our last search found auctions for, or nil before it has answered
local awaiting = false -- our search's results haven't all come in yet

-- Needs -----------------------------------------------------------------------------------------

local function byName(a, b)
    return a.name < b.name
end

-- Reads every crate in the bags.
local function readCrates()
    wipe(needs)
    crates = 0
    local wanted, names, icon = {}, {}, nil
    for bag = 0, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local data = info and C_TooltipInfo.GetBagItem(bag, slot)
            local bundles = data and internal.CrateBundles(data)
            if bundles and #bundles > 0 then
                crates = crates + 1
                icon = icon or info.iconFileID
                for _, bundle in ipairs(bundles) do
                    local count, name = bundle[1], bundle[2]
                    if not wanted[name] then
                        names[#names + 1] = name
                    end
                    wanted[name] = (wanted[name] or 0) + count
                end
            end
        end
    end
    for _, name in ipairs(names) do
        local itemID = internal.ItemByName(name)
        local still = wanted[name] - (itemID and C_Item.GetItemCount(itemID) or 0)
        if still > 0 then
            needs[#needs + 1] = { name = name, count = still, itemID = itemID }
        end
    end
    sort(needs, byName)
    if button then
        button:SetIcon(icon or CRATE_ICON)
    end
end

-- Whether any need can be searched for.
local function searchable()
    for _, need in ipairs(needs) do
        if need.itemID then
            return true
        end
    end
    return false
end

-- Enabled while there's something to list, desaturated otherwise, like the Favorites star.
local function refresh()
    readCrates()
    local enabled = searchable()
    button:SetEnabled(enabled)
    button.Icon:SetDesaturated(not enabled)
end

-- Searching -------------------------------------------------------------------------------------

local onThrottleReady

local function search()
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    local ready = C_AuctionHouse.IsThrottledMessageSystemReady
    if ready and not ready() then
        ns.On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
        return
    end
    local keys = {}
    for _, need in ipairs(needs) do
        if need.itemID then
            keys[#keys + 1] = C_AuctionHouse.MakeItemKey(need.itemID)
        end
    end
    if #keys == 0 then
        return
    end
    -- The browse list only shows on the Buy display, not an item's own listings. Then an empty
    -- list while the search runs, as the Favorites star does. Probed: Mainline's frame.
    local frame, modes = _G.AuctionHouseFrame, _G.AuctionHouseFrameDisplayMode
    if frame and modes and frame.GetDisplayMode and frame:GetDisplayMode() ~= modes.Buy then
        frame:SetDisplayMode(modes.Buy)
    end
    local mixin = _G.AuctionHouseFrameMixin
    if frame and frame.TriggerEvent and mixin and mixin.Event and mixin.Event.BrowseSearchStarted then
        frame:TriggerEvent(mixin.Event.BrowseSearchStarted)
    end
    local order = Enum.AuctionHouseSortOrder
    local sorts = order and { { sortOrder = order.Name, reverseSort = false } } or {}
    listed, awaiting = nil, true
    C_AuctionHouse.SearchForItemKeys(keys, sorts)
end

function onThrottleReady()
    search()
end

-- Notes which items our search found auctions for, so the tooltip can say which have none.
local function addResults(results)
    listed = listed or {}
    for _, result in ipairs(results or {}) do
        local itemID = result.itemKey and result.itemKey.itemID
        if itemID then
            listed[itemID] = true
        end
    end
    awaiting = not C_AuctionHouse.HasFullBrowseResults()
end

local function onResultsUpdated()
    if awaiting then
        listed = nil
        addResults(C_AuctionHouse.GetBrowseResults())
    end
end

local function onResultsAdded(_, added)
    if awaiting then
        addResults(added)
    end
end

-- Button ----------------------------------------------------------------------------------------

local function onClick()
    refresh()
    search()
end

local function onEnter(self)
    refresh()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.CRATELIST_TITLE, HIGHLIGHT_FONT_COLOR:GetRGB())
    if crates == 0 then
        GameTooltip:AddLine(L.CRATELIST_NO_CRATES, GRAY_FONT_COLOR:GetRGB())
    elseif #needs == 0 then
        GameTooltip:AddLine(L.CRATELIST_DONE, GRAY_FONT_COLOR:GetRGB())
    end
    local wr, wg, wb = HIGHLIGHT_FONT_COLOR:GetRGB()
    local gr, gg, gb = GRAY_FONT_COLOR:GetRGB()
    for _, need in ipairs(needs) do
        local count = format("%d", need.count)
        if not need.itemID then
            GameTooltip:AddDoubleLine(need.name, L.CRATELIST_NOT_FOUND, gr, gg, gb, gr, gg, gb)
        elseif listed and not awaiting and not listed[need.itemID] then
            GameTooltip:AddDoubleLine(need.name, format("%s  %s", count,
                GRAY_FONT_COLOR:WrapTextInColorCode(L.CRATELIST_NONE_LISTED)), wr, wg, wb, wr, wg, wb)
        else
            GameTooltip:AddDoubleLine(need.name, count, wr, wg, wb, wr, wg, wb)
        end
    end
    if searchable() then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.CRATELIST_HINT, GREEN_FONT_COLOR:GetRGB())
    end
    GameTooltip:Show()
end

local function onLeave()
    GameTooltip:Hide()
end

-- Bags change while the auction house is open (a purchase lands): read the crates again.
local function onShow()
    refresh()
    ns.On("BAG_UPDATE_DELAYED", refresh)
end

local function onHide()
    ns.Off("BAG_UPDATE_DELAYED", refresh)
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
end

-- Our own square icon button, Blizzard's template for the Favorites star, just left of the star
-- on the search bar, so it shows on the Buy tab with it.
local function setup()
    local bar = _G.AuctionHouseFrame and _G.AuctionHouseFrame.SearchBar
    local star = bar and bar.FavoritesSearchButton
    if not (star and C_AuctionHouse.SearchForItemKeys and C_AuctionHouse.MakeItemKey
        and C_TooltipInfo and C_TooltipInfo.GetBagItem) then
        return
    end
    if not button then
        button = CreateFrame("Button", nil, bar, "SquareIconButtonTemplate")
        button:SetPoint("RIGHT", star, "LEFT", -2, 0)
        button:SetMotionScriptsWhileDisabled(true)
        button:SetScript("OnClick", onClick)
        button:SetScript("OnEnter", onEnter)
        button:SetScript("OnLeave", onLeave)
        button:SetScript("OnShow", onShow)
        button:SetScript("OnHide", onHide)
        button:SetIcon(CRATE_ICON)
    end
    button:Show()
end

local events = {
    AUCTION_HOUSE_BROWSE_RESULTS_UPDATED = onResultsUpdated,
    AUCTION_HOUSE_BROWSE_RESULTS_ADDED = onResultsAdded,
}

internal.AddPart("crateList", {
    requires = "auction",
    enable = function()
        for event, fn in pairs(events) do
            ns.On(event, fn)
        end
        ns.AddOns.WhenLoaded("Blizzard_AuctionHouseUI", setup)
    end,
    disable = function()
        for event, fn in pairs(events) do
            ns.Off(event, fn)
        end
        ns.AddOns.Cancel("Blizzard_AuctionHouseUI", setup)
        listed, awaiting = nil, false
        if button then
            button:Hide()
        end
    end,
})
