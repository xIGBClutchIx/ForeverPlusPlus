-- Quest Nameplates: a quest icon and what's left to do (3/8, or how many more) beside the health bar
-- of a creature that's part of one of your quests. It reads the objective lines of the unit's
-- tooltip, which are the game's own word on which quest a creature belongs to and how far along
-- it is, and draws a small frame of our own on the plate's UnitFrame.
local _, ns = ...

local ipairs, setmetatable, tonumber, floor, max = ipairs, setmetatable, tonumber, math.floor, math.max
local CreateFrame, C_Timer, C_TooltipInfo, C_QuestLog = CreateFrame, C_Timer, C_TooltipInfo, C_QuestLog

local L = ns.L
local Nameplates = ns.Nameplates
local readable = ns.IsReadable

local module = ns.NewModule("QuestPlates", L.QUESTPLATES_DESC, {
    enabled = false,
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
local ATLASES = { "QuestObjective", "QuestNormal", "quest-icon-exclamation" }

local indicators = setmetatable({}, { __mode = "k" }) -- Blizzard unit frame -> our indicator
local atlas -- the atlas found, or false

local function findAtlas()
    if atlas == nil then
        atlas = false
        for _, name in ipairs(ATLASES) do
            if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
                atlas = name
                break
            end
        end
    end
    return atlas
end

-- The first objective of this unit's quests that isn't done, as `current, needed, percent` (a
-- percentage objective has `needed` of 100), `false` when it has none, or nil when the game won't
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
                return current, needed
            end
        end
    end
    if unknown then
        return nil
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

local function place(box, frame, current, needed)
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
    local name = findAtlas()
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
    if db.progress == "count" then
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
    local current, needed = scan(unit)
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
    place(box, frame, current, needed)
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
        if module.enabled then
            Nameplates.ForEach(update)
        end
    end)
end

function module:OnEnable()
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
