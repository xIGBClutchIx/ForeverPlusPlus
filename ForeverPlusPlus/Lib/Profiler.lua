-- How much CPU each module takes, for the Profiler page (Modules/Tools/Profiler.lua). The game
-- measures only the addon as a whole (C_AddOnProfiler), so while recording, each call into a
-- module's code is timed and charged to its module: events and hooks through Core.lua, callbacks
-- the shared Lib files run for modules, and per-frame updates a module wraps with Profiler.Wrap.
-- Time a timed call spends inside another timed call is charged to the inner one only.
-- Off (the default) nothing is timed: each of those paths checks `recording` and calls straight
-- through, and no frame runs.
local _, ns = ...

local pairs, ipairs, type, sort, wipe = pairs, ipairs, type, table.sort, wipe
local debugprofilestop, GetTime, CreateFrame = debugprofilestop, GetTime, CreateFrame

local Profiler = { recording = false }
ns.Profiler = Profiler

-- The key for code no module owns: the Lib files' own event handlers and anything else not
-- traced to a module.
local SHARED = {}
Profiler.SHARED = SHARED

-- key -> { total = ms, calls, frame = ms this frame, peak = most ms in one frame }: each key's own
-- time, and in `groups` a module's together with its parts' (Profiler.Part).
local stats = {}
local groups = {}
local started, stopped -- GetTime() when recording started and stopped (nil while it runs)
local depth = 0 -- timed calls under way, one inside another
local inner = {} -- depth -> ms spent in timed calls inside the one at that depth
local frame -- closes each frame's sums while recording

local function entry(list, key)
    local s = list[key]
    if not s then
        s = { total = 0, calls = 0, frame = 0, peak = 0 }
        list[key] = s
    end
    return s
end

local function closeFrame(list)
    for _, s in pairs(list) do
        if s.frame > s.peak then
            s.peak = s.frame
        end
        s.frame = 0
    end
end

-- Once a frame while recording: each module's time this frame against its worst. A call that
-- errored never closed its depth, so the count starts over here too.
local function onUpdate()
    closeFrame(stats)
    closeFrame(groups)
    depth = 0
end

---Calls `fn(...)` and returns its first result. While recording, the time it takes is charged to
---`key`: a module (a part is charged to its module), or nil for shared code.
---@param key table?
---@param fn function
---@return any
function Profiler.Call(key, fn, ...)
    if not Profiler.recording then
        return (fn(...))
    end
    -- A part of a module (module:NewPart) is a row of its own under the module, like
    -- Profiler.Part; any other owner that stands in for a module is charged to the module.
    if type(key) == "table" and key.module and not key.key then
        key = key.module
    end
    depth = depth + 1
    local level = depth
    inner[level] = 0
    local start = debugprofilestop()
    local result = fn(...)
    local spent = debugprofilestop() - start
    depth = level - 1
    if level > 1 then
        inner[level - 1] = (inner[level - 1] or 0) + spent
    end
    local own = spent - inner[level]
    key = key or SHARED
    local s = entry(stats, key)
    s.total = s.total + own
    s.frame = s.frame + own
    s.calls = s.calls + 1
    local g = entry(groups, key.parent or key.module or key)
    g.total = g.total + own
    g.frame = g.frame + own
    return result
end

---Counts a call to `key` without timing it, for something called thousands of times a second,
---where a stopwatch around each would cost more than the call. Only while recording.
---@param key table
function Profiler.Count(key)
    local s = entry(stats, key)
    s.calls = s.calls + 1
    s.counted = true
    entry(groups, key.parent or key.module or key)
end

---A key for one part of a module's work, listed on the page under its module, so a heavy module
---can show which of its parts the time goes to. The module's row adds up its parts. A module's
---parts made with module:NewPart get rows of their own without this.
---@param module table
---@param label string
---@return table key for Profiler.Call
function Profiler.Part(module, label)
    return { parent = module, label = label }
end

---The module a key belongs to: itself, or the module of a part.
---@param key table
---@return table
function Profiler.ModuleOf(key)
    return key.parent or key.module or key
end

---A function that calls `fn` and, while recording, charges it to `key`: for a module's OnUpdate
---script, timers, and other code that doesn't come through Core.
---@param key table the module
---@param fn function
---@return function
function Profiler.Wrap(key, fn)
    return function(...)
        if Profiler.recording then
            return Profiler.Call(key, fn, ...)
        end
        return fn(...)
    end
end

---Starts recording from nothing.
function Profiler.Start()
    wipe(stats)
    wipe(groups)
    depth = 0
    started, stopped = GetTime(), nil
    Profiler.recording = true
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", onUpdate)
    end
    frame:Show()
end

---Stops recording, keeping what it found.
function Profiler.Stop()
    if not Profiler.recording then
        return
    end
    onUpdate() -- the last frame's sums count toward the worst frame
    Profiler.recording = false
    stopped = GetTime()
    frame:Hide()
end

---Forgets what was recorded; recording goes on from now if it was running.
function Profiler.Reset()
    wipe(stats)
    wipe(groups)
    depth = 0
    started = Profiler.recording and GetTime() or nil
    stopped = nil
end

---Seconds recorded so far, or nil before the first recording.
---@return number?
function Profiler.Elapsed()
    return started and (stopped or GetTime()) - started or nil
end

local function heaviest(a, b)
    return a.total > b.total
end

-- One row of Results from a key's sums.
local function row(key, s, seconds, calls)
    return {
        key = key, total = s.total, peak = s.frame > s.peak and s.frame or s.peak,
        perSecond = seconds > 0 and s.total / seconds or 0,
        callsPerSecond = seconds > 0 and calls / seconds or 0,
        counted = s.counted, -- only counted (Profiler.Count): it has calls but no time
    }
end

---What was recorded, heaviest first: a row for each module (Profiler.SHARED for shared code)
---with its parts' time added in, and the parts in `parts`, heaviest first, with the module's own
---time beside them as `own` (nil without parts). A row is { key, total, peak, perSecond,
---callsPerSecond, counted }, times in ms; a part's key has `label`.
---@return table[]
function Profiler.Results()
    local seconds = Profiler.Elapsed() or 0
    local list, byKey = {}, {}
    for key, g in pairs(groups) do
        local own = stats[key]
        local result = row(key, g, seconds, own and own.calls or 0)
        list[#list + 1] = result
        byKey[key] = result
    end
    for key, s in pairs(stats) do
        local parent = key.parent or key.module
        local result = parent and byKey[parent]
        if result then
            result.parts = result.parts or {}
            result.parts[#result.parts + 1] = row(key, s, seconds, s.calls)
        end
    end
    for _, result in ipairs(list) do
        if result.parts then
            sort(result.parts, heaviest)
            local own = stats[result.key]
            if own then
                result.own = row(result.key, own, seconds, own.calls)
            end
            -- With no calls of its own, the module ran as often as its busiest part.
            if result.callsPerSecond == 0 then
                for _, part in ipairs(result.parts) do
                    if part.callsPerSecond > result.callsPerSecond then
                        result.callsPerSecond = part.callsPerSecond
                    end
                end
            end
        end
    end
    sort(list, heaviest)
    return list
end

---Forever++ as a whole, from the game: its average and its most ms in one frame, lately
---(C_AddOnProfiler), and its memory in KB. Any of them is nil when this client can't say.
---@return number? average
---@return number? peak
---@return number? memory
function Profiler.AddOn()
    local average, peak
    local profiler, metric = C_AddOnProfiler, Enum and Enum.AddOnProfilerMetric
    if profiler and profiler.GetAddOnMetric and metric then
        average = profiler.GetAddOnMetric(ns.name, metric.RecentAverageTime)
        peak = profiler.GetAddOnMetric(ns.name, metric.PeakTime)
    end
    local update = UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
    local get = GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage)
    local memory
    if update and get then
        update()
        memory = get(ns.name)
    end
    return average, peak, memory
end
