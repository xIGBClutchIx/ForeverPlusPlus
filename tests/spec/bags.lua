-- Bags: walking every slot of the player's bags, and counting the free ones.
local T = ...
local ns, eq, same = T.ns, T.eq, T.same

-- Bag 0 has three slots (the second empty), bag 1 one, bag 4 none, the reagent bag (5) two.
local slots = {
    [0] = { { itemID = 10 }, false, { itemID = 12 } },
    [1] = { { itemID = 20 } },
    [5] = { { itemID = 50 }, { itemID = 51 } },
}
-- Free slots and the kind of thing each bag takes: bag 2 is a quiver, bag 3 gives no answer.
local free = { [0] = { 4, 0 }, [1] = { 2 }, [2] = { 9, 1 }, [4] = { 1, 0 }, [5] = { 7, 0 } }
C_Container = {
    GetContainerNumSlots = function(bag) return slots[bag] and #slots[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot) return slots[bag][slot] or nil end,
    GetContainerNumFreeSlots = function(bag)
        local entry = free[bag]
        if entry then
            return entry[1], entry[2]
        end
    end,
}
T.load("Lib/Bags", ns)
local Bags = ns.Bags

local function walk(reagent)
    local seen = {}
    Bags.Each(function(bag, slot, info)
        seen[#seen + 1] = bag .. ":" .. slot .. ":" .. (info and info.itemID or "empty")
    end, reagent)
    return seen
end
same(walk(), { "0:1:10", "0:2:empty", "0:3:12", "1:1:20" }, "bags: every slot of the bags, empty ones too")
same(walk(true), { "0:1:10", "0:2:empty", "0:3:12", "1:1:20", "5:1:50", "5:2:51" },
    "bags: and the reagent bag when asked")

local visited = 0
local bag, slot, id = Bags.Each(function(b, s, info)
    visited = visited + 1
    if info and info.itemID == 12 then
        return b, s, info.itemID
    end
end)
same({ bag, slot, id }, { 0, 3, 12 }, "bags: the walk returns what stopped it")
eq(visited, 3, "bags: and stops there")
eq(Bags.Each(function() end), nil, "bags: a walk nothing stops returns nil")

-- The backpack's 4, bag 1's 2 (no family is an ordinary bag), bag 4's 1; not the quiver's 9, the
-- bag that gave no answer, or the reagent bag's 7.
eq(Bags.FreeSlots(), 7, "bags: free slots in the bags that take anything")

eq(Bags.REAGENT, 5, "bags: the reagent bag without Enum.BagIndex")
C_Container = nil
T.load("Lib/Bags", ns)
eq(ns.Bags.Each(function() return true end), nil, "bags: no walk on a client without C_Container")
