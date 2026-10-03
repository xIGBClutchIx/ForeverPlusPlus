-- The dungeons and raids, for the modules that place or list them: each is { instance ID (the game
-- names it in the player's language), English name for when it can't, lowest level, highest
-- level, true for a raid }, by a short key.
local _, ns = ...

local pairs, type, tostring = pairs, type, tostring
local GetRealZoneText, format = GetRealZoneText, string.format

local L = ns.L

local Instances = {
    aq20 = { 509, "Ruins of Ahn'Qiraj", 60, 60, true },
    aq40 = { 531, "Temple of Ahn'Qiraj", 60, 60, true },
    blackfathom = { 48, "Blackfathom Deeps", 24, 32 },
    brd = { 230, "Blackrock Depths", 52, 60 },
    brs = { 229, "Blackrock Spire", 55, 60 },
    bwl = { 469, "Blackwing Lair", 60, 60, true },
    deadmines = { 36, "The Deadmines", 17, 26 },
    diremaul = { 429, "Dire Maul", 56, 60 },
    gnomeregan = { 90, "Gnomeregan", 29, 38 },
    -- Forever's. The instance IDs are the client's Map table (build 70009); the lowest levels are
    -- its dungeon finder's, the highest are guides'. The other five Forever dungeons aren't in
    -- the client yet.
    hallOfThanes = { 3065, "The Hall of Thanes", 13, 18 },
    ruinsOfLordaeron = { 2999, "Ruins of Lordaeron", 15, 20 },
    excavationSite = { 2998, "Excavation Site: Wetlands", 26, 31 },
    dalaran = { 2959, "City of Dalaran", 28, 33 },
    maraudon = { 349, "Maraudon", 46, 55 },
    mc = { 409, "Molten Core", 60, 60, true },
    naxxramas = { 533, "Naxxramas", 60, 60, true },
    onyxia = { 249, "Onyxia's Lair", 60, 60, true },
    ragefire = { 389, "Ragefire Chasm", 13, 18 },
    razorfenDowns = { 129, "Razorfen Downs", 37, 46 },
    razorfenKraul = { 47, "Razorfen Kraul", 29, 38 },
    scarlet = { 189, "Scarlet Monastery", 34, 45 },
    scholomance = { 289, "Scholomance", 58, 60 },
    shadowfang = { 33, "Shadowfang Keep", 22, 30 },
    stockade = { 34, "The Stockade", 22, 30 },
    stratholme = { 329, "Stratholme", 58, 60 },
    sunkenTemple = { 109, "The Temple of Atal'Hakkar", 50, 60 },
    uldaman = { 70, "Uldaman", 41, 51 },
    wailing = { 43, "Wailing Caverns", 17, 24 },
    zulfarrak = { 209, "Zul'Farrak", 44, 54 },
    zulgurub = { 309, "Zul'Gurub", 60, 60, true },
}

ns.Instances = {
    byKey = Instances,
}

---Blizzard's dungeon or raid entrance icon for an instance, as text to put before its name.
---@param instance table an entry of `byKey`, or one shaped like it
---@param size number pixels
---@return string
function ns.Instances.Icon(instance, size)
    return format("|A:%s:%d:%d|a", instance[5] and "Raid" or "Dungeon", size, size)
end

---An instance's name in the player's language from the game, or the English one.
---@param instance table an entry of `byKey`, or one shaped like it
---@return string
function ns.Instances.Name(instance)
    local name = instance[1] and GetRealZoneText and GetRealZoneText(instance[1])
    if not name or name == "" then
        name = instance[2]
    end
    return name
end

---An instance's level range as text, colored against the player's level like a quest's.
---@param instance table an entry of `byKey`, or one shaped like it
---@param compact boolean? "52-60" instead of "Level 52-60"
---@return string
function ns.Instances.Levels(instance, compact)
    local low, high = instance[3], instance[4]
    local text
    if compact then
        text = low == high and tostring(low) or format(L.INSTANCES_RANGE, low, high)
    else
        text = low == high and format(L.INSTANCES_LEVEL, low) or format(L.INSTANCES_LEVELS, low, high)
    end
    local color = ns.Colors.LevelRange(low, high)
    if not color then
        return text
    end
    return ns.Colors.Text(color, text)
end

ns.Instances.ICON_SIZE = 14 -- pixels, the icon before an instance in a tooltip or panel

---One instance as a row: its icon, its name, and its level range, the same in every tooltip and
---panel that lists instances. The parts are held together with no-break spaces so a row that
---wraps never splits the name or the levels.
---@param instance table an entry of `byKey`, or one shaped like it
---@param name string? shown instead of the instance's own name (for one of its entrances)
---@return string
function ns.Instances.Line(instance, name)
    return format("%s %s  %s", ns.Instances.Icon(instance, ns.Instances.ICON_SIZE),
        ns.MapTooltip.NoBreak(name or ns.Instances.Name(instance)), ns.Instances.Levels(instance, true))
end

local byName -- instances by lower-case name, once asked

---The instance a name belongs to (in the player's language or English), for telling Blizzard's
---own icon for it from ours.
---@param name string?
---@return table? instance an entry of `byKey`
function ns.Instances.ByName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if not byName then
        byName = {}
        for _, instance in pairs(Instances) do
            byName[ns.Instances.Name(instance):lower()] = instance
            byName[instance[2]:lower()] = instance
        end
    end
    return byName[name:lower()]
end
