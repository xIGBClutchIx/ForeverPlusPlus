-- What's in the player's bags: walking every slot, counting the free ones, and finding the gray
-- stack worth least. One place for which bags there are, so a build that moves a bag index is
-- fixed here. The buttons Blizzard draws for them are Lib/ItemButtons.lua's.
local _, ns = ...

local type = type
local C_Container = C_Container

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

-- Whether a bag takes anything, so emptying a slot in it makes room for any loot.
local function ordinary(bag)
    local _, family = C_Container.GetContainerNumFreeSlots(bag)
    return family == nil or family == 0
end

---The gray stack in the ordinary bags worth least to a vendor, the whole stack counted: its bag,
---slot, item info, and value in copper. Only Poor quality items a vendor buys, not locked, and
---with a price `price(link)` knows; never the reagent bag or a bag that takes only its own kind.
---The first of equal ones wins. Nil when there's none.
---@param price fun(link: string): number|nil a vendor's price for one, such as ns.Prices.Vendor
---@return number|nil bag
---@return number|nil slot
---@return table|nil info
---@return number|nil value
function Bags.CheapestJunk(price)
    local poor = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0
    local best, bestBag, bestSlot, bestInfo
    local skip = {} -- bag -> true for a bag that takes only its own kind
    Bags.Each(function(bag, slot, info)
        if skip[bag] == nil then
            skip[bag] = not ordinary(bag)
        end
        if skip[bag] or not info or info.quality ~= poor or info.hasNoValue or info.isLocked
            or not info.hyperlink then
            return
        end
        local each = price(info.hyperlink)
        if type(each) ~= "number" or each <= 0 then
            return
        end
        local value = each * (info.stackCount or 1)
        if not best or value < best then
            best, bestBag, bestSlot, bestInfo = value, bag, slot, info
        end
    end)
    if not best then
        return nil
    end
    return bestBag, bestSlot, bestInfo, best
end
