-- Bag Slot Counter: how many bag slots are free, as a number on the bag buttons beside the micro
-- menu, like an item's stack count. Either each bag's own count on its button or the total on the
-- backpack. Special bags (quivers, ammo pouches, soul bags, herb bags), whose slots only take some
-- items, can be left out. The reagent bag has its own setting: its own count, added to the
-- backpack's count, or nothing. The text's size and corner are options.
local _, ns = ...

local _G, ipairs, pairs, tostring = _G, ipairs, pairs, tostring
local CreateFrame, C_Container, Enum = CreateFrame, C_Container, Enum

local L = ns.L

local module = ns.NewModule("BagSlots", L.BAGSLOTS_DESC, {
    enabled = true,
    show = "each", -- "each": every bag its own; "backpack": the total on the backpack
    special = true, -- count bags whose slots only take some items
    reagent = "own", -- the reagent bag: "own" count on its button, in the backpack's "total", or "off"
    size = "large", -- a key of SIZES
    position = "bottomright", -- a key of POSITIONS
})
module.title = L.BAGSLOTS_TITLE
module.category = "items"

module.options = {
    {
        key = "show", name = L.BAGSLOTS_SHOW, description = L.BAGSLOTS_SHOW_DESC,
        section = L.BAGSLOTS_SECTION_COUNT,
        choices = {
            { "each", L.BAGSLOTS_SHOW_EACH },
            { "backpack", L.BAGSLOTS_SHOW_BACKPACK },
        },
    },
    {
        key = "special", name = L.BAGSLOTS_SPECIAL, description = L.BAGSLOTS_SPECIAL_DESC,
        section = L.BAGSLOTS_SECTION_COUNT,
    },
    {
        key = "reagent", name = L.BAGSLOTS_REAGENT, description = L.BAGSLOTS_REAGENT_DESC,
        section = L.BAGSLOTS_SECTION_COUNT,
        choices = {
            { "own", L.BAGSLOTS_REAGENT_OWN },
            { "total", L.BAGSLOTS_REAGENT_TOTAL },
            { "off", L.BAGSLOTS_REAGENT_OFF },
        },
    },
    {
        key = "size", name = L.BAGSLOTS_SIZE, description = L.BAGSLOTS_SIZE_DESC,
        section = L.BAGSLOTS_SECTION_TEXT,
        choices = {
            { "small", L.BAGSLOTS_SIZE_SMALL },
            { "normal", L.BAGSLOTS_SIZE_NORMAL },
            { "large", L.BAGSLOTS_SIZE_LARGE },
            { "huge", L.BAGSLOTS_SIZE_HUGE },
        },
    },
    {
        key = "position", name = L.BAGSLOTS_POSITION, description = L.BAGSLOTS_POSITION_DESC,
        section = L.BAGSLOTS_SECTION_TEXT,
        choices = {
            { "bottomright", L.BAGSLOTS_POSITION_BOTTOMRIGHT },
            { "bottomleft", L.BAGSLOTS_POSITION_BOTTOMLEFT },
            { "topright", L.BAGSLOTS_POSITION_TOPRIGHT },
            { "topleft", L.BAGSLOTS_POSITION_TOPLEFT },
            { "bottom", L.BAGSLOTS_POSITION_BOTTOM },
            { "top", L.BAGSLOTS_POSITION_TOP },
            { "center", L.BAGSLOTS_POSITION_CENTER },
        },
    },
}

-- Blizzard's number fonts, the ones stack counts use, smallest to largest.
local SIZES = {
    small = "NumberFontNormalSmall",
    normal = "NumberFontNormal",
    large = "NumberFontNormalLarge",
    huge = "NumberFontNormalHuge",
}

-- Anchor point, x and y offset from the button's edge, and justification.
local INSET = 3
local POSITIONS = {
    bottomright = { "BOTTOMRIGHT", -INSET, INSET, "RIGHT" },
    bottomleft = { "BOTTOMLEFT", INSET, INSET, "LEFT" },
    topright = { "TOPRIGHT", -INSET, -INSET, "RIGHT" },
    topleft = { "TOPLEFT", INSET, -INSET, "LEFT" },
    bottom = { "BOTTOM", 0, INSET, "CENTER" },
    top = { "TOP", 0, -INSET, "CENTER" },
    center = { "CENTER", 0, 0, "CENTER" },
}

-- Bag ids (Enum.BagIndex) and their buttons on Mainline's bag bar. A button Forever doesn't have
-- is skipped.
local BACKPACK = 0
local REAGENT = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or 5
local BAGS = {
    { id = BACKPACK, button = "MainMenuBarBackpackButton" },
    { id = 1, button = "CharacterBag0Slot" },
    { id = 2, button = "CharacterBag1Slot" },
    { id = 3, button = "CharacterBag2Slot" },
    { id = 4, button = "CharacterBag3Slot" },
    { id = REAGENT, button = "CharacterReagentBag0Slot" },
}

local RED_FONT_COLOR = RED_FONT_COLOR
local FULL = RED_FONT_COLOR and { RED_FONT_COLOR:GetRGB() } or { 1, 0.1, 0.1 } -- a count of 0
local WHITE = { 1, 1, 1 }

local counts = {} -- bag id -> our FontString, on its own frame over the button
local frames = {} -- our frames, so turning off hides them all
local built = false

-- Blizzard's own free slot count on the backpack ("(16)", with the displayFreeBagSlots CVar).
-- Hidden while this module is on so the backpack doesn't show two numbers.
local function blizzardCount()
    local backpack = _G.MainMenuBarBackpackButton
    return _G.MainMenuBarBackpackButtonCount or (backpack and backpack.Count)
end

local function style()
    local font = _G[SIZES[module.db.size] or SIZES.normal] or _G.NumberFontNormal
    local position = POSITIONS[module.db.position] or POSITIONS.bottomright
    for _, text in pairs(counts) do
        if font then
            text:SetFontObject(font)
        end
        text:ClearAllPoints()
        text:SetPoint(position[1], position[2], position[3])
        text:SetJustifyH(position[4])
    end
end

local function build()
    built = true
    for _, bag in ipairs(BAGS) do
        local button = _G[bag.button]
        if button then
            -- Our own frame above the button, so the text sits over its icon and border.
            local frame = CreateFrame("Frame", nil, button)
            frame:SetAllPoints()
            frame:SetFrameLevel(button:GetFrameLevel() + 2)
            counts[bag.id] = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            frames[#frames + 1] = frame
        end
    end
end

-- Free slots in a bag, or nil when there's no bag there or it doesn't count.
local function freeSlots(bag)
    if C_Container.GetContainerNumSlots(bag.id) == 0 then
        return nil
    end
    local free, family = C_Container.GetContainerNumFreeSlots(bag.id)
    if bag.id == REAGENT then
        if module.db.reagent == "off" then
            return nil
        end
    elseif family and family ~= 0 and not module.db.special then
        return nil
    end
    return free or 0
end

local function setCount(text, free)
    if not text then
        return
    end
    if free then
        local color = free == 0 and FULL or WHITE
        text:SetTextColor(color[1], color[2], color[3])
        text:SetText(tostring(free))
        text:Show()
    else
        text:Hide()
    end
end

local function update()
    local each = module.db.show == "each"
    local shown = {} -- bag id -> the count on its button
    local total, any = 0, false
    for _, bag in ipairs(BAGS) do
        local free = freeSlots(bag)
        local own = each
        if bag.id == REAGENT then
            own = module.db.reagent == "own"
        end
        if own then
            shown[bag.id] = free
        elseif free then
            total, any = total + free, true
        end
    end
    -- Every bag without its own count adds up on the backpack, on top of the backpack's own.
    if any then
        shown[BACKPACK] = (shown[BACKPACK] or 0) + total
    end
    for _, bag in ipairs(BAGS) do
        setCount(counts[bag.id], shown[bag.id])
    end
end

local function showAll(shown)
    for _, frame in ipairs(frames) do
        frame:SetShown(shown)
    end
    local count = blizzardCount()
    if count then
        count:SetAlpha(shown and 0 or 1)
    end
end

function module:OnEnable()
    if not built then
        build()
    end
    style() -- the size or position may have changed while it was off
    showAll(true)
    self:On("BAG_UPDATE_DELAYED", update)
    self:On("BAG_CONTAINER_UPDATE", update) -- a bag put on or taken off
    self:On("PLAYER_ENTERING_WORLD", update)
    update()
end

function module:OnDisable()
    showAll(false)
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "size" or key == "position" then
        style()
    else
        update()
    end
end
