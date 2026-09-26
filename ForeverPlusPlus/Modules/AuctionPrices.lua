-- Auction Prices: scans the auction house when it opens and shows the lowest buyout in item
-- tooltips. Hold Shift over a stack to see the price of the whole stack too.
--
-- The scan is an empty browse search paged to the end, the same one Auctionator's default scan
-- uses on Forever. C_AuctionHouse.ReplicateItems is in the client too, but it's unproven here,
-- and Auctionator leaves it off by default. Browse results give the lowest unit price per item.
local _, ns = ...

local pairs, ipairs, format, time = pairs, ipairs, string.format, time
local C_AuctionHouse, C_Item, C_CurrencyInfo, C_Timer = C_AuctionHouse, C_Item, C_CurrencyInfo, C_Timer
local GetRealmName, UnitFactionGroup, IsShiftKeyDown = GetRealmName, UnitFactionGroup, IsShiftKeyDown
local GetMoneyString, TooltipDataProcessor, Enum, GameTooltip = GetMoneyString, TooltipDataProcessor, Enum, GameTooltip
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR

local L = ns.L

local SCAN_INTERVAL = 15 * 60 -- seconds between automatic scans, as Auctionator waits

local module = ns.NewModule("AuctionPrices", L.AUCTIONPRICES_DESC, {
    enabled = false,
    scanOnOpen = true,
    -- Per auction house ("Realm-Faction"): { scannedAt = time(), prices = { [itemID] = copper } }.
    -- Data, not a setting: it isn't in module.options.
    houses = {},
})
module.title = L.AUCTIONPRICES_TITLE

module.options = {
    {
        key = "scanOnOpen",
        name = L.AUCTIONPRICES_SCAN_ON_OPEN,
        description = L.AUCTIONPRICES_SCAN_ON_OPEN_DESC,
    },
}

local function money(amount)
    -- Probe: GetMoneyString is Mainline FrameXML; the coin text is the fallback.
    if GetMoneyString then
        return GetMoneyString(amount, true)
    end
    return C_CurrencyInfo.GetCoinTextureString(amount)
end

-- The auction house this character sees. Realms share one per faction.
local function house()
    local key = format("%s-%s", GetRealmName(), UnitFactionGroup("player") or "")
    local data = module.db.houses[key]
    if not data then
        data = { scannedAt = 0, prices = {} }
        module.db.houses[key] = data
    end
    return data
end

-- Scanning -----------------------------------------------------------------------------------

local scanning = false
local seen -- itemIDs priced in this scan, to count them

-- Keeps the lowest price from browse results. Any browse (the player's own searches too) updates
-- the prices, so they stay fresh between full scans.
local function addResults(results)
    local prices = house().prices
    for _, result in ipairs(results or {}) do
        local itemID = result.itemKey and result.itemKey.itemID
        if itemID and result.totalQuantity and result.totalQuantity > 0 and result.minPrice
            and result.minPrice > 0 then
            if scanning then
                -- The first price this scan replaces the old one; later ones only lower it,
                -- since one item can come back once per item level or suffix.
                if not seen[itemID] or result.minPrice < prices[itemID] then
                    prices[itemID] = result.minPrice
                end
                seen[itemID] = true
            else
                prices[itemID] = result.minPrice
            end
        end
    end
end

local function stopScan()
    scanning = false
    seen = nil
end

-- Asks for the next page, or finishes once the server has sent everything.
local function nextPage()
    if not scanning then
        return
    end
    if not C_AuctionHouse.HasFullBrowseResults() then
        C_AuctionHouse.RequestMoreBrowseResults()
        return
    end
    local count = 0
    for _ in pairs(seen) do
        count = count + 1
    end
    house().scannedAt = time()
    stopScan()
    ns.Print(format(L.AUCTIONPRICES_SCANNED, count))
end

local function onResultsUpdated()
    addResults(C_AuctionHouse.GetBrowseResults())
    nextPage()
end

local function onResultsAdded(_, added)
    addResults(added)
    nextPage()
end

local startScan

local function onThrottleReady()
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    startScan()
end

function startScan()
    if scanning then
        return
    end
    -- The server drops queries sent too fast; wait until it's ready.
    local ready = C_AuctionHouse.IsThrottledMessageSystemReady
    if ready and not ready() then
        ns.On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
        return
    end
    scanning = true
    seen = {}
    C_AuctionHouse.SendBrowseQuery({
        searchString = "", sorts = {}, filters = {}, itemClassFilters = {},
    })
end

local function onShow()
    if module.db.scanOnOpen and time() - house().scannedAt >= SCAN_INTERVAL then
        -- A moment after opening, so Blizzard's window has set itself up first.
        C_Timer.After(0.5, startScan)
    end
end

local function onClosed()
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    if scanning then
        stopScan() -- prices seen so far are kept; the next visit scans again
    end
end

-- Tooltips -----------------------------------------------------------------------------------

-- How many items the hovered stack holds, or 1 when it can't tell (links, merchants).
local function stackCount(data)
    if data.guid and C_Item.GetItemLocation and C_Item.GetStackCount then
        local location = C_Item.GetItemLocation(data.guid)
        if location and location:IsValid() then
            return C_Item.GetStackCount(location) or 1
        end
    end
    return 1
end

local function onItemTooltip(tooltip, data)
    if not module.enabled or not data or not ns.IsReadable(data.id) or not data.id then
        return
    end
    local price = house().prices[data.id]
    if not price then
        return
    end
    local r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB()
    tooltip:AddDoubleLine(L.AUCTIONPRICES_LINE, money(price), r, g, b, r, g, b)
    local count = IsShiftKeyDown() and stackCount(data) or 1
    if count > 1 then
        tooltip:AddDoubleLine(format(L.AUCTIONPRICES_STACK_LINE, count), money(price * count),
            r, g, b, r, g, b)
    end
end

-- Redraws the item tooltip when Shift goes up or down, so the stack line comes and goes.
local function onModifier(_, key)
    local shift = key == "LSHIFT" or key == "RSHIFT"
    if shift and GameTooltip:IsShown() and GameTooltip.RefreshData then
        GameTooltip:RefreshData()
    end
end

local hooked = false

function module:OnEnable()
    ns.On("AUCTION_HOUSE_SHOW", onShow)
    ns.On("AUCTION_HOUSE_CLOSED", onClosed)
    ns.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", onResultsUpdated)
    ns.On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", onResultsAdded)
    ns.On("MODIFIER_STATE_CHANGED", onModifier)
    -- Post calls can't be removed; onItemTooltip checks module.enabled instead.
    if not hooked then
        hooked = true
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItemTooltip)
    end
end

function module:OnDisable()
    ns.Off("AUCTION_HOUSE_SHOW", onShow)
    ns.Off("AUCTION_HOUSE_CLOSED", onClosed)
    ns.Off("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", onResultsUpdated)
    ns.Off("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", onResultsAdded)
    ns.Off("MODIFIER_STATE_CHANGED", onModifier)
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    stopScan()
end
