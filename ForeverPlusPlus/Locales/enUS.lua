-- English text, and the fallback for every other language: every key the addon uses is here.
-- Another language gets its own file (Locales/deDE.lua, ...) that starts the same way with its
-- own code, sets only the keys it translates, and goes in the TOC after this one.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- Core: /fpp and chat
L.ON = "on"
L.OFF = "off"
L.MODULE_STATE = "%s is %s." -- module name, on/off
L.NO_MODULE = "no module called %s"
L.OFF_AFTER_RELOAD = "%s turns fully off after /reload."
L.SLASH_MODULES = "modules (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "open the settings"
L.SLASH_RESET = "all settings back to defaults (reloads)"

-- Settings
L.MODULES = "Modules"
L.DEBUG = "Debug"
L.SETTINGS_AFTER_COMBAT = "Settings open after combat."

-- FriendlyPlates
L.FRIENDLYPLATES_TITLE = "Friendly Player Nameplates"
L.FRIENDLYPLATES_DESC = "Always show friendly players' names. Their health bar appears only when "
    .. "they're hurt or in combat."
L.FRIENDLYPLATES_BAR_WHEN_HURT = "Health Bar When Hurt"
L.FRIENDLYPLATES_BAR_WHEN_HURT_DESC = "Show the health bar when a friendly player is missing "
    .. "health. When off, it only shows in combat."
L.FRIENDLYPLATES_NPCS = "Friendly NPCs"
L.FRIENDLYPLATES_NPCS_DESC = "Give friendly NPCs the same nameplates: name always, health bar "
    .. "when hurt or in combat."
L.FRIENDLYPLATES_CLASS_COLOR = "Class Colors"
L.FRIENDLYPLATES_CLASS_COLOR_DESC = "Color names by class while the health bar is hidden."
L.FRIENDLYPLATES_GUILD_NAMES = "Guild Names"
L.FRIENDLYPLATES_GUILD_NAMES_DESC = "Show the player's <Guild> under their name."
L.FRIENDLYPLATES_GUILD_NAMES_HIDDEN = "Without Health Bar"
L.FRIENDLYPLATES_GUILD_NAMES_ALWAYS = "Always"
L.FRIENDLYPLATES_GUILD_NAMES_OFF = "Never"
L.FRIENDLYPLATES_LEVEL = "Level"
L.FRIENDLYPLATES_LEVEL_DESC = "Where the level shows while the health bar is hidden."
L.FRIENDLYPLATES_LEVEL_BEFORE = "Before Name"
L.FRIENDLYPLATES_LEVEL_AFTER = "After Name"
L.FRIENDLYPLATES_LEVEL_OFF = "Hidden"
L.FRIENDLYPLATES_GUILD_HIGHLIGHT = "Highlight Guildmates"
L.FRIENDLYPLATES_GUILD_HIGHLIGHT_DESC = "Show the <Guild> line of players in your own guild in "
    .. "guild chat green."
L.FRIENDLYPLATES_SOCIAL_ICONS = "Group and Friend Icons"
L.FRIENDLYPLATES_SOCIAL_ICONS_DESC = "Show an icon beside the names of your group members, and "
    .. "the Battle.net logo beside your friends, while the health bar is hidden."
L.FRIENDLYPLATES_GROUP_ICON = "Group Icon"
L.FRIENDLYPLATES_GROUP_ICON_DESC = "Which icon group members get."
L.FRIENDLYPLATES_GROUP_ICON_ROLE = "Their Role (Tank, Healer, Damage)"
L.FRIENDLYPLATES_GROUP_ICON_LOOKING = "Looking for Group"
L.FRIENDLYPLATES_TEST_ICONS = "Test Group and Friend Icons"
L.FRIENDLYPLATES_TEST_ICONS_DESC = "Show an icon on every friendly player, as if they were all "
    .. "in your group or all your friends, to check how the icons look."
L.FRIENDLYPLATES_TEST_ICONS_OFF = "Off"
L.FRIENDLYPLATES_TEST_ICONS_GROUP = "Everyone in Group"
L.FRIENDLYPLATES_TEST_ICONS_FRIEND = "Everyone a Friend"
