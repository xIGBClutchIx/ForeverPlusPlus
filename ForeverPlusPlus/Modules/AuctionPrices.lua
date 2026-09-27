-- Auction Prices: scans the auction house when it opens and shows the lowest buyout in item
-- tooltips, under the sell price. Like the sell price, it counts the stack (Shift for one), or
-- the other way round.
--
-- The scan is an empty browse search paged to the end, the same one Auctionator's default scan
-- uses on Forever. C_AuctionHouse.ReplicateItems is in the client too, but it's unproven here,
-- and Auctionator leaves it off by default. Browse results give the lowest unit price per item.
local _, ns = ...

local ipairs, format, time, floor = ipairs, string.format, time, math.floor
local C_AuctionHouse, C_Timer = C_AuctionHouse, C_Timer
local GetRealmName, UnitFactionGroup = GetRealmName, UnitFactionGroup
local CreateFrame, pcall = CreateFrame, pcall
local StaticPopupDialogs, StaticPopup_Show, YES, NO = StaticPopupDialogs, StaticPopup_Show, YES, NO

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local SCAN_INTERVAL = 15 * 60 -- seconds between automatic scans, as Auctionator waits

local module = ns.NewModule("AuctionPrices", L.AUCTIONPRICES_DESC, ItemTooltip.PriceDefaults({
    enabled = true,
    scanOnOpen = true,
    chat = true,
    -- Per auction house ("Realm-Faction"): { scannedAt = time(), prices = { [itemID] = copper } }.
    -- Data, not a setting: it isn't in module.options.
    houses = {},
}, "gold"))
module.title = L.AUCTIONPRICES_TITLE

-- The price line first, then scanning, with the Reset button (module.actions) under it.
module.options = ItemTooltip.PriceOptions({
    {
        key = "scanOnOpen",
        name = L.AUCTIONPRICES_SCAN_ON_OPEN,
        description = L.AUCTIONPRICES_SCAN_ON_OPEN_DESC,
        section = L.AUCTIONPRICES_SECTION_SCANNING,
    },
    ns.ChatOption(L.AUCTIONPRICES_CHAT_DESC, L.AUCTIONPRICES_SECTION_SCANNING),
}, L.AUCTIONPRICES_SECTION_TOOLTIP)

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

-- Indicator ----------------------------------------------------------------------------------
-- A spinner and a line of text in the auction house's title bar while a scan runs, then
-- "Prices updated" for a few seconds. Our own frame, parented to Blizzard's window.

local indicator, hideTimer

local function getIndicator()
    local parent = _G.AuctionHouseFrame
    if not parent then
        return nil
    end
    if not indicator then
        indicator = CreateFrame("Frame", nil, parent)
        indicator:SetSize(1, 20)
        indicator:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -1)
        -- Above the window's border and title art, which are child frames of their own.
        indicator:SetFrameStrata("HIGH")
        indicator.text = indicator:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        indicator.text:SetPoint("RIGHT")
        -- Probe: LoadingSpinnerTemplate is Mainline SharedXML; without it, only the text shows.
        local ok, spinner = pcall(CreateFrame, "Frame", nil, indicator, "LoadingSpinnerTemplate")
        if ok and spinner then
            spinner:SetSize(20, 20)
            spinner:SetPoint("RIGHT", indicator.text, "LEFT", -2, 0)
            indicator.spinner = spinner
        end
    end
    return indicator
end

local function showIndicator(text, busy)
    local frame = getIndicator()
    if not frame then
        if not busy then
            module:Print(text) -- no auction house window to show it on
        end
        return
    end
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
    frame.text:SetText(text)
    if frame.spinner then
        frame.spinner:SetShown(busy)
    end
    frame:Show()
    if not busy then
        hideTimer = C_Timer.NewTimer(4, function()
            hideTimer = nil
            frame:Hide()
        end)
    end
end

local function hideIndicator()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
    if indicator then
        indicator:Hide()
    end
end

-- Scanning -----------------------------------------------------------------------------------

local scanning = false
local seen, seenCount -- itemIDs priced in this scan, and how many

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
                if not seen[itemID] then
                    seen[itemID] = true
                    seenCount = seenCount + 1
                    prices[itemID] = result.minPrice
                elseif result.minPrice < prices[itemID] then
                    prices[itemID] = result.minPrice
                end
            else
                prices[itemID] = result.minPrice
            end
        end
    end
end

local open = false -- the auction house is open

local function stopScan()
    scanning = false
    seen, seenCount = nil, nil
end

-- Asks for the next page, or finishes once the server has sent everything.
local function nextPage()
    if not scanning then
        return
    end
    if not C_AuctionHouse.HasFullBrowseResults() then
        showIndicator(format(L.AUCTIONPRICES_SCANNING, seenCount), true)
        C_AuctionHouse.RequestMoreBrowseResults()
        return
    end
    local count = seenCount
    house().scannedAt = time()
    stopScan()
    showIndicator(format(L.AUCTIONPRICES_SCANNED, count), false)
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
    if scanning or not open then
        return
    end
    showIndicator(format(L.AUCTIONPRICES_SCANNING, 0), true)
    -- The server drops queries sent too fast; wait until it's ready.
    local ready = C_AuctionHouse.IsThrottledMessageSystemReady
    if ready and not ready() then
        ns.On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
        return
    end
    scanning = true
    seen, seenCount = {}, 0
    C_AuctionHouse.SendBrowseQuery({
        searchString = "", sorts = {}, filters = {}, itemClassFilters = {},
    })
end

-- A moment after opening, so Blizzard's window has set itself up first: scan when it's due, or
-- say how old the prices are.
local function afterShow()
    if not open or scanning then
        return
    end
    local age = time() - house().scannedAt
    if module.db.scanOnOpen and age >= SCAN_INTERVAL then
        startScan()
    elseif house().scannedAt > 0 then
        showIndicator(format(L.AUCTIONPRICES_AGE, floor(age / 60)), false)
    end
end

local function onShow()
    open = true
    C_Timer.After(0.5, afterShow)
end

-- /fpp scan: scan now, whenever the last one was.
local function scanCommand()
    if not module.enabled then
        ns.Print(L.AUCTIONPRICES_IS_OFF)
    elseif not open then
        ns.Print(L.AUCTIONPRICES_NOT_OPEN)
    else
        startScan()
    end
end
ns.AddCommand("scan", "", L.AUCTIONPRICES_COMMAND, scanCommand)

-- Reset: forgets this auction house's prices, after the player confirms in a popup.
local POPUP = "FOREVERPLUSPLUS_RESET_AUCTION_PRICES"

local function resetPrices()
    local data = house()
    data.prices = {}
    data.scannedAt = 0
    ns.Print(L.AUCTIONPRICES_RESET_DONE)
end

local function confirmReset()
    -- Probe: StaticPopup is Blizzard's confirmation dialog; without it, reset straight away.
    if not (StaticPopupDialogs and StaticPopup_Show) then
        resetPrices()
        return
    end
    if not StaticPopupDialogs[POPUP] then
        StaticPopupDialogs[POPUP] = {
            text = L.AUCTIONPRICES_RESET_CONFIRM,
            button1 = YES,
            button2 = NO,
            OnAccept = resetPrices,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show(POPUP)
end
ns.AddCommand("resetprices", "", L.AUCTIONPRICES_RESET_COMMAND, confirmReset)

module.actions = {
    {
        name = L.AUCTIONPRICES_RESET,
        button = L.AUCTIONPRICES_RESET_BUTTON,
        description = L.AUCTIONPRICES_RESET_DESC,
        fn = confirmReset,
    },
}

local function onClosed()
    open = false
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    stopScan() -- prices seen so far are kept; the next visit scans again
    hideIndicator()
end

-- Tooltips -----------------------------------------------------------------------------------

local function addAuctionPrice(tooltip, data)
    local itemID = module.enabled and ItemTooltip.ItemID(data)
    local price = itemID and house().prices[itemID]
    if price then
        ItemTooltip.AddPrice(tooltip, data, L.AUCTIONPRICES_LINE, price, module.db)
    end
end

local hooked = false

function module:OnEnable()
    self:On("AUCTION_HOUSE_SHOW", onShow)
    self:On("AUCTION_HOUSE_CLOSED", onClosed)
    self:On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", onResultsUpdated)
    self:On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", onResultsAdded)
    -- The hook can't be removed; addAuctionPrice checks module.enabled instead.
    if not hooked then
        hooked = true
        ItemTooltip.OnPrices(addAuctionPrice)
    end
end

function module:OnDisable()
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    stopScan()
    hideIndicator()
    open = false
end
