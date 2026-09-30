-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page. Few entries, so the sidebar stays short:
--   Forever++        a welcome page: what the addon is, how many modules are on, buttons to the
--                    Modules and Changelog pages, the version, links, and the /fpp commands
--     Modules        an on/off checkbox per module (the only place modules turn on and off),
--                    grouped under headers by `module.category`. A module's options (checkboxes,
--                    dropdowns and sliders) and buttons (from `module.actions`) sit indented under
--                    its checkbox, hidden until its gear is clicked, and greyed out while it's
--                    off. An option can sit under another (`requires`). The indent groups them, so
--                    their `section`s get no header here. A module's `notice` (a warning) shows under its
--                    checkbox while it applies. `alwaysOn` modules (tools) have no checkbox
--     <Tool>         a page a module draws itself (`BuildPage`)
--     Debug          options marked `debug = true`, for testing
--     Changelog      the release notes from Changelog.lua
-- Without subpages (an older Settings API), everything goes on one page with every option shown.
local _, ns = ...

local ipairs, format, type, sort, strlower = ipairs, string.format, type, table.sort, string.lower
local InCombatLockdown, CreateFrame, GetBuildInfo = InCombatLockdown, CreateFrame, GetBuildInfo
local setmetatable, hooksecurefunc = setmetatable, hooksecurefunc
local C_AddOns, GetAddOnMetadata, GameTooltip = C_AddOns, GetAddOnMetadata, GameTooltip
local C_XMLUtil = C_XMLUtil
local L = ns.L

local settings = {} -- module name -> its Blizzard setting objects, to refresh after /fpp changes
local mainCategory -- the Forever++ page, for /fpp
local modulesCategory -- the Modules page
local changelogCategory -- the Changelog page, for the welcome page's button
local pages = {} -- module name -> the page it draws itself, for ns.OpenSettings(name)
local inline = {} -- module name -> true when its options sit under its checkbox on the Modules page
local expanded = {} -- module name -> true while those options are shown (this session only)
local nested = {} -- module name -> true when an option sits under another (`requires`)

-- Redraws the open Settings list, so rows shown or hidden by `expanded` appear or go. Probe:
-- SettingsInbound.RepairDisplay is Mainline's; ArcaneWizardLibrary uses it on Forever.
local function canRedraw()
    return SettingsInbound and SettingsInbound.RepairDisplay and true or false
end

-- Opens a Forever++ page (after combat, if the player is in combat).
local function open(category)
    if not (category and Settings.OpenToCategory and category.GetID) then
        return false
    end
    if InCombatLockdown() then
        ns.Print(L.SETTINGS_AFTER_COMBAT)
    end
    ns.AfterCombat(function()
        Settings.OpenToCategory(category:GetID())
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

local function track(module, setting)
    local list = settings[module.name] or {}
    settings[module.name] = list
    list[#list + 1] = setting
end

-- Gear icons beside the Modules page's checkboxes, for modules with options: a click shows or
-- hides them (or opens the module's own page, for one that draws it). The list's row frames are
-- Blizzard's and pooled across every Settings page, so the gear is our own child button kept in a
-- weak table, shown only while one of our rows uses the frame.
local gears = setmetatable({}, { __mode = "k" }) -- row frame -> our gear button
local GEAR = "Interface\\WorldMap\\Gear_64" -- the cog Leatrix Maps uses for its option buttons

-- Gold while the options are hidden, white while they show, like a pressed button.
local function tintGear(gear)
    local texture = gear:GetNormalTexture()
    if expanded[gear.module] then
        texture:SetVertexColor(1, 1, 1)
    else
        texture:SetVertexColor(1, 0.82, 0) -- gold, like the labels
    end
end

local function gearTooltip(gear)
    local text = L.SETTINGS_OPEN_PAGE
    if inline[gear.module] then
        text = expanded[gear.module] and L.SETTINGS_HIDE_OPTIONS or L.SETTINGS_SHOW_OPTIONS
    end
    GameTooltip:SetOwner(gear, "ANCHOR_RIGHT")
    GameTooltip:SetText(format(text, gear.title), 1, 1, 1)
    GameTooltip:Show()
end

local function gearFor(frame, anchor)
    local gear = gears[frame]
    if not gear then
        gear = CreateFrame("Button", nil, frame)
        gear:SetSize(18, 18)
        gear:SetNormalTexture(GEAR)
        gear:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
        gear:SetHighlightTexture(GEAR, "ADD")
        gear:GetHighlightTexture():SetTexCoord(0, 0.5, 0, 0.5)
        gear:SetScript("OnClick", function(self)
            if not inline[self.module] then
                ns.OpenSettings(self.module)
                return
            end
            expanded[self.module] = not expanded[self.module] or nil
            tintGear(self)
            gearTooltip(self)
            SettingsInbound.RepairDisplay()
        end)
        gear:SetScript("OnEnter", gearTooltip)
        gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- The frame goes back to the pool hidden; another page's row may get it next.
        frame:HookScript("OnHide", function() gear:Hide() end)
        gears[frame] = gear
    end
    gear:ClearAllPoints()
    gear:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
    return gear
end

-- Puts a gear beside the checkbox each time Blizzard sets a row up for this initializer.
local function addGear(initializer, module)
    if not initializer.InitFrame then
        return -- Probe: rows are set up through InitFrame on Mainline's Settings list.
    end
    hooksecurefunc(initializer, "InitFrame", function(_, frame)
        local anchor = frame.Checkbox or frame.CheckBox
        if not anchor then
            return
        end
        local gear = gearFor(frame, anchor)
        gear.module, gear.title = module.name, module.title or module.name
        tintGear(gear)
        gear:Show()
    end)
end

-- The module's on/off checkbox on the Modules page. It reads and writes through the module, so
-- /fpp and the page agree. A gear beside it shows its options, or opens its own page.
local function addToggle(category, module, hasGear)
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s", module.name), Settings.VarType.Boolean,
        module.title or module.name, module.defaults.enabled,
        function() return module.db.enabled end,
        function(value)
            ns.SetEnabled(module.name, value)
            -- A row under one of its options only rechecks that option, not the module: redraw.
            if nested[module.name] and canRedraw() then
                SettingsInbound.RepairDisplay()
            end
        end)
    track(module, setting)
    local initializer = Settings.CreateCheckbox(category, setting, module.description)
    if hasGear and initializer then
        addGear(initializer, module)
    end
    return initializer
end

-- Greys a row out while the module is off, so it shows nothing on it applies. Probe:
-- AddModifyPredicate is Mainline's; ManiaTip uses it on Forever.
local function greyWhenOff(initializer, module)
    if initializer and initializer.AddModifyPredicate then
        initializer:AddModifyPredicate(function() return module.db.enabled end)
    end
end

-- Hides a row unless `shown()` is true. Probe: AddShownPredicate is Mainline's; ManiaTip uses it
-- on Forever.
local function showWhen(initializer, shown)
    if shown and initializer and initializer.AddShownPredicate then
        initializer:AddShownPredicate(shown)
    end
end

-- Indents a row under the module's checkbox (`parent`), greyed out while the module is off, or
-- just greys it without one (the Debug page).
local function placeUnder(initializer, module, parent)
    if parent and initializer and initializer.SetParentInitializer then
        initializer:SetParentInitializer(parent, function() return module.db.enabled end)
    else
        greyWhenOff(initializer, module)
    end
end

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
            ns.SetOption(module.name, option.key, value)
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

-- A module's own option (from `module.options`): a checkbox, a dropdown when it lists `choices`,
-- or a slider when it has `min` and `max` (in one row with the checkbox that names it as its
-- `slider`, where it can), under the module's checkbox (or under the checkbox option named by
-- `requires`, greyed out while that is off), and only while `shown()` is true. `added` maps the
-- module's option keys to their rows, for `requires`.
local function addOption(category, layout, module, option, parent, shown, added)
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
        nested[module.name] = true
    else
        placeUnder(initializer, module, parent)
    end
    showWhen(initializer, shown)
    added[option.key] = initializer
end

local function addHeader(layout, text, shown)
    if layout and CreateSettingsListSectionHeaderInitializer then
        local initializer = CreateSettingsListSectionHeaderInitializer(text)
        showWhen(initializer, shown)
        layout:AddInitializer(initializer)
    end
end

local function hasOptions(module, debug)
    for _, option in ipairs(module.options or {}) do
        if (option.debug or false) == debug then
            return true
        end
    end
    return false
end

-- A module's options, in the order it lists them. On the Debug page (no `parent`), an option whose
-- `section` differs from the one before it starts a section header. Under a module's checkbox on
-- the Modules page, sections get no header: a full one sits at the page's left edge in the size of
-- the category headers, and a bare Blizzard row as a label (SettingsListElementTemplate through
-- Settings.CreateElementInitializer) stopped the page drawing on Forever.
local function addOptions(category, layout, module, parent, debug, shown)
    local section
    local added = {}
    for _, option in ipairs(module.options or {}) do
        if (option.debug or false) == debug then
            if option.section and option.section ~= section and not parent then
                addHeader(layout, option.section, shown)
            end
            section = option.section
            addOption(category, layout, module, option, parent, shown, added)
        end
    end
end

-- A module's buttons (from `module.actions`: `{ name, button, description, fn }`, and `confirm`, a
-- question to ask before `fn` runs, with `key` naming its popup), after its options.
local function addActions(layout, module, parent, shown, actions)
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for i, action in ipairs(actions or module.actions or {}) do
        local fn = action.fn
        if action.confirm then
            -- Asks first (ns.Confirm), in a popup named by `key`, so a command can ask the same one.
            local key = action.key or format("%s_ACTION%d", module.name:upper(), i)
            fn = function()
                ns.Confirm(key, action.confirm, action.fn)
            end
        end
        local initializer = CreateSettingsButtonInitializer(action.name, action.button,
            fn, action.description, true)
        placeUnder(initializer, module, parent)
        showWhen(initializer, shown)
        layout:AddInitializer(initializer)
    end
end

-- A module's `notice` ({ text, description, button, fn, shown }): a gray row under its checkbox
-- while `shown()` is true, such as a Blizzard setting the module needs being off, with a button
-- that fixes it. A normal settings row, so it's the size of the options around it. It shows
-- whether or not the module's options do. ns.CVars.OffNotice makes one for a CVar.
local function addNotice(layout, module, parent)
    local notice = module.notice
    if not (notice and layout and CreateSettingsButtonInitializer) then
        return
    end
    local initializer = CreateSettingsButtonInitializer(format("|cff999999%s|r", notice.text),
        notice.button, notice.fn, notice.description, true)
    if parent and initializer.SetParentInitializer then
        initializer:SetParentInitializer(parent)
    end
    if initializer.AddShownPredicate then
        initializer:AddShownPredicate(notice.shown)
        layout:AddInitializer(initializer)
    end
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
    if changelogCategory then
        local changelog = addButton(frame, L.CHANGELOG, changelogCategory)
        changelog:SetPoint("LEFT", modules, "RIGHT", 8, 0)
    end

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

    local gameVersion, build, _, interface = GetBuildInfo()
    local game = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    game:SetPoint("BOTTOMLEFT", 16, 12)
    game:SetText(format(L.HOME_GAME_BUILD, gameVersion, build, interface))
end

-- Changelog page ------------------------------------------------------------------------------
-- The release notes from Changelog.lua, newest first, in a scrolling list. Built the first time
-- it's shown.

local SCROLL_TEMPLATE = "ScrollFrameTemplate" -- Mainline's, with the thin scroll bar

local function buildChangelog(frame)
    ns.AddPageTitle(frame, L.CHANGELOG)

    -- Probe: fall back to the older template if Mainline's isn't on this client.
    local template = SCROLL_TEMPLATE
    if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(template)) then
        template = "UIPanelScrollFrameTemplate"
    end
    local scroll = CreateFrame("ScrollFrame", nil, frame, template)
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

-- Module names in the order their titles sort in the player's language, so the toggles and pages
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

-- The Modules page's groups, in order: a module's `category` and its header. A module without one
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

-- The Modules page: each category's modules under its header, each module's options under its
-- checkbox. With `collapse`, those options show only while the module's gear has them open.
local function addModules(category, layout, grouped, collapse)
    local current
    for _, name in ipairs(grouped) do
        local module = ns.modules[name]
        if not module.alwaysOn then
            local group = categoryOf(module)
            if group ~= current then
                current = group
                addHeader(layout, CATEGORY_NAMES[group])
            end
            inline[name] = not module.BuildPage
                and (hasOptions(module, false) or module.actions) and true or nil
            local hasGear = module.BuildPage and pages[name] or (collapse and inline[name])
            local parent = addToggle(category, module, hasGear)
            addNotice(layout, module, parent)
            if inline[name] then
                local shown = collapse and function() return expanded[name] end or nil
                addOptions(category, layout, module, parent, false, shown)
                addActions(layout, module, parent, shown)
            end
        end
    end
end

---Adds the Forever++ pages to Settings > AddOns (called once, after ns.Start).
function ns.RegisterSettings()
    -- Probe: the Mainline Settings API is on Forever (build 70009), but it's a beta.
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local subpages = Settings.RegisterVerticalLayoutSubcategory ~= nil
        and Settings.RegisterCanvasLayoutSubcategory ~= nil
        and Settings.RegisterCanvasLayoutCategory ~= nil
    local order = byTitle()
    -- Modules by category, then title: the order of the Modules page and of the tool pages.
    local grouped = {}
    for _, group in ipairs(CATEGORIES) do
        for _, name in ipairs(order) do
            if categoryOf(ns.modules[name]) == group[1] then
                grouped[#grouped + 1] = name
            end
        end
    end

    -- Without subpages, one page holds every module with its options always shown.
    if not subpages then
        local category, layout = Settings.RegisterVerticalLayoutCategory(ns.title)
        addModules(category, layout, grouped, false)
        Settings.RegisterAddOnCategory(category)
        mainCategory, modulesCategory = category, category
        return
    end

    local category = Settings.RegisterCanvasLayoutCategory(canvasFrame(buildWelcome), ns.title)
    local modulesPage, modulesLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.MODULES)
    modulesCategory = modulesPage
    -- Pages modules draw themselves (tools such as Console Variables), before the Modules page is
    -- filled so their gears can open them.
    for _, name in ipairs(grouped) do
        local module = ns.modules[name]
        if module.BuildPage then
            pages[name] = addCanvasPage(category, module.title or name, function(frame)
                module:BuildPage(frame)
            end)
        end
    end
    addModules(modulesPage, modulesLayout, grouped, canRedraw())
    -- Debug options, grouped by module.
    local debugPage, debugLayout
    for _, name in ipairs(order) do
        local module = ns.modules[name]
        if hasOptions(module, true) or module.debugActions then
            if not debugPage then
                debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.DEBUG)
            end
            addHeader(debugLayout, module.title or name)
            addOptions(debugPage, debugLayout, module, nil, true)
            -- Buttons (`module.debugActions`, the same shape as `actions`) after the options.
            addActions(debugLayout, module, nil, nil, module.debugActions)
        end
    end
    changelogCategory = addCanvasPage(category, L.CHANGELOG, buildChangelog)
    Settings.RegisterAddOnCategory(category)
    mainCategory = category
end

---Opens the Forever++ welcome page in Settings, or a module's options: its own page, or the
---Modules page with its options shown (after combat, if the player is in combat).
---@param name? string a module
---@return boolean opened false when this client's Settings can't open to it
function ns.OpenSettings(name)
    if name and pages[name] then
        return open(pages[name])
    end
    if name and ns.modules[name] then
        if inline[name] and not expanded[name] then
            expanded[name] = true
            -- Already open on the Modules page: show them now.
            if canRedraw() and SettingsPanel and SettingsPanel:IsShown() then
                SettingsInbound.RepairDisplay()
            end
        end
        return open(modulesCategory)
    end
    return open(mainCategory)
end

---Updates a module's checkboxes and dropdowns after it changed somewhere else (/fpp toggle, set).
---@param name string
function ns.RefreshSetting(name)
    if not Settings or not Settings.NotifyUpdate then
        return
    end
    for _, setting in ipairs(settings[name] or {}) do
        Settings.NotifyUpdate(setting:GetVariable())
    end
end
