-- A fresh loaded Core for one spec (the core_* specs), as `local c = T.Core()`: the real Core.lua,
-- Commands.lua and the Lib files Core needs, in an `ns` of their own (`c.ns`, not `T.ns`), against
-- stub frames whose events are fired by hand and a clock for C_Timer that moves only when told.
-- Nothing has logged in yet: a spec makes its modules, or `c.Modules()` for the usual ones, then
-- calls `c.Login()`. This chunk runs in the spec's environment, so its stubs stay in that spec.
local T = ...

local c = {
    heard = {}, -- what `c.count(key)` handlers counted, by key
    refreshed = {}, -- the module names Settings was asked to redraw; a spec may set a new table
    inCombat = false, -- what InCombatLockdown answers
    cvars = { coords = "0" }, -- the client's CVars, for an option that is one of Blizzard's (`cvar`)
    refuse = {}, -- CVars the client won't set: name -> true
}

local frames = {}
local Frame = {}
Frame.__index = Frame
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:RegisterUnitEvent(event, ...) self.events[event] = { ... } end
function Frame:HookScript() end
CreateFrame = function()
    local frame = setmetatable({ scripts = {}, events = {} }, Frame)
    frames[#frames + 1] = frame
    return frame
end

---Fires `event` on every frame registered for it, honoring unit filters as the client would.
function c.fire(event, ...)
    local unit = ...
    for _, frame in ipairs(frames) do
        local reg = frame.events[event]
        local pass = reg == true
        if type(reg) == "table" then
            for _, u in ipairs(reg) do
                pass = pass or u == unit
            end
        end
        if pass then
            frame.scripts.OnEvent(frame, event, ...)
        end
    end
end

---Whether any frame listens for `event`.
function c.registered(event)
    for _, frame in ipairs(frames) do
        if frame.events[event] then
            return true
        end
    end
    return false
end

-- C_Timer on a clock that moves only when `c.wait` says.
local now, pending = 0, {}
C_Timer = {
    NewTimer = function(seconds, fn)
        local handle = { at = now + seconds, fn = fn }
        function handle:Cancel() self.cancelled = true end
        pending[#pending + 1] = handle
        return handle
    end,
}

---Moves the clock on, running the timers that came due.
function c.wait(seconds)
    now = now + seconds
    local due = pending
    pending = {}
    for _, handle in ipairs(due) do
        if handle.at > now then
            pending[#pending + 1] = handle
        elseif not handle.cancelled then
            handle.fn()
        end
    end
end

---A handler that counts its calls in `c.heard[key]`.
function c.count(key)
    return function() c.heard[key] = (c.heard[key] or 0) + 1 end
end

securecallfunction = function(fn, ...) return fn(...) end -- errors fail the run
hooksecurefunc = function() end
InCombatLockdown = function() return c.inCombat end
C_CVar = {
    GetCVar = function(name) return c.cvars[name] end,
    GetCVarDefault = function() return "0" end,
    SetCVar = function(name, value)
        if c.refuse[name] then
            return false
        end
        c.cvars[name] = value
        return true
    end,
}
GetLocale = function() return "enUS" end
C_AddOns = { GetAddOnMetadata = function() return "0.9.0" end }
SlashCmdList = {}
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
strsplit = function(sep, s, limit)
    local parts, from = {}, 1
    while not limit or #parts < limit - 1 do
        local at = s:find(sep, from, true)
        if not at then
            break
        end
        parts[#parts + 1] = s:sub(from, at - 1)
        from = at + #sep
    end
    parts[#parts + 1] = s:sub(from)
    return unpack(parts)
end
UnitGUID = function() return "Player-1-A" end

local core = {}
local files = { "Core", "Commands", "Locales/enUS/Core", "Lib/Presets", "Lib/Store", "Lib/Profiles", "Lib/Frames",
    "Lib/Players", "Lib/CVars", "Lib/Text", "Lib/Secret", "Lib/Plugins" }
for _, path in ipairs(files) do
    T.load(path, core)
end
core.GameData = { Prune = function() end }
core.Profiler = { recording = false, Wrap = function(_, fn) return fn end }
core.RefreshSetting = function(name) c.refreshed[#c.refreshed + 1] = name end -- Settings.lua's
core.OpenSettings = function() return true end
c.ns = core

---Logs in: Core reads the saved variables and turns on the modules made so far.
---@param db? table what ForeverPlusPlusDB holds from the last session (nothing by default)
function c.Login(db)
    ForeverPlusPlusDB = db
    ForeverPlusPlusCharDB = nil
    core.Start()
end

---The modules most core specs act on. Call it before `c.Login()`.
---@return table m the modules and parts by name, their timers, and what their callbacks recorded
function c.Modules()
    local Frames, count = core.Frames, c.count
    local m = {}

    -- A module with a checkbox and a dropdown option, each driving events through OnWhile.
    local plain = core.NewModule("Plain", "test", { enabled = true, loud = false, mode = "a" })
    plain.options = {
        { key = "loud", name = "Loud" },
        { key = "mode", name = "Mode", choices = { { "a" }, { "b" }, { "off" } } },
    }
    plain:OnWhile("loud", { PLAYER_MONEY = count("money") })
    plain:OnWhile("mode", { BAG_UPDATE = count("bag") })
    plain:OnWhile(function(db) return db.loud and db.mode == "b" end, { ZONE_CHANGED = count("zone") })
    function plain:OnEnable()
        self:On("PLAYER_LEVEL_UP", count("level"))
    end
    m.plain = plain
    m.plainTimer = Frames.Timer(plain)
    m.plainQueue = Frames.Coalesce(count("coalesced"), 0.1, plain)

    -- A module made of a checkbox part and a dropdown part.
    local host = core.NewModule("Host", "test", { enabled = true })
    local check = host:NewPart({ key = "extra", name = "Extra", section = "S1" }, { loud2 = false })
    check:AddOptions({ { key = "loud2", name = "Loud" } })
    check:OnWhile("loud2", { PLAYER_XP_UPDATE = count("xp") })
    local WHERE = { { "off" }, { "top" }, { "bottom" } }
    local drop = host:NewPart({ key = "where", name = "Where", section = "S2", choices = WHERE },
        { where = "bottom" })
    local dropCalls = { enable = 0, disable = 0, changed = {} }
    function drop:OnEnable() dropCalls.enable = dropCalls.enable + 1 end
    function drop:OnDisable() dropCalls.disable = dropCalls.disable + 1 end
    function drop:OnOptionChanged(key) dropCalls.changed[#dropCalls.changed + 1] = key end
    drop:OnWhile("where", { MAIL_SHOW = count("mail") })
    m.host, m.check, m.drop, m.dropCalls = host, check, drop, dropCalls
    m.dropTimer = Frames.Timer(drop)
    m.side = host:NewPart({ key = "side", name = "Side", section = "S3", choices = WHERE })

    -- A module with a checkbox that is one of Blizzard's settings. A spec may set a new
    -- `m.coordsHeard` table.
    local coords = core.NewModule("Coords", "test", { enabled = true, player = true })
    coords.options = { { key = "player", name = "Player", cvar = "coords" } }
    m.coordsHeard = {}
    coords.OnOptionChanged = function(_, key) m.coordsHeard[#m.coordsHeard + 1] = key end
    m.coords = coords

    -- A locked module (one the game broke) stays off, even saved as on.
    local locked = core.NewModule("Locked", "test", { enabled = true })
    locked.locked = true
    m.lockedEnables = 0
    function locked:OnEnable() m.lockedEnables = m.lockedEnables + 1 end
    m.locked = locked

    -- A tool that is always on, with an option, for switching profiles.
    local tool = core.NewModule("Tool", "test", { enabled = true, mode = "a" })
    tool.alwaysOn = true
    tool.options = { { key = "mode", name = "Mode", choices = { { "a" }, { "b" } } } }
    m.toolHeard = {}
    tool.OnOptionChanged = function(_, key) m.toolHeard[#m.toolHeard + 1] = key end
    m.tool = tool

    return m
end

return c
