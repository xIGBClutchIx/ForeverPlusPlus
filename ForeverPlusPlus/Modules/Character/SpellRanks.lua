-- Spell Ranks: marks the spells on your action bars that have a higher rank you already know, so
-- a rank 1 Fireball left on the bar after leveling stands out. A small warning badge (or a red
-- tint) sits over the button, and spell tooltips say which rank is the best you know. /fpp ranks
-- lists them in chat. Action buttons are protected, so the marks are our own frames over them and
-- we only read which spell is in each slot. The game has no combat log for addons, and none is
-- needed: slots and spells change out of combat, and the marks refresh after a short wait.
local _, ns = ...

local _G, ipairs, pairs, tonumber, strmatch, format = _G, ipairs, pairs, tonumber, string.match,
    string.format
local CreateFrame, C_Spell, C_SpellBook = CreateFrame, C_Spell, C_SpellBook
local GetActionInfo, InCombatLockdown = GetActionInfo, InCombatLockdown
local Enum, GameTooltip = Enum, GameTooltip

local L = ns.L
local readable = ns.IsReadable
local Frames = ns.Frames

local module = ns.NewModule("SpellRanks", L.SPELLRANKS_DESC, {
    enabled = true,
    style = "badge", -- "badge" or "tint"
    tooltip = true, -- say the best known rank in spell tooltips
    chat = true,
})
module.title = L.SPELLRANKS_TITLE
module.category = "character"

module.options = {
    {
        key = "style", name = L.SPELLRANKS_STYLE, description = L.SPELLRANKS_STYLE_DESC,
        choices = {
            { "badge", L.SPELLRANKS_STYLE_BADGE },
            { "tint", L.SPELLRANKS_STYLE_TINT },
        },
    },
    { key = "tooltip", name = L.SPELLRANKS_TOOLTIP, description = L.SPELLRANKS_TOOLTIP_DESC },
    ns.ChatOption(L.SPELLRANKS_CHAT_DESC),
}

-- Blizzard's action bars, in the order /fpp ranks numbers them: the button name prefix of each.
local BARS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
    "MultiBar7Button",
}
local BUTTONS = 12
local DELAY = 0.2 -- seconds to wait for a burst of changes to settle

local ALERT_ATLAS = "services-icon-warning" -- Blizzard's yellow warning triangle, when it exists
local ALERT_FILE = "Interface\\DialogFrame\\DialogAlertIcon" -- and its older art
local BADGE_SIZE = 16
-- Levels above the button: past its cooldown, flash, and the other child frames Blizzard stacks
-- on it, so the mark is never drawn under them.
local LEVELS_ABOVE = 20

local known -- spell name -> the highest rank known, or nil until scanned
local marks = setmetatable({}, { __mode = "k" }) -- button -> our overlay frame
local lowSlots = {} -- { bar, slot, spellID, rank, best } for every marked button, in bar order
local lastCount = 0

-- A spell ID's name and rank don't change between spellbook scans, so they're kept until the next
-- one (dropped wherever `known` is): spellID -> { name, rank }.
local rankOf = {}

-- The spell's name and rank, or nil while the game hasn't loaded its data (it is asked for, and
-- SPELL_DATA_LOAD_RESULT refreshes us).
local function spellRank(spellID)
    local hit = rankOf[spellID]
    if hit then
        return hit[1], hit[2]
    end
    local name, text = C_Spell.GetSpellName(spellID), C_Spell.GetSpellSubtext(spellID)
    if not name or text == nil then
        if C_Spell.RequestLoadSpellData then
            C_Spell.RequestLoadSpellData(spellID)
        end
        return nil
    end
    if not readable(text) then
        return name, nil
    end
    local digits = strmatch(text, "%d+")
    local rank = digits and tonumber(digits)
    rankOf[spellID] = { name, rank }
    return name, rank
end

-- Every spell in your spellbook's highest rank by name. Probe: the skill line fields are
-- Mainline's; on Forever they are **Unverified** (docs/forever-api.md).
local function scan()
    local best, complete = {}, true
    local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
        -- Spells of the spec you aren't using can't be put on the bar.
        if info and not (info.offSpecID and info.offSpecID ~= 0) then
            for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(i, bank)
                if item and item.spellID and not item.isPassive then
                    local name, rank = spellRank(item.spellID)
                    if not name then
                        complete = false
                    elseif rank and (not best[name] or rank > best[name]) then
                        best[name] = rank
                    end
                end
            end
        end
    end
    return best, complete
end

-- The spell a slot holds, or nil for an empty slot or an item, or a macro with no spell.
local function slotSpell(slot)
    local kind, id, subType = GetActionInfo(slot)
    if not (kind and readable(id) and id) then
        return nil
    end
    if kind == "macro" then
        -- A macro that shows a spell gives that spell's ID, not the macro's index (Mainline).
        return readable(subType) and subType == "spell" and id or nil
    end
    return kind == "spell" and id or nil
end

local function overlay(button)
    local frame = marks[button]
    if frame or InCombatLockdown() then
        return frame -- creating a child of a protected button waits for combat to end
    end
    frame = CreateFrame("Frame", nil, button)
    frame:SetAllPoints()
    frame:SetFrameLevel(button:GetFrameLevel() + LEVELS_ABOVE)
    frame:EnableMouse(false)
    frame.tint = frame:CreateTexture(nil, "OVERLAY")
    frame.tint:SetPoint("TOPLEFT", 2, -2)
    frame.tint:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.tint:SetColorTexture(1, 0.1, 0.1, 0.4)
    frame.badge = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.badge:SetSize(BADGE_SIZE, BADGE_SIZE)
    -- Inside the button's corner: past its edge, the next button over draws on top of it.
    frame.badge:SetPoint("TOPRIGHT", -1, -1)
    if Frames.HasAtlas(ALERT_ATLAS) then
        frame.badge:SetAtlas(ALERT_ATLAS)
    else
        frame.badge:SetTexture(ALERT_FILE)
    end
    marks[button] = frame
    return frame
end

local function mark(button, on)
    local frame = on and overlay(button) or marks[button]
    if not frame then
        return
    end
    frame:SetShown(on)
    local tint = module.db.style == "tint"
    frame.tint:SetShown(tint)
    frame.badge:SetShown(not tint)
end

-- The spellbook scan's own row on the Profiler page. Profiler.Call keeps one result, so the
-- scan's two come back as a pair.
local Profiler = ns.Profiler
local PART_SCAN = Profiler.Part(module, L.SPELLRANKS_PART_SCAN)
local scanned = {}

local function scanBoth()
    scanned[1], scanned[2] = scan()
    return scanned
end

local function refresh()
    if not module.enabled then
        return
    end
    if not known then
        local result = Profiler.Call(PART_SCAN, scanBoth)
        local complete
        known, complete = result[1], result[2]
        -- Usable as it is; when data was still loading, SPELL_DATA_LOAD_RESULT scans again.
        module.incomplete = not complete
    end
    lowSlots = {}
    for bar, prefix in ipairs(BARS) do
        for slotNumber = 1, BUTTONS do
            local button = _G[prefix .. slotNumber]
            local low = false
            if button then
                local action = button.action
                local spellID = action and readable(action) and slotSpell(action)
                if spellID then
                    local name, rank = spellRank(spellID)
                    local best = name and rank and known[name]
                    if best and rank < best then
                        low = true
                        lowSlots[#lowSlots + 1] = { bar = bar, slot = slotNumber,
                            spellID = spellID, rank = rank, best = best }
                    end
                end
                mark(button, low)
            end
        end
    end
    -- Say it once when a level or a new spell adds marks, not on every bar change.
    if #lowSlots > lastCount and module.announce then
        module:Print(format(L.SPELLRANKS_FOUND, #lowSlots))
    end
    lastCount = #lowSlots
    module.announce = false
end

local schedule, cancel = Frames.Coalesce(refresh, DELAY, module)

local function queue()
    if module.enabled then
        schedule()
    end
end

local function onSpellsChanged()
    known, rankOf = nil, {}
    queue()
end

-- Only a new spell or a level is worth a chat line; SPELLS_CHANGED also fires at every login.
local function onLearned()
    module.announce = true
    onSpellsChanged()
end

local function onLoaded()
    if module.incomplete then
        known, rankOf = nil, {}
    end
    queue()
end

-- Adds "Higher Rank Known: Rank 7" to a spell's tooltip when a higher rank than this one is
-- known, shaped like our item tooltip lines (white label, value at the right edge) so it doesn't
-- read as part of the gold spell description.
local function onTooltip(tooltip, data)
    if not (module.db.tooltip and known and tooltip == GameTooltip
        and data and readable(data.id) and data.id) then
        return
    end
    local name, rank = spellRank(data.id)
    local best = name and rank and known[name]
    if best and rank < best then
        tooltip:AddDoubleLine(L.SPELLRANKS_BEST, format(L.SPELLRANKS_BEST_RANK, best), 1, 1, 1, 1, 1, 1)
    end
end

function module:OnEnable()
    if not (C_Spell and C_Spell.GetSpellSubtext and C_SpellBook
        and C_SpellBook.GetNumSpellBookSkillLines) then
        return
    end
    self:On("SPELLS_CHANGED", onSpellsChanged)
    self:On("LEARNED_SPELL_IN_SKILL_LINE", onLearned)
    self:On("PLAYER_LEVEL_UP", onLearned)
    self:On("ACTIONBAR_SLOT_CHANGED", queue)
    self:On("ACTIONBAR_PAGE_CHANGED", queue)
    self:On("UPDATE_BONUS_ACTIONBAR", queue)
    self:On("UPDATE_SHAPESHIFT_FORM", queue)
    self:On("PLAYER_REGEN_ENABLED", queue) -- buttons created late, when we were in combat
    self:On("SPELL_DATA_LOAD_RESULT", onLoaded)
    self:TooltipPostCall(Enum.TooltipDataType and Enum.TooltipDataType.Spell, onTooltip)
    known, rankOf = nil, {}
    lastCount = 0
    queue()
end

function module:OnDisable()
    cancel()
    for _, frame in pairs(marks) do
        frame:Hide()
    end
    known, lowSlots, rankOf = nil, {}, {}
end

function module:OnOptionChanged(key)
    if key == "style" and self.enabled then
        queue()
    end
end

ns.AddCommand("ranks", "", L.SPELLRANKS_COMMAND, function()
    if not module.enabled then
        ns.Print(L.SPELLRANKS_OFF)
        return
    end
    if #lowSlots == 0 then
        ns.Print(L.SPELLRANKS_NONE)
        return
    end
    for _, entry in ipairs(lowSlots) do
        local link = C_Spell.GetSpellLink(entry.spellID) or C_Spell.GetSpellName(entry.spellID)
        ns.Print(format(L.SPELLRANKS_LINE, entry.bar, entry.slot, link, entry.rank, entry.best))
    end
end)
