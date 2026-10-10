-- Character Frame Enhancements: tidies the Character window. The Equipment Manager, Titles, and
-- Pet tabs that sit across the top of the stats pane move to the side, under the Character,
-- Reputation, and other tabs, and the pane's header (the portrait tab and the "Level 60 Class"
-- line) goes, so the stats start at the top. The window's title becomes your level and name in
-- your class color.
local _, ns = ...

local _G, ipairs, pairs, type, CreateFrame = _G, ipairs, pairs, type, CreateFrame
local format, UnitLevel, UnitName, UnitPVPName = string.format, UnitLevel, UnitName, UnitPVPName
local HasPetUI, SetPortraitTexture = HasPetUI, SetPortraitTexture

local L = ns.L
local Colors = ns.Colors

local module = ns.NewModule("CharacterFrame", L.CHARACTERFRAME_DESC, {
    enabled = true,
    sideTabs = true,
    colorTitle = true,
})
module.title = L.CHARACTERFRAME_TITLE
module.category = "interface"

module.options = {
    { key = "sideTabs", name = L.CHARACTERFRAME_SIDETABS, description = L.CHARACTERFRAME_SIDETABS_DESC },
    { key = "colorTitle", name = L.CHARACTERFRAME_COLORTITLE, description = L.CHARACTERFRAME_COLORTITLE_DESC },
}

local ADDON = "Blizzard_UIPanels_Game"
local STATS = 1 -- Blizzard's PAPERDOLL_SIDEBARS index for the stats; every other one gets a side tab
local GAP = 10 -- between Blizzard's tabs and ours, when there's room
local SPACING = 2 -- between side tabs, as Blizzard spaces its own
local BOTTOM = 4 -- kept clear above the bottom of the window
local LEVEL_TOP = 8 -- from the top of the right pane to the pet's level line

local started
local tabs = {} -- sidebar index -> our side tab, from STATS + 1 to numSidebars
local numSidebars = 0
local panes -- pane -> true for the scrolling lists (stats, pet, titles), false for the others
local petPane

local function frameOf(index)
    return _G.GetPaperDollSideBarFrame and _G.GetPaperDollSideBarFrame(index)
end

-- Sidebars are found by their pane, not their place: build 70170 put Titles third and moved the
-- pet to fourth (Forever only).
local function isPet(index)
    return frameOf(index) == petPane
end

-- Title ----------------------------------------------------------------------------------------

local function updateTitle()
    local frame = _G.CharacterFrame
    if not (module.db.colorTitle and (frame.activeSubframe or "PaperDollFrame") == "PaperDollFrame") then
        return
    end
    local text = frame:GetTitleText()
    -- The level in gold and the name in the class color, so the text itself is plain white.
    local level = Colors.Text(NORMAL_FONT_COLOR, UnitLevel("player"))
    local name = UnitPVPName("player") or UnitName("player")
    local color = Colors.Class("player")
    text:SetText(format(L.CHARACTERFRAME_TITLE_FORMAT, level, color and Colors.Text(color, name) or name))
    text:SetTextColor(1, 1, 1)
end

-- Blizzard's own title back, for when the option or the module turns off.
local function restoreTitle()
    _G.CharacterFrame:UpdateTitle()
end

-- Header ---------------------------------------------------------------------------------------

local function collapsed()
    return _G.CharacterFrame:IsRightPaneCollapsed()
end

-- The tab row always goes. The level line goes too, except on the pet pane: there it carries the
-- pet's level, family, and loyalty, which the title doesn't, so it moves to the top of the pane.
local function updateHeader()
    if module.db.sideTabs then
        _G.PaperDollSidebarTabs:Hide()
        _G.PaperDollLevelInfo:SetShown(petPane:IsVisible())
    end
end

-- The stats, pet stats, titles, and equipment sets panes hang from the bottom of the stone
-- header, so they move up to the top of the right pane.
local function anchorPanes(up)
    local host = _G.CharacterFrame.RightPaneHost
    local info = _G.PaperDollLevelInfo
    for pane, stats in pairs(panes) do
        if pane == petPane then
            -- The pet stats start under the level line, which is two lines tall with loyalty.
            pane:ClearAllPoints()
            if up then
                pane:SetPoint("TOP", info, "BOTTOM", 0, -4)
            else
                pane:SetPoint("TOPLEFT", host.StoneBg, "BOTTOMLEFT")
            end
            pane:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT")
        elseif up then
            pane:SetPoint("TOPLEFT", host, "TOPLEFT")
        else
            pane:SetPoint("TOPLEFT", host.StoneBg, "BOTTOMLEFT")
        end
        -- The lists leave room at the bottom for a divider line; take most of it back so they
        -- run further down.
        if stats then
            pane.ScrollBox:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -30, up and 4 or 30)
            -- The scrollbar stops a little short of the list's end, so it isn't pressed against
            -- the window's edge.
            pane.ScrollBar:SetPoint("BOTTOMLEFT", pane.ScrollBox, "BOTTOMRIGHT", 0, up and 10 or 0)
        end
    end
    info:ClearAllPoints()
    if up then
        info:SetPoint("TOP", host, "TOP", 0, -LEVEL_TOP)
    else
        info:SetPoint("TOP", _G.PaperDollSidebarTabs, "TOP", 0, -50)
    end
    host.StoneBg:SetAlpha(up and 0 or 1)
end

-- Blizzard's header back.
local function showHeader()
    anchorPanes(false)
    _G.PaperDollLevelInfo:Show()
    _G.PaperDollSidebarTabs:SetShown(_G.PaperDollFrame:IsShown() and not collapsed())
end

local function applyHeader()
    if module.db.sideTabs then
        anchorPanes(true)
        updateHeader()
    else
        showHeader()
    end
end

-- Side tabs ------------------------------------------------------------------------------------

-- The pet's portrait, cropped to the tab like the Character tab's. A new portrait can undo the
-- crop, so it goes on again each time.
local function petPortrait(tab)
    SetPortraitTexture(tab.Icon, "pet")
    if tab.UpdateIconInterior then
        tab:UpdateIconInterior()
    end
end

-- Like Blizzard's sidebar tabs: the name, and while the tab can't be used, why in red (no titles
-- yet, no pet).
local function tooltipFor(info, tab)
    return function(tooltip)
        _G.GameTooltip_SetTitle(tooltip, info.name)
        local reason = info.disabledTooltip
        if type(reason) == "function" then
            reason = reason()
        end
        if not tab.active and reason then
            _G.GameTooltip_AddErrorLine(tooltip, reason, true)
        end
        return true
    end
end

-- The gap above our tabs and their scale, so the last one ends inside the window. Blizzard's own
-- six tabs fill most of its 484 high side, so with all three of ours (a pet) the full gap may not
-- fit: it shrinks to Blizzard's spacing first, and only then do our tabs get smaller.
local function fit(frame, last, count, height)
    local bottom, lastBottom = frame:GetBottom(), last and last:GetBottom()
    if count == 0 or height <= 0 or not (bottom and lastBottom) then
        return GAP, 1
    end
    local room = lastBottom - bottom - BOTTOM - count * height - (count - 1) * SPACING
    if room >= GAP then
        return GAP, 1
    elseif room >= SPACING then
        return room, 1
    end
    local scale = (lastBottom - bottom - BOTTOM - count * SPACING) / (count * height)
    return SPACING, scale > 0 and scale or 1
end

local function refreshTabs()
    local frame = _G.CharacterFrame
    local show = module.db.sideTabs and frame:IsShown()
    local onPaperDoll = _G.PaperDollFrame:IsShown() and not collapsed()

    local last
    for _, tab in ipairs(frame.ModeTabs.Tabs) do
        if tab:IsShown() then
            last = tab
        end
    end

    local count, height = 0, 0
    for index = STATS + 1, numSidebars do
        local tab = tabs[index]
        local visible = show and last and (not isPet(index) or HasPetUI()) and true or false
        tab:SetShown(visible)
        if visible then
            count, height = count + 1, tab:GetHeight()
        end
    end
    local gap, scale = fit(frame, last, count, height)

    local above = last
    local ownSelected
    for index = STATS + 1, numSidebars do
        local tab = tabs[index]
        if tab:IsShown() then
            local pet = isPet(index)
            -- A tab's offsets are in its own scale, so they're divided by it to stay the same gap.
            tab:SetScale(scale)
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -gap / scale)
            above, gap = tab, SPACING
            local bar = frameOf(index)
            local checked = onPaperDoll and bar and bar:IsShown() or false
            ownSelected = ownSelected or checked
            tab:SetChecked(checked)
            tab.active = _G.PAPERDOLL_SIDEBARS[index].IsActive()
            tab:SetAlpha(tab.active and 1 or 0.5)
            tab.Icon:SetDesaturated(not tab.active)
            if pet then
                petPortrait(tab)
            end
        end
    end

    -- The Character tab isn't the selected one while one of ours is.
    if show then
        frame.ModeTabs.CharacterTab:SetChecked(_G.PaperDollFrame:IsShown() and not ownSelected)
    end
    updateHeader()
end

-- A side tab opens the Character window's pane for it, and the Character tab goes back to stats.
local function toggle(index)
    local frame = _G.CharacterFrame
    if frame:IsRightPaneCollapsed() then
        frame:SetRightPaneCollapsed(false)
    end
    if not _G.PaperDollFrame:IsShown() then
        _G.ToggleCharacter("PaperDollFrame", true)
    end
    _G.PaperDollFrame_SetSidebar(_G.PaperDollSidebarTabs, index)
    refreshTabs()
end

local function onModeTabClicked(_, tab)
    if module.db.sideTabs and tab.frameName == "PaperDollFrame" then
        _G.PaperDollFrame_SetSidebar(_G.PaperDollSidebarTabs, STATS)
    end
end

-- Use the icon Blizzard's own tab shows, so it stays in step with the game, at our tab's size.
local function copyIcon(icon, source)
    local atlas = source.GetAtlas and source:GetAtlas()
    if atlas then
        icon:SetAtlas(atlas)
    else
        icon:SetTexture(source:GetTexture())
        icon:SetTexCoord(source:GetTexCoord())
    end
    local width, height = source:GetSize()
    icon:SetSize(36, width > 0 and 36 * height / width or 36)
end

local function makeTab(index)
    local info = _G.PAPERDOLL_SIDEBARS[index]
    local tab = CreateFrame("Frame", nil, _G.CharacterFrame, "LargeSideTabButtonTemplate")
    tab:EnableMouse(true)
    tab.tooltipText = info.name
    local setup = tooltipFor(info, tab)
    function tab:GetTooltipTextSetupFunction()
        return setup
    end
    tab:Hide()
    local source = _G["PaperDollSidebarTab" .. index]
    if isPet(index) then
        tab:SetFillToInterior(true)
    elseif source then
        copyIcon(tab.Icon, source.Icon)
    end
    tab:SetCustomOnMouseUpHandler(function(self, button, upInside)
        if button == "LeftButton" and upInside and self.active then
            toggle(index)
        end
    end)
    return tab
end

-- Start ----------------------------------------------------------------------------------------

local function start()
    if started or not (_G.CharacterFrame and _G.PaperDollSidebarTabs and _G.PaperDollFrame
        and _G.PAPERDOLL_SIDEBARS and _G.PaperDollFrame_SetSidebar) then
        return
    end
    started = true

    petPane = _G.CharacterStatsPanePetScrollBox
    panes = {
        [_G.CharacterStatsPaneScrollBox] = true,
        [petPane] = true,
        [_G.CharacterStatsPane] = false,
        [_G.PaperDollFrame.EquipmentManagerPane] = false,
    }
    -- The titles list has the stats lists' scroll box and bar, and the same gap under them.
    if _G.PaperDollFrame.TitleManagerPane then
        panes[_G.PaperDollFrame.TitleManagerPane] = true
    end
    numSidebars = #_G.PAPERDOLL_SIDEBARS
    for index = STATS + 1, numSidebars do
        tabs[index] = makeTab(index)
    end

    -- Blizzard shows the header again whenever the pane opens.
    module:HookScript(_G.PaperDollSidebarTabs, "OnShow", updateHeader)
    module:HookScript(_G.PaperDollLevelInfo, "OnShow", updateHeader)
    module:HookScript(_G.PaperDollFrame, "OnShow", refreshTabs)
    module:HookScript(_G.PaperDollFrame, "OnHide", refreshTabs)
    module:Hook("PaperDollFrame_UpdateSidebarTabs", refreshTabs)
    module:Hook("PaperDollFrame_SetSidebar", refreshTabs)
    module:Hook(_G.CharacterFrame, "RefreshRightPane", refreshTabs)
    module:Hook(_G.CharacterFrame, "UpdateTabLayout", refreshTabs)
    module:Hook(_G.CharacterFrame, "SetSelectedModeTabByFrame", refreshTabs)
    module:Hook(_G.CharacterFrame, "OnModeTabClicked", onModeTabClicked)
    module:HookScript(_G.CharacterFrame, "OnShow", refreshTabs)
    module:HookScript(_G.CharacterFrame, "OnHide", refreshTabs)
    module:Hook(_G.CharacterFrame, "UpdateTitle", updateTitle)

    applyHeader()
    refreshTabs()
    updateTitle()
end

local function onPortrait()
    if not started then
        return
    end
    for index, tab in pairs(tabs) do
        if isPet(index) and tab:IsShown() then
            petPortrait(tab)
        end
    end
end

-- Blizzard only updates its pet tab while the stats pane is open, so ours follows the pet on the
-- Reputation and other panes too.
local function onPet(_, unit)
    if started and unit == "player" then
        refreshTabs()
    end
end

-- Blizzard only rechecks which of its tabs can be used when the stats pane changes, so a first
-- title or equipment set wouldn't wake up our tab until then.
local function onTabsChanged()
    if started and _G.CharacterFrame:IsShown() then
        refreshTabs()
    end
end

-- Blizzard redoes the title for a new name or title, but not for a new level.
local function onLevel(_, unit)
    if started and unit == "player" and _G.CharacterFrame:IsShown() then
        updateTitle()
    end
end

function module:OnEnable()
    self:On("UNIT_LEVEL", onLevel)
    self:On("UNIT_PET", onPet)
    self:On("UNIT_PORTRAIT_UPDATE", onPortrait)
    self:On("PORTRAITS_UPDATED", onPortrait)
    self:On("KNOWN_TITLES_UPDATE", onTabsChanged)
    self:On("EQUIPMENT_SETS_CHANGED", onTabsChanged)
    if _G.CharacterFrame then
        start()
    end
    if started then
        applyHeader()
        refreshTabs()
        updateTitle()
    else
        ns.AddOns.WhenLoaded(ADDON, start)
    end
end

function module:OnDisable()
    ns.AddOns.Cancel(ADDON, start)
    if not started then
        return
    end
    showHeader()
    for _, tab in pairs(tabs) do
        tab:Hide()
    end
    _G.CharacterFrame.ModeTabs.CharacterTab:SetChecked(_G.PaperDollFrame:IsShown())
    restoreTitle()
end

function module:OnOptionChanged(key)
    if not (self.enabled and started) then
        return
    end
    if key == "sideTabs" then
        applyHeader()
        refreshTabs()
    elseif key == "colorTitle" then
        if self.db.colorTitle then
            updateTitle()
        else
            restoreTitle()
        end
    end
end
