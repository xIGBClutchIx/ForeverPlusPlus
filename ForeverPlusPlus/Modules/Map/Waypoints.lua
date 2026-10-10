-- Waypoints: /way puts Blizzard's own map pin (the user waypoint) on a spot and tracks it, so the
-- game draws its pin and its marker in the world; a command another addon already has (TomTom's
-- /way) is left to that addon (Lib/Slash). The Arrow option adds a small arrow on screen that
-- turns toward the waypoint as you turn, with the distance under it, for the pin set by /way or
-- by clicking the map. It reads only the player's own position and facing, never another unit's.
local _, ns = ...

local ipairs, tonumber, format, floor = ipairs, tonumber, string.format, math.floor
local tconcat = table.concat
local CreateFrame, UIParent, C_Map, C_Texture = CreateFrame, UIParent, C_Map, C_Texture
local GetPlayerFacing = GetPlayerFacing

local L = ns.L
local WorldMap = ns.WorldMap

local module = ns.NewModule("Waypoints", L.WAYPOINTS_DESC, {
    enabled = true,
    way = true,
    arrow = false,
    scale = 100, -- percent
    x = 0, -- the arrow's offset from the center of the screen
    y = 180,
})
module.title = L.WAYPOINTS_TITLE
module.category = "map"
module.added = "0.8.0"

module.options = {
    { key = "way", name = L.WAYPOINTS_WAY, description = L.WAYPOINTS_WAY_DESC },
    { key = "arrow", name = L.WAYPOINTS_ARROW, description = L.WAYPOINTS_ARROW_DESC },
}

-- /way ----------------------------------------------------------------------------------------

-- Forever's Azeroth map (Classic map IDs: Kalimdor 1414, Eastern Kingdoms 1415), for finding a
-- zone by name where the player has no map, like in a dungeon.
local AZEROTH = 947

local function canWaypoint()
    return C_Map and C_Map.SetUserWaypoint and C_Map.CanSetUserWaypointOnMap and true or false
end

-- A name made easy to compare: lowercase letters and digits only.
local function plain(text)
    return (text:lower():gsub("[^%w]", ""))
end

-- The top map above the player's (the world or Azeroth), under which every zone is.
local function rootMap()
    local mapID = C_Map.GetBestMapForUnit("player")
    local info = mapID and C_Map.GetMapInfo(mapID)
    while info and info.parentMapID and info.parentMapID ~= 0 do
        local parent = C_Map.GetMapInfo(info.parentMapID)
        if not parent then
            break
        end
        info = parent
    end
    return info and info.mapID or AZEROTH
end

-- The map called `name`: a zone before any other kind of map with that name, then the first
-- zone whose name starts with it. "#1429" is a map ID, as TomTom takes it.
local function findMap(name)
    local id = tonumber(name:match("^#(%d+)$"))
    if id then
        return C_Map.GetMapInfo(id) and id
    end
    local wanted = plain(name)
    if wanted == "" or not C_Map.GetMapChildrenInfo then
        return nil
    end
    local zone = Enum and Enum.UIMapType and Enum.UIMapType.Zone
    local exact, other, partial
    for _, info in ipairs(C_Map.GetMapChildrenInfo(rootMap(), nil, true) or {}) do
        local have = plain(info.name or "")
        if have == wanted then
            if info.mapType == zone then
                exact = exact or info.mapID
            else
                other = other or info.mapID
            end
        elseif not partial and info.mapType == zone and have:sub(1, #wanted) == wanted then
            partial = info.mapID
        end
    end
    return exact or other or partial
end

local function mapName(mapID)
    local info = C_Map.GetMapInfo(mapID)
    return info and info.name or ("#" .. mapID)
end

-- The words typed, with commas as spaces so "45.2, 67.8" reads like "45.2 67.8".
local function words(text)
    local list = {}
    for word in text:gsub(",", " "):gmatch("%S+") do
        list[#list + 1] = word
    end
    return list
end

local CLEAR = { clear = true, reset = true, off = true, remove = true }

local function way(message)
    if not (module.enabled and module.db.way) then
        return -- chat cached the command before it was turned off, on a client we couldn't clear
    end
    if not canWaypoint() then
        ns.Print(L.WAYPOINTS_UNAVAILABLE)
        return
    end
    local list = words(message or "")
    if #list == 1 and CLEAR[list[1]:lower()] then
        C_Map.ClearUserWaypoint()
        ns.Print(L.WAYPOINTS_CLEARED)
        return
    end
    -- [zone] x y [anything else, ignored: Blizzard's pin has no label]
    local at
    for i = 1, #list - 1 do
        if tonumber(list[i]) and tonumber(list[i + 1]) then
            at = i
            break
        end
    end
    if not at then
        ns.Print(L.WAYPOINTS_USAGE)
        return
    end
    local x, y = tonumber(list[at]), tonumber(list[at + 1])
    if x < 0 or x > 100 or y < 0 or y > 100 then
        ns.Print(L.WAYPOINTS_RANGE)
        return
    end
    local mapID
    if at > 1 then
        local name = tconcat(list, " ", 1, at - 1)
        mapID = findMap(name)
        if not mapID then
            ns.Print(format(L.WAYPOINTS_NO_ZONE, name))
            return
        end
    else
        mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then
            ns.Print(L.WAYPOINTS_NO_MAP)
            return
        end
    end
    if not C_Map.CanSetUserWaypointOnMap(mapID) then
        ns.Print(format(L.WAYPOINTS_NOT_HERE, mapName(mapID)))
        return
    end
    local point
    if UiMapPoint and UiMapPoint.CreateFromCoordinates then
        point = UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100)
    else
        point = { uiMapID = mapID, position = CreateVector2D(x / 100, y / 100) }
    end
    C_Map.SetUserWaypoint(point)
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    ns.Print(format(L.WAYPOINTS_SET, mapName(mapID), x, y))
end

local WAY_KEY, WAY_SLASH = "FOREVERPLUSPLUS_WAY", "/way"

local function syncWay()
    if module.enabled and module.db.way then
        ns.Slash.Add(WAY_KEY, WAY_SLASH, way)
    else
        ns.Slash.Remove(WAY_KEY, WAY_SLASH)
    end
end

-- Where the waypoint is ----------------------------------------------------------------------

local ARRIVED = 5 -- yards; closer than this the arrow goes away

-- How far the waypoint is from the player in yards, and its direction counter-clockwise from
-- north, or nil when the game can't say (no waypoint, in an instance, another continent).
-- Works on the waypoint's own map, or the first map above it the player is also on, so a pin in
-- the next zone still points the right way.
local function locate()
    local point = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
    if not (point and point.uiMapID and point.position) then
        return nil
    end
    local pinMap = point.uiMapID
    local continent, world
    if C_Map.GetWorldPosFromMapPos then
        continent, world = C_Map.GetWorldPosFromMapPos(pinMap, point.position)
    end
    local continentType = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
    local mapID = pinMap
    while mapID and mapID ~= 0 do
        local info = C_Map.GetMapInfo(mapID)
        if not info or (info.mapType and info.mapType < continentType) then
            return nil -- past the continent: another continent's pin has no direction from here
        end
        local here = C_Map.GetPlayerMapPosition(mapID, "player")
        if here then
            local target = point.position
            if mapID ~= pinMap then
                target = nil
                if world and C_Map.GetMapPosFromWorldPos then
                    local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, mapID)
                    target = pos
                end
            end
            local width, height = C_Map.GetMapWorldSize(mapID)
            local px, py = here:GetXY()
            if target and ns.IsReadable(px) and ns.IsReadable(width) and width > 0 and height > 0
                and not (px == 0 and py == 0) then
                local tx, ty = target:GetXY()
                return WorldMap.Toward(width, height, px, py, tx, ty)
            end
        end
        mapID = info.parentMapID
    end
    return nil
end

-- The arrow -----------------------------------------------------------------------------------

local ARROW_ATLAS = "Navigation-Tracked-Arrow" -- the arrow of Blizzard's own waypoint marker
local ARROW_TEXTURE = "Interface\\Minimap\\MiniMap-QuestArrow" -- older art, if the atlas is gone
local SIZE = 48
local INTERVAL = 0.03 -- seconds between turns, smooth enough to follow the camera

local frame, watcher

local function hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

-- "120 yds", like Blizzard's own marker (IN_GAME_NAVIGATION_RANGE), with big numbers shortened.
local function distanceText(yards)
    yards = floor(yards + 0.5)
    local text = yards < 1000 and tostring(yards) or (AbbreviateNumbers and AbbreviateNumbers(yards))
        or tostring(yards)
    return format(IN_GAME_NAVIGATION_RANGE or L.WAYPOINTS_YARDS, text)
end

local function newFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(SIZE, SIZE)
    f.arrow = f:CreateTexture(nil, "ARTWORK")
    f.arrow:SetPoint("CENTER")
    if hasAtlas(ARROW_ATLAS) then
        f.arrow:SetAtlas(ARROW_ATLAS)
        f.arrow:SetSize(SIZE * 0.6, SIZE * 0.6)
    else
        f.arrow:SetTexture(ARROW_TEXTURE)
        f.arrow:SetSize(SIZE * 0.6, SIZE * 0.6)
    end
    f.distance = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.distance:SetPoint("TOP", f, "BOTTOM", 0, 4)
    f:Hide()
    return f
end

local function place()
    frame:SetScale(module.db.scale / 100)
    ns.EditMode.Place(frame, module.db.x, module.db.y)
end

-- Turns the arrow toward the waypoint, or takes it down when there's no direction to give.
local function update()
    if ns.EditMode.IsActive() then
        return -- the sample stays put while it's being placed
    end
    local yards, angle = locate()
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not yards or yards < ARRIVED or not (facing and ns.IsReadable(facing)) then
        frame:Hide()
        return
    end
    frame.arrow:SetRotation(angle - facing)
    frame.distance:SetText(distanceText(yards))
    frame:Show()
end

local function arrowWanted()
    return module.enabled and module.db.arrow and C_Map.HasUserWaypoint
        and C_Map.HasUserWaypoint() or false
end

-- Runs the watcher only while there is a waypoint to point at.
local function refresh()
    if not frame then
        return
    end
    if arrowWanted() then
        watcher:Show()
        update()
    else
        watcher:Hide()
        if not ns.EditMode.IsActive() then
            frame:Hide()
        end
    end
end

-- Edit Mode -----------------------------------------------------------------------------------

-- In Edit Mode the arrow shows pointing ahead, so it can be placed.
local function sample(active)
    if active then
        frame.arrow:SetRotation(0)
        frame.distance:SetText(distanceText(120))
        frame:Show()
    else
        frame:Hide()
        refresh()
    end
end

local function moved(x, y)
    module.db.x, module.db.y = x, y
end

local editModeOptions = {
    onChange = sample,
    reset = function()
        module.db.x, module.db.y = module.defaults.x, module.defaults.y
        if frame then
            place()
        end
    end,
    scale = {
        min = 50, max = 200, step = 10, format = "%d%%",
        get = function() return module.db.scale end,
        set = function(value)
            module.db.scale = value
            place()
        end,
    },
}

local function syncArrow()
    if module.enabled and module.db.arrow then
        if not frame then
            frame = newFrame()
            watcher = CreateFrame("Frame", nil, UIParent)
            watcher:Hide()
            watcher:SetScript("OnUpdate", WorldMap.Throttled(INTERVAL, update))
        end
        place()
        module:On("USER_WAYPOINT_UPDATED", refresh)
        module:On("PLAYER_ENTERING_WORLD", refresh)
        ns.EditMode.Register(frame, L.WAYPOINTS_ARROW, moved, editModeOptions)
    elseif frame then
        module:Off("USER_WAYPOINT_UPDATED", refresh)
        module:Off("PLAYER_ENTERING_WORLD", refresh)
        ns.EditMode.Unregister(frame)
    end
    refresh()
end

function module:OnEnable()
    syncWay()
    syncArrow()
end

function module:OnDisable()
    syncWay()
    syncArrow()
end

function module:OnOptionChanged(option)
    if option == "way" then
        syncWay()
    elseif option == "arrow" then
        syncArrow()
    elseif option == "scale" and frame then
        place()
    end
end
