-- Action Bar Colors: a whole action button tinted red while the target is out of its range, and a
-- deeper blue while the player can't pay its cost. The game only turns the key text red and tints
-- the icon a faint blue.
--
-- It colors the icon itself, as Blizzard does for the faint blue (ActionBarActionButtonMixin's
-- UpdateUsable sets the icon's vertex color: white, 0.5/0.5/1 short of mana, 0.4 gray unusable),
-- so the tint sits under the cooldown swipe, the border, and the key like Blizzard's own. A texture
-- of ours over the icon would wash it out instead. Blizzard sets the color again each time it
-- updates a button, so every place it does is hooked and our tint goes back on after it:
--   - an action button's UpdateUsable (also the controller interface's buttons, which call it),
--   - ActionButton_UpdateRangeIndicator, which the action and pet bars call with the range result
--     (ACTION_RANGE_CHECK_UPDATE's payload, and GetPetActionInfo's on the pet bar's timer),
--   - the controller interface's RefreshRange, its own range handler,
--   - a pet button's UpdateButtonState, which colors its icon white or gray.
-- Range comes before cost. The pet bar has no "not enough" state, so it only gets the red. The
-- stance bar checks no range and has no cost color, so it's left alone.
--
-- The hooks only read and set the icon texture's color: nothing is written on Blizzard's buttons,
-- and a texture's color isn't protected, so it changes in combat too. Turning off puts back the
-- color Blizzard would have set, by the same rule. IsUsableAction, IsActionInRange, and the range
-- event aren't marked secret in this build's API docs (ActionBarFrameDocumentation.lua, build
-- 70205), but each value is still checked before it's tested.
local _, ns = ...

local pairs, ipairs, select, setmetatable = pairs, ipairs, select, setmetatable
local C_ActionBar, GetPetActionInfo, GetPetActionSlotUsable = C_ActionBar, GetPetActionInfo, GetPetActionSlotUsable

local L = ns.L

local module = ns.NewModule("ActionBarColors", L.ACTIONBARCOLORS_DESC, {
    enabled = false,
    range = true,
    resource = true,
})
module.title = L.ACTIONBARCOLORS_TITLE
module.presets = { developer = { enabled = true } }
module.category = "interface"
module.added = "1.10.0"

module.options = {
    { key = "range", name = L.ACTIONBARCOLORS_RANGE, description = L.ACTIONBARCOLORS_RANGE_DESC },
    { key = "resource", name = L.ACTIONBARCOLORS_RESOURCE, description = L.ACTIONBARCOLORS_RESOURCE_DESC },
}

function module:IsAvailable()
    return C_ActionBar and C_ActionBar.IsUsableAction and C_ActionBar.IsActionInRange
        and ActionButton_UpdateRangeIndicator and true or false
end

-- Our tints: soft enough that the icon still reads, in the game's red and mana blue.
local RANGE = { 1, 0.3, 0.3 }
local RESOURCE = { 0.3, 0.4, 1 }
-- Blizzard's own colors, put back when our tint comes off (UpdateUsable, UpdateButtonState).
local USABLE = { 1, 1, 1 }
local NO_MANA = { 0.5, 0.5, 1 }
local UNUSABLE = { 0.4, 0.4, 0.4 }

local readable, isTrue, trueOrSecret = ns.IsReadable, ns.IsTrue, ns.IsTrueOrSecret

local kinds = setmetatable({}, { __mode = "k" }) -- button -> "action" or "pet"
local applied = setmetatable({}, { __mode = "k" }) -- button -> "range" or "resource" while tinted

-- The slot an action button holds, or nil for an empty one or one that can't be read.
local function slotOf(button)
    local action = button.action
    if not (action and readable(action)) or action == 0 or not C_ActionBar.HasAction(action) then
        return nil
    end
    return action
end

-- Whether the action button's target is known to be out of range.
local function actionOutOfRange(button)
    local action = slotOf(button)
    if not action then
        return false
    end
    local inRange = C_ActionBar.IsActionInRange(action)
    -- nil when range can't be told (no target, or an action with no range).
    return readable(inRange) and inRange == false
end

-- Whether the action is usable, and whether only its cost stops it. Nil when it can't be read.
local function actionUsable(button, isUsable, noMana)
    if isUsable == nil or noMana == nil then
        local action = slotOf(button)
        if not action then
            return nil
        end
        isUsable, noMana = C_ActionBar.IsUsableAction(action)
    end
    if not (readable(isUsable) and readable(noMana)) then
        return nil
    end
    return not not isUsable, not not noMana
end

local function petID(button)
    local id = button.index or (button.GetID and button:GetID())
    return ns.IsNumber(id) and id > 0 and id or nil
end

local function petUsable(button)
    local id = petID(button)
    if not (id and GetPetActionSlotUsable) then
        return nil
    end
    local usable = GetPetActionSlotUsable(id)
    if not readable(usable) then
        return nil, false
    end
    return not not usable, false
end

local function petOutOfRange(button)
    local id = petID(button)
    if not (id and GetPetActionInfo) then
        return false
    end
    local checksRange, inRange = select(8, GetPetActionInfo(id))
    return isTrue(checksRange) and not trueOrSecret(inRange)
end

-- The tint a button should have: range first, then cost.
local function wanted(outOfRange, usable, noMana)
    local db = module.db
    if db.range and outOfRange then
        return "range"
    end
    if db.resource and usable == false and noMana then
        return "resource"
    end
    return nil
end

-- Sets the icon's color for `want`, or, coming off a tint of ours, the color Blizzard would have.
local function paint(button, want, usable, noMana)
    local icon = button.icon
    if not (icon and icon.SetVertexColor) then
        return
    end
    local color
    if want == "range" then
        color = RANGE
    elseif want == "resource" then
        color = RESOURCE
    elseif applied[button] then
        color = (usable ~= false) and USABLE or (noMana and NO_MANA) or UNUSABLE
    end
    applied[button] = want
    if color then
        icon:SetVertexColor(color[1], color[2], color[3])
    end
end

-- Works out and paints a button's tint from the game's state now.
local function refresh(button)
    local kind = kinds[button]
    if kind == "action" then
        local usable, noMana = actionUsable(button)
        paint(button, wanted(actionOutOfRange(button), usable, noMana), usable, noMana)
    elseif kind == "pet" then
        local usable = petUsable(button)
        paint(button, wanted(petOutOfRange(button), usable, false), usable, false)
    end
end

-- After Blizzard's UpdateUsable has just set the icon's color: ours goes back on top.
local function onUsable(button, _, isUsable, noMana)
    applied[button] = nil
    local usable, short = actionUsable(button, isUsable, noMana)
    local want = wanted(actionOutOfRange(button), usable, short)
    if want then
        paint(button, want, usable, short)
    end
end

local function onPetState(button)
    applied[button] = nil
    local usable = petUsable(button)
    local want = wanted(petOutOfRange(button), usable, false)
    if want then
        paint(button, want, usable, false)
    end
end

-- A range result for a button (ActionButton_UpdateRangeIndicator, or the controller's
-- RefreshRange). The pet bar's comes every 0.2 seconds, so an unchanged tint does nothing.
local function onRange(button, checksRange, inRange)
    local kind = kinds[button]
    if not kind then
        return
    end
    local outOfRange = isTrue(checksRange) and not trueOrSecret(inRange)
    local usable, noMana
    if kind == "action" then
        usable, noMana = actionUsable(button)
    else
        usable, noMana = petUsable(button)
    end
    local want = wanted(outOfRange, usable, noMana)
    if want ~= applied[button] then
        paint(button, want, usable, noMana)
    end
end

local function hookButtons()
    ns.ActionButtons.Each(function(button)
        if button.UpdateUsable and not kinds[button] then
            kinds[button] = "action"
            module:Hook(button, "UpdateUsable", onUsable)
            module:Hook(button, "RefreshRange", onRange) -- the controller interface's buttons only
        end
    end, true)
    local pets = PetActionBar and PetActionBar.actionButtons
    for _, button in ipairs(pets or {}) do
        if button.UpdateButtonState and not kinds[button] then
            kinds[button] = "pet"
            module:Hook(button, "UpdateButtonState", onPetState)
        end
    end
end

local function refreshAll()
    for button in pairs(kinds) do
        refresh(button)
    end
end

local queue = ns.Frames.Coalesce(function()
    hookButtons()
    refreshAll()
end, 0.1, module)

function module:OnEnable()
    self:Hook("ActionButton_UpdateRangeIndicator", onRange)
    ns.ActionButtons.Watch(self, queue) -- the controller interface's bars, made or paged later
    hookButtons()
    refreshAll()
end

function module:OnDisable()
    for button, tint in pairs(applied) do
        if tint then
            local usable, noMana
            if kinds[button] == "action" then
                usable, noMana = actionUsable(button)
            else
                usable, noMana = petUsable(button)
            end
            paint(button, nil, usable, noMana)
        end
    end
end

function module:OnOptionChanged()
    refreshAll()
end
