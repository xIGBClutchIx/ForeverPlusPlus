-- Hide Minimap Buttons: the buttons other addons put around the minimap (LibDBIcon's, Forever++'s,
-- and the rest) can't be seen until the mouse is over the minimap or one of them, and fade in and
-- out. With an option, Blizzard's own buttons by the minimap fade too: the calendar, tracking, the
-- addon compartment, and the expansion button. The mail and crafting order icons never do, since
-- they say something arrived.
--
-- An addon's button is a Button the addon gave the minimap, or the frame behind it
-- (MinimapBackdrop), whose middle sits on the minimap's edge or past it: where LibDBIcon and the
-- other button libraries put theirs. Icons on the map itself are left alone: the ones placed by
-- HereBeDragons, the library most map pin addons use, by its own list, and the rest since they sit
-- inside the edge (HereBeDragons keeps even a pin held on the edge at nine tenths of the way out).
-- The buttons are looked for again every second, so one an addon makes later joins the others.
--
-- Each button is faded with an alpha of its own, never hidden or moved, so it still takes clicks,
-- and the mouse over it brings them all back. The child buttons take the mouse from the minimap, so
-- where the mouse is gets checked a few times a second while the module is on. A LibDBIcon button
-- whose own addon fades it already (LibDBIcon's showOnMouseover) is left to it.
local _, ns = ...

local _G, ipairs, pairs, type, sqrt, max, abs = _G, ipairs, pairs, type, math.sqrt, math.max, math.abs
local setmetatable, CreateFrame = setmetatable, CreateFrame

local L = ns.L

local module = ns.NewModule("HideMinimapButtons", L.HIDEMINIMAPBUTTONS_DESC, {
    enabled = false,
    blizzard = false, -- Blizzard's calendar, tracking, addon compartment, and expansion buttons too
})
module.title = L.HIDEMINIMAPBUTTONS_TITLE
module.category = "map"
module.added = "1.10.0"

module.options = {
    {
        key = "blizzard",
        name = L.HIDEMINIMAPBUTTONS_BLIZZARD,
        description = L.HIDEMINIMAPBUTTONS_BLIZZARD_DESC,
    },
}

-- Seconds to fade in and out, and to wait after the mouse leaves: LibDBIcon's own fade (a fifth of
-- a second, after one).
local FADE_IN, FADE_OUT, HOLD = 0.15, 0.2, 1
local POLL = 0.1 -- seconds between looks at where the mouse is
local RESCAN = 1 -- seconds between looks for new buttons
-- How far inside the minimap's edge a button's middle may be and still count as on the edge.
local EDGE = 2

-- Blizzard's own frames in the minimap (Blizzard_Minimap's Minimap.xml, wow-ui-source's forever
-- branch): never taken for an addon's button.
local function blizzardChildren()
    local minimap = _G.Minimap
    return {
        [minimap.ZoomHitArea or false] = true,
        [minimap.ZoomIn or false] = true,
        [minimap.ZoomOut or false] = true,
        [_G.MinimapBackdrop or false] = true,
        [_G.ExpansionLandingPageMinimapButton or false] = true,
    }
end

-- Blizzard's buttons the option fades: the calendar (GameTimeFrame), tracking, the addon
-- compartment, and the expansion button. Blizzard never sets their alpha itself.
local function blizzardButtons()
    local cluster = _G.MinimapCluster
    return {
        _G.GameTimeFrame,
        cluster and cluster.Tracking,
        _G.AddonCompartmentFrame,
        _G.ExpansionLandingPageMinimapButton,
    }
end

local watcher -- our Frames.Watcher, shown while the module is on
local fader -- our frame whose OnUpdate runs a fade; hidden between fades
local tracked = setmetatable({}, { __mode = "k" }) -- button -> its alpha before we faded it
local alpha, goal = 1, 1
local away = 0 -- seconds the mouse has been off the minimap and the buttons
local sinceScan = RESCAN

-- The pins HereBeDragons places on the minimap, by frame, or nil without it.
local function libraryPins()
    local LibStub = _G.LibStub
    -- A plain table to the checker, whose type for the library leaves out its minimapPins
    -- (HereBeDragons-Pins-2.0.lua declares it: pins.minimapPins = pins.minimapPins or {}).
    ---@type table|false|nil
    local pins = type(LibStub) == "table" and LibStub("HereBeDragons-Pins-2.0", true)
    return pins and type(pins.minimapPins) == "table" and pins.minimapPins or nil
end

-- Whether a frame's middle is on the minimap's edge or past it.
local function onEdge(frame)
    local minimap = _G.Minimap
    local fx, fy = frame:GetCenter()
    local mx, my = minimap:GetCenter()
    if not (fx and mx) then
        return false
    end
    local ratio = frame:GetEffectiveScale() / minimap:GetEffectiveScale()
    local dx, dy = fx * ratio - mx, fy * ratio - my
    local half = minimap:GetWidth() / 2
    if ns.MinimapPins.Square() then
        return max(abs(dx), abs(dy)) >= half - EDGE
    end
    return sqrt(dx * dx + dy * dy) >= half - EDGE
end

local function isAddonButton(frame, skip, pins)
    return not skip[frame] and not (pins and pins[frame])
        and frame:IsObjectType("Button") and frame:IsShown()
        and not frame.showOnMouseover -- LibDBIcon's own fade, read only
        and onEdge(frame)
end

local function track(button)
    if tracked[button] == nil then
        tracked[button] = button:GetAlpha()
        button:SetAlpha(alpha)
    end
end

local function release(button)
    local was = tracked[button]
    if was ~= nil then
        tracked[button] = nil
        button:SetAlpha(was)
    end
end

-- Looks for the buttons now. One that's gone from the edge (hidden, dragged onto the map) or out
-- of the choice gets its alpha back.
local function scan()
    local found = {}
    local skip, pins = blizzardChildren(), libraryPins()
    for _, parent in ipairs({ _G.Minimap, _G.MinimapBackdrop }) do
        for _, child in ipairs({ parent:GetChildren() }) do
            if isAddonButton(child, skip, pins) then
                found[child] = true
            end
        end
    end
    if module.db.blizzard then
        for _, button in pairs(blizzardButtons()) do
            if button then
                found[button] = true
            end
        end
    end
    for button in pairs(tracked) do
        if not found[button] then
            release(button)
        end
    end
    for button in pairs(found) do
        track(button)
    end
end

local function set(value)
    alpha = value
    for button in pairs(tracked) do
        button:SetAlpha(value)
    end
end

local function onFade(self, elapsed)
    local step = elapsed / (goal > alpha and FADE_IN or FADE_OUT)
    if goal > alpha then
        set(alpha + step < goal and alpha + step or goal)
    else
        set(alpha - step > goal and alpha - step or goal)
    end
    if alpha == goal then
        self:Hide()
    end
end

local function fadeTo(value)
    if goal ~= value then
        goal = value
        fader:SetShown(alpha ~= goal)
    end
end

local function mouseOver()
    local cluster = _G.MinimapCluster
    if (cluster and cluster:IsMouseOver()) or _G.Minimap:IsMouseOver() then
        return true
    end
    for button in pairs(tracked) do
        if button:IsVisible() and button:IsMouseOver() then
            return true
        end
    end
    return false
end

local function poll()
    sinceScan = sinceScan + POLL
    if sinceScan >= RESCAN then
        sinceScan = 0
        scan()
    end
    if mouseOver() then
        away = 0
        fadeTo(1)
    else
        away = away + POLL
        if away >= HOLD then
            fadeTo(0)
        end
    end
end

function module:IsAvailable()
    return _G.Minimap ~= nil
end

function module:OnEnable()
    if not watcher then
        watcher = ns.Frames.Watcher(self, POLL, poll)
        fader = CreateFrame("Frame")
        fader:Hide()
        fader:SetScript("OnUpdate", ns.Profiler.Wrap(self, onFade))
    end
    alpha, goal, away, sinceScan = 0, 0, HOLD, 0
    scan()
    poll()
    watcher:Show()
end

function module:OnDisable()
    watcher:Hide()
    fader:Hide()
    local list = {}
    for button in pairs(tracked) do
        list[#list + 1] = button
    end
    for _, button in ipairs(list) do
        release(button)
    end
    alpha, goal = 1, 1
end

function module:OnOptionChanged(key)
    if key == "blizzard" and self.enabled then
        scan()
    end
end
