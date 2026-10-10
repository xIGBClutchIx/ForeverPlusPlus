-- Item Tooltips' item count: how many of an item you own, just above the prices: the total,
-- then how many are in your bags and in your bank in gray, with Blizzard's bag and bank icons
-- (or words).
--
-- Bags are counted live. The bank is counted while it's open and kept per character, since the
-- bank's contents only change at the bank. Before a character has opened the bank, the client's
-- own bank count is used, which may be nothing until then.
local _, ns = ...

local _G, pairs, format, strfind, tconcat = _G, pairs, string.format, string.find, table.concat
local C_Item, C_Container, C_Texture, C_Timer, C_EventUtils = C_Item, C_Container, C_Texture, C_Timer,
    C_EventUtils
local Enum = Enum
local UnitName, GetRealmName, GetFileIDFromPath = UnitName, GetRealmName, GetFileIDFromPath
local GRAY_FONT_COLOR = GRAY_FONT_COLOR

local L = ns.L
local ItemTooltip = ns.ItemTooltip

local module = ns.modules.ItemTooltips
local internal = module.internal

-- Icons ----------------------------------------------------------------------------------------
-- Blizzard's own art at the text's height: an atlas when the client has it, else a texture file
-- the client has, else none (and the words show instead).

local function iconMarkup(atlas, file)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        return format("|A:%s:0:0|a", atlas)
    end
    if not GetFileIDFromPath or GetFileIDFromPath(file) then
        return format("|T%s:0|t", file)
    end
end

local icons -- { bags = markup|false, bank = markup|false }, found once

local function icon(place)
    if not icons then
        icons = {
            bags = iconMarkup("bag-main", "Interface\\Buttons\\Button-Backpack-Up") or false,
            bank = iconMarkup("Banker", "Interface\\Minimap\\Tracking\\Banker") or false,
        }
    end
    return icons[place]
end

-- Bank -----------------------------------------------------------------------------------------

-- The bank's bag ids: every Enum.BagIndex with "Bank" in its name, except the account (warband)
-- bank, which isn't this character's. Mainline renamed these over time (Bank and BankBag_1..7,
-- then CharacterBankTab_1..6), so they're found by name instead of listed.
local bankBags

local function bankBagIDs()
    if not bankBags then
        bankBags = {}
        local index = Enum and Enum.BagIndex
        if index then
            for name, id in pairs(index) do
                if strfind(name, "[Bb]ank") and not strfind(name, "Account") then
                    bankBags[#bankBags + 1] = id
                end
            end
        else
            bankBags[1] = -1 -- BANK_CONTAINER
        end
    end
    return bankBags
end

local function characterKey()
    -- UnitName's second value is a surname on Forever, not a realm.
    return format("%s-%s", GetRealmName() or "", (UnitName("player")) or "")
end

local bankOpen = false

-- Counts everything in the bank and keeps it for this character.
local function scanBank()
    if not (bankOpen and C_Container and C_Container.GetContainerNumSlots) then
        return
    end
    local counts = {}
    for _, bag in pairs(bankBagIDs()) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local id = info and info.itemID
            if id and ns.IsReadable(id) then
                counts[id] = (counts[id] or 0) + (info.stackCount or 1)
            end
        end
    end
    module.db.banks[characterKey()] = counts
end

local scanQueued = false

-- Many slots change at once when items move; one scan on the next frame covers them all.
local function queueScan()
    if scanQueued or not bankOpen then
        return
    end
    scanQueued = true
    C_Timer.After(0, function()
        scanQueued = false
        if internal.Active("itemCount") then
            scanBank()
        end
    end)
end

local function onBankOpened()
    bankOpen = true
    queueScan()
end

local function onBankClosed()
    bankOpen = false
end

-- How many are in the bank: counted live while it's open, else what was kept, else what the
-- client says (nothing kept yet for this character).
local function bankCount(id, bags)
    local kept = module.db.banks[characterKey()]
    if kept and not bankOpen then
        return kept[id] or 0
    end
    local all = C_Item.GetItemCount(id, true, false, true)
    return all and all > bags and all - bags or 0
end

-- Tooltip --------------------------------------------------------------------------------------

local function part(place, count, db)
    local mark = db.labels == "icons" and icon(place)
    if mark then
        return format(L.ITEMCOUNT_ICON_COUNT, mark, count)
    end
    return format(place == "bags" and L.ITEMCOUNT_IN_BAGS or L.ITEMCOUNT_IN_BANK, count)
end

-- "Owned: 45 (bag 30  bank 15)": the total in white, where they are in gray. With all of them in
-- one place, just that place and its count.
local function addCount(tooltip, data)
    local id = internal.Active("itemCount") and ItemTooltip.ItemID(data)
    if not (id and C_Item.GetItemCount) then
        return
    end
    local db = module.db
    local bags = C_Item.GetItemCount(id) or 0
    local bank = db.bank and bankCount(id, bags) or 0
    local total = bags + bank
    if total <= 0 then
        return
    end
    local text
    if bags > 0 and bank > 0 then
        local where = tconcat({ part("bags", bags, db), part("bank", bank, db) }, L.ITEMCOUNT_SEPARATOR)
        text = format(L.ITEMCOUNT_TOTAL, total, GRAY_FONT_COLOR:WrapTextInColorCode(format(L.ITEMCOUNT_WHERE, where)))
    else
        text = part(bags > 0 and "bags" or "bank", total, db)
    end
    ItemTooltip.AddInfo(tooltip, L.ITEMCOUNT_LINE, text, db.align, "white")
end

local events = {
    BANKFRAME_OPENED = onBankOpened,
    BANKFRAME_CLOSED = onBankClosed,
    BAG_UPDATE_DELAYED = queueScan,
}
-- The bank's own slots (not its bags) say so with these, where the client still has them.
for _, event in pairs({ "PLAYERBANKSLOTS_CHANGED", "PLAYERREAGENTBANKSLOTS_CHANGED" }) do
    events[event] = queueScan
end

internal.AddPart("itemCount", {
    enable = function()
        for event, fn in pairs(events) do
            -- Probe: registering an event the client doesn't know is an error.
            if not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event) then
                ns.On(event, fn)
            end
        end
        -- Turned on at the bank: count it now. Probe: BankFrame is Blizzard's bank window.
        local bankFrame = _G.BankFrame
        bankOpen = bankFrame and bankFrame:IsShown() or false
        queueScan()
        -- The hook can't be removed; addCount checks the part is on instead.
        ItemTooltip.OnInfo(addCount)
    end,
    disable = function()
        for event, fn in pairs(events) do
            ns.Off(event, fn)
        end
        bankOpen = false
    end,
})
