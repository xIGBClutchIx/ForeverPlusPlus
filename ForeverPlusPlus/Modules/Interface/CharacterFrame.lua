-- Character Frame Enhancements: tidies the Character window. The Equipment Manager and Pet tabs
-- that sit across the top of the stats pane move to the side, under the Character, Reputation,
-- and other tabs, and the pane's header (the portrait tab and the "Level 60 Class" line) goes, so
-- the stats start at the top. The window's title becomes your level and name in your class color.
local _, ns = ...

local _G, ipairs, pairs, CreateFrame = _G, ipairs, pairs, CreateFrame
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
local EQUIPMENT, PET = 2, 3 -- indexes in Blizzard's PAPERDOLL_SIDEBARS (1 is Stats)
local GAP = 10 -- between Blizzard's tabs and ours

local started
local tabs = {} -- sidebar index -> our side tab
local panes -- the panes that hang from the header

local function frameOf(index)
    return _G.GetPaperDollSideBarFrame and _G.GetPaperDollSideBarFrame(index)
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

local function hideHeader()
    if module.db.sideTabs then
        _G.PaperDollSidebarTabs:Hide()
        _G.PaperDollLevelInfo:Hide()
    end
end

-- The stats, pet stats, and equipment sets panes hang from the bottom of the stone header, so
-- they move up to the top of the right pane.
local function anchorPanes(up)
    local host = _G.CharacterFrame.RightPaneHost
    for index, pane in ipairs(panes) do
        if up then
            pane:SetPoint("TOPLEFT", host, "TOPLEFT")
        else
            pane:SetPoint("TOPLEFT", host.StoneBg, "BOTTOMLEFT")
        end
        -- The stats lists leave room at the bottom for a divider line; take most of it back so
        -- they run further down.
        if index <= 2 then -- the two stats lists, not the equipment sets pane
            pane.ScrollBox:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -30, up and 4 or 30)
            -- The scrollbar stops a little short of the list's end, so it isn't pressed against
            -- the window's edge.
            pane.ScrollBar:SetPoint("BOTTOMLEFT", pane.ScrollBox, "BOTTOMRIGHT", 0, up and 10 or 0)
        end
    end
    host.StoneBg:SetAlpha(up and 0 or 1)
end

local function applyHeader()
    if module.db.sideTabs then
        anchorPanes(true)
        hideHeader()
    else
        anchorPanes(false)
        _G.PaperDollLevelInfo:Show()
        _G.PaperDollSidebarTabs:SetShown(_G.PaperDollFrame:IsShown() and not collapsed())
    end
end

-- Side tabs ------------------------------------------------------------------------------------

local function refreshTabs()
    local frame = _G.CharacterFrame
    local show = module.db.sideTabs and frame:IsShown()
    local onPaperDoll = _G.PaperDollFrame:IsShown()

    local last
    for _, tab in ipairs(frame.ModeTabs.Tabs) do
        if tab:IsShown() then
            last = tab
        end
    end

    local above, gap = last, GAP
    local ownSelected
    for index = EQUIPMENT, PET do
        local tab = tabs[index]
        local visible = show and last and (index ~= PET or HasPetUI())
        tab:SetShown(visible and true or false)
        if visible then
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -gap)
            above, gap = tab, 2
            local bar = frameOf(index)
            local checked = onPaperDoll and bar and bar:IsShown() or false
            ownSelected = ownSelected or checked
            tab:SetChecked(checked)
            tab.active = _G.PAPERDOLL_SIDEBARS[index].IsActive()
            tab:SetAlpha(tab.active and 1 or 0.5)
            tab.Icon:SetDesaturated(not tab.active)
            if index == PET then
                SetPortraitTexture(tab.Icon, "pet")
            end
        end
    end

    -- The Character tab isn't the selected one while one of ours is.
    if show then
        frame.ModeTabs.CharacterTab:SetChecked(onPaperDoll and not ownSelected)
    end
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
        _G.PaperDollFrame_SetSidebar(_G.PaperDollSidebarTabs, 1)
    end
end

local function makeTab(index)
    local info = _G.PAPERDOLL_SIDEBARS[index]
    local tab = CreateFrame("Frame", nil, _G.CharacterFrame, "LargeSideTabButtonTemplate")
    tab:EnableMouse(true)
    tab.tooltipText = info.name
    tab:Hide()
    if index == PET then
        tab:SetFillToInterior(true)
    else
        -- Use the icon Blizzard's own tab shows, so it stays in step with the game.
        local source = _G["PaperDollSidebarTab" .. index].Icon
        tab.Icon:SetTexture(source:GetTexture())
        tab.Icon:SetTexCoord(source:GetTexCoord())
        tab.Icon:SetSize(36, 36)
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

    panes = {
        _G.CharacterStatsPaneScrollBox, _G.CharacterStatsPanePetScrollBox, _G.CharacterStatsPane,
        _G.PaperDollFrame.EquipmentManagerPane,
    }
    for index = EQUIPMENT, PET do
        tabs[index] = makeTab(index)
    end

    -- Blizzard shows the header again whenever the pane opens.
    module:HookScript(_G.PaperDollSidebarTabs, "OnShow", hideHeader)
    module:HookScript(_G.PaperDollLevelInfo, "OnShow", hideHeader)
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
    if started and tabs[PET]:IsShown() then
        SetPortraitTexture(tabs[PET].Icon, "pet")
    end
end

local function onLevel(_, unit)
    if started and unit == "player" and _G.CharacterFrame:IsShown() then
        updateTitle()
    end
end

function module:OnEnable()
    self:On("UNIT_LEVEL", onLevel)
    self:On("UNIT_PORTRAIT_UPDATE", onPortrait)
    self:On("PORTRAITS_UPDATED", onPortrait)
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
    anchorPanes(false)
    _G.PaperDollLevelInfo:Show()
    _G.PaperDollSidebarTabs:SetShown(_G.PaperDollFrame:IsShown() and not collapsed())
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
