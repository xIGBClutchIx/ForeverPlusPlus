-- DungeonMaps: whether DungeonJournal can show an instance's map, and asking it to, against a
-- made-up stub of what it leaves in reach.
local T = ...
local ns, eq = T.ns, T.eq

local combat = false
InCombatLockdown = function() return combat end
T.load("Lib/DungeonMaps", ns)
local DM = ns.DungeonMaps

eq(DM.Has(), false, "dungeonmaps: no DungeonJournal")
eq(DM.Can("Ragefire Chasm"), false, "dungeonmaps: nobody to show it")
eq(DM.Open("Ragefire Chasm"), false, "dungeonmaps: nothing opened")

local opened, toggled = nil, 0
ForeverDungeonJournal_NS = {
    DUNGEON_MAPS = { ["Ragefire Chasm"] = {} },
    DungeonFromInstanceName = function(name)
        return (name == "Ragefire Chasm" or name == "Uldaman") and name or nil
    end,
    OpenDungeonMap = function(key) opened = key end,
}
eq(DM.Has(), false, "dungeonmaps: DungeonJournal without its toggle doesn't count")
ForeverDungeonJournal_Toggle = function() toggled = toggled + 1 end
eq(DM.Has(), true, "dungeonmaps: DungeonJournal")
eq(DM.Can("Ragefire Chasm"), true, "dungeonmaps: a dungeon it has a map of")
eq(DM.Can("Uldaman"), false, "dungeonmaps: a dungeon it knows without a map")
eq(DM.Can("Nowhere"), false, "dungeonmaps: a dungeon it doesn't know")
eq(DM.Can(nil), false, "dungeonmaps: no name")
eq(DM.Open("Ragefire Chasm"), true, "dungeonmaps: asked DungeonJournal")
eq(opened, "Ragefire Chasm", "dungeonmaps: with its own key")
eq(toggled, 1, "dungeonmaps: its window opened first")
ForeverDungeonJournalFrame = { IsShown = function() return true end }
DM.Open("Ragefire Chasm")
eq(toggled, 1, "dungeonmaps: an open window isn't toggled shut")
combat = true
eq(DM.Open("Ragefire Chasm"), false, "dungeonmaps: not in combat")
combat = false
ForeverDungeonJournal_NS.OpenDungeonMap = function() error("changed") end
eq(DM.Open("Ragefire Chasm"), false, "dungeonmaps: its error stays its own")
