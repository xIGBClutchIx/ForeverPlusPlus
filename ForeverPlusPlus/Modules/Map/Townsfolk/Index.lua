-- Townsfolk's index: QuestieDB read once into the townsfolk on each map, a few at a time so the
-- game doesn't stall. Every NPC's flags say whether it keeps an inn, a bank, an auction house, or a
-- stable, sends to a battleground, trains, sells, or repairs; the English title under its name
-- (Data/Townsfolk.lua's words) says which class or profession it trains and what it sells. A
-- mailbox is a world object named Mailbox in QuestieDB's English data.
--
-- `internal.byMap[mapID]` is a list of `{ entry, x, y }`, one for each spawn on that map, and an
-- entry `{ kinds, name, title, friendly, class, line, object }`: every kind it could show as (by
-- option key), its name and title in the game's language, the side it's friendly to, the class or
-- profession skill line it trains, and whether it's an object. Nothing is kept of QuestieDB's own.
local _, ns = ...

local ipairs, pairs, find, min = ipairs, pairs, string.find, math.min
local InCombatLockdown, debugprofilestop = InCombatLockdown, debugprofilestop

local QuestieDB = ns.QuestieDB
local Data = ns.Data

local module = ns.modules.Townsfolk
local internal = module.internal

local PER_STEP = 20 -- records read between looks at the clock
local BUDGET = 4 -- milliseconds of reading a frame

internal.byMap = {}
internal.ready = false

local timer = ns.Frames.Timer(module)
local npcIDs, objectIDs, position
local flags -- QuestieDB's NPC flag bits we read, by our name for them, once it's ready

-- Whether `text` has one of the words in `words`, anywhere in it.
local function hasWord(text, words)
    for _, word in ipairs(words) do
        if find(text, word, 1, true) then
            return true
        end
    end
    return false
end

-- The bits of the flags we read. One the installed QuestieDB lacks is nil and never matches.
local function readFlags()
    return {
        innkeeper = QuestieDB.NpcFlag("INNKEEPER"),
        banker = QuestieDB.NpcFlag("BANKER"),
        auctioneer = QuestieDB.NpcFlag("AUCTIONEER"),
        stable = QuestieDB.NpcFlag("STABLEMASTER"),
        battlemaster = QuestieDB.NpcFlag("BATTLEMASTER"),
        trainer = QuestieDB.NpcFlag("TRAINER"),
        vendor = QuestieDB.NpcFlag("VENDOR"),
        repair = QuestieDB.NpcFlag("REPAIR"),
    }
end

local function has(mask, name)
    return QuestieDB.HasFlag(mask, flags[name])
end

-- Every kind an NPC with these flags and this English title is, as a set of option keys, and the
-- class and skill line it trains; nil when it's none of ours.
local function classify(npcID, mask)
    local kinds, class, line
    local function add(key)
        kinds = kinds or {}
        kinds[key] = true
    end
    for _, key in ipairs({ "innkeeper", "banker", "auctioneer", "stable", "battlemaster", "repair" }) do
        if has(mask, key) then
            add(key)
        end
    end
    local trains, sells = has(mask, "trainer"), has(mask, "vendor")
    if trains or sells then
        local title = QuestieDB.English("Npc", npcID, "subName")
        if title then
            -- A demon trainer sells rather than trains, so a class's words count for either.
            for token, words in pairs(Data.townsfolkClassTrainers) do
                if hasWord(title, words) then
                    add("class")
                    class = token
                end
            end
            if trains and not class then
                for skill, words in pairs(Data.townsfolkProfessionTrainers) do
                    if hasWord(title, words) then
                        add("profession")
                        line = skill
                    end
                end
            end
            if sells then
                for key, words in pairs(Data.townsfolkVendors) do
                    if hasWord(title, words) then
                        add(key)
                    end
                end
            end
        end
    end
    return kinds, class, line
end

local function addSpots(entry, spawns)
    for _, spawn in ipairs(spawns) do
        local list = internal.byMap[spawn.uiMapID]
        if not list then
            list = {}
            internal.byMap[spawn.uiMapID] = list
        end
        list[#list + 1] = { entry = entry, x = spawn.x, y = spawn.y }
    end
end

local function indexNpc(npcID)
    local mask = QuestieDB.NpcFlags(npcID)
    if mask == 0 then
        return
    end
    local kinds, class, line = classify(npcID, mask)
    if not kinds then
        return
    end
    local npc = QuestieDB.Npc(npcID)
    if not npc or #npc.spawns == 0 then
        return
    end
    addSpots({ kinds = kinds, name = npc.name, title = npc.subName, friendly = npc.friendlyTo,
        class = class, line = line }, npc.spawns)
end

local MAILBOX = { mailbox = true }

local function indexObject(objectID)
    if QuestieDB.English("Object", objectID, "name") ~= "Mailbox" then
        return
    end
    local object = QuestieDB.Object(objectID)
    if object and #object.spawns > 0 then
        addSpots({ kinds = MAILBOX, name = object.name, object = true }, object.spawns)
    end
end

-- Reads records for a few milliseconds, then waits for the next frame: NPCs, then objects. Never
-- in combat, where a slow frame costs the most.
local function step()
    if not module.enabled then
        return
    end
    if InCombatLockdown() then
        timer:Start(1, step)
        return
    end
    local started = debugprofilestop()
    repeat
        local ids, read = npcIDs, indexNpc
        if position > #npcIDs then
            ids, read = objectIDs, indexObject
        end
        local first = position > #npcIDs and position - #npcIDs or position
        local last = min(first + PER_STEP - 1, #ids)
        for i = first, last do
            read(ids[i])
        end
        position = position + (last - first + 1)
    until position > #npcIDs + #objectIDs or debugprofilestop() - started >= BUDGET
    if position > #npcIDs + #objectIDs then
        npcIDs, objectIDs = nil, nil
        internal.ready = true
        internal.Changed()
    else
        timer:Start(0, step)
    end
end

---Starts reading QuestieDB, unless it's read or being read.
function internal.Build()
    if internal.ready or npcIDs then
        return
    end
    flags = readFlags()
    npcIDs, objectIDs, position = QuestieDB.Ids("Npc"), QuestieDB.Ids("Object"), 1
    timer:Start(0, step)
end

---Drops the index, when the module turns off.
function internal.Reset()
    timer:Cancel()
    npcIDs, objectIDs, position = nil, nil, nil
    internal.byMap, internal.ready = {}, false
end
