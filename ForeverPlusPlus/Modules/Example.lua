-- An example module: copy this file to start a new change, add it to ForeverPlusPlus.toc (before
-- Init.lua), and delete this one when you no longer need it.
local _, ns = ...

local module = ns.NewModule("Example", "Says hello when you log in.", {
    enabled = true,
    greeting = "Hello from Forever++!",
})

-- Runs when the module turns on (at login if it's on, or from /fpp toggle).
function module:OnEnable()
    ns.On("PLAYER_ENTERING_WORLD", self.Greet)
end

-- Runs when it turns off. Leave this out if a change can only be undone by /reload (a hook).
function module:OnDisable()
    ns.Off("PLAYER_ENTERING_WORLD", self.Greet)
end

function module.Greet(_, isLogin)
    if isLogin then
        ns.Print(module.db.greeting)
    end
end
