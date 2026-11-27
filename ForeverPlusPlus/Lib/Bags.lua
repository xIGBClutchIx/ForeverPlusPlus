-- What's in the player's bags: walking every slot, counting the free ones, and how many more of
-- an item fit. One place for which bags there are, so a build that moves a bag index is fixed
-- here. The buttons Blizzard draws for them are Lib/ItemButtons.lua's.
local _, ns = ...

local type, bit = type, bit
local C_Container, C_Item = C_Container, C_Item

local Bags = {}
ns.Bags = Bags

---The last of the player's ordinary bags: the backpack is 0, then four bags.
Bags.LAST = 4

---The reagent bag, which holds only reagents and profession tools. Probe: Enum.BagIndex is
---Mainline's; 5 is the slot after the four bags.
Bags.REAGENT = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or 5

---Calls `fn(bag, slot, info)` for every slot of the backpack and the four bags, and with
---`reagent` the reagent bag too. `info` is C_Container.GetContainerItemInfo's table, nil for an
---empty slot. A walk stops at the first `fn` that returns something, and returns what it did.
---@param fn function fn(bag, slot, info), returning nothing to go on
---@param reagent? boolean
---@return any ...
function Bags.Each(fn, reagent)
    if not (C_Container and C_Container.GetContainerNumSlots) then
        return nil
    end
    for bag = 0, reagent and Bags.REAGENT or Bags.LAST do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local a, b, c, d = fn(bag, slot, C_Container.GetContainerItemInfo(bag, slot))
            if a ~= nil then
                return a, b, c, d
            end
        end
    end
    return nil
end

---How many slots are free in the bags that take anything. A quiver or a herb bag takes only its
---own kind (its family isn't 0), so its free slots don't count, nor do the reagent bag's.
---@return number
function Bags.FreeSlots()
    local free = 0
    for bag = 0, Bags.LAST do
        local slots, family = C_Container.GetContainerNumFreeSlots(bag)
        if type(slots) == "number" and (family == nil or family == 0) then
            free = free + slots
        end
    end
    return free
end

---How many more of an item fit in the bags: what its own stacks there have room for, and a full
---stack in each free slot of a bag that takes it, one that takes anything or one of its own kind
---(arrows in a quiver). The reagent bag isn't counted, so it may say less than fits, never more.
---@param itemID number
---@param stackSize number how many make a full stack of it
---@return number
function Bags.Room(itemID, stackSize)
    if not (C_Container and C_Container.GetContainerNumFreeSlots) then
        return 0
    end
    local family = C_Item and C_Item.GetItemFamily and C_Item.GetItemFamily(itemID)
    family = type(family) == "number" and family or 0
    local room = 0
    for bag = 0, Bags.LAST do
        local slots, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
        local takes = bagFamily == nil or bagFamily == 0
            or (family ~= 0 and bit and bit.band(family, bagFamily) ~= 0)
        if takes then
            room = room + (type(slots) == "number" and slots or 0) * stackSize
            for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID == itemID and not info.isLocked and (info.stackCount or 0) < stackSize then
                    room = room + stackSize - (info.stackCount or 0)
                end
            end
        end
    end
    return room
end
