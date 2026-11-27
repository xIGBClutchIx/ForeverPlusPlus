-- Chat Tab Resizing: dragging the main chat window's General tab up or down makes the window
-- taller or shorter, for a quick look at more chat (issue #29).
--
-- Blizzard's tab drag does nothing for the main window: the tab's OnDragStart returns at once for
-- DEFAULT_CHAT_FRAME, since Edit Mode owns its place and size (FloatingChatFrame.xml, build
-- 1.60.1.70205). So the drag is free, and our hook on it sizes the window from its top edge with
-- StartSizing("TOP"), as Blizzard's own resize grips size a chat window (StartSizing, then
-- StopMovingOrSizing). The tab sits on the window's top edge, so it follows the cursor.
--
-- Edit Mode owns the window's height: it lays the window out again from its layout at a /reload
-- or a change of layout. So with Save to Edit Mode the new height is written into the layout in
-- use once the drag ends (ns.EditMode.SaveSettings, the game's own save calls), as resizing the
-- window in Edit Mode and pressing Save would. Never through EditModeManagerFrame
-- (OnSystemSettingChange), which would be our code running Edit Mode's and taint it. Blizzard's
-- preset layouts can't be changed, so with one in use, or the option off, the height lasts until
-- Edit Mode lays the window out again.
local _, ns = ...

local _G, CreateFrame, IsMouseButtonDown, floor = _G, CreateFrame, IsMouseButtonDown, math.floor

local L = ns.L

local module = ns.NewModule("ChatTabResize", L.CHATTABRESIZE_DESC, {
    enabled = true,
    save = true, -- write the new height into the Edit Mode layout in use
})
module.title = L.CHATTABRESIZE_TITLE
module.category = "chat"
module.added = "1.10.0"
module.options = {
    { key = "save", name = L.CHATTABRESIZE_SAVE, description = L.CHATTABRESIZE_SAVE_DESC },
}
module.notice = {
    {
        text = L.CHATTABRESIZE_NOTICE, description = L.CHATTABRESIZE_NOTICE_DESC,
        shown = function()
            return not module.db.save
        end,
    },
    {
        text = L.CHATTABRESIZE_PRESET, description = L.CHATTABRESIZE_PRESET_DESC,
        shown = function()
            return module.db.save and ns.EditMode.OwnLayout() == false
        end,
    },
    ns.Gamepad.LimitedNotice(), -- dragging a tab needs a mouse
}

local sizing -- the mouse button the drag started with, while the window is being sized
local driver -- our frame that sees the button let go; hidden between drags
local before -- the window's height when the drag began

-- The window's height into the Edit Mode layout in use, kept as Edit Mode keeps it: hundreds and
-- the rest apart (EditModeChatFrameSystemMixin:UpdateSystemSettingHeight).
local function save()
    local frame = _G.ChatFrame1
    local systems = Enum and Enum.EditModeSystem
    local settings = Enum and Enum.EditModeChatFrameSetting
    if not (module.enabled and module.db.save and frame and systems and systems.ChatFrame and settings
        and settings.HeightHundreds and settings.HeightTensAndOnes) then
        return
    end
    local height = floor(frame:GetHeight() + 0.5)
    ns.EditMode.SaveSettings(systems.ChatFrame, {
        [settings.HeightHundreds] = floor(height / 100),
        [settings.HeightTensAndOnes] = height % 100,
    })
end

local function stop()
    if not sizing then
        return
    end
    sizing = nil
    driver:Hide()
    local frame, tab = _G.ChatFrame1, _G.ChatFrame1Tab
    if frame then
        frame:StopMovingOrSizing()
        if before and floor(frame:GetHeight() + 0.5) ~= before then
            ns.AfterCombat(save) -- the game's layouts can't be saved in combat
        end
    end
    before = nil
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
    before = floor(frame:GetHeight() + 0.5)
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
    -- Another layout came into use: the notice about Blizzard's own layouts follows it.
    if ns.HasEvent("EDIT_MODE_LAYOUTS_UPDATED") then
        self:On("EDIT_MODE_LAYOUTS_UPDATED", function()
            if ns.RefreshSetting then
                ns.RefreshSetting(module.name)
            end
        end)
    end
end

function module:OnDisable()
    stop()
end
