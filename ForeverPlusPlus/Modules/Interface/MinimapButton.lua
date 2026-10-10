-- Minimap Button: Forever++'s button on the minimap, in the addon compartment, or both. A click
-- opens Forever++ settings and a right-click a menu of quick module toggles; while Error Catcher
-- is on, a Shift-right-click shows its errors and the button shows how many this session caught
-- (through ns.Errors, never Error Catcher itself). After a fresh install the button wears
-- Blizzard's NEW label, and its first click opens the About page instead, once; no popup at login.
local _, ns = ...

local format, type, tremove = string.format, type, table.remove
local cos, sin, rad, deg, atan2, floor = math.cos, math.sin, math.rad, math.deg, math.atan2, math.floor
local ipairs, CreateFrame, GetCursorPosition = ipairs, CreateFrame, GetCursorPosition
local C_XMLUtil = C_XMLUtil
local IsControlKeyDown, IsShiftKeyDown, IsAltKeyDown = IsControlKeyDown, IsShiftKeyDown, IsAltKeyDown

local L = ns.L
local Errors = ns.Errors

local module = ns.NewModule("MinimapButton", L.MINIMAPBUTTON_DESC, {
    enabled = true,
    where = "minimap", -- minimap, compartment, or both
    clearModifier = "ctrl", -- held with a right-click to clear this session's errors
    -- Data, not settings: a table, so presets leave it alone.
    saved = {
        angle = 200, -- the button's place around the minimap, in degrees
    },
})
module.title = L.MINIMAPBUTTON_TITLE
module.category = "interface"
module.added = "0.8.0"

local button
local compartment -- our entry in the addon compartment, while it's there

-- The keys that, held with a right-click, clear this session's errors. Not Shift: a
-- Shift-right-click shows them.
local MODIFIERS = {
    ctrl = { name = L.MINIMAPBUTTON_KEY_CTRL, down = IsControlKeyDown },
    alt = { name = L.MINIMAPBUTTON_KEY_ALT, down = IsAltKeyDown },
}

-- The modules the right-click menu turns on and off, in this order.
local QUICK_TOGGLES = { "FastLoot", "AutoQuest", "AutoSellJunk" }

-- Turned on and off through Core, as the Modules page does, so Settings and /fpp follow along.
local function quickMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(ns.title)
        for _, name in ipairs(QUICK_TOGGLES) do
            local other = ns.modules[name]
            if other and not other.unavailable then
                root:CreateCheckbox(other.title or name,
                    function() return other.db.enabled end,
                    function()
                        ns.SetEnabled(name, not other.db.enabled)
                        ns.RefreshSetting(name)
                    end)
            end
        end
    end)
end

local function onClick(owner, mouse)
    if mouse ~= "RightButton" then
        if not (ns.WelcomePending() and ns.OpenAbout()) then
            ns.OpenSettings()
        end
        return
    end
    if Errors.IsOn() then
        -- Clearing needs the key held, so it's never an accident.
        local modifier = MODIFIERS[module.db.clearModifier]
        if modifier and modifier.down() then
            Errors.ClearSession()
            return
        elseif IsShiftKeyDown() then
            Errors.Toggle()
            return
        end
    end
    quickMenu(owner)
end

-- The tooltip. `drag` adds the line about dragging, which only the minimap button does.
local function showTooltip(owner, drag)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.title)
    local errors = Errors.IsOn()
    if errors then
        GameTooltip:AddLine(format(L.MINIMAPBUTTON_TIP_SESSION, Errors.SessionCount()), 1, 1, 1)
        GameTooltip:AddLine(format(L.MINIMAPBUTTON_TIP_SAVED, Errors.SavedCount()), 1, 1, 1)
        GameTooltip:AddLine(" ")
    end
    GameTooltip:AddLine(ns.WelcomePending() and L.MINIMAPBUTTON_TIP_WELCOME
        or L.MINIMAPBUTTON_TIP_SETTINGS, 0.1, 1, 0.1)
    GameTooltip:AddLine(L.MINIMAPBUTTON_TIP_TOGGLES, 0.1, 1, 0.1)
    if errors then
        GameTooltip:AddLine(L.MINIMAPBUTTON_TIP_ERRORS, 0.1, 1, 0.1)
        local modifier = MODIFIERS[module.db.clearModifier]
        if modifier then
            GameTooltip:AddLine(format(L.MINIMAPBUTTON_TIP_CLEAR, modifier.name), 0.1, 1, 0.1)
        end
    end
    if drag then
        GameTooltip:AddLine(L.MINIMAPBUTTON_TIP_DRAG, 0.1, 1, 0.1)
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
    {
        key = "clearModifier",
        name = L.MINIMAPBUTTON_CLEAR_KEY,
        description = L.MINIMAPBUTTON_CLEAR_KEY_DESC,
        choices = {
            { "ctrl", L.MINIMAPBUTTON_KEY_CTRL },
            { "alt", L.MINIMAPBUTTON_KEY_ALT },
            { "none", L.MINIMAPBUTTON_KEY_NONE },
        },
    },
}

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
