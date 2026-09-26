-- Friendly player (and optionally NPC) nameplates that always show the name, with the guild and
-- level beside it, and show the health bar only while that unit is hurt or in combat. Built on
-- Blizzard's own nameplates: the bar and name fade, and a label of ours shows while it's hidden.
local _, ns = ...

local pairs, ipairs, setmetatable = pairs, ipairs, setmetatable
local CreateFrame, hooksecurefunc = CreateFrame, hooksecurefunc
local C_CVar, C_NamePlate, C_CurveUtil, C_ClassColor = C_CVar, C_NamePlate, C_CurveUtil, C_ClassColor
local InCombatLockdown, UnitHealthPercent = InCombatLockdown, UnitHealthPercent
local UnitIsPlayer, UnitIsFriend, UnitIsUnit = UnitIsPlayer, UnitIsFriend, UnitIsUnit
local UnitAffectingCombat, UnitClass, GetGuildInfo = UnitAffectingCombat, UnitClass, GetGuildInfo
local UnitLevel, UnitGUID, UnitInParty, UnitInRaid = UnitLevel, UnitGUID, UnitInParty, UnitInRaid
local UnitIsInMyGuild, C_FriendList, C_BattleNet = UnitIsInMyGuild, C_FriendList, C_BattleNet
local UnitGroupRolesAssigned, GetTexCoordsForRoleSmallCircle =
    UnitGroupRolesAssigned, GetTexCoordsForRoleSmallCircle

local module = ns.NewModule("FriendlyPlates",
    "Always show friendly players' names. Their health bar appears only when they're hurt or in combat.",
    {
        enabled = false,
        classColor = true,
        barWhenHurt = true,
        npcs = false,
        guildNames = "hidden", -- "hidden" (only without the bar), "always", or "off"
        level = "before", -- "before", "after", or "off"
        guildHighlight = true,
        socialIcons = true,
        groupIcon = "people", -- "people", "looking", or "role"
        testIcons = "off", -- debug: "off", "group", or "friend" on every friendly player
        saved = {}, -- CVar -> the player's own value, put back when the module turns off
    })
module.title = "Friendly Player Nameplates"

-- Extra settings under this module's checkbox in Settings (see Settings.lua).
module.options = {
    {
        key = "barWhenHurt",
        name = "Health Bar When Hurt",
        description = "Show the health bar when a friendly player is missing health. "
            .. "When off, it only shows in combat.",
    },
    {
        key = "npcs",
        name = "Friendly NPCs",
        description = "Give friendly NPCs the same nameplates: name always, health bar when hurt "
            .. "or in combat.",
    },
    {
        key = "classColor",
        name = "Class Colors",
        description = "Color names by class while the health bar is hidden.",
    },
    {
        key = "guildNames",
        name = "Guild Names",
        description = "Show the player's <Guild> under their name.",
        choices = { { "hidden", "Without Health Bar" }, { "always", "Always" }, { "off", "Never" } },
    },
    {
        key = "level",
        name = "Level",
        description = "Where the level shows while the health bar is hidden.",
        choices = { { "before", "Before Name" }, { "after", "After Name" }, { "off", "Hidden" } },
    },
    {
        key = "guildHighlight",
        name = "Highlight Guildmates",
        description = "Show the <Guild> line of players in your own guild in guild chat green.",
    },
    {
        key = "socialIcons",
        name = "Group and Friend Icons",
        description = "Show an icon beside the names of your group members, and the Battle.net "
            .. "logo beside your friends, while the health bar is hidden.",
    },
    {
        key = "groupIcon",
        name = "Group Icon",
        description = "Which icon group members get.",
        choices = {
            { "people", "Guild Crowd" },
            { "looking", "Looking for Group" },
            { "role", "Their Role (Tank, Healer, Damage)" },
        },
    },
    {
        key = "testIcons",
        name = "Test Group and Friend Icons",
        description = "Show an icon on every friendly player, as if they were all in your group "
            .. "or all your friends, to check how the icons look.",
        choices = { { "off", "Off" }, { "group", "Everyone in Group" }, { "friend", "Everyone a Friend" } },
        debug = true,
    },
}

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
        if name and entry.option and not module.db[entry.option] then
            -- Its option is off: give the player's own value back, if we changed it.
            if saved[name] ~= nil then
                C_CVar.SetCVar(name, saved[name])
                saved[name] = nil
            end
        elseif name then
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
local LEVEL_GAP = 3 -- pixels between the name and the level
local NPC_COLOR = { 0.1, 1, 0.1 } -- the green of friendly NPC names in the world
local GUILDMATE_COLOR = { 0.25, 1, 0.25 } -- guild chat's green

-- Art for the icons beside the name. Friends get the Battle.net logo; group members get the
-- Group Icon option's choice. `round` crops a spell-style icon round, like a minimap button;
-- `role` picks that role from Blizzard's round role icons.
local ICON_ART = {
    battlenet = { file = "Interface\\FriendsFrame\\Battlenet-Battleneticon" },
    people = { file = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend", round = true },
    looking = { file = "Interface\\Icons\\INV_Misc_GroupLooking", round = true },
    TANK = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", role = "TANK" },
    HEALER = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", role = "HEALER" },
    DAMAGER = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", role = "DAMAGER" },
}
local ICON_ORDER = { "group", "friend" }
local ICON_SCALE = 1.4 -- icon size against the name's font size
local ROUND_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- Which art an icon uses for this unit.
local function iconArt(kind, unit)
    if kind == "friend" then
        return "battlenet"
    end
    local choice = module.db.groupIcon
    if choice == "role" then
        local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
        -- No role (or not in a group, while testing) falls back to the people icon.
        return readable(role) and ICON_ART[role] and role or "people"
    end
    return ICON_ART[choice] and choice or "people"
end

-- Sets an icon's art; only does the work when it changed.
local function styleIcon(icon, key)
    if icon.art == key then
        return
    end
    icon.art = key
    local art = ICON_ART[key]
    icon:SetTexture(art.file)
    if art.role and GetTexCoordsForRoleSmallCircle then
        icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(art.role))
    elseif art.round then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        icon:SetTexCoord(0, 1, 0, 1)
    end
    if art.round then
        if not icon.masked then
            icon:AddMaskTexture(icon.mask)
            icon.masked = true
        end
    else
        if icon.masked then
            icon:RemoveMaskTexture(icon.mask)
            icon.masked = false
        end
    end
end

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
    label.icons = {}
    for _, kind in ipairs(ICON_ORDER) do
        local icon = label:CreateTexture(nil, "OVERLAY")
        icon.kind = kind
        icon.mask = label:CreateMaskTexture()
        icon.mask:SetTexture(ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        icon.mask:SetAllPoints(icon)
        icon:Hide()
        label.icons[kind] = icon
    end
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
                badge.hasArt = true
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
    label.nameSize = size
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

local function inGroup(unit)
    local party, raid = UnitInParty(unit), UnitInRaid(unit)
    return (readable(party) and party) or (readable(raid) and raid ~= nil) or false
end

-- On the friends list or Battle.net friends. Identity can be secret, so an unreadable GUID
-- just means no icon.
local function isFriend(unit)
    local guid = UnitGUID(unit)
    if not (readable(guid) and guid) then
        return false
    end
    if C_FriendList and C_FriendList.IsFriend and C_FriendList.IsFriend(guid) then
        return true
    end
    return C_BattleNet and C_BattleNet.GetAccountInfoByGUID
        and C_BattleNet.GetAccountInfoByGUID(guid) ~= nil or false
end

local function layoutLabel(label, record, unit)
    local container = record.container
    matchFont(label, record.name)
    local _, class = UnitClass(unit)
    local color = record.isPlayer and module.db.classColor and readable(class) and class
        and C_ClassColor and C_ClassColor.GetClassColor(class)
    if color then
        label.name:SetTextColor(color:GetRGB())
    elseif record.isPlayer then
        label.name:SetTextColor(1, 1, 1)
    else
        label.name:SetTextColor(NPC_COLOR[1], NPC_COLOR[2], NPC_COLOR[3])
    end
    -- The level goes on one side of the name and the icons on the other. The name then shifts by
    -- half the difference, so the whole row is centered over the bar. The guild stays centered.
    local badge = label.level
    local where = module.db.level
    local leftWidth, rightWidth = 0, 0
    if record.levelFrame and where ~= "off" then
        copyBadge(label, record.levelFrame)
        local level = UnitLevel(unit)
        if readable(level) and level <= 0 then
            badge.text:SetText("??")
        else
            badge.text:SetText(level)
        end
        -- Without copied art the badge is just the number, so it's as wide as the number.
        local textWidth = badge.text:GetStringWidth()
        if not badge.hasArt and readable(textWidth) and textWidth > 0 then
            badge:SetWidth(textWidth)
        end
        local width = badge:GetWidth()
        width = readable(width) and width + LEVEL_GAP or 0
        badge:ClearAllPoints()
        if where == "after" then
            rightWidth = width
            badge:SetPoint("LEFT", label.name, "RIGHT", LEVEL_GAP, 0)
        else
            leftWidth = width
            badge:SetPoint("RIGHT", label.name, "LEFT", -LEVEL_GAP, 0)
        end
        badge:Show()
    else
        badge:Hide()
    end
    -- Icons go on the side the level isn't on, one after another away from the name.
    local iconsLeft = where == "after"
    local size = (label.nameSize or 12) * ICON_SCALE
    local previous = label.name
    local iconsWidth = 0
    for _, kind in ipairs(ICON_ORDER) do
        local icon = label.icons[kind]
        if icon then
            local show = record.isPlayer and module.db.socialIcons
                and (module.db.testIcons == kind
                    or kind == "group" and inGroup(unit) or kind == "friend" and isFriend(unit))
            icon:ClearAllPoints()
            if show then
                styleIcon(icon, iconArt(kind, unit))
                icon:SetSize(size, size)
                if iconsLeft then
                    icon:SetPoint("RIGHT", previous, "LEFT", -LEVEL_GAP, 0)
                else
                    icon:SetPoint("LEFT", previous, "RIGHT", LEVEL_GAP, 0)
                end
                previous = icon
                iconsWidth = iconsWidth + size + LEVEL_GAP
            end
            icon:SetShown(show)
        end
    end
    if iconsLeft then
        leftWidth = leftWidth + iconsWidth
    else
        rightWidth = rightWidth + iconsWidth
    end
    local shift = (leftWidth - rightWidth) / 2
    local guildNames = module.db.guildNames
    local guild = guildNames ~= "off" and GetGuildInfo(unit)
    label.name:ClearAllPoints()
    label.guild:ClearAllPoints()
    label.barGuild:ClearAllPoints()
    if readable(guild) and guild and guild ~= "" then
        local mate = module.db.guildHighlight and UnitIsInMyGuild and UnitIsInMyGuild(unit)
        local color = (readable(mate) and mate) and GUILDMATE_COLOR or GUILD_COLOR
        label.guild:SetTextColor(color[1], color[2], color[3])
        label.barGuild:SetTextColor(color[1], color[2], color[3])
        label.name:SetPoint("BOTTOM", container, "CENTER", shift, 1)
        label.guild:SetPoint("TOP", container, "CENTER", 0, 0)
        label.guild:SetFormattedText("<%s>", guild)
        label.guild:Show()
        label.barGuild:SetPoint("TOP", container, "BOTTOM", 0, -2)
        label.barGuild:SetFormattedText("<%s>", guild)
        label.barGuild:SetShown(guildNames == "always")
    else
        label.name:SetPoint("CENTER", container, "CENTER", shift, 0)
        label.guild:Hide()
        label.barGuild:Hide()
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

local function release(record)
    record.container:SetAlpha(1)
    fadeLevel(record, 1)
    if record.name then
        record.name:SetAlpha(1)
        mirrored[record.name] = nil
    end
    if record.label then
        record.label:Hide()
        record.label.barGuildFrame:Hide()
    end
end

-- Whether we handle this unit: a friendly player, or a friendly NPC when that option is on, that
-- we can read. Returns whether it's a player as the second value. Friendly plates in instances
-- are forbidden to addons, and GetNamePlateForUnit doesn't return them, so this only sees the
-- open world. The personal resource display is a friendly player too, so leave out ourselves.
local function isOurs(unit)
    local isPlayer, isFriend, isSelf = UnitIsPlayer(unit), UnitIsFriend("player", unit),
        UnitIsUnit(unit, "player")
    if not (readable(isPlayer) and readable(isFriend) and readable(isSelf)) then
        return false
    end
    return isFriend and not isSelf and (isPlayer or module.db.npcs), isPlayer
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
    -- shown: the bar and everything that goes with it; hidden: our label, its opposite.
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
        label.barGuildFrame:SetAlpha(shown)
        label:SetAlpha(hidden)
    end
end

local function refreshLabel(unit)
    local record = plates[unit]
    if record and record.label then
        record.label.name:SetText(record.name:GetText())
        layoutLabel(record.label, record, unit)
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
    local ours, isPlayer = isOurs(unit)
    if not ours then
        return
    end
    local record = { container = container, isPlayer = isPlayer }
    local name = frame.name or frame.Name
    if name and name.SetText then
        record.name = name
        record.levelFrame = frame.LevelFrame -- Forever-only, as of build 70009
        record.levelDiffFrame = frame.PlayerLevelDiffFrame
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

-- Picks up every plate already on screen (when turning on, or when the NPC option changes).
local function addAll()
    for _, plate in pairs(C_NamePlate.GetNamePlates()) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit then
            add(unit)
        end
    end
end

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
        addAll()
        return
    end
    for unit in pairs(plates) do
        refreshLabel(unit)
        update(unit)
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

-- Group or friends changed: the icons may need to come or go.
function module.OnSocialChange()
    for unit in pairs(plates) do
        refreshLabel(unit)
    end
end

local EVENTS = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_FLAGS", "UNIT_NAME_UPDATE", "UNIT_LEVEL" }
local SOCIAL_EVENTS = { "GROUP_ROSTER_UPDATE", "FRIENDLIST_UPDATE" }

function module:OnEnable()
    buildCurves()
    applyCVars()
    for _, event in pairs(EVENTS) do
        ns.On(event, self.OnPlateEvent)
    end
    for _, event in pairs(SOCIAL_EVENTS) do
        ns.On(event, self.OnSocialChange)
    end
    -- UNIT_FLAGS covers other players' combat; these cover the fallback to our own.
    ns.On("PLAYER_REGEN_DISABLED", self.OnPlayerCombat)
    ns.On("PLAYER_REGEN_ENABLED", self.OnPlayerCombat)
    addAll()
end

function module:OnDisable()
    for _, event in pairs(EVENTS) do
        ns.Off(event, self.OnPlateEvent)
    end
    for _, event in pairs(SOCIAL_EVENTS) do
        ns.Off(event, self.OnSocialChange)
    end
    ns.Off("PLAYER_REGEN_DISABLED", self.OnPlayerCombat)
    ns.Off("PLAYER_REGEN_ENABLED", self.OnPlayerCombat)
    for unit in pairs(plates) do
        remove(unit)
    end
    restoreCVars()
end
