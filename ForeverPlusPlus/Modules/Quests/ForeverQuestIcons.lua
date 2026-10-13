-- Forever Quest Icons: a small icon after the name of quests that are new to Forever, the ones
-- that weren't in original Classic, in the quest log on the world map, the objective tracker, a
-- quest giver's list of quests, and the title of a quest's details, each with its own checkbox. Idea from ForeverQuestTint; none of
-- its code.
--
-- New quests are told apart by ID. Every quest of original Classic has an ID of 9665 or less
-- (inferred from Classic quest data), so a higher ID is a quest Forever added.
--
-- The icon is an atlas in the title's text. Blizzard measures a row's height from its text before
-- we add to it, so a title the icon would push onto another line is left without one.
local _, ns = ...

local pairs, ipairs, select, type, format, floor = pairs, ipairs, select, type, string.format,
    math.floor

local L = ns.L
local hasAtlas = ns.Frames.HasAtlas

local module = ns.NewModule("ForeverQuestIcons", L.FOREVERQUESTICONS_DESC, {
    enabled = true,
    log = true,
    tracker = true,
    givers = true,
    details = true,
    icon = "infinity",
    -- Icon size in each place, in percent.
    logSize = 80,
    trackerSize = 80,
    giversSize = 80,
    -- The details title's font is larger, so a smaller share keeps the icon near the lists' size.
    detailsSize = 60,
})
module.title = L.FOREVERQUESTICONS_TITLE
module.category = "quests"

-- A place's checkbox, with its size slider in the same row.
local function place(key, name, description, added)
    local sizeKey = key .. "Size"
    return { key = key, name = name, description = description, slider = sizeKey, added = added },
        { key = sizeKey, name = L.FOREVERQUESTICONS_SIZE, description = L.FOREVERQUESTICONS_SIZE_DESC,
            requires = key, min = 50, max = 300, step = 10, format = "%d%%" }
end

module.options = {
    {
        key = "icon", name = L.FOREVERQUESTICONS_ICON, description = L.FOREVERQUESTICONS_ICON_DESC,
        choices = {
            { "infinity", L.FOREVERQUESTICONS_ICON_INFINITY },
            { "logo", L.FOREVERQUESTICONS_ICON_LOGO },
        },
    },
}
for _, args in ipairs({
    { "log", L.FOREVERQUESTICONS_LOG, L.FOREVERQUESTICONS_LOG_DESC },
    { "tracker", L.FOREVERQUESTICONS_TRACKER, L.FOREVERQUESTICONS_TRACKER_DESC },
    { "givers", L.FOREVERQUESTICONS_GIVERS, L.FOREVERQUESTICONS_GIVERS_DESC },
    { "details", L.FOREVERQUESTICONS_DETAILS, L.FOREVERQUESTICONS_DETAILS_DESC, "0.9.0" },
}) do
    local toggle, size = place(args[1], args[2], args[3], args[4])
    module.options[#module.options + 1] = toggle
    module.options[#module.options + 1] = size
end

local LAST_CLASSIC_QUEST = 9665

-- Blizzard atlases (the Trading Post's infinity sign and the WoW Forever logo), each with its
-- height and width at 100% as a share of the text's font size. The logo's square art has room
-- around it, so it's drawn larger. Probed: atlas names change between builds.
local ICONS = {
    infinity = { atlas = "perks-infinity", height = 1, width = 1.9 },
    logo = { atlas = "logo-wow-forever", height = 2.6, width = 2.6 },
}

local function iconFor(fontString, percent)
    local icon = ICONS[module.db.icon] or ICONS.infinity
    if not hasAtlas(icon.atlas) then
        icon = icon == ICONS.infinity and ICONS.logo or ICONS.infinity
        if not hasAtlas(icon.atlas) then
            return nil
        end
    end
    local _, size = fontString:GetFont()
    size = (size or 12) * (percent or 100) / 100
    return format("|A:%s:%d:%d|a", icon.atlas, floor(size * icon.height + 0.5),
        floor(size * icon.width + 0.5))
end

local function isNew(questID)
    return type(questID) == "number" and questID > LAST_CLASSIC_QUEST
end

-- A title without our icon at its end, so a title can be marked again (another icon, or none)
-- without stacking icons, even after something else (Quest Levels) changed the rest of it.
local function plain(text)
    for _, icon in pairs(ICONS) do
        text = text:gsub(" |A:" .. icon.atlas:gsub("%-", "%%-") .. ":%d+:%d+|a$", "")
    end
    return text
end

---Adds the icon to a quest title, or takes it off.
---@param fontString table the title's font string
---@param questID number|nil
---@param place string "log", "tracker", "givers", or "details": its checkbox and size
local function mark(fontString, questID, place)
    if not fontString then
        return
    end
    local text = fontString:GetText()
    if type(text) ~= "string" then
        return
    end
    text = plain(text)
    local db = module.db
    local icon = module.enabled and db[place] and isNew(questID)
        and iconFor(fontString, db[place .. "Size"])
    local wanted = icon and text .. " " .. icon or text
    if wanted ~= fontString:GetText() then
        if icon and fontString.GetNumLines then
            -- Count the lines of the plain title, not of one we marked before.
            fontString:SetText(text)
            local lines = fontString:GetNumLines()
            fontString:SetText(wanted)
            if fontString:GetNumLines() > lines then
                fontString:SetText(text)
            end
        else
            fontString:SetText(wanted)
        end
    end
end

-- The quest log beside the world map.
local function markLog()
    local pool = QuestScrollFrame and QuestScrollFrame.titleFramePool
    if not pool then
        return
    end
    for button in pool:EnumerateActive() do
        mark(button.Text, button.questID, "log")
    end
end

-- The objective tracker: its quest and campaign quest sections, each block's id a quest ID.
local TRACKERS = { "QuestObjectiveTracker", "CampaignQuestObjectiveTracker" }

local function markBlock(block)
    mark(block.HeaderText, block.id, "tracker")
end

local function markTrackerQuest(tracker, quest)
    local block = quest and quest.GetID and tracker.GetExistingBlock
        and tracker:GetExistingBlock(quest:GetID())
    if block then
        markBlock(block)
    end
end

local function markTracker()
    for _, name in ipairs(TRACKERS) do
        local tracker = _G[name]
        if tracker and tracker.EnumerateActiveBlocks then
            tracker:EnumerateActiveBlocks(markBlock)
        end
    end
end

-- A quest giver's list, the gossip way (most NPCs).
local function markGossip()
    local panel = GossipFrame and GossipFrame.GreetingPanel
    local box = panel and panel.ScrollBox
    if not (box and box.ForEachFrame) then
        return
    end
    box:ForEachFrame(function(button)
        local data = button.GetElementData and button:GetElementData()
        local kind = data and data.buttonType
        if kind == GOSSIP_BUTTON_TYPE_ACTIVE_QUEST or kind == GOSSIP_BUTTON_TYPE_AVAILABLE_QUEST then
            mark(button:GetFontString(), data.info and data.info.questID, "givers")
        end
    end)
end

-- A quest giver's list, the older greeting way. Active quests come first; each button's ID is
-- its place in its own list.
local function markGreeting()
    local panel = QuestFrameGreetingPanel
    local pool = panel and panel.titleButtonPool
    if not pool then
        return
    end
    for button in pool:EnumerateActive() do
        local id = button:GetID()
        local questID
        if button.isActive == 1 then
            questID = GetActiveQuestID and GetActiveQuestID(id)
        elseif GetAvailableQuestInfo then
            questID = select(5, GetAvailableQuestInfo(id))
        end
        mark(button:GetFontString(), questID, "givers")
    end
end

-- The title of a quest's details: QuestInfo_Display fills them for a quest giver's offer and
-- reward, and for the quest log on the map.
local function markDetails()
    local questID
    if QuestInfoFrame and QuestInfoFrame.questLog then
        questID = C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()
    else
        questID = GetQuestID and GetQuestID()
    end
    mark(QuestInfoTitleHeader, questID, "details")
end

-- The window that asks for a quest's items before you turn it in.
local function markProgress()
    mark(QuestProgressTitleText, GetQuestID and GetQuestID(), "details")
end

-- The tracker is its own Blizzard addon. Each tracker frame has its own copy of the method, so
-- the frame is hooked.
local function hookTracker()
    for _, name in ipairs(TRACKERS) do
        module:Hook(_G[name], "UpdateSingle", markTrackerQuest)
    end
    markTracker()
end

local function markAll()
    markLog()
    markTracker()
    markGossip()
    markGreeting()
    markDetails()
    markProgress()
end

function module:OnEnable()
    self:Hook("QuestLogQuests_Update", markLog)
    ns.AddOns.WhenLoaded("Blizzard_ObjectiveTracker", hookTracker)
    -- Runs when the list is filled and when it scrolls.
    self:Hook(GossipFrame and GossipFrame.GreetingPanel and GossipFrame.GreetingPanel.ScrollBox,
        "Update", markGossip)
    if QuestFrameGreetingPanel then
        -- The panel's script holds the function it had at load, and Blizzard also calls the
        -- global itself, so both are hooked.
        self:HookScript(QuestFrameGreetingPanel, "OnShow", markGreeting)
        self:Hook("QuestFrameGreetingPanel_OnShow", markGreeting)
    end
    self:Hook("QuestInfo_Display", markDetails)
    self:HookScript(QuestFrameProgressPanel, "OnShow", markProgress)
    self:Hook("QuestFrameProgressPanel_OnShow", markProgress)
    markAll()
end

-- Hooks stop by themselves; the titles showing now get their own text back.
function module:OnDisable()
    ns.AddOns.Cancel("Blizzard_ObjectiveTracker", hookTracker)
    markAll()
end

function module:OnOptionChanged()
    markAll()
end
