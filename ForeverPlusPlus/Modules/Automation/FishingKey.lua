-- Fishing Key: one key for fishing. Its first press takes a fishing pole from the bags (and, with
-- Fishing Gear, the hat and boots worn for their Fishing bonus); then the same key casts Fishing,
-- and while the bobber is out it loots the bobber. A second key, or Shift with the first, puts the
-- player's own weapons and gear back on. Both keys are in Blizzard's Key Bindings (Bindings.xml,
-- under Forever++): the left and right clicks of one secure button.
--
-- How the one key does both (Blizzard's source, `forever` branch): casting needs a secure action
-- button, and nothing secure can interact with an object (there's no "interact" action in
-- SecureTemplates.lua and no /interact). So the key clicks our button, whose `*type1` is the
-- Fishing spell while a pole is in hand. When the Fishing channel starts, the key's own keys get an
-- override binding to INTERACTTARGET, the game's Interact With Target, which interacts with the
-- soft interact target (`C_PlayerInteractionManager.InteractUnit("anyinteract")`): the bobber.
-- When the channel ends (looted, or the fish got away), the override comes off and the key casts
-- again. The button acts on the key going down (`useOnKeyDown`), so the release after a loot
-- doesn't cast. Attributes and override bindings can only change out of combat, so in combat the
-- key keeps what it did; a press then changes the gear once combat ends.
--
-- The game only gives the bobber to Interact With Target while its Enable Interact Key setting is
-- on (the softTargetInteract CVar). With Interact Key, the module turns it on while a fishing pole
-- is in hand and puts the player's own value back when the pole comes off, through ns.CVars, which
-- keeps that value in `saved`, so a reload or logout with the pole still in hand puts it back too.
-- A player who has it on already has nothing changed.
--
-- The gear: each change is a swap of a bag slot with an inventory slot (Lib/Equipment.lua), and
-- what it replaced is remembered for the character by item, enchant, gems, and suffix, so the
-- right item goes back after a reload or logout. A pole takes both hands, so a worn off-hand goes
-- into the bags first and back on after the main hand. A record is dropped when the slot no longer
-- holds what we put there (the player changed it), and when the item to put back isn't in the
-- bags any more, which it says in chat. Gear that isn't bound yet would ask first, so it's left.
local _, ns = ...

local pairs, ipairs, type, tonumber, tostring, select, next, format, _G =
    pairs, ipairs, type, tonumber, tostring, select, next, string.format, _G
local CreateFrame, InCombatLockdown, GetBindingKey = CreateFrame, InCombatLockdown, GetBindingKey
local SetOverrideBinding, ClearOverrideBindings = SetOverrideBinding, ClearOverrideBindings
local CursorHasItem, GetCursorInfo, IsInventoryItemLocked = CursorHasItem, GetCursorInfo, IsInventoryItemLocked
local C_Spell, C_Item, C_CVar = C_Spell, C_Item, C_CVar

local L = ns.L
local Equipment = ns.Equipment

local module = ns.NewModule("FishingKey", L.FISHINGKEY_DESC, {
    enabled = false,
    interact = true, -- turn on the game's Enable Interact Key while a pole is in hand, if it's off
    gear = true, -- fishing gear from the bags too, not only the pole
    shiftBack = true, -- Shift with the key puts the player's gear back
    chat = true,
    saved = {}, -- CVar -> the player's own value while Interact Key has changed it
    -- What we put on, by inventory slot, for this character: { put = key of the item we put on
    -- (false for a slot we emptied), back = key of the item it replaced (false for an empty
    -- slot), link = that item's link }. Data, not a setting.
    worn = {},
})
module.perCharacter = { worn = true }
module.title = L.FISHINGKEY_TITLE
module.category = "automation"
module.added = "1.10.0"
-- A reload or logout with the pole in hand leaves the Interact Key on: put it back at login if the
-- module is off then (OnEnable does it when it's on and the pole is off).
ns.CVars.Track(module)

-- The button the keys click, named for its bindings in Bindings.xml.
local BUTTON = "ForeverPlusPlusFishingButton"
local FISH = "CLICK " .. BUTTON .. ":LeftButton"
local BACK = "CLICK " .. BUTTON .. ":RightButton"

-- Blizzard's Key Bindings read these names when it lists Bindings.xml's keys.
BINDING_HEADER_FOREVERPLUSPLUS = ns.title
for binding, name in pairs({ [FISH] = L.FISHINGKEY_BINDING, [BACK] = L.FISHINGKEY_BACK_BINDING }) do
    _G["BINDING_NAME_" .. binding] = name
end

module.notice = {
    {
        text = L.FISHINGKEY_NO_KEY, description = L.FISHINGKEY_NO_KEY_DESC,
        button = L.FISHINGKEY_BIND, fn = ns.Keys.OpenBindings,
        shown = function() return module.db.enabled and not GetBindingKey(FISH) end,
    },
    { text = L.FISHINGKEY_COMBAT, description = L.FISHINGKEY_COMBAT_DESC },
}

module.options = {
    { key = "interact", name = L.FISHINGKEY_INTERACT, description = L.FISHINGKEY_INTERACT_DESC },
    { key = "gear", name = L.FISHINGKEY_GEAR, description = L.FISHINGKEY_GEAR_DESC },
    { key = "shiftBack", name = L.FISHINGKEY_SHIFT, description = L.FISHINGKEY_SHIFT_DESC },
    ns.ChatOption(L.FISHINGKEY_CHAT_DESC),
}

-- Classic's ID: Self Test on build 70338 found Mainline's 131474 isn't in Forever's data.
local FISHING = ns.Data.Spell("FISHING")
local GEAR = ns.GameData.New("fishingGear", ns.Data.fishingGear, { kind = "item", label = "Fishing Key gear" })

local MAINHAND, OFFHAND = 16, 17
-- The game's Enable Interact Key (Blizzard_SettingsDefinitions_Frame/Controls.lua, `forever`
-- branch): Enum.SoftTargetEnableFlags, 1 for the controller, 2 for keyboard and mouse, 3 for both.
-- The Settings checkbox sets 3 for on and 1 for off.
local INTERACT = "softTargetInteract"
local INTERACT_ON = "3"
local PAD, KBM, ANY = 1, 2, 3
-- How far away the soft interact target may be. A bobber lands up to about 20 yards out; this is
-- raised only when we turn the Interact Key on, and only ever raised. Unverified on Forever: a
-- client without the CVar is left alone.
local REACH, REACH_YARDS = "SoftTargetInteractRange", 30
local RETRY = 0.5 -- seconds before looking again after a move or a locked item
local MAX_TRIES = 12

local button -- the secure button, made on first enable (a frame can't be removed)
local owner -- the frame that owns the override bindings
local fishing = false -- the player's Fishing channel is up: the bobber is out
local want -- "fish" or "normal" while a change of gear is under way, else nil
local tries = 0
local waiting = false -- a change is waiting for combat to end
local retry = ns.Frames.Timer(module)
local step

local function poleWorn()
    return Equipment.WeaponSubclass(MAINHAND) == Equipment.FISHING_POLE
end

local function locked(slot)
    return ns.IsTrueOrSecret(IsInventoryItemLocked(slot))
end

local function isFishing(spellID)
    if not spellID or not ns.IsReadable(spellID) then
        return false
    end
    local name = C_Spell.GetSpellName(spellID)
    return name ~= nil and name == C_Spell.GetSpellName(FISHING)
end

-- The Interact Key -------------------------------------------------------------------------------

-- Whether the game's Enable Interact Key is on for what the player plays with now. True on a client
-- without the setting, where there's nothing to turn on.
local function interactOn()
    local value = tonumber(C_CVar.GetCVar(INTERACT) or "")
    if not value then
        return true
    end
    return value == ANY or value == (ns.Gamepad.On() and PAD or KBM)
end

-- Holds the Interact Key on while a pole is in hand and the option is on; otherwise puts the
-- player's own values back.
local function holdInteract()
    local saved = module.db.saved
    if module.enabled and module.db.interact and poleWorn() then
        if not interactOn() then
            ns.CVars.Set(saved, INTERACT, INTERACT_ON)
            local reach = tonumber(C_CVar.GetCVar(REACH) or "")
            if reach and reach < REACH_YARDS then
                ns.CVars.Set(saved, REACH, tostring(REACH_YARDS))
            end
        end
    elseif next(saved) ~= nil then
        ns.CVars.RestoreAll(saved)
    end
end

-- The key ----------------------------------------------------------------------------------------

-- What the key does: Interact With Target while the bobber is out, else the button. Out of combat
-- only; ns.AfterCombat waits, and the state is read when it runs.
local function updateKeys()
    ns.AfterCombat(function()
        if not owner then
            return
        end
        ClearOverrideBindings(owner)
        if module.enabled and fishing then
            for _, key in ipairs({ GetBindingKey(FISH) }) do
                SetOverrideBinding(owner, true, key, "INTERACTTARGET")
            end
        end
    end)
end

-- Whether a press of the key casts: a pole in hand, and not Shift when Shift puts the gear back.
local function casts(mouseButton)
    return module.enabled and mouseButton == "LeftButton" and poleWorn()
        and not (module.db.shiftBack and ns.Keys.IsDown("shift"))
end

local function updateButton()
    ns.AfterCombat(function()
        if button then
            button:SetAttribute("spell", C_Spell.GetSpellName(FISHING))
            button:SetAttribute("*type1", casts("LeftButton") and "spell" or nil)
        end
    end)
end

local function start(kind)
    want = kind
    tries = 0
    step()
end

-- Before the secure click: set what it does from how things are now (it can't change in combat,
-- when it keeps what it had), and on the press, start a change of gear the press asks for.
local function preClick(self, mouseButton, down)
    if not module.enabled then
        return
    end
    if not InCombatLockdown() then
        self:SetAttribute("*type1", casts(mouseButton) and "spell" or nil)
    end
    if not down then
        return
    end
    if mouseButton == "RightButton" or (module.db.shiftBack and ns.Keys.IsDown("shift")) then
        start("normal")
    elseif mouseButton == "LeftButton" and not poleWorn() then
        start("fish")
    end
end

-- Gear -------------------------------------------------------------------------------------------

-- Whether equipping this bag item would bind it, which the game asks about first. Unknown counts.
local function wouldBind(info, link)
    if info.isBound ~= false then
        return false
    end
    local bindType = select(14, C_Item.GetItemInfo(link))
    return bindType ~= 0
end

-- The best fishing pole in the bags, by item level: { bag, slot, link, locked }, and the link of
-- one left because it would bind.
local function findPole()
    local best, bestLevel, unbound
    ns.Bags.Each(function(bag, slot, info)
        local link = info and info.hyperlink
        if not ns.IsText(link, true) then
            return
        end
        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(link)
        if classID ~= Equipment.WEAPON or subclassID ~= Equipment.FISHING_POLE then
            return
        end
        if wouldBind(info, link) then
            unbound = unbound or link
            return
        end
        local level = Equipment.ItemLevel(link) or 0
        if not best or level > bestLevel then
            best = { bag = bag, slot = slot, link = link, locked = ns.IsTrueOrSecret(info.isLocked) }
            bestLevel = level
        end
    end)
    return best, unbound
end

local function isGear(link)
    local itemID = C_Item.GetItemInfoInstant(link)
    return itemID ~= nil and GEAR:Get(itemID) == true
end

local function remember(slot, put, worn)
    module.db.worn[slot] = { put = put, back = worn and Equipment.ItemKey(worn) or false, link = worn }
end

-- Puts the fishing gear on, a step at a time. "wait" to look again shortly, "done", or "stop".
local function putOn()
    local db = module.db
    if not poleWorn() then
        local pole, unbound = findPole()
        if not pole then
            module:Print(unbound and format(L.FISHINGKEY_UNBOUND, unbound) or L.FISHINGKEY_NO_POLE)
            return "stop"
        end
        -- A pole takes both hands: the off-hand goes into the bags first.
        local off = Equipment.Worn(OFFHAND)
        if off then
            if locked(OFFHAND) then
                return "wait"
            end
            local done = Equipment.Unequip(OFFHAND)
            if done == "full" then
                module:Print(format(L.FISHINGKEY_BAGS_FULL, off))
                return "stop"
            elseif done then
                db.worn[OFFHAND] = { put = false, back = Equipment.ItemKey(off), link = off }
            end
            return "wait"
        end
        if pole.locked or locked(MAINHAND) then
            return "wait"
        end
        local worn = Equipment.Worn(MAINHAND)
        if not Equipment.Swap(pole.bag, pole.slot, MAINHAND) then
            return "stop" -- the game won't put it on (a level or skill it needs)
        end
        remember(MAINHAND, Equipment.ItemKey(pole.link), worn)
        return "wait"
    end
    if not db.gear then
        return "done"
    end
    local moved, filled = false, {}
    ns.Bags.Each(function(bag, slot, info)
        local link = info and info.hyperlink
        if not (ns.IsText(link, true) and isGear(link)) or wouldBind(info, link) then
            return
        end
        local slots = Equipment.Slots(select(4, C_Item.GetItemInfoInstant(link)))
        local invSlot = slots and slots[1]
        local worn = invSlot and Equipment.Worn(invSlot)
        if not invSlot or filled[invSlot] or (worn and isGear(worn)) then
            return
        end
        filled[invSlot] = true
        if ns.IsTrueOrSecret(info.isLocked) or locked(invSlot) then
            moved = true
        elseif Equipment.Swap(bag, slot, invSlot) then
            remember(invSlot, Equipment.ItemKey(link), worn)
            moved = true
        end
    end)
    return moved and "wait" or "done"
end

-- Puts back what we replaced in `slot`. True when something moved or is locked, to look again.
local function putBack(slot)
    local db = module.db
    local record = db.worn[slot]
    if type(record) ~= "table" then
        db.worn[slot] = nil
        return false
    end
    if locked(slot) then
        return true
    end
    local worn = Equipment.Worn(slot)
    if (worn and Equipment.ItemKey(worn) or false) ~= record.put then
        db.worn[slot] = nil -- changed since; what's worn now is the player's choice
        return false
    end
    if record.back == false then
        -- The slot was empty: what we put there goes into the bags.
        local done = Equipment.Unequip(slot)
        if done == "full" then
            db.worn[slot] = nil
            module:Print(format(L.FISHINGKEY_BAGS_FULL, worn))
        elseif done then
            db.worn[slot] = nil
        end
        return done == true
    end
    local bag, bagSlot, itemLocked = ns.Bags.Each(function(b, s, info)
        if info and Equipment.ItemKey(info.hyperlink) == record.back then
            return b, s, ns.IsTrueOrSecret(info.isLocked)
        end
    end)
    if not bag then
        db.worn[slot] = nil
        module:Print(format(L.FISHINGKEY_MISSING, ns.IsText(record.link, true) and record.link or record.back))
        return false
    elseif itemLocked then
        return true
    end
    -- Refused, it stays remembered for the next press.
    if Equipment.Swap(bag, bagSlot, slot) then
        db.worn[slot] = nil
    end
    return true
end

-- Puts the player's own gear back, a step at a time: the main hand first, then the off-hand once
-- it's done (an off-hand can't go on beside the pole), then the rest.
local function putAllBack()
    local db = module.db
    if db.worn[MAINHAND] then
        return putBack(MAINHAND) and "wait" or (next(db.worn) and "wait" or "done")
    end
    if db.worn[OFFHAND] then
        if locked(MAINHAND) then
            return "wait"
        end
        return putBack(OFFHAND) and "wait" or (next(db.worn) and "wait" or "done")
    end
    local moved = false
    for slot in pairs(db.worn) do
        local number = tonumber(slot)
        if number then
            moved = putBack(number) or moved
        else
            db.worn[slot] = nil
        end
    end
    return (moved or next(db.worn)) and "wait" or "done"
end

local function finish()
    want = nil
    tries = 0
    retry:Cancel()
end

step = function()
    if not (module.enabled and want) then
        return
    end
    local busy = ns.Units.PlayerBusy()
    if busy == "combat" then
        if not waiting then
            waiting = true
            ns.AfterCombat(function()
                waiting = false
                tries = 0
                step()
            end)
        end
        return
    elseif busy == "dead" or busy == "taxi" then
        return finish()
    end
    -- Not while the player holds something or casts, except that putting the gear back may end
    -- the Fishing channel (changing weapons does).
    local result
    if CursorHasItem() or GetCursorInfo() or (busy == "casting" and not (want == "normal" and fishing)) then
        result = "wait"
    elseif want == "fish" then
        result = putOn()
    else
        result = putAllBack()
    end
    if result == "wait" and tries < MAX_TRIES then
        tries = tries + 1
        retry:Start(RETRY, step)
    else
        finish()
    end
end

-- Events -----------------------------------------------------------------------------------------

local function onEquipment(_, slot)
    if slot == MAINHAND then
        holdInteract()
        updateButton()
    end
end

local function onChannelStart(_, unit, _, spellID)
    if unit == "player" and isFishing(spellID) then
        fishing = true
        updateKeys()
    end
end

local function onChannelStop(_, unit)
    if unit == "player" and fishing then
        fishing = false
        updateKeys()
    end
end

function module:OnEnable()
    if not button then
        button = CreateFrame("Button", BUTTON, UIParent, "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyDown", "AnyUp")
        button:SetScript("PreClick", preClick)
        owner = CreateFrame("Frame")
        ns.AfterCombat(function()
            -- On the press, however the game's Cast on Key Down is set, so the release after a
            -- loot (the override is gone by then) doesn't cast again.
            button:SetAttribute("useOnKeyDown", true)
        end)
    end
    fishing = false
    self:On("PLAYER_EQUIPMENT_CHANGED", onEquipment)
    self:On("UNIT_SPELLCAST_CHANNEL_START", onChannelStart)
    self:On("UNIT_SPELLCAST_CHANNEL_STOP", onChannelStop)
    holdInteract()
    updateButton()
    updateKeys()
end

-- Turned off: the key does nothing and the Interact Key goes back. The fishing gear stays on, and
-- what it replaced stays remembered for the next time the module is on.
function module:OnDisable()
    finish()
    fishing = false
    updateKeys()
    updateButton()
    holdInteract()
end

function module:OnOptionChanged(key)
    if key == "interact" then
        holdInteract()
    elseif key == "shiftBack" then
        updateButton()
    end
end
