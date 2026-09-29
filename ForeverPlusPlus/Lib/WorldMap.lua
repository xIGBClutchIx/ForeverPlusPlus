-- The world map, which comes with a load-on-demand Blizzard addon: whether it has loaded, code to
-- run once it has, and the parts of it more than one module finds. Nothing is listened to until a
-- module waits for it.
local _, ns = ...

local ipairs, pairs = ipairs, pairs
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
