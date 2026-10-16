-- An item's stats in short keys every module can share (STR, SP, HIT, DPS, ...), read from the
-- game's stat table (C_Item.GetItemStats, which on Forever carries the Equip: effects too, as the
-- Gear Probe showed on build 70425), with its slot, item level, and level requirement; and the
-- arithmetic of a stat weight score. An item the game hasn't cached yet gives nil and its ID, so
-- the caller can look again at GET_ITEM_INFO_RECEIVED. Nothing here reads frames.
local _, ns = ...

local pairs, type, sort = pairs, type, table.sort
local C_Item = C_Item

local ItemStats = {}
ns.ItemStats = ItemStats

-- The game's stat keys (C_Item.GetItemStats) and ours. Retail tells melee, ranged, and spell hit
-- and crit apart by key; Forever's strings say "Hit" and "Critical Strike" for one stat each
-- (Gear Probe, build 70425), so those fold together, with spell hit and crit kept apart in case
-- an item carries them. A key not here is remembered in `unknown` for the Debug page.
ItemStats.KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "STR",
    ITEM_MOD_AGILITY_SHORT = "AGI",
    ITEM_MOD_STAMINA_SHORT = "STA",
    ITEM_MOD_INTELLECT_SHORT = "INT",
    ITEM_MOD_SPIRIT_SHORT = "SPI",
    ITEM_MOD_HEALTH_SHORT = "HEALTH",
    ITEM_MOD_MANA_SHORT = "MANA",
    ITEM_MOD_ATTACK_POWER_SHORT = "AP",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "RAP",
    ITEM_MOD_SPELL_POWER_SHORT = "SP",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "SP",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "HEAL",
    ITEM_MOD_MANA_REGENERATION_SHORT = "MP5",
    ITEM_MOD_POWER_REGEN0_SHORT = "MP5",
    ITEM_MOD_HEALTH_REGEN_SHORT = "HP5",
    ITEM_MOD_HEALTH_REGENERATION_SHORT = "HP5",
    ITEM_MOD_HIT_RATING_SHORT = "HIT",
    ITEM_MOD_HIT_MELEE_RATING_SHORT = "HIT",
    ITEM_MOD_HIT_RANGED_RATING_SHORT = "HIT",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "SPELLHIT",
    ITEM_MOD_CRIT_RATING_SHORT = "CRIT",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT = "CRIT",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT = "CRIT",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "SPELLCRIT",
    ITEM_MOD_HASTE_RATING_SHORT = "HASTE",
    ITEM_MOD_HASTE_MELEE_RATING_SHORT = "HASTE",
    ITEM_MOD_HASTE_RANGED_RATING_SHORT = "HASTE",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT = "HASTE",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "EXPERTISE",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "ARMORPEN",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "DEF",
    ITEM_MOD_DODGE_RATING_SHORT = "DODGE",
    ITEM_MOD_PARRY_RATING_SHORT = "PARRY",
    ITEM_MOD_BLOCK_RATING_SHORT = "BLOCK",
    ITEM_MOD_BLOCK_VALUE_SHORT = "BLOCKVALUE",
    ITEM_MOD_EXTRA_ARMOR_SHORT = "ARMOR",
    RESISTANCE0_NAME = "ARMOR",
    RESISTANCE2_NAME = "RES_FIRE",
    RESISTANCE3_NAME = "RES_NATURE",
    RESISTANCE4_NAME = "RES_FROST",
    RESISTANCE5_NAME = "RES_SHADOW",
    RESISTANCE6_NAME = "RES_ARCANE",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "DPS",
}

-- Our keys in the order a page lists them. DPS_OFF and DPS_RANGED aren't stats an item has: a
-- weight set uses them for a weapon's DPS in the off hand and the ranged slot (see `Slotted`).
ItemStats.ORDER = {
    "STR", "AGI", "STA", "INT", "SPI", "HEALTH", "MANA",
    "AP", "RAP", "HIT", "CRIT", "HASTE", "EXPERTISE", "ARMORPEN",
    "SP", "HEAL", "SPELLHIT", "SPELLCRIT", "MP5", "HP5",
    "ARMOR", "DEF", "DODGE", "PARRY", "BLOCK", "BLOCKVALUE",
    "DPS", "DPS_OFF", "DPS_RANGED",
    "RES_FIRE", "RES_NATURE", "RES_FROST", "RES_SHADOW", "RES_ARCANE",
}

-- The keys whose values are a chance in percent on Forever's gear (inferred from the client's
-- strings and the character sheet; a weight for them is per 1%).
ItemStats.PERCENT = {
    HIT = true, CRIT = true, HASTE = true, SPELLHIT = true, SPELLCRIT = true,
    DODGE = true, PARRY = true, BLOCK = true,
}

local unknown = {} -- a game key KEYS lacks -> true, once met

---The game's stat table in our keys, numbers only; keys we don't know are remembered for
---`Unknown`. Two game keys that mean the same stat add up.
---@param raw table? C_Item.GetItemStats's table
---@return table stats our key -> value
function ItemStats.Normalize(raw)
    local stats = {}
    if type(raw) ~= "table" then
        return stats
    end
    for key, value in pairs(raw) do
        if ns.IsReadable(key) and ns.IsReadable(value) and type(value) == "number" then
            local ours = ItemStats.KEYS[key]
            if ours then
                stats[ours] = (stats[ours] or 0) + value
            elseif type(key) == "string" then
                unknown[key] = true
            end
        end
    end
    return stats
end

---The game's stat keys met so far that aren't mapped, sorted, for the Debug page.
---@return string[]
function ItemStats.Unknown()
    local list = {}
    for key in pairs(unknown) do
        list[#list + 1] = key
    end
    sort(list)
    return list
end

-- Reading items ---------------------------------------------------------------------------------

local cache = {} -- link -> info

---What an item link is: `{ id, slot (INVTYPE_*, or ""), classID, subclassID, level, minLevel,
---stats }`, kept per link (which carries suffix and enchant). Nil while the game hasn't cached
---the item, with its ID as a second value so the caller can look again at GET_ITEM_INFO_RECEIVED
---(the data is asked for); nil alone for something that isn't an item.
---@param link string
---@return table? info
---@return number? itemID when the item isn't cached yet
function ItemStats.Get(link)
    if not ns.IsText(link, true) then
        return nil
    end
    local info = cache[link]
    if info then
        return info
    end
    if not (C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfo) then
        return nil
    end
    local itemID, _, _, equipLoc, _, classID, subclassID = C_Item.GetItemInfoInstant(link)
    if not (ns.IsReadable(itemID) and type(itemID) == "number") then
        return nil
    end
    local name, _, _, level, minLevel = C_Item.GetItemInfo(link)
    if not ns.IsText(name, true) then
        if C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
        return nil, itemID
    end
    local raw = C_Item.GetItemStats and C_Item.GetItemStats(link)
    info = {
        id = itemID,
        slot = ns.IsText(equipLoc) and equipLoc or "",
        classID = ns.IsReadable(classID) and classID or nil,
        subclassID = ns.IsReadable(subclassID) and subclassID or nil,
        level = ns.IsReadable(level) and type(level) == "number" and level or 0,
        minLevel = ns.IsReadable(minLevel) and type(minLevel) == "number" and minLevel or 0,
        stats = ItemStats.Normalize(ns.IsReadable(raw) and raw or nil),
    }
    cache[link] = info
    return info
end

---Forgets every item read, so the next read asks the game again (after a patch, or for a test).
function ItemStats.Forget()
    for link in pairs(cache) do
        cache[link] = nil
    end
end

-- Scoring ---------------------------------------------------------------------------------------

-- The weapon slots whose DPS a weight set prices apart from a main hand's.
local DPS_KEYS = {
    INVTYPE_WEAPONOFFHAND = "DPS_OFF",
    INVTYPE_RANGED = "DPS_RANGED",
    INVTYPE_RANGEDRIGHT = "DPS_RANGED",
    INVTYPE_THROWN = "DPS_RANGED",
}

---An item's stats with its DPS under the key its slot prices (DPS_OFF for an off-hand weapon,
---DPS_RANGED for a ranged one, DPS otherwise), so one weight set scores every weapon.
---@param stats table
---@param slot string INVTYPE_*
---@return table stats the same table when nothing changes
function ItemStats.Slotted(stats, slot)
    local key = DPS_KEYS[slot]
    if not (key and stats.DPS) then
        return stats
    end
    local copy = {}
    for k, v in pairs(stats) do
        copy[k] = v
    end
    copy[key] = copy.DPS
    copy.DPS = nil
    return copy
end

---A stat weight score: each stat times its weight, added up. A stat without a weight counts
---nothing.
---@param stats table our key -> value
---@param weights table our key -> weight
---@return number
function ItemStats.Score(stats, weights)
    local total = 0
    for key, value in pairs(stats) do
        local weight = weights[key]
        if weight and weight ~= 0 then
            total = total + value * weight
        end
    end
    return total
end

---Whether a score beats the score of what it would replace by more than `threshold` percent, and
---by how much. Against nothing (an empty slot, rival 0) anything with a score is an upgrade, and
---the percentage is nil, since there's nothing to be a percentage of.
---@param score number
---@param rival number
---@param threshold? number percent, 0 by default
---@return boolean upgrade
---@return number? percent
function ItemStats.Compare(score, rival, threshold)
    if rival <= 0 then
        return score > 0, nil
    end
    local percent = (score - rival) / rival * 100
    return percent > (threshold or 0), percent
end
