-- Whisper Window: whispers in a window of their own, a conversation per person, like a messenger.
-- Whispers you get and send (from the window or from chat), Battle.net whispers, away and busy
-- replies, and "no player named" errors go into the conversation they belong to, which is saved
-- for each character, since whispers go to one character and an alt's shouldn't mix in. This
-- file keeps the conversations and listens to chat; Window.lua draws them.
--
-- Chat lines can come back secret on Forever (Midnight's rules, mostly in instances). A whisper
-- whose text or sender can't be read is left to Blizzard's chat as it is, and never hidden there.
-- The sender is the name the game gives, which on Forever may carry a surname after a "-"
-- (docs/forever-api.md), so it's kept whole: it's what a reply goes to.
local _, ns = ...

local pairs, ipairs, type, time, format, tremove = pairs, ipairs, type, time, string.format, table.remove
local sort, wipe, GetTime = table.sort, wipe, GetTime
local lower, match = string.lower, string.match

local L = ns.L

local module = ns.NewModule("WhisperWindow", L.WHISPERWINDOW_DESC, {
    enabled = false,
    openOnWhisper = true,
    hideInChat = false,
    chatButton = true,
    alpha = 100,
    movingAlpha = 60,
    combatAlpha = 40,
    -- Data, not settings.
    conversations = {}, -- key -> conversation (see `newConversation`), for each character
    layout = {}, -- the window's place and size
})
module.title = L.WHISPERWINDOW_TITLE
module.category = "chat"
module.added = "0.9.0"
module.perCharacter = { conversations = true }
module.internal = {}
local internal = module.internal

local MAX_MESSAGES = 200 -- kept per conversation, the oldest go first
local MAX_CONVERSATIONS = 50 -- the ones quiet longest go first
internal.MAX_MESSAGES = MAX_MESSAGES

local WINDOW = L.WHISPERWINDOW_SECTION_WINDOW
local OPACITY = L.WHISPERWINDOW_SECTION_OPACITY

local function percent(option)
    option.min, option.max, option.step, option.format = 10, 100, 5, "%d%%"
    option.section = OPACITY
    return option
end

module.options = {
    { key = "openOnWhisper", name = L.WHISPERWINDOW_OPEN, description = L.WHISPERWINDOW_OPEN_DESC,
        section = WINDOW },
    { key = "hideInChat", name = L.WHISPERWINDOW_HIDE, description = L.WHISPERWINDOW_HIDE_DESC,
        section = WINDOW },
    { key = "chatButton", name = L.WHISPERWINDOW_BUTTON, description = L.WHISPERWINDOW_BUTTON_DESC,
        section = WINDOW },
    percent({ key = "alpha", name = L.WHISPERWINDOW_ALPHA, description = L.WHISPERWINDOW_ALPHA_DESC }),
    percent({ key = "movingAlpha", name = L.WHISPERWINDOW_MOVING,
        description = L.WHISPERWINDOW_MOVING_DESC }),
    percent({ key = "combatAlpha", name = L.WHISPERWINDOW_COMBAT,
        description = L.WHISPERWINDOW_COMBAT_DESC }),
}

-- Conversations ---------------------------------------------------------------------------------

---Every saved conversation, by key.
---@return table
function internal.Conversations()
    return module.db.conversations
end

---The conversations, the latest first.
---@return table[]
function internal.Sorted()
    local list = {}
    for _, conversation in pairs(internal.Conversations()) do
        list[#list + 1] = conversation
    end
    sort(list, function(a, b)
        if (a.last or 0) ~= (b.last or 0) then
            return (a.last or 0) > (b.last or 0)
        end
        return a.key < b.key
    end)
    return list
end

---How many whispers wait unread, in every conversation.
---@return number
function internal.UnreadTotal()
    local total = 0
    for _, conversation in pairs(internal.Conversations()) do
        total = total + (conversation.unread or 0)
    end
    return total
end

-- The first part of a name, before a surname or realm, for matching a name typed by hand.
local function firstName(name)
    return lower(match(name, "^[^%-%s]+") or name)
end

-- How a name shows: as Blizzard's chat shows it, where the game has Ambiguate.
local function shownName(name)
    if Ambiguate then
        local shown = Ambiguate(name, "none")
        if ns.IsText(shown, true) then
            return shown
        end
    end
    return name
end

-- Drops the conversations quiet longest, past MAX_CONVERSATIONS.
local function trimConversations()
    local list = internal.Sorted()
    local conversations = internal.Conversations()
    for i = MAX_CONVERSATIONS + 1, #list do
        conversations[list[i].key] = nil
    end
end

-- A conversation: `key`, `name` (who a reply goes to), `display`, `class` (a class token, when
-- known), `bnet` (a BattleTag, for Battle.net whispers), `messages` ({ time, kind, text }, oldest
-- first, kind "in", "out" or "info"), `unread`, `last` (the time of the latest), and `typed` (made
-- from a name typed in New Whisper, until the game says whose it is).
local function newConversation(key, name, display, bnet)
    local conversation = { key = key, name = name, display = display, bnet = bnet, messages = {},
        unread = 0, last = time() }
    internal.Conversations()[key] = conversation
    trimConversations()
    return conversation
end

-- The conversation with a player, made if `create`. A conversation started by typing a name
-- ("bob") takes the name the game gives once the whisper goes out ("Bob-Surname").
local function playerConversation(sender, create)
    local conversations = internal.Conversations()
    local key = lower(sender)
    local conversation = conversations[key]
    if not conversation then
        local typed = conversations[firstName(sender)]
        if typed and typed.typed then
            conversations[typed.key] = nil
            typed.key, typed.name, typed.display, typed.typed = key, sender, shownName(sender), nil
            conversations[key] = typed
            conversation = typed
        end
    end
    if not conversation and create then
        conversation = newConversation(key, sender, shownName(sender))
    end
    return conversation
end

-- Battle.net friends: the game's id for an account changes each session, so a conversation keeps
-- the BattleTag, and the id for this session is looked up.
local bnetIds = {} -- conversation key -> bnetAccountID, this session

local function bnetInfo(id)
    if not (C_BattleNet and C_BattleNet.GetAccountInfoByID and ns.IsReadable(id)
        and type(id) == "number") then
        return nil
    end
    local info = C_BattleNet.GetAccountInfoByID(id)
    if info and ns.IsText(info.battleTag, true) then
        return info
    end
end

local function bnetConversation(id, create)
    local info = bnetInfo(id)
    if not info then
        return nil
    end
    local key = "bnet:" .. lower(info.battleTag)
    bnetIds[key] = id
    local conversation = internal.Conversations()[key]
    if not conversation and create then
        conversation = newConversation(key, info.battleTag, match(info.battleTag, "^[^#]+")
            or info.battleTag, info.battleTag)
    end
    return conversation
end

-- This session's account id for a Battle.net conversation, from the friends list if no whisper
-- came in this session.
local function bnetId(conversation)
    local id = bnetIds[conversation.key]
    if id or not (C_BattleNet and C_BattleNet.GetFriendAccountInfo and BNGetNumFriends) then
        return id
    end
    for i = 1, BNGetNumFriends() or 0 do
        local info = C_BattleNet.GetFriendAccountInfo(i)
        if info and ns.IsText(info.battleTag) and lower(info.battleTag) == lower(conversation.bnet) then
            bnetIds[conversation.key] = info.bnetAccountID
            return info.bnetAccountID
        end
    end
end

-- The class of the player behind a GUID, as a token, when it can be read.
local function classOf(guid)
    if not (GetPlayerInfoByGUID and ns.IsText(guid, true)) then
        return nil
    end
    local _, class = GetPlayerInfoByGUID(guid)
    if ns.IsText(class, true) then
        return class
    end
end

local function add(conversation, kind, text)
    local messages = conversation.messages
    messages[#messages + 1] = { time = time(), kind = kind, text = text }
    while #messages > MAX_MESSAGES do
        tremove(messages, 1)
    end
    conversation.last = time()
    if kind == "in" and not internal.IsReading(conversation) then
        conversation.unread = (conversation.unread or 0) + 1
    end
    internal.Changed(conversation)
end

---Marks a conversation read.
---@param conversation table
function internal.MarkRead(conversation)
    if conversation and (conversation.unread or 0) > 0 then
        conversation.unread = 0
        internal.Changed(conversation)
    end
end

---Forgets a conversation.
---@param conversation table
function internal.Remove(conversation)
    internal.Conversations()[conversation.key] = nil
    internal.Changed(nil)
end

---Forgets every conversation of this character.
function internal.Clear()
    wipe(internal.Conversations())
    internal.Changed(nil)
end

---A conversation with a name typed by hand (New Whisper), made if there's none yet.
---@param name string
---@return table
function internal.Start(name)
    local conversation = playerConversation(name, false)
        or internal.Conversations()[firstName(name)]
    if not conversation then
        conversation = newConversation(lower(name), name, name)
        conversation.typed = true
    end
    return conversation
end

-- Sending ---------------------------------------------------------------------------------------

---Whether the game holds back chat right now (Midnight's chat lockdown, in some instances).
---Probe: only Mainline clients have it.
---@return boolean
local function chatLocked()
    local info = C_ChatInfo
    return info and info.InChatMessagingLockdown and ns.IsTrueOrSecret(info.InChatMessagingLockdown())
        or false
end

---Sends a whisper in a conversation. It shows in the conversation once the game says it went
---out (CHAT_MSG_WHISPER_INFORM), as one sent from chat does. Returns false when it couldn't go.
---@param conversation table
---@param text string
---@return boolean
function internal.Send(conversation, text)
    if chatLocked() then
        ns.Frames.ErrorMessage(L.WHISPERWINDOW_LOCKED)
        return false
    end
    if conversation.bnet then
        local id = bnetId(conversation)
        if not (id and BNSendWhisper) then
            add(conversation, "info", L.WHISPERWINDOW_BNET_OFFLINE)
            return false
        end
        BNSendWhisper(id, text)
        return true
    end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    send(text, "WHISPER", nil, conversation.name)
    return true
end

---Invites the player of a conversation to the group.
---@param conversation table
function internal.Invite(conversation)
    if conversation.bnet then
        return
    end
    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(conversation.name)
    elseif InviteUnit then
        InviteUnit(conversation.name)
    end
end

-- Chat ------------------------------------------------------------------------------------------

local INCOMING = { CHAT_MSG_WHISPER = true, CHAT_MSG_BN_WHISPER = true }
local BNET = { CHAT_MSG_BN_WHISPER = true, CHAT_MSG_BN_WHISPER_INFORM = true }
local AWAY = { CHAT_MSG_AFK = L.WHISPERWINDOW_AFK, CHAT_MSG_DND = L.WHISPERWINDOW_DND }

-- Whether a whisper event's line is kept in a conversation: its text and sender can be read.
-- The chat filter asks the same, so a line is hidden in chat only when the window has it.
local function kept(event, text, sender, bnSenderID)
    if not ns.IsText(text) then
        return false
    end
    if BNET[event] then
        return bnetInfo(bnSenderID) ~= nil
    end
    return ns.IsText(sender, true)
end

-- The conversation a whisper event belongs to, made if there's none yet, or nil when it isn't kept.
local function whisperConversation(event, text, sender, bnSenderID)
    if not kept(event, text, sender, bnSenderID) then
        return nil
    end
    if BNET[event] then
        return bnetConversation(bnSenderID, true)
    end
    return playerConversation(sender, true)
end

-- Blizzard's whisper sound, as its chat plays it (once after a quiet while), for a whisper the
-- chat never shows when Hide Whispers in Chat is on.
local soundAfter = 0

local function playSound()
    local now = GetTime()
    if now >= soundAfter and PlaySound and SOUNDKIT and SOUNDKIT.TELL_MESSAGE then
        PlaySound(SOUNDKIT.TELL_MESSAGE)
    end
    soundAfter = now + (CHAT_TELL_ALERT_TIME or 300)
end

-- Who Reply (R) goes to: Blizzard's chat sets it when it shows a whisper, so a hidden one sets it
-- here. Probe: ChatFrameUtil's on Mainline, the older global elsewhere.
local function setReplyTarget(name, chatType)
    local set = ChatFrameUtil and ChatFrameUtil.SetLastTellTarget or ChatEdit_SetLastTellTarget
    if set then
        set(name, chatType)
    end
end

local function onWhisper(event, text, sender, _, _, _, _, _, _, _, _, _, guid, bnSenderID)
    local conversation = whisperConversation(event, text, sender, bnSenderID)
    if not conversation then
        return
    end
    local incoming = INCOMING[event]
    if incoming and not conversation.bnet then
        conversation.class = classOf(guid) or conversation.class
    end
    add(conversation, incoming and "in" or "out", text)
    if incoming and module.db.hideInChat then
        playSound()
        setReplyTarget(sender, conversation.bnet and "BN_WHISPER" or "WHISPER")
    end
    if module.db.openOnWhisper and not internal.IsShown() then
        ns.AfterCombat(function()
            if module.enabled and not internal.IsShown() then
                internal.Open(conversation)
            end
        end)
    end
end

local function onAway(event, text, sender)
    if not (ns.IsText(text) and ns.IsText(sender, true)) then
        return
    end
    local conversation = playerConversation(sender, false)
    if conversation then
        add(conversation, "info", format(AWAY[event], text))
    end
end

-- "No player named 'Bob' is currently playing.", in the conversation with Bob.
local notFound

local function onSystem(_, text)
    if not ns.IsText(text) then
        return
    end
    if not notFound and type(ERR_CHAT_PLAYER_NOT_FOUND_S) == "string" then
        notFound = "^" .. ns.Text.FormatPattern(ERR_CHAT_PLAYER_NOT_FOUND_S, true) .. "$"
    end
    local name = notFound and match(text, notFound)
    local conversation = name and playerConversation(name, false)
    if conversation then
        add(conversation, "info", text)
    end
end

-- The chat filter for Hide Whispers in Chat: true hides the line in every chat window.
local function filter(_, event, text, sender, _, _, _, _, _, _, _, _, _, _, bnSenderID)
    if not (module.enabled and module.db.hideInChat) then
        return false
    end
    if AWAY[event] then
        return ns.IsText(text) and ns.IsText(sender, true)
            and playerConversation(sender, false) ~= nil
    end
    return kept(event, text, sender, bnSenderID)
end

local WHISPER_EVENTS = { "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM" }

local FILTERED_EVENTS = { "CHAT_MSG_AFK", "CHAT_MSG_DND" }
for _, event in ipairs(WHISPER_EVENTS) do
    FILTERED_EVENTS[#FILTERED_EVENTS + 1] = event
end

local filtered = {} -- events with the filter on

-- The chat filter is on while the module and Hide Whispers in Chat are.
local function updateFilter()
    local on = module.enabled and module.db.hideInChat
    for _, event in ipairs(FILTERED_EVENTS) do
        if on and not filtered[event] and ns.HasEvent(event) then
            filtered[event] = ns.Chat.AddFilter(event, filter) or nil
        elseif not on and filtered[event] then
            ns.Chat.RemoveFilter(event, filter)
            filtered[event] = nil
        end
    end
end

-- The module ------------------------------------------------------------------------------------

module.actions = {
    {
        name = L.WHISPERWINDOW_SHOW,
        button = L.WHISPERWINDOW_SHOW_BUTTON,
        description = L.WHISPERWINDOW_SHOW_DESC,
        fn = function()
            internal.Toggle()
        end,
    },
    {
        name = L.WHISPERWINDOW_CLEAR_NAME,
        button = L.WHISPERWINDOW_CLEAR,
        description = L.WHISPERWINDOW_CLEAR_DESC,
        confirm = L.WHISPERWINDOW_CLEAR_CONFIRM,
        key = "WHISPERWINDOW_CLEAR",
        fn = function()
            internal.Clear()
        end,
    },
}

function module:OnEnable()
    for _, event in ipairs(WHISPER_EVENTS) do
        if ns.HasEvent(event) then
            self:On(event, onWhisper)
        end
    end
    self:On("CHAT_MSG_AFK", onAway)
    self:On("CHAT_MSG_DND", onAway)
    self:On("CHAT_MSG_SYSTEM", onSystem)
    updateFilter()
    internal.EnableWindow()
end

function module:OnDisable()
    updateFilter()
    internal.DisableWindow()
end

function module:OnOptionChanged(key)
    if key == "hideInChat" then
        updateFilter()
    else
        internal.OptionChanged(key)
    end
end

ns.AddCommand("whispers", "", L.WHISPERWINDOW_COMMAND, function()
    if module.enabled then
        internal.Toggle()
    else
        ns.Print(L.WHISPERWINDOW_OFF)
    end
end)
