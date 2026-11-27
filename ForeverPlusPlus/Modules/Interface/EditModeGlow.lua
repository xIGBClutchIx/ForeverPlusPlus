-- Edit Mode Glow: dims the blue (gold once picked) boxes Edit Mode draws over every frame it moves,
-- so the frames' own edges show through and can be lined up. Our own frames' boxes (Lib/EditMode)
-- dim with them. A row under Blizzard's Edit Mode window, laid out like its Show Grid row, has a
-- Show Glow checkbox that hides the boxes until Edit Mode closes, and the same slider as Settings.
--
-- Each of Blizzard's boxes is a system frame's `Selection` (EditModeSystemSelectionBaseTemplate):
-- nine textures NineSliceUtil lays out on it the first time it shows, the same pieces again in the
-- gold kit when it's picked, and the same nine on its `MouseOverHighlight`, the brighter box under
-- the mouse. Only those textures' alpha is set: none of Edit Mode's code reads it, no field is
-- written on Blizzard's frames, and the Selection frames keep the mouse, so a box at 0% still picks
-- and drags its frame. Their labels ("Click To Edit", the frame's name) stay as they are.
-- A box's pieces are made when it first shows, so each box is dimmed again as it shows.
--
-- The grid and the snap lines are left alone: Edit Mode's own Show Grid turns the grid off.
local _, ns = ...

local ipairs, type, pcall = ipairs, type, pcall
local format = string.format
local CreateFrame, UIParent = CreateFrame, UIParent

local L = ns.L

local module = ns.NewModule("EditModeGlow", L.EDITMODEGLOW_DESC, {
    enabled = false,
    opacity = 40,
    panel = true,
})
module.title = L.EDITMODEGLOW_TITLE
module.presets = { developer = { enabled = true, options = { opacity = 100 } } }
module.category = "interface"
module.added = "1.10.0"

module.options = {
    { key = "opacity", name = L.EDITMODEGLOW_OPACITY, description = L.EDITMODEGLOW_OPACITY_DESC,
        min = 0, max = 100, step = 5, format = "%d%%" },
    { key = "panel", name = L.EDITMODEGLOW_PANEL, description = L.EDITMODEGLOW_PANEL_DESC },
}

function module:IsAvailable()
    return EditModeManagerFrame ~= nil and type(EditModeManagerFrame.registeredSystemFrames) == "table"
end

local hidden = false -- Show Glow unchecked under the Edit Mode window, until Edit Mode closes
local panel

local function strength()
    if not module.enabled then
        return 1
    end
    if hidden then
        return 0
    end
    return module.db.opacity / 100
end

local function dim(selection)
    local alpha = strength()
    ns.EditMode.DimBox(selection, alpha)
    ns.EditMode.DimBox(selection.MouseOverHighlight, alpha)
end

-- Blizzard's boxes, each hooked once so it's dimmed again as it shows: a frame that turns up in
-- Edit Mode later (one an Account Setting shows) makes its pieces only then.
local function apply()
    for _, system in ipairs(EditModeManagerFrame.registeredSystemFrames) do
        local selection = type(system) == "table" and system.Selection
        if type(selection) == "table" then
            module:HookScript(selection, "OnShow", dim)
            dim(selection)
        end
    end
    ns.EditMode.SetGlow(strength())
end

-- The row under the Edit Mode window ---------------------------------------------------------

local function syncPanel()
    if not panel then
        return
    end
    panel.check:SetChecked(not hidden)
    if panel.slider then
        panel.refreshing = true
        local formatter = CreateMinimalSliderFormatter and MinimalSliderWithSteppersMixin.Label
            and CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right,
                function(value) return format("%d%%", value) end)
        panel.slider:Init(module.db.opacity, 0, 100, 20,
            formatter and { [MinimalSliderWithSteppersMixin.Label.Right] = formatter } or nil)
        panel.refreshing = false
    end
end

-- Laid out as Blizzard's Show Grid row: a checkbox, its label, and a slider with steppers.
local function newPanel()
    local frame = ns.Frames.TemplateBox(UIParent, "DialogBorderTranslucentTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetHeight(56)
    frame:EnableMouse(true)
    -- Under the window, as wide as it, following it when it's dragged.
    frame:SetPoint("TOPLEFT", EditModeManagerFrame, "BOTTOMLEFT", 0, 2)
    frame:SetPoint("TOPRIGHT", EditModeManagerFrame, "BOTTOMRIGHT", 0, 2)

    local check = CreateFrame("CheckButton", nil, frame)
    check:SetSize(32, 32)
    check:SetPoint("LEFT", 20, 0)
    check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetScript("OnClick", function(self)
        hidden = not self:GetChecked()
        apply()
    end)
    frame.check = check

    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    label:SetSize(96, 32)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    label:SetText(L.EDITMODEGLOW_SHOW)

    local ok, slider = pcall(CreateFrame, "Frame", nil, frame, "MinimalSliderWithSteppersTemplate")
    if ok and slider and slider.Init and slider.RegisterCallback and MinimalSliderWithSteppersMixin then
        slider:SetSize(300, 32)
        slider:SetPoint("LEFT", label, "RIGHT", 2, 0)
        slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            if not frame.refreshing and value ~= module.db.opacity then
                frame.adjusting = true
                ns.SetOption(module.name, "opacity", value)
                frame.adjusting = false
            end
        end, frame)
        frame.slider = slider
    end
    frame:Hide()
    return frame
end

local function showPanel()
    local want = module.enabled and module.db.panel and ns.EditMode.IsActive()
    if want then
        panel = panel or newPanel()
        syncPanel()
        panel:Show()
    elseif panel then
        panel:Hide()
    end
end

-- Turning on and off -------------------------------------------------------------------------

local function onEnter()
    hidden = false
    apply()
    showPanel()
end

local function onExit()
    hidden = false
    showPanel()
end

function module:OnEnable()
    self:Hook(EditModeManagerFrame, "EnterEditMode", onEnter)
    self:Hook(EditModeManagerFrame, "ExitEditMode", onExit)
    hidden = false
    apply()
    showPanel()
end

function module:OnDisable()
    hidden = false
    apply() -- the module is off, so every box goes back to Blizzard's look
    showPanel()
end

function module:OnOptionChanged(key)
    if key == "opacity" then
        hidden = false
        apply()
        if panel and not panel.adjusting then
            syncPanel()
        elseif panel then
            panel.check:SetChecked(true)
        end
    else
        showPanel()
    end
end
