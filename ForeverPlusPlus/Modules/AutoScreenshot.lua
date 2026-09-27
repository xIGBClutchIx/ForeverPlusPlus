-- Auto Screenshot: takes a screenshot when something worth keeping happens: a level up, an
-- achievement, good loot, a boss kill, and more, each with its own checkbox. The shot waits a
-- moment so Blizzard's toast is on screen, and can leave the interface out.
local _, ns = ...

local ipairs, pairs, format, tonumber, type = ipairs, pairs, string.format, tonumber, type
local C_Timer, C_Item, C_EventUtils = C_Timer, C_Item, C_EventUtils
local Screenshot, InCombatLockdown, UIParent = Screenshot, InCombatLockdown, UIParent
local GetNumTitles, IsTitleKnown, GetTime = GetNumTitles, IsTitleKnown, GetTime

local L = ns.L
local readable = ns.IsReadable

local module = ns.NewModule("AutoScreenshot", L.AUTOSCREENSHOT_DESC, {
    enabled = false,
    levelUp = true,
    achievement = true,
    loot = false,
    lootQuality = "4", -- Enum.ItemQuality: 3 rare, 4 epic, 5 legendary
    bossKill = true,
    reputation = false,
    pvpRank = false,
    title = false,
    battleground = false,
    death = false,
    hideUI = false,
    chat = true,
})
module.title = L.AUTOSCREENSHOT_TITLE
module.category = "interface"

local GENERAL, EVENTS = L.AUTOSCREENSHOT_SECTION_GENERAL, L.AUTOSCREENSHOT_SECTION_EVENTS

module.options = {
    { key = "hideUI", name = L.AUTOSCREENSHOT_HIDE_UI, description = L.AUTOSCREENSHOT_HIDE_UI_DESC,
        section = GENERAL },
    ns.ChatOption(L.AUTOSCREENSHOT_CHAT_DESC, GENERAL),
    { key = "levelUp", name = L.AUTOSCREENSHOT_LEVEL_UP, description = L.AUTOSCREENSHOT_LEVEL_UP_DESC,
        section = EVENTS },
    { key = "achievement", name = L.AUTOSCREENSHOT_ACHIEVEMENT,
        description = L.AUTOSCREENSHOT_ACHIEVEMENT_DESC, section = EVENTS },
    { key = "loot", name = L.AUTOSCREENSHOT_LOOT, description = L.AUTOSCREENSHOT_LOOT_DESC,
        section = EVENTS },
    {
        key = "lootQuality",
        name = L.AUTOSCREENSHOT_LOOT_QUALITY,
        description = L.AUTOSCREENSHOT_LOOT_QUALITY_DESC,
        section = EVENTS,
        choices = {
            { "3", L.AUTOSCREENSHOT_QUALITY_RARE },
            { "4", L.AUTOSCREENSHOT_QUALITY_EPIC },
            { "5", L.AUTOSCREENSHOT_QUALITY_LEGENDARY },
        },
    },
    { key = "bossKill", name = L.AUTOSCREENSHOT_BOSS_KILL, description = L.AUTOSCREENSHOT_BOSS_KILL_DESC,
        section = EVENTS },
    { key = "reputation", name = L.AUTOSCREENSHOT_REPUTATION,
        description = L.AUTOSCREENSHOT_REPUTATION_DESC, section = EVENTS },
    { key = "pvpRank", name = L.AUTOSCREENSHOT_PVP_RANK, description = L.AUTOSCREENSHOT_PVP_RANK_DESC,
        section = EVENTS },
    { key = "title", name = L.AUTOSCREENSHOT_NEW_TITLE, description = L.AUTOSCREENSHOT_NEW_TITLE_DESC,
        section = EVENTS },
    { key = "battleground", name = L.AUTOSCREENSHOT_BATTLEGROUND,
        description = L.AUTOSCREENSHOT_BATTLEGROUND_DESC, section = EVENTS },
    { key = "death", name = L.AUTOSCREENSHOT_DEATH, description = L.AUTOSCREENSHOT_DEATH_DESC,
        section = EVENTS },
}

local DELAY = 1 -- seconds after the event, so its toast is on screen
local HIDE_WAIT = 0.1 -- seconds between hiding the interface and the shot, so it's drawn without
local UI_BACK = 3 -- seconds before the interface comes back if the game never reports the shot
-- Forever's PvP rank is the renown level of this faction (Blizzard's Camelot PVPRankFrame.lua).
local PVP_RANK_FACTION = 2800

-- Taking a picture ----------------------------------------------------------------------------

local timer -- the pending shot, or nil
local reason -- what the pending or last shot is for, for chat
local hidden = false -- the interface is hidden for a shot and must come back
local showUI

local function onShot(event)
    ns.Off("SCREENSHOT_SUCCEEDED", onShot)
    ns.Off("SCREENSHOT_FAILED", onShot)
    showUI()
    -- Said now rather than when asked, so the chat line isn't in the picture.
    if event == "SCREENSHOT_SUCCEEDED" and reason then
        module:Print(format(L.AUTOSCREENSHOT_TAKEN, reason))
    end
end

-- Brings the interface back. Showing it can be blocked in combat, so it waits for combat to end
-- then; combat starting is also a cue, since that's the last moment it can.
function showUI()
    if not hidden then
        return
    end
    if InCombatLockdown() then
        ns.AfterCombat(showUI)
        return
    end
    hidden = false
    ns.Off("PLAYER_REGEN_DISABLED", showUI)
    UIParent:Show()
end

local function take()
    timer = nil
    ns.On("SCREENSHOT_SUCCEEDED", onShot)
    ns.On("SCREENSHOT_FAILED", onShot)
    -- Hiding the interface in combat can be blocked, and so can showing it again, so only out of
    -- combat. If the player hid it themselves (Alt-Z), it's already out of the way.
    if module.db.hideUI and not InCombatLockdown() and UIParent:IsShown() then
        hidden = true
        ns.On("PLAYER_REGEN_DISABLED", showUI)
        UIParent:Hide()
        C_Timer.After(HIDE_WAIT, Screenshot)
        C_Timer.After(UI_BACK, showUI)
    else
        Screenshot()
    end
end

-- Asks for a shot a moment from now. Things that happen together (a level up that also earns an
-- achievement) share one shot, named for the first.
local function request(why)
    if timer or not module.enabled then
        return
    end
    reason = why
    timer = C_Timer.NewTimer(DELAY, take)
end

-- Reading chat lines --------------------------------------------------------------------------

-- A Lua pattern for one of the client's chat formats, such as LOOT_ITEM_SELF ("You receive loot:
-- %s."), capturing each %s and %d. Nil if the client doesn't have that format.
local function toPattern(text)
    if type(text) ~= "string" then
        return nil
    end
    text = text:gsub("%%%d+%$", "%%") -- "%1$s" (reordered, in some languages) is "%s"
    text = text:gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")
    text = text:gsub("%%s", "(.+)")
    text = text:gsub("%%d", "(%%d+)")
    return "^" .. text .. "$"
end

local lootPatterns -- built the first time, from the client's own (translated) formats
local function getLootPatterns()
    if not lootPatterns then
        lootPatterns = {}
        for _, text in ipairs({ LOOT_ITEM_SELF_MULTIPLE, LOOT_ITEM_SELF,
            LOOT_ITEM_PUSHED_SELF_MULTIPLE, LOOT_ITEM_PUSHED_SELF }) do
            lootPatterns[#lootPatterns + 1] = toPattern(text)
        end
    end
    return lootPatterns
end

local standingPattern -- "You are now %s with %s."
local lowStandings -- Hated to Unfriendly, male and female: reaching these is a step down
local function getStanding()
    if standingPattern == nil then
        standingPattern = toPattern(FACTION_STANDING_CHANGED) or false
        lowStandings = {}
        for i = 1, 4 do
            for _, text in ipairs({ _G["FACTION_STANDING_LABEL" .. i],
                _G["FACTION_STANDING_LABEL" .. i .. "_FEMALE"] }) do
                lowStandings[text] = true
            end
        end
    end
    return standingPattern
end

-- Events --------------------------------------------------------------------------------------

local function onLoot(_, text)
    if not readable(text) or type(text) ~= "string" then
        return
    end
    for _, pattern in ipairs(getLootPatterns()) do
        local link = text:match(pattern)
        if link then
            local item = link:match("|H(item:[^|]+)|h")
            local quality = item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(item)
            if readable(quality) and quality and quality >= (tonumber(module.db.lootQuality) or 4) then
                request(L.AUTOSCREENSHOT_LOOT)
            end
            return
        end
    end
end

local function onStanding(_, text)
    local pattern = getStanding()
    if not (pattern and readable(text) and type(text) == "string") then
        return
    end
    local standing = text:match(pattern)
    if standing and not lowStandings[standing] then
        request(L.AUTOSCREENSHOT_REPUTATION)
    end
end

local TITLES_SETTLE = 10 -- seconds after login (or turning on) while the title list may still fill in
local knownTitles = 0
local countedAt = 0 -- when knownTitles was first counted

local function countTitles()
    local count = 0
    if GetNumTitles and IsTitleKnown then
        for i = 1, GetNumTitles() do
            if IsTitleKnown(i) then
                count = count + 1
            end
        end
    end
    return count
end

local function onTitles(_, unit)
    if unit ~= nil and not (readable(unit) and unit == "player") then
        return
    end
    local count = countTitles()
    -- Right after login the list can arrive late, which looks like new titles.
    if count > knownTitles and GetTime() - countedAt > TITLES_SETTLE then
        request(L.AUTOSCREENSHOT_NEW_TITLE)
    end
    knownTitles = count
end

-- Each checkbox's events. Handlers get the event's name, then its payload.
local HANDLERS = {
    levelUp = { PLAYER_LEVEL_UP = function()
        request(L.AUTOSCREENSHOT_LEVEL_UP)
    end },
    achievement = { ACHIEVEMENT_EARNED = function(_, _, alreadyEarned)
        -- Already earned means on another character; this one only caught up.
        if not (readable(alreadyEarned) and alreadyEarned) then
            request(L.AUTOSCREENSHOT_ACHIEVEMENT)
        end
    end },
    loot = { CHAT_MSG_LOOT = onLoot },
    bossKill = { ENCOUNTER_END = function(_, _, _, _, _, success)
        if readable(success) and success == 1 then
            request(L.AUTOSCREENSHOT_BOSS_KILL)
        end
    end },
    -- Which chat event carries "You are now Friendly with ..." isn't certain on this client, so
    -- both; the line only comes once.
    reputation = { CHAT_MSG_SYSTEM = onStanding, CHAT_MSG_COMBAT_FACTION_CHANGE = onStanding },
    pvpRank = { MAJOR_FACTION_RENOWN_LEVEL_CHANGED = function(_, factionID, new, old)
        if readable(factionID) and readable(new) and readable(old)
            and factionID == PVP_RANK_FACTION and new > old then
            request(L.AUTOSCREENSHOT_PVP_RANK)
        end
    end },
    title = { KNOWN_TITLES_UPDATE = onTitles },
    battleground = { PVP_MATCH_COMPLETE = function()
        request(L.AUTOSCREENSHOT_BATTLEGROUND)
    end },
    death = { PLAYER_DEAD = function()
        request(L.AUTOSCREENSHOT_DEATH)
    end },
}

-- Registering an event the client doesn't have is an error, and Forever is a beta.
local function exists(event)
    return not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event)
end

-- Listens for the events of the checkboxes that are on, and stops the rest.
local function sync()
    for key, events in pairs(HANDLERS) do
        local on = module.enabled and module.db[key]
        for event, fn in pairs(events) do
            if on and exists(event) then
                module:On(event, fn)
            else
                module:Off(event, fn)
            end
        end
    end
    if module.enabled and module.db.title and countedAt == 0 then
        knownTitles = countTitles()
        countedAt = GetTime()
    end
    if not (module.enabled and module.db.title) then
        countedAt = 0
    end
end

function module:OnEnable()
    sync()
end

function module:OnDisable()
    if timer then
        timer:Cancel()
        timer = nil
    end
    ns.Off("SCREENSHOT_SUCCEEDED", onShot)
    ns.Off("SCREENSHOT_FAILED", onShot)
    showUI()
end

function module:OnOptionChanged()
    sync()
end
