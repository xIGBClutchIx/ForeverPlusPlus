-- Item Tooltips' quests: which quests an item is for, just above the prices, from the QuestieDB
-- addon (ns.QuestieDB): a quest the item starts, asks for, or that hands it over to be used. A
-- "Quest:" line for each, its level and name in the quest's difficulty color as the quest log has
-- it, "(in log)" in gray for one in the quest log, and the whole line gray with "(done)" for one
-- already done, so an old quest item that can go stands out. Quests the player's race or class
-- can't take aren't named, which leaves out the other side's.
--
-- The quests in the log come first, then the ones not done, then the done ones, each kind with
-- its own checkbox, at most Lines of them (three by default) and a gray count of the rest. An item more than five of the player's quests ask for is a
-- common one (cloth, bars, the war effort's goods): only the quests in the log are named for it.
--
-- QuestieDB names an item's quests from the quests' side, so the index of items to quests is
-- built a few hundred quests a frame once the part is on; until it's whole there's no line.
local _, ns = ...

local ipairs, sort, format = ipairs, table.sort, string.format
local UnitRace, UnitClass, GetQuestDifficultyColor = UnitRace, UnitClass, GetQuestDifficultyColor
local C_QuestLog = C_QuestLog
local GRAY_FONT_COLOR = GRAY_FONT_COLOR

local L = ns.L
local ItemTooltip, QuestieDB, Quests, Colors, Text = ns.ItemTooltip, ns.QuestieDB, ns.Quests, ns.Colors, ns.Text

local module = ns.modules.ItemTooltips:NewPart({
    key = "itemQuests", name = L.ITEMTOOLTIPS_ITEMQUESTS, description = L.ITEMQUESTS_DESC,
    section = L.ITEMQUESTS_TITLE, added = "1.10.0",
    available = QuestieDB.IsAvailable, needs = format(L.SETTINGS_NEEDS_ADDON, "QuestieDB"),
}, {
    itemQuests = true,
    questLines = 3, -- quests named on one tooltip; a count of the rest after them
    questsInLog = true, -- name the quests in the quest log
    questsOpen = true, -- name the quests neither in the log nor done
    questsDone = true, -- name the quests already done
})

module:AddOptions({
    {
        key = "questLines", name = L.ITEMQUESTS_LINES, description = L.ITEMQUESTS_LINES_DESC,
        min = 1, max = 10, step = 1, format = "%d",
    },
    { key = "questsInLog", name = L.ITEMQUESTS_SHOW_IN_LOG, description = L.ITEMQUESTS_SHOW_IN_LOG_DESC },
    { key = "questsOpen", name = L.ITEMQUESTS_SHOW_OPEN, description = L.ITEMQUESTS_SHOW_OPEN_DESC },
    { key = "questsDone", name = L.ITEMQUESTS_SHOW_DONE, description = L.ITEMQUESTS_SHOW_DONE_DESC },
})

local COMMON = 5 -- more of the player's quests than this, and only the ones in the log are named
local STEP = 250 -- quests read into the index a frame

-- Where a quest stands for the player, in the order they're listed.
local IN_LOG, OPEN, DONE = 1, 2, 3

-- The index ---------------------------------------------------------------------------------------

local timer = ns.Frames.Timer(module)

local function index()
    if not QuestieDB.IndexItemQuests(STEP) then
        timer:Start(0, index)
    end
end

-- Quests --------------------------------------------------------------------------------------------

-- Quest ID -> what the line needs of it, or false for one QuestieDB doesn't have. Kept: its data
-- can't change without a reload.
local quests = {}

local function questInfo(questID)
    local info = quests[questID]
    if info == nil then
        local quest = QuestieDB.Quest(questID)
        info = quest and {
            name = quest.name, level = quest.level, races = quest.races, classes = quest.classes,
            repeatable = quest.repeatable,
        } or false
        quests[questID] = info
    end
    return info or nil
end

local function stateOf(questID, info)
    local log = C_QuestLog
    if log.GetLogIndexForQuestID and log.GetLogIndexForQuestID(questID) then
        return IN_LOG
    end
    -- A repeatable quest done once is still one to do again.
    if not info.repeatable and log.IsQuestFlaggedCompleted and log.IsQuestFlaggedCompleted(questID) then
        return DONE
    end
    return OPEN
end

-- The player's quests of an item's, with where each stands, in the order they're listed.
local function playerQuests(itemID)
    local list = QuestieDB.ItemQuests(itemID)
    if not list or #list == 0 then
        return nil
    end
    local _, _, race = UnitRace("player")
    local _, _, class = UnitClass("player")
    local out = {}
    for _, entry in ipairs(list) do
        local info = questInfo(entry.id)
        if info and (not race or QuestieDB.HasRace(info.races, race))
            and (not class or QuestieDB.HasClass(info.classes, class)) then
            out[#out + 1] = { id = entry.id, info = info, state = stateOf(entry.id, info), level = info.level or 0 }
        end
    end
    sort(out, function(a, b)
        if a.state ~= b.state then
            return a.state < b.state
        elseif a.level ~= b.level then
            return a.level < b.level
        end
        return a.id < b.id
    end)
    return out
end

-- "[12] Name" in the quest's difficulty color, with "(in log)" in gray after one in the log; all
-- gray with "(done)" for one done. Nil for a quest with no name.
local function questText(entry)
    local questID, info = entry.id, entry.info
    local name = Quests.Title(questID, info.name)
    if not name then
        return nil
    end
    local level = Quests.DifficultyLevel(questID, info.level)
    local text = level and format(L.ITEMQUESTS_LEVEL_NAME, Quests.LevelTag(questID, level), name) or name
    if entry.state == DONE then
        return GRAY_FONT_COLOR:WrapTextInColorCode(format(L.ITEMQUESTS_STATE, text, L.ITEMQUESTS_DONE))
    end
    local color = level and GetQuestDifficultyColor and GetQuestDifficultyColor(level)
    if color then
        text = Colors.Text(color, text)
    end
    if entry.state == IN_LOG then
        text = format(L.ITEMQUESTS_STATE, text, GRAY_FONT_COLOR:WrapTextInColorCode(L.ITEMQUESTS_IN_LOG))
    end
    return text
end

-- Tooltip -------------------------------------------------------------------------------------------

local function addQuests(tooltip, data)
    local itemID = module.enabled and ItemTooltip.ItemID(data)
    local list = itemID and playerQuests(itemID)
    if not list then
        return
    end
    local db = module.db
    local align = db.align
    local lines = db.questLines
    local wanted = { [IN_LOG] = db.questsInLog, [OPEN] = db.questsOpen, [DONE] = db.questsDone }
    local common = #list > COMMON
    local shown, more = 0, 0
    for _, entry in ipairs(list) do
        if common and entry.state ~= IN_LOG then
            break -- the log's come first
        end
        local text = wanted[entry.state] and questText(entry)
        if text then
            if shown < lines then
                shown = shown + 1
                ItemTooltip.AddInfo(tooltip, L.ITEMQUESTS_LINE, text, align, "white")
            else
                more = more + 1
            end
        end
    end
    if more > 0 then
        ItemTooltip.AddInfo(tooltip, L.ITEMQUESTS_LINE, format(Text.Plural(L.ITEMQUESTS_MORE, more), more), align, "gray")
    end
end

function module:OnEnable()
    QuestieDB.OnReady(index)
    -- The hook can't be removed; addQuests checks the part is on.
    ItemTooltip.OnInfo(addQuests, module)
end

function module:OnDisable()
    QuestieDB.Cancel(index)
end
