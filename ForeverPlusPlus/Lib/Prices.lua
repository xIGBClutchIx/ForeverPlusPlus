-- Auction prices for any module: Item Tooltips' Auction Prices scans the auction house and gives
-- its prices here while it's on, and other modules (Waylaid Crates) read them without reaching
-- into it. With no source, there are no prices.
local _, ns = ...

local C_Item = C_Item

local Prices = {}
ns.Prices = Prices

local source -- { price = fn(itemID), itemByName = fn(name), inline = fn() }, or nil

---Sets where auction prices come from, or nil when there are none (Auction Prices is off).
---@param new table|nil { price = fun(itemID): number?, itemByName = fun(name): number?, inline = fun(): boolean }
function Prices.SetSource(new)
    source = new
end

---Whether auction prices are available.
---@return boolean
function Prices.Available()
    return source ~= nil
end

---The lowest auction buyout for one of an item, in copper, or nil.
---@param itemID number
---@return number|nil
function Prices.Auction(itemID)
    return source and source.price(itemID) or nil
end

---An item's ID from its name: from the client's item cache, or else among the items with an
---auction price. Nil when neither knows it.
---@param name string
---@return number|nil
function Prices.ItemByName(name)
    local id = C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(name)
    if id then
        return id
    end
    return source and source.itemByName(name) or nil
end

---Whether price lines go right after their label instead of at the tooltip's right edge, as
---the player set it for Item Tooltips.
---@return boolean
function Prices.Inline()
    return source and source.inline() or false
end
