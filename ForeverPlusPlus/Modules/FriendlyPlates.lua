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
local UnitLevel = UnitLevel

local module = ns.NewModule("FriendlyPlates",
    "Friendly players always show their name and guild; the health bar shows only when hurt or in combat.",
    {
        enabled = false,
        guild = true,
        saved = {}, -- CVar -> the player's own value, put back when the module turns off
    })

-- Extra checkboxes under this module's own in Settings (see Settings.lua).
module.options = {
    { key = "guild", name = "Guild names", description = "Show the guild under friendly player names." },
}

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
-- own label takes its place, centered over where the bar was: the name in class color with
-- "<Guild>" under it, or the name alone at the bar's middle when there's no guild. While the bar
-- is up, Blizzard's name is back and the guild sits under the bar instead. The two swap with the
-- same health curve as the bar, so the client does it even when health is secret.

local GUILD_SCALE = 0.9 -- the guild line is a touch smaller than the name
local GUILD_COLOR = { 0.9, 0.9, 0.9 }

local function newText(parent)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFontObject("SystemFont_NamePlate")
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)
    return text
end

local function createLabel(frame)
    local label = CreateFrame("Frame", nil, frame)
    label:SetAllPoints(frame)
    label.name = newText(label)
    label.guild = newText(label)
    label.guild:SetTextColor(GUILD_COLOR[1], GUILD_COLOR[2], GUILD_COLOR[3])
    -- A separate frame so it can fade in with the bar while the rest of the label fades out.
    label.barGuildFrame = CreateFrame("Frame", nil, frame)
    label.barGuildFrame:SetAllPoints(frame)
    label.barGuild = newText(label.barGuildFrame)
    label.barGuild:SetTextColor(GUILD_COLOR[1], GUILD_COLOR[2], GUILD_COLOR[3])
    -- Our copy of the level badge, which sits after the name instead of at the bar's end.
    label.level = CreateFrame("Frame", nil, label)
    label.level.text = label.level:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label.level.text:SetPoint("CENTER")
    return label
end

-- Copies the look of Forever's level badge (UnitFrame.LevelFrame): its atlas art and its
-- number's font. The art is copied once per label, since the badge is the same on every plate;
-- the size is retried until Blizzard has laid its badge out.
local function copyBadge(label, levelFrame)
    local badge = label.level
    local width, height = levelFrame:GetSize()
    if readable(width) and readable(height) and width and width > 0 then
        badge:SetSize(width, height)
    elseif not badge.sized then
        badge:SetSize(24, 14)
    end
    badge.sized = true
    if badge.copied then
        return
    end
    badge.copied = true
    local sources = { levelFrame }
    for _, child in pairs({ levelFrame:GetChildren() }) do
        sources[#sources + 1] = child
    end
    for _, source in pairs(sources) do
        for _, region in pairs({ source:GetRegions() }) do
            local kind = region:GetObjectType()
            if kind == "Texture" and region:GetAtlas() then
                local texture = badge:CreateTexture(nil, region:GetDrawLayer())
                texture:SetAtlas(region:GetAtlas())
                texture:SetAllPoints(badge)
            elseif kind == "FontString" then
                local file, size, flags = region:GetFont()
                if file and size then
                    badge.text:SetFont(file, size, flags)
                end
            end
        end
    end
end

local function getLabel(frame)
    local label = labels[frame]
    if not label then
        label = createLabel(frame)
        labels[frame] = label
    end
    return label
end

-- Use the font Blizzard's name is drawn with right now. Its font object can be a different size
-- (nameplates set the size on the string), which made our copy come out small.
local function matchFont(label, name)
    local file, size, flags = name:GetFont()
    if not (file and size) then
        return
    end
    label.name:SetFont(file, size, flags)
    label.guild:SetFont(file, size * GUILD_SCALE, flags)
    label.barGuild:SetFont(file, size * GUILD_SCALE, flags)
end

-- Blizzard sets the name text (with surname) itself; ours copies it as it changes.
local function mirrorName(fontString, text)
    local label = mirrored[fontString]
    if label then
        label.name:SetText(text)
        matchFont(label, fontString)
    end
end

local function hookName(name)
    if not hookedNames[name] then
        hookedNames[name] = true
        hooksecurefunc(name, "SetText", mirrorName)
    end
end

local function layoutLabel(label, record, unit)
    local container = record.container
    matchFont(label, record.name)
    local _, class = UnitClass(unit)
    local color = readable(class) and class and C_ClassColor and C_ClassColor.GetClassColor(class)
    if color then
        label.name:SetTextColor(color:GetRGB())
    else
        label.name:SetTextColor(1, 1, 1)
    end
    local guild = module.db.guild and GetGuildInfo(unit)
    label.name:ClearAllPoints()
    label.guild:ClearAllPoints()
    label.barGuild:ClearAllPoints()
    if readable(guild) and guild and guild ~= "" then
        label.name:SetPoint("BOTTOM", container, "CENTER", 0, 1)
        label.guild:SetPoint("TOP", label.name, "BOTTOM", 0, -1)
        label.guild:SetFormattedText("<%s>", guild)
        label.guild:Show()
        label.barGuild:SetPoint("TOP", container, "BOTTOM", 0, -2)
        label.barGuild:SetFormattedText("<%s>", guild)
        label.barGuild:Show()
    else
        label.name:SetPoint("CENTER", container, "CENTER", 0, 0)
        label.guild:Hide()
        label.barGuild:Hide()
    end
    local badge = label.level
    if record.levelFrame then
        copyBadge(label, record.levelFrame)
        badge:ClearAllPoints()
        badge:SetPoint("LEFT", label.name, "RIGHT", 3, 0)
        local level = UnitLevel(unit)
        if readable(level) and level <= 0 then
            badge.text:SetText("??")
        else
            badge.text:SetText(level)
        end
        badge:Show()
    else
        badge:Hide()
    end
end

local function release(record)
    record.container:SetAlpha(1)
    if record.levelFrame then
        record.levelFrame:SetAlpha(1)
    end
    if record.name then
        record.name:SetAlpha(1)
        mirrored[record.name] = nil
    end
    if record.label then
        record.label:Hide()
        record.label.barGuildFrame:Hide()
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
    local label, levelFrame = record.label, record.levelFrame
    if inCombat or not curve then
        record.container:SetAlpha(1)
        if label and levelFrame then
            levelFrame:SetAlpha(1)
        end
        if label then
            record.name:SetAlpha(1)
            label:SetAlpha(0)
            label.barGuildFrame:SetAlpha(1)
        end
    else
        -- The percent can be secret in combat, so the client maps it to an alpha, not Lua.
        local shown = UnitHealthPercent(unit, true, curve)
        record.container:SetAlpha(shown)
        if label and levelFrame then
            levelFrame:SetAlpha(shown)
        end
        if label then
            record.name:SetAlpha(shown)
            label.barGuildFrame:SetAlpha(shown)
            label:SetAlpha(UnitHealthPercent(unit, true, inverse))
        end
    end
end

local function refreshLabel(unit)
    local record = plates[unit]
    if record and record.label then
        record.label.name:SetText(record.name:GetText())
        layoutLabel(record.label, record, unit)
    end
end

-- Called by Settings when an option changes.
function module:OnOptionChanged()
    for unit in pairs(plates) do
        refreshLabel(unit)
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
        record.levelFrame = frame.LevelFrame -- Forever-only, as of build 70009
        record.label = getLabel(frame)
        record.label:Show()
        record.label.barGuildFrame:Show()
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
        if event == "UNIT_NAME_UPDATE" or event == "UNIT_LEVEL" then
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
    "UNIT_FLAGS", "UNIT_NAME_UPDATE", "UNIT_LEVEL" }

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
