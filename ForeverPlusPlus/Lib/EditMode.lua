-- Edit Mode for our own frames, made to look and work like Blizzard's own system frames: while
-- the player is in Blizzard's Edit Mode, a frame registered here gets the same blue selection box,
-- which turns gold when clicked, and can be dragged with snapping to the screen's middle and
-- edges and to the other frames, nudged a pixel at a time with the arrow keys, and opens a small
-- settings dialog (scale and reset position) like the one Blizzard's frames open. Blizzard's Edit
-- Mode has no way for an addon to add a frame to its layouts (that needs its protected system
-- code), so the position is the module's, not part of an Edit Mode layout. Nothing is hooked until
-- a module registers a frame.
local _, ns = ...

local pairs, type, pcall, abs, min, max = pairs, type, pcall, math.abs, math.min, math.max
local format = string.format
local CreateFrame, UIParent, hooksecurefunc = CreateFrame, UIParent, hooksecurefunc
local GetCursorPosition = GetCursorPosition
local NineSliceUtil, EditModeSystemSelectionLayout = NineSliceUtil, EditModeSystemSelectionLayout

local L = ns.L
local call = ns.Call

local EditMode = {}
ns.EditMode = EditMode

local SNAP = 10 -- how close, in pixels, before a frame snaps to a line
local GOLD = { 1, 0.82, 0 }

local registered = {} -- frame -> { label, onMove, onChange, scale, reset, selection }
local hooked = false
local selected -- the frame of ours that is selected, if any

---Whether Edit Mode is open. Probe: EditModeManagerFrame is Mainline's.
---@return boolean
function EditMode.IsActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown() or false
end

-- Positions ---------------------------------------------------------------------------------------

---Puts `frame` at an offset from the center of the screen, in screen units, whatever its own
---scale is. Modules use this for a frame that takes its scale itself.
---@param frame table
---@param x number
---@param y number
function EditMode.Place(frame, x, y)
    local scale = frame:GetScale()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x / scale, y / scale)
end

-- A frame's box in screen units: center, width, and height. Nil until the frame has a place.
local function box(frame)
    local cx, cy = frame:GetCenter()
    if not cx then
        return
    end
    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return cx * ratio, cy * ratio, frame:GetWidth() * ratio, frame:GetHeight() * ratio
end

-- Moves `frame` to a center in screen units and hands the offset to its module to save.
local function moveTo(frame, info, cx, cy)
    local ux, uy = UIParent:GetCenter()
    local x, y = cx - ux, cy - uy
    EditMode.Place(frame, x, y)
    info.onMove(x, y)
end

-- Snapping ------------------------------------------------------------------------------------------

local guides -- the two lines drawn where a frame snaps: { vertical, horizontal }

local function guide(index)
    guides = guides or {}
    if not guides[index] then
        local line = UIParent:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.8)
        line:SetDrawLayer("OVERLAY", 7)
        line:Hide()
        guides[index] = line
    end
    return guides[index]
end

local function hideGuides()
    if guides then
        for _, line in pairs(guides) do
            line:Hide()
        end
    end
end

-- The lines on one axis to snap to: the screen's edges and middle, and every other frame of ours
-- that is showing. `axis` is 1 for x, 2 for y.
local function lines(frame, axis)
    local size = axis == 1 and UIParent:GetWidth() or UIParent:GetHeight()
    local list = { 0, size / 2, size }
    for other in pairs(registered) do
        if other ~= frame and other:IsShown() then
            local cx, cy, w, h = box(other)
            if cx then
                local center, length = axis == 1 and cx or cy, axis == 1 and w or h
                list[#list + 1] = center - length / 2
                list[#list + 1] = center
                list[#list + 1] = center + length / 2
            end
        end
    end
    return list
end

-- Where a dragged frame's center goes on one axis: pulled onto the nearest line within reach, for
-- its near edge, middle, or far edge. Second value is the line it snapped to, if any.
local function snap(frame, center, length, axis)
    local best, bestLine
    for _, line in pairs(lines(frame, axis)) do
        for _, edge in pairs({ -length / 2, 0, length / 2 }) do
            local off = line - (center + edge)
            if abs(off) <= SNAP and (not best or abs(off) < abs(best)) then
                best, bestLine = off, line
            end
        end
    end
    if best then
        return center + best, bestLine
    end
    return center
end

-- Keeps a frame's box on the screen.
local function clamp(center, length, size)
    return max(length / 2, min(size - length / 2, center))
end

local function showGuides(vertical, horizontal)
    if vertical then
        local line = guide(1)
        line:ClearAllPoints()
        line:SetPoint("TOP", UIParent, "BOTTOMLEFT", vertical, UIParent:GetHeight())
        line:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", vertical, 0)
        line:SetWidth(2)
        line:Show()
    elseif guides and guides[1] then
        guides[1]:Hide()
    end
    if horizontal then
        local line = guide(2)
        line:ClearAllPoints()
        line:SetPoint("LEFT", UIParent, "BOTTOMLEFT", 0, horizontal)
        line:SetPoint("RIGHT", UIParent, "BOTTOMRIGHT", 0, horizontal)
        line:SetHeight(2)
        line:Show()
    elseif guides and guides[2] then
        guides[2]:Hide()
    end
end

-- The drag: follows the cursor, keeping the spot that was grabbed under it, snapping as it goes.
local function dragUpdate(selection)
    local frame = selection:GetParent()
    local info = registered[frame]
    if not info or not info.grab then
        return
    end
    local mx, my = GetCursorPosition()
    local ratio = UIParent:GetEffectiveScale()
    local _, _, width, height = box(frame)
    if not width then
        return
    end
    local cx, vertical = snap(frame, mx / ratio + info.grab[1], width, 1)
    local cy, horizontal = snap(frame, my / ratio + info.grab[2], height, 2)
    cx = clamp(cx, width, UIParent:GetWidth())
    cy = clamp(cy, height, UIParent:GetHeight())
    moveTo(frame, info, cx, cy)
    showGuides(vertical, horizontal)
end

local function dragStart(frame, info)
    local cx, cy = box(frame)
    if not cx then
        return
    end
    local mx, my = GetCursorPosition()
    local ratio = UIParent:GetEffectiveScale()
    info.grab = { cx - mx / ratio, cy - my / ratio }
    info.selection:SetScript("OnUpdate", dragUpdate)
end

local function dragStop(frame, info)
    info.grab = nil
    info.selection:SetScript("OnUpdate", nil)
    hideGuides()
    if EditMode.Refresh then
        EditMode.Refresh()
    end
end

-- The selection box --------------------------------------------------------------------------------

-- Blizzard's two looks for a frame in Edit Mode: blue while it can be picked, gold once picked. The
-- art comes from its atlas names; without them the layout's own look is used with a tint.
local KITS = { [false] = "editmode-actionbar-highlight", [true] = "editmode-actionbar-selected" }

local function look(selection, isSelected)
    if NineSliceUtil and EditModeSystemSelectionLayout then
        local kit = KITS[isSelected]
        local hasKit = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(kit .. "-NineSlice-Corner")
        if hasKit then
            NineSliceUtil.ApplyLayout(selection, EditModeSystemSelectionLayout, kit)
        else
            NineSliceUtil.ApplyLayout(selection, EditModeSystemSelectionLayout)
        end
        selection.tint:SetShown(isSelected and not hasKit)
    else
        selection.tint:SetColorTexture(0.2, 0.5, 1, 0.3)
        selection.tint:Show()
    end
end

local pick, deselect, refreshDialog

local function newSelection(frame, info)
    local selection = CreateFrame("Frame", nil, frame)
    selection:SetAllPoints(frame)
    selection:SetFrameLevel(frame:GetFrameLevel() + 10)
    selection:EnableMouse(true)
    selection:RegisterForDrag("LeftButton")
    selection.tint = selection:CreateTexture(nil, "BACKGROUND")
    selection.tint:SetAllPoints()
    selection.tint:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.2)
    selection.tint:Hide()
    look(selection, false)
    selection:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            pick(frame)
        end
    end)
    -- Right-click, as on Blizzard's frames: a menu with the scale and reset.
    selection:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and MenuUtil and MenuUtil.CreateContextMenu then
            pick(frame)
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle(info.label)
                local scale = info.scale
                if scale then
                    local sub = root:CreateButton(L.EDITMODE_SCALE)
                    for value = scale.min, scale.max, scale.step do
                        sub:CreateRadio(format(scale.format or "%d%%", value),
                            function() return scale.get() == value end,
                            function()
                                scale.set(value)
                                EditMode.Refresh()
                            end)
                    end
                end
                if info.reset then
                    root:CreateButton(L.EDITMODE_RESET_POSITION, function() call(info.reset) end)
                end
            end)
        end
    end)
    selection:SetScript("OnDragStart", function() pick(frame) dragStart(frame, info) end)
    selection:SetScript("OnDragStop", function() dragStop(frame, info) end)
    -- Arrow keys nudge the selected frame a pixel; every other key goes on to the game.
    selection:SetScript("OnKeyDown", function(self, key)
        local dx = (key == "RIGHT" and 1) or (key == "LEFT" and -1) or 0
        local dy = (key == "UP" and 1) or (key == "DOWN" and -1) or 0
        if dx == 0 and dy == 0 then
            self:SetPropagateKeyboardInput(true)
            return
        end
        self:SetPropagateKeyboardInput(false)
        local cx, cy, width, height = box(frame)
        if cx then
            moveTo(frame, info, clamp(cx + dx, width, UIParent:GetWidth()),
                clamp(cy + dy, height, UIParent:GetHeight()))
        end
    end)
    selection:Hide()
    return selection
end

-- The settings dialog -----------------------------------------------------------------------------

local dialog

local function newSlider(parent)
    local ok, slider = pcall(CreateFrame, "Slider", nil, parent, "MinimalSliderWithSteppersTemplate")
    if ok and slider and slider.Init and slider.RegisterCallback and MinimalSliderWithSteppersMixin then
        return slider
    end
end

local function newDialog()
    local hasBorder = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("DialogBorderTranslucentTemplate")
    local frame = CreateFrame("Frame", nil, UIParent, hasBorder and "DialogBorderTranslucentTemplate"
        or "BackdropTemplate")
    if not hasBorder and frame.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        frame:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        frame:SetBackdropColor(0, 0, 0, 0.8)
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetSize(320, 130)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", 0, -15)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() deselect() end)

    frame.scaleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.scaleLabel:SetPoint("TOPLEFT", 20, -50)
    frame.scaleLabel:SetText(L.EDITMODE_SCALE)
    frame.slider = newSlider(frame)
    if frame.slider then
        frame.slider:SetPoint("LEFT", frame.scaleLabel, "LEFT", 90, 0)
        frame.slider:SetWidth(190)
        frame.slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged,
            function(_, value)
                local info = selected and registered[selected]
                if info and info.scale and not frame.refreshing then
                    call(info.scale.set, value)
                    -- A frame that changes size changes what it snaps against.
                    if EditMode.Refresh then
                        EditMode.Refresh()
                    end
                end
            end, frame)
    end

    frame.reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.reset:SetSize(200, 24)
    frame.reset:SetText(L.EDITMODE_RESET_POSITION)
    frame.reset:SetScript("OnClick", function()
        local info = selected and registered[selected]
        if info and info.reset then
            call(info.reset)
        end
    end)
    frame:Hide()
    return frame
end

-- Sets the dialog up for the selected frame: its name, its scale slider if it has one, and a
-- reset button if it has one; and puts it beside the frame, on whichever side has more room.
function refreshDialog()
    local frame = selected
    local info = frame and registered[frame]
    if not info then
        if dialog then
            dialog:Hide()
        end
        return
    end
    dialog = dialog or newDialog()
    dialog.title:SetText(info.label)
    local height = 50
    local scale = info.scale
    local showSlider = scale and dialog.slider
    dialog.scaleLabel:SetShown(showSlider and true or false)
    if dialog.slider then
        dialog.slider:SetShown(showSlider and true or false)
    end
    if showSlider then
        dialog.refreshing = true
        local steps = (scale.max - scale.min) / scale.step
        local formatter = CreateMinimalSliderFormatter and MinimalSliderWithSteppersMixin.Label
            and CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right,
                function(value) return format(scale.format or "%d%%", value) end)
        dialog.slider:Init(scale.get(), scale.min, scale.max, steps,
            formatter and { [MinimalSliderWithSteppersMixin.Label.Right] = formatter } or nil)
        dialog.refreshing = false
        height = height + 40
    end
    dialog.reset:SetShown(info.reset ~= nil)
    if info.reset then
        dialog.reset:ClearAllPoints()
        dialog.reset:SetPoint("TOP", 0, -height)
        height = height + 34
    end
    dialog:SetHeight(height + 20)
    -- Beside the frame on the side of the screen with room, and above it when it fills the width.
    local cx, cy, width, h = box(frame)
    dialog:ClearAllPoints()
    if cx then
        local left = cx - width / 2
        local right = UIParent:GetWidth() - (cx + width / 2)
        if left >= dialog:GetWidth() + 10 or right >= dialog:GetWidth() + 10 then
            if right >= left then
                dialog:SetPoint("LEFT", frame, "RIGHT", 10, 0)
            else
                dialog:SetPoint("RIGHT", frame, "LEFT", -10, 0)
            end
        elseif cy > UIParent:GetHeight() / 2 then
            dialog:SetPoint("TOP", frame, "BOTTOM", 0, -10)
        else
            dialog:SetPoint("BOTTOM", frame, "TOP", 0, 10)
        end
    else
        dialog:SetPoint("CENTER")
    end
    dialog:Show()
end

function EditMode.Refresh()
    if selected then
        refreshDialog()
    end
end

-- Selecting ---------------------------------------------------------------------------------------

local selecting = false -- true while we ask Blizzard's own dialog to close

function deselect()
    if selected then
        local info = registered[selected]
        selected = nil
        if info then
            info.selection:SetScript("OnUpdate", nil)
            info.selection:EnableKeyboard(false)
            look(info.selection, false)
        end
    end
    hideGuides()
    refreshDialog()
end

function pick(frame)
    if selected == frame then
        return
    end
    deselect()
    local info = registered[frame]
    if not info then
        return
    end
    selected = frame
    -- Only one frame is selected at a time, so Blizzard's own selection and dialog go.
    if EditModeManagerFrame and EditModeManagerFrame.ClearSelectedSystem then
        selecting = true
        pcall(EditModeManagerFrame.ClearSelectedSystem, EditModeManagerFrame)
        selecting = false
    end
    look(info.selection, true)
    info.selection:EnableKeyboard(true)
    info.selection:SetPropagateKeyboardInput(true)
    refreshDialog()
end

local function setActive(active)
    if not active then
        deselect()
    end
    for _, info in pairs(registered) do
        info.selection:SetShown(active)
        if info.onChange then
            call(info.onChange, active)
        end
    end
end

local function install()
    if hooked or not EditModeManagerFrame then
        return
    end
    hooked = true
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() setActive(true) end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() setActive(false) end)
    -- Picking one of Blizzard's frames lets go of ours.
    for _, name in pairs({ "SelectSystem", "SetSelectedSystem" }) do
        if type(EditModeManagerFrame[name]) == "function" then
            hooksecurefunc(EditModeManagerFrame, name, function()
                if not selecting then
                    deselect()
                end
            end)
        end
    end
end

-- Registering -------------------------------------------------------------------------------------

---Makes `frame` selectable and draggable in Edit Mode, like Blizzard's own frames. It is placed
---from an offset from the center of the screen (`EditMode.Place`), and `onMove` gets the new offset
---when it moves.
---@param frame table
---@param label string the dialog's title and the right-click menu's
---@param onMove fun(x: number, y: number)
---@param options? { onChange: fun(active: boolean)?, scale: { min: number, max: number, step: number, format: string?, get: fun(): number, set: fun(value: number) }?, reset: fun()? }
--- onChange is called when Edit Mode opens or closes, and now if it's open. scale gives the
--- dialog a scale slider; reset gives it a Reset To Default Position button.
function EditMode.Register(frame, label, onMove, options)
    options = options or {}
    local info = registered[frame]
    if info then
        info.label, info.onMove, info.onChange = label, onMove, options.onChange
        info.scale, info.reset = options.scale, options.reset
        return
    end
    info = {
        label = label, onMove = onMove, onChange = options.onChange,
        scale = options.scale, reset = options.reset,
    }
    registered[frame] = info
    info.selection = newSelection(frame, info)
    install()
    if EditMode.IsActive() then
        info.selection:Show()
        if info.onChange then
            call(info.onChange, true)
        end
    end
end

---Takes the selection box off a frame, for a module turning off.
---@param frame table
function EditMode.Unregister(frame)
    local info = registered[frame]
    if not info then
        return
    end
    if selected == frame then
        deselect()
    end
    registered[frame] = nil
    info.selection:Hide()
    if info.onChange then
        call(info.onChange, false)
    end
end
