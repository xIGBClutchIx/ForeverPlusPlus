-- The open flight master's flight points, as Mainline's C_TaxiMap.GetAllTaxiNodes lists them on
-- its map. Several modules read them when the flight map opens (TAXIMAP_OPENED); the list is read
-- once per frame and shared, whichever of them asks first.
local _, ns = ...

local GetTime = GetTime

local Taxi = {}
ns.Taxi = Taxi

local nodes, mapID, readAt = {}, nil, nil

---The flight points the open flight master lists (Mainline's node tables: nodeID, slotIndex,
---name, state, position, ...), and the map they're on. Empty when no flight map is open or this
---client can't say. The list is shared: read it, don't change it.
---@return table[] nodes
---@return number? mapID
function Taxi.Nodes()
    local now = GetTime()
    if readAt == now then
        return nodes, mapID
    end
    nodes, mapID, readAt = {}, nil, now
    -- Probe: both are Mainline's.
    if C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and GetTaxiMapID then
        mapID = GetTaxiMapID()
        nodes = mapID and C_TaxiMap.GetAllTaxiNodes(mapID) or nodes
    end
    return nodes, mapID
end
