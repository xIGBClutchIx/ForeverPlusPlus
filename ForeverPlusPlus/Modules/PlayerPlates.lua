-- Player Nameplates: friendly players always show their name, with their guild, level, and group
-- and friend icons beside it, and the health bar only shows while they're hurt or in combat.
-- The plates themselves are ns.FriendlyPlates; this module picks the colors and the guild line.
local _, ns = ...

local ipairs, GetGuildInfo = ipairs, GetGuildInfo

local L = ns.L
local Units = ns.Units

local module = ns.NewModule("PlayerPlates", L.PLAYERPLATES_DESC, {
    enabled = true,
    barWhenHurt = true,
    nameColor = "class", -- "class" or "white"
    nameSize = 100, -- percent of Blizzard's name size
    recentAllies = true,
    level = "before", -- "before", "after", or "off"
    guildNames = "always", -- "always", "hidden" (only without the bar), or "off"
    guildColor = "gray", -- "gray" or "green"
    guildHighlight = true,
    socialIcons = true,
    groupIcon = "role", -- "role" or "looking"
    testIcons = "off", -- debug: "off", "group", or "friend" on every friendly player
    centerLine = false, -- debug: a line through each plate's center
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.PLAYERPLATES_TITLE
module.category = "nameplates"

module.options = {
    { key = "barWhenHurt", name = L.PLATES_BAR_WHEN_HURT, description = L.PLAYERPLATES_BAR_WHEN_HURT_DESC },
    {
        key = "nameColor", name = L.PLATES_NAME_COLOR, description = L.PLAYERPLATES_NAME_COLOR_DESC,
        choices = { { "class", L.PLAYERPLATES_NAME_COLOR_CLASS }, { "white", L.PLATES_COLOR_WHITE } },
    },
    ns.PlateLabel.NameSizeOption(),
    { key = "recentAllies", name = L.PLAYERPLATES_RECENT_ALLIES, description = L.PLAYERPLATES_RECENT_ALLIES_DESC },
    { key = "level", name = L.PLATES_LEVEL, description = L.PLATES_LEVEL_DESC, choices = ns.PlateLabel.LEVEL_CHOICES },
    {
        key = "guildNames", name = L.PLAYERPLATES_GUILD_NAMES, description = L.PLAYERPLATES_GUILD_NAMES_DESC,
        choices = ns.PlateLabel.SUBTITLE_CHOICES,
    },
    {
        key = "guildColor", name = L.PLAYERPLATES_GUILD_COLOR, description = L.PLAYERPLATES_GUILD_COLOR_DESC,
        choices = { { "gray", L.PLATES_COLOR_GRAY }, { "green", L.PLATES_COLOR_GREEN } },
    },
    { key = "guildHighlight", name = L.PLAYERPLATES_GUILD_HIGHLIGHT, description = L.PLAYERPLATES_GUILD_HIGHLIGHT_DESC },
    { key = "socialIcons", name = L.PLAYERPLATES_SOCIAL_ICONS, description = L.PLAYERPLATES_SOCIAL_ICONS_DESC },
    {
        key = "groupIcon", name = L.PLAYERPLATES_GROUP_ICON, description = L.PLAYERPLATES_GROUP_ICON_DESC,
        choices = {
            { "role", L.PLAYERPLATES_GROUP_ICON_ROLE },
            { "looking", L.PLAYERPLATES_GROUP_ICON_LOOKING },
        },
    },
    {
        key = "testIcons", name = L.PLAYERPLATES_TEST_ICONS, description = L.PLAYERPLATES_TEST_ICONS_DESC,
        choices = {
            { "off", L.PLAYERPLATES_TEST_ICONS_OFF },
            { "group", L.PLAYERPLATES_TEST_ICONS_GROUP },
            { "friend", L.PLAYERPLATES_TEST_ICONS_FRIEND },
        },
        debug = true,
    },
    { key = "centerLine", name = L.PLATES_CENTER_LINE, description = L.PLATES_CENTER_LINE_DESC, debug = true },
}

-- Guild Name Color choices. Highlighted guildmates get guild chat's green, or white when every
-- guild is already green, so they still stand out.
local GUILD_COLORS = {
    gray = ns.Colors.GRAY,
    green = ns.Colors.GUILD_GREEN,
}
local GUILDMATE_COLORS = {
    gray = GUILD_COLORS.green,
    green = { 0.9, 0.9, 0.9 },
}

local style = { icons = true }

local RECENT_ALLY = ns.Colors.RECENT_ALLY

local function isRecentAlly(unit)
    return module.db.recentAllies and Units.IsRecentAlly(unit)
end

function style.NameColor(unit)
    if isRecentAlly(unit) then
        return RECENT_ALLY[1], RECENT_ALLY[2], RECENT_ALLY[3]
    end
    if module.db.nameColor == "class" then
        local color = ns.Colors.Class(unit)
        if color then
            return color:GetRGB()
        end
    end
    return 1, 1, 1
end

-- With the bar up, the name is plain white, as Blizzard draws it, except a recent ally's.
function style.BarNameColor(unit)
    if isRecentAlly(unit) then
        return RECENT_ALLY[1], RECENT_ALLY[2], RECENT_ALLY[3]
    end
    return 1, 1, 1
end

function style.Subtitle(unit)
    local mode = module.db.guildNames
    if mode == "off" then
        return nil, mode
    end
    return GetGuildInfo(unit), mode -- may be secret; PlateLabel checks
end

function style.SubtitleColor(unit)
    local db = module.db
    local scheme = GUILD_COLORS[db.guildColor] and db.guildColor or "gray"
    if db.guildHighlight and Units.IsGuildmate(unit) then
        return GUILDMATE_COLORS[scheme]
    end
    return GUILD_COLORS[scheme]
end

-- Blizzard's friendly player nameplates can be turned off after this module turns them on (in
-- its options, or with its keybind), and then there are no plates to draw on.
local SHOW_FRIENDLY = { "nameplateShowFriendlyPlayers", "nameplateShowFriends" }
module.notice = ns.CVars.OffNotice(module, SHOW_FRIENDLY, L.PLATES_BLIZZARD_OFF,
    L.PLAYERPLATES_BLIZZARD_OFF_DESC)

local plates = ns.FriendlyPlates.New(module, {
    players = true,
    cvars = {
        -- Each entry lists the names the setting has had, newest first; the first one this client
        -- knows is used.
        { names = SHOW_FRIENDLY, value = "1" },
        -- Blizzard's names-only mode drops the bar entirely, so it could never come back when hurt.
        { names = { "nameplateShowOnlyNameForFriendlyPlayerUnits", "nameplateShowOnlyNames" }, value = "0" },
        -- Blizzard's own name, shown while the bar is up, stays plain white; class color is for ours.
        { names = { "nameplateUseClassColorForFriendlyPlayerUnitNames" }, value = "0" },
    },
    style = style,
})

-- The recent allies list loads after login (or changed): recolor the names.
local function onRecentAllies()
    if module.db.recentAllies then
        plates:Refresh()
    end
end

function module:OnEnable()
    plates:Enable()
    if Units.HasRecentAllies() then
        for _, event in ipairs(Units.RECENT_ALLY_EVENTS) do
            self:On(event, onRecentAllies)
        end
    end
end

function module:OnDisable()
    plates:Disable()
end

function module:OnOptionChanged()
    if self.enabled then
        plates:Refresh()
    end
end
