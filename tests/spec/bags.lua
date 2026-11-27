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

-- The cheapest gray stack: bag 0 has gray 100 (2 at 30c, 60c) and gray 101 (1 at 40c), a white
-- 102 worth 1c, a gray 103 a vendor won't buy, a locked gray 104, and a gray 105 with no price
-- known; the quiver (bag 2) has a gray 106 worth 1c, the reagent bag a gray 107 worth 1c.
local function gray(id, count, extra)
    local info = { itemID = id, quality = 0, stackCount = count, hyperlink = "item:" .. id }
    for k, v in pairs(extra or {}) do
        info[k] = v
    end
    return info
end
slots = {
    [0] = {
        gray(100, 2), gray(101, 1), gray(102, 1, { quality = 1 }), gray(103, 1, { hasNoValue = true }),
        gray(104, 1, { isLocked = true }), gray(105, 1), false,
    },
    [2] = { gray(106, 1) },
    [5] = { gray(107, 1) },
}
local prices = { ["item:100"] = 30, ["item:101"] = 40, ["item:102"] = 1, ["item:103"] = 1, ["item:104"] = 1,
    ["item:106"] = 1, ["item:107"] = 1 }
local function price(link) return prices[link] end
local junkBag, junkSlot, junkInfo, junkValue = Bags.CheapestJunk(price)
same({ junkBag, junkSlot, junkInfo and junkInfo.itemID, junkValue }, { 0, 2, 101, 40 },
    "bags: the cheapest gray stack counts the whole stack, and skips white, no-value, locked, and unpriced")
prices["item:100"] = 20
junkBag, junkSlot, junkInfo, junkValue = Bags.CheapestJunk(price)
same({ junkBag, junkSlot, junkValue }, { 0, 1, 40 }, "bags: the first of equal stacks wins")
slots = { [0] = { gray(102, 1, { quality = 1 }) }, [2] = { gray(106, 1) }, [5] = { gray(107, 1) } }
eq(Bags.CheapestJunk(price), nil, "bags: no junk in the ordinary bags, none outside them counted")

eq(Bags.REAGENT, 5, "bags: the reagent bag without Enum.BagIndex")

-- Room for an item of 20 a stack: bag 0 holds 15 of item 10 and a locked 5 of it, bag 1 a full
-- 20, bag 2 is a quiver with 3 free, and the reagent bag has 15 of it and 6 free.
slots = {
    [0] = { { itemID = 10, stackCount = 15 }, { itemID = 10, stackCount = 5, isLocked = true }, false },
    [1] = { { itemID = 10, stackCount = 20 }, { itemID = 11, stackCount = 1 } },
    [2] = { false, false, false },
    [5] = { { itemID = 10, stackCount = 15 } },
}
free = { [0] = { 1, 0 }, [1] = { 0, 0 }, [2] = { 3, 1 }, [5] = { 6, 0 } }
local families = { [10] = 0, [30] = 1 } -- item 30 is arrows, which a quiver (family 1) takes
local hadItem = C_Item
C_Item = { GetItemFamily = function(id) return families[id] end }
local hadBit = bit
bit = bit or { band = function(a, b) return (a == 1 and b == 1) and 1 or 0 end }
T.load("Lib/Bags", ns)
Bags = ns.Bags
-- 5 more in the stack of 15 and 20 in the free slot; not the locked stack's, the quiver's, or the
-- reagent bag's.
eq(Bags.Room(10, 20), 25, "bags: room for an item, its stacks and the free slots of bags that take anything")
eq(Bags.Room(30, 200), 800, "bags: and a quiver's free slots for arrows")
eq(Bags.Room(99, 1), 1, "bags: an item of one a stack fits once a free slot")
bit = hadBit
C_Item = hadItem

C_Container = nil
T.load("Lib/Bags", ns)
eq(ns.Bags.Each(function() return true end), nil, "bags: no walk on a client without C_Container")
