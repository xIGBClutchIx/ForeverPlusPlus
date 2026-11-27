-- Bag Slot Counter: how many bag slots are free, as a number on the bag buttons beside the micro
-- menu, like an item's stack count. Either the total on the backpack or each bag's own count on its
-- button. Special bags (quivers, ammo pouches, soul bags, herb bags), whose slots only take some
-- items, can be left out. The reagent bag has its own setting: its own count, added to the
-- backpack's count, or nothing. The text's size and corner are options.
--
-- The controller interface hides the bag bar (Blizzard_ActionBar's MainActionBar_UnInitializeMKB
-- hides BagsBar and MicroMenu), and its own bag buttons are only in the bag window. So while it's
-- on, a button of our own shows the backpack's icon and the total, placed in Edit Mode. It only
-- shows: a click of ours opening Blizzard's bags would run in our call, and the controller's focus
-- manager answers a window opening (docs/forever-api.md).
local _, ns = ...

local _G, ipairs, pairs, tostring, format = _G, ipairs, pairs, tostring, string.format
local CreateFrame, C_Container, Enum, UIParent = CreateFrame, C_Container, Enum, UIParent

local L = ns.L

local module = ns.NewModule("BagSlotCounter", L.BAGSLOTCOUNTER_DESC, {
    enabled = true,
    show = "backpack", -- "backpack": the total on the backpack; "each": every bag its own
    special = true, -- count bags whose slots only take some items
    reagent = "own", -- the reagent bag: "own" count on its button, in the backpack's "total", or "off"
    size = "large", -- a key of SIZES
    position = "bottomright", -- a key of POSITIONS
    color = true, -- red at 0 free, and orange at `lowSlots` or fewer
    lowSlots = 4, -- 0 for no orange
    controller = true, -- our own bag button while the controller interface is on
    x = 330, -- that button's offset from the center of the screen: right of the controller's bar
    y = -330,
    scale = 100, -- percent
})
module.title = L.BAGSLOTCOUNTER_TITLE
module.category = "items"

module.options = {
    {
        key = "show", name = L.BAGSLOTCOUNTER_SHOW, description = L.BAGSLOTCOUNTER_SHOW_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_COUNT,
        choices = {
            { "backpack", L.BAGSLOTCOUNTER_SHOW_BACKPACK },
            { "each", L.BAGSLOTCOUNTER_SHOW_EACH },
        },
    },
    {
        key = "special", name = L.BAGSLOTCOUNTER_SPECIAL, description = L.BAGSLOTCOUNTER_SPECIAL_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_COUNT,
    },
    {
        key = "reagent", name = L.BAGSLOTCOUNTER_REAGENT, description = L.BAGSLOTCOUNTER_REAGENT_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_COUNT,
        choices = {
            { "own", L.BAGSLOTCOUNTER_REAGENT_OWN },
            { "total", L.BAGSLOTCOUNTER_REAGENT_TOTAL },
            { "off", L.BAGSLOTCOUNTER_REAGENT_OFF },
        },
    },
    {
        key = "size", name = L.BAGSLOTCOUNTER_SIZE, description = L.BAGSLOTCOUNTER_SIZE_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_TEXT,
        choices = {
            { "small", L.BAGSLOTCOUNTER_SIZE_SMALL },
            { "normal", L.BAGSLOTCOUNTER_SIZE_NORMAL },
            { "large", L.BAGSLOTCOUNTER_SIZE_LARGE },
            { "huge", L.BAGSLOTCOUNTER_SIZE_HUGE },
        },
    },
    {
        key = "position", name = L.BAGSLOTCOUNTER_POSITION, description = L.BAGSLOTCOUNTER_POSITION_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_TEXT,
        choices = {
            { "bottomright", L.BAGSLOTCOUNTER_POSITION_BOTTOMRIGHT },
            { "bottomleft", L.BAGSLOTCOUNTER_POSITION_BOTTOMLEFT },
            { "topright", L.BAGSLOTCOUNTER_POSITION_TOPRIGHT },
            { "topleft", L.BAGSLOTCOUNTER_POSITION_TOPLEFT },
            { "bottom", L.BAGSLOTCOUNTER_POSITION_BOTTOM },
            { "top", L.BAGSLOTCOUNTER_POSITION_TOP },
            { "center", L.BAGSLOTCOUNTER_POSITION_CENTER },
        },
    },
    {
        key = "color", name = L.BAGSLOTCOUNTER_COLOR, description = L.BAGSLOTCOUNTER_COLOR_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_TEXT, slider = "lowSlots", added = "0.9.0",
    },
    {
        key = "lowSlots", name = L.BAGSLOTCOUNTER_LOW_SLOTS, description = L.BAGSLOTCOUNTER_LOW_SLOTS_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_TEXT, requires = "color",
        min = 0, max = 20, step = 1, format = function(value)
            return value == 0 and L.BAGSLOTCOUNTER_LOW_SLOTS_OFF or tostring(value)
        end,
    },
    {
        key = "controller", name = L.BAGSLOTCOUNTER_CONTROLLER,
        description = L.BAGSLOTCOUNTER_CONTROLLER_DESC,
        section = L.BAGSLOTCOUNTER_SECTION_CONTROLLER, added = "1.10.0",
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
local REAGENT = ns.Bags.REAGENT
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
local LOW = ORANGE_FONT_COLOR and { ORANGE_FONT_COLOR:GetRGB() } or { 1, 0.5, 0.25 } -- a few left
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

-- Our bag button for the controller interface, made the first time it shows.
local hud
local hudRegistered = false -- in Edit Mode
-- The backpack's own icon and art, as Blizzard's backpack button draws them (BagsBar's
-- MainMenuBarBackpackButton and BaseBagSlotButtonMixin:GetSlotAtlases, Camelot
-- MainMenuBarBagButtons, Gethe `forever` branch, read 2026-11-26).
local HUD_ICON = "Interface\\Icons\\ui-hud-actionbar-bag"
local HUD_BORDER = "ui-hud-actionbar-iconframe-bags"
local HUD_MASK = "UI-HUD-ActionBar-IconFrame-Mask"
local HUD_SIZE = 45 -- the backpack button's size

local function styleText(text, font, position)
    if font then
        text:SetFontObject(font)
    end
    text:ClearAllPoints()
    text:SetPoint(position[1], position[2], position[3])
    text:SetJustifyH(position[4])
end

local function style()
    local font = _G[SIZES[module.db.size] or SIZES.normal] or _G.NumberFontNormal
    local position = POSITIONS[module.db.position] or POSITIONS.bottomright
    for _, text in pairs(counts) do
        styleText(text, font, position)
    end
    if hud then
        styleText(hud.count, font, position)
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
        local color = WHITE
        if module.db.color then
            color = free == 0 and FULL or free <= module.db.lowSlots and LOW or WHITE
        end
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
    local all, anyBag = 0, false -- every bag that counts, for our controller button
    for _, bag in ipairs(BAGS) do
        local free = freeSlots(bag)
        if free then
            all, anyBag = all + free, true
        end
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
    if hud then
        setCount(hud.count, anyBag and all or nil)
    end
end

-- The controller button ---------------------------------------------------------------------------

-- Each bag that counts, with its free and total slots, the way the module counts them.
local function showTooltip(self)
    local tooltip = _G.GameTooltip
    tooltip:SetOwner(self, "ANCHOR_LEFT")
    tooltip:SetText(L.BAGSLOTCOUNTER_HUD_TITLE)
    local getName = C_Container.GetBagName
    for index, bag in ipairs(BAGS) do
        local free = freeSlots(bag)
        if free then
            local name = getName and getName(bag.id)
            if not (ns.IsText(name) and name ~= "") then
                name = format(L.BAGSLOTCOUNTER_HUD_BAG, index)
            end
            tooltip:AddDoubleLine(name, format(L.BAGSLOTCOUNTER_HUD_FREE, free,
                C_Container.GetContainerNumSlots(bag.id)), 1, 1, 1, 1, 1, 1)
        end
    end
    tooltip:Show()
end

local function newHud()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(HUD_SIZE, HUD_SIZE)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true) -- a tooltip only: clicks go through to the world
    if f.SetMouseClickEnabled then
        f:SetMouseClickEnabled(false)
    end
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(HUD_ICON)
    if ns.Frames.HasAtlas(HUD_MASK) then
        -- Blizzard's square bag slot mask, at its offsets (SquareBagSlotButtonTemplate).
        local mask = f:CreateMaskTexture()
        mask:SetAtlas(HUD_MASK)
        mask:SetPoint("TOPLEFT", -8, 8)
        mask:SetPoint("BOTTOMRIGHT", 8, -8)
        icon:AddMaskTexture(mask)
    end
    if ns.Frames.HasAtlas(HUD_BORDER) then
        local border = f:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints()
        border:SetAtlas(HUD_BORDER)
    end
    f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.count:SetDrawLayer("OVERLAY", 7)
    f:SetScript("OnEnter", showTooltip)
    f:SetScript("OnLeave", _G.GameTooltip_Hide)
    f:Hide()
    return f
end

local function placeHud()
    hud:SetScale(module.db.scale / 100)
    ns.EditMode.Place(hud, module.db.x, module.db.y)
end

-- Shows our button while the module and its option are on and the controller interface is in use,
-- and takes it away otherwise.
local function refreshHud()
    if module.enabled and module.db.controller and ns.Gamepad.On() then
        if not hud then
            hud = newHud()
            style()
        end
        placeHud()
        if not hudRegistered then
            hudRegistered = true
            ns.EditMode.RegisterModule(module, hud, L.BAGSLOTCOUNTER_TITLE, placeHud)
        end
        hud:Show()
    elseif hud then
        if hudRegistered then
            hudRegistered = false
            ns.EditMode.Unregister(hud)
        end
        hud:Hide()
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
    self:On("PLAYER_ENTERING_WORLD", function()
        refreshHud()
        update()
    end)
    refreshHud()
    update()
end

function module:OnDisable()
    showAll(false)
    refreshHud() -- the module is off now, so this takes the controller button away
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "size" or key == "position" then
        style()
    elseif key == "controller" then
        refreshHud()
        update()
    else
        update()
    end
end
