-- Nameplate Combo Points: a Rogue's or a cat Druid's combo points on their target's nameplate,
-- above its name or below its health bar, one dot a point and nothing at none. A feature request,
-- issue #27. Drawn as the target frame draws them by default, or as a plain light.
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

-- What a dot can look like. Each has to be a whole image: a status bar crops its texture itself as
-- it fills, so a part of a sheet picked with SetTexCoord (the target frame's ComboFrame art) came
-- out as slivers of the wrong part. The round lights are files the game has always had; the Rogue
-- points are the modern Rogue bar's atlases, offered only on a client that has them.
local ICONS = {
    red = "Interface\\COMMON\\Indicator-Red",
    yellow = "Interface\\COMMON\\Indicator-Yellow",
    green = "Interface\\COMMON\\Indicator-Green",
    rogue = "uf-roguecp-icon-red",
    rogueBlue = "uf-roguecp-icon-blue",
}
-- The target frame's own points (ComboPointTemplate, Blizzard_UnitFrame's ComboFrame.xml): a dark
-- socket for every point and a red light in each one held. A sheet, so not a status bar's
-- texture: see The target frame's look below.
local NATIVE = "target"
local NATIVE_ART = "Interface\\ComboFrame\\ComboPoint"

local ICON_CHOICES = {
    { NATIVE, L.NAMEPLATECOMBO_ICON_TARGET },
    { "red", L.PLATES_COLOR_RED },
    { "yellow", L.PLATES_COLOR_YELLOW },
    { "green", L.PLATES_COLOR_GREEN },
}
if ns.Frames.HasAtlas(ICONS.rogue) then
    ICON_CHOICES[#ICON_CHOICES + 1] = { "rogue", L.NAMEPLATECOMBO_ICON_ROGUE }
end
if ns.Frames.HasAtlas(ICONS.rogueBlue) then
    ICON_CHOICES[#ICON_CHOICES + 1] = { "rogueBlue", L.NAMEPLATECOMBO_ICON_ROGUE_BLUE }
end

local module = ns.NewModule("NameplateComboPoints", L.NAMEPLATECOMBO_DESC, {
    enabled = true, -- only Rogues and Druids have the module at all (IsAvailable)
    icon = NATIVE, -- as the target frame draws them
    position = "below", -- above the name is where the plate's debuffs go
    size = 100, -- percent
    preview = false, -- Debug: made-up points counting up, on any class
})
module.title = L.NAMEPLATECOMBO_TITLE
module.category = "units"
module.added = "1.10.0"
module.quickToggle = "nameplates"

module.options = {
    { key = "icon", name = L.NAMEPLATECOMBO_ICON, description = L.NAMEPLATECOMBO_ICON_DESC, choices = ICON_CHOICES },
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

local DOT_SIZE, GAP = 12, 1
local DEFAULT_MAX = 5
local OFFSET = 2 -- between the dots and the name over them
local OFFSET_BELOW = 6 -- and under the health bar, whose border and glow reach past its edge

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
        dot:SetMinMaxValues(i - 1, i)
        dot:SetValue(0)
        dots[i] = dot
    end
    holder:SetSize(#dots * DOT_SIZE + (#dots - 1) * GAP, DOT_SIZE)
end

-- The target frame's look ---------------------------------------------------------------------
-- Its art is one sheet (a socket, a red light, a shine), which a status bar can't draw a part of.
-- So the art is plain textures, and the bars only say how much of them shows, still with no
-- count compared: a bar's fill is as wide as its dot from its point on and has no width before
-- it, and a frame that clips what's in it is stretched over that fill, with the light inside.
-- The sockets are in one such frame over a bar that fills from the first point on, so with no
-- points there's nothing, as the target frame hides its own.
local ART_HEIGHT = 16 -- the sheet's art is taller than a dot (ComboPointTemplate: 12 by 16)
local BLANK = "Interface\\Buttons\\WHITE8x8" -- a bar needs a texture to have a fill; never seen

-- { bars = the bars the count goes to, shown = every frame of the look }, made the first time
-- the look is picked.
local native

-- A frame over `bar`'s fill, as tall as the art, that hides whatever of its children is outside it.
local function clipOver(bar)
    local fill = bar:GetStatusBarTexture()
    local clip = CreateFrame("Frame", nil, holder)
    clip:SetClipsChildren(true)
    clip:SetPoint("TOPLEFT", fill, "TOPLEFT")
    clip:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, DOT_SIZE - ART_HEIGHT)
    return clip
end

-- A part of the sheet as a texture. The sheet is small (32 by 16) and a nameplate is scaled to
-- sizes that aren't whole pixels, so it's drawn smoothed and off the pixel grid: snapped, each
-- point landed a pixel off its neighbors and the edges came out jagged (in game, 2026-11-27).
local function sheetPart(parent, layer, left, right, width)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetTexture(NATIVE_ART, nil, nil, "TRILINEAR")
    texture:SetTexCoord(left, right, 0, 1)
    texture:SetSize(width, ART_HEIGHT)
    if texture.SetSnapToPixelGrid then
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
    end
    return texture
end

local function buildNative()
    if native then
        return
    end
    -- Bars of the look's own, each with its fill from the start and never given another texture:
    -- a clip is anchored to the fill, and over a bar with no texture yet it was anchored to
    -- nothing, so every light showed whatever the count (in game, 2026-11-27).
    local function unseenBar(from, to)
        local bar = CreateFrame("StatusBar", nil, holder)
        bar:SetStatusBarTexture(BLANK)
        bar:GetStatusBarTexture():SetAlpha(0)
        bar:SetMinMaxValues(from, to)
        bar:SetValue(from)
        return bar
    end
    local gate = unseenBar(0, 1)
    gate:SetAllPoints(holder)
    local sockets = clipOver(gate)
    native = { bars = { gate }, shown = { gate, sockets } }
    for i, dot in ipairs(dots) do
        local socket = sheetPart(sockets, "BACKGROUND", 0, 0.375, 12)
        socket:SetPoint("TOPLEFT", dot, "TOPLEFT")
        local bar = unseenBar(i - 1, i)
        bar:SetAllPoints(dot)
        local clip = clipOver(bar)
        clip:SetFrameLevel(sockets:GetFrameLevel() + 1)
        local light = sheetPart(clip, "ARTWORK", 0.375, 0.5625, 8)
        light:SetPoint("TOPLEFT", dot, "TOPLEFT", 2, 0)
        native.bars[#native.bars + 1] = bar
        native.shown[#native.shown + 1] = bar
        native.shown[#native.shown + 1] = clip
    end
end

-- Each dot as the look picked draws it: its own art in the bar, or the bar unseen under the
-- target frame's art.
local function applyLook()
    local look = module.db.icon
    local isNative = look == NATIVE
    if isNative then
        buildNative()
    end
    for _, dot in ipairs(dots) do
        if not isNative then
            dot:SetStatusBarTexture(ICONS[look] or ICONS.red)
        end
        -- Under the target frame's art the plain dots stay where they are, unseen: the art is
        -- placed by them.
        dot:SetAlpha(isNative and 0 or 1)
    end
    if native then
        for _, part in ipairs(native.shown) do
            part:SetShown(isNative)
        end
    end
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
    if native then
        for _, bar in ipairs(native.bars) do
            bar:SetValue(points)
        end
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
        holder:SetPoint("TOP", container, "BOTTOM", 0, -OFFSET_BELOW)
    else
        -- Over the name, which sits on the bar: straight on the bar they'd cover it.
        holder:SetPoint("BOTTOM", parts.name or container, "TOP", 0, OFFSET)
    end
    applyLook()
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
