-- Hide Beta Feedback: takes the beta's "Press F6 to submit an issue for this Item" line off
-- tooltips and hides its floating bug report button. F6 still reports an issue; only the
-- reminder and the button go. Off by default, so players keep sending beta feedback.
local _, ns = ...

local _G, type, pairs, ipairs, setmetatable = _G, type, pairs, ipairs, setmetatable
local find, gsub = string.find, string.gsub
local hooksecurefunc = hooksecurefunc

local L = ns.L

local module = ns.NewModule("HideFeedback", L.HIDEFEEDBACK_DESC, {
    enabled = false,
    tooltip = true, -- hide the "Press F6" reminder on tooltips
    button = true, -- hide the floating bug report button
})
module.title = L.HIDEFEEDBACK_TITLE
module.category = "interface"

module.options = {
    { key = "tooltip", name = L.HIDEFEEDBACK_TOOLTIP, description = L.HIDEFEEDBACK_TOOLTIP_DESC },
    { key = "button", name = L.HIDEFEEDBACK_BUTTON, description = L.HIDEFEEDBACK_BUTTON_DESC },
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

-- The feedback code may load after Forever++; wait for it while the module is on.
local function onLoad()
    if setupReporter() then
        module:Off("ADDON_LOADED", onLoad)
        module:Off("PLAYER_ENTERING_WORLD", onLoad)
        hideButton()
    end
end

function module:OnEnable()
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
end

-- The tooltip setting takes effect on the next tooltip; the button one right away.
function module:OnOptionChanged(key)
    if key == "button" and self.enabled then
        if self.db.button then
            hideButton()
        else
            showButton()
        end
    end
end
