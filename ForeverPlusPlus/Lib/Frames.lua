-- Small frame helpers modules share: probing for Blizzard art and templates, the box tooltips are
-- drawn in, Escape closing our windows, red text in the error frame, running something once
-- after a burst of calls, and a timer that waits for one run at a time.
local _, ns = ...

local select, ipairs, tinsert, CreateFrame, C_Timer = select, ipairs, table.insert, CreateFrame, C_Timer
local setmetatable = setmetatable

local Frames = {}
ns.Frames = Frames

---Whether this client has an atlas. Probe: atlas names change between builds.
---@param name string
---@return boolean
function Frames.HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

---The first atlas in the list this client has, or nil.
---@param ... string atlas names, best first
---@return string?
function Frames.FirstAtlas(...)
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if Frames.HasAtlas(name) then
            return name
        end
    end
end

---Whether this client has a Blizzard template (Mainline's).
---@param name string
---@return boolean
function Frames.HasTemplate(name)
    return C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(name) and true
        or false
end

---A frame in the box Blizzard draws tooltips in, or the older tooltip backdrop where this client
---doesn't have the template.
---@param parent table
---@return table
function Frames.TooltipBox(parent)
    local hasTemplate = Frames.HasTemplate("TooltipBackdropTemplate")
    local box = CreateFrame("Frame", nil, parent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    if not hasTemplate and box.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        box:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        box:SetBackdropColor(0, 0, 0, 0.8)
    end
    return box
end

---Lets Escape close one of our windows, the way Blizzard's own windows close: its name goes in
---UISpecialFrames, which the game menu key hides first. Blizzard reads the list through
---securecall, so our entry taints nothing, and it skips hidden frames, so Escape still opens the
---game menu while the window is closed. The frame needs a global name.
---@param frame table a named frame
function Frames.CloseOnEscape(frame)
    local name = frame:GetName()
    if not (name and UISpecialFrames) then
        return
    end
    for _, special in ipairs(UISpecialFrames) do
        if special == name then
            return
        end
    end
    tinsert(UISpecialFrames, name)
end

---Red text in the middle of the screen, the way the game says "Not enough rage".
---@param text string?
function Frames.ErrorMessage(text)
    if not (text and UIErrorsFrame) then
        return
    end
    if UIErrorsFrame.AddExternalErrorMessage then
        UIErrorsFrame:AddExternalErrorMessage(text)
    else
        UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1)
    end
end

---Runs `fn` once, `delay` seconds after the first call (the next frame by default), however often
---it's called before then. For events that come in bursts.
---@param fn function
---@param delay? number
---@return function queue call to run `fn` soon
---@return function cancel drops a queued run
function Frames.Coalesce(fn, delay)
    local timer
    local function run()
        timer = nil
        fn()
    end
    local function queue()
        if not timer then
            timer = C_Timer.NewTimer(delay or 0, run)
        end
    end
    local function cancel()
        if timer then
            timer:Cancel()
            timer = nil
        end
    end
    return queue, cancel
end

---An OnUpdate script that calls `fn(frame)` at most every `interval` seconds: look a few times a
---second instead of every frame.
---@param interval number seconds
---@param fn fun(frame: table)
---@return fun(frame: table, delta: number)
function Frames.Throttled(interval, fn)
    local elapsed = 0
    return function(frame, delta)
        elapsed = elapsed + delta
        if elapsed >= interval then
            elapsed = 0
            fn(frame)
        end
    end
end

---A hidden frame that calls `fn()` every `interval` seconds while it's shown, charged to `module`
---on the Profiler page. Show it to start watching and hide it to stop.
---@param module table
---@param interval number seconds
---@param fn function
---@return table frame
function Frames.Watcher(module, interval, fn)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()
    frame:SetScript("OnUpdate", ns.Profiler.Wrap(module, Frames.Throttled(interval, fn)))
    return frame
end

local Timer = {}
Timer.__index = Timer

---Runs `fn` in `seconds`, in place of the run waiting, if any.
---@param seconds number
---@param fn function
function Timer:Start(seconds, fn)
    self:Cancel()
    local handle
    handle = C_Timer.NewTimer(seconds, function()
        if self.handle == handle then
            self.handle = nil
        end
        fn()
    end)
    self.handle = handle
end

---Drops the run waiting, if any.
function Timer:Cancel()
    if self.handle then
        self.handle:Cancel()
        self.handle = nil
    end
end

---Whether a run is waiting.
---@return boolean
function Timer:IsPending()
    return self.handle ~= nil
end

---A timer that waits for one run at a time: `Start(seconds, fn)` replaces the run waiting,
---`Cancel()` drops it (for OnDisable), and `IsPending()` says whether one is waiting. `fn` can
---start it again.
---@return table timer
function Frames.Timer()
    return setmetatable({}, Timer)
end
