-- Commands: short slash commands players expect from other games' addons, each its own checkbox.
-- /way puts Blizzard's own map pin (the user waypoint) on a spot and tracks it, so the arrow and
-- distance come from the game; /rl reloads the UI. A command another addon already has (TomTom's
-- /way) is left to that addon. /fpp is Core's and is always there, whatever this module does.
local _, ns = ...

local pairs, ipairs, type, tonumber, format = pairs, ipairs, type, tonumber, string.format
local tconcat, _G = table.concat, _G

local L = ns.L

local module = ns.NewModule("Commands", L.COMMANDS_DESC, {
    enabled = true,
    way = true,
    reload = true,
})
module.title = L.COMMANDS_TITLE
module.category = "interface"

module.options = {
    { key = "way", name = L.COMMANDS_WAY, description = L.COMMANDS_WAY_DESC },
    { key = "reload", name = L.COMMANDS_RELOAD, description = L.COMMANDS_RELOAD_DESC },
}

-- Slash commands ------------------------------------------------------------------------------
-- A command is the SLASH_<key>1 global and SlashCmdList[key]. Chat caches a command's function
-- the first time it's typed (hash_SlashCmdList), so taking one away clears that too, like
-- AceConsole does.

-- Whether a command other than `key` already answers to `slash`.
local function taken(slash, key)
    slash = slash:upper()
    for name in pairs(SlashCmdList) do
        if name ~= key then
            local i = 1
            local text = _G["SLASH_" .. name .. i]
            while text do
                if type(text) == "string" and text:upper() == slash then
                    return true
                end
                i = i + 1
                text = _G["SLASH_" .. name .. i]
            end
        end
    end
    return false
end

local added = {} -- key -> true while our command is registered

local function add(key, slash, fn)
    if added[key] or taken(slash, key) then
        return
    end
    _G["SLASH_" .. key .. "1"] = slash
    SlashCmdList[key] = fn
    added[key] = true
end

local function remove(key, slash)
    if not added[key] then
        return
    end
    SlashCmdList[key] = nil
    _G["SLASH_" .. key .. "1"] = nil
    -- Probe: Mainline keeps the cache in this global; without it there's nothing cached to clear.
    local hash = _G.hash_SlashCmdList
    if type(hash) == "table" then
        hash[slash:upper()] = nil
    end
    added[key] = nil
end

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
        ns.Print(L.COMMANDS_WAY_UNAVAILABLE)
        return
    end
    local list = words(message or "")
    if #list == 1 and CLEAR[list[1]:lower()] then
        C_Map.ClearUserWaypoint()
        ns.Print(L.COMMANDS_WAY_CLEARED)
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
        ns.Print(L.COMMANDS_WAY_USAGE)
        return
    end
    local x, y = tonumber(list[at]), tonumber(list[at + 1])
    if x < 0 or x > 100 or y < 0 or y > 100 then
        ns.Print(L.COMMANDS_WAY_RANGE)
        return
    end
    local mapID
    if at > 1 then
        local name = tconcat(list, " ", 1, at - 1)
        mapID = findMap(name)
        if not mapID then
            ns.Print(format(L.COMMANDS_WAY_NO_ZONE, name))
            return
        end
    else
        mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then
            ns.Print(L.COMMANDS_WAY_NO_MAP)
            return
        end
    end
    if not C_Map.CanSetUserWaypointOnMap(mapID) then
        ns.Print(format(L.COMMANDS_WAY_NOT_HERE, mapName(mapID)))
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
    ns.Print(format(L.COMMANDS_WAY_SET, mapName(mapID), x, y))
end

-- /rl -----------------------------------------------------------------------------------------

local function reload()
    if module.enabled and module.db.reload then
        ReloadUI()
    end
end

-- The commands, each behind the option with its key.
local COMMANDS = {
    { option = "way", key = "FOREVERPLUSPLUS_WAY", slash = "/way", fn = way },
    { option = "reload", key = "FOREVERPLUSPLUS_RELOAD", slash = "/rl", fn = reload },
}

local function sync()
    for _, command in ipairs(COMMANDS) do
        if module.enabled and module.db[command.option] then
            add(command.key, command.slash, command.fn)
        else
            remove(command.key, command.slash)
        end
    end
end

function module:OnEnable()
    sync()
end

function module:OnDisable()
    sync()
end

function module:OnOptionChanged()
    sync()
end
