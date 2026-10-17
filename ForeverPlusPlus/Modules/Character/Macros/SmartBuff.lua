-- Macros' Smart Buff: one macro that casts the buff your friendly target (or you, with no friendly
-- target) should get from you, at the best rank you know that they can take. Each class has its
-- own buffs in the order it prefers them, and some go only to those who use mana (Arcane
-- Intellect, Blessing of Wisdom) or only to those who don't (Blessing of Might); for yourself,
-- a Paladin's or Druid's talent tree decides. A buff they already have, from anyone, is skipped
-- unless it's about to run out, and a Blessing is skipped when they have one of yours already,
-- since each Paladin's Blessings replace each other. With nothing left to give, the macro casts
-- nothing and its buttons show a red X.
--
-- The macro is rewritten out of combat whenever the target, an aura, a rank, or the talents
-- change. In combat it can't be, and auras can't be read either: a new target there gets what the
-- macro last held, and when that's the wrong buff for them, the buttons show a warning and the
-- game's red error text says so.
local _, ns = ...

local ipairs, format, concat, huge = ipairs, pairs, string.format, table.concat, math.huge
local pcall, tonumber, min = pcall, tonumber, math.min
local UnitClass, UnitLevel, UnitExists, UnitCanAssist = UnitClass, UnitLevel, UnitExists, UnitCanAssist
local UnitIsDeadOrGhost, UnitIsUnit, InCombatLockdown = UnitIsDeadOrGhost, UnitIsUnit, InCombatLockdown
local GetTime, C_Spell, C_UnitAuras, C_Timer = GetTime, C_Spell, C_UnitAuras, C_Timer

local L = ns.L
local Frames, Spellbook, Talents = ns.Frames, ns.Spellbook, ns.Talents
local readable, isTrue = ns.IsReadable, ns.IsTrue

local macros = ns.modules.Macros
local internal = macros.internal
local module = macros:NewPart({
    key = "smartBuff", name = L.MACROS_SMARTBUFF, description = L.MACROS_SMARTBUFF_DESC,
    section = L.MACROS_SMARTBUFF,
}, {
    smartBuff = true,
    smartBuffRefresh = 60, -- seconds left below which a buff counts as missing
})

module:AddOptions({
    {
        key = "smartBuffRefresh", name = L.MACROS_SMARTBUFF_REFRESH,
        description = L.MACROS_SMARTBUFF_REFRESH_DESC,
        min = 0, max = 300, step = 15, format = ns.Text.Seconds,
    },
    ns.ChatOption(L.MACROS_CHAT_DESC),
})

local NAME = L.MACROS_SMARTBUFF_MACRO -- the macro's name, at most 16 letters
local DELAY = 0.1 -- seconds to wait for a burst of changes to settle

-- Each buff's first rank (build 70374, Classic's IDs); the spellbook gives the rest by name.
local SPELLS = ns.GameData.New("smartBuffSpells", {
    [19740] = "Blessing of Might",
    [19742] = "Blessing of Wisdom",
    [20217] = "Blessing of Kings",
    [1243] = "Power Word: Fortitude",
    [14752] = "Divine Spirit",
    [588] = "Inner Fire",
    [1459] = "Arcane Intellect",
    [7302] = "Ice Armor",
    [168] = "Frost Armor",
    [1126] = "Mark of the Wild",
    [467] = "Thorns",
    [16864] = "Omen of Clarity",
    [706] = "Demon Armor",
    [687] = "Demon Skin",
    [324] = "Lightning Shield",
    [6673] = "Battle Shout",
    [19506] = "Trueshot Aura",
}, { kind = "spell", label = L.MACROS_SMARTBUFF })

-- Each class's buffs, the one it prefers first. `who` is who can get it: "any", "mana" (those who
-- use mana), "physical" (those who don't, or a Paladin or Druid of a melee tree), or "self". Of a
-- `group`, a unit holds one from each caster: a Paladin's Blessings, a Mage's or Warlock's armor.
local BUFFS = {
    PALADIN = {
        { id = 19740, who = "physical", group = "blessing" },
        { id = 19742, who = "mana", group = "blessing" },
        { id = 20217, who = "any", group = "blessing" },
    },
    PRIEST = {
        { id = 1243, who = "any" },
        { id = 14752, who = "mana" },
        { id = 588, who = "self" },
    },
    MAGE = {
        { id = 1459, who = "mana" },
        { id = 7302, who = "self", group = "armor" },
        { id = 168, who = "self", group = "armor" },
    },
    DRUID = {
        { id = 1126, who = "any" },
        { id = 467, who = "physical" },
        { id = 16864, who = "self" },
    },
    WARLOCK = {
        { id = 706, who = "self", group = "armor" },
        { id = 687, who = "self", group = "armor" },
    },
    SHAMAN = { { id = 324, who = "self" } },
    WARRIOR = { { id = 6673, who = "self" } },
    HUNTER = { { id = 19506, who = "self" } },
}

-- Classes that don't use mana; anyone else gets the mana buffs.
local PHYSICAL = { WARRIOR = true, ROGUE = true }
-- For yourself, the talent trees that make a hybrid physical, and what an untalented one is.
local OWN_TREES = {
    PALADIN = { physical = { [2] = true, [3] = true }, untalented = "physical" },
    DRUID = { physical = { [2] = true }, untalented = "mana" },
}

local playerClass
local ranks -- spell name -> its known ranks (Lib/Spellbook.lua), or nil until read
local incomplete = false
local written -- what the macro holds: { target = cast or false, self = cast or false, aimed = bool }
local checkTimer

local function classOf(unit)
    local _, class = UnitClass(unit)
    return readable(class) and class or nil
end

local function spellName(entry)
    local name = C_Spell.GetSpellName(entry.id)
    return readable(name) and name or nil
end

-- Whether the class has buffs for others, so the macro aims at a friendly target at all.
local function givesOthers()
    for _, entry in ipairs(BUFFS[playerClass] or {}) do
        if entry.who ~= "self" then
            return true
        end
    end
    return false
end

-- "physical" or "mana": what kind of buffs the unit wants.
local function kindOf(unit, isSelf)
    local trees = isSelf and OWN_TREES[playerClass]
    if trees then
        local tab, total = Talents.Dominant()
        if not tab or total == 0 then
            return trees.untalented
        end
        return trees.physical[tab.index] and "physical" or "mana"
    end
    local class = classOf(unit)
    return class and PHYSICAL[class] and "physical" or "mana"
end

local function fits(entry, kind, isSelf)
    if entry.who == "self" then
        return isSelf
    end
    return entry.who == "any" or entry.who == kind
end

-- The unit's buffs by name: { mine = cast by you, left = seconds left or huge }. Nil while auras
-- can't be read (in combat, mostly), so nothing counts as there.
local function aurasOf(unit)
    if not (ns.AurasReadable() and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
        return nil
    end
    local found, now = {}, GetTime()
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
        if not (ok and aura) then
            break
        end
        local name, expires, source = aura.name, aura.expirationTime, aura.sourceUnit
        if ns.IsText(name, true) then
            local left = readable(expires) and tonumber(expires) or 0
            found[name] = {
                mine = readable(source) and source == "player",
                left = left > 0 and left - now or huge,
            }
        end
    end
    return found
end

-- The macro text that casts the best rank of `name` you know the unit can take: a buff's rank can
-- go on someone up to 10 levels below the level it's learned at.
local function castText(name, unit)
    local list = ranks and ranks[name]
    if not (list and #list > 0) then
        return nil
    end
    local level = UnitLevel(unit)
    level = readable(level) and tonumber(level) or 0
    -- Below every rank's limit, the first rank: the game says why when it's cast.
    local best = list[1]
    for i = #list, 1, -1 do
        local learned = level > 0 and Spellbook.LevelLearned(list[i].id)
        if not learned or learned - 10 <= level then
            best = list[i]
            break
        end
    end
    if best.subtext ~= "" then
        return format("%s(%s)", name, best.subtext)
    end
    return name
end

-- What the unit should get from you: the macro text that casts it, or nil when there's nothing
-- left to give. With `auras`, buffs they have are skipped; the second result is when the soonest
-- of those runs low (seconds from now), to look again then.
local function pick(unit, isSelf, auras)
    local list = BUFFS[playerClass]
    if not list then
        return nil
    end
    local kind = kindOf(unit, isSelf)
    local margin = module.db.smartBuffRefresh or 0
    local soonest = huge
    local function has(name)
        local aura = auras and auras[name]
        if aura and aura.left > margin then
            soonest = min(soonest, aura.left - margin)
            return aura
        end
        return nil
    end
    -- A group the unit has one of yours from is full: another would replace it.
    local full = {}
    for _, entry in ipairs(list) do
        local name = entry.group and spellName(entry)
        local aura = name and has(name)
        if aura and aura.mine then
            full[entry.group] = true
        end
    end
    for _, entry in ipairs(list) do
        if fits(entry, kind, isSelf) and not (entry.group and full[entry.group]) then
            local name = spellName(entry)
            if name and not has(name) then
                local cast = castText(name, unit)
                if cast then
                    return cast, soonest
                end
            end
        end
    end
    return nil, soonest
end

-- Whether the target is someone the macro buffs: a friendly unit other than you, alive.
local function friendlyTarget()
    return UnitExists("target") and not UnitIsUnit("target", "player")
        and isTrue(UnitCanAssist("player", "target")) and not isTrue(UnitIsDeadOrGhost("target"))
end

local function body(target, own, aimed)
    local lines = { "#showtooltip" }
    if aimed and target then
        lines[#lines + 1] = format("/cast [@target,help,nodead] %s%s", target,
            own and format("; [@player] %s", own) or "")
    else
        if aimed then
            lines[#lines + 1] = "/stopmacro [@target,help,nodead]"
        end
        if own then
            lines[#lines + 1] = format("/cast [@player] %s", own)
        end
    end
    return concat(lines, "\n")
end

local refresh

local function lookAgain(seconds)
    if checkTimer then
        checkTimer:Cancel()
        checkTimer = nil
    end
    if seconds < huge then
        checkTimer = C_Timer.NewTimer(seconds + 0.5, function()
            checkTimer = nil
            refresh()
        end)
    end
end

-- In combat: the macro can't change, so say when it now casts the wrong thing.
-- Only on a target change: auras can't be read, so a check for the same target would wrongly
-- count the buffs it already has as missing.
local function checkInCombat()
    if not written then
        return
    end
    local state
    if givesOthers() and friendlyTarget() then
        local should = pick("target", false, nil)
        local holds = written.aimed and written.target or nil
        if should ~= holds then
            state = "stale"
        elseif not holds then
            state = "none"
        end
    elseif not written.self then
        state = "none"
    end
    if state == "stale" then
        Frames.ErrorMessage(L.MACROS_SMARTBUFF_STALE)
    end
    internal.Mark(NAME, state)
end

function refresh(targetChanged)
    if not module.enabled or not playerClass then
        return
    end
    if InCombatLockdown() then
        if targetChanged then
            checkInCombat()
        end
        return
    end
    if not internal.Ready() then
        return
    end
    if not ranks then
        local complete
        ranks, complete = Spellbook.Ranks()
        incomplete = not complete
    end
    local aimed = givesOthers()
    local target, soonTarget = nil, huge
    local hasTarget = aimed and friendlyTarget()
    if hasTarget then
        target, soonTarget = pick("target", false, aurasOf("target"))
    end
    local own, soonOwn = pick("player", true, aurasOf("player"))
    if internal.Write(NAME, body(target, own, hasTarget)) then
        written = { target = target or false, self = own or false, aimed = hasTarget }
        local casts = hasTarget and target or not hasTarget and own
        internal.Mark(NAME, not casts and "none" or nil)
    end
    lookAgain(min(soonTarget or huge, soonOwn or huge))
end

local queue, cancel = Frames.Coalesce(refresh, DELAY)

local function onTarget()
    if InCombatLockdown() then
        refresh(true) -- the warning has to come with the target, not after a wait
    else
        queue()
    end
end

local function onAura(_, unit)
    if unit == "player" or unit == "target" then
        queue()
    end
end

local function onSpells()
    ranks = nil
    queue()
end

local function onLoaded()
    if incomplete then
        ranks = nil
        queue()
    end
end

function module:OnReady()
    queue()
end

function module:OnEnable()
    if not (Spellbook.Available() and C_Spell.GetSpellName) then
        return
    end
    playerClass = classOf("player")
    ranks, written = nil, nil
    self:On("PLAYER_TARGET_CHANGED", onTarget)
    self:On("UNIT_AURA", onAura)
    self:On("UNIT_LEVEL", onAura)
    self:On("SPELLS_CHANGED", onSpells)
    self:On("LEARNED_SPELL_IN_SKILL_LINE", onSpells)
    self:On("PLAYER_LEVEL_UP", onSpells)
    self:On("SPELL_DATA_LOAD_RESULT", onLoaded)
    self:On("PLAYER_REGEN_ENABLED", queue)
    self:On("UPDATE_MACROS", queue) -- deleted or edited by hand: made again
    if ns.HasEvent("TRAIT_CONFIG_UPDATED") then
        self:On("TRAIT_CONFIG_UPDATED", queue)
    end
    queue()
end

function module:OnDisable()
    cancel()
    lookAgain(huge)
    written, ranks = nil, nil
    internal.Delete(NAME)
end

function module:OnOptionChanged(key)
    if key == "smartBuffRefresh" and self.enabled then
        queue()
    end
end

macros.actions = {
    {
        name = L.MACROS_SMARTBUFF_PICKUP, button = L.MACROS_PICKUP_BUTTON,
        description = L.MACROS_SMARTBUFF_PICKUP_DESC,
        fn = function()
            internal.Pickup(NAME)
        end,
    },
}
