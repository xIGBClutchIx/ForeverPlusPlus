-- NPC Nameplates: friendly NPCs always show their name, with their title (<Innkeeper>) and level
-- beside it, and the health bar only shows while they're hurt or in combat.
-- The plates themselves are ns.FriendlyPlates; this module picks the colors and the title line.
local _, ns = ...

local L = ns.L
local Units = ns.Units

local module = ns.NewModule("NpcPlates", L.NPCPLATES_DESC, {
    enabled = true,
    barWhenHurt = true,
    nameColor = "green", -- "green" (as in the world) or "white"
    nameSize = 120, -- percent of Blizzard's name size
    level = "before", -- "before", "after", or "off"
    titles = "always", -- "always", "hidden" (only without the bar), or "off"
    titleColor = "name", -- "name" (the name's color), "gray", or "green"
    centerLine = false, -- debug: a line through each plate's center
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.NPCPLATES_TITLE
module.category = "nameplates"

module.options = {
    { key = "barWhenHurt", name = L.PLATES_BAR_WHEN_HURT, description = L.NPCPLATES_BAR_WHEN_HURT_DESC },
    {
        key = "nameColor", name = L.PLATES_NAME_COLOR, description = L.NPCPLATES_NAME_COLOR_DESC,
        choices = { { "green", L.PLATES_COLOR_GREEN }, { "white", L.PLATES_COLOR_WHITE } },
    },
    ns.PlateLabel.NameSizeOption(),
    { key = "level", name = L.PLATES_LEVEL, description = L.PLATES_LEVEL_DESC, choices = ns.PlateLabel.LEVEL_CHOICES },
    {
        key = "titles", name = L.NPCPLATES_TITLES, description = L.NPCPLATES_TITLES_DESC,
        choices = ns.PlateLabel.SUBTITLE_CHOICES,
    },
    {
        key = "titleColor", name = L.NPCPLATES_TITLE_COLOR, description = L.NPCPLATES_TITLE_COLOR_DESC,
        choices = {
            { "name", L.NPCPLATES_TITLE_COLOR_NAME },
            { "gray", L.PLATES_COLOR_GRAY },
            { "green", L.PLATES_COLOR_GREEN },
        },
    },
    { key = "centerLine", name = L.PLATES_CENTER_LINE, description = L.PLATES_CENTER_LINE_DESC, debug = true },
}

local NAME_COLORS = {
    green = { 0.1, 1, 0.1 }, -- the green of friendly NPC names in the world
    white = { 1, 1, 1 },
}
local TITLE_COLORS = { -- the same as Player Nameplates' guild colors
    gray = ns.Colors.GRAY,
    green = ns.Colors.GUILD_GREEN,
}

local function nameColor()
    return NAME_COLORS[module.db.nameColor] or NAME_COLORS.green
end

local style = { icons = false }

function style.NameColor()
    local color = nameColor()
    return color[1], color[2], color[3]
end

function style.Subtitle(unit)
    local mode = module.db.titles
    if mode == "off" then
        return nil, mode
    end
    return Units.Title(unit), mode
end

function style.SubtitleColor()
    return TITLE_COLORS[module.db.titleColor] or nameColor()
end

-- Blizzard's friendly NPC nameplates can be turned off after this module turns them on, and then
-- there are no plates to draw on.
local SHOW_NPCS = { "nameplateShowFriendlyNpcs", "nameplateShowFriendlyNPCs" }
module.notice = ns.CVars.OffNotice(module, SHOW_NPCS, L.PLATES_BLIZZARD_OFF,
    L.NPCPLATES_BLIZZARD_OFF_DESC)

local plates = ns.FriendlyPlates.New(module, {
    players = false,
    cvars = {
        { names = SHOW_NPCS, value = "1" },
    },
    style = style,
})

function module:OnEnable()
    plates:Enable()
end

function module:OnDisable()
    plates:Disable()
end

function module:OnOptionChanged()
    if self.enabled then
        plates:Refresh()
    end
end
