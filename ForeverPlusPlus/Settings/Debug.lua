-- The Debug page: Blizzard settings rows (a list page, not one we draw), with a header for each
-- section (What's New, Diagnostics, Testing, Logging). Under each, Forever++'s own rows and then
-- each module's options marked `debug = true` and buttons from `module.debugActions` that name it;
-- after them a header for each module with rows in no section. Our own Defaults button sits over
-- Blizzard's on it.
local _, ns = ...

local ipairs, pairs, format, concat, tostring = ipairs, pairs, string.format, table.concat, tostring
local CreateFrame, GetBuildInfo = CreateFrame, GetBuildInfo
local L = ns.L
local S = ns.SettingsUI

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
            S.change(function()
                ns.SetOption(module.name, option.key, value)
            end)
        end)
    S.track(module, setting)
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
            S.change(function()
                ns.db.showTags = value or nil
                S.markNew()
                S.refreshAll()
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
                S.actionFn(module, action, i), action.description, true)
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
-- searching. The Modules, Changelog and About pages are drawn by us and have their own.

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
function S.AddDefaultsButton()
    local list = SettingsPanel and SettingsPanel.GetSettingsList and SettingsPanel:GetSettingsList()
    local blizzard = list and list.Header and list.Header.DefaultsButton
    if not (blizzard and EventRegistry and EventRegistry.RegisterCallback) then
        return
    end
    defaultsButton = CreateFrame("Button", nil, list.Header, "UIPanelButtonTemplate")
    defaultsButton:SetAllPoints(blizzard)
    defaultsButton:SetFrameLevel(blizzard:GetFrameLevel() + 5)
    defaultsButton:SetText(SETTINGS_DEFAULTS or L.HOME_DEFAULTS)
    defaultsButton:SetScript("OnClick", S.askDefaults)
    defaultsButton:Hide()
    blizzard:HookScript("OnShow", function() updateDefaults(blizzard) end)
    blizzard:HookScript("OnHide", function() updateDefaults(blizzard) end)
    EventRegistry:RegisterCallback("Settings.CategoryChanged", function() updateDefaults(blizzard) end,
        defaultsButton)
end

-- Debug page tools ----------------------------------------------------------------------------
-- Forever++'s own rows on the Debug page, and the page itself.

-- One line for a bug report: the addon and client, and the modules on.
local function debugInfo()
    local gameVersion, build, _, interface = GetBuildInfo()
    local on = ns.ModulesOn()
    return format(L.DEBUG_INFO_LINE, ns.version, tostring(gameVersion), tostring(build),
        tostring(interface), GetLocale(), #on, concat(on, ", "))
end

-- How many hooks a module has made (`module:Hook`, `HookScript`, `TooltipPostCall`). They stay but
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
    for _, name in ipairs(S.byTitle()) do
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
        description = L.DEBUG_RESET_SEEN_DESC, fn = S.resetSeen, section = L.DEBUG_SECTION_NEW },
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

-- The Debug page under `parent`: a header for each section, with Forever++'s own rows and then
-- each module's (in `order`, by title) under it, and after them a header for each module with rows
-- in no section.
function S.AddDebugPage(parent, order)
    local category, layout = Settings.RegisterVerticalLayoutSubcategory(parent, L.DEBUG)
    ourPages[category] = true
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
