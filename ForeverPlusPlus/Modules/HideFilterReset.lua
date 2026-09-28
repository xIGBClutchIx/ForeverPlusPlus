-- Hide Filter Reset: hides the reset button on the world map's filter dropdown, which shows
-- whenever a filter is off its default, so players who turn filters off on purpose see it all
-- the time. Idea from Leatrix Maps' "Hide filter reset button"; none of its code.
local _, ns = ...

local ipairs = ipairs
local C_AddOns = C_AddOns

local L = ns.L

local module = ns.NewModule("HideFilterReset", L.HIDEFILTERRESET_DESC, {
    enabled = false,
})
module.title = L.HIDEFILTERRESET_TITLE
module.category = "map"

local MAP_ADDON = "Blizzard_WorldMap"

-- The parts to hide: Mainline's filter dropdown has a ResetButton; older templates had a counter
-- and its banner instead. Probe for each.
local PARTS = { "ResetButton", "FilterCounter", "FilterCounterBanner" }

local parts -- the ones found, once the map has loaded

-- The filter dropdown is one of the map's overlay frames, with no name, so it's found by its parts.
local function findParts()
    local found = {}
    for _, frame in ipairs(WorldMapFrame.overlayFrames or {}) do
        for _, key in ipairs(PARTS) do
            if frame[key] then
                found[#found + 1] = frame[key]
            end
        end
    end
    return found
end

-- Blizzard shows and hides the button as the filters change, so it's faded out and made
-- unclickable instead of hidden, and stays that way whatever Blizzard does.
local function apply()
    local on = module.enabled
    for _, part in ipairs(parts) do
        part:SetAlpha(on and 0 or 1)
        if part.EnableMouse then
            part:EnableMouse(not on)
        end
    end
end

local waiting

local function attach()
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    parts = parts or findParts()
    apply()
end

local function mapLoaded()
    return (not C_AddOns or C_AddOns.IsAddOnLoaded(MAP_ADDON)) and WorldMapFrame
end

function module:OnEnable()
    if mapLoaded() then
        attach()
    else
        waiting = function(_, name)
            if name == MAP_ADDON then
                attach()
            end
        end
        ns.On("ADDON_LOADED", waiting)
    end
end

function module:OnDisable()
    if waiting then
        ns.Off("ADDON_LOADED", waiting)
        waiting = nil
    end
    if parts then
        apply()
    end
end
