-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page. Few entries, so the sidebar stays short:
--   Forever++        the Modules page: every module (the only place modules turn on and off) in
--                    a list on the left, with a checkbox each, under a label per
--                    `module.category`. Clicking one shows
--                    it on the right: its title, category and description, its Enabled
--                    checkbox, its `notice` (a warning) while that applies, then its options
--                    (checkboxes, dropdowns and sliders) and buttons (from `module.actions`),
--                    greyed out while it's off. An option can sit under another (`requires`).
--                    A module made of parts (`module:NewPart`) has a section for each, headed by
--                    the part's Enabled checkbox, with the part's options greyed out while it's off.
--                    `alwaysOn` modules (tools) aren't listed. A search box at the top narrows
--                    the list to modules by title and description, or by an option's name or
--                    description, and highlights those options. A module or option added
--                    since the player last looked (`added`), or an option changed since then
--                    (`changed`), is marked NEW
--     <Tool>         a page a module draws itself (`BuildPage`)
--     Debug          sections of Forever++'s own rows and modules' options marked `debug = true`
--                    and buttons from `module.debugActions`, each placed by its `section`: What's
--                    New (Show Tags, Reset Seen Version, Reset Welcome), Diagnostics (Copy Debug
--                    Info, Print Module Events, Reload UI), Testing, and Logging
--     Changelog      the releases in Changelog.lua in a list like the Modules page's, with the
--                    selected one's notes beside it, and a search box and the Defaults button
--                    at the top like Modules
--     About          what the addon is, how many modules are on, the version, links, and the /fpp
--                    commands, with the Defaults button at the top right like Modules
-- Without subpages (an older Settings API), the Modules page is the only page.
local _, ns = ...

local ipairs, pairs, next, format, type, sort = ipairs, pairs, next, string.format, type, table.sort
local strlower, concat = string.lower, table.concat
local min, max, pcall, tostring = math.min, math.max, pcall, tostring
local InCombatLockdown, CreateFrame, GetBuildInfo = InCombatLockdown, CreateFrame, GetBuildInfo
local wipe = wipe
local GameTooltip = GameTooltip
local C_Timer = C_Timer
local L = ns.L
local hasTemplate, hasAtlas = ns.Frames.HasTemplate, ns.Frames.HasAtlas

local settings = {} -- module name -> its Blizzard setting objects, to refresh after /fpp changes
local modulesCategory -- the Modules page, the top Forever++ entry, for /fpp
local pages = {} -- module name -> the page it draws itself, for ns.OpenSettings(name)
local aboutCategory -- the About page, for ns.OpenAbout

-- Opens a Forever++ page (after combat, if the player is in combat).
local function open(category)
    if not (category and Settings.OpenToCategory and category.GetID) then
        return false
    end
    if InCombatLockdown() then
        ns.Print(L.SETTINGS_AFTER_COMBAT)
    end
    ns.AfterCombat(function()
        -- Through the client when it can: it opens the panel from its own event, so Blizzard's
        -- pages (and the pooled rows they share) aren't set up while our code is running, which
        -- taints them (the Nameplates preview and Discord buttons then error).
        if C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel then
            C_SettingsUtil.OpenSettingsPanel(category:GetID())
        else
            Settings.OpenToCategory(category:GetID())
        end
    end)
    return true
end

-- A frame for a page drawn by `build(frame)` instead of from settings, such as a list. Settings
-- needs the frame now, so it starts empty and is filled the first time it's shown. It starts
-- hidden: a new frame is shown, and Settings showing a frame that already is doesn't fire OnShow,
-- so the page stayed empty until the player left it and came back.
local function canvasFrame(build)
    local frame = CreateFrame("Frame")
    frame:Hide()
    local built = false
    frame:SetScript("OnShow", function(self)
        if not built then
            built = true
            build(self)
        end
    end)
    return frame
end

local function addCanvasPage(category, name, build)
    return Settings.RegisterCanvasLayoutSubcategory(category, canvasFrame(build), name)
end

---Puts a page's title and the divider under it at the top of a drawn page, like Blizzard's own
---Settings pages.
---@param frame table the page
---@param text string
function ns.AddPageTitle(frame, text)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 7, -22)
    title:SetText(text)
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetAtlas("Options_HorizontalDivider", true)
    divider:SetPoint("TOP", 0, -50)
end

-- A scrolling area for a drawn page. Probe: fall back to the older template if Mainline's (the
-- thin scroll bar) isn't on this client.
local function newScroll(parent)
    local template = "ScrollFrameTemplate"
    if not hasTemplate(template) then
        template = "UIPanelScrollFrameTemplate"
    end
    return CreateFrame("ScrollFrame", nil, parent, template)
end

local function track(module, setting)
    local list = settings[module.name] or {}
    settings[module.name] = list
    list[#list + 1] = setting
end

-- Blizzard's Defaults button asks "These Settings" or "All Settings". All Settings sets every
-- setting in the panel to its default, every addon's included, so one misclick would throw away
-- every Forever++ choice. While Blizzard is setting defaults our setters hold their change back,
-- and the event the panel fires after says which button it was: Settings.CategoryDefaulted (These
-- Settings, on one of our pages) applies them, Settings.Defaulted (All Settings) drops them. Our own
-- Defaults button (askDefaults) is the way to reset everything of ours.
local held -- changes held back while Blizzard sets defaults, to apply or drop after

-- Probe: CheckIsSettingDefaults is Mainline's (the `forever` UI source has it); without it,
-- changes apply at once, as before.
local function settingDefaults()
    return SettingsPanel and SettingsPanel.CheckIsSettingDefaults
        and SettingsPanel:CheckIsSettingDefaults() and true or false
end

-- Runs `fn`, a setter's change, now or once Blizzard's Defaults says which button it was.
local function change(fn)
    if settingDefaults() then
        held = held or {}
        held[#held + 1] = fn
    else
        fn()
    end
end

local function release(apply)
    local list = held
    held = nil
    if not list then
        return
    end
    if apply then
        for _, fn in ipairs(list) do
            fn()
        end
    end
    -- The rows show the defaults Blizzard set; put them back to what's saved.
    for name in pairs(settings) do
        ns.RefreshSetting(name)
    end
end

-- Our Defaults popup, laid out like Blizzard's, that offers only Forever++'s two presets:
-- Developer's Defaults | Cancel | Recommended Defaults.
local function askDefaults()
    ns.ConfirmChoice("DEFAULTS_CHOICE", L.DEFAULTS_ASK, L.DEFAULTS_DEVELOPER,
        ns.ApplyDeveloperDefaults, L.DEFAULTS_RECOMMENDED, function() ns.ApplyPreset() end)
end

-- NEW labels ----------------------------------------------------------------------------------
-- A module added (`added`) after the version the player last saw it in gets Blizzard's NEW label
-- after its name, the one Blizzard's own new settings get. So does an option added or changed
-- (`changed`) since then, unless its module is new itself (a longer word like CHANGED squeezes the
-- option's name), and the module's name in the list with it. A version after this one isn't marked
-- yet: what's tagged for the next release shows once the TOC's version reaches it.
-- A module is seen once the player has clicked it and moved on (to another module, or off the
-- page): its labels stay while it shows. The page opens on the first module with a marked option.
-- What's saved stays small: the version everything was seen in (ns.db.seenVersion), and the version
-- each module was seen in since (ns.db.seenModules), dropped once nothing is marked any more.
-- Show Tags on the Debug page (ns.db.showTags) marks everything tagged after the last release in
-- Changelog.lua instead, whatever was seen, and keeps it marked, to check them.
local newRows = {} -- module name (a new module), module table (one with a marked option), or
                   -- option table -> true while it's marked
local newOrder -- the modules to mark, once trackNew has run
local selected -- the module shown on the right of the Modules page
local viewing -- the module the player is looking at, to call seen once they move on
local refreshAll -- redraws the Modules page (defined with it, below)

-- Probe: NewFeatureLabelTemplate is Mainline's (LibUIDropDownMenu uses it on Forever).
local function canLabel()
    return hasTemplate("NewFeatureLabelTemplate")
end

-- The newest version in Changelog.lua with a date, so released, and older than `before` if given.
local function lastRelease(before)
    for _, release in ipairs(ns.changelog or {}) do
        if release.date and (not before or ns.Text.NewerVersion(before, release.version)) then
            return release.version
        end
    end
    return "0"
end

-- A version after the one module `name` was last seen in, and not after this one (still
-- unreleased). With Show Tags on, any version after the last release.
local function since(version, name)
    local Text = ns.Text
    if type(version) ~= "string" then
        return false
    end
    if ns.db.showTags then
        return Text.NewerVersion(version, lastRelease()) and true or false
    end
    local seenIn = ns.db.seenVersion
    local module = ns.db.seenModules[name]
    if type(module) == "string" and Text.NewerVersion(module, seenIn) then
        seenIn = module
    end
    return Text.NewerVersion(version, seenIn) and not Text.NewerVersion(version, ns.version)
        and true or false
end

local TAG_PADDING = 14 -- the room a label takes after its text, besides its own text

-- A function that shows a NEW label just after `text`, a font string, or hides it: the text at most
-- `room` wide, less the label's room while it shows. It returns how far past the text's end the
-- label reaches (0 while hidden), for something after it. The label is made the first time it's
-- needed, so it can come and go with Show Tags.
local function newLabel(parent, text, room)
    local label
    return function(shown)
        if shown and not label and canLabel() then
            label = CreateFrame("Frame", nil, parent, "NewFeatureLabelTemplate")
        end
        local tag = 0
        if shown and label and label.Label then
            tag = ns.Text.Width(label.Label) -- Blizzard's own NEW, in the game's language
        elseif shown then
            tag = 26
        end
        text:SetWidth(min(ns.Text.Width(text) + 2, room - (shown and tag + TAG_PADDING or 0)))
        if label then
            -- The text's width, unless it's cut short, then half the label's text: the template
            -- centers its text on the frame.
            local width = min(ns.Text.Width(text), text:GetWidth())
            label:ClearAllPoints()
            label:SetPoint("CENTER", text, "LEFT", width + 6 + tag / 2, 0)
            label:SetShown(shown and true or false)
        end
        return shown and 6 + tag or 0
    end
end

-- An update that keeps a NEW label just after `text` while `key` (a module's name, or one of its
-- options) is marked, or `other` (the slider in an option's row, or the module in the list).
local function newMark(parent, text, room, key, other)
    local show = newLabel(parent, text, room)
    return function()
        show(newRows[key] or (other and newRows[other]))
    end
end

-- Marks what's new in `newOrder`'s modules, afresh. With nothing marked, everything up to this
-- version has been seen, so that's saved instead of each module.
local function markNew()
    wipe(newRows)
    for _, name in ipairs(newOrder or {}) do
        local module = ns.modules[name]
        if since(module.added, name) then
            newRows[name] = true -- all of it is new, so its options aren't marked
        else
            for _, option in ipairs(module.options or {}) do
                if not option.debug and (since(option.added, name) or since(option.changed, name)) then
                    newRows[option] = true
                    newRows[module] = true
                end
            end
        end
    end
    if not next(newRows) and not ns.db.showTags and newOrder then
        if ns.Text.NewerVersion(ns.version, ns.db.seenVersion) then
            ns.db.seenVersion = ns.version
        end
        wipe(ns.db.seenModules)
    end
end

-- Saves that the player has seen the module they were looking at, once they move on from it, and
-- drops its labels.
local function moveOn(name)
    local left = viewing
    viewing = name
    local module = left and left ~= name and ns.modules[left]
    if module and (newRows[left] or newRows[module]) and not ns.db.showTags then
        ns.db.seenModules[left] = ns.version
        markNew()
        refreshAll()
    end
end

-- Whether the Modules page is the one showing.
local function onModulesPage()
    return SettingsPanel:IsShown() and SettingsPanel:GetCurrentCategory() == modulesCategory
end

-- The module on the right is being looked at while the Modules page shows; leaving the page moves
-- on from it.
local function updateSeen()
    moveOn(onModulesPage() and selected or nil)
end

-- Probe: Settings.CategoryChanged and GetCurrentCategory are Mainline's (the `forever` UI source
-- has them); without them nothing is marked new.
local function trackNew(order)
    if not (SettingsPanel and SettingsPanel.GetCurrentCategory and EventRegistry
        and EventRegistry.RegisterCallback and canLabel()) then
        return
    end
    newOrder = order
    markNew()
    EventRegistry:RegisterCallback("Settings.CategoryChanged", updateSeen, newRows)
    SettingsPanel:HookScript("OnShow", updateSeen)
    SettingsPanel:HookScript("OnHide", updateSeen)
end

-- Options -------------------------------------------------------------------------------------
-- The pieces both the Modules page and the Debug page use for a module's options.

-- The slider's value as its label shows it: `option.format` (a format string, such as "%d%%", or
-- a function of the value, for labels like "Never" at 0), or the number.
local function sliderOptions(option)
    local options = Settings.CreateSliderOptions(option.min, option.max, option.step or 1)
    if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
        local label = option.format
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            if type(label) == "function" then
                return label(value)
            end
            return format(label or "%s", value)
        end)
    end
    return options
end

-- A module's button `action` (`{ name, button, description, fn }`, and `confirm`, a question to
-- ask before `fn` runs, with `key` naming its popup) as the function its button calls.
local function actionFn(module, action, i)
    if not action.confirm then
        return action.fn
    end
    -- Asks first (ns.Confirm), in a popup named by `key`, so a command can ask the same one.
    local key = action.key or format("%s_ACTION%d", module.name:upper(), i)
    return function()
        ns.Confirm(key, action.confirm, action.fn)
    end
end

-- Debug page ----------------------------------------------------------------------------------
-- Options marked `debug = true`, as Blizzard settings rows, under the section headers they name.

-- Greys a row out while the module is off, so it shows nothing on it applies. Probe:
-- AddModifyPredicate is Mainline's; ManiaTip uses it on Forever.
local function greyWhenOff(initializer, module)
    if initializer and initializer.AddModifyPredicate then
        initializer:AddModifyPredicate(function() return module.db.enabled end)
    end
end

-- The Blizzard setting behind one of a module's options, read and written through the module.
local function optionSetting(category, module, option)
    local varType = option.choices and Settings.VarType.String or Settings.VarType.Boolean
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s_%s", module.name, option.key), varType,
        option.name, module.defaults[option.key],
        function() return module.db[option.key] end,
        function(value)
            change(function()
                ns.SetOption(module.name, option.key, value)
            end)
        end)
    track(module, setting)
    return setting
end

-- A debug option: a checkbox, or a dropdown when it lists `choices` (debug options are only
-- these), greyed out while the module is off.
local function addOption(category, module, option)
    local choices = option.choices
    local initializer
    if option.min then
        return -- a slider isn't one of these; it stays at its default rather than show as a checkbox
    elseif choices then
        if not (Settings.CreateDropdown and Settings.CreateControlTextContainer) then
            return -- Probe: dropdowns are Mainline's; leave the option at its default without one.
        end
        initializer = Settings.CreateDropdown(category, optionSetting(category, module, option),
            function()
                local container = Settings.CreateControlTextContainer()
                for _, choice in ipairs(choices) do
                    container:Add(choice[1], choice[2])
                end
                return container:GetData()
            end, option.description)
    else
        initializer = Settings.CreateCheckbox(category, optionSetting(category, module, option),
            option.description)
    end
    greyWhenOff(initializer, module)
end

local function addHeader(layout, text)
    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
end

-- The Debug page's sections, in order. Forever++'s own rows and modules' debug options and buttons
-- name one with `section`; a module's rows that name none of these go under its title, after them.
local DEBUG_SECTIONS = {
    L.DEBUG_SECTION_NEW, L.DEBUG_SECTION_DIAGNOSTICS, L.DEBUG_SECTION_TESTING, L.DEBUG_SECTION_LOGGING,
}

local function debugSection(row)
    for _, section in ipairs(DEBUG_SECTIONS) do
        if row.section == section then
            return section
        end
    end
end

-- Whether a module has debug options or buttons in `section` (nil: in none of the Debug page's).
local function hasDebugRows(module, section)
    for _, option in ipairs(module.options or {}) do
        if option.debug and debugSection(option) == section then
            return true
        end
    end
    for _, action in ipairs(module.debugActions or {}) do
        if debugSection(action) == section then
            return true
        end
    end
    return false
end

-- A module's debug options in `section` (nil: in none of the Debug page's), in the order it lists
-- them.
local function addDebugOptions(category, module, section)
    for _, option in ipairs(module.options or {}) do
        if option.debug and debugSection(option) == section then
            addOption(category, module, option)
        end
    end
end

-- Show Tags: every module and option added or changed since the last release marked NEW on the
-- Modules page, and kept marked, to check how they look. Live: the marks are made again and the
-- page redrawn.
local function addShowTags(category)
    local setting = Settings.RegisterProxySetting(category, "ForeverPlusPlus_ShowTags",
        Settings.VarType.Boolean, L.SETTINGS_SHOW_TAGS, false,
        function() return ns.db.showTags and true or false end,
        function(value)
            change(function()
                ns.db.showTags = value or nil
                markNew()
                refreshAll()
            end)
        end)
    Settings.CreateCheckbox(category, setting, L.SETTINGS_SHOW_TAGS_DESC)
end

-- A module's debug buttons in `section` (`module.debugActions`, the same shape as `actions`), after
-- its options there. Greyed out while the module is off, unless the button is for that too
-- (`whileOff`).
local function addDebugActions(layout, module, section)
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for i, action in ipairs(module.debugActions or {}) do
        if debugSection(action) == section then
            local initializer = CreateSettingsButtonInitializer(action.name, action.button,
                actionFn(module, action, i), action.description, true)
            if not action.whileOff then
                greyWhenOff(initializer, module)
            end
            layout:AddInitializer(initializer)
        end
    end
end

-- Defaults button -----------------------------------------------------------------------------
-- Blizzard's Defaults button, at the top right of a settings list, asks "These Settings" or "All
-- Settings", and All Settings resets the whole game. On our list page (Debug) our own Defaults
-- button sits over it instead, with our popup (askDefaults). Blizzard's is faded out underneath
-- (never changed otherwise), and ours shows and hides with it, since Blizzard hides it while
-- searching. The Modules and About pages are drawn by us and have their own.

local ourPages = {} -- category -> true, for the list pages that are ours
local defaultsButton -- ours, while it's made

local function onOurPage()
    return SettingsPanel and SettingsPanel.GetCurrentCategory
        and ourPages[SettingsPanel:GetCurrentCategory()] or false
end

local function updateDefaults(blizzard)
    local ours = onOurPage() and blizzard:IsShown()
    defaultsButton:SetShown(ours and true or false)
    blizzard:SetAlpha(ours and 0 or 1)
end

-- Probe: the list header's DefaultsButton, GetSettingsList, and the Settings.CategoryChanged event
-- are Mainline's (the `forever` UI source has them); without them Blizzard's button stays as is.
local function addDefaultsButton()
    local list = SettingsPanel and SettingsPanel.GetSettingsList and SettingsPanel:GetSettingsList()
    local blizzard = list and list.Header and list.Header.DefaultsButton
    if not (blizzard and EventRegistry and EventRegistry.RegisterCallback) then
        return
    end
    defaultsButton = CreateFrame("Button", nil, list.Header, "UIPanelButtonTemplate")
    defaultsButton:SetAllPoints(blizzard)
    defaultsButton:SetFrameLevel(blizzard:GetFrameLevel() + 5)
    defaultsButton:SetText(SETTINGS_DEFAULTS or L.HOME_DEFAULTS)
    defaultsButton:SetScript("OnClick", askDefaults)
    defaultsButton:Hide()
    blizzard:HookScript("OnShow", function() updateDefaults(blizzard) end)
    blizzard:HookScript("OnHide", function() updateDefaults(blizzard) end)
    EventRegistry:RegisterCallback("Settings.CategoryChanged", function() updateDefaults(blizzard) end,
        defaultsButton)
end

-- Module categories ---------------------------------------------------------------------------

-- The Modules page's groups: a module's `category` and its label. They show in the order their
-- labels sort in the player's language, with Other last. A module without one goes under Other.
local CATEGORIES = {
    { "automation", L.CATEGORY_AUTOMATION },
    { "character", L.CATEGORY_CHARACTER },
    { "chat", L.CATEGORY_CHAT },
    { "interface", L.CATEGORY_INTERFACE },
    { "items", L.CATEGORY_ITEMS },
    { "map", L.CATEGORY_MAP },
    { "quests", L.CATEGORY_QUESTS },
    { "system", L.CATEGORY_SYSTEM },
    { "units", L.CATEGORY_UNITS },
}
sort(CATEGORIES, function(a, b) return strlower(a[2]) < strlower(b[2]) end)
CATEGORIES[#CATEGORIES + 1] = { "other", L.CATEGORY_OTHER }
local CATEGORY_NAMES = {}
for _, group in ipairs(CATEGORIES) do
    CATEGORY_NAMES[group[1]] = group[2]
end

local function categoryOf(module)
    return CATEGORY_NAMES[module.category] and module.category or "other"
end

-- Modules page --------------------------------------------------------------------------------
-- A page we draw ourselves, built the first time it's shown: under the title, a search box and
-- our Defaults button; then a compact checklist of every module on the left, grouped under small
-- gold category labels, and the selected module on the right, each side scrolling on its own.
-- Our own frames from Blizzard's templates and art (the Settings panel's minimal checkboxes,
-- sliders and dropdowns, and its sidebar highlight), so nothing of Blizzard's pooled Settings
-- rows is touched. Every change goes through ns.SetEnabled and ns.SetOption, then
-- ns.RefreshSetting, which puts that module back to what's saved wherever it shows, so /fpp and
-- the page agree.

local LIST_LEFT, LIST_WIDTH, LIST_ROW = 7, 186, 20 -- the module list and its rows (and the
                                                    -- Changelog page's)
local ROW_HEIGHT = 26 -- an option's row, as in Blizzard's lists
local INDENT = 15 -- an option under another (`requires`)
local CONTROL_LEFT = 150 -- where an option's control starts, after its name
local DESCRIPTION_LINES = 4 -- the room a description always takes, so the options stay put

local listed = {} -- the names of the modules on the page, by category, then title
local searchText = {} -- module name -> its title, description, and options' text, lowercased
local filter, filterText -- the search text, lowercased and as typed, or nil while the box is empty
local newOnly -- the New checkbox: only modules marked NEW show, off each time Settings opens
local page -- the page's frames, once built
local bound = {} -- module name -> functions that put what shows of it back to what's saved
local refreshModule -- puts one module back to what's saved wherever it shows

local function isNew(name)
    return (newRows[name] or newRows[ns.modules[name]]) and true or false
end

local function matches(name)
    if newOnly and not isNew(name) then
        return false
    end
    return not filter or (searchText[name] or ""):find(filter, 1, true) ~= nil
end

-- Whether any listed module is marked NEW.
local function anyNew()
    for _, name in ipairs(listed) do
        if isNew(name) then
            return true
        end
    end
    return false
end

-- Whether the search shows a module of `group` (any module, without one).
local function anyMatch(group)
    for _, name in ipairs(listed) do
        if (not group or categoryOf(ns.modules[name]) == group) and matches(name) then
            return true
        end
    end
    return false
end

-- Runs `fn` now and whenever the module changes.
local function bind(name, fn)
    local list = bound[name]
    if not list then
        list = {}
        bound[name] = list
    end
    list[#list + 1] = fn
    fn()
end

local function showTooltip(owner, title, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if text and text ~= "" then
        GameTooltip:AddLine(text, 1, 0.82, 0, true) -- gold, like Blizzard's settings tooltips
    end
    GameTooltip:Show()
end

-- The tooltip a row shows over itself and its controls, as Blizzard's settings rows do.
local function addTooltip(row, title, text, ...)
    if not text or text == "" then
        return
    end
    local function enter()
        showTooltip(row, title, text)
    end
    local function leave()
        if GameTooltip:GetOwner() == row then
            GameTooltip:Hide()
        end
    end
    for _, frame in ipairs({ row, ... }) do
        frame:HookScript("OnEnter", enter)
        frame:HookScript("OnLeave", leave)
    end
end

-- A checkbox like the Settings panel's (its minimal art), calling `onClick(checked)`. Probe: the
-- art is Mainline's; without it, the older gold check.
local function newCheckbox(parent, size, onClick)
    local box
    if hasAtlas("checkbox-minimal") then
        box = CreateFrame("CheckButton", nil, parent)
        box:SetSize(size, size)
        box:SetNormalAtlas("checkbox-minimal")
        box:SetPushedAtlas("checkbox-minimal")
        local check = box:CreateTexture(nil, "ARTWORK")
        check:SetAtlas("checkmark-minimal")
        check:SetAllPoints()
        box:SetCheckedTexture(check)
        local grey = box:CreateTexture(nil, "ARTWORK")
        grey:SetAtlas("checkmark-minimal-disabled")
        grey:SetAllPoints()
        box:SetDisabledCheckedTexture(grey)
    else
        box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        box:SetSize(size, size)
    end
    box:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        if PlaySound and SOUNDKIT then
            PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
                or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        end
        onClick(checked)
    end)
    return box
end

local function newButton(parent, text, width, fn)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", function() fn() end)
    return button
end

-- Our Defaults button (askDefaults) at the top right of a page we draw: Modules, Changelog, About.
local function addPageDefaults(frame)
    local button = newButton(frame, SETTINGS_DEFAULTS or L.HOME_DEFAULTS, 96, askDefaults)
    button:SetPoint("TOPRIGHT", -10, -18)
    return button
end

local function setEnabled(name, on)
    ns.SetEnabled(name, on)
    ns.RefreshSetting(name)
end

local function setOption(module, option, value)
    ns.SetOption(module.name, option.key, value)
    ns.RefreshSetting(module.name)
end

-- The module's on/off checkbox, kept in step with its other one.
local function newModuleCheck(parent, name, size)
    local box = newCheckbox(parent, size, function(checked) setEnabled(name, checked) end)
    bind(name, function()
        box:SetChecked(ns.modules[name].db.enabled and true or false)
    end)
    return box
end

-- Blizzard's slider with steppers for a slider option. Probe: Mainline's.
local function newSlider(parent, module, option, width)
    if not (MinimalSliderWithSteppersMixin and Settings.CreateSliderOptions) then
        return
    end
    local ok, slider = pcall(CreateFrame, "Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    if not (ok and slider and slider.Init and slider.RegisterCallback) then
        return
    end
    slider:SetWidth(width)
    local options = sliderOptions(option)
    slider:Init(module.db[option.key], options.minValue, options.maxValue, options.steps,
        options.formatters)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        value = ns.SliderValue(option, value)
        -- Setting it back to what's saved (a refresh) changes nothing.
        if value and value ~= module.db[option.key] then
            setOption(module, option, value)
        end
    end, slider)
    return slider
end

-- Blizzard's menu dropdown for an option with `choices`. Probe: Mainline's.
local function newDropdown(parent, module, option, width)
    if not WowStyle1DropdownMixin then
        return
    end
    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent,
        "WowStyle1DropdownTemplate")
    if not (ok and dropdown and dropdown.SetupMenu) then
        return
    end
    dropdown:SetWidth(width)
    dropdown:SetupMenu(function(_, root)
        for _, choice in ipairs(option.choices) do
            root:CreateRadio(choice[2], function(value)
                return module.db[option.key] == value
            end, function(value)
                setOption(module, option, value)
            end, choice[1])
        end
    end)
    return dropdown
end

-- Moves `scroll` so `frame`, in its `content`, is at the top. With `onlyIfHidden`, only when the
-- frame is below what shows. After a frame, once the new layout's sizes are known.
local function scrollTo(scroll, content, frame, onlyIfHidden)
    if not (C_Timer and frame) then
        return
    end
    C_Timer.After(0, function()
        local top, inner = content:GetTop(), frame:GetTop()
        if not (top and inner) then
            return
        end
        if onlyIfHidden then
            local bottom, height = frame:GetBottom(), scroll:GetHeight()
            if not (bottom and height and top - bottom > scroll:GetVerticalScroll() + height) then
                return
            end
        end
        local range = scroll:GetVerticalScrollRange() or 0
        scroll:SetVerticalScroll(min(max(top - inner - 4, 0), range))
    end)
end

-- What the search looks for in an option: its name and description (its tooltip), lowercased.
local function optionText(option)
    return strlower(format("%s\n%s", option.name or "", option.description or ""))
end

-- Stacks ----------------------------------------------------------------------------------------
-- A stack is a frame whose entries ({ frame, shown, gap }) sit one under the other, `top` down
-- from its top, each only while its `shown()` is true. The module list is one, and so are the
-- module's rows on the right.

local function newStack(parent, width, gap)
    local stack = CreateFrame("Frame", nil, parent)
    stack:SetWidth(width)
    stack.entries, stack.gap, stack.top, stack.bottom = {}, gap, 0, 0
    return stack
end

local function addEntry(stack, frame, shown, gap)
    stack.entries[#stack.entries + 1] = { frame = frame, shown = shown, gap = gap }
end

local function layoutStack(stack)
    local y, any = -stack.top, false
    for _, entry in ipairs(stack.entries) do
        local shown = not entry.shown or entry.shown() and true or false
        entry.frame:SetShown(shown)
        if shown then
            if any then
                y = y - (entry.gap or stack.gap)
            end
            entry.frame:ClearAllPoints()
            entry.frame:SetPoint("TOPLEFT", 0, y)
            y = y - entry.frame:GetHeight()
            any = true
        end
    end
    stack:SetHeight(max(-y + stack.bottom, 1))
end

-- Split pages ------------------------------------------------------------------------------------
-- The Modules and Changelog pages (and Console Variables, through ns.Split): under the title, a
-- narrow list on the left with rows like the Settings sidebar's, a faint gold line, and a pane on
-- the right for what's selected, each side scrolling on its own.

-- A list `listWidth` wide and a pane right of it and its scroll bar, as `split.listScroll` and
-- `split.list` (a stack), and `split.pane` and `split.paneContent` (`split.paneWidth` wide). With
-- `scrollBox`, the pane is a WowScrollBoxList instead, with `split.scrollBar` and no paneContent,
-- for a page with too many rows to make a frame for each.
local function newSplit(frame, listWidth, scrollBox)
    local width = frame:GetWidth()
    width = width > 0 and width or 615
    local paneLeft = LIST_LEFT + listWidth + 41
    local split = {}

    local list = newScroll(frame)
    list:SetPoint("TOPLEFT", LIST_LEFT, -60)
    list:SetPoint("BOTTOMLEFT", LIST_LEFT, 8)
    list:SetWidth(listWidth)
    split.listScroll = list
    split.list = newStack(list, listWidth, 2)
    split.list.bottom = 8
    list:SetScrollChild(split.list)

    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.25)
    line:SetWidth(1)
    line:SetPoint("TOPLEFT", paneLeft - 12, -66)
    line:SetPoint("BOTTOMLEFT", paneLeft - 12, 14)

    local pane
    if scrollBox then
        pane = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
        split.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
        split.scrollBar:SetPoint("TOPLEFT", pane, "TOPRIGHT", 8, 0)
        split.scrollBar:SetPoint("BOTTOMLEFT", pane, "BOTTOMRIGHT", 8, 0)
    else
        pane = newScroll(frame)
    end
    pane:SetPoint("TOPLEFT", paneLeft, -60)
    pane:SetPoint("BOTTOMRIGHT", -32, 8)
    split.pane, split.paneWidth = pane, width - paneLeft - 32
    if not scrollBox then
        split.paneContent = CreateFrame("Frame", nil, pane)
        split.paneContent:SetWidth(split.paneWidth)
        pane:SetScrollChild(split.paneContent)
    end
    return split
end

-- Blizzard's sidebar highlight while a list row is selected or under the mouse.
local function paint(row)
    local atlas
    if row.isSelected() then
        atlas = "Options_List_Active"
    elseif row.over then
        atlas = "Options_List_Hover"
    end
    if atlas and hasAtlas(atlas) then
        row.highlight:SetAtlas(atlas)
        row.highlight:Show()
    else
        row.highlight:Hide()
    end
end

local function hover(row, over)
    row.over = over
    paint(row)
end

-- A row of a split page's list, lit while `isSelected()` is true and under the mouse.
local function newListButton(list, isSelected)
    local row = CreateFrame("Button", nil, list)
    row:SetSize(list:GetWidth(), LIST_ROW)
    row.isSelected = isSelected
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row:SetScript("OnEnter", function() hover(row, true) end)
    row:SetScript("OnLeave", function() hover(row, false) end)
    return row
end

-- A split page's list row in grey for when it lists nothing, with its `text` set by the page.
local function newEmptyRow(list, width)
    local empty = CreateFrame("Frame", nil, list)
    empty:SetSize(width, 40)
    empty.text = empty:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty.text:SetPoint("TOPLEFT", 2, -4)
    empty.text:SetWidth(width - 4)
    empty.text:SetJustifyH("LEFT")
    return empty
end

-- The selected module's rows -------------------------------------------------------------------
-- A view is a stack of the module's rows: a name on the left and its control after. Its
-- `updates` put its controls back to what's saved.

-- A row: `text` on the left, gold while `on()` and grey otherwise, and the space after it for a
-- control. Shown only while `shown()` is true, when given.
local function addRow(view, text, indent, on, shown)
    local row = CreateFrame("Frame", nil, view)
    row:EnableMouse(true)
    row:SetWidth(view:GetWidth())
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 4 + indent, 0)
    label:SetWidth(CONTROL_LEFT - 8 - indent)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    row:SetHeight(max(ROW_HEIGHT, label:GetStringHeight() + 8))
    addEntry(view, row, shown)
    if on then
        view.updates[#view.updates + 1] = function()
            label:SetFontObject(on() and "GameFontNormal" or "GameFontDisable")
        end
    end
    return row, label
end

-- How wide a dropdown or button is in a row with `room` after the option's name.
local function controlWidth(room)
    return min(180, room - 16)
end

-- How wide every slider is, its arrows included, so they all look alike whatever their values.
local SLIDER_WIDTH = 180

-- How wide a slider starting `left` into a row with `room` is: SLIDER_WIDTH, or less where its
-- value label (drawn after it) wouldn't fit.
local function sliderWidth(row, option, room, left)
    local measure = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local widest = 0
    for _, value in ipairs({ option.min, option.max }) do
        local text = type(option.format) == "function" and option.format(value)
            or format(option.format or "%s", value)
        measure:SetText(text)
        widest = max(widest, ns.Text.Width(measure))
    end
    measure:Hide()
    return max(60, min(SLIDER_WIDTH, room - 16 - left - widest - 12))
end

-- The room the reset arrow takes at the end of an option's row.
local RESET_SIZE = 20

-- An option's default as its control shows it: a slider's text, a dropdown's choice, or checked.
local function defaultText(module, option)
    local value = module.defaults[option.key]
    if option.min then
        return type(option.format) == "function" and option.format(value)
            or format(option.format or "%s", value)
    elseif option.choices then
        for _, choice in ipairs(option.choices) do
            if choice[1] == value then
                return choice[2]
            end
        end
        return tostring(value)
    end
    return value and L.SETTINGS_CHECKED or L.SETTINGS_UNCHECKED
end

-- The undo arrow at the end of an option's row (and the slider in it, `pair`), shown while either
-- isn't at its default, that puts them back. Like the undo buttons on Blizzard's Talents and
-- Transmog windows. Probe: their atlases are Mainline's; without one, no arrow.
local function addResetButton(view, row, module, option, pair, on)
    local atlas = hasAtlas("common-icon-undo") and "common-icon-undo"
        or hasAtlas("talents-button-undo") and "talents-button-undo"
    if not atlas then
        return
    end
    local keys = { option, pair }
    local function changed()
        for _, each in ipairs(keys) do
            if module.db[each.key] ~= module.defaults[each.key] then
                return true
            end
        end
        return false
    end
    local button = CreateFrame("Button", nil, row)
    button:SetSize(RESET_SIZE, RESET_SIZE)
    button:SetPoint("RIGHT", -2, 0)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAtlas(atlas)
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    button:SetHighlightAtlas(atlas, "ADD")
    button:GetHighlightTexture():SetAllPoints(icon)
    -- Pressed in a pixel, as Blizzard's icon buttons are.
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            icon:SetPoint("CENTER", 1, -1)
        end
    end)
    button:SetScript("OnMouseUp", function() icon:SetPoint("CENTER") end)
    button:SetScript("OnClick", function()
        if PlaySound and SOUNDKIT then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        for _, each in ipairs(keys) do
            local default = module.defaults[each.key]
            if module.db[each.key] ~= default then
                ns.SetOption(module.name, each.key, default)
            end
        end
        ns.RefreshSetting(module.name)
    end)
    -- Greyed with the option, and still saying what it would do.
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnEnter", function(self)
        local text = defaultText(module, option)
        if pair then
            text = format(L.SETTINGS_RESET_PAIR, text, defaultText(module, pair))
        end
        showTooltip(self, L.SETTINGS_RESET, format(L.SETTINGS_RESET_TO, text))
    end)
    button:SetScript("OnLeave", function(self)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)
    view.updates[#view.updates + 1] = function()
        button:SetShown(changed())
        button:SetEnabled(on())
        icon:SetDesaturated(not on())
    end
end

-- One of the module's options, with `byKey` for the option it's under (`requires`) or the slider
-- in its row (`slider`), and `done` for those already drawn.
local function addOptionRow(view, module, option, byKey, done)
    local parent = option.requires and byKey[option.requires]
    -- Under an option that is itself under another, it's on only while all of them are.
    local function on()
        -- Off with the module, and with its part's checkbox (`part`) when it's one of a part's.
        if not module.db.enabled or option.part and not module.db[option.part] then
            return false
        end
        local up = parent
        while up do
            local value = module.db[up.key]
            if not value or value == "off" then -- a checkbox, or a dropdown
                return false
            end
            up = up.requires and byKey[up.requires]
        end
        return true
    end
    local depth, up = 0, parent
    while up do
        depth = depth + 1
        up = up.requires and byKey[up.requires]
    end
    local indent = depth * INDENT
    -- A part's checkbox (`toggle`) is right under its section's header, which names it.
    local row, label = addRow(view, option.toggle and L.SETTINGS_ENABLED or option.name, indent, on)
    local updates = view.updates
    local pair = option.slider and byKey[option.slider]
    -- Highlighted like a selected sidebar entry while the search finds it (or the slider in it).
    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints()
    if hasAtlas("Options_List_Active") then
        highlight:SetAtlas("Options_List_Active")
    else
        highlight:SetColorTexture(1, 0.82, 0, 0.15)
    end
    highlight:Hide()
    view.found[#view.found + 1] = { row = row, highlight = highlight,
        text = optionText(option) .. (pair and "\n" .. optionText(pair) or "") }
    -- The name wraps narrower while it's marked NEW, so the row's height follows it. A slider in
    -- the row has no name of its own here, so its mark goes on the row's.
    local mark = newMark(row, label, CONTROL_LEFT - 8 - indent, option, pair)
    updates[#updates + 1] = function()
        mark()
        row:SetHeight(max(ROW_HEIGHT, label:GetStringHeight() + 8))
    end
    local room = view:GetWidth() - CONTROL_LEFT - RESET_SIZE
    local paired = pair and pair.min
    addResetButton(view, row, module, option, paired and pair or nil, on)
    if paired or not (option.min or option.choices) then
        local box = newCheckbox(row, 30, function(checked) setOption(module, option, checked) end)
        box:SetPoint("LEFT", CONTROL_LEFT, 0)
        updates[#updates + 1] = function()
            box:SetChecked(module.db[option.key] and true or false)
            box:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, box)
        if not paired then
            return
        end
        -- Its slider in the same row, greyed while the checkbox is off.
        done[pair.key] = true
        local slider = newSlider(row, module, pair, sliderWidth(row, pair, room, 36))
        if slider then
            slider:SetPoint("LEFT", box, "RIGHT", 6, 0)
            updates[#updates + 1] = function()
                slider:SetValue(module.db[pair.key])
                slider:SetEnabled(on() and module.db[option.key] and true or false)
            end
        end
    elseif option.min then
        local slider = newSlider(row, module, option, sliderWidth(row, option, room, 6))
        if not slider then
            return -- leave the option at its default without one
        end
        slider:SetPoint("LEFT", CONTROL_LEFT + 6, 0)
        updates[#updates + 1] = function()
            slider:SetValue(module.db[option.key])
            slider:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, slider.Slider)
    elseif option.choices then
        local dropdown = newDropdown(row, module, option, controlWidth(room))
        if not dropdown then
            return
        end
        dropdown:SetPoint("LEFT", CONTROL_LEFT + 6, 0)
        updates[#updates + 1] = function()
            dropdown:GenerateMenu()
            dropdown:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, dropdown)
    end
end

-- A row with a button: one of `module.actions`, the module's notice, or the way to its own page.
-- `title` heads its tooltip when `text` isn't plain.
local function addButtonRow(view, text, on, shown, button, fn, tooltip, title)
    local row = addRow(view, text, 0, on, shown)
    local control = newButton(row, button, min(180, view:GetWidth() - CONTROL_LEFT - 16), fn)
    control:SetPoint("LEFT", CONTROL_LEFT + 6, 0)
    if on then
        view.updates[#view.updates + 1] = function()
            control:SetEnabled(on())
        end
    end
    addTooltip(row, title or text, tooltip, control)
end

-- A line of text across the view: a section's header, a smaller one inside it, or "no options".
local function addLine(view, font, text, gap)
    local row = CreateFrame("Frame", nil, view)
    row:SetSize(view:GetWidth(), font == "GameFontHighlightLarge" and 24 or ROW_HEIGHT)
    local line = row:CreateFontString(nil, "OVERLAY", font)
    line:SetPoint("LEFT", 4, 0)
    line:SetText(text)
    addEntry(view, row, nil, gap or 16)
end

-- The module's rows, under its title, category and description: its notice, then its options and
-- buttons in the order it lists them, or a line saying it has none. Each change of `section`
-- starts a header with its name; options before the first section get an Options header. Inside a
-- section, each change of `subsection` (a part's own sections) starts a smaller one.
local function addModuleRows(view, module)
    local name = module.name
    local function on()
        return module.db.enabled and true or false
    end
    -- A gray row while `shown()` is true, such as a Blizzard setting the module needs being off,
    -- with a button that fixes it. ns.CVars.OffNotice makes one for a CVar. One without a `button`
    -- only says so, across the whole row.
    local notice = module.notice
    if notice and not notice.button then
        local row, label = addRow(view, format("|cff999999%s|r", notice.text), 0, nil, notice.shown)
        label:SetWidth(view:GetWidth() - 8)
        row:SetHeight(max(ROW_HEIGHT, label:GetStringHeight() + 8))
        addTooltip(row, notice.text, notice.description)
    elseif notice then
        addButtonRow(view, format("|cff999999%s|r", notice.text), nil, notice.shown,
            notice.button, function()
                notice.fn()
                refreshModule(name)
                -- A CVar can change a moment later (ns.CVars waits out combat).
                if C_Timer then
                    C_Timer.After(0.2, function() refreshModule(name) end)
                end
            end, notice.description, notice.text)
    end
    local options, byKey, done = {}, {}, {}
    for _, option in ipairs(module.options or {}) do
        if not option.debug then
            options[#options + 1] = option
            byKey[option.key] = option
        end
    end
    local ownPage = module.BuildPage and pages[name]
    if #options == 0 and not module.actions and not ownPage then
        addLine(view, "GameFontDisable", L.SETTINGS_NO_OPTIONS)
        return
    end
    local section, subsection
    if not (options[1] and options[1].section) then
        addLine(view, "GameFontHighlightLarge", L.SETTINGS_OPTIONS)
    end
    for _, option in ipairs(options) do
        if option.section and option.section ~= section then
            section, subsection = option.section, nil
            addLine(view, "GameFontHighlightLarge", section)
        end
        if option.subsection and option.subsection ~= subsection then
            subsection = option.subsection
            addLine(view, "GameFontHighlight", subsection, 8)
        end
        if not done[option.key] then
            addOptionRow(view, module, option, byKey, done)
        end
    end
    for i, action in ipairs(module.actions or {}) do
        addButtonRow(view, action.name, on, nil, action.button, actionFn(module, action, i),
            action.description)
    end
    if ownPage then
        addButtonRow(view, "", nil, nil, format(L.SETTINGS_OPEN_PAGE, module.title or name),
            function() open(ownPage) end)
    end
end

-- The module on the right: its title, its category, its description in DESCRIPTION_LINES, and its
-- Enabled checkbox in a row like its options', over its rows.
local function buildView(name)
    local module = ns.modules[name]
    local title = module.title or name
    local width = page.paneWidth
    local view = newStack(page.paneContent, width, 4)
    view:SetPoint("TOPLEFT")
    view.updates, view.found = {}, {}

    local heading = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    heading:SetPoint("TOPLEFT", 4, -4)
    heading:SetJustifyH("LEFT")
    heading:SetWordWrap(false)
    heading:SetText(title)
    view.updates[#view.updates + 1] = newMark(view, heading, width - 12, name)

    local group = view:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    group:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4)
    group:SetText(CATEGORY_NAMES[categoryOf(module)])
    local description = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -10)
    description:SetWidth(width - 12)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    -- The height of DESCRIPTION_LINES lines of this font, measured.
    description:SetText(("X\n"):rep(DESCRIPTION_LINES - 1) .. "X")
    local height = description:GetStringHeight()
    description:SetHeight(height)
    if description.SetMaxLines then
        description:SetMaxLines(DESCRIPTION_LINES) -- longer text ends in "..."
    end
    description:SetText(module.description or "")
    -- The whole description in a tooltip when it's cut short. Probe: IsTruncated is Mainline's.
    if description.IsTruncated then
        local hit = CreateFrame("Frame", nil, view)
        hit:SetAllPoints(description)
        hit:EnableMouse(true)
        hit:SetScript("OnEnter", function()
            if description:IsTruncated() then
                showTooltip(hit, title, module.description)
            end
        end)
        hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    view.top = 4 + heading:GetStringHeight() + 4 + group:GetStringHeight() + 10 + height + 6
    view.bottom = 12

    local row = addRow(view, L.SETTINGS_ENABLED, 0)
    local box = newModuleCheck(row, name, 30)
    box:SetPoint("LEFT", CONTROL_LEFT, 0)
    addModuleRows(view, module)
    bind(name, function()
        for _, update in ipairs(view.updates) do
            update()
        end
    end)
    return view
end

-- The module list ------------------------------------------------------------------------------

-- Highlights the options of `view` the search finds. With `reveal`, scrolls the first of them into
-- sight when it's below what shows.
local function markFound(view, reveal)
    local first
    for _, entry in ipairs(view.found) do
        local found = filter and entry.text:find(filter, 1, true) ~= nil
        entry.highlight:SetShown(found)
        first = first or found and entry.row
    end
    if reveal then
        scrollTo(page.pane, page.paneContent, first, true)
    end
end

-- Shows `name` on the right (nil for none).
local function choose(name)
    selected = name
    for _, row in pairs(page.rows) do
        paint(row)
    end
    for other, view in pairs(page.views) do
        view:SetShown(other == name)
    end
    if name then
        local view = page.views[name]
        if not view then
            view = buildView(name)
            page.views[name] = view
        end
        layoutStack(view)
        page.paneContent:SetHeight(view:GetHeight())
        page.pane:SetVerticalScroll(0)
        markFound(view, true)
    end
    -- Last, since moving on from a module with labels redraws the page.
    if newOrder and onModulesPage() then
        moveOn(name)
    end
end

-- Shows `name` on the right and scrolls the list to it.
local function selectModule(name)
    choose(name)
    scrollTo(page.listScroll, page.list, page.rows[name])
end

-- The first listed module with an option the player hasn't seen yet, or nil.
local function firstNew()
    for _, name in ipairs(listed) do
        if newRows[ns.modules[name]] then
            return name
        end
    end
end

-- A row of the list: the module's checkbox and its name, white while it's on and grey while it's
-- off, with a NEW label while it's new. Clicking it selects the module.
local function newListRow(name)
    local module = ns.modules[name]
    local row = newListButton(page.list, function() return selected == name end)
    local box = newModuleCheck(row, name, 22)
    box:SetPoint("LEFT", 0, 0)
    -- The checkbox takes the mouse from the row, so it keeps the row's highlight.
    box:HookScript("OnEnter", function() hover(row, true) end)
    box:HookScript("OnLeave", function() hover(row, false) end)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", box, "RIGHT", 2, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(module.title or name)
    local mark = newMark(row, text, LIST_WIDTH - 26, name, module)
    bind(name, function()
        text:SetFontObject(module.db.enabled and "GameFontHighlight" or "GameFontDisable")
        mark()
    end)
    row:SetScript("OnClick", function()
        if selected ~= name then
            choose(name)
        end
    end)
    return row
end

-- Lays out the modules the search shows, keeps the selection on one of them (the first, when it
-- hides the selected one), and lays out the selected module's rows.
-- `reveal` scrolls the first option the search finds into sight (see markFound).
local function relayout(reveal)
    if not page then
        return
    end
    if newOnly and not anyNew() then
        page.empty.text:SetText(L.SETTINGS_NOTHING_NEW)
    else
        page.empty.text:SetText(format(L.SETTINGS_NO_MATCH, filterText or ""))
    end
    layoutStack(page.list)
    if not (selected and matches(selected)) then
        local first
        for _, name in ipairs(listed) do
            if matches(name) then
                first = name
                break
            end
        end
        choose(first)
    elseif page.views[selected] then
        layoutStack(page.views[selected])
        page.paneContent:SetHeight(page.views[selected]:GetHeight())
        markFound(page.views[selected], reveal)
    end
end

function refreshModule(name)
    for _, fn in ipairs(bound[name] or {}) do
        fn()
    end
    relayout()
end

function refreshAll()
    for _, list in pairs(bound) do
        for _, fn in ipairs(list) do
            fn()
        end
    end
    relayout()
end

-- A search box at the top of a page we draw, left of `anchor` (its Defaults button) or at the top
-- right without one, with `instructions` in gray while it's empty. It calls `onChange(text)` with
-- the text, trimmed, as it's typed. Blizzard's own search, at the top left of the panel, finds settings across every
-- addon, not what our pages list. Probe: SearchBoxTemplate is Mainline's.
local function addSearchBox(frame, anchor, instructions, onChange)
    if not hasTemplate("SearchBoxTemplate") then
        return
    end
    local box = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    box:SetSize(200, 20)
    if anchor then
        box:SetPoint("RIGHT", anchor, "LEFT", -12, 0)
    else
        box:SetPoint("TOPRIGHT", -12, -19) -- where the Defaults button would be
    end
    box:SetAutoFocus(false)
    if box.Instructions then
        box.Instructions:SetText(instructions)
    end
    -- After the template's own OnTextChanged, which shows the clear button and the gray text.
    box:HookScript("OnTextChanged", function(self)
        onChange((self:GetText():match("^%s*(.-)%s*$")))
    end)
    return box
end

-- For a tool page (`BuildPage`) to look like the split pages: `New(frame, listWidth, scrollBox)`,
-- `ListButton(list, isSelected)` and `Paint(row)` after the selection changes, `AddEntry(stack,
-- frame, shown, gap)` and `Layout(stack)` for the list, and `AddSearchBox(frame, nil,
-- instructions, onChange)` for the search box at the top right (nil without the template).
ns.Split = {
    New = newSplit,
    ListButton = newListButton,
    Paint = paint,
    AddEntry = addEntry,
    Layout = layoutStack,
    AddSearchBox = addSearchBox,
}

-- The Modules page's search: the list narrows to the modules whose title or description has the
-- text, or an option's name or description, and those options are highlighted on the right.
local function searchModules(text)
    filter = text ~= "" and strlower(text) or nil
    filterText = text
    relayout(true)
end

-- A New checkbox left of the search box that narrows the list to the modules marked NEW, with the
-- search on top. It's off each time Settings opens, so the whole list is what the page opens on.
-- Without NEW labels on this client (trackNew didn't run), there's nothing to show, so no checkbox.
local function addNewOnly(frame, anchor)
    if not newOrder then
        return
    end
    local box = newCheckbox(frame, 22, function(checked)
        newOnly = checked or nil
        relayout()
    end)
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetText(L.SETTINGS_NEW_ONLY)
    text:SetPoint("RIGHT", anchor, "LEFT", -12, 0)
    box:SetPoint("RIGHT", text, "LEFT", -2, 0)
    -- Clicking the word clicks the box, like Blizzard's checkboxes with a label.
    box:SetHitRectInsets(0, -(ns.Text.Width(text) + 2), 0, 0)
    SettingsPanel:HookScript("OnShow", function()
        box:SetChecked(false)
        if newOnly then
            newOnly = nil
            relayout()
        end
    end)
    return box
end

local function buildModules(frame)
    ns.AddPageTitle(frame, L.MODULES)
    page = newSplit(frame, LIST_WIDTH)
    page.rows, page.views = {}, {}

    local defaults = addPageDefaults(frame)
    page.search = addSearchBox(frame, defaults, L.SETTINGS_SEARCH, searchModules)
    page.newOnly = addNewOnly(frame, page.search or defaults)

    -- "No modules match" while the search hides them all, or "Nothing new" while the New checkbox
    -- is on and nothing is marked.
    local empty = newEmptyRow(page.list, LIST_WIDTH)
    page.empty = empty
    addEntry(page.list, empty, function() return not anyMatch() end)
    local group
    for _, name in ipairs(listed) do
        local current = categoryOf(ns.modules[name])
        if current ~= group then
            group = current
            local label = CreateFrame("Frame", nil, page.list)
            label:SetSize(LIST_WIDTH, 16)
            local text = label:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("BOTTOMLEFT", 2, 2)
            text:SetText(CATEGORY_NAMES[current])
            addEntry(page.list, label, function() return anyMatch(current) end, 12)
        end
        page.rows[name] = newListRow(name)
        addEntry(page.list, page.rows[name], function() return matches(name) end)
    end

    -- Opens on the module ns.OpenSettings asked for, or the first with a new option to see, or
    -- else the first.
    selected = selected or firstNew()
    if selected then
        selectModule(selected)
    end
    relayout()
    -- After /fpp or a preset changed things while the page was closed, and for notices.
    frame:HookScript("OnShow", refreshAll)
end

-- About page ----------------------------------------------------------------------------------
-- What the addon is, how many modules are on, links, and the /fpp commands, with the Defaults
-- button at the top right like the Modules page. Built the first time it's shown; the module
-- count updates each time.

local WEBSITE = "https://github.com/xIGBClutchIx/ForeverPlusPlus"
local ISSUES = WEBSITE .. "/issues"

local metadata = ns.Metadata

-- A gold label at the left of a row, for a value beside it.
local function addLabel(frame, y, text)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, y)
    label:SetWidth(110)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

-- A link can't be clicked in the game, so it sits in a read-only box, selected on click, to copy.
local function addLink(frame, y, label, url)
    local left = addLabel(frame, y, label)
    local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    box:SetSize(360, 20)
    box:SetPoint("LEFT", left, "RIGHT", 14, 0)
    box:SetAutoFocus(false)
    box:SetText(url)
    box:SetCursorPosition(0)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- Typing can't change it.
    box:SetScript("OnTextChanged", function(self, user)
        if user then
            self:SetText(url)
            self:HighlightText()
        end
    end)
    box:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.HOME_COPY, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function addHeading(frame, y, text)
    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    heading:SetPoint("TOPLEFT", 16, y)
    heading:SetText(text)
end

-- How many modules the player can turn on, and how many are on.
local function countModules()
    local on, total = 0, 0
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if not (module.unavailable or module.alwaysOn) then
            total = total + 1
            if module.db.enabled then
                on = on + 1
            end
        end
    end
    return on, total
end

local function buildAbout(frame)
    ns.AddPageTitle(frame, L.ABOUT)
    -- The NEW tag on the Minimap Button can go. On every show, since Reset Welcome sets it again.
    ns.SetWelcome(false)
    frame:HookScript("OnShow", function() ns.SetWelcome(false) end)
    addPageDefaults(frame)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("TOPLEFT", 16, -64)
    icon:SetTexture(ns.icon)

    local welcome = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    welcome:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4)
    welcome:SetText(format(L.HOME_WELCOME, ns.title))

    local tagline = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", welcome, "BOTTOMLEFT", 0, -6)
    tagline:SetText(metadata("Notes") ~= "" and metadata("Notes") or L.HOME_TAGLINE)

    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("TOPLEFT", tagline, "BOTTOMLEFT", 0, -6)
    version:SetText(format(L.HOME_VERSION, ns.version, metadata("Author")))

    -- Under the version, since the command list below grows with every module.
    local gameVersion, build, _, interface = GetBuildInfo()
    local game = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    game:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -2)
    game:SetText(format(L.HOME_GAME_BUILD, gameVersion, build, interface))

    local y = -144
    local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", 16, y)
    intro:SetWidth(560)
    intro:SetJustifyH("LEFT")
    intro:SetText(L.HOME_INTRO)
    y = y - intro:GetStringHeight() - 14

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("TOPLEFT", 16, y)
    local function update()
        status:SetText(format(L.HOME_MODULES_ON, countModules()))
    end
    update()
    frame:HookScript("OnShow", update) -- after /fpp or the Modules page changed some

    y = y - 52
    addHeading(frame, y, L.HOME_LINKS)
    y = y - 26
    addLink(frame, y, L.HOME_WEBSITE, WEBSITE)
    y = y - 24
    addLink(frame, y, L.HOME_ISSUES, ISSUES)
    y = y - 22
    local requests = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    requests:SetPoint("TOPLEFT", 16, y)
    requests:SetText(L.HOME_REQUESTS)

    y = y - 30
    addHeading(frame, y, L.HOME_COMMANDS)
    y = y - 24
    for _, line in ipairs(ns.Commands()) do
        local command = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        command:SetPoint("TOPLEFT", 16, y)
        command:SetText(line[1])
        local description = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        description:SetPoint("TOPLEFT", 250, y)
        description:SetText(line[2])
        y = y - 16
    end
end

-- Changelog page ------------------------------------------------------------------------------
-- The release notes from Changelog.lua as a split page, like the Modules page: the releases on the
-- left (Unreleased first, then newest first) with their dates, and the selected one's notes on the
-- right. A release newer than the version the player last saw on the Modules page gets the NEW
-- label. Built the first time it's shown, on the newest.

local CHANGELOG_LIST_WIDTH = 140 -- the release list, narrower than the module list
local RULE_WIDTH = 260 -- the gold line under a section's heading

-- Whether a release is newer than the version the player last saw. Unreleased notes always are.
local function isNewRelease(release)
    return not release.date or ns.Text.NewerVersion(release.version, ns.db.seenVersion) and true
        or false
end

-- An entry as it shows: its text, after its module's name in gold when it has one.
local function entryText(entry)
    if type(entry) == "table" then
        return format("|cffffd100%s|r: %s", entry[1], entry[2]) -- gold, like GameFontNormal
    end
    return entry
end

-- Whether the search (lowercased, nil for none) finds an entry, by its module's name or its text.
local function entryMatches(entry, search)
    if not search then
        return true
    end
    local text = type(entry) == "table" and format("%s: %s", entry[1], entry[2]) or entry
    return strlower(text):find(search, 1, true) ~= nil
end

-- How many of a release's entries the search finds (all of them without one).
local function countMatches(release, search)
    local count = 0
    for _, section in ipairs(release.sections) do
        for _, entry in ipairs(section[2]) do
            if entryMatches(entry, search) then
                count = count + 1
            end
        end
    end
    return count
end

-- "N changes" for a release's notes.
local function countText(count)
    return count == 1 and L.CHANGELOG_ONE_CHANGE or format(L.CHANGELOG_CHANGES, count)
end

-- Gold fading out to the right. Probe: SetGradient with colors is Mainline's; without it, a faint
-- gold line like the one between the list and the pane.
local function fadeGold(texture)
    texture:SetColorTexture(1, 1, 1, 1)
    if not (CreateColor and texture.SetGradient and pcall(texture.SetGradient, texture,
        "HORIZONTAL", CreateColor(1, 0.82, 0, 0.45), CreateColor(1, 0.82, 0, 0))) then
        texture:SetColorTexture(1, 0.82, 0, 0.25)
    end
end

-- A release's row in the list: its version, the NEW label while it's new, and its date (MM-DD) in
-- gray at the right. Returns the row and an update for its label.
local function newReleaseRow(list, release, isSelected)
    local row = newListButton(list, isSelected)
    local date = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    date:SetPoint("RIGHT", -6, 0)
    date:SetText(release.date and release.date:sub(6) or "")
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", 8, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(release.version)
    local mark = newLabel(row, text, row:GetWidth() - 18 - ns.Text.Width(date))
    return row, function() mark(isNewRelease(release)) end
end

-- A release's notes, a stack: its title, the NEW label while it's new, and how many changes the
-- search finds, then each section's heading in gold over a fading gold line, and its entries after
-- a dash, their wrapped lines lined up after it and a module's name in gold. Only the entries the
-- search finds show, under their sections' headings. `view.search(text)` lays it out for a search
-- (lowercased, nil for none), and `view.update` keeps its NEW label.
local function buildNotes(content, width, release)
    local view = newStack(content, width, 0)
    view:SetPoint("TOPLEFT")
    view.top, view.bottom = 4, 12
    local search

    local header = CreateFrame("Frame", nil, view)
    header:SetWidth(width)
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 4, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    -- Unreleased notes have no date.
    title:SetText(release.date and format(L.CHANGELOG_RELEASE, release.version, release.date)
        or release.version)
    header:SetHeight(title:GetStringHeight())
    addEntry(view, header)
    local count = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetText(countText(countMatches(release)))
    local mark = newLabel(header, title, width - 18 - ns.Text.Width(count))
    function view.update()
        local after = mark(isNewRelease(release))
        local x = min(ns.Text.Width(title), title:GetWidth()) + after + 10
        count:ClearAllPoints()
        count:SetPoint("LEFT", title, "LEFT", x, 0)
    end

    for _, section in ipairs(release.sections) do
        local entries = section[2]
        local top = CreateFrame("Frame", nil, view)
        top:SetWidth(width)
        local heading = top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        heading:SetPoint("TOPLEFT", 4, 0)
        heading:SetText(section[1])
        local rule = top:CreateTexture(nil, "ARTWORK")
        rule:SetPoint("TOPLEFT", 4, -heading:GetStringHeight() - 6)
        rule:SetSize(min(RULE_WIDTH, width - 8), 1)
        fadeGold(rule)
        top:SetHeight(heading:GetStringHeight() + 6 + 1 + 5)
        addEntry(view, top, function()
            for _, entry in ipairs(entries) do
                if entryMatches(entry, search) then
                    return true
                end
            end
            return false
        end, 18)
        for _, entry in ipairs(entries) do
            local row = CreateFrame("Frame", nil, view)
            row:SetWidth(width)
            local dash = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            dash:SetPoint("TOPLEFT", 12, 0)
            dash:SetText("-")
            local line = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            line:SetPoint("TOPLEFT", 24, 0)
            line:SetWidth(width - 28)
            line:SetJustifyH("LEFT")
            line:SetText(entryText(entry))
            row:SetHeight(line:GetStringHeight())
            addEntry(view, row, function() return entryMatches(entry, search) end, 8)
        end
    end

    function view.search(text)
        search = text
        count:SetText(countText(countMatches(release, search)))
        layoutStack(view)
    end
    return view
end

local function buildChangelog(frame)
    ns.AddPageTitle(frame, L.CHANGELOG)
    local split = newSplit(frame, CHANGELOG_LIST_WIDTH)
    local releases = ns.changelog or {}
    local rows, views, updates = {}, {}, {}
    local shown -- the release on the right
    local search -- the search, lowercased, or nil while the box is empty

    local function matches(i)
        return countMatches(releases[i], search) > 0
    end

    -- Shows release `i` on the right (nil for none), laid out for the search.
    local function show(i)
        shown = i
        for _, row in ipairs(rows) do
            paint(row)
        end
        for other, view in pairs(views) do
            view:SetShown(other == i)
        end
        if not i then
            split.paneContent:SetHeight(1)
            return
        end
        local view = views[i]
        if not view then
            view = buildNotes(split.paneContent, split.paneWidth, releases[i])
            views[i] = view
            updates[#updates + 1] = view.update
            view.update()
        end
        view.search(search)
        split.paneContent:SetHeight(view:GetHeight())
        split.pane:SetVerticalScroll(0)
    end

    -- "No changes match" while the search finds nothing.
    local empty = newEmptyRow(split.list, CHANGELOG_LIST_WIDTH)
    addEntry(split.list, empty, function()
        for i in ipairs(releases) do
            if matches(i) then
                return false
            end
        end
        return true
    end)

    for i, release in ipairs(releases) do
        local row, update = newReleaseRow(split.list, release, function() return shown == i end)
        row:SetScript("OnClick", function()
            if shown ~= i then
                show(i)
            end
        end)
        rows[i] = row
        updates[#updates + 1] = update
        addEntry(split.list, row, function() return matches(i) end)
    end
    layoutStack(split.list)

    -- Defaults and the search box at the top, as on the Modules page. The list keeps the releases
    -- the search finds something in, and stays on the one shown while it's one of them, or else
    -- shows the first.
    local defaults = addPageDefaults(frame)
    addSearchBox(frame, defaults, L.CHANGELOG_SEARCH, function(text)
        search = text ~= "" and strlower(text) or nil
        empty.text:SetText(format(L.CHANGELOG_NO_MATCH, text))
        layoutStack(split.list)
        if shown and matches(shown) then
            show(shown)
            return
        end
        local first
        for i in ipairs(releases) do
            if matches(i) then
                first = i
                break
            end
        end
        show(first)
    end)

    -- The NEW labels follow the version last seen, which the Modules page moves on.
    local function refresh()
        for _, update in ipairs(updates) do
            update()
        end
    end
    refresh()
    if releases[1] then
        show(1)
    end
    -- Again a frame later: on the first visit the release with a NEW label stayed blank until the
    -- page was shown again, as if its text wasn't measured yet while the page was being built.
    if C_Timer then
        C_Timer.After(0, refresh)
    end
    frame:HookScript("OnShow", refresh)
end

-- Module names in the order their titles sort in the player's language, so the list and pages
-- read alphabetically whatever order the TOC loads them in. Modules this client doesn't get are
-- left out.
local function byTitle()
    local names = {}
    for _, name in ipairs(ns.order) do
        if not ns.modules[name].unavailable then
            names[#names + 1] = name
        end
    end
    local function key(name)
        return strlower(ns.modules[name].title or name)
    end
    sort(names, function(a, b) return key(a) < key(b) end)
    return names
end

-- Debug page tools ----------------------------------------------------------------------------
-- Forever++'s own rows on the Debug page, and the page itself.

-- Puts the version last seen back to the release before this one, so the Modules page marks what a
-- player updating from it would see, and opens it the way it would open for them: on the first
-- module with a marked option. A module's marks go once it's been clicked, as they do after an
-- update. Once this version is released it's the last release itself, so it can't be the one.
local function resetSeen()
    ns.db.seenVersion = lastRelease(ns.version)
    wipe(ns.db.seenModules)
    markNew()
    if page then
        selected = firstNew()
        refreshAll()
        if selected then
            selectModule(selected)
        end
    end
    open(modulesCategory)
end

-- One line for a bug report: the addon and client, and the modules on.
local function debugInfo()
    local gameVersion, build, _, interface = GetBuildInfo()
    local on = ns.ModulesOn()
    return format(L.DEBUG_INFO_LINE, ns.version, tostring(gameVersion), tostring(build),
        tostring(interface), GetLocale(), #on, concat(on, ", "))
end

-- How many hooks a module has made (`module:Hook`, `module:HookScript`). They stay once made but
-- do nothing while the module is off.
local function hookCount(module)
    local count = 0
    for _, byMethod in pairs(module.hooked or {}) do
        for _, byFn in pairs(byMethod) do
            for _ in pairs(byFn) do
                count = count + 1
            end
        end
    end
    return count
end

-- Prints each module's events (`module:On`) and hooks, to check a module that's off listens to
-- nothing. A module that's off but still has events is printed in red.
local function printEvents()
    local leaks = 0
    for _, name in ipairs(byTitle()) do
        local module = ns.modules[name]
        local list = {}
        for _, entry in ipairs(module.events or {}) do
            list[#list + 1] = entry[1]
        end
        local hooks = hookCount(module)
        if #list > 0 or (module.enabled and hooks > 0) then
            local line = format(L.DEBUG_EVENTS_LINE, module.title or name,
                ns.StateText(module.enabled), #list, #list > 0 and concat(list, ", ") or "-", hooks)
            if not module.enabled and #list > 0 then
                leaks = leaks + 1
                line = "|cffdd4444" .. line .. "|r"
            end
            ns.Print(line)
        end
    end
    ns.Print(leaks > 0 and format(L.DEBUG_EVENTS_LEAKS, leaks) or L.DEBUG_EVENTS_CLEAN)
end

local DEBUG_TOOLS = {
    { name = L.DEBUG_RESET_SEEN, button = L.DEBUG_RESET_SEEN_BUTTON,
        description = L.DEBUG_RESET_SEEN_DESC, fn = resetSeen, section = L.DEBUG_SECTION_NEW },
    { name = L.DEBUG_RESET_WELCOME, button = L.DEBUG_RESET_WELCOME_BUTTON,
        description = L.DEBUG_RESET_WELCOME_DESC, section = L.DEBUG_SECTION_NEW,
        fn = function()
            ns.SetWelcome(true)
            ns.Print(L.DEBUG_RESET_WELCOME_DONE)
        end },
    { name = L.DEBUG_INFO, button = L.DEBUG_INFO_BUTTON, description = L.DEBUG_INFO_DESC,
        section = L.DEBUG_SECTION_DIAGNOSTICS,
        fn = function() ns.Prompt("DEBUG_INFO", L.DEBUG_INFO_PROMPT, debugInfo()) end },
    { name = L.DEBUG_EVENTS, button = L.DEBUG_EVENTS_BUTTON, description = L.DEBUG_EVENTS_DESC,
        fn = printEvents, section = L.DEBUG_SECTION_DIAGNOSTICS },
    { name = L.DEBUG_RELOAD, button = L.DEBUG_RELOAD_BUTTON, description = L.DEBUG_RELOAD_DESC,
        fn = function() ReloadUI() end, section = L.DEBUG_SECTION_DIAGNOSTICS },
}

-- Forever++'s own rows in `section`: Show Tags first in What's New, then its buttons there.
local function addDebugTools(category, layout, section)
    if section == L.DEBUG_SECTION_NEW then
        addShowTags(category)
    end
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for _, tool in ipairs(DEBUG_TOOLS) do
        if tool.section == section then
            layout:AddInitializer(CreateSettingsButtonInitializer(tool.name, tool.button, tool.fn,
                tool.description, true))
        end
    end
end

-- The Debug page: a header for each section, with Forever++'s own rows and then each module's
-- (by title) under it, and after them a header for each module with rows in no section.
local function buildDebug(category, layout, order)
    local function addRows(module, section)
        addDebugOptions(category, module, section)
        addDebugActions(layout, module, section)
    end
    for _, section in ipairs(DEBUG_SECTIONS) do
        addHeader(layout, section)
        addDebugTools(category, layout, section)
        for _, name in ipairs(order) do
            if hasDebugRows(ns.modules[name], section) then
                addRows(ns.modules[name], section)
            end
        end
    end
    for _, name in ipairs(order) do
        local module = ns.modules[name]
        if hasDebugRows(module, nil) then
            addHeader(layout, module.title or name)
            addRows(module, nil)
        end
    end
end

---Adds the Forever++ pages to Settings > AddOns (called once, after ns.Start).
function ns.RegisterSettings()
    -- Probe: the Mainline Settings API is on Forever (build 70009), but it's a beta.
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    -- Probe: both events are Mainline's (the `forever` UI source fires them).
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("Settings.CategoryDefaulted", function() release(true) end, ns)
        EventRegistry:RegisterCallback("Settings.Defaulted", function() release(false) end, ns)
    end
    local subpages = Settings.RegisterVerticalLayoutSubcategory ~= nil
        and Settings.RegisterCanvasLayoutSubcategory ~= nil
    local order = byTitle()
    trackNew(order)
    -- Modules by category, then title: the order of the Modules page and of the tool pages.
    local grouped = {}
    for _, group in ipairs(CATEGORIES) do
        for _, name in ipairs(order) do
            if categoryOf(ns.modules[name]) == group[1] then
                grouped[#grouped + 1] = name
            end
        end
    end
    for _, name in ipairs(grouped) do
        local module = ns.modules[name]
        if not module.alwaysOn then
            listed[#listed + 1] = name
            local text = { strlower(format("%s\n%s", module.title or name,
                module.description or "")) }
            for _, option in ipairs(module.options or {}) do
                if not option.debug then
                    text[#text + 1] = optionText(option)
                end
            end
            searchText[name] = concat(text, "\n")
        end
    end

    -- The top Forever++ entry is the Modules page; without subpages it's the only one.
    local category = Settings.RegisterCanvasLayoutCategory(canvasFrame(buildModules), ns.title)
    modulesCategory = category
    if not subpages then
        Settings.RegisterAddOnCategory(category)
        return
    end

    -- Pages modules draw themselves (tools such as Console Variables).
    for _, name in ipairs(grouped) do
        local module = ns.modules[name]
        if module.BuildPage then
            pages[name] = addCanvasPage(category, module.title or name, function(frame)
                module:BuildPage(frame)
            end)
        end
    end
    local debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.DEBUG)
    buildDebug(debugPage, debugLayout, order)
    addCanvasPage(category, L.CHANGELOG, buildChangelog)
    aboutCategory = addCanvasPage(category, L.ABOUT, buildAbout)
    Settings.RegisterAddOnCategory(category)
    ourPages[debugPage] = true
    addDefaultsButton()
end

---Opens the Forever++ Modules page in Settings, or a module: its own page, or the Modules page
---with it selected (after combat, if the player is in combat).
---@param name? string a module
---@return boolean opened false when this client's Settings can't open to it
function ns.OpenSettings(name)
    if name and pages[name] then
        return open(pages[name])
    end
    if name and searchText[name] then
        if page then
            -- Searching for something else would hide it.
            if not matches(name) and page.search then
                page.search:SetText("")
            end
            selectModule(name)
        else
            selected = name -- the page opens on it
        end
    end
    return open(modulesCategory)
end

---Opens the Forever++ About page in Settings (after combat, if the player is in combat).
---@return boolean opened false when this client's Settings can't open to it
function ns.OpenAbout()
    return open(aboutCategory)
end

---Updates a module's controls after it changed somewhere else (/fpp toggle, set, a preset).
---@param name string
function ns.RefreshSetting(name)
    refreshModule(name)
    if not Settings or not Settings.NotifyUpdate then
        return
    end
    for _, setting in ipairs(settings[name] or {}) do
        Settings.NotifyUpdate(setting:GetVariable())
    end
end
