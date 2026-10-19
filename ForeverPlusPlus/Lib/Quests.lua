-- Which quest Blizzard's quest windows show, and its level from the quest log, for the quest
-- modules that tag or mark quest titles. The window functions are read when called, since some
-- (the greeting's level functions) are Classic's and may be gone on a patch. Probe each.
local _, ns = ...

local select, type = select, type

local Quests = {}
ns.Quests = Quests

---The quest's level as the quest log has it, or nil while the log doesn't have it (or the quest
---isn't in it).
---@param questID number?
---@return number?
function Quests.Level(questID)
    local log = C_QuestLog
    if not (questID and log and log.GetLogIndexForQuestID) then
        return nil
    end
    local index = log.GetLogIndexForQuestID(questID)
    local info = index and log.GetInfo(index)
    local level = info and (info.difficultyLevel or info.level)
    if type(level) == "number" and level > 0 then
        return level
    end
end

---The quest in the details pane. QuestInfo_Display fills it for a quest giver's offer and reward,
---and for the quest log on the map, where it's the log's selected quest.
---@return number?
function Quests.DetailsID()
    if QuestInfoFrame and QuestInfoFrame.questLog then
        return C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()
    end
    return GetQuestID and GetQuestID()
end

---The quest giver's quest, in the window that asks for its items before you turn it in.
---@return number?
function Quests.GiverID()
    return GetQuestID and GetQuestID()
end

---A title button in a quest giver's older greeting list: its quest ID, and its level while the
---client still has the old index functions. Active quests come first; each button's ID is its
---place in its own list.
---@param button table
---@return number? questID
---@return number? level
function Quests.GreetingButton(button)
    local index = button:GetID()
    if button.isActive == 1 then
        return GetActiveQuestID and GetActiveQuestID(index),
            GetActiveLevel and GetActiveLevel(index)
    end
    return GetAvailableQuestInfo and (select(5, GetAvailableQuestInfo(index))),
        GetAvailableLevel and GetAvailableLevel(index)
end
