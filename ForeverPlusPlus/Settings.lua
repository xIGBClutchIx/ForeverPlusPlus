-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page. Few entries, so the sidebar stays short:
--   Forever++        the Modules page: every module (the only place modules turn on and off) in
--                    a list on the left,
--                    with a checkbox each, under a label per `module.category`. Clicking one shows
--                    it on the right: its title, category and description, its Enabled
--                    checkbox, its `notice` (a warning) while that applies, then its options
--                    (checkboxes, dropdowns and sliders) and buttons (from `module.actions`),
--                    greyed out while it's off. An option can sit under another (`requires`).
--                    `alwaysOn` modules (tools) aren't listed. A search box at the top narrows
--                    the list to modules by title and description. A module or option added
--                    since the player last looked (`added`) is marked NEW, and an option
--                    changed since then (`changed`) CHANGED
--     <Tool>         a page a module draws itself (`BuildPage`)
--     Debug          Show Tags and Forever++'s own buttons (Reset Seen Version, Copy Debug Info,
--                    Print Module Events, Reload UI), then options marked `debug = true` and
--                    buttons from `module.debugActions`, for testing
--     Changelog      the release notes from Changelog.lua
--     About          what the addon is, how many modules are on, the version, links, and the /fpp
--                    commands, with the Defaults button at the top right like Modules
-- Without subpages (an older Settings API), the Modules page is the only page.
local _, ns = ...

local ipairs, pairs, next, format, type, sort = ipairs, pairs, next, string.format, type, table.sort
local strlower = string.lower
local min, max, pcall = math.min, math.max, pcall
local InCombatLockdown, CreateFrame, GetBuildInfo = InCombatLockdown, CreateFrame, GetBuildInfo
local wipe = wipe
local C_AddOns, GetAddOnMetadata, GameTooltip = C_AddOns, GetAddOnMetadata, GameTooltip
local C_XMLUtil, C_Texture, C_Timer = C_XMLUtil, C_Texture, C_Timer
local L = ns.L

local settings = {} -- module name -> its Blizzard setting objects, to refresh after /fpp changes
local modulesCategory -- the Modules page, the top Forever++ entry, for /fpp
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
        ns.ApplyDeveloperDefaults, L.DEFAULTS_RECOMMENDED, ns.ApplyDefaults)
end

-- NEW labels ----------------------------------------------------------------------------------
-- A module added (`added`) after the version the player last saw the Modules page in gets
-- Blizzard's NEW label after its name, the one Blizzard's own new settings get. So does an option
-- added since then, unless its module is new itself, and an option changed (`changed`) since then
-- gets the same label reading CHANGED; the page opens on the first module with one, so the option
-- is seen. A version after this one isn't marked yet: what's
-- tagged for the next release shows once the TOC's version reaches it. Seeing the page saves this
-- version (ns.db.seenVersion); the labels stay while the player is on it and are gone once they
-- leave. Show Tags on the Debug page (ns.db.showTags: "new", "changed", or "both") marks everything
-- tagged that way after the last release in Changelog.lua instead, whatever was seen, and keeps it
-- marked, to check them.
local newRows = {} -- module name, or option table -> "new" or "changed" while it's marked
local newOrder -- the modules to mark, once trackNew has run
local seen -- true once the Modules page has been shown this session
local refreshAll -- redraws the Modules page, once it's built

-- Probe: NewFeatureLabelTemplate is Mainline's (LibUIDropDownMenu uses it on Forever).
local function canLabel()
    return hasTemplate("NewFeatureLabelTemplate")
end

-- The newest version in Changelog.lua with a date, so released.
local function lastRelease()
    for _, release in ipairs(ns.changelog or {}) do
        if release.date then
            return release.version
        end
    end
    return "0"
end

-- Whether Show Tags marks every `kind` ("new" or "changed") tag since the last release.
local function forced(kind)
    local tags = ns.db.showTags
    return tags == "both" or tags == kind
end

-- A version after the one last seen, and not after this one (still unreleased). With Show Tags
-- on for `kind`, any version after the last release.
local function since(version, kind)
    local Text = ns.Text
    if type(version) ~= "string" then
        return false
    end
    if forced(kind) then
        return Text.NewerVersion(version, lastRelease()) and true or false
    end
    return Text.NewerVersion(version, ns.db.seenVersion) and not Text.NewerVersion(version, ns.version)
        and true or false
end

local TAG_PADDING = 14 -- the room a label takes after its text, besides its own text

-- An update that keeps a NEW or CHANGED label just after `text`, a font string, while `key` (a
-- module's name, or one of its options) is marked: the text at most `room` wide, less the label's
-- room while it shows. The label is made the first time it's needed, so it can come and go with
-- Show Tags.
local function newMark(parent, text, room, key)
    local label, newText
    return function()
        local kind = newRows[key]
        if kind and not label and canLabel() then
            label = CreateFrame("Frame", nil, parent, "NewFeatureLabelTemplate")
            newText = label.Label and label.Label:GetText() -- Blizzard's own NEW, in the game's language
        end
        local tag = 0
        if kind and label and label.Label then
            local word = kind == "changed" and L.SETTINGS_CHANGED_TAG or newText
            label.Label:SetText(word)
            -- Inferred from Mainline: BGLabel is a copy of Label drawn behind it as a shadow.
            if label.BGLabel then
                label.BGLabel:SetText(word)
            end
            tag = ns.Text.Width(label.Label)
        elseif kind then
            tag = 26
        end
        text:SetWidth(min(ns.Text.Width(text) + 2, room - (kind and tag + TAG_PADDING or 0)))
        if label then
            -- The text's width, unless it's cut short, then half the label's text: the template
            -- centers its text on the frame.
            local width = min(ns.Text.Width(text), text:GetWidth())
            label:ClearAllPoints()
            label:SetPoint("CENTER", text, "LEFT", width + 6 + tag / 2, 0)
            label:SetShown(kind and true or false)
        end
    end
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
    elseif seen and next(newRows) and not ns.db.showTags then
        wipe(newRows)
        if refreshAll then
            refreshAll()
        end
    end
end

-- Marks what's new in `newOrder`'s modules, afresh.
local function markNew()
    wipe(newRows)
    for _, name in ipairs(newOrder or {}) do
        local module = ns.modules[name]
        if since(module.added, "new") then
            newRows[name] = "new" -- all of it is new, so its options aren't marked
        else
            for _, option in ipairs(module.options or {}) do
                if not option.debug then
                    if since(option.added, "new") then
                        newRows[option] = "new"
                    elseif since(option.changed, "changed") then
                        newRows[option] = "changed"
                    end
                end
            end
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

-- Show Tags: every module and option tagged NEW, CHANGED, or both since the last release marked
-- on the Modules page, and kept marked, to check how they look. Live: the marks are made again and
-- the page redrawn.
local SHOW_TAGS = {
    { "off", L.SETTINGS_SHOW_TAGS_OFF },
    { "new", L.SETTINGS_SHOW_TAGS_NEW },
    { "changed", L.SETTINGS_SHOW_TAGS_CHANGED },
    { "both", L.SETTINGS_SHOW_TAGS_BOTH },
}

local function addShowTags(category)
    if not (Settings.CreateDropdown and Settings.CreateControlTextContainer) then
        return -- Probe: dropdowns are Mainline's.
    end
    local setting = Settings.RegisterProxySetting(category, "ForeverPlusPlus_ShowTags",
        Settings.VarType.String, L.SETTINGS_SHOW_TAGS, "off",
        function() return ns.db.showTags or "off" end,
        function(value)
            change(function()
                ns.db.showTags = value ~= "off" and value or nil
                markNew()
                if refreshAll then
                    refreshAll()
                end
            end)
        end)
    Settings.CreateDropdown(category, setting, function()
        local container = Settings.CreateControlTextContainer()
        for _, choice in ipairs(SHOW_TAGS) do
            container:Add(choice[1], choice[2])
        end
        return container:GetData()
    end, L.SETTINGS_SHOW_TAGS_DESC)
end

-- A module's debug buttons (`module.debugActions`, the same shape as `actions`), after its
-- options. Greyed out while the module is off, unless the button is for that too (`whileOff`).
local function addDebugActions(layout, module)
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for i, action in ipairs(module.debugActions or {}) do
        local initializer = CreateSettingsButtonInitializer(action.name, action.button,
            actionFn(module, action, i), action.description, true)
        if not action.whileOff then
            greyWhenOff(initializer, module)
        end
        layout:AddInitializer(initializer)
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
-- A page we draw ourselves, built the first time it's shown: under the title, a search box and
-- our Defaults button; then a compact checklist of every module on the left, grouped under small
-- gold category labels, and the selected module on the right, each side scrolling on its own.
-- Our own frames from Blizzard's templates and art (the Settings panel's minimal checkboxes,
-- sliders and dropdowns, and its sidebar highlight), so nothing of Blizzard's pooled Settings
-- rows is touched. Every change goes through ns.SetEnabled and ns.SetOption, then
-- ns.RefreshSetting, which puts that module back to what's saved wherever it shows, so /fpp and
-- the page agree.

local LIST_LEFT, LIST_WIDTH, LIST_ROW = 7, 186, 20 -- the module list and its rows
local PANE_LEFT = 234 -- where the details start, right of the list and its scroll bar
local ROW_HEIGHT = 26 -- an option's row, as in Blizzard's lists
local INDENT = 15 -- an option under another (`requires`)
local CONTROL_LEFT = 150 -- where an option's control starts, after its name
local DESCRIPTION_LINES = 4 -- the room a description always takes, so the options stay put

local listed = {} -- the names of the modules on the page, by category, then title
local searchText = {} -- module name -> its title and description, lowercased
local filter, filterText -- the search text, lowercased and as typed, or nil while the box is empty
local selected -- the module shown on the right
local page -- the page's frames, once built
local bound = {} -- module name -> functions that put what shows of it back to what's saved
local refreshModule -- puts one module back to what's saved wherever it shows

local function matches(name)
    return not filter or (searchText[name] or ""):find(filter, 1, true) ~= nil
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

-- Moves `scroll` so `frame`, in its `content`, is at the top. After a frame, once the new layout's
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

-- One of the module's options, with `byKey` for the option it's under (`requires`) or the slider
-- in its row (`slider`), and `done` for those already drawn.
local function addOptionRow(view, module, option, byKey, done)
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
    local indent = parent and INDENT or 0
    local row, label = addRow(view, option.name, indent, on)
    local updates = view.updates
    -- The name wraps narrower while it's marked NEW, so the row's height follows it.
    local mark = newMark(row, label, CONTROL_LEFT - 8 - indent, option)
    updates[#updates + 1] = function()
        mark()
        row:SetHeight(max(ROW_HEIGHT, label:GetStringHeight() + 8))
    end
    local room = view:GetWidth() - CONTROL_LEFT
    local pair = option.slider and byKey[option.slider]
    if pair and pair.min then
        -- A checkbox and its slider in one row, the slider greyed while the checkbox is off.
        done[pair.key] = true
        local box = newCheckbox(row, 30, function(checked) setOption(module, option, checked) end)
        box:SetPoint("LEFT", CONTROL_LEFT, 0)
        local slider = newSlider(row, module, pair, min(200, room - 50) - 36)
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
        local slider = newSlider(row, module, option, min(200, room - 50))
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
        local dropdown = newDropdown(row, module, option, min(180, room - 16))
        if not dropdown then
            return
        end
        dropdown:SetPoint("LEFT", CONTROL_LEFT + 6, 0)
        updates[#updates + 1] = function()
            dropdown:GenerateMenu()
            dropdown:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, dropdown)
    else
        local box = newCheckbox(row, 30, function(checked) setOption(module, option, checked) end)
        box:SetPoint("LEFT", CONTROL_LEFT, 0)
        updates[#updates + 1] = function()
            box:SetChecked(module.db[option.key] and true or false)
            box:SetEnabled(on())
        end
        addTooltip(row, option.name, option.description, box)
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

-- A line of text across the view: the Options header, or "no options".
local function addLine(view, font, text)
    local row = CreateFrame("Frame", nil, view)
    row:SetSize(view:GetWidth(), font == "GameFontHighlightLarge" and 24 or ROW_HEIGHT)
    local line = row:CreateFontString(nil, "OVERLAY", font)
    line:SetPoint("LEFT", 4, 0)
    line:SetText(text)
    addEntry(view, row, nil, 16)
end

-- The module's rows, under its title, category and description: its notice, then its options and
-- buttons in the order it lists them, or a line saying it has none. Each change of `section`
-- starts a header with its name; options before the first section get an Options header.
local function addModuleRows(view, module)
    local name = module.name
    local function on()
        return module.db.enabled and true or false
    end
    -- A gray row while `shown()` is true, such as a Blizzard setting the module needs being off,
    -- with a button that fixes it. ns.CVars.OffNotice makes one for a CVar.
    local notice = module.notice
    if notice then
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
    local section
    if not (options[1] and options[1].section) then
        addLine(view, "GameFontHighlightLarge", L.SETTINGS_OPTIONS)
    end
    for _, option in ipairs(options) do
        if option.section and option.section ~= section then
            section = option.section
            addLine(view, "GameFontHighlightLarge", section)
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
    view.updates = {}

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

-- Shows `name` on the right (nil for none).
local function choose(name)
    selected = name
    for _, row in pairs(page.rows) do
        paint(row)
    end
    for other, view in pairs(page.views) do
        view:SetShown(other == name)
    end
    if not name then
        return
    end
    local view = page.views[name]
    if not view then
        view = buildView(name)
        page.views[name] = view
    end
    layoutStack(view)
    page.paneContent:SetHeight(view:GetHeight())
    page.pane:SetVerticalScroll(0)
end

-- A row of the list: the module's checkbox and its name, white while it's on and grey while it's
-- off, with a NEW label while it's new. Clicking it selects the module.
local function newListRow(name)
    local module = ns.modules[name]
    local row = CreateFrame("Button", nil, page.list)
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
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", box, "RIGHT", 2, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(module.title or name)
    local mark = newMark(row, text, LIST_WIDTH - 26, name)
    bind(name, function()
        text:SetFontObject(module.db.enabled and "GameFontHighlight" or "GameFontDisable")
        mark()
    end)
    row:SetScript("OnClick", function()
        if selected ~= name then
            choose(name)
        end
    end)
    row:SetScript("OnEnter", function() hover(true) end)
    row:SetScript("OnLeave", function() hover(false) end)
    return row
end

-- Lays out the modules the search shows, keeps the selection on one of them (the first, when it
-- hides the selected one), and lays out the selected module's rows.
local function relayout()
    if not page then
        return
    end
    page.empty.text:SetText(format(L.SETTINGS_NO_MATCH, filterText or ""))
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

-- A search box at the top of the page, left of the Defaults button, that narrows the list to the
-- modules whose title or description has the text. Blizzard's own search, at the top left of the
-- panel, finds settings across every addon, not modules. Probe: SearchBoxTemplate is Mainline's.
local function addSearchBox(frame, anchor)
    if not hasTemplate("SearchBoxTemplate") then
        return
    end
    local box = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    box:SetSize(200, 20)
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
        relayout()
    end)
    return box
end

local function buildModules(frame)
    ns.AddPageTitle(frame, L.MODULES)
    local width = frame:GetWidth()
    page = { rows = {}, views = {}, width = width > 0 and width or 615 }

    local defaults = newButton(frame, SETTINGS_DEFAULTS or L.HOME_DEFAULTS, 96, askDefaults)
    defaults:SetPoint("TOPRIGHT", -10, -18)
    page.search = addSearchBox(frame, defaults)

    local list = newScroll(frame)
    list:SetPoint("TOPLEFT", LIST_LEFT, -60)
    list:SetPoint("BOTTOMLEFT", LIST_LEFT, 8)
    list:SetWidth(LIST_WIDTH)
    page.listScroll = list
    page.list = newStack(list, LIST_WIDTH, 2)
    page.list.bottom = 8
    list:SetScrollChild(page.list)

    -- "No modules match" while the search hides them all.
    local empty = CreateFrame("Frame", nil, page.list)
    empty:SetSize(LIST_WIDTH, 40)
    empty.text = empty:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty.text:SetPoint("TOPLEFT", 2, -4)
    empty.text:SetWidth(LIST_WIDTH - 4)
    empty.text:SetJustifyH("LEFT")
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

    -- A faint gold line between the list and the details.
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.25)
    line:SetWidth(1)
    line:SetPoint("TOPLEFT", PANE_LEFT - 12, -66)
    line:SetPoint("BOTTOMLEFT", PANE_LEFT - 12, 14)

    local pane = newScroll(frame)
    pane:SetPoint("TOPLEFT", PANE_LEFT, -60)
    pane:SetPoint("BOTTOMRIGHT", -32, 8)
    page.pane, page.paneWidth = pane, page.width - PANE_LEFT - 32
    page.paneContent = CreateFrame("Frame", nil, pane)
    page.paneContent:SetWidth(page.paneWidth)
    pane:SetScrollChild(page.paneContent)

    -- Opens on the module ns.OpenSettings asked for, or the first with a new option to see, or
    -- else the first.
    if not selected then
        for _, name in ipairs(listed) do
            if hasNewOption(ns.modules[name]) then
                selected = name
                break
            end
        end
    end
    if selected then
        choose(selected)
        scrollTo(list, page.list, page.rows[selected])
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
    local defaults = newButton(frame, SETTINGS_DEFAULTS or L.HOME_DEFAULTS, 96, askDefaults)
    defaults:SetPoint("TOPRIGHT", -10, -18) -- where the Modules page has it

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
    -- With `bullet`, a dash before it and the text's wrapped lines lined up after the dash, so
    -- each entry's start stands out.
    local function add(font, text, indent, gap, bullet)
        y = y - (gap or 0)
        indent = indent or 0
        if bullet then
            local dash = content:CreateFontString(nil, "OVERLAY", font)
            dash:SetPoint("TOPLEFT", indent, y)
            dash:SetText("-")
            indent = indent + 10
        end
        local line = content:CreateFontString(nil, "OVERLAY", font)
        line:SetPoint("TOPLEFT", indent, y)
        line:SetWidth(width - indent)
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
                add("GameFontHighlightSmall", text, 8, 6, true)
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

-- Debug page tools ----------------------------------------------------------------------------
-- Forever++'s own buttons on the Debug page, under Show Tags.

-- Puts the version last seen back to the last release, so the Modules page marks what a player
-- updating from it would see, and opens it the way it would open for them: on the first module
-- with a marked option. The marks go once the page is left, as they do after an update.
local function resetSeen()
    ns.db.seenVersion = lastRelease()
    seen = false
    markNew()
    if page then
        selected = nil
        for _, name in ipairs(listed) do
            if hasNewOption(ns.modules[name]) then
                selected = name
                break
            end
        end
        if refreshAll then
            refreshAll()
        end
        if selected then
            choose(selected)
            scrollTo(page.listScroll, page.list, page.rows[selected])
        end
    end
    open(modulesCategory)
end

-- One line for a bug report: the addon and client, and the modules on.
local function debugInfo()
    local gameVersion, build, _, interface = GetBuildInfo()
    local on = {}
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if module.enabled and not module.alwaysOn then
            on[#on + 1] = name
        end
    end
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
        description = L.DEBUG_RESET_SEEN_DESC, fn = resetSeen },
    { name = L.DEBUG_INFO, button = L.DEBUG_INFO_BUTTON, description = L.DEBUG_INFO_DESC,
        fn = function() ns.Prompt("DEBUG_INFO", L.DEBUG_INFO_PROMPT, debugInfo()) end },
    { name = L.DEBUG_EVENTS, button = L.DEBUG_EVENTS_BUTTON, description = L.DEBUG_EVENTS_DESC,
        fn = printEvents },
    { name = L.DEBUG_RELOAD, button = L.DEBUG_RELOAD_BUTTON, description = L.DEBUG_RELOAD_DESC,
        fn = function() ReloadUI() end },
}

local function addDebugTools(layout)
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for _, tool in ipairs(DEBUG_TOOLS) do
        layout:AddInitializer(CreateSettingsButtonInitializer(tool.name, tool.button, tool.fn,
            tool.description, true))
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
            searchText[name] = strlower(format("%s\n%s", module.title or name,
                module.description or ""))
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
    -- Debug options: Forever++'s own first, then each module's.
    local debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.DEBUG)
    addHeader(debugLayout, ns.title)
    addShowTags(debugPage)
    addDebugTools(debugLayout)
    for _, name in ipairs(order) do
        local module = ns.modules[name]
        if hasOptions(module, true) or module.debugActions then
            addHeader(debugLayout, module.title or name)
            addDebugOptions(debugPage, debugLayout, module)
            addDebugActions(debugLayout, module)
        end
    end
    addCanvasPage(category, L.CHANGELOG, buildChangelog)
    addCanvasPage(category, L.ABOUT, buildAbout)
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
            choose(name)
            scrollTo(page.listScroll, page.list, page.rows[name])
        else
            selected = name -- the page opens on it
        end
    end
    return open(modulesCategory)
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
