-- Core and Commands.lua: /fpp set and toggle, Defaults, and a command whose module is off.
local T = ...
local eq = T.eq

local c = T.Core()
local core, registered = c.ns, c.registered
local m = c.Modules()
local plain, host = m.plain, m.host
c.Login()
core.SetOption("Plain", "loud", true)

-- /fpp set and the presets (Commands.lua) go through the same paths.
local fpp = SlashCmdList.FOREVERPLUSPLUS
core.Print = function() end
fpp("set Plain mode off")
eq(plain.db.mode, "off", "commands: /fpp set takes a choice key")
eq(registered("BAG_UPDATE"), false, "commands: /fpp set tells the module")
fpp("toggle Plain loud")
eq(plain.db.loud, false, "commands: /fpp toggle flips a checkbox")
fpp("toggle Host")
eq(host.enabled, false, "commands: /fpp toggle <module> turns it off")
core.SetOption("Plain", "loud", true)
core.ApplyPreset()
eq(plain.db.loud == false and plain.db.mode == "a", true, "commands: preset resets options")
eq(registered("PLAYER_MONEY") or not registered("BAG_UPDATE"), false,
    "commands: preset tells the module")
eq(host.enabled, true, "commands: preset turns default-on modules back on")
local said, ran = nil, false
core.Print = function(text) said = text end
core.AddCommand("ping", "", "test", function() ran = true end, "Plain")
core.SetEnabled("Plain", false)
fpp("ping")
eq(not ran and said ~= nil and said:find("/fpp ping", 1, true) ~= nil, true,
    "commands: a command whose module is off says so")
core.SetEnabled("Plain", true)
fpp("ping")
eq(ran, true, "commands: and runs once it's on")
