-- Profiler: a page under Forever++ in Settings that shows how much CPU each module takes, to find
-- what needs work. Record times every call into each module's code (Lib/Profiler.lua) until Stop;
-- the list shows the heaviest modules first, with their milliseconds a second, their worst single
-- frame, and how often they ran, beside the game's own numbers for Forever++ as a whole. Memory
-- can only be read for the whole addon. Nothing is timed until Record, and nothing is built until
-- the page is first shown; `/fpp profile` opens it.
local _, ns = ...

local ipairs, format, concat = ipairs, string.format, table.concat
local CreateFrame, C_Timer = CreateFrame, C_Timer
local L = ns.L
local Profiler = ns.Profiler

local module = ns.NewModule("Profiler", L.PROFILER_DESC, { enabled = true })
module.title = L.PROFILER_TITLE
module.alwaysOn = true -- a tool page; it costs nothing until it records

local ROWS = 20 -- the heaviest modules shown, as many as fit on the page
local ROW_HEIGHT = 18
local NAME_WIDTH = 280 -- the name column
local COLUMNS = { 400, 510, 610 } -- right edges of the three number columns, from the left
local INDENT = 16 -- a module's parts sit this far in, under it
local REFRESH = 1 -- seconds between updates while the page is open

local ui -- the page's parts, once built
local ticker

local function nameOf(key)
    if key == Profiler.SHARED then
        return L.PROFILER_SHARED
    end
    return key.label or key.title or key.name or "?"
end

local function newText(parent, template, x, y, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", template)
    if justify == "RIGHT" then
        text:SetPoint("TOPRIGHT", parent, "TOPLEFT", x, y)
    else
        text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
    text:SetJustifyH(justify or "LEFT")
    return text
end

-- A row of the list: the module's name, then its three numbers.
local function newRow(parent, y, template)
    local row = { name = newText(parent, template, 10, y), y = y }
    row.name:SetWidth(NAME_WIDTH)
    row.name:SetWordWrap(false)
    for i, x in ipairs(COLUMNS) do
        row[i] = newText(parent, template, x, y, "RIGHT")
    end
    return row
end

local function setRow(row, name, a, b, c)
    row.name:SetText(name or "")
    row[1]:SetText(a or "")
    row[2]:SetText(b or "")
    row[3]:SetText(c or "")
end

-- A module's row in white, or (`part`) one of its parts indented under it in gray.
local function showResult(row, result, part)
    local x = part and 10 + INDENT or 10
    row.name:SetPoint("TOPLEFT", row.name:GetParent(), "TOPLEFT", x, row.y)
    row.name:SetWidth(NAME_WIDTH - (x - 10))
    local color = part and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR
    for _, text in ipairs({ row.name, row[1], row[2], row[3] }) do
        text:SetTextColor(color.r, color.g, color.b)
    end
    setRow(row, part == "own" and L.PROFILER_OWN or nameOf(result.key), format("%.3f", result.perSecond),
        format("%.2f", result.peak), format("%.1f", result.callsPerSecond))
end

local function refresh()
    if not ui then
        return
    end
    local recording = Profiler.recording
    ui.record:SetText(recording and L.PROFILER_STOP or L.PROFILER_RECORD)
    local seconds = Profiler.Elapsed()
    if recording then
        ui.status:SetText(format(L.PROFILER_RECORDING, ns.Text.Clock(seconds or 0)))
    elseif seconds then
        ui.status:SetText(format(L.PROFILER_STOPPED, ns.Text.Clock(seconds)))
    else
        ui.status:SetText(L.PROFILER_IDLE)
    end

    local average, peak, memory = Profiler.AddOn()
    local parts = {}
    if average then
        parts[#parts + 1] = format(L.PROFILER_ADDON_CPU, average, peak or 0)
    end
    if memory then
        parts[#parts + 1] = format(L.PROFILER_ADDON_MEMORY, memory / 1024)
    end
    ui.addon:SetText(#parts > 0 and concat(parts, "  ") or "")

    -- Each module, then its parts under it and what it did besides them.
    local results = Profiler.Results()
    local lines = {}
    for _, result in ipairs(results) do
        lines[#lines + 1] = { result }
        for _, part in ipairs(result.parts or {}) do
            lines[#lines + 1] = { part, true }
        end
        if result.own then
            lines[#lines + 1] = { result.own, "own" }
        end
    end
    for i, row in ipairs(ui.rows) do
        local line = lines[i]
        if line then
            showResult(row, line[1], line[2])
        else
            setRow(row)
        end
    end
    ui.empty:SetShown(#results == 0)
    ui.more:SetShown(#lines > ROWS)
    if #lines > ROWS then
        ui.more:SetText(format(L.PROFILER_MORE, #lines - ROWS))
    end
end

local function startTicker()
    if not ticker then
        ticker = C_Timer.NewTicker(REFRESH, refresh)
    end
end

local function stopTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

---Draws the page the first time it's shown (called by Settings.lua).
---@param frame table the empty page
function module:BuildPage(frame)
    ui = { rows = {} }
    ns.AddPageTitle(frame, module.title)

    ui.reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    ui.reset:SetSize(96, 22)
    ui.reset:SetPoint("TOPRIGHT", -12, -19) -- where the Defaults button would be
    ui.reset:SetText(L.PROFILER_RESET)
    ui.reset:SetScript("OnClick", function()
        Profiler.Reset()
        refresh()
    end)

    ui.record = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    ui.record:SetSize(96, 22)
    ui.record:SetPoint("RIGHT", ui.reset, "LEFT", -8, 0)
    ui.record:SetScript("OnClick", function()
        if Profiler.recording then
            Profiler.Stop()
        else
            Profiler.Start()
        end
        refresh()
    end)

    ui.status = newText(frame, "GameFontHighlight", 10, -62)
    ui.addon = newText(frame, "GameFontHighlight", 10, -82)
    -- Under the totals, where it's always on the page however tall Settings is.
    ui.note = newText(frame, "GameFontDisableSmall", 10, -104)
    ui.note:SetWidth(COLUMNS[3] - 10)
    ui.note:SetText(L.PROFILER_NOTE)

    local top = -142
    local header = newRow(frame, top, "GameFontNormal")
    setRow(header, L.PROFILER_MODULE, L.PROFILER_PER_SECOND, L.PROFILER_PEAK, L.PROFILER_CALLS)
    for i = 1, ROWS do
        ui.rows[i] = newRow(frame, top - i * ROW_HEIGHT, "GameFontHighlightSmall")
    end
    ui.empty = newText(frame, "GameFontDisable", 10, top - ROW_HEIGHT)
    ui.empty:SetText(L.PROFILER_EMPTY)
    ui.more = newText(frame, "GameFontDisableSmall", 10, top - (ROWS + 1) * ROW_HEIGHT)

    frame:HookScript("OnShow", function()
        refresh()
        startTicker()
    end)
    frame:HookScript("OnHide", stopTicker)
    refresh()
    if frame:IsShown() then
        startTicker()
    end
end

ns.AddCommand("profile", "", L.PROFILER_COMMAND, function()
    if not ns.OpenSettings(module.name) then
        ns.Print(L.PROFILER_NO_PAGE)
    end
end)
