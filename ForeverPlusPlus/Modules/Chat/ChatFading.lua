-- Keep Chat Visible: keeps chat text on screen. Blizzard fades each window's lines out after a while;
-- this turns that off per window and gives the window's own setting back when the module stops.
local _, ns = ...

local ipairs, setmetatable = ipairs, setmetatable

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatFading", L.CHATFADING_DESC, {
    enabled = true,
})
module.title = L.CHATFADING_TITLE
module.category = "chat"

-- Whether each window faded before we changed it, to give back.
local original = setmetatable({}, { __mode = "k" })

---Stops a window's text fading out.
---@param frame table
local function apply(frame)
    if not (frame.SetFading and frame.GetFading) then
        return
    end
    if original[frame] == nil then
        original[frame] = frame:GetFading() and true or false
    end
    frame:SetFading(false)
end

local function applyAll()
    for _, frame in ipairs(Chat.Frames()) do
        apply(frame)
    end
end

function module:IsAvailable()
    return ChatFrame1 ~= nil
end

function module:OnEnable()
    applyAll()
    -- A window that was reset or added later starts with Blizzard's fading.
    self:On("UPDATE_CHAT_WINDOWS", applyAll)
    self:On("UPDATE_FLOATING_CHAT_WINDOWS", applyAll)
end

function module:OnDisable()
    for _, frame in ipairs(Chat.Frames()) do
        local fading = original[frame]
        if fading ~= nil then
            frame:SetFading(fading)
            original[frame] = nil
        end
    end
end
