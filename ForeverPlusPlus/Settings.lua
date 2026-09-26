-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page:
--   Forever++        an on/off checkbox per module (the only place modules turn on and off)
--     <Module>       one page per module with options, holding just its options (and buttons,
--                    from `module.actions`)
--     <Tool>         a page a module draws itself (`BuildPage`), after the option pages
--     Debug          options marked `debug = true`, for testing
-- Without subpages (an older Settings API), everything goes on the main page instead.
local _, ns = ...

local ipairs, format = ipairs, string.format

local pairs = pairs
local InCombatLockdown, CreateFrame, GetBuildInfo = InCombatLockdown, CreateFrame, GetBuildInfo
local C_AddOns, GetAddOnMetadata, GameTooltip = C_AddOns, GetAddOnMetadata, GameTooltip
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

-- The module's on/off checkbox on the main page. It reads and writes through the module, so
-- /fpp and the page agree.
local function addToggle(category, module)
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s", module.name), Settings.VarType.Boolean,
        module.title or module.name, module.defaults.enabled,
        function() return module.db.enabled end,
        function(value) ns.SetEnabled(module.name, value) end)
    track(module, setting)
    return Settings.CreateCheckbox(category, setting, module.description)
end

-- A module's own option (from `module.options`): a checkbox, or a dropdown when it lists
-- `choices`. With a `parent`, it's indented under it and greyed out while the module is off.
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

local function addOptions(category, module, parent, debug)
    for _, option in ipairs(module.options or {}) do
        if (option.debug or false) == debug then
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
        layout:AddInitializer(CreateSettingsButtonInitializer(action.name, action.button,
            action.fn, action.description, true))
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

    y = y - 36
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

---Adds the Forever++ pages to Settings > AddOns (called once, after ns.Start).
function ns.RegisterSettings()
    -- Probe: the Mainline Settings API is on Forever (build 70009), but it's a beta.
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.title)
    local subpages = Settings.RegisterVerticalLayoutSubcategory ~= nil
    addHeader(layout, L.MODULES)
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        local parent = addToggle(category, module)
        if not module.BuildPage and (hasOptions(module, false) or module.actions) then
            if subpages then
                local page, pageLayout = Settings.RegisterVerticalLayoutSubcategory(category,
                    module.title or name)
                addOptions(page, module, nil, false)
                addActions(pageLayout, module)
            else
                addOptions(category, module, parent, false)
                addActions(layout, module)
            end
        end
    end
    -- Pages modules draw themselves (tools such as Console Variables) go last, above Debug.
    if subpages and Settings.RegisterCanvasLayoutSubcategory then
        for _, name in ipairs(ns.order) do
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
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if hasOptions(module, true) then
            if debugPage == category and subpages then
                debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.DEBUG)
            end
            addHeader(debugLayout, module.title or name)
            addOptions(debugPage, module, nil, true)
        end
    end
    if subpages and Settings.RegisterCanvasLayoutSubcategory then
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
