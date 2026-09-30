-- Combat Alert: a line of text that floats up and fades above the middle of the screen when you
-- enter or leave combat, in the game's big title font, red going in and green coming out. The
-- combat log is closed to addons on Forever, so this follows the player's own combat state
-- (PLAYER_REGEN_DISABLED and PLAYER_REGEN_ENABLED), which is the same thing the log would say.
local _, ns = ...

local CreateFrame, UIParent = CreateFrame, UIParent

local L = ns.L
local Colors = ns.Colors

local module = ns.NewModule("CombatAlert", L.COMBATALERT_DESC, {
    enabled = false,
    entering = true,
    leaving = true,
    scale = 100, -- percent
    duration = 2, -- seconds
    x = 0, -- the text's offset from the center of the screen
    y = 120,
})
module.title = L.COMBATALERT_TITLE
module.category = "interface"

module.options = {
    { key = "entering", name = L.COMBATALERT_ENTERING, description = L.COMBATALERT_ENTERING_DESC },
    { key = "leaving", name = L.COMBATALERT_LEAVING, description = L.COMBATALERT_LEAVING_DESC },
    {
        key = "scale",
        name = L.COMBATALERT_SCALE,
        description = L.COMBATALERT_SCALE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
    {
        key = "duration",
        name = L.COMBATALERT_DURATION,
        description = L.COMBATALERT_DURATION_DESC,
        min = 1, max = 5, step = 1, format = ns.Text.Seconds,
    },
}

local DEFAULT_X, DEFAULT_Y = 0, 120
local WIDTH, HEIGHT = 400, 50
local RISE = 40 -- how far the text floats up, in pixels

local frame, rise, fade

local function newFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("HIGH")
    -- The big gold font Blizzard uses for zone names and the like.
    -- The text sits in a child that takes the scale, so the frame's own size and position stay
    -- in screen units for Edit Mode.
    f.inner = CreateFrame("Frame", nil, f)
    f.inner:SetSize(WIDTH, HEIGHT)
    f.inner:SetPoint("CENTER") -- a scaled frame scales about its center, so keep it centered
    f.text = f.inner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.text:SetPoint("CENTER")
    f.text:SetShadowOffset(1, -1)
    local group = f:CreateAnimationGroup()
    rise = group:CreateAnimation("Translation")
    rise:SetOffset(0, RISE)
    rise:SetOrder(1)
    fade = group:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetOrder(1)
    group:SetScript("OnFinished", function()
        if not ns.EditMode.IsActive() then
            f:Hide()
        end
    end)
    f.group = group
    f:Hide()
    return f
end

local function place()
    frame.inner:SetScale(module.db.scale / 100)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", module.db.x, module.db.y)
end

-- Shows `text` in a color, floating up for the set time and fading out over the second half.
local function alert(text, color)
    frame.group:Stop()
    frame.text:SetText(text)
    frame.text:SetTextColor(color[1], color[2], color[3])
    local duration = module.db.duration
    rise:SetDuration(duration)
    fade:SetStartDelay(duration / 2)
    fade:SetDuration(duration / 2)
    frame:SetAlpha(1)
    frame:Show()
    frame.group:Play()
end

local function entering()
    if module.db.entering then
        alert(L.COMBATALERT_ENTER_TEXT, Colors.RED)
    end
end

local function leaving()
    if module.db.leaving then
        alert(L.COMBATALERT_LEAVE_TEXT, Colors.GUILD_GREEN)
    end
end

-- Edit Mode -------------------------------------------------------------------------------------

-- In Edit Mode the text stays up, so it can be placed.
local function sample(active)
    frame.group:Stop()
    if active then
        frame.text:SetText(L.COMBATALERT_ENTER_TEXT)
        frame.text:SetTextColor(Colors.RED[1], Colors.RED[2], Colors.RED[3])
        frame:SetAlpha(1)
        frame:Show()
    else
        frame:Hide()
    end
end

local function moved(x, y)
    module.db.x, module.db.y = x, y
end

local function resetPosition()
    module.db.x, module.db.y = DEFAULT_X, DEFAULT_Y
    if frame then
        place()
    end
end

-- What Edit Mode's dialog for the alert offers.
local editModeOptions = {
    onChange = sample,
    reset = resetPosition,
    scale = {
        min = 50, max = 200, step = 10, format = "%d%%",
        get = function() return module.db.scale end,
        set = function(value)
            module.db.scale = value
            place()
        end,
    },
}

module.actions = {
    {
        name = L.COMBATALERT_RESET_POSITION,
        button = L.COMBATALERT_RESET_POSITION_BUTTON,
        description = L.COMBATALERT_RESET_POSITION_DESC,
        fn = resetPosition,
    },
}

function module:OnEnable()
    frame = frame or newFrame()
    place()
    self:On("PLAYER_REGEN_DISABLED", entering)
    self:On("PLAYER_REGEN_ENABLED", leaving)
    ns.EditMode.Register(frame, L.COMBATALERT_TITLE, moved, editModeOptions)
end

function module:OnDisable()
    if frame then
        ns.EditMode.Unregister(frame)
        frame.group:Stop()
        frame:Hide()
    end
end

function module:OnOptionChanged(option)
    if frame and (option == "scale") then
        place()
    end
end
