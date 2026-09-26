-- Friendly Player Nameplates: friendly players (and optionally NPCs) always show their name, with
-- the guild and level beside it, and the health bar only shows while they're hurt or in combat.
-- Built on Blizzard's own nameplates: the bar and name fade, and a label of ours shows instead.
--
-- Files, in load order:
--   Module.lua  the module, its settings, and constants shared by the other files
--   Icons.lua   the group and friend icons
--   Label.lua   our label: name, guild, level
--   Plates.lua  which plates we handle, fading, events, turning on and off
-- They share `module.internal` (P); nothing outside this folder uses it.
local _, ns = ...

local L = ns.L

local module = ns.NewModule("FriendlyPlates", L.FRIENDLYPLATES_DESC, {
    enabled = false,
    classColor = true,
    barWhenHurt = true,
    npcs = false,
    guildNames = "hidden", -- "hidden" (only without the bar), "always", or "off"
    level = "before", -- "before", "after", or "off"
    guildHighlight = true,
    socialIcons = true,
    groupIcon = "role", -- "role" or "looking"
    testIcons = "off", -- debug: "off", "group", or "friend" on every friendly player
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.FRIENDLYPLATES_TITLE

-- Extra settings on this module's page in Settings (see Settings.lua).
module.options = {
    {
        key = "barWhenHurt",
        name = L.FRIENDLYPLATES_BAR_WHEN_HURT,
        description = L.FRIENDLYPLATES_BAR_WHEN_HURT_DESC,
    },
    {
        key = "npcs",
        name = L.FRIENDLYPLATES_NPCS,
        description = L.FRIENDLYPLATES_NPCS_DESC,
    },
    {
        key = "classColor",
        name = L.FRIENDLYPLATES_CLASS_COLOR,
        description = L.FRIENDLYPLATES_CLASS_COLOR_DESC,
    },
    {
        key = "guildNames",
        name = L.FRIENDLYPLATES_GUILD_NAMES,
        description = L.FRIENDLYPLATES_GUILD_NAMES_DESC,
        choices = {
            { "hidden", L.FRIENDLYPLATES_GUILD_NAMES_HIDDEN },
            { "always", L.FRIENDLYPLATES_GUILD_NAMES_ALWAYS },
            { "off", L.FRIENDLYPLATES_GUILD_NAMES_OFF },
        },
    },
    {
        key = "level",
        name = L.FRIENDLYPLATES_LEVEL,
        description = L.FRIENDLYPLATES_LEVEL_DESC,
        choices = {
            { "before", L.FRIENDLYPLATES_LEVEL_BEFORE },
            { "after", L.FRIENDLYPLATES_LEVEL_AFTER },
            { "off", L.FRIENDLYPLATES_LEVEL_OFF },
        },
    },
    {
        key = "guildHighlight",
        name = L.FRIENDLYPLATES_GUILD_HIGHLIGHT,
        description = L.FRIENDLYPLATES_GUILD_HIGHLIGHT_DESC,
    },
    {
        key = "socialIcons",
        name = L.FRIENDLYPLATES_SOCIAL_ICONS,
        description = L.FRIENDLYPLATES_SOCIAL_ICONS_DESC,
    },
    {
        key = "groupIcon",
        name = L.FRIENDLYPLATES_GROUP_ICON,
        description = L.FRIENDLYPLATES_GROUP_ICON_DESC,
        choices = {
            { "role", L.FRIENDLYPLATES_GROUP_ICON_ROLE },
            { "looking", L.FRIENDLYPLATES_GROUP_ICON_LOOKING },
        },
    },
    {
        key = "testIcons",
        name = L.FRIENDLYPLATES_TEST_ICONS,
        description = L.FRIENDLYPLATES_TEST_ICONS_DESC,
        choices = {
            { "off", L.FRIENDLYPLATES_TEST_ICONS_OFF },
            { "group", L.FRIENDLYPLATES_TEST_ICONS_GROUP },
            { "friend", L.FRIENDLYPLATES_TEST_ICONS_FRIEND },
        },
        debug = true,
    },
}

local P = {}
module.internal = P

P.GAP = 3 -- pixels between the name, the level, and the icons
