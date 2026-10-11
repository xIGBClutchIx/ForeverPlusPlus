-- Quest Tracker: restyles Blizzard's own objective tracker instead of replacing it, so it keeps
-- its Edit Mode place, height and opacity, its menus, quest items and clicks. It changes the
-- tracker's font objects (face, size, outline), draws a tooltip-style box that fits what the
-- tracker shows, can fade the tracker in combat, and can sort tracked quests by level.
-- It never calls the tracker's update or layout itself: that would run Blizzard's layout as
-- addon code and could taint the quest item buttons. A font change the tracker has already laid
-- out settles at its next update (any quest progress, or collapsing and expanding it).
local _, ns = ...

local pairs, ipairs, type, floor, min, max = pairs, ipairs, type, math.floor, math.min, math.max
local setmetatable, GetLocale, CreateFrame, sort = setmetatable, GetLocale, CreateFrame, table.sort
local InCombatLockdown, C_Timer, C_QuestLog = InCombatLockdown, C_Timer, C_QuestLog

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
    sort = "off", -- or "low" / "high": which level comes first
})
module.title = L.QUESTTRACKER_TITLE
module.category = "interface"

-- Which quests and in what order, then the text, the box behind it, and combat.
local QUESTS, TEXT, BOX, COMBAT = L.QUESTTRACKER_SECTION_QUESTS, L.QUESTTRACKER_SECTION_TEXT,
    L.QUESTTRACKER_SECTION_BOX, L.QUESTTRACKER_SECTION_COMBAT
module.options = {
    {
        key = "sort",
        name = L.QUESTTRACKER_SORT,
        description = L.QUESTTRACKER_SORT_DESC,
        section = QUESTS,
        added = "0.8.2",
        choices = {
            { "off", L.QUESTTRACKER_SORT_OFF },
            { "low", L.QUESTTRACKER_SORT_LOW },
            { "high", L.QUESTTRACKER_SORT_HIGH },
        },
    },
    {
        key = "font",
        name = L.QUESTTRACKER_FONT,
        description = L.QUESTTRACKER_FONT_DESC,
        section = TEXT,
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
        section = TEXT,
        min = 80, max = 150, step = 5, format = "%d%%",
    },
    {
        key = "outline",
        name = L.QUESTTRACKER_OUTLINE,
        description = L.QUESTTRACKER_OUTLINE_DESC,
        section = TEXT,
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
        section = BOX,
        slider = "opacity",
    },
    {
        key = "opacity",
        name = L.QUESTTRACKER_OPACITY,
        description = L.QUESTTRACKER_OPACITY_DESC,
        section = BOX,
        requires = "background",
        min = 10, max = 100, step = 10, format = "%d%%",
    },
    {
        key = "border",
        name = L.QUESTTRACKER_BORDER,
        description = L.QUESTTRACKER_BORDER_DESC,
        section = BOX,
        requires = "background",
    },
    {
        key = "padding",
        name = L.QUESTTRACKER_PADDING,
        description = L.QUESTTRACKER_PADDING_DESC,
        section = BOX,
        requires = "background",
        min = 0, max = 24, step = 2, format = "%d",
    },
    {
        key = "fade",
        name = L.QUESTTRACKER_FADE,
        description = L.QUESTTRACKER_FADE_DESC,
        section = COMBAT,
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

local fitBox
local pending, settling = false, false
local SETTLE = 0.2 -- seconds; when to fit once more after a change
-- How far the header art and the quests' map buttons reach past the tracker's left edge (about
-- 5 pixels in game), so the padding on the left measures from them whether sections are open or
-- not. Measured from what's drawn, the buttons' glow made it jump.
local OVERHANG = 6

-- Fits the box on the next frame, once, however many of the tracker's frames changed. Opening a
-- section shows its quests a moment before Blizzard has moved them all into place, which fires
-- nothing we can hear, so it fits once more a little later too.
local function requestFit()
    if not module.enabled then
        return
    end
    if not pending then
        pending = true
        C_Timer.After(0, function()
            pending = false
            fitBox()
        end)
    end
    if not settling then
        settling = true
        C_Timer.After(SETTLE, function()
            settling = false
            fitBox()
        end)
    end
end

-- Collapsing a section, or a quest coming or going, shows, hides or resizes one of the tracker's
-- frames without always going through an update we can hook, so every frame measured refits the
-- box when that happens to it.
local function watch(frame)
    module:HookScript(frame, "OnShow", requestFit)
    module:HookScript(frame, "OnHide", requestFit)
    module:HookScript(frame, "OnSizeChanged", requestFit)
end

-- Lowers `bounds.bottom` to the lowest thing a frame and its children draw: header art and text,
-- quest lines, map and item buttons. Only what's drawn counts, not frame sizes, since a
-- collapsed section can keep its full height.
local function measure(frame, bounds, depth)
    watch(frame)
    if not frame:IsVisible() or frame:GetEffectiveAlpha() <= 0 then
        return
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        if isDrawn(region) then
            local _, bottom, width, height = region:GetRect()
            if bottom and width > 1 and height > 1 then
                bounds.bottom = min(bounds.bottom or bottom, bottom)
            end
        end
    end
    if depth > 0 then
        for _, child in ipairs({ frame:GetChildren() }) do
            measure(child, bounds, depth - 1)
        end
    end
end

-- Fits the box to the tracker's width (Edit Mode's) and down to the last thing it draws, so a
-- collapsed tracker or section takes a short box. Blizzard's own background (Edit Mode's
-- Opacity) fills the whole height instead.
function fitBox()
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
    local _, frameBottom, _, frameHeight = frame:GetRect()
    if not (bounds.bottom and frameBottom) then
        box:Hide()
        return
    end
    local frameTop = frameBottom + frameHeight
    local pad = module.db.padding -- how far the box reaches past what the tracker shows
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", -OVERHANG - pad, pad)
    box:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", pad, bounds.bottom - frameTop - pad)
    setColors()
    box:Show()
end

-- After the tracker lays itself out: style fonts it has started using, and fit the box.
local function onUpdate()
    findFonts(tracker(), 4)
    fitBox()
    requestFit()
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

-- Sorting -----------------------------------------------------------------------------------------
-- The tracker lists quests in watch list order (after callings and quests that set their own
-- place) and has no sort of its own, and the comparison is a local in its code. So Sort by Level
-- reorders the watch list: it untracks the quests out of place and tracks them again in level
-- order. These are plain C_QuestLog calls, not the tracker's code; the tracker only marks itself
-- dirty on QUEST_WATCH_LIST_CHANGED and redraws on its own next frame, and since the blocks still
-- exist then, it plays no "quest added" fanfare. Out of combat only, to keep well away from the
-- quest item buttons.
-- Tracking a quest again put it at the top of the list on Forever, not the end as assumed (Lowest
-- First came out highest first), so the first sort checks which end it goes to and learns.

local SORT_DELAY = 0.2 -- seconds; one sort after a burst of quest log events
local sortPending, sortAfterCombat = false, false
local sortGaveUp = false -- the client kept neither order, so stop trying until turned on again
local addsToTop = true -- AddQuestWatch puts the quest first rather than last
local addEndKnown = false -- a sort has shown which end it goes to

---The quest's level, or nil while the quest log doesn't know it yet.
---@param questID number
---@return number?
local function questLevel(questID)
    local index = C_QuestLog.GetLogIndexForQuestID(questID)
    local info = index and C_QuestLog.GetInfo(index)
    local level = info and info.level
    if type(level) == "number" and level > 0 then
        return level
    end
end

-- Whether the watch list holds exactly `ids`, in that order.
local function watchesMatch(ids)
    if C_QuestLog.GetNumQuestWatches() ~= #ids then
        return false
    end
    for i = 1, #ids do
        if C_QuestLog.GetQuestIDForQuestWatchIndex(i) ~= ids[i] then
            return false
        end
    end
    return true
end

local requestSort

local function sortWatches()
    local order = module.db.sort
    if not module.enabled or order == "off" or sortGaveUp then
        return
    end
    if InCombatLockdown() then
        sortAfterCombat = true
        return
    end
    local watched = {}
    for i = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        local level = questID and questLevel(questID)
        if not level then
            return -- the quest log isn't ready; its next update sorts again
        end
        watched[i] = { id = questID, level = level, index = i }
    end
    local sorted = {}
    for i, quest in ipairs(watched) do
        sorted[i] = quest
    end
    -- Same level keeps the order they were tracked in.
    local highFirst = order == "high"
    sort(sorted, function(a, b)
        if a.level ~= b.level then
            if highFirst then
                return a.level > b.level
            end
            return a.level < b.level
        end
        return a.index < b.index
    end)
    -- The quests already in place at the end they're added at stay; the rest are tracked again.
    -- Adding to the top, they go in from the last out of place to the first.
    local from, to, step
    if addsToTop then
        for i = #sorted, 1, -1 do
            if sorted[i] ~= watched[i] then
                from, to, step = i, 1, -1
                break
            end
        end
    else
        for i = 1, #sorted do
            if sorted[i] ~= watched[i] then
                from, to, step = i, #sorted, 1
                break
            end
        end
    end
    if not from then
        return
    end
    local ids = {}
    for i, quest in ipairs(sorted) do
        ids[i] = quest.id
    end
    -- Untracking a quest can drop it as the quest the map and arrow follow, so put that back.
    local super = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
        and C_SuperTrack.GetSuperTrackedQuestID()
    for i = from, to, step do
        C_QuestLog.RemoveQuestWatch(ids[i])
    end
    for i = from, to, step do
        C_QuestLog.AddQuestWatch(ids[i])
    end
    if super and super ~= 0 and C_SuperTrack.SetSuperTrackedQuestID
        and C_SuperTrack.GetSuperTrackedQuestID() ~= super then
        C_SuperTrack.SetSuperTrackedQuestID(super)
    end
    -- Check the order once the client has it. Wrong the first time means quests go to the other
    -- end, so sort again that way; wrong after that, and this client keeps its own order.
    C_Timer.After(0, function()
        if watchesMatch(ids) then
            addEndKnown = true
        elseif not addEndKnown then
            addEndKnown = true
            addsToTop = not addsToTop
            requestSort()
        else
            sortGaveUp = true
        end
    end)
end

function requestSort()
    if sortPending then
        return
    end
    sortPending = true
    C_Timer.After(SORT_DELAY, function()
        sortPending = false
        sortWatches()
    end)
end

local function onCombatEnd()
    if sortAfterCombat then
        sortAfterCombat = false
        requestSort()
    end
end

-- Listens for new quests and tracking only while Sort by Level is on.
local function setSorting(on)
    if on then
        sortGaveUp = false
        module:On("QUEST_WATCH_LIST_CHANGED", requestSort)
        module:On("QUEST_LOG_UPDATE", requestSort)
        module:On("PLAYER_REGEN_ENABLED", onCombatEnd)
        requestSort()
    else
        module:Off("QUEST_WATCH_LIST_CHANGED", requestSort)
        module:Off("QUEST_LOG_UPDATE", requestSort)
        module:Off("PLAYER_REGEN_ENABLED", onCombatEnd)
        sortAfterCombat = false
    end
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
    self:HookScript(frame, "OnSizeChanged", requestFit)
    self:HookScript(frame, "OnShow", requestFit)
    self:On("PLAYER_REGEN_DISABLED", function() setFaded(true) end)
    self:On("PLAYER_REGEN_ENABLED", function() setFaded(false) end)
    setFaded(InCombatLockdown())
    setSorting(self.db.sort ~= "off")
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
    elseif key == "sort" then
        setSorting(self.db.sort ~= "off")
    else
        fitBox()
    end
end
