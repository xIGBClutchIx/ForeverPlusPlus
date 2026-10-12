-- Short Channel Names: [1. General] becomes [1], [G], or [1. G] in chat. Blizzard builds the channel link
-- from the channel's full name, so this rewrites the finished line after it is added to the
-- window, through the chat frame's own TransformMessages (the line stays a working link). Lines
-- the game marks secret can't be read and are left alone.
local _, ns = ...

local ipairs, gsub, tonumber = ipairs, string.gsub, tonumber

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChannelNames", L.CHANNELNAMES_DESC, {
    enabled = false,
    style = "both",
})
module.title = L.CHANNELNAMES_TITLE
module.category = "chat"

module.options = {
    {
        key = "style",
        name = L.CHANNELNAMES_STYLE,
        description = L.CHANNELNAMES_STYLE_DESC,
        choices = {
            { "number", L.CHANNELNAMES_NUMBER },
            { "letter", L.CHANNELNAMES_LETTER },
            { "both", L.CHANNELNAMES_BOTH },
        },
    },
}

-- The first character of a name, whole, even when it takes several bytes (UTF-8).
local FIRST_CHARACTER = "^[%z\1-\127\194-\244][\128-\191]*"

-- The rendered link is |Hchannel:channel:5|h[5. General - Elwynn Forest]|h.
local LINK = "(|Hchannel:channel:%d+|h%[)(%d+)%. ([^%]]-)(%]|h)"

---A chat line with its numbered channel link shortened.
---@param text string
---@return string
local function rewrite(text)
    return (gsub(text, LINK, function(open, number, name, close)
        local letter = name:match(FIRST_CHARACTER)
        local short = number
        if module.db.style == "letter" then
            short = letter or number
        elseif module.db.style == "both" and letter then
            short = number .. ". " .. letter
        end
        return open .. short .. close
    end))
end

local function onMessage(frame, text)
    if not (ns.IsReadable(text) and type(text) == "string" and text:find("|Hchannel:channel:", 1, true)) then
        return
    end
    local short = rewrite(text)
    if short == text then
        return
    end
    Chat.Transform(frame, function(message)
        return message == text
    end, function()
        return short
    end)
end

function module:IsAvailable()
    return ChatFrame1 ~= nil and ChatFrame1.TransformMessages ~= nil
end

function module:OnEnable()
    -- Every window, and one added later.
    Chat.EachWindow(self, function(frame)
        module:Hook(frame, "AddMessage", onMessage)
    end)
end

-- A shortened link, to put the name back: |Hchannel:channel:5|h[5. G]|h.
local SHORT_LINK = "(|Hchannel:channel:(%d+)|h%[)([^%]]-)(%]|h)"

---A chat line with its shortened channel link given its full name again, as the channel is named
---now. Only an inner text that is one of our short forms for that channel is replaced.
---@param text string
---@return string
local function restore(text)
    return (gsub(text, SHORT_LINK, function(open, number, inner, close)
        local _, name = GetChannelName(tonumber(number))
        if type(name) ~= "string" or name == "" then
            return nil
        end
        local letter = name:match(FIRST_CHARACTER)
        if inner == number or inner == letter or (letter and inner == number .. ". " .. letter) then
            return open .. number .. ". " .. name .. close
        end
        return nil
    end))
end

-- Lines already shortened get their names back, so turning the module off undoes it.
function module:OnDisable()
    for _, frame in ipairs(Chat.Frames()) do
        Chat.Transform(frame, function(message)
            return message:find("|Hchannel:channel:", 1, true) ~= nil and restore(message) ~= message
        end, restore)
    end
end
