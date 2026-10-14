-- Small text helpers modules share: measuring a font string, lines of a tooltip, and how long as
-- words ("3 Seconds", "12m ago"), comparing version strings, text without its escape codes, and
-- the client's format strings as patterns.
local _, ns = ...

local format, floor, max, type, _G = string.format, math.floor, math.max, type, _G
local gmatch, gsub, tonumber = string.gmatch, string.gsub, tonumber

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

---A tooltip's right font string on line `i`, or nil for tooltips without named lines.
---@param tooltip table
---@param i number
---@return table?
function Text.RightLine(tooltip, i)
    local name = tooltip.GetName and tooltip:GetName()
    return type(name) == "string" and _G[name .. "TextRight" .. i] or nil
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

---A length of time as a clock: "0:42", "12:05", and from an hour "1:02:05".
---@param seconds number
---@return string
function Text.Clock(seconds)
    seconds = max(0, floor(seconds + 0.5)) -- an aura a moment past its end still reads 0:00
    if seconds >= 3600 then
        return format("%d:%02d:%02d", floor(seconds / 3600), floor(seconds / 60) % 60, seconds % 60)
    end
    return format("%d:%02d", floor(seconds / 60), seconds % 60)
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

---Whether version `a` comes after version `b`, part by part: "0.10.0" is newer than "0.9.2".
---@param a string such as "0.8.0"
---@param b string
---@return boolean
function Text.NewerVersion(a, b)
    local left, right = {}, {}
    for part in gmatch(a, "%d+") do
        left[#left + 1] = tonumber(part)
    end
    for part in gmatch(b, "%d+") do
        right[#right + 1] = tonumber(part)
    end
    for i = 1, max(#left, #right) do
        local x, y = left[i] or 0, right[i] or 0
        if x ~= y then
            return x > y
        end
    end
    return false
end

---Text without its escape codes: colors, links (their text stays), textures, and atlases.
---Nothing here may be given a secret value; test with `ns.IsReadable` first.
---@param text string
---@return string
function Text.Plain(text)
    -- An escaped pipe is set aside first, so "||r" or "||cff..." isn't read as a code.
    text = gsub(text, "||", "\1")
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = gsub(text, "|cn[^:|]*:", "")
    text = gsub(text, "|r", "")
    text = gsub(text, "|H[^|]*|h(.-)|h", "%1")
    text = gsub(text, "|T[^|]*|t", "")
    text = gsub(text, "|A[^|]*|a", "")
    text = gsub(text, "\1", "|")
    return text
end

local CAPTURES = { s = "(.+)", d = "(%d+)" }
local MATCHES = { s = ".-", d = "%d+" }

---A Lua pattern for one of the client's format strings, such as ITEM_MIN_SKILL ("Requires %s
---(%d)"), so it matches in any language. Each %s and %d is captured, or only matched without
---`capture`. "%1$s" (reordered, in some languages) counts as "%s". Not anchored.
---@param formatString string
---@param capture? boolean
---@return string
function Text.FormatPattern(formatString, capture)
    local pattern = gsub(formatString, "%%%d+%$", "%%")
    pattern = gsub(pattern, "[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")
    return (gsub(pattern, "%%([sd])", capture and CAPTURES or MATCHES))
end
