-- Core and Lib/Profiles.lua: switching profiles live, waiting out combat, and ns.switching.
local T = ...
local eq = T.eq

local c = T.Core()
local core, fire, registered = c.ns, c.fire, c.registered
local m = c.Modules()
local plain, host, check, tool = m.plain, m.host, m.check, m.tool
c.Login()
core.Print = function() end

-- Profiles: a switch turns off what's on, reads the other profile, and turns on what it has
-- on, live; in combat it waits. Presets reset only the profile in use.
local Profiles = core.Profiles
eq(Profiles.Current(), "default", "profiles: the character starts on Default")
core.SetOption("Plain", "loud", true)
local two = Profiles.Create("Two")
core.db.profiles[two].settings = { Plain = { enabled = false, mode = "gone" }, Host = { extra = false },
    Tool = { mode = "b" } }
local switchedTold = {}
core.OnModuleChanged(function(name, key) switchedTold[#switchedTold + 1] = name .. ":" .. tostring(key) end)
c.refreshed = {}
eq(Profiles.Switch(two), true, "profiles: a switch out of combat")
eq(plain.enabled, false, "profiles: a module the new profile has off turns off")
eq(registered("PLAYER_LEVEL_UP"), false, "profiles: and its events stop")
eq(host.enabled and not check.enabled, true, "profiles: a module on in both reads the new profile's parts")
eq(plain.db.loud, false, "profiles: settings read the new profile")
eq(plain.db.mode, "a", "profiles: a saved choice that isn't one goes back to its default")
eq(tool.enabled and tool.db.mode == "b", true, "profiles: a tool stays on and reads the new profile")
eq(m.toolHeard[#m.toolHeard], "mode", "profiles: and hears the option that changed")
eq(table.concat(switchedTold, ","):find("Plain:nil", 1, true) ~= nil, true,
    "profiles: listeners hear of a module turned off")
eq(#c.refreshed >= #core.order, true, "profiles: every module's page redraws")
core.SetOption("Plain", "mode", "b")
eq(core.db.settings.Plain.mode, nil, "profiles: a change goes to the profile in use, not Default")
core.ApplyPreset()
eq(core.db.profiles[two].settings.Plain == nil or core.db.profiles[two].settings.Plain.mode == nil, true,
    "profiles: Defaults resets the profile in use")
eq(core.db.settings.Plain.loud, true, "profiles: and leaves the other profiles alone")
core.SetEnabled("Plain", false)
c.inCombat = true
eq(Profiles.Switch("default"), false, "profiles: in combat a switch waits")
eq(plain.enabled, false, "profiles: and nothing changes yet")
c.inCombat = false
fire("PLAYER_REGEN_ENABLED")
eq(Profiles.Current(), "default", "profiles: once combat ends it switches")
eq(plain.enabled and plain.db.loud, true, "profiles: and Default's modules and settings are back")
eq(registered("PLAYER_LEVEL_UP"), true, "profiles: with their events")
eq(check.enabled, true, "profiles: and parts")
eq(tool.db.mode, "a", "profiles: and the tool's option")

-- A module can tell being switched away from (a profile, a preset, Defaults) from being turned
-- off by the player: ns.switching is true only for the first. Two has Plain off.
local seen = {}
plain.OnDisable = function()
    seen[#seen + 1] = core.switching and true or false
end
core.SetEnabled("Plain", true)
core.SetEnabled("Plain", false)
core.SetEnabled("Plain", true)
Profiles.Switch(two)
Profiles.Switch("default")
eq(tostring(seen[1]) .. "," .. tostring(seen[2]), "false,true",
    "switching: off by hand, then by a profile switch")
eq(core.switching, false, "switching: over once the switch is done")
