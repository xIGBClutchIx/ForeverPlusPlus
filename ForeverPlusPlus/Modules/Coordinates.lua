-- Coordinates: the player's and the cursor's coordinates on the world map. Forever's map already
-- has them (Blizzard's coordinates panel, off until its Settings checkboxes are on), so this turns
-- those settings on from here, one toggle each, and shows Blizzard's text in a panel like Zone
-- Info's, so it reads over any map art. Ideas from Leatrix Maps' coordinates; none of its code.
local _, ns = ...

local ipairs, pairs, max = ipairs, pairs, math.max
local CreateFrame, C_AddOns, C_XMLUtil = CreateFrame, C_AddOns, C_XMLUtil

local L = ns.L

local module = ns.NewModule("Coordinates", L.COORDS_DESC, {
    enabled = false,
    player = true,
    cursor = true,
    tenths = true,
    minimap = false,
    panel = true,
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.COORDS_TITLE
module.category = "map"

module.options = {
    { key = "player", name = L.COORDS_PLAYER, description = L.COORDS_PLAYER_DESC },
    { key = "cursor", name = L.COORDS_CURSOR, description = L.COORDS_CURSOR_DESC },
    { key = "tenths", name = L.COORDS_TENTHS, description = L.COORDS_TENTHS_DESC },
    { key = "minimap", name = L.COORDS_MINIMAP, description = L.COORDS_MINIMAP_DESC },
    { key = "panel", name = L.COORDS_PANEL, description = L.COORDS_PANEL_DESC },
}

-- The client's own setting behind each option: the checkboxes under Settings > Gameplay >
-- Interface > Coordinates. Forever only; see docs/forever-api.md.
local CVARS = {
    player = "worldMapShowPlayerCoords",
    cursor = "worldMapShowCursorCoords",
    tenths = "coordsByTenths",
    minimap = "minimapShowPlayerCoords",
}

local MAP_ADDON = "Blizzard_WorldMap"
local LEFT, BOTTOM = 60, 4 -- where Blizzard's panel is, a little inside the map's edge
local PADDING = 6
local GAP = 2 -- between rows
local THROTTLE = 0.05

-- Sets the client's setting to match an option, remembering the player's value the first time.
local function applyCVar(key)
    ns.CVars.Set(module.db.saved, CVARS[key], module.db[key] and "1" or "0")
end

-- The panel ----------------------------------------------------------------------------------

local coords -- Blizzard's panel, once found
local panel, driver -- ours

-- Blizzard's coordinates panel: the map's overlay frame with a cursor row and a player row. It
-- has no name, so it's found by its parts.
local function findCoords()
    for _, frame in ipairs(WorldMapFrame.overlayFrames or {}) do
        if frame.CursorCoords and frame.PlayerCoords then
            return frame
        end
    end
end

-- A tooltip's look, like Zone Info's panel, on the map's scroll container over its pins.
-- Blizzard's own panel sits under the map art's level, so a background behind its text doesn't
-- show; this shows the same text on a frame of our own instead. Probe: the template is
-- Mainline's; without it, the plain backdrop template and its tooltip backdrop.
local function newPanel(parent)
    local hasTemplate = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("TooltipBackdropTemplate")
    local frame = CreateFrame("Frame", nil, parent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    if not hasTemplate and frame.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        frame:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        frame:SetBackdropColor(0, 0, 0, 0.8)
    end
    frame:SetFrameLevel(parent:GetFrameLevel() + 2000)
    frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", LEFT, BOTTOM)
    frame.lines = {}
    for i = 1, 2 do
        local line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line:SetJustifyH("LEFT")
        frame.lines[i] = line
    end
    frame:Hide()
    return frame
end

-- How wide a line is. Probe: GetUnboundedStringWidth is Mainline's.
local function textWidth(text)
    return text.GetUnboundedStringWidth and text:GetUnboundedStringWidth() or text:GetStringWidth()
end

-- Copies the rows Blizzard shows now (cursor, then player) into ours: its text already has the
-- tenths setting and, off the player's map, the player's zone.
local function update()
    local width, height, above = 0, PADDING * 2 - GAP, nil
    for i, row in ipairs({ coords.CursorCoords, coords.PlayerCoords }) do
        local line = panel.lines[i]
        if row:IsShown() then
            line:SetText(row.Label:GetText())
            line:ClearAllPoints()
            if above then
                line:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -GAP)
            else
                line:SetPoint("TOPLEFT", PADDING, -PADDING)
            end
            line:Show()
            width = max(width, textWidth(line))
            height = height + GAP + line:GetStringHeight()
            above = line
        else
            line:Hide()
        end
    end
    if not above then
        panel:Hide()
        return
    end
    panel:SetSize(width + PADDING * 2, height)
    panel:Show()
end

local elapsed = 0
local function onUpdate(_, delta)
    elapsed = elapsed + delta
    if elapsed >= THROTTLE then
        elapsed = 0
        update()
    end
end

-- Our panel in place of Blizzard's, or Blizzard's as it comes. Its own text is only faded out, so
-- it keeps updating for ours to copy.
local function restyle()
    local on = module.enabled and module.db.panel
    coords:SetAlpha(on and 0 or 1)
    driver:SetShown(on)
    if on then
        update()
    else
        panel:Hide()
    end
end

local waiting

-- Makes our panel on the world map, once the map has loaded. The driver is the scroll
-- container's child, so it stops while the map is closed.
local function attach()
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    if not panel then
        coords = findCoords()
        if not coords then
            return -- a client without Blizzard's panel; the settings still apply
        end
        local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
        panel = newPanel(parent)
        driver = CreateFrame("Frame", nil, parent)
        driver:SetScript("OnUpdate", onUpdate)
    end
    restyle()
end

local function mapLoaded()
    return (not C_AddOns or C_AddOns.IsAddOnLoaded(MAP_ADDON)) and WorldMapFrame
end

function module:OnEnable()
    for key in pairs(CVARS) do
        applyCVar(key)
    end
    if mapLoaded() then
        attach()
    else
        waiting = function(_, name)
            if name == MAP_ADDON then
                attach()
            end
        end
        ns.On("ADDON_LOADED", waiting)
    end
end

function module:OnDisable()
    ns.CVars.RestoreAll(self.db.saved)
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    if panel then
        restyle()
    end
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    elseif CVARS[key] then
        applyCVar(key)
    elseif panel then
        restyle()
    end
end
