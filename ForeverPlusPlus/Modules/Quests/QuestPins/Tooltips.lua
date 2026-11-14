-- Quest Pins on an NPC's tooltip: the quests it offers that the player can take (!) and the quests
-- in the log that are ready to turn in to it (?), from QuestieDB's lists for that NPC.
local _, ns = ...

local type, ipairs, format, sort = type, ipairs, string.format, table.sort
local C_QuestLog, GameTooltip = C_QuestLog, GameTooltip
local GetQuestDifficultyColor, NORMAL_FONT_COLOR = GetQuestDifficultyColor, NORMAL_FONT_COLOR

local QuestieDB = ns.QuestieDB
local module = ns.modules.QuestPins
local internal = module.internal

local function row(id, marker)
    local title = internal.Title(id)
    local level = internal.Level(id)
    return { id = id, level = level, text = format("%s %s%s", marker, level and (ns.Quests.LevelTag(id, level) .. " ") or "", title) }
end

local function onUnit(tooltip, data)
    local db = module.db
    if tooltip ~= GameTooltip or not db.npcTooltips or not internal.ready
        or (tooltip.IsForbidden and tooltip:IsForbidden()) or ns.Instances.Here() then
        return
    end
    local id = data and ns.Units.NpcID(data.guid)
    local npc = id and QuestieDB.Npc(id)
    if not npc then
        return
    end
    local rows = {}
    for _, questID in ipairs(npc.questStarts) do
        local ok, note = internal.Check(questID)
        -- Not an upcoming quest: the NPC doesn't offer it yet.
        if ok and note ~= "upcoming" and internal.FriendlyToPlayer(npc.friendlyTo) then
            rows[#rows + 1] = row(questID, "!")
        end
    end
    for _, questID in ipairs(npc.questEnds) do
        if internal.InLog(questID) and not internal.Done(questID) and not db.hidden[questID]
            and C_QuestLog.IsComplete(questID) then
            rows[#rows + 1] = row(questID, "?")
        end
    end
    sort(rows, function(a, b)
        if a.level ~= b.level then
            return (a.level or 1000) < (b.level or 1000)
        end
        return a.id < b.id
    end)
    for _, r in ipairs(rows) do
        local color = r.level and GetQuestDifficultyColor(r.level) or NORMAL_FONT_COLOR
        tooltip:AddLine(r.text, color.r, color.g, color.b, true)
    end
    if #rows > 0 then
        tooltip:Show()
    end
end

---Adds the lines to unit tooltips, while the module is on.
function internal.HookTooltips()
    module:TooltipPostCall(Enum.TooltipDataType.Unit, onUnit)
end
