-- Character Window's item details: each item's level on its icon, in its quality's color, and a
-- mark in the icon's corner nearest the character for its enchant: green when it has one, red when
-- it could take one and hasn't. The same in the Inspect window, with its option on.
--
-- The enchant is the second field of the item's link (`item:ID:enchantID:...`), which the
-- inspected player's links carry too. Sockets get nothing: no item in Forever's tables has one
-- (ItemSparse's SocketType_*, build 1.60.1.71139). Which items can take an enchant is a seed in
-- Data/Items.lua that play adds to when it sees an enchant on a kind of item it lacks.
-- CharacterWindow.lua turns this on and off.
local _, ns = ...

local _G, pairs, ipairs, tonumber, CreateFrame = _G, pairs, ipairs, tonumber, CreateFrame
local setmetatable, pcall = setmetatable, pcall
local GetInventoryItemLink, GetInventorySlotInfo = GetInventoryItemLink, GetInventorySlotInfo
local C_Item = C_Item

local L = ns.L
local module = ns.modules.CharacterWindow
local internal = module.internal

local ENCHANTABLE = ns.GameData.New("enchantable", ns.Data.enchantable, { label = "Enchantable items" })

local INSPECT = "Blizzard_InspectUI"
local INSET = 2 -- between a mark and the icon's edge

-- The corner of the icon nearest the character, by the side the slot's column faces.
local CORNERS = { RIGHT = "BOTTOMRIGHT", LEFT = "BOTTOMLEFT", BOTTOM = "BOTTOMLEFT" }

---@class DetailMarks
---@field level table the item level's FontString
---@field enchant table the enchant mark's FontString
---@field slot number

-- Per window: its slot buttons (weak, they're Blizzard's) -> our marks.
local player = setmetatable({}, { __mode = "k" })
local inspect = setmetatable({}, { __mode = "k" })
local playerHolder, inspectHolder -- our frames over each window's slots; hidden with the option off
local waiting -- an item's level wasn't cached yet: GET_ITEM_INFO_RECEIVED shows it

local function on()
    return module.enabled and (module.db.itemLevel or module.db.enchants) and true or false
end

local function inspectOn()
    return on() and module.db.inspect and true or false
end

-- The kind of item an enchant goes on: its type, or a weapon's subclass (a staff and a fishing
-- pole are both two-handed).
local function kindOf(link)
    local _, _, _, equipLoc, _, classID, subclassID = C_Item.GetItemInfoInstant(link)
    if classID == ns.Equipment.WEAPON and subclassID then
        return "weapon:" .. subclassID
    end
    return equipLoc
end

-- The enchant's ID from the link's second field, 0 for none.
local function enchantOf(link)
    return tonumber(link:match("item:%-?%d+:(%d+)")) or 0
end

local function makeMarks(holder, button, slot, side)
    local frame = CreateFrame("Frame", nil, holder)
    frame:SetAllPoints(button)
    -- Over the icon and its quality border.
    frame:SetFrameLevel(button:GetFrameLevel() + 2)
    local level = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    level:SetPoint("TOPLEFT", INSET, -INSET)
    local enchant = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    local corner = CORNERS[side]
    enchant:SetPoint(corner, corner == "BOTTOMRIGHT" and -INSET or INSET, INSET)
    enchant:SetText(L.CHARACTERWINDOW_ENCHANT_MARK)
    return { level = level, enchant = enchant, slot = slot }
end

-- Our marks over every slot button of a window whose buttons are named prefix .. "HeadSlot".
local function build(holder, marks, prefix)
    for side, names in pairs(internal.SIDES) do
        for _, name in ipairs(names) do
            local button = _G[prefix .. name .. "Slot"]
            local ok, slot = pcall(GetInventorySlotInfo, name .. "Slot")
            if button and ok and slot then
                marks[button] = makeMarks(holder, button, slot, side)
            end
        end
    end
end

-- One slot's marks, for what `unit` wears there.
local function show(marks, unit)
    local link = unit and GetInventoryItemLink(unit, marks.slot)
    if not ns.IsText(link, true) then
        marks.level:Hide()
        marks.enchant:Hide()
        return
    end
    -- Gear only: a shirt's or a tabard's level says nothing (Lib/Equipment.lua).
    local level, quality
    if module.db.itemLevel then
        level, quality = ns.Equipment.ItemLevel(link)
        if level == nil then
            waiting = true
        end
    end
    if level then
        local color = ns.Colors.Quality(quality)
        marks.level:SetText(level)
        marks.level:SetTextColor(color.r, color.g, color.b)
    end
    marks.level:SetShown(level and true or false)

    local color
    if module.db.enchants then
        local kind = kindOf(link)
        if enchantOf(link) > 0 then
            color = _G.GREEN_FONT_COLOR
            -- An enchant on a kind of item the seed doesn't have: a patch added one.
            if kind and ENCHANTABLE:Get(kind) == nil then
                ENCHANTABLE:Learn(kind, true)
            end
        elseif kind and ENCHANTABLE:Get(kind) then
            color = _G.RED_FONT_COLOR
        end
    end
    if color then
        marks.enchant:SetTextColor(color:GetRGB())
    end
    marks.enchant:SetShown(color and true or false)
end

-- IsVisible, not IsShown: the holder stays shown while the window is closed, and its OnShow reads
-- the items again when it opens.
local function updatePlayer()
    if not (playerHolder and playerHolder:IsVisible()) then
        return
    end
    for _, marks in pairs(player) do
        show(marks, "player")
    end
end

local function inspectUnit()
    local frame = _G.InspectFrame
    return frame and frame.unit
end

local function updateInspect()
    if not (inspectHolder and inspectHolder:IsVisible()) then
        return
    end
    local unit = inspectUnit()
    for _, marks in pairs(inspect) do
        show(marks, unit)
    end
end

-- Blizzard redraws a slot of the Inspect window when the player's items arrive or change.
local function onInspectSlot(button)
    local marks = inspect[button]
    if marks and inspectHolder and inspectHolder:IsVisible() then
        show(marks, inspectUnit())
    end
end

local function buildInspect()
    if inspectHolder or not _G.InspectPaperDollItemsFrame then
        return
    end
    inspectHolder = CreateFrame("Frame", nil, _G.InspectPaperDollItemsFrame)
    inspectHolder:SetAllPoints()
    inspectHolder:SetScript("OnShow", updateInspect)
    build(inspectHolder, inspect, "Inspect")
    module:Hook("InspectPaperDollItemSlotButton_Update", onInspectSlot)
end

local function onInspectLoaded()
    if inspectOn() then
        buildInspect()
        internal.updateDetails()
    end
end

local function onItemInfo()
    if not waiting then
        return
    end
    waiting = false
    updatePlayer()
    updateInspect()
end

---Shows or hides the marks to match the module and its options. Once the character frame has
---loaded for the player's; the Inspect window's wait for it to load.
function internal.updateDetails()
    local shown = on()
    if shown and not playerHolder and _G.PaperDollItemsFrame then
        playerHolder = CreateFrame("Frame", nil, _G.PaperDollItemsFrame)
        playerHolder:SetAllPoints()
        playerHolder:SetScript("OnShow", updatePlayer)
        build(playerHolder, player, "Character")
    end
    if playerHolder then
        playerHolder:SetShown(shown)
        updatePlayer()
    end
    if inspectOn() then
        if inspectHolder then
            inspectHolder:Show()
            updateInspect()
        else
            ns.AddOns.WhenLoaded(INSPECT, onInspectLoaded)
        end
    else
        ns.AddOns.Cancel(INSPECT, onInspectLoaded)
        if inspectHolder then
            inspectHolder:Hide()
        end
    end
end

-- A new enchant changes the link but not what's equipped.
local function onInventory(_, unit)
    if ns.IsText(unit) and unit == "player" then
        updatePlayer()
    end
end

-- The events the marks want while either of them is on. updatePlayer() does nothing while the
-- window is closed.
module:OnWhile(function(db)
    return db.itemLevel or db.enchants
end, {
    PLAYER_EQUIPMENT_CHANGED = updatePlayer,
    UNIT_INVENTORY_CHANGED = onInventory,
    GET_ITEM_INFO_RECEIVED = onItemInfo,
})
