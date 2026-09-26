-- The "Forever++" pages in the game's Settings > AddOns list, built from Blizzard's own settings
-- templates so they look like any other options page:
--   Forever++        an on/off checkbox per module
--     <Module>       one page per module with options: its on/off checkbox, then its options
--     Debug          options marked `debug = true`, for testing
-- Without subpages (an older Settings API), everything goes on the main page instead.
local _, ns = ...

local ipairs, format = ipairs, string.format

local settings = {} -- module name -> its Blizzard setting objects, to refresh after /fpp toggle

-- The module's on/off checkbox. Each page gets its own setting (the variable names must differ);
-- all of them read and write through the module, so /fpp and every page agree.
local function addToggle(category, module, suffix)
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s%s", module.name, suffix), Settings.VarType.Boolean,
        module.title or module.name, module.defaults.enabled,
        function() return module.db.enabled end,
        function(value) ns.SetEnabled(module.name, value) end)
    settings[module.name] = settings[module.name] or {}
    local list = settings[module.name]
    list[#list + 1] = setting
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
        function(value)
            module.db[option.key] = value
            if module.OnOptionChanged then
                module:OnOptionChanged(option.key)
            end
        end)
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

---Adds the Forever++ pages to Settings > AddOns (called once, after ns.Start).
function ns.RegisterSettings()
    -- Probe: the Mainline Settings API is on Forever (build 70009), but it's a beta.
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.title)
    local subpages = Settings.RegisterVerticalLayoutSubcategory ~= nil
    addHeader(layout, "Modules")
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        local parent = addToggle(category, module, "")
        if hasOptions(module, false) then
            if subpages then
                local page = Settings.RegisterVerticalLayoutSubcategory(category, module.title or name)
                addOptions(page, module, addToggle(page, module, "_Page"), false)
            else
                addOptions(category, module, parent, false)
            end
        end
    end
    -- Debug options, grouped by module.
    local debugPage, debugLayout = category, layout
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        if hasOptions(module, true) then
            if debugPage == category and subpages then
                debugPage, debugLayout = Settings.RegisterVerticalLayoutSubcategory(category, "Debug")
            end
            addHeader(debugLayout, module.title or name)
            addOptions(debugPage, module, nil, true)
        end
    end
    Settings.RegisterAddOnCategory(category)
end

---Updates a module's checkboxes after it changed somewhere else (/fpp toggle).
---@param name string
function ns.RefreshSetting(name)
    if not Settings or not Settings.NotifyUpdate then
        return
    end
    for _, setting in ipairs(settings[name] or {}) do
        Settings.NotifyUpdate(setting:GetVariable())
    end
end
