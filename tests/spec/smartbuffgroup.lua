-- Smart Buff's Buff Your Group: whom in the group the macro buffs next, and when with a buff's group
-- version. The module's own rules file is loaded onto a stand-in Macros module, so these are its
-- real rules; nothing here needs a group or a frame.
local T = ...
local ns, eq, same = T.ns, T.eq, T.same

local internal = {}
ns.modules = { Macros = { internal = internal } }
T.load("Modules/Character/Macros/SmartBuffGroup", ns)
local plan = internal.PlanGroup

-- Buffs as Data/Buffs.lua has them, with what matters here.
local fort = { id = 1, reach = "all" }
local spirit = { id = 2, reach = "all" }
local kings = { id = 3, reach = "class" }
local might = { id = 4, reach = "class" }
local inner = { id = 5 } -- yours alone, no group version

local function yes() return true end
local function no() return false end

local function member(entry, class, ready)
    return { entry = entry, class = class or "WARRIOR", ready = ready ~= false and entry ~= nil }
end

-- Single casts -----------------------------------------------------------------------------------

local index, wide = plan({ member(nil), member(nil) }, 3, yes)
eq(index, nil, "group: nobody needs anything: nothing")
eq(wide, false, "group: nobody needs anything: no group version")

index, wide = plan({ member(inner, "PRIEST"), member(fort) }, 3, yes)
eq(index, 1, "group: you first")
eq(wide, false, "group: one missing: single")

index = plan({ member(nil, "PRIEST"), member(fort, "MAGE", false), member(fort) }, 3, yes)
eq(index, 3, "group: out of range skipped")

-- Group versions ----------------------------------------------------------------------------------

local priests = {
    member(inner, "PRIEST"), member(fort, "MAGE"), member(fort, "ROGUE"), member(fort, "WARRIOR"),
}
index, wide = plan(priests, 3, yes)
eq(index, 2, "group: three missing: the first of them")
eq(wide, true, "group: three missing: group version")

index, wide = plan(priests, 4, yes)
eq(index, 1, "group: below the minimum: you first, single")
eq(wide, false, "group: below the minimum: single")

index, wide = plan(priests, nil, yes)
eq(wide, false, "group: Group Buffs off: single")
index, wide = plan(priests, 0, yes)
eq(wide, false, "group: a minimum of 0: single")

index, wide = plan(priests, 3, no)
eq(wide, false, "group: can't cast it (no reagent): single")
eq(index, 1, "group: can't cast it: you first")

local _, _, wideFor = plan(priests, 3, yes)
same(wideFor, { [2] = true, [3] = true, [4] = true }, "group: every member it reaches")

-- Out of range members don't count toward the minimum.
index, wide = plan({ member(fort, "MAGE"), member(fort, "ROGUE"), member(fort, "WARRIOR", false) }, 3, yes)
eq(wide, false, "group: one out of range: below the minimum")

-- The buff with the most missing it wins; a tie goes to the earliest.
index, wide = plan({
    member(spirit, "MAGE"), member(spirit, "PRIEST"),
    member(fort, "ROGUE"), member(fort, "WARRIOR"), member(fort, "WARRIOR"),
}, 2, yes)
eq(index, 3, "group: the buff most are missing")
eq(wide, true, "group: the buff most are missing: group version")
index = plan({ member(spirit, "MAGE"), member(spirit, "PRIEST"), member(fort), member(fort) }, 2, yes)
eq(index, 1, "group: a tie: the earliest")

-- Only the buffs whose group version can be cast now.
index, wide = plan({ member(spirit, "MAGE"), member(spirit, "PRIEST"), member(fort), member(fort),
    member(fort) }, 2, function(entry) return entry == spirit end)
eq(index, 1, "group: only Spirit's can be cast")
eq(wide, true, "group: only Spirit's can be cast: its group version")

-- A class's group version ------------------------------------------------------------------------

index, wide = plan({ member(nil, "PALADIN"), member(kings, "WARRIOR"), member(kings, "WARRIOR"),
    member(kings, "MAGE") }, 2, yes)
eq(index, 2, "group: two Warriors missing Kings")
eq(wide, true, "group: two Warriors missing Kings: the Greater one")

index, wide = plan({ member(nil, "PALADIN"), member(kings, "WARRIOR"), member(kings, "MAGE"),
    member(kings, "ROGUE") }, 2, yes)
eq(wide, false, "group: one of each class: single")

-- A Warrior who'd get Might instead, or who needs nothing (has your Might), would lose it.
index, wide = plan({ member(kings, "WARRIOR"), member(kings, "WARRIOR"), member(might, "WARRIOR") },
    2, yes)
eq(wide, false, "group: a Warrior getting another Blessing: single")
index, wide = plan({ member(kings, "WARRIOR"), member(kings, "WARRIOR"), member(nil, "WARRIOR") },
    2, yes)
eq(wide, false, "group: a Warrior needing nothing: single")
-- An out of range Warrior getting the same still allows it, but doesn't count.
index, wide = plan({ member(kings, "WARRIOR"), member(kings, "WARRIOR"),
    member(kings, "WARRIOR", false) }, 3, yes)
eq(wide, false, "group: out of range Warrior: not counted")
index, wide = plan({ member(kings, "WARRIOR"), member(kings, "WARRIOR"),
    member(kings, "WARRIOR", false) }, 2, yes)
eq(wide, true, "group: out of range Warrior getting the same: allowed")
-- A class that couldn't be read never gets a class's group version.
local unknown = { entry = kings, ready = true }
index, wide = plan({ unknown, { entry = kings, ready = true } }, 2, yes)
eq(wide, false, "group: unknown class: single")
eq(index, 1, "group: unknown class: the first")
