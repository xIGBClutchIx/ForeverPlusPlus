-- Hide Beta Feedback: takes the beta's "Press F6 to submit an issue for this Item" line off
-- tooltips and hides its floating bug report button. F6 still reports an issue; only the
-- reminder, the button, and the feedback buttons on quest windows go. Off by default, so players keep sending beta feedback.
local _, ns = ...

local _G, type, pairs, ipairs, setmetatable = _G, type, pairs, ipairs, setmetatable
local find, gsub = string.find, string.gsub
local hooksecurefunc, C_Timer = hooksecurefunc, C_Timer

local L = ns.L

local module = ns.NewModule("HideFeedback", L.HIDEFEEDBACK_DESC, {
    enabled = false,
    tooltip = true, -- hide the "Press F6" reminder on tooltips
    button = true, -- hide the floating bug report button
    quest = true, -- hide the feedback widgets on quest windows
})
module.title = L.HIDEFEEDBACK_TITLE
module.category = "interface"

module.options = {
    { key = "tooltip", name = L.HIDEFEEDBACK_TOOLTIP, description = L.HIDEFEEDBACK_TOOLTIP_DESC },
    { key = "button", name = L.HIDEFEEDBACK_BUTTON, description = L.HIDEFEEDBACK_BUTTON_DESC },
    { key = "quest", name = L.HIDEFEEDBACK_QUEST, description = L.HIDEFEEDBACK_QUEST_DESC },
}

-- Only test clients (the beta, a PTR) have the feedback code. Probe: IsBetaBuild and
-- IsPublicTestClient are Mainline's, and which one is true on Forever's beta is Unverified, so
-- the reporter being there already counts too.
function module:IsAvailable()
    return (IsBetaBuild and IsBetaBuild()) or (IsPublicTestClient and IsPublicTestClient())
        or _G.PTR_IssueReporter ~= nil
end

-- Forever beta only: Blizzard's PTR feedback code makes PTR_IssueReporter, the bug report button,
-- and adds a " " line and then the reminder to tooltips after everything else (probed
-- 2026-09-26). Its BugTooltipString and friends are the reminder's format strings, so matching
-- them works in every language.
local REPORTER_STRINGS = { "BugTooltipString", "BugTooltipPartialString", "MissingBindTooltipString" }

local reporter -- PTR_IssueReporter, once it exists
local patterns = {}
local hooked = setmetatable({}, { __mode = "k" }) -- tooltip -> true
local buttonWasShown = false
local busy = false

-- "Press %s to submit an issue for this %s" -> a Lua pattern where each %s matches anything.
local function toPattern(formatString)
    local pattern = gsub(formatString, "[%^%$%(%)%.%[%]%*%+%-%?%%]", "%%%0")
    return (gsub(pattern, "%%%%[sd]", ".-"))
end

local function isReminder(text)
    -- Unit tooltip lines can be secret in combat; those are never the reminder.
    if type(text) ~= "string" or not ns.IsReadable(text) then
        return false
    end
    for _, pattern in ipairs(patterns) do
        if find(text, pattern) then
            return true
        end
    end
    return false
end

local function isBlank(text)
    return text == " " or text == ""
end

local function blank(name, i)
    _G[name .. "TextLeft" .. i]:SetText("")
    local right = _G[name .. "TextRight" .. i]
    if right then
        right:SetText("")
    end
end

-- Blanks the reminder and the empty line above it. Tooltip lines can't be removed, so the
-- tooltip is shown again to shrink around what's left.
local function scrub(tooltip)
    if busy or not (module.enabled and module.db.tooltip) or #patterns == 0 then
        return
    end
    local name = tooltip.GetName and tooltip:GetName()
    if not name or not tooltip.NumLines then
        return
    end
    local found = false
    for i = tooltip:NumLines(), 1, -1 do
        local line = _G[name .. "TextLeft" .. i]
        if line and isReminder(line:GetText()) then
            blank(name, i)
            local above = _G[name .. "TextLeft" .. (i - 1)]
            local text = above and above:GetText()
            if ns.IsReadable(text) and isBlank(text) then
                blank(name, i - 1)
            end
            found = true
        end
    end
    if found then
        busy = true
        tooltip:Show()
        busy = false
        -- If showing it again made the reporter add its line again, blank that too, without
        -- another Show.
        for i = tooltip:NumLines(), 1, -1 do
            local line = _G[name .. "TextLeft" .. i]
            if line and isReminder(line:GetText()) then
                blank(name, i)
            end
        end
    end
end

local function hookTooltip(tooltip)
    if type(tooltip) ~= "table" or not tooltip.NumLines or hooked[tooltip] then
        return
    end
    hooked[tooltip] = true
    -- After the reporter's own Show hook, if it has one, since it was added first.
    hooksecurefunc(tooltip, "Show", scrub)
end

local function keepHidden(frame)
    if module.enabled and module.db.button then
        frame:Hide()
    end
end

local function setupReporter()
    reporter = _G.PTR_IssueReporter
    if type(reporter) ~= "table" then
        reporter = nil
        return false
    end
    for _, key in ipairs(REPORTER_STRINGS) do
        local value = reporter[key]
        if type(value) == "string" and value ~= "" then
            patterns[#patterns + 1] = toPattern(value)
        end
    end
    hookTooltip(_G.GameTooltip)
    hookTooltip(_G.ItemRefTooltip)
    if type(reporter.TooltipFrames) == "table" then
        for key, value in pairs(reporter.TooltipFrames) do
            hookTooltip(key)
            hookTooltip(value)
        end
    end
    -- Catches the line on tooltips it adds to without calling Show.
    if type(reporter.HookIntoTooltip) == "function" then
        hooksecurefunc(reporter, "HookIntoTooltip", function(tooltip)
            if type(tooltip) == "table" and tooltip.NumLines then
                scrub(tooltip)
            end
        end)
    end
    if reporter.HookScript then
        reporter:HookScript("OnShow", keepHidden)
    end
    return true
end

local function hideButton()
    if module.db.button and reporter and reporter.Hide then
        buttonWasShown = reporter:IsShown()
        reporter:Hide()
    end
end

-- Puts the button back if we hid it.
local function showButton()
    if reporter and buttonWasShown then
        buttonWasShown = false
        reporter:Show()
    end
end

-- Quest frames. The reporter has a quest setup (`Setup*Tooltips`), and the feedback widgets it
-- puts on quest windows aren't known by name: Unverified in game, so every child of the quest
-- frames whose name mentions the reporter or feedback is hidden, and anything else is left alone.
local QUEST_FRAMES = { "QuestFrame", "GossipFrame", "QuestLogPopupDetailFrame", "QuestMapFrame" }
local QUEST_EVENTS = { "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW" }
local MAX_DEPTH = 4
local questHidden = setmetatable({}, { __mode = "k" }) -- widget -> alpha it had

local function isFeedbackName(name)
    if type(name) ~= "string" then
        return false
    end
    return find(name, "PTR", 1, true) ~= nil or find(name, "IssueReport", 1, true) ~= nil
        or find(name, "Feedback", 1, true) ~= nil or find(name, "BugReport", 1, true) ~= nil
end

local function hideQuestWidget(widget)
    if questHidden[widget] == nil and widget.GetAlpha and widget.SetAlpha then
        questHidden[widget] = widget:GetAlpha()
    end
    if widget.SetAlpha then
        widget:SetAlpha(0)
    end
    if widget.EnableMouse then
        widget:EnableMouse(false)
    end
end

local function scanQuest(frame, depth)
    if type(frame) ~= "table" or not frame.GetChildren then
        return
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        local name = child.GetName and child:GetName()
        if isFeedbackName(name) then
            hideQuestWidget(child)
        elseif depth < MAX_DEPTH then
            scanQuest(child, depth + 1)
        end
    end
end

local alertHooked = setmetatable({}, { __mode = "k" }) -- widget -> true

-- Fading it out isn't enough: the alert plays an animation that sets its alpha back, so it is
-- also hidden, and hidden again whenever the reporter shows it.
local function hideAlert(widget)
    if module.enabled and module.db.quest then
        hideQuestWidget(widget)
        if widget.Hide and not widget:IsForbidden() then
            widget:Hide()
        end
    end
end

-- The reporter's alert frame (PTRIssueReporterAlertFrame, seen in the frame stack on quest
-- windows) isn't a child of the quest frames, so the scan above never finds it. Look for it, and
-- for other named feedback frames directly under UIParent, and hide it again whenever it shows.
local function hideAlertFrames()
    local found = { _G.PTRIssueReporterAlertFrame }
    if UIParent and UIParent.GetChildren then
        for _, child in ipairs({ UIParent:GetChildren() }) do
            local name = child.GetName and child:GetName()
            if isFeedbackName(name) and child ~= found[1] then
                found[#found + 1] = child
            end
        end
    end
    for _, widget in ipairs(found) do
        if type(widget) == "table" and widget.HookScript then
            hideAlert(widget)
            if not alertHooked[widget] then
                alertHooked[widget] = true
                module:HookScript(widget, "OnShow", hideAlert)
            end
        end
    end
end

local function hideQuestFeedback()
    if not (module.enabled and module.db.quest) then
        return
    end
    for _, name in ipairs(QUEST_FRAMES) do
        scanQuest(_G[name], 1)
    end
    hideAlertFrames()
end

-- Puts back what was hidden.
local function showQuestFeedback()
    for widget, alpha in pairs(questHidden) do
        widget:SetAlpha(alpha)
        if widget.EnableMouse then
            widget:EnableMouse(true)
        end
        questHidden[widget] = nil
    end
end

local function onQuestEvent()
    -- The reporter adds its widgets as the window opens; look once it has.
    C_Timer.After(0, hideQuestFeedback)
end

local function setupQuest()
    for _, name in ipairs(QUEST_FRAMES) do
        local frame = _G[name]
        if frame and frame.HookScript then
            module:HookScript(frame, "OnShow", onQuestEvent)
        end
    end
    for _, event in ipairs(QUEST_EVENTS) do
        module:On(event, onQuestEvent)
    end
    -- The quest log lives in the world map, which loads on demand.
    ns.AddOns.WhenLoaded("Blizzard_WorldMap", function()
        if module.enabled and _G.QuestMapFrame and _G.QuestMapFrame.HookScript then
            module:HookScript(_G.QuestMapFrame, "OnShow", onQuestEvent)
        end
    end)
    hideQuestFeedback()
end

-- The feedback code may load after Forever++; wait for it while the module is on.
local function onLoad()
    if setupReporter() then
        module:Off("ADDON_LOADED", onLoad)
        module:Off("PLAYER_ENTERING_WORLD", onLoad)
        hideButton()
    end
end

function module:OnEnable()
    if self.db.quest then
        setupQuest()
    end
    if reporter or setupReporter() then
        hideButton()
    else
        self:On("ADDON_LOADED", onLoad)
        self:On("PLAYER_ENTERING_WORLD", onLoad)
    end
end

function module:OnDisable()
    -- The hooks stay, but do nothing while the module is off.
    showButton()
    showQuestFeedback()
end

-- The tooltip setting takes effect on the next tooltip; the button and quest ones right away.
function module:OnOptionChanged(key)
    if key == "quest" and self.enabled then
        if self.db.quest then
            setupQuest()
        else
            showQuestFeedback()
        end
    elseif key == "button" and self.enabled then
        if self.db.button then
            hideButton()
        else
            showButton()
        end
    end
end
