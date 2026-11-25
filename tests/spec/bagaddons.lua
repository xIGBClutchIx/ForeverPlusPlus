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
