-- MapPins: the size, opacity, and continent options every module with map icons shares. The rest
-- of the file is frames.
local T = ...
local ns, eq, same = T.ns, T.eq, T.same
local L = ns.L

T.load("Lib/MapPins", ns)
local MapPins = ns.MapPins

same(MapPins.SizeOption("mapSize", "World Map"), {
    key = "mapSize", name = L.MAPPINS_SIZE, description = L.MAPPINS_SIZE_DESC, section = "World Map",
    min = 50, max = 200, step = 10, format = "%d%%",
}, "mappins: the size slider")
same(MapPins.OpacityOption("mapAlpha", "World Map"), {
    key = "mapAlpha", name = L.MAPPINS_OPACITY, description = L.MAPPINS_OPACITY_DESC, section = "World Map",
    min = 10, max = 100, step = 5, format = "%d%%",
}, "mappins: the opacity slider")
same(MapPins.ContinentOption("mapContinents"), {
    key = "mapContinents", name = L.MAPPINS_CONTINENTS, description = L.MAPPINS_CONTINENTS_DESC,
}, "mappins: the continent checkbox, with no section")

local size = MapPins.SizeOption("size", "Pins", { requires = "pins", added = "1.7.0", description = "Pins." })
eq(size.requires, "pins", "mappins: extra fields are added")
eq(size.added, "1.7.0", "mappins: every one of them")
eq(size.description, "Pins.", "mappins: extra replaces the description")
eq(size.name, L.MAPPINS_SIZE, "mappins: and leaves the name it didn't give")
eq(size.max, 200, "mappins: and the range")
eq(MapPins.OpacityOption("alpha", nil, { name = "Solid" }).name, "Solid", "mappins: extra replaces the name")
eq(MapPins.ContinentOption("worldMap", "Pins", { requires = "pins" }).requires, "pins",
    "mappins: the checkbox takes extra too")
eq(MapPins.SizeOption("a").name ~= nil and MapPins.SizeOption("a") ~= MapPins.SizeOption("a"), true,
    "mappins: each call builds its own table")
