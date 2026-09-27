-- Shared nameplate plumbing for modules: which nameplates are on screen, the parts of a Forever
-- nameplate by name, and whether a unit is casting. It listens to events only while at least one
-- module has registered, so it costs nothing otherwise.
--
--   ns.Nameplates.Register(owner, {
--       OnAdded = function(unit, frame) end,   -- a plate appeared (frame = plate.UnitFrame)
--       OnRemoved = function(unit, frame) end, -- it went away; undo changes, plates are pooled
--       OnCast = function(unit, casting) end,  -- a cast or channel started or ended
--   })
--
-- Friendly plates in instances are forbidden to addons and never show up here.
local _, ns = ...

local pairs, next, type, C_NamePlate = pairs, next, type, C_NamePlate
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo

local Nameplates = {}
ns.Nameplates = Nameplates

local users = {} -- owner -> handlers
local frames = {} -- nameplate unit -> its UnitFrame, while on screen
local casting = {} -- nameplate unit -> true while casting

-- Cast events -> whether the unit is casting afterwards. Only the event is trusted: the cast
-- itself can be secret.
local CAST_EVENTS = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_STOP = false,
    UNIT_SPELLCAST_CHANNEL_STOP = false,
}

local function dispatch(method, ...)
    for _, handlers in pairs(users) do
        if handlers[method] then
            handlers[method](...)
        end
    end
end

local function frameFor(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    return plate and plate.UnitFrame
end

local function onEvent(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local frame = frameFor(unit)
        frames[unit], casting[unit] = frame, nil
        if frame then
            dispatch("OnAdded", unit, frame)
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        -- Remembered from when it was added, since the plate may already be gone.
        local frame = frames[unit]
        frames[unit], casting[unit] = nil, nil
        if frame then
            dispatch("OnRemoved", unit, frame)
        end
    elseif frames[unit] then
        local now = CAST_EVENTS[event]
        casting[unit] = now or nil
        dispatch("OnCast", unit, now)
    end
end

local EVENTS = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }
for event in pairs(CAST_EVENTS) do
    EVENTS[#EVENTS + 1] = event
end

-- Picks up the plates already on screen.
local function scan()
    for _, plate in pairs(C_NamePlate.GetNamePlates()) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit and plate.UnitFrame then
            frames[unit] = plate.UnitFrame
        end
    end
end

---Starts calling `handlers` for nameplate changes, first with OnAdded for every plate on screen.
---@param owner any a key for Unregister, usually the module
---@param handlers table OnAdded, OnRemoved, OnCast (all optional)
function Nameplates.Register(owner, handlers)
    if users[owner] then
        return
    end
    if not next(users) then
        for _, event in pairs(EVENTS) do
            ns.On(event, onEvent)
        end
        scan()
    end
    users[owner] = handlers
    if handlers.OnAdded then
        for unit, frame in pairs(frames) do
            handlers.OnAdded(unit, frame)
        end
    end
end

---Stops calling `owner`'s handlers, first with OnRemoved for every plate on screen.
---@param owner any
function Nameplates.Unregister(owner)
    local handlers = users[owner]
    if not handlers then
        return
    end
    users[owner] = nil
    if handlers.OnRemoved then
        for unit, frame in pairs(frames) do
            handlers.OnRemoved(unit, frame)
        end
    end
    if not next(users) then
        for _, event in pairs(EVENTS) do
            ns.Off(event, onEvent)
        end
        frames, casting = {}, {}
    end
end

---Calls `fn(unit, frame)` for every plate on screen (only while something is registered).
---@param fn fun(unit: string, frame: table)
function Nameplates.ForEach(fn)
    for unit, frame in pairs(frames) do
        fn(unit, frame)
    end
end

---Whether the unit is casting or channeling. A start event is needed, and the cast API has to
---agree, so a stop event that never came (an interrupt, a plate that went away) doesn't leave it
---stuck on. The API's result is only tested for nil, which is safe even when it's secret.
---@param unit string
---@return boolean
function Nameplates.IsCasting(unit)
    if not casting[unit] then
        return false
    end
    local cast = UnitCastingInfo and UnitCastingInfo(unit)
    local channel = UnitChannelInfo and UnitChannelInfo(unit)
    if type(cast) == "nil" and type(channel) == "nil" then
        casting[unit] = nil
        return false
    end
    return true
end

---Whether Blizzard is drawing a cast bar on this plate right now. Friendly plates can hide cast
---bars, so casting alone doesn't mean one is there. `castBar` is Parts(frame).castBar, a container
---whose children are the bars; a visibility we can't read counts as hidden.
---@param castBar table?
---@return boolean
function Nameplates.IsCastBarShown(castBar)
    if not castBar then
        return false
    end
    local children = { castBar:GetChildren() }
    if #children == 0 then
        local shown = castBar:IsVisible()
        return ns.IsReadable(shown) and shown or false
    end
    for i = 1, #children do
        local shown = children[i]:IsVisible()
        if ns.IsReadable(shown) and shown then
            return true
        end
    end
    return false
end

---The parts of a nameplate's UnitFrame, under the names Forever uses (build 70009). Any may be
---nil on another build, so check before use.
---@param frame table plate.UnitFrame
---@return table parts plate, name, container (the health bar's frame), healthBar, level, levelDiff, castBar
function Nameplates.Parts(frame)
    return {
        -- The nameplate itself, which the game centers on the unit. The UnitFrame inside it may
        -- not be centered, so center anything meant to sit over the unit on this.
        plate = frame:GetParent() or frame,
        name = frame.name or frame.Name,
        container = frame.HealthBarsContainer or frame.healthBar,
        healthBar = frame.healthBar,
        level = frame.LevelFrame, -- Forever-only: the level badge at the bar's end
        levelDiff = frame.PlayerLevelDiffFrame,
        castBar = frame.CastBarsContainer,
    }
end
