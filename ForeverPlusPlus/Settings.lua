-- The "Forever++" page in the game's Settings > AddOns list: one checkbox per module, built from
-- Blizzard's own settings templates so it looks like any other options page.
local _, ns = ...

local ipairs, format = ipairs, string.format

local settings = {} -- module name -> Blizzard setting object, to refresh after /fpp toggle

-- A module's own on/off option (from `module.options`), shown indented under its checkbox and
-- greyed out while the module is off.
local function addOption(category, module, option, parent)
    local setting = Settings.RegisterProxySetting(category,
        format("ForeverPlusPlus_%s_%s", module.name, option.key), Settings.VarType.Boolean,
        option.name, module.defaults[option.key],
        function() return module.db[option.key] end,
        function(value)
            module.db[option.key] = value
            if module.OnOptionChanged then
                module:OnOptionChanged(option.key)
            end
        end)
    local initializer = Settings.CreateCheckbox(category, setting, option.description)
    if parent and initializer and initializer.SetParentInitializer then
        initializer:SetParentInitializer(parent, function() return module.db.enabled end)
    end
end

---Adds the Forever++ category to Settings > AddOns (called once, after ns.Start).
function ns.RegisterSettings()
    -- Probe: the Mainline Settings API is on Forever (build 70009), but it's a beta.
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.title)
    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Modules"))
    end
    for _, name in ipairs(ns.order) do
        local module = ns.modules[name]
        -- A proxy setting reads and writes through the module, so /fpp and this page agree.
        local setting = Settings.RegisterProxySetting(category,
            format("ForeverPlusPlus_%s", name), Settings.VarType.Boolean, name,
            module.defaults.enabled,
            function() return module.db.enabled end,
            function(value) ns.SetEnabled(name, value) end)
        local parent = Settings.CreateCheckbox(category, setting, module.description)
        settings[name] = setting
        for _, option in ipairs(module.options or {}) do
            addOption(category, module, option, parent)
        end
    end
    Settings.RegisterAddOnCategory(category)
end

---Updates a module's checkbox after it changed somewhere else (/fpp toggle).
---@param name string
function ns.RefreshSetting(name)
    local setting = settings[name]
    if setting and Settings.NotifyUpdate then
        Settings.NotifyUpdate(setting:GetVariable())
    end
end
