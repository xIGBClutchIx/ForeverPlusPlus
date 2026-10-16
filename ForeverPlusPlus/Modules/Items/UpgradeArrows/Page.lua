-- Upgrade Arrows' own page in Settings (`/fpp weights`): the Profile dropdown (Auto, the
-- class's talent tabs, and Feral Bear for Druids), which picks the module's Profile setting,
-- then a slider row per stat of the profile in use under small headers, with its value and an
-- undo arrow while it isn't the default. Only the stats the profile weighs are listed unless
-- Show All is ticked. Drawn with ns.SettingsKit so it looks like the Modules page, which uses
-- the same slider and dropdown templates.
local _, ns = ...

local ipairs, pairs, format, tonumber, select = ipairs, pairs, string.format, tonumber, select
local CreateFrame, UnitClass = CreateFrame, UnitClass

local L = ns.L
local Kit = ns.SettingsKit
local ItemStats = ns.ItemStats
local Talents = ns.Talents

local module = ns.modules.UpgradeArrows
local internal = module.internal

-- The stats in groups, in the order the page lists them (every key of ItemStats.ORDER).
local GROUPS = {
    { L.UPGRADEARROWS_GROUP_ATTRIBUTES, { "STR", "AGI", "STA", "INT", "SPI", "HEALTH", "MANA" } },
    { L.UPGRADEARROWS_GROUP_MELEE, { "AP", "HIT", "CRIT", "HASTE", "EXPERTISE", "ARMORPEN" } },
    { L.UPGRADEARROWS_GROUP_RANGED, { "RAP" } },
    { L.UPGRADEARROWS_GROUP_SPELL, { "SP", "HEAL", "SPELLHIT", "SPELLCRIT", "MP5", "HP5" } },
    { L.UPGRADEARROWS_GROUP_DEFENSE, { "ARMOR", "DEF", "DODGE", "PARRY", "BLOCK", "BLOCKVALUE" } },
    { L.UPGRADEARROWS_GROUP_WEAPONS, { "DPS", "DPS_OFF", "DPS_RANGED" } },
    { L.UPGRADEARROWS_GROUP_RESISTANCES, { "RES_FIRE", "RES_NATURE", "RES_FROST", "RES_SHADOW", "RES_ARCANE" } },
}

local MAX_WEIGHT, STEP = 20, 0.1
local ROW_HEIGHT, HEADER_HEIGHT = 26, 24
local NAME_WIDTH, SLIDER_WIDTH, RESET_SIZE = 190, 250, 22

local ui -- the page's frames, once built
local editing -- the profile shown: from internal.Profile
local showAll = false

-- The stat's name, with "per 1%" in gray after a chance stat's.
local function statName(stat)
    local name = L["UPGRADEARROWS_STAT_" .. stat] or stat
    if ItemStats.PERCENT[stat] then
        name = format("%s |cff808080%s|r", name, L.UPGRADEARROWS_PER_PERCENT)
    end
    return name
end

local function weightText(value)
    return format("%.1f", value or 0)
end

-- Profiles ------------------------------------------------------------------------------------

local function playerClass()
    local _, class = UnitClass("player")
    return ns.IsText(class, true) and class or "?"
end

-- The profiles the dropdown offers, each with the Profile setting's value: Auto, each talent
-- tab, and Bear for a Druid.
local function choices()
    local list = { { value = "auto", name = L.UPGRADEARROWS_PROFILE_AUTO } }
    local tabs = Talents.Tabs()
    for i = 1, 3 do
        local tab = tabs and tabs[i]
        local name = tab and tab.name ~= "" and tab.name or format(L.UPGRADEARROWS_PROFILE_TREE, i)
        list[#list + 1] = { value = tostring(i), index = i, name = name }
    end
    if playerClass() == "DRUID" then
        list[#list + 1] = { value = "bear", bear = true, name = L.UPGRADEARROWS_PROFILE_BEAR }
    end
    return list
end

-- The profile the Profile setting resolves to, with the module's saved weights read in: the
-- module's own while it's on, else worked out the same way here.
local function resolveProfile()
    local current = internal.CurrentProfile()
    if current then
        return internal.Profile(current.class, current.index, current.bear), current.guess
    end
    local choice = module.db.profile
    local class = playerClass()
    if choice == "bear" and class == "DRUID" then
        return internal.Profile(class, 1, true), false
    elseif tonumber(choice) then
        return internal.Profile(class, tonumber(choice)), false
    end
    local best = Talents.Dominant()
    if best and best.spent > 0 then
        return internal.Profile(class, best.index), false
    end
    return internal.Profile(class, 1), true
end

-- The name of the tab or Bear a profile is, for the line under the dropdown.
local function profileName(profile)
    for _, choice in ipairs(choices()) do
        if choice.value ~= "auto" and internal.Profile(profile.class, choice.index or 1, choice.bear).key == profile.key then
            return choice.name
        end
    end
    return profile.key
end

-- What the module judges gear by right now.
local function usedText(guess)
    if not editing then
        return ""
    end
    local name = profileName(editing)
    if module.db.profile == "auto" then
        local best = Talents.Dominant()
        if guess or not best then
            return format(L.UPGRADEARROWS_PAGE_USED_GUESS, name)
        end
        return format(L.UPGRADEARROWS_PAGE_USED_AUTO, name, best.spent)
    end
    return format(L.UPGRADEARROWS_PAGE_USED, name)
end

-- Rows ------------------------------------------------------------------------------------------

-- Whether a stat's row shows: always with Show All, else while the profile weighs it or the
-- player set it.
local function rowShown(stat)
    if showAll or not editing then
        return true
    end
    return (editing.defaults[stat] or 0) ~= 0 or editing.weights[stat] ~= nil
end

local function currentWeight(stat)
    return editing and editing.weights[stat] or 0
end

local function defaultWeight(stat)
    return editing and editing.defaults[stat] or 0
end

-- The undo arrow at a row's right, shown while the weight isn't the profile's default. Probe:
-- the atlases are Mainline's; without one, no arrow.
local function addResetButton(row, stat)
    local atlas = ns.Frames.FirstAtlas("common-icon-undo", "talents-button-undo")
    if not atlas then
        return nil
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
    button:SetScript("OnMouseDown", function() icon:SetPoint("CENTER", 1, -1) end)
    button:SetScript("OnMouseUp", function() icon:SetPoint("CENTER") end)
    button:SetScript("OnClick", function()
        if PlaySound and SOUNDKIT then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        if editing then
            internal.SetWeight(editing, stat, defaultWeight(stat))
            ui.refresh()
        end
    end)
    button:SetScript("OnEnter", function(self)
        Kit.ShowTooltip(self, L.SETTINGS_RESET, format(L.UPGRADEARROWS_PAGE_DEFAULT, weightText(defaultWeight(stat))))
    end)
    button:SetScript("OnLeave", Kit.HideTooltip)
    return button
end

-- Blizzard's slider with steppers, 0 to 20 by 0.1, its value shown at its right. Probe:
-- Mainline's; without it the row shows the value as text only.
local function addSlider(row, stat)
    if not (MinimalSliderWithSteppersMixin and Settings and Settings.CreateSliderOptions) then
        return nil
    end
    local ok, slider = pcall(CreateFrame, "Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    if not (ok and slider and slider.Init and slider.RegisterCallback) then
        return nil
    end
    slider:SetWidth(SLIDER_WIDTH)
    slider:SetPoint("LEFT", NAME_WIDTH, 0)
    local options = Settings.CreateSliderOptions(0, MAX_WEIGHT, STEP)
    if MinimalSliderWithSteppersMixin.Label then
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, weightText)
    end
    slider:Init(currentWeight(stat), options.minValue, options.maxValue, options.steps, options.formatters)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        value = tonumber(format("%.1f", value))
        -- Setting it back to what's saved (a refresh) changes nothing.
        if editing and value and value ~= currentWeight(stat) then
            internal.SetWeight(editing, stat, value)
            ui.refreshRow(stat)
        end
    end, slider)
    return slider
end

local function newRow(parent, stat)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth(), ROW_HEIGHT)
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", 8, 0)
    name:SetWidth(NAME_WIDTH - 12)
    name:SetJustifyH("LEFT")
    name:SetText(statName(stat))
    row.slider = addSlider(row, stat)
    if not row.slider then
        row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.value:SetPoint("LEFT", NAME_WIDTH, 0)
    end
    row.reset = addResetButton(row, stat)
    row.stat = stat
    return row
end

local function newHeader(parent, text)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(parent:GetWidth(), HEADER_HEIGHT)
    local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", 8, 2)
    label:SetText(text)
    return header
end

-- Refreshing --------------------------------------------------------------------------------------

local function refreshRow(stat)
    local row = ui.rows[stat]
    if not row then
        return
    end
    local value = currentWeight(stat)
    if row.slider then
        row.slider:SetValue(value)
    elseif row.value then
        row.value:SetText(weightText(value))
    end
    if row.reset then
        row.reset:SetShown(value ~= defaultWeight(stat))
    end
end

local function refresh()
    if not ui then
        return
    end
    local guess
    editing, guess = resolveProfile()
    ui.used:SetText(usedText(guess))
    if ui.dropdown and ui.dropdown.GenerateMenu then
        ui.dropdown:GenerateMenu()
    elseif ui.profileText then
        ui.profileText:SetText(profileName(editing))
    end
    for stat in pairs(ui.rows) do
        refreshRow(stat)
    end
    Kit.Layout(ui.content)
end

-- The page --------------------------------------------------------------------------------------

-- Blizzard's menu dropdown for the profile. Probe: Mainline's; without it, the profile's name.
local function addDropdown(frame)
    if WowStyle1DropdownMixin then
        local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
        if ok and dropdown and dropdown.SetupMenu then
            dropdown:SetWidth(200)
            dropdown:SetupMenu(function(_, root)
                for _, choice in ipairs(choices()) do
                    root:CreateRadio(choice.name, function()
                        return module.db.profile == choice.value
                    end, function()
                        internal.SetProfile(choice.value)
                        refresh()
                    end)
                end
            end)
            Kit.AddTooltip(dropdown, L.UPGRADEARROWS_PROFILE, L.UPGRADEARROWS_PROFILE_DESC)
            return dropdown
        end
    end
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.profileText = text
    return text
end

---Draws the page the first time it's shown (called by Settings/Settings.lua).
---@param frame table the empty page
function module:BuildPage(frame)
    ui = { rows = {}, refresh = refresh, refreshRow = refreshRow }
    Kit.AddPageTitle(frame, module.title)

    -- Defaults at the top right, as on the other pages, for the shown profile.
    local reset = Kit.NewButton(frame, L.UPGRADEARROWS_PAGE_RESET, 96, function()
        if not editing then
            return
        end
        ns.Confirm("UPGRADEARROWS_RESET", L.UPGRADEARROWS_PAGE_RESET_CONFIRM, function()
            internal.ResetWeights(editing)
            refresh()
        end, editing.key)
    end)
    reset:SetPoint("TOPRIGHT", -12, -19)
    Kit.AddTooltip(reset, L.UPGRADEARROWS_PAGE_RESET, L.UPGRADEARROWS_PAGE_RESET_DESC)

    local showAllBox = Kit.AddLabeledCheck(frame, reset, L.UPGRADEARROWS_PAGE_SHOW_ALL, function(checked)
        showAll = checked
        refresh()
    end)
    showAllBox:SetChecked(showAll)
    Kit.AddTooltip(showAllBox, L.UPGRADEARROWS_PAGE_SHOW_ALL, L.UPGRADEARROWS_PAGE_SHOW_ALL_DESC)

    local profileLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 10, -64)
    profileLabel:SetText(L.UPGRADEARROWS_PROFILE)
    ui.dropdown = addDropdown(frame)
    ui.dropdown:SetPoint("LEFT", profileLabel, "RIGHT", 8, 0)

    ui.used = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.used:SetPoint("TOPLEFT", 10, -90)
    ui.used:SetPoint("RIGHT", -40, 0)
    ui.used:SetJustifyH("LEFT")

    local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 10, -106)
    note:SetPoint("RIGHT", -40, 0)
    note:SetJustifyH("LEFT")
    note:SetText(L.UPGRADEARROWS_PAGE_NOTE)

    local scroll = Kit.NewScroll(frame)
    scroll:SetPoint("TOPLEFT", 4, -128)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local width = 560
    ui.content = Kit.NewStack(scroll, width, 2)
    scroll:SetScrollChild(ui.content)
    scroll:HookScript("OnSizeChanged", function(self, w)
        ui.content:SetWidth(w)
    end)

    for _, group in ipairs(GROUPS) do
        local stats = group[2]
        local header = newHeader(ui.content, group[1])
        Kit.AddEntry(ui.content, header, function()
            for _, stat in ipairs(stats) do
                if rowShown(stat) then
                    return true
                end
            end
            return false
        end, 8)
        for _, stat in ipairs(stats) do
            local row = newRow(ui.content, stat)
            ui.rows[stat] = row
            Kit.AddEntry(ui.content, row, function()
                return rowShown(stat)
            end)
        end
    end

    frame:HookScript("OnShow", refresh)
    refresh()
end

ns.AddCommand("weights", "", L.UPGRADEARROWS_COMMAND, function()
    ns.OpenSettings(module.name)
end)
