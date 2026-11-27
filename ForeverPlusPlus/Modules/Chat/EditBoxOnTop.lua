-- Edit Box on Top: the box chat is typed in sits above its chat window's tabs instead of under
-- the window.
--
-- Each window's edit box (`frame.editBox`) is anchored once, in FloatingChatFrame.xml, under its
-- window: nothing of Blizzard's moves it afterwards, so its place is ours to change and to give
-- back. It goes above the window's background, which the tabs stand on (FCF_SetTabPosition) and
-- which already reaches over the Combat Log's bar of filter buttons, as wide as it was: the
-- background's width and one more to the right. The anchors it had are kept to put back, so one
-- another addon had moved returns to where that addon left it.
-- (wow-ui-source's `forever` branch, read 2026-11-24.)
--
-- The main chat window is also let down to the bottom of the screen. Edit Mode keeps it clear of
-- every edge by as much as its selection box reaches past it (EditModeSystemMixin's
-- UpdateClampOffsets, and the box's anchors in EditModeChatFrameSystemTemplate: 32 left for the
-- buttons, 60 up for the tabs, 32 down for the edit box), so with the edit box gone from under it
-- the window stopped 32 short of the bottom for nothing (a CurseForge comment). The room above is
-- already enough for the box: it ends 57 over the window. Only ChatFrame1 is an Edit Mode system;
-- the other windows have no such margins. (Build 1.60.1.70205.)
local _, ns = ...

local _G, ipairs, setmetatable = _G, ipairs, setmetatable

local L = ns.L
local Chat = ns.Chat
local Frames = ns.Frames

local module = ns.NewModule("EditBoxOnTop", L.EDITBOXONTOP_DESC, {
    enabled = false,
})
module.title = L.EDITBOXONTOP_TITLE
module.category = "chat"
module.added = "1.9.0"

-- How far above the background's top the box's bottom goes: past the tabs, which are 32 high but
-- drawn in the lower 24 or so, less the few empty pixels at the bottom of the box's own art.
local ABOVE = 22

-- The anchors each edit box had before we moved it, to give back.
local original = setmetatable({}, { __mode = "k" })

---Moves a window's edit box above its tabs.
---@param frame table a chat window
local function apply(frame)
    local box, background = frame.editBox, frame.Background
    if not (box and background and box.GetNumPoints) then
        return
    end
    if not original[box] then
        original[box] = Frames.GetPoints(box)
    end
    box:ClearAllPoints()
    box:SetPoint("BOTTOMLEFT", background, "TOPLEFT", -3, ABOVE)
    box:SetPoint("BOTTOMRIGHT", background, "TOPRIGHT", 1, ABOVE)
end

-- How far under the main window the screen's edge may come: as far as its background reaches
-- (FloatingBorderedFrame's Background, 6 below the window), so that sits on the edge.
local BOTTOM = -6

-- The main window's own margin under it, to give back.
local bottomInset

-- Lets the main chat window down to the bottom of the screen. Also after Blizzard works its
-- margins out again, as it does each time Edit Mode lays the window's selection box out.
local function unclamp()
    local frame = _G.ChatFrame1
    if not (frame and frame.GetClampRectInsets and frame.SetClampRectInsets) then
        return
    end
    local left, right, top, bottom = frame:GetClampRectInsets()
    if bottom ~= BOTTOM then
        bottomInset = bottom
        frame:SetClampRectInsets(left, right, top, BOTTOM)
    end
end

local function reclamp()
    local frame = _G.ChatFrame1
    if not (bottomInset and frame and frame.GetClampRectInsets and frame.SetClampRectInsets) then
        return
    end
    local left, right, top, bottom = frame:GetClampRectInsets()
    if bottom == BOTTOM then
        frame:SetClampRectInsets(left, right, top, bottomInset)
    end
    bottomInset = nil
end

function module:IsAvailable()
    return _G.ChatFrame1 ~= nil and _G.ChatFrame1.editBox ~= nil
end

function module:OnEnable()
    -- Also a window added later: one made for a whisper, or one a reset brings back.
    Chat.EachWindow(self, apply)
    self:Hook(_G.ChatFrame1, "UpdateClampOffsets", unclamp)
    unclamp()
end

function module:OnDisable()
    reclamp()
    for _, frame in ipairs(Chat.Frames()) do
        local box = frame.editBox
        local points = box and original[box]
        if points then
            original[box] = nil
            if points[1] then
                Frames.SetPoints(box, points)
            end
        end
    end
end
