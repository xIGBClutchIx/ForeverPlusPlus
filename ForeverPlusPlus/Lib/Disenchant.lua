-- What disenchanting an item gives: which items can be disenchanted, the materials it gives with
-- each one's chance and amount, and what that's worth on average at given prices. Pure rules, no
-- frames, so tests/run.lua checks them.
--
-- The rules are Classic Era 1.x's, by quality, item level, and weapon or armor, written from
-- general game knowledge. UNVERIFIED on Forever: its outcomes may differ, and a few items the
-- game flags as not disenchantable can't be told apart here (the flag isn't in item info).
local _, ns = ...

local ipairs, type = ipairs, type

local GameData = ns.GameData

local Disenchant = {}
ns.Disenchant = Disenchant

-- Materials. Classic Era 1.x item IDs, written from general game knowledge, UNVERIFIED on
-- Forever; Self Test lists any the client doesn't have.
local function item(id, label)
    return GameData.Item(id, label)
end

local STRANGE_DUST = item(10940, "Strange Dust")
local SOUL_DUST = item(11083, "Soul Dust")
local VISION_DUST = item(11137, "Vision Dust")
local DREAM_DUST = item(11176, "Dream Dust")
local ILLUSION_DUST = item(16204, "Illusion Dust")
local LESSER_MAGIC = item(10938, "Lesser Magic Essence")
local GREATER_MAGIC = item(10939, "Greater Magic Essence")
local LESSER_ASTRAL = item(10998, "Lesser Astral Essence")
local GREATER_ASTRAL = item(11082, "Greater Astral Essence")
local LESSER_MYSTIC = item(11134, "Lesser Mystic Essence")
local GREATER_MYSTIC = item(11135, "Greater Mystic Essence")
local LESSER_NETHER = item(11174, "Lesser Nether Essence")
local GREATER_NETHER = item(11175, "Greater Nether Essence")
local LESSER_ETERNAL = item(16202, "Lesser Eternal Essence")
local GREATER_ETERNAL = item(16203, "Greater Eternal Essence")
local SMALL_GLIMMERING = item(10978, "Small Glimmering Shard")
local LARGE_GLIMMERING = item(11084, "Large Glimmering Shard")
local SMALL_GLOWING = item(11138, "Small Glowing Shard")
local LARGE_GLOWING = item(11139, "Large Glowing Shard")
local SMALL_RADIANT = item(11177, "Small Radiant Shard")
local LARGE_RADIANT = item(11178, "Large Radiant Shard")
local SMALL_BRILLIANT = item(14343, "Small Brilliant Shard")
local LARGE_BRILLIANT = item(14344, "Large Brilliant Shard")
local NEXUS_CRYSTAL = item(20725, "Nexus Crystal")

-- Enum.ItemQuality and Enum.ItemClass values, as numbers so the rules need no client.
local UNCOMMON, RARE, EPIC = 2, 3, 4
local WEAPON, ARMOR = 2, 4

-- Uncommon: { low, high, dust, essence, shard }, each { item, min, max }. Armor gives mostly dust,
-- weapons mostly essence; `chances` is { major, minor, shard } for the bracket.
local CHANCES = { 0.75, 0.20, 0.05 }
local UNCOMMON_ROWS = {
    { 5, 15, { STRANGE_DUST, 1, 2 }, { LESSER_MAGIC, 1, 2 }, nil, { 0.80, 0.20, 0 } },
    { 16, 20, { STRANGE_DUST, 2, 3 }, { GREATER_MAGIC, 1, 2 }, { SMALL_GLIMMERING, 1, 1 } },
    { 21, 25, { STRANGE_DUST, 4, 6 }, { LESSER_ASTRAL, 1, 2 }, { SMALL_GLIMMERING, 1, 1 },
        { 0.75, 0.15, 0.10 } },
    { 26, 30, { SOUL_DUST, 1, 2 }, { GREATER_ASTRAL, 1, 2 }, { LARGE_GLIMMERING, 1, 1 } },
    { 31, 35, { SOUL_DUST, 2, 5 }, { LESSER_MYSTIC, 1, 2 }, { SMALL_GLOWING, 1, 1 } },
    { 36, 40, { VISION_DUST, 1, 2 }, { GREATER_MYSTIC, 1, 2 }, { LARGE_GLOWING, 1, 1 } },
    { 41, 45, { VISION_DUST, 2, 5 }, { LESSER_NETHER, 1, 2 }, { SMALL_RADIANT, 1, 1 } },
    { 46, 50, { DREAM_DUST, 1, 2 }, { GREATER_NETHER, 1, 2 }, { LARGE_RADIANT, 1, 1 } },
    { 51, 55, { DREAM_DUST, 2, 5 }, { LESSER_ETERNAL, 1, 2 }, { SMALL_BRILLIANT, 1, 1 } },
    { 56, 60, { ILLUSION_DUST, 1, 2 }, { GREATER_ETERNAL, 1, 2 }, { LARGE_BRILLIANT, 1, 1 } },
    { 61, 65, { ILLUSION_DUST, 2, 5 }, { GREATER_ETERNAL, 2, 3 }, { LARGE_BRILLIANT, 1, 1 } },
}

-- Rare, weapons and armor alike: { low, high, outcomes }.
local RARE_ROWS = {
    { 11, 25, { { SMALL_GLIMMERING, 1, 1, 1 } } },
    { 26, 30, { { LARGE_GLIMMERING, 1, 1, 1 } } },
    { 31, 35, { { SMALL_GLOWING, 1, 1, 1 } } },
    { 36, 40, { { LARGE_GLOWING, 1, 1, 1 } } },
    { 41, 45, { { SMALL_RADIANT, 1, 1, 1 } } },
    { 46, 50, { { LARGE_RADIANT, 1, 1, 1 } } },
    { 51, 55, { { SMALL_BRILLIANT, 1, 1, 1 } } },
    { 56, 65, { { LARGE_BRILLIANT, 0.995, 1, 1 }, { NEXUS_CRYSTAL, 0.005, 1, 1 } } },
}

-- Epic, weapons and armor alike.
local EPIC_ROWS = {
    { 40, 45, { { SMALL_RADIANT, 1, 2, 4 } } },
    { 46, 50, { { LARGE_RADIANT, 1, 2, 4 } } },
    { 51, 55, { { SMALL_BRILLIANT, 1, 2, 4 } } },
    { 56, 60, { { NEXUS_CRYSTAL, 1, 1, 1 } } },
    { 61, 80, { { NEXUS_CRYSTAL, 1, 1, 2 } } },
}

local function row(rows, itemLevel)
    for _, entry in ipairs(rows) do
        if itemLevel >= entry[1] and itemLevel <= entry[2] then
            return entry
        end
    end
end

local function outcome(material, chance)
    return { item = material[1], chance = chance, min = material[2], max = material[3] }
end

---What disenchanting an item gives, most likely first: a list of { item, chance (0 to 1), min,
---max }, or nil when its quality and item level give nothing.
---@param quality number Enum.ItemQuality: 2 Uncommon, 3 Rare, 4 Epic
---@param itemLevel number
---@param isWeapon boolean
---@return table|nil
function Disenchant.Outcomes(quality, itemLevel, isWeapon)
    if type(itemLevel) ~= "number" then
        return nil
    end
    if quality == UNCOMMON then
        local entry = row(UNCOMMON_ROWS, itemLevel)
        if not entry then
            return nil
        end
        local chances = entry[6] or CHANCES
        local major, minor = entry[3], entry[4] -- armor: dust first
        if isWeapon then
            major, minor = minor, major
        end
        local list = { outcome(major, chances[1]), outcome(minor, chances[2]) }
        if entry[5] and chances[3] > 0 then
            list[3] = outcome(entry[5], chances[3])
        end
        return list
    end
    local entry = row(quality == RARE and RARE_ROWS or quality == EPIC and EPIC_ROWS or {}, itemLevel)
    if not entry then
        return nil
    end
    local list = {}
    for i, each in ipairs(entry[3]) do
        list[i] = { item = each[1], chance = each[2], min = each[3], max = each[4] }
    end
    return list
end

---Whether an item can be disenchanted, from its item info: an Uncommon, Rare, or Epic weapon or
---armor piece, not a shirt or tabard, with an item level the rules know. Can't see the flag a
---few items carry that stops it. Returns its outcomes too.
---@param classID number
---@param quality number
---@param equipLoc string|nil such as "INVTYPE_BODY"
---@param itemLevel number
---@return table|nil outcomes
function Disenchant.ForItem(classID, quality, equipLoc, itemLevel)
    if classID ~= WEAPON and classID ~= ARMOR then
        return nil
    end
    if equipLoc == "INVTYPE_BODY" or equipLoc == "INVTYPE_TABARD" then
        return nil
    end
    return Disenchant.Outcomes(quality, itemLevel, classID == WEAPON)
end

---What the outcomes are worth on average, in copper: each one's chance times its average amount
---times its price. `priceFn(itemID)` gives one item's price or nil. Also returns how many
---outcomes had no price; the total leaves them out.
---@param outcomes table from Outcomes
---@param priceFn fun(itemID: number): number|nil
---@return number total
---@return number missing
function Disenchant.Value(outcomes, priceFn)
    local total, missing = 0, 0
    for _, each in ipairs(outcomes) do
        local price = priceFn(each.item)
        if price then
            total = total + each.chance * (each.min + each.max) / 2 * price
        else
            missing = missing + 1
        end
    end
    return total, missing
end
