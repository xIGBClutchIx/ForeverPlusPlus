-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page:
--   Forever++        an on/off checkbox per module (the only place modules turn on and off),
--                    grouped under headers by `module.category`, with a gear that opens its page
--                    when it has one. `alwaysOn` modules (tools) have none
--     <Module>       one page per module with options, holding just its options (and buttons,
--                    from `module.actions`), in the main page's order, greyed out with a note at
--                    the top while the module is off, and its `notice` (a warning) while that
--                    applies (on the main page, under its checkbox, for a module with no page).
--                    Options with a `section` get a header above each group, for pages long
--                    enough to need them
--     <Tool>         a page a module draws itself (`BuildPage`), after the option pages
--     Debug          options marked `debug = true`, for testing
--     Changelog      the release notes from Changelog.lua
--     About          the version, links, and /fpp commands
-- Without subpages (an older Settings API), everything goes on the main page instead.
local _, ns = ...

local ipairs, format, type, sort, strlower = ipairs, string.format, type, table.sort, string.lower
local InCombatLockdown, CreateFrame, GetBuildInfo = InCombatLockdown, CreateFrame, GetBuildInfo
local setmetatable, hooksecurefunc = setmetatable, hooksecurefunc
local C_AddOns, GetAddOnMetadata, GameTooltip = C_AddOns, GetAddOnMetadata, GameTooltip
local C_XMLUtil = C_XMLUtil
local L = ns.L

local settings = {} -- module name -> its Blizzard setting objects, to refresh after /fpp changes
local mainCategory -- the Forever++ page, for /fpp
local pages = {} -- module name -> its own page, for ns.OpenSettings(name)

-- A page drawn by `build(frame)` instead of from settings, such as a list. Settings needs the
-- frame now, so it starts empty and is filled the first time it's shown.
local function addCanvasPage(category, name, build)
    local frame = CreateFrame("Frame")
    local built = false
    frame:SetScript("OnShow", function(self)
        if not built then
            built = true
            build(self)
        end
    end)
    return Settings.RegisterCanvasLayoutSubcategory(category, frame, name)
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

-- Gear icons beside the main page's checkboxes, for modules with a page. The list's row frames
-- are Blizzard's and pooled across every Settings page, so the gear is our own child button kept
-- in a weak table, shown only while one of our rows uses the frame.
local gears = setmetatable({}, { __mode = "k" }) -- row frame -> our gear button
local GEAR = "Interface\\WorldMap\\Gear_64" -- the cog Leatrix Maps uses for its option buttons

local function gearFor(frame, anchor)
    local gear = gears[frame]
    if not gear then
        gear = CreateFrame("Button", nil, frame)
        gear:SetSize(18, 18)
        gear:SetNormalTexture(GEAR)
        gear:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
        gear:GetNormalTexture():SetVertexColor(1, 0.82, 0) -- gold, like the labels
        gear:SetHighlightTexture(GEAR, "ADD")
        gear:GetHighlightTexture():SetTexCoord(0, 0.5, 0, 0.5)
        gear:SetScript("OnClick", function(self) ns.OpenSettings(self.module) end)
        gear:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(format(L.SETTINGS_OPEN_PAGE, self.title), 1, 1, 1)
            GameTooltip:Show()
        end)
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
        gear:Show()
    end)
end

-- The module's on/off checkbox on the main page. It reads and writes through the module, so
-- /fpp and the page agree. With a page of its own, a gear beside it opens that page.
local function addToggle(category, module, hasPage)
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s", module.name), Settings.VarType.Boolean,
        module.title or module.name, module.defaults.enabled,
        function() return module.db.enabled end,
        function(value) ns.SetEnabled(module.name, value) end)
    track(module, setting)
    local initializer = Settings.CreateCheckbox(category, setting, module.description)
    if hasPage and initializer then
        addGear(initializer, module)
    end
    return initializer
end

-- Greys a row out while the module is off, so its page shows nothing on it applies. Probe:
-- AddModifyPredicate is Mainline's; ManiaTip uses it on Forever.
local function greyWhenOff(initializer, module)
    if initializer and initializer.AddModifyPredicate then
        initializer:AddModifyPredicate(function() return module.db.enabled end)
    end
end

-- A module's own option (from `module.options`): a checkbox, or a dropdown when it lists
-- `choices`. With a `parent` (the main page, without subpages), it's indented under it; either
-- way it's greyed out while the module is off.
local function addOption(category, module, option, parent)
    local choices = option.choices
    if choices and not (Settings.CreateDropdown and Settings.CreateControlTextContainer) then
        return -- Probe: dropdowns are Mainline's; leave the option at its default without one.
    end
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s_%s", module.name, option.key),
        choices and Settings.VarType.String or Settings.VarType.Boolean,
        option.name, module.defaults[option.key],
        function() return module.db[option.key] end,
        function(value) ns.SetOption(module.name, option.key, value) end)
    track(module, setting)
    local initializer
    if choices then
        initializer = Settings.CreateDropdown(category, setting, function()
            local container = Settings.CreateControlTextContainer()
            for _, choice in ipairs(choices) do
                container:Add(choice[1], choice[2])
            end
            return container:GetData()
        end, option.description)
    else
        initializer = Settings.CreateCheckbox(category, setting, option.description)
    end
    if parent and initializer and initializer.SetParentInitializer then
        initializer:SetParentInitializer(parent, function() return module.db.enabled end)
    else
        greyWhenOff(initializer, module)
    end
end

local function addHeader(layout, text)
    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
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

-- A module's options, in the order it lists them. With a layout (the module's own page), an
-- option whose `section` differs from the one before it starts a new section header there.
local function addOptions(category, module, parent, debug, layout)
    local section
    for _, option in ipairs(module.options or {}) do
        if (option.debug or false) == debug then
            if option.section and option.section ~= section then
                addHeader(layout, option.section)
            end
            section = option.section
            addOption(category, module, option, parent)
        end
    end
end

-- A module's buttons (from `module.actions`: `{ name, button, description, fn }`), after its
-- options.
local function addActions(layout, module)
    if not (layout and CreateSettingsButtonInitializer) then
        return -- Probe: the button row is Mainline's Settings.
    end
    for _, action in ipairs(module.actions or {}) do
        local initializer = CreateSettingsButtonInitializer(action.name, action.button,
            action.fn, action.description, true)
        greyWhenOff(initializer, module)
        layout:AddInitializer(initializer)
    end
end

-- The top of a module's page, only while it's off: says the page's options don't apply, and
-- where to turn it on. Probe: AddShownPredicate is Mainline's; ManiaTip uses it on Forever.
local function addOffNotice(layout, module)
    if not (layout and CreateSettingsListSectionHeaderInitializer) then
        return
    end
    local initializer = CreateSettingsListSectionHeaderInitializer(L.SETTINGS_MODULE_OFF)
    if initializer.AddShownPredicate then
        initializer:AddShownPredicate(function() return not module.db.enabled end)
        layout:AddInitializer(initializer)
    end
end

-- A module's `notice` ({ text, description, button, fn, shown }): a gray row at the top of its
-- page while `shown()` is true, such as a Blizzard setting the module needs being off, with a
-- button that fixes it. A normal settings row, so it's the size of the options below it. A module
-- without a page gets it on the main page instead, indented under its checkbox (`parent`).
-- ns.CVars.OffNotice makes one for a CVar.
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

-- About page ----------------------------------------------------------------------------------
-- The version and who made it, the game build, links, and the /fpp commands. Built the first time
-- it's shown.

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

-- A gold label with a value beside it, the way Blizzard's own info pages look.
local function addRow(frame, y, label, value)
    local left = addLabel(frame, y, label)
    local right = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    right:SetPoint("LEFT", left, "RIGHT", 8, 0)
    right:SetText(value)
    return right
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
        GameTooltip:SetText(L.ABOUT_COPY, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function addHeading(frame, y, text)
    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    heading:SetPoint("TOPLEFT", 16, y)
    heading:SetText(text)
end

local function buildAbout(frame)
    ns.AddPageTitle(frame, ns.title)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("TOPRIGHT", -16, -64)
    icon:SetTexture(ns.icon)

    local tagline = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", 16, -64)
    tagline:SetText(metadata("Notes") ~= "" and metadata("Notes") or L.ABOUT_TAGLINE)

    local version, build, _, interface = GetBuildInfo()
    local y = -92
    addRow(frame, y, L.ABOUT_VERSION, metadata("Version"))
    y = y - 20
    addRow(frame, y, L.ABOUT_AUTHOR, metadata("Author"))
    y = y - 20
    addRow(frame, y, L.ABOUT_GAME, format(L.ABOUT_GAME_BUILD, version, build, interface))
    y = y - 26
    addLink(frame, y, L.ABOUT_WEBSITE, WEBSITE)
    y = y - 24
    addLink(frame, y, L.ABOUT_ISSUES, ISSUES)
    y = y - 22
    local requests = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    requests:SetPoint("TOPLEFT", 16, y)
    requests:SetText(L.ABOUT_REQUESTS)

    y = y - 30
    addHeading(frame, y, L.ABOUT_COMMANDS)
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
        add("GameFontHighlightLarge", format(L.CHANGELOG_RELEASE, release.version, release.date),
            0, i > 1 and 24 or 0)
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

-- The main page's groups, in order: a module's `category` and its header. A module without one
-- goes under Other.
local CATEGORIES = {
    { "automation", L.CATEGORY_AUTOMATION },
    { "items", L.CATEGORY_ITEMS },
    { "interface", L.CATEGORY_INTERFACE },
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

---Adds the Forever++ pages to Settings > AddOns (called once, after ns.Start).
function ns.RegisterSettings()
    -- Probe: the Mainline Settings API is on Forever (build 70009), but it's a beta.
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.title)
    local subpages = Settings.RegisterVerticalLayoutSubcategory ~= nil
    local order = byTitle()
    -- Modules by category, then title: the order of the main page and of the option pages, so
    -- each page sits beside the others in its group.
    local grouped = {}
    for _, group in ipairs(CATEGORIES) do
        for _, name in ipairs(order) do
            if categoryOf(ns.modules[name]) == group[1] then
                grouped[#grouped + 1] = name
            end
        end
    end
    local canvas = subpages and Settings.RegisterCanvasLayoutSubcategory
    local function hasPage(module)
        if module.BuildPage then
            return canvas and true or false
        end
        return subpages and (hasOptions(module, false) or module.actions) and true or false
    end
    -- The main page: each category's modules under its header. Without subpages, a module's
    -- options follow its checkbox.
    local current
    for _, name in ipairs(grouped) do
        local module = ns.modules[name]
        if not module.alwaysOn then
            local group = categoryOf(module)
            if group ~= current then
                current = group
                addHeader(layout, CATEGORY_NAMES[group])
            end
            local parent = addToggle(category, module, hasPage(module))
            if not (subpages and hasPage(module) and not module.BuildPage) then
                addNotice(layout, module, parent)
            end
            if not subpages then
                addOptions(category, module, parent, false)
                addActions(layout, module)
            end
        end
    end
    -- A page per module with options.
    if subpages then
        for _, name in ipairs(grouped) do
            local module = ns.modules[name]
            if not module.BuildPage and hasPage(module) then
                local page, pageLayout = Settings.RegisterVerticalLayoutSubcategory(category,
                    module.title or name)
                pages[name] = page
                addOffNotice(pageLayout, module)
                addNotice(pageLayout, module)
                addOptions(page, module, nil, false, pageLayout)
                addActions(pageLayout, module)
            end
        end
    end
    -- Pages modules draw themselves (tools such as Console Variables) go last, above Debug.
    if canvas then
        for _, name in ipairs(grouped) do
            local module = ns.modules[name]
            if module.BuildPage then
                pages[name] = addCanvasPage(category, module.title or name, function(frame)
                    module:BuildPage(frame)
                end)
            end
        end
    end
    -- Debug options, grouped by module.
    local debugPage, debugLayout = category, layout
    for _, name in ipairs(order) do
        local module = ns.modules[name]
        if hasOptions(module, true) then
            if debugPage == category and subpages then
                debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.DEBUG)
            end
            addHeader(debugLayout, module.title or name)
            addOptions(debugPage, module, nil, true)
        end
    end
    if canvas then
        addCanvasPage(category, L.CHANGELOG, buildChangelog)
        addCanvasPage(category, L.ABOUT, buildAbout)
    end
    Settings.RegisterAddOnCategory(category)
    mainCategory = category
end

---Opens the Forever++ page in Settings, or a module's own page (after combat, if the player is in
---combat).
---@param name? string a module with its own page
---@return boolean opened false when this client's Settings can't open to it
function ns.OpenSettings(name)
    local category = name and pages[name] or mainCategory
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
