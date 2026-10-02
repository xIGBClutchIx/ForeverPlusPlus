-- Forever Quest Icons: a small icon after the name of quests that are new to Forever, the ones
-- that weren't in original Classic, in the quest log on the world map and in a quest giver's
-- list of quests. Idea from ForeverQuestTint; none of its code.
--
-- New quests are told apart by ID. Every quest of original Classic has an ID of 9665 or less
-- (inferred from Classic quest data), so a higher ID is a quest Forever added.
--
-- The icon is an atlas in the title's text. Blizzard measures a row's height from its text before
-- we add to it, so a title the icon would push onto a second line is left without one.
local _, ns = ...

local setmetatable, select, type, format, floor = setmetatable, select, type, string.format,
    math.floor
local C_Texture = C_Texture

local L = ns.L

local module = ns.NewModule("QuestIcons", L.QUESTICONS_DESC, {
    enabled = true,
    icon = "infinity",
})
module.title = L.QUESTICONS_TITLE
module.category = "interface"

module.options = {
    {
        key = "icon", name = L.QUESTICONS_ICON, description = L.QUESTICONS_ICON_DESC,
        choices = {
            { "infinity", L.QUESTICONS_ICON_INFINITY },
            { "logo", L.QUESTICONS_ICON_LOGO },
        },
    },
}

local LAST_CLASSIC_QUEST = 9665

-- Blizzard atlases (the Trading Post's infinity sign and the WoW Forever logo), each with its
-- height and width as a share of the text's font size. Probed: atlas names change between builds.
local ICONS = {
    infinity = { atlas = "perks-infinity", height = 0.7, width = 1.3 },
    logo = { atlas = "logo-wow-forever", height = 1.3, width = 1.3 },
}

local function hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function iconFor(fontString)
    local icon = ICONS[module.db.icon] or ICONS.infinity
    if not hasAtlas(icon.atlas) then
        icon = icon == ICONS.infinity and ICONS.logo or ICONS.infinity
        if not hasAtlas(icon.atlas) then
            return nil
        end
    end
    local _, size = fontString:GetFont()
    size = size or 12
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
local function mark(fontString, questID)
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
    local wanted = text
    local icon = module.enabled and isNew(questID) and iconFor(fontString)
    if icon then
        wanted = text .. " " .. icon
    end
    original[fontString] = text
    if wanted ~= fontString:GetText() then
        local lines = fontString.GetNumLines and fontString:GetNumLines()
        fontString:SetText(wanted)
        if icon and lines and fontString:GetNumLines() > lines then
            wanted = text
            fontString:SetText(text)
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
        mark(button.Text, button.questID)
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
            mark(button:GetFontString(), data.info and data.info.questID)
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
        mark(button:GetFontString(), questID)
    end
end

local function markAll()
    markLog()
    markGossip()
    markGreeting()
end

function module:OnEnable()
    if QuestLogQuests_Update then
        self:Hook("QuestLogQuests_Update", markLog)
    end
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
    markAll()
end

function module:OnOptionChanged()
    markAll()
end
