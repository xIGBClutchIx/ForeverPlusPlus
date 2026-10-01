-- Friendly nameplates that always show the unit's name, and the health bar only while it's hurt or
-- in combat. Built on Blizzard's own nameplates: the bar and Blizzard's name fade, and our label
-- (ns.PlateLabel) shows instead. Player Nameplates and NPC Nameplates each run one of these for
-- their own kind of unit:
--
--   local plates = ns.FriendlyPlates.New(module, {
--       players = true,             -- friendly players, or false for friendly NPCs
--       cvars = { { names = { "cvarName", "olderName" }, value = "1" }, ... },
--       style = { NameColor = fn, Subtitle = fn, SubtitleColor = fn, icons = bool },
--       OnEnable = fn(module), -- optional: more to do when the module turns on
--   })
--   plates:Refresh() -- after a setting the plates draw from changed
--
-- New gives the module its OnEnable, OnDisable and OnOptionChanged (unless it has its own
-- OnDisable or OnOptionChanged). The module's settings come from FriendlyPlates.Defaults: they
-- need barWhenHurt, level, nameSize, centerLine, and `saved = {}` for the CVars.
local _, ns = ...

local pairs, ipairs, setmetatable, hooksecurefunc = pairs, ipairs, setmetatable, hooksecurefunc
local UnitIsPlayer, UnitIsFriend, UnitIsUnit = UnitIsPlayer, UnitIsFriend, UnitIsUnit
local UnitAffectingCombat, UnitHealthPercent = UnitAffectingCombat, UnitHealthPercent
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local min, max, C_Timer = math.min, math.max, C_Timer

local readable = ns.IsReadable
local Nameplates, PlateLabel = ns.Nameplates, ns.PlateLabel

local FriendlyPlates = {}
ns.FriendlyPlates = FriendlyPlates

local Plates = {}
Plates.__index = Plates

local weak = { __mode = "k" }
-- Blizzard name font string -> { plates, unit } while one of ours shows on its plate
local mirrored = setmetatable({}, weak)
local hookedNames = setmetatable({}, weak)
local curve -- health fraction -> alpha: 1 below full health, 0 at full
local inverse -- the opposite: 0 below full health, 1 at full

local EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_FLAGS", "UNIT_NAME_UPDATE", "UNIT_LEVEL" }
local SOCIAL_EVENTS = { "GROUP_ROSTER_UPDATE", "FRIENDLIST_UPDATE" }

-- Blizzard sets the name text (with surname) itself; our label copies it as it changes, and the
-- icons beside Blizzard's name move to where the new text ends.
local function onNameSet(fontString)
    local entry = mirrored[fontString]
    if entry then
        entry[1]:Layout(entry[2])
    end
end

local function hookName(name)
    if not hookedNames[name] then
        hookedNames[name] = true
        hooksecurefunc(name, "SetText", onNameSet)
    end
end

-- Blizzard's level at the bar's end. Which of the two frames draws the badge players see isn't
-- known yet (LevelFrame alone left it showing), so both fade with the bar.
local function fadeLevel(record, alpha)
    if record.levelFrame then
        record.levelFrame:SetAlpha(alpha)
    end
    if record.levelDiffFrame then
        record.levelDiffFrame:SetAlpha(alpha)
    end
end

-- The aura rows (UnitFrame.AurasFrame.BuffListFrame and DebuffListFrame, seen with Frame Stack on
-- Forever; may be nil elsewhere) line their icons up from the bar's left end, which sits left of
-- center. On a name-only plate we slide each row sideways so its icons center over our name.
-- Blizzard's anchors are kept as they are (only their x offset moves), so the row keeps its size,
-- and its icons are measured on screen, since we can't know how Blizzard sizes the row.
-- aura row -> { label, points = Blizzard's anchors, dx = our shift, busy } while we hold it
local centered = setmetatable({}, weak)
local hookedAuras = setmetatable({}, weak)

local function readPoints(list)
    local points = {}
    for i = 1, list:GetNumPoints() do
        points[i] = { list:GetPoint(i) }
    end
    return points
end

local function setPoints(list, points, dx)
    list:ClearAllPoints()
    for _, point in ipairs(points) do
        list:SetPoint(point[1], point[2], point[3], (point[4] or 0) + dx, point[5] or 0)
    end
end

-- The screen-space center of the row's shown icons, or nil when none is shown or laid out yet.
local function iconsCenter(list)
    local left, right
    for _, icon in ipairs({ list:GetChildren() }) do
        local shown = icon:IsShown()
        if readable(shown) and shown then
            local l, r, scale = icon:GetLeft(), icon:GetRight(), icon:GetEffectiveScale()
            if readable(l) and readable(r) and l and r then
                l, r = l * scale, r * scale
                left = left and min(left, l) or l
                right = right and max(right, r) or r
            end
        end
    end
    return left and (left + right) / 2
end

local function holdAuras(list)
    local held = centered[list]
    if not held then
        return
    end
    local target = held.label.name
    local x, scale = target:GetCenter(), target:GetEffectiveScale()
    local current = iconsCenter(list)
    if not (current and readable(x) and x) then
        return
    end
    held.dx = held.dx + (x * scale - current) / list:GetEffectiveScale()
    held.busy = true
    setPoints(list, held.points, held.dx)
    held.busy = false
end

-- Blizzard anchored the row again: those are its anchors now, and ours go on top of them.
local function onAurasPoint(list)
    local held = centered[list]
    if held and not held.busy then
        held.points, held.dx = readPoints(list), 0
        holdAuras(list)
    end
end

-- Blizzard laid the icons out again (one came or went): center the new set.
local function onAurasLayout(list)
    if centered[list] then
        holdAuras(list)
    end
end

local function centerFrame(list, label, on)
    local held = centered[list]
    if on and label then
        if not held then
            held = { label = label, points = readPoints(list), dx = 0 }
            centered[list] = held
            if not hookedAuras[list] then
                hookedAuras[list] = true
                hooksecurefunc(list, "SetPoint", onAurasPoint)
                if list.Layout then
                    hooksecurefunc(list, "Layout", onAurasLayout)
                end
            end
        end
        holdAuras(list)
        -- Icons can be laid out after this; measure again on the next frame.
        C_Timer.After(0, function() onAurasLayout(list) end)
    elseif held then
        centered[list] = nil
        setPoints(list, held.points, 0)
    end
end

-- Centers the plate's buff and debuff rows over our label (or gives them back to Blizzard's).
local function centerAuras(record, on)
    if record.auras then
        for _, list in ipairs(record.auras) do
            centerFrame(list, record.label, on)
        end
    end
end

---Friendly plates for one module (see the top of this file).
---@param module table
---@param spec table players, cvars, style
---@return table plates
function FriendlyPlates.New(module, spec)
    local self = setmetatable({ module = module, spec = spec, style = spec.style, records = {} }, Plates)
    self.onAdded = function(unit, frame) self:Add(unit, frame) end
    self.onRemoved = function(unit) self:Remove(unit) end
    self.onUnitEvent = function(event, unit)
        if self.records[unit] then
            if event == "UNIT_NAME_UPDATE" or event == "UNIT_LEVEL" then
                self:Layout(unit)
            end
            self:Fade(unit)
        end
    end
    self.onPlayerCombat = function()
        for unit in pairs(self.records) do
            self:Fade(unit)
        end
    end
    -- Group or friends changed: the icons may need to come or go.
    self.onSocialChange = function()
        for unit in pairs(self.records) do
            self:Layout(unit)
        end
    end
    -- The module's turning on and off and option changes are the same for every plate module. It
    -- keeps its own if it already has one, and `spec.OnEnable(module)` adds to turning on.
    function module.OnEnable(mod)
        self:Enable()
        if spec.OnEnable then
            spec.OnEnable(mod)
        end
    end
    module.OnDisable = module.OnDisable or function()
        self:Disable()
    end
    module.OnOptionChanged = module.OnOptionChanged or function(mod)
        if mod.enabled then
            self:Refresh()
        end
    end
    return self
end

---The settings every friendly plate module has, with `extra` (the module's own) added.
---@param extra table
---@return table defaults
function FriendlyPlates.Defaults(extra)
    extra.enabled = true
    extra.barWhenHurt = true
    extra.nameSize = 80 -- percent of Blizzard's name size
    extra.level = "before" -- "before", "after", or "off"
    extra.centerLine = false -- debug: a line through each plate's center
    extra.saved = {} -- CVar -> the player's own value, put back when the module turns off
    return extra
end

-- Whether this is one of ours: a friendly player (or NPC) we can read. The personal resource
-- display is a friendly player too, so leave out ourselves.
function Plates:IsOurs(unit)
    local isPlayer, isFriend, isSelf = UnitIsPlayer(unit), UnitIsFriend("player", unit),
        UnitIsUnit(unit, "player")
    if not (readable(isPlayer) and readable(isFriend) and readable(isSelf)) then
        return false
    end
    return isFriend and not isSelf and (isPlayer and true or false) == self.spec.players
end

function Plates:Layout(unit)
    local record = self.records[unit]
    if record and record.label then
        PlateLabel.Layout(record.label, record, unit, self.style)
    end
end

-- Fades the bar (and Blizzard's name and level with it) in when the unit is hurt or in combat,
-- and our label in when it isn't.
function Plates:Fade(unit)
    local record = self.records[unit]
    if not record then
        return
    end
    local inCombat = UnitAffectingCombat(unit)
    if not readable(inCombat) then
        inCombat = UnitAffectingCombat("player")
    end
    local shown, hidden
    local nameOnly = false
    if inCombat then
        shown, hidden = 1, 0
    elseif not self.module.db.barWhenHurt then
        shown, hidden = 0, 1
        nameOnly = true
    elseif not curve then
        shown, hidden = 1, 0
    else
        -- The percent can be secret in combat, so the client maps it to an alpha, not Lua.
        shown, hidden = UnitHealthPercent(unit, true, curve), UnitHealthPercent(unit, true, inverse)
        -- Friendly health reads as secret even out of combat (seen on Forever), so only a
        -- readable reading below full health counts as the bar showing; otherwise name-only.
        local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
        nameOnly = not (readable(health) and readable(maxHealth) and health < maxHealth)
    end
    centerAuras(record, nameOnly)
    record.container:SetAlpha(shown)
    local label = record.label
    if label then
        fadeLevel(record, shown)
        -- Blizzard's name is always hidden: our label draws the name in both views.
        record.name:SetAlpha(0)
        label.barFrame:SetAlpha(shown)
        label:SetAlpha(hidden)
    end
end

function Plates:Add(unit, frame)
    local parts = Nameplates.Parts(frame)
    if not (parts.container and self:IsOurs(unit)) then
        return
    end
    local record = { container = parts.container }
    local name = parts.name
    if name and name.SetText then
        record.name = name
        record.levelFrame = parts.level
        record.levelDiffFrame = parts.levelDiff
        record.castBar = parts.castBar
        -- Frame Stack on Forever: UnitFrame.AurasFrame.BuffListFrame holds the buff icons.
        local auras = frame.AurasFrame
        if auras then
            record.auras = {}
            for _, list in ipairs({ auras.BuffListFrame, auras.DebuffListFrame }) do
                record.auras[#record.auras + 1] = list
            end
        end
        record.label = PlateLabel.Show(frame)
        hookName(name)
        mirrored[name] = { self, unit }
    end
    self.records[unit] = record
    self:Layout(unit)
    self:Fade(unit)
end

-- Plates are pooled, so everything we changed goes back as the plate leaves.
function Plates:Remove(unit)
    local record = self.records[unit]
    if not record then
        return
    end
    self.records[unit] = nil
    centerAuras(record, false)
    record.container:SetAlpha(1)
    fadeLevel(record, 1)
    if record.name then
        record.name:SetAlpha(1)
        mirrored[record.name] = nil
    end
    if record.label then
        PlateLabel.Hide(record.label)
    end
end

---Lays out and fades every plate again, after a setting changed.
function Plates:Refresh()
    for unit in pairs(self.records) do
        self:Layout(unit)
        self:Fade(unit)
    end
end

---Sets the CVars, and starts handling plates and their events (through module:On, so they stop
---when the module turns off).
function Plates:Enable()
    local module = self.module
    if not curve then
        curve, inverse = ns.HealthStepCurve(1, 0), ns.HealthStepCurve(0, 1)
    end
    self.style.db = module.db
    for _, entry in ipairs(self.spec.cvars) do
        ns.CVars.Set(module.db.saved, entry.names, entry.value)
    end
    for _, event in ipairs(EVENTS) do
        module:On(event, self.onUnitEvent)
    end
    if self.style.icons then
        for _, event in ipairs(SOCIAL_EVENTS) do
            module:On(event, self.onSocialChange)
        end
    end
    -- UNIT_FLAGS covers other units' combat; these cover the fallback to our own.
    module:On("PLAYER_REGEN_DISABLED", self.onPlayerCombat)
    module:On("PLAYER_REGEN_ENABLED", self.onPlayerCombat)
    Nameplates.Register(self, {
        OnAdded = self.onAdded,
        OnRemoved = self.onRemoved,
        OnCastBar = function(unit) self:Layout(unit) end,
    })
end

---Gives every plate back to Blizzard and puts the player's CVars back.
function Plates:Disable()
    Nameplates.Unregister(self)
    ns.CVars.RestoreAll(self.module.db.saved)
end
