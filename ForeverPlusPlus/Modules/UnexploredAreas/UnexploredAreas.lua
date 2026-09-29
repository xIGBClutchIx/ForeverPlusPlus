-- Unexplored Areas: the parts of zone maps you haven't explored yet, drawn in the same art as the
-- ones you have, on the world map and the zone map. They're tinted by default so the two stand
-- apart. The game only knows the explored areas, so the art of the rest is in Data.lua.
-- Blizzard's own explored areas are left alone: these are our own textures on our own frame,
-- under a data provider of our own, on each map's canvas.
local _, ns = ...

local ceil, ipairs, pairs, setmetatable = math.ceil, ipairs, pairs, setmetatable
local CreateFrame, C_AddOns, C_Map, C_MapExplorationInfo =
    CreateFrame, C_AddOns, C_Map, C_MapExplorationInfo

local L = ns.L

local module = ns.NewModule("UnexploredAreas", L.UNEXPLORED_DESC, {
    enabled = true,
    tint = true,
    tintStrength = 70, -- percent of the full color
    tintColor = "gray",
})
module.title = L.UNEXPLORED_TITLE
module.category = "map"

-- The tint colors at full strength. Gray by default: unexplored areas read as faded, not colored.
local COLORS = {
    gray = { 0.5, 0.5, 0.5 },
    blue = { 0.4, 0.55, 1 },
    gold = { 1, 0.8, 0.35 },
    green = { 0.5, 1, 0.45 },
    red = { 1, 0.4, 0.35 },
    purple = { 0.75, 0.45, 1 },
}

module.options = {
    { key = "tint", name = L.UNEXPLORED_TINT, description = L.UNEXPLORED_TINT_DESC,
        slider = "tintStrength" },
    {
        key = "tintStrength", name = L.UNEXPLORED_STRENGTH,
        description = L.UNEXPLORED_STRENGTH_DESC, requires = "tint", min = 10, max = 100, step = 10, format = "%d%%",
    },
    {
        key = "tintColor", name = L.UNEXPLORED_COLOR, description = L.UNEXPLORED_COLOR_DESC,
        requires = "tint",
        choices = {
            { "gray", L.UNEXPLORED_GRAY },
            { "blue", L.UNEXPLORED_BLUE },
            { "gold", L.UNEXPLORED_GOLD },
            { "green", L.UNEXPLORED_GREEN },
            { "red", L.UNEXPLORED_RED },
            { "purple", L.UNEXPLORED_PURPLE },
        },
    },
}

-- Shared with Data.lua: `overlays`, by map art ID.
module.internal = {}
local internal = module.internal

-- The vertex color for unexplored areas: white untinted, or the tint color mixed with white by
-- its strength.
local function tintColor()
    local db = module.db
    if not db.tint then
        return 1, 1, 1
    end
    local color = COLORS[db.tintColor] or COLORS.gray
    local strength = db.tintStrength / 100
    return 1 - (1 - color[1]) * strength, 1 - (1 - color[2]) * strength,
        1 - (1 - color[3]) * strength
end

-- The maps it draws on, with the load-on-demand Blizzard addon each comes with.
local MAPS = {
    { addon = "Blizzard_WorldMap", frame = function() return WorldMapFrame end },
    { addon = "Blizzard_BattlefieldMap", frame = function() return BattlefieldMapFrame end },
}

-- The map frame, once its addon has loaded.
local function mapFrame(entry)
    if C_AddOns and not C_AddOns.IsAddOnLoaded(entry.addon) then
        return nil
    end
    return entry.frame()
end

-- One area as a number, to match the game's explored areas against Data.lua's. Sizes and
-- offsets are under 2048 map pixels.
local function areaKey(width, height, x, y)
    return ((width * 2048 + height) * 2048 + x) * 2048 + y
end

-- A tile's size on the map and in its file, like Blizzard's own explored areas: a full tile fills
-- its file; the last in a row or column is what's left, in a file rounded up to a power of two.
local function tileSize(total, tile, index, count)
    if index < count then
        return tile, tile
    end
    local size = total % tile
    if size == 0 then
        size = tile
    end
    local file = 16
    while file < size do
        file = file * 2
    end
    return size, file
end

-- Drawing on one map -----------------------------------------------------------------------------

local Overlay = {}
Overlay.__index = Overlay

-- Hides every texture and keeps it for the next map.
function Overlay:Release()
    for i = 1, self.count do
        self.textures[i]:Hide()
    end
    self.count = 0
end

function Overlay:Texture()
    self.count = self.count + 1
    local texture = self.textures[self.count]
    if not texture then
        texture = self.frame:CreateTexture(nil, "ARTWORK")
        -- The map's own mask, so the areas stay inside the map when it's zoomed in.
        if self.map.AddMaskableTexture then
            self.map:AddMaskableTexture(texture)
        end
        self.textures[self.count] = texture
    end
    return texture
end

-- One area of Data.lua, in its tiles.
function Overlay:Add(area, tileWidth, tileHeight, r, g, b)
    local width, height, x, y = area[1], area[2], area[3], area[4]
    local wide, tall = ceil(width / tileWidth), ceil(height / tileHeight)
    for row = 1, tall do
        local pixelHeight, fileHeight = tileSize(height, tileHeight, row, tall)
        for column = 1, wide do
            local pixelWidth, fileWidth = tileSize(width, tileWidth, column, wide)
            local texture = self:Texture()
            texture:SetTexture(area[4 + (row - 1) * wide + column], nil, nil, "TRILINEAR")
            texture:SetSize(pixelWidth, pixelHeight)
            texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", x + tileWidth * (column - 1),
                -(y + tileHeight * (row - 1)))
            texture:SetVertexColor(r, g, b)
            texture:Show()
        end
    end
end

-- Draws the unexplored areas of the map it shows now.
function Overlay:Draw()
    self:Release()
    local map = self.map
    local mapID = map:GetMapID()
    local artID = mapID and C_Map.GetMapArtID(mapID)
    local areas = artID and internal.overlays[artID]
    if not areas then
        return
    end
    self.layerIndex = map:GetCanvasContainer():GetCurrentLayerIndex()
    local layers = C_Map.GetMapArtLayers(mapID)
    local layer = layers and layers[self.layerIndex]
    if not layer then
        return
    end
    local explored = {}
    local textures = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures(mapID)
    for _, info in ipairs(textures or {}) do
        explored[areaKey(info.textureWidth, info.textureHeight, info.offsetX, info.offsetY)] = true
    end
    -- Where Blizzard's explored areas go: above the map art, below every icon.
    local manager = map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
    if manager then
        self.frame:SetFrameLevel(manager:GetValidFrameLevel("PIN_FRAME_LEVEL_MAP_EXPLORATION"))
    end
    local r, g, b = tintColor()
    for _, area in ipairs(areas) do
        if not explored[areaKey(area[1], area[2], area[3], area[4])] then
            self:Add(area, layer.tileWidth, layer.tileHeight, r, g, b)
        end
    end
end

-- The data provider the map calls as it changes maps and zooms.
local function newProvider(overlay)
    return ns.WorldMap.NewProvider({
        RemoveAllData = function() overlay:Release() end,
        RefreshAllData = function() overlay:Draw() end,
        -- Zooming can switch to another layer of map art, with other tile sizes.
        OnCanvasScaleChanged = function()
            local container = overlay.map:GetCanvasContainer()
            if overlay.layerIndex ~= container:GetCurrentLayerIndex() then
                overlay:Draw()
            end
        end,
        -- The map fades while the player moves, if they chose that; fade with it.
        OnGlobalAlphaChanged = function()
            if overlay.map.GetGlobalAlpha then
                overlay.frame:SetAlpha(overlay.map:GetGlobalAlpha())
            end
        end,
    })
end

local function newOverlay(map)
    local frame = CreateFrame("Frame", nil, map:GetCanvas())
    frame:SetAllPoints()
    local overlay = setmetatable({ map = map, frame = frame, textures = {}, count = 0 }, Overlay)
    overlay.provider = newProvider(overlay)
    return overlay
end

-- Turning on and off ------------------------------------------------------------------------------

-- An overlay per map frame, made the first time it's attached.
local overlays = {}
-- The overlays on their maps now.
local attached = {}

local function attach(entry)
    local map = mapFrame(entry)
    if not map or attached[entry] then
        return
    end
    overlays[entry] = overlays[entry] or newOverlay(map)
    local overlay = overlays[entry]
    attached[entry] = overlay
    map:AddDataProvider(overlay.provider)
    -- Adding a provider doesn't draw it; the map only asks when it shows or changes map.
    if map:IsShown() then
        overlay:Draw()
    end
end

local function redraw()
    for _, overlay in pairs(attached) do
        if overlay.map:IsShown() then
            overlay:Draw()
        end
    end
end

function module:OnEnable()
    for _, entry in ipairs(MAPS) do
        attach(entry)
    end
    -- The zone map loads when it's first opened.
    self:On("ADDON_LOADED", function(_, name)
        for _, entry in ipairs(MAPS) do
            if entry.addon == name then
                attach(entry)
            end
        end
    end)
    -- A newly explored area now comes from Blizzard; stop drawing it.
    self:On("MAP_EXPLORATION_UPDATED", redraw)
end

function module:OnDisable()
    for entry, overlay in pairs(attached) do
        overlay.map:RemoveDataProvider(overlay.provider)
        overlay:Release()
        attached[entry] = nil
    end
end

function module:OnOptionChanged()
    if self.enabled then
        redraw()
    end
end
