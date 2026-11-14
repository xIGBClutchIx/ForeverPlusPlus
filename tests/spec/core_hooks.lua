-- Core: a module's tooltip hooks, made once and doing nothing while it's off.
local T = ...
local eq = T.eq

local c = T.Core()
local core = c.ns
local plain = c.Modules().plain
c.Login()

-- module:TooltipLinePreCall hooks once, passes on what `fn` returns (true leaves the line
-- out), and does nothing while the module is off. A tooltip type of the same number is a
-- separate hook.
plain:TooltipLinePreCall(18, function() end) -- no TooltipDataProcessor: nothing, no error
local linePre, post = {}, {}
TooltipDataProcessor = {
    AddLinePreCall = function(kind, fn) linePre[#linePre + 1] = { kind, fn } end,
    AddTooltipPostCall = function(kind, fn) post[#post + 1] = { kind, fn } end,
}
local skipLine = function(_, lineData) return lineData.skip end
plain:TooltipLinePreCall(18, skipLine)
plain:TooltipLinePreCall(18, skipLine)
plain:TooltipPostCall(18, skipLine)
eq(#linePre .. "," .. #post, "1,1", "hooks: a line pre call is hooked once, apart from post calls")
eq(linePre[1][1], 18, "hooks: for its line type")
eq(linePre[1][2]({}, { skip = true }), true, "hooks: a line pre call's true comes back")
eq(linePre[1][2]({}, { skip = false }), false, "hooks: and its false")
core.SetEnabled("Plain", false)
eq(linePre[1][2]({}, { skip = true }), nil, "hooks: a line pre call does nothing while off")
core.SetEnabled("Plain", true)
