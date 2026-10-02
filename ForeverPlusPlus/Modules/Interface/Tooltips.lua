-- Tooltips: colors unit and item tooltips so they say more at a glance. The border and name
-- follow the unit's class or how it feels about you, item borders follow quality, the guild,
-- level and class on a unit's lines get colors, a player's title shows in their name, and a line
-- says who the unit is targeting. Ideas from ManiaTip; none of its code.
--
-- Every change is made after Blizzard builds the tooltip (TooltipDataProcessor post calls), on
-- Blizzard's own lines. Unit data can be secret, mostly in combat and instances: text we'd have
-- to read is left alone then, and colors that come back secret go straight to the setters.
local _, ns = ...

local type, setmetatable = type, setmetatable
local find, sub, gsub = string.find, string.sub, string.gsub
local TooltipDataProcessor, Enum, C_Item = TooltipDataProcessor, Enum, C_Item
local UnitExists, UnitClass, UnitLevel, UnitName = UnitExists, UnitClass, UnitLevel, UnitName
local UnitPVPName, UnitIsUnit, UnitReaction, UnitSelectionColor = UnitPVPName, UnitIsUnit, UnitReaction, UnitSelectionColor
local GetGuildInfo, GetCreatureDifficultyColor = GetGuildInfo, GetCreatureDifficultyColor
local GetQuestDifficultyColor, FACTION_BAR_COLORS = GetQuestDifficultyColor, FACTION_BAR_COLORS
local NORMAL_FONT_COLOR, TOOLTIP_DEFAULT_COLOR = NORMAL_FONT_COLOR, TOOLTIP_DEFAULT_COLOR
local FACTION_HORDE, FACTION_ALLIANCE = FACTION_HORDE, FACTION_ALLIANCE
local GameTooltip, InCombatLockdown = GameTooltip, InCombatLockdown

local L = ns.L
local readable = ns.IsReadable
local Units = ns.Units
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
    title = true,
    target = true,
    hideInCombat = false, -- hide unit tooltips while in combat
    anchorCursor = false, -- tooltips at the mouse instead of the bottom right
})
module.title = L.TOOLTIPS_TITLE
module.category = "interface"

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
    { key = "title", name = L.TOOLTIPS_PLAYER_TITLE, description = L.TOOLTIPS_PLAYER_TITLE_DESC,
        section = L.TOOLTIPS_SECTION_LINES },
    { key = "target", name = L.TOOLTIPS_TARGET, description = L.TOOLTIPS_TARGET_DESC,
        section = L.TOOLTIPS_SECTION_LINES },
    { key = "anchorCursor", name = L.TOOLTIPS_ANCHOR_CURSOR, description = L.TOOLTIPS_ANCHOR_CURSOR_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR },
    { key = "hideInCombat", name = L.TOOLTIPS_HIDE_IN_COMBAT, description = L.TOOLTIPS_HIDE_IN_COMBAT_DESC,
        section = L.TOOLTIPS_SECTION_BEHAVIOR },
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
    if readable(text) and type(text) == "string" then
        return text
    end
end

local function escape(text)
    return (gsub(text, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- `text` with the first match of `pattern` wrapped in a color, and whether it matched. The |r
-- goes back to the line's own color.
local function colorMatch(text, pattern, r, g, b)
    local first, last = find(text, pattern)
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
        if not (readable(own) and type(own) == "number") then
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
    if not (readable(unit) and type(unit) == "string") then
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
            local line = color and leftLine(tooltip, i)
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
    if not (readable(level) and type(level) == "number") then
        return
    end
    local levelPattern = level > 0 and "%f[%d]" .. level .. "%f[%D]" or "%?%?"
    local className = db.classColor and UnitClass(unit)
    local class = classColor(unit)
    local classPattern = readable(className) and className and class
        and "%f[%w]" .. escape(className) .. "%f[%W]"
    for i = 2, #data.lines do
        local text = i ~= guildLine and lineText(data, i)
        if text and find(text, levelPattern) then
            local changed, found = false
            if db.levelColor then
                local color = levelColor(level)
                if color then
                    text, changed = colorMatch(text, levelPattern, color.r, color.g, color.b)
                end
            end
            if classPattern then
                local r, g, b = class:GetRGB()
                text, found = colorMatch(text, classPattern, r, g, b)
                changed = changed or found
                local nextText = not found and lineText(data, i + 1)
                if nextText then
                    local nextLine = leftLine(tooltip, i + 1)
                    nextText, found = colorMatch(nextText, classPattern, r, g, b)
                    if found and nextLine then
                        nextLine:SetText(nextText)
                    end
                end
            end
            local line = changed and leftLine(tooltip, i)
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
        local line = side and leftLine(tooltip, i)
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

local function onUnit(tooltip, data)
    -- Hide in Combat: the mouseover tooltip only; tooltips the player opens stay.
    if module.enabled and module.db.hideInCombat and tooltip == GameTooltip and InCombatLockdown() then
        tooltip:Hide()
        return
    end
    local unit = module.enabled and data and tooltipUnit(tooltip)
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
    if db.target then
        addTarget(tooltip, unit)
    end
end

-- Item tooltips ------------------------------------------------------------------------------

local function onItem(tooltip, data)
    if not (module.enabled and module.db.itemBorder and data and C_Item.GetItemQualityByID) then
        return
    end
    local item = ns.ItemTooltip.ItemID(data)
    if not item and readable(data.hyperlink) then
        item = data.hyperlink
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
    if module.db.anchorCursor then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    end
end

local hooked = false

function module:OnEnable()
    -- Tooltip data calls can't be removed; each one checks module.enabled.
    if not hooked then
        hooked = true
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onUnit)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItem)
    end
    -- Probe: GameTooltip_SetDefaultAnchor is Blizzard's for every default-placed tooltip.
    if GameTooltip_SetDefaultAnchor then
        self:Hook("GameTooltip_SetDefaultAnchor", onDefaultAnchor)
    end
end
