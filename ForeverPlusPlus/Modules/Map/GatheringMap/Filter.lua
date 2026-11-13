-- Gathering Map in the world map's filter menu (the funnel at its top right): a Gathering Map
-- checkbox under the Forever++ title, the same switch as Show on World Map, with a submenu of a
-- checkbox for Herbs, Ore, Treasure, and Fishing Pools. Those are the same switches as the kinds'
-- checkboxes on the Gathering Map page, saved for each character. A kind this character doesn't
-- have the profession for, with Only My Professions on, is greyed out, its tooltip saying why:
-- checking it would show nothing.
local _, ns = ...

local ipairs = ipairs

local L = ns.L
local Professions = ns.Professions

local module = ns.modules.GatheringMap
local internal = module.internal

local KINDS = internal.KINDS -- the kinds the menu lists, in order, with the skill line of each

-- The submenu's rows, made each time the menu opens: which kinds are greyed depends on the
-- character's professions and Only My Professions.
local function kinds()
    local db = module.db
    local list = {}
    for i, kind in ipairs(KINDS) do
        local usable = not (db.onlyMine and kind.line) or Professions.Rank(kind.line) ~= nil
        list[i] = {
            name = kind.name,
            disabled = not usable and L.GATHERINGMAP_FILTER_NO_SKILL or nil,
            get = function()
                return not db.hiddenKinds[kind.kind]
            end,
            set = function(on)
                db.hiddenKinds[kind.kind] = not on or nil
                internal.Changed(nil)
            end,
        }
    end
    return list
end

-- Under the Forever++ title (Lib/WorldMap's AddFilter), after World Map's and Quest Pins', while
-- Gathering Map is on.
ns.WorldMap.AddFilter(3, function()
    return module.enabled and true or false
end, function(root)
    ns.WorldMap.FilterLayer(root, L.GATHERINGMAP_TITLE, function()
        return module.db.worldMap
    end, function(on)
        ns.SetOption(module.name, "worldMap", on)
    end, kinds())
end)
