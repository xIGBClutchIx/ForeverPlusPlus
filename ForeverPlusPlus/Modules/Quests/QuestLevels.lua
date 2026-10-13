-- Quest Levels: puts a quest's level before its name, "[12] Title", the way Forever's quest log and
-- tracker show it, where Blizzard shows only the name: a quest giver's list (the gossip window
-- most NPCs use and the older greeting window) and the title of a quest's details (in the quest
-- window and on the map). Checked in wow-ui-source's forever branch: GossipFrameShared.lua,
-- QuestFrame.lua, and QuestInfo.lua.
--
-- The tag is Blizzard's own, QuestUtilsOverrides.GetQuestTitlePrefix: on Forever (Camelot) that's
-- "[12] ", with a + for elite quests. Blizzard measures a greeting row's height before it sets the
-- title, so a title the tag pushes onto another line can crowd the row below.
local _, ns = ...

local setmetatable, select, type, sub, hooksecurefunc = setmetatable, select, type, string.sub,
    hooksecurefunc

local L = ns.L

local module = ns.NewModule("QuestLevels", L.QUESTLEVELS_DESC, { enabled = true })
module.title = L.QUESTLEVELS_TITLE
module.category = "quests"
module.added = "0.9.0"

-- What a tag looks like, to take ours off a title again.
local TAG_PATTERN = "^%[%d+%+?%] "

---The tag for a quest, such as "[12] ", or nil while its level isn't known.
---@param questID number?
---@param level number? the level the list gave, for when the quest log can't say
---@return string?
local function prefixFor(questID, level)
    if type(questID) ~= "number" or questID <= 0 then
        return nil
    end
    -- The quest log's tag uses the difficulty level, so prefer it.
    local difficulty = C_QuestLog.GetQuestDifficultyLevel and C_QuestLog.GetQuestDifficultyLevel(questID)
    if type(difficulty) == "number" and difficulty > 0 then
        level = difficulty
    end
    if type(level) ~= "number" or level <= 0 then
        return nil
    end
    local blizzard = QuestUtilsOverrides and QuestUtilsOverrides.GetQuestTitlePrefix
    -- Mainline's version gives nil unless its Show Quest Level setting is on; this module is ours.
    return blizzard and blizzard({ questID = questID, difficultyLevel = level }) or "[" .. level .. "] "
end

-- Puts the tag before a title's text, once.
local function tagText(fontString, prefix)
    local text = fontString and fontString:GetText()
    if prefix and type(text) == "string" and sub(text, 1, #prefix) ~= prefix then
        fontString:SetText(prefix .. text)
    end
end

-- Takes our tag off a title.
local function untagText(fontString)
    local text = fontString and fontString:GetText()
    if type(text) == "string" and text:find(TAG_PATTERN) then
        fontString:SetText((text:gsub(TAG_PATTERN, "")))
    end
end

-- The gossip window. Blizzard's Setup formats the title (gray for trivial quests) and sizes the
-- row; doing it again with the tag inside keeps both right, for the rows and the one it measures.
local function tagGossip(button, info)
    local prefix = info and prefixFor(info.questID, info.questLevel)
    if prefix and info.title and button.UpdateTitleForQuest then
        button:UpdateTitleForQuest(info.questID, prefix .. info.title, info.isIgnored, info.isTrivial)
    end
end

-- The greeting window. Its last word on each title is the button's SetText, so the tag goes in
-- right after that, before anything hooked to the panel's OnShow (Forever Quest Icons) sees it.
local hooked = setmetatable({}, { __mode = "k" })
local busy = false

-- The row's quest ID, and its level from the old index functions if this client still has them.
local function greetingQuest(button)
    local index = button:GetID()
    if button.isActive == 1 then
        return GetActiveQuestID and GetActiveQuestID(index), GetActiveLevel and GetActiveLevel(index)
    end
    return GetAvailableQuestInfo and (select(5, GetAvailableQuestInfo(index))),
        GetAvailableLevel and GetAvailableLevel(index)
end

local function tagGreeting(button, text)
    if busy or not module.enabled or type(text) ~= "string" then
        return
    end
    local prefix = prefixFor(greetingQuest(button))
    if prefix and sub(text, 1, #prefix) ~= prefix then
        busy = true
        button:SetText(prefix .. text)
        busy = false
    end
end

-- Runs right after the pool hands out a button and before Blizzard titles it.
local function hookGreetingButtons(pool)
    for button in pool:EnumerateActive() do
        if not hooked[button] then
            hooked[button] = true
            hooksecurefunc(button, "SetText", tagGreeting)
        end
    end
end

-- A quest's details: QuestInfo_Display fills them for a quest giver's offer and reward, and for
-- the quest log on the map. The quest log knows its quest's level even when the API doesn't.
local function logLevel(questID)
    local index = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
    local info = index and C_QuestLog.GetInfo(index)
    return info and (info.difficultyLevel or info.level)
end

local function detailsQuestID()
    if QuestInfoFrame and QuestInfoFrame.questLog then
        return C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()
    end
    return GetQuestID and GetQuestID()
end

local function tagDetails()
    local questID = detailsQuestID()
    tagText(QuestInfoTitleHeader, prefixFor(questID, questID and logLevel(questID)))
end

-- The window that asks for a quest's items before you turn it in.
local function tagProgress()
    local questID = GetQuestID and GetQuestID()
    tagText(QuestProgressTitleText, prefixFor(questID, questID and logLevel(questID)))
end

-- Fills an open list again, with or without the tags, and tags or untags open details.
local function refresh()
    if GossipFrame and GossipFrame.Update and GossipFrame:IsShown() then
        GossipFrame:Update()
    end
    if QuestFrameGreetingPanel and QuestFrameGreetingPanel_OnShow and QuestFrameGreetingPanel:IsShown() then
        QuestFrameGreetingPanel_OnShow()
    end
    if module.enabled then
        tagDetails()
        tagProgress()
    else
        untagText(QuestInfoTitleHeader)
        untagText(QuestProgressTitleText)
    end
end

function module:OnEnable()
    -- Mainline's buttons call these shared methods by name, so hooking them reaches every button.
    self:Hook(GossipSharedAvailableQuestButtonMixin, "Setup", tagGossip)
    self:Hook(GossipSharedActiveQuestButtonMixin, "Setup", tagGossip)
    self:Hook(QuestFrameGreetingPanel and QuestFrameGreetingPanel.titleButtonPool, "Acquire",
        hookGreetingButtons)
    self:Hook("QuestInfo_Display", tagDetails)
    -- The panel's script holds the function it had at load, and Blizzard may call the global
    -- itself, so both are hooked; tagging twice does nothing more.
    self:HookScript(QuestFrameProgressPanel, "OnShow", tagProgress)
    self:Hook("QuestFrameProgressPanel_OnShow", tagProgress)
    refresh()
end

-- Hooks stop by themselves; what's open gets its plain titles back.
function module:OnDisable()
    refresh()
end
