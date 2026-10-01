-- Quest Nameplates: a quest icon and what's left to do (3/8, or how many more) beside the health bar
-- of a creature that's part of one of your quests. It reads the objective lines of the unit's
-- tooltip, which are the game's own word on which quest a creature belongs to and how far along
-- it is, and draws a small frame of our own on the plate's UnitFrame.
local _, ns = ...

local ipairs, pairs, setmetatable, tonumber, floor, max = ipairs, pairs, setmetatable, tonumber, math.floor,
    math.max
local CreateFrame, C_Timer, C_TooltipInfo, C_QuestLog = CreateFrame, C_Timer, C_TooltipInfo, C_QuestLog

local L = ns.L
local Nameplates = ns.Nameplates
local readable = ns.IsReadable

local module = ns.NewModule("QuestPlates", L.QUESTPLATES_DESC, {
    enabled = true,
    progress = "count", -- "count" (3/8), "remaining" (5), or "off" (just the icon)
    side = "left", -- which side of the bar: "left" or "right"
    size = 100, -- a percent
})
module.title = L.QUESTPLATES_TITLE
module.category = "nameplates"

module.options = {
    {
        key = "progress", name = L.QUESTPLATES_PROGRESS, description = L.QUESTPLATES_PROGRESS_DESC,
        choices = {
            { "count", L.QUESTPLATES_PROGRESS_COUNT },
            { "remaining", L.QUESTPLATES_PROGRESS_REMAINING },
            { "off", L.QUESTPLATES_PROGRESS_OFF },
        },
    },
    {
        key = "side", name = L.QUESTPLATES_SIDE, description = L.QUESTPLATES_SIDE_DESC,
        choices = { { "left", L.QUESTPLATES_SIDE_LEFT }, { "right", L.QUESTPLATES_SIDE_RIGHT } },
    },
    {
        key = "size", name = L.QUESTPLATES_SIZE, description = L.QUESTPLATES_SIZE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
}

local ICON_SIZE = 18 -- at 100%
local TEXT_SIZE = 12
local GAP = 2
-- Blizzard's quest atlases, the first this client has (probed: names change between builds).
-- `default` is the plain quest icon; the others are the cursor icons Blizzard shows over that
-- kind of target, by the objective type C_QuestLog.GetQuestObjectives reports.
local ATLASES = {
    default = { "QuestObjective", "QuestNormal", "quest-icon-exclamation" },
    monster = { "Crosshair_Attack_32", "worldquest-icon-pvp-ffa" },
    player = { "worldquest-icon-pvp-ffa", "Crosshair_Attack_32" },
    item = { "Crosshair_Pickup_32", "Crosshair_Take_32", "Crosshair_Loot_32" },
    object = { "Crosshair_Interact_32", "Crosshair_Gossip_32" },
    done = { "common-icon-checkmark", "UI-QuestTracker-Tracker-Check", "ui-questtracker-tracker-check" },
}

local indicators = setmetatable({}, { __mode = "k" }) -- Blizzard unit frame -> our indicator
local atlases = {} -- objective type -> the atlas found, or false

local function findAtlas(kind)
    kind = ATLASES[kind] and kind or "default"
    local found = atlases[kind]
    if found == nil then
        found = false
        for _, name in ipairs(ATLASES[kind]) do
            if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
                found = name
                break
            end
        end
        atlases[kind] = found
    end
    return found or (kind ~= "default" and findAtlas("default"))
end

-- The tooltip's objective lines don't say what kind of objective they are, but the quest log
-- does, so its objectives are indexed by their text with the numbers and punctuation taken out.
local kinds -- normalized objective text -> objective type, nil until needed
local matched = {} -- normalized tooltip text -> objective type or false

local function normalize(text)
    return (text:lower():gsub("%d+", ""):gsub("[%p%s]+", " "):gsub("^ ", ""):gsub(" $", ""))
end

local function indexObjectives()
    kinds = {}
    matched = {}
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo
        and C_QuestLog.GetQuestObjectives) then
        return
    end
    for index = 1, (C_QuestLog.GetNumQuestLogEntries()) do
        local info = C_QuestLog.GetInfo(index)
        local objectives = info and not info.isHeader and C_QuestLog.GetQuestObjectives(info.questID)
        for _, objective in ipairs(objectives or {}) do
            local text, kind = objective.text, objective.type
            if readable(text) and readable(kind) and type(text) == "string" and type(kind) == "string" then
                text = normalize(text)
                if #text >= 3 then
                    kinds[text] = kind
                end
            end
        end
    end
end

local function objectiveKind(text)
    if not kinds then
        indexObjectives()
    end
    text = normalize(text)
    local kind = matched[text]
    if kind == nil then
        kind = false
        if #text >= 3 then
            for key, objectiveType in pairs(kinds) do
                if key == text or key:find(text, 1, true) or text:find(key, 1, true) then
                    kind = objectiveType
                    break
                end
            end
        end
        matched[text] = kind
    end
    return kind
end

-- The first objective of this unit's quests that isn't done, as `current, needed, kind` (a
-- percentage objective has `needed` of 100; `kind` is the quest log's objective type, or false
-- when it can't be matched), or `current, needed, "done"` when all it lists are done, `false`
-- when it has none, or nil when the game won't
-- say (secret values in combat or an instance), so the plate keeps what it shows.
local function scan(unit)
    if C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
        local related = C_QuestLog.UnitIsRelatedToActiveQuest(unit)
        if readable(related) and not related then
            return false
        end
    end
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then
        return false
    end
    local data = C_TooltipInfo.GetUnit(unit)
    if not (data and data.lines) then
        return false
    end
    local types = Enum and Enum.TooltipDataLineType
    local objectiveType, titleType, playerType = types and types.QuestObjective, types and types.QuestTitle,
        types and types.QuestPlayer
    local inQuest, unknown = false, false
    local doneCurrent, doneNeeded
    for _, line in ipairs(data.lines) do
        local text, kind = line.leftText, line.type
        if not (readable(text) and readable(kind) and type(text) == "string") then
            unknown = true
        elseif titleType and kind == titleType then
            inQuest = true
        elseif not (playerType and kind == playerType) and (inQuest or (objectiveType and kind == objectiveType)) then
            -- "0/8 Boars", "Boars: 0/8", and "Escort (45%)" read the same in every language.
            local current, needed = text:match("(%d+)%s*/%s*(%d+)")
            local percent = not current and text:match("(%d+)%%")
            if percent then
                current, needed = percent, 100
            end
            current, needed = tonumber(current), tonumber(needed)
            if current and needed and current < needed then
                return current, needed, objectiveKind(text)
            end
            if current and needed and not doneCurrent then
                doneCurrent, doneNeeded = current, needed
            end
        end
    end
    if unknown then
        return nil
    end
    -- Every objective listed is done: show the check and the final count.
    if doneCurrent then
        return doneCurrent, doneNeeded, "done"
    end
    return false
end

local function create(frame)
    local box = CreateFrame("Frame", nil, frame)
    box:Hide()
    box.icon = box:CreateTexture(nil, "OVERLAY")
    box.text = box:CreateFontString(nil, "OVERLAY")
    -- The nameplate font family (a font per alphabet), sized the way Blizzard's plates are.
    box.text:SetFontObject("SystemFont_NamePlate")
    box.text:SetTextColor(1, 0.82, 0)
    return box
end

local function place(box, frame, current, needed, kind)
    local db = module.db
    local scale = db.size / 100
    local parts = Nameplates.Parts(frame)
    local anchor = parts.container
    if not anchor then
        return
    end
    local right = db.side == "right"
    -- The level badge sits at the bar's right end, so the box goes past it.
    if right and parts.level then
        anchor = parts.level
    end
    local size = floor(ICON_SIZE * scale + 0.5)
    local name = findAtlas(kind)
    if name then
        box.icon:SetAtlas(name, false)
    else
        box.icon:SetTexture(nil)
    end
    box.icon:SetSize(size, size)
    local text = box.text
    if text.SetFontHeight then
        text:SetFontHeight(TEXT_SIZE * scale)
    end
    local label
    local done = kind == "done"
    if done then
        text:SetTextColor(0.1, 1, 0.1)
    else
        text:SetTextColor(1, 0.82, 0)
    end
    -- A finished objective has nothing remaining, so it shows its count either way.
    if db.progress == "count" or (done and db.progress == "remaining") then
        label = current .. "/" .. needed
        if needed == 100 then
            label = current .. "%"
        end
    elseif db.progress == "remaining" then
        label = max(needed - current, 0) .. (needed == 100 and "%" or "")
    end
    text:SetText(label or "")
    box.icon:ClearAllPoints()
    text:ClearAllPoints()
    box:ClearAllPoints()
    box:SetSize(size, size)
    if right then
        box:SetPoint("LEFT", anchor, "RIGHT", GAP, 0)
        box.icon:SetPoint("LEFT", box, "LEFT")
        text:SetPoint("LEFT", box.icon, "RIGHT", GAP, 0)
    else
        box:SetPoint("RIGHT", anchor, "LEFT", -GAP, 0)
        box.icon:SetPoint("RIGHT", box, "RIGHT")
        text:SetPoint("RIGHT", box.icon, "LEFT", -GAP, 0)
    end
    box:Show()
end

local function update(unit, frame)
    local box = indicators[frame]
    local current, needed, kind = scan(unit)
    if current == nil then
        return
    end
    if not current then
        if box then
            box:Hide()
        end
        return
    end
    if not box then
        box = create(frame)
        indicators[frame] = box
    end
    place(box, frame, current, needed, kind)
end

local pending = false

-- Quest events come in bursts, so the plates are refreshed once after they settle.
local function refreshSoon()
    if pending then
        return
    end
    pending = true
    C_Timer.After(0.2, function()
        pending = false
        kinds = nil -- the quest log changed: index its objectives again
        if module.enabled then
            Nameplates.ForEach(update)
        end
    end)
end

function module:OnEnable()
    kinds = nil
    Nameplates.Register(self, {
        OnAdded = update,
        OnRemoved = function(_, frame)
            local box = indicators[frame]
            if box then
                box:Hide()
            end
        end,
    })
    self:On("QUEST_LOG_UPDATE", refreshSoon)
    self:On("UNIT_QUEST_LOG_CHANGED", refreshSoon)
    self:On("QUEST_WATCH_UPDATE", refreshSoon)
end

function module:OnDisable()
    Nameplates.Unregister(self)
end

function module:OnOptionChanged()
    if self.enabled then
        Nameplates.ForEach(update)
    end
end
