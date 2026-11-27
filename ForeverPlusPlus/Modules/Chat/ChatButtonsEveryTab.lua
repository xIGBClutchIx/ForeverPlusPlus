-- Chat Buttons on Every Tab: the buttons beside the chat window (Blizzard's chat menu and channels
-- buttons, and what our modules add under them: Social Button's, Whisper Window's, Chat Copy's)
-- stay there whichever chat tab is in front. A CurseForge comment asked why they aren't.
--
-- Blizzard's buttons are children of the main window's button frame (ChatFrame1ButtonFrame,
-- FloatingChatFrame.xml), which hides with the main window while another tab is in front. Every
-- docked window is laid over the main one and has a button frame of its own in the same place, at
-- full alpha (FCFDock_AddChatFrame), so the buttons are given to the button frame of the tab in
-- front and handed on as the tab changes (FCFDock_SelectWindow). Each keeps the anchors it had,
-- which are to the main window's button frame, still in place behind the tab. Ours follow by
-- themselves: the column sits in whichever frame holds Blizzard's buttons (Lib/Chat.lua).
-- (Build 1.60.1.70205.)
local _, ns = ...

local _G, pairs, ipairs, setmetatable = _G, pairs, ipairs, setmetatable

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatButtonsEveryTab", L.CHATBUTTONSEVERYTAB_DESC, {
    enabled = false,
})
module.title = L.CHATBUTTONSEVERYTAB_TITLE
module.category = "chat"
module.added = "1.10.0"
module.notice = ns.Gamepad.HidesNotice() -- Blizzard hides the chat buttons itself then

-- The buttons we've taken from the main window's button frame, to hand on and to give back.
local moved = setmetatable({}, { __mode = "k" })

-- Gives every button to `to`. The main window's own minimize button stays: each window has one.
local function give(to)
    local main = _G.ChatFrame1
    local home = main and main.buttonFrame
    if not (home and to) then
        return
    end
    for _, child in ipairs({ home:GetChildren() }) do
        if child ~= home.minimizeButton then
            moved[child] = true
        end
    end
    for button in pairs(moved) do
        if button:GetParent() ~= to then
            button:SetParent(to)
        end
    end
    -- Ours go to wherever Blizzard's are now, and stack under them again.
    Chat.Layout()
end

-- To the tab in front, or home while that's the main window (or one that isn't docked).
local function place()
    local main = _G.ChatFrame1
    local front = Chat.FrontTab()
    give(front and front.buttonFrame or main and main.buttonFrame)
end

function module:IsAvailable()
    local main = _G.ChatFrame1
    return main ~= nil and main.buttonFrame ~= nil and Chat.Anchor() ~= nil
        and _G.FCFDock_SelectWindow ~= nil
end

function module:OnEnable()
    self:Hook("FCFDock_SelectWindow", place)
    place()
end

function module:OnDisable()
    local main = _G.ChatFrame1
    give(main and main.buttonFrame)
    for button in pairs(moved) do
        moved[button] = nil
    end
end
