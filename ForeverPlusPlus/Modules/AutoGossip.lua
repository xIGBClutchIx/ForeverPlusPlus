-- Auto Gossip: when an NPC's gossip has exactly one option and no quests, pick it, so a banker,
-- vendor, trainer, flight master and the rest open straight away. Each kind of NPC has its own
-- checkbox. Hold Shift while talking to the NPC to skip it.
local _, ns = ...

local ipairs, format, tostring = ipairs, string.format, tostring
local C_GossipInfo, C_TooltipInfo, Enum = C_GossipInfo, C_TooltipInfo, Enum
local IsShiftKeyDown = IsShiftKeyDown

local L = ns.L

local module = ns.NewModule("AutoGossip", L.AUTOGOSSIP_DESC, {
    enabled = true,
    banker = true,
    vendor = true,
    trainer = true,
    taxi = true,
    innkeeper = true,
    auction = true,
    stable = true,
    other = true,
    printOptions = false,
})
module.title = L.AUTOGOSSIP_TITLE

module.options = {
    { key = "banker", name = L.AUTOGOSSIP_BANKER, description = L.AUTOGOSSIP_BANKER_DESC },
    { key = "vendor", name = L.AUTOGOSSIP_VENDOR, description = L.AUTOGOSSIP_VENDOR_DESC },
    { key = "trainer", name = L.AUTOGOSSIP_TRAINER, description = L.AUTOGOSSIP_TRAINER_DESC },
    { key = "taxi", name = L.AUTOGOSSIP_TAXI, description = L.AUTOGOSSIP_TAXI_DESC },
    { key = "innkeeper", name = L.AUTOGOSSIP_INNKEEPER, description = L.AUTOGOSSIP_INNKEEPER_DESC },
    { key = "auction", name = L.AUTOGOSSIP_AUCTION, description = L.AUTOGOSSIP_AUCTION_DESC },
    { key = "stable", name = L.AUTOGOSSIP_STABLE, description = L.AUTOGOSSIP_STABLE_DESC },
    { key = "other", name = L.AUTOGOSSIP_OTHER, description = L.AUTOGOSSIP_OTHER_DESC },
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
    [132052] = "innkeeper", -- BinderGossipIcon
}

-- Auctioneers and stable masters have no icon of their own, so they go by the title under the
-- NPC's name.
local TITLES = {
    [L.AUTOGOSSIP_TITLE_AUCTIONEER] = "auction",
    [L.AUTOGOSSIP_TITLE_STABLE] = "stable",
}

-- The line under the NPC's name ("Auctioneer"), or nil.
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
    if option.spellID or (option.rewards and #option.rewards > 0) then
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

-- One pick per conversation, so a chain of one-option pages (story text) isn't skipped.
local picked = false

local function onGossipShow()
    local options = C_GossipInfo.GetOptions() or {}
    if module.db.printOptions then
        printOptions(options)
    end
    if picked or IsShiftKeyDown() or #options ~= 1 then
        return
    end
    if C_GossipInfo.ForceGossip and C_GossipInfo.ForceGossip() then
        return -- the NPC wants its text read
    end
    local available = C_GossipInfo.GetAvailableQuests() or {}
    local active = C_GossipInfo.GetActiveQuests() or {}
    if #available > 0 or #active > 0 then
        return
    end
    local option = options[1]
    if not isSafe(option) or not module.db[kindOf(option)] then
        return
    end
    picked = true
    C_GossipInfo.SelectOption(option.gossipOptionID)
end

local function onGossipClosed()
    picked = false
end

function module:OnEnable()
    ns.On("GOSSIP_SHOW", onGossipShow)
    ns.On("GOSSIP_CLOSED", onGossipClosed)
end

function module:OnDisable()
    ns.Off("GOSSIP_SHOW", onGossipShow)
    ns.Off("GOSSIP_CLOSED", onGossipClosed)
    picked = false
end
