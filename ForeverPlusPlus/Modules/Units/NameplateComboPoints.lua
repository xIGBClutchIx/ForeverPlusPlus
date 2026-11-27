-- Nameplate Combo Points: a Rogue's or a cat Druid's combo points on their target's nameplate,
-- above or below its health bar, one dot a point and nothing at none. A feature request, issue #27.
--
-- Forever has no combo points on nameplates of its own: Blizzard_NamePlates' TOC leaves the Rogue
-- and Druid ClassNameplateBar files out of this client, so its combo points are only the dots on
-- the target frame (ComboFrame, build 1.60.1.70205). Ours use that frame's own art.
--
-- The count may be secret (GetComboPoints is SecretWhenUnitPowerRestricted in the client's API
-- notes, and our own mana reads secret even out of combat), so it's never compared: each dot is a
-- status bar that runs from one point to the next, and the count goes straight to SetValue. A dot
-- is then full or empty by the bar's own drawing, and no points draws nothing.
local _, ns = ...

local select, ipairs, type = select, ipairs, type
local CreateFrame, UnitClass, UnitPowerMax, GetComboPoints = CreateFrame, UnitClass, UnitPowerMax, GetComboPoints
local C_NamePlate = C_NamePlate

local L = ns.L

local module = ns.NewModule("NameplateComboPoints", L.NAMEPLATECOMBO_DESC, {
    enabled = false,
    position = "above",
    size = 100, -- percent
})
module.title = L.NAMEPLATECOMBO_TITLE
module.category = "units"
module.added = "1.9.2"
module.quickToggle = "nameplates"

module.options = {
    {
        key = "position", name = L.NAMEPLATECOMBO_POSITION, description = L.NAMEPLATECOMBO_POSITION_DESC,
        choices = {
            { "above", L.NAMEPLATECOMBO_POSITION_ABOVE },
            { "below", L.NAMEPLATECOMBO_POSITION_BELOW },
        },
    },
    {
        key = "size", name = L.NAMEPLATECOMBO_SIZE, description = L.NAMEPLATECOMBO_SIZE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
}

-- Only the classes that have combo points here.
function module:IsAvailable()
    local class = select(2, UnitClass("player"))
    return (class == "ROGUE" or class == "DRUID") and GetComboPoints ~= nil and C_NamePlate ~= nil
end

local TEXTURE = "Interface\\ComboFrame\\ComboPoint" -- the target frame's dots (ComboFrame.xml)
local DOT_WIDTH, DOT_HEIGHT, GAP = 8, 16, 2 -- its red dot's part of the art, as Blizzard sizes it
local DEFAULT_MAX = 5
local OFFSET = 2 -- between the dots and the health bar

local holder -- our frame, made the first time a target's plate is up
local dots = {}

-- How many points the player can hold, or five when the client won't say.
local function maxPoints()
    local power = Enum and Enum.PowerType and Enum.PowerType.ComboPoints
    local most = power and UnitPowerMax("player", power)
    if ns.IsReadable(most) and type(most) == "number" and most > 0 and most <= 10 then
        return most
    end
    return DEFAULT_MAX
end

local function build()
    if holder then
        return
    end
    holder = CreateFrame("Frame")
    holder:Hide()
    for i = 1, maxPoints() do
        -- Full from point i on, empty before it: the count is only ever handed to the bar.
        local dot = CreateFrame("StatusBar", nil, holder)
        dot:SetSize(DOT_WIDTH, DOT_HEIGHT)
        dot:SetPoint("LEFT", (i - 1) * (DOT_WIDTH + GAP), 0)
        dot:SetStatusBarTexture(TEXTURE)
        local fill = dot:GetStatusBarTexture()
        if fill then
            fill:SetTexCoord(0.375, 0.5625, 0, 1)
        end
        dot:SetMinMaxValues(i - 1, i)
        dot:SetValue(0)
        dots[i] = dot
    end
    holder:SetSize(#dots * DOT_WIDTH + (#dots - 1) * GAP, DOT_HEIGHT)
end

local function update()
    if not holder or not holder:IsShown() then
        return
    end
    local points = GetComboPoints("player", "target")
    for _, dot in ipairs(dots) do
        dot:SetValue(points)
    end
end

-- Puts the dots on the target's plate, or hides them without one (no target, a plate off screen,
-- or a friendly plate the game forbids addons).
local function attach()
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    local frame = plate and plate.UnitFrame
    local container = frame and ns.Nameplates.Parts(frame).container
    if not container then
        if holder then
            holder:Hide()
        end
        return
    end
    build()
    -- On the plate's own frame, beside its health bar: never the plate above it (Lib/Nameplates).
    holder:SetParent(frame)
    holder:ClearAllPoints()
    if module.db.position == "below" then
        holder:SetPoint("TOP", container, "BOTTOM", 0, -OFFSET)
    else
        holder:SetPoint("BOTTOM", container, "TOP", 0, OFFSET)
    end
    holder:SetScale(module.db.size / 100)
    holder:SetFrameLevel(frame:GetFrameLevel() + 5)
    holder:Show()
    update()
end

local handlers = {
    -- The target's plate may come up after it was targeted, or go while it still is.
    OnAdded = attach,
    -- Plates are pooled: the dots come off before this one shows another unit.
    OnRemoved = function(_, frame)
        if holder and holder:GetParent() == frame then
            holder:Hide()
        end
    end,
}

function module:OnEnable()
    ns.Nameplates.Register(self, handlers)
    self:On("PLAYER_TARGET_CHANGED", attach)
    self:OnUnit("UNIT_POWER_UPDATE", { "player" }, update)
    self:OnUnit("UNIT_POWER_FREQUENT", { "player" }, update)
    attach()
end

function module:OnDisable()
    ns.Nameplates.Unregister(self)
    if holder then
        holder:Hide()
    end
end

function module:OnOptionChanged()
    if self.enabled then
        attach()
    end
end
