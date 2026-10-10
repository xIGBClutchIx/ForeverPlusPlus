-- The world map, which comes with a load-on-demand Blizzard addon: whether it has loaded, code to
-- run once it has, and the parts of it more than one module finds. Nothing is listened to until a
-- module waits for it.
local _, ns = ...

local ipairs, pairs = ipairs, pairs
local sqrt, atan2, pi = math.sqrt, math.atan2, math.pi
local UnitFactionGroup, CreateFromMixins = UnitFactionGroup, CreateFromMixins
local FACTION_ALLIANCE, FACTION_HORDE = FACTION_ALLIANCE, FACTION_HORDE

local WorldMap = {}
ns.WorldMap = WorldMap

local ADDON = "Blizzard_WorldMap"

---The world map, once its addon has loaded, or nil. Probe: it's loaded at login on Mainline, but
---it's a load-on-demand Blizzard addon, so don't count on it.
---@return table?
function WorldMap.Get()
    return ns.AddOns.IsLoaded(ADDON) and WorldMapFrame or nil
end

local waiting = {} -- fn -> the function waiting on the addon for it

---Calls `fn(map)` now if the world map has loaded, or else once it does. Waiting with the same
---`fn` again doesn't call it twice; `WorldMap.Cancel(fn)` stops the wait, for a module turned off
---before the map loaded.
---@param fn fun(map: table)
function WorldMap.WhenLoaded(fn)
    local map = WorldMap.Get()
    if map then
        fn(map)
        return
    end
    waiting[fn] = waiting[fn] or function()
        waiting[fn] = nil
        if WorldMapFrame then
            fn(WorldMapFrame)
        end
    end
    ns.AddOns.WhenLoaded(ADDON, waiting[fn])
end

---Stops waiting to call `fn` when the world map loads.
---@param fn function
function WorldMap.Cancel(fn)
    if waiting[fn] then
        ns.AddOns.Cancel(ADDON, waiting[fn])
        waiting[fn] = nil
    end
end


---A data provider for a map to draw our own things on: what the map calls as it changes maps,
---zooms or resizes. `handlers` may have RemoveAllData, RefreshAllData, OnCanvasScaleChanged,
---OnCanvasSizeChanged and OnGlobalAlphaChanged, each called with the provider. Add it with
---`map:AddDataProvider`. Only call this once the map has loaded, since the mixin comes with it.
---@param handlers table<string, fun(provider: table)>
---@return table provider
function WorldMap.NewProvider(handlers)
    local provider = CreateFromMixins(MapCanvasDataProviderMixin)
    for name, fn in pairs(handlers) do
        provider[name] = fn
    end
    return provider
end

---An OnUpdate script that calls `fn(frame)` at most every `interval` seconds, for a frame on the
---map (a child of it stops updating while the map is closed). Look at the map a few times a
---second instead of every frame.
---@param interval number seconds
---@param fn fun(frame: table)
---@return fun(frame: table, delta: number)
function WorldMap.Throttled(interval, fn)
    local elapsed = 0
    return function(frame, delta)
        elapsed = elapsed + delta
        if elapsed >= interval then
            elapsed = 0
            fn(frame)
        end
    end
end

---Whether a map (`C_Map.GetMapInfo` of it) is a continent or the world map, as against a zone.
---@param info table?
---@param cosmic? boolean count the cosmic map (Azeroth and beyond) too
---@return boolean
function WorldMap.IsContinent(info, cosmic)
    local types = Enum and Enum.UIMapType
    if not (info and types) then
        return false
    end
    local kind = info.mapType
    return kind == types.Continent or kind == types.World or (cosmic and kind == types.Cosmic) or false
end

-- Directions ----------------------------------------------------------------------------------

---How far and which way one spot on a map is from another, for an arrow. Spots are 0 to 1 across
---and down the map, as C_Map gives them, and `width` and `height` are the map's size in yards
---(C_Map.GetMapWorldSize). The angle is counter-clockwise from north in radians, 0 to 2 pi, like
---GetPlayerFacing, so an arrow pointing ahead turns by `angle - facing`.
---@param width number yards
---@param height number yards
---@param fromX number
---@param fromY number
---@param toX number
---@param toY number
---@return number yards
---@return number angle
function WorldMap.Toward(width, height, fromX, fromY, toX, toY)
    local east = (toX - fromX) * width
    local south = (toY - fromY) * height
    return sqrt(east * east + south * south), atan2(-east, -south) % (2 * pi)
end

-- Sides -----------------------------------------------------------------------------------------
-- Map data marks what belongs to a faction with "A" (Alliance) or "H" (Horde).

local SIDES = { Alliance = "A", Horde = "H" }
local SIDE_NAMES = { A = FACTION_ALLIANCE, H = FACTION_HORDE }

---The player's side, "A" or "H", or nil when the game doesn't say.
---@return string?
function WorldMap.PlayerSide()
    return SIDES[UnitFactionGroup("player") or ""]
end

---A side's faction name in the player's language ("Horde"), or nil for any other letter.
---@param side string
---@return string?
function WorldMap.SideName(side)
    return SIDE_NAMES[side]
end

-- Blizzard's panels ---------------------------------------------------------------------------

local coords -- false once looked for and not there

---Blizzard's coordinates panel: the map's overlay frame with a CursorCoords row and a
---PlayerCoords row, or nil before the map loads or on a client without it. It has no name, so
---it's found by its parts.
---@return table?
function WorldMap.CoordsPanel()
    if coords == nil then
        local map = WorldMap.Get()
        if not map then
            return nil
        end
        coords = false
        for _, frame in ipairs(map.overlayFrames or {}) do
            if frame.CursorCoords and frame.PlayerCoords then
                coords = frame
                break
            end
        end
    end
    return coords or nil
end
