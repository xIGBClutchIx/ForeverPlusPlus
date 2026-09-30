-- Chat Font: draws the chat windows in a font from the game's own set. Blizzard keeps the size (and
-- outline) per window, so this only swaps the file and gives it back when the module turns off.
-- SetFont takes a single file, so the alphabets the game's chat font covers with fallbacks (Korean,
-- Chinese, Cyrillic) would draw blank; the module stays off on clients in those languages.
local _, ns = ...

local ipairs, setmetatable, GetLocale = ipairs, setmetatable, GetLocale

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatFont", L.CHATFONT_DESC, {
    enabled = false,
    font = "Fonts\\ARIALN.TTF",
})
module.title = L.CHATFONT_TITLE
module.category = "chat"

module.options = {
    {
        key = "font",
        name = L.CHATFONT_FONT,
        description = L.CHATFONT_FONT_DESC,
        choices = {
            { "Fonts\\FRIZQT__.TTF", L.CHATFONT_FRIZQT },
            { "Fonts\\ARIALN.TTF", L.CHATFONT_ARIALN },
            { "Fonts\\skurri.ttf", L.CHATFONT_SKURRI },
            { "Fonts\\MORPHEUS.TTF", L.CHATFONT_MORPHEUS },
        },
    },
}

local NON_ROMAN = { koKR = true, zhCN = true, zhTW = true, ruRU = true }

-- The font file each window had before we changed it, to give back.
local original = setmetatable({}, { __mode = "k" })

---Sets a window to the chosen font, keeping its size and outline.
---@param frame table
local function apply(frame)
    local file, size, flags = frame:GetFont()
    if not file then
        return
    end
    if original[frame] == nil then
        original[frame] = file
    end
    if file ~= module.db.font then
        frame:SetFont(module.db.font, size, flags)
    end
end

local function applyAll()
    for _, frame in ipairs(Chat.Frames()) do
        apply(frame)
    end
end

function module:IsAvailable()
    return ChatFrame1 ~= nil and not NON_ROMAN[GetLocale()]
end

function module:OnEnable()
    applyAll()
    -- Blizzard changes a window's size with SetFont on the file it reads back, which is ours by now;
    -- this covers a window that was reset or added later.
    self:Hook("FCF_SetChatWindowFontSize", applyAll)
    self:On("UPDATE_CHAT_WINDOWS", applyAll)
    self:On("UPDATE_FLOATING_CHAT_WINDOWS", applyAll)
end

function module:OnDisable()
    for _, frame in ipairs(Chat.Frames()) do
        local file = original[frame]
        if file then
            local _, size, flags = frame:GetFont()
            frame:SetFont(file, size, flags)
            original[frame] = nil
        end
    end
end

function module:OnOptionChanged(key)
    if key == "font" and self.enabled then
        applyAll()
    end
end
