-- Bag addons that draw the bags with item buttons of their own instead of Blizzard's: Baganator
-- and GW2 UI. Both make their buttons for the player's own bags from Blizzard's
-- ContainerFrameItemButtonTemplate, so each says its bag and slot as Blizzard's does
-- (GetBagID, GetID), and a click on one does what a click on Blizzard's would. Lib/BagClicks.lua
-- lays its overlays on them and Lib/ItemButtons.lua marks them. Nothing here runs, hooks, or
-- listens while neither addon is loaded, nor before a module asks.
--
-- Baganator (build 868, read 2026-11-25; its GitHub repository is gone, read from a copy of the
-- CurseForge release): its frames through its public API, Baganator.API.Skins.GetAllFrames (every
-- frame it made, each { regionType, region, tags }, API/Main.lua and Skins/Initialize.lua). Its
-- live bag buttons inherit ContainerFrameItemButtonTemplate (ItemViewCommon/ItemButton.xml); the
-- ones showing another character's bags and its bag slot buttons don't, so they have no GetBagID.
-- The buttons are pooled and change slots each time it lays a view out, so nothing is kept per
-- button: each walk reads them again. A view laid out fires ViewComplete on
-- Baganator.CallbackRegistry, which Baganator puts on its global for other addons (its own skins
-- listen to it) but doesn't list in API/.
--
-- GW2 UI (read 2026-11-25, Games/Shared/Inventory/itemButtons.lua): no API for its bags. Its own
-- buttons, each fixed to one slot, through GW2_ADDON.ForEachOwnBagItemButton, which it exports for
-- integrations, and its windows GwBagFrame and GwBankFrame. It turns its own bags off while
-- Baganator is loaded (its Inventory module's incompatible addons), so only one of the two draws.
local _, ns = ...

local _G, ipairs, pairs, type, setmetatable = _G, ipairs, pairs, type, setmetatable
local max = math.max

local BagAddons = {}
ns.BagAddons = BagAddons

local function loaded(name)
    local C = _G.C_AddOns
    return C and C.IsAddOnLoaded and C.IsAddOnLoaded(name) and true or false
end

-- Every frame Baganator made, or nil without Baganator or that API.
local function baganatorFrames()
    local api = loaded("Baganator") and _G.Baganator and _G.Baganator.API
    local skins = type(api) == "table" and api.Skins
    if not (type(skins) == "table" and type(skins.GetAllFrames) == "function") then
        return nil
    end
    local all = skins.GetAllFrames()
    return type(all) == "table" and all or nil
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

-- GW2 UI's walk over its own item buttons, or nil while it isn't drawing the bags.
local function gwEach()
    local gw = loaded("GW2_UI") and _G.GW2_ADDON
    local each = type(gw) == "table" and gw.ForEachOwnBagItemButton
    return type(each) == "function" and each or nil
end

---Whether a bag addon whose buttons we know is loaded: Baganator, or GW2 UI drawing the bags.
---@return boolean
function BagAddons.Loaded()
    return (baganatorFrames() or gwEach()) and true or false
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

---Calls `fn(button, bag, slot, bank)` for each item button a bag addon shows on screen for the
---player's own items: `bank` is true for one in the bank. Buttons showing another character's
---bags aren't walked; neither are bag slots. Does nothing without a bag addon.
---@param fn fun(button: table, bag: number, slot: number, bank: boolean)
function BagAddons.EachButton(fn)
    local last = lastBag()
    local function visit(button)
        local bag, slot = live(button)
        if bag then
            fn(button, bag, slot, not (bag >= 0 and bag <= last))
        end
    end
    local frames = baganatorFrames()
    if frames then
        for _, details in ipairs(frames) do
            if type(details) == "table" and details.regionType == "ItemButton"
                and not hasTag(details, "containerBag") then
                visit(details.region)
            end
        end
    end
    local each = gwEach()
    if each then
        each(visit)
    end
end

-- The bag addons' windows: Baganator's bags and bank, and GW2 UI's.
local function windows(fn)
    local frames = baganatorFrames()
    if frames then
        for _, details in ipairs(frames) do
            if type(details) == "table" and details.regionType == "ButtonFrame"
                and (hasTag(details, "backpack") or hasTag(details, "bank")) then
                fn(details.region, hasTag(details, "bank"))
            end
        end
    end
    if gwEach() then
        fn(_G.GwBagFrame, false)
        fn(_G.GwBankFrame, true)
    end
end

---Whether a bag addon's bank window is open: a right-click in the bags then stores the item.
---@return boolean
function BagAddons.BankShown()
    local shown = false
    windows(function(frame, bank)
        if bank and type(frame) == "table" and frame.IsShown and frame:IsShown() then
            shown = true
        end
    end)
    return shown
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

local hooked = setmetatable({}, { __mode = "k" }) -- window -> true once its scripts are hooked
local registered = false

-- Hooks whatever is there to hook now: a window can be made after login (GW2 UI's) or again later
-- (Baganator's, when its skin changes). These hooks can't come off; `notify` runs a listener only
-- while its module is on.
local function hookAll()
    windows(function(frame)
        if type(frame) == "table" and frame.HookScript and not hooked[frame] then
            hooked[frame] = true
            frame:HookScript("OnShow", notify)
            frame:HookScript("OnHide", notify)
        end
    end)
    local registry = not registered and baganatorFrames() and _G.Baganator.CallbackRegistry
    if type(registry) == "table" and type(registry.RegisterCallback) == "function" then
        registered = true
        registry:RegisterCallback("ViewComplete", notify, BagAddons)
    end
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
