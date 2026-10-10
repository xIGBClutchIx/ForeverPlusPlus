-- World Map: what Forever++ adds to the world map, in one module with a part for each: Points of
-- Interest, Zone Info, Unexplored Areas, and Coordinates. Each part is in its own file and has its
-- own checkbox heading its section in Settings; they share nothing but this module.
local _, ns = ...

local L = ns.L

local module = ns.NewModule("WorldMap", L.WORLDMAP_DESC, {
    enabled = true,
})
module.title = L.WORLDMAP_TITLE
module.category = "map"
module.added = "0.8.0"
module.options = {}

-- Each part's own shared table, by its checkbox's key, for its Data.lua.
module.internal = {}
