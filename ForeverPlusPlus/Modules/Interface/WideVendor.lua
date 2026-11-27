-- Wide Vendor Window: the vendor window shows 20 items to a page instead of 10, in a second block
-- of ten beside Blizzard's own, and its Buyback tab its 12 items in two blocks of six.
--
-- Blizzard's MerchantFrame_UpdateMerchantInfo fills `MerchantItem1` to `MerchantItem<n>` for the
-- page, n being the global MERCHANT_ITEMS_PER_PAGE, which it, the paging, the page text, the
-- quality borders, and the stack split all read each time (Blizzard_UIPanels_Game, Mainline
-- MerchantFrame.lua). So the one way to a bigger page without replacing Blizzard's code is to raise
-- that number and make the buttons it then looks up, by name, from Blizzard's own
-- MerchantItemTemplate: 11 and 12 are there for Buyback already, 13 to 20 are ours. EnhanceQOL
-- does the same.
--
-- That number is the one Blizzard value this addon writes, and it taints: Blizzard's merchant code
-- runs as ours after reading it. Nothing in it is protected (buying, selling, buyback, repairs),
-- and MerchantFrame.page and the rest of its fields stay Blizzard's to write. It's written only
-- while the window is closed, since Blizzard puts the page back to 1 each time the window opens, so
-- the page never has to be changed for it; a change made while one is open waits for it to close.
--
-- The controller interface's cursor reads the number too (MerchantFrame_SetupGamepad's page turn),
-- and its focus code refuses tainted calls (docs/forever-api.md), so the window keeps its size then.
--
-- The layout: Blizzard's ten stay where Blizzard puts them; the window grows by two items to the
-- right and 11 to 20 sit there in the same two columns. On Buyback, 7 to 12 move to that side.
-- Blizzard anchors 3, 5, 7, and 9 again as each tab draws, so ours go on after it, from hooks.
-- Item marks (Lib/ItemButtons.lua) read the same number, so they reach the new buttons by
-- themselves.
local _, ns = ...

local type, hooksecurefunc, CreateFrame = type, hooksecurefunc, CreateFrame

local L = ns.L
local _G = _G

local module = ns.NewModule("WideVendor", L.WIDEVENDOR_DESC, {
    enabled = false,
})
module.title = L.WIDEVENDOR_TITLE
module.category = "interface"
module.added = "1.10.0"
module.notice = {
    { text = L.WIDEVENDOR_NOTICE, description = L.WIDEVENDOR_NOTICE_DESC },
    { text = L.WIDEVENDOR_CONTROLLER, description = L.WIDEVENDOR_CONTROLLER_DESC, shown = ns.Gamepad.On },
}

local PER_PAGE = 20 -- items on a page while it's on
local ITEM_WIDTH, GAP = 153, 12 -- MerchantItemTemplate's width, and the gap between two columns
local WIDER = 2 * (ITEM_WIDTH + GAP) -- how much wider the window gets: two more columns

function module:IsAvailable()
    return _G.MerchantFrame and _G.MerchantItem12 and _G.MerchantNextPageButton
        and type(_G.MERCHANT_ITEMS_PER_PAGE) == "number"
        and _G.MerchantFrame_UpdateMerchantInfo and _G.MerchantFrame_UpdateBuybackInfo and true or false
end

local applied = false -- whether the window is wide now: it changes only while the window is closed
local blizzardPerPage, blizzardWidth -- Blizzard's own, read before the first change
local hooked = false

local function item(i)
    return _G["MerchantItem" .. i]
end

-- MerchantItem13 to 20, from Blizzard's template, named as Blizzard's code looks them up.
local function makeItems()
    for i = 13, PER_PAGE do
        if not item(i) then
            CreateFrame("Frame", "MerchantItem" .. i, MerchantFrame, "MerchantItemTemplate")
        end
    end
end

-- Anchors item `i`'s top left to a point of `anchor`, its one anchor.
local function place(i, anchor, relativePoint, x, y)
    local frame = item(i)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, relativePoint, x, y)
end

-- The Merchant tab: 11 to 20 in two columns right of Blizzard's ten, spaced as Blizzard's are.
local function layoutMerchant()
    if not applied then
        return
    end
    place(7, item(5), "BOTTOMLEFT", 0, -8)
    place(11, item(2), "TOPRIGHT", GAP, 0)
    for i = 12, PER_PAGE do
        if i % 2 == 0 then
            place(i, item(i - 1), "TOPRIGHT", GAP, 0)
        else
            place(i, item(i - 2), "BOTTOMLEFT", 0, -8)
        end
    end
    -- Blizzard hides 11 and 12 after filling them; each still shows nothing past the last item.
    for i = 11, PER_PAGE do
        item(i):Show()
    end
end

-- Buyback: 1 to 6 where Blizzard puts them, 7 to 12 beside them, and nothing of ours.
local function layoutBuyback()
    if not applied then
        return
    end
    place(7, item(2), "TOPRIGHT", GAP, 0)
    place(11, item(9), "BOTTOMLEFT", 0, -15)
    place(12, item(11), "TOPRIGHT", GAP, 0)
    for i = 13, PER_PAGE do
        item(i):Hide()
    end
end

-- Blizzard's anchors, from MerchantFrame.xml, for the frames moved here.
local function restore()
    place(7, item(5), "BOTTOMLEFT", 0, -8)
    place(11, item(9), "BOTTOMLEFT", 0, -15)
    place(12, item(11), "TOPRIGHT", GAP, 0)
    item(11):Hide()
    item(12):Hide()
    for i = 13, PER_PAGE do
        if item(i) then
            item(i):Hide()
        end
    end
    local button = _G.MerchantNextPageButton
    button:ClearAllPoints()
    button:SetPoint("CENTER", MerchantFrame, "BOTTOMLEFT", 310, 96)
end

local function apply(wide)
    if wide == applied then
        return
    end
    if wide then
        blizzardPerPage = blizzardPerPage or MERCHANT_ITEMS_PER_PAGE
        blizzardWidth = blizzardWidth or MerchantFrame:GetWidth()
        makeItems()
        MERCHANT_ITEMS_PER_PAGE = PER_PAGE
        MerchantFrame:SetWidth(blizzardWidth + WIDER)
        -- Blizzard's Next button sits a fixed way in from the left; it goes to the new right edge.
        local button = _G.MerchantNextPageButton
        button:ClearAllPoints()
        button:SetPoint("CENTER", MerchantFrame, "BOTTOMRIGHT", -26, 96)
        applied = true
    else
        MERCHANT_ITEMS_PER_PAGE = blizzardPerPage
        MerchantFrame:SetWidth(blizzardWidth)
        applied = false
        restore()
    end
end

-- Wide while the module is on, and never with the controller interface; only while it's closed.
local function sync()
    if MerchantFrame:IsShown() then
        return
    end
    apply(module.enabled and not ns.Gamepad.On())
end

function module:OnEnable()
    if not hooked then
        -- Hooked with `applied`, not module.enabled: turned off while the window is open, it stays
        -- wide until it closes, and these keep it whole until then.
        hooked = true
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", layoutMerchant)
        hooksecurefunc("MerchantFrame_UpdateBuybackInfo", layoutBuyback)
        MerchantFrame:HookScript("OnHide", sync)
    end
    sync()
end

function module:OnDisable()
    sync()
end
