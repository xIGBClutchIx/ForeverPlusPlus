-- Colors more than one module uses, so the same thing looks the same everywhere (a guild name on a
-- nameplate and in a tooltip), and color codes for text.
local _, ns = ...

local format, floor, max = string.format, math.floor, math.max
local UnitLevel, GetQuestDifficultyColor, QuestDifficultyColors =
    UnitLevel, GetQuestDifficultyColor, QuestDifficultyColors
local RECENT_ALLY_FONT_COLOR, UnitClass, C_ClassColor = RECENT_ALLY_FONT_COLOR, UnitClass, C_ClassColor
local UnitIsPlayer = UnitIsPlayer
local PLAYER_FACTION_COLORS = PLAYER_FACTION_COLORS

local readable = ns.IsReadable

local Colors = {
    GRAY = { 0.65, 0.65, 0.65 }, -- a guild name or an NPC title that isn't highlighted
    RED = { 1, 0.25, 0.25 }, -- "You" as a target, and what can't be changed
    GUILD_GREEN = { 0.25, 1, 0.25 }, -- guild chat's green, for the player's own guild
    -- The game's light blue for recent allies' names. It comes from the client's color table
    -- (no Blizzard Lua uses it), so keep its build 70009 value in case the name goes away.
    RECENT_ALLY = RECENT_ALLY_FONT_COLOR and { RECENT_ALLY_FONT_COLOR:GetRGB() } or { 0.325, 0.788, 1 },
}
ns.Colors = Colors

---The code that starts text in this color; end the colored part with |r.
---@param r number 0 to 1
---@param g number
---@param b number
---@return string
function Colors.Code(r, g, b)
    return format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5),
        floor(b * 255 + 0.5))
end

---Text in a color, for a color table with `r`, `g` and `b` (Blizzard's, or one of ours).
---@param color table
---@param text string|number
---@return string
function Colors.Text(color, text)
    return Colors.Code(color.r, color.g, color.b) .. text .. "|r"
end

---The color of a level range (a zone's or a dungeon's) against the player's level, like a quest's:
---red or orange while it's above you, yellow while you're in it, green or gray once you've
---outleveled it. Two below the top counts as outleveled, so a range you've finished isn't yellow.
---Nil without Blizzard's quest colors. Probe: they're FrameXML's.
---@param low number
---@param high number
---@return table? color with r, g, b
function Colors.LevelRange(low, high)
    if not (GetQuestDifficultyColor and QuestDifficultyColors) then
        return nil
    end
    local level = UnitLevel("player")
    if level < low then
        return GetQuestDifficultyColor(low)
    elseif level > high then
        return GetQuestDifficultyColor(max(low, high - 2))
    end
    return QuestDifficultyColors.difficult
end

-- Blizzard's faction colors (Horde red, Alliance blue, from its PLAYER_FACTION_COLORS), with
-- these values kept for when the table isn't there. Anything neither side's is yellow, like a
-- neutral reputation.
local FACTION_COLORS = {
    H = PLAYER_FACTION_COLORS and PLAYER_FACTION_COLORS[0] or { r = 0.9, g = 0.05, b = 0.07 },
    A = PLAYER_FACTION_COLORS and PLAYER_FACTION_COLORS[1] or { r = 0.29, g = 0.33, b = 0.91 },
    N = { r = 0.9, g = 0.7, b = 0 },
}

---The color of a side in map data: "H" (Horde), "A" (Alliance), or anything else for neutral.
---@param side string?
---@return table color with r, g, b
function Colors.Faction(side)
    return FACTION_COLORS[side or "N"] or FACTION_COLORS.N
end

---The unit's class color (a ColorMixin), or nil when its class can't be read (secret, mostly in
---instances). NPCs have classes too, so check UnitIsPlayer first when only players should get one.
---@param unit string
---@return table?
function Colors.Class(unit)
    local _, class = UnitClass(unit)
    if readable(class) and class and C_ClassColor then
        return C_ClassColor.GetClassColor(class)
    end
end

---Like `Colors.Class`, but nil for anything that isn't a player.
---@param unit string
---@return table?
function Colors.PlayerClass(unit)
    local player = UnitIsPlayer(unit)
    if readable(player) and player then
        return Colors.Class(unit)
    end
end
