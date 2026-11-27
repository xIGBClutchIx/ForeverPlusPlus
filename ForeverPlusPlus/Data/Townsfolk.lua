-- Townsfolk: the words that tell one kind of townsperson from another in the English titles under
-- their names, as QuestieDB's own data has them before its translations (QuestieDB.English), so
-- they hold in every language. QuestieDB's NPC flags say who trains or sells; only the title says
-- what. Words, not NPC IDs: who stands where is read from QuestieDB at run time, never kept here.
-- From the titles of every NPC with the trainer or vendor flag in QuestieDB's Forever data
-- (data/Forever/foreverNpcDB.lua, read 2026-11-27); each word is matched anywhere in a title.
local _, ns = ...

ns.Data = ns.Data or {}

-- Class trainers, by the class's token (UnitClass's second value). Pet Trainer teaches a hunter's
-- pet, Demon Trainer sells a warlock's demon spells, Portal Trainer a mage's portals.
ns.Data.townsfolkClassTrainers = {
    WARRIOR = { "Warrior Trainer" },
    PALADIN = { "Paladin Trainer" },
    HUNTER = { "Hunter Trainer", "Pet Trainer" },
    ROGUE = { "Rogue Trainer", "Grand Master Rogue" },
    PRIEST = { "Priest Trainer", "High Priest" },
    SHAMAN = { "Shaman Trainer" },
    MAGE = { "Mage Trainer", "Master Mage", "Portal Trainer" },
    WARLOCK = { "Warlock Trainer", "Demon Trainer" },
    DRUID = { "Druid Trainer" },
}

-- Profession trainers, by skill line ID (SkillLine): Journeyman, Expert, Artisan, and Master
-- titles all carry the profession's word. Physicians and surgeons teach First Aid; the Superior
-- Butcher, Cooking.
ns.Data.townsfolkProfessionTrainers = {
    [171] = { "Alchem" }, -- Alchemy
    [164] = { "Blacksmith", "Armorsmith", "Weaponsmith", "Armor Crafter", "Weapon Crafter" }, -- Blacksmithing
    [333] = { "Enchant" }, -- Enchanting
    [202] = { "Engineer" }, -- Engineering
    [165] = { "Leather" }, -- Leatherworking
    [197] = { "Tailor" }, -- Tailoring
    [185] = { "Cook", "Butcher" }, -- Cooking
    [129] = { "First Aid", "Physician", "Surgeon" }, -- First Aid
    [356] = { "Fish" }, -- Fishing
    [182] = { "Herbalis" }, -- Herbalism
    [186] = { "Miner", "Mining" }, -- Mining
    [393] = { "Skinn" }, -- Skinning
}

-- Vendors, by the kinds the minimap's tracking menu has. A vendor whose title has none of these
-- words shows only as a repairer, if it repairs.
ns.Data.townsfolkVendors = {
    food = { "Food", "Drink", "Baker", "Bread", "Butcher", "Meat", "Fruit", "Fish Vendor",
        "Mushroom", "Bartender", "Barmaid", "Waitress", "Sweet", "Treats", "Wine" },
    reagent = { "Reagent" },
    poison = { "Poison" },
    ammo = { "Ammunition", "Bowyer", "Fletch", "Gunsmith", "Gun Merchant", "Guns Vendor",
        "Bow Merchant" },
}
