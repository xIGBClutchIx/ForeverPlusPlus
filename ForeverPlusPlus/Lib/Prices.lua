-- Auction prices for any module: Item Tooltips' Auction Prices scans the auction house and gives
-- its prices here while it's on, and other modules (Waylaid Crates) read them without reaching
-- into it. With no source, there are no prices.
local _, ns = ...

local C_Item = C_Item
local floor, format, tonumber, type, pairs = math.floor, string.format, tonumber, type, pairs

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

---Brings one auction house's saved prices to the packed form, for a migration: items saved as
---{ price, seenAt } tables (0.7.0 to 0.8.4), and `prices` saved before 0.7.0 with only the house's
---scan time, which become items seen at that scan.
---@param house table { scannedAt, items, prices }
function Prices.PackHouse(house)
    if type(house) ~= "table" then
        return
    end
    local items = type(house.items) == "table" and house.items or {}
    for itemID, item in pairs(items) do
        if type(item) == "table" and type(item.price) == "number" and type(item.seenAt) == "number" then
            items[itemID] = Prices.Pack(item.price, item.seenAt)
        elseif type(item) ~= "string" then
            items[itemID] = nil
        end
    end
    -- Without a scan time there's no age to give them, so they go rather than show as decades old.
    local scannedAt = house.scannedAt
    if type(house.prices) == "table" and type(scannedAt) == "number" and scannedAt > 0 then
        for itemID, copper in pairs(house.prices) do
            if items[itemID] == nil and type(copper) == "number" then
                items[itemID] = Prices.Pack(copper, scannedAt)
            end
        end
    end
    house.prices = nil
    house.items = items
    house.scannedAt = house.scannedAt or 0
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
