-- Loaded last: every module has registered, so start them once the player is in the world.
local _, ns = ...

-- Each step through ns.Call: an error in one is reported and the next still runs, so a problem
-- while the modules start can't also cost the player the Settings pages.
ns.On("PLAYER_LOGIN", function()
    ns.Call(ns.Start)
    ns.Call(ns.RegisterSettings)
    ns.Call(ns.API.Fire, "READY") -- other addons can read saved data now
end)
