-- Arrival: the time left from how fast a distance is closing, and when it says nothing.
local T = ...
local eq = T.eq

local ns = {}
T.load("Lib/Arrival", ns)
local Arrival = ns.Arrival

-- Feeds `est` a sample every `step` seconds from `from` to `to`, the distance given by `at(t)`,
-- and returns the last answer.
local function run(est, from, to, step, at)
    local seconds
    local t = from
    while t <= to + 1e-9 do
        seconds = est:Add(t, at(t))
        t = t + step
    end
    return seconds
end

local function near(got, want, name)
    eq(got ~= nil and math.abs(got - want) < 0.01, true, name .. " (" .. tostring(got) .. ")")
end

do -- a steady run: 7 yards a second from 700 yards
    local est = Arrival.New()
    local function running(t)
        return 700 - 7 * t
    end
    eq(run(est, 0, 1.75, 0.25, running), nil, "arrival: nothing before two seconds of samples")
    near(run(est, 2, 2, 0.25, running), (700 - 14) / 7, "arrival: a steady run after two seconds")
    near(run(est, 2.25, 10, 0.25, running), 90, "arrival: the window slides with the run")
end

do -- fed every frame, it keeps a sample a quarter second apart and answers the same between
    local est = Arrival.New()
    local seconds = run(est, 0, 5, 0.03, function(t)
        return 500 - 14 * t
    end)
    eq(seconds ~= nil and math.abs(seconds - (500 - 14 * 5) / 14) < 0.5, true,
        "arrival: every frame gives the same time (" .. tostring(seconds) .. ")")
    eq(est.count <= 18, true, "arrival: it keeps only the window's samples (" .. est.count .. ")")
    eq(est:Add(5.01, 0), seconds, "arrival: a sample too soon after the last is left out")
end

do -- standing still, and moving away
    local est = Arrival.New()
    eq(run(est, 0, 6, 0.25, function()
        return 300
    end), nil, "arrival: standing still")
    est:Reset()
    eq(run(est, 0, 6, 0.25, function(t)
        return 300 + 7 * t
    end), nil, "arrival: moving away")
    est:Reset()
    eq(run(est, 0, 6, 0.25, function(t)
        return 300 - 0.5 * t
    end), nil, "arrival: creeping closer is not heading there")
end

do -- an unsteady rate: stopped, then running
    local est = Arrival.New()
    local function stopAndGo(t)
        return t < 10 and 400 or 400 - 7 * (t - 10)
    end
    eq(run(est, 0, 11.5, 0.25, stopAndGo), nil, "arrival: just set off, not steady yet")
    near(run(est, 11.75, 16, 0.25, stopAndGo), (400 - 42) / 7, "arrival: steady once it has run")
    -- Then stops: the late half of the window stops closing.
    eq(run(est, 16.25, 18.5, 0.25, function()
        return 358
    end), nil, "arrival: stopped")
end

do -- a gap, a jump, a clock that went back, and Reset start it over
    local function running(t)
        return 700 - 7 * t
    end
    local est = Arrival.New()
    run(est, 0, 5, 0.25, running)
    eq(est:Add(8, running(8)), nil, "arrival: a gap in the samples starts over")
    eq(est.count, 1, "arrival: only the sample after the gap is kept")
    near(run(est, 8.25, 11, 0.25, running), (700 - 77) / 7, "arrival: and it finds the rate again")
    eq(est:Add(11.25, 200), nil, "arrival: a jump no travel explains starts over")
    run(est, 11.5, 14, 0.25, function(t)
        return 200 - 7 * (t - 11.25)
    end)
    eq(est:Add(3, 150), nil, "arrival: a clock that went back starts over")
    run(est, 3.25, 6, 0.25, function(t)
        return 150 - 7 * (t - 3)
    end)
    eq(est.seconds ~= nil, true, "arrival: an estimate before Reset")
    est:Reset()
    eq(est:Add(6.25, 120), nil, "arrival: Reset forgets it")
end

do -- too far to be worth a clock
    local est = Arrival.New()
    eq(run(est, 0, 5, 0.25, function(t)
        return 30000 - 7 * t
    end), nil, "arrival: more than an hour away")
end

do -- the clock to show counts down by the second and ignores small changes in the estimate
    local est = Arrival.New()
    eq(est:Countdown(0), nil, "arrival: no clock without an estimate")
    est.seconds = 400.4
    eq(est:Countdown(10), 400, "arrival: the clock starts at the estimate")
    est.seconds = 396 -- 3.4 seconds off what the clock says a second later: within 3%
    eq(est:Countdown(11), 399, "arrival: the clock counts down a second at a time")
    est.seconds = 405
    eq(est:Countdown(12), 398, "arrival: a small change in the estimate doesn't move the clock")
    est.seconds = 350 -- the player sped up
    eq(est:Countdown(13), 350, "arrival: a big change sets the clock to the estimate")
    eq(est:Countdown(14.2), 349, "arrival: and it counts down from there")
    est.seconds = 10
    eq(est:Countdown(15), 10, "arrival: near the end")
    est.seconds = 7.5 -- more than a second off the 9 it would say
    eq(est:Countdown(16), 8, "arrival: near the end the clock stays within a second of the estimate")
    est.seconds = nil
    eq(est:Countdown(17), nil, "arrival: no estimate, no clock")
    est.seconds = 200
    eq(est:Countdown(30), 200, "arrival: a new estimate starts a new clock")
    est:Reset()
    est.seconds = 90
    eq(est:Countdown(31), 90, "arrival: a reset forgets the clock")
end
