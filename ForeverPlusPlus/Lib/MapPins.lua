-- Our own icons on the world map, through Blizzard's map data providers: the map asks for the
-- icons each time it shows a map and drops them when it leaves it. The icons are our own frames
-- on the map's canvas (no XML template, so no global mixin), kept the same size on screen at every
-- zoom. They show a tooltip but let clicks through, so the map still zooms and changes maps.
-- Nothing is made until a layer is enabled.
local _, ns = ...

local ipairs, select, setmetatable = ipairs, select, setmetatable
local CreateFrame, CreateFromMixins = CreateFrame, CreateFromMixins
local C_AddOns, C_Texture, GameTooltip = C_AddOns, C_Texture, GameTooltip
local NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR = NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR

local MapPins = {}
ns.MapPins = MapPins

local MAP_ADDON = "Blizzard_WorldMap"

-- The world map, once its addon has loaded. Probe: it's loaded at login on Mainline, but it's a
-- load-on-demand Blizzard addon, so don't count on it.
local function worldMap()
    return (not C_AddOns or C_AddOns.IsAddOnLoaded(MAP_ADDON)) and WorldMapFrame or nil
end

---The first atlas in the list this client has, or the last one. For art that may not exist on
---every build.
---@param ... string atlas names, best first
---@return string
function MapPins.Atlas(...)
    local count = select("#", ...)
    for i = 1, count - 1 do
        local name = select(i, ...)
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
            return name
        end
    end
    return (select(count, ...))
end

-- Pins ----------------------------------------------------------------------------------------

local function onEnter(pin)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(pin.info.title, HIGHLIGHT_FONT_COLOR:GetRGB())
    for _, line in ipairs(pin.info.lines or {}) do
        GameTooltip:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
    pin.highlight:Show()
end

local function onLeave(pin)
    GameTooltip:Hide()
    pin.highlight:Hide()
end

local function newPin(canvas)
    local pin = CreateFrame("Frame", nil, canvas)
    pin.texture = pin:CreateTexture(nil, "ARTWORK")
    pin.texture:SetAllPoints()
    pin.highlight = pin:CreateTexture(nil, "OVERLAY")
    pin.highlight:SetAllPoints()
    pin.highlight:SetBlendMode("ADD")
    pin.highlight:SetAlpha(0.5)
    pin.highlight:Hide()
    -- Hover for the tooltip; clicks go through to the map. Probe: without the split, the pin
    -- takes the mouse whole.
    if pin.SetMouseMotionEnabled and pin.SetMouseClickEnabled then
        pin:SetMouseMotionEnabled(true)
        pin:SetMouseClickEnabled(false)
    else
        pin:EnableMouse(true)
    end
    pin:SetScript("OnEnter", onEnter)
    pin:SetScript("OnLeave", onLeave)
    return pin
end

-- Puts a pin at its place on the canvas, sized so the map's zoom doesn't change it on screen.
local function place(pin, map)
    local canvas = map:GetCanvas()
    local scale = map.GetCanvasScale and map:GetCanvasScale() or 1
    local size = pin.info.size / (scale > 0 and scale or 1)
    pin:SetSize(size, size)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT", canvas:GetWidth() * pin.x,
        -canvas:GetHeight() * pin.y)
end

-- Layers --------------------------------------------------------------------------------------

local Layer = {}
Layer.__index = Layer

-- Hides every pin and keeps it for the next map.
function Layer:Release()
    for i = 1, self.count do
        local pin = self.pins[i]
        if GameTooltip:IsOwned(pin) then
            GameTooltip:Hide()
        end
        pin:Hide()
        pin.info = nil
    end
    self.count = 0
end

function Layer:Add(map, x, y, info)
    self.count = self.count + 1
    local pin = self.pins[self.count]
    if not pin then
        pin = newPin(map:GetCanvas())
        self.pins[self.count] = pin
    end
    pin.x, pin.y, pin.info = x, y, info
    pin.texture:SetAtlas(info.atlas)
    pin.highlight:SetAtlas(info.atlas)
    -- Where Blizzard's own dungeon entrance icons go: above the map art and areas, below quests.
    local manager = map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
    if manager then
        pin:SetFrameLevel(manager:GetValidFrameLevel("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE"))
    end
    place(pin, map)
    pin:Show()
end

-- Draws the pins for the map it shows now.
function Layer:Draw()
    self:Release()
    local map = self.provider:GetMap()
    local mapID = map and map:GetMapID()
    if not mapID then
        return
    end
    self.fill(mapID, function(x, y, info)
        self:Add(map, x, y, info)
    end)
end

function Layer:Place()
    local map = self.provider:GetMap()
    if not map then
        return
    end
    for i = 1, self.count do
        place(self.pins[i], map)
    end
end

-- The layer's data provider: what the map calls as it changes maps and zooms. Made once the map
-- has loaded, since the mixin comes with it.
local function newProvider(layer)
    local provider = CreateFromMixins(MapCanvasDataProviderMixin)
    function provider:RemoveAllData()
        layer:Release()
    end
    function provider:RefreshAllData()
        layer:Draw()
    end
    function provider:OnCanvasScaleChanged()
        layer:Place()
    end
    function provider:OnCanvasSizeChanged()
        layer:Place()
    end
    return provider
end

-- Adds the layer to the world map, once it has loaded.
function Layer:Attach()
    local map = worldMap()
    if not map then
        return
    end
    if self.waiting then
        ns.Off("ADDON_LOADED", self.waiting)
        self.waiting = nil
    end
    self.provider = self.provider or newProvider(self)
    if not self.attached then
        self.attached = true
        map:AddDataProvider(self.provider)
        -- Adding a provider doesn't draw it; the map only asks when it shows or changes map.
        if map:IsShown() then
            self:Draw()
        end
    end
end

---Shows the layer's pins on the world map.
function Layer:Enable()
    self.enabled = true
    if worldMap() then
        self:Attach()
    elseif not self.waiting then
        self.waiting = function(_, name)
            if name == MAP_ADDON and self.enabled then
                self:Attach()
            end
        end
        ns.On("ADDON_LOADED", self.waiting)
    end
end

---Takes the layer's pins off the world map.
function Layer:Disable()
    self.enabled = false
    if self.waiting then
        ns.Off("ADDON_LOADED", self.waiting)
        self.waiting = nil
    end
    if self.attached then
        self.attached = false
        worldMap():RemoveDataProvider(self.provider)
    end
    self:Release()
end

---Redraws the pins, after something that decides them changed (a setting).
function Layer:Refresh()
    if self.attached then
        self:Draw()
    end
end

---Makes a layer of map pins. `fill(mapID, add)` runs each time the map shows a map, and calls
---`add(x, y, info)` for each pin: x and y from 0 to 1 across the map, and info
---`{ atlas, size, title, lines }` (size in pixels on screen; lines of tooltip text under the
---title). Call `layer:Enable()` to show it and `layer:Disable()` to take it off.
---@param fill fun(mapID: number, add: fun(x: number, y: number, info: table))
---@return table layer
function MapPins.New(fill)
    return setmetatable({ fill = fill, pins = {}, count = 0 }, Layer)
end
