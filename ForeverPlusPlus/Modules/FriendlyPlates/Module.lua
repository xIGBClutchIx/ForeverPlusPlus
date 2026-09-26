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
        groupIcon = "role", -- "role" or "looking"
        testIcons = "off", -- debug: "off", "group", or "friend" on every friendly player
        saved = {}, -- CVar -> the player's own value, put back when the module turns off
    })
module.title = "Friendly Player Nameplates"

-- Extra settings on this module's page in Settings (see Settings.lua).
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
            { "role", "Their Role (Tank, Healer, Damage)" },
            { "looking", "Looking for Group" },
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

local P = {}
module.internal = P

P.GAP = 3 -- pixels between the name, the level, and the icons
