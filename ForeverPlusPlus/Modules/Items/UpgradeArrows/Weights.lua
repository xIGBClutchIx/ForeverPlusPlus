-- Upgrade Arrows' stat weights: a template per role, which talent tab of each class uses which,
-- what each tab changes, and the profile a character judges gear by (its template plus what
-- the player changed, saved per profile). The root numbers (attack power, hit, crit, spell
-- damage, healing, regen, defense, weapon damage) are Forever++'s own judgment, per point of a
-- stat and per 1% of a chance stat, from Classic conventions; the attributes follow from the
-- game's own conversions (below). The orderings were checked against Icy Veins' WoW Forever
-- beta guides (icy-veins.com/wow-forever, read 2026-10-16): Fury lists weapon damage, hit,
-- crit, Strength, Agility; Frost Mage hit (to its cap), spell damage, crit, then Spirit and
-- Intellect; Holy Priest healing, mana per 5, Spirit, Intellect, then crit; Beast Mastery
-- weapon damage, then Agility. Those guides give orders, not numbers, and say Forever's caps
-- aren't known yet. Not another addon's tables.
local _, ns = ...

local pairs, next, type, format, tonumber, concat = pairs, next, type, string.format, tonumber, table.concat

local L = ns.L
local ItemStats = ns.ItemStats

local module = ns.modules.UpgradeArrows
local internal = module.internal

-- Role templates. DPS is a main-hand or two-handed weapon's, DPS_OFF an off-hand weapon's, and
-- DPS_RANGED a ranged weapon's (Lib/ItemStats.lua, Slotted). Every value is a multiple of 0.05,
-- the page's slider step, so a default sits on a step and never reads as changed.
-- Strength, Agility, Stamina, and Intellect are placeholders: for the character's own class
-- they're worked out from the game's conversions and the root weights (attack power, crit,
-- dodge, armor, health, spell crit, mana; Lib/ItemStats.lua, DeriveAttributes), so 1 Agility on
-- a Rogue is worth what the game says it gives. The placeholders serve another class's trees
-- and a client that can't answer. Spirit stays a judgment: its regen counts only outside the
-- five-second rule.
local TEMPLATES = {
    -- Strength melee: 2 attack power a point for these classes; the off hand counts for the
    -- dual wielders among them.
    strength = { STR = 1, AGI = 0.6, AP = 0.5, HIT = 10, CRIT = 8, STA = 0.3, HEALTH = 0.03, DPS = 4, DPS_OFF = 1.5 },
    -- Agility melee: crit and attack power from agility.
    agility = { AGI = 1, STR = 0.5, AP = 0.5, HIT = 10, CRIT = 7, STA = 0.3, HEALTH = 0.03, DPS = 3, DPS_OFF = 1.5 },
    -- Ranged: the ranged weapon's DPS first; melee weapons are stat sticks.
    ranged = { AGI = 1, RAP = 0.5, AP = 0.2, HIT = 10, CRIT = 8, INT = 0.3, MANA = 0.02, STA = 0.3, HEALTH = 0.03,
        DPS_RANGED = 5, DPS = 0.2 },
    -- Casters: spell damage, then hit, then crit; a wand's damage counts while leveling.
    caster = { SP = 1, SPELLHIT = 10, SPELLCRIT = 7, INT = 0.35, MANA = 0.02, STA = 0.25, HEALTH = 0.03, MP5 = 0.6,
        SPI = 0.15, DPS_RANGED = 1.2 },
    -- Healers: healing, regen, and mana. Spirit matters more on Forever than in Classic.
    healer = { HEAL = 1, SP = 0.3, MP5 = 1.5, INT = 0.6, MANA = 0.04, SPI = 0.5, SPELLCRIT = 3, STA = 0.2,
        HEALTH = 0.02, DPS_RANGED = 0.5 },
    -- Tanks: defense until uncrittable, then avoidance and stamina.
    tank = { STA = 1.2, HEALTH = 0.12, DEF = 1.8, DODGE = 10, PARRY = 8, BLOCK = 4, BLOCKVALUE = 0.4, ARMOR = 0.05,
        STR = 0.6, AGI = 0.7, AP = 0.3, HIT = 4, CRIT = 2, DPS = 1 },
    -- Bears: armor is multiplied in form, so it counts more; no block or parry.
    bear = { STA = 1.2, HEALTH = 0.12, AGI = 1, ARMOR = 0.1, STR = 0.4, AP = 0.2, DEF = 1.2, DODGE = 10, HIT = 4,
        CRIT = 3, DPS = 1 },
    -- A tab the map doesn't know (after a patch): something sensible.
    fallback = { STR = 1, AGI = 1, STA = 0.5, HEALTH = 0.05, INT = 1, MANA = 0.03, SPI = 0.5, AP = 0.3, SP = 0.8,
        HEAL = 0.6, HIT = 5, CRIT = 5, SPELLHIT = 5, SPELLCRIT = 5, DPS = 2 },
}

-- The attributes the game's conversions decide, and the rates behind each.
local DERIVED = { STR = true, AGI = true, STA = true, INT = true }
internal.DERIVED = DERIVED

local rates -- the player's rates, read when a profile is made

local playerClass = internal.PlayerClass

-- Puts the derived attributes into a profile's defaults, for the character's own class.
local function derive(class, defaults)
    if class ~= playerClass() then
        return
    end
    rates = ItemStats.PlayerRates()
    for stat, value in pairs(ItemStats.DeriveAttributes(defaults, rates)) do
        defaults[stat] = value
    end
end

-- A rate as text: up to three decimals, no trailing zeros.
local function rateText(value)
    local text = format("%.3f", value)
    text = (text:gsub("0+$", ""))
    return (text:gsub("%.$", ""))
end

---What one point of a derived attribute gives the character, for a row's tooltip, or nil for
---a stat that isn't derived or a rate the client didn't give.
---@param stat string
---@param profile table from internal.Profile
---@return string?
function internal.DerivedText(stat, profile)
    if not (DERIVED[stat] and rates and profile.class == playerClass()) then
        return nil
    end
    local parts = {}
    local function add(key, template)
        local rate = rates[key]
        if rate and rate ~= 0 then
            parts[#parts + 1] = format(template, rateText(rate))
        end
    end
    if stat == "STR" then
        add("AP_STR", L.UPGRADEARROWS_DERIVED_AP)
    elseif stat == "AGI" then
        add("AP_AGI", L.UPGRADEARROWS_DERIVED_AP)
        add("RAP_AGI", L.UPGRADEARROWS_DERIVED_RAP)
        add("CRIT_AGI", L.UPGRADEARROWS_DERIVED_CRIT)
        add("DODGE_AGI", L.UPGRADEARROWS_DERIVED_DODGE)
        add("ARMOR_AGI", L.UPGRADEARROWS_DERIVED_ARMOR)
    elseif stat == "STA" then
        add("HEALTH_STA", L.UPGRADEARROWS_DERIVED_HEALTH)
    elseif stat == "INT" then
        add("SPELLCRIT_INT", L.UPGRADEARROWS_DERIVED_SPELLCRIT)
        add("MANA_INT", L.UPGRADEARROWS_DERIVED_MANA)
    end
    if #parts == 0 then
        return nil
    end
    return format(L.UPGRADEARROWS_DERIVED, L["UPGRADEARROWS_STAT_" .. stat], concat(parts, ", "))
end

-- Each class's talent tabs in order, and the template each uses. The order is Classic's, which
-- Forever keeps (Gear Probe, build 70425: Mage Arcane, Fire, Frost).
local CLASS_TABS = {
    WARRIOR = { "strength", "strength", "tank" }, -- Arms, Fury, Protection
    PALADIN = { "healer", "tank", "strength" }, -- Holy, Protection, Retribution
    HUNTER = { "ranged", "ranged", "ranged" }, -- Beast Mastery, Marksmanship, Survival
    ROGUE = { "agility", "agility", "agility" }, -- Assassination, Combat, Subtlety
    PRIEST = { "healer", "healer", "caster" }, -- Discipline, Holy, Shadow
    SHAMAN = { "caster", "strength", "healer" }, -- Elemental, Enhancement, Restoration
    MAGE = { "caster", "caster", "caster" }, -- Arcane, Fire, Frost
    WARLOCK = { "caster", "caster", "caster" }, -- Affliction, Demonology, Destruction
    DRUID = { "caster", "agility", "healer" }, -- Balance, Feral (cat), Restoration
}

---A class's talent tab's name in our strings, for a class the client has no talent data for
---(another class than the character's). "Tree N" for a class or tab we don't know.
---@param class string the class token
---@param index number 1 to 3
---@return string
function internal.TabName(class, index)
    -- ns.L gives a missing key back as itself, never nil.
    local key = format("UPGRADEARROWS_TAB_%s_%d", class, index)
    local name = L[key]
    if name ~= key then
        return name
    end
    return format(L.UPGRADEARROWS_PROFILE_TREE, index)
end

-- What each tab changes in its template, so every tree has defaults of its own: two-handers
-- for Arms and Retribution, the off hand for Fury and Combat, crit for the crit trees (Fire,
-- Destruction, Elemental, Assassination), hit for Shadow, mana for Warlocks (Life Tap) and
-- Arcane, Spirit for the healers who regen on it, armor and stamina for Demonology.
local NUDGES = {
    WARRIOR = {
        [1] = { CRIT = 9, DPS = 5, DPS_OFF = 0 }, -- Arms: a slow two-hander, Deep Wounds
        [2] = { HIT = 11, DPS_OFF = 2.5 }, -- Fury: dual wielding needs hit, and the off hand counts
        [3] = {}, -- Protection
    },
    PALADIN = {
        [1] = { INT = 0.7, SPELLCRIT = 4 }, -- Holy: Illumination
        [2] = { BLOCKVALUE = 0.6, SP = 0.3 }, -- Protection: blocks, and holy damage from spell power
        [3] = { CRIT = 9, DPS = 5, DPS_OFF = 0, SP = 0.2 }, -- Retribution: a slow two-hander, seals
    },
    HUNTER = {
        [1] = { STA = 0.35, INT = 0.35 }, -- Beast Mastery: mana for the pet's keeper
        [2] = { RAP = 0.55, CRIT = 9 }, -- Marksmanship
        [3] = { AGI = 1.1 }, -- Survival: agility talents
    },
    ROGUE = {
        [1] = { CRIT = 8, DPS = 3.5 }, -- Assassination: Seal Fate, a dagger's damage
        [2] = { HIT = 11, DPS_OFF = 2 }, -- Combat: dual wielding needs hit
        [3] = { AGI = 1.1 }, -- Subtlety
    },
    PRIEST = {
        [1] = { SPI = 0.9, INT = 0.7 }, -- Discipline: Spiritual Guidance, Mental Strength
        [2] = { SPI = 0.9 }, -- Holy: Spiritual Guidance
        [3] = { SPELLHIT = 11, SPI = 0.4 }, -- Shadow
    },
    SHAMAN = {
        [1] = { SPELLCRIT = 9 }, -- Elemental
        [2] = { DPS = 5, DPS_OFF = 0.5, INT = 0.2 }, -- Enhancement: a slow two-hander for Windfury
        [3] = { MP5 = 1.7 }, -- Restoration
    },
    MAGE = {
        [1] = { INT = 0.5, MANA = 0.03, SPELLCRIT = 6 }, -- Arcane: a mana pool to burn
        [2] = { SPELLCRIT = 9 }, -- Fire: Ignite
        [3] = { SPELLCRIT = 8, SPI = 0.3 }, -- Frost: Ice Shards; Spirit for regen (Icy Veins)
    },
    WARLOCK = {
        [1] = { MP5 = 0.2, SPI = 0.25 }, -- Affliction: Life Tap, some regen
        [2] = { MP5 = 0.2, STA = 0.4 }, -- Demonology: Life Tap, stamina for the pet and the tap
        [3] = { MP5 = 0.2, SPELLCRIT = 9 }, -- Destruction: Life Tap, crit
    },
    DRUID = {
        [1] = { SPELLCRIT = 8, SPI = 0.3 }, -- Balance
        [2] = { STR = 0.6, DPS_OFF = 0 }, -- Feral (cat): no off hand
        [3] = { SPI = 0.9 }, -- Restoration
    },
}

---The profile a character judges gear by: `{ key, template, defaults, weights, class, index,
---bear }`, where `key` names the saved weights ("MAGE:3", "DRUID:bear"), `template` the role it
---starts from, `defaults` the template with the class's nudges, and `weights` those with the
---player's own changes on top.
---@param class string the class token, such as "MAGE"
---@param index number the talent tab, 1 to 3
---@param bear? boolean the Feral Bear profile (Druids)
---@return table profile
function internal.Profile(class, index, bear)
    class = class or "?"
    index = tonumber(index) or 1
    local template = bear and "bear" or (CLASS_TABS[class] and CLASS_TABS[class][index]) or "fallback"
    local key = bear and (class .. ":bear") or format("%s:%d", class, index)
    local defaults, weights = {}, {}
    for stat, weight in pairs(TEMPLATES[template]) do
        defaults[stat] = weight
    end
    local nudge = not bear and NUDGES[class] and NUDGES[class][index]
    for stat, weight in pairs(nudge or {}) do
        defaults[stat] = weight
    end
    derive(class, defaults)
    for stat, weight in pairs(defaults) do
        weights[stat] = weight
    end
    local saved = module.db and module.db.weights and module.db.weights[key]
    for stat, weight in pairs(type(saved) == "table" and saved or {}) do
        if type(weight) == "number" then
            weights[stat] = weight
        end
    end
    return { key = key, template = template, defaults = defaults, weights = weights,
        class = class, index = index, bear = bear or nil }
end

---Saves the player's weight for a stat in a profile: nothing when it's the default again, so a
---better default reaches everyone who never changed it.
---@param profile table from internal.Profile
---@param stat string
---@param value number
function internal.SetWeight(profile, stat, value)
    local all = module.db.weights
    local saved = all[profile.key]
    local default = profile.defaults[stat] or 0
    if value == default then
        if saved then
            saved[stat] = nil
            if next(saved) == nil then
                all[profile.key] = nil
            end
        end
    else
        if not saved then
            saved = {}
            all[profile.key] = saved
        end
        saved[stat] = value
    end
    profile.weights[stat] = value ~= 0 and value or nil
    internal.WeightsChanged()
end

---Forgets every weight the player changed in a profile.
---@param profile table from internal.Profile
function internal.ResetWeights(profile)
    module.db.weights[profile.key] = nil
    for stat in pairs(profile.weights) do
        profile.weights[stat] = nil
    end
    for stat, weight in pairs(profile.defaults) do
        profile.weights[stat] = weight
    end
    internal.WeightsChanged()
end
