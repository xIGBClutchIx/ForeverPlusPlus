-- Nameplate Combo Points: a Rogue's or a cat Druid's combo points on their target's nameplate,
-- above its name or below its health bar, and nothing at none. A feature request, issue #27.
--
-- Forever has no combo points on nameplates of its own: Blizzard_NamePlates' TOC leaves the Rogue
-- and Druid ClassNameplateBar files out of this client, so its combo points are only the dots on
-- the target frame (ComboFrame, build 1.60.1.70205). This is laid out as that bar is where the
-- game has it (ClassNameplateBarRogueFrame, Blizzard_ClassNameplateBar_Rogue.xml): 20 by 20
-- points, its own scale of 0.7 whatever the plate's (ignoreParentScale), and Blizzard's art for
-- them, which this client still has: the nameplates' own older points (ClassOverlay-ComboPoint)
-- and the Rogue bar's (uf-roguecp). The target frame's art (Interface\ComboFrame\ComboPoint) is a
-- 32 by 16 sheet made for one size: on a nameplate it was jagged and cut off however it was
-- drawn (in game, 2026-11-27), so it isn't offered.
--
-- The count may be secret (GetComboPoints is SecretWhenUnitPowerRestricted in the client's API
-- notes, and our own mana reads secret even out of combat), so it's never compared: the count
-- goes straight to status bars, one for each point, running from one point to the next, and a
-- bar's own drawing says whether its point shows. See Looks below.
local _, ns = ...

local select, ipairs, type, tostring, floor = select, ipairs, type, tostring, math.floor
local CreateFrame, UnitClass, UnitPowerMax, GetComboPoints = CreateFrame, UnitClass, UnitPowerMax, GetComboPoints
local GetTime = GetTime
local C_NamePlate, C_Texture = C_NamePlate, C_Texture

local L = ns.L
local HasAtlas = ns.Frames.HasAtlas

-- Looks -----------------------------------------------------------------------------------------
-- A plain look is one image, the bar's own texture: the round lights the game has always had.
-- A status bar crops its texture itself as it fills, so it has to be a whole image.
local PLAIN = {
    red = "Interface\\COMMON\\Indicator-Red",
    yellow = "Interface\\COMMON\\Indicator-Yellow",
    green = "Interface\\COMMON\\Indicator-Green",
}

-- A socketed look is Blizzard's own art in layers, each `{ atlas, x, y }` from the point's middle:
-- `empty` shows for every point once there's one (the socket), `full` over it for a point held.
local SOCKETED = {}
if HasAtlas("ClassOverlay-ComboPoint") and HasAtlas("ClassOverlay-ComboPoint-Off") then
    -- The nameplates' own points before the class bars were redrawn: a red point in a dark socket.
    SOCKETED.classic = {
        gap = 2,
        empty = { { "ClassOverlay-ComboPoint-Off" } },
        full = { { "ClassOverlay-ComboPoint" } },
    }
end
if HasAtlas("uf-roguecp-bg") and HasAtlas("uf-roguecp-bg-dis") then
    -- The Rogue bar's, as RogueComboPointTemplate lays them out (RogueComboPointBar.xml).
    local function rogue(icon)
        return {
            gap = 4,
            empty = { { "uf-roguecp-bg-shadow", 0, -4 }, { "uf-roguecp-bg-dis" } },
            full = { { "uf-roguecp-bg" }, { icon } },
        }
    end
    if HasAtlas("uf-roguecp-icon-red") then
        SOCKETED.rogue = rogue("uf-roguecp-icon-red")
    end
    if HasAtlas("uf-roguecp-icon-blue") then
        SOCKETED.rogueBlue = rogue("uf-roguecp-icon-blue")
    end
end

local ICON_CHOICES = {}
for _, choice in ipairs({
    { "classic", L.NAMEPLATECOMBO_ICON_CLASSIC },
    { "rogue", L.NAMEPLATECOMBO_ICON_ROGUE },
    { "rogueBlue", L.NAMEPLATECOMBO_ICON_ROGUE_BLUE },
    { "red", L.PLATES_COLOR_RED },
    { "yellow", L.PLATES_COLOR_YELLOW },
    { "green", L.PLATES_COLOR_GREEN },
}) do
    if SOCKETED[choice[1]] or PLAIN[choice[1]] then
        ICON_CHOICES[#ICON_CHOICES + 1] = choice
    end
end

local module = ns.NewModule("NameplateComboPoints", L.NAMEPLATECOMBO_DESC, {
    enabled = true, -- only Rogues and Druids have the module at all (IsAvailable)
    icon = ICON_CHOICES[1][1], -- Blizzard's own points where the client has the art
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

local BAR_SCALE = 0.7 -- ClassNameplateBarRogueFrame's own scale, with the plate's ignored
local POINT = 20 -- a socketed point (RogueComboPointTemplate: 20 by 20)
local PLAIN_POINT, PLAIN_GAP = 14, 2 -- a plain light, and between two
local ROOM = 8 -- kept clear around the points for art that reaches past them (the shadow)
local DEFAULT_MAX = 5
local OFFSET = 2 -- between the points and the name over them
local OFFSET_BELOW = 6 -- and under the health bar, whose border and glow reach past its edge
local BLANK = "Interface\\Buttons\\WHITE8x8" -- a bar needs a texture to have a fill; never seen

local holder -- our frame, made the first time a target's plate is up
-- One for each point: { slot = where it is, dot = the plain look's bar, bar = the socketed looks'
-- unseen bar, empty = a frame for the socket's art, full = one for the held point's }.
local points = {}
local gate -- the unseen bar that fills from the first point on, which the sockets show with
local bars = {} -- every bar the count goes to

-- How many points the player can hold, or five when the client won't say.
local function maxPoints()
    local power = Enum and Enum.PowerType and Enum.PowerType.ComboPoints
    local most = power and UnitPowerMax("player", power)
    if ns.IsReadable(most) and type(most) == "number" and most > 0 and most <= 10 then
        return most
    end
    return DEFAULT_MAX
end

-- A bar the count goes to that draws nothing itself: only how wide its fill is matters.
local function unseenBar(from, to)
    local bar = CreateFrame("StatusBar", nil, holder)
    bar:SetStatusBarTexture(BLANK)
    bar:GetStatusBarTexture():SetAlpha(0)
    bar:SetMinMaxValues(from, to)
    bar:SetValue(from)
    bars[#bars + 1] = bar
    return bar
end

-- A frame stretched over `bar`'s fill, with room above and below, that hides whatever of its
-- children is outside it: nothing while the bar is empty, since the fill then has no width, and
-- everything once it's full. That is how art that isn't a bar's own texture follows a count
-- nothing may compare. The bar has its fill before this is anchored to it: over a bar with no
-- texture yet the frame was anchored to nothing, and every point showed (in game, 2026-11-27).
local function clipOver(bar)
    local fill = bar:GetStatusBarTexture()
    local clip = CreateFrame("Frame", nil, holder)
    clip:SetClipsChildren(true)
    clip:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, ROOM)
    clip:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, -ROOM)
    return clip
end

local function build()
    if holder then
        return
    end
    holder = CreateFrame("Frame")
    holder:Hide()
    -- As Blizzard's class nameplate bars: one size on screen, whatever the plate's scale.
    holder:SetIgnoreParentScale(true)
    -- Wider than the points by the room, so art past the first and last isn't cut off.
    gate = unseenBar(0, 1)
    gate:SetPoint("TOPLEFT", -ROOM, 0)
    gate:SetPoint("BOTTOMRIGHT", ROOM, 0)
    local sockets = clipOver(gate)
    for i = 1, maxPoints() do
        local slot = CreateFrame("Frame", nil, holder)
        -- Full from point i on, empty before it: the count is only ever handed to the bar.
        local dot = CreateFrame("StatusBar", nil, slot)
        dot:SetAllPoints(slot)
        dot:SetMinMaxValues(i - 1, i)
        dot:SetValue(0)
        bars[#bars + 1] = dot
        local bar = unseenBar(i - 1, i)
        bar:SetAllPoints(slot)
        local full = clipOver(bar)
        full:SetFrameLevel(sockets:GetFrameLevel() + 1)
        points[i] = { slot = slot, dot = dot, bar = bar, empty = sockets, full = full, art = {} }
    end
end

-- The art of one layer list on a point, in textures kept for it: each an atlas at its own size,
-- off the pixel grid as Blizzard's class bars set theirs (snapToPixelGrid false, texelSnappingBias
-- 0), since a nameplate doesn't sit on whole pixels. The art drawn at twice the size is used
-- where the client has it, at the plain one's size, so it stays sharp when Size makes it bigger.
local function dress(point, key, layers)
    local parent = point[key]
    for i, layer in ipairs(layers) do
        local name = key .. i
        local texture = point.art[name]
        if not texture then
            texture = parent:CreateTexture(nil, "ARTWORK", nil, i)
            if texture.SetSnapToPixelGrid then
                texture:SetSnapToPixelGrid(false)
                texture:SetTexelSnappingBias(0)
            end
            point.art[name] = texture
        end
        local atlas = layer[1]
        local info = C_Texture.GetAtlasInfo(atlas)
        texture:SetAtlas(HasAtlas(atlas .. "-2x") and atlas .. "-2x" or atlas)
        texture:SetSize(info and info.width or POINT, info and info.height or POINT)
        texture:ClearAllPoints()
        texture:SetPoint("CENTER", point.slot, "CENTER", layer[2] or 0, layer[3] or 0)
        texture:Show()
    end
end

-- The points as the look picked draws them, laid out in a row in the middle of the holder.
local function applyLook()
    local look = module.db.icon
    local socketed = SOCKETED[look]
    local size = socketed and POINT or PLAIN_POINT
    local gap = socketed and socketed.gap or PLAIN_GAP
    holder:SetSize(#points * size + (#points - 1) * gap, size)
    for i, point in ipairs(points) do
        point.slot:SetSize(size, size)
        point.slot:ClearAllPoints()
        point.slot:SetPoint("LEFT", (i - 1) * (size + gap), 0)
        for _, texture in pairs(point.art) do
            texture:Hide()
        end
        if socketed then
            dress(point, "empty", socketed.empty)
            dress(point, "full", socketed.full)
        else
            point.dot:SetStatusBarTexture(PLAIN[look] or PLAIN.red)
        end
        point.dot:SetShown(not socketed)
        point.bar:SetShown(socketed ~= nil)
        point.full:SetShown(socketed ~= nil)
    end
    gate:SetShown(socketed ~= nil)
    points[1].empty:SetShown(socketed ~= nil)
    holder:SetScale(BAR_SCALE * module.db.size / 100)
end

local function update()
    if not holder or not holder:IsShown() then
        return
    end
    local count
    if module.db.preview then
        -- Debug's preview: none, then one more each second up to them all, and round again.
        count = floor(GetTime()) % (#points + 1)
    else
        count = GetComboPoints("player", "target")
    end
    for _, bar in ipairs(bars) do
        bar:SetValue(count)
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

-- Puts the points on the target's plate, or hides them without one (no target, a plate off
-- screen, or a friendly plate the game forbids addons).
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
    holder:SetFrameLevel(frame:GetFrameLevel() + 5)
    holder:SetScript("OnUpdate", module.db.preview and onUpdate or nil)
    holder:Show()
    update()
end

-- Debug's button: what the client gives for the target's combo points, and whether it can be read.
local function printPoints()
    local count = GetComboPoints("player", "target")
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    ns.Print(L.NAMEPLATECOMBO_PRINT_LINE:format(
        ns.IsReadable(count) and tostring(count) or "secret", maxPoints(),
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
    -- Plates are pooled: the points come off before this one shows another unit.
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
