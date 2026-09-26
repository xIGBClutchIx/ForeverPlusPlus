-- Friendly player nameplates that always show the name, and show the health bar only while that
-- player is hurt or in combat. Uses Blizzard's own nameplates; only the bar's alpha changes.
local _, ns = ...

local pairs, setmetatable = pairs, setmetatable
local C_CVar, C_NamePlate, C_CurveUtil = C_CVar, C_NamePlate, C_CurveUtil
local InCombatLockdown, UnitHealthPercent = InCombatLockdown, UnitHealthPercent
local UnitIsPlayer, UnitIsFriend, UnitIsUnit = UnitIsPlayer, UnitIsFriend, UnitIsUnit
local UnitAffectingCombat = UnitAffectingCombat

local module = ns.NewModule("FriendlyPlates",
    "Friendly players always show their name; the health bar shows only when hurt or in combat.",
    {
        enabled = false,
        saved = {}, -- CVar -> the player's own value, put back when the module turns off
    })

-- The CVars that make friendly player nameplates show with a bar. Each entry lists the names
-- the setting has had, newest first; the first one this client knows is used.
local CVARS = {
    { names = { "nameplateShowFriendlyPlayers", "nameplateShowFriends" }, value = "1" },
    -- Blizzard's names-only mode drops the bar entirely, so it could never come back when hurt.
    { names = { "nameplateShowOnlyNameForFriendlyPlayerUnits", "nameplateShowOnlyNames" }, value = "0" },
}

local plates = {} -- nameplate unit -> its health bar container, while we manage it
local touched = setmetatable({}, { __mode = "k" }) -- containers we changed the alpha of
local curve -- health fraction -> alpha: 1 below full health, 0 at full

-- Secret values (Forever inherits Midnight's rules) can't be tested; treat them as unknown.
local function readable(value)
    return not (issecretvalue and issecretvalue(value))
end

local function buildCurve()
    if curve or not (C_CurveUtil and C_CurveUtil.CreateCurve and UnitHealthPercent) then
        return curve
    end
    curve = C_CurveUtil.CreateCurve()
    if Enum.LuaCurveType and Enum.LuaCurveType.Step and curve.SetType then
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0, 1)
        curve:AddPoint(1, 0)
    else
        curve:AddPoint(0, 1)
        curve:AddPoint(0.99, 1)
        curve:AddPoint(1, 0)
    end
    return curve
end

-- CVars -----------------------------------------------------------------------------------------
-- Nameplate CVars can't change in combat, so this waits for it to end.

local function findCVar(names)
    for i = 1, #names do
        if C_CVar.GetCVar(names[i]) ~= nil then
            return names[i]
        end
    end
end

local waiting = false

local function waitForCombatEnd()
    if not waiting then
        waiting = true
        ns.On("PLAYER_REGEN_ENABLED", module.RetryCVars)
    end
end

local function applyCVars()
    if InCombatLockdown() then
        waitForCombatEnd()
        return
    end
    local saved = module.db.saved
    for _, entry in pairs(CVARS) do
        local name = findCVar(entry.names)
        if name then
            local current = C_CVar.GetCVar(name)
            if current ~= entry.value then
                if saved[name] == nil then
                    saved[name] = current
                end
                C_CVar.SetCVar(name, entry.value)
            end
        end
    end
end

local function restoreCVars()
    if InCombatLockdown() then
        waitForCombatEnd()
        return
    end
    local saved = module.db.saved
    for name, value in pairs(saved) do
        C_CVar.SetCVar(name, value)
        saved[name] = nil
    end
end

function module.RetryCVars()
    waiting = false
    ns.Off("PLAYER_REGEN_ENABLED", module.RetryCVars)
    if module.enabled then
        applyCVars()
    else
        restoreCVars()
    end
end

-- Plates ----------------------------------------------------------------------------------------

local function release(container)
    if touched[container] then
        container:SetAlpha(1)
        touched[container] = nil
    end
end

-- A friendly player we can read. Friendly plates in instances are forbidden to addons, and
-- GetNamePlateForUnit doesn't return them, so this only sees the open world.
-- The personal resource display is a friendly player too, so leave out ourselves.
local function isFriendlyPlayer(unit)
    local isPlayer, isFriend, isSelf = UnitIsPlayer(unit), UnitIsFriend("player", unit),
        UnitIsUnit(unit, "player")
    return readable(isPlayer) and readable(isFriend) and readable(isSelf)
        and isPlayer and isFriend and not isSelf
end

local function update(unit)
    local container = plates[unit]
    if not container then
        return
    end
    local inCombat = UnitAffectingCombat(unit)
    if not readable(inCombat) then
        inCombat = UnitAffectingCombat("player")
    end
    touched[container] = true
    if inCombat or not curve then
        container:SetAlpha(1)
    else
        -- The percent can be secret in combat, so the client maps it to an alpha, not Lua.
        container:SetAlpha(UnitHealthPercent(unit, true, curve))
    end
end

local function add(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    local container = frame and (frame.HealthBarsContainer or frame.healthBar)
    if not container then
        return
    end
    if isFriendlyPlayer(unit) then
        plates[unit] = container
        update(unit)
    else
        -- Plates are pooled: one we faded may come back for an enemy or an NPC.
        release(container)
    end
end

local function remove(unit)
    local container = plates[unit]
    if container then
        plates[unit] = nil
        release(container)
    end
end

function module.OnPlateEvent(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        add(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        remove(unit)
    elseif plates[unit] then
        update(unit)
    end
end

function module.OnPlayerCombat()
    for unit in pairs(plates) do
        update(unit)
    end
end

local EVENTS = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_FLAGS" }

function module:OnEnable()
    buildCurve()
    applyCVars()
    for _, event in pairs(EVENTS) do
        ns.On(event, self.OnPlateEvent)
    end
    -- UNIT_FLAGS covers other players' combat; these cover the fallback to our own.
    ns.On("PLAYER_REGEN_DISABLED", self.OnPlayerCombat)
    ns.On("PLAYER_REGEN_ENABLED", self.OnPlayerCombat)
    for _, plate in pairs(C_NamePlate.GetNamePlates()) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit then
            add(unit)
        end
    end
end

function module:OnDisable()
    for _, event in pairs(EVENTS) do
        ns.Off(event, self.OnPlateEvent)
    end
    ns.Off("PLAYER_REGEN_DISABLED", self.OnPlayerCombat)
    ns.Off("PLAYER_REGEN_ENABLED", self.OnPlayerCombat)
    for unit in pairs(plates) do
        remove(unit)
    end
    restoreCVars()
end
