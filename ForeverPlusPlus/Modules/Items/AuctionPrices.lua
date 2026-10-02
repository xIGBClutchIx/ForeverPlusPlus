-- Auction Prices: scans the auction house when it opens and shows the lowest buyout in item
-- tooltips, under the sell price. Like the sell price, it counts the stack (Shift for one), or
-- the other way round. In the professions window, it adds up what a recipe's reagents cost
-- against what the crafted items are worth.
--
-- The scan is an empty browse search paged to the end, the same one Auctionator's default scan
-- uses on Forever. C_AuctionHouse.ReplicateItems is in the client too, but it's unproven here,
-- and Auctionator leaves it off by default. Browse results give the lowest unit price per item.
local _, ns = ...

local ipairs, format, time, floor = ipairs, string.format, time, math.floor
local C_AuctionHouse, C_Timer, GetTime = C_AuctionHouse, C_Timer, GetTime
local GetRealmName, UnitFactionGroup = GetRealmName, UnitFactionGroup
local CreateFrame, pcall, type, hooksecurefunc = CreateFrame, pcall, type, hooksecurefunc
local select, tostring, C_Item, C_TradeSkillUI, Enum = select, tostring, C_Item, C_TradeSkillUI, Enum

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local SCAN_INTERVAL = 15 * 60 -- seconds between automatic scans, as Auctionator waits

local module = ns.NewModule("AuctionPrices", L.AUCTIONPRICES_DESC, ItemTooltip.PriceDefaults({
    enabled = true,
    scanOnOpen = true,
    scanAge = "right", -- "right", "inline" (like the price line's alignment), or "off"
    scanAgeColor = "age", -- "age" (green when fresh to red when old), "gray", "white", or "gold"
    scanAgeRedHours = 12, -- hours old at which "age" is fully red
    chat = true,
    crafting = true, -- costs, value, and profit under a recipe's reagents
    -- What merchants charge for one of an item: { [itemID] = copper }, learned at each visit.
    -- Data, not a setting, like houses.
    vendor = {},
    -- Per auction house ("Realm-Faction"): { scannedAt = time(), items = { [itemID] = { price =
    -- copper, seenAt = time() } } }. scannedAt is the last full scan and decides when to scan
    -- again; seenAt is when that item's price was last seen, which the tooltip's age shows, since
    -- an item missing from a scan keeps its older price. Data, not a setting: it isn't in
    -- module.options.
    houses = {},
}, "gold"))
module.title = L.AUCTIONPRICES_TITLE
module.category = "items"

-- The price line first, then crafting, then scanning, with the Reset button (module.actions) under it.
module.options = ItemTooltip.PriceOptions({
    {
        key = "scanAge",
        name = L.AUCTIONPRICES_SCAN_AGE,
        description = L.AUCTIONPRICES_SCAN_AGE_DESC,
        section = L.AUCTIONPRICES_SECTION_TOOLTIP,
        choices = {
            { "right", L.PRICE_ALIGN_RIGHT },
            { "inline", L.PRICE_ALIGN_INLINE },
            { "off", L.AUCTIONPRICES_SCAN_AGE_OFF },
        },
    },
    {
        key = "scanAgeColor",
        name = L.AUCTIONPRICES_SCAN_AGE_COLOR,
        description = L.AUCTIONPRICES_SCAN_AGE_COLOR_DESC,
        section = L.AUCTIONPRICES_SECTION_TOOLTIP,
        choices = {
            { "age", L.AUCTIONPRICES_SCAN_AGE_COLOR_AGE },
            { "gray", L.PRICE_COLOR_GRAY },
            { "white", L.PRICE_COLOR_WHITE },
            { "gold", L.PRICE_COLOR_GOLD },
        },
    },
    {
        key = "scanAgeRedHours",
        name = L.AUCTIONPRICES_SCAN_AGE_RED,
        description = L.AUCTIONPRICES_SCAN_AGE_RED_DESC,
        section = L.AUCTIONPRICES_SECTION_TOOLTIP,
        min = 1, max = 48, step = 1,
        format = ns.Text.Hours,
    },
    {
        key = "crafting",
        name = L.AUCTIONPRICES_CRAFTING,
        description = L.AUCTIONPRICES_CRAFTING_DESC,
        section = L.AUCTIONPRICES_SECTION_CRAFTING,
    },
    {
        key = "scanOnOpen",
        name = L.AUCTIONPRICES_SCAN_ON_OPEN,
        description = L.AUCTIONPRICES_SCAN_ON_OPEN_DESC,
        section = L.AUCTIONPRICES_SECTION_SCANNING,
    },
    ns.ChatOption(L.AUCTIONPRICES_CHAT_DESC, L.AUCTIONPRICES_SECTION_SCANNING),
}, L.AUCTIONPRICES_SECTION_TOOLTIP)

-- The auction house this character sees. Realms share one per faction. Kept once found, since
-- every item tooltip asks and neither changes while logged in.
local houseData

local function house()
    if houseData then
        return houseData
    end
    local faction = UnitFactionGroup("player")
    local key = format("%s-%s", GetRealmName(), faction or "")
    local data = module.db.houses[key]
    if not (data and data.items) then
        data = { scannedAt = 0, items = {} } -- new, or saved before items kept their own age
        module.db.houses[key] = data
    end
    if faction then
        houseData = data -- without a faction yet (early in login), look again next time
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
        -- Above the window's border and title art, which are child frames with their own fixed
        -- levels, well above the window's (parent + 100 drew under them). A level over the title
        -- bar, as Coordinates does on the map, not a strata, so it stays with the window instead
        -- of floating over others.
        local title = parent.TitleContainer
        indicator:SetFrameLevel((title or parent):GetFrameLevel() + (title and 1 or 500))
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

-- busy shows the spinner; stay keeps the text up instead of hiding it after a few seconds.
local function showIndicator(text, busy, stay)
    local frame = getIndicator()
    if not frame then
        if not busy and not stay then
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
    if not busy and not stay then
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
    local items = house().items
    local now = time()
    for _, result in ipairs(results or {}) do
        local itemID = result.itemKey and result.itemKey.itemID
        local price = result.minPrice
        if itemID and result.totalQuantity and result.totalQuantity > 0 and price
            and price > 0 then
            local item = items[itemID]
            if scanning and seen[itemID] then
                -- One item can come back once per item level or suffix: keep the lowest.
                if price < item.price then
                    item.price = price
                end
            else
                -- The first price this scan, or from any other browse, replaces the old one.
                if scanning then
                    seen[itemID] = true
                    seenCount = seenCount + 1
                end
                if item then
                    item.price, item.seenAt = price, now
                else
                    items[itemID] = { price = price, seenAt = now }
                end
            end
        end
    end
end

local open = false -- the auction house is open

-- The scan shares the server's query throttle with everything the player does in the auction
-- house. Paging nonstop starved Blizzard's own queries, so the Sell tab's list never loaded and
-- posts could fail. Now it keeps one request out at a time, sends only when the throttle is
-- ready, gives way for a moment after each of Blizzard's own queries, and pauses while an item
-- sits in the sell box, so the list and the post go through first. Browsing tabs with nothing
-- to sell doesn't stop it.
local YIELD = 2 -- seconds the scan waits after one of Blizzard's own queries

local sent = false -- the scan's browse query has gone out
local waiting -- what the next step waits on: "server", "throttle", or "blocked"
local ownQuery = false -- set while sending the scan's own browse query
local lastQuery = 0 -- GetTime() of Blizzard's last query of its own
local blockTimer
local onThrottleReady

local function stopScan()
    scanning, sent, waiting = false, false, nil
    seen, seenCount = nil, nil
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    if blockTimer then
        blockTimer:Cancel()
        blockTimer = nil
    end
end

-- An item is in the sell box on the Sell tab, so a post is coming. Probed: when the window's
-- mode or the sell frame can't be read, don't pause.
local function selling()
    local frame, modes = _G.AuctionHouseFrame, _G.AuctionHouseFrameDisplayMode
    if not (frame and modes and frame.GetDisplayMode) then
        return false
    end
    local mode = frame:GetDisplayMode()
    local sellFrame = (mode == modes.ItemSell and frame.ItemSellFrame)
        or (mode == modes.CommoditiesSell and frame.CommoditiesSellFrame)
    return sellFrame and sellFrame.GetItem and sellFrame:GetItem() ~= nil or false
end

local step

-- Paused for the sell box or giving way: look again shortly. The timer runs only while a scan
-- is held back.
local function onBlockTimer()
    blockTimer = nil
    if waiting == "blocked" then
        step()
    end
end

-- Sends the scan's query, asks for the next page, or finishes once the server has sent
-- everything. Runs once per answer, so there's never more than one request out.
function step()
    if not scanning then
        return
    end
    local sell = selling()
    local wait = lastQuery + YIELD - GetTime()
    if sell or wait > 0 then
        waiting = "blocked"
        if sell then
            showIndicator(format(L.AUCTIONPRICES_PAUSED, seenCount), false, true)
        end
        if not blockTimer then
            blockTimer = C_Timer.NewTimer(sell and 1 or wait, onBlockTimer)
        end
        return
    end
    showIndicator(format(L.AUCTIONPRICES_SCANNING, seenCount), true)
    local ready = C_AuctionHouse.IsThrottledMessageSystemReady
    if ready and not ready() then
        if waiting ~= "throttle" then
            waiting = "throttle"
            ns.On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
        end
        return
    end
    waiting = "server"
    if not sent then
        sent, ownQuery = true, true
        C_AuctionHouse.SendBrowseQuery({
            searchString = "", sorts = {}, filters = {}, itemClassFilters = {},
        })
        ownQuery = false
    elseif not C_AuctionHouse.HasFullBrowseResults() then
        C_AuctionHouse.RequestMoreBrowseResults()
    else
        local count = seenCount
        house().scannedAt = time()
        stopScan()
        showIndicator(format(L.AUCTIONPRICES_SCANNED, count), false)
    end
end

function onThrottleReady()
    ns.Off("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", onThrottleReady)
    if waiting == "throttle" then
        step()
    end
end

local function onResults()
    if scanning and sent and waiting == "server" then
        step()
    end
end

local function onResultsUpdated()
    addResults(C_AuctionHouse.GetBrowseResults())
    onResults()
end

local function onResultsAdded(_, added)
    addResults(added)
    onResults()
end

-- Blizzard sent a query of its own (the sell list, an item's listings, your auctions, a post,
-- a purchase): hold the next page back for a moment so those go first.
local function onBlizzardQuery()
    if module.enabled and scanning then
        lastQuery = GetTime()
    end
end

-- Another search (the player's, favorites, another addon's) replaces the browse results the scan
-- was paging through, so stop, keeping the prices seen so far. Also stops a scan still waiting
-- to start, which would otherwise replace the player's results.
local function onOtherSearch()
    if module.enabled and scanning and not ownQuery then
        local count = seenCount
        stopScan()
        showIndicator(format(L.AUCTIONPRICES_STOPPED, count), false)
    end
end

local SEARCHES = { "SendBrowseQuery", "SearchForFavorites", "SearchForItemKeys" }
local QUERIES = {
    "SendSearchQuery", "SendSellSearchQuery", "RequestMoreItemSearchResults",
    "RequestMoreCommoditySearchResults", "RefreshItemSearchResults",
    "RefreshCommoditySearchResults", "QueryOwnedAuctions", "QueryBids", "PostItem",
    "PostCommodity", "PlaceBid", "CancelAuction", "StartCommoditiesPurchase",
    "ConfirmCommoditiesPurchase",
}

-- Hooks can't be removed; the functions above check module.enabled. Probed per name, since the
-- client may not have them all.
local hookedQueries = false

local function hookAuctionHouse()
    if hookedQueries then
        return
    end
    hookedQueries = true
    for _, name in ipairs(SEARCHES) do
        if type(C_AuctionHouse[name]) == "function" then
            hooksecurefunc(C_AuctionHouse, name, onOtherSearch)
        end
    end
    for _, name in ipairs(QUERIES) do
        if type(C_AuctionHouse[name]) == "function" then
            hooksecurefunc(C_AuctionHouse, name, onBlizzardQuery)
        end
    end
end

local function startScan()
    if scanning or not open then
        return
    end
    hookAuctionHouse()
    scanning, sent, waiting = true, false, nil
    seen, seenCount = {}, 0
    step()
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
local function resetPrices()
    local data = house()
    data.items = {}
    data.scannedAt = 0
    ns.Print(L.AUCTIONPRICES_RESET_DONE)
end

local RESET_POPUP = "AUCTIONPRICES_RESET"

local function confirmReset()
    ns.Confirm(RESET_POPUP, L.AUCTIONPRICES_RESET_CONFIRM, resetPrices)
end
ns.AddCommand("resetprices", "", L.AUCTIONPRICES_RESET_COMMAND, confirmReset)

module.actions = {
    {
        name = L.AUCTIONPRICES_RESET,
        button = L.AUCTIONPRICES_RESET_BUTTON,
        description = L.AUCTIONPRICES_RESET_DESC,
        fn = resetPrices,
        confirm = L.AUCTIONPRICES_RESET_CONFIRM,
        key = RESET_POPUP, -- the same popup /fpp resetprices asks
    },
}

local function onClosed()
    open = false
    stopScan() -- prices seen so far are kept; the next visit scans again
    hideIndicator()
end

-- Tooltips -----------------------------------------------------------------------------------

-- Scan Age Color "age": green when just scanned, yellow halfway, red at Red After (hours).
local function ageColor(seconds)
    local t = seconds / (module.db.scanAgeRedHours * 3600)
    t = t > 1 and 1 or t
    if t < 0.5 then
        return { t * 2, 1, 0 }
    end
    return { 1, (1 - t) * 2, 0 }
end

local function addAuctionPrice(tooltip, data)
    local itemID = module.enabled and ItemTooltip.ItemID(data)
    local item = itemID and house().items[itemID]
    if not item then
        return
    end
    local db = module.db
    ItemTooltip.AddPrice(tooltip, data, L.AUCTIONPRICES_LINE, item.price, db)
    -- When this item's price was last seen, by a scan or the player's own search: an item
    -- missing from the last scan keeps its older price and age.
    if db.scanAge ~= "off" then
        local age = time() - item.seenAt
        local color = db.scanAgeColor == "age" and ageColor(age) or db.scanAgeColor
        ItemTooltip.AddInfo(tooltip, L.AUCTIONPRICES_SCAN_AGE_LINE, ns.Text.Ago(age), db.scanAge, color)
    end
end

-- Crafting -----------------------------------------------------------------------------------
-- Under a recipe's reagents in the professions window: what each reagent costs (one's price
-- times how many the recipe takes), the total, what the crafted items are worth, and the
-- profit. A reagent a merchant sells costs the merchant's price when that's lower than the
-- auction's; those prices are learned at merchants. A crafted item with no auction price is
-- worth what a merchant pays for it. Our own frame, parented to Blizzard's recipe form.

-- A merchant's item: its price, how many that price buys, how many are left (-1: unlimited),
-- and whether it costs something besides money. Probe: C_MerchantFrame.GetItemInfo is newer
-- Mainline; GetMerchantItemInfo the older one.
local function merchantItem(index)
    local C_MerchantFrame = _G.C_MerchantFrame
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local info = C_MerchantFrame.GetItemInfo(index)
        if info then
            return info.price, info.stackCount, info.numAvailable, info.hasExtendedCost
        end
    elseif _G.GetMerchantItemInfo then
        local _, _, price, stack, available, _, _, extended = _G.GetMerchantItemInfo(index)
        return price, stack, available, extended
    end
end

-- Remembers what the open merchant charges for one of each item it always has, for money only.
local function recordMerchant()
    local count = _G.GetMerchantNumItems and _G.GetMerchantNumItems() or 0
    local getID = _G.GetMerchantItemID
    if not getID then
        return
    end
    local vendor = module.db.vendor
    for i = 1, count do
        local id = getID(i)
        local price, stack, available, extended = merchantItem(i)
        if id and price and price > 0 and available == -1 and not extended then
            vendor[id] = price / ((stack and stack > 0) and stack or 1)
        end
    end
end

-- What one of a reagent costs: the lower of its auction and merchant prices, or nil.
local function reagentCost(itemID)
    local item = house().items[itemID]
    local auction = item and item.price
    local vendor = module.db.vendor[itemID]
    if auction and vendor then
        return auction < vendor and auction or vendor
    end
    return auction or vendor
end

-- What one crafted item is worth: its auction price, or else what a merchant pays (and true).
local function craftedValue(itemID)
    local item = house().items[itemID]
    if item then
        return item.price, false
    end
    local sell = select(11, C_Item.GetItemInfo(itemID))
    if sell and sell > 0 then
        return sell, true
    end
end

-- The reagents every craft uses (not optional or finishing ones): { itemID, count } each. Probe:
-- reagentType and its enum are Mainline's; without them, the required slots.
local function basicReagents(schematic)
    local basic = Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
    local list = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
        local reagent = slot.reagents and slot.reagents[1]
        local isBasic
        if basic and slot.reagentType ~= nil then
            isBasic = slot.reagentType == basic
        else
            isBasic = slot.required
        end
        if isBasic and reagent and reagent.itemID and (slot.quantityRequired or 0) > 0 then
            list[#list + 1] = { reagent.itemID, slot.quantityRequired }
        end
    end
    return list
end

local GRAY, WHITE = GRAY_FONT_COLOR, HIGHLIGHT_FONT_COLOR
local GREEN, RED = GREEN_FONT_COLOR, RED_FONT_COLOR

-- Copper as coins, with a minus sign when it's negative.
local function coins(amount)
    amount = floor(amount + 0.5)
    if amount < 0 then
        return "-" .. ns.Money(-amount)
    end
    return ns.Money(amount)
end

local CRAFT_WIDTH, ROW_HEIGHT = 280, 14

local panel -- our frame under the reagents, made the first time a recipe shows

local function craftForm()
    local frame = _G.ProfessionsFrame
    local page = frame and frame.CraftingPage
    return page and page.SchematicForm
end

local function getPanel(form)
    if not panel then
        panel = CreateFrame("Frame", nil, form)
        panel:SetSize(CRAFT_WIDTH, ROW_HEIGHT)
        panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        panel.title:SetPoint("TOPLEFT")
        panel.title:SetText(L.AUCTIONPRICES_CRAFT_TITLE)
        panel.rows = {}
    end
    return panel
end

-- Row `i` at `y` below the title: a label on the left and a value at the right edge.
local function setRow(i, y, label, value)
    local row = panel.rows[i]
    if not row then
        row = {
            left = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
            right = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
        }
        row.left:SetJustifyH("LEFT")
        row.left:SetWordWrap(false)
        row.right:SetJustifyH("RIGHT")
        panel.rows[i] = row
    end
    row.right:ClearAllPoints()
    row.right:SetPoint("TOPRIGHT", 0, y)
    row.left:ClearAllPoints()
    row.left:SetPoint("TOPLEFT", 0, y)
    row.left:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
    row.left:SetText(label)
    row.right:SetText(value)
    row.left:Show()
    row.right:Show()
end

local function noPrice()
    return GRAY:WrapTextInColorCode(L.AUCTIONPRICES_CRAFT_NO_PRICE)
end

local function refreshCrafting(recipeInfo)
    local form = craftForm()
    if not form then
        return
    end
    recipeInfo = recipeInfo or (form.GetRecipeInfo and form:GetRecipeInfo())
    local recipeID = module.enabled and module.db.crafting and recipeInfo and recipeInfo.recipeID
    local schematic = recipeID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic
        and C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    local reagents = schematic and basicReagents(schematic)
    -- Under the optional reagents when the recipe has them, or else the reagents.
    local below = form.OptionalReagents
    if not (below and below:IsShown()) then
        below = form.Reagents
    end
    if not (reagents and #reagents > 0 and below) then
        if panel then
            panel:Hide()
        end
        return
    end
    getPanel(form)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -12)

    local i, y = 0, -(ROW_HEIGHT + 4)
    local total, missing = 0, false
    for _, reagent in ipairs(reagents) do
        local itemID, count = reagent[1], reagent[2]
        local name = C_Item.GetItemNameByID(itemID) or L.AUCTIONPRICES_CRAFT_UNKNOWN
        local unit = reagentCost(itemID)
        local value
        if unit then
            total = total + unit * count
            value = coins(unit * count)
            if count > 1 then
                value = format(L.AUCTIONPRICES_CRAFT_EACH, GRAY:WrapTextInColorCode(
                    format(L.AUCTIONPRICES_CRAFT_TIMES, coins(unit), count)), value)
            end
        else
            missing = true
            value = noPrice()
        end
        i = i + 1
        setRow(i, y, name, value)
        y = y - ROW_HEIGHT
    end
    y = y - 4
    i = i + 1
    setRow(i, y, L.AUCTIONPRICES_CRAFT_COST, missing and noPrice() or coins(total))
    y = y - ROW_HEIGHT

    -- Enchants and other recipes that make no item have no value or profit.
    local output = schematic.outputItemID
    local unitValue, fromVendor
    if output then
        unitValue, fromVendor = craftedValue(output)
        local low, high = schematic.quantityMin or 1, schematic.quantityMax or 1
        local made = (low + high) / 2 -- some recipes make a random number: count the middle
        local label = L.AUCTIONPRICES_CRAFT_VALUE
        if high > 1 then
            local amount = low == high and tostring(low) or format(L.AUCTIONPRICES_CRAFT_RANGE, low, high)
            label = format(L.AUCTIONPRICES_CRAFT_VALUE_COUNT, amount)
        end
        local valueText = noPrice()
        if unitValue then
            unitValue = unitValue * made
            valueText = coins(unitValue)
            if fromVendor then
                valueText = format(L.AUCTIONPRICES_CRAFT_EACH,
                    GRAY:WrapTextInColorCode(L.AUCTIONPRICES_CRAFT_VENDOR), valueText)
            end
        end
        i = i + 1
        setRow(i, y, label, valueText)
        y = y - ROW_HEIGHT

        local profitText = noPrice()
        if unitValue and not missing then
            local profit = unitValue - total
            local color = profit > 0 and GREEN or profit < 0 and RED or WHITE
            profitText = color:WrapTextInColorCode(coins(profit))
        end
        i = i + 1
        setRow(i, y, L.AUCTIONPRICES_CRAFT_PROFIT, profitText)
        y = y - ROW_HEIGHT
    end

    for j = i + 1, #panel.rows do
        panel.rows[j].left:Hide()
        panel.rows[j].right:Hide()
    end
    panel:SetHeight(-y)
    panel:Show()
end

local function onRecipeInit(_, recipeInfo)
    refreshCrafting(recipeInfo)
end

-- Blizzard_Professions is load-on-demand: hook its recipe form once it has loaded. Init runs each
-- time a recipe is picked.
local function hookProfessions()
    local form = craftForm()
    if form then
        module:Hook(form, "Init", onRecipeInit)
        refreshCrafting()
    end
end

function module:OnEnable()
    self:On("AUCTION_HOUSE_SHOW", onShow)
    self:On("AUCTION_HOUSE_CLOSED", onClosed)
    self:On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", onResultsUpdated)
    self:On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", onResultsAdded)
    -- The hook can't be removed; addAuctionPrice checks module.enabled instead.
    ItemTooltip.OnPrices(addAuctionPrice)
    ItemTooltip.RedrawOnShift(self, true)
    self:On("MERCHANT_SHOW", recordMerchant)
    self:On("MERCHANT_UPDATE", recordMerchant)
    ns.AddOns.WhenLoaded("Blizzard_Professions", hookProfessions)
end

function module:OnDisable()
    ItemTooltip.RedrawOnShift(self, false)
    stopScan()
    hideIndicator()
    open = false
    ns.AddOns.Cancel("Blizzard_Professions", hookProfessions)
    if panel then
        panel:Hide()
    end
end

function module:OnOptionChanged(key)
    if key == "crafting" then
        refreshCrafting()
    end
end
