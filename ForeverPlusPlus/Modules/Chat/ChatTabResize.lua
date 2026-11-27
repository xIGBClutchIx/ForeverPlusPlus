-- Chat Tab Resizing: dragging the main chat window's General tab up or down makes the window
-- taller or shorter, for a quick look at more chat (issue #29).
--
-- Blizzard's tab drag does nothing for the main window: the tab's OnDragStart returns at once for
-- DEFAULT_CHAT_FRAME, since Edit Mode owns its place and size (FloatingChatFrame.xml, build
-- 1.60.1.70205). So the drag is free, and our hook on it sizes the window from its top edge with
-- StartSizing("TOP"), as Blizzard's own resize grips size a chat window (StartSizing, then
-- StopMovingOrSizing). The tab sits on the window's top edge, so it follows the cursor.
--
-- The new height isn't written into Edit Mode's layout: that is Blizzard's saved data, and
-- changing it outside Edit Mode (EditModeManagerFrame:OnSystemSettingChange) would be our code
-- running Edit Mode's, which taints it. So the height lasts until Edit Mode lays the window out
-- again (a /reload, or another layout), and Edit Mode keeps the height it comes back at.
local _, ns = ...

local _G, CreateFrame, IsMouseButtonDown = _G, CreateFrame, IsMouseButtonDown

local L = ns.L

local module = ns.NewModule("ChatTabResize", L.CHATTABRESIZE_DESC, {
    enabled = false,
})
module.title = L.CHATTABRESIZE_TITLE
module.category = "chat"
module.added = "1.10.0"
module.notice = {
    { text = L.CHATTABRESIZE_NOTICE, description = L.CHATTABRESIZE_NOTICE_DESC },
    ns.Gamepad.LimitedNotice(), -- dragging a tab needs a mouse
}

local sizing -- the mouse button the drag started with, while the window is being sized
local driver -- our frame that sees the button let go; hidden between drags

local function stop()
    if not sizing then
        return
    end
    sizing = nil
    driver:Hide()
    local frame, tab = _G.ChatFrame1, _G.ChatFrame1Tab
    if frame then
        frame:StopMovingOrSizing()
    end
    if tab then
        tab:UnlockHighlight()
    end
end

-- Blizzard's own tab drag watches the button too (FCFTab_OnUpdate), since OnDragStop doesn't
-- always come.
local function onUpdate()
    if not (sizing and IsMouseButtonDown(sizing)) then
        stop()
    end
end

local function onDragStart(tab, button)
    local frame = _G.ChatFrame1
    -- Only the main window's tab, which Blizzard leaves alone. In Edit Mode the window is
    -- Blizzard's to move and size.
    if sizing or button ~= "LeftButton" or not frame or frame ~= _G.DEFAULT_CHAT_FRAME
        or ns.EditMode.IsActive() or not frame:IsResizable() then
        return
    end
    if not driver then
        driver = CreateFrame("Frame")
        driver:Hide()
        driver:SetScript("OnUpdate", onUpdate)
    end
    sizing = button
    frame:StartSizing("TOP")
    tab:LockHighlight()
    driver:Show()
    if _G.GameTooltip then
        _G.GameTooltip:Hide()
    end
end

function module:IsAvailable()
    local frame = _G.ChatFrame1
    return _G.ChatFrame1Tab ~= nil and frame ~= nil and frame.StartSizing ~= nil
end

function module:OnEnable()
    self:HookScript(_G.ChatFrame1Tab, "OnDragStart", onDragStart)
    self:HookScript(_G.ChatFrame1Tab, "OnDragStop", stop)
end

function module:OnDisable()
    stop()
end
