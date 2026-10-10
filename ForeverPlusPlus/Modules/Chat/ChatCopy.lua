-- Chat Copy: a button in the column beside the chat window that opens the selected chat tab in a
-- window, in its chat colors and already selected, so Ctrl+C copies it as plain text. The lines
-- come from the chat frame's own buffer (GetMessageInfo); a line the game marks secret can't be
-- read, so it shows as a placeholder instead.
-- Its Click Timestamps option makes the timestamp Blizzard puts on each chat line a link: clicking
-- it shows that line in a popup to copy. Blizzard adds the stamp itself, so the finished line is
-- rewritten through the chat frame's own TransformMessages, a frame after it arrives (so other
-- modules rewriting the same line see it first). The link is the stamp's own text in the line's
-- color, so nothing looks different. The game can't copy for an addon (CopyToClipboard is
-- Blizzard's only), hence the popup.
local _, ns = ...

local CreateFrame, UIParent, C_Timer, EventRegistry = CreateFrame, UIParent, C_Timer, EventRegistry
local ipairs, pairs, next, type, time = ipairs, pairs, next, type, time
local max, floor, concat = math.max, math.floor, table.concat
local find, gsub, match, sub = string.find, string.gsub, string.match, string.sub

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatCopy", L.CHATCOPY_DESC, {
    lines = 250,
    stamps = false,
})
module.title = L.CHATCOPY_TITLE
module.category = "chat"

module.options = {
    {
        key = "lines",
        name = L.CHATCOPY_LINES,
        description = L.CHATCOPY_LINES_DESC,
        min = 50, max = 500, step = 50, format = "%d",
    },
    {
        key = "stamps",
        name = L.CHATCOPY_STAMPS,
        description = L.CHATCOPY_STAMPS_DESC,
        added = "0.8.0",
    },
}

-- The window's text box is limited in length; a long chat drops its oldest lines to fit, with
-- room left for the selection marker below.
local MAX_LETTERS = 200000
local MAX_TEXT = MAX_LETTERS - 100

-- Copying from an edit box copies its raw text, color codes and all, so while Ctrl (or Cmd) is
-- held the box holds the plain text instead, with the same selection.
local COPY_KEYS = { LCTRL = true, RCTRL = true, LMETA = true, RMETA = true }
-- Typed over the selection to find where it is; edit boxes have no way to ask.
local MARKER = "{fpp:selection}"

local button, window

---The chat window the player is looking at in its chat colors, newest line last.
---@return string
local function chatText()
    local frame = SELECTED_CHAT_FRAME or ChatFrame1
    if not (frame and frame.GetNumMessages and frame.GetMessageInfo) then
        return ""
    end
    local total = frame:GetNumMessages()
    local lines, size = {}, 0
    for i = total, max(1, total - module.db.lines + 1), -1 do
        local text, r, g, b = frame:GetMessageInfo(i)
        local line
        if ns.IsReadable(text) and type(text) == "string" then
            if not (ns.IsReadable(r) and ns.IsReadable(g) and ns.IsReadable(b)) then
                r, g, b = nil, nil, nil
            end
            line = Chat.Colored(text, r, g, b)
        else
            line = L.CHATCOPY_HIDDEN
        end
        size = size + #line + 1
        if size > MAX_TEXT then
            break
        end
        lines[#lines + 1] = line
    end
    -- Gathered newest first; the window shows them oldest first.
    local count = #lines
    for i = 1, floor(count / 2) do
        lines[i], lines[count - i + 1] = lines[count - i + 1], lines[i]
    end
    return concat(lines, "\n")
end

---Where the selection is in the box's text, as the bytes before its start and its end. This types
---over the selection, so the caller sets the box's text again after.
---@param edit table
---@param text string what the box holds
---@return number? start
---@return number? finish
local function selection(edit, text)
    edit:Insert(MARKER)
    local now = edit:GetText()
    local at = now:find(MARKER, 1, true)
    if not at then
        return nil
    end
    local start = at - 1
    return start, #text - (#now - start - #MARKER)
end

---Shows the plain or the colored text, keeping the selection and the scroll.
---@param plain boolean
local function showPlain(plain)
    if not window or window.plain == plain then
        return
    end
    local edit, colored = window.edit, window.colored
    local from = window.plain and Chat.Uncolor(colored) or colored
    local scroll = window.scroll:GetVerticalScroll()
    local start, finish = selection(edit, from)
    local length = #from
    edit:SetText(plain and Chat.Uncolor(colored) or colored)
    window.plain = plain
    if start == 0 and finish == length then
        edit:HighlightText()
    elseif start then
        local convert = plain and Chat.PlainOffset or Chat.ColoredOffset
        start, finish = convert(colored, start), convert(colored, finish)
        edit:SetCursorPosition(finish)
        edit:HighlightText(start, finish)
    end
    window.scroll:SetVerticalScroll(scroll)
end

local function newWindow()
    local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(540, 420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", f.StartMoving)
    f:SetScript("OnMouseUp", f.StopMovingOrSizing)
    if f.SetTitle then
        f:SetTitle(L.CHATCOPY_TITLE)
    elseif f.TitleText then
        f.TitleText:SetText(L.CHATCOPY_TITLE)
    end

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    -- Below the title bar, which is about 24 pixels tall.
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -36)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 12)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetMaxLetters(MAX_LETTERS)
    edit:SetWidth(480)
    edit:SetScript("OnEscapePressed", function()
        f:Hide()
    end)
    edit:SetScript("OnKeyDown", function(_, key)
        if COPY_KEYS[key] then
            showPlain(true)
        end
    end)
    edit:SetScript("OnKeyUp", function(_, key)
        if COPY_KEYS[key] then
            showPlain(false)
        end
    end)
    edit:SetScript("OnEditFocusLost", function()
        showPlain(false)
    end)
    scroll:SetScrollChild(edit)
    scroll:SetScript("OnSizeChanged", function(_, width)
        edit:SetWidth(width)
    end)

    f.edit, f.scroll = edit, scroll
    f:Hide()
    return f
end

local function open()
    window = window or newWindow()
    local text = chatText()
    window.colored = text ~= "" and text or L.CHATCOPY_EMPTY
    window.plain = false
    window.edit:SetText(window.colored)
    window:Show()
    window.edit:SetFocus()
    window.edit:HighlightText()
    -- Newest lines are at the bottom; the scroll range is known once the text has been laid out.
    C_Timer.After(0, function()
        if window:IsShown() then
            window.scroll:SetVerticalScroll(window.scroll:GetVerticalScrollRange())
        end
    end)
end

local function toggle()
    if window and window:IsShown() then
        window:Hide()
    else
        open()
    end
end

local function newButton()
    -- In the chat window's button frame, so it fades along with Blizzard's buttons.
    local b = CreateFrame("Button", nil, ChatFrame1.buttonFrame or ChatFrame1.ButtonFrame or UIParent)
    local template = ChatFrameChannelButton or ChatFrameMenuButton
    b:SetSize(template and template:GetWidth() or 32, template and template:GetHeight() or 32)
    -- The same button art as Blizzard's menu and channel buttons.
    b:SetNormalAtlas("chatframe-button-up")
    b:SetPushedAtlas("chatframe-button-down")
    b:SetHighlightAtlas("chatframe-button-highlight")
    local icon = b:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    b:SetScript("OnMouseDown", function()
        icon:SetPoint("CENTER", 1, -1)
    end)
    b:SetScript("OnMouseUp", function()
        icon:SetPoint("CENTER", 0, 0)
    end)
    b:SetScript("OnClick", toggle)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.CHATCOPY_TOOLTIP)
        GameTooltip:AddLine(L.CHATCOPY_TOOLTIP_DESC, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

-- Click Timestamps ----------------------------------------------------------------------------

-- addon links go to EventRegistry's "SetItemRef" when clicked. The number tells the lines apart:
-- the session's start time, then a count, since Chat History brings back lines from before.
local LINK_PREFIX = "addon:ForeverPlusPlus:stamp:"
local LINKED = "^|H" .. LINK_PREFIX .. "[%d%.]+|h(.-)|h"
local SESSION = time() .. "."

local stampsOn = false
local lastStamp = 0
local pending = {}

---The chat timestamp format the player picked, or nil while timestamps are off.
---@return string?
local function stampFormat()
    local format
    if ChatFrameUtil and ChatFrameUtil.GetTimestampFormat then
        format = ChatFrameUtil.GetTimestampFormat()
    else
        format = CHAT_TIMESTAMP_FORMAT
    end
    if type(format) == "string" and format ~= "" then
        return format
    end
end

---Makes the timestamp of each line in a chat window that has none yet a link.
---@param frame table
local function linkStamps(frame)
    local format = stampFormat()
    if not (format and frame.TransformMessages) then
        return
    end
    local pattern = Chat.TimestampPattern(format)
    frame:TransformMessages(function(message)
        return ns.IsReadable(message) and type(message) == "string" and find(message, pattern) ~= nil
    end, function(message, ...)
        local _, finish = find(message, pattern)
        -- The space after the stamp stays outside the link.
        local stamp, space = match(sub(message, 1, finish), "^(.-)(%s*)$")
        lastStamp = lastStamp + 1
        return "|H" .. LINK_PREFIX .. SESSION .. lastStamp .. "|h" .. stamp .. "|h" .. space
            .. sub(message, finish + 1), ...
    end)
end

---Puts every line of a chat window back the way Blizzard wrote it.
---@param frame table
local function unlinkStamps(frame)
    if not frame.TransformMessages then
        return
    end
    frame:TransformMessages(function(message)
        return ns.IsReadable(message) and type(message) == "string" and find(message, LINKED) ~= nil
    end, function(message, ...)
        return (gsub(message, LINKED, "%1", 1)), ...
    end)
end

local function linkPending()
    for frame in pairs(pending) do
        pending[frame] = nil
        if stampsOn then
            linkStamps(frame)
        end
    end
end

local function onMessage(frame)
    if not stampsOn then
        return
    end
    if not next(pending) then
        C_Timer.After(0, linkPending)
    end
    pending[frame] = true
end

---Shows the chat line that has a stamp link in a popup, as plain text ready to copy.
---@param link string
---@param frame table? the chat window it was clicked in
local function onStampClick(_, link, _, button, frame)
    if not (stampsOn and type(link) == "string" and button == "LeftButton") then
        return
    end
    local id = match(link, "^" .. LINK_PREFIX .. "([%d%.]+)$")
    if not id then
        return
    end
    frame = frame or SELECTED_CHAT_FRAME or ChatFrame1
    if not (frame and frame.GetNumMessages and frame.GetMessageInfo) then
        return
    end
    local wanted = "|H" .. LINK_PREFIX .. id .. "|h"
    for i = 1, frame:GetNumMessages() do
        local text = frame:GetMessageInfo(i)
        if ns.IsReadable(text) and type(text) == "string" and find(text, wanted, 1, true) == 1 then
            ns.Prompt("CHATCOPY_LINE", L.CHATCOPY_STAMPS_PROMPT, Chat.Plain(text))
            return
        end
    end
end

local function attach()
    for _, frame in ipairs(Chat.Frames()) do
        module:Hook(frame, "AddMessage", onMessage)
    end
end

---Turns Click Timestamps on or off to match the option.
local function updateStamps()
    local on = (module.enabled and module.db.stamps and EventRegistry ~= nil) and true or false
    if on == stampsOn then
        return
    end
    stampsOn = on
    if on then
        attach()
        EventRegistry:RegisterCallback("SetItemRef", onStampClick, module)
        for _, frame in ipairs(Chat.Frames()) do
            linkStamps(frame)
        end
    else
        EventRegistry:UnregisterCallback("SetItemRef", module)
        for _, frame in ipairs(Chat.Frames()) do
            unlinkStamps(frame)
        end
    end
end

function module:OnOptionChanged(key)
    if key == "stamps" then
        updateStamps()
    end
end

function module:IsAvailable()
    return ChatFrame1 ~= nil and ChatFrame1.GetMessageInfo ~= nil
end

function module:OnEnable()
    button = button or newButton()
    button:Show()
    Chat.AddButton(self.name, button, 20)
    updateStamps()
    -- A chat window added later.
    self:On("UPDATE_CHAT_WINDOWS", function()
        if stampsOn then
            attach()
        end
    end)
    self:On("UPDATE_FLOATING_CHAT_WINDOWS", function()
        if stampsOn then
            attach()
        end
    end)
end

function module:OnDisable()
    updateStamps()
    Chat.RemoveButton(self.name)
    if button then
        button:Hide()
    end
    if window then
        window:Hide()
    end
end
