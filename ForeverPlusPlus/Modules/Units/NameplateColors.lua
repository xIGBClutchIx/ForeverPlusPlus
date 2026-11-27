-- Mob Type Nameplate Colors: the health bar of an enemy NPC's nameplate in a color for what it is
-- (a boss, a rare, an elite, a caster), on Blizzard's own plate. A feature request, issue #27.
--
-- Blizzard's CompactUnitFrame_UpdateHealthColor (Blizzard_UnitFrame/Shared/CompactUnitFrame.lua,
-- build 1.60.1.70205) never looks at what kind of mob a unit is: a bar is its threat color, gray
-- for a tapped mob, or the selection color. It sets the color only when it differs from what the
-- bar shows, so our hook on SetStatusBarColor remembers what it set and paints over it, as Player
-- Nameplates does for players' bars, and puts Blizzard's back when the plate goes to another unit.
--
-- Two of Blizzard's colors mean more than ours and are left alone: a tapped mob's gray, and its
-- threat colors (GAINING_THREAT_COLOR and HIGH_THREAT_COLOR, shown in a group with Health Bar Color
-- on under Options > Nameplates > Aggro Display). Whether a bar shows one is asked the way Blizzard
-- asks it (showsThreat), never told from the color: a mob fighting the player is plain red, which
-- matched a threat color and left every mob in combat unpainted.
--
-- What a mob is comes from UnitClassification, UnitIsBossMob and UnitHasPowerType, none of which
-- the client's API notes mark as secret; each is still read through ns.IsReadable, and a plate
-- whose answer can't be read keeps Blizzard's color. Not yet checked in a dungeon, in combat.
local _, ns = ...

local type, tostring, setmetatable = type, tostring, setmetatable
local UnitIsPlayer, UnitCanAttack, UnitIsTapDenied, UnitExists = UnitIsPlayer, UnitCanAttack, UnitIsTapDenied, UnitExists
local UnitInParty, UnitThreatSituation, UnitThreatLeadSituation = UnitInParty, UnitThreatSituation, UnitThreatLeadSituation
local C_NamePlate = C_NamePlate
local UnitClassification, UnitIsBossMob, UnitHasPowerType = UnitClassification, UnitIsBossMob, UnitHasPowerType

local L = ns.L
local readable = ns.IsReadable

local module = ns.NewModule("NameplateColors", L.NAMEPLATECOLORS_DESC, {
    enabled = false,
    boss = "purple",
    rare = "lightblue",
    elite = "orange",
    caster = "blue",
    preview = "off", -- Debug: every enemy NPC's plate as this kind
})
module.title = L.NAMEPLATECOLORS_TITLE
module.category = "units"
module.added = "1.10.0"
module.quickToggle = "nameplates"

-- The colors a kind can have, each unlike the ones Blizzard's own bars mean something by: hostile
-- red, tapped gray, and its threat colors. The names are the nameplate options' shared ones.
local COLORS = {
    purple = { 0.70, 0.30, 0.95 },
    lightblue = { 0.45, 0.80, 1.00 },
    blue = { 0.30, 0.50, 1.00 },
    orange = { 1.00, 0.55, 0.10 },
    yellow = { 1.00, 0.90, 0.20 },
    green = { 0.30, 0.90, 0.35 },
    pink = { 1.00, 0.50, 0.80 },
    white = { 1.00, 1.00, 1.00 },
}
local CHOICES = {
    { "off", L.NAMEPLATECOLORS_OFF },
    { "purple", L.PLATES_COLOR_PURPLE },
    { "lightblue", L.NAMEPLATECOLORS_LIGHT_BLUE },
    { "blue", L.PLATES_COLOR_BLUE },
    { "orange", L.PLATES_COLOR_ORANGE },
    { "yellow", L.PLATES_COLOR_YELLOW },
    { "green", L.PLATES_COLOR_GREEN },
    { "pink", L.PLATES_COLOR_PINK },
    { "white", L.PLATES_COLOR_WHITE },
}

module.options = {
    { key = "boss", name = L.NAMEPLATECOLORS_BOSS, description = L.NAMEPLATECOLORS_BOSS_DESC, choices = CHOICES },
    { key = "rare", name = L.NAMEPLATECOLORS_RARE, description = L.NAMEPLATECOLORS_RARE_DESC, choices = CHOICES },
    { key = "elite", name = L.NAMEPLATECOLORS_ELITE, description = L.NAMEPLATECOLORS_ELITE_DESC, choices = CHOICES },
    { key = "caster", name = L.NAMEPLATECOLORS_CASTER, description = L.NAMEPLATECOLORS_CASTER_DESC,
        choices = CHOICES },
    { key = "preview", name = L.NAMEPLATECOLORS_PREVIEW, description = L.NAMEPLATECOLORS_PREVIEW_DESC,
        choices = {
            { "off", L.NAMEPLATECOLORS_OFF },
            { "boss", L.NAMEPLATECOLORS_BOSS },
            { "rare", L.NAMEPLATECOLORS_RARE },
            { "elite", L.NAMEPLATECOLORS_ELITE },
            { "caster", L.NAMEPLATECOLORS_CASTER },
        },
        debug = true, section = L.DEBUG_SECTION_PREVIEWS },
}
module.notice = { text = L.NAMEPLATECOLORS_THREAT, description = L.NAMEPLATECOLORS_THREAT_DESC }

local weak = { __mode = "k" }
local unitOf = setmetatable({}, weak) -- bar -> the unit its plate shows
local frameOf = setmetatable({}, weak) -- bar -> its plate's UnitFrame
local blizzardColor = setmetatable({}, weak) -- bar -> { r, g, b } as Blizzard last set it
local painted = setmetatable({}, weak) -- bar -> true while it shows our color
local painting = false -- our own SetStatusBarColor, so the hook lets it by

-- A value read, or nil when it's secret.
local function read(value)
    if readable(value) then
        return value
    end
    return nil
end

-- Whether a unit is one we'd color at all: an NPC the player can attack, as far as the client says.
local function isEnemyNpc(unit)
    return read(UnitIsPlayer(unit)) == false and read(UnitCanAttack("player", unit)) == true
end

-- The kind of mob a unit is, as an option's key, or nil for one we don't color: a player, a unit
-- that can't be attacked, or anything the client won't say.
local function kindOf(unit)
    local db = module.db
    if not isEnemyNpc(unit) then
        return nil
    end
    local classification = read(UnitClassification(unit))
    if type(classification) ~= "string" then
        return nil
    end
    -- A kind set to Off isn't colored, and the mob counts as the next kind it also is.
    local boss, rare, elite, caster = COLORS[db.boss], COLORS[db.rare], COLORS[db.elite], COLORS[db.caster]
    if boss and (classification == "worldboss" or UnitIsBossMob and read(UnitIsBossMob(unit)) == true) then
        return "boss"
    elseif rare and (classification == "rare" or classification == "rareelite") then
        return "rare"
    elseif elite and (classification == "elite" or classification == "rareelite") then
        return "elite"
    end
    local mana = Enum and Enum.PowerType and Enum.PowerType.Mana
    if caster and UnitHasPowerType and mana and read(UnitHasPowerType(unit, mana)) == true then
        return "caster"
    end
    return nil
end

-- Whether a threat reading means a threat color: any threat above none, or one we can't read.
local function isThreat(situation)
    if not readable(situation) then
        return true
    end
    return type(situation) == "number" and situation > 0
end

-- Whether Blizzard is showing its threat color on a bar, which we leave. It does (CompactUnitFrame's
-- ShouldUseThreatHealthBarColor) only with Health Bar Color on, which the plate keeps as
-- displayThreatHealthBarColor, in a party, and with threat on the mob: the player's own, or for a
-- tank how close the next player is. We don't ask which the player is, so either counts.
local function showsThreat(bar, unit)
    local frame = frameOf[bar]
    if not (frame and frame.displayThreatHealthBarColor) then
        return false
    end
    if read(UnitInParty("player")) == false then
        return false
    end
    return isThreat(UnitThreatSituation("player", unit))
        or (UnitThreatLeadSituation ~= nil and isThreat(UnitThreatLeadSituation("player", unit)))
end

local function restore(bar)
    local old = blizzardColor[bar]
    painted[bar] = nil
    if old then
        painting = true
        bar:SetStatusBarColor(old[1], old[2], old[3])
        painting = false
    end
end

local function paint(bar)
    local unit = unitOf[bar]
    if not unit then
        return
    end
    -- Blizzard colored it before our hook saw: keep what it shows now to put back.
    if not blizzardColor[bar] then
        local r, g, b = bar:GetStatusBarColor()
        blizzardColor[bar] = { r, g, b }
    end
    -- Debug's Show All Mobs As: every enemy NPC as the one kind picked, whatever it is.
    local kind
    local forced = module.db.preview
    if forced ~= "off" then
        kind = isEnemyNpc(unit) and forced or nil
    else
        kind = kindOf(unit)
    end
    local tapped = read(UnitIsTapDenied(unit))
    if not kind or tapped ~= false or showsThreat(bar, unit) then
        if painted[bar] then
            restore(bar)
        end
        return
    end
    -- The preview shows a kind that's set to Off too, in the color it starts with.
    local color = COLORS[module.db[kind]] or COLORS[module.defaults[kind]]
    painting = true
    bar:SetStatusBarColor(color[1], color[2], color[3])
    painting = false
    painted[bar] = true
end

-- Remember what Blizzard sets, then paint over it again.
local function onColored(bar, r, g, b)
    if painting or not unitOf[bar] then
        return
    end
    blizzardColor[bar] = { r, g, b }
    paint(bar)
end

-- Blizzard's health bar on a plate, or nil on a build without it.
local function barOf(frame)
    local container = ns.Nameplates.Parts(frame).container
    local bar = frame.healthBar or container and container.healthBar
    return bar and bar.SetStatusBarColor and bar.GetStatusBarColor and bar or nil
end

local handlers = {
    OnAdded = function(unit, frame)
        local bar = barOf(frame)
        if bar then
            unitOf[bar], frameOf[bar] = unit, frame
            module:Hook(bar, "SetStatusBarColor", onColored)
            paint(bar)
        end
    end,
    -- Plates are pooled: the next unit's bar starts from Blizzard's color.
    OnRemoved = function(_, frame)
        local bar = barOf(frame)
        if bar then
            if painted[bar] then
                restore(bar)
            end
            unitOf[bar], frameOf[bar], blizzardColor[bar] = nil, nil, nil
        end
    end,
}

-- Debug's button: what the client says about the target, whether each answer can be read, and
-- what we make of it. For checking in a dungeon and in combat, where an answer may be secret.
local function shown(value)
    if not readable(value) then
        return "secret"
    end
    return tostring(value)
end

local function printTarget()
    local unit = "target"
    if not UnitExists(unit) then
        ns.Print(L.NAMEPLATECOLORS_PRINT_NONE)
        return
    end
    local mana = Enum and Enum.PowerType and Enum.PowerType.Mana
    local frame = ns.Nameplates.FrameFor(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local bar = (frame and barOf(frame)) or (plate and plate.UnitFrame and barOf(plate.UnitFrame))
    ns.Print(L.NAMEPLATECOLORS_PRINT_LINE:format(
        shown(UnitClassification(unit)),
        UnitIsBossMob and shown(UnitIsBossMob(unit)) or "-",
        UnitHasPowerType and mana and shown(UnitHasPowerType(unit, mana)) or "-",
        shown(UnitIsTapDenied(unit)),
        shown(UnitCanAttack("player", unit)),
        shown(UnitIsPlayer(unit)),
        bar and frameOf[bar] and tostring(showsThreat(bar, unit)) or "-",
        tostring(kindOf(unit))))
end

module.debugActions = {
    {
        name = L.NAMEPLATECOLORS_PRINT, button = L.NAMEPLATECOLORS_PRINT_BUTTON,
        description = L.NAMEPLATECOLORS_PRINT_DESC, section = L.DEBUG_SECTION_DIAGNOSTICS, fn = printTarget,
    },
}

local function repaint()
    ns.Nameplates.ForEach(function(_, frame)
        local bar = barOf(frame)
        if bar then
            paint(bar)
        end
    end)
end

-- A mob another player tapped, or one that turned hostile or attackable, with its plate still up.
local function onUnitChanged(_, unit)
    local frame = unit and ns.Nameplates.FrameFor(unit)
    local bar = frame and barOf(frame)
    if bar then
        paint(bar)
    end
end

function module:OnEnable()
    ns.Nameplates.Register(self, handlers)
    self:On("UNIT_FACTION", onUnitChanged)
    -- Joining or leaving a party is when Blizzard's threat colors start and stop.
    self:On("GROUP_ROSTER_UPDATE", repaint)
    if ns.HasEvent("UNIT_CLASSIFICATION_CHANGED") then
        self:On("UNIT_CLASSIFICATION_CHANGED", onUnitChanged)
    end
end

function module:OnDisable()
    ns.Nameplates.Unregister(self) -- calls OnRemoved for every plate, which puts the colors back
end

function module:OnOptionChanged()
    if self.enabled then
        repaint()
    end
end
