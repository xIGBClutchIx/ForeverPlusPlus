-- Chat Copy: a button in the column beside the chat window that opens the selected chat tab as
-- plain text in a window, already selected, so Ctrl+C copies it. The lines come from the chat
-- frame's own buffer (GetMessageInfo); a line the game marks secret can't be read, so it shows
-- as a placeholder instead.
local _, ns = ...

local CreateFrame, UIParent, C_Timer = CreateFrame, UIParent, C_Timer
local max, concat = math.max, table.concat

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatCopy", L.CHATCOPY_DESC, {
    enabled = false,
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

-- The window's text box is limited in length; a long chat drops its oldest lines to fit.
local MAX_LETTERS = 200000

local button, window

---The text of the chat window the player is looking at, newest line last.
---@return string
local function chatText()
    local frame = SELECTED_CHAT_FRAME or ChatFrame1
    if not (frame and frame.GetNumMessages and frame.GetMessageInfo) then
        return ""
    end
    local total = frame:GetNumMessages()
    local lines = {}
    for i = max(1, total - module.db.lines + 1), total do
        local text = frame:GetMessageInfo(i)
        if ns.IsReadable(text) and type(text) == "string" then
            lines[#lines + 1] = Chat.Plain(text)
        else
            lines[#lines + 1] = L.CHATCOPY_HIDDEN
        end
    end
    local text = concat(lines, "\n")
    if #text > MAX_LETTERS then
        text = text:sub(-MAX_LETTERS)
    end
    return text
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
    window.edit:SetText(text ~= "" and text or L.CHATCOPY_EMPTY)
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
