-- Error Catcher: catches Lua errors, blocked and forbidden actions, and Lua warnings instead of
-- Blizzard's error window and popup, saves them with the session they happened in, and shows
-- them in a window as text that can be copied (`/fpp errors`, or the minimap button). An error
-- that happens again is counted instead of kept twice.
--
-- The error handler goes in when this file loads, not in OnEnable, so errors while the addons
-- after this one load are caught too. Whether the module is on is only known once saved
-- variables load, so until then errors wait in `pending`: OnEnable saves them, and OnLoad, when
-- the module is off, gives the handler back and passes them on to it. The TOC loads this file
-- first among the modules, so their load errors are caught too.
local _, ns = ...

local format, tostring, pcall, select, ipairs = string.format, tostring, pcall, select, ipairs
local min, floor = math.min, math.floor
local concat, tremove, wipe, time, date = table.concat, table.remove, wipe, time, date
local cos, sin, rad, deg, atan2 = math.cos, math.sin, math.rad, math.deg, math.atan2
local CreateFrame, UIParent, GetTime, GetCursorPosition = CreateFrame, UIParent, GetTime, GetCursorPosition
local C_Timer, error = C_Timer, error
local seterrorhandler, geterrorhandler = seterrorhandler, geterrorhandler
local debugstack, debuglocals = debugstack, debuglocals
local GetCallstackHeight, GetErrorCallstackHeight = GetCallstackHeight, GetErrorCallstackHeight
local issecretvalue = issecretvalue

local L = ns.L

local module = ns.NewModule("ErrorCatcher", L.ERRORCATCHER_DESC, {
    enabled = false,
    chat = true,
    minimap = true,
    clearModifier = "ctrl",
    -- Data, not settings: a table, so presets leave it alone.
    saved = {
        session = 0, -- counts logins and reloads
        errors = {}, -- oldest first: { message, stack, locals, count, session, time }
        angle = 200, -- the minimap button's place around the minimap, in degrees
    },
})
module.title = L.ERRORCATCHER_TITLE
module.category = "interface"

local MAX_ERRORS = 200 -- the oldest go first
local MAX_TEXT = 4000 -- letters kept of a stack or the locals, so the saved file stays small
local PER_SECOND = 10 -- errors caught a second at most; an error in OnUpdate repeats every frame
local ANNOUNCE_EVERY = 10 -- seconds between chat messages about new errors

local previous -- the handler before ours, given back when the module turns off
local pending = {} -- errors caught before saved variables loaded
local busy -- true while catching an error, so an error while catching can't loop
local allowance, lastCaught = PER_SECOND, 0
local lastAnnounced = -ANNOUNCE_EVERY
local button, window

-- Text that's safe to keep: a secret value or nil becomes `fallback`.
local function readable(value, fallback)
    if issecretvalue and issecretvalue(value) then
        return fallback
    end
    if value == nil then
        return fallback
    end
    value = tostring(value)
    if #value > MAX_TEXT then
        value = value:sub(1, MAX_TEXT) .. "\n..."
    end
    return value
end

-- Errors -------------------------------------------------------------------------------------

---The saved errors and session number, or nil before saved variables load.
local function saved()
    return module.db and module.db.saved
end

---How many different errors this session caught.
---@return number
local function sessionCount()
    local data = saved()
    if not data then
        return 0
    end
    local count = 0
    for _, entry in ipairs(data.errors) do
        if entry.session == data.session then
            count = count + 1
        end
    end
    return count
end

local refreshButton, refreshWindow -- set below, once the frames exist

local function changed()
    if refreshButton then
        refreshButton()
    end
    if refreshWindow then
        refreshWindow(true)
    end
end

-- The first line of an error, without the "Interface/AddOns/" every file path starts with.
local function short(message)
    local line = message:match("^[^\n]*") or message
    line = line:gsub("^Interface[/\\]AddOns[/\\]", "")
    if #line > 120 then
        line = line:sub(1, 117) .. "..."
    end
    return line
end

-- Saves an error, or counts it again if it's already saved. An error seen again in a new session
-- moves to the end, into this session, with its new stack.
local function store(entry, announce)
    local data = saved()
    local errors = data.errors
    for i = #errors, 1, -1 do
        local old = errors[i]
        if old.message == entry.message then
            old.count = (old.count or 1) + 1
            old.time = entry.time
            if old.session ~= data.session then
                old.session = data.session
                old.stack, old.locals = entry.stack, entry.locals
                tremove(errors, i)
                errors[#errors + 1] = old
            end
            changed()
            return
        end
    end
    entry.count = 1
    entry.session = data.session
    errors[#errors + 1] = entry
    while #errors > MAX_ERRORS do
        tremove(errors, 1)
    end
    if announce and GetTime() - lastAnnounced >= ANNOUNCE_EVERY then
        lastAnnounced = GetTime()
        module:Print(format(L.ERRORCATCHER_CAUGHT, short(entry.message)))
    end
    changed()
end

-- Keeps an error: saved while the module is on, kept for later before saved variables load,
-- and handed to the old handler if ours is still called while the module is off.
local function catch(entry)
    if module.enabled then
        store(entry, true)
    elseif not module.db then
        pending[#pending + 1] = entry
    elseif previous then
        pcall(previous, entry.message)
    end
end

-- Whether another error may be caught now (at most PER_SECOND a second).
local function allowed()
    local now = GetTime()
    allowance = min(PER_SECOND, allowance + (now - lastCaught) * PER_SECOND)
    lastCaught = now
    if allowance < 1 then
        return false
    end
    allowance = allowance - 1
    return true
end

-- The stack and locals of the function that raised the error. Blizzard's own handler finds it
-- from the two stack heights; without them, it's three levels up (this, the pcall, the handler).
-- Must be called through pcall straight from the handler, for the fallback depth to be right.
local function capture()
    local level = 4
    local height = GetCallstackHeight and GetCallstackHeight()
    local errorHeight = GetErrorCallstackHeight and GetErrorCallstackHeight()
    if height and errorHeight then
        level = height - errorHeight + 1
    end
    -- Both can come back secret on Forever (Midnight's rules).
    return readable(debugstack and debugstack(level), nil), readable(debuglocals and debuglocals(level), nil)
end

-- The error handler: the game calls it with the message of every Lua error.
local function onError(message)
    if busy or not allowed() then
        return
    end
    busy = true
    local ok, stack, locals = pcall(capture)
    if not ok then
        stack, locals = nil, nil
    end
    pcall(catch, {
        message = readable(message, L.ERRORCATCHER_SECRET),
        stack = stack,
        locals = locals,
        time = time(),
    })
    busy = false
end

-- ADDON_ACTION_BLOCKED and ADDON_ACTION_FORBIDDEN: an addon called something only Blizzard's
-- code may. The stack here would only be this handler's, so there's none.
local function onBlocked(event, addon, fn)
    if not allowed() then
        return
    end
    catch({
        message = format(L.ERRORCATCHER_BLOCKED, event, readable(addon, L.ERRORCATCHER_UNKNOWN),
            readable(fn, L.ERRORCATCHER_UNKNOWN)),
        time = time(),
    })
end

-- LUA_WARNING: older clients send a warning type before the text, newer ones only the text.
local function onWarning(_, ...)
    if not allowed() then
        return
    end
    local text = select(select("#", ...), ...)
    catch({
        message = format(L.ERRORCATCHER_WARNING, readable(text, L.ERRORCATCHER_UNKNOWN)),
        time = time(),
    })
end

local function clear()
    local data = saved()
    if data then
        wipe(data.errors)
        changed()
    end
end

-- Forgets this session's errors, keeping earlier sessions'.
local function clearSession()
    local data = saved()
    if not data then
        return
    end
    local kept = {}
    for _, entry in ipairs(data.errors) do
        if entry.session ~= data.session then
            kept[#kept + 1] = entry
        end
    end
    data.errors = kept
    changed()
end

-- Caught from here on (see the top of the file).
previous = geterrorhandler()
seterrorhandler(onError)

-- The window ----------------------------------------------------------------------------------

local SESSION, LAST, ALL = "session", "last", "all"
local filter = SESSION
local list, index = {}, 0 -- the errors the filter shows, and which one is open

-- The latest session before this one that caught anything.
local function lastSession(data)
    local last
    for _, entry in ipairs(data.errors) do
        if entry.session < data.session and (not last or entry.session > last) then
            last = entry.session
        end
    end
    return last
end

local function filtered()
    local data = saved()
    local result = {}
    if not data then
        return result
    end
    local wanted = filter == SESSION and data.session or filter == LAST and lastSession(data)
    for _, entry in ipairs(data.errors) do
        if filter == ALL or entry.session == wanted then
            result[#result + 1] = entry
        end
    end
    return result
end

-- An error as the text the window shows. "|" is doubled so the text shows as it is, instead of
-- as colors and icons.
local function entryText(entry)
    local lines = { entry.message, "",
        format(L.ERRORCATCHER_DETAILS, entry.count or 1, entry.session or 0,
            date("%Y-%m-%d %H:%M:%S", entry.time or 0)) }
    if entry.stack and entry.stack ~= "" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = L.ERRORCATCHER_STACK
        lines[#lines + 1] = entry.stack
    end
    if entry.locals and entry.locals ~= "" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = L.ERRORCATCHER_LOCALS
        lines[#lines + 1] = entry.locals
    end
    return (concat(lines, "\n"):gsub("|", "||"))
end

local function show()
    local f = window
    local entry = list[index]
    if entry then
        f.position:SetText(format(L.ERRORCATCHER_POSITION, index, #list))
        f.seen:SetText(format(L.ERRORCATCHER_SEEN, entry.count or 1,
            ns.Text.Ago(time() - (entry.time or time()))))
        f.edit:SetText(entryText(entry))
    else
        f.position:SetText("")
        f.seen:SetText("")
        f.edit:SetText(L.ERRORCATCHER_NONE)
    end
    f.edit:SetCursorPosition(0)
    f.scroll:SetVerticalScroll(0)
    f.prev:SetEnabled(index > 1)
    f.next:SetEnabled(index < #list)
    f.clear:SetEnabled(saved() ~= nil and #saved().errors > 0)
end

-- Rebuilds the list. `follow` keeps the newest error open if it was, so new ones show at once.
function refreshWindow(follow)
    if not (window and window:IsShown()) then
        return
    end
    local atEnd = index >= #list
    list = filtered()
    if (follow and atEnd) or index > #list or index < 1 then
        index = #list
    end
    show()
end

local function setFilter(value)
    filter = value
    list = filtered()
    index = #list
    show()
end

local function newButton(parent, text, width)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    return b
end

local FILTERS = {
    { SESSION, L.ERRORCATCHER_THIS_SESSION },
    { LAST, L.ERRORCATCHER_LAST_SESSION },
    { ALL, L.ERRORCATCHER_ALL },
}

-- Blizzard's dropdown for the session filter. Probe: WowStyle1DropdownTemplate is Mainline's;
-- without it, a button that steps through the choices.
local function newFilter(parent)
    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(150)
        dropdown:SetupMenu(function(_, root)
            for _, choice in ipairs(FILTERS) do
                root:CreateRadio(choice[2], function(value)
                    return filter == value
                end, setFilter, choice[1])
            end
        end)
        return dropdown
    end
    local b = newButton(parent, FILTERS[1][2], 150)
    b:SetScript("OnClick", function(self)
        for i, choice in ipairs(FILTERS) do
            if choice[1] == filter then
                local nextChoice = FILTERS[i % #FILTERS + 1]
                self:SetText(nextChoice[2])
                setFilter(nextChoice[1])
                return
            end
        end
    end)
    return b
end

local function newWindow()
    local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(640, 460)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", f.StartMoving)
    f:SetScript("OnMouseUp", f.StopMovingOrSizing)
    if f.SetTitle then
        f:SetTitle(L.ERRORCATCHER_TITLE)
    elseif f.TitleText then
        f.TitleText:SetText(L.ERRORCATCHER_TITLE)
    end

    -- Which error this is, and how often and how long ago it happened, under the title bar.
    f.position = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.position:SetPoint("TOPLEFT", 16, -34)
    f.seen = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.seen:SetPoint("TOPRIGHT", -16, -34)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -54)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 40)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetWidth(590)
    edit:SetScript("OnEscapePressed", function()
        f:Hide()
    end)
    -- Selected on click, ready for Ctrl+C.
    edit:SetScript("OnEditFocusGained", edit.HighlightText)
    -- Read only: typing puts the error back.
    edit:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            show()
        end
    end)
    scroll:SetScrollChild(edit)
    scroll:SetScript("OnSizeChanged", function(_, width)
        edit:SetWidth(width)
    end)

    f.prev = newButton(f, L.ERRORCATCHER_PREV, 90)
    f.prev:SetPoint("BOTTOMLEFT", 12, 10)
    f.prev:SetScript("OnClick", function()
        index = index - 1
        show()
    end)
    f.next = newButton(f, L.ERRORCATCHER_NEXT, 90)
    f.next:SetPoint("LEFT", f.prev, "RIGHT", 4, 0)
    f.next:SetScript("OnClick", function()
        index = index + 1
        show()
    end)
    f.filter = newFilter(f)
    f.filter:SetPoint("LEFT", f.next, "RIGHT", 12, 0)
    f.clear = newButton(f, L.ERRORCATCHER_CLEAR, 90)
    f.clear:SetPoint("BOTTOMRIGHT", -12, 10)
    f.clear:SetScript("OnClick", function()
        ns.Confirm("ERRORCATCHER_CLEAR", L.ERRORCATCHER_CLEAR_CONFIRM, clear)
    end)

    f.edit, f.scroll = edit, scroll
    f:Hide()
    return f
end

local function toggleWindow()
    if window and window:IsShown() then
        window:Hide()
        return
    end
    window = window or newWindow()
    window:Show()
    list = filtered()
    index = #list
    show()
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

function refreshButton()
    if not button then
        return
    end
    local count = sessionCount()
    button.count:SetText(count > 0 and count or "")
    -- Gray while this session has caught nothing.
    button.icon:SetDesaturated(count == 0)
end

-- The keys that, held with a right-click on the minimap button, clear this session's errors.
local MODIFIERS = {
    ctrl = { name = L.ERRORCATCHER_KEY_CTRL, down = IsControlKeyDown },
    shift = { name = L.ERRORCATCHER_KEY_SHIFT, down = IsShiftKeyDown },
    alt = { name = L.ERRORCATCHER_KEY_ALT, down = IsAltKeyDown },
}

local function onClick(_, mouse)
    if mouse ~= "RightButton" then
        toggleWindow()
        return
    end
    -- A right-click alone does nothing, so clearing is never an accident.
    local modifier = MODIFIERS[module.db.clearModifier]
    if modifier and modifier.down() then
        clearSession()
    end
end

local function onEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.ERRORCATCHER_TITLE)
    GameTooltip:AddLine(format(L.ERRORCATCHER_TIP_SESSION, sessionCount()), 1, 1, 1)
    GameTooltip:AddLine(format(L.ERRORCATCHER_TIP_SAVED, saved() and #saved().errors or 0), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.ERRORCATCHER_TIP_CLICK, 0.1, 1, 0.1)
    local modifier = MODIFIERS[module.db.clearModifier]
    if modifier then
        GameTooltip:AddLine(format(L.ERRORCATCHER_TIP_CLEAR, modifier.name), 0.1, 1, 0.1)
    end
    GameTooltip:AddLine(L.ERRORCATCHER_TIP_DRAG, 0.1, 1, 0.1)
    GameTooltip:Show()
end

-- The usual round minimap button: Blizzard's tracking border around a small icon.
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
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(ns.icon)
    b.icon:SetSize(18, 18)
    b.icon:SetPoint("TOPLEFT", 7, -6)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
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

local function updateButton()
    if module.enabled and module.db.minimap and Minimap then
        button = button or newMinimapButton()
        place()
        refreshButton()
        button:Show()
    elseif button then
        button:SetScript("OnUpdate", nil)
        button:Hide()
    end
end

-- The module ----------------------------------------------------------------------------------

module.options = {
    {
        key = "minimap",
        name = L.ERRORCATCHER_MINIMAP,
        description = L.ERRORCATCHER_MINIMAP_DESC,
    },
    {
        key = "clearModifier",
        name = L.ERRORCATCHER_CLEAR_KEY,
        description = L.ERRORCATCHER_CLEAR_KEY_DESC,
        choices = {
            { "ctrl", L.ERRORCATCHER_KEY_CTRL },
            { "shift", L.ERRORCATCHER_KEY_SHIFT },
            { "alt", L.ERRORCATCHER_KEY_ALT },
            { "none", L.ERRORCATCHER_KEY_NONE },
        },
    },
    ns.ChatOption(L.ERRORCATCHER_CHAT_DESC),
}

module.actions = {
    {
        name = L.ERRORCATCHER_SHOW,
        button = L.ERRORCATCHER_SHOW_BUTTON,
        description = L.ERRORCATCHER_SHOW_DESC,
        fn = toggleWindow,
    },
    {
        name = L.ERRORCATCHER_CLEAR_NAME,
        button = L.ERRORCATCHER_CLEAR,
        description = L.ERRORCATCHER_CLEAR_DESC,
        confirm = L.ERRORCATCHER_CLEAR_CONFIRM,
        key = "ERRORCATCHER_CLEAR",
        fn = clear,
    },
}

-- Raises a Lua error on purpose, to see what catches it. On the next frame, so it goes to the
-- error handler on its own instead of out of the Settings button's click.
local function testError()
    C_Timer.After(0, function()
        error(L.ERRORCATCHER_TEST_MESSAGE)
    end)
end

-- On the Debug page (Settings.lua). Works with the module off too, to see Blizzard's handler.
module.debugActions = {
    {
        name = L.ERRORCATCHER_TEST,
        button = L.ERRORCATCHER_TEST_BUTTON,
        description = L.ERRORCATCHER_TEST_DESC,
        fn = testError,
    },
}

-- An event this client may not have: RegisterEvent can raise an error for an unknown one.
local function listen(event, fn)
    if not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event) then
        module:On(event, fn)
    end
end

function module:OnLoad()
    local data = self.db.saved
    data.session = data.session + 1
    if self.db.enabled then
        return -- OnEnable saves what's pending
    end
    -- Off: give the handler back, with what it missed while the addons loaded.
    if geterrorhandler() == onError then
        seterrorhandler(previous)
    end
    for _, entry in ipairs(pending) do
        pcall(previous, entry.message)
    end
    pending = {}
end

function module:OnEnable()
    local current = geterrorhandler()
    if current ~= onError then
        previous = current
        seterrorhandler(onError)
    end
    -- BugGrabber keeps the handler to itself, so ours never goes in.
    if geterrorhandler() ~= onError then
        self:Print(L.ERRORCATCHER_OTHER_HANDLER)
    end
    listen("ADDON_ACTION_BLOCKED", onBlocked)
    listen("ADDON_ACTION_FORBIDDEN", onBlocked)
    listen("LUA_WARNING", onWarning)
    -- Blizzard's "blocked from an action" popup, which offers to turn the addon off.
    if StaticPopup_Show and StaticPopup_Hide then
        self:Hook("StaticPopup_Show", function(which)
            if which == "ADDON_ACTION_FORBIDDEN" then
                StaticPopup_Hide(which)
            end
        end)
    end
    -- Blizzard's error window, which still opens for Lua warnings.
    if ScriptErrorsFrame then
        self:HookScript(ScriptErrorsFrame, "OnShow", ScriptErrorsFrame.Hide)
    end

    if #pending > 0 then
        local count = #pending
        for _, entry in ipairs(pending) do
            store(entry, false)
        end
        pending = {}
        self:Print(format(L.ERRORCATCHER_CAUGHT_LOADING, count))
    end
    updateButton()
end

function module:OnDisable()
    if geterrorhandler() == onError then
        seterrorhandler(previous)
    end
    updateButton()
    if window then
        window:Hide()
    end
end

function module:OnOptionChanged(key)
    if key == "minimap" then
        updateButton()
    end
end

ns.AddCommand("errors", "", L.ERRORCATCHER_COMMAND, function()
    if module.enabled then
        toggleWindow()
    else
        ns.Print(L.ERRORCATCHER_OFF)
    end
end)
