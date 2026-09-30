-- Edit Mode for our own frames: while the player is in Blizzard's Edit Mode, a frame registered
-- here gets the same blue selection box Blizzard's frames get and can be dragged, and the position
-- is handed back to the module to save. Blizzard's Edit Mode has no way for an addon to add a
-- frame to its layouts (that needs its protected system code), so this only draws the box and
-- moves the frame; the position is the module's, not part of an Edit Mode layout. Nothing is
-- hooked until a module registers a frame.
local _, ns = ...

local pairs = pairs
local CreateFrame, UIParent, hooksecurefunc = CreateFrame, UIParent, hooksecurefunc
local NineSliceUtil, EditModeSystemSelectionLayout = NineSliceUtil, EditModeSystemSelectionLayout

local call = ns.Call

local EditMode = {}
ns.EditMode = EditMode

local registered = {} -- frame -> { label, onMove, onChange, selection }
local hooked = false

---Whether Edit Mode is open. Probe: EditModeManagerFrame is Mainline's.
---@return boolean
function EditMode.IsActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown() or false
end

-- The selection box: Blizzard's own border art when its layout is there, else a plain tint.
local function newSelection(frame, label)
    local selection = CreateFrame("Frame", nil, frame)
    selection:SetAllPoints(frame)
    selection:SetFrameLevel(frame:GetFrameLevel() + 10)
    selection:EnableMouse(true)
    selection:RegisterForDrag("LeftButton")
    if NineSliceUtil and EditModeSystemSelectionLayout then
        NineSliceUtil.ApplyLayout(selection, EditModeSystemSelectionLayout)
    else
        local tint = selection:CreateTexture(nil, "BACKGROUND")
        tint:SetAllPoints()
        tint:SetColorTexture(0.2, 0.5, 1, 0.3)
    end
    local text = selection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER")
    text:SetText(label)
    selection:Hide()
    return selection
end

-- After a drag: the frame's center against the screen's center, which any saved position and
-- scale can rebuild.
local function dropped(frame, info)
    frame:StopMovingOrSizing()
    local x, y = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not (x and ux) then
        return
    end
    x, y = x - ux, y - uy
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    info.onMove(x, y)
end

local function setActive(active)
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
end

---Makes `frame` draggable in Edit Mode. It should be anchored to UIParent's center; `onMove(x, y)`
---gets its new offset from there when a drag ends.
---@param frame table
---@param label string what the selection box says
---@param onMove fun(x: number, y: number)
---@param onChange? fun(active: boolean) called when Edit Mode opens or closes, and now if it's open
function EditMode.Register(frame, label, onMove, onChange)
    if registered[frame] then
        registered[frame].onMove, registered[frame].onChange = onMove, onChange
        return
    end
    local info = { onMove = onMove, onChange = onChange, selection = newSelection(frame, label) }
    registered[frame] = info
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    info.selection:SetScript("OnDragStart", function() frame:StartMoving() end)
    info.selection:SetScript("OnDragStop", function() dropped(frame, info) end)
    install()
    if EditMode.IsActive() then
        info.selection:Show()
        if onChange then
            call(onChange, true)
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
    registered[frame] = nil
    info.selection:Hide()
    if info.onChange then
        call(info.onChange, false)
    end
end
