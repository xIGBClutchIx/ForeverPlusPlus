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
-- need barWhenHurt, level, buffs, nameSize, centerLine, and `saved = {}` for the CVars.
local _, ns = ...

local pairs, ipairs, setmetatable, hooksecurefunc = pairs, ipairs, setmetatable, hooksecurefunc
local UnitIsPlayer, UnitIsFriend, UnitIsUnit = UnitIsPlayer, UnitIsFriend, UnitIsUnit
local UnitAffectingCombat, UnitHealthPercent = UnitAffectingCombat, UnitHealthPercent
local UnitHealth, UnitHealthMax, pcall, max = UnitHealth, UnitHealthMax, pcall, math.max

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

-- Blizzard's buff row (UnitFrame.AurasFrame.BuffListFrame) sits beside the bar, to the left of its
-- classification icon, so on a name-only plate it floats far left of the name. There it moves to
-- the module's Buffs setting (`buffs`): above the whole row (level, name, and icons), or beside it
-- past the level and icons, so it never covers them. The subtitle and cast bar are below the
-- name, so neither choice reaches them. The buff row sizes itself to its icons.
-- The row is a restricted region: its anchors can be set but never read, so we put back
-- Blizzard's anchor from its XML (Blizzard_NamePlates.xml; Lua never changes it). pcall, so a
-- client that refuses the anchor can't stop the fade around it.
local BUFF_ABOVE_GAP = 6
local BUFF_SIDE_GAP = 4
-- While the bar shows: left of the bar itself, with room between. (Blizzard anchors past the
-- classification icon instead, which sat the row too close; a bigger offset from that icon
-- moved it inward on Forever, so the icon isn't where its XML suggests.)
local BUFF_BAR_GAP = 8

---@param where string "above", "before", "after", "bar" (beside the bar), or "blizzard"
---(Blizzard's own anchor, for giving the plate back)
local function anchorBuffs(record, where)
    local buffs, label = record.buffs, record.label
    if not (buffs and record.classification and label) then
        return
    end
    local x
    local shift = label.nameShift or 0
    if where == "above" then
        -- The name sits off the row's center by its shift; undo it to center on the row.
        x = -shift
    elseif where == "before" or where == "after" then
        -- Past the level and icons on that side, or past the guild/title line under the name if
        -- that reaches further (it's centered on the row, and often longer than the name).
        local before = where == "before"
        local reach = (before and label.leftWidth or label.rightWidth) or 0
        if label.subtitle:IsShown() then
            local nameWidth, subWidth = label.name:GetStringWidth(), label.subtitle:GetStringWidth()
            if readable(nameWidth) and readable(subWidth) then
                local overhang = (subWidth - nameWidth) / 2 + (before and shift or -shift)
                reach = max(reach, overhang)
            end
        end
        x = (before and -1 or 1) * (reach + BUFF_SIDE_GAP)
    end
    -- Untouched plates stay untouched, and an unchanged spot isn't set again.
    if (record.buffsWhere or "blizzard") == where and record.buffsX == x then
        return
    end
    record.buffsWhere, record.buffsX = where, x
    pcall(function()
        buffs:ClearAllPoints()
        if where == "above" then
            buffs:SetPoint("BOTTOM", label.name, "TOP", x, BUFF_ABOVE_GAP)
        elseif where == "before" then
            buffs:SetPoint("RIGHT", label.name, "LEFT", x, 0)
        elseif where == "after" then
            buffs:SetPoint("LEFT", label.name, "RIGHT", x, 0)
        elseif where == "bar" then
            buffs:SetPoint("RIGHT", record.container, "LEFT", -BUFF_BAR_GAP, 0)
        else
            buffs:SetPoint("RIGHT", record.classification, "LEFT", -5, 0)
        end
    end)
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
    extra.buffs = "above" -- where the buff row sits without the bar: see PlateLabel.BUFF_CHOICES
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
        -- The name, level, or icons may have moved; keep the buffs placed against them.
        if record.buffsWhere and record.buffsWhere ~= "blizzard" then
            anchorBuffs(record, record.buffsWhere)
        end
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
    if inCombat then
        shown, hidden = 1, 0
    elseif not self.module.db.barWhenHurt then
        shown, hidden = 0, 1
    elseif not curve then
        shown, hidden = 1, 0
    else
        -- The percent can be secret in combat, so the client maps it to an alpha, not Lua.
        shown, hidden = UnitHealthPercent(unit, true, curve), UnitHealthPercent(unit, true, inverse)
    end
    record.container:SetAlpha(shown)
    local label = record.label
    if label then
        fadeLevel(record, shown)
        -- Blizzard's name is always hidden: our label draws the name in both views.
        record.name:SetAlpha(0)
        label.barFrame:SetAlpha(shown)
        label:SetAlpha(hidden)
    end
    -- Whether the bar is surely hidden, for the buff row. The alpha above can be secret, so this
    -- asks again in plain terms. Friendly health reads as secret even out of combat; only health
    -- we can read as below full counts as the bar showing.
    local nameOnly = not inCombat
    if nameOnly and self.module.db.barWhenHurt then
        local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
        nameOnly = not (readable(health) and readable(maxHealth) and health < maxHealth)
    end
    anchorBuffs(record, nameOnly and self.module.db.buffs or "bar")
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
        record.buffs = parts.buffs
        record.classification = parts.classification
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
    anchorBuffs(record, "blizzard")
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
