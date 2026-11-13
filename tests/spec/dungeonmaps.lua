-- DungeonMaps: which addon can show an instance's map, and asking it to, against made-up stubs of
-- the two addons' ways in.
local T = ...
local ns, eq = T.ns, T.eq

local combat = false
InCombatLockdown = function() return combat end
SlashCmdList = {}
T.load("Lib/DungeonMaps", ns)
local DM = ns.DungeonMaps

eq(DM.Has("journal"), false, "dungeonmaps: no DungeonJournal")
eq(DM.Has("leatrix"), false, "dungeonmaps: no Leatrix Maps")
eq(DM.Which("auto", 389, "Ragefire Chasm"), nil, "dungeonmaps: nobody to show it")
eq(DM.Open("journal", 389, "Ragefire Chasm"), false, "dungeonmaps: nothing opened")

-- DungeonJournal.
local opened, toggled = nil, 0
ForeverDungeonJournal_NS = {
    DUNGEON_MAPS = { ["Ragefire Chasm"] = {} },
    DungeonFromInstanceName = function(name)
        return (name == "Ragefire Chasm" or name == "Uldaman") and name or nil
    end,
    OpenDungeonMap = function(key) opened = key end,
}
eq(DM.Has("journal"), false, "dungeonmaps: DungeonJournal without its toggle doesn't count")
ForeverDungeonJournal_Toggle = function() toggled = toggled + 1 end
eq(DM.Has("journal"), true, "dungeonmaps: DungeonJournal")
eq(DM.Can("journal", 389, "Ragefire Chasm"), true, "dungeonmaps: a dungeon it has a map of")
eq(DM.Can("journal", 70, "Uldaman"), false, "dungeonmaps: a dungeon it knows without a map")
eq(DM.Can("journal", 1, "Nowhere"), false, "dungeonmaps: a dungeon it doesn't know")
eq(DM.Open("journal", 389, "Ragefire Chasm"), true, "dungeonmaps: asked DungeonJournal")
eq(opened, "Ragefire Chasm", "dungeonmaps: with its own key")
eq(toggled, 1, "dungeonmaps: its window opened first")
ForeverDungeonJournalFrame = { IsShown = function() return true end }
DM.Open("journal", 389, "Ragefire Chasm")
eq(toggled, 1, "dungeonmaps: an open window isn't toggled shut")
combat = true
eq(DM.Open("journal", 389, "Ragefire Chasm"), false, "dungeonmaps: not in combat")
combat = false
ForeverDungeonJournal_NS.OpenDungeonMap = function() error("changed") end
eq(DM.Open("journal", 389, "Ragefire Chasm"), false, "dungeonmaps: its error stays its own")

-- Leatrix Maps.
local said
SlashCmdList["Leatrix_Maps"] = function(text) said = text end
eq(DM.Has("leatrix"), false, "dungeonmaps: Leatrix Maps without its saved settings")
LeaMapsDB = { ShowDungeonMaps = "Off" }
eq(DM.Has("leatrix"), false, "dungeonmaps: its dungeon maps turned off")
LeaMapsDB.ShowDungeonMaps = "On"
eq(DM.Has("leatrix"), true, "dungeonmaps: Leatrix Maps")
eq(DM.Can("leatrix", 70, "Uldaman"), true, "dungeonmaps: a dungeon in its list")
eq(DM.Can("leatrix", 531, "Temple of Ahn'Qiraj"), false, "dungeonmaps: one no single word finds")
eq(DM.Open("leatrix", 70, "Uldaman"), true, "dungeonmaps: asked Leatrix Maps")
eq(said, "dun uldaman", "dungeonmaps: through its slash command")

eq(DM.Which("auto", 389, "Ragefire Chasm"), "journal", "dungeonmaps: auto prefers DungeonJournal")
eq(DM.Which("auto", 70, "Uldaman"), "leatrix", "dungeonmaps: auto falls to the one that has it")
eq(DM.Which("leatrix", 389, "Ragefire Chasm"), "leatrix", "dungeonmaps: the one picked")
eq(DM.Which("journal", 70, "Uldaman"), nil, "dungeonmaps: the one picked can't")
eq(DM.Which("off", 389, "Ragefire Chasm"), nil, "dungeonmaps: off")
