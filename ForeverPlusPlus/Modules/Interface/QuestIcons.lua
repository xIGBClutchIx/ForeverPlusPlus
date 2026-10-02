-- Forever Quest Icons: a small icon after the name of quests that are new to Forever, the ones
-- that weren't in original Classic, in the quest log on the world map, the objective tracker, and
-- a quest giver's list of quests, each with its own checkbox. Idea from ForeverQuestTint; none of
-- its code.
--
-- New quests are told apart by ID. Every quest of original Classic has an ID of 9665 or less
-- (inferred from Classic quest data), so a higher ID is a quest Forever added.
--
-- The icon is an atlas in the title's text. Blizzard measures a row's height from its text before
-- we add to it, so a title the icon would push onto another line is left without one.
local _, ns = ...

local setmetatable, ipairs, select, type, format, floor = setmetatable, ipairs, select, type,
    string.format, math.floor
local C_Texture = C_Texture

local L = ns.L

local module = ns.NewModule("QuestIcons", L.QUESTICONS_DESC, {
    enabled = true,
    log = true,
    tracker = true,
    givers = true,
    icon = "infinity",
    -- Icon size in each place, in percent.
    logSize = 80,
    trackerSize = 80,
    giversSize = 80,
})
module.title = L.QUESTICONS_TITLE
module.category = "interface"

-- A place's checkbox, with its size slider in the same row.
local function place(key, name, description)
    local sizeKey = key .. "Size"
    return { key = key, name = name, description = description, slider = sizeKey },
        { key = sizeKey, name = L.QUESTICONS_SIZE, description = L.QUESTICONS_SIZE_DESC,
            requires = key, min = 50, max = 300, step = 10, format = "%d%%" }
end

module.options = {
    {
        key = "icon", name = L.QUESTICONS_ICON, description = L.QUESTICONS_ICON_DESC,
        choices = {
            { "infinity", L.QUESTICONS_ICON_INFINITY },
            { "logo", L.QUESTICONS_ICON_LOGO },
        },
    },
}
for _, args in ipairs({
    { "log", L.QUESTICONS_LOG, L.QUESTICONS_LOG_DESC },
    { "tracker", L.QUESTICONS_TRACKER, L.QUESTICONS_TRACKER_DESC },
    { "givers", L.QUESTICONS_GIVERS, L.QUESTICONS_GIVERS_DESC },
}) do
    local toggle, size = place(args[1], args[2], args[3])
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

local function hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

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

-- The text Blizzard gave each title, and the text we set, so a title we marked can be marked
-- again (another icon, or none) without stacking icons.
local original = setmetatable({}, { __mode = "k" })
local marked = setmetatable({}, { __mode = "k" })

---Adds the icon to a quest title, or takes it off.
---@param fontString table the title's font string
---@param questID number|nil
---@param place string "log", "tracker", or "givers": its checkbox and size
local function mark(fontString, questID, place)
    if not fontString then
        return
    end
    local text = fontString:GetText()
    if not text then
        return
    end
    if marked[fontString] == text then
        text = original[fontString]
    end
    original[fontString] = text
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
                wanted = text
                fontString:SetText(text)
            end
        else
            fontString:SetText(wanted)
        end
    end
    marked[fontString] = wanted
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

-- The tracker is its own Blizzard addon. Each tracker frame has its own copy of the method, so
-- the frame is hooked.
local function hookTracker()
    for _, name in ipairs(TRACKERS) do
        local tracker = _G[name]
        if tracker and tracker.UpdateSingle then
            module:Hook(tracker, "UpdateSingle", markTrackerQuest)
        end
    end
    markTracker()
end

local function markAll()
    markLog()
    markTracker()
    markGossip()
    markGreeting()
end

function module:OnEnable()
    if QuestLogQuests_Update then
        self:Hook("QuestLogQuests_Update", markLog)
    end
    ns.AddOns.WhenLoaded("Blizzard_ObjectiveTracker", hookTracker)
    local box = GossipFrame and GossipFrame.GreetingPanel and GossipFrame.GreetingPanel.ScrollBox
    if box then
        -- Runs when the list is filled and when it scrolls.
        self:Hook(box, "Update", markGossip)
    end
    if QuestFrameGreetingPanel then
        -- The panel's script holds the function it had at load, and Blizzard also calls the
        -- global itself, so both are hooked.
        self:HookScript(QuestFrameGreetingPanel, "OnShow", markGreeting)
        if QuestFrameGreetingPanel_OnShow then
            self:Hook("QuestFrameGreetingPanel_OnShow", markGreeting)
        end
    end
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
