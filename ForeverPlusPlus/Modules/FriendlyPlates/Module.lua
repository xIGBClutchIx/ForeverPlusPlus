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
    barWhenHurt = true,
    nameColor = "class", -- players' names: "class" or "white"
    npcs = true,
    npcBarWhenHurt = true,
    npcLevel = "before", -- like level
    npcNameColor = "green", -- NPCs' names: "green" (as in the world) or "white"
    guildNames = "always", -- "always", "hidden" (only without the bar), or "off"
    guildColor = "gray", -- "gray" or "green"
    level = "before", -- "before", "after", or "off"
    guildHighlight = true,
    socialIcons = true,
    groupIcon = "role", -- "role" or "looking"
    npcTitles = "always", -- like guildNames, for an NPC's <Title>
    npcTitleColor = "name", -- "name" (the NPC's name color), "gray", or "green"
    testIcons = "off", -- debug: "off", "group", or "friend" on every friendly player
    centerLine = false, -- debug: a line through each plate's center
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.FRIENDLYPLATES_TITLE

-- Extra settings on this module's page in Settings (see Settings.lua), in two sections: players,
-- then NPCs.
local PLAYERS = L.FRIENDLYPLATES_SECTION_PLAYERS
local NPCS = L.FRIENDLYPLATES_SECTION_NPCS

-- When a <Guild> or <Title> line shows.
local function subtitleChoices()
    return {
        { "always", L.FRIENDLYPLATES_SUBTITLE_ALWAYS },
        { "hidden", L.FRIENDLYPLATES_SUBTITLE_HIDDEN },
        { "off", L.FRIENDLYPLATES_SUBTITLE_OFF },
    }
end

-- Where the level goes beside the name.
local function levelChoices()
    return {
        { "before", L.FRIENDLYPLATES_LEVEL_BEFORE },
        { "after", L.FRIENDLYPLATES_LEVEL_AFTER },
        { "off", L.FRIENDLYPLATES_LEVEL_OFF },
    }
end

module.options = {
    {
        key = "barWhenHurt",
        name = L.FRIENDLYPLATES_BAR_WHEN_HURT,
        description = L.FRIENDLYPLATES_BAR_WHEN_HURT_DESC,
        section = PLAYERS,
    },
    {
        key = "nameColor",
        name = L.FRIENDLYPLATES_NAME_COLOR,
        description = L.FRIENDLYPLATES_NAME_COLOR_DESC,
        section = PLAYERS,
        choices = {
            { "class", L.FRIENDLYPLATES_NAME_COLOR_CLASS },
            { "white", L.FRIENDLYPLATES_COLOR_WHITE },
        },
    },
    {
        key = "level",
        name = L.FRIENDLYPLATES_LEVEL,
        description = L.FRIENDLYPLATES_LEVEL_DESC,
        section = PLAYERS,
        choices = levelChoices(),
    },
    {
        key = "guildNames",
        name = L.FRIENDLYPLATES_GUILD_NAMES,
        description = L.FRIENDLYPLATES_GUILD_NAMES_DESC,
        section = PLAYERS,
        choices = subtitleChoices(),
    },
    {
        key = "guildColor",
        name = L.FRIENDLYPLATES_GUILD_COLOR,
        description = L.FRIENDLYPLATES_GUILD_COLOR_DESC,
        section = PLAYERS,
        choices = {
            { "gray", L.FRIENDLYPLATES_GUILD_COLOR_GRAY },
            { "green", L.FRIENDLYPLATES_GUILD_COLOR_GREEN },
        },
    },
    {
        key = "guildHighlight",
        name = L.FRIENDLYPLATES_GUILD_HIGHLIGHT,
        description = L.FRIENDLYPLATES_GUILD_HIGHLIGHT_DESC,
        section = PLAYERS,
    },
    {
        key = "socialIcons",
        name = L.FRIENDLYPLATES_SOCIAL_ICONS,
        description = L.FRIENDLYPLATES_SOCIAL_ICONS_DESC,
        section = PLAYERS,
    },
    {
        key = "groupIcon",
        name = L.FRIENDLYPLATES_GROUP_ICON,
        description = L.FRIENDLYPLATES_GROUP_ICON_DESC,
        section = PLAYERS,
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
        key = "npcBarWhenHurt",
        name = L.FRIENDLYPLATES_NPC_BAR_WHEN_HURT,
        description = L.FRIENDLYPLATES_NPC_BAR_WHEN_HURT_DESC,
        section = NPCS,
    },
    {
        key = "npcLevel",
        name = L.FRIENDLYPLATES_NPC_LEVEL,
        description = L.FRIENDLYPLATES_NPC_LEVEL_DESC,
        section = NPCS,
        choices = levelChoices(),
    },
    {
        key = "npcNameColor",
        name = L.FRIENDLYPLATES_NPC_NAME_COLOR,
        description = L.FRIENDLYPLATES_NPC_NAME_COLOR_DESC,
        section = NPCS,
        choices = {
            { "green", L.FRIENDLYPLATES_GUILD_COLOR_GREEN },
            { "white", L.FRIENDLYPLATES_COLOR_WHITE },
        },
    },
    {
        key = "npcTitles",
        name = L.FRIENDLYPLATES_NPC_TITLES,
        description = L.FRIENDLYPLATES_NPC_TITLES_DESC,
        section = NPCS,
        choices = subtitleChoices(),
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
