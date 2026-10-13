-- Quest Giver Levels: puts a quest's level before its name in a quest giver's list, "[12] Title",
-- the way Forever's quest log and tracker show it, in both the gossip window most NPCs use and
-- the older greeting window. Blizzard's lists show only the name (wow-ui-source, forever branch:
-- GossipFrameShared.lua and QuestFrame.lua).
--
-- The tag is Blizzard's own, QuestUtilsOverrides.GetQuestTitlePrefix: on Forever (Camelot) that's
-- "[12] ", with a + for elite quests. Blizzard measures a greeting row's height before it sets the
-- title, so a title the tag pushes onto another line can crowd the row below.
local _, ns = ...

local setmetatable, select, type, sub, hooksecurefunc = setmetatable, select, type, string.sub,
    hooksecurefunc

local L = ns.L

local module = ns.NewModule("QuestGiverLevels", L.QUESTGIVERLEVELS_DESC, { enabled = true })
module.title = L.QUESTGIVERLEVELS_TITLE
module.category = "quests"
module.added = "0.9.0"

---The tag for a quest, such as "[12] ", or nil while its level isn't known.
---@param questID number?
---@param level number? the level the list gave, for when the quest log can't say
---@return string?
local function prefixFor(questID, level)
    if type(questID) ~= "number" then
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

-- Fills an open list again, with or without the tags.
local function refresh()
    if GossipFrame and GossipFrame.Update and GossipFrame:IsShown() then
        GossipFrame:Update()
    end
    if QuestFrameGreetingPanel and QuestFrameGreetingPanel_OnShow and QuestFrameGreetingPanel:IsShown() then
        QuestFrameGreetingPanel_OnShow()
    end
end

function module:OnEnable()
    -- Mainline's buttons call these shared methods by name, so hooking them reaches every button.
    self:Hook(GossipSharedAvailableQuestButtonMixin, "Setup", tagGossip)
    self:Hook(GossipSharedActiveQuestButtonMixin, "Setup", tagGossip)
    self:Hook(QuestFrameGreetingPanel and QuestFrameGreetingPanel.titleButtonPool, "Acquire",
        hookGreetingButtons)
    refresh()
end

-- Hooks stop by themselves; an open list gets its plain titles back.
function module:OnDisable()
    refresh()
end
