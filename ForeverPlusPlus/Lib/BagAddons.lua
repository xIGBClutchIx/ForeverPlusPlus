-- Bag addons that draw the bags with item buttons of their own instead of Blizzard's. Each makes
-- its buttons for the player's own bags from Blizzard's ContainerFrameItemButtonTemplate, so each
-- says its bag and slot as Blizzard's does (GetBagID, GetID), and a click on one does what a click
-- on Blizzard's would. Lib/BagClicks.lua lays its overlays on them and Lib/ItemButtons.lua marks
-- them. Nothing here runs, hooks, or listens while none is loaded, nor before a module asks.
--
-- Each addon is one adapter in ADAPTERS below: how to reach it once it's loaded (`get`), its live
-- bag and bank buttons (`each`), its windows (`windows`), whether its bank is open (`bankOpen`),
-- and what tells us it drew the bags again (`listen`). Adding an addon is one more adapter. What we
-- know of each, with versions and sources, is in docs/forever-api.md (Bags and the bank).
local _, ns = ...

local _G, ipairs, pairs, type, setmetatable, rawget, pcall = _G, ipairs, pairs, type, setmetatable, rawget, pcall
local max = math.max

local BagAddons = {}
ns.BagAddons = BagAddons

local function loaded(name)
    local C = _G.C_AddOns
    return C and C.IsAddOnLoaded and C.IsAddOnLoaded(name) and true or false
end

-- Another addon's global, by name: the type checker knows only the client's own.
local function global(name)
    return _G[name]
end

local function shown(frame)
    return type(frame) == "table" and type(frame.IsShown) == "function" and frame:IsShown() and true or false
end

local function hasTag(details, tag)
    local tags = details.tags
    if type(tags) == "table" then
        for _, t in ipairs(tags) do
            if t == tag then
                return true
            end
        end
    end
    return false
end

-- The adapters ---------------------------------------------------------------------------------
-- get() returns the addon's handle while it's loaded and drawing the bags, or nil. The rest take
-- that handle:
--   each(h, visit)      calls visit(button, art) for each of its buttons for the player's own bag
--                       and bank items (not another character's): `art` is the button that draws
--                       the icon when that isn't the button itself.
--   windows(h, fn)      calls fn(frame, isBank) for its bag and bank windows.
--   bankOpen(h)         whether its bank is open at a banker (default: its bank window is shown).
--   listen(h, notify)   once: has `notify` called when it lays its items out again.
--   hookButtons(h, hook) optional: calls hook(button) on buttons whose OnShow and OnHide tell us
--                       it laid them out again, for an addon with nothing better to listen to.

local ADAPTERS = {}

-- Baganator (build 868): its frames through its public API, Baganator.API.Skins.GetAllFrames (each
-- { regionType, region, tags }). Its live bag buttons inherit ContainerFrameItemButtonTemplate;
-- those showing another character's bags and its bag slot buttons don't, so they have no
-- GetBagID. The buttons are pooled and change slots each time it lays a view out, so nothing is
-- kept per button. A view laid out fires ViewComplete on Baganator.CallbackRegistry, which it
-- puts on its global for other addons (its own skins listen) but doesn't list in API/.
-- It draws an item's level on its buttons itself, by default in the top left corner (its
-- Core/Config.lua: icon_top_left_corner_array defaults to "junk", "item_level").
ADAPTERS[#ADAPTERS + 1] = {
    name = "Baganator",
    itemLevels = true,
    get = function()
        local b = loaded("Baganator") and global("Baganator")
        local skins = type(b) == "table" and type(b.API) == "table" and b.API.Skins
        if type(skins) == "table" and type(skins.GetAllFrames) == "function" then
            return b
        end
    end,
    frames = function(b)
        local all = b.API.Skins.GetAllFrames()
        return type(all) == "table" and all or {}
    end,
    each = function(b, visit, self)
        for _, details in ipairs(self.frames(b)) do
            if type(details) == "table" and details.regionType == "ItemButton"
                and not hasTag(details, "containerBag") then
                visit(details.region)
            end
        end
    end,
    windows = function(b, fn, self)
        for _, details in ipairs(self.frames(b)) do
            if type(details) == "table" and details.regionType == "ButtonFrame"
                and (hasTag(details, "backpack") or hasTag(details, "bank")) then
                fn(details.region, hasTag(details, "bank"))
            end
        end
    end,
    listen = function(b, notify)
        local registry = b.CallbackRegistry
        if type(registry) == "table" and type(registry.RegisterCallback) == "function" then
            registry:RegisterCallback("ViewComplete", notify, BagAddons)
        end
    end,
}

-- GW2 UI: no API for its bags. Its own buttons, each fixed to one slot, through
-- GW2_ADDON.ForEachOwnBagItemButton, which it exports for integrations, and its windows GwBagFrame
-- and GwBankFrame. It turns its own bags off while Baganator, ArkInventory, or Bagnon is loaded
-- (its Inventory module's incompatible addons), and then has no such function to give.
ADAPTERS[#ADAPTERS + 1] = {
    name = "GW2_UI",
    get = function()
        local gw = loaded("GW2_UI") and global("GW2_ADDON")
        if type(gw) == "table" and type(gw.ForEachOwnBagItemButton) == "function" then
            return gw
        end
    end,
    each = function(gw, visit)
        gw.ForEachOwnBagItemButton(visit)
    end,
    windows = function(_, fn)
        fn(global("GwBagFrame"), false)
        fn(global("GwBankFrame"), true)
    end,
}

-- Bagnon and Bagnonium (12.1.13), two looks over one core, BagBrother, each with its own global.
-- No API for their buttons, so this reads, and never calls anything that lays out: the window from
-- its frames registry (`Frames:Get(id)`, a frame once `[0]` is there), the buttons its item group
-- shows (`ItemGroup.buttons`, ContainerFrameItemButtonTemplate, each fixed to one slot under a
-- frame whose ID is the bag), and whether a bag is another character's or the bank's away from a
-- banker (`frame:IsCached(bag)`). Only the bags and the bank: its guild bank's buttons say their
-- tab as their bag. Nothing tells other addons it laid them out, but each layout hides and shows
-- its buttons again, so their OnShow and OnHide do.
local function bagnon(addon)
    local function window(b, id)
        local frame = b.Frames:Get(id)
        if type(frame) == "table" and frame[0] and type(frame.IsCached) == "function" then
            return frame
        end
    end
    return {
        name = addon,
        get = function()
            local b = loaded(addon) and global(addon)
            if type(b) == "table" and type(b.Frames) == "table" and type(b.Frames.Get) == "function" then
                return b
            end
        end,
        buttons = function(b, fn)
            for _, id in ipairs({ "inventory", "bank" }) do
                local frame = window(b, id)
                local group = frame and rawget(frame, "ItemGroup")
                local list = type(group) == "table" and rawget(group, "buttons")
                if type(list) == "table" then
                    for _, button in ipairs(list) do
                        fn(button, frame)
                    end
                end
            end
        end,
        each = function(b, visit, self)
            self.buttons(b, function(button, frame)
                local bag = type(button) == "table" and button.GetBagID and button:GetBagID()
                if type(bag) == "number" and not frame:IsCached(bag) then
                    visit(button)
                end
            end)
        end,
        hookButtons = function(b, hook, self)
            self.buttons(b, hook)
        end,
        windows = function(b, fn)
            fn(window(b, "inventory"), false)
            fn(window(b, "bank"), true)
        end,
        bankOpen = function(b)
            local bank = window(b, "bank")
            return bank and shown(bank) and not bank:IsCached() or false
        end,
    }
end
ADAPTERS[#ADAPTERS + 1] = bagnon("Bagnon")
ADAPTERS[#ADAPTERS + 1] = bagnon("Bagnonium")

-- BetterBags (v0.9.5, its BetterBags_Camelot.toc for Forever): an AceAddon whose modules its
-- plugins reach with GetModule. Each item is two buttons from ContainerFrameItemButtonTemplate:
-- the one clicked (`button`), set once to one bag and slot through Blizzard's Initialize, and
-- below it the one that draws the icon (`_decoration`), so marks go on that one. Every item it
-- made is in the ItemFrame module's `activeItems`, read here; its own items for no slot (a
-- section's header) say slot 0. It draws the bags again on its messages bags/Draw/Backpack/Done
-- and bags/Draw/Bank/Done, which plugins hear with the Events module's RegisterMessage. It has
-- no view of another character's bags, and shows its bank only at a banker.
-- It draws an item's level itself, on by default (its core/constants.lua: itemLevel.enabled).
ADAPTERS[#ADAPTERS + 1] = {
    name = "BetterBags",
    itemLevels = true,
    get = function()
        local ace = loaded("BetterBags") and _G.LibStub and _G.LibStub("AceAddon-3.0", true)
        local bb = ace and ace:GetAddon("BetterBags", true)
        local items = bb and type(bb.GetModule) == "function" and bb:GetModule("ItemFrame", true)
        if type(items) == "table" and type(items.activeItems) == "table" then
            return bb
        end
    end,
    each = function(bb, visit)
        for item in pairs(bb:GetModule("ItemFrame").activeItems) do
            if type(item) == "table" then
                visit(item.button, item._decoration)
            end
        end
    end,
    windows = function(bb, fn)
        local bags = type(bb.Bags) == "table" and bb.Bags or {}
        fn(type(bags.Backpack) == "table" and bags.Backpack.frame, false)
        fn(type(bags.Bank) == "table" and bags.Bank.frame, true)
    end,
    bankOpen = function(bb)
        local bank = type(bb.Bags) == "table" and bb.Bags.Bank
        return bb.atBank == true and type(bank) == "table" and shown(bank.frame) or false
    end,
    listen = function(bb, notify)
        local events = bb:GetModule("Events", true)
        if type(events) == "table" and type(events.RegisterMessage) == "function" then
            events:RegisterMessage("bags/Draw/Backpack/Done", notify)
            events:RegisterMessage("bags/Draw/Bank/Done", notify)
        end
    end,
}

-- ArkInventory (3.12.17, its ArkInventory_Camelot.toc for Forever), through its public API
-- (Core/ArkInventoryAPI.lua): ItemFrameLoadedIterate walks every item frame it made, with its
-- window (location) id, and LocationIsOffline says whether a window shows another character's
-- items or the bank away from a banker. Each frame is fixed to one slot of its window, made from
-- ContainerFrameItemButtonTemplate with its slot as ID, under a bag frame whose ID is the bag.
-- Only its Bag and Bank windows hold container buttons. Its API says to hear a frame drawn
-- again with hooksecurefunc(ArkInventory.API, "ItemFrameUpdated", fn), as this does. Its windows
-- are ARKINV_Frame<location>.
ADAPTERS[#ADAPTERS + 1] = {
    name = "ArkInventory",
    get = function()
        local ark = loaded("ArkInventory") and global("ArkInventory")
        local api = type(ark) == "table" and ark.API
        local const = type(ark) == "table" and type(ark.Const) == "table" and ark.Const.Location
        if type(api) == "table" and type(api.ItemFrameLoadedIterate) == "function"
            and type(api.LocationIsOffline) == "function" and type(const) == "table"
            and type(const.Bag) == "number" and type(const.Bank) == "number" then
            return ark
        end
    end,
    each = function(ark, visit)
        local api, loc = ark.API, ark.Const.Location
        local online = {
            [loc.Bag] = api.LocationIsOffline(loc.Bag) == false,
            [loc.Bank] = api.LocationIsOffline(loc.Bank) == false,
        }
        -- Its walk is its own code: one that fails (before its windows are set up) walks nothing,
        -- and our callbacks run after it, outside the pcall.
        local frames = {}
        pcall(function()
            for _, frame, window in api.ItemFrameLoadedIterate() do
                if online[window] then
                    frames[#frames + 1] = frame
                end
            end
        end)
        for _, frame in ipairs(frames) do
            visit(frame)
        end
    end,
    windows = function(ark, fn)
        local loc = ark.Const.Location
        fn(_G["ARKINV_Frame" .. loc.Bag], false)
        fn(_G["ARKINV_Frame" .. loc.Bank], true)
    end,
    bankOpen = function(ark)
        local bank = ark.Const.Location.Bank
        return ark.API.LocationIsOffline(bank) == false and shown(_G["ARKINV_Frame" .. bank])
    end,
    listen = function(ark, notify)
        if type(_G.hooksecurefunc) == "function" and type(ark.API.ItemFrameUpdated) == "function" then
            _G.hooksecurefunc(ark.API, "ItemFrameUpdated", notify)
        end
    end,
}

-- The walk -------------------------------------------------------------------------------------

-- Calls fn(adapter, handle) for each adapter whose addon is there.
local function eachAddon(fn)
    for _, adapter in ipairs(ADAPTERS) do
        local h = adapter.get()
        if h then
            fn(adapter, h)
        end
    end
end

---Whether a bag addon whose buttons we know is loaded and drawing the bags.
---@return boolean
function BagAddons.Loaded()
    for _, adapter in ipairs(ADAPTERS) do
        if adapter.get() then
            return true
        end
    end
    return false
end

---Whether a bag addon that's drawing the bags shows item levels on its buttons itself (an
---adapter's `itemLevels`: Baganator and BetterBags do by default), so a mark of ours for the same
---thing would sit on top of its own. Whether the player has that turned off in the bag addon
---isn't known here.
---@return boolean
function BagAddons.ShowsItemLevels()
    for _, adapter in ipairs(ADAPTERS) do
        if adapter.itemLevels and adapter.get() then
            return true
        end
    end
    return false
end

-- The last of the player's own bags: the backpack is 0, then the bags and the reagent bag. A bag
-- after it is the bank's.
local function lastBag()
    return max(ns.Bags.LAST, ns.Bags.REAGENT)
end

-- A button's bag and slot while it's a live container button on screen, or nil. On screen, not
-- only shown: a window can be shown under a hidden parent or at no alpha.
local function live(button)
    if type(button) ~= "table" or type(button.GetBagID) ~= "function" or not button:IsVisible()
        or button:GetEffectiveAlpha() <= 0 then
        return nil
    end
    local bag, slot = button:GetBagID(), button:GetID()
    if type(bag) == "number" and type(slot) == "number" and slot > 0 then
        return bag, slot
    end
    return nil
end

local hookAll -- below

---Calls `fn(button, bag, slot, bank, art)` for each item button a bag addon shows on screen for
---the player's own items: `bank` is true for one in the bank, and `art` is the button that draws
---its icon when that's another (BetterBags'). Buttons showing another character's bags aren't
---walked; neither are bag slots. Does nothing without a bag addon.
---@param fn fun(button: table, bag: number, slot: number, bank: boolean, art: table?)
function BagAddons.EachButton(fn)
    local last = lastBag()
    local function visit(button, art)
        local bag, slot = live(button)
        if bag then
            fn(button, bag, slot, not (bag >= 0 and bag <= last), art)
        end
    end
    local any = false
    eachAddon(function(adapter, h)
        any = true
        adapter.each(h, visit, adapter)
    end)
    if any then
        hookAll() -- a window made since we last looked (a bank's, on its first visit)
    end
end

---Whether a bag addon's bank window is open at a banker: a right-click in the bags then stores
---the item.
---@return boolean
function BagAddons.BankShown()
    local open = false
    eachAddon(function(adapter, h)
        if adapter.bankOpen then
            open = open or adapter.bankOpen(h, adapter) and true or false
        elseif adapter.windows then
            adapter.windows(h, function(frame, bank)
                if bank and shown(frame) then
                    open = true
                end
            end, adapter)
        end
    end)
    return open
end

-- Watching -----------------------------------------------------------------------------------

local listeners = {} -- fn -> the module it runs for, only while that module is on

local function notify()
    for fn, module in pairs(listeners) do
        if module.enabled then
            ns.Call(fn)
        end
    end
end

local hooked = setmetatable({}, { __mode = "k" }) -- frame -> true once its scripts are hooked
local listening = {} -- adapter -> true once its own callback is registered

-- OnShow and OnHide on a frame of theirs, once. These hooks can't come off; `notify` runs a
-- listener only while its module is on.
local function hookShown(frame)
    if type(frame) == "table" and frame.HookScript and not hooked[frame] then
        hooked[frame] = true
        frame:HookScript("OnShow", notify)
        frame:HookScript("OnHide", notify)
    end
end

-- Hooks whatever is there to hook now: a window can be made after login (GW2 UI's, a bank's on
-- its first visit) or again later (Baganator's, when its skin changes).
function hookAll()
    eachAddon(function(adapter, h)
        if adapter.windows then
            adapter.windows(h, hookShown, adapter)
        end
        if adapter.hookButtons then
            adapter.hookButtons(h, hookShown, adapter)
        end
        if adapter.listen and not listening[adapter] then
            listening[adapter] = true
            adapter.listen(h, notify, adapter)
        end
    end)
end

local onBags = setmetatable({}, { __mode = "k" }) -- fn -> its BAG_UPDATE_DELAYED handler

---Calls `fn()` while `module` is on whenever a bag addon's bags show, hide, or lay their items
---out again, and as the bags change (BAG_UPDATE_DELAYED, through the module, so it stops when the
---module turns off). Call it from OnEnable, with `fn` coalesced: it can come several times a
---frame. Does nothing without a bag addon.
---@param module table
---@param fn fun()
function BagAddons.Watch(module, fn)
    if not BagAddons.Loaded() then
        return
    end
    listeners[fn] = module
    hookAll()
    local handler = onBags[fn]
    if not handler then
        handler = function()
            hookAll()
            fn()
        end
        onBags[fn] = handler
    end
    module:On("BAG_UPDATE_DELAYED", handler)
    module:On("PLAYER_ENTERING_WORLD", handler)
end
