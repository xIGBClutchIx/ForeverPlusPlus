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
-- on under Options > Nameplates > Threat Display). Which is which is told from the color Blizzard
-- just set, so nothing about threat is read here.
--
-- What a mob is comes from UnitClassification, UnitIsBossMob and UnitHasPowerType, none of which
-- the client's API notes mark as secret; each is still read through ns.IsReadable, and a plate
-- whose answer can't be read keeps Blizzard's color. Not yet checked in a dungeon, in combat.
local _, ns = ...

local ipairs, type, tostring, setmetatable, _G = ipairs, type, tostring, setmetatable, _G
local UnitIsPlayer, UnitCanAttack, UnitIsTapDenied, UnitExists = UnitIsPlayer, UnitCanAttack, UnitIsTapDenied, UnitExists
local C_NamePlate = C_NamePlate
local UnitClassification, UnitIsBossMob, UnitHasPowerType = UnitClassification, UnitIsBossMob, UnitHasPowerType

local L = ns.L
local readable = ns.IsReadable

local module = ns.NewModule("NameplateColors", L.NAMEPLATECOLORS_DESC, {
    enabled = false,
    boss = true,
    rare = true,
    elite = true,
    caster = true,
    preview = false, -- Debug: every enemy NPC's plate as a made-up kind
})
module.title = L.NAMEPLATECOLORS_TITLE
module.category = "units"
module.added = "1.9.2"
module.quickToggle = "nameplates"

module.options = {
    { key = "boss", name = L.NAMEPLATECOLORS_BOSS, description = L.NAMEPLATECOLORS_BOSS_DESC },
    { key = "rare", name = L.NAMEPLATECOLORS_RARE, description = L.NAMEPLATECOLORS_RARE_DESC },
    { key = "elite", name = L.NAMEPLATECOLORS_ELITE, description = L.NAMEPLATECOLORS_ELITE_DESC },
    { key = "caster", name = L.NAMEPLATECOLORS_CASTER, description = L.NAMEPLATECOLORS_CASTER_DESC },
    { key = "preview", name = L.NAMEPLATECOLORS_PREVIEW, description = L.NAMEPLATECOLORS_PREVIEW_DESC,
        debug = true, section = L.DEBUG_SECTION_PREVIEWS },
}
module.notice = { text = L.NAMEPLATECOLORS_THREAT, description = L.NAMEPLATECOLORS_THREAT_DESC }

-- One color a kind, each unlike Blizzard's own bar colors (hostile red, neutral yellow, friendly
-- green, tapped gray, and the threat colors).
local COLORS = {
    boss = { 0.70, 0.30, 0.95 }, -- purple
    rare = { 0.45, 0.80, 1.00 }, -- light blue
    elite = { 1.00, 0.55, 0.10 }, -- orange
    caster = { 0.30, 0.50, 1.00 }, -- blue
}

local weak = { __mode = "k" }
local unitOf = setmetatable({}, weak) -- bar -> the unit its plate shows
local blizzardColor = setmetatable({}, weak) -- bar -> { r, g, b } as Blizzard last set it
local painted = setmetatable({}, weak) -- bar -> true while it shows our color
local painting = false -- our own SetStatusBarColor, so the hook lets it by
-- Debug's Preview Mob Type Colors: the kind each bar is made out to be, dealt in turn as plates come.
local PREVIEW_KINDS = { "boss", "rare", "elite", "caster" }
local previewKind = setmetatable({}, weak)
local dealt = 0

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
    if db.boss and (classification == "worldboss" or UnitIsBossMob and read(UnitIsBossMob(unit)) == true) then
        return "boss"
    elseif db.rare and (classification == "rare" or classification == "rareelite") then
        return "rare"
    elseif db.elite and (classification == "elite" or classification == "rareelite") then
        return "elite"
    end
    local mana = Enum and Enum.PowerType and Enum.PowerType.Mana
    if db.caster and UnitHasPowerType and mana and read(UnitHasPowerType(unit, mana)) == true then
        return "caster"
    end
    return nil
end

-- Whether a color is one of Blizzard's that we leave: a threat color, or one we can't read.
local function isTheirs(r, g, b)
    if not (readable(r) and readable(g) and readable(b)) then
        return true
    end
    for _, name in ipairs({ "GAINING_THREAT_COLOR", "HIGH_THREAT_COLOR" }) do
        local color = _G[name]
        if type(color) == "table" and color.GetRGB then
            local tr, tg, tb = color:GetRGB()
            if r == tr and g == tg and b == tb then
                return true
            end
        end
    end
    return false
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
    local theirs = blizzardColor[bar]
    local kind
    if module.db.preview then
        if isEnemyNpc(unit) then
            if not previewKind[bar] then
                dealt = dealt % #PREVIEW_KINDS + 1
                previewKind[bar] = PREVIEW_KINDS[dealt]
            end
            kind = previewKind[bar]
        end
    else
        kind = kindOf(unit)
    end
    local tapped = read(UnitIsTapDenied(unit))
    if not kind or tapped ~= false or isTheirs(theirs[1], theirs[2], theirs[3]) then
        if painted[bar] then
            restore(bar)
        end
        return
    end
    local color = COLORS[kind]
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
            unitOf[bar] = unit
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
            unitOf[bar], blizzardColor[bar], previewKind[bar] = nil, nil, nil
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
    local theirs = bar and blizzardColor[bar]
    ns.Print(L.NAMEPLATECOLORS_PRINT_LINE:format(
        shown(UnitClassification(unit)),
        UnitIsBossMob and shown(UnitIsBossMob(unit)) or "-",
        UnitHasPowerType and mana and shown(UnitHasPowerType(unit, mana)) or "-",
        shown(UnitIsTapDenied(unit)),
        shown(UnitCanAttack("player", unit)),
        shown(UnitIsPlayer(unit)),
        theirs and tostring(isTheirs(theirs[1], theirs[2], theirs[3])) or "-",
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
