-- Spell Ranks: marks the spells on your action bars that have a higher rank you already know, so
-- a rank 1 Fireball left on the bar after leveling stands out. A small warning badge (or a red
-- tint) sits over the button, and spell tooltips say which rank is the best you know. /fpp ranks
-- lists them in chat. Action buttons are protected, so the marks are our own frames over them and
-- we only read which spell is in each slot. The game has no combat log for addons, and none is
-- needed: slots and spells change out of combat, and the marks refresh after a short wait.
local _, ns = ...

local _G, ipairs, pairs, tonumber, strmatch, format = _G, ipairs, pairs, tonumber, string.match,
    string.format
local CreateFrame, C_Timer, C_Spell, C_SpellBook, C_Texture = CreateFrame, C_Timer, C_Spell,
    C_SpellBook, C_Texture
local GetActionInfo, InCombatLockdown = GetActionInfo, InCombatLockdown
local GetMacroSpell = GetMacroSpell or (_G.C_Macro and _G.C_Macro.GetMacroSpell)
local TooltipDataProcessor, Enum, GameTooltip = TooltipDataProcessor, Enum, GameTooltip

local L = ns.L
local readable = ns.IsReadable

local module = ns.NewModule("SpellRanks", L.SPELLRANKS_DESC, {
    enabled = true,
    style = "badge", -- "badge" or "tint"
    tooltip = true, -- say the best known rank in spell tooltips
    chat = true,
})
module.title = L.SPELLRANKS_TITLE
module.category = "interface"

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

local known -- spell name -> the highest rank known, or nil until scanned
local marks = setmetatable({}, { __mode = "k" }) -- button -> our overlay frame
local lowSlots = {} -- { bar, slot, spellID, rank, best } for every marked button, in bar order
local lastCount = 0
local timer

local function rankNumber(spellID)
    local text = C_Spell.GetSpellSubtext(spellID)
    local rank = text and readable(text) and strmatch(text, "%d+")
    return rank and tonumber(rank)
end

-- The spell's name and rank, or nil while the game hasn't loaded its data (it is asked for, and
-- SPELL_DATA_LOAD_RESULT refreshes us).
local function spellRank(spellID)
    local name = C_Spell.GetSpellName(spellID)
    if not name or C_Spell.GetSpellSubtext(spellID) == nil then
        if C_Spell.RequestLoadSpellData then
            C_Spell.RequestLoadSpellData(spellID)
        end
        return nil
    end
    return name, rankNumber(spellID)
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
    local kind, id = GetActionInfo(slot)
    if not (kind and readable(id) and id) then
        return nil
    end
    if kind == "macro" then
        return GetMacroSpell and GetMacroSpell(id) or nil
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
    frame:SetFrameLevel(button:GetFrameLevel() + 5)
    frame:EnableMouse(false)
    frame.tint = frame:CreateTexture(nil, "OVERLAY")
    frame.tint:SetPoint("TOPLEFT", 2, -2)
    frame.tint:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.tint:SetColorTexture(1, 0.1, 0.1, 0.4)
    frame.badge = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.badge:SetSize(BADGE_SIZE, BADGE_SIZE)
    frame.badge:SetPoint("TOPRIGHT", 2, 2)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(ALERT_ATLAS) then
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

local function refresh()
    timer = nil
    if not module.enabled then
        return
    end
    if not known then
        local complete
        known, complete = scan()
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

local function queue()
    if module.enabled and not timer then
        timer = C_Timer.NewTimer(DELAY, refresh)
    end
end

local function onSpellsChanged()
    known = nil
    module.announce = true
    queue()
end

local function onLoaded()
    if module.incomplete then
        known = nil
    end
    queue()
end

-- Adds "Best known rank" to a spell's tooltip when a higher rank than this one is known.
local function onTooltip(tooltip, data)
    if not (module.enabled and module.db.tooltip and known and tooltip == GameTooltip
        and data and readable(data.id) and data.id) then
        return
    end
    local name, rank = spellRank(data.id)
    local best = name and rank and known[name]
    if best and rank < best then
        tooltip:AddLine(format(L.SPELLRANKS_BEST, best), 1, 0.82, 0)
    end
end

local hooked = false

function module:OnEnable()
    if not (C_Spell and C_Spell.GetSpellSubtext and C_SpellBook
        and C_SpellBook.GetNumSpellBookSkillLines) then
        return
    end
    self:On("SPELLS_CHANGED", onSpellsChanged)
    self:On("LEARNED_SPELL_IN_SKILL_LINE", onSpellsChanged)
    self:On("PLAYER_LEVEL_UP", onSpellsChanged)
    self:On("ACTIONBAR_SLOT_CHANGED", queue)
    self:On("ACTIONBAR_PAGE_CHANGED", queue)
    self:On("UPDATE_BONUS_ACTIONBAR", queue)
    self:On("UPDATE_SHAPESHIFT_FORM", queue)
    self:On("PLAYER_REGEN_ENABLED", queue) -- buttons created late, when we were in combat
    self:On("SPELL_DATA_LOAD_RESULT", onLoaded)
    if not hooked and TooltipDataProcessor and Enum.TooltipDataType.Spell then
        -- Post calls can't be removed; onTooltip checks module.enabled.
        hooked = true
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, onTooltip)
    end
    known = nil
    lastCount = 0
    queue()
end

function module:OnDisable()
    if timer then
        timer:Cancel()
        timer = nil
    end
    for _, frame in pairs(marks) do
        frame:Hide()
    end
    known, lowSlots = nil, {}
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
