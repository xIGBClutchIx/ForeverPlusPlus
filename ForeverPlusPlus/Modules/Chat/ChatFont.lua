-- Chat Font: draws the chat windows in a font from the game's own set. Blizzard keeps the size (and
-- outline) per window, so this only swaps the file and gives it back when the module turns off.
-- SetFont takes a single file, so the alphabets the game's chat font covers with fallbacks (Korean,
-- Chinese, Cyrillic) would draw blank; the module stays off on clients in those languages.
local _, ns = ...

local ipairs, setmetatable, GetLocale = ipairs, setmetatable, GetLocale

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatFont", L.CHATFONT_DESC, {
    enabled = true,
    font = "Fonts\\FRIZQT__.TTF",
    inputBox = true,
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
    {
        key = "inputBox",
        name = L.CHATFONT_INPUT,
        description = L.CHATFONT_INPUT_DESC,
    },
}

local NON_ROMAN = { koKR = true, zhCN = true, zhTW = true, ruRU = true }

-- The font file each window or input box had before we changed it, to give back.
local original = setmetatable({}, { __mode = "k" })

---Sets a font string or edit box to the given font, keeping its size and outline.
---@param region table
---@param font string
local function setFont(region, font)
    local file, size, flags = region:GetFont()
    if not file then
        return
    end
    if original[region] == nil then
        original[region] = file
    end
    if file ~= font then
        region:SetFont(font, size, flags)
    end
end

---Gives a region back the font it had before we changed it.
---@param region table
local function restore(region)
    local file = original[region]
    if file then
        local _, size, flags = region:GetFont()
        region:SetFont(file, size, flags)
        original[region] = nil
    end
end

---The input box of a chat window, and the prompt text beside it ("Say:").
---@param frame table
---@return table[]
local function inputParts(frame)
    local box = frame.editBox
    if not box then
        return {}
    end
    return { box, box.header, box.headerSuffix }
end

---Sets a window, and with the option its input box, to the chosen font.
---@param frame table
local function apply(frame)
    setFont(frame, module.db.font)
    for _, part in ipairs(inputParts(frame)) do
        if module.db.inputBox then
            setFont(part, module.db.font)
        else
            restore(part)
        end
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
        restore(frame)
        for _, part in ipairs(inputParts(frame)) do
            restore(part)
        end
    end
end

function module:OnOptionChanged(key)
    if (key == "font" or key == "inputBox") and self.enabled then
        applyAll()
    end
end
