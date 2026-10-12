-- Coordinates, a part of World Map: the player's and the cursor's coordinates on the world map.
-- Forever's map already has them (Blizzard's coordinates panel, shown by its own checkboxes under
-- Settings > Gameplay > Interface > Coordinates), so this leaves which ones show, and tenths, to
-- those, and moves Blizzard's text into the map's title bar: the player's on the left, the
-- cursor's on the right, either side of the title. Ideas from Leatrix Maps' coordinates; none of
-- its code.
local _, ns = ...

local ipairs, max, min = ipairs, math.max, math.min
local CreateFrame = CreateFrame

local L = ns.L
local CVars = ns.CVars

local module = ns.modules.WorldMap:NewPart({
    key = "coordinates", name = L.COORDS_TITLE, description = L.COORDS_DESC,
    section = L.COORDS_TITLE,
})

-- Blizzard's checkboxes for the player's and the cursor's coordinates on the map. Forever only;
-- see docs/forever-api.md.
local MAP_CVARS = { "worldMapShowPlayerCoords", "worldMapShowCursorCoords" }

local function anyShown()
    return CVars.IsOn(MAP_CVARS[1]) or CVars.IsOn(MAP_CVARS[2])
end

-- With both of Blizzard's checkboxes off there's nothing to move, so World Map says so, with a
-- button that turns both on.
module.module.notice = {
    text = L.COORDS_BLIZZARD_OFF,
    description = L.COORDS_BLIZZARD_OFF_DESC,
    button = L.SETTINGS_TURN_ON,
    fn = function()
        for _, name in ipairs(MAP_CVARS) do
            CVars.Apply(name, "1")
        end
    end,
    shown = function()
        return module.module.db.enabled and module.db.coordinates and not anyShown()
    end,
}

local INSET = 8 -- from the title bar's ends
local GAP = 12 -- the least room kept either side of the title
local THROTTLE = 0.05

-- The title bar ------------------------------------------------------------------------------

local coords -- Blizzard's panel, once found
local bar -- ours: two lines over the title bar

-- A line at one end of the bar: `point` is its side, against `edge`'s other side.
local function newLine(frame, point, edge, relativePoint, x)
    local line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetPoint(point, edge, relativePoint, x, -1)
    line:SetJustifyH(point)
    line:SetWordWrap(false)
    return line
end

-- Our frame covers the title bar, a level above it so the text draws over its art. The title bar
-- is anchored to the map's frame, so it widens with the quest log and when the map is maximized,
-- and our lines follow. The cursor's stops short of the maximize button.
local function newBar(border)
    local title = border.TitleContainer
    local frame = CreateFrame("Frame", nil, border)
    frame:SetFrameLevel(title:GetFrameLevel() + 1)
    frame:SetAllPoints(title)
    frame.player = newLine(frame, "LEFT", frame, "LEFT", INSET)
    local button = border.MaximizeMinimizeFrame
    if button then
        frame.cursor = newLine(frame, "RIGHT", button, "LEFT", -INSET)
    else
        frame.cursor = newLine(frame, "RIGHT", frame, "RIGHT", -INSET)
    end
    return frame
end

local textWidth = ns.Text.Width

-- One line from a row of Blizzard's: its text, which already has the tenths setting and, off the
-- player's map, the player's zone, cut short with "..." before it reaches the title.
local function copy(line, row, room)
    if not row:IsShown() then
        line:Hide()
        return
    end
    line:SetWidth(0)
    line:SetText(row.Label:GetText())
    line:SetWidth(min(textWidth(line), max(room, 0)))
    line:Show()
end

local function update()
    local titleText = WorldMapFrame.BorderFrame.TitleContainer.TitleText
    local titleWidth = titleText and textWidth(titleText) or 0
    -- Half the bar beside the title, less the ends and the maximize button's width on the right.
    local half = (bar:GetWidth() - titleWidth) / 2 - GAP - INSET
    local button = WorldMapFrame.BorderFrame.MaximizeMinimizeFrame
    copy(bar.player, coords.PlayerCoords, half)
    copy(bar.cursor, coords.CursorCoords, half - (button and button:GetWidth() or 0))
end

local onUpdate = ns.WorldMap.Throttled(THROTTLE, update)

-- Ours in the title bar, or Blizzard's panel as it comes. Blizzard's text is only faded out, so
-- it keeps updating for ours to copy. Ours is the border frame's child, so it stops with the map.
local function restyle()
    local on = module.enabled and true or false
    coords:SetAlpha(on and 0 or 1)
    bar:SetShown(on)
    bar:SetScript("OnUpdate", on and onUpdate or nil)
    if on then
        update()
    end
end

local function attach(map)
    if not bar then
        local border = map.BorderFrame
        coords = ns.WorldMap.CoordsPanel()
        if not (coords and border and border.TitleContainer) then
            return -- a client without Blizzard's panel; its coordinates stay where they are
        end
        bar = newBar(border)
    end
    restyle()
end

function module:OnEnable()
    ns.WorldMap.WhenLoaded(attach)
end

function module:OnDisable()
    ns.WorldMap.Cancel(attach)
    if bar then
        restyle()
    end
end
