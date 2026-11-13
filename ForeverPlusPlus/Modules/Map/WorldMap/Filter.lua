-- World Map in the world map's filter menu (the funnel at its top right): a Forever++ title and a
-- few quick checkboxes after Blizzard's own, the icons players turn on and off as they look at the
-- map. Each is the same switch as its option in Settings: Dungeons, Raids, Flight Masters, and Boats
-- and Zeppelins (one checkbox for both) while Points of Interest is on, and the Unexplored Areas and
-- Zone Info parts. Sizes, continent maps, and the rest stay in Settings, to keep the menu short.
local _, ns = ...

local ipairs = ipairs

local L = ns.L

local module = ns.modules.WorldMap

-- Points of Interest's kinds the menu offers, by their option keys: a list of keys is one checkbox
-- for all of them, on while any is.
local KINDS = {
    { name = L.POI_DUNGEONS, keys = { "dungeons" } },
    { name = L.POI_RAIDS, keys = { "raids" } },
    { name = L.POI_FLIGHT, keys = { "flightMasters" } },
    { name = L.WORLDMAP_FILTER_TRAVEL, keys = { "ships", "zeppelins" } },
}

-- The parts the menu turns on and off, by their checkbox keys.
local PARTS = {
    { name = L.UNEXPLORED_TITLE, key = "unexploredAreas" },
    { name = L.ZONEINFO_TITLE, key = "zoneInfo" },
}

local function anyOn(keys)
    for _, key in ipairs(keys) do
        if module.db[key] then
            return true
        end
    end
    return false
end

-- Through Core, as the Modules page sets options, so parts turn on and off and Settings follows.
local function setAll(keys, on)
    for _, key in ipairs(keys) do
        ns.SetOption(module.name, key, on)
    end
end

local function addEntries(root)
    if ns.PartOn(module, "pointsOfInterest") then
        for _, kind in ipairs(KINDS) do
            root:CreateCheckbox(kind.name, function()
                return anyOn(kind.keys)
            end, function()
                setAll(kind.keys, not anyOn(kind.keys))
            end)
        end
    end
    for _, part in ipairs(PARTS) do
        root:CreateCheckbox(part.name, function()
            return ns.PartOn(module, part.key)
        end, function()
            ns.SetOption(module.name, part.key, not ns.PartOn(module, part.key))
        end)
    end
end

-- First under the Forever++ title (Lib/WorldMap's AddFilter), while World Map is on.
ns.WorldMap.AddFilter(1, function()
    return module.enabled and true or false
end, addEntries)
