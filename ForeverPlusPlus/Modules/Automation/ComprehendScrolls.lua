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
-- The known scrolls are a seed (ns.GameData); a scroll a patch adds is found by its "Requires
-- Comprehension (N)" line, read in the client's language, and remembered for the account.
--
-- On by default, but only a character who knows Comprehend Scroll (a Mage) gets overlays, so
-- nobody else notices it.
local _, ns = ...

local C_SpellBook, C_TooltipInfo, C_TradeSkillUI = C_SpellBook, C_TooltipInfo, C_TradeSkillUI
local IsSpellKnown, type = IsSpellKnown, type

local L = ns.L

local module = ns.NewModule("ComprehendScrolls", L.COMPREHENDSCROLLS_DESC, {
    enabled = true,
})
module.title = L.COMPREHENDSCROLLS_TITLE
module.category = "automation"
module.added = "0.9.0"

-- Comprehend Scroll, in the General tab of a Mage's spellbook (skill line 3012, Comprehension).
-- **[web]** (wago.tools SpellName and SkillLineAbility for 1.60.1.70374)
local COMPREHEND_SCROLL = ns.GameData.Spell(1296017, "Comprehend Scroll")
local COMPREHENSION = 3012

-- The scrolls that need Comprehension (ItemSparse.RequiredSkill 3012), Mage only. A seed: any
-- other bag item whose tooltip says "Requires Comprehension (N)" is learned as one too.
-- **[web]** (wago.tools ItemSparse for 1.60.1.70374)
local SCROLLS = ns.GameData.New("comprehendScrolls", {
    [211780] = true, [211784] = true, [211785] = true, [211786] = true, [211787] = true,
    [211853] = true, [211854] = true, [211855] = true,
    [213543] = true, [213544] = true, [213545] = true, [213546] = true, [213547] = true,
    [281015] = true, [281016] = true, [281017] = true, [281018] = true,
}, { kind = "item", label = "Comprehend Scrolls" })

local skillName -- Comprehension in the client's language, once known
local checked = {} -- itemID -> true once its tooltip was read this session

function module:IsAvailable()
    return ns.BagClicks.IsAvailable()
end

local function known()
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(COMPREHEND_SCROLL)
    end
    return IsSpellKnown and IsSpellKnown(COMPREHEND_SCROLL)
end

-- Probe: the skill line's own name, when the client has profession info for it.
local function nameFromSkillLine()
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(COMPREHENSION)
        local name = info and info.professionName
        if ns.IsReadable(name) and type(name) == "string" and name ~= "" then
            return name
        end
    end
end

-- Reads a bag item's "Requires <skill> (N)" line. A known scroll teaches the skill's name, in case
-- the skill line didn't; with the name, any other item that needs it is learned as a scroll.
local overlays

local function readTooltip(itemID, bag, slot)
    local data = C_TooltipInfo and C_TooltipInfo.GetBagItem and C_TooltipInfo.GetBagItem(bag, slot)
    if not data then
        return -- not loaded yet; tried again next time
    end
    checked[itemID] = true
    local skill = ns.GameData.TooltipRequires(data)
    if not skill then
        return
    end
    if SCROLLS:Get(itemID) then
        -- A scroll's own line is the surest name, over the skill line's.
        if skill ~= skillName then
            skillName = skill
            checked = { [itemID] = true } -- read the rest again, now with the name
            overlays.refresh()
        end
    elseif skill == skillName then
        SCROLLS:Learn(itemID, true)
    end
end

local function match(itemID, bag, slot)
    if not known() then
        return false
    end
    if not checked[itemID] then
        skillName = skillName or nameFromSkillLine()
        readTooltip(itemID, bag, slot)
    end
    return SCROLLS:Get(itemID)
end

local function click(overlay, _, bag, slot)
    overlay:SetAttribute("type2", "spell")
    overlay:SetAttribute("spell", COMPREHEND_SCROLL)
    overlay:SetAttribute("target-bag", bag)
    overlay:SetAttribute("target-slot", slot)
    return true
end

overlays = ns.BagClicks.New(module, match, click)

function module:OnEnable()
    overlays:Enable()
    self:On("SPELLS_CHANGED", overlays.refresh)
end

function module:OnDisable()
    overlays:Disable()
end
