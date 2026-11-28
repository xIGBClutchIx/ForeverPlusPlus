-- Quest Item Button: a key that uses the item of the quest you're closest to, and a button showing
-- which item that is, which Edit Mode moves. The key is in Blizzard's Key Bindings (Bindings.xml,
-- under Forever++).
--
-- The items: what the quest log gives a quest (GetQuestLogSpecialItemInfo, the item Blizzard's
-- quest tracker puts beside it), and with Quest Items in Your Bags, usable items in the bags that
-- are quest items or that QuestieDB says a quest in the log gives or asks you to use. Classic's
-- quests may flag no item for the log, which is why the bags are read too.
--
-- Which one: the selected (super-tracked) quest's, with that option on; else the quest nearest
-- you, by the game's distance to it (C_QuestLog.GetDistanceSqToQuest), its spot on the map
-- (Lib/WorldMap.lua), or the nearest spawn on your zone's map of what QuestieDB says its
-- objectives are; then a quest with an item but no distance known; then a quest item matched to
-- no quest. The choice is made again as the log, the bags, or the zone change, and every few
-- seconds as you move while there's more than one.
--
-- With Only Near Its Quest, a quest known to be far is left out, the selected one too: further
-- than the slider's yards, on another continent by the game's word, or with every place QuestieDB
-- lists for it on another map than your zone's. A quest nothing gives a place for stays in, and
-- so does every quest where your own place can't be read, as in a dungeon.
--
-- The key clicks a secure action button whose `item` is the item's ID. Its attributes can only be
-- set out of combat, so in combat the key and the button keep the item they had; both pick again
-- once combat ends. The button only shows and hides out of combat for the same reason: it's faded
-- out instead while there's nothing to use or Show Button is off, and never hidden while the
-- module is on, so the key always has a button to click.
local _, ns = ...

local ipairs, pairs, select, wipe = ipairs, pairs, select, wipe
local min, sqrt = math.min, math.sqrt
local CreateFrame, GetBindingKey, GetBindingText = CreateFrame, GetBindingKey, GetBindingText
local InCombatLockdown, GameTooltip = InCombatLockdown, GameTooltip
local C_QuestLog, C_Item, C_Container = C_QuestLog, C_Item, C_Container

local L = ns.L
local WorldMap, QuestieDB = ns.WorldMap, ns.QuestieDB
local isNumber = ns.IsNumber

local module = ns.NewModule("QuestItemButton", L.QUESTITEMBUTTON_DESC, {
    enabled = false,
    button = true, -- show the item on a button, not only on the key
    selected = true, -- the selected quest's item first, before a closer quest's
    bags = true, -- quest items in the bags, not only the quest log's
    near = true, -- leave out a quest known to be further than nearYards, or in another zone
    nearYards = 500,
    scale = 100, -- percent
    x = 0, -- the button's offset from the center of the screen
    y = -150,
})
module.title = L.QUESTITEMBUTTON_TITLE
module.category = "quests"
module.added = "1.10.0"

-- The button the key clicks, named for its binding in Bindings.xml.
local BUTTON = "ForeverPlusPlusQuestItemButton"
local BINDING = "CLICK " .. BUTTON .. ":LeftButton"

-- Blizzard's Key Bindings read these names when it lists Bindings.xml's keys.
BINDING_HEADER_FOREVERPLUSPLUS = ns.title
_G["BINDING_NAME_" .. BINDING] = L.QUESTITEMBUTTON_BINDING

local QUEST_CLASS = Enum and Enum.ItemClass and Enum.ItemClass.Questitem or 12
local DELAY = 0.5 -- seconds for a burst of log and bag updates to settle
local RECHECK = 3 -- seconds between looks at which quest is nearest, while there's a choice
local MAX_SPOTS = 400 -- the most QuestieDB spawns kept for one quest
local MAX_SOURCES = 8 -- the most creatures or objects read for one item objective
local ICON_SIZE = 36
-- The quest tracker's own quest item frame, drawn around a 26 pixel icon at 42.
local FRAME_ATLAS = "UI-QuestTrackerButton-QuestItem-Frame"
local FRAME_SIZE = ICON_SIZE * 42 / 26
local SAMPLE_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

module.notice = {
    {
        text = L.QUESTITEMBUTTON_NO_KEY, description = L.QUESTITEMBUTTON_NO_KEY_DESC,
        button = L.QUESTITEMBUTTON_BIND, fn = ns.Keys.OpenBindings,
        shown = function() return module.db.enabled and not GetBindingKey(BINDING) end,
    },
    { text = L.QUESTITEMBUTTON_COMBAT, description = L.QUESTITEMBUTTON_COMBAT_DESC },
}

module.options = {
    { key = "button", name = L.QUESTITEMBUTTON_BUTTON, description = L.QUESTITEMBUTTON_BUTTON_DESC },
    { key = "selected", name = L.QUESTITEMBUTTON_SELECTED, description = L.QUESTITEMBUTTON_SELECTED_DESC },
    { key = "bags", name = L.QUESTITEMBUTTON_BAGS, description = L.QUESTITEMBUTTON_BAGS_DESC },
    {
        key = "near", name = L.QUESTITEMBUTTON_NEAR, description = L.QUESTITEMBUTTON_NEAR_DESC,
        slider = "nearYards",
    },
    {
        key = "nearYards", name = L.QUESTITEMBUTTON_NEAR_YARDS,
        description = L.QUESTITEMBUTTON_NEAR_YARDS_DESC, requires = "near",
        min = 100, max = 2000, step = 100, format = ns.Text.Yards,
    },
}

local button -- the secure button, made once
local current -- the item ID the button uses now, or nil
local currentQuest -- the quest it's for, or nil
local wanted -- what the last choice picked, set on the button once out of combat
local wantedQuest
local candidates = {} -- { itemID, questID? } in the order found: the quest log's, then the bags'
local quests = {} -- quest ID -> QuestieDB's quest, or false: read once while the module is on
local points = {} -- quest ID -> its map point (WorldMap.QuestPoint), or false
local spots = {} -- quest ID -> QuestieDB spawns on spotsMap, or false
local elsewhere = {} -- quest ID -> true when QuestieDB lists places for it, and none on spotsMap
local spotsMap -- the zone map spots and points were worked out on
local recheck = ns.Frames.Timer(module)

-- Items ------------------------------------------------------------------------------------------

local function itemOf(link)
    local id = C_Item.GetItemInfoInstant(link)
    return isNumber(id) and id or nil
end

-- Whether an item does something when used: it has a use spell.
local function usable(itemID)
    local name = C_Item.GetItemSpell(itemID)
    return ns.IsText(name, true)
end

local function questOf(questID)
    local quest = quests[questID]
    if quest == nil then
        quest = QuestieDB.IsReady() and QuestieDB.Quest(questID) or false
        if quest or QuestieDB.IsReady() then
            quests[questID] = quest
        end
    end
    return quest or nil
end

-- The quests in the log, quest ID -> its place, and the log's own items added as candidates.
local function readLog(add)
    local log = {}
    local count = C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries() or 0
    local special = GetQuestLogSpecialItemInfo
    for index = 1, count do
        local info = C_QuestLog.GetInfo(index)
        local questID = info and not info.isHeader and not info.isHidden and info.questID or nil
        if questID and isNumber(questID) and questID > 0 then
            log[questID] = index
            if special then
                -- As Blizzard's tracker: a finished quest's item only when it says to keep showing it.
                local link, _, _, whenComplete = special(index)
                if ns.IsText(link, true) and (whenComplete or not C_QuestLog.IsComplete(questID)) then
                    add(itemOf(link), questID)
                end
            end
        end
    end
    return log
end

-- Item ID -> the quest in the log QuestieDB says gives it (its source item) or has you use it (a
-- spell objective's item).
local function questieItems(log)
    local found = {}
    if not QuestieDB.IsReady() then
        return found
    end
    for questID in pairs(log) do
        local quest = questOf(questID)
        if quest then
            if quest.sourceItemID then
                found[quest.sourceItemID] = found[quest.sourceItemID] or questID
            end
            for _, objective in ipairs(quest.objectives) do
                if objective.kind == "spell" and objective.itemID then
                    found[objective.itemID] = found[objective.itemID] or questID
                end
            end
        end
    end
    return found
end

-- A quest in the log that QuestieDB lists the item as part of.
local function relatedQuest(itemID, log)
    local item = QuestieDB.IsReady() and QuestieDB.Item(itemID)
    for _, questID in ipairs(item and item.relatedQuests or {}) do
        if log[questID] then
            return questID
        end
    end
    return nil
end

local function readBags(log, add, seen)
    local given = questieItems(log)
    local questInfo = C_Container.GetContainerItemQuestInfo
    ns.Bags.Each(function(bag, slot, info)
        local itemID = info and info.itemID
        if not (isNumber(itemID) and not seen[itemID]) then
            return
        end
        seen[itemID] = true
        if not usable(itemID) then
            return
        end
        local quest = questInfo and questInfo(bag, slot)
        local classID = select(6, C_Item.GetItemInfoInstant(itemID))
        local isQuest = (quest and quest.isQuestItem == true) or classID == QUEST_CLASS
        local questID = quest and isNumber(quest.questID) and log[quest.questID] and quest.questID
            or given[itemID] or (isQuest and relatedQuest(itemID, log)) or nil
        if questID or isQuest then
            add(itemID, questID)
        end
    end)
end

local function collect()
    wipe(candidates)
    local seen = {}
    local function add(itemID, questID)
        if itemID and not seen[itemID] then
            seen[itemID] = true
            candidates[#candidates + 1] = { itemID = itemID, questID = questID }
        end
    end
    local log = readLog(add)
    if module.db.bags then
        readBags(log, add, seen)
    end
    wipe(points)
end

-- Distance ---------------------------------------------------------------------------------------

-- What QuestieDB says the quest has you go to (its creatures and objects, and those that drop its
-- items), as spawns on `mapID`. And whether it's elsewhere: QuestieDB lists a place for it, on a
-- map or inside a dungeon, and none of them is on `mapID`.
local function questieSpots(questID, mapID)
    local quest = questOf(questID)
    if not quest then
        return false, false
    end
    local list, known = {}, false
    local function addSpawns(entity)
        if not entity then
            return
        end
        if (entity.spawns and #entity.spawns > 0) or (entity.instances and #entity.instances > 0) then
            known = true
        end
        for _, spawn in ipairs(entity.spawns or {}) do
            if #list >= MAX_SPOTS then
                return
            end
            if spawn.uiMapID == mapID then
                list[#list + 1] = spawn
            end
        end
    end
    for _, objective in ipairs(quest.objectives) do
        local kind = objective.kind
        if kind == "npc" then
            addSpawns(QuestieDB.Npc(objective.id))
        elseif kind == "object" then
            addSpawns(QuestieDB.Object(objective.id))
        elseif kind == "killCredit" then
            for _, id in ipairs(objective.ids or {}) do
                addSpawns(QuestieDB.Npc(id))
            end
        elseif kind == "item" then
            local item = QuestieDB.Item(objective.id)
            if item then
                for i = 1, min(#item.npcDrops, MAX_SOURCES) do
                    addSpawns(QuestieDB.Npc(item.npcDrops[i]))
                end
                for i = 1, min(#item.objectDrops, MAX_SOURCES) do
                    addSpawns(QuestieDB.Object(item.objectDrops[i]))
                end
            end
        end
    end
    return #list > 0 and list or false, known and #list == 0
end

-- How far the quest is in yards, or nil when nothing says, and then true when it's known to be
-- far all the same: on another continent, or all of it on other maps than the player's zone.
-- `here` is where the player stands on their zone's map: { mapID, x, y, width, height }, or nil
-- where it can't be read.
local function distance(questID, here)
    local get = C_QuestLog.GetDistanceSqToQuest
    local offContinent = false
    if get then
        local squared, onContinent = get(questID)
        if isNumber(squared) and squared > 0 then
            if ns.IsReadable(onContinent) and onContinent == false then
                offContinent = true
            else
                return sqrt(squared)
            end
        end
    end
    -- Not for a quest on another continent: its point is the way there (a boat), not the quest.
    if not offContinent then
        local point = points[questID]
        if point == nil then
            point = WorldMap.QuestPoint(questID) or false
            points[questID] = point
        end
        local yards = point and WorldMap.FromPlayer(point)
        if yards then
            return yards
        end
    end
    if not (here and here.width and QuestieDB.IsReady()) then
        return nil, offContinent
    end
    local list = spots[questID]
    if list == nil then
        list, elsewhere[questID] = questieSpots(questID, here.mapID)
        spots[questID] = list
    end
    if not list then
        return nil, offContinent or elsewhere[questID] == true
    end
    local best
    for _, spot in ipairs(list) do
        local east, south = (spot.x - here.x) * here.width, (spot.y - here.y) * here.height
        local squared = east * east + south * south
        if not best or squared < best then
            best = squared
        end
    end
    return best and sqrt(best)
end

local function whereAmI()
    local mapID, x, y = WorldMap.PlayerZonePosition()
    if mapID ~= spotsMap then
        spotsMap = mapID
        wipe(spots)
        wipe(elsewhere)
        wipe(points)
    end
    if not mapID then
        return nil
    end
    local width, height = WorldMap.Size(mapID)
    return { mapID = mapID, x = x, y = y, width = width, height = height }
end

-- The candidate to use: the selected quest's, then the nearest quest's, then one with no distance
-- known, then an item with no quest, each in the order found. With Only Near Its Quest, never
-- one whose quest is known to be far.
local function choose()
    local selected = module.db.selected and ns.Quests.Selected()
    local limit = module.db.near and module.db.nearYards or nil
    local several = #candidates > 1
    local here = (several or limit) and whereAmI() or nil
    local best, bestRank, bestYards
    for _, candidate in ipairs(candidates) do
        local questID = candidate.questID
        local rank, yards, far = 4, nil, nil
        if questID then
            -- The selected quest's distance only matters to the limit, and a lone quest's too.
            if limit or (several and questID ~= selected) then
                yards, far = distance(questID, here)
            end
            rank = questID == selected and 1 or (yards and 2 or 3)
        end
        local tooFar = limit and (far or (yards and yards > limit))
        if not tooFar and (not best or rank < bestRank
            or (rank == bestRank and yards and bestYards and yards < bestYards)) then
            best, bestRank, bestYards = candidate, rank, yards
        end
    end
    return best
end

-- Whether moving can change the choice: there's more than one to choose from, or a quest's item
-- that Only Near Its Quest may take away or bring back.
local function moves()
    if #candidates > 1 then
        return true
    end
    return module.db.near and candidates[1] ~= nil and candidates[1].questID ~= nil
end

-- The button --------------------------------------------------------------------------------------

local function bindingText()
    local key = GetBindingKey(BINDING)
    if not key then
        return ""
    end
    -- As on action buttons: the game's abbreviated text ("s-C"), cut off at the button's width,
    -- or in short ("SC") while Short Keybinds is on. A controller button keeps the game's icon.
    local short = ns.Providers.Get("shortKeybinds") and ns.Keys.Short(key)
    return short or GetBindingText(key, nil, true)
end

local editing = false -- Edit Mode is open: the button shows, to be placed

local function shownAlpha()
    if editing then
        return 1
    end
    return (module.enabled and module.db.button and current) and 1 or 0
end

-- What the button shows: the item it uses, its count, cooldown, and key. Plain textures and text,
-- which may change in combat.
local function draw()
    if not button then
        return
    end
    local itemID = current
    local icon = itemID and C_Item.GetItemIconByID(itemID)
    button.icon:SetTexture(icon or SAMPLE_ICON)
    local count = itemID and C_Item.GetItemCount(itemID) or 0
    button.Count:SetText(isNumber(count) and count > 1 and count or "")
    button.icon:SetDesaturated(itemID ~= nil and isNumber(count) and count == 0)
    local start, duration, enable
    if itemID and C_Container.GetItemCooldown then
        start, duration, enable = C_Container.GetItemCooldown(itemID)
    end
    local ticking = ns.IsReadable(enable) and enable ~= 0 and enable ~= false
    if ticking and isNumber(start) and isNumber(duration) and duration > 0 then
        button.cooldown:SetCooldown(start, duration)
    else
        button.cooldown:Clear()
    end
    button.HotKey:SetText(bindingText())
    button:SetAlpha(shownAlpha())
end

local function onEnter(self)
    if not current or self:GetAlpha() == 0 then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetItemByID(current)
    local title = currentQuest and ns.Quests.Title(currentQuest)
    if title then
        GameTooltip:AddDoubleLine(L.QUESTITEMBUTTON_FOR, title, 1, 1, 1, 1, 1, 1)
    end
    GameTooltip:Show()
end

local function onLeave()
    GameTooltip:Hide()
end

local function place()
    if not button or InCombatLockdown() then
        return
    end
    button:SetScale(module.db.scale / 100)
    ns.EditMode.Place(button, module.db.x, module.db.y)
end

local function build()
    button = CreateFrame("Button", BUTTON, UIParent, "SecureActionButtonTemplate")
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button:SetFrameStrata("MEDIUM")
    -- Down and up, so it acts on whichever the player's "Cast action keybinds on key down" says.
    button:RegisterForClicks("AnyUp", "AnyDown")
    button.icon = button:CreateTexture(nil, "BORDER")
    button.icon:SetAllPoints()
    if ns.Frames.HasAtlas(FRAME_ATLAS) then
        local frame = button:CreateTexture(nil, "ARTWORK")
        frame:SetAtlas(FRAME_ATLAS)
        frame:SetSize(FRAME_SIZE, FRAME_SIZE)
        frame:SetPoint("CENTER")
    end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.Count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.HotKey = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    button.HotKey:SetPoint("TOPRIGHT", -2, -3)
    -- One line no wider than the button, as Blizzard's action buttons keep their key label.
    button.HotKey:SetSize(ICON_SIZE - 4, 10)
    button.HotKey:SetJustifyH("RIGHT")
    button.HotKey:SetWordWrap(false)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)
    button:SetAlpha(0)
end

-- Puts the chosen item on the button, out of combat.
local applying = false
local function apply()
    if applying then
        return
    end
    applying = true
    ns.AfterCombat(function()
        applying = false
        if not button then
            return
        end
        local on = module.enabled
        local itemID = on and wanted or nil
        if itemID ~= current then
            button:SetAttribute("type", itemID and "item" or nil)
            button:SetAttribute("item", itemID and ("item:" .. itemID) or nil)
        end
        current, currentQuest = itemID, on and wantedQuest or nil
        button:EnableMouse(shownAlpha() > 0)
        button:SetShown(on)
        draw()
    end)
end

local function update()
    if not module.enabled then
        return
    end
    local best = choose()
    wanted, wantedQuest = best and best.itemID, best and best.questID
    if wanted ~= current or wantedQuest ~= currentQuest then
        apply()
    end
    if moves() then
        recheck:Start(RECHECK, update)
    else
        recheck:Cancel()
    end
end

local function refresh()
    collect()
    update()
end

local queue = ns.Frames.Coalesce(refresh, DELAY, module)

local function onQuestieReady()
    if module.enabled then
        wipe(quests)
        wipe(spots)
        wipe(elsewhere)
        queue()
    end
end

-- Edit Mode shows the button, with a question mark while there's no item, so it can be placed.
local function onEditMode(active)
    editing = active and true or false
    if button and not InCombatLockdown() then
        button:EnableMouse(shownAlpha() > 0)
    end
    draw()
end

-- QuestieDB matches bag items to quests, and says where a quest is when the game doesn't, so
-- it's asked for (and loaded, if it loads on demand) only while Quest Items in Your Bags or Only
-- Near Its Quest is on.
local function wantQuestie()
    if module.db.bags or module.db.near then
        QuestieDB.OnReady(onQuestieReady)
    else
        QuestieDB.Cancel(onQuestieReady)
    end
end

-- Short Keybinds turned on or off: the key label follows it.
ns.Providers.OnChanged("shortKeybinds", function()
    if module.enabled then
        draw()
    end
end)

function module:OnEnable()
    self:On("QUEST_LOG_UPDATE", queue)
    self:On("BAG_UPDATE_DELAYED", queue)
    self:On("SUPER_TRACKING_CHANGED", update)
    self:On("ZONE_CHANGED_NEW_AREA", queue)
    self:On("PLAYER_REGEN_ENABLED", update)
    self:On("BAG_UPDATE_COOLDOWN", draw)
    self:On("UPDATE_BINDINGS", draw)
    wantQuestie()
    -- The button is secure: made, placed, and given to Edit Mode out of combat.
    ns.AfterCombat(function()
        if not module.enabled then
            return
        end
        if not button then
            build()
        end
        place()
        ns.EditMode.RegisterModule(module, button, L.QUESTITEMBUTTON_TITLE, place, onEditMode)
    end)
    apply()
    queue()
end

function module:OnDisable()
    QuestieDB.Cancel(onQuestieReady)
    wipe(candidates)
    wipe(quests)
    wipe(points)
    wipe(spots)
    wipe(elsewhere)
    spotsMap, wanted, wantedQuest, editing = nil, nil, nil, false
    if button then
        button:SetAlpha(0)
    end
    ns.AfterCombat(function()
        if button and not module.enabled then
            ns.EditMode.Unregister(button)
        end
    end)
    apply()
end

function module:OnOptionChanged(key)
    if key == "bags" then
        wantQuestie()
        queue()
    elseif key == "near" then
        wantQuestie()
        update()
    elseif key == "selected" or key == "nearYards" then
        update()
    else
        apply()
    end
end
