-- Arrival: how long until the player reaches something, from how fast the distance to it is
-- really shrinking, not from a run speed: so a mount, a flight, a swim, and a winding road all
-- give a time that's true of how the player is travelling now. An estimator is fed the distance
-- as often as its owner likes (every frame is fine: it keeps one sample each SAMPLE seconds, over
-- the last WINDOW) and answers with the seconds left, or nil while there's nothing honest to say:
-- too little to go on yet, not getting closer, or a rate that's changing too fast to trust.
-- No frames and no game calls; the caller gives the clock.
local _, ns = ...

local setmetatable, abs, floor, max, min = setmetatable, math.abs, math.floor, math.max, math.min

local Arrival = {}
ns.Arrival = Arrival

local SAMPLE = 0.25 -- seconds between the samples kept
local WINDOW = 4 -- seconds of samples the rate is taken over
local MIN_SPAN = 2 -- seconds of samples needed before there's an estimate
local MIN_RATE = 1 -- yards a second; slower than this isn't heading there (walking is 2.5)
local MAX_GAP = 1.5 -- seconds without a sample after which the old ones say nothing
local MAX_SPEED = 100 -- yards a second; a bigger jump is a teleport or a new target
local MAX_SECONDS = 3600 -- an hour away isn't worth a clock
local STEADY = 0.5 -- each half of the window must close at this share of the whole's rate
local DRIFT = 0.03 -- the share of the estimate the shown clock may be off and still just run
local SNAP = 0.25 -- the share it may be off before it's set to the estimate outright
local SNAP_SECONDS = 10 -- and the least that takes, so the last seconds never jump
local HOLD = 3 -- seconds the shown clock keeps running with no estimate

local Estimator = {}
Estimator.__index = Estimator

---A new estimator, with nothing to go on yet.
---@return table
function Arrival.New()
    return setmetatable({ times = {}, yards = {}, count = 0 }, Estimator)
end

---Forgets what it has seen: for a new target.
function Estimator:Reset()
    self.count = 0
    self.seconds = nil
    self.shownSeconds = nil
end

-- The seconds left by the samples kept, or nil.
local function estimate(times, yards, count)
    local span = times[count] - times[1]
    if span < MIN_SPAN then
        return nil
    end
    local rate = (yards[1] - yards[count]) / span
    if rate < MIN_RATE then
        return nil
    end
    -- The first sample at or past the middle of the window splits it in two.
    local middle = times[1] + span / 2
    local mid = 2
    while mid < count - 1 and times[mid] < middle do
        mid = mid + 1
    end
    local early = (yards[1] - yards[mid]) / (times[mid] - times[1])
    local late = (yards[mid] - yards[count]) / (times[count] - times[mid])
    if early < rate * STEADY or late < rate * STEADY then
        return nil -- speeding up, slowing down, or turning: the rate isn't one to count on
    end
    local seconds = yards[count] / rate
    return seconds <= MAX_SECONDS and seconds or nil
end

---Takes the distance to the target now and returns the seconds until the player is there at the
---rate it has been closing, or nil while there's no steady rate. Call it as often as you like.
---@param now number a clock in seconds, such as GetTime()
---@param distance number yards to the target; must be readable, never a secret value
---@return number? seconds
function Estimator:Add(now, distance)
    local times, yards, count = self.times, self.yards, self.count
    if count > 0 then
        local gap = now - times[count]
        if gap < SAMPLE and gap >= 0 then
            return self.seconds
        end
        if gap < 0 or gap > MAX_GAP or abs(distance - yards[count]) > MAX_SPEED * gap then
            count = 0
        end
    end
    -- Drop what's older than the window, keeping the order.
    local first = 1
    while first <= count and now - times[first] > WINDOW do
        first = first + 1
    end
    if first > 1 then
        for i = first, count do
            times[i - first + 1], yards[i - first + 1] = times[i], yards[i]
        end
        count = count - first + 1
    end
    count = count + 1
    times[count], yards[count] = now, distance
    self.count = count
    self.seconds = count >= 3 and estimate(times, yards, count) or nil
    return self.seconds
end

---The estimate as a clock to show: whole seconds that count down, never up, and don't jump about
---as the rate changes with every turn and sidestep. It starts at the estimate and runs with the
---caller's clock. While the two are within DRIFT (or a second) it just runs; farther apart it runs
---faster or stops until they meet; and only a change too big to walk off (SNAP, a mount or a new
---road) sets it to the estimate at once. It keeps running for HOLD seconds without an estimate, so
---a turn doesn't blink it away. Nil with no estimate for longer. Call it after Add, as often.
---@param now number the clock given to Add
---@return number? seconds
function Estimator:Countdown(now)
    local seconds = self.seconds
    local shown = self.shownSeconds
    local dt = shown and now - self.shownAt
    if dt and (dt < 0 or dt > MAX_GAP) then
        shown = nil
    end
    if not seconds then
        if not shown or now - self.estimatedAt > HOLD then
            self.shownSeconds = nil
            return nil
        end
        shown = shown - dt
    else
        self.estimatedAt = now
        local off = shown and seconds - (shown - dt) -- above 0: the clock is ahead of the estimate
        if not off or abs(off) > max(SNAP_SECONDS, seconds * SNAP) then
            shown = seconds
        elseif abs(off) > max(1, seconds * DRIFT) then
            shown = shown - dt + max(-dt, min(dt, off)) -- twice as fast, or stopped
        else
            shown = shown - dt
        end
    end
    self.shownSeconds, self.shownAt = shown, now
    return max(0, floor(shown + 0.5))
end
