-- Item Tooltips' crate shopping list: a Waylaid Crates row at the top of the auction house's
-- category list that fills Blizzard's browse list with every item the crates in your bags still
-- need, one row each, the way the Favorites star lists your favorites. A crate's tooltip lists
-- the bundles it takes ("- 6 Bolt of Woolen Cloth"); what's still needed is every crate's bundles
-- added up, less what's already in your bags. Items are found by name, as Waylaid Crate Costs
-- finds them.
--
-- The rows come from C_AuctionHouse.SearchForItemKeys: Blizzard's browse list shows whatever
-- browse results arrive, whoever asked for them. A real category would mean adding to Blizzard's
-- AuctionCategories table, which would taint the auction house, so the row is our own button in
-- the category buttons' art, and the list's scroll box moves down one row to make room for it
-- (put back when the option goes off).
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
local ROW_WIDTH, ROW_HEIGHT = 132, 21 -- Blizzard's category buttons (AuctionCategoryButtonTemplate)

local row -- our Waylaid Crates row
local scrollAnchor -- the category list's scroll box TOPLEFT anchor before we moved it
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
    local wanted, names = {}, {}
    for bag = 0, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local data = info and C_TooltipInfo.GetBagItem(bag, slot)
            local bundles = data and internal.CrateBundles(data)
            if bundles and #bundles > 0 then
                crates = crates + 1
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

-- Gold like Blizzard's categories while there's something to list, gray otherwise.
local function refresh()
    readCrates()
    row:SetNormalFontObject(searchable() and "GameFontNormalSmall" or "GameFontDisableSmall")
end

local function setSelected(selected)
    row.selected = selected
    row.SelectedTexture:SetShown(selected)
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
    -- As the Favorites star does: no Blizzard category selected (which also shows the Buy
    -- display, where the browse list is), then an empty list while the search runs. Probed:
    -- Mainline's frame.
    local frame = _G.AuctionHouseFrame
    local list = frame and frame.CategoriesList
    if list and list.SetSelectedCategory then
        list:SetSelectedCategory(nil)
    end
    local mixin = _G.AuctionHouseFrameMixin
    if frame and frame.TriggerEvent and mixin and mixin.Event and mixin.Event.BrowseSearchStarted then
        frame:TriggerEvent(mixin.Event.BrowseSearchStarted)
    end
    local order = Enum.AuctionHouseSortOrder
    local sorts = order and { { sortOrder = order.Name, reverseSort = false } } or {}
    listed, awaiting = nil, true
    setSelected(true)
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

-- New browse results that aren't ours (a search, favorites, a sort) replace our list.
local function onResultsUpdated()
    if awaiting then
        listed = nil
        addResults(C_AuctionHouse.GetBrowseResults())
    elseif row and row.selected then
        setSelected(false)
    end
end

local function onResultsAdded(_, added)
    if awaiting then
        addResults(added)
    end
end

-- Picking one of Blizzard's categories deselects ours.
local function onCategorySelected()
    if row and row.selected and not awaiting then
        setSelected(false)
    end
end

-- Row -------------------------------------------------------------------------------------------

local function onClick()
    refresh()
    search()
end

local function onEnter(self)
    self.HighlightTexture:Show()
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

local function onLeave(self)
    self.HighlightTexture:Hide()
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
    awaiting = false
    setSelected(false)
end

-- A texture in one of the category button's atlases, sized and placed as Blizzard's top-level
-- category buttons set theirs (AuctionHouseFilterButton_SetUp).
local function texture(layer, atlas, width, height, point, x)
    local tex = row:CreateTexture(nil, layer)
    tex:SetAtlas(atlas, false)
    tex:SetSize(width, height)
    tex:SetPoint(point, x, 0)
    return tex
end

local function makeRow(list)
    row = CreateFrame("Button", nil, list)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    texture("BACKGROUND", "auctionhouse-nav-button", 136, 32, "TOPLEFT", -2)
    row.HighlightTexture = texture("BORDER", "auctionhouse-nav-button-highlight", ROW_WIDTH, ROW_HEIGHT,
        "LEFT", 0)
    row.HighlightTexture:Hide()
    row.SelectedTexture = texture("ARTWORK", "auctionhouse-nav-button-select", ROW_WIDTH, ROW_HEIGHT,
        "LEFT", 0)
    row.SelectedTexture:SetBlendMode("ADD")
    row.SelectedTexture:Hide()
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    text:SetShadowOffset(1, -1)
    row:SetFontString(text)
    row:SetText(L.CRATELIST_CATEGORY)
    row:SetPushedTextOffset(1, -1)
    row:SetScript("OnClick", onClick)
    row:SetScript("OnEnter", onEnter)
    row:SetScript("OnLeave", onLeave)
    row:SetScript("OnShow", onShow)
    row:SetScript("OnHide", onHide)
end

-- The scroll box's TOPLEFT anchor: its index and values, or nil.
local function topLeft(box)
    for i = 1, box:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = box:GetPoint(i)
        if point == "TOPLEFT" then
            return { relativeTo, relativePoint, x, y }
        end
    end
end

-- Our row where the list's first row was, and the list one row lower.
local function setup()
    local frame = _G.AuctionHouseFrame
    local list = frame and frame.CategoriesList
    local box = list and list.ScrollBox
    if not (box and C_AuctionHouse.SearchForItemKeys and C_AuctionHouse.MakeItemKey
        and C_TooltipInfo and C_TooltipInfo.GetBagItem) then
        return
    end
    scrollAnchor = scrollAnchor or topLeft(box)
    if not scrollAnchor then
        return
    end
    if not row then
        makeRow(list)
        module:Hook(list, "SetSelectedCategory", onCategorySelected)
    end
    local anchor = scrollAnchor
    -- The list's view pads its rows 3 from the left.
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", anchor[1], anchor[2], anchor[3] + 3, anchor[4])
    box:SetPoint("TOPLEFT", anchor[1], anchor[2], anchor[3], anchor[4] - ROW_HEIGHT)
    row:Show()
end

local function teardown()
    if row then
        row:Hide()
    end
    local list = _G.AuctionHouseFrame and _G.AuctionHouseFrame.CategoriesList
    local box = list and list.ScrollBox
    if box and scrollAnchor then
        local anchor = scrollAnchor
        box:SetPoint("TOPLEFT", anchor[1], anchor[2], anchor[3], anchor[4])
    end
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
        teardown()
    end,
})
