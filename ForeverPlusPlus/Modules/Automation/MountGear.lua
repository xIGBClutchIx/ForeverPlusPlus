-- Mount Speed Gear: when you mount up, gear from your bags that makes the mount faster goes on
-- (Carrot on a Stick, gloves enchanted with Riding Skill, boots with Mithril Spurs), and when you
-- get off, the gear it replaced goes back on.
--
-- Each change is a swap of a bag slot with an inventory slot (Blizzard's equipment manager does the
-- same: pick up the bag item, then the inventory slot), so the worn item lands where the other
-- came from and full bags don't matter. What it replaced is remembered for the character, by item,
-- enchant, gems, and suffix (not the whole link, whose level field changes on a level up), so a
-- reload or logout while mounted still puts the right item back. The record is dropped when the
-- slot no longer holds what we put there (the player or an equipment set changed it), and when the
-- item to put back isn't in the bags any more (sold or banked), which it says in chat.
--
-- Gear can't change in combat, so a change waits for combat to end (ns.AfterCombat). Nothing
-- changes while dead, on a flight, or casting; the events below bring it back. A druid's Travel
-- Form isn't a mount (IsMounted says no), so it changes nothing. Only gear already bound to the
-- player is put on, since unbound gear would ask first.
local _, ns = ...

local pairs, select, type, tonumber, format, concat = pairs, select, type, tonumber, string.format, table.concat
local IsMounted, CursorHasItem, GetCursorInfo, ClearCursor = IsMounted, CursorHasItem, GetCursorInfo, ClearCursor
local PickupInventoryItem, IsInventoryItemLocked = PickupInventoryItem, IsInventoryItemLocked
local C_Container, C_Item, C_PaperDollInfo = C_Container, C_Item, C_PaperDollInfo

local L = ns.L

local module = ns.NewModule("MountGear", L.MOUNTGEAR_DESC, {
    enabled = false,
    trinket = true,
    trinketSlot = "14", -- the inventory slot Carrot on a Stick goes in: "13" upper, "14" lower
    gloves = true,
    boots = true,
    instances = false,
    chat = true,
    -- What we put on, by inventory slot, for this character: { put = key of the item we put on,
    -- back = key of the item it replaced (false for an empty slot), link = that item's link }.
    -- Data, not a setting.
    worn = {},
})
module.perCharacter = { worn = true }
module.title = L.MOUNTGEAR_TITLE
module.category = "automation"
module.added = "1.10.0"
-- The game's rules, not ours; a notice with no button.
module.notice = { text = L.MOUNTGEAR_NOTICE, description = L.MOUNTGEAR_NOTICE_DESC }

module.options = {
    { key = "trinket", name = L.MOUNTGEAR_TRINKET, description = L.MOUNTGEAR_TRINKET_DESC },
    {
        key = "trinketSlot", name = L.MOUNTGEAR_TRINKET_SLOT, description = L.MOUNTGEAR_TRINKET_SLOT_DESC,
        requires = "trinket",
        choices = {
            { "13", L.MOUNTGEAR_TRINKET_UPPER },
            { "14", L.MOUNTGEAR_TRINKET_LOWER },
        },
    },
    { key = "gloves", name = L.MOUNTGEAR_GLOVES, description = L.MOUNTGEAR_GLOVES_DESC },
    { key = "boots", name = L.MOUNTGEAR_BOOTS, description = L.MOUNTGEAR_BOOTS_DESC },
    { key = "instances", name = L.MOUNTGEAR_INSTANCES, description = L.MOUNTGEAR_INSTANCES_DESC },
    ns.ChatOption(L.MOUNTGEAR_CHAT_DESC),
}

local TRINKETS = ns.GameData.New("mountSpeedTrinkets", ns.Data.mountSpeedTrinkets,
    { kind = "item", label = "Mount Speed Gear trinkets" })
local ENCHANTS = ns.GameData.New("mountSpeedEnchants", ns.Data.mountSpeedEnchants,
    { label = "Mount Speed Gear enchants" })

local HANDS, FEET, TRINKET1, TRINKET2 = 10, 8, 13, 14
local RETRY = 0.5 -- seconds before trying again after a locked item or a cast

function module:IsAvailable()
    return IsMounted and PickupInventoryItem and C_Container and C_Container.PickupContainerItem
        and C_Item and C_Item.GetItemInfoInstant and true or false
end

-- Items ---------------------------------------------------------------------------------------

-- A link's fields after "item:", empty ones kept, or nil for something that isn't an item link.
local function fields(link)
    local body = ns.IsText(link, true) and link:match("item:([^|]+)")
    if not body then
        return nil
    end
    local out = {}
    for value in (body .. ":"):gmatch("([^:]*):") do
        out[#out + 1] = value
    end
    return out
end

-- Which item this is, the same however it's linked and whatever level the character is: the item,
-- its enchant, gems, and suffix.
local function itemKey(link)
    local parts = fields(link)
    if not parts then
        return nil
    end
    local key = {}
    for i = 1, 7 do
        local value = parts[i]
        key[i] = (value == nil or value == "") and "0" or value
    end
    return concat(key, ":")
end

-- Whether a link is mount speed gear for this inventory slot.
local function isMountGear(link, slot)
    local parts = fields(link)
    if not parts then
        return false
    end
    if slot == TRINKET1 or slot == TRINKET2 then
        return TRINKETS:Get(tonumber(parts[1])) == true
    end
    local enchant = tonumber(parts[2])
    local equipLoc = enchant and select(4, C_Item.GetItemInfoInstant(link))
    local wanted = enchant and ENCHANTS:Get(enchant)
    return wanted ~= nil and wanted == equipLoc and (slot == HANDS and equipLoc == "INVTYPE_HAND"
        or slot == FEET and equipLoc == "INVTYPE_FEET")
end

-- The first bag slot whose item passes `test(link)`: bag, slot, link, and whether it's locked.
local function findInBags(test)
    return ns.Bags.Each(function(bag, slot, info)
        local link = info and info.hyperlink
        if ns.IsText(link, true) and test(link) then
            -- Unbound gear would ask before it's worn; leave it.
            if info.isBound == false then
                return nil
            end
            return bag, slot, link, ns.IsTrueOrSecret(info.isLocked)
        end
    end)
end

-- A free slot in a bag that takes anything: bag, slot.
local function freeSlot()
    return ns.Bags.Each(function(bag, slot, info)
        if info == nil then
            local _, family = C_Container.GetContainerNumFreeSlots(bag)
            if family == nil or family == 0 then
                return bag, slot
            end
        end
    end)
end

-- Swaps the item in a bag slot with what's worn in an inventory slot. False when the client
-- wouldn't (the item can't go there, or one of them is locked), with the cursor left empty.
local function swap(bag, bagSlot, invSlot)
    C_Container.PickupContainerItem(bag, bagSlot)
    if not CursorHasItem() then
        return false
    end
    local fits = not C_PaperDollInfo or not C_PaperDollInfo.CursorCanGoInSlot
        or ns.IsTrue(C_PaperDollInfo.CursorCanGoInSlot(invSlot))
    if not fits or ns.IsTrueOrSecret(IsInventoryItemLocked(invSlot)) then
        ClearCursor()
        return false
    end
    PickupInventoryItem(invSlot)
    if CursorHasItem() then
        ClearCursor()
    end
    return true
end

-- Putting on and taking off -------------------------------------------------------------------

local retry = ns.Frames.Timer(module)
local MAX_TRIES = 10
local tries = 0 -- retries after a lock since the last event
local afterCombat = false -- a run is waiting for combat to end
local update

-- Puts mount speed gear on in `slot`. True when something was locked, to try again.
local function putOn(slot)
    local worn = ns.Equipment.Worn(slot)
    if worn and isMountGear(worn, slot) then
        return false -- already on, ours or the player's
    end
    local other = slot == TRINKET1 and TRINKET2 or slot == TRINKET2 and TRINKET1 or nil
    local otherWorn = other and ns.Equipment.Worn(other)
    if otherWorn and isMountGear(otherWorn, other) then
        return false -- the other trinket slot has it
    end
    local bag, bagSlot, link, locked = findInBags(function(candidate)
        return isMountGear(candidate, slot)
    end)
    if not bag then
        return false
    elseif locked or ns.IsTrueOrSecret(IsInventoryItemLocked(slot)) then
        return true
    end
    if not swap(bag, bagSlot, slot) then
        return false -- the client won't put it there (a level or skill it needs): leave it
    end
    module.db.worn[slot] = { put = itemKey(link), back = worn and itemKey(worn) or false, link = worn }
    return false
end

-- Puts back what mount speed gear replaced in `slot`. True when something was locked.
local function takeOff(slot)
    local record = module.db.worn[slot]
    if type(record) ~= "table" then
        module.db.worn[slot] = nil
        return false
    end
    local worn = ns.Equipment.Worn(slot)
    if not worn or itemKey(worn) ~= record.put then
        module.db.worn[slot] = nil -- changed since; what's worn now is the player's choice
        return false
    end
    if ns.IsTrueOrSecret(IsInventoryItemLocked(slot)) then
        return true
    end
    if record.back == false then
        -- The slot was empty: the gear goes into the bags.
        local bag, bagSlot = freeSlot()
        if not bag then
            module.db.worn[slot] = nil
            module:Print(format(L.MOUNTGEAR_BAGS_FULL, worn))
            return false
        end
        PickupInventoryItem(slot)
        if not CursorHasItem() then
            return false -- refused: it stays remembered for the next try
        end
        C_Container.PickupContainerItem(bag, bagSlot)
        if CursorHasItem() then
            ClearCursor() -- refused too
        else
            module.db.worn[slot] = nil
        end
        return false
    end
    local bag, bagSlot, _, locked = findInBags(function(candidate)
        return itemKey(candidate) == record.back
    end)
    if not bag then
        module.db.worn[slot] = nil
        module:Print(format(L.MOUNTGEAR_MISSING, ns.IsText(record.link, true) and record.link or record.back))
        return false
    elseif locked then
        return true
    end
    -- Refused, it stays remembered for the next try (the next mount, reload, or flight's end).
    if swap(bag, bagSlot, slot) then
        module.db.worn[slot] = nil
    end
    return false
end

-- Whether mount speed gear should be on now.
local function mounted()
    if not ns.IsTrue(IsMounted()) then
        return false
    end
    return module.db.instances or not ns.Instances.Here()
end

-- The slots mount speed gear goes in with the options as set: slot -> true.
local function slots(db)
    local out = {}
    if db.trinket then
        out[tonumber(db.trinketSlot) == TRINKET1 and TRINKET1 or TRINKET2] = true
    end
    if db.gloves then
        out[HANDS] = true
    end
    if db.boots then
        out[FEET] = true
    end
    return out
end

-- Brings the gear in line with whether the player is mounted.
update = function()
    local busy = ns.Units.PlayerBusy()
    if busy == "combat" then
        if not afterCombat then
            afterCombat = true
            ns.AfterCombat(function()
                afterCombat = false
                if module.enabled then
                    tries = 0
                    update()
                end
            end)
        end
        return
    elseif busy == "casting" or CursorHasItem() or GetCursorInfo() then
        retry:Start(RETRY, update) -- not while the player holds something or is casting
        return
    elseif busy then
        return -- dead or on a flight: PLAYER_UNGHOST, PLAYER_ALIVE, or PLAYER_CONTROL_GAINED comes
    end
    local db = module.db
    local wanted = mounted() and slots(db) or {}
    local again = false
    -- Put back first, so a trinket slot changed in the options is freed before the other is used.
    for slot in pairs(db.worn) do
        local number = tonumber(slot)
        if number and not wanted[number] then
            again = takeOff(number) or again
        elseif not number then
            db.worn[slot] = nil
        end
    end
    for slot in pairs(wanted) do
        if not db.worn[slot] then
            again = putOn(slot) or again
        end
    end
    -- A lock is the client finishing a move; one that doesn't clear gives up until the next event.
    if again and tries < MAX_TRIES then
        tries = tries + 1
        retry:Start(RETRY, update)
    end
end

local queue = ns.Frames.Coalesce(function()
    tries = 0
    update()
end, 0.1, module)

function module:OnEnable()
    self:On("PLAYER_MOUNT_DISPLAY_CHANGED", queue)
    self:On("PLAYER_ENTERING_WORLD", queue)
    self:On("PLAYER_CONTROL_GAINED", queue) -- a flight ends
    self:On("PLAYER_ALIVE", queue)
    self:On("PLAYER_UNGHOST", queue)
    queue()
end

-- Turned off: put the player's own gear back now, when the game allows it. Otherwise what was
-- replaced stays remembered, and goes back on the next time the module is on.
function module:OnDisable()
    retry:Cancel()
    if ns.Units.PlayerBusy() or CursorHasItem() then
        return
    end
    for slot in pairs(self.db.worn) do
        local number = tonumber(slot)
        if number then
            takeOff(number)
        end
    end
end

function module:OnOptionChanged()
    queue()
end
