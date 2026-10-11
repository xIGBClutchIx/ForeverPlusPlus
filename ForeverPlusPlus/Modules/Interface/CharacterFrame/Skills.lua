-- Character Window's equipped weapon skills: on the Skills tab, the bars of the weapon skills for
-- the weapons in the main hand, off hand, and ranged slots are green instead of Blizzard's blue,
-- in the list and in the selected skill's details. CharacterFrame.lua turns them on and off.
local _, ns = ...

local _G, pairs, type = _G, pairs, type
local GetInventoryItemID, GetInventorySlotInfo, pcall = GetInventoryItemID, GetInventorySlotInfo, pcall

local module = ns.modules.CharacterFrame
local internal = module.internal

local WEAPON = 2 -- Enum.ItemClass.Weapon; shields are armor, so their subclass is no weapon's

-- Weapon item subclass -> its skill line, as Blizzard's SkillsFrame.lua (Forever only) lists the
-- weapon skill lines. Fist weapons share Unarmed's line there.
local SKILL_LINES = {
    [0] = 44, -- One-Handed Axes
    [1] = 172, -- Two-Handed Axes
    [2] = 45, -- Bows
    [3] = 46, -- Guns
    [4] = 54, -- One-Handed Maces
    [5] = 160, -- Two-Handed Maces
    [6] = 229, -- Polearms
    [7] = 43, -- One-Handed Swords
    [8] = 55, -- Two-Handed Swords
    [10] = 136, -- Staves
    [13] = 162, -- Fist Weapons
    [15] = 173, -- Daggers
    [16] = 176, -- Thrown
    [18] = 226, -- Crossbows
    [19] = 228, -- Wands
}

local SLOTS = { "MainHandSlot", "SecondaryHandSlot", "RangedSlot" } -- Ranged only if Forever has it

local started
local slots -- inventory slot ids of SLOTS that exist
local equipped = {} -- skill line -> true, for the weapons worn now

local function on()
    return module.enabled and module.db.weaponSkills
end

local function readEquipped()
    equipped = {}
    for i = 1, #slots do
        local item = GetInventoryItemID("player", slots[i])
        if item then
            local _, _, _, _, _, class, subclass = _G.C_Item.GetItemInfoInstant(item)
            local line = class == WEAPON and SKILL_LINES[subclass]
            if line then
                equipped[line] = true
            end
        end
    end
end

-- Green for an equipped weapon's skill, Blizzard's blue otherwise. A new fill texture takes its
-- atlas's size, so the bar's fill goes back on after it, as Blizzard's own InitializeBar does.
local function paintBar(bar, info)
    if not (bar and bar.SetFillTextureByColorType and info and info.skillID) then
        return
    end
    local rank, maximum = info.rank, info.maxRank
    if type(rank) ~= "number" or type(maximum) ~= "number" then
        return
    end
    local types = _G.ColoredProgressBarMixin.ColorType
    bar:SetFillTextureByColorType(on() and equipped[info.skillID] and types.Green or types.Blue)
    bar:UpdateBarValues(0, maximum, rank)
end

local function paintEntry(_, entry, info)
    if module.enabled and info and not info.isHeader and entry.Content then
        paintBar(entry.Content.SkillsBar, info)
    end
end

local function paintDetail(detail, info)
    paintBar(detail.RankBar, info)
end

local function repaint()
    if not (started and _G.SkillsFrame:IsShown()) then
        return
    end
    local frame = _G.SkillsFrame
    frame.ScrollBox:ForEachFrame(function(entry, info)
        paintEntry(nil, entry, info)
    end)
    local detail = frame.SkillDetailFrame
    if detail and detail.GetSelectedSkillInfo then
        local info = detail:GetSelectedSkillInfo()
        if info then
            paintDetail(detail, info)
        end
    end
end

local function start()
    local frame = _G.SkillsFrame
    if started or not (frame and frame.ScrollBox and _G.ScrollBoxListMixin
        and _G.ColoredProgressBarMixin and _G.C_Item and _G.C_Item.GetItemInfoInstant) then
        return
    end
    started = true
    slots = {}
    for i = 1, #SLOTS do
        local ok, slot = pcall(GetInventorySlotInfo, SLOTS[i])
        if ok and slot then
            slots[#slots + 1] = slot
        end
    end
    frame.ScrollBox:RegisterCallback(_G.ScrollBoxListMixin.Event.OnInitializedFrame, paintEntry, module)
    if frame.SkillDetailFrame and frame.SkillDetailFrame.RefreshRankBar then
        module:Hook(frame.SkillDetailFrame, "RefreshRankBar", paintDetail)
    end
end

local function onEquipment()
    if started then
        readEquipped()
        repaint()
    end
end

---Colors the skill bars to match the module and its `weaponSkills` option. Once the character
---frame has loaded.
function internal.updateWeaponSkills()
    if on() then
        start()
    end
    if started then
        readEquipped()
        repaint()
    end
end

-- The events the colors want while the module is on.
function internal.enableWeaponSkills()
    module:On("PLAYER_EQUIPMENT_CHANGED", onEquipment)
end
