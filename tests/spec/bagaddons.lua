-- Bag addons: Baganator's and GW2 UI's item buttons, which of them are the player's live bag
-- slots, their bank windows, and being told when their bags redraw.
local T = ...
local ns, eq, same, ok = T.ns, T.eq, T.same, T.ok

T.load("Lib/Bags", ns)

local loadedAddOns = {}
C_AddOns = {
    IsAddOnLoaded = function(name)
        return loadedAddOns[name] or false
    end,
}

-- A stand-in for a ContainerFrameItemButtonTemplate button (`live`), or another kind of button.
local function button(bag, slot, opts)
    opts = opts or {}
    local b = {
        GetID = function() return slot end,
        IsVisible = function() return opts.visible ~= false end,
        GetEffectiveAlpha = function() return opts.alpha or 1 end,
    }
    if opts.live ~= false then
        b.GetBagID = function() return bag end
    end
    return b
end

local function window(shown)
    local w = { shown = shown, scripts = {} }
    w.IsShown = function(self) return self.shown end
    w.HookScript = function(self, script, fn)
        self.scripts[script] = fn
    end
    return w
end

T.load("Lib/BagAddons", ns)
local BagAddons = ns.BagAddons

local function walk()
    local seen = {}
    BagAddons.EachButton(function(_, bag, slot, bank)
        seen[#seen + 1] = bag .. ":" .. slot .. (bank and ":bank" or "")
    end)
    return seen
end

eq(BagAddons.Loaded(), false, "bagaddons: none loaded")
eq(BagAddons.ShowsItemLevels(), false, "bagaddons: and none drawing item levels of its own")
same(walk(), {}, "bagaddons: no buttons without one")
eq(BagAddons.BankShown(), false, "bagaddons: no bank without one")

-- Baganator ---------------------------------------------------------------------------------

local bags, bank = window(true), window(false)
local callbacks = {}
local frames = {
    { regionType = "ButtonFrame", region = bags, tags = { "backpack" } },
    { regionType = "ButtonFrame", region = bank, tags = { "bank" } },
    { regionType = "ItemButton", region = button(0, 1) },
    { regionType = "ItemButton", region = button(0, 2, { visible = false }) }, -- in the pool
    { regionType = "ItemButton", region = button(1, 3, { alpha = 0 }) },
    { regionType = "ItemButton", region = button(0, 4, { live = false }) }, -- another character's
    { regionType = "ItemButton", region = button(2, 1), tags = { "containerBag" } }, -- a bag slot
    { regionType = "ItemButton", region = button(5, 2) }, -- the reagent bag
    { regionType = "ItemButton", region = button(6, 7) }, -- a bank tab
}
Baganator = {
    API = { Skins = { GetAllFrames = function() return frames end } },
    CallbackRegistry = {
        RegisterCallback = function(_, event, fn, owner)
            callbacks[#callbacks + 1] = { event, fn, owner }
        end,
    },
}
eq(BagAddons.Loaded(), false, "bagaddons: Baganator's global without the addon loaded")
loadedAddOns.Baganator = true
eq(BagAddons.Loaded(), true, "bagaddons: Baganator loaded")
eq(BagAddons.ShowsItemLevels(), true, "bagaddons: Baganator draws item levels itself")
same(walk(), { "0:1", "5:2", "6:7:bank" },
    "bagaddons: Baganator's live buttons on screen, not pooled, faded out, cached, or bag slots")
eq(BagAddons.BankShown(), false, "bagaddons: Baganator's bank closed")
bank.shown = true
eq(BagAddons.BankShown(), true, "bagaddons: Baganator's bank open")
bank.shown = false

-- Watching: the windows' scripts and ViewComplete, and the bag events through the module.
local module = { enabled = true, events = {} }
function module:On(event, fn)
    self.events[event] = fn
end
local calls = 0
local function refresh()
    calls = calls + 1
end
BagAddons.Watch(module, refresh)
eq(#callbacks, 1, "bagaddons: ViewComplete listened to")
eq(callbacks[1][1], "ViewComplete", "bagaddons: the event")
ok(bags.scripts.OnShow and bags.scripts.OnHide and bank.scripts.OnHide, "bagaddons: the windows hooked")
callbacks[1][2](callbacks[1][3])
bags.scripts.OnHide(bags)
eq(calls, 2, "bagaddons: told when a view is laid out and a window hides")
module.events.BAG_UPDATE_DELAYED()
eq(calls, 3, "bagaddons: and as the bags change")
module.enabled = false
callbacks[1][2](callbacks[1][3])
eq(calls, 3, "bagaddons: not while the module is off")
module.enabled = true
BagAddons.Watch(module, refresh)
eq(#callbacks, 1, "bagaddons: ViewComplete listened to once")

-- GW2 UI ------------------------------------------------------------------------------------

loadedAddOns.Baganator = nil
local gwButtons = { button(0, 3), button(4, 1, { visible = false }) }
GW2_ADDON = {
    ForEachOwnBagItemButton = function(fn)
        for _, b in ipairs(gwButtons) do
            fn(b)
        end
    end,
}
eq(BagAddons.Loaded(), false, "bagaddons: GW2 UI's global without the addon loaded")
loadedAddOns.GW2_UI = true
same(walk(), { "0:3" }, "bagaddons: GW2 UI's buttons on screen")
GwBagFrame, GwBankFrame = window(true), window(true)
eq(BagAddons.BankShown(), true, "bagaddons: GW2 UI's bank open")
module.events.BAG_UPDATE_DELAYED()
ok(GwBagFrame.scripts.OnShow and GwBankFrame.scripts.OnHide, "bagaddons: GW2 UI's windows hooked once made")
GW2_ADDON = {}
eq(BagAddons.Loaded(), false, "bagaddons: GW2 UI without its bags")

-- Bagnon and Bagnonium ------------------------------------------------------------------------

-- A Bagnon window: a real frame once [0] is there, its item group's shown buttons, and which of
-- its bags are cached (another character's, or the bank away from a banker).
local function bagnonWindow(list, cached, isShown)
    local w = window(isShown)
    w[0] = true
    w.ItemGroup = { buttons = list }
    w.IsCached = function(_, bag)
        if bag == nil then
            return cached.all or false
        end
        return cached.all or cached[bag] or false
    end
    return w
end

local function hookable(b)
    b.scripts = {}
    b.HookScript = function(self, script, fn)
        self.scripts[script] = fn
    end
    return b
end

local inventory = bagnonWindow({ hookable(button(0, 1)), button(4, 2), button(1, 5, { visible = false }) }, {}, true)
local bagnonBank = bagnonWindow({ button(6, 3), button(-1, 4) }, { all = true }, true)
local registry = {
    { id = "inventory", frame = inventory },
    { id = "bank", frame = bagnonBank },
    { id = "guild", frame = { id = "guild" } }, -- never made: the registry's own entry
}
Bagnon = {
    Frames = {
        Get = function(_, id)
            for _, entry in ipairs(registry) do
                if entry.id == id then
                    return entry.frame
                end
            end
        end,
    },
}
eq(BagAddons.Loaded(), false, "bagaddons: Bagnon's global without the addon loaded")
loadedAddOns.Bagnon = true
eq(BagAddons.Loaded(), true, "bagaddons: Bagnon loaded")
same(walk(), { "0:1", "4:2" }, "bagaddons: Bagnon's bag buttons on screen, not its bank away from a banker")
eq(BagAddons.BankShown(), false, "bagaddons: Bagnon's bank shown away from a banker isn't open")
bagnonBank.IsCached = function(_, bag)
    return bag == -1 -- at a banker: only the bank's first bag is out of view
end
same(walk(), { "0:1", "4:2", "6:3:bank" }, "bagaddons: Bagnon's bank at a banker")
eq(BagAddons.BankShown(), true, "bagaddons: Bagnon's bank open at a banker")
bagnonBank.shown = false
eq(BagAddons.BankShown(), false, "bagaddons: Bagnon's bank closed")
local before = calls
module.events.BAG_UPDATE_DELAYED()
ok(inventory.scripts.OnShow and bagnonBank.scripts.OnHide, "bagaddons: Bagnon's windows hooked")
local first = inventory.ItemGroup.buttons[1]
ok(first.scripts.OnShow and first.scripts.OnHide, "bagaddons: Bagnon's buttons hooked, for its layouts")
first.scripts.OnShow(first)
eq(calls, before + 2, "bagaddons: told when Bagnon lays its buttons out")
registry[1].frame = { id = "inventory" }
registry[2].frame = { id = "bank" }
same(walk(), {}, "bagaddons: no buttons before Bagnon makes its windows")
loadedAddOns.Bagnon = nil

-- Bagnonium is the same core under its own global.
Bagnonium = Bagnon
loadedAddOns.Bagnonium = true
registry[1].frame = inventory
same(walk(), { "0:1", "4:2" }, "bagaddons: Bagnonium's bag buttons")
loadedAddOns.Bagnonium = nil
eq(BagAddons.Loaded(), false, "bagaddons: none loaded again")

-- BetterBags --------------------------------------------------------------------------------

-- Its items: the button clicked, and the one under it that draws the icon.
local function bbItem(bag, slot, opts)
    return { button = button(bag, slot, opts), _decoration = { art = bag .. ":" .. slot } }
end

local messages = {}
local bbBackpack, bbBank = window(true), window(false)
local betterBags = {
    atBank = false,
    Bags = { Backpack = { frame = bbBackpack }, Bank = { frame = bbBank } },
    modules = {
        ItemFrame = { activeItems = {} },
        Events = {
            RegisterMessage = function(_, message, fn)
                messages[#messages + 1] = message
                messages[message] = fn
            end,
        },
    },
}
function betterBags:GetModule(name)
    return self.modules[name]
end
for _, item in ipairs({ bbItem(0, 2), bbItem(3, 1), bbItem(-3, 0), bbItem(2, 4, { visible = false }), bbItem(7, 9) }) do
    betterBags.modules.ItemFrame.activeItems[item] = true
end
LibStub = function(major)
    return major == "AceAddon-3.0" and {
        GetAddon = function(_, name)
            return name == "BetterBags" and betterBags or nil
        end,
    } or nil
end
eq(BagAddons.Loaded(), false, "bagaddons: BetterBags without the addon loaded")
loadedAddOns.BetterBags = true
eq(BagAddons.Loaded(), true, "bagaddons: BetterBags loaded")
local seen = {}
BagAddons.EachButton(function(_, bag, slot, bank, art)
    seen[#seen + 1] = bag .. ":" .. slot .. (bank and ":bank" or "") .. "@" .. (art and art.art or "")
end)
table.sort(seen)
same(seen, { "0:2@0:2", "3:1@3:1", "7:9:bank@7:9" },
    "bagaddons: BetterBags' items on screen with the button that draws each, not one for no slot")
eq(BagAddons.BankShown(), false, "bagaddons: BetterBags' bank closed")
bbBank.shown = true
eq(BagAddons.BankShown(), false, "bagaddons: BetterBags' bank window isn't open away from a banker")
betterBags.atBank = true
eq(BagAddons.BankShown(), true, "bagaddons: BetterBags' bank open at a banker")
before = calls
module.events.BAG_UPDATE_DELAYED()
same({ messages[1], messages[2] }, { "bags/Draw/Backpack/Done", "bags/Draw/Bank/Done" },
    "bagaddons: BetterBags' draws listened to")
ok(bbBackpack.scripts.OnShow and bbBank.scripts.OnHide, "bagaddons: BetterBags' windows hooked")
messages["bags/Draw/Backpack/Done"]({})
eq(calls, before + 2, "bagaddons: told when BetterBags draws the bags")
module.events.BAG_UPDATE_DELAYED()
eq(#messages, 2, "bagaddons: BetterBags' draws listened to once")
loadedAddOns.BetterBags = nil

-- ArkInventory ------------------------------------------------------------------------------

local BAG, BANK, VAULT = 1, 3, 4
local offline = { [BAG] = false, [BANK] = true, [VAULT] = false }
local arkFrames = {
    { button(0, 6), BAG },
    { button(2, 3, { visible = false }), BAG },
    { button(7, 1), BANK },
    { button(1, 2), VAULT }, -- its guild bank: not container buttons
}
local updated
ArkInventory = {
    Const = { Location = { Bag = BAG, Bank = BANK, Vault = VAULT } },
    API = {
        ItemFrameUpdated = function() end,
        LocationIsOffline = function(loc)
            return offline[loc]
        end,
        ItemFrameLoadedIterate = function()
            local i = 0
            return function()
                i = i + 1
                local entry = arkFrames[i]
                if entry then
                    return "ARKINV_Frame" .. entry[2] .. "Item" .. i, entry[1], entry[2], 1, i
                end
            end
        end,
    },
}
hooksecurefunc = function(t, key, fn)
    local original = t[key]
    t[key] = function(...)
        original(...)
        fn(...)
    end
    updated = t[key]
end
ARKINV_Frame1, ARKINV_Frame3 = window(true), window(true)
eq(BagAddons.Loaded(), false, "bagaddons: ArkInventory without the addon loaded")
loadedAddOns.ArkInventory = true
eq(BagAddons.Loaded(), true, "bagaddons: ArkInventory loaded")
same(walk(), { "0:6" }, "bagaddons: ArkInventory's bag frames on screen, not its bank away from a banker or its guild bank")
eq(BagAddons.BankShown(), false, "bagaddons: ArkInventory's bank shown away from a banker isn't open")
offline[BANK] = false
same(walk(), { "0:6", "7:1:bank" }, "bagaddons: ArkInventory's bank at a banker")
eq(BagAddons.BankShown(), true, "bagaddons: ArkInventory's bank open at a banker")
offline[BAG] = true
same(walk(), { "7:1:bank" }, "bagaddons: not ArkInventory's bags while they show another character's")
before = calls
module.events.BAG_UPDATE_DELAYED()
ok(ARKINV_Frame1.scripts.OnShow and ARKINV_Frame3.scripts.OnHide, "bagaddons: ArkInventory's windows hooked")
ok(updated, "bagaddons: ArkInventory's ItemFrameUpdated hooked through its API")
ArkInventory.API.ItemFrameUpdated(arkFrames[1][1], BAG, 1, 6)
eq(calls, before + 2, "bagaddons: told when ArkInventory draws a frame again")
ArkInventory.API.ItemFrameLoadedIterate = function()
    error("not set up yet")
end
same(walk(), {}, "bagaddons: ArkInventory's walk failing walks nothing")
loadedAddOns.ArkInventory = nil
