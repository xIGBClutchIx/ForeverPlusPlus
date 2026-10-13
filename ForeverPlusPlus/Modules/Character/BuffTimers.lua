-- Buff Timers: the time left under your buff and debuff icons as a clock (1:23) instead of
-- Blizzard's rounded "2 m". Blizzard's text keeps running underneath at no alpha and ours sits on
-- top, so when a time can't be read (a secret value in combat) Blizzard's shows again as it was.
local _, ns = ...

local ipairs, pairs, type, setmetatable = ipairs, pairs, type, setmetatable
local GetCVarBool = C_CVar and C_CVar.GetCVarBool or GetCVarBool

local L = ns.L
local readable = ns.IsReadable
local clock = ns.Text.Clock

local module = ns.NewModule("BuffTimers", L.BUFFTIMERS_DESC, {
    enabled = true,
    limit = "10m", -- "1m", "10m", "hour", or "all": which auras get a clock
})
module.title = L.BUFFTIMERS_TITLE
module.category = "character"
module.added = "0.8.0"
-- Blizzard shows its own Duration text only with this CVar on, and so do we (see below).
module.notice = ns.CVars.OffNotice(module, "buffDurations", L.BUFFTIMERS_BLIZZARD_OFF,
    L.BUFFTIMERS_BLIZZARD_OFF_DESC)

module.options = {
    {
        key = "limit", name = L.BUFFTIMERS_LIMIT, description = L.BUFFTIMERS_LIMIT_DESC,
        changed = "0.8.2",
        choices = {
            { "1m", L.BUFFTIMERS_LIMIT_1M },
            { "10m", L.BUFFTIMERS_LIMIT_10M },
            { "hour", L.BUFFTIMERS_LIMIT_1H },
            { "all", L.BUFFTIMERS_LIMIT_ALL },
        },
    },
}

local LIMITS = { ["1m"] = 60, ["10m"] = 600, hour = 3600 }
local WARNING = 31 -- Blizzard's BUFF_DURATION_WARNING_TIME, if it's missing

local texts = setmetatable({}, { __mode = "k" }) -- aura button -> our FontString

local function restore(button)
    local text = texts[button]
    if text then
        text:Hide()
    end
    button.Duration:SetAlpha(1)
end

-- After Blizzard's AuraButtonMixin:UpdateDuration, which runs every frame while the aura counts
-- down. It shows its Duration text only with the "buffDurations" CVar on, so we do too.
local function update(button, timeLeft)
    local limit = LIMITS[module.db.limit]
    if not (readable(timeLeft) and timeLeft and GetCVarBool("buffDurations")
        and (not limit or timeLeft < limit)) then
        restore(button)
        return
    end
    local duration = button.Duration
    local text = texts[button]
    if not text then
        text = button:CreateFontString(nil, "OVERLAY")
        text:SetPoint("TOP", duration, "TOP")
        texts[button] = text
    end
    text:SetFontObject(duration:GetFontObject())
    text:SetText(clock(timeLeft))
    -- Blizzard's colors: white in the last half minute, gold before.
    local color = timeLeft < (BUFF_DURATION_WARNING_TIME or WARNING) and HIGHLIGHT_FONT_COLOR
        or NORMAL_FONT_COLOR
    text:SetTextColor(color.r, color.g, color.b)
    text:Show()
    duration:SetAlpha(0)
end

-- An aura with no end hides Blizzard's text and stops counting without UpdateDuration.
-- A secret time left (in combat) leaves Blizzard's own text, as `update` does.
local function expiration(button)
    local timeLeft = button.timeLeft
    if not readable(timeLeft) or not timeLeft then
        restore(button)
    end
end

-- Blizzard's buff and debuff buttons (made once when the frames load) and the big deadly debuff.
local function buttons()
    local list = {}
    for _, frame in ipairs({ BuffFrame, DebuffFrame }) do
        for _, button in ipairs(frame and frame.auraFrames or {}) do
            list[#list + 1] = button
        end
    end
    if DeadlyDebuffFrame then
        list[#list + 1] = DeadlyDebuffFrame.Debuff
    end
    return list
end

-- Edit Mode's example auras, and buttons left without an aura, don't count down through
-- UpdateDuration, so our clock would stay as it was.
local function afterAuraButtons(frame)
    for _, button in ipairs(frame.auraFrames or {}) do
        if texts[button] and (button.isExample or not button:IsShown()) then
            restore(button)
        end
    end
end

function module:OnEnable()
    for _, button in ipairs(buttons()) do
        if type(button.UpdateDuration) == "function" and button.Duration then
            self:Hook(button, "UpdateDuration", update)
            self:Hook(button, "UpdateExpirationTime", expiration)
        end
    end
    self:Hook(BuffFrame, "UpdateAuraButtons", afterAuraButtons)
    self:Hook(DebuffFrame, "UpdateAuraButtons", afterAuraButtons)
end

function module:OnDisable()
    for button in pairs(texts) do
        restore(button)
    end
end
