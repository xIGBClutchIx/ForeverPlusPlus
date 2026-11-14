-- Core and Lib/Frames.lua: a window's saved size, and timers a module or a part owns.
local T = ...
local eq = T.eq

local c = T.Core()
local core, wait, heard = c.ns, c.wait, c.heard
local Frames = core.Frames
local m = c.Modules()
local plainTimer, plainQueue, dropTimer = m.plainTimer, m.plainQueue, m.dropTimer
c.Login()

-- A window's saved size: kept within its bounds, the default when none (or junk) was saved.
eq(Frames.WindowSize(nil, 640, 480, 1200), 640, "window: no saved size is the default")
eq(Frames.WindowSize("wide", 640, 480, 1200), 640, "window: nor is one that isn't a number")
eq(Frames.WindowSize(700, 640, 480, 1200), 700, "window: a saved size is kept")
eq(Frames.WindowSize(100, 640, 480, 1200), 480, "window: not below the least")
eq(Frames.WindowSize(5000, 640, 480, 1200), 1200, "window: nor above the most")
eq(Frames.WindowSize(5000, 640), 5000, "window: no bounds, no clamp")

-- Owned timers stop with the module, and don't run while it's off.
local ran = 0
plainTimer:Start(1, function() ran = ran + 1 end)
plainQueue()
core.SetEnabled("Plain", false)
eq(plainTimer:IsPending(), false, "lifecycle: module off: timer cancelled")
wait(2)
eq(ran, 0, "lifecycle: cancelled timer didn't run")
eq(heard.coalesced, nil, "lifecycle: cancelled Coalesce didn't run")
plainTimer:Start(1, function() ran = ran + 1 end)
plainQueue()
wait(2)
eq(ran, 0, "lifecycle: a timer doesn't run while its module is off")
eq(heard.coalesced, nil, "lifecycle: a Coalesce doesn't run while its module is off")
core.SetEnabled("Plain", true)
plainTimer:Start(1, function() ran = ran + 1 end)
plainQueue()
plainQueue()
wait(2)
eq(ran, 1, "lifecycle: timer runs while on")
eq(heard.coalesced, 1, "lifecycle: Coalesce runs once while on")

-- A part's timer stops when its part turns off.
dropTimer:Start(1, function() ran = ran + 10 end)
core.SetOption("Host", "where", "off")
wait(2)
eq(ran, 1, "lifecycle: a part's timer stops with the part")
