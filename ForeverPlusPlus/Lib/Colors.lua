-- Colors more than one module uses, so the same thing looks the same everywhere (a guild name on a
-- nameplate and in a tooltip), and color codes for text.
local _, ns = ...

local format, floor = string.format, math.floor
local RECENT_ALLY_FONT_COLOR = RECENT_ALLY_FONT_COLOR

local Colors = {
    GRAY = { 0.65, 0.65, 0.65 }, -- a guild name or an NPC title that isn't highlighted
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
