-- QuestieDB: the one place Forever++ reads the QuestieDB addon's quest, NPC, item, and world object
-- data, through its public API (`LibQuestieDB`) at run time. We ship none of its data or code, so a
-- module that needs it is off by default and says so with `QuestieDB.Notices()`.
--
-- Everything here is read only: we never register Corrections, change its locale, or drop its
-- caches, since Questie and other addons share the same tables. Every call into it is protected,
-- so a change on its side returns nil instead of an error, and `Problem()` says when the installed
-- version doesn't have the shape we expect. What we return is our own plain tables, never its.
--
-- Its coordinates are 0-100 percents keyed by AreaTable IDs; ours are 0-1 on a uiMapID, as
-- ns.WorldMap's. The area-to-map table is QuestieDB's own support data. docs/questiedb.md has what
-- its API offers and how each shape here comes from it.
--
-- It costs nothing until a module asks: nothing is listened to at load, and the zone and drop
-- tables are read the first time something wants them.
local _, ns = ...

local type, pairs, ipairs, pcall, next = type, pairs, ipairs, pcall, next
local loadstring, setfenv = loadstring, setfenv
local floor, min, sort = math.floor, math.min, table.sort

local L = ns.L

local QuestieDB = {}
ns.QuestieDB = QuestieDB

QuestieDB.ADDON = "QuestieDB" -- its folder and TOC name; the baked QuestieDB_Forever.toc is the same addon
QuestieDB.CONTRACT = 1 -- the contract we read against: entity reads only (docs/questiedb.md)

-- The kinds of data, as QuestieDB names its entity tables.
local KINDS = { Quest = true, Npc = true, Item = true, Object = true }

-- The fields we read from each kind. Every one is checked against its schema before we trust the
-- API, so a field renamed on their side is a Problem() rather than a quiet nil.
local FIELDS = {
    Quest = { "name", "questLevel", "requiredLevel", "requiredMaxLevel", "startedBy", "finishedBy",
        "objectives", "objectivesText", "preQuestGroup", "preQuestSingle", "nextQuestInChain",
        "exclusiveTo", "zoneOrSort", "requiredRaces", "requiredClasses", "sourceItemId",
        "requiredSourceItems", "requiredSkill", "breadcrumbForQuestId", "questFlags", "specialFlags",
        "requiredMinRep", "requiredMaxRep", "childQuests", "parentQuest" },
    Npc = { "name", "subName", "minLevel", "maxLevel", "rank", "spawns", "zoneID", "questStarts",
        "questEnds", "friendlyToFaction", "npcFlags" },
    Item = { "name", "npcDrops", "objectDrops", "itemDrops", "vendors", "questRewards", "startQuest",
        "relatedQuests", "itemLevel", "requiredLevel", "class", "subClass", "teachesSpell" },
    Object = { "name", "spawns", "zoneID", "questStarts", "questEnds" },
}

-- The API --------------------------------------------------------------------------------------

local status -- "ready", "contract", or "shape", once LibQuestieDB is there; nil before
local lib -- LibQuestieDB, once checked

-- Calls fn(...) protected: its first result, or nil when it errors.
local function try(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

-- Whether every field we read is in a kind's schema (Meta.<Kind>.keys, or the documented
-- Meta.<Kind>Meta.<kind>Keys spelling of the same table).
local function hasFields(api, kind)
    local meta = type(api.Meta) == "table" and api.Meta or nil
    if not meta then
        return false
    end
    local keys = type(meta[kind]) == "table" and meta[kind].keys
    if type(keys) ~= "table" then
        local spelled = meta[kind .. "Meta"]
        keys = type(spelled) == "table" and spelled[kind:sub(1, 1):lower() .. kind:sub(2) .. "Keys"]
    end
    if type(keys) ~= "table" then
        return false
    end
    for _, field in ipairs(FIELDS[kind]) do
        if keys[field] == nil then
            return false
        end
    end
    return true
end

-- What the installed LibQuestieDB is to us: "ready", "contract" (a contract range without ours),
-- or "shape" (something we call is missing).
local function check(api)
    if type(api) ~= "table" or type(api.RequireContract) ~= "function" then
        return "shape"
    end
    local ok, fits = pcall(api.RequireContract, QuestieDB.CONTRACT)
    if not ok then
        return "shape"
    end
    if not fits then
        return "contract"
    end
    for kind in pairs(KINDS) do
        local entity = api[kind]
        if type(entity) ~= "table" or type(entity.GetAll) ~= "function"
            or type(entity.GetAllIds) ~= "function" or not hasFields(api, kind) then
            return "shape"
        end
    end
    return "ready"
end

-- LibQuestieDB once it's there and checked, else nil. The verdict is kept: the installed addon
-- can't change without a /reload.
local function api()
    if lib then
        return status == "ready" and lib or nil
    end
    local found = LibQuestieDB
    if type(found) ~= "table" then
        return nil
    end
    lib, status = found, check(found)
    return status == "ready" and lib or nil
end

-- C_AddOns' answer about QuestieDB: whether it's installed, loaded, loadable now, and loaded on
-- demand. Probe: without C_AddOns, only whether its global is there.
local function addon()
    local addons = C_AddOns
    if type(addons) ~= "table" then
        return false, false, false, false
    end
    local name = QuestieDB.ADDON
    local loaded = try(addons.IsAddOnLoaded, name) and true or false
    local installed = loaded
    local loadable = false
    if type(addons.GetAddOnInfo) == "function" then
        local ok, found, _, _, canLoad, reason = pcall(addons.GetAddOnInfo, name)
        if ok and found and reason ~= "MISSING" then
            installed = true
            -- An on-demand addon not loaded yet says DEMAND_LOADED rather than loadable.
            loadable = (canLoad or reason == "DEMAND_LOADED") and true or false
        end
    end
    if not installed and type(addons.DoesAddOnExist) == "function" then
        installed = try(addons.DoesAddOnExist, name) and true or false
    end
    local onDemand = try(addons.IsAddOnLoadOnDemand, name) and true or false
    return installed, loaded, loadable, onDemand
end

---Where QuestieDB stands: `"ready"` (its API answers), `"missing"` (not installed), `"off"`
---(installed but turned off in the AddOns list, or it couldn't load), `"waiting"` (installed and
---loaded on demand, not loaded yet), `"contract"` (a version without our contract), or `"shape"`
---(its API lacks something we call).
---@return string
function QuestieDB.Status()
    if api() then
        return "ready"
    end
    if lib then
        return status or "shape" -- set with `lib`, so never nil here
    end
    local installed, loaded, loadable, onDemand = addon()
    if not installed then
        return "missing"
    end
    if not loaded and onDemand and loadable then
        return "waiting"
    end
    if loaded then
        -- Loaded, yet no LibQuestieDB: a version that names it differently.
        return "shape"
    end
    return "off"
end

---Whether QuestieDB is installed, on, and has the API we expect, or will once it loads on demand.
---@return boolean
function QuestieDB.IsAvailable()
    local now = QuestieDB.Status()
    return now == "ready" or now == "waiting"
end

---Whether its data can be read right now.
---@return boolean
function QuestieDB.IsReady()
    return api() ~= nil
end

---Whether the installed QuestieDB doesn't fit what we read (a contract or shape we don't know),
---for a module's `Problem()`.
---@return boolean
function QuestieDB.Problem()
    local now = QuestieDB.Status()
    return now == "contract" or now == "shape"
end

-- Waiting for it ------------------------------------------------------------------------------

local waiting = {} -- fn -> true, for OnReady
local listening = false

local function onLoaded()
    listening = false
    local fns = waiting
    waiting = {}
    if not api() then
        return
    end
    for fn in pairs(fns) do
        ns.Call(fn)
    end
end

local function load()
    local addons = C_AddOns
    if type(addons) == "table" then
        try(addons.LoadAddOn, QuestieDB.ADDON)
    end
end

---Calls `fn()` now if QuestieDB is ready, or once it is: it's loaded first if it loads on demand
---(after combat, since loading it all takes a moment). Nothing is called while it's missing, off,
---or the wrong shape. The same `fn` waits once; `Cancel` stops it, for a module turned off first.
---@param fn fun()
function QuestieDB.OnReady(fn)
    if api() then
        fn()
        return
    end
    local now = QuestieDB.Status()
    if now ~= "waiting" then
        return
    end
    waiting[fn] = true
    if not listening then
        listening = true
        ns.AddOns.WhenLoaded(QuestieDB.ADDON, onLoaded)
        ns.AfterCombat(load)
    end
end

---Stops waiting to call `fn` when QuestieDB is ready.
---@param fn function
function QuestieDB.Cancel(fn)
    waiting[fn] = nil
    if listening and not next(waiting) then
        listening = false
        ns.AddOns.Cancel(QuestieDB.ADDON, onLoaded)
    end
end

---What the installed QuestieDB says about itself, for Self Test: its version (from its TOC), its
---contract range, and whether it reads baked data or its source files.
---@return table info `{ status, version, contract, minContract, readMode }`, any of them nil
function QuestieDB.Info()
    local info = { status = QuestieDB.Status() }
    local addons = C_AddOns
    if type(addons) == "table" then
        info.version = try(addons.GetAddOnMetadata, QuestieDB.ADDON, "Version")
    end
    local found = LibQuestieDB
    if type(found) == "table" then
        local contract, minContract, mode = found.contractVersion, found.minSupportedContract, found.readMode
        info.contract = type(contract) == "number" and contract or nil
        info.minContract = type(minContract) == "number" and minContract or nil
        info.readMode = type(mode) == "string" and mode or nil
    end
    return info
end

-- Plain values out of theirs -----------------------------------------------------------------

-- An ID, or nil for QuestieDB's 0 ("none") and anything that isn't a number.
local function id(value)
    if type(value) == "number" and value ~= 0 then
        return value
    end
    return nil
end

-- A number, or nil for 0 and anything else: levels and masks that 0 means "not set" for.
local number = id

-- A level, or nil for none: QuestieDB's 0, and its -1 for a quest that scales to the player's
-- level (7 quests in 1.1.2, such as the warlock quests Devourer of Souls), which isn't a level.
local function level(value)
    local n = number(value)
    return n and n > 0 and n or nil
end

-- A string, or nil.
local function str(value)
    return type(value) == "string" and value or nil
end

-- A list of IDs as our own list: only the non-zero numbers, in order.
local function ids(list)
    local out = {}
    if type(list) == "table" then
        for _, value in ipairs(list) do
            if id(value) then
                out[#out + 1] = value
            end
        end
    end
    return out
end

-- A prerequisite list as real quest IDs. A negative ID in QuestieDB's preQuestGroup still means
-- that quest must be done; the sign only tells Questie an exclusive alternative doesn't count in
-- its place (QuestieDB:IsPreQuestGroupFulfilled). Nothing of ours counts alternatives, so the
-- sign is dropped. 1.1.2 has two such rows: quests 4964 and 4975.
local function prerequisites(list)
    local out = ids(list)
    for i, value in ipairs(out) do
        if value < 0 then
            out[i] = -value
        end
    end
    return out
end

-- A list of strings as our own list.
local function strings(list)
    local out = {}
    if type(list) == "table" then
        for _, value in ipairs(list) do
            if type(value) == "string" then
                out[#out + 1] = value
            end
        end
    end
    return out
end

-- A record's fields, by name: GetAll's packed values for FIELDS[kind], or nil for an unknown ID.
local function read(kind, entityID)
    local found = api()
    if not found or type(entityID) ~= "number" then
        return nil
    end
    local entity = found[kind]
    local values = try(entity.GetAll, entityID, FIELDS[kind])
    if type(values) ~= "table" then
        return nil
    end
    local fields = {}
    for i, field in ipairs(FIELDS[kind]) do
        fields[field] = values[i]
    end
    return fields
end

-- Zones ---------------------------------------------------------------------------------------

local zones -- area ID -> uiMapID (false: no map), read once from QuestieDB's ZoneDB support data

-- One of its support tables, which it keeps as Lua source text (`return { ... }`) for Questie's
-- loadstring: run with no globals, so it can only build a table. Takes a table as it is.
local function source(value)
    if type(value) == "table" then
        return value
    end
    if type(value) ~= "string" or not loadstring then
        return nil
    end
    local chunk = loadstring(value)
    if not chunk then
        return nil
    end
    setfenv(chunk, {})
    local result = try(chunk)
    return type(result) == "table" and result or nil
end

-- A support module's table (`Support.Get(name)`), or nil.
local function support(name)
    local found = api()
    local lib_ = found and found.Support
    if type(lib_) ~= "table" then
        return nil
    end
    local module = try(lib_.Get, name)
    return type(module) == "table" and module or nil
end

local function loadZones()
    zones = {}
    local zoneDB = support("ZoneDB")
    local private = zoneDB and type(zoneDB.private) == "table" and zoneDB.private
    if not private then
        return
    end
    -- Its overrides win, as Questie reads them; 0 there means "shown on no map".
    for _, list in ipairs({ source(private.areaIdToUiMapId) or {}, source(private.areaIdToUiMapIdOverride) or {} }) do
        for area, map in pairs(list) do
            if type(area) == "number" and type(map) == "number" then
                zones[area] = map ~= 0 and map or false
            end
        end
    end
end

---The uiMapID QuestieDB maps an AreaTable ID (a zone or a place in one) to, or nil when it has none.
---@param areaID number
---@return number|nil uiMapID
function QuestieDB.UiMapID(areaID)
    if not api() or type(areaID) ~= "number" then
        return nil
    end
    if not zones then
        loadZones()
    end
    return zones[areaID] or nil
end

-- Spawns as our own list, `{ uiMapID, x, y, areaID, phase }` with x and y 0-1 on that map, and the
-- areas of instances it's in (QuestieDB's -1, -1 "somewhere inside" point). A spawn in an area
-- with no map is left out.
local function spawns(list)
    local out, instances = {}, {}
    if type(list) ~= "table" then
        return out, instances
    end
    for area, points in pairs(list) do
        if type(area) == "number" and type(points) == "table" then
            local map = QuestieDB.UiMapID(area)
            for _, point in ipairs(points) do
                local x, y = type(point) == "table" and point[1], type(point) == "table" and point[2]
                if type(x) == "number" and type(y) == "number" then
                    if x == -1 and y == -1 then
                        instances[#instances + 1] = area
                    elseif map then
                        out[#out + 1] = { uiMapID = map, x = x / 100, y = y / 100, areaID = area,
                            phase = id(point[3]) }
                    end
                end
            end
        end
    end
    return out, instances
end

-- The readers --------------------------------------------------------------------------------

-- Objective kinds, in QuestieDB's group order.
local function objectives(groups)
    local out = {}
    if type(groups) ~= "table" then
        return out
    end
    local function each(group, fn)
        if type(groups[group]) == "table" then
            for _, row in ipairs(groups[group]) do
                if type(row) == "table" then
                    fn(row)
                end
            end
        end
    end
    for group, kind in ipairs({ "npc", "object", "item" }) do
        each(group, function(row)
            if id(row[1]) then
                out[#out + 1] = { kind = kind, id = row[1], text = str(row[2]) }
            end
        end)
    end
    local rep = groups[4]
    if type(rep) == "table" and id(rep[1]) and type(rep[2]) == "number" then
        out[#out + 1] = { kind = "reputation", id = rep[1], value = rep[2] }
    end
    each(5, function(row)
        if id(row[2]) then
            out[#out + 1] = { kind = "killCredit", id = row[2], ids = ids(row[1]), text = str(row[3]) }
        end
    end)
    each(6, function(row)
        if id(row[1]) then
            out[#out + 1] = { kind = "spell", id = row[1], text = str(row[2]), itemID = id(row[3]) }
        end
    end)
    return out
end

-- QuestieDB's Enum.questFlags bits we read (its docs: src/corrections/enum/quests.lua).
local QUEST_RAID, QUEST_DAILY, QUEST_WEEKLY, QUEST_MONTHLY = 64, 4096, 32768, 65536

-- Whether a bit of a flag mask is set (Lua 5.1 has no bit operators; the client's `bit` isn't
-- needed for one bit).
local function hasFlag(mask, bit)
    return floor(mask / bit) % 2 == 1
end

-- A list field of a startedBy/finishedBy table.
local function group(tbl, index)
    return ids(type(tbl) == "table" and tbl[index] or nil)
end

-- A `{ factionID, value }` reputation requirement as `{ id, value }`, or nil for none.
local function reputation(pair)
    if type(pair) == "table" and id(pair[1]) and type(pair[2]) == "number" then
        return { id = pair[1], value = pair[2] }
    end
    return nil
end

---A quest, or nil when QuestieDB isn't ready or doesn't know it.
---
---`{ id, name, level, requiredLevel, maxLevel, races, classes, areaID, uiMapID, sortID,
---starters = { npcs, objects, items }, finishers = { npcs, objects }, objectives, objectivesText,
---prerequisites = { all, any }, next, children, parent, exclusiveTo, breadcrumbFor, sourceItemID,
---requiredSkill, flags, specialFlags, repeatable, raid, minRep, maxRep }`. `children` are the quests
---this one unlocks, and `parent` the quest that must be in the log for this one to be offered
---(QuestieDB's `childQuests` and `parentQuest`). Prerequisite IDs are always real, positive quest
---IDs. `minRep` and `maxRep` are
---`{ id, value }`: a faction and the reputation with it the quest needs at least, or less than.
---`objectives` is a list of `{ kind, id, text }` (`kind` is `"npc"`, `"object"`, `"item"`,
---`"reputation"` with `value`, `"killCredit"` with `ids`, or `"spell"` with `itemID`). Every
---prerequisite in `all` and one of `any` must be done. `areaID` (and its `uiMapID`) is the zone the
---quest is listed in; `sortID` is the quest log category of one listed under a category instead.
---`races` and `classes` are masks, nil for anyone. `flags` and `specialFlags` are QuestieDB's
---quest flag masks (0 when none); `repeatable` is true for a repeatable, daily, weekly, or monthly
---quest, and `raid` for one its flags mark as a raid quest. `tag` is the client's, not QuestieDB's
---(`ns.Quests.Tag`), nil until the client has the quest cached; QuestieDB has no quest tags.
---@param questID number
---@return table|nil
function QuestieDB.Quest(questID)
    local f = read("Quest", questID)
    if not f then
        return nil
    end
    local zone = type(f.zoneOrSort) == "number" and f.zoneOrSort or 0
    local flags = type(f.questFlags) == "number" and f.questFlags or 0
    local special = type(f.specialFlags) == "number" and f.specialFlags or 0
    local skill = type(f.requiredSkill) == "table" and id(f.requiredSkill[1])
        and { id = f.requiredSkill[1], value = type(f.requiredSkill[2]) == "number" and f.requiredSkill[2] or 0 }
    return {
        id = questID,
        name = str(f.name),
        level = level(f.questLevel),
        requiredLevel = level(f.requiredLevel),
        maxLevel = level(f.requiredMaxLevel),
        races = number(f.requiredRaces),
        classes = number(f.requiredClasses),
        areaID = zone > 0 and zone or nil,
        uiMapID = zone > 0 and QuestieDB.UiMapID(zone) or nil,
        sortID = zone < 0 and -zone or nil,
        starters = { npcs = group(f.startedBy, 1), objects = group(f.startedBy, 2), items = group(f.startedBy, 3) },
        finishers = { npcs = group(f.finishedBy, 1), objects = group(f.finishedBy, 2) },
        objectives = objectives(f.objectives),
        objectivesText = strings(f.objectivesText),
        prerequisites = { all = prerequisites(f.preQuestGroup), any = prerequisites(f.preQuestSingle) },
        next = id(f.nextQuestInChain),
        children = ids(f.childQuests),
        parent = id(f.parentQuest),
        exclusiveTo = ids(f.exclusiveTo),
        breadcrumbFor = id(f.breadcrumbForQuestId),
        sourceItemID = id(f.sourceItemId),
        requiredSkill = skill or nil,
        flags = flags,
        specialFlags = special,
        repeatable = special % 2 == 1 or hasFlag(flags, QUEST_DAILY) or hasFlag(flags, QUEST_WEEKLY) or hasFlag(flags, QUEST_MONTHLY),
        raid = hasFlag(flags, QUEST_RAID),
        tag = ns.Quests.Tag(questID),
        minRep = reputation(f.requiredMinRep),
        maxRep = reputation(f.requiredMaxRep),
    }
end

---An NPC, or nil when QuestieDB isn't ready or doesn't know it.
---
---`{ id, name, subName, minLevel, maxLevel, rank, flags, friendlyTo, areaID, uiMapID, spawns,
---instances, questStarts, questEnds }`. `spawns` is a list of `{ uiMapID, x, y, areaID, phase }`
---with x and y 0-1 on that map; `instances` lists the area IDs of dungeons it's somewhere inside.
---`friendlyTo` is `"A"`, `"H"`, or `"AH"`; `flags` QuestieDB's NPC flag mask
---(`LibQuestieDB.Enum.npcFlags`).
---@param npcID number
---@return table|nil
function QuestieDB.Npc(npcID)
    local f = read("Npc", npcID)
    if not f then
        return nil
    end
    local list, instances = spawns(f.spawns)
    local friendly = f.friendlyToFaction
    return {
        id = npcID,
        name = str(f.name),
        subName = str(f.subName),
        minLevel = number(f.minLevel),
        maxLevel = number(f.maxLevel),
        rank = type(f.rank) == "number" and f.rank or 0,
        flags = type(f.npcFlags) == "number" and f.npcFlags or 0,
        friendlyTo = (friendly == "A" or friendly == "H" or friendly == "AH") and friendly or nil,
        areaID = id(f.zoneID),
        uiMapID = id(f.zoneID) and QuestieDB.UiMapID(f.zoneID) or nil,
        spawns = list,
        instances = instances,
        questStarts = ids(f.questStarts),
        questEnds = ids(f.questEnds),
    }
end

---An item, or nil when QuestieDB isn't ready or doesn't know it.
---
---`{ id, name, level, requiredLevel, class, subClass, npcDrops, objectDrops, containers, vendors,
---questRewards, startsQuest, relatedQuests, teachesSpell }`: where it comes from as ID lists (NPCs
---that drop it, objects that hold it, items that contain it, NPCs that sell it, quests that give
---it). Drop chances aren't here; see `QuestieDB.DropRates`.
---@param itemID number
---@return table|nil
function QuestieDB.Item(itemID)
    local f = read("Item", itemID)
    if not f then
        return nil
    end
    return {
        id = itemID,
        name = str(f.name),
        level = number(f.itemLevel),
        requiredLevel = number(f.requiredLevel),
        class = type(f.class) == "number" and f.class or nil,
        subClass = type(f.subClass) == "number" and f.subClass or nil,
        npcDrops = ids(f.npcDrops),
        objectDrops = ids(f.objectDrops),
        containers = ids(f.itemDrops),
        vendors = ids(f.vendors),
        questRewards = ids(f.questRewards),
        startsQuest = id(f.startQuest),
        relatedQuests = ids(f.relatedQuests),
        teachesSpell = id(f.teachesSpell),
    }
end

---A world object (a chest, a node, a quest object), or nil when QuestieDB isn't ready or doesn't
---know it: `{ id, name, areaID, uiMapID, spawns, instances, questStarts, questEnds }`, with `spawns`
---and `instances` as `QuestieDB.Npc`'s.
---@param objectID number
---@return table|nil
function QuestieDB.Object(objectID)
    local f = read("Object", objectID)
    if not f then
        return nil
    end
    local list, instances = spawns(f.spawns)
    return {
        id = objectID,
        name = str(f.name),
        areaID = id(f.zoneID),
        uiMapID = id(f.zoneID) and QuestieDB.UiMapID(f.zoneID) or nil,
        spawns = list,
        instances = instances,
        questStarts = ids(f.questStarts),
        questEnds = ids(f.questEnds),
    }
end

---Every ID of a kind (`"Quest"`, `"Npc"`, `"Item"`, `"Object"`), ascending, as our own list; empty
---while QuestieDB isn't ready.
---@param kind string
---@return number[]
function QuestieDB.Ids(kind)
    local found = api()
    if not found or not KINDS[kind] then
        return {}
    end
    return ids(try(found[kind].GetAllIds))
end

---The IDs of a kind whose name is exactly `name` in the game's language, ascending, as our own
---list; empty when none is. The first call for a kind makes QuestieDB index every name of it (tens
---of milliseconds), so call it where a stall won't show, not first on a hover.
---@param kind string
---@param name string
---@return number[]
function QuestieDB.IdsByName(kind, name)
    local found = api()
    if not found or not KINDS[kind] or type(name) ~= "string" then
        return {}
    end
    return ids(try(found[kind].IdsByName, name))
end

---The bit of one of QuestieDB's NPC flags, by its name in `LibQuestieDB.Enum.npcFlags`
---(`"INNKEEPER"`, `"TRAINER"`, `"VENDOR"`, ...), or nil when the installed version doesn't have
---it: the table came with contract 4, and a flag the game's version lacks is left out of it.
---@param name string
---@return number|nil bit
function QuestieDB.NpcFlag(name)
    local found = api()
    local enum = found and type(found.Enum) == "table" and found.Enum.npcFlags
    local value = type(enum) == "table" and enum[name]
    if type(value) == "number" and value > 0 then
        return value
    end
    return nil
end

---An NPC's flag mask alone, a far cheaper read than `QuestieDB.Npc` for going over every NPC: 0
---for none, an unknown ID, or while QuestieDB isn't ready.
---@param npcID number
---@return number mask
function QuestieDB.NpcFlags(npcID)
    local found = api()
    if not found or type(npcID) ~= "number" then
        return 0
    end
    local mask = try(found.Npc.Get, npcID, "npcFlags")
    return type(mask) == "number" and mask or 0
end

---Whether a flag mask has a flag's bit set (`QuestieDB.NpcFlag`'s). Lua 5.1 has no bit operators,
---and the masks can be wider than the client's 32-bit `bit` library.
---@param mask number
---@param flag number
---@return boolean
function QuestieDB.HasFlag(mask, flag)
    return type(mask) == "number" and type(flag) == "number" and flag > 0 and hasFlag(mask, flag)
end

---A text field (a `name`, an NPC's `subName`) as QuestieDB's own data has it, before its
---translations and Corrections (its `GetRaw`): English whatever the game's language, for telling
---kinds apart by their words. Nil when it has none, isn't text, or QuestieDB isn't ready. Each read
---is uncached on its side.
---@param kind string `"Npc"`, `"Object"`, `"Item"`, or `"Quest"`
---@param entityID number
---@param field string
---@return string|nil
function QuestieDB.English(kind, entityID, field)
    local found = api()
    if not found or not KINDS[kind] or type(entityID) ~= "number" or type(field) ~= "string" then
        return nil
    end
    return str(try(found[kind].GetRaw, entityID, field))
end

-- Drop chances --------------------------------------------------------------------------------

-- Item ID -> { NPC ID -> percent }, from QuestieDB's drop support data: Wowhead's numbers, then
-- CMaNGOS's for an item Wowhead's lack. Not part of its documented contract (the module's name is
-- its Classic drop table's), so it's probed and may be gone in a later version.
local drops

local function loadDrops()
    drops = {}
    local module = support("QuestieClassicItemDrops") or support("DropDB")
    if not module then
        return
    end
    for _, key in ipairs({ "wowheadData", "cmangosData" }) do
        local list = source(module[key])
        if list then
            for item, rates in pairs(list) do
                if type(item) == "number" and type(rates) == "table" and not drops[item] then
                    drops[item] = rates
                end
            end
        end
    end
end

---The chance, in percent, each NPC drops an item with, as far as QuestieDB's drop tables know:
---`{ [npcID] = percent }`, or nil when they don't have it. The first call reads the whole table, so
---call it out of combat.
---@param itemID number
---@return table<number, number>|nil
function QuestieDB.DropRates(itemID)
    if not api() or type(itemID) ~= "number" then
        return nil
    end
    if not drops then
        loadDrops()
    end
    local rates = drops[itemID]
    if not rates then
        return nil
    end
    local out = {}
    for npc, chance in pairs(rates) do
        if type(npc) == "number" and type(chance) == "number" then
            out[npc] = chance
        end
    end
    return next(out) and out or nil
end

---The creatures that drop the items a quest asks for, as far as QuestieDB knows: a list of
---`{ itemID, name, index, npcs = { [npcID] = true } }`, one for each item objective a creature
---drops. `index` is the item's place among the quest's item objectives, for matching it with the
---quest log's when its name doesn't. Empty when no creature drops any; nil for an unknown quest.
---@param questID number
---@return table[]|nil
function QuestieDB.QuestDrops(questID)
    local quest = QuestieDB.Quest(questID)
    if not quest then
        return nil
    end
    local out, index = {}, 0
    for _, objective in ipairs(quest.objectives) do
        if objective.kind == "item" then
            index = index + 1
            local item = QuestieDB.Item(objective.id)
            local npcs
            for _, npc in ipairs(item and item.npcDrops or {}) do
                npcs = npcs or {}
                npcs[npc] = true
            end
            if npcs then
                out[#out + 1] = { itemID = objective.id, name = item.name, index = index, npcs = npcs }
            end
        end
    end
    return out
end

-- Quest links, the other way ------------------------------------------------------------------

-- Quest ID -> the quests that name it, built once from every quest's links: `unlocks` (those that
-- list it as a prerequisite) and `leadsTo` (those whose next quest in the chain it is).
local links

local function loadLinks()
    links = { unlocks = {}, leadsTo = {} }
    local found = api()
    if not found then
        return
    end
    local entity = found.Quest
    local fields = { "preQuestGroup", "preQuestSingle", "nextQuestInChain" }
    local function add(index, key, questID)
        local list = index[key]
        if not list then
            list = {}
            index[key] = list
        end
        if list[#list] ~= questID then -- in both of a quest's prerequisite lists
            list[#list + 1] = questID
        end
    end
    for _, questID in ipairs(ids(try(entity.GetAllIds))) do
        local values = try(entity.GetAll, questID, fields)
        if type(values) == "table" then
            for _, before in ipairs(prerequisites(values[1])) do
                add(links.unlocks, before, questID)
            end
            for _, before in ipairs(prerequisites(values[2])) do
                add(links.unlocks, before, questID)
            end
            local after = id(values[3])
            if after then
                add(links.leadsTo, after, questID)
            end
        end
    end
end

-- A copy of one list of the index, empty for none.
local function linked(index, questID)
    if not api() or type(questID) ~= "number" then
        return {}
    end
    if not links then
        loadLinks()
    end
    local out = {}
    for i, value in ipairs(links[index][questID] or {}) do
        out[i] = value
    end
    return out
end

---The quests that need this one done first (it's in their `prerequisites`), ascending, as our own
---list; empty for none. The first call reads every quest's links (a few thousand reads), so call it
---out of combat, not first on a hover.
---@param questID number
---@return number[]
function QuestieDB.QuestsUnlockedBy(questID)
    return linked("unlocks", questID)
end

---The quests whose `next` quest in the chain is this one, ascending, as our own list; empty for
---none. Built with `QuestsUnlockedBy`, from the same one read of every quest.
---@param questID number
---@return number[]
function QuestieDB.QuestsLeadingTo(questID)
    return linked("leadsTo", questID)
end

-- Races and classes ---------------------------------------------------------------------------

-- QuestieDB's race mask: the race ID's own bit for Classic's eight, and bits 33 and 34 for
-- Forever's two Skyborne races, 95 (Alliance) and 96 (Horde), as its raceMaskById has them
-- (QuestieDB src/corrections/enum/expansions.lua, read 2026-11-15). Its Forever data sets a
-- Skyborne's bit on every quest one can take: all 3461 quests for a whole side have it, and so do
-- class quests shared with another race (a Night Elf's druid quests), counted in its data at
-- build commit 4dbb8244. So the bit alone decides. By race ID, not by side: the side isn't
-- always known (early in login), and a guess there would hide or show every quest.
local CLASSIC_RACES = 8
local NEW_RACE_BITS = { [95] = 33, [96] = 34 }

-- Whether a mask has the bit of an ID (1, 2, 3, ... from the lowest bit).
local function inMask(mask, bitID)
    return floor(mask / 2 ^ (bitID - 1)) % 2 == 1
end

---Whether a quest's race mask (`races` of `QuestieDB.Quest`) lets a race (`UnitRace`'s third value)
---take it, by the race's own bit: a Dwarf's quest isn't a Skyborne's. True for no mask, and for a
---race the masks have no bit for.
---@param mask number?
---@param raceID number
---@return boolean
function QuestieDB.HasRace(mask, raceID)
    if not mask then
        return true
    end
    if raceID <= CLASSIC_RACES then
        return inMask(mask, raceID)
    end
    local bitID = NEW_RACE_BITS[raceID]
    return not bitID or inMask(mask, bitID)
end

---Whether a quest's class mask (`classes`) lets a class (`UnitClass`'s third value) take it. True
---for no mask.
---@param mask number?
---@param classID number
---@return boolean
function QuestieDB.HasClass(mask, classID)
    return not mask or inMask(mask, classID)
end

-- Items and their quests ----------------------------------------------------------------------

-- Item ID -> { [questID] = kind }, from every quest's rows: the items that start it, the items it
-- asks for (an item objective, or the item a spell objective is cast with), the item its giver hands
-- over, and the items it needs that aren't objectives. Built a few quests at a time by
-- IndexItemQuests, since that's a read of four fields of every quest (about 5,900 in 1.1.6, which
-- tie about 4,000 items to quests). Items name only some of theirs (`relatedQuests`, 755 items), so
-- this is read from the quests' side.
local ITEM_FIELDS = { "startedBy", "objectives", "sourceItemId", "requiredSourceItems" }
local KIND_ORDER = { starts = 1, objective = 2, given = 3, used = 4, related = 5 }
local itemIndex
local indexIDs, indexNext -- the quest IDs being read, and the next place in them; nil once done
local itemQuests = {} -- item ID -> our list, kept: the data can't change without a reload

-- Ties an item to a quest, keeping the kind that says most when it's tied more than one way.
local function tie(index, itemID, questID, kind)
    if not id(itemID) then
        return
    end
    local quests = index[itemID]
    if not quests then
        quests = {}
        index[itemID] = quests
    end
    local had = quests[questID]
    if not had or KIND_ORDER[kind] < KIND_ORDER[had] then
        quests[questID] = kind
    end
end

-- The item IDs in one group of a quest's objectives, at `at` in each row.
local function objectiveItems(groups, group, at, fn)
    local rows = type(groups) == "table" and groups[group]
    if type(rows) == "table" then
        for _, row in ipairs(rows) do
            if type(row) == "table" then
                fn(row[at])
            end
        end
    end
end

---Reads up to `count` more quests into the index of which items are for which quest, and says
---whether it's whole. Call it a few hundred at a time on later frames, so no one frame reads every
---quest; `ItemQuests` answers once it's whole. False while QuestieDB isn't ready.
---@param count number
---@return boolean done
function QuestieDB.IndexItemQuests(count)
    local found = api()
    if not found then
        return false
    end
    if itemIndex and not indexIDs then
        return true
    end
    local entity = found.Quest
    if not itemIndex then
        itemIndex = {}
        indexIDs, indexNext = ids(try(entity.GetAllIds)), 1
    end
    local index = itemIndex
    local last = min(#indexIDs, indexNext + count - 1)
    for i = indexNext, last do
        local questID = indexIDs[i]
        local values = try(entity.GetAll, questID, ITEM_FIELDS)
        if type(values) == "table" then
            for _, itemID in ipairs(group(values[1], 3)) do
                tie(index, itemID, questID, "starts")
            end
            local function asked(itemID)
                tie(index, itemID, questID, "objective")
            end
            objectiveItems(values[2], 3, 1, asked)
            objectiveItems(values[2], 6, 3, asked)
            tie(index, values[3], questID, "given")
            for _, itemID in ipairs(ids(values[4])) do
                tie(index, itemID, questID, "used")
            end
        end
    end
    indexNext = last + 1
    if indexNext > #indexIDs then
        indexIDs, indexNext = nil, nil
        return true
    end
    return false
end

---The quests an item is for, ascending by quest ID, as our own list of `{ id, kind }`: `kind` is
---`"starts"` (the item starts it), `"objective"` (the quest asks for it), `"given"` (its giver hands
---it over), `"used"` (the quest needs it but doesn't count it), or `"related"` (only the item's
---own `relatedQuests` names it). Empty for an item tied to none; nil until `IndexItemQuests` is
---whole, or while QuestieDB isn't ready. Every quest QuestieDB has, for either side and any class.
---@param itemID number
---@return table[]|nil
function QuestieDB.ItemQuests(itemID)
    local found = api()
    if not (found and itemIndex and not indexIDs) or type(itemID) ~= "number" then
        return nil
    end
    local list = itemQuests[itemID]
    if not list then
        local kinds = {}
        for questID, kind in pairs(itemIndex[itemID] or {}) do
            kinds[questID] = kind
        end
        local values = try(found.Item.GetAll, itemID, { "startQuest", "relatedQuests" })
        if type(values) == "table" then
            local starts = id(values[1])
            if starts then
                kinds[starts] = "starts"
            end
            for _, questID in ipairs(ids(values[2])) do
                kinds[questID] = kinds[questID] or "related"
            end
        end
        list = {}
        for questID, kind in pairs(kinds) do
            list[#list + 1] = { id = questID, kind = kind }
        end
        sort(list, function(a, b) return a.id < b.id end)
        itemQuests[itemID] = list
    end
    local out = {}
    for i, entry in ipairs(list) do
        out[i] = { id = entry.id, kind = entry.kind }
    end
    return out
end

-- Settings ------------------------------------------------------------------------------------

---The gray rows a module that needs QuestieDB puts in `module.notice`: that it needs the addon,
---while it's missing or off, and that the installed version doesn't fit, while that's so. A
---module with notices of its own adds these to its list.
---@return table[] notices
function QuestieDB.Notices()
    return {
        {
            text = L.QUESTIEDB_NEEDED,
            description = L.QUESTIEDB_NEEDED_DESC,
            shown = function()
                local now = QuestieDB.Status()
                return now == "missing" or now == "off"
            end,
        },
        {
            text = L.QUESTIEDB_PROBLEM,
            description = L.QUESTIEDB_PROBLEM_DESC,
            shown = QuestieDB.Problem,
        },
    }
end

---Sets a module up as one that can't work without QuestieDB, called as its file loads: it gets
---the notices above, and its name is red in the Modules list while QuestieDB is missing, off, or
---the wrong version (`module:Problem()`). While it's missing or off the module is locked off too
---(`module.locked`), a padlock for its checkbox saying why, so it can be read about but not turned
---on. QuestieDB is in our TOC's OptionalDeps, so it has loaded by the time a module's file asks,
---and the AddOns list can't change without a reload.
---@param module table
function QuestieDB.Require(module)
    module.notice = QuestieDB.Notices()
    local now = QuestieDB.Status()
    if now == "missing" or now == "off" then
        module.locked = true
        module.lockedText = L.QUESTIEDB_LOCKED
    end
    function module:Problem()
        return self.locked or QuestieDB.Problem()
    end
end

---Forgets what was read and checked, for the tests (a new stub of LibQuestieDB).
function QuestieDB.Reset()
    lib, status, zones, drops, links = nil, nil, nil, nil, nil
    itemIndex, indexIDs, indexNext, itemQuests = nil, nil, nil, {}
    waiting, listening = {}, false
end
