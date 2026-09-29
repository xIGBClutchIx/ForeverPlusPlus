-- Durability Bars: a thin bar beside each equipped item on the character frame that shows how
-- worn it is, green when whole through yellow to red when broken. Left column items get it on
-- their right side and right column items on their left, so it faces the character model; the
-- weapons along the bottom get a flat bar under them, since the gap between them is too narrow.
-- Items without durability get no bar.
local _, ns = ...

local _G, pairs, CreateFrame = _G, pairs, CreateFrame
local pcall, GetInventorySlotInfo, GetInventoryItemDurability = pcall, GetInventorySlotInfo, GetInventoryItemDurability

local L = ns.L

local module = ns.NewModule("DurabilityBars", L.DURABILITYBARS_DESC, {
    enabled = true,
    show = "always", -- a key of SHOW_BELOW
})
module.title = L.DURABILITYBARS_TITLE
module.category = "items"

-- Show a bar only below this much durability (a bar at exactly 1 is whole).
local SHOW_BELOW = { always = 2, worn = 1, half = 0.5, quarter = 0.25 }

module.options = {
    {
        key = "show", name = L.DURABILITYBARS_SHOW, description = L.DURABILITYBARS_SHOW_DESC,
        choices = {
            { "always", L.DURABILITYBARS_SHOW_ALWAYS },
            { "worn", L.DURABILITYBARS_SHOW_WORN },
            { "half", L.DURABILITYBARS_SHOW_HALF },
            { "quarter", L.DURABILITYBARS_SHOW_QUARTER },
        },
    },
}

local THICKNESS = 3 -- bar width, in pixels
local GAP = 2 -- space between the bar and the item button
local INSET = 2 -- how far the bar stops short of the button's ends

-- The slot names, by which edge of the button faces inward.
local SIDES = {
    RIGHT = { "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist" },
    LEFT = { "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1" },
    BOTTOM = { "MainHand", "SecondaryHand", "Ranged" }, -- Ranged only if Forever has the slot
}

local container -- our frame on the paper doll; bars are children, so they hide with it
local bars = {} -- inventory slot id -> StatusBar

local function makeBar(button, side)
    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    if side == "BOTTOM" then
        bar:SetHeight(THICKNESS)
        bar:SetPoint("TOPLEFT", button, "BOTTOMLEFT", INSET, -GAP)
        bar:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", -INSET, -GAP)
    else
        bar:SetOrientation("VERTICAL")
        bar:SetWidth(THICKNESS)
        local point, other, x = "TOPLEFT", "TOPRIGHT", GAP
        if side == "LEFT" then
            point, other, x = "TOPRIGHT", "TOPLEFT", -GAP
        end
        bar:SetPoint(point, button, other, x, -INSET)
        bar:SetPoint("BOTTOM", button, "BOTTOM", 0, INSET)
    end
    bar:Hide()
    return bar
end

local function build()
    container = CreateFrame("Frame", nil, _G.PaperDollItemsFrame)
    container:SetAllPoints()
    for side, names in pairs(SIDES) do
        for i = 1, #names do
            local name = names[i] .. "Slot"
            local button = _G["Character" .. name]
            local ok, slot = pcall(GetInventorySlotInfo, name)
            if button and ok and slot then
                bars[slot] = makeBar(button, side)
            end
        end
    end
end

local function update()
    local below = SHOW_BELOW[module.db.show] or SHOW_BELOW.always
    for slot, bar in pairs(bars) do
        local current, maximum = GetInventoryItemDurability(slot)
        local fraction = current and maximum and maximum > 0 and current / maximum
        if fraction and fraction < below then
            bar:SetValue(fraction)
            -- Green at full, yellow at half, red at zero.
            if fraction > 0.5 then
                bar:SetStatusBarColor((1 - fraction) * 2, 1, 0)
            else
                bar:SetStatusBarColor(1, fraction * 2, 0)
            end
            bar:Show()
        else
            bar:Hide()
        end
    end
end

local function start()
    if not _G.PaperDollItemsFrame then
        return
    end
    if not container then
        build()
    end
    container:Show()
    update()
end

-- The character frame is in Blizzard_UIPanels_Game on Mainline, which loads before addons; wait
-- for it anyway in case Forever makes it load on demand.
local ADDON = "Blizzard_UIPanels_Game"

function module:OnEnable()
    self:On("UPDATE_INVENTORY_DURABILITY", update)
    self:On("PLAYER_EQUIPMENT_CHANGED", update)
    if _G.PaperDollItemsFrame then
        start()
    else
        ns.AddOns.WhenLoaded(ADDON, start)
    end
end

function module:OnDisable()
    ns.AddOns.Cancel(ADDON, start)
    if container then
        container:Hide()
    end
end

function module:OnOptionChanged()
    if self.enabled and container then
        update()
    end
end
