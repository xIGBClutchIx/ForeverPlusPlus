-- Friendly Nameplates: which plates we handle, fading the bar with health, the events, and
-- turning the module on and off.
local _, ns = ...

local pairs, ipairs, setmetatable, hooksecurefunc = pairs, ipairs, setmetatable, hooksecurefunc
local UnitIsPlayer, UnitIsFriend, UnitIsUnit = UnitIsPlayer, UnitIsFriend, UnitIsUnit
local UnitAffectingCombat, UnitHealthPercent = UnitAffectingCombat, UnitHealthPercent

local module = ns.modules.FriendlyPlates
local P = module.internal
local readable = ns.IsReadable
local Nameplates = ns.Nameplates

-- The CVars that make friendly player nameplates show with a bar. Each entry lists the names
-- the setting has had, newest first; the first one this client knows is used.
local CVARS = {
    { names = { "nameplateShowFriendlyPlayers", "nameplateShowFriends" }, value = "1" },
    -- Blizzard's names-only mode drops the bar entirely, so it could never come back when hurt.
    { names = { "nameplateShowOnlyNameForFriendlyPlayerUnits", "nameplateShowOnlyNames" }, value = "0" },
    -- Blizzard's own name, shown while the bar is up, stays plain white; class color is for ours.
    { names = { "nameplateUseClassColorForFriendlyPlayerUnitNames" }, value = "0" },
    -- Only while the Friendly NPCs option is on.
    { names = { "nameplateShowFriendlyNpcs", "nameplateShowFriendlyNPCs" }, value = "1", option = "npcs" },
}

local weak = { __mode = "k" }
local plates = {} -- nameplate unit -> record { container, name, label, ... }, while we manage it
local mirrored = setmetatable({}, weak) -- Blizzard name font string -> the unit it belongs to
local hookedNames = setmetatable({}, weak)
local curve -- health fraction -> alpha: 1 below full health, 0 at full
local inverse -- the opposite: 0 below full health, 1 at full

-- Sets our CVars, or gives the player's own values back for options that are off.
local function applyCVars()
    local saved = module.db.saved
    for _, entry in ipairs(CVARS) do
        if entry.option and not module.db[entry.option] then
            ns.CVars.Restore(saved, entry.names)
        else
            ns.CVars.Set(saved, entry.names, entry.value)
        end
    end
end

local function refresh(unit)
    local record = plates[unit]
    if record and record.label then
        P.LayoutLabel(record.label, record, unit)
    end
end

-- Blizzard sets the name text (with surname) itself; our label copies it as it changes, and the
-- icons beside Blizzard's name move to where the new text ends.
local function onNameSet(fontString)
    local unit = mirrored[fontString]
    if unit then
        refresh(unit)
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

-- Whether we handle this unit: a friendly player, or a friendly NPC when that option is on, that
-- we can read. Returns whether it's a player as the second value. The personal resource display
-- is a friendly player too, so leave out ourselves.
local function isOurs(unit)
    local isPlayer, isFriend, isSelf = UnitIsPlayer(unit), UnitIsFriend("player", unit),
        UnitIsUnit(unit, "player")
    if not (readable(isPlayer) and readable(isFriend) and readable(isSelf)) then
        return false
    end
    return isFriend and not isSelf and (isPlayer or module.db.npcs), isPlayer
end

-- Fades the bar (and Blizzard's name and level with it) in when the unit is hurt or in combat,
-- and our label in when it isn't.
local function update(unit)
    local record = plates[unit]
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
    elseif not module.db.barWhenHurt then
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
        record.name:SetAlpha(shown)
        label.barFrame:SetAlpha(shown)
        label:SetAlpha(hidden)
    end
end

local function add(unit, frame)
    local parts = Nameplates.Parts(frame)
    if not parts.container then
        return
    end
    local ours, isPlayer = isOurs(unit)
    if not ours then
        return
    end
    local record = { container = parts.container, plate = parts.plate, isPlayer = isPlayer }
    local name = parts.name
    if name and name.SetText then
        record.name = name
        record.levelFrame = parts.level
        record.levelDiffFrame = parts.levelDiff
        record.castBar = parts.castBar
        record.label = P.GetLabel(frame)
        record.label:Show()
        record.label.barFrame:Show()
        record.label.debugFrame:Show()
        hookName(name)
        mirrored[name] = unit
    end
    plates[unit] = record
    refresh(unit)
    update(unit)
end

-- Plates are pooled, so everything we changed goes back as the plate leaves.
local function remove(unit)
    local record = plates[unit]
    if not record then
        return
    end
    plates[unit] = nil
    record.container:SetAlpha(1)
    fadeLevel(record, 1)
    if record.name then
        record.name:SetAlpha(1)
        mirrored[record.name] = nil
    end
    if record.label then
        record.label:Hide()
        record.label.barFrame:Hide()
        record.label.debugFrame:Hide()
    end
end

local plateHandlers = {
    OnAdded = add,
    OnRemoved = remove,
    OnCast = refresh,
}

-- Called by Settings when an option changes.
function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "npcs" then
        applyCVars()
        for unit in pairs(plates) do
            remove(unit)
        end
        Nameplates.ForEach(add)
        return
    end
    for unit in pairs(plates) do
        refresh(unit)
        update(unit)
    end
end

function module.OnUnitEvent(event, unit)
    if plates[unit] then
        if event == "UNIT_NAME_UPDATE" or event == "UNIT_LEVEL" then
            refresh(unit)
        end
        update(unit)
    end
end

function module.OnPlayerCombat()
    for unit in pairs(plates) do
        update(unit)
    end
end

-- Group or friends changed: the icons may need to come or go.
function module.OnSocialChange()
    for unit in pairs(plates) do
        refresh(unit)
    end
end

local EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_FLAGS", "UNIT_NAME_UPDATE", "UNIT_LEVEL" }
local SOCIAL_EVENTS = { "GROUP_ROSTER_UPDATE", "FRIENDLIST_UPDATE" }

function module:OnEnable()
    if not curve then
        curve, inverse = ns.HealthStepCurve(1, 0), ns.HealthStepCurve(0, 1)
    end
    applyCVars()
    for _, event in pairs(EVENTS) do
        self:On(event, self.OnUnitEvent)
    end
    for _, event in pairs(SOCIAL_EVENTS) do
        self:On(event, self.OnSocialChange)
    end
    -- UNIT_FLAGS covers other players' combat; these cover the fallback to our own.
    self:On("PLAYER_REGEN_DISABLED", self.OnPlayerCombat)
    self:On("PLAYER_REGEN_ENABLED", self.OnPlayerCombat)
    Nameplates.Register(self, plateHandlers)
end

function module:OnDisable()
    Nameplates.Unregister(self)
    ns.CVars.RestoreAll(self.db.saved)
end
