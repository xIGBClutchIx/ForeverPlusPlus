-- Friendly Nameplates: friendly players (and optionally NPCs) always show their name, with
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
    enabled = true,
    classColor = true,
    barWhenHurt = true,
    npcs = true,
    guildNames = "always", -- "always", "hidden" (only without the bar), or "off"
    guildColor = "gray", -- "gray" or "green"
    level = "before", -- "before", "after", or "off"
    guildHighlight = true,
    socialIcons = true,
    groupIcon = "role", -- "role" or "looking"
    npcTitles = true,
    npcTitleColor = "name", -- "name" (the NPC's name color), "gray", or "green"
    testIcons = "off", -- debug: "off", "group", or "friend" on every friendly player
    centerLine = false, -- debug: a line through each plate's center
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.FRIENDLYPLATES_TITLE

-- Extra settings on this module's page in Settings (see Settings.lua), in sections: the plate,
-- the guild line, icons, then NPCs.
local GENERAL = L.FRIENDLYPLATES_SECTION_GENERAL
local GUILD = L.FRIENDLYPLATES_SECTION_GUILD
local ICONS = L.FRIENDLYPLATES_SECTION_ICONS
local NPCS = L.FRIENDLYPLATES_SECTION_NPCS

module.options = {
    {
        key = "barWhenHurt",
        name = L.FRIENDLYPLATES_BAR_WHEN_HURT,
        description = L.FRIENDLYPLATES_BAR_WHEN_HURT_DESC,
        section = GENERAL,
    },
    {
        key = "classColor",
        name = L.FRIENDLYPLATES_CLASS_COLOR,
        description = L.FRIENDLYPLATES_CLASS_COLOR_DESC,
        section = GENERAL,
    },
    {
        key = "level",
        name = L.FRIENDLYPLATES_LEVEL,
        description = L.FRIENDLYPLATES_LEVEL_DESC,
        section = GENERAL,
        choices = {
            { "before", L.FRIENDLYPLATES_LEVEL_BEFORE },
            { "after", L.FRIENDLYPLATES_LEVEL_AFTER },
            { "off", L.FRIENDLYPLATES_LEVEL_OFF },
        },
    },
    {
        key = "guildNames",
        name = L.FRIENDLYPLATES_GUILD_NAMES,
        description = L.FRIENDLYPLATES_GUILD_NAMES_DESC,
        section = GUILD,
        choices = {
            { "always", L.FRIENDLYPLATES_GUILD_NAMES_ALWAYS },
            { "hidden", L.FRIENDLYPLATES_GUILD_NAMES_HIDDEN },
            { "off", L.FRIENDLYPLATES_GUILD_NAMES_OFF },
        },
    },
    {
        key = "guildColor",
        name = L.FRIENDLYPLATES_GUILD_COLOR,
        description = L.FRIENDLYPLATES_GUILD_COLOR_DESC,
        section = GUILD,
        choices = {
            { "gray", L.FRIENDLYPLATES_GUILD_COLOR_GRAY },
            { "green", L.FRIENDLYPLATES_GUILD_COLOR_GREEN },
        },
    },
    {
        key = "guildHighlight",
        name = L.FRIENDLYPLATES_GUILD_HIGHLIGHT,
        description = L.FRIENDLYPLATES_GUILD_HIGHLIGHT_DESC,
        section = GUILD,
    },
    {
        key = "socialIcons",
        name = L.FRIENDLYPLATES_SOCIAL_ICONS,
        description = L.FRIENDLYPLATES_SOCIAL_ICONS_DESC,
        section = ICONS,
    },
    {
        key = "groupIcon",
        name = L.FRIENDLYPLATES_GROUP_ICON,
        description = L.FRIENDLYPLATES_GROUP_ICON_DESC,
        section = ICONS,
        choices = {
            { "role", L.FRIENDLYPLATES_GROUP_ICON_ROLE },
            { "looking", L.FRIENDLYPLATES_GROUP_ICON_LOOKING },
        },
    },
    {
        key = "npcs",
        name = L.FRIENDLYPLATES_NPCS,
        description = L.FRIENDLYPLATES_NPCS_DESC,
        section = NPCS,
    },
    {
        key = "npcTitles",
        name = L.FRIENDLYPLATES_NPC_TITLES,
        description = L.FRIENDLYPLATES_NPC_TITLES_DESC,
        section = NPCS,
    },
    {
        key = "npcTitleColor",
        name = L.FRIENDLYPLATES_NPC_TITLE_COLOR,
        description = L.FRIENDLYPLATES_NPC_TITLE_COLOR_DESC,
        section = NPCS,
        choices = {
            { "name", L.FRIENDLYPLATES_NPC_TITLE_COLOR_NAME },
            { "gray", L.FRIENDLYPLATES_GUILD_COLOR_GRAY },
            { "green", L.FRIENDLYPLATES_GUILD_COLOR_GREEN },
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
    {
        key = "centerLine",
        name = L.FRIENDLYPLATES_CENTER_LINE,
        description = L.FRIENDLYPLATES_CENTER_LINE_DESC,
        debug = true,
    },
}

local P = {}
module.internal = P

P.GAP = 3 -- pixels between the name, the level, and the icons
