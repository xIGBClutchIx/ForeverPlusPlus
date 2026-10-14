-- Minimap Node Icons' probes: pointing the minimap's mouseover at a spot and reading the names its
-- tooltip gives there, the spaces the spot may be measured in, and the grid a finding pass probes.
local _, ns = ...

local ipairs, type, pcall, floor, tonumber = ipairs, type, pcall, math.floor, tonumber
local gmatch, match, tostring, format = string.gmatch, string.match, tostring, string.format
local min, max = math.min, math.max
local Minimap, C_TooltipInfo = Minimap, C_TooltipInfo

local L = ns.L
local readable = ns.IsReadable
local plain = ns.Text.Plain
local Profiler = ns.Profiler

local module = ns.modules.MinimapNodeIcons
local internal = module.internal

local PART_ASK = Profiler.Part(module, L.MINIMAPNODEICONS_PART_ASK)

-- What UpdateMouseoverAtPoint's point is measured in isn't documented (see docs/forever-api.md), so
-- each way it could be is tried until a pass finds a node, and the one that does is saved. Each
-- turns minimap units right and up of its center into that space.
local SPACES = {
    -- Screen pixels from the bottom left, like GetCursorPosition.
    cursor = function(right, up)
        local cx, cy = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        return (cx + right) * scale, (cy + up) * scale
    end,
    -- Minimap units from its center.
    center = function(right, up)
        return right, up
    end,
    -- Minimap units from its bottom left.
    corner = function(right, up)
        return Minimap:GetWidth() / 2 + right, Minimap:GetHeight() / 2 + up
    end,
    -- 0 to 1 across and up the minimap.
    unit = function(right, up)
        return 0.5 + right / Minimap:GetWidth(), 0.5 + up / Minimap:GetHeight()
    end,
}
local ORDER = { "cursor", "center", "corner", "unit" }
internal.ORDER = ORDER
local trying = 1 -- the space in ORDER tried while none is saved

function internal.currentSpace()
    return module.db.calibration.space or ORDER[trying]
end

-- A pass found nothing in the space it tried: try the next one.
function internal.nextSpace()
    trying = trying % #ORDER + 1
end

-- A line's own color as r, g, b, or nil. Tooltip data colors are color mixins or plain tables.
local function lineColor(line)
    local color = line.leftColor
    if not (color and readable(color) and type(color) == "table") then
        return nil
    end
    if color.GetRGB then
        return color:GetRGB()
    end
    return color.r, color.g, color.b
end

-- Whether a name's color is gray rather than white or a color: how the minimap may name a node on
-- another level than the player, as in a cave. Unverified; /fpp nodes here prints the color.
local function isGray(r, g, b)
    if not (r and g and b and readable(r) and readable(g) and readable(b)) then
        return false
    end
    local high, low = max(r, g, b), min(r, g, b)
    return high < 0.8 and high - low < 0.08
end

-- The names in a line of a probe's text, one per row (overlapping dots each add one), without the
-- color codes and spaces the game may wrap them in, each with its color: its own color code, or
-- else the line's.
local function addNames(list, text, r, g, b)
    for row in gmatch(text, "[^\n]+") do
        local hex = match(row, "|c%x%x(%x%x%x%x%x%x)")
        local cr, cg, cb = r, g, b
        if hex then
            cr = tonumber(hex:sub(1, 2), 16) / 255
            cg = tonumber(hex:sub(3, 4), 16) / 255
            cb = tonumber(hex:sub(5, 6), 16) / 255
        end
        local name = strtrim(plain(row))
        if name ~= "" then
            list[#list + 1] = { name = name, gray = isGray(cr, cg, cb), r = cr, g = cg, b = cb }
        end
    end
end

-- What the minimap's mouseover names now: a list of { name, gray, r, g, b }, or nil.
local function readMouseover()
    local data = C_TooltipInfo.GetMinimapMouseover()
    local lines = data and data.lines
    if not (lines and readable(lines) and type(lines) == "table") then
        return nil
    end
    local list
    for _, line in ipairs(lines) do
        local left = line.leftText
        if ns.IsText(left, true) then
            list = list or {}
            addNames(list, left, lineColor(line))
        end
    end
    return list
end
internal.readMouseover = readMouseover

-- Points the minimap's mouseover at a spot right and up of its center and returns what it names
-- there, as readMouseover does. Call between startProbing and stopProbing.
function internal.probe(right, up, space)
    local x, y = (SPACES[space] or SPACES.cursor)(right, up)
    if Profiler.recording then
        Profiler.Count(PART_ASK)
    end
    local ok, err = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, x, y)
    if not ok then
        internal.blocked = true
        module:Print(format(L.MINIMAPNODEICONS_FAILED, tostring(err)))
        return nil
    end
    return readMouseover()
end

-- The minimap takes a probe's point only in soft cursor mode (a controller's cursor); otherwise
-- the mouse's spot wins and every probe reads nothing (in game, 2026-10-13). So probes run between
-- these two: on, then the point off the minimap and back to the mouse. This would also end a real
-- controller's soft cursor on the minimap; it takes it up again as it moves.
function internal.startProbing()
    if Minimap.SetUsingSoftCursor then
        pcall(Minimap.SetUsingSoftCursor, Minimap, true)
    end
end

function internal.stopProbing()
    pcall(Minimap.UpdateMouseoverAtPoint, Minimap, -10000, -10000)
    if Minimap.SetUsingSoftCursor then
        pcall(Minimap.SetUsingSoftCursor, Minimap, false)
    end
end

-- The spots a finding pass probes, right and up of the minimap's center, inside its circle.
local points, pointsFor

function internal.grid(half, spacing)
    local key = half .. ":" .. spacing
    if pointsFor == key then
        return points
    end
    points, pointsFor = {}, key
    local radius = half - internal.EDGE
    local n = floor(radius / spacing)
    for i = -n, n do
        for j = -n, n do
            local right, up = i * spacing, j * spacing
            if right * right + up * up <= radius * radius then
                points[#points + 1] = { right, up }
            end
        end
    end
    return points
end
