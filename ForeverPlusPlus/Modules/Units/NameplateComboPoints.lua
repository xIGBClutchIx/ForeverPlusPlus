-- Nameplate Combo Points: a Rogue's or a cat Druid's combo points on their target's nameplate,
-- above its name or below its health bar, one dot a point and nothing at none. A feature request,
-- issue #27.
--
-- Forever has no combo points on nameplates of its own: Blizzard_NamePlates' TOC leaves the Rogue
-- and Druid ClassNameplateBar files out of this client, so its combo points are only the dots on
-- the target frame (ComboFrame, build 1.60.1.70205).
--
-- The count may be secret (GetComboPoints is SecretWhenUnitPowerRestricted in the client's API
-- notes, and our own mana reads secret even out of combat), so it's never compared: each dot is a
-- status bar that runs from one point to the next, and the count goes straight to SetValue. A dot
-- is then full or empty by the bar's own drawing, and no points draws nothing.
local _, ns = ...

local select, ipairs, type, tostring, floor = select, ipairs, type, tostring, math.floor
local CreateFrame, UnitClass, UnitPowerMax, GetComboPoints = CreateFrame, UnitClass, UnitPowerMax, GetComboPoints
local GetTime = GetTime
local C_NamePlate = C_NamePlate

local L = ns.L

local module = ns.NewModule("NameplateComboPoints", L.NAMEPLATECOMBO_DESC, {
    enabled = false,
    position = "above",
    size = 100, -- percent
    preview = false, -- Debug: made-up points counting up, on any class
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
    { key = "preview", name = L.NAMEPLATECOMBO_PREVIEW, description = L.NAMEPLATECOMBO_PREVIEW_DESC,
        debug = true, section = L.DEBUG_SECTION_PREVIEWS },
}

-- Only the classes that have combo points here. With Debug on at login it's there for any class,
-- for its preview (Debug's file loads before this one, so its settings are read by then).
function module:IsAvailable()
    if not (GetComboPoints and C_NamePlate) then
        return false
    end
    local class = select(2, UnitClass("player"))
    local debug = ns.modules.Debug
    return class == "ROGUE" or class == "DRUID" or (debug and debug.db and debug.db.enabled) or false
end

-- A dot's art has to be a whole image: a status bar crops its texture itself as it fills, so a part
-- of a sheet picked with SetTexCoord (the target frame's ComboFrame art) came out as slivers of the
-- wrong part. Blizzard's own red combo point from its modern Rogue bar where the client has that
-- atlas, or else the round red light the game has always had.
local ATLAS = "uf-roguecp-icon-red"
local TEXTURE = "Interface\\COMMON\\Indicator-Red"
local DOT_SIZE, GAP = 12, 1
local DEFAULT_MAX = 5
local OFFSET = 2 -- between the dots and what they sit beside

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
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetPoint("LEFT", (i - 1) * (DOT_SIZE + GAP), 0)
        dot:SetStatusBarTexture(ns.Frames.HasAtlas(ATLAS) and ATLAS or TEXTURE)
        dot:SetMinMaxValues(i - 1, i)
        dot:SetValue(0)
        dots[i] = dot
    end
    holder:SetSize(#dots * DOT_SIZE + (#dots - 1) * GAP, DOT_SIZE)
end

local function update()
    if not holder or not holder:IsShown() then
        return
    end
    local points
    if module.db.preview then
        -- Debug's preview: none, then one more each second up to them all, and round again.
        points = floor(GetTime()) % (#dots + 1)
    else
        points = GetComboPoints("player", "target")
    end
    for _, dot in ipairs(dots) do
        dot:SetValue(points)
    end
end

-- The preview's points change with the clock, not with an event.
local sinceTick = 0
local function onUpdate(_, elapsed)
    sinceTick = sinceTick + elapsed
    if sinceTick >= 0.25 then
        sinceTick = 0
        update()
    end
end

-- Puts the dots on the target's plate, or hides them without one (no target, a plate off screen,
-- or a friendly plate the game forbids addons).
local function attach()
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    local frame = plate and plate.UnitFrame
    local parts = frame and ns.Nameplates.Parts(frame)
    local container = parts and parts.container
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
        -- Over the name, which sits on the bar: straight on the bar they'd cover it.
        holder:SetPoint("BOTTOM", parts.name or container, "TOP", 0, OFFSET)
    end
    holder:SetScale(module.db.size / 100)
    holder:SetFrameLevel(frame:GetFrameLevel() + 5)
    holder:SetScript("OnUpdate", module.db.preview and onUpdate or nil)
    holder:Show()
    update()
end

-- Debug's button: what the client gives for the target's combo points, and whether it can be read.
local function printPoints()
    local points = GetComboPoints("player", "target")
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    ns.Print(L.NAMEPLATECOMBO_PRINT_LINE:format(
        ns.IsReadable(points) and tostring(points) or "secret", maxPoints(),
        tostring(plate ~= nil and plate.UnitFrame ~= nil)))
end

module.debugActions = {
    {
        name = L.NAMEPLATECOMBO_PRINT, button = L.NAMEPLATECOMBO_PRINT_BUTTON,
        description = L.NAMEPLATECOMBO_PRINT_DESC, section = L.DEBUG_SECTION_DIAGNOSTICS, fn = printPoints,
    },
}

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
