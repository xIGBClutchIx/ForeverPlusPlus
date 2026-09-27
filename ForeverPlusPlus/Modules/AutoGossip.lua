-- Auto Gossip: when an NPC's gossip has exactly one option and no quests, pick it, so a banker,
-- vendor, trainer, flight master and the rest open straight away. Each kind of NPC has its own
-- checkbox. Hold Shift while talking to the NPC to skip it (unless Shift Skips is off).
local _, ns = ...

local ipairs, format, tostring = ipairs, string.format, tostring
local C_GossipInfo, C_TooltipInfo, Enum = C_GossipInfo, C_TooltipInfo, Enum
local IsShiftKeyDown, GetTime = IsShiftKeyDown, GetTime

local L = ns.L

local module = ns.NewModule("AutoGossip", L.AUTOGOSSIP_DESC, {
    enabled = true,
    banker = true,
    vendor = true,
    trainer = true,
    taxi = true,
    stable = true,
    other = true,
    shiftSkips = true,
    printOptions = false,
})
module.title = L.AUTOGOSSIP_TITLE
module.category = "automation"

local GENERAL, NPCS = L.AUTOGOSSIP_SECTION_GENERAL, L.AUTOGOSSIP_SECTION_NPCS

module.options = {
    { key = "shiftSkips", name = L.AUTOGOSSIP_SHIFT, description = L.AUTOGOSSIP_SHIFT_DESC, section = GENERAL },
    -- Alphabetical, with the catch-all last.
    { key = "banker", name = L.AUTOGOSSIP_BANKER, description = L.AUTOGOSSIP_BANKER_DESC, section = NPCS },
    { key = "taxi", name = L.AUTOGOSSIP_TAXI, description = L.AUTOGOSSIP_TAXI_DESC, section = NPCS },
    { key = "stable", name = L.AUTOGOSSIP_STABLE, description = L.AUTOGOSSIP_STABLE_DESC, section = NPCS },
    { key = "trainer", name = L.AUTOGOSSIP_TRAINER, description = L.AUTOGOSSIP_TRAINER_DESC, section = NPCS },
    { key = "vendor", name = L.AUTOGOSSIP_VENDOR, description = L.AUTOGOSSIP_VENDOR_DESC, section = NPCS },
    { key = "other", name = L.AUTOGOSSIP_OTHER, description = L.AUTOGOSSIP_OTHER_DESC, section = NPCS },
    {
        key = "printOptions",
        name = L.AUTOGOSSIP_PRINT,
        description = L.AUTOGOSSIP_PRINT_DESC,
        debug = true,
    },
}

-- The kind of NPC, from the option's gossip icon. These are the Classic GossipFrame icon file
-- IDs; Forever sending the same ones is Unverified (turn on the Debug option to see them).
local ICONS = {
    [132050] = "banker", -- BankerGossipIcon
    [132060] = "vendor", -- VendorGossipIcon, also repair vendors
    [132058] = "trainer", -- TrainerGossipIcon
    [132057] = "taxi", -- TaxiGossipIcon
}

-- Stable masters have no icon of their own, so they go by the title under the NPC's name.
-- (Auctioneers on Forever open the auction house without any gossip.)
local TITLES = {
    [L.AUTOGOSSIP_TITLE_STABLE] = "stable",
}

-- The line under the NPC's name ("Banker"), or nil.
local function npcTitle()
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then
        return nil
    end
    local data = C_TooltipInfo.GetUnit("npc")
    local line = data and data.lines and data.lines[2]
    local text = line and line.leftText
    if ns.IsReadable(text) and text then
        return text
    end
end

local function kindOf(option)
    return ICONS[option.icon] or TITLES[npcTitle() or ""] or "other"
end

-- An option that is safe to pick without asking: available, and with no cost, reward, or spell
-- attached. Options that cost gold also ask first (GOSSIP_CONFIRM); that popup stays for the
-- player, since this only picks the option, never confirms.
local AVAILABLE = Enum.GossipOptionStatus and Enum.GossipOptionStatus.Available or 0

local function isSafe(option)
    if option.status and option.status ~= AVAILABLE then
        return false
    end
    if option.spellID or (option.rewards and #option.rewards > 0) or not option.gossipOptionID then
        return false
    end
    -- Blizzard picks these itself; picking again would select twice.
    return not option.selectOptionWhenOnlyOption
end

local function printOptions(options)
    ns.Print(format(L.AUTOGOSSIP_PRINT_HEADER, tostring(npcTitle())))
    for _, option in ipairs(options) do
        ns.Print(format(L.AUTOGOSSIP_PRINT_LINE, tostring(option.gossipOptionID),
            tostring(option.icon), tostring(option.status), tostring(option.flags),
            tostring(option.name)))
    end
end

-- A page that shows right after a pick is the next page of the same conversation (story text),
-- so leave it for the player to read. A time, not GOSSIP_CLOSED: that doesn't always fire when
-- the pick opens another window (bank, flight map), which left later NPCs never picked.
local REPICK_DELAY = 1
local lastPick = 0

-- Why the only option isn't picked, or nil to pick it.
local function skipReason(options)
    if GetTime() - lastPick < REPICK_DELAY then
        return "just picked"
    elseif module.db.shiftSkips and IsShiftKeyDown() then
        return "Shift"
    elseif #options ~= 1 then
        return "options"
    end
    local available = C_GossipInfo.GetAvailableQuests() or {}
    local active = C_GossipInfo.GetActiveQuests() or {}
    if #available > 0 or #active > 0 then
        return "quests"
    elseif not isSafe(options[1]) then
        return "not safe"
    end
    local kind = kindOf(options[1])
    if not module.db[kind] then
        return kind .. " off"
    end
    -- ForceGossip asks for the text to be read. Forever sets it on flight masters too, so it only
    -- holds back NPCs that aren't a known service.
    if kind == "other" and C_GossipInfo.ForceGossip and C_GossipInfo.ForceGossip() then
        return "ForceGossip"
    end
end

local function onGossipShow()
    local options = C_GossipInfo.GetOptions() or {}
    local reason = skipReason(options)
    if module.db.printOptions then
        printOptions(options)
        ns.Print(format(L.AUTOGOSSIP_PRINT_RESULT, reason or kindOf(options[1])))
    end
    if reason then
        return
    end
    lastPick = GetTime()
    C_GossipInfo.SelectOption(options[1].gossipOptionID)
end

function module:OnEnable()
    self:On("GOSSIP_SHOW", onGossipShow)
end

function module:OnDisable()
    lastPick = 0
end
