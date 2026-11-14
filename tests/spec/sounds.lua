-- Sounds: the Sound dropdown's choices and playing the one picked.
local T = ...
local ns, eq = T.ns, T.eq

local played = {}
SOUNDKIT = { RAID_WARNING = 8959 }
PlaySound = function(id, channel)
    played[#played + 1] = id .. ":" .. channel
end
T.load("Lib/Sounds")
local Sounds = ns.Sounds

eq(Sounds.CHOICES[1][1], "off", "sounds: Off comes first")
local named = true
for _, choice in ipairs(Sounds.CHOICES) do
    named = named and type(choice[2]) == "string"
end
eq(named, true, "sounds: every choice has a name")

-- The dropdown every module's Sound option is.
local option = Sounds.Option("sound", "what it's for", { added = "1.0.0" })
eq(option.key .. ":" .. option.name .. ":" .. option.added, "sound:" .. ns.L.SOUND_NAME .. ":1.0.0",
    "option: named Sound, with what the module adds")
eq(option.choices, Sounds.CHOICES, "option: every choice, Off among them")
local under = Sounds.Option("kind", "which", { requires = "sound", name = "Entering Sound" })
eq(under.name, "Entering Sound", "option: a name of its own when given")
eq(under.choices[1][1] ~= "off" and #under.choices, #Sounds.CHOICES - 1,
    "option: no Off under a checkbox that already turns it off")

Sounds.Play("raidwarning")
eq(played[1], "8959:Master", "sounds: plays on the Master channel")
Sounds.Play("off")
Sounds.Play("gm") -- not in this client's SOUNDKIT
Sounds.Play(nil)
eq(#played, 1, "sounds: nothing for off, a missing kit, or nil")
