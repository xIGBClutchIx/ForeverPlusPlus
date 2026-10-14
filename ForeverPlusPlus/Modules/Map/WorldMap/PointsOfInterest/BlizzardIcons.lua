-- Points of Interest's handling of Blizzard's own icons on the world map.
local _, ns = ...

local pairs, type = pairs, type

local internal = ns.modules.WorldMap.internal.pointsOfInterest
local module = internal.module
local KINDS, shows, zoneName = internal.KINDS, internal.shows, internal.zoneName
local placedByUs, isContinent = internal.placedByUs, internal.isContinent

-- Blizzard's own icons ------------------------------------------------------------------------
-- Blizzard marks the capitals on continent maps, and may mark dungeon entrances anywhere, with
-- pins of its own. Wherever ours show for the same place, theirs are hidden so there's one icon,
-- not two (Undercity's, and the Ruins of Lordaeron's beside it). Capital Cities set to Off hides
-- Blizzard's too, like Leatrix Maps' Hide Town and City Icons, but told apart by the name
-- instead of the icon's place in its texture.

local cityNames

local function isCity(name)
    if not cityNames then
        cityNames = {}
        for cityMap in pairs(internal.cities) do
            local cityName = zoneName(cityMap)
            if cityName ~= "" then
                cityNames[cityName] = true
                cityNames[(cityName:gsub(" City$", ""))] = true -- "Stormwind City" as "Stormwind"
            end
        end
    end
    return cityNames[name] == true or cityNames[(name:gsub("^[Tt]he ", ""))] == true
end

-- Whether ours replace Blizzard's pin with this name on the map now: a city's (ours, or none at
-- all), or a dungeon's or raid's, where its kind shows. Ours show on zone maps whenever their
-- checkbox is on, and on continents with On Continent Maps.
local function hidesBlizzard(mapID, name)
    if not module.enabled then
        return false
    end
    local db, world = module.db, isContinent(mapID)
    if isCity(name) then
        return db.capitals == "off" or (db.capitals == "ours" and (not world or db.capitalsWorld))
    end
    local ours, instance = placedByUs(name)
    if not instance then
        return false
    end
    local kindInfo = KINDS[instance[5] and "raid" or "dungeon"]
    if ours then
        return shows(kindInfo, world) and true or false
    end
    -- One we don't place: gameEntrances draws it on zone maps, and on a continent the game's icon
    -- is the only one.
    return not world and shows(kindInfo) and true or false
end

-- After the world map acquires a pin of its own. The pin is hidden, not faded, so its tooltip
-- goes too; the map shows it again when it reuses the pin.
local BLIZZARD_TEMPLATES = { AreaPOIPinTemplate = true, DungeonEntrancePinTemplate = true }

function internal.onAcquire(map, template, poiInfo)
    if not BLIZZARD_TEMPLATES[template] or type(poiInfo) ~= "table" or type(poiInfo.name) ~= "string"
        or not hidesBlizzard(map:GetMapID(), poiInfo.name) then
        return
    end
    for pin in map:EnumeratePinsByTemplate(template) do
        if pin.poiInfo == poiInfo or pin.dungeonEntranceInfo == poiInfo or pin.name == poiInfo.name then
            pin:Hide()
        end
    end
end
