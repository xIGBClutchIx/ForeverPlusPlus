-- Friendly player nameplates that always show the name (in class color, with the guild under
-- it), and show the health bar only while that player is hurt or in combat. Built on Blizzard's
-- own nameplates: the bar and name fade, and a label of ours shows while the bar is hidden.
local _, ns = ...

local pairs, setmetatable = pairs, setmetatable
local CreateFrame, hooksecurefunc = CreateFrame, hooksecurefunc
local C_CVar, C_NamePlate, C_CurveUtil, C_ClassColor = C_CVar, C_NamePlate, C_CurveUtil, C_ClassColor
local InCombatLockdown, UnitHealthPercent = InCombatLockdown, UnitHealthPercent
local UnitIsPlayer, UnitIsFriend, UnitIsUnit = UnitIsPlayer, UnitIsFriend, UnitIsUnit
local UnitAffectingCombat, UnitClass, GetGuildInfo = UnitAffectingCombat, UnitClass, GetGuildInfo

local module = ns.NewModule("FriendlyPlates",
    "Friendly players always show their name and guild; the health bar shows only when hurt or in combat.",
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
    -- Class color on Blizzard's own name, shown while the bar is up.
    { names = { "nameplateUseClassColorForFriendlyPlayerUnitNames" }, value = "1" },
}

local weak = { __mode = "k" }
local plates = {} -- nameplate unit -> { container, name, label }, while we manage it
local byFrame = setmetatable({}, weak) -- Blizzard unit frame -> the record we last made for it
local labels = setmetatable({}, weak) -- Blizzard unit frame -> our label frame on it
local mirrored = setmetatable({}, weak) -- Blizzard name font string -> our label copying it
local hookedNames = setmetatable({}, weak)
local curve -- health fraction -> alpha: 1 below full health, 0 at full
local inverse -- the opposite: 0 below full health, 1 at full

-- Secret values (Forever inherits Midnight's rules) can't be tested; treat them as unknown.
local function readable(value)
    return not (issecretvalue and issecretvalue(value))
end

-- A curve that gives `hurt` below full health and `full` at full health.
local function buildCurve(hurt, full)
    local c = C_CurveUtil.CreateCurve()
    if Enum.LuaCurveType and Enum.LuaCurveType.Step and c.SetType then
        c:SetType(Enum.LuaCurveType.Step)
        c:AddPoint(0, hurt)
        c:AddPoint(1, full)
    else
        c:AddPoint(0, hurt)
        c:AddPoint(0.99, hurt)
        c:AddPoint(1, full)
    end
    return c
end

local function buildCurves()
    if curve or not (C_CurveUtil and C_CurveUtil.CreateCurve and UnitHealthPercent) then
        return
    end
    curve, inverse = buildCurve(1, 0), buildCurve(0, 1)
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

-- Labels: while the bar is hidden, Blizzard's name (which sits above the bar) fades out and our
-- own label takes its place: the name in class color with "<Guild>" under it, or the name alone
-- lower down, level with the bar's middle, when there's no guild. The two swap with the same
-- health curve as the bar, so the client does it even when health is secret.

local NAME_X = -6 -- a little left of the bar's edge, clear of the level on the right

local function createLabel(frame, name)
    local label = CreateFrame("Frame", nil, frame)
    label:SetAllPoints(frame)
    label.name = label:CreateFontString(nil, "OVERLAY")
    label.guild = label:CreateFontString(nil, "OVERLAY")
    local fontObject = name.GetFontObject and name:GetFontObject()
    for _, text in pairs({ label.name, label.guild }) do
        if fontObject then
            text:SetFontObject(fontObject)
        else
            text:SetFontObject("SystemFont_NamePlate")
        end
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
    end
    label.guild:SetTextColor(0.9, 0.9, 0.9)
    return label
end

local function getLabel(frame, name)
    local label = labels[frame]
    if not label then
        label = createLabel(frame, name)
        labels[frame] = label
    end
    return label
end

-- Blizzard sets the name text (with surname) itself; ours copies it as it changes.
local function mirrorName(fontString, text)
    local label = mirrored[fontString]
    if label then
        label.name:SetText(text)
    end
end

local function hookName(name)
    if not hookedNames[name] then
        hookedNames[name] = true
        hooksecurefunc(name, "SetText", mirrorName)
    end
end

local function layoutLabel(label, container, unit)
    local _, class = UnitClass(unit)
    local color = readable(class) and class and C_ClassColor and C_ClassColor.GetClassColor(class)
    if color then
        label.name:SetTextColor(color:GetRGB())
    else
        label.name:SetTextColor(1, 1, 1)
    end
    local guild = GetGuildInfo(unit)
    label.name:ClearAllPoints()
    label.guild:ClearAllPoints()
    if readable(guild) and guild and guild ~= "" then
        label.name:SetPoint("BOTTOMLEFT", container, "LEFT", NAME_X, 1)
        label.guild:SetPoint("TOPLEFT", label.name, "BOTTOMLEFT", 0, -1)
        label.guild:SetFormattedText("<%s>", guild)
        label.guild:Show()
    else
        label.name:SetPoint("LEFT", container, "LEFT", NAME_X, 0)
        label.guild:Hide()
    end
end

local function release(record)
    record.container:SetAlpha(1)
    if record.name then
        record.name:SetAlpha(1)
        mirrored[record.name] = nil
    end
    if record.label then
        record.label:Hide()
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
    local record = plates[unit]
    if not record then
        return
    end
    local inCombat = UnitAffectingCombat(unit)
    if not readable(inCombat) then
        inCombat = UnitAffectingCombat("player")
    end
    local label = record.label
    if inCombat or not curve then
        record.container:SetAlpha(1)
        if label then
            record.name:SetAlpha(1)
            label:SetAlpha(0)
        end
    else
        -- The percent can be secret in combat, so the client maps it to an alpha, not Lua.
        local shown = UnitHealthPercent(unit, true, curve)
        record.container:SetAlpha(shown)
        if label then
            record.name:SetAlpha(shown)
            label:SetAlpha(UnitHealthPercent(unit, true, inverse))
        end
    end
end

local function refreshLabel(unit)
    local record = plates[unit]
    if record and record.label then
        record.label.name:SetText(record.name:GetText())
        layoutLabel(record.label, record.container, unit)
    end
end

local function add(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    local container = frame and (frame.HealthBarsContainer or frame.healthBar)
    if not container then
        return
    end
    -- Plates are pooled: one we changed may come back for an enemy or an NPC.
    local old = byFrame[frame]
    if old then
        release(old)
        byFrame[frame] = nil
    end
    if not isFriendlyPlayer(unit) then
        return
    end
    local record = { container = container }
    local name = frame.name or frame.Name
    if name and name.SetText then
        record.name = name
        record.label = getLabel(frame, name)
        record.label:Show()
        hookName(name)
        mirrored[name] = record.label
    end
    plates[unit] = record
    byFrame[frame] = record
    refreshLabel(unit)
    update(unit)
end

local function remove(unit)
    local record = plates[unit]
    if record then
        plates[unit] = nil
        release(record)
    end
end

function module.OnPlateEvent(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        add(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        remove(unit)
    elseif plates[unit] then
        if event == "UNIT_NAME_UPDATE" then
            refreshLabel(unit)
        end
        update(unit)
    end
end

function module.OnPlayerCombat()
    for unit in pairs(plates) do
        update(unit)
    end
end

local EVENTS = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_FLAGS", "UNIT_NAME_UPDATE" }

function module:OnEnable()
    buildCurves()
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
