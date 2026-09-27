-- Bag Slot Counter: how many bag slots are free, as a number in the corner of the bag buttons
-- beside the micro menu, like an item's stack count. Either the total on the backpack or each
-- bag's own count on its button. Only normal bags count unless the player adds special ones
-- (quivers, ammo pouches, soul bags, herb bags, the reagent bag), whose slots only take some items.
local _, ns = ...

local _G, ipairs, tostring = _G, ipairs, tostring
local CreateFrame, C_Container = CreateFrame, C_Container

local L = ns.L

local module = ns.NewModule("BagSlots", L.BAGSLOTS_DESC, {
    enabled = true,
    show = "backpack", -- "backpack": the total on the backpack; "each": every bag its own
    special = false, -- count bags whose slots only take some items
})
module.title = L.BAGSLOTS_TITLE
module.category = "items"

module.options = {
    {
        key = "show", name = L.BAGSLOTS_SHOW, description = L.BAGSLOTS_SHOW_DESC,
        choices = {
            { "backpack", L.BAGSLOTS_SHOW_BACKPACK },
            { "each", L.BAGSLOTS_SHOW_EACH },
        },
    },
    { key = "special", name = L.BAGSLOTS_SPECIAL, description = L.BAGSLOTS_SPECIAL_DESC },
}

-- Bag ids (Enum.BagIndex) and their buttons on Mainline's bag bar. A button Forever doesn't have
-- is skipped. The reagent bag counts as special whatever its family says.
local BACKPACK = 0
local BAGS = {
    { id = 0, button = "MainMenuBarBackpackButton" },
    { id = 1, button = "CharacterBag0Slot" },
    { id = 2, button = "CharacterBag1Slot" },
    { id = 3, button = "CharacterBag2Slot" },
    { id = 4, button = "CharacterBag3Slot" },
    { id = 5, button = "CharacterReagentBag0Slot", special = true },
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

local function build()
    built = true
    for _, bag in ipairs(BAGS) do
        local button = _G[bag.button]
        if button then
            -- Our own frame above the button, so the text sits over its icon and border.
            local frame = CreateFrame("Frame", nil, button)
            frame:SetAllPoints()
            frame:SetFrameLevel(button:GetFrameLevel() + 2)
            local text = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            text:SetPoint("BOTTOMRIGHT", -3, 3)
            text:SetJustifyH("RIGHT")
            counts[bag.id] = text
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
    local special = bag.special or (family and family ~= 0)
    if special and not module.db.special then
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
    local total, any = 0, false
    for _, bag in ipairs(BAGS) do
        local free = freeSlots(bag)
        if free then
            total, any = total + free, true
        end
        if each then
            setCount(counts[bag.id], free)
        elseif bag.id ~= BACKPACK then
            setCount(counts[bag.id], nil)
        end
    end
    if not each then
        setCount(counts[BACKPACK], any and total or nil)
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
    showAll(true)
    self:On("BAG_UPDATE_DELAYED", update)
    self:On("BAG_CONTAINER_UPDATE", update) -- a bag put on or taken off
    self:On("PLAYER_ENTERING_WORLD", update)
    update()
end

function module:OnDisable()
    showAll(false)
end

function module:OnOptionChanged()
    if self.enabled then
        update()
    end
end
