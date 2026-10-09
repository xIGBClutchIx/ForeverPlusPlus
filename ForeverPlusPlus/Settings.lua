-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page. Few entries, so the sidebar stays short:
--   Forever++        a welcome page: what the addon is, how many modules are on, buttons to the
--                    Modules and Changelog pages, the version, links, and the /fpp commands
--     Modules        every module (the only place modules turn on and off), with a checkbox each,
--                    grouped by `module.category`, in the layout the player picks at the top:
--                    a list with the selected module's details beside it, one long list, a tab
--                    per category, collapsible categories, or cards. Wherever a module's options
--                    show (checkboxes, dropdowns and sliders, and buttons from `module.actions`),
--                    they're greyed out while it's off, an option can sit under another
--                    (`requires`), and its `notice` (a warning) shows while that applies.
--                    `alwaysOn` modules (tools) aren't listed. A search box at the top narrows
--                    it to modules by title and description. A module or option added since the
--                    player last looked (`added`) is marked NEW
--     <Tool>         a page a module draws itself (`BuildPage`)
--     Debug          options marked `debug = true`, for testing
--     Changelog      the release notes from Changelog.lua
-- Without subpages (an older Settings API), the Modules page is the only page.
local _, ns = ...

local ipairs, pairs, next, format, type, sort = ipairs, pairs, next, string.format, type, table.sort
local strlower = string.lower
local concat, min, max, floor, pcall = table.concat, math.min, math.max, math.floor, pcall
local InCombatLockdown, CreateFrame, GetBuildInfo = InCombatLockdown, CreateFrame, GetBuildInfo
local wipe = wipe
local C_AddOns, GetAddOnMetadata, GameTooltip = C_AddOns, GetAddOnMetadata, GameTooltip
local C_XMLUtil, C_Texture, C_Timer = C_XMLUtil, C_Texture, C_Timer
local L = ns.L

local settings = {} -- module name -> its Blizzard setting objects, to refresh after /fpp changes
local mainCategory -- the Forever++ page, for /fpp
local modulesCategory -- the Modules page
local changelogCategory -- the Changelog page, for the welcome page's button
local pages = {} -- module name -> the page it draws itself, for ns.OpenSettings(name)

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
-- needs the frame now, so it starts empty and is filled the first time it's shown.
local function canvasFrame(build)
    local frame = CreateFrame("Frame")
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

-- Probe: a Blizzard template (Mainline's) this client has.
local function hasTemplate(name)
    return C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(name) and true
        or false
end

local function hasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
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
-- Settings, on one of our pages) applies them, Settings.Defaulted (All Settings) drops them. The
-- welcome page's Defaults button is the way to reset everything of ours.
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
        ns.ApplyDeveloperDefaults, L.DEFAULTS_RECOMMENDED, ns.ApplyDefaults)
end

-- NEW labels ----------------------------------------------------------------------------------
-- A module added (`added`) after the version the player last saw the Modules page in gets
-- Blizzard's NEW label after its name, the one Blizzard's own new settings get. So does an option
-- added or changed (`changed`) since then, unless its module is new itself; its module starts
-- selected or open, so the option is seen. Seeing the page saves this version
-- (ns.db.seenVersion); the labels stay while the player is on it and are gone once they leave.
local newRows = {} -- module name, or option table -> true while it's marked new
local seen -- true once the Modules page has been shown this session
local refreshAll -- redraws the Modules page, once it's built

-- Probe: NewFeatureLabelTemplate is Mainline's (LibUIDropDownMenu uses it on Forever).
local function canLabel()
    return hasTemplate("NewFeatureLabelTemplate")
end

-- A version after the one last seen, and not after this one (still unreleased).
local function since(version)
    local Text = ns.Text
    return type(version) == "string" and Text.NewerVersion(version, ns.db.seenVersion)
        and not Text.NewerVersion(version, ns.version)
end

-- A NEW label for `text`, a font string, put just after its text.
local function newLabel(parent, text)
    local label = CreateFrame("Frame", nil, parent, "NewFeatureLabelTemplate")
    -- The text's width, unless it's cut short, then half the label's text: the template centers
    -- its text on the frame.
    local width = ns.Text.Width(text)
    if text:GetWidth() > 0 and width > text:GetWidth() then
        width = text:GetWidth()
    end
    local half = label.Label and ns.Text.Width(label.Label) / 2 or 16
    label:SetPoint("CENTER", text, "LEFT", width + 6 + half, 0)
    return label
end

-- Whether a module has an option the player hasn't seen yet.
local function hasNewOption(module)
    for _, option in ipairs(module.options or {}) do
        if newRows[option] then
            return true
        end
    end
    return false
end

-- Saves the version once the Modules page shows, and drops the labels once the player leaves it.
local function updateSeen()
    local current = SettingsPanel:IsShown() and SettingsPanel:GetCurrentCategory()
    if current == modulesCategory then
        if not seen and ns.Text.NewerVersion(ns.version, ns.db.seenVersion) then
            ns.db.seenVersion = ns.version
        end
        seen = true
    elseif seen and next(newRows) then
        wipe(newRows)
        if refreshAll then
            refreshAll()
        end
    end
end

-- Probe: Settings.CategoryChanged and GetCurrentCategory are Mainline's (the `forever` UI source
-- has them); without them nothing is marked new.
local function trackNew(order)
    if not (SettingsPanel and SettingsPanel.GetCurrentCategory and EventRegistry
        and EventRegistry.RegisterCallback and canLabel()) then
        return
    end
    for _, name in ipairs(order) do
        local module = ns.modules[name]
        if since(module.added) then
            newRows[name] = true -- all of it is new, so its options aren't marked
        else
            for _, option in ipairs(module.options or {}) do
                if not option.debug and (since(option.added) or since(option.changed)) then
                    newRows[option] = true
                end
            end
        end
    end
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

-- Whether a module's options are shown on the Debug page (`debug`) or the Modules page.
local function hasOptions(module, debug)
    for _, option in ipairs(module.options or {}) do
        if (option.debug or false) == debug then
            return true
        end
    end
    return false
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
-- Options marked `debug = true`, as Blizzard settings rows, grouped under a header per module.

-- Greys a row out while the module is off, so it shows nothing on it applies. Probe:
-- AddModifyPredicate is Mainline's; ManiaTip uses it on Forever.
local function greyWhenOff(initializer, module)
    if initializer and initializer.AddModifyPredicate then
        initializer:AddModifyPredicate(function() return module.db.enabled end)
    end
end

-- The Blizzard setting behind one of a module's options, read and written through the module.
local function optionSetting(category, module, option)
    local varType = Settings.VarType.Boolean
    if option.choices then
        varType = Settings.VarType.String
    elseif option.min then
        varType = Settings.VarType.Number
    end
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s_%s", module.name, option.key), varType,
        option.name, module.defaults[option.key],
        function() return module.db[option.key] end,
        function(value)
            if option.min then
                value = ns.SliderValue(option, value)
            end
            change(function()
                ns.SetOption(module.name, option.key, value)
            end)
        end)
    track(module, setting)
    return setting
end

local function optionByKey(module, key)
    for _, option in ipairs(module.options or {}) do
        if option.key == key then
            return option
        end
    end
end

-- Whether a checkbox and its slider (`option.slider`) can share a row, like Blizzard's own. Probe:
-- the combined row is Mainline's; without it the slider gets a row of its own under the checkbox.
local function canCombine()
    return CreateSettingsCheckboxSliderInitializer ~= nil and Settings.CreateSliderOptions ~= nil
end

-- A checkbox option and its slider option in one row. Rows under the checkbox (`requires`) follow
-- the checkbox.
local function addCheckboxSlider(category, layout, module, option, slider)
    local checkbox = optionSetting(category, module, option)
    local initializer = CreateSettingsCheckboxSliderInitializer(checkbox, option.name,
        option.description, optionSetting(category, module, slider), sliderOptions(slider),
        slider.name, slider.description)
    initializer.GetSetting = function() return checkbox end
    layout:AddInitializer(initializer)
    return initializer
end

-- A debug option: a checkbox, a dropdown when it lists `choices`, or a slider when it has `min`
-- and `max` (in one row with the checkbox that names it as its `slider`, where it can), greyed
-- out while the module is off (or under the checkbox option named by `requires`, greyed out while
-- that is off). `added` maps the module's option keys to their rows, for `requires`.
local function addOption(category, layout, module, option, added)
    local choices, slider = option.choices, option.min
    if added[option.key] then
        return -- a slider already in its checkbox's row
    end
    if choices and not (Settings.CreateDropdown and Settings.CreateControlTextContainer) then
        return -- Probe: dropdowns are Mainline's; leave the option at its default without one.
    end
    if slider and not (Settings.CreateSlider and Settings.CreateSliderOptions) then
        return -- Probe: sliders are Mainline's; ArcaneWizardLibrary uses them on Forever.
    end
    local initializer
    local rowSlider = option.slider and layout and canCombine()
        and optionByKey(module, option.slider)
    if rowSlider then
        initializer = addCheckboxSlider(category, layout, module, option, rowSlider)
        added[rowSlider.key] = initializer
    elseif slider then
        local setting = optionSetting(category, module, option)
        initializer = Settings.CreateSlider(category, setting, sliderOptions(option),
            option.description)
    elseif choices then
        local setting = optionSetting(category, module, option)
        initializer = Settings.CreateDropdown(category, setting, function()
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
    local requires = option.requires and added[option.requires]
    if requires and initializer and initializer.SetParentInitializer then
        initializer:SetParentInitializer(requires, function()
            local value = module.db[option.requires]
            return module.db.enabled and value and value ~= "off" -- a checkbox, or a dropdown
        end)
    else
        greyWhenOff(initializer, module)
    end
    added[option.key] = initializer
end

local function addHeader(layout, text)
    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
end

-- A module's debug options, in the order it lists them. An option whose `section` differs from
-- the one before it starts a section header.
local function addDebugOptions(category, layout, module)
    local section
    local added = {}
    for _, option in ipairs(module.options or {}) do
        if option.debug then
            if option.section and option.section ~= section then
                addHeader(layout, option.section)
            end
            section = option.section
            addOption(category, layout, module, option, added)
        end
    end
end

-- A module's debug buttons (`module.debugActions`, the same shape as `actions`), after its
-- options.
local function addDebugActions(layout, module)
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for i, action in ipairs(module.debugActions or {}) do
        local initializer = CreateSettingsButtonInitializer(action.name, action.button,
            actionFn(module, action, i), action.description, true)
        greyWhenOff(initializer, module)
        layout:AddInitializer(initializer)
    end
end

-- Defaults button -----------------------------------------------------------------------------
-- Blizzard's Defaults button, at the top right of a settings list, asks "These Settings" or "All
-- Settings", and All Settings resets the whole game. On our list page (Debug) our own Defaults
-- button sits over it instead, with our popup (askDefaults). Blizzard's is faded out underneath
-- (never changed otherwise), and ours shows and hides with it, since Blizzard hides it while
-- searching. The Modules page is drawn by us and has its own.

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

-- The Modules page's groups, in order: a module's `category` and its label. A module without one
-- goes under Other.
local CATEGORIES = {
    { "automation", L.CATEGORY_AUTOMATION },
    { "items", L.CATEGORY_ITEMS },
    { "interface", L.CATEGORY_INTERFACE },
    { "chat", L.CATEGORY_CHAT },
    { "map", L.CATEGORY_MAP },
    { "unitframes", L.CATEGORY_UNITFRAMES },
    { "nameplates", L.CATEGORY_NAMEPLATES },
    { "other", L.CATEGORY_OTHER },
}
local CATEGORY_NAMES = {}
for _, group in ipairs(CATEGORIES) do
    CATEGORY_NAMES[group[1]] = group[2]
end

local function categoryOf(module)
    return CATEGORY_NAMES[module.category] and module.category or "other"
end

-- Modules page --------------------------------------------------------------------------------
-- A page we draw ourselves, built the first time it's shown: under the title, a Layout dropdown,
-- a search box and our Defaults button, then the modules in the layout the player picked. Every
-- layout is made of the same pieces (a module's checkbox and name, its rows of options, notice
-- and buttons, category headers and counts) and only arranges them, so how an option looks or
-- works is written once. A layout is built the first time it's picked and kept, so switching is
-- live. Our own frames from Blizzard's templates and art (the Settings panel's minimal checkboxes,
-- sliders, dropdowns, tabs, and sidebar highlight), so nothing of Blizzard's pooled Settings rows
-- is touched. Every change goes through ns.SetEnabled and ns.SetOption, then ns.RefreshSetting,
-- which puts every piece of that module back to what's saved, so /fpp and the page agree.

local ROW_HEIGHT = 26 -- an option's row, as in Blizzard's lists
local INDENT = 15 -- an option under another (`requires`), or a module's rows under it in a list
local NARROW_CONTROL = 150 -- where an option's control starts in a narrow block, after its name

-- The layouts, in the dropdown's order. The first is the default.
local LAYOUTS = {
    { "details", L.SETTINGS_LAYOUT_DETAILS },
    { "list", L.SETTINGS_LAYOUT_LIST },
    { "tabs", L.SETTINGS_LAYOUT_TABS },
    { "addons", L.SETTINGS_LAYOUT_ADDONS },
    { "cards", L.SETTINGS_LAYOUT_CARDS },
}
local builders = {} -- layout key -> function(frame) that draws it and returns { relayout, show }

local listed = {} -- the names of the modules on the page, by category, then title
local searchText = {} -- module name -> its title and description, lowercased
local filter, filterText -- the search text, lowercased and as typed, or nil while the box is empty
local page -- the page's frames, once built
local wanted -- a module ns.OpenSettings asked for before the page was built
local bound = {} -- module name -> functions that put what shows of it back to what's saved
local counters = {} -- functions that recount how many modules of a category are on
local refreshModule -- puts one module back to what's saved everywhere it shows

local function matches(name)
    return not filter or (searchText[name] or ""):find(filter, 1, true) ~= nil
end

local function inGroup(name, group)
    return categoryOf(ns.modules[name]) == group
end

-- Whether a module of `group` shows, given `shown(name)` for one module.
local function anyShown(group, shown)
    for _, name in ipairs(listed) do
        if (not group or inGroup(name, group)) and shown(name) then
            return true
        end
    end
    return false
end

local function countOn(group)
    local on, total = 0, 0
    for _, name in ipairs(listed) do
        if inGroup(name, group) then
            total = total + 1
            if ns.modules[name].db.enabled then
                on = on + 1
            end
        end
    end
    return on, total
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

-- The modules shown in the layout `key`, or details when it's no layout any more.
local function layoutKey()
    for _, layout in ipairs(LAYOUTS) do
        if layout[1] == ns.db.modulesLayout then
            return layout[1]
        end
    end
    return LAYOUTS[1][1]
end

-- Pieces ----------------------------------------------------------------------------------------

local function showTooltip(owner, title, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if text and text ~= "" then
        GameTooltip:AddLine(text, 1, 0.82, 0, true) -- gold, like Blizzard's settings tooltips
    end
    GameTooltip:Show()
end

-- The tooltip a row shows over itself and its controls, as Blizzard's settings rows do, and the
-- row's hover highlight, when it has one.
local function addTooltip(row, title, text, ...)
    local function enter()
        if row.hover then
            row.hover:Show()
        end
        if text and text ~= "" then
            showTooltip(row, title, text)
        end
    end
    local function leave()
        if row.hover then
            row.hover:Hide()
        end
        if GameTooltip:GetOwner() == row then
            GameTooltip:Hide()
        end
    end
    for _, frame in ipairs({ row, ... }) do
        frame:HookScript("OnEnter", enter)
        frame:HookScript("OnLeave", leave)
    end
end

-- The faint white a row of a wide list gets under the mouse, as Blizzard's settings rows do.
local function addHover(row)
    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetColorTexture(1, 1, 1, 0.1)
    row.hover:SetAllPoints()
    row.hover:Hide()
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

local function setEnabled(name, on)
    ns.SetEnabled(name, on)
    ns.RefreshSetting(name)
end

local function setOption(module, option, value)
    ns.SetOption(module.name, option.key, value)
    ns.RefreshSetting(module.name)
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

-- Blizzard's menu dropdown, its radio choices from `choices()`, each { value, text }. Probe:
-- Mainline's.
local function newMenu(parent, width, choices, isSelected, select)
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
        for _, choice in ipairs(choices) do
            root:CreateRadio(choice[2], isSelected, select, choice[1])
        end
    end)
    return dropdown
end

-- The gear beside a module's checkbox that shows its options: gold while they're hidden, white
-- while they show (`isOpen()`), like a pressed button.
local GEAR = "Interface\\WorldMap\\Gear_64" -- the cog Leatrix Maps uses for its option buttons

local function newGear(row, title, isOpen, onClick)
    local gear = CreateFrame("Button", nil, row)
    gear:SetSize(18, 18)
    gear:SetNormalTexture(GEAR)
    gear:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
    gear:SetHighlightTexture(GEAR, "ADD")
    gear:GetHighlightTexture():SetTexCoord(0, 0.5, 0, 0.5)
    function gear.tint()
        if isOpen() then
            gear:GetNormalTexture():SetVertexColor(1, 1, 1)
        else
            gear:GetNormalTexture():SetVertexColor(1, 0.82, 0) -- gold, like the labels
        end
    end
    local function tooltip()
        GameTooltip:SetOwner(gear, "ANCHOR_RIGHT")
        GameTooltip:SetText(format(isOpen() and L.SETTINGS_HIDE_OPTIONS or L.SETTINGS_SHOW_OPTIONS,
            title), 1, 1, 1)
        GameTooltip:Show()
    end
    gear:SetScript("OnClick", function()
        onClick()
        gear.tint()
        tooltip()
    end)
    gear:SetScript("OnEnter", function()
        if row.hover then
            row.hover:Show()
        end
        tooltip()
    end)
    gear:SetScript("OnLeave", function()
        if row.hover then
            row.hover:Hide()
        end
        GameTooltip:Hide()
    end)
    gear.tint()
    return gear
end

-- The module's on/off checkbox, kept in step with its others.
local function newModuleCheck(parent, name, size)
    local box = newCheckbox(parent, size, function(checked) setEnabled(name, checked) end)
    bind(name, function()
        box:SetChecked(ns.modules[name].db.enabled and true or false)
    end)
    return box
end

-- The module's name, at most `room` wide, with a NEW label after it while the module is new.
-- With `fonts` ({ on, off }) it's greyed while the module is off.
local function newModuleName(parent, name, font, room, fonts)
    local module = ns.modules[name]
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(module.title or name)
    local isNew = newRows[name] and canLabel()
    text:SetWidth(min(ns.Text.Width(text) + 2, room - (isNew and 40 or 0)))
    local new = isNew and newLabel(parent, text)
    bind(name, function()
        if fonts then
            text:SetFontObject(module.db.enabled and fonts[1] or fonts[2])
        end
        if new then
            new:SetShown(newRows[name] and true or false)
        end
    end)
    return text
end

-- How many modules of `group` are on, kept up to date.
local function newCount(parent, group)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    local function update()
        text:SetText(format(L.SETTINGS_ON_COUNT, countOn(group)))
    end
    counters[#counters + 1] = update
    update()
    return text
end

-- A category's header across a wide list, like Blizzard's section headers, with its count.
local function newHeader(parent, width, group, counts)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(width, 45)
    local text = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    text:SetPoint("TOPLEFT", 7, -16)
    text:SetText(CATEGORY_NAMES[group])
    if counts then
        newCount(header, group):SetPoint("TOPRIGHT", -24, -20)
    end
    return header
end

-- "No modules match" while the search hides them all.
local function newEmpty(parent, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, 40)
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    text:SetPoint("TOPLEFT", 12, -14)
    text:SetWidth(width - 24)
    text:SetJustifyH("LEFT")
    return frame, function()
        text:SetText(format(L.SETTINGS_NO_MATCH, filterText or ""))
        return not anyShown(nil, matches)
    end
end

-- Moves `scroll` so `frame`, in its content, is at the top. After a frame, once the new layout's
-- sizes are known.
local function scrollTo(scroll, content, frame)
    if not (C_Timer and frame) then
        return
    end
    C_Timer.After(0, function()
        local top, inner = content:GetTop(), frame:GetTop()
        if top and inner then
            local range = scroll:GetVerticalScrollRange() or 0
            scroll:SetVerticalScroll(min(max(top - inner - 4, 0), range))
        end
    end)
end

-- Stacks ----------------------------------------------------------------------------------------
-- A stack is a frame whose entries ({ frame, shown, gap }) sit one under the other, `top` down
-- from its top, each only while its `shown()` is true. An entry can wait to `make()` its frame
-- until it first shows. A stack inside a stack is laid out first, and left out while nothing in
-- it shows. Lists, the rows of a module's options, and the details all stack this way.

local function newStack(parent, width, gap)
    local stack = CreateFrame("Frame", nil, parent)
    stack:SetWidth(width)
    stack.entries, stack.gap, stack.top = {}, gap or 0, 0
    return stack
end

local function addEntry(stack, frame, shown, gap)
    local entry = { frame = frame, shown = shown, gap = gap }
    stack.entries[#stack.entries + 1] = entry
    return entry
end

local function layoutStack(stack)
    local y, any = -stack.top, false
    for _, entry in ipairs(stack.entries) do
        local shown = not entry.shown or entry.shown()
        if shown and not entry.frame and entry.make then
            entry.frame = entry.make()
        end
        local frame = entry.frame
        if frame then
            if shown and frame.entries then
                shown = layoutStack(frame)
            end
            frame:SetShown(shown and true or false)
            if shown then
                if any then
                    y = y - (entry.gap or stack.gap)
                end
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", 0, y)
                y = y - frame:GetHeight()
                any = true
            end
        end
    end
    stack:SetHeight(max(-y + (stack.bottom or 0), 1))
    return any
end

-- A scrolling stack in `scroll`.
local function scrollStack(scroll, width, gap)
    local content = newStack(scroll, width, gap)
    scroll:SetScrollChild(content)
    return content
end

-- A module's rows -------------------------------------------------------------------------------
-- A block is a stack of a module's rows: a name on the left and its control after, wide (across a
-- list, placed like Blizzard's settings rows, which put the control at the middle) or narrow (the
-- details beside the list, the Cards dialog), moved in by `indent`. Its `updates` put its controls
-- back to what's saved.

local function newBlock(parent, width, wide, indent)
    local block = newStack(parent, width, wide and 6 or 4)
    block.updates, block.wide, block.indent = {}, wide, indent or 0
    if wide then
        block.labelLeft = 37
        block.controlLeft = floor(width / 2) - 80
        block.labelRight = floor(width / 2) - 85
    else
        block.labelLeft = 4
        block.controlLeft = NARROW_CONTROL
        block.labelRight = NARROW_CONTROL - 4
    end
    local room = width - block.controlLeft
    block.sliderWidth = min(wide and 250 or 200, room - 50)
    block.dropdownWidth = min(wide and 220 or 180, room - 16)
    block.buttonWidth = min(wide and 200 or 180, room - 16)
    return block
end

local function refreshBlock(block)
    for _, update in ipairs(block.updates) do
        update()
    end
end

-- A row: `text` on the left, gold while `on()` and grey otherwise, and the space after it for a
-- control. Shown only while `shown()` is true, when given. `narrow` keeps room for a NEW label.
local function addRow(block, text, indent, on, shown, narrow)
    local row = CreateFrame("Frame", nil, block)
    row:EnableMouse(true)
    row:SetWidth(block:GetWidth())
    if block.wide then
        addHover(row)
    end
    local left = block.labelLeft + block.indent + indent
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", left, 0)
    label:SetWidth(block.labelRight - left - (narrow or 0))
    label:SetJustifyH("LEFT")
    label:SetText(text)
    row:SetHeight(max(ROW_HEIGHT, label:GetStringHeight() + 8))
    addEntry(block, row, shown)
    if on then
        block.updates[#block.updates + 1] = function()
            label:SetFontObject(on() and "GameFontNormal" or "GameFontDisable")
        end
    end
    return row, label
end

-- One of the module's options, with `byKey` for the option it's under (`requires`) or the slider
-- in its row (`slider`), and `done` for those already drawn.
local function addOptionRow(block, module, option, byKey, done)
    local parent = option.requires and byKey[option.requires]
    local function on()
        if not module.db.enabled then
            return false
        end
        if parent then
            local value = module.db[parent.key]
            return value and value ~= "off" and true or false -- a checkbox, or a dropdown
        end
        return true
    end
    local isNew = newRows[option] and canLabel()
    local row, label = addRow(block, option.name, parent and INDENT or 0, on, nil, isNew and 40)
    local updates = block.updates
    if isNew then
        local new = newLabel(row, label)
        updates[#updates + 1] = function()
            new:SetShown(newRows[option] and true or false)
        end
    end
    local left = block.controlLeft
    local pair = option.slider and byKey[option.slider]
    if pair and pair.min then
        -- A checkbox and its slider in one row, the slider greyed while the checkbox is off.
        done[pair.key] = true
        local box = newCheckbox(row, 30, function(checked) setOption(module, option, checked) end)
        box:SetPoint("LEFT", left, 0)
        local slider = newSlider(row, module, pair, block.sliderWidth - 36)
        if slider then
            slider:SetPoint("LEFT", box, "RIGHT", 6, 0)
        end
        updates[#updates + 1] = function()
            box:SetChecked(module.db[option.key] and true or false)
            box:SetEnabled(on())
            if slider then
                slider:SetValue(module.db[pair.key])
                slider:SetEnabled(on() and module.db[option.key] and true or false)
            end
        end
        addTooltip(row, option.name, option.description, box)
    elseif option.min then
        local slider = newSlider(row, module, option, block.sliderWidth)
        if not slider then
            return -- leave the option at its default without one
        end
        slider:SetPoint("LEFT", left + 6, 0)
        updates[#updates + 1] = function()
            slider:SetValue(module.db[option.key])
            slider:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, slider.Slider)
    elseif option.choices then
        local dropdown = newMenu(row, block.dropdownWidth, option.choices, function(value)
            return module.db[option.key] == value
        end, function(value)
            setOption(module, option, value)
        end)
        if not dropdown then
            return
        end
        dropdown:SetPoint("LEFT", left + 6, 0)
        updates[#updates + 1] = function()
            dropdown:GenerateMenu()
            dropdown:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, dropdown)
    else
        local box = newCheckbox(row, 30, function(checked) setOption(module, option, checked) end)
        box:SetPoint("LEFT", left, 0)
        updates[#updates + 1] = function()
            box:SetChecked(module.db[option.key] and true or false)
            box:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, box)
    end
end

-- A row with a button: one of `module.actions`, the module's notice, or the way to its own page.
-- `title` heads its tooltip when `text` isn't plain.
local function addButtonRow(block, text, on, shown, button, fn, tooltip, title)
    local row = addRow(block, text, 0, on, shown)
    local control = newButton(row, button, block.buttonWidth, fn)
    control:SetPoint("LEFT", block.controlLeft + 6, 0)
    if on then
        block.updates[#block.updates + 1] = function()
            control:SetEnabled(on())
        end
    end
    addTooltip(row, title or text, tooltip, control)
end

-- A line of text across a block: the Options header, or "no options".
local function addLine(block, font, text, gap)
    local row = CreateFrame("Frame", nil, block)
    row:SetSize(block:GetWidth(), font == "GameFontHighlightLarge" and 24 or ROW_HEIGHT)
    local line = row:CreateFontString(nil, "OVERLAY", font)
    line:SetPoint("LEFT", block.labelLeft + block.indent, 0)
    line:SetText(text)
    addEntry(block, row, nil, gap)
end

-- Whether a module has anything to show beyond its checkbox: options, buttons, or its own page.
local function hasDetails(module)
    return hasOptions(module, false) or module.actions ~= nil
        or (module.BuildPage and pages[module.name]) ~= nil
end

-- Fills a block with a module's rows: with `parts.enabled` its Enabled checkbox, with
-- `parts.notice` its notice, and with `parts.options` its options and buttons, in the order it
-- lists them (their `section`s only order them here), under an Options header with
-- `parts.heading`, which also says when there are none.
local function addModuleRows(block, module, parts)
    local name = module.name
    local function on()
        return module.db.enabled and true or false
    end
    if parts.enabled then
        local row = addRow(block, L.SETTINGS_ENABLED, 0)
        local box = newModuleCheck(row, name, 30)
        box:SetPoint("LEFT", block.controlLeft, 0)
    end
    -- A gray row while `shown()` is true, such as a Blizzard setting the module needs being off,
    -- with a button that fixes it. ns.CVars.OffNotice makes one for a CVar.
    local notice = module.notice
    if parts.notice and notice then
        addButtonRow(block, format("|cff999999%s|r", notice.text), nil, notice.shown,
            notice.button, function()
                notice.fn()
                refreshModule(name)
                -- A CVar can change a moment later (ns.CVars waits out combat).
                if C_Timer then
                    C_Timer.After(0.2, function() refreshModule(name) end)
                end
            end, notice.description, notice.text)
    end
    if parts.options then
        local options, byKey, done = {}, {}, {}
        for _, option in ipairs(module.options or {}) do
            if not option.debug then
                options[#options + 1] = option
                byKey[option.key] = option
            end
        end
        if hasDetails(module) then
            if parts.heading then
                addLine(block, "GameFontHighlightLarge", L.SETTINGS_OPTIONS, 16)
            end
            for _, option in ipairs(options) do
                if not done[option.key] then
                    addOptionRow(block, module, option, byKey, done)
                end
            end
            for i, action in ipairs(module.actions or {}) do
                addButtonRow(block, action.name, on, nil, action.button,
                    actionFn(module, action, i), action.description)
            end
            local ownPage = module.BuildPage and pages[name]
            if ownPage then
                addButtonRow(block, "", nil, nil, format(L.SETTINGS_OPEN_PAGE, module.title or name),
                    function() open(ownPage) end)
            end
        elseif parts.heading then
            addLine(block, "GameFontDisable", L.SETTINGS_NO_OPTIONS, 16)
        end
    end
    bind(name, function() refreshBlock(block) end)
    return block
end

-- A module's options, or its notice, under its row in a wide list: a block made when it first
-- shows.
local function addUnder(stack, width, module, parts, shown)
    local entry = addEntry(stack, nil, shown)
    entry.make = function()
        return addModuleRows(newBlock(stack, width, true, INDENT), module, parts)
    end
end

-- List, and Category Tabs ------------------------------------------------------------------------
-- Every module one under the other under its category's header, each a row like Blizzard's
-- settings rows: its name, its checkbox at the middle, and a gear that shows its options under it.
-- `inTab(name)` narrows it further, and `counts` puts each category's count in its header.

local function buildWideList(frame, top, inTab, counts)
    local scroll = newScroll(frame)
    scroll:SetPoint("TOPLEFT", 0, top)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local width = page.width - 28
    local content = scrollStack(scroll, width, 6)
    content.top, content.bottom = 2, 12
    local expanded, rows = {}, {}
    local layout = { scroll = scroll }
    local function shown(name)
        return matches(name) and (not inTab or inTab(name))
    end
    local empty, noMatch = newEmpty(content, width)
    addEntry(content, empty, noMatch)
    local group
    for _, name in ipairs(listed) do
        local module = ns.modules[name]
        local title = module.title or name
        if categoryOf(module) ~= group then
            group = categoryOf(module)
            local current = group
            addEntry(content, newHeader(content, width, current, counts), function()
                return anyShown(current, shown)
            end)
        end
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(width, ROW_HEIGHT)
        row:EnableMouse(true)
        addHover(row)
        local center = floor(width / 2)
        newModuleName(row, name, "GameFontNormal", center - 85 - 37):SetPoint("LEFT", 37, 0)
        local box = newModuleCheck(row, name, 30)
        box:SetPoint("LEFT", center - 80, 0)
        if hasDetails(module) then
            -- A module with a new option starts with its options open, so it's seen.
            expanded[name] = hasNewOption(module) or nil
            row.gear = newGear(row, title, function() return expanded[name] end, function()
                expanded[name] = not expanded[name] or nil
                layoutStack(content)
            end)
            row.gear:SetPoint("LEFT", box, "RIGHT", 6, 0)
        end
        addTooltip(row, title, module.description, box)
        rows[name] = row
        local function rowShown()
            return shown(name)
        end
        addEntry(content, row, rowShown)
        if module.notice then
            addUnder(content, width, module, { notice = true }, rowShown)
        end
        if hasDetails(module) then
            addUnder(content, width, module, { options = true }, function()
                return shown(name) and expanded[name]
            end)
        end
    end
    function layout.relayout()
        layoutStack(content)
    end
    function layout.show(name)
        local row = rows[name]
        if row.gear then
            expanded[name] = true
            row.gear.tint()
        end
        layoutStack(content)
        scrollTo(scroll, content, row)
    end
    return layout
end

builders.list = function(frame)
    return buildWideList(frame, -4)
end

-- A tab per category (Blizzard's minimal tabs, as the Settings panel's own) over the same list,
-- showing that category's modules. All shows every one, and so does searching.
builders.tabs = function(frame)
    local current = "all"
    local tabs = {}
    local layout
    local function inTab(name)
        return filter or current == "all" or inGroup(name, current)
    end
    local function paint()
        local selected = filter and "all" or current
        for key, tab in pairs(tabs) do
            if tab.SetSelected then
                tab:SetSelected(key == selected)
            elseif key == selected then
                tab:LockHighlight()
            else
                tab:UnlockHighlight()
            end
        end
    end
    -- Probe: MinimalTabTemplate is Mainline's; without it, plain buttons.
    local minimal = hasTemplate("MinimalTabTemplate")
    local x = 8
    local function addTab(key, text, group)
        local tab = CreateFrame("Button", nil, frame, minimal and "MinimalTabTemplate"
            or "UIPanelButtonTemplate")
        local label = tab.Text or tab:GetFontString()
        if label then
            label:SetText(text)
        else
            tab:SetText(text)
        end
        tab:SetSize(ns.Text.Width(label or tab:GetFontString()) + 24, minimal and 37 or 22)
        tab:SetPoint("TOPLEFT", x, 0)
        x = x + tab:GetWidth() + 2
        tab:SetScript("OnClick", function()
            current = key
            if layout then
                paint()
                layout.relayout()
                layout.scroll:SetVerticalScroll(0)
            end
        end)
        if group then
            tab:HookScript("OnEnter", function()
                showTooltip(tab, text, format(L.SETTINGS_ON_COUNT, countOn(group)))
            end)
            tab:HookScript("OnLeave", function() GameTooltip:Hide() end)
        end
        tabs[key] = tab
    end
    addTab("all", L.SETTINGS_TAB_ALL)
    for _, group in ipairs(CATEGORIES) do
        if anyShown(group[1], function() return true end) then
            addTab(group[1], group[2], group[1])
        end
    end
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetAtlas("Options_HorizontalDivider", true)
    divider:SetPoint("TOP", 0, minimal and -37 or -24)
    layout = buildWideList(frame, minimal and -42 or -30, inTab, true)
    local relayout, show = layout.relayout, layout.show
    function layout.relayout()
        paint()
        relayout()
    end
    function layout.show(name)
        current = categoryOf(ns.modules[name])
        paint()
        show(name)
    end
    return layout
end

-- AddOn List -------------------------------------------------------------------------------------
-- Modeled on Blizzard's AddOn List: a bar per category with an arrow that opens and closes it
-- (all closed at first, opened while searching) and how many are on, and each module's
-- description under its name, so it reads without hovering. The gear shows its options under it.

local function expandArt(texture, open)
    local atlas = open and "Options_ListExpand_Right_Expanded" or "Options_ListExpand_Right"
    if hasAtlas(atlas) then
        texture:SetAtlas(atlas, true)
    else
        texture:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up"
            or "Interface\\Buttons\\UI-PlusButton-Up")
        texture:SetSize(16, 16)
    end
end

builders.addons = function(frame)
    local scroll = newScroll(frame)
    scroll:SetPoint("TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local width = page.width - 28
    local content = scrollStack(scroll, width, 2)
    content.top, content.bottom = 6, 12
    local closed, expanded, rows, bars = {}, {}, {}, {}
    local layout = {}
    local empty, noMatch = newEmpty(content, width)
    addEntry(content, empty, noMatch)
    local group
    for _, name in ipairs(listed) do
        local module = ns.modules[name]
        local title = module.title or name
        if categoryOf(module) ~= group then
            group = categoryOf(module)
            local current = group
            closed[current] = true
            local bar = CreateFrame("Button", nil, content)
            bar:SetSize(width - 8, 30)
            local highlight = bar:CreateTexture(nil, "BACKGROUND")
            highlight:SetAllPoints()
            if hasAtlas("Options_List_Hover") then
                highlight:SetAtlas("Options_List_Hover")
            else
                highlight:SetColorTexture(1, 1, 1, 0.1)
            end
            highlight:Hide()
            local arrow = bar:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("LEFT", 10, 0)
            local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", 34, 0)
            label:SetText(CATEGORY_NAMES[current])
            newCount(bar, current):SetPoint("RIGHT", -14, 0)
            function bar.paint()
                expandArt(arrow, filter or not closed[current])
            end
            bar:SetScript("OnClick", function()
                closed[current] = not closed[current] or nil
                layout.relayout()
            end)
            bar:SetScript("OnEnter", function() highlight:Show() end)
            bar:SetScript("OnLeave", function() highlight:Hide() end)
            bars[current] = bar
            addEntry(content, bar, function()
                return anyShown(current, matches)
            end, 6)
        end
        local current = group
        local function rowShown()
            return matches(name) and (filter or not closed[current]) and true or false
        end
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(width - 8, 42)
        row:EnableMouse(true)
        addHover(row)
        local box = newModuleCheck(row, name, 30)
        box:SetPoint("TOPLEFT", 6, -6)
        newModuleName(row, name, "GameFontNormal", width - 110, { "GameFontNormal", "GameFontDisable" })
            :SetPoint("TOPLEFT", 42, -8)
        local description = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        description:SetPoint("TOPLEFT", 42, -25)
        description:SetWidth(width - 100)
        description:SetJustifyH("LEFT")
        description:SetWordWrap(false)
        description:SetText(module.description or "")
        if hasDetails(module) then
            if hasNewOption(module) then
                expanded[name], closed[current] = true, nil
            end
            row.gear = newGear(row, title, function() return expanded[name] end, function()
                expanded[name] = not expanded[name] or nil
                layoutStack(content)
            end)
            row.gear:SetPoint("TOPRIGHT", -16, -12)
        end
        addTooltip(row, title, module.description, box)
        rows[name] = row
        addEntry(content, row, rowShown)
        if module.notice then
            addUnder(content, width, module, { notice = true }, rowShown)
        end
        if hasDetails(module) then
            addUnder(content, width, module, { options = true }, function()
                return rowShown() and expanded[name]
            end)
        end
    end
    function layout.relayout()
        for _, bar in pairs(bars) do
            bar.paint()
        end
        layoutStack(content)
    end
    function layout.show(name)
        closed[categoryOf(ns.modules[name])] = nil
        local row = rows[name]
        if row.gear then
            expanded[name] = true
            row.gear.tint()
        end
        layout.relayout()
        scrollTo(scroll, content, row)
    end
    return layout
end

-- Cards ------------------------------------------------------------------------------------------
-- Two columns of cards under each category's header: a module's checkbox, name, and two lines of
-- its description, with a mark while its notice applies. The gear opens its options in a dialog
-- like Edit Mode's, with Revert to Defaults.

local CARD_HEIGHT = 62

-- Puts a module's options back to their defaults (not whether it's on).
local function revertOptions(module)
    for _, option in ipairs(module.options or {}) do
        if not option.debug and module.db[option.key] ~= module.defaults[option.key] then
            ns.SetOption(module.name, option.key, module.defaults[option.key])
        end
    end
    ns.RefreshSetting(module.name)
end

-- The dialog, over the page, with a veil under it so the cards can't be clicked while it's open.
local function newDialog(frame)
    local veil = CreateFrame("Frame", nil, frame)
    veil:SetAllPoints(page.frame)
    veil:SetFrameLevel(frame:GetFrameLevel() + 40)
    veil:EnableMouse(true)
    local shade = veil:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, 0.35)
    -- Probe: as Edit Mode's dialog in Lib/EditMode.lua.
    local border = hasTemplate("DialogBorderTranslucentTemplate")
    local dialog = CreateFrame("Frame", nil, veil, border and "DialogBorderTranslucentTemplate"
        or "BackdropTemplate")
    if not border and dialog.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        dialog:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        dialog:SetBackdropColor(0, 0, 0, 0.9)
    end
    local width = min(460, page.width - 40)
    dialog:SetSize(width, min(470, (page.frame:GetHeight() or 0) > 0 and page.frame:GetHeight() - 30
        or 470))
    dialog:SetPoint("CENTER", page.frame, "CENTER")
    dialog:SetFrameLevel(veil:GetFrameLevel() + 5)
    dialog:EnableMouse(true)
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    dialog.title:SetPoint("TOP", 0, -18)
    dialog.description = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.description:SetPoint("TOP", dialog.title, "BOTTOM", 0, -6)
    dialog.description:SetWidth(width - 40)
    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() veil:Hide() end)
    dialog.scroll = newScroll(dialog)
    dialog.scroll:SetPoint("BOTTOMRIGHT", -30, 48)
    dialog.content = CreateFrame("Frame", nil, dialog.scroll)
    dialog.content:SetWidth(width - 50)
    dialog.scroll:SetScrollChild(dialog.content)
    dialog.blocks = {}
    dialog.revert = newButton(dialog, L.SETTINGS_REVERT, 160, function()
        revertOptions(ns.modules[dialog.name])
    end)
    dialog.revert:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -4, 16)
    dialog.revert:HookScript("OnEnter", function(self)
        showTooltip(self, L.SETTINGS_REVERT, L.SETTINGS_REVERT_TIP)
    end)
    dialog.revert:HookScript("OnLeave", function() GameTooltip:Hide() end)
    newButton(dialog, L.SETTINGS_CLOSE, 160, function() veil:Hide() end)
        :SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 4, 16)
    veil:Hide()
    dialog.veil = veil
    return dialog
end

builders.cards = function(frame)
    local scroll = newScroll(frame)
    scroll:SetPoint("TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local width = page.width - 28
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(width)
    scroll:SetScrollChild(content)
    local cardWidth = floor((width - 30) / 2)
    local cards, headers = {}, {}
    local layout = {}
    local dialog
    local empty, noMatch = newEmpty(content, width)

    -- Shows a module in the dialog: its Enabled checkbox, notice, and options.
    local function openDialog(name)
        local module = ns.modules[name]
        dialog = dialog or newDialog(frame)
        dialog.name = name
        dialog.title:SetText(module.title or name)
        dialog.description:SetText(module.description or "")
        dialog.scroll:SetPoint("TOPLEFT", 14, -(18 + dialog.title:GetStringHeight() + 6
            + dialog.description:GetStringHeight() + 14))
        for other, block in pairs(dialog.blocks) do
            block:SetShown(other == name)
        end
        local block = dialog.blocks[name]
        if not block then
            block = newBlock(dialog.content, dialog.content:GetWidth(), false)
            block:SetPoint("TOPLEFT")
            addModuleRows(block, module, { enabled = true, notice = true, options = true })
            dialog.blocks[name] = block
        end
        block:Show()
        refreshBlock(block)
        layoutStack(block)
        dialog.content:SetHeight(block:GetHeight())
        dialog.scroll:SetVerticalScroll(0)
        dialog.revert:SetEnabled(hasOptions(module, false))
        dialog.veil:Show()
    end

    for _, group in ipairs(CATEGORIES) do
        local header = CreateFrame("Frame", nil, content)
        header:SetSize(width, 30)
        local text = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        text:SetPoint("BOTTOMLEFT", 10, 6)
        text:SetText(group[2])
        newCount(header, group[1]):SetPoint("BOTTOMLEFT", text, "BOTTOMRIGHT", 8, 1)
        headers[group[1]] = header
    end
    for _, name in ipairs(listed) do
        local module = ns.modules[name]
        local title = module.title or name
        -- Probe: InsetFrameTemplate is Blizzard's dark inset panel; without it, a tooltip border.
        local inset = hasTemplate("InsetFrameTemplate")
        local card = CreateFrame("Frame", nil, content, inset and "InsetFrameTemplate"
            or "BackdropTemplate")
        if not inset and card.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
            card:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
            card:SetBackdropColor(0, 0, 0, 0.6)
        end
        card:SetSize(cardWidth, CARD_HEIGHT)
        card:EnableMouse(true)
        local box = newModuleCheck(card, name, 30)
        box:SetPoint("TOPLEFT", 5, -4)
        newModuleName(card, name, "GameFontNormal", cardWidth - 80,
            { "GameFontNormal", "GameFontDisable" }):SetPoint("TOPLEFT", 38, -11)
        local description = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        description:SetPoint("TOPLEFT", 38, -28)
        description:SetWidth(cardWidth - 50)
        description:SetJustifyH("LEFT")
        if description.SetMaxLines then
            description:SetMaxLines(2)
        end
        description:SetText(module.description or "")
        if hasDetails(module) or module.notice then
            local gear = newGear(card, title, function() return false end, function()
                openDialog(name)
            end)
            gear:SetPoint("TOPRIGHT", -8, -7)
        end
        local notice = module.notice
        if notice then
            -- The mark while the notice applies: open the options to fix it.
            local mark = CreateFrame("Frame", nil, card)
            mark:SetSize(16, 16)
            mark:SetPoint("TOPRIGHT", -30, -8)
            local icon = mark:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
            mark:EnableMouse(true)
            mark:SetScript("OnEnter", function()
                showTooltip(mark, notice.text, L.SETTINGS_FIX_NOTICE)
            end)
            mark:SetScript("OnLeave", function() GameTooltip:Hide() end)
            bind(name, function()
                mark:SetShown(notice.shown() and true or false)
            end)
        end
        addTooltip(card, title, module.description, box)
        cards[name] = card
    end

    function layout.relayout()
        local y, any = -6, false
        for _, group in ipairs(CATEGORIES) do
            local header = headers[group[1]]
            local column = 0
            header:Hide()
            for _, name in ipairs(listed) do
                local card = cards[name]
                if inGroup(name, group[1]) then
                    if matches(name) then
                        if column == 0 then
                            if not header:IsShown() then
                                header:ClearAllPoints()
                                header:SetPoint("TOPLEFT", 0, y)
                                header:Show()
                                y = y - header:GetHeight() - 4
                            end
                        end
                        card:ClearAllPoints()
                        card:SetPoint("TOPLEFT", 10 + column * (cardWidth + 10), y)
                        card:Show()
                        column = column + 1
                        if column == 2 then
                            column = 0
                            y = y - CARD_HEIGHT - 8
                        end
                        any = true
                    else
                        card:Hide()
                    end
                end
            end
            if column == 1 then
                y = y - CARD_HEIGHT - 8
            end
            if header:IsShown() then
                y = y - 6
            end
        end
        empty:SetShown(noMatch())
        empty:ClearAllPoints()
        empty:SetPoint("TOPLEFT")
        if not any then
            y = y - empty:GetHeight()
        end
        content:SetHeight(-y + 8)
    end
    function layout.show(name)
        layout.relayout()
        scrollTo(scroll, content, cards[name])
        openDialog(name)
    end
    return layout
end

-- List and Details -------------------------------------------------------------------------------
-- A compact checklist of every module on the left, grouped under small gold category labels, and
-- the selected module on the right: its title, category and description, its Enabled checkbox,
-- notice, and options, each side scrolling on its own.

local LIST_LEFT, LIST_WIDTH, LIST_ROW = 7, 186, 20 -- the module list and its rows
local PANE_LEFT = 234 -- where the details start, right of the list and its scroll bar

builders.details = function(frame)
    local layout = {}
    local selected
    local rows, views = {}, {}

    local list = newScroll(frame)
    list:SetPoint("TOPLEFT", LIST_LEFT, -4)
    list:SetPoint("BOTTOMLEFT", LIST_LEFT, 8)
    list:SetWidth(LIST_WIDTH)
    local content = scrollStack(list, LIST_WIDTH, 2)
    content.bottom = 8

    local pane = newScroll(frame)
    pane:SetPoint("TOPLEFT", PANE_LEFT, -4)
    pane:SetPoint("BOTTOMRIGHT", -32, 8)
    local width = page.width - PANE_LEFT - 32
    local paneContent = CreateFrame("Frame", nil, pane)
    paneContent:SetWidth(width)
    pane:SetScrollChild(paneContent)

    -- A faint gold line between the list and the details.
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.25)
    line:SetWidth(1)
    line:SetPoint("TOPLEFT", PANE_LEFT - 12, -10)
    line:SetPoint("BOTTOMLEFT", PANE_LEFT - 12, 14)

    -- Blizzard's sidebar highlight while a row is selected or under the mouse.
    local function paint(row)
        local atlas
        if selected == row.name then
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

    -- The module on the right: a narrow block under its title, category and description.
    local function buildView(name)
        local module = ns.modules[name]
        local view = newBlock(paneContent, width, false)
        view:SetPoint("TOPLEFT")
        local title = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        title:SetPoint("TOPLEFT", 4, -4)
        title:SetText(module.title or name)
        if newRows[name] and canLabel() then
            local new = newLabel(view, title)
            bind(name, function()
                new:SetShown(newRows[name] and true or false)
            end)
        end
        local group = view:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        group:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        group:SetText(CATEGORY_NAMES[categoryOf(module)])
        local description = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        description:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -10)
        description:SetWidth(width - 12)
        description:SetJustifyH("LEFT")
        description:SetText(module.description or "")
        view.top = 4 + title:GetStringHeight() + 4 + group:GetStringHeight() + 10
            + description:GetStringHeight() + 10
        view.bottom = 12
        return addModuleRows(view, module, { enabled = true, notice = true, options = true,
            heading = true })
    end

    local function choose(name)
        selected = name
        for _, row in pairs(rows) do
            paint(row)
        end
        for other, view in pairs(views) do
            view:SetShown(other == name)
        end
        if not name then
            return
        end
        if not views[name] then
            views[name] = buildView(name)
        end
        layoutStack(views[name])
        paneContent:SetHeight(views[name]:GetHeight())
        pane:SetVerticalScroll(0)
    end

    local empty, noMatch = newEmpty(content, LIST_WIDTH)
    addEntry(content, empty, noMatch)
    local group
    for _, name in ipairs(listed) do
        local module = ns.modules[name]
        if categoryOf(module) ~= group then
            group = categoryOf(module)
            local current = group
            local label = CreateFrame("Frame", nil, content)
            label:SetSize(LIST_WIDTH, 16)
            local text = label:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("BOTTOMLEFT", 2, 2)
            text:SetText(CATEGORY_NAMES[current])
            addEntry(content, label, function()
                return anyShown(current, matches)
            end, 12)
        end
        local row = CreateFrame("Button", nil, content)
        row:SetSize(LIST_WIDTH, LIST_ROW)
        row.name = name
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        local function hover(over)
            row.over = over
            paint(row)
        end
        local box = newModuleCheck(row, name, 22)
        box:SetPoint("LEFT", 0, 0)
        -- The checkbox takes the mouse from the row, so it keeps the row's highlight.
        box:HookScript("OnEnter", function() hover(true) end)
        box:HookScript("OnLeave", function() hover(false) end)
        newModuleName(row, name, "GameFontHighlight", LIST_WIDTH - 26,
            { "GameFontHighlight", "GameFontDisable" }):SetPoint("LEFT", box, "RIGHT", 2, 0)
        row:SetScript("OnClick", function()
            if selected ~= name then
                choose(name)
            end
        end)
        row:SetScript("OnEnter", function() hover(true) end)
        row:SetScript("OnLeave", function() hover(false) end)
        rows[name] = row
        addEntry(content, row, function() return matches(name) end)
    end

    -- Keeps the selection on a module the search shows, the first one when it hides it.
    function layout.relayout()
        layoutStack(content)
        if not (selected and matches(selected)) then
            local first
            for _, name in ipairs(listed) do
                if matches(name) then
                    first = name
                    break
                end
            end
            choose(first)
        elseif views[selected] then
            layoutStack(views[selected])
            paneContent:SetHeight(views[selected]:GetHeight())
        end
    end
    function layout.show(name)
        choose(name)
        scrollTo(list, content, rows[name])
    end

    -- Opens on the first module with a new option to see, or else the first.
    for _, name in ipairs(listed) do
        if hasNewOption(ns.modules[name]) then
            choose(name)
            break
        end
    end
    return layout
end

-- The page ---------------------------------------------------------------------------------------

function refreshModule(name)
    for _, fn in ipairs(bound[name] or {}) do
        fn()
    end
    for _, fn in ipairs(counters) do
        fn()
    end
    if page and page.active then
        page.active.relayout()
    end
end

function refreshAll()
    for _, list in pairs(bound) do
        for _, fn in ipairs(list) do
            fn()
        end
    end
    for _, fn in ipairs(counters) do
        fn()
    end
    if page and page.active then
        page.active.relayout()
    end
end

-- Shows the layout `key`, drawing it the first time.
local function useLayout(key)
    ns.db.modulesLayout = key
    local active = page.layouts[key]
    if not active then
        local container = CreateFrame("Frame", nil, page.body)
        container:SetAllPoints()
        active = builders[key](container)
        active.frame = container
        page.layouts[key] = active
    end
    for other, layout in pairs(page.layouts) do
        layout.frame:SetShown(other == key)
    end
    page.active = active
    refreshAll()
end

-- A search box at the top of the page, left of the Defaults button, that narrows the modules to
-- the ones whose title or description has the text. Blizzard's own search, at the top left of the
-- panel, finds settings across every addon, not modules. Probe: SearchBoxTemplate is Mainline's.
local function addSearchBox(frame, anchor)
    if not hasTemplate("SearchBoxTemplate") then
        return
    end
    local box = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    box:SetSize(160, 20)
    box:SetPoint("RIGHT", anchor, "LEFT", -12, 0)
    box:SetAutoFocus(false)
    if box.Instructions then
        box.Instructions:SetText(L.SETTINGS_SEARCH)
    end
    -- After the template's own OnTextChanged, which shows the clear button and the gray text.
    box:HookScript("OnTextChanged", function(self)
        local text = self:GetText():match("^%s*(.-)%s*$")
        filter = text ~= "" and strlower(text) or nil
        filterText = text
        if page.active then
            page.active.relayout()
        end
    end)
    return box
end

-- The Layout dropdown, a standard Blizzard one, left of the search box. Without one, the page
-- stays on the default layout.
local function addLayoutMenu(frame, anchor)
    local menu = newMenu(frame, 150, LAYOUTS, function(key)
        return layoutKey() == key
    end, useLayout)
    if not menu then
        return
    end
    menu:SetPoint("RIGHT", anchor, "LEFT", -14, 0)
    menu:HookScript("OnEnter", function()
        showTooltip(menu, L.SETTINGS_LAYOUT, L.SETTINGS_LAYOUT_TIP)
    end)
    menu:HookScript("OnLeave", function() GameTooltip:Hide() end)
    return menu
end

local function buildModules(frame)
    ns.AddPageTitle(frame, L.MODULES)
    local width = frame:GetWidth()
    page = { frame = frame, layouts = {}, width = width > 0 and width or 615 }

    local defaults = newButton(frame, SETTINGS_DEFAULTS or L.HOME_DEFAULTS, 96, askDefaults)
    defaults:SetPoint("TOPRIGHT", -10, -18)
    page.search = addSearchBox(frame, defaults)
    local menu = addLayoutMenu(frame, page.search or defaults)

    page.body = CreateFrame("Frame", nil, frame)
    page.body:SetPoint("TOPLEFT", 0, -56)
    page.body:SetPoint("BOTTOMRIGHT")
    useLayout(menu and layoutKey() or LAYOUTS[1][1])
    if wanted then
        page.active.show(wanted)
        wanted = nil
    end
    -- After /fpp or a preset changed things while the page was closed, and for notices.
    frame:HookScript("OnShow", refreshAll)
end

-- Welcome page --------------------------------------------------------------------------------
-- The top Forever++ page: what the addon is, how many modules are on, the way to the Modules and
-- Changelog pages, links, and the /fpp commands. Built the first time it's shown; the module count
-- updates each time.

local WEBSITE = "https://github.com/xIGBClutchIx/ForeverPlusPlus"
local ISSUES = WEBSITE .. "/issues"

local function metadata(field)
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get(ns.name, field) or ""
end

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

local function addButton(frame, text, category)
    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(140, 24)
    button:SetText(text)
    button:SetScript("OnClick", function() open(category) end)
    return button
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

local function buildWelcome(frame)
    ns.AddPageTitle(frame, ns.title)

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
    version:SetText(format(L.HOME_VERSION, metadata("Version"), metadata("Author")))

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
    y = y - 22

    local modules = addButton(frame, L.MODULES, modulesCategory)
    modules:SetPoint("TOPLEFT", 16, y)
    local last = modules
    if changelogCategory then
        last = addButton(frame, L.CHANGELOG, changelogCategory)
        last:SetPoint("LEFT", modules, "RIGHT", 8, 0)
    end

    -- Two presets on the same row, each asking first since they overwrite the player's settings.
    local function addPreset(text, tooltip, key, question, fn, anchor)
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(155, 24)
        button:SetText(text)
        button:SetScript("OnClick", function() ns.Confirm(key, question, fn) end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
        return button
    end
    local defaults = addPreset(L.DEFAULTS_RECOMMENDED, L.HOME_DEFAULTS_TIP, "DEFAULTS",
        L.HOME_DEFAULTS_ASK, ns.ApplyDefaults, last)
    local developerTip = format(L.HOME_DEVELOPER_TIP,
        concat(ns.DeveloperModules(), L.HOME_LIST_SEPARATOR))
    addPreset(L.DEFAULTS_DEVELOPER, developerTip, "DEVELOPER", L.HOME_DEVELOPER_ASK,
        ns.ApplyDeveloperDefaults, defaults)

    y = y - 44
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
-- The release notes from Changelog.lua, newest first, in a scrolling list. Built the first time
-- it's shown.

local function buildChangelog(frame)
    ns.AddPageTitle(frame, L.CHANGELOG)

    local scroll = newScroll(frame)
    scroll:SetPoint("TOPLEFT", 16, -64)
    scroll:SetPoint("BOTTOMRIGHT", -32, 8)

    local width = scroll:GetWidth()
    if width <= 0 then
        width = 560 -- about the width of the Settings page, if its size isn't known yet
    end
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(width)
    scroll:SetScrollChild(content)

    local y = 0
    -- A line of text across the list, wrapping, below the one before it.
    local function add(font, text, indent, gap)
        y = y - (gap or 0)
        local line = content:CreateFontString(nil, "OVERLAY", font)
        line:SetPoint("TOPLEFT", indent or 0, y)
        line:SetWidth(width - (indent or 0))
        line:SetJustifyH("LEFT")
        line:SetText(text)
        y = y - line:GetStringHeight()
    end

    for i, release in ipairs(ns.changelog or {}) do
        -- Unreleased notes have no date.
        local title = release.date and format(L.CHANGELOG_RELEASE, release.version, release.date)
            or release.version
        add("GameFontHighlightLarge", title, 0, i > 1 and 24 or 0)
        for _, section in ipairs(release.sections) do
            add("GameFontNormal", section[1], 0, 14)
            for _, entry in ipairs(section[2]) do
                local text = entry
                if type(entry) == "table" then
                    text = format("|cffffd100%s|r: %s", entry[1], entry[2]) -- gold, like GameFontNormal
                end
                add("GameFontHighlightSmall", format("- %s", text), 8, 6)
            end
        end
    end
    content:SetHeight(-y + 8)
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
            searchText[name] = strlower(format("%s\n%s", module.title or name,
                module.description or ""))
        end
    end

    -- Without subpages, the Modules page is the only one.
    if not subpages then
        local category = Settings.RegisterCanvasLayoutCategory(canvasFrame(buildModules), ns.title)
        Settings.RegisterAddOnCategory(category)
        mainCategory, modulesCategory = category, category
        return
    end

    local category = Settings.RegisterCanvasLayoutCategory(canvasFrame(buildWelcome), ns.title)
    modulesCategory = addCanvasPage(category, L.MODULES, buildModules)
    -- Pages modules draw themselves (tools such as Console Variables).
    for _, name in ipairs(grouped) do
        local module = ns.modules[name]
        if module.BuildPage then
            pages[name] = addCanvasPage(category, module.title or name, function(frame)
                module:BuildPage(frame)
            end)
        end
    end
    -- Debug options, grouped by module.
    local debugPage, debugLayout
    for _, name in ipairs(order) do
        local module = ns.modules[name]
        if hasOptions(module, true) or module.debugActions then
            if not debugPage then
                debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.DEBUG)
            end
            addHeader(debugLayout, module.title or name)
            addDebugOptions(debugPage, debugLayout, module)
            addDebugActions(debugLayout, module)
        end
    end
    changelogCategory = addCanvasPage(category, L.CHANGELOG, buildChangelog)
    Settings.RegisterAddOnCategory(category)
    mainCategory = category
    if debugPage then
        ourPages[debugPage] = true
        addDefaultsButton()
    end
end

---Opens the Forever++ welcome page in Settings, or a module: its own page, or the Modules page
---showing it, in whichever layout the player uses (after combat, if the player is in combat).
---@param name? string a module
---@return boolean opened false when this client's Settings can't open to it
function ns.OpenSettings(name)
    if name and pages[name] then
        return open(pages[name])
    end
    if name and searchText[name] then
        if page and page.active then
            -- Searching for something else would hide it.
            if not matches(name) and page.search then
                page.search:SetText("")
            end
            page.active.show(name)
        else
            wanted = name -- the page shows it once it's built
        end
        return open(modulesCategory)
    end
    return open(mainCategory)
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
