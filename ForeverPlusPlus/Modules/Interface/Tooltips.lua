-- Tooltips: colors unit and item tooltips so they say more at a glance. The border and name
-- follow the unit's class or how it feels about you, item borders follow quality, the guild,
-- level and class on a unit's lines get colors, a player's title shows in their name, and a line
-- says who the unit is targeting. Ideas from ManiaTip; none of its code. Off by default, a
-- player's item level and specialization (another player's by inspect, through ns.Inspect) and
-- health text on the health bar.
--
-- Every change is made after Blizzard builds the tooltip (TooltipDataProcessor post calls), on
-- Blizzard's own lines, except Quest Lines, which leaves the quest lines out as it's built (line
-- pre calls). Unit data can be secret, mostly in combat and instances: text we'd have to read is
-- left alone then, and colors that come back secret go straight to the setters.
local _, ns = ...

local _G, type, setmetatable, ipairs, pairs = _G, type, setmetatable, ipairs, pairs
local find, sub, byte, format, match = string.find, string.sub, string.byte, string.format, string.match
local Enum, C_Item, TooltipDataProcessor = Enum, C_Item, TooltipDataProcessor
local UnitExists, UnitClass, UnitLevel, UnitName = UnitExists, UnitClass, UnitLevel, UnitName
local UnitPVPName, UnitIsUnit, UnitReaction, UnitSelectionColor = UnitPVPName, UnitIsUnit, UnitReaction, UnitSelectionColor
local GetGuildInfo, GetCreatureDifficultyColor = GetGuildInfo, GetCreatureDifficultyColor
local GetQuestDifficultyColor, FACTION_BAR_COLORS = GetQuestDifficultyColor, FACTION_BAR_COLORS
local NORMAL_FONT_COLOR, TOOLTIP_DEFAULT_COLOR = NORMAL_FONT_COLOR, TOOLTIP_DEFAULT_COLOR
local FACTION_HORDE, FACTION_ALLIANCE = FACTION_HORDE, FACTION_ALLIANCE
local GameTooltip, InCombatLockdown = GameTooltip, InCombatLockdown
local UnitChannelInfo, C_Spell, select = UnitChannelInfo, C_Spell, select
local GetActionInfo, C_MountJournal, C_PetJournal = GetActionInfo, C_MountJournal, C_PetJournal
local tostring, unpack, pcall, concat, floor = tostring, unpack, pcall, table.concat, math.floor
local UnitGUID, UnitIsPlayer, GetAverageItemLevel = UnitGUID, UnitIsPlayer, GetAverageItemLevel
local UnitHealth, UnitHealthMax, UnitHealthPercent = UnitHealth, UnitHealthMax, UnitHealthPercent
local CurveConstants, AbbreviateLargeNumbers = CurveConstants, AbbreviateLargeNumbers

local L = ns.L
local readable = ns.IsReadable
local Units = ns.Units
local QuestieDB = ns.QuestieDB
local C_QuestLog = C_QuestLog
local colorCode = ns.Colors.Code

local module = ns.NewModule("Tooltips", L.TOOLTIPS_DESC, {
    enabled = true,
    border = "class", -- unit borders: "class" (players by class, others by reaction), "reaction", "off"
    itemBorder = true,
    nameColor = "class", -- unit names, same choices as border
    guildColor = "all", -- "mine" (your guild green), "all" (yours green, others gray), "off"
    levelColor = true,
    classColor = true,
    factionColor = true,
    friends = true,
    title = true,
    target = true,
    itemLevel = false, -- a player's average item level; another player's needs an inspect
    itemLevelColor = true, -- that number in the color of the quality most of their gear is
    spec = true, -- a player's talent tree with the most points
    talentPoints = true, -- with the specialization, the points in each tree
    healthText = "both", -- on the health bar: "off", "percent", "value", "both"
    hideInCombat = false, -- hide unit tooltips while in combat
    anchorCursor = false, -- tooltips at the mouse instead of the bottom right
    hideFishing = false, -- hide the bobber's tooltip while fishing
    hideClickHint = false, -- leave "<Right click for frame settings>" off unit frames' tooltips
    hideTabTooltip = false, -- hide the tooltip of a chat window's tab
    hideHealthBar = false, -- hide the health bar under unit tooltips
    questLines = "show", -- "show", "units" (hidden on unit tooltips), "all" (and on objects)
    dropChance = true, -- a quest item's drop chance after its objective line; needs QuestieDB
    nameIcon = true, -- an item's or spell's icon before its name
    classSide = true, -- a player's class and side on one row
    questCounts = false, -- a quest objective's count at the right edge
    scale = 100, -- percent
})
module.title = L.TOOLTIPS_TITLE
module.category = "interface"
-- Hide Right-Click Hints and Hide Chat Tab Tooltips
module.presets = { developer = { options = { hideClickHint = true, hideTabTooltip = true, hideFishing = true } } }

local UNIT_COLORS = {
    { "class", L.TOOLTIPS_COLOR_CLASS },
    { "reaction", L.TOOLTIPS_COLOR_REACTION },
    { "off", L.TOOLTIPS_COLOR_OFF },
}

module.options = {
    { key = "border", name = L.TOOLTIPS_BORDER, description = L.TOOLTIPS_BORDER_DESC,
        choices = UNIT_COLORS, section = L.TOOLTIPS_SECTION_BORDERS },
    { key = "itemBorder", name = L.TOOLTIPS_ITEM_BORDER, description = L.TOOLTIPS_ITEM_BORDER_DESC,
        section = L.TOOLTIPS_SECTION_BORDERS },
    { key = "nameColor", name = L.TOOLTIPS_NAME_COLOR, description = L.TOOLTIPS_NAME_COLOR_DESC,
        choices = UNIT_COLORS, section = L.TOOLTIPS_SECTION_TEXT },
    {
        key = "guildColor", name = L.TOOLTIPS_GUILD_COLOR, description = L.TOOLTIPS_GUILD_COLOR_DESC,
        section = L.TOOLTIPS_SECTION_TEXT,
        choices = {
            { "mine", L.TOOLTIPS_GUILD_COLOR_MINE },
            { "all", L.TOOLTIPS_GUILD_COLOR_ALL },
            { "off", L.TOOLTIPS_COLOR_OFF },
        },
    },
    { key = "levelColor", name = L.TOOLTIPS_LEVEL_COLOR, description = L.TOOLTIPS_LEVEL_COLOR_DESC,
        section = L.TOOLTIPS_SECTION_TEXT },
    { key = "classColor", name = L.TOOLTIPS_CLASS_COLOR, description = L.TOOLTIPS_CLASS_COLOR_DESC,
        section = L.TOOLTIPS_SECTION_TEXT },
    { key = "factionColor", name = L.TOOLTIPS_FACTION_COLOR,
        description = L.TOOLTIPS_FACTION_COLOR_DESC, section = L.TOOLTIPS_SECTION_TEXT },
    { key = "friends", name = L.TOOLTIPS_FRIENDS, description = L.TOOLTIPS_FRIENDS_DESC,
        section = L.TOOLTIPS_SECTION_TEXT, added = "1.0.2" },
    { key = "title", name = L.TOOLTIPS_PLAYER_TITLE, description = L.TOOLTIPS_PLAYER_TITLE_DESC,
        section = L.TOOLTIPS_SECTION_LINES },
    { key = "target", name = L.TOOLTIPS_TARGET, description = L.TOOLTIPS_TARGET_DESC,
        section = L.TOOLTIPS_SECTION_LINES },
    { key = "itemLevel", name = L.TOOLTIPS_ITEM_LEVEL, description = L.TOOLTIPS_ITEM_LEVEL_DESC,
        section = L.TOOLTIPS_SECTION_LINES, added = "1.10.0" },
    { key = "itemLevelColor", name = L.TOOLTIPS_ITEM_LEVEL_COLOR, description = L.TOOLTIPS_ITEM_LEVEL_COLOR_DESC,
        section = L.TOOLTIPS_SECTION_LINES, added = "1.10.0", requires = "itemLevel" },
    { key = "spec", name = L.TOOLTIPS_SPEC, description = L.TOOLTIPS_SPEC_DESC,
        section = L.TOOLTIPS_SECTION_LINES, added = "1.10.0" },
    { key = "talentPoints", name = L.TOOLTIPS_TALENT_POINTS, description = L.TOOLTIPS_TALENT_POINTS_DESC,
        section = L.TOOLTIPS_SECTION_LINES, requires = "spec", added = "1.10.0" },
    { key = "dropChance", name = L.TOOLTIPS_DROP_CHANCE, description = L.TOOLTIPS_DROP_CHANCE_DESC,
        section = L.TOOLTIPS_SECTION_LINES, added = "1.9.0",
        available = function() return QuestieDB.IsReady() end,
        needs = format(L.SETTINGS_NEEDS_ADDON, "QuestieDB") },
    { key = "nameIcon", name = L.TOOLTIPS_NAME_ICON, description = L.TOOLTIPS_NAME_ICON_DESC,
        section = L.TOOLTIPS_SECTION_TIDY, added = "1.10.0" },
    { key = "classSide", name = L.TOOLTIPS_CLASS_SIDE, description = L.TOOLTIPS_CLASS_SIDE_DESC,
        section = L.TOOLTIPS_SECTION_TIDY, added = "1.10.0" },
    { key = "questCounts", name = L.TOOLTIPS_QUEST_COUNTS, description = L.TOOLTIPS_QUEST_COUNTS_DESC,
        section = L.TOOLTIPS_SECTION_TIDY, added = "1.10.0" },
    { key = "scale", name = L.TOOLTIPS_SCALE, description = L.TOOLTIPS_SCALE_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "1.8.0",
        min = 50, max = 200, step = 10, format = "%d%%" },
    { key = "anchorCursor", name = L.TOOLTIPS_ANCHOR_CURSOR, description = L.TOOLTIPS_ANCHOR_CURSOR_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR },
    { key = "hideInCombat", name = L.TOOLTIPS_HIDE_IN_COMBAT, description = L.TOOLTIPS_HIDE_IN_COMBAT_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR },
    { key = "hideFishing", name = L.TOOLTIPS_HIDE_FISHING, description = L.TOOLTIPS_HIDE_FISHING_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "1.6.0" },
    { key = "hideClickHint", name = L.TOOLTIPS_HIDE_CLICK_HINT, description = L.TOOLTIPS_HIDE_CLICK_HINT_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "1.6.0" },
    { key = "hideTabTooltip", name = L.TOOLTIPS_HIDE_TAB_TOOLTIP,
        description = L.TOOLTIPS_HIDE_TAB_TOOLTIP_DESC, section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "1.8.0" },
    {
        key = "healthText", name = L.TOOLTIPS_HEALTH_TEXT, description = L.TOOLTIPS_HEALTH_TEXT_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "1.10.0",
        choices = {
            { "off", L.TOOLTIPS_HEALTH_TEXT_OFF },
            { "percent", L.TOOLTIPS_HEALTH_TEXT_PERCENT },
            { "value", L.TOOLTIPS_HEALTH_TEXT_VALUE },
            { "both", L.TOOLTIPS_HEALTH_TEXT_BOTH },
        },
        conflicts = {
            { key = "hideHealthBar", text = L.TOOLTIPS_HEALTH_TEXT_CONFLICT,
                when = function(db) return db.healthText ~= "off" and db.hideHealthBar end },
        },
    },
    { key = "hideHealthBar", name = L.TOOLTIPS_HIDE_HEALTH_BAR,
        description = L.TOOLTIPS_HIDE_HEALTH_BAR_DESC, section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "0.9.0" },
    {
        key = "questLines", name = L.TOOLTIPS_QUEST_LINES, description = L.TOOLTIPS_QUEST_LINES_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR, added = "1.2.1",
        choices = {
            { "show", L.TOOLTIPS_QUEST_LINES_SHOW },
            { "units", L.TOOLTIPS_QUEST_LINES_UNITS },
            { "all", L.TOOLTIPS_QUEST_LINES_ALL },
        },
    },
}

local GUILDMATE_COLOR = ns.Colors.GUILD_GREEN -- as on Player Nameplates
local GUILD_COLOR = ns.Colors.GRAY
local YOU_COLOR = ns.Colors.RED

-- Text and colors -----------------------------------------------------------------------------

local leftLine = ns.Text.LeftLine

-- The text Blizzard put on line `i`, from the tooltip's data rather than the font string, or
-- nil when it's missing or secret.
local function lineText(data, i)
    local lineData = data.lines[i]
    local text = lineData and lineData.leftText
    if ns.IsText(text) then
        return text
    end
end

-- The tooltip's left font string for data line `i`. Blizzard numbers each line it adds
-- (lineData.lineIndex); after a line left out (Quest Lines, or another addon's line pre call),
-- the tooltip's lines no longer match their place in the data. When the first line has a number
-- and this one hasn't, it was left out: nil.
local function dataLine(tooltip, data, i)
    local lineData, first = data.lines[i], data.lines[1]
    local index = lineData and lineData.lineIndex
    if ns.IsNumber(index) then
        return leftLine(tooltip, index)
    end
    if lineData and not (first and ns.IsNumber(first.lineIndex)) then
        return leftLine(tooltip, i)
    end
end

-- Whether the byte at `i` is an ASCII letter or digit, so a match there runs into a longer word.
local function wordByte(text, i)
    local c = byte(text, i)
    return c and ((c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122))
end

-- Where `word` first stands alone in `text`. A plain search with the edges checked by hand, since
-- %w and %f only know ASCII and would never match a Russian or Korean class name.
local function findWord(text, word)
    local start = 1
    while true do
        local first, last = find(text, word, start, true)
        if not first then
            return
        end
        if not wordByte(text, first - 1) and not wordByte(text, last + 1) then
            return first, last
        end
        start = first + 1
    end
end

-- `text` with the first match of `pattern` (or of `word`, standing alone) wrapped in a color, and
-- whether it matched. The |r goes back to the line's own color.
local function colorMatch(text, pattern, r, g, b, word)
    local first, last
    if word then
        first, last = findWord(text, word)
    else
        first, last = find(text, pattern)
    end
    if not first then
        return text, false
    end
    return sub(text, 1, first - 1) .. colorCode(r, g, b) .. sub(text, first, last) .. "|r" .. sub(text, last + 1), true
end

-- The unit's class color, or nil when it isn't a player or its class can't be read.
local classColor = ns.Colors.PlayerClass

-- true and r, g, b for the unit in `mode` ("class" or "reaction"), or nothing. The first value
-- is only there to test: the colors may be secret, so they can't be.
local function unitColor(unit, mode)
    if mode == "class" then
        local color = classColor(unit)
        if color then
            return true, color:GetRGB()
        end
    end
    -- Probe: UnitSelectionColor is the color Blizzard gives the unit's name and selection circle,
    -- and may come back secret. Without it, the reputation bar colors by reaction.
    if UnitSelectionColor then
        return true, UnitSelectionColor(unit, true)
    end
    local reaction = UnitReaction(unit, "player")
    local color = readable(reaction) and reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
    if color then
        return true, color.r, color.g, color.b
    end
end

-- The color for a unit of `level` against the player's, as quest levels are colored.
local function levelColor(level)
    if level <= 0 then
        local own = UnitLevel("player")
        if not (ns.IsNumber(own)) then
            return nil
        end
        level = own + 10 -- "??": far above the player
    end
    local getColor = GetCreatureDifficultyColor or GetQuestDifficultyColor
    return getColor and getColor(level)
end

-- Border -------------------------------------------------------------------------------------

local colored = setmetatable({}, { __mode = "k" }) -- tooltip -> true while we colored its border
local clearHooked = setmetatable({}, { __mode = "k" }) -- tooltip -> true

local function resetBorder(tooltip)
    if colored[tooltip] then
        colored[tooltip] = nil
        if TOOLTIP_DEFAULT_COLOR then
            tooltip.NineSlice:SetBorderColor(TOOLTIP_DEFAULT_COLOR:GetRGB())
        else
            tooltip.NineSlice:SetBorderColor(1, 1, 1)
        end
    end
end

local function setBorder(tooltip, r, g, b)
    local slice = tooltip.NineSlice
    if not (slice and slice.SetBorderColor) or tooltip.IsEmbedded then
        return -- tooltips inside other tooltips use their parent's border
    end
    if not clearHooked[tooltip] then
        clearHooked[tooltip] = true
        tooltip:HookScript("OnTooltipCleared", resetBorder)
    end
    colored[tooltip] = true
    slice:SetBorderColor(r, g, b)
end

-- Unit tooltips ------------------------------------------------------------------------------

-- The unit the tooltip shows, or nil when it can't tell.
local function tooltipUnit(tooltip)
    if not tooltip.GetUnit then
        return nil
    end
    local _, unit = tooltip:GetUnit()
    if not ns.IsText(unit) then
        return nil
    end
    local exists = UnitExists(unit)
    if readable(exists) and exists then
        return unit
    end
end

-- Puts the title in the name when Blizzard's line is only the name.
local function addTitle(tooltip, data, unit)
    local shown, name = lineText(data, 1), UnitName(unit)
    local full = UnitPVPName and UnitPVPName(unit)
    if shown and readable(name) and readable(full) and full and shown == name and full ~= name then
        local line = leftLine(tooltip, 1)
        if line then
            line:SetText(full)
        end
    end
end

-- Colors the <Guild> line and returns its number, so the level search skips it.
local function colorGuild(tooltip, data, unit)
    local guild = GetGuildInfo(unit)
    if not (readable(guild) and guild) then
        return nil
    end
    for i = 2, 4 do
        local text = lineText(data, i)
        if text and find(text, guild, 1, true) then
            local mode, color = module.db.guildColor, nil
            if mode ~= "off" and Units.IsGuildmate(unit) then
                color = GUILDMATE_COLOR
            elseif mode == "all" then
                color = GUILD_COLOR
            end
            local line = color and dataLine(tooltip, data, i)
            if line then
                line:SetTextColor(color[1], color[2], color[3])
            end
            return i
        end
    end
end

-- Colors the level by difficulty and the class name by class, on the level line (and the line
-- after it, where Mainline puts a player's specialization and class).
local function colorLevelLine(tooltip, data, unit, guildLine)
    local db = module.db
    local level = UnitLevel(unit)
    if not (ns.IsNumber(level)) then
        return
    end
    local levelPattern = level > 0 and "%f[%d]" .. level .. "%f[%D]" or "%?%?"
    local className = db.classColor and UnitClass(unit)
    local class = classColor(unit)
    local classWord = readable(className) and className ~= "" and class and className
    for i = 2, #data.lines do
        local text = i ~= guildLine and lineText(data, i)
        if text and find(text, levelPattern) then
            local changed, found = false, nil
            if db.levelColor then
                local color = levelColor(level)
                if color then
                    text, changed = colorMatch(text, levelPattern, color.r, color.g, color.b)
                end
            end
            if classWord then
                local r, g, b = class:GetRGB()
                text, found = colorMatch(text, nil, r, g, b, classWord)
                changed = changed or found
                local nextText = not found and lineText(data, i + 1)
                if nextText then
                    local nextLine = dataLine(tooltip, data, i + 1)
                    nextText, found = colorMatch(nextText, nil, r, g, b, classWord)
                    if found and nextLine then
                        nextLine:SetText(nextText)
                    end
                end
            end
            local line = changed and dataLine(tooltip, data, i)
            if line then
                line:SetText(text)
            end
            return
        end
    end
end

-- Colors the "Horde" or "Alliance" line Blizzard adds to a unit, in the side's color, as on maps.
local function colorFaction(tooltip, data)
    for i = 2, #data.lines do
        local text = lineText(data, i)
        local side = text and (text == FACTION_HORDE and "H" or text == FACTION_ALLIANCE and "A")
        local line = side and dataLine(tooltip, data, i)
        if line then
            local color = ns.Colors.Faction(side)
            line:SetTextColor(color.r, color.g, color.b)
            return
        end
    end
end

-- Adds "Target: <name>", or "Target: You", colored like names.
local function addTarget(tooltip, unit)
    local target = unit .. "target"
    local exists = UnitExists(target)
    if not (readable(exists) and exists) then
        return
    end
    local lr, lg, lb = NORMAL_FONT_COLOR:GetRGB()
    local isPlayer = UnitIsUnit(target, "player")
    if readable(isPlayer) and isPlayer then
        tooltip:AddDoubleLine(L.TOOLTIPS_TARGET_LINE, L.TOOLTIPS_TARGET_YOU, lr, lg, lb,
            YOU_COLOR[1], YOU_COLOR[2], YOU_COLOR[3])
        return
    end
    local ok, r, g, b = unitColor(target, "class")
    if not ok then
        r, g, b = 1, 1, 1
    end
    -- The name may be secret; it goes straight to the tooltip.
    tooltip:AddDoubleLine(L.TOOLTIPS_TARGET_LINE, UnitName(target), lr, lg, lb, r, g, b)
end

-- Item Level and Specialization: lines from what a player wears and where their talent points
-- are. The player's own come from the game straight away; another player's need the server's
-- answer to an inspect (ns.Inspect), so they're added when it comes, if the tooltip still shows
-- that player, and from the kept answer on every tooltip after. Each tab's name is the game's.
local function addInspectLines(tooltip, entry)
    local db = module.db
    if db.itemLevel and ns.IsNumber(entry.itemLevel) then
        -- In the color of the quality most of their gear is, as an item's name is colored.
        local color = ns.Colors.Quality(db.itemLevelColor and entry.quality or nil)
        tooltip:AddDoubleLine(L.TOOLTIPS_ITEM_LEVEL_LINE, tostring(entry.itemLevel), 1, 1, 1,
            color.r, color.g, color.b)
    end
    local best, total = nil, 0
    if db.spec and entry.tabs then
        best, total = ns.Talents.Dominant(nil, entry.tabs)
    end
    if best and total > 0 and best.name ~= "" then
        local text = best.name
        if db.talentPoints then
            local points = {}
            for i, tab in ipairs(entry.tabs) do
                points[i] = tab.spent
            end
            local gray = ns.Colors.GRAY
            text = text .. " " .. colorCode(gray[1], gray[2], gray[3]) .. "(" .. concat(points, "/") .. ")|r"
        end
        tooltip:AddDoubleLine(L.TOOLTIPS_SPEC_LINE, text, 1, 1, 1, 1, 1, 1)
    end
end

-- The player's own item level and talents, read now.
local function ownEntry()
    local level
    if GetAverageItemLevel then
        local overall, equipped = GetAverageItemLevel()
        level = ns.IsNumber(equipped) and equipped or overall
    end
    return {
        itemLevel = ns.IsNumber(level) and level > 0 and floor(level) or nil,
        quality = ns.Inspect.UnitQuality("player"),
        tabs = ns.Talents.Tabs(),
    }
end

-- The server's answer for a player pointed at: drawn on GameTooltip while it still shows them.
local function onInspected(entry, guid)
    if not (module.enabled and entry and GameTooltip:IsShown()) then
        return
    end
    local unit = tooltipUnit(GameTooltip)
    local shown = unit and UnitGUID(unit)
    if readable(shown) and shown == guid then
        addInspectLines(GameTooltip, entry)
        GameTooltip:Show() -- sizes itself again for the new lines
    end
end

local function inspectLines(tooltip, unit)
    local isPlayer = UnitIsPlayer(unit)
    if not (readable(isPlayer) and isPlayer) then
        return
    end
    local isSelf = UnitIsUnit(unit, "player")
    if not readable(isSelf) then
        return
    end
    if isSelf then
        addInspectLines(tooltip, ownEntry())
        return
    end
    local guid = UnitGUID(unit)
    local entry = readable(guid) and guid and ns.Inspect.Get(guid)
    if not entry and tooltip == GameTooltip then
        entry = ns.Inspect.Request(unit, onInspected)
    end
    if entry then
        addInspectLines(tooltip, entry)
    end
end

-- Health Text: a font string of ours on GameTooltip's health bar, with the health of the unit the
-- tooltip shows. Blizzard fills the bar from the unit's GUID every frame (GameTooltipUnitHealthBarMixin,
-- Blizzard_GameTooltip/Mainline/GameTooltip.lua), so the text is written again whenever its value
-- changes. Health is secret in combat and instances: it only ever goes to SetFormattedText, which
-- takes a secret, and to the game's own percent and number helpers, under pcall in case this
-- client's don't take one (as Druid Mana Bar does). Nothing here is compared or added up.
local healthString -- made the first time the option is on
local healthUnit -- the unit GameTooltip shows, while it shows one

local function setHealth(format, ...)
    local args = { ... }
    local short = AbbreviateLargeNumbers
    local done = short and pcall(function()
        local shown = {}
        for i, value in ipairs(args) do
            shown[i] = i <= 2 and short(value) or value
        end
        healthString:SetFormattedText(format, unpack(shown, 1, #args))
    end)
    if not done then
        healthString:SetFormattedText(format, unpack(args, 1, #args))
    end
end

local function updateHealthText()
    if not healthString then
        return
    end
    local mode = module.enabled and module.db.healthText or "off"
    local unit = healthUnit
    if mode == "off" or not unit then
        healthString:SetText("")
        return
    end
    local exists = UnitExists(unit)
    if not (readable(exists) and exists) then
        return -- the mouse has left the unit: the bar and its text are on their way out
    end
    local percentOk, percent = false, nil
    if mode ~= "value" then
        local scale = CurveConstants and CurveConstants.ScaleTo100
        if UnitHealthPercent and scale then
            percentOk, percent = pcall(UnitHealthPercent, unit, true, scale)
        end
    end
    if mode == "percent" then
        if percentOk then
            healthString:SetFormattedText("%.0f%%", percent)
        else
            healthString:SetText("")
        end
    elseif mode == "both" and percentOk then
        setHealth("%s / %s (%.0f%%)", UnitHealth(unit), UnitHealthMax(unit), percent)
    else
        setHealth("%s / %s", UnitHealth(unit), UnitHealthMax(unit))
    end
end

local function healthTextFor(unit)
    healthUnit = unit
    if not healthString and module.db.healthText ~= "off" then
        local bar = GameTooltip.StatusBar
        if not bar then
            return
        end
        healthString = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        healthString:SetPoint("CENTER", bar, "CENTER", 0, 0)
        module:HookScript(bar, "OnValueChanged", updateHealthText)
    end
    updateHealthText()
end

local function clearHealthText()
    healthUnit = nil
    if healthString then
        healthString:SetText("")
    end
end

-- Hide in Combat fades GameTooltip rather than hiding it: Hide would run Blizzard's OnHide from
-- our code, mid-processing and in combat, and taint the next tooltip. The next tooltip or its
-- hiding brings it back.
local faded = false

local function unfade()
    if faded then
        faded = false
        GameTooltip:SetAlpha(1)
    end
end

-- Hide Bobber Tooltip: while Fishing channels, the thing under the mouse is the bobber, and its
-- tooltip (worse at the cursor, with Anchor to Cursor) sits over it just when it's watched for the
-- splash. Any rank of Fishing counts, by the spell's name.
local FISHING = ns.Data.Spell("FISHING")

local function fishing()
    local spellID = select(8, UnitChannelInfo("player"))
    if not ns.IsNumber(spellID) then
        return false
    end
    local name = C_Spell.GetSpellName(spellID)
    return ns.IsText(name) and name == C_Spell.GetSpellName(FISHING)
end

-- Hide Right-Click Hint: a unit frame's tooltip (player, target, focus, party, raid) ends with a
-- blank line and "<Right click for frame settings>", added by UnitFrame_UpdateTooltip after the
-- unit's own lines, not as tooltip data, so no line pre call can leave them out (wow-ui-source,
-- forever branch, Blizzard_UnitFrame/Mainline/UnitFrame.lua). After it has run, the tooltip is
-- filled again with the unit alone, as that function fills it, which drops the two lines.
local function dropClickHint(frame)
    if not module.db.hideClickHint or type(frame) ~= "table" or not frame.unit then
        return
    end
    if GameTooltip:IsOwned(frame) and GameTooltip:SetUnit(frame.unit, frame.hideStatusOnTooltip) then
        GameTooltip:Show()
    end
end

-- A chat tab's tooltip is its name and a green "<Right click for tab settings>", both added by
-- the tab's OnEnter and not as tooltip data (FloatingChatFrame.xml, ChatTabTemplate). After it has
-- run, the tooltip is set again to its first line alone. A tab's name is never secret here: the
-- tab of a whisper window whose name is, shows no tooltip of ours to change.
local function dropTabHint(tab)
    if not GameTooltip:IsOwned(tab) then
        return
    end
    -- Hide Chat Tab Tooltips: the whole tooltip, which only repeats the tab's name. Faded, as
    -- Hide in Combat fades one; the next tooltip or its hiding brings it back.
    if module.db.hideTabTooltip then
        faded = true
        GameTooltip:SetAlpha(0)
        return
    end
    if not module.db.hideClickHint then
        return
    end
    local line = leftLine(GameTooltip, 1)
    local title = line and line:GetText()
    if ns.IsText(title, true) and GameTooltip:NumLines() > 1 then
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:Show()
    end
end

-- Every chat window's tab, and those of windows added later.
local function hookTab(frame)
    local name = frame.GetName and frame:GetName()
    local tab = name and _G[name .. "Tab"]
    if tab then
        module:HookScript(tab, "OnEnter", dropTabHint)
    end
end

-- A world object's tooltip: the bobber's, while fishing.
local function onObject(tooltip)
    if module.db.hideFishing and tooltip == GameTooltip and fishing() then
        faded = true
        tooltip:SetAlpha(0)
    end
end

local function onUnit(tooltip, data)
    -- Hide in Combat: the mouseover tooltip only; tooltips the player opens stay.
    if module.db.hideInCombat and tooltip == GameTooltip and InCombatLockdown() then
        faded = true
        tooltip:SetAlpha(0)
        return
    end
    local unit = data and tooltipUnit(tooltip)
    if not unit then
        return
    end
    local db = module.db
    local lines = readable(data.lines) and type(data.lines) == "table"
    if lines and db.title then
        addTitle(tooltip, data, unit)
    end
    if db.nameColor ~= "off" then
        local ok, r, g, b = unitColor(unit, db.nameColor)
        local line = ok and leftLine(tooltip, 1)
        if line then
            line:SetTextColor(r, g, b)
        end
    end
    if db.border ~= "off" then
        local ok, r, g, b = unitColor(unit, db.border)
        if ok then
            setBorder(tooltip, r, g, b)
        end
    end
    if lines then
        colorLevelLine(tooltip, data, unit, colorGuild(tooltip, data, unit))
        if db.factionColor then
            colorFaction(tooltip, data)
        end
    end
    if db.itemLevel or db.spec then
        inspectLines(tooltip, unit)
    end
    if db.target then
        addTarget(tooltip, unit)
    end
    if tooltip == GameTooltip and (healthString or db.healthText ~= "off") then
        healthTextFor(unit)
    end
end

-- Friends list tooltips ----------------------------------------------------------------------

-- Forever's friends list is the Social window's (docs/forever-api.md), whose cards build a plain
-- GameTooltip with no tooltip data: the account name, then for a WoW character its name, "Level 17
-- Shaman", race, zone, and side (FriendsListSocialCardMixin:BuildTooltip, Gethe `forever` branch,
-- checked 2026-11-05). So it's recolored after it shows, finding Blizzard's lines by the text it
-- built from the card's own friend info. Battle.net friend info isn't secret.

-- The friend info of the Social window card that owns the tooltip, or nil for any other owner.
local function friendCardInfo(tooltip)
    local mixin = _G.FriendsListSocialCardMixin
    local owner = mixin and tooltip:GetOwner()
    if not (owner and owner.BuildTooltip == mixin.BuildTooltip) then
        return nil
    end
    local data = owner.elementData
    local info = data and data.accountInfo
    local game = info and info.gameAccountInfo
    if game and game.isOnline and ns.IsText(game.characterName, true) and ns.IsText(game.className, true)
        and ns.IsNumber(game.characterLevel) then
        return game
    end
end

-- The tooltip's line `i` and its text, when it's readable.
local function shownLine(tooltip, i)
    local line = leftLine(tooltip, i)
    local text = line and line:GetText()
    if ns.IsText(text) then
        return line, text
    end
end

local function onFriendTooltip(tooltip)
    local db = module.db
    local game = db.friends and friendCardInfo(tooltip)
    if not (game and FRIENDS_LEVEL_TEMPLATE) then
        return
    end
    local levelText = format(FRIENDS_LEVEL_TEMPLATE, game.characterLevel, game.className)
    for i = 2, tooltip:NumLines() do
        local line, text = shownLine(tooltip, i)
        if text == levelText then
            local class = ns.Colors.ClassToken(game.classFilename)
                or ns.Colors.ClassToken(ns.Players.ClassToken(game.className))
            local nameLine, nameText = shownLine(tooltip, i - 1)
            if class and db.nameColor ~= "off" and nameText and find(nameText, game.characterName, 1, true) then
                nameLine:SetTextColor(class:GetRGB())
            end
            -- A level against the player's means something only in this game.
            local color = db.levelColor and game.wowProjectID == WOW_PROJECT_ID and levelColor(game.characterLevel)
            local levelPattern = "%f[%d]" .. game.characterLevel .. "%f[%D]"
            if color then
                text = colorMatch(text, levelPattern, color.r, color.g, color.b)
            end
            if class and db.classColor then
                local r, g, b = class:GetRGB()
                text = colorMatch(text, nil, r, g, b, game.className)
            end
            line:SetText(text)
            -- Race and zone, then the side.
            local sideLine, side = shownLine(tooltip, i + 3)
            side = side and (side == FACTION_HORDE and "H" or side == FACTION_ALLIANCE and "A")
            if side and db.factionColor then
                local faction = ns.Colors.Faction(side)
                sideLine:SetTextColor(faction.r, faction.g, faction.b)
            end
            return
        end
    end
end

-- Item tooltips ------------------------------------------------------------------------------

-- Icon by Name: an item's or spell's icon before its name, at the height of the text. The name
-- is Blizzard's line (or a module's, with an upgrade arrow at its right), written again with the
-- icon in front. Its text comes from the tooltip's data, never the tooltip, and only when it can
-- be read.
local function nameIcon(tooltip, data, icon, known)
    local lines = readable(data.lines) and type(data.lines) == "table" and data.lines
    local first = lines and lines[1]
    -- The name from the tooltip's data, or the one the caller already has for a tooltip whose
    -- data doesn't hold it (a macro's).
    local name = first and first.leftText
    if not ns.IsText(name, true) then
        name = known
    end
    if not (icon and readable(icon) and ns.IsText(name, true)) then
        return
    end
    -- Blizzard numbers each line it adds. A name a module drew in its place has no number: it's
    -- the first line, except on a tooltip that opens with a line of its own ("Currently
    -- Equipped" on the ones that compare gear), which is left alone.
    local index = first and first.lineIndex
    if not ns.IsNumber(index) then
        if tooltip ~= GameTooltip and tooltip ~= _G.ItemRefTooltip then
            return
        end
        index = 1
    end
    local line = leftLine(tooltip, index)
    if line then
        line:SetText("|T" .. icon .. ":0|t " .. name)
    end
end

-- The icon of the spell, or else the item, called `name`: a spell the character knows and an
-- item the client has seen are found by name. Nil for a name that's neither, or can't be read.
local function iconByName(name)
    if not ns.IsText(name, true) then
        return nil
    end
    name = ns.Text.Plain(name)
    local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(name)
    if not icon and C_Item.GetItemInfoInstant then
        icon = select(5, C_Item.GetItemInfoInstant(name))
    end
    return icon
end

local function onSpell(tooltip, data)
    if not (module.db.nameIcon and data and C_Spell and C_Spell.GetSpellTexture) then
        return
    end
    local id = data.id
    if readable(id) and id then
        nameIcon(tooltip, data, C_Spell.GetSpellTexture(id))
    else
        -- A spell tooltip with no ID of its own (a macro's, on some clients): by its name.
        local lines = readable(data.lines) and type(data.lines) == "table" and data.lines
        nameIcon(tooltip, data, iconByName(lines and lines[1] and lines[1].leftText))
    end
end

-- A toy: an item with a tooltip kind of its own (seen in game 2026-11-26: a toy got no icon from
-- the item call). Its ID is the item's; failing that, the item is found by the tooltip's name.
local function onToy(tooltip, data)
    if not (module.db.nameIcon and data) then
        return
    end
    local id = data.id
    local icon = readable(id) and id and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
    if not icon then
        local lines = readable(data.lines) and type(data.lines) == "table" and data.lines
        icon = iconByName(lines and lines[1] and lines[1].leftText)
    end
    nameIcon(tooltip, data, icon)
end

-- After the game fills a tooltip with a toy, by its item: the same again from the item itself,
-- as onSetAction does for a macro, in case the toy tooltip's own post call changes nothing either.
local function onSetToy(tooltip, itemID)
    if not (module.db.nameIcon and readable(itemID) and itemID and C_Item.GetItemIconByID) then
        return
    end
    local icon = C_Item.GetItemIconByID(itemID)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    local line = leftLine(tooltip, 1)
    if line and icon and readable(icon) and ns.IsText(name, true) then
        line:SetText("|T" .. icon .. ":0|t " .. name)
        tooltip:Show()
    end
end

-- Writes the first line of a tooltip the game has just filled: `name` with `icon` in front. The
-- name is wider by its icon, so the tooltip sizes itself again.
local function writeName(tooltip, icon, name)
    local line = leftLine(tooltip, 1)
    if line and icon and readable(icon) and ns.IsText(name, true) then
        line:SetText("|T" .. icon .. ":0|t " .. name)
        tooltip:Show()
    end
end

-- A mount's icon and name from the spell that summons it: the journal's, or else the spell's own.
local function mountBySpell(spellID)
    local journal = C_MountJournal
    if journal and journal.GetMountFromSpell and journal.GetMountInfoByID then
        local mountID = journal.GetMountFromSpell(spellID)
        if mountID then
            local name, _, icon = journal.GetMountInfoByID(mountID)
            if icon then
                return icon, name
            end
        end
    end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID), C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
    end
end

-- A mount: one more tooltip kind of its own (seen in game 2026-11-26: no icon). After the game
-- fills the tooltip from the mount's spell, and from the mount tooltip's own post call, whose ID
-- may be the mount's or its spell's.
local function onSetMount(tooltip, spellID)
    if module.db.nameIcon and readable(spellID) and spellID then
        writeName(tooltip, mountBySpell(spellID))
    end
end

local function onMount(tooltip, data)
    if not (module.db.nameIcon and data) then
        return
    end
    local id = data.id
    local icon
    if readable(id) and id then
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            icon = select(3, C_MountJournal.GetMountInfoByID(id))
        end
        icon = icon or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)) or nil
    end
    if not icon then
        local lines = readable(data.lines) and type(data.lines) == "table" and data.lines
        icon = iconByName(lines and lines[1] and lines[1].leftText)
    end
    nameIcon(tooltip, data, icon)
end

-- A companion pet: the same, from the pet journal. A pet the player named shows that name.
local function onSetPet(tooltip, petID)
    if not (module.db.nameIcon and readable(petID) and petID and C_PetJournal and C_PetJournal.GetPetInfoByPetID) then
        return
    end
    local _, customName, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(petID)
    writeName(tooltip, icon, ns.IsText(customName, true) and customName or name)
end

local function onPet(tooltip, data)
    if not (module.db.nameIcon and data and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID) then
        return
    end
    local id = data.id
    if readable(id) and id then
        local _, icon = C_PetJournal.GetPetInfoBySpeciesID(id)
        nameIcon(tooltip, data, icon)
    end
end

-- When the tooltip shows: the icon again, for the kinds whose own post call leaves the name as it
-- was. A macro's did (only writing it after the game had finished with the tooltip worked), and a
-- mount's and a pet's did too (dumped in game 2026-11-26: types 10 and 9, and still no icon). The
-- game shows the tooltip as the last thing it does to it, so this is after everything. Each
-- tooltip's data gets it once; writing the name shows the tooltip again, which ends here.
local iconDone = setmetatable({}, { __mode = "k" }) -- tooltip -> the data it was last done for

local function onShowIcon(tooltip)
    if not (module.db.nameIcon and tooltip.GetPrimaryTooltipData) then
        return
    end
    local data = tooltip:GetPrimaryTooltipData()
    if type(data) ~= "table" or iconDone[tooltip] == data then
        return
    end
    local kind, id = data.type, data.id
    if not readable(kind) then
        return
    end
    local types = Enum.TooltipDataType
    local icon, name
    if kind == (types.Macro or 25) then
        local owner = tooltip.GetOwner and tooltip:GetOwner()
        local slot, shown, subType
        if type(owner) == "table" then
            slot, shown, subType = ns.ActionButtons.Content(owner)
        end
        if slot == "macro" and shown then
            if readable(subType) and subType == "item" then
                icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(shown)
                name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(shown)
            elseif C_Spell and C_Spell.GetSpellTexture then
                icon = C_Spell.GetSpellTexture(shown)
                name = C_Spell.GetSpellName and C_Spell.GetSpellName(shown)
            end
        end
    elseif kind == types.Toy then
        if readable(id) and id and C_Item.GetItemIconByID then
            icon = C_Item.GetItemIconByID(id)
            name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
        end
    elseif kind == types.Mount then
        -- The ID may be the mount's or its spell's: the journal is asked both ways.
        if readable(id) and id then
            if C_MountJournal and C_MountJournal.GetMountInfoByID then
                local mountName, _, mountIcon = C_MountJournal.GetMountInfoByID(id)
                icon, name = mountIcon, mountName
            end
            if not icon then
                icon, name = mountBySpell(id)
            end
        end
    elseif kind == types.CompanionPet then
        if readable(id) and id and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
            name, icon = C_PetJournal.GetPetInfoBySpeciesID(id)
        end
    else
        return
    end
    iconDone[tooltip] = data
    -- The name the tooltip shows, when its data has it: the game's own wording, a named pet's
    -- name. Then whatever shows it also finds its icon, when nothing above did.
    local lines = readable(data.lines) and type(data.lines) == "table" and data.lines
    local shownName = lines and lines[1] and lines[1].leftText
    if ns.IsText(shownName, true) then
        name = shownName
        -- A pet's tooltip has no ID on this client (dumped in game 2026-11-26: nil, with the
        -- pet's name on its first line): the journal finds the pet by that name.
        if not icon and kind == types.CompanionPet and C_PetJournal and C_PetJournal.FindPetIDByName
            and C_PetJournal.GetPetInfoBySpeciesID then
            local speciesID = C_PetJournal.FindPetIDByName(ns.Text.Plain(shownName))
            if speciesID then
                icon = select(2, C_PetJournal.GetPetInfoBySpeciesID(speciesID))
            end
        end
        icon = icon or iconByName(shownName)
    end
    writeName(tooltip, icon, name)
end

-- A buff or debuff: a spell with a tooltip kind of its own. Its ID can be secret in combat, and
-- then it gets no icon.
local function onAura(tooltip, data)
    if not (module.db.nameIcon and data and C_Spell and C_Spell.GetSpellTexture) then
        return
    end
    local id = data.id
    if readable(id) and id then
        nameIcon(tooltip, data, C_Spell.GetSpellTexture(id))
    end
end

-- A macro on an action bar that shows a spell's or item's tooltip (#showtooltip): its tooltip is a
-- macro's, not a spell's or item's, and what it shows is named on its first line. Probe: the
-- first line's tooltipType and tooltipID are how Mainline's own TooltipUtil tells which spell or
-- item a macro's tooltip displays; unseen on this client, so each is checked before it's used.
local function onMacro(tooltip, data)
    if not (module.db.nameIcon and data) then
        return
    end
    -- The action button the tooltip belongs to says what its macro shows: the slot's ID is that
    -- spell or item, not the macro (ActionButtons.Content). This client's macro tooltip data
    -- doesn't say (seen in game 2026-11-26: type 25, and Smart Buff's macro got no icon from it).
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if type(owner) == "table" then
        local kind, id, subType = ns.ActionButtons.Content(owner)
        if kind == "macro" and id then
            if readable(subType) and subType == "item" then
                if C_Item.GetItemIconByID then
                    nameIcon(tooltip, data, C_Item.GetItemIconByID(id),
                        C_Item.GetItemNameByID and C_Item.GetItemNameByID(id))
                end
                return
            elseif C_Spell and C_Spell.GetSpellTexture then
                local icon = C_Spell.GetSpellTexture(id)
                if icon then
                    nameIcon(tooltip, data, icon, C_Spell.GetSpellName and C_Spell.GetSpellName(id))
                    return
                end
            end
        end
    end
    local lines = readable(data.lines) and type(data.lines) == "table" and data.lines
    local first = lines and lines[1]
    local kind, id = first and first.tooltipType, first and first.tooltipID
    if readable(kind) and readable(id) and kind and id then
        if kind == Enum.TooltipDataType.Spell and C_Spell and C_Spell.GetSpellTexture then
            nameIcon(tooltip, data, C_Spell.GetSpellTexture(id))
            return
        elseif kind == Enum.TooltipDataType.Item and C_Item.GetItemIconByID then
            nameIcon(tooltip, data, C_Item.GetItemIconByID(id))
            return
        end
    end
    -- Not on an action bar: the tooltip's first line is the spell's or item's name.
    nameIcon(tooltip, data, iconByName(first and first.leftText))
end

-- After the game fills a tooltip from an action bar slot: a macro's again, from the slot itself.
-- The slot says "macro", the spell or item it shows, and which of the two (dumped in game
-- 2026-11-26: "macro", 11550, "spell" for Smart Buff's macro showing Battle Shout), and yet the
-- macro tooltip's own post call put no icon on it, so this doesn't lean on that call at all. The
-- name is written whole, so an icon already there isn't doubled.
local function onSetAction(tooltip, slot)
    if not (module.db.nameIcon and readable(slot) and slot and GetActionInfo) then
        return
    end
    local kind, id, subType = GetActionInfo(slot)
    if not (readable(kind) and readable(id) and kind == "macro" and id) then
        return
    end
    local icon, name
    if readable(subType) and subType == "item" then
        icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
        name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    elseif C_Spell and C_Spell.GetSpellTexture then
        icon = C_Spell.GetSpellTexture(id)
        name = C_Spell.GetSpellName and C_Spell.GetSpellName(id)
    end
    local line = leftLine(tooltip, 1)
    if line and icon and readable(icon) and ns.IsText(name, true) then
        line:SetText("|T" .. icon .. ":0|t " .. name)
        tooltip:Show() -- the name is wider by its icon: the tooltip sizes itself again
    end
end

-- Class and Side on One Row: a player's class line and the side line right after it go on one
-- row, class at the left and side at the right. Told from the tooltip's data as the game adds each
-- line, by the client's own class and side names, so it needs no unit; in combat, when the lines
-- can't be read, they stay as two.
local CLASS_TOKENS -- a class's name as the client writes it -> its token, made when first asked

local function classToken(text)
    if not CLASS_TOKENS then
        CLASS_TOKENS = {}
        for _, names in ipairs({ _G.LOCALIZED_CLASS_NAMES_MALE or {}, _G.LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
            for token, name in pairs(names) do
                CLASS_TOKENS[name] = token
            end
        end
    end
    return CLASS_TOKENS[text]
end

local classPairs = setmetatable({}, { __mode = "k" }) -- unit tooltip data -> { class line, side line, token, side }
local NO_PAIR = {}
local sideDrawn = setmetatable({}, { __mode = "k" }) -- tooltip -> the side line just drawn at the right

local function classPair(data)
    local found = classPairs[data]
    if found then
        return found ~= NO_PAIR and found or nil
    end
    found = NO_PAIR
    local lines = readable(data.lines) and type(data.lines) == "table" and data.lines or {}
    for i = 2, #lines - 1 do
        local text, nextText = lineText(data, i), lineText(data, i + 1)
        local token = text and classToken(text)
        local side = nextText and (nextText == FACTION_ALLIANCE and "A" or nextText == FACTION_HORDE and "H")
        if token and side then
            found = { lines[i], lines[i + 1], token, side }
            break
        end
    end
    classPairs[data] = found
    return found ~= NO_PAIR and found or nil
end

local function onAnyLine(tooltip, line)
    if sideDrawn[tooltip] == line then
        sideDrawn[tooltip] = nil
        return true -- it's at the right of the class line
    end
    if not (module.db.classSide and tooltip.GetProcessingTooltipInfo) then
        return
    end
    local info = tooltip:GetProcessingTooltipInfo()
    local data = info and info.tooltipData
    local kind = data and data.type
    if not (readable(kind) and kind == Enum.TooltipDataType.Unit) then
        return
    end
    local pair = classPair(data)
    if not (pair and pair[1] == line) then
        return
    end
    local db = module.db
    local r, g, b = 1, 1, 1
    local class = db.classColor and ns.Colors.ClassToken(pair[3])
    if class then
        r, g, b = class:GetRGB()
    end
    local r2, g2, b2 = 1, 1, 1
    if db.factionColor then
        local side = ns.Colors.Faction(pair[4])
        r2, g2, b2 = side.r, side.g, side.b
    end
    tooltip:AddDoubleLine(pair[1].leftText, pair[2].leftText, r, g, b, r2, g2, b2)
    sideDrawn[tooltip] = pair[2]
    return true
end

local function onItem(tooltip, data)
    if data and module.db.nameIcon and C_Item.GetItemIconByID then
        local id = ns.ItemTooltip.ItemID(data)
        if id then
            nameIcon(tooltip, data, C_Item.GetItemIconByID(id))
        end
    end
    if not (module.db.itemBorder and data and C_Item.GetItemQualityByID) then
        return
    end
    local item = ns.ItemTooltip.ItemID(data)
    if not item and readable(data.hyperlink) then
        item = data.hyperlink
    end
    -- A module that draws this item's border in a color of its own has the tooltip's too.
    if item then
        local r, g, b = ns.ItemTooltip.BorderColor(item)
        if r then
            setBorder(tooltip, r, g, b)
            return
        end
    end
    local quality = item and C_Item.GetItemQualityByID(item)
    if readable(quality) and quality and C_Item.GetItemQualityColor then
        local r, g, b = C_Item.GetItemQualityColor(quality)
        if r then
            setBorder(tooltip, r, g, b)
        end
    end
end

-- Anchor to Cursor: after Blizzard places a tooltip at its default spot (bottom right), move it
-- to the mouse instead.
local function onDefaultAnchor(tooltip, parent)
    -- Not with the controller interface on: there's no mouse, only wherever it was left.
    if module.db.anchorCursor and not ns.Gamepad.On() then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    end
end

-- Hide Health Bar: GameTooltip.StatusBar hangs under the tooltip and shows, hides, and fills
-- itself from a unit's GUID on every unit tooltip (GameTooltipUnitHealthBarMixin, with secure
-- methods because the health may be secret). Fading it leaves all of that to Blizzard: nothing
-- reads the bar, hooks it, or runs when it shows.
local function fadeHealthBar(hide)
    local bar = GameTooltip.StatusBar
    if bar then
        bar:SetAlpha(hide and 0 or 1)
    end
end

-- Scale: the tooltips the game shows by themselves, each scaled alone since none is the child of
-- another: the main one, the one a clicked item link opens, the two that compare gear, and the
-- one the controller interface shows a buff in by itself (BuffFrameTooltip). A tooltip's scale is
-- nobody else's, so at 100% they're left alone until we've changed one.
local SCALED = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "BuffFrameTooltip" }
local scaled = false

local function applyScale()
    local scale = module.enabled and module.db.scale or 100
    if scale == 100 and not scaled then
        return
    end
    scaled = scale ~= 100
    for _, name in ipairs(SCALED) do
        local tooltip = _G[name]
        if tooltip and tooltip.SetScale then
            tooltip:SetScale(scale / 100)
        end
    end
end

-- Quest Lines: true leaves a quest line (its title, an objective, or whose they are in a group) out
-- of a unit's tooltip, or an object's too, as the tooltip is built. Idea from NoQuestTooltips and
-- cyberox's Hide Quest Tooltips. Only the tooltip skips them: the data keeps them, so what reads
-- it (Quest Nameplates, through C_TooltipInfo) still sees them. The tooltip's type is never secret,
-- since Blizzard keys its own callback tables by it.
local QUEST_LINES = { "QuestTitle", "QuestObjective", "QuestPlayer" }

local function skipQuestLine(tooltip)
    local mode = module.db.questLines
    if mode == "show" or not tooltip.GetProcessingTooltipInfo then
        return false
    end
    local info = tooltip:GetProcessingTooltipInfo()
    local kind = info and info.tooltipData and info.tooltipData.type
    local types = Enum.TooltipDataType
    return kind == types.Unit or (mode == "all" and kind == types.Object)
end

-- Drop Chance: a creature's quest objective line for an item it drops, "0/1 Intact Hailstrider
-- Beak", gets the chance it drops it after it, "(35%)" in gray. The chances are the QuestieDB
-- addon's, Classic's numbers from Wowhead and CMaNGOS rather than measured on Forever, so an
-- estimate. The line is found by the item's name in it: the quest log's item objectives a creature
-- drops, by the creature, from QuestieDB's lists.
local dropQuests = {} -- quest ID -> QuestieDB.QuestDrops, or false; kept, since a quest's items don't change
local dropsByNpc -- NPC ID -> a list of QuestDrops' items, for the quests in the log; nil when stale
local dropRates = {} -- item ID -> QuestieDB.DropRates, or false
local ratesRead -- the drop table has been read: its first read is a large one, kept out of combat

local function staleDrops()
    dropsByNpc = nil
end

local function npcDrops(npcID)
    if not dropsByNpc then
        dropsByNpc = {}
        if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
            for index = 1, (C_QuestLog.GetNumQuestLogEntries()) do
                local info = C_QuestLog.GetInfo(index)
                local questID = info and not info.isHeader and info.questID
                if type(questID) == "number" then
                    local drops = dropQuests[questID]
                    if drops == nil then
                        drops = QuestieDB.QuestDrops(questID) or false
                        dropQuests[questID] = drops
                    end
                    for _, drop in ipairs(drops or {}) do
                        for npc in pairs(drop.npcs) do
                            local list = dropsByNpc[npc]
                            if not list then
                                list = {}
                                dropsByNpc[npc] = list
                            end
                            list[#list + 1] = drop
                        end
                    end
                end
            end
        end
    end
    return dropsByNpc[npcID]
end

-- "(35%)" for the item an objective line names, or nil when the creature drops none of it or
-- QuestieDB has no chance for it. A chance under 10 keeps a decimal.
local function dropChance(npcID, text)
    for _, drop in ipairs(npcDrops(npcID) or {}) do
        if drop.name and find(text, drop.name, 1, true) then
            local rates = dropRates[drop.itemID]
            if rates == nil then
                if not ratesRead and InCombatLockdown() then
                    return nil
                end
                rates = QuestieDB.DropRates(drop.itemID) or false
                ratesRead = true
                dropRates[drop.itemID] = rates
            end
            local chance = rates and rates[npcID]
            if chance and chance > 0 then
                local number = chance >= 9.95 and format("%d", chance + 0.5) or format("%.1f", chance)
                local gray = ns.Colors.GRAY
                return colorCode(gray[1], gray[2], gray[3]) .. format(L.TOOLTIPS_DROP_CHANCE_FORMAT, number) .. "|r"
            end
        end
    end
    return nil
end

-- An objective line: left out by Quest Lines, or added by us with its drop chance, or Blizzard's.
-- Blizzard's transparent texture, as a gap of a given width inside text.
local INDENT = "|TInterface\\Common\\spacer:1:%d|t"

-- A quest objective as its words and its count ("Tough Wolf Meat", "6 / 8"), from Blizzard's
-- "6/8 Tough Wolf Meat" or "Tough Wolf Meat: 6/8". Nothing for an objective written another way
-- (a percent, a single step): that one stays as Blizzard writes it.
local function objectiveParts(text)
    local plain = ns.Text.Plain(text)
    local have, need, words = match(plain, "^[%s%-]*(%d+)/(%d+)%s+(.+)$")
    if not have then
        words, have, need = match(plain, "^[%s%-]*(.-):%s*(%d+)/(%d+)%s*$")
    end
    if have and words and words ~= "" then
        return words, have .. " / " .. need
    end
end

local function questObjectiveLine(tooltip, line)
    if skipQuestLine(tooltip) then
        return true
    end
    local text = line and line.leftText
    if not ns.IsText(text, true) or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return false
    end
    local db = module.db
    -- The drop chance, on a creature's tooltip.
    local chance
    if db.dropChance and tooltip.GetProcessingTooltipInfo and QuestieDB.IsReady() then
        local info = tooltip:GetProcessingTooltipInfo()
        local data = info and info.tooltipData
        local npcID = data and data.type == Enum.TooltipDataType.Unit and Units.NpcID(data.guid)
        chance = npcID and dropChance(npcID, text) or nil
    end
    -- Counts at the Right: the objective's words at the left and its count at the right edge.
    local words, count
    if db.questCounts then
        words, count = objectiveParts(text)
    end
    if not (chance or words) then
        return false
    end
    local color = line.leftColor
    color = readable(color) and type(color) == "table" and color.r and color or NORMAL_FONT_COLOR
    if words then
        -- Blizzard indents an objective by its offset; a line with two sides takes none, so the
        -- same indent goes in as a gap in front of the words.
        local offset = line.leftOffset
        local indent = ns.IsNumber(offset) and offset > 0 and format(INDENT, offset) or "  "
        tooltip:AddDoubleLine(indent .. words .. (chance and (" " .. chance) or ""), count,
            color.r, color.g, color.b, color.r, color.g, color.b)
        return true
    end
    -- As Blizzard adds the line (TooltipDataHandlerMixin:AddLineDataText), with the chance after it.
    tooltip:AddLine(text .. " " .. chance, color.r, color.g, color.b, line.wrapText or false, line.leftOffset)
    return true
end

function module:OnEnable()
    -- Probe: line types and line pre calls are Mainline's.
    local lineTypes = Enum.TooltipDataLineType
    for _, name in ipairs(lineTypes and QUEST_LINES or {}) do
        self:TooltipLinePreCall(lineTypes[name], name == "QuestObjective" and questObjectiveLine or skipQuestLine)
    end
    self:On("QUEST_LOG_UPDATE", staleDrops)
    self:TooltipPostCall(Enum.TooltipDataType.Unit, onUnit)
    self:TooltipPostCall(Enum.TooltipDataType.Item, onItem)
    self:TooltipPostCall(Enum.TooltipDataType.Object, onObject)
    self:TooltipPostCall(Enum.TooltipDataType.Spell, onSpell)
    -- A macro's tooltip is type 25 on this client (dumped in game 2026-11-26), whether or not
    -- its Enum names it.
    self:TooltipPostCall(Enum.TooltipDataType.Macro or 25, onMacro)
    self:Hook(GameTooltip, "SetAction", onSetAction)
    self:TooltipPostCall(Enum.TooltipDataType.Toy, onToy)
    self:Hook(GameTooltip, "SetToyByItemID", onSetToy)
    self:TooltipPostCall(Enum.TooltipDataType.Mount, onMount)
    self:Hook(GameTooltip, "SetMountBySpellID", onSetMount)
    self:TooltipPostCall(Enum.TooltipDataType.CompanionPet, onPet)
    self:Hook(GameTooltip, "SetCompanionPet", onSetPet)
    self:Hook(GameTooltip, "Show", onShowIcon)
    self:TooltipPostCall(Enum.TooltipDataType.UnitAura, onAura)
    -- Probe: every line of every tooltip, for a player's class line.
    if TooltipDataProcessor and TooltipDataProcessor.AllTypes then
        self:TooltipLinePreCall(TooltipDataProcessor.AllTypes, onAnyLine)
    end
    -- The friends list's tooltip has no tooltip data for a post call, so after it shows.
    self:Hook(GameTooltip, "Show", onFriendTooltip)
    -- GameTooltip_SetDefaultAnchor is Blizzard's for every default-placed tooltip.
    self:Hook("GameTooltip_SetDefaultAnchor", onDefaultAnchor)
    self:Hook("UnitFrame_UpdateTooltip", dropClickHint)
    ns.Chat.EachWindow(self, hookTab)
    self:HookScript(GameTooltip, "OnTooltipCleared", unfade)
    self:HookScript(GameTooltip, "OnHide", unfade)
    self:HookScript(GameTooltip, "OnTooltipCleared", clearHealthText)
    fadeHealthBar(self.db.hideHealthBar)
    applyScale()
end

function module:OnDisable()
    fadeHealthBar(false)
    unfade()
    applyScale()
    clearHealthText()
    ns.Inspect.Prune()
end

function module:OnOptionChanged(key)
    if key == "hideHealthBar" and self.enabled then
        fadeHealthBar(self.db.hideHealthBar)
    elseif key == "scale" then
        applyScale()
    elseif key == "healthText" then
        updateHealthText()
    end
end
