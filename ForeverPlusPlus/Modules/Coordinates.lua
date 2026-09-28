-- Coordinates: the player's and the cursor's coordinates on the world map. Forever's map already
-- has them (Blizzard's coordinates panel, off until its Settings checkboxes are on), so this turns
-- those settings on from here, one toggle each, and puts a tooltip-style background behind the
-- panel so it reads over any map art. Ideas from Leatrix Maps' coordinates; none of its code.
local _, ns = ...

local ipairs, pairs, max, ceil = ipairs, pairs, math.max, math.ceil
local CreateFrame, C_AddOns, C_XMLUtil = CreateFrame, C_AddOns, C_XMLUtil

local L = ns.L

local module = ns.NewModule("Coordinates", L.COORDS_DESC, {
    enabled = false,
    player = true,
    cursor = true,
    tenths = true,
    minimap = false,
    background = true,
    saved = {}, -- CVar -> the player's own value, put back when the module turns off
})
module.title = L.COORDS_TITLE
module.category = "map"

module.options = {
    { key = "player", name = L.COORDS_PLAYER, description = L.COORDS_PLAYER_DESC },
    { key = "cursor", name = L.COORDS_CURSOR, description = L.COORDS_CURSOR_DESC },
    { key = "tenths", name = L.COORDS_TENTHS, description = L.COORDS_TENTHS_DESC },
    { key = "minimap", name = L.COORDS_MINIMAP, description = L.COORDS_MINIMAP_DESC },
    { key = "background", name = L.COORDS_BACKGROUND, description = L.COORDS_BACKGROUND_DESC },
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
local PAD_X, PAD_Y = 6, 2 -- around the text; the panel sits 2 pixels above the map's edge
local STEP = 8 -- the background's width grows in steps, so it doesn't twitch as numbers change
local THROTTLE = 0.1

-- Sets the client's setting to match an option, remembering the player's value the first time.
local function applyCVar(key)
    ns.CVars.Set(module.db.saved, CVARS[key], module.db[key] and "1" or "0")
end

-- The background ---------------------------------------------------------------------------------

local coords -- Blizzard's panel, once found
local background -- ours, a child of it drawn under its rows

-- Blizzard's coordinates panel: the map's overlay frame with a cursor row and a player row. It
-- has no name, so it's found by its parts.
local function findPanel()
    for _, frame in ipairs(WorldMapFrame.overlayFrames or {}) do
        if frame.CursorCoords and frame.PlayerCoords then
            return frame
        end
    end
end

-- A tooltip's look, like Zone Info's panel. Probe: the template is Mainline's; without it, the
-- plain backdrop template and its tooltip backdrop.
local function newBackground(parent)
    local hasTemplate = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("TooltipBackdropTemplate")
    local frame = CreateFrame("Frame", nil, parent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    if not hasTemplate and frame.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        frame:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        frame:SetBackdropColor(0, 0, 0, 0.8)
    end
    -- On the panel's own level, so its rows (one level up) draw over it.
    frame:SetFrameLevel(parent:GetFrameLevel())
    frame:Hide()
    return frame
end

-- Fits the background around the rows Blizzard shows now, or hides it when there are none.
local function fit()
    local width, top, bottom = 0, nil, nil
    for _, row in ipairs({ coords.CursorCoords, coords.PlayerCoords }) do
        if row:IsShown() then
            width = max(width, row.Label:GetStringWidth())
            top = top or row
            bottom = row
        end
    end
    if not (module.db.background and top) then
        background:Hide()
        return
    end
    background:ClearAllPoints()
    background:SetPoint("TOPLEFT", top, "TOPLEFT", -PAD_X, PAD_Y)
    background:SetPoint("BOTTOM", bottom, "BOTTOM", 0, -PAD_Y)
    background:SetWidth(ceil(width / STEP) * STEP + PAD_X * 2)
    background:Show()
end

local elapsed = 0
local function onUpdate(_, delta)
    elapsed = elapsed + delta
    if elapsed >= THROTTLE then
        elapsed = 0
        fit()
    end
end

local waiting

-- Adds the background to Blizzard's panel, once the map has loaded. Its driver is the panel's
-- child, so it stops while the map is closed.
local function attach()
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    if not background then
        coords = findPanel()
        if not coords then
            return -- a client without Blizzard's panel; the settings still apply
        end
        background = newBackground(coords)
    end
    background:SetScript("OnUpdate", onUpdate)
    fit()
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
    if background then
        background:SetScript("OnUpdate", nil)
        background:Hide()
    end
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    elseif CVARS[key] then
        applyCVar(key)
    elseif background then
        fit()
    end
end
