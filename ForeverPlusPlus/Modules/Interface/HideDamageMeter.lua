-- Hide Damage Meter: Blizzard's damage meter out of sight until the mouse is over it, fading in and
-- out, and with an option shown all through a fight. Asked for on GitHub (#53), after Hide Bag and
-- Menu Bars. Blizzard's own Visibility setting in Edit Mode (Always, In Combat, In Group, Hidden)
-- shows or hides the whole meter but has no mouseover, so this works on top of it.
--
-- The meter (Blizzard_DamageMeter, wow-ui-source's `forever` branch) is one frame, DamageMeter, an
-- Edit Mode system parented to UIParent. Its session windows (up to three) and each one's source
-- window are its children, also the ones the player drags elsewhere, so one alpha on DamageMeter
-- fades them all. Blizzard sets the session windows' alpha (Edit Mode's Transparency) and shows or
-- hides DamageMeter itself (UpdateShownState), but never sets DamageMeter's alpha, so that one is
-- ours: it multiplies with Blizzard's Transparency, and the alpha it had before goes back when the
-- module turns off. Nothing in it is secure, so the alpha can be set in combat too.
--
-- A faded window still takes the mouse: it's only faded, never hidden or moved. Where the mouse is
-- gets checked a few times a second while the meter shows (IsMouseOver, which goes by the window's
-- box, so a window set to click through counts too). The numbers in it, which can be secret, are
-- never read. It shows in Edit Mode, where it's moved, and with the controller interface on, where
-- no mouse can bring it back.
local _, ns = ...

local _G, ipairs, setmetatable = _G, ipairs, setmetatable
local CreateFrame, InCombatLockdown = CreateFrame, InCombatLockdown

local L = ns.L

local module = ns.NewModule("HideDamageMeter", L.HIDEDAMAGEMETER_DESC, {
    enabled = false,
    combat = true, -- shown all through a fight
})
module.title = L.HIDEDAMAGEMETER_TITLE
module.category = "interface"
module.added = "1.10.0"
module.notice = ns.Gamepad.LimitedNotice()

module.options = {
    { key = "combat", name = L.HIDEDAMAGEMETER_COMBAT, description = L.HIDEDAMAGEMETER_COMBAT_DESC },
}

local ADDON = "Blizzard_DamageMeter"
-- Seconds to fade in and out, and to wait after the mouse leaves or the fight ends, as Hide Minimap
-- Buttons does (LibDBIcon's own fade).
local FADE_IN, FADE_OUT, HOLD = 0.15, 0.2, 1
local POLL = 0.1 -- seconds between looks at where the mouse is

local watcher -- our Frames.Watcher, shown while the module is on and the meter shows
local fader -- our frame whose OnUpdate runs a fade; hidden between fades
local saved = setmetatable({}, { __mode = "k" }) -- the meter -> its alpha before we faded it
local alpha, goal = 1, 1
local away = 0 -- seconds the meter has had no reason to show

-- Blizzard's meter, once its addon has loaded.
local function meter()
    return _G.DamageMeter
end

function module:IsAvailable()
    -- Probe: C_DamageMeter and Blizzard_DamageMeter are Mainline's.
    return _G.C_DamageMeter ~= nil
end

local function set(value)
    alpha = value
    local frame = meter()
    if frame and saved[frame] ~= nil then
        frame:SetAlpha(value)
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

-- Whether the mouse is over a session window or the source window beside one. Edit Mode's box and
-- resize button are its other children, and hidden outside Edit Mode.
local function mouseOver(frame)
    for _, window in ipairs({ frame:GetChildren() }) do
        if window:IsVisible() and window:IsMouseOver() then
            return true
        end
        local source = window.SourceWindow -- Blizzard's parentKey, read only
        if source and source.IsVisible and source:IsVisible() and source:IsMouseOver() then
            return true
        end
    end
    return false
end

local function wanted(frame)
    return ns.EditMode.IsActive() or ns.Gamepad.On()
        or (module.db.combat and InCombatLockdown())
        or mouseOver(frame)
end

local function poll()
    local frame = meter()
    if not frame then
        return
    end
    if wanted(frame) then
        away = 0
        fadeTo(1)
    else
        away = away + POLL
        if away >= HOLD then
            fadeTo(0)
        end
    end
end

local function onShow()
    if module.enabled then
        poll()
        watcher:Show()
    end
end

local function onHide()
    watcher:Hide()
end

-- Takes the meter over once Blizzard_DamageMeter has loaded.
local function attach()
    local frame = meter()
    if not (module.enabled and frame and frame.SetAlpha) or saved[frame] ~= nil then
        return
    end
    saved[frame] = frame:GetAlpha()
    module:HookScript(frame, "OnShow", onShow)
    module:HookScript(frame, "OnHide", onHide)
    -- Straight to where it should be, without a fade first.
    local show = wanted(frame)
    alpha, goal, away = show and 1 or 0, show and 1 or 0, show and 0 or HOLD
    set(alpha)
    watcher:SetShown(frame:IsShown())
end

function module:OnEnable()
    if not watcher then
        watcher = ns.Frames.Watcher(self, POLL, poll)
        fader = CreateFrame("Frame")
        fader:Hide()
        fader:SetScript("OnUpdate", ns.Profiler.Wrap(self, onFade))
    end
    ns.AddOns.WhenLoaded(ADDON, attach)
end

function module:OnDisable()
    ns.AddOns.Cancel(ADDON, attach)
    watcher:Hide()
    fader:Hide()
    alpha, goal = 1, 1
    local frame = meter()
    if frame and saved[frame] ~= nil then
        frame:SetAlpha(saved[frame])
        saved[frame] = nil
    end
end
