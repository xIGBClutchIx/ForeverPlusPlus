-- Chat History: keeps each chat window's latest lines across logging out and reloading. The
-- lines are read from the windows' own buffers as the game logs out (PLAYER_LOGOUT, which a
-- reload also sends), so nothing runs while you play, and put back with AddMessage at login.
-- Colors and links are kept because the lines are saved as they were drawn. A line the game
-- marks secret can't be read, so it isn't saved.
local _, ns = ...

local ipairs, type, max = ipairs, type, math.max

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatHistory", L.CHATHISTORY_DESC, {
    lines = 100,
    saved = {}, -- chat window number -> { { text, r, g, b }, ... }
})
module.title = L.CHATHISTORY_TITLE
module.category = "chat"

module.options = {
    {
        key = "lines",
        name = L.CHATHISTORY_LINES,
        description = L.CHATHISTORY_LINES_DESC,
        min = 25, max = 250, step = 25, format = "%d",
    },
}

local function save()
    local saved = {}
    for index, frame in ipairs(Chat.Frames()) do
        local total = frame:GetNumMessages()
        local lines = {}
        for i = max(1, total - module.db.lines + 1), total do
            local text, r, g, b = frame:GetMessageInfo(i)
            if ns.IsReadable(text) and type(text) == "string" and text ~= L.CHATHISTORY_DIVIDER
                and ns.IsReadable(r) and ns.IsReadable(g) and ns.IsReadable(b) then
                lines[#lines + 1] = { text, r, g, b }
            end
        end
        if #lines > 0 then
            saved[index] = lines
        end
    end
    module.db.saved = saved
end

local function restore(_, isLogin, isReload)
    if not (isLogin or isReload) then
        return
    end
    for index, frame in ipairs(Chat.Frames()) do
        local lines = module.db.saved[index]
        if lines and #lines > 0 then
            for _, line in ipairs(lines) do
                frame:AddMessage(line[1], line[2], line[3], line[4])
            end
            frame:AddMessage(L.CHATHISTORY_DIVIDER, 0.6, 0.6, 0.6)
        end
    end
end

function module:IsAvailable()
    return ChatFrame1 ~= nil and ChatFrame1.GetMessageInfo ~= nil
end

function module:OnEnable()
    self:On("PLAYER_LOGOUT", save)
    self:On("PLAYER_ENTERING_WORLD", restore)
end

function module:OnDisable()
    self.db.saved = {}
end
