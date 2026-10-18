-- Blizzard's action buttons and what their slots hold, for modules that mark buttons with frames of
-- their own. The buttons are protected, so we only read them, and a mark is our own child frame,
-- made out of combat (a child of a protected button can't be made in combat; showing and hiding
-- one we already made is fine).
local _, ns = ...

local _G, ipairs, pairs, setmetatable = _G, ipairs, pairs, setmetatable
local CreateFrame, GetActionInfo, InCombatLockdown = CreateFrame, GetActionInfo, InCombatLockdown
local C_ActionBar, GetActionText = C_ActionBar, GetActionText

local ActionButtons = {}
ns.ActionButtons = ActionButtons

local readable = ns.IsReadable

-- Blizzard's action bars, in the order /fpp ranks numbers them: the button name prefix of each.
local BARS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
    "MultiBar7Button",
}
local BUTTONS = 12
-- Levels above the button: past its cooldown, flash, and the other child frames Blizzard stacks
-- on it, so a mark is never drawn under them.
local LEVELS_ABOVE = 20

---Calls `fn(button, bar, index)` for every Blizzard action button this client has.
---@param fn fun(button: table, bar: number, index: number)
function ActionButtons.Each(fn)
    for bar, prefix in ipairs(BARS) do
        for index = 1, BUTTONS do
            local button = _G[prefix .. index]
            if button then
                fn(button, bar, index)
            end
        end
    end
end

---What the button's slot holds: its kind ("spell", "macro", "item") and ID, or nil for an empty
---slot or one that can't be read now. A macro's ID is the spell or item it shows, not its index,
---and its subtype says which ("spell" for a spell; it may be secret, so check it's readable);
---ActionButtons.MacroName tells which macro it is.
---@param button table
---@return string? kind
---@return number? id
---@return string? subType
function ActionButtons.Content(button)
    local action = button.action
    if not (action and readable(action)) then
        return nil
    end
    local kind, id, subType = GetActionInfo(action)
    if not (kind and readable(kind) and readable(id)) then
        return nil
    end
    return kind, id, subType
end

---The name of the macro in the button's slot, or nil when it holds none or can't be read now.
---@param button table
---@return string?
function ActionButtons.MacroName(button)
    local action = button.action
    local get = C_ActionBar and C_ActionBar.GetActionText or GetActionText
    if not (get and action and readable(action)) then
        return nil
    end
    local name = get(action)
    return ns.IsText(name, true) and name or nil
end

---A set of marks: one frame of ours over each action button that needs one, made the first time
---it's asked for out of combat. `build(frame)` adds the frame's regions.
---@param build fun(frame: table)
---@return table marks with `Get(button)` (the button's frame, made if it can be, or nil), `Find(button)` (only one already made), and `HideAll()`
function ActionButtons.Marks(build)
    local frames = setmetatable({}, { __mode = "k" }) -- button -> our frame
    local marks = {}

    function marks.Find(button)
        return frames[button]
    end

    function marks.Get(button)
        local frame = frames[button]
        if frame or InCombatLockdown() then
            return frame
        end
        frame = CreateFrame("Frame", nil, button)
        frame:SetAllPoints()
        frame:SetFrameLevel(button:GetFrameLevel() + LEVELS_ABOVE)
        frame:EnableMouse(false)
        build(frame)
        frames[button] = frame
        return frame
    end

    function marks.HideAll()
        for _, frame in pairs(frames) do
            frame:Hide()
        end
    end

    return marks
end
