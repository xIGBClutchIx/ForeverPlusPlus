-- Flight Timer: how long a flight takes. The game doesn't say, so every flight you take is timed
-- and remembered by the game's flight point IDs (the same IDs Points of Interest uses), one time
-- for each pair of flight points. The next time, a bar shows the time left as you fly, and the
-- flight map's tooltip on a flight point shows how long it will take. Each pair is its own time:
-- flights differ each way, and a flight with stops is not the sum of its parts. Times are saved
-- for the whole account, since a flight is the same for every character.
local _, ns = ...

local ipairs, floor, format, max, min = ipairs, math.floor, string.format, math.max, math.min
local C_TaxiMap, Enum, GetTime, UnitOnTaxi = C_TaxiMap, Enum, GetTime, UnitOnTaxi
local CreateFrame, UIParent, GameTooltip = CreateFrame, UIParent, GameTooltip

local L = ns.L

local module = ns.NewModule("FlightTimer", L.FLIGHTTIMER_DESC, {
    enabled = true,
    bar = true,
    tooltip = true,
    scale = 100, -- percent
    x = 0, -- the bar's offset from the center of the screen
    y = 250,
    -- Seconds by "fromNodeID>toNodeID". Data, not a setting.
    times = {},
})
module.title = L.FLIGHTTIMER_TITLE
module.category = "map"

module.options = {
    { key = "bar", name = L.FLIGHTTIMER_BAR, description = L.FLIGHTTIMER_BAR_DESC },
    { key = "tooltip", name = L.FLIGHTTIMER_TOOLTIP, description = L.FLIGHTTIMER_TOOLTIP_DESC },
    {
        key = "scale",
        name = L.FLIGHTTIMER_SCALE,
        description = L.FLIGHTTIMER_SCALE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
}

local DEFAULT_X, DEFAULT_Y = 0, 250
local WIDTH, HEIGHT = 208, 16 -- about Blizzard's cast bar
local TOO_SHORT = 3 -- seconds; anything shorter wasn't a flight
local WAIT = 10 -- seconds to wait for a flight to start after asking for it

local clock = ns.Text.Clock

-- The flight points ----------------------------------------------------------------------------

-- Mainline's flight master API, at a flight master: slots are what the old API counts by, node
-- IDs are the game's own. Filled when the flight map opens.
local nodeOfSlot, nameOfNode = {}, {}
local current -- the node ID the flight master is at

local function readNodes()
    nodeOfSlot, nameOfNode, current = {}, {}, nil
    if not (C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and GetTaxiMapID) then
        return
    end
    local mapID = GetTaxiMapID()
    for _, node in ipairs(mapID and C_TaxiMap.GetAllTaxiNodes(mapID) or {}) do
        if node.nodeID then
            if node.slotIndex then
                nodeOfSlot[node.slotIndex] = node.nodeID
            end
            nameOfNode[node.nodeID] = node.name
            if Enum.FlightPathState and node.state == Enum.FlightPathState.Current then
                current = node.nodeID
            end
        end
    end
end

-- The times ------------------------------------------------------------------------------------

local function key(from, to)
    return from .. ">" .. to
end

-- How long the flight from one node to another takes, if it has been flown: seconds. Each way and
-- each route is its own time, since flights differ both ways and a chained flight isn't the sum of
-- its stops.
local function estimate(from, to)
    return module.db.times[key(from, to)]
end

-- The flight underway ---------------------------------------------------------------------------

local flight -- { from, to, total, name, asked, started, aborted } from asking a flight master to go

local bar, watcher

local function newBar()
    local hasTemplate = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("TooltipBackdropTemplate")
    -- The same box Blizzard draws tooltips in, with the fill inside it.
    local frame = CreateFrame("Frame", nil, UIParent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    if not hasTemplate and frame.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        frame:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        frame:SetBackdropColor(0, 0, 0, 0.8)
    end
    local fill = CreateFrame("StatusBar", nil, frame)
    fill:SetPoint("TOPLEFT", 4, -4)
    fill:SetPoint("BOTTOMRIGHT", -4, 4)
    fill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    fill:SetStatusBarColor(1, 0.7, 0) -- the cast bar's gold
    fill:SetMinMaxValues(0, 1)
    frame.fill = fill
    frame.name = fill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.name:SetPoint("LEFT", 4, 0)
    frame.name:SetPoint("RIGHT", -44, 0)
    frame.name:SetJustifyH("LEFT")
    frame.name:SetWordWrap(false)
    frame.time = fill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.time:SetPoint("RIGHT", -4, 0)
    frame:Hide()
    return frame
end

local function place()
    bar:SetScale(module.db.scale / 100)
    ns.EditMode.Place(bar, module.db.x, module.db.y)
end

local function fillTo(fraction)
    bar.fill:SetValue(fraction)
end

-- Stops timing and takes the bar down, unless Edit Mode is showing it for placing.
local function cancel()
    flight = nil
    if watcher then
        watcher:Hide()
    end
    if bar and not ns.EditMode.IsActive() then
        bar:Hide()
    end
end

local function showFlight()
    local elapsed = GetTime() - flight.started
    bar.name:SetText(flight.name or "")
    if flight.total then
        local left = max(flight.total - elapsed, 0)
        fillTo(min(elapsed / flight.total, 1))
        bar.time:SetText(clock(left))
    else
        -- A flight not flown before: no length to count down, so the time so far.
        fillTo(1)
        bar.time:SetText(clock(elapsed))
    end
end

local function finish()
    if flight.started and not flight.aborted then
        local elapsed = GetTime() - flight.started
        if elapsed >= TOO_SHORT and flight.from and flight.to then
            module.db.times[key(flight.from, flight.to)] = floor(elapsed + 0.5)
        end
    end
    cancel()
end

local function tick()
    if not flight then
        cancel()
        return
    end
    local now = GetTime()
    if not flight.started then
        if UnitOnTaxi("player") then
            flight.started = now
            if module.db.bar then
                bar:Show()
            end
        elseif now - flight.asked > WAIT then
            cancel() -- never took off
        end
        return
    end
    if not UnitOnTaxi("player") then
        finish()
    elseif bar:IsShown() then
        showFlight()
    end
end

-- Asking a flight master to go to a slot: what the flight is, before it starts.
local function onTake(slot)
    local to = nodeOfSlot[slot]
    if not (to and current) then
        flight = nil
        return
    end
    local total = estimate(current, to)
    flight = {
        from = current, to = to, total = total,
        name = nameOfNode[to], asked = GetTime(),
    }
    watcher:Show()
end

local function onEarlyLanding()
    if flight then
        flight.aborted = true -- the time to somewhere else says nothing about this flight
    end
end

-- The flight map's tooltip ---------------------------------------------------------------------

local adding -- so showing the tooltip again for the new line doesn't add it again

-- The node a tooltip over the flight map is about: the new map's pins carry their node data; the
-- old map's buttons are the slot they're for.
local function nodeOfOwner(owner)
    local data = owner.taxiNodeData
    if data and data.nodeID then
        return data.nodeID
    end
    if owner.nodeID then
        return owner.nodeID
    end
    if TaxiFrame and TaxiFrame:IsShown() and owner.GetID then
        return nodeOfSlot[owner:GetID()]
    end
end

local function onTooltipShow(tooltip)
    if adding or not module.db.tooltip or tooltip ~= GameTooltip then
        return
    end
    if not ((FlightMapFrame and FlightMapFrame:IsShown()) or (TaxiFrame and TaxiFrame:IsShown())) then
        return
    end
    local owner = tooltip:GetOwner()
    local to = owner and nodeOfOwner(owner)
    if not (to and current) or to == current then
        return
    end
    local time = estimate(current, to)
    if not time then
        return
    end
    adding = true
    tooltip:AddLine(format(L.FLIGHTTIMER_TIME, clock(time)),
        1, 1, 1)
    tooltip:Show() -- to fit the new line
    adding = false
end

-- Edit Mode -------------------------------------------------------------------------------------

-- In Edit Mode the bar shows even when nobody is flying, so it can be placed.
local function sample(active)
    if flight and flight.started then
        return
    end
    if active then
        bar.name:SetText(L.FLIGHTTIMER_TITLE)
        fillTo(0.6)
        bar.time:SetText(clock(45))
        bar:Show()
    else
        bar:Hide()
    end
end

local function moved(x, y)
    module.db.x, module.db.y = x, y
end

local function resetPosition()
    module.db.x, module.db.y = DEFAULT_X, DEFAULT_Y
    if bar then
        place()
    end
end

-- What Edit Mode's dialog for the bar offers.
local editModeOptions = {
    onChange = sample,
    reset = resetPosition,
    scale = {
        min = 50, max = 200, step = 10, format = "%d%%",
        get = function() return module.db.scale end,
        set = function(value)
            module.db.scale = value
            place()
        end,
    },
}

module.actions = {
    {
        name = L.FLIGHTTIMER_RESET_POSITION,
        button = L.FLIGHTTIMER_RESET_POSITION_BUTTON,
        description = L.FLIGHTTIMER_RESET_POSITION_DESC,
        fn = resetPosition,
    },
    {
        name = L.FLIGHTTIMER_RESET_TIMES,
        button = L.FLIGHTTIMER_RESET_TIMES_BUTTON,
        description = L.FLIGHTTIMER_RESET_TIMES_DESC,
        confirm = L.FLIGHTTIMER_RESET_TIMES_CONFIRM,
        fn = function()
            module.db.times = {}
            ns.Print(L.FLIGHTTIMER_RESET_TIMES_DONE)
        end,
    },
}

function module:OnEnable()
    if not bar then
        bar = newBar()
        watcher = CreateFrame("Frame", nil, UIParent)
        watcher:Hide()
        local elapsed = 0
        watcher:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            if elapsed >= 0.1 then
                elapsed = 0
                tick()
            end
        end)
    end
    place()
    self:On("TAXIMAP_OPENED", readNodes)
    if TakeTaxiNode then
        self:Hook("TakeTaxiNode", onTake)
    end
    if TaxiRequestEarlyLanding then
        self:Hook("TaxiRequestEarlyLanding", onEarlyLanding)
    end
    self:Hook(GameTooltip, "Show", onTooltipShow)
    self:On("PLAYER_ENTERING_WORLD", cancel) -- a loading screen ends any timing
    ns.EditMode.Register(bar, L.FLIGHTTIMER_TITLE, moved, editModeOptions)
end

function module:OnDisable()
    if bar then
        ns.EditMode.Unregister(bar)
        cancel()
        bar:Hide()
    end
end

function module:OnOptionChanged(option)
    if option == "scale" and bar then
        place()
    end
    if option == "bar" and bar and not self.db.bar and not ns.EditMode.IsActive() then
        bar:Hide()
    end
end
