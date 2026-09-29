-- Small text helpers modules share: measuring a font string, lines of a tooltip, and how long as
-- words ("3 Seconds", "12m ago").
local _, ns = ...

local format, floor, type, _G = string.format, math.floor, type, _G

local L = ns.L

local Text = {}
ns.Text = Text

---How wide a font string's text is unwrapped. Probe: GetUnboundedStringWidth is Mainline's.
---@param text table a FontString
---@return number
function Text.Width(text)
    return text.GetUnboundedStringWidth and text:GetUnboundedStringWidth() or text:GetStringWidth()
end

---A tooltip's left font string on line `i`, or nil for tooltips without named lines.
---@param tooltip table
---@param i number
---@return table?
function Text.LeftLine(tooltip, i)
    local name = tooltip.GetName and tooltip:GetName()
    return type(name) == "string" and _G[name .. "TextLeft" .. i] or nil
end

---A number of seconds for a slider label: "1 Second", "5 Seconds".
---@param seconds number
---@return string
function Text.Seconds(seconds)
    return seconds == 1 and L.TEXT_ONE_SECOND or format(L.TEXT_SECONDS, seconds)
end

---A number of hours for a slider label: "1 Hour", "12 Hours".
---@param hours number
---@return string
function Text.Hours(hours)
    return hours == 1 and L.TEXT_ONE_HOUR or format(L.TEXT_HOURS, hours)
end

---How long ago something was, as short as a price line: "just now", "12m ago", "3h ago", "2d ago".
---@param seconds number
---@return string
function Text.Ago(seconds)
    if seconds < 60 then
        return L.TEXT_AGO_NOW
    elseif seconds < 3600 then
        return format(L.TEXT_AGO_MINUTES, floor(seconds / 60))
    elseif seconds < 86400 then
        return format(L.TEXT_AGO_HOURS, floor(seconds / 3600))
    end
    return format(L.TEXT_AGO_DAYS, floor(seconds / 86400))
end
