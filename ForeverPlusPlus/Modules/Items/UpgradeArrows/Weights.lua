-- Upgrade Arrows' stat weights: a template per role, which talent tab of each class uses which,
-- a few nudges per class, and the profile a character judges gear by (its template plus what
-- the player changed, saved per profile). The numbers are starting points from Classic
-- conventions, per point of a stat and per 1% of a chance stat, to be tuned as Forever's gear
-- shows how it reads; they are Forever++'s own, not another addon's.
local _, ns = ...

local pairs, format, tonumber = pairs, string.format, tonumber

local module = ns.modules.UpgradeArrows
local internal = module.internal

-- Role templates. DPS is a main-hand or two-handed weapon's, DPS_OFF an off-hand weapon's, and
-- DPS_RANGED a ranged weapon's (Lib/ItemStats.lua, Slotted).
local TEMPLATES = {
    -- Strength melee: 2 attack power a point for these classes; the off hand counts for the
    -- dual wielders among them.
    strength = { STR = 1, AGI = 0.6, AP = 0.5, HIT = 10, CRIT = 8, STA = 0.3, DPS = 4, DPS_OFF = 1.5 },
    -- Agility melee: crit and attack power from agility.
    agility = { AGI = 1, STR = 0.5, AP = 0.5, HIT = 10, CRIT = 7, STA = 0.3, DPS = 3, DPS_OFF = 1.5 },
    -- Ranged: the ranged weapon's DPS first; melee weapons are stat sticks.
    ranged = { AGI = 1, RAP = 0.5, AP = 0.2, HIT = 10, CRIT = 8, INT = 0.3, STA = 0.3, DPS_RANGED = 5, DPS = 0.2 },
    -- Casters: spell damage, then hit, then crit.
    caster = { SP = 1, SPELLHIT = 10, SPELLCRIT = 7, INT = 0.35, STA = 0.25, MP5 = 0.6, SPI = 0.15 },
    -- Healers: healing, regen, and mana. Spirit matters more on Forever than in Classic.
    healer = { HEAL = 1, SP = 0.3, MP5 = 1.5, INT = 0.6, SPI = 0.5, SPELLCRIT = 3, STA = 0.2 },
    -- Tanks: defense until uncrittable, then avoidance and stamina.
    tank = { STA = 1.2, DEF = 1.8, DODGE = 10, PARRY = 8, BLOCK = 4, BLOCKVALUE = 0.4, ARMOR = 0.06,
        STR = 0.6, AGI = 0.7, HIT = 4, CRIT = 2, DPS = 1 },
    -- Bears: armor is multiplied in form, so it counts more; no block or parry.
    bear = { STA = 1.2, AGI = 1, ARMOR = 0.08, STR = 0.4, DEF = 1.2, DODGE = 10, HIT = 4, CRIT = 3, DPS = 1 },
    -- A tab the map doesn't know (after a patch): something sensible.
    fallback = { STR = 1, AGI = 1, STA = 0.5, INT = 1, SPI = 0.5, AP = 0.3, SP = 0.8, HEAL = 0.6,
        HIT = 5, CRIT = 5, SPELLHIT = 5, SPELLCRIT = 5, DPS = 2 },
}
internal.TEMPLATES = TEMPLATES

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
internal.CLASS_TABS = CLASS_TABS

-- Changes to a template for one class's tab: Warlocks tap for mana, Priests and Druids heal on
-- Spirit.
local NUDGES = {
    WARLOCK = { [1] = { MP5 = 0.2 }, [2] = { MP5 = 0.2 }, [3] = { MP5 = 0.2 } },
    PRIEST = { [1] = { SPI = 0.9 }, [2] = { SPI = 0.9 } },
    DRUID = { [3] = { SPI = 0.9 } },
}

---The profile a character judges gear by: `{ key, template, weights }`, where `key` names the
---saved weights ("MAGE:3", "DRUID:bear"), `template` the role it starts from, and `weights` the
---template with the class's nudges and the player's own changes on top.
---@param class string the class token, such as "MAGE"
---@param index number the talent tab, 1 to 3
---@param bear? boolean the Feral Bear profile (Druids)
---@return table profile
function internal.Profile(class, index, bear)
    class = class or "?"
    index = tonumber(index) or 1
    local template = bear and "bear" or (CLASS_TABS[class] and CLASS_TABS[class][index]) or "fallback"
    local key = bear and (class .. ":bear") or format("%s:%d", class, index)
    local weights = {}
    for stat, weight in pairs(TEMPLATES[template]) do
        weights[stat] = weight
    end
    local nudge = not bear and NUDGES[class] and NUDGES[class][index]
    for stat, weight in pairs(nudge or {}) do
        weights[stat] = weight
    end
    local saved = module.db and module.db.weights and module.db.weights[key]
    for stat, weight in pairs(type(saved) == "table" and saved or {}) do
        if type(weight) == "number" then
            weights[stat] = weight
        end
    end
    return { key = key, template = template, weights = weights }
end
