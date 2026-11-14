-- Core: a choice staying saved until a reset forgets it, and a checkbox that is one of Blizzard's
-- settings (`cvar`), in and out of combat.
local T = ...
local eq = T.eq

local c = T.Core()
local core, fire, registered, cvars, refuse = c.ns, c.fire, c.registered, c.cvars, c.refuse
local m = c.Modules()
local plain, coords = m.plain, m.coords
c.Login()
core.Print = function() end

-- A choice stays saved, even at the default, until a reset forgets it.
local saved = core.db.settings
core.SetEnabled("Plain", false)
core.SetEnabled("Plain", true)
eq(saved.Plain and saved.Plain.enabled, true, "choices: a module turned off and on keeps its choice")
core.SetOption("Plain", "loud", true)
core.SetOption("Plain", "loud", false)
eq(saved.Plain.loud, false, "choices: an option set back to its default keeps the choice")
plain.defaults.loud = true -- a later release turns it on by default
eq(plain.db.loud, false, "choices: so a new default doesn't change it")
core.ResetOption("Plain", "loud")
eq(saved.Plain.loud, nil, "choices: the undo arrow forgets it")
eq(plain.db.loud, true, "choices: and the new default reads back")
eq(registered("PLAYER_MONEY"), true, "choices: and the module hears it")
plain.defaults.loud = false
core.ResetOption("Plain", "loud")
core.SetOption("Plain", "mode", "a")
core.ApplyPreset()
eq(saved.Plain == nil or (saved.Plain.enabled == nil and saved.Plain.mode == nil), true,
    "choices: a preset forgets what it puts back to the default")
core.ApplyPreset({ "Plain" }, { Plain = { mode = "b" } })
eq(saved.Plain and saved.Plain.mode, "b", "choices: and saves what it sets otherwise")
core.ApplyPreset()

-- A `cvar` checkbox reads and sets the CVar; in combat it reads the choice until combat ends,
-- and the module, the API's listeners and the page hear about it then.
local told = {}
core.OnModuleChanged(function(name, key)
    if name == "Coords" then told[#told + 1] = key end
end)
local function news() -- what the module and the listeners heard since last asked
    local text = table.concat(m.coordsHeard, ",") .. "|" .. table.concat(told, ",")
    m.coordsHeard, told = {}, {}
    return text
end
eq(coords.defaults.player, false, "cvar: the default is the client's")
core.SetOption("Coords", "player", true)
eq(cvars.coords == "1" and coords.db.player == true, true, "cvar: out of combat it's set at once")
eq(news(), "player|player", "cvar: and the module hears it at once")
c.inCombat = true
core.SetOption("Coords", "player", false)
eq(cvars.coords, "1", "cvar: in combat the CVar waits")
eq(coords.db.player, false, "cvar: but the option reads the choice")
eq(news(), "|", "cvar: and nobody is told yet")
core.SetOption("Coords", "player", true)
core.SetOption("Coords", "player", false)
c.refreshed = {}
c.inCombat = false
fire("PLAYER_REGEN_ENABLED")
eq(cvars.coords == "0" and coords.db.player == false, true, "cvar: after combat it's the last choice")
eq(news(), "player|player", "cvar: told once, when it lands")
eq(table.concat(c.refreshed, ","), "Coords", "cvar: and the page redraws")
c.inCombat = true
core.SetOption("Coords", "player", true)
core.SetOption("Coords", "player", false)
c.inCombat = false
fire("PLAYER_REGEN_ENABLED")
eq(news(), "|", "cvar: a choice taken back in combat tells nobody")
c.inCombat = true
core.SetOption("Coords", "player", true)
core.ResetOption("Coords", "player")
eq(coords.db.player, false, "cvar: the undo arrow in combat reads the default")
core.SetOption("Coords", "player", true)
refuse.coords = true
c.inCombat = false
fire("PLAYER_REGEN_ENABLED")
eq(coords.db.player, false, "cvar: refused, it reads the CVar again")
eq(news(), "player|player", "cvar: and the module and page hear it, having shown the choice")
refuse.coords = nil
c.inCombat = true
core.ResetOption("Coords", "player")
eq(news(), "|", "cvar: a reset in combat waits too")
c.inCombat = false
fire("PLAYER_REGEN_ENABLED")
eq(news(), "|", "cvar: and tells nobody when nothing changed")
