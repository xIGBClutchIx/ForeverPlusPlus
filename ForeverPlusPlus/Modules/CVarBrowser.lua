-- Console Variables: a page under Forever++ in Settings that lists the game's console variables
-- (CVars) the player can change with a search, shows each one's value and default, and lets the
-- player change one or put it back to its default. Read-only CVars are left out. Changes made in combat wait for it to end (ns.CVars.Apply).
-- Nothing is built until the page is first shown; `/fpp cvar <search>` opens it.
local _, ns = ...

local ipairs, type, sort, format, tostring = ipairs, type, table.sort, string.format, tostring
local strlower, strfind, strtrim, tinsert = string.lower, string.find, strtrim, table.insert
local CreateFrame, InCombatLockdown = CreateFrame, InCombatLockdown
local C_CVar, C_Timer = C_CVar, C_Timer
-- The console's command list. Forever (build 70009) has the global, like Retail; C_Console is a
-- guess at a later rename.
local getAllCommands = ConsoleGetAllCommands or (C_Console and C_Console.GetAllCommands)
local L = ns.L

local module = ns.NewModule("CVarBrowser", L.CVARBROWSER_DESC, { enabled = true })
module.title = L.CVARBROWSER_TITLE
module.alwaysOn = true -- a tool page, not a change to the game; it costs nothing until opened

local ROW_HEIGHT = 26
-- Columns, measured from the list's right edge so the name gets whatever width is left.
local RESET_WIDTH, DEFAULT_WIDTH, VALUE_WIDTH, GAP = 80, 110, 150, 10
local DEFAULT_RIGHT = -(4 + RESET_WIDTH + GAP)
local VALUE_RIGHT = DEFAULT_RIGHT - DEFAULT_WIDTH - GAP

local all -- every listed CVar, sorted: { name, key (lowercase name), text (lowercase name and help), help }
local byKey = {} -- lowercase name -> entry in `all`
local search, changedOnly = "", false
local listening = false
local ui -- the page's parts, once built

-- value, default, and flags ({ account, character, readOnly, secure }) for one CVar.
local function read(name)
    if C_CVar.GetCVarInfo then
        local value, default, account, character, locked, secure, readOnly = C_CVar.GetCVarInfo(name)
        return value, default, {
            account = account,
            character = character,
            readOnly = locked or readOnly,
            secure = secure,
        }
    end
    return C_CVar.GetCVar(name), C_CVar.GetCVarDefault and C_CVar.GetCVarDefault(name), {}
end

local function isReadOnly(name)
    local _, _, flags = read(name)
    return flags.readOnly
end

-- Every CVar this client lists that the player can change (read-only ones are left out). Without
-- the list, typing an exact name still finds a CVar.
local function loadAll()
    all = {}
    if not getAllCommands then
        return
    end
    local cvarType = Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar or 0
    for _, info in ipairs(getAllCommands() or {}) do
        local name = info.command
        if info.commandType == cvarType and type(name) == "string" and name ~= ""
            and not isReadOnly(name) then
            local key = strlower(name)
            if not byKey[key] then
                local help = info.help or ""
                local entry = { name = name, key = key, help = help, text = key .. " " .. strlower(help) }
                byKey[key] = entry
                all[#all + 1] = entry
            end
        end
    end
    sort(all, function(a, b) return a.key < b.key end)
end

local function isChanged(name)
    local value, default = read(name)
    return default ~= nil and value ~= default
end

-- Lists the CVars that match the search (and "Changed Only"), keeping the scroll position.
local function refresh()
    if not ui then
        return
    end
    local query = strlower(search)
    local rows = {}
    for _, entry in ipairs(all) do
        if (query == "" or strfind(entry.text, query, 1, true)) and not (changedOnly and not isChanged(entry.name)) then
            rows[#rows + 1] = entry
        end
    end
    -- An exact name the list doesn't have (a hidden CVar, or no command list) still shows, first,
    -- unless it's read-only.
    if query ~= "" and not byKey[query] and C_CVar.GetCVar(search) ~= nil and not isReadOnly(search)
        and not (changedOnly and not isChanged(search)) then
        tinsert(rows, 1, { name = search, key = query, help = "", text = query })
    end
    ui.scrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
    ui.count:SetText(format(L.CVARBROWSER_COUNT, #rows, #all))
end

local function apply(name, value)
    if InCombatLockdown() then
        ns.Print(format(L.CVARBROWSER_AFTER_COMBAT, name))
    end
    ns.CVars.Apply(name, value, function(ok)
        if not ok then
            ns.Print(format(L.CVARBROWSER_REFUSED, name))
        end
        refresh()
    end)
end

-- Rows -----------------------------------------------------------------------------------------

local function showTooltip(row)
    local entry = row.entry
    local value, default, flags = read(entry.name)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.name, 1, 1, 1)
    if entry.help ~= "" then
        GameTooltip:AddLine(entry.help, nil, nil, nil, true)
    end
    GameTooltip:AddLine(format(L.CVARBROWSER_VALUE_IS, tostring(value)), 0.8, 0.8, 0.8)
    if default ~= nil then
        GameTooltip:AddLine(format(L.CVARBROWSER_DEFAULT_IS, default), 0.8, 0.8, 0.8)
    end
    if flags.account then
        GameTooltip:AddLine(L.CVARBROWSER_ACCOUNT, 0.6, 0.6, 0.6)
    elseif flags.character then
        GameTooltip:AddLine(L.CVARBROWSER_CHARACTER, 0.6, 0.6, 0.6)
    end
    if flags.readOnly then
        GameTooltip:AddLine(L.CVARBROWSER_READ_ONLY, 1, 0.3, 0.3)
    elseif flags.secure then
        GameTooltip:AddLine(L.CVARBROWSER_SECURE, 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

local function hideTooltip()
    GameTooltip:Hide()
end

local function buildRow(row)
    row:EnableMouse(true)
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(1, 1, 1, 0.08)
    row.highlight:Hide()

    row.reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.reset:SetSize(RESET_WIDTH, 22)
    row.reset:SetPoint("RIGHT", -4, 0)
    row.reset:SetText(L.CVARBROWSER_DEFAULT)
    row.reset:SetScript("OnClick", function()
        local _, default = read(row.entry.name)
        if default ~= nil then
            apply(row.entry.name, default)
        end
    end)

    row.default = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.default:SetPoint("RIGHT", DEFAULT_RIGHT, 0)
    row.default:SetWidth(DEFAULT_WIDTH)
    row.default:SetJustifyH("LEFT")
    row.default:SetWordWrap(false)

    row.value = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.value:SetSize(VALUE_WIDTH, 20)
    row.value:SetPoint("RIGHT", VALUE_RIGHT, 0)
    row.value:SetAutoFocus(false)
    row.value:HookScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local value = read(row.entry.name)
        local text = self:GetText()
        if text ~= value then
            apply(row.entry.name, text)
        end
    end)
    -- Leaving the box without Enter drops the edit.
    row.value:HookScript("OnEditFocusLost", function(self)
        self:SetText(tostring(read(row.entry.name) or ""))
        self:SetCursorPosition(0)
    end)
    row.value:HookScript("OnEnter", function() showTooltip(row) end)
    row.value:HookScript("OnLeave", hideTooltip)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", 6, 0)
    row.name:SetPoint("RIGHT", row.value, "LEFT", -GAP - 6, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row:SetScript("OnEnter", function(self)
        self.highlight:Show()
        showTooltip(self)
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        hideTooltip()
    end)
end

local function initRow(row, entry)
    if not row.value then
        buildRow(row)
    end
    row.entry = entry
    local value, default, flags = read(entry.name)
    local changed = default ~= nil and value ~= default
    row.name:SetText(entry.name)
    if flags.readOnly then
        row.name:SetTextColor(0.5, 0.5, 0.5)
    elseif changed then
        row.name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    else
        row.name:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end
    if not row.value:HasFocus() then
        row.value:SetText(tostring(value or ""))
        row.value:SetCursorPosition(0)
    end
    if row.value.SetEnabled then
        row.value:SetEnabled(not flags.readOnly)
    end
    row.default:SetText(default or "")
    row.reset:SetEnabled(changed and not flags.readOnly)
end

-- Page -----------------------------------------------------------------------------------------

-- CVAR_UPDATE comes in bursts (the game's Settings can change dozens at once), and each refresh
-- goes through every CVar, so a burst refreshes once, on the next frame.
local refreshQueued = false

local function queuedRefresh()
    refreshQueued = false
    refresh()
end

local function onCVarUpdate()
    if not refreshQueued then
        refreshQueued = true
        C_Timer.After(0, queuedRefresh)
    end
end

-- Follows changes made anywhere (the game's own settings, other addons) while the page is open.
local function listen(on)
    if on == listening then
        return
    end
    listening = on
    if on then
        ns.On("CVAR_UPDATE", onCVarUpdate)
    else
        ns.Off("CVAR_UPDATE", onCVarUpdate)
    end
end

-- A column title above the list, `x` from its left or right edge (`side`), like the rows.
local function header(parent, text, side, x)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOMLEFT", parent, "TOP" .. side, x, 4)
    label:SetText(text)
    return label
end

---Draws the page the first time it's shown (called by Settings.lua).
---@param frame table the empty page
function module:BuildPage(frame)
    loadAll()
    ui = {}

    ns.AddPageTitle(frame, module.title)

    local list = CreateFrame("Frame", nil, frame)
    list:SetPoint("TOPLEFT", 0, -58)
    list:SetPoint("BOTTOMRIGHT")
    ui.list = list

    local searchBox = CreateFrame("EditBox", nil, list, "SearchBoxTemplate")
    searchBox:SetSize(240, 20)
    searchBox:SetPoint("TOPLEFT", 16, -6)
    searchBox:SetText(search)
    searchBox:HookScript("OnTextChanged", function(self)
        search = strtrim(self:GetText() or "")
        refresh()
    end)
    ui.search = searchBox

    local changed = CreateFrame("CheckButton", nil, list, "UICheckButtonTemplate")
    changed:SetSize(26, 26)
    changed:SetPoint("LEFT", searchBox, "RIGHT", 12, 0)
    changed:SetChecked(changedOnly)
    changed:SetScript("OnClick", function(self)
        changedOnly = self:GetChecked()
        refresh()
    end)
    local changedLabel = changed.text or changed.Text
    if changedLabel then
        changedLabel:SetFontObject("GameFontHighlight")
        changedLabel:SetText(L.CVARBROWSER_CHANGED_ONLY)
    end

    ui.count = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.count:SetPoint("TOPRIGHT", -28, -10)

    local scrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 8, -52)
    scrollBox:SetPoint("BOTTOMRIGHT", -28, 8)
    ui.scrollBox = scrollBox

    local scrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)

    header(scrollBox, L.CVARBROWSER_NAME, "LEFT", 6)
    header(scrollBox, L.CVARBROWSER_VALUE, "RIGHT", VALUE_RIGHT - VALUE_WIDTH)
    header(scrollBox, L.CVARBROWSER_DEFAULT, "RIGHT", DEFAULT_RIGHT - DEFAULT_WIDTH)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ROW_HEIGHT)
    view:SetElementInitializer("Frame", initRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    frame:HookScript("OnShow", function() listen(true); refresh() end)
    frame:HookScript("OnHide", function() listen(false) end)
    listen(frame:IsShown())
    refresh()
end

---Shows the page with `text` in the search box.
---@param text string
local function openWith(text)
    search = text
    if ui then
        ui.search:SetText(text) -- runs refresh() through OnTextChanged
    end
    if not ns.OpenSettings(module.name) then
        ns.Print(L.CVARBROWSER_NO_PAGE)
    end
end

ns.AddCommand("cvar", "[search]", L.CVARBROWSER_COMMAND, function(rest)
    openWith(strtrim(rest))
end)
