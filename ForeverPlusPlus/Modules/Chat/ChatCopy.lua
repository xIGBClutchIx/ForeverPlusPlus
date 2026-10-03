-- Chat Copy: a button in the column beside the chat window that opens the selected chat tab in a
-- window, in its chat colors and already selected, so Ctrl+C copies it as plain text. The lines
-- come from the chat frame's own buffer (GetMessageInfo); a line the game marks secret can't be
-- read, so it shows as a placeholder instead.
local _, ns = ...

local CreateFrame, UIParent, C_Timer = CreateFrame, UIParent, C_Timer
local max, floor, concat = math.max, math.floor, table.concat

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatCopy", L.CHATCOPY_DESC, {
    lines = 250,
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

function module:IsAvailable()
    return ChatFrame1 ~= nil and ChatFrame1.GetMessageInfo ~= nil
end

function module:OnEnable()
    button = button or newButton()
    button:Show()
    Chat.AddButton(self.name, button, 20)
end

function module:OnDisable()
    Chat.RemoveButton(self.name)
    if button then
        button:Hide()
    end
    if window then
        window:Hide()
    end
end
