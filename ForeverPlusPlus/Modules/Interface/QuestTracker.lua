-- Quest Tracker: restyles Blizzard's own objective tracker instead of replacing it, so it keeps
-- its Edit Mode place, height and opacity, its menus, quest items and clicks. It changes the
-- tracker's font objects (face, size, outline), draws a tooltip-style box that fits what the
-- tracker shows, and can fade the tracker in combat.
-- It never calls the tracker's update or layout itself: that would run Blizzard's layout as
-- addon code and could taint the quest item buttons. A font change the tracker has already laid
-- out settles at its next update (any quest progress, or collapsing and expanding it).
local _, ns = ...

local pairs, ipairs, type, floor, min, max = pairs, ipairs, type, math.floor, math.min, math.max
local setmetatable, GetLocale, CreateFrame = setmetatable, GetLocale, CreateFrame
local InCombatLockdown, C_Timer = InCombatLockdown, C_Timer

local L = ns.L

local module = ns.NewModule("QuestTracker", L.QUESTTRACKER_DESC, {
    enabled = true,
    font = "default",
    size = 100, -- percent of Blizzard's size
    outline = "default",
    background = true,
    opacity = 30, -- percent
    border = false,
    padding = 10,
    fade = false,
})
module.title = L.QUESTTRACKER_TITLE
module.category = "interface"

module.options = {
    {
        key = "font",
        name = L.QUESTTRACKER_FONT,
        description = L.QUESTTRACKER_FONT_DESC,
        choices = {
            { "default", L.QUESTTRACKER_DEFAULT },
            { "Fonts\\FRIZQT__.TTF", L.QUESTTRACKER_FRIZQT },
            { "Fonts\\ARIALN.TTF", L.QUESTTRACKER_ARIALN },
            { "Fonts\\skurri.ttf", L.QUESTTRACKER_SKURRI },
            { "Fonts\\MORPHEUS.TTF", L.QUESTTRACKER_MORPHEUS },
        },
    },
    {
        key = "size",
        name = L.QUESTTRACKER_SIZE,
        description = L.QUESTTRACKER_SIZE_DESC,
        min = 80, max = 150, step = 5, format = "%d%%",
    },
    {
        key = "outline",
        name = L.QUESTTRACKER_OUTLINE,
        description = L.QUESTTRACKER_OUTLINE_DESC,
        choices = {
            { "default", L.QUESTTRACKER_DEFAULT },
            { "", L.QUESTTRACKER_OUTLINE_NONE },
            { "OUTLINE", L.QUESTTRACKER_OUTLINE_THIN },
            { "THICKOUTLINE", L.QUESTTRACKER_OUTLINE_THICK },
        },
    },
    {
        key = "background",
        name = L.QUESTTRACKER_BACKGROUND,
        description = L.QUESTTRACKER_BACKGROUND_DESC,
        slider = "opacity",
    },
    {
        key = "opacity",
        name = L.QUESTTRACKER_OPACITY,
        description = L.QUESTTRACKER_OPACITY_DESC,
        requires = "background",
        min = 10, max = 100, step = 10, format = "%d%%",
    },
    {
        key = "border",
        name = L.QUESTTRACKER_BORDER,
        description = L.QUESTTRACKER_BORDER_DESC,
        requires = "background",
    },
    {
        key = "padding",
        name = L.QUESTTRACKER_PADDING,
        description = L.QUESTTRACKER_PADDING_DESC,
        requires = "background",
        min = 0, max = 24, step = 2, format = "%d",
    },
    {
        key = "fade",
        name = L.QUESTTRACKER_FADE,
        description = L.QUESTTRACKER_FADE_DESC,
    },
}

-- SetFont takes a single file, so the alphabets the game's fonts cover with fallbacks would draw
-- blank in another face; those clients keep Blizzard's face and only get size and outline.
local NON_ROMAN = { koKR = true, zhCN = true, zhTW = true, ruRU = true }

local FADED = 0.3 -- the tracker's alpha in combat with Fade in Combat

-- Font objects the tracker is known to use, set before its first layout when they exist. The
-- tracker's text is searched for more as it updates.
local KNOWN_FONTS = { "ObjectiveTrackerHeaderFont", "ObjectiveTrackerLineFont", "ObjectiveTrackerFont12",
    "ObjectiveTrackerFont14", "ObjectiveTrackerFont16", "ObjectiveTrackerFont18", "ObjectiveTrackerFont20" }

local original = setmetatable({}, { __mode = "k" }) -- font object -> { file, size, flags } before us
local box -- the background, made the first time it's needed
local faded = false -- we set the tracker's alpha for combat

local function tracker()
    return ObjectiveTrackerFrame
end

-- Fonts -------------------------------------------------------------------------------------------

---Sets one of the tracker's font objects to the chosen face, size and outline, from its own.
---@param font table
local function applyFont(font)
    local saved = original[font]
    if not saved then
        local file, size, flags = font:GetFont()
        if not file then
            return
        end
        saved = { file, size, flags }
        original[font] = saved
    end
    local db = module.db
    local file = saved[1]
    if db.font ~= "default" and not NON_ROMAN[GetLocale()] then
        file = db.font
    end
    local flags = saved[3]
    if db.outline ~= "default" then
        flags = db.outline
    end
    font:SetFont(file, floor(saved[2] * db.size / 100 + 0.5), flags)
end

---Whether a font object is one of the tracker's own, not a shared one like GameFontNormal.
---@param font table?
---@return boolean
local function isTrackerFont(font)
    if type(font) ~= "table" or not font.GetName then
        return false
    end
    local name = font:GetName()
    return type(name) == "string" and name:find("^ObjectiveTracker") ~= nil
end

-- Finds the tracker's font objects in its text, a few frames deep, and styles any new ones.
local function findFonts(frame, depth)
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetFontObject then
            local font = region:GetFontObject()
            if font and not original[font] and isTrackerFont(font) then
                applyFont(font)
            end
        end
    end
    if depth > 0 then
        for _, child in ipairs({ frame:GetChildren() }) do
            findFonts(child, depth - 1)
        end
    end
end

local function applyFonts()
    for _, name in ipairs(KNOWN_FONTS) do
        local font = _G[name]
        if isTrackerFont(font) then
            applyFont(font)
        end
    end
    for font in pairs(original) do
        applyFont(font)
    end
end

local function restoreFonts()
    for font, saved in pairs(original) do
        font:SetFont(saved[1], saved[2], saved[3])
        original[font] = nil
    end
end

-- Background --------------------------------------------------------------------------------------

local function newBox()
    local frame = tracker()
    local hasTemplate = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("TooltipBackdropTemplate")
    -- The same box Blizzard draws tooltips in, behind the tracker's own frames.
    local b = CreateFrame("Frame", nil, frame, hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    b:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
    if not hasTemplate and b.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        b:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
    end
    b:Hide()
    return b
end

local function setColors()
    local alpha = module.db.opacity / 100
    local borderAlpha = module.db.border and 1 or 0
    local r, g, b = 1, 1, 1
    if TOOLTIP_DEFAULT_COLOR then
        r, g, b = TOOLTIP_DEFAULT_COLOR:GetRGB()
    end
    local slice = box.NineSlice
    if slice and slice.SetCenterColor then
        slice:SetCenterColor(0, 0, 0, alpha)
        slice:SetBorderColor(r, g, b, borderAlpha)
    elseif box.SetBackdropColor then
        box:SetBackdropColor(0, 0, 0, alpha)
        box:SetBackdropBorderColor(r, g, b, borderAlpha)
    end
end

---Whether a texture or font string is drawn now: shown, not see-through, not a mouseover
---highlight, and for text, not empty.
---@param region table
---@return boolean
local function isDrawn(region)
    if not (region.IsVisible and region:IsVisible()) or region:GetAlpha() <= 0 then
        return false
    end
    if region.GetDrawLayer and region:GetDrawLayer() == "HIGHLIGHT" then
        return false
    end
    if region.GetText then
        local text = region:GetText()
        return text ~= nil and text ~= ""
    end
    return true
end

-- Widens `bounds` ({ left, right, top, bottom }) to what a frame draws, and its children's: the
-- headers' art and text, the quest lines, their map buttons on the left and item buttons on the
-- right. Only what's drawn counts, not frame sizes: a collapsed section keeps its full height,
-- and some of the tracker's frames are wider than what shows in them.
local function measure(frame, bounds, depth)
    if not frame:IsVisible() or frame:GetEffectiveAlpha() <= 0 then
        return
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        if isDrawn(region) then
            local left, bottom, width, height = region:GetRect()
            if left and width > 1 and height > 1 then
                bounds[1] = min(bounds[1] or left, left)
                bounds[2] = max(bounds[2] or left + width, left + width)
                bounds[3] = max(bounds[3] or bottom + height, bottom + height)
                bounds[4] = min(bounds[4] or bottom, bottom)
            end
        end
    end
    if depth > 0 then
        for _, child in ipairs({ frame:GetChildren() }) do
            measure(child, bounds, depth - 1)
        end
    end
end

-- Fits the box around what the tracker shows: its header, and the blocks under it unless it's
-- collapsed. Blizzard's own background (Edit Mode's Opacity) fills the whole height instead.
local function fitBox()
    local frame = tracker()
    if not (module.enabled and module.db.background) or not frame:IsVisible() then
        if box then
            box:Hide()
        end
        return
    end
    box = box or newBox()
    local bounds = {}
    for _, child in ipairs({ frame:GetChildren() }) do
        if child ~= box and child ~= frame.NineSlice and child ~= frame.Selection then
            measure(child, bounds, 5)
        end
    end
    local left, right, top, bottom = bounds[1], bounds[2], bounds[3], bounds[4]
    local frameLeft, frameBottom, _, frameHeight = frame:GetRect()
    if not (left and frameLeft) then
        box:Hide()
        return
    end
    local frameTop = frameBottom + frameHeight
    box:ClearAllPoints()
    local pad = module.db.padding -- how far the box reaches past what the tracker shows
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", left - frameLeft - pad, top - frameTop + pad)
    box:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", right - frameLeft + pad, bottom - frameTop - pad)
    setColors()
    box:Show()
end

-- After the tracker lays itself out: style fonts it has started using, and fit the box.
local function onUpdate()
    local frame = tracker()
    findFonts(frame, 4)
    fitBox()
    -- Collapsing a section can hide its lines after the update returns, so look again a frame on.
    C_Timer.After(0, fitBox)
end

-- Fading ------------------------------------------------------------------------------------------

local function setFaded(on)
    on = on and module.db.fade
    if on == faded then
        return
    end
    faded = on
    tracker():SetAlpha(on and FADED or 1)
end

-- Module ------------------------------------------------------------------------------------------

function module:IsAvailable()
    return ObjectiveTrackerFrame ~= nil
end

function module:OnEnable()
    local frame = tracker()
    applyFonts()
    if frame.Update then
        self:Hook(frame, "Update", onUpdate)
    else
        -- Mainline's tracker has Update; this covers a client where it doesn't.
        local function later()
            C_Timer.After(0, onUpdate)
        end
        self:On("QUEST_LOG_UPDATE", later)
        self:On("QUEST_WATCH_LIST_CHANGED", later)
    end
    -- The header's collapse and Edit Mode's height change what shows without always updating.
    self:HookScript(frame, "OnSizeChanged", fitBox)
    self:HookScript(frame, "OnShow", fitBox)
    self:On("PLAYER_REGEN_DISABLED", function() setFaded(true) end)
    self:On("PLAYER_REGEN_ENABLED", function() setFaded(false) end)
    setFaded(InCombatLockdown())
    onUpdate()
end

function module:OnDisable()
    restoreFonts()
    if box then
        box:Hide()
    end
    if faded then
        faded = false
        tracker():SetAlpha(1)
    end
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "font" or key == "size" or key == "outline" then
        applyFonts()
        fitBox()
    elseif key == "fade" then
        setFaded(InCombatLockdown())
    else
        fitBox()
    end
end
