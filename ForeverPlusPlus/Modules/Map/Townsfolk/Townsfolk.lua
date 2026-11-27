-- Townsfolk: icons on the world map for the people and places a town has, as the minimap's
-- tracking menu names them: innkeepers, mailboxes, bankers, auctioneers, stable masters,
-- battlemasters, the player's class trainers, the trainers of their professions (or of every
-- profession), repairers, and food, reagent, poison, and ammunition vendors. Each kind has its own
-- checkbox; the world map's filter menu has the same ones. Who stands where comes from the
-- QuestieDB addon at run time (Lib/QuestieDB.lua), never copied here: the game has no API for it.
-- Needs QuestieDB: without it the module is red and locked off in the list, saying to get it.
--
-- This file holds the module, its options, and the icons; Index.lua reads QuestieDB into a list
-- of townsfolk on each map. They share module.internal.
local _, ns = ...

local ipairs, select = ipairs, select
local UnitClass = UnitClass

local L = ns.L
local QuestieDB, MapPins, MapTooltip = ns.QuestieDB, ns.MapPins, ns.MapTooltip

local module = ns.NewModule("Townsfolk", L.TOWNSFOLK_DESC, {
    enabled = false,
    pins = true, -- the world map's filter menu switches this one
    size = 80, -- percent of PIXELS
    innkeeper = true,
    mailbox = true,
    banker = true,
    auctioneer = true,
    stable = false,
    battlemaster = false,
    class = true, -- the player's own class's trainers
    profession = true, -- the trainers of the player's professions
    allProfessions = false, -- and of every other profession
    repair = true,
    food = false,
    reagent = false,
    poison = false,
    ammo = false,
})
module.title = L.TOWNSFOLK_TITLE
module.presets = { developer = { enabled = true, options = { mailbox = false, repair = false } } }
module.category = "map"
module.added = "1.10.0"
module.internal = {}
local internal = module.internal

-- Red and locked off without QuestieDB, red with a version we don't read, a notice saying which.
QuestieDB.Require(module)
module.notice[#module.notice + 1] = { text = L.TOWNSFOLK_NOTICE, description = L.TOWNSFOLK_NOTICE_DESC }

local PIXELS = 16 -- an icon's size on screen at 100%

-- Each kind, in the order an NPC of several kinds is drawn as (the first that shows) and the
-- filter menu lists them: its checkbox, and its icon, the minimap's tracking icon for it
-- (UiTextureAtlasMember, wago.tools, build 1.60.1.71139; Unverified in game). An icon the client
-- lacks falls back to a plain ball.
local FALLBACK = "Vehicle-TempleofKotmogu-CyanBall"
local KINDS = {
    { key = "innkeeper", name = L.TOWNSFOLK_INNKEEPER, desc = L.TOWNSFOLK_INNKEEPER_DESC, atlas = "innkeeper" },
    { key = "mailbox", name = L.TOWNSFOLK_MAILBOX, desc = L.TOWNSFOLK_MAILBOX_DESC, atlas = "mailbox" },
    { key = "banker", name = L.TOWNSFOLK_BANKER, desc = L.TOWNSFOLK_BANKER_DESC, atlas = "banker" },
    { key = "auctioneer", name = L.TOWNSFOLK_AUCTIONEER, desc = L.TOWNSFOLK_AUCTIONEER_DESC, atlas = "auctioneer" },
    { key = "stable", name = L.TOWNSFOLK_STABLE, desc = L.TOWNSFOLK_STABLE_DESC, atlas = "stablemaster" },
    { key = "battlemaster", name = L.TOWNSFOLK_BATTLEMASTER, desc = L.TOWNSFOLK_BATTLEMASTER_DESC,
        atlas = "battlemaster" },
    { key = "class", name = L.TOWNSFOLK_CLASS, desc = L.TOWNSFOLK_CLASS_DESC, atlas = "class", trainer = true },
    { key = "profession", name = L.TOWNSFOLK_PROFESSION, desc = L.TOWNSFOLK_PROFESSION_DESC,
        atlas = "profession", trainer = true },
    { key = "repair", name = L.TOWNSFOLK_REPAIR, desc = L.TOWNSFOLK_REPAIR_DESC, atlas = "repair" },
    { key = "food", name = L.TOWNSFOLK_FOOD, desc = L.TOWNSFOLK_FOOD_DESC, atlas = "food" },
    { key = "reagent", name = L.TOWNSFOLK_REAGENT, desc = L.TOWNSFOLK_REAGENT_DESC, atlas = "reagents" },
    { key = "poison", name = L.TOWNSFOLK_POISON, desc = L.TOWNSFOLK_POISON_DESC, atlas = "poisons" },
    { key = "ammo", name = L.TOWNSFOLK_AMMO, desc = L.TOWNSFOLK_AMMO_DESC, atlas = "ammunition" },
}

-- Options ----------------------------------------------------------------------------------------

-- The first two go under Options; then a section for each group of kinds.
local SERVICES, TRAINERS, VENDORS = L.TOWNSFOLK_SECTION_SERVICES, L.TOWNSFOLK_SECTION_TRAINERS,
    L.TOWNSFOLK_SECTION_VENDORS
local SECTION = {
    innkeeper = SERVICES, mailbox = SERVICES, banker = SERVICES, auctioneer = SERVICES,
    stable = SERVICES, battlemaster = SERVICES, class = TRAINERS, profession = TRAINERS,
    repair = VENDORS, food = VENDORS, reagent = VENDORS, poison = VENDORS, ammo = VENDORS,
}

local options = {
    { key = "pins", name = L.TOWNSFOLK_PINS, description = L.TOWNSFOLK_PINS_DESC },
    MapPins.SizeOption("size", nil, { requires = "pins" }),
}
for _, kind in ipairs(KINDS) do
    options[#options + 1] = { key = kind.key, name = kind.name, description = kind.desc,
        requires = "pins", section = SECTION[kind.key] }
    if kind.key == "profession" then
        options[#options + 1] = { key = "allProfessions", name = L.TOWNSFOLK_ALL_PROFESSIONS,
            description = L.TOWNSFOLK_ALL_PROFESSIONS_DESC, requires = "profession", section = TRAINERS }
    end
end
module.options = options

-- Drawing ----------------------------------------------------------------------------------------

local function atlasOf(kind)
    if not kind.found then
        kind.found = MapPins.Atlas(kind.atlas, FALLBACK)
    end
    return kind.found
end

-- Whether an entry's trainer is one for the player: their class's, or a profession they have (or
-- any profession, with Every Profession on).
local function forPlayer(entry, key, db)
    if key == "class" then
        return entry.class == select(2, UnitClass("player"))
    end
    if key == "profession" then
        return db.allProfessions or ns.Professions.Rank(entry.line) ~= nil
    end
    return true
end

-- The kind an entry shows as, or nil when none of its kinds is on: the first one in KINDS order.
local function kindOf(entry, db)
    for _, kind in ipairs(KINDS) do
        if entry.kinds[kind.key] and db[kind.key] and forPlayer(entry, kind.key, db) then
            return kind
        end
    end
end

-- Whether the player's side can use an NPC: friendly to it, or to both. Mailboxes have no side.
local function friendly(entry, side)
    local to = entry.friendly
    if entry.object then
        return true
    end
    return to ~= nil and (to == "AH" or to == side)
end

local function fill(mapID, add)
    local list = internal.byMap[mapID]
    if not list then
        return
    end
    local db = module.db
    local side = ns.WorldMap.PlayerSide()
    local size = PIXELS * db.size / 100
    for _, spot in ipairs(list) do
        local entry = spot.entry
        local kind = friendly(entry, side) and kindOf(entry, db)
        if kind then
            -- The name, its kind at the right unless that's the name (a mailbox), and its title
            -- under it when that says more (a trainer's "Expert Blacksmith"; an innkeeper's title
            -- is only "Innkeeper").
            local name, title = entry.name or kind.name, entry.title
            add(spot.x, spot.y, {
                atlas = atlasOf(kind), size = size, title = name,
                kind = name ~= kind.name and kind.name or nil,
                lines = title and title ~= kind.name and { MapTooltip.Detail(title) } or nil,
                waypoint = true,
            })
        end
    end
end

local layer

local function apply()
    if not layer then
        return
    end
    if module.enabled and module.db.pins and internal.ready then
        layer:Enable()
        layer:Refresh()
    else
        layer:Disable()
    end
end
internal.Changed = apply

-- A profession learned or dropped changes which trainers show.
module:OnWhile(function(db)
    return db.pins and db.profession and not db.allProfessions
end, { SKILL_LINES_CHANGED = ns.Frames.Coalesce(apply, 1, module) })

-- The world map's filter menu ----------------------------------------------------------------------
-- A Townsfolk checkbox after Blizzard's own entries, the same switch as Show on World Map in
-- Settings, with a submenu of the kinds, the same switches as their checkboxes.
local MENU_KINDS = {}
for i, kind in ipairs(KINDS) do
    MENU_KINDS[i] = {
        name = kind.name,
        get = function()
            return module.db[kind.key]
        end,
        set = function(on)
            ns.SetOption(module.name, kind.key, on)
        end,
    }
end

-- Under the Forever++ title (Lib/WorldMap's AddFilter), after Gathering Map's, while Townsfolk is
-- on.
ns.WorldMap.AddFilter(4, function()
    return module.enabled and true or false
end, function(root)
    ns.WorldMap.FilterLayer(root, L.TOWNSFOLK_TITLE, function()
        return module.db.pins
    end, function(on)
        ns.SetOption(module.name, "pins", on)
    end, MENU_KINDS)
end)

-- Starting and stopping ----------------------------------------------------------------------------

local function start()
    if module.enabled then
        internal.Build()
    end
end

function module:OnEnable()
    layer = layer or MapPins.New(fill)
    QuestieDB.OnReady(start)
end

function module:OnDisable()
    QuestieDB.Cancel(start)
    internal.Reset()
    if layer then
        layer:Disable()
    end
end

function module:OnOptionChanged()
    apply()
end
