-- Debug: the Debug page under Forever++ in Settings (drawn by Settings/Debug.lua), with every
-- module's debug options and buttons, Show Tags, and the testing tools (Self Test, Gear Probe,
-- Screenshots). While it's off the page and those tools' commands are gone, and every debug option
-- is back at its default, so nothing set there goes on working out of sight.
local _, ns = ...

local ipairs, C_Timer = ipairs, C_Timer
local L = ns.L

local module = ns.NewModule("Debug", L.DEBUG_DESC, { enabled = false })
module.title = L.DEBUG
module.category = "tools"
module.added = "0.10.0"

-- Puts every module's debug options back to their defaults, and Show Tags off.
local function resetDebugOptions()
    for _, name in ipairs(ns.order) do
        local other = ns.modules[name]
        for _, option in ipairs(other.options or {}) do
            if option.debug and other.db and other.db[option.key] ~= other.defaults[option.key] then
                ns.SetOption(name, option.key, other.defaults[option.key])
                ns.RefreshSetting(name)
            end
        end
    end
    if ns.db and ns.db.showTags then
        ns.db.showTags = nil
        local S = ns.SettingsUI
        if S and S.markNew and S.refreshAll then
            S.markNew()
            S.refreshAll()
        end
    end
end

-- Off at login: once every module has loaded its settings, anything a debug option still has on
-- from before goes back to its default.
function module:OnLoad()
    if not self.db.enabled and C_Timer then
        C_Timer.After(0, function()
            if not module.enabled then
                resetDebugOptions()
            end
        end)
    end
end

function module:OnDisable()
    resetDebugOptions()
end
