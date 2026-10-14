-- Minimap Button: Forever++'s button on the minimap, in the addon compartment, or both. A click
-- opens Forever++ settings and a right-click a menu of quick module toggles; while Error Catcher
-- is on, a click with a key held shows its errors, clears this session's, or clears them all (each
-- key is an option), and the button shows how many this session caught (through ns.Errors, never
-- Error Catcher itself). After a fresh install the button wears
-- Blizzard's NEW label, and its first click opens the About page instead, once; no popup at login.
local _, ns = ...

local format, type, tremove, sort = string.format, type, table.remove, table.sort
local cos, sin, rad, deg, atan2, floor = math.cos, math.sin, math.rad, math.deg, math.atan2, math.floor
local ipairs, CreateFrame, GetCursorPosition = ipairs, CreateFrame, GetCursorPosition
local C_XMLUtil = C_XMLUtil
local RED = RED_FONT_COLOR and { RED_FONT_COLOR:GetRGB() } or { 1, 0.1, 0.1 }
local WHITE = { 1, 1, 1 }

local L = ns.L
local Errors = ns.Errors
local Keys = ns.Keys

local module = ns.NewModule("MinimapButton", L.MINIMAPBUTTON_DESC, {
    enabled = true,
    where = "minimap", -- minimap, compartment, or both
    -- Keys held with a click, while Error Catcher is on.
    errorsKey = "shift", -- shows the errors
    clearModifier = "ctrl", -- clears this session's errors
    clearAllKey = "alt", -- clears every saved error, after asking
    -- Data, not settings: a table, so presets leave it alone.
    saved = {
        angle = 200, -- the button's place around the minimap, in degrees
    },
})
module.title = L.MINIMAPBUTTON_TITLE
module.category = "system"
module.added = "0.8.0"

-- Before 0.8.0 the button was Error Catcher's, with its Minimap Button checkbox, Clear Key, and the
-- button's place. A player who had turned that button off keeps it off the minimap.
ns.Migrate(1, function(db)
    local saved = db.modules or {}
    local old = saved.ErrorCatcher
    if not (old and (old.minimap ~= nil or old.clearModifier ~= nil)) then
        return
    end
    local db = saved.MinimapButton or {}
    saved.MinimapButton = db
    ns.MoveSettings(old, db, { "clearModifier" })
    if old.minimap == false then
        db.where = "compartment"
    end
    if type(old.saved) == "table" and old.saved.angle then
        db.saved = db.saved or {}
        db.saved.angle = old.saved.angle
        old.saved.angle = nil
    end
    old.minimap, old.clearModifier = nil, nil
end)

local button
local compartment -- our entry in the addon compartment, while it's there

-- What a click does with a key held, while Error Catcher is on: the first whose key is held wins,
-- so showing the errors beats clearing them when two share a key. `count` hides the tooltip's
-- hint while there's nothing to clear.
local KEY_ACTIONS = {
    { setting = "errorsKey", hint = L.MINIMAPBUTTON_HINT_ERRORS,
        run = function() Errors.Toggle() end },
    { setting = "clearModifier", hint = L.MINIMAPBUTTON_HINT_CLEAR, count = Errors.SessionCount,
        run = function() Errors.ClearSession() end },
    { setting = "clearAllKey", hint = L.MINIMAPBUTTON_HINT_CLEAR_ALL, count = Errors.SavedCount,
        run = function() Errors.ClearAll() end },
}

-- A key's name for the tooltip, such as Ctrl, from the dropdown's choices.
local KEY_NAMES = {}
for _, choice in ipairs(Keys.CHOICES) do
    KEY_NAMES[choice[1]] = choice[2]
end

-- The modules the right-click menu turns on and off, listed by title in alphabetical order, so
-- the order holds in every language. One that isn't available on this client (Hide Beta Feedback
-- off the beta) is left out.
local QUICK_TOGGLES = {
    "AutoDecline", "AutoDismount", "AutoGossip", "AutoQuest", "AutoRelease", "AutoRepair",
    "AutoScreenshot", "AutoSellJunk", "AutoStow", "FastLoot", "FishingCast", "GatheringTracking",
    "HideBetaFeedback", "MinimapNodeIcons", "MovableFramerate", "SkipCinematics",
}

local function byTitle(a, b)
    return a.title < b.title
end

-- Turned on and off through Core, as the Modules page does, so Settings and /fpp follow along.
local function quickMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        return
    end
    local entries = {}
    for _, name in ipairs(QUICK_TOGGLES) do
        local other = ns.modules[name]
        if other and not other.unavailable then
            entries[#entries + 1] = { name = name, module = other, title = other.title or name }
        end
    end
    sort(entries, byTitle)
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(ns.title)
        for _, entry in ipairs(entries) do
            local name, other = entry.name, entry.module
            root:CreateCheckbox(entry.title,
                function() return other.db.enabled end,
                function()
                    ns.SetEnabled(name, not other.db.enabled)
                    ns.RefreshSetting(name)
                end)
        end
    end)
end

local function onClick(owner, mouse)
    if mouse == "RightButton" then
        quickMenu(owner)
        return
    end
    if Errors.IsOn() then
        -- Clearing needs a key held, so it's never an accident.
        for _, action in ipairs(KEY_ACTIONS) do
            if Keys.IsDown(module.db[action.setting]) then
                action.run()
                return
            end
        end
    end
    if not (ns.WelcomePending() and ns.OpenAbout()) then
        ns.OpenSettings()
    end
end

-- A count row: a white label, and the count at the right, red once there are any.
local function addCount(label, count)
    local color = count > 0 and RED or WHITE
    GameTooltip:AddDoubleLine(label, count, 1, 1, 1, color[1], color[2], color[3])
end

-- A hint row: what it does in green, as Blizzard's own hints, and the click for it in white.
local function addHint(action, click)
    GameTooltip:AddDoubleLine(action, click, 0.1, 1, 0.1, 1, 1, 1)
end

-- The tooltip: the error counts, then a hint for each click. `drag` adds the hint about dragging,
-- which only the minimap button does.
local function showTooltip(owner, drag)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.title)
    local errors = Errors.IsOn()
    if errors then
        addCount(L.MINIMAPBUTTON_TIP_SESSION, Errors.SessionCount())
        addCount(L.MINIMAPBUTTON_TIP_SAVED, Errors.SavedCount())
        GameTooltip:AddLine(" ")
    end
    addHint(ns.WelcomePending() and L.MINIMAPBUTTON_HINT_WELCOME or L.MINIMAPBUTTON_HINT_SETTINGS,
        L.MINIMAPBUTTON_CLICK)
    addHint(L.MINIMAPBUTTON_HINT_TOGGLES, L.MINIMAPBUTTON_RIGHT_CLICK)
    if errors then
        for _, action in ipairs(KEY_ACTIONS) do
            local key = module.db[action.setting]
            if key ~= "none" and KEY_NAMES[key] and (not action.count or action.count() > 0) then
                addHint(action.hint, format(L.MINIMAPBUTTON_KEY_CLICK, KEY_NAMES[key]))
            end
        end
    end
    if drag then
        addHint(L.MINIMAPBUTTON_HINT_MOVE, L.MINIMAPBUTTON_DRAG)
    end
    GameTooltip:Show()
end

-- This session's error count on the button and in the compartment's text, while Error Catcher
-- is on and has caught any.
local function refresh()
    local count = Errors.SessionCount()
    if compartment then
        -- Read when the compartment's menu opens, so it shows the count from then on.
        compartment.text = count > 0 and format(L.MINIMAPBUTTON_COMPARTMENT_COUNT, ns.title, count)
            or ns.title
    end
    if button then
        button.count:SetText(count > 0 and count or "")
        -- Blizzard's NEW label, as on new things in its own menus, until the About page is seen.
        local new = ns.WelcomePending()
        if new and not button.new and C_XMLUtil and C_XMLUtil.GetTemplateInfo
            and C_XMLUtil.GetTemplateInfo("NewFeatureLabelTemplate") then
            button.new = CreateFrame("Frame", nil, button, "NewFeatureLabelTemplate")
            button.new:SetPoint("CENTER", button, "TOP", 0, -2)
        end
        if button.new then
            button.new:SetShown(new)
        end
    end
end

-- The minimap button ----------------------------------------------------------------------------

local function place()
    local angle = rad(module.db.saved.angle)
    local radius = Minimap:GetWidth() / 2 + 10
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", cos(angle) * radius, sin(angle) * radius)
end

-- While dragging: the button follows the cursor around the minimap's edge.
local function follow()
    local x, y = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    module.db.saved.angle = floor(deg(atan2(cy / scale - y, cx / scale - x)) % 360)
    place()
end

local function onEnter(self)
    showTooltip(self, true)
end

-- The usual round minimap button: Blizzard's tracking border around a small icon, laid out as
-- LibDBIcon does on Mainline clients like Forever's (the Classic offsets sit up and to the left).
local function newMinimapButton()
    local b = CreateFrame("Button", nil, Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = b:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.icon)
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")
    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", 2, 1)

    b:SetScript("OnClick", onClick)
    b:SetScript("OnDragStart", function(self)
        GameTooltip_Hide()
        self:SetScript("OnUpdate", follow)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

-- The addon compartment ---------------------------------------------------------------------------
-- The menu under the minimap that lists addons. Forever has it (Manners, an addon for this
-- client, registers there the same way). Registered here rather than with the TOC's
-- AddonCompartmentFunc, so it can come and go with the option.

local function compartmentFrame()
    local frame = AddonCompartmentFrame
    if frame and frame.RegisterAddon then
        return frame
    end
end

local function addCompartment()
    local frame = compartmentFrame()
    if compartment or not frame then
        return
    end
    compartment = {
        text = ns.title,
        icon = ns.icon,
        notCheckable = true,
        registerForAnyClick = true,
        -- The mouse button comes inside the input data; the TOC's way passes it as a string.
        func = function(_, input)
            onClick(frame, type(input) == "table" and input.buttonName or input)
        end,
        funcOnEnter = function(owner)
            showTooltip(type(owner) == "table" and owner.IsObjectType and owner or frame, false)
        end,
        funcOnLeave = GameTooltip_Hide,
    }
    refresh()
    frame:RegisterAddon(compartment)
end

-- Blizzard has no way to unregister, so ours comes out of its list, as LibDBIcon does, and the
-- compartment redraws. The list holds only addons' entries, so this touches nothing secure.
local function removeCompartment()
    local frame = compartmentFrame()
    local entries = frame and frame.registeredAddons
    if compartment and entries then
        for i = #entries, 1, -1 do
            if entries[i] == compartment then
                tremove(entries, i)
            end
        end
        if frame.UpdateDisplay then
            frame:UpdateDisplay()
        end
    end
    compartment = nil
end

-- Shows the minimap button and the compartment entry the option asks for, and only those.
local function update()
    local where = module.enabled and module.db.where or "none"
    if (where == "minimap" or where == "both") and Minimap then
        button = button or newMinimapButton()
        place()
        button:Show()
    elseif button then
        button:SetScript("OnUpdate", nil)
        button:Hide()
    end
    if where == "compartment" or where == "both" then
        addCompartment()
    else
        removeCompartment()
    end
    refresh()
end

-- The module ----------------------------------------------------------------------------------

module.options = {
    {
        key = "where",
        name = L.MINIMAPBUTTON_WHERE,
        description = L.MINIMAPBUTTON_WHERE_DESC,
        choices = {
            { "minimap", L.MINIMAPBUTTON_WHERE_MINIMAP },
            { "compartment", L.MINIMAPBUTTON_WHERE_COMPARTMENT },
            { "both", L.MINIMAPBUTTON_WHERE_BOTH },
        },
    },
    Keys.Option("errorsKey", L.MINIMAPBUTTON_ERRORS_KEY, L.MINIMAPBUTTON_ERRORS_KEY_DESC),
    -- Changed: a click instead of a right-click, and Shift is a choice.
    Keys.Option("clearModifier", L.MINIMAPBUTTON_CLEAR_KEY, L.MINIMAPBUTTON_CLEAR_KEY_DESC, nil,
        "0.9.0"),
    Keys.Option("clearAllKey", L.MINIMAPBUTTON_CLEAR_ALL_KEY, L.MINIMAPBUTTON_CLEAR_ALL_KEY_DESC),
}
for _, option in ipairs(module.options) do
    if option.key == "errorsKey" or option.key == "clearAllKey" then
        option.added = "0.9.0"
    end
end

local function onChanged()
    if module.enabled then
        refresh()
    end
end
Errors.OnChanged(onChanged)
ns.OnWelcomed(onChanged)

function module:OnEnable()
    update()
end

function module:OnDisable()
    update()
end

function module:OnOptionChanged(key)
    if key == "where" then
        update()
    end
end
