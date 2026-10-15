-- Screenshots: a Debug page button (and `/fpp shots`) that takes the addon's gallery pictures from
-- the real game: it opens one window at a time (the world map, an item tooltip, the bags, the
-- character window, talents, Settings, the minimap button's tooltip), waits for it to draw, takes
-- a screenshot, and puts it away again. The modules a scene shows are turned on just for its shot
-- and put back after, through Core as the Modules page does. A scene that can't be set up honestly
-- (no Skills tab, the window didn't open) is skipped and named in chat at the end. `/fpp shots
-- wait` takes the screen as it is after a countdown, for what needs the world (nameplates, a
-- merchant, the waypoint arrow, a right-click menu). Nothing runs until it's asked for, and never
-- in combat.
local _, ns = ...

local ipairs, pairs, pcall, type, tostring, tonumber = ipairs, pairs, pcall, type, tostring, tonumber
local format = string.format
local tconcat, min, max, floor = table.concat, math.min, math.max, math.floor
local Screenshot, InCombatLockdown, C_Container = Screenshot, InCombatLockdown, C_Container
local L = ns.L

local module = ns.NewModule("Screenshots", L.SCREENSHOTS_DESC, { enabled = true })
module.title = L.SCREENSHOTS_TITLE
module.alwaysOn = true -- a tool, not a change to the game

-- The tooltip's item when nothing in the bags sells.
local LINEN_CLOTH = ns.GameData.Item(2589, "Linen Cloth")
local START_WAIT = 1 -- seconds for Settings to close before the first scene
local DRAW_WAIT = 1.5 -- seconds for a scene to draw before its shot
local GAP = 0.5 -- seconds between putting one scene away and opening the next
local SHOT_TIMEOUT = 5 -- seconds to wait for the game to say a shot was saved
local CAPTURED_WAIT = 4 -- seconds at most to wait for "Screen captured" to fade

-- Blizzard windows ------------------------------------------------------------------------------

local function shown(frame)
    return frame and frame:IsShown() and true or false
end

local function hide(frame)
    if shown(frame) then
        HideUIPanel(frame)
    end
end

local function closeSettings()
    hide(SettingsPanel)
end

-- The bag slot holding the biggest stack that sells, for a Sell Price line worth showing.
local function bestStack()
    if not (C_Container and C_Container.GetContainerNumSlots) then
        return nil
    end
    local bestBag, bestSlot, most = nil, nil, 0
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not info.hasNoValue and (info.stackCount or 0) > most then
                bestBag, bestSlot, most = bag, slot, info.stackCount
            end
        end
    end
    return bestBag, bestSlot
end

-- The scenes ------------------------------------------------------------------------------------
-- Each has an `id` for `/fpp shots <id>`, a `name`, the `modules` it shows (module -> options to
-- set for the shot), `open()` (returns why it can't, or nil), `close()`, `isShown()` (checked
-- before the shot, so a window that didn't open isn't pictured), and how long to `wait` to draw.

local SCENES = {
    {
        id = "map",
        name = L.SCREENSHOTS_SCENE_MAP,
        modules = { WorldMap = { pointsOfInterest = true, zoneInfo = true, hover = false } },
        wait = 2,
        open = function()
            local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if not (mapID and WorldMapFrame) then
                return L.SCREENSHOTS_NO_ZONE
            end
            if OpenWorldMap then
                OpenWorldMap(mapID)
            else
                ShowUIPanel(WorldMapFrame)
                WorldMapFrame:SetMapID(mapID)
            end
        end,
        isShown = function() return shown(WorldMapFrame) end,
        close = function() hide(WorldMapFrame) end,
    },
    {
        id = "tooltip",
        name = L.SCREENSHOTS_SCENE_TOOLTIP,
        modules = { ItemTooltips = { sellPrice = true, itemCount = true, auction = true } },
        open = function()
            local tooltip = GameTooltip
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            tooltip:ClearAllPoints()
            tooltip:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
            local bag, slot = bestStack()
            if bag then
                tooltip:SetBagItem(bag, slot)
            else
                tooltip:SetItemByID(LINEN_CLOTH)
            end
            tooltip:Show()
        end,
        isShown = function() return shown(GameTooltip) end,
        close = function() GameTooltip:Hide() end,
    },
    {
        id = "bags",
        name = L.SCREENSHOTS_SCENE_BAGS,
        modules = { AlreadyKnown = {}, UnusableItemsTint = {}, BagSlotCounter = {} },
        open = function()
            OpenAllBags()
        end,
        isShown = function() return shown(ContainerFrameCombinedBags) or shown(ContainerFrame1) end,
        close = function() CloseAllBags() end,
    },
    {
        id = "character",
        name = L.SCREENSHOTS_SCENE_CHARACTER,
        modules = { CharacterWindow = {} },
        open = function()
            ToggleCharacter("PaperDollFrame", true)
        end,
        isShown = function() return shown(PaperDollFrame) end,
        close = function() hide(CharacterFrame) end,
    },
    {
        id = "skills",
        name = L.SCREENSHOTS_SCENE_SKILLS,
        modules = { CharacterWindow = {} },
        open = function()
            if not SkillsFrame then -- Forever only: the Classic Skills tab
                return L.SCREENSHOTS_NO_SKILLS
            end
            ToggleCharacter("SkillsFrame", true)
        end,
        isShown = function() return shown(SkillsFrame) end,
        close = function() hide(CharacterFrame) end,
    },
    {
        id = "talents",
        name = L.SCREENSHOTS_SCENE_TALENTS,
        modules = { TalentPlanner = {} },
        wait = 2,
        open = function()
            local addon = "Blizzard_PlayerSpells" -- the talent window, load on demand
            if C_AddOns and C_AddOns.LoadAddOn and not ns.AddOns.IsLoaded(addon) then
                C_AddOns.LoadAddOn(addon)
            end
            if PlayerSpellsUtil and PlayerSpellsUtil.OpenToClassTalentsTab then
                PlayerSpellsUtil.OpenToClassTalentsTab()
            elseif PlayerSpellsFrame then
                ShowUIPanel(PlayerSpellsFrame)
            else
                return L.SCREENSHOTS_NO_WINDOW
            end
        end,
        isShown = function()
            return shown(PlayerSpellsFrame) and shown(PlayerSpellsFrame.TalentsFrame)
        end,
        close = function() hide(PlayerSpellsFrame) end,
    },
    {
        id = "settings",
        name = L.SCREENSHOTS_SCENE_SETTINGS,
        modules = { WorldMap = {} },
        wait = 2.5,
        open = function()
            if not ns.OpenSettings("WorldMap") then
                return L.SCREENSHOTS_NO_WINDOW
            end
        end,
        isShown = function() return shown(SettingsPanel) end,
        close = closeSettings,
    },
    {
        id = "minimap",
        name = L.SCREENSHOTS_SCENE_MINIMAP,
        modules = { MinimapButton = { where = "minimap" } },
        open = function()
            local button = ns.modules.MinimapButton
            if not (button.ShowTooltip and button.ShowTooltip()) then
                return L.SCREENSHOTS_NO_BUTTON
            end
        end,
        isShown = function() return shown(GameTooltip) end,
        close = function() GameTooltip:Hide() end,
    },
}

-- Turning modules on for a shot -----------------------------------------------------------------

local changed = {} -- { module name, key ("enabled" or an option), value to put back }, oldest first

-- Turns a module on with `options` set, remembering what to put back. False when this client
-- doesn't have it.
local function use(name, options)
    local other = ns.modules[name]
    if not other or other.unavailable then
        return false
    end
    if not other.enabled then
        changed[#changed + 1] = { name, "enabled", false }
        ns.SetEnabled(name, true)
    end
    for key, value in pairs(options) do
        local old = other.db[key]
        if old ~= value then
            changed[#changed + 1] = { name, key, old }
            ns.SetOption(name, key, value)
        end
    end
    ns.RefreshSetting(name)
    return true
end

local function putBack()
    for i = #changed, 1, -1 do
        local name, key, old = changed[i][1], changed[i][2], changed[i][3]
        if key == "enabled" then
            ns.SetEnabled(name, old)
        else
            ns.SetOption(name, key, old)
        end
        ns.RefreshSetting(name)
        changed[i] = nil
    end
end

-- Running the scenes ----------------------------------------------------------------------------

local timer = ns.Frames.Timer()
local cvars = {} -- the player's screenshot CVars, put back at the end
local queue, step, taken, skipped, current
local nextScene, onShot, stop

-- Puts the scene on screen away, and the modules it turned on.
local function closeScene()
    if current then
        pcall(current.close)
        current = nil
    end
    putBack()
end

local function finish()
    timer:Cancel()
    ns.Off("SCREENSHOT_SUCCEEDED", onShot)
    ns.Off("SCREENSHOT_FAILED", onShot)
    ns.Off("PLAYER_REGEN_DISABLED", stop)
    ns.CVars.RestoreAll(cvars)
    queue = nil
    ns.Print(format(L.SCREENSHOTS_DONE, taken))
    for _, line in ipairs(skipped) do
        ns.Print(line)
    end
end

local function skip(scene, why)
    skipped[#skipped + 1] = format(L.SCREENSHOTS_SKIPPED, scene.name, why)
    closeScene()
    timer:Start(GAP, nextScene)
end

local held = 0 -- seconds this shot has waited for the last one's "Screen captured" to go

local function shoot()
    if current.isShown and not current.isShown() then
        skip(current, L.SCREENSHOTS_NO_WINDOW)
        return
    end
    -- Blizzard's "Screen captured" from the last shot would be in this one.
    if shown(ActionStatus) and held < CAPTURED_WAIT then
        held = held + 0.25
        timer:Start(0.25, shoot)
        return
    end
    held = 0
    ns.On("SCREENSHOT_SUCCEEDED", onShot)
    ns.On("SCREENSHOT_FAILED", onShot)
    timer:Start(SHOT_TIMEOUT, function() onShot("SCREENSHOT_FAILED") end)
    Screenshot()
end

function onShot(event)
    ns.Off("SCREENSHOT_SUCCEEDED", onShot)
    ns.Off("SCREENSHOT_FAILED", onShot)
    if event == "SCREENSHOT_SUCCEEDED" then
        taken = taken + 1
    else
        skipped[#skipped + 1] = format(L.SCREENSHOTS_SKIPPED, current.name, L.SCREENSHOTS_FAILED)
    end
    closeScene()
    timer:Start(GAP, nextScene)
end

function nextScene()
    step = step + 1
    local scene = queue[step]
    if not scene then
        finish()
        return
    end
    current = scene
    for name, options in pairs(scene.modules or {}) do
        if not use(name, options) then
            skip(scene, format(L.SCREENSHOTS_NO_MODULE, name))
            return
        end
    end
    local ok, why = pcall(scene.open)
    if not ok or why then
        skip(scene, why and tostring(why) or L.SCREENSHOTS_NO_WINDOW)
        return
    end
    timer:Start(scene.wait or DRAW_WAIT, shoot)
end

-- Combat started: stop, and put everything away once it's over (some windows can't close in it).
function stop()
    timer:Cancel()
    ns.Off("SCREENSHOT_SUCCEEDED", onShot)
    ns.Off("SCREENSHOT_FAILED", onShot)
    ns.Print(L.SCREENSHOTS_STOPPED)
    local scene = current
    current = nil
    queue = {}
    step = 0
    ns.AfterCombat(function()
        current = scene
        closeScene()
        finish()
    end)
end

local function scenesText()
    local ids = {}
    for i, scene in ipairs(SCENES) do
        ids[i] = scene.id
    end
    ids[#ids + 1] = "wait"
    return tconcat(ids, ", ")
end

-- The scenes `/fpp shots <rest>` asks for: every one, one by its id, or the screen after a wait.
local function pick(rest)
    local word, number = rest:match("^(%S*)%s*(%S*)")
    word = word:lower()
    if word == "" then
        return SCENES
    end
    if word == "wait" then
        local seconds = max(1, min(30, floor(tonumber(number) or 5)))
        return { { name = L.SCREENSHOTS_SCENE_SCREEN, wait = seconds, open = function() end,
            close = function() end } }, seconds
    end
    for _, scene in ipairs(SCENES) do
        if scene.id == word then
            return { scene }
        end
    end
    ns.Print(format(L.SCREENSHOTS_UNKNOWN, word, scenesText()))
end

---Takes the screenshots `rest` asks for (see `pick`): every scene when empty.
---@param rest? string
function module.Run(rest)
    if queue then
        ns.Print(L.SCREENSHOTS_BUSY)
        return
    end
    if InCombatLockdown() then
        ns.Print(L.SCREENSHOTS_COMBAT)
        return
    end
    local scenes, seconds = pick(type(rest) == "string" and rest or "")
    if not scenes then
        return
    end
    queue, step, taken, skipped, current = scenes, 0, 0, {}, nil
    ns.On("PLAYER_REGEN_DISABLED", stop)
    -- PNG at full quality for the gallery; the player's own format comes back at the end.
    ns.CVars.Set(cvars, "screenshotFormat", "png")
    ns.CVars.Set(cvars, "screenshotQuality", "10")
    held = 0
    if seconds then
        ns.Print(format(L.SCREENSHOTS_WAIT, seconds))
        nextScene()
        return
    end
    ns.Print(format(L.SCREENSHOTS_START, #scenes))
    -- Not from inside the Debug page's click: Settings closes first, then the scenes start.
    timer:Start(0.1, function()
        closeSettings()
        timer:Start(START_WAIT, nextScene)
    end)
end

-- Shown on the Debug page (Settings/Debug.lua).
module.debugActions = {
    {
        name = L.SCREENSHOTS_TITLE,
        button = L.SCREENSHOTS_BUTTON,
        description = L.SCREENSHOTS_BUTTON_DESC,
        fn = function() module.Run() end,
        section = L.DEBUG_SECTION_TESTING,
    },
}

ns.AddCommand("shots", "[scene | wait seconds]", L.SCREENSHOTS_COMMAND, module.Run)
