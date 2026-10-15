-- Screenshots: a Debug page button (and `/fpp shots`) that takes the addon's gallery pictures from
-- the real game, one scene at a time: it turns on the modules a scene shows, waits for the scene
-- to be on screen and drawn, takes a screenshot, and puts the modules back. Our code never opens
-- Blizzard's windows (the world map, bags, character window, talents): a window opened from addon
-- code runs its setup tainted, and Blizzard's own code then errors on secret values (the player
-- frame's health text did). So it asks the player to open each one and takes the shot once it's
-- open. It does the rest itself: an item tooltip, the minimap button's tooltip, and Settings
-- (opened through the client, which doesn't taint). A scene left unopened is skipped and named in
-- chat at the end. `/fpp shots wait` takes the screen as it is after a countdown, for what needs
-- the world (nameplates, a merchant, the waypoint arrow, a right-click menu). Nothing runs until
-- it's asked for, and never in combat.
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
local POLL = 0.25 -- seconds between looks for a window the player opens
local OPEN_TIMEOUT = 45 -- seconds to wait for the player to open a window
local DRAW_WAIT = 1.5 -- seconds for a scene to draw before its shot
local GAP = 0.5 -- seconds between one scene's shot and the next scene
local SHOT_TIMEOUT = 5 -- seconds to wait for the game to say a shot was saved
local CAPTURED_WAIT = 4 -- seconds at most to wait for "Screen captured" to fade

local function shown(frame)
    return frame and frame:IsShown() and true or false
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
-- set for the shot), `isShown()` (the shot waits for it, and a scene that isn't on screen isn't
-- pictured), and how long to `wait` to draw. A scene we set up has `open()` (returns why it
-- can't, or nil) and `close()`; one the player opens has `binding`, the key binding that opens it.

local SCENES = {
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
    {
        id = "map",
        name = L.SCREENSHOTS_SCENE_MAP,
        modules = { WorldMap = { pointsOfInterest = true, zoneInfo = true, hover = false } },
        binding = "TOGGLEWORLDMAP",
        wait = 2,
        isShown = function() return shown(WorldMapFrame) end,
    },
    {
        id = "bags",
        name = L.SCREENSHOTS_SCENE_BAGS,
        modules = { AlreadyKnown = {}, UnusableItemsTint = {}, BagSlotCounter = {} },
        binding = "OPENALLBAGS",
        isShown = function() return shown(ContainerFrameCombinedBags) or shown(ContainerFrame1) end,
    },
    {
        id = "character",
        name = L.SCREENSHOTS_SCENE_CHARACTER,
        modules = { CharacterWindow = {} },
        binding = "TOGGLECHARACTER0",
        isShown = function() return shown(PaperDollFrame) end,
    },
    {
        id = "skills",
        name = L.SCREENSHOTS_SCENE_SKILLS,
        modules = { CharacterWindow = {} },
        -- Forever only: the Classic Skills tab. Its key binding varies, so none is named.
        isShown = function() return shown(SkillsFrame) end,
        unavailable = function() return not SkillsFrame and L.SCREENSHOTS_NO_SKILLS end,
    },
    {
        id = "talents",
        name = L.SCREENSHOTS_SCENE_TALENTS,
        modules = { TalentPlanner = {} },
        binding = "TOGGLETALENTS",
        wait = 2,
        isShown = function()
            return shown(PlayerSpellsFrame) and shown(PlayerSpellsFrame.TalentsFrame)
        end,
    },
    {
        -- Last, since it stays open for the player to close.
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
local waited = 0 -- seconds spent waiting on the player, or on "Screen captured" to fade
local nextScene, onShot, stop

-- Puts away what the scene on screen set up, and the modules it turned on.
local function closeScene()
    if current and current.close then
        pcall(current.close)
    end
    current = nil
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

local function shoot()
    if current.isShown and not current.isShown() then
        skip(current, L.SCREENSHOTS_NO_WINDOW)
        return
    end
    -- Blizzard's "Screen captured" from the last shot would be in this one.
    if shown(ActionStatus) and waited < CAPTURED_WAIT then
        waited = waited + POLL
        timer:Start(POLL, shoot)
        return
    end
    waited = 0
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

-- Waits for the player to open the scene's window, then gives it time to draw.
local function waitForPlayer()
    if current.isShown() then
        waited = 0
        timer:Start(current.wait or DRAW_WAIT, shoot)
    elseif waited >= OPEN_TIMEOUT then
        waited = 0
        skip(current, L.SCREENSHOTS_NOT_OPENED)
    else
        waited = waited + POLL
        timer:Start(POLL, waitForPlayer)
    end
end

-- "Open the Bags (B)." with the key the player has bound, if any.
local function askToOpen(scene)
    local key = scene.binding and GetBindingKey and GetBindingKey(scene.binding)
    if key then
        ns.Print(format(L.SCREENSHOTS_OPEN_KEY, scene.name, GetBindingText and GetBindingText(key) or key))
    else
        ns.Print(format(L.SCREENSHOTS_OPEN, scene.name))
    end
end

function nextScene()
    step = step + 1
    local scene = queue[step]
    if not scene then
        finish()
        return
    end
    current = scene
    local why = scene.unavailable and scene.unavailable()
    if why then
        skip(scene, why)
        return
    end
    for name, options in pairs(scene.modules or {}) do
        if not use(name, options) then
            skip(scene, format(L.SCREENSHOTS_NO_MODULE, name))
            return
        end
    end
    if not scene.open then
        if not scene.isShown() then
            askToOpen(scene)
        end
        waited = 0
        waitForPlayer()
        return
    end
    local ok
    ok, why = pcall(scene.open)
    if not ok or why then
        skip(scene, why and tostring(why) or L.SCREENSHOTS_NO_WINDOW)
        return
    end
    timer:Start(scene.wait or DRAW_WAIT, shoot)
end

-- Combat started: stop, and put the modules back once it's over.
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

-- Settings is open when the run starts from the Debug page; the player closes it (closing it from
-- our code would taint it), then the scenes start.
local function waitForSettings()
    if not shown(SettingsPanel) then
        waited = 0
        timer:Start(GAP, nextScene)
    elseif waited >= OPEN_TIMEOUT then
        finish()
    else
        waited = waited + POLL
        timer:Start(POLL, waitForSettings)
    end
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
        return { { name = L.SCREENSHOTS_SCENE_SCREEN, wait = seconds, open = function() end } },
            seconds
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
    queue, step, taken, skipped, current, waited = scenes, 0, 0, {}, nil, 0
    ns.On("PLAYER_REGEN_DISABLED", stop)
    -- PNG at full quality for the gallery; the player's own format comes back at the end.
    ns.CVars.Set(cvars, "screenshotFormat", "png")
    ns.CVars.Set(cvars, "screenshotQuality", "10")
    if seconds then
        ns.Print(format(L.SCREENSHOTS_WAIT, seconds))
        nextScene()
        return
    end
    ns.Print(format(L.SCREENSHOTS_START, #scenes))
    if shown(SettingsPanel) then
        ns.Print(L.SCREENSHOTS_CLOSE_SETTINGS)
    end
    waitForSettings()
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
