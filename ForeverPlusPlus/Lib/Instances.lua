-- The dungeons and raids, for the modules that place or list them: each is { instance ID (the game
-- names it in the player's language), English name for when it can't, lowest level, highest
-- level, true for a raid }, by a short key.
local _, ns = ...

local GetRealZoneText, format = GetRealZoneText, string.format

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
    -- Forever's. Their instance IDs aren't known yet, so the names are the English ones.
    hallOfThanes = { nil, "The Hall of Thanes", 13, 18 },
    ruinsOfLordaeron = { nil, "Ruins of Lordaeron", 15, 20 },
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
