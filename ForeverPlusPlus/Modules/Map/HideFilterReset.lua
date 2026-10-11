-- Hide Filter Reset: hides the reset button on the world map's filter dropdown, which shows
-- whenever a filter is off its default, so players who turn filters off on purpose see it all
-- the time. Idea from Leatrix Maps' "Hide filter reset button"; none of its code.
local _, ns = ...

local ipairs = ipairs

local L = ns.L

local module = ns.NewModule("HideFilterReset", L.HIDEFILTERRESET_DESC, {
    enabled = true,
})
module.title = L.HIDEFILTERRESET_TITLE
module.category = "map"

-- The parts to hide: Mainline's filter dropdown has a ResetButton; older templates had a counter
-- and its banner instead. Probe for each.
local PARTS = { "ResetButton", "FilterCounter", "FilterCounterBanner" }

local parts -- the ones found, once the map has loaded
local tookMouse = {} -- part -> whether it took the mouse before we changed it

-- The filter dropdown is one of the map's overlay frames, with no name, so it's found by its parts.
local function findParts(map)
    local found = {}
    for _, frame in ipairs(map.overlayFrames or {}) do
        for _, key in ipairs(PARTS) do
            local part = frame[key]
            if part then
                found[#found + 1] = part
                if part.IsMouseEnabled then
                    tookMouse[part] = part:IsMouseEnabled()
                end
            end
        end
    end
    return found
end

-- Blizzard shows and hides the button as the filters change, so it's faded out and made
-- unclickable instead of hidden, and stays that way whatever Blizzard does. Turned off, each part
-- takes the mouse again only if it did before.
local function apply()
    local on = module.enabled
    for _, part in ipairs(parts) do
        part:SetAlpha(on and 0 or 1)
        if tookMouse[part] ~= nil then
            part:EnableMouse(not on and tookMouse[part])
        end
    end
end

local function attach(map)
    parts = parts or findParts(map)
    apply()
end

function module:OnEnable()
    ns.WorldMap.WhenLoaded(attach)
end

function module:OnDisable()
    ns.WorldMap.Cancel(attach)
    if parts then
        apply()
    end
end
