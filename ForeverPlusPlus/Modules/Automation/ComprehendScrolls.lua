-- Comprehend Scrolls: right-clicking a Mage's scroll in your bags ("Scroll: CHAP BALK WELLES",
-- read with the Comprehension skill) casts Comprehend Scroll on it, instead of casting the spell
-- from the spellbook and then clicking the scroll.
--
-- The scrolls have no use of their own, and a spell's item cursor can only be answered by a
-- hardware click, so each scroll in Blizzard's bags gets a secure overlay (ns.BagClicks) that
-- casts the spell and then targets its bag slot through Blizzard's own `target-bag` and
-- `target-slot` attributes. Not in combat, when the bags work as Blizzard's. A scroll that needs
-- more skill than the player has is still tried, so the game says why it can't be read.
--
-- On by default, but only Mages have it: other classes don't see it in Settings, and a Mage
-- who hasn't learned the spell gets no overlays.
local _, ns = ...

local C_SpellBook = C_SpellBook
local IsSpellKnown, UnitClass = IsSpellKnown, UnitClass

local L = ns.L

local module = ns.NewModule("ComprehendScrolls", L.COMPREHENDSCROLLS_DESC, {
    enabled = true,
})
module.title = L.COMPREHENDSCROLLS_TITLE
module.category = "automation"
module.added = "0.9.0"

-- Comprehend Scroll, in the General tab of a Mage's spellbook (skill line 3012, Comprehension).
-- **[web]** (wago.tools SpellName and SkillLineAbility for 1.60.1.70374)
local COMPREHEND_SCROLL = 1296017

-- The scrolls that need Comprehension (ItemSparse.RequiredSkill 3012), Mage only.
-- **[web]** (wago.tools ItemSparse for 1.60.1.70374)
local SCROLLS = {
    [211780] = true, [211784] = true, [211785] = true, [211786] = true, [211787] = true,
    [211853] = true, [211854] = true, [211855] = true,
    [213543] = true, [213544] = true, [213545] = true, [213546] = true, [213547] = true,
    [281015] = true, [281016] = true, [281017] = true, [281018] = true,
}

function module:IsAvailable()
    local _, class = UnitClass("player")
    return class == "MAGE" and ns.BagClicks.IsAvailable()
end

local function known()
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(COMPREHEND_SCROLL)
    end
    return IsSpellKnown and IsSpellKnown(COMPREHEND_SCROLL)
end

local function match(itemID)
    return SCROLLS[itemID] and known()
end

local function click(overlay, _, bag, slot)
    overlay:SetAttribute("type2", "spell")
    overlay:SetAttribute("spell", COMPREHEND_SCROLL)
    overlay:SetAttribute("target-bag", bag)
    overlay:SetAttribute("target-slot", slot)
    return true
end

local overlays = ns.BagClicks.New(module, match, click)

function module:OnEnable()
    overlays:Enable()
    self:On("SPELLS_CHANGED", overlays.refresh)
end

function module:OnDisable()
    overlays:Disable()
end
