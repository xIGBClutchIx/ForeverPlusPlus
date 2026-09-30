-- Short Channel Names: [1. General] becomes [1] or [G] in chat. Blizzard builds the channel link
-- from the channel's full name, so this rewrites the finished line after it is added to the
-- window, through the chat frame's own TransformMessages (the line stays a working link). Lines
-- the game marks secret can't be read and are left alone.
local _, ns = ...

local ipairs, gsub = ipairs, string.gsub

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChannelNames", L.CHANNELNAMES_DESC, {
    enabled = false,
    style = "number",
})
module.title = L.CHANNELNAMES_TITLE
module.category = "chat"

module.options = {
    {
        key = "style",
        name = L.CHANNELNAMES_STYLE,
        description = L.CHANNELNAMES_STYLE_DESC,
        choices = { { "number", L.CHANNELNAMES_NUMBER }, { "letter", L.CHANNELNAMES_LETTER } },
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
        local short = number
        if module.db.style == "letter" then
            short = name:match(FIRST_CHARACTER) or number
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
    frame:TransformMessages(function(message)
        return ns.IsReadable(message) and message == text
    end, function(_, ...)
        return short, ...
    end)
end

function module:IsAvailable()
    return ChatFrame1 ~= nil and ChatFrame1.TransformMessages ~= nil
end

local function attach()
    for _, frame in ipairs(Chat.Frames()) do
        module:Hook(frame, "AddMessage", onMessage)
    end
end

function module:OnEnable()
    attach()
    -- A chat window added later.
    self:On("UPDATE_CHAT_WINDOWS", attach)
    self:On("UPDATE_FLOATING_CHAT_WINDOWS", attach)
end
