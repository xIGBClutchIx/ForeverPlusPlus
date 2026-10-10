-- XP Bar Text: the experience bar shows its numbers all the time, not only under the mouse, with
-- the percent, your rested XP, and the XP the quests in your log will give. Blizzard's bar text is
-- set to alpha 0 and a font string of ours, in the same font and spot, shows ours instead. Each
-- status bar container (Edit Mode's two) has its own experience bar, so both get one. The bars
-- come from Blizzard_StatusTrackingBar (FrameXML on Forever build 70338).
local _, ns = ...

local ipairs, floor, format = ipairs, math.floor, string.format
local UnitXP, UnitXPMax, GetXPExhaustion = UnitXP, UnitXPMax, GetXPExhaustion
local C_QuestLog, BreakUpLargeNumbers = C_QuestLog, BreakUpLargeNumbers

local L = ns.L
local readable = ns.IsReadable

local module = ns.NewModule("XPBarText", L.XPBARTEXT_DESC, {
    enabled = false,
    always = true, -- false: only while the mouse is over the bar, like Blizzard's
    percent = true,
    rested = true,
    quests = "complete", -- "off", "complete" (ready to turn in), or "all"
})
module.title = L.XPBARTEXT_TITLE
module.category = "interface"
module.added = "0.8.0"

module.options = {
    { key = "always", name = L.XPBARTEXT_ALWAYS, description = L.XPBARTEXT_ALWAYS_DESC },
    { key = "percent", name = L.XPBARTEXT_PERCENT, description = L.XPBARTEXT_PERCENT_DESC },
    { key = "rested", name = L.XPBARTEXT_RESTED, description = L.XPBARTEXT_RESTED_DESC },
    {
        key = "quests", name = L.XPBARTEXT_QUESTS, description = L.XPBARTEXT_QUESTS_DESC,
        choices = {
            { "complete", L.XPBARTEXT_QUESTS_COMPLETE },
            { "all", L.XPBARTEXT_QUESTS_ALL },
            { "off", L.XPBARTEXT_QUESTS_OFF },
        },
    },
}

local ADDON = "Blizzard_StatusTrackingBar"

local texts = setmetatable({}, { __mode = "k" }) -- Blizzard's experience bar -> our font string
local bars = {} -- the experience bars, once found
local questXP = 0

local function number(n)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(n) or n
end

-- "2,100 (42%)", or just the number with Percent off.
local function amount(n, max)
    if module.db.percent and max > 0 then
        return format(L.XPBARTEXT_AMOUNT, number(n), floor(n / max * 100))
    end
    return number(n)
end

-- The XP the quests in your log give: only those ready to turn in, or all of them. A quest's
-- reward reads 0 until the game has its data; QUEST_LOG_UPDATE comes when it does.
local function countQuestXP()
    questXP = 0
    local which = module.db.quests
    if which == "off" or not (GetQuestLogRewardXP and C_QuestLog and C_QuestLog.GetNumQuestLogEntries
        and C_QuestLog.GetInfo) then
        return
    end
    local isComplete = C_QuestLog.ReadyForTurnIn or C_QuestLog.IsComplete
    for index = 1, (C_QuestLog.GetNumQuestLogEntries()) do
        local info = C_QuestLog.GetInfo(index)
        local id = info and not info.isHeader and info.questID
        if id and (which == "all" or (isComplete and isComplete(id))) then
            local xp = GetQuestLogRewardXP(id)
            if readable(xp) and type(xp) == "number" then
                questXP = questXP + xp
            end
        end
    end
end

-- Our text, or nil when the XP can't be read (then Blizzard's own text stays).
local function barText()
    local current, max = UnitXP("player"), UnitXPMax("player")
    if not (readable(current) and readable(max) and type(current) == "number"
        and type(max) == "number" and max > 0) then
        return nil
    end
    local text = format(L.XPBARTEXT_XP, number(current), number(max))
    if module.db.percent then
        text = format(L.XPBARTEXT_WITH_PERCENT, text, floor(current / max * 100))
    end
    local rested = module.db.rested and GetXPExhaustion and GetXPExhaustion()
    if rested and readable(rested) and type(rested) == "number" and rested > 0 then
        text = text .. "    " .. format(L.XPBARTEXT_RESTED_TEXT, amount(rested, max))
    end
    if module.db.quests ~= "off" and questXP > 0 then
        local quests = format(L.XPBARTEXT_QUESTS_TEXT, amount(questXP, max))
        if current + questXP >= max then
            -- Enough to level: green, like a quest you can turn in.
            quests = ns.Colors.Text(GREEN_FONT_COLOR, quests)
        end
        text = text .. "    " .. quests
    end
    return text
end

local function update(bar)
    local ours = texts[bar]
    if not ours then
        return
    end
    local text = module.enabled and barText()
    if not text then
        ours:Hide()
        bar.OverlayFrame.Text:SetAlpha(1)
        return
    end
    bar.OverlayFrame.Text:SetAlpha(0)
    ours:SetText(text)
    ours:SetShown(module.db.always or (bar.ShouldBarTextBeDisplayed
        and bar:ShouldBarTextBeDisplayed()) or false)
end

local function updateAll()
    for _, bar in ipairs(bars) do
        update(bar)
    end
end

local function refreshQuests()
    countQuestXP()
    updateAll()
end

-- Finds each container's experience bar and gives it our text, once.
local function setUp()
    if not module.enabled then
        return
    end
    local manager = StatusTrackingBarManager
    local index = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
        and StatusTrackingBarInfo.BarsEnum.Experience
    if not (manager and manager.barContainers and index) then
        return
    end
    for _, container in ipairs(manager.barContainers) do
        local bar = container.bars and container.bars[index]
        if bar and bar.OverlayFrame and bar.OverlayFrame.Text and not texts[bar] then
            local ours = bar.OverlayFrame:CreateFontString(nil, "ARTWORK", "TextStatusBarText")
            ours:SetDrawLayer("ARTWORK", 5)
            ours:SetPoint("CENTER", bar.OverlayFrame, "CENTER", 0, 1)
            ours:Hide()
            texts[bar] = ours
            bars[#bars + 1] = bar
        end
    end
    for _, bar in ipairs(bars) do
        -- Blizzard sets its text on every XP update and shows it on mouseover.
        module:Hook(bar, "UpdateCurrentText", update)
        module:Hook(bar, "UpdateTextVisibility", update)
    end
    refreshQuests()
end

function module:OnEnable()
    ns.AddOns.WhenLoaded(ADDON, setUp)
    self:On("PLAYER_XP_UPDATE", updateAll)
    self:On("UPDATE_EXHAUSTION", updateAll)
    self:On("PLAYER_LEVEL_UP", updateAll)
    self:On("PLAYER_ENTERING_WORLD", refreshQuests)
    self:On("QUEST_LOG_UPDATE", refreshQuests)
end

function module:OnDisable()
    ns.AddOns.Cancel(ADDON, setUp)
    for _, bar in ipairs(bars) do
        texts[bar]:Hide()
        bar.OverlayFrame.Text:SetAlpha(1)
    end
end

function module:OnOptionChanged()
    refreshQuests()
end
