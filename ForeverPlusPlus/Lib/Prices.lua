-- Auction prices for any module: Item Tooltips' Auction Prices scans the auction house and gives
-- its prices here while it's on, and other modules (Waylaid Crates) read them without reaching
-- into it. With no source, there are no prices.
local _, ns = ...

local C_Item = C_Item
local floor, format, tonumber, type = math.floor, string.format, tonumber, type

local Prices = {}
ns.Prices = Prices

-- Saved prices ------------------------------------------------------------------------------------
-- A saved price is one short string, "copper,minutes", with the minutes since EPOCH it was seen:
-- thousands of them are saved, and a table each took three times the room in the saved file.

local EPOCH = 1700000000 -- 2023-11-14, before any price was saved

---A price and the time it was seen as the string saved for it.
---@param copper number
---@param seenAt number time()
---@return string
function Prices.Pack(copper, seenAt)
    return format("%d,%d", floor(copper + 0.5), floor((seenAt - EPOCH) / 60))
end

---The price and the time (to the minute) a saved string holds, or nil for none.
---@param saved string|nil
---@return number|nil copper
---@return number|nil seenAt
function Prices.Unpack(saved)
    if type(saved) ~= "string" then
        return nil
    end
    local copper, minutes = saved:match("^(%d+),(%-?%d+)$")
    if not copper then
        return nil
    end
    return tonumber(copper), EPOCH + tonumber(minutes) * 60
end

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
