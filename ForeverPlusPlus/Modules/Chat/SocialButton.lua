-- Social Button: the social (Quick Join) button sits above the chat window on its own. This puts
-- it at the bottom of the column of small buttons beside the window, with the others, and gives
-- it back its place when the module turns off. The button is an ordinary frame; Blizzard moves it
-- from its own code now and then, so its SetPoint is hooked to put it back.
local _, ns = ...

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("SocialButton", L.SOCIALBUTTON_DESC, {
})
module.title = L.SOCIALBUTTON_TITLE
module.category = "chat"

local original -- where Blizzard had the button: its parent and anchor points

local function remember(button)
    original = { parent = button:GetParent(), points = {} }
    for i = 1, button:GetNumPoints() do
        original.points[i] = { button:GetPoint(i) }
    end
end

local function restore(button)
    if not original then
        return
    end
    button:SetParent(original.parent)
    button:ClearAllPoints()
    for _, point in ipairs(original.points) do
        button:SetPoint(point[1], point[2], point[3], point[4], point[5])
    end
end

function module:IsAvailable()
    return QuickJoinToastButton ~= nil and (ChatFrameChannelButton or ChatFrameMenuButton) ~= nil
end

function module:OnEnable()
    local button = QuickJoinToastButton
    if not original then
        remember(button)
    end
    local host = (ChatFrameChannelButton or ChatFrameMenuButton):GetParent()
    if host then
        button:SetParent(host)
    end
    Chat.AddButton(self.name, button, 10)
    self:Hook(button, "SetPoint", function()
        if not Chat.IsLaying() then
            Chat.Layout()
        end
    end)
end

function module:OnDisable()
    Chat.RemoveButton(self.name, true)
    restore(QuickJoinToastButton)
end
