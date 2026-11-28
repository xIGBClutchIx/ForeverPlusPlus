-- Hand-kept data for the Smart Buff macro: each class's buffs and the spells behind them. A fix
-- is made here; Macros' SmartBuff.lua has Self Test check every ID.
local _, ns = ...

ns.Data = ns.Data or {}

-- Each class's buffs, the one it prefers first, by its first rank's spell ID (build 70374,
-- Classic's IDs; the spellbook gives the other ranks by name).
--   who: who can get it: "any", "mana" (those who use mana), "physical" (those who don't, or a
--     Paladin or Druid of a melee tree), or "self".
--   group: a unit holds one of a group from each caster: a Paladin's Blessings, a Mage's or
--     Warlock's armor.
--   stronger: buffs that count as having it: its group version, from anyone.
--   reach: who the group version (the first of `stronger`) buffs, for Smart Buff's Group Versions:
--     "all", every party and raid member, or "class", those of the target's class. From the
--     spells' descriptions in the client's Spell table (wago.tools, build 1.60.1.71139): Prayer of
--     Fortitude and Spirit and Gift of the Wild "all party and raid members", Arcane Brilliance
--     "the target's party and raid", a Greater Blessing "all members of the raid or group that
--     share the same class with the target".
ns.Data.smartBuffs = {
    PALADIN = {
        -- Kings first: 10% of every stat beats Might or Wisdom once it's learned.
        { id = 20217, name = "Blessing of Kings", who = "any", group = "blessing", stronger = { 25898 },
            reach = "class" },
        { id = 19740, name = "Blessing of Might", who = "physical", group = "blessing", stronger = { 25782 },
            reach = "class" },
        { id = 19742, name = "Blessing of Wisdom", who = "mana", group = "blessing", stronger = { 25894 },
            reach = "class" },
    },
    PRIEST = {
        { id = 1243, name = "Power Word: Fortitude", who = "any", stronger = { 21562 }, reach = "all" },
        { id = 14752, name = "Divine Spirit", who = "mana", stronger = { 27681 }, reach = "all" },
        { id = 588, name = "Inner Fire", who = "self" },
    },
    MAGE = {
        { id = 1459, name = "Arcane Intellect", who = "mana", stronger = { 23028 }, reach = "all" },
        { id = 7302, name = "Ice Armor", who = "self", group = "armor" },
        { id = 168, name = "Frost Armor", who = "self", group = "armor" },
    },
    DRUID = {
        { id = 1126, name = "Mark of the Wild", who = "any", stronger = { 21849 }, reach = "all" },
        { id = 467, name = "Thorns", who = "physical" },
        { id = 16864, name = "Omen of Clarity", who = "self" },
    },
    WARLOCK = {
        { id = 706, name = "Demon Armor", who = "self", group = "armor" },
        { id = 687, name = "Demon Skin", who = "self", group = "armor" },
    },
    SHAMAN = { { id = 324, name = "Lightning Shield", who = "self" } },
    WARRIOR = { { id = 6673, name = "Battle Shout", who = "self" } },
    HUNTER = { { id = 19506, name = "Trueshot Aura", who = "self" } },
}

-- The stronger versions named above (Classic's IDs, first rank).
ns.Data.smartBuffStronger = {
    [25782] = "Greater Blessing of Might",
    [25894] = "Greater Blessing of Wisdom",
    [25898] = "Greater Blessing of Kings",
    [21562] = "Prayer of Fortitude",
    [27681] = "Prayer of Spirit",
    [23028] = "Arcane Brilliance",
    [21849] = "Gift of the Wild",
}

-- The level of buffs the game doesn't give a learned level for, since a talent isn't learned from
-- a trainer (Classic's spell levels; Forever refused Kings on a level 7 on 2026-10-20).
ns.Data.smartBuffLevels = {
    [20217] = 20, -- Blessing of Kings
}
