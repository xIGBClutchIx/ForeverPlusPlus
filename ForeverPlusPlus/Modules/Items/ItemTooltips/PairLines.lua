-- Item Tooltips' Pair Short Lines: two short lines of an item that already sit one after the
-- other go on one row, the first at the left and the second at the right, so the tooltip is a
-- row shorter and nothing has moved: how it binds with "Unique" ("Binds when picked up",
-- "Quest Item"), and a shield's armor with its block. Told from the tooltip's data as the game
-- adds each line; a pair another module draws is left as two lines.
local _, ns = ...

local type, setmetatable, ipairs = type, setmetatable, ipairs
local find, gsub = string.find, string.gsub
local ARMOR_TEMPLATE, SHIELD_BLOCK_TEMPLATE = ARMOR_TEMPLATE, SHIELD_BLOCK_TEMPLATE
local ITEM_UNIQUE, ITEM_UNIQUE_MULTIPLE, ITEM_UNIQUE_EQUIPPABLE = ITEM_UNIQUE, ITEM_UNIQUE_MULTIPLE, ITEM_UNIQUE_EQUIPPABLE
local ITEM_BIND_QUEST, ITEM_SOULBOUND = ITEM_BIND_QUEST, ITEM_SOULBOUND
local ITEM_BIND_ON_PICKUP, ITEM_BIND_ON_EQUIP, ITEM_BIND_ON_USE = ITEM_BIND_ON_PICKUP, ITEM_BIND_ON_EQUIP, ITEM_BIND_ON_USE

local L = ns.L
local ItemTooltip, Text = ns.ItemTooltip, ns.Text

local module = ns.modules.ItemTooltips:NewPart({
    key = "pairLines", name = L.ITEMTOOLTIPS_PAIRLINES, description = L.PAIRLINES_DESC,
    section = L.PAIRLINES_TITLE, added = "1.10.0",
}, {
    pairLines = true,
})

-- Probe: the binding line's type by number, as seen on this client (docs/forever-api.md); the
-- client's own strings tell one where the number doesn't.
local LINE_BINDING = 20
local BINDINGS = {}
for _, text in ipairs({ ITEM_BIND_QUEST, ITEM_SOULBOUND, ITEM_BIND_ON_PICKUP, ITEM_BIND_ON_EQUIP, ITEM_BIND_ON_USE }) do
    BINDINGS[text] = true
end

-- A client format string ("%s Armor") as a pattern for a whole line, or nil without one.
local function linePattern(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    text = gsub(text, "%%%d*%$?[sd]", "\1") -- the placeholders, set aside
    text = gsub(text, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%0")
    return "^" .. gsub(text, "\1", ".+") .. "$"
end

local ARMOR, BLOCK = linePattern(ARMOR_TEMPLATE), linePattern(SHIELD_BLOCK_TEMPLATE)
local UNIQUE_MANY = linePattern(ITEM_UNIQUE_MULTIPLE)

local function matches(plain, pattern)
    return pattern ~= nil and find(plain, pattern) ~= nil
end

-- A line's text without codes, or nil for one that has none or already has a right side.
local function plainOf(lineData)
    local text = lineData.leftText
    if not ns.IsText(text, true) or ns.IsText(lineData.rightText, true) then
        return nil
    end
    return Text.Plain(text)
end

local function isBinding(lineData, plain)
    local kind = lineData.type
    return (ns.IsReadable(kind) and kind == LINE_BINDING) or BINDINGS[plain] == true
end

local function isUnique(plain)
    return plain == ITEM_UNIQUE or plain == ITEM_UNIQUE_EQUIPPABLE or matches(plain, UNIQUE_MANY)
end

local pairings = setmetatable({}, { __mode = "k" }) -- tooltip data -> first line -> the line after it
local drawn = setmetatable({}, { __mode = "k" }) -- tooltip -> the second line of the pair just drawn

-- The pairs in an item's lines: each first line with the line that follows it.
local function pairsOf(data)
    local found = pairings[data]
    if found then
        return found
    end
    found = {}
    pairings[data] = found
    local lines = ns.IsReadable(data.lines) and type(data.lines) == "table" and data.lines or {}
    local i = 2
    while i < #lines do
        local first, second = lines[i], lines[i + 1]
        local a, b = plainOf(first), plainOf(second)
        if a and b and ((isBinding(first, a) and isUnique(b)) or (matches(a, ARMOR) and matches(b, BLOCK))) then
            found[first] = second
            i = i + 1
        end
        i = i + 1
    end
    return found
end

local function colorOf(lineData)
    local color = lineData.leftColor
    if ns.IsReadable(color) and type(color) == "table" and color.r then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

-- Draws a pair's first line with its second at the right, and leaves the second out when it
-- comes. The second is only left out when the first was drawn here: if another module drew the
-- first (Color Stats, an armor line), both stay as they are.
local function drawLine(tooltip, data, lineData)
    if drawn[tooltip] == lineData then
        drawn[tooltip] = nil
        return true
    end
    if not module.enabled then
        return
    end
    local second = pairsOf(data)[lineData]
    if not second then
        return
    end
    local r, g, b = colorOf(lineData)
    local r2, g2, b2 = colorOf(second)
    tooltip:AddDoubleLine(lineData.leftText, second.leftText, r, g, b, r2, g2, b2)
    drawn[tooltip] = second
    return true
end

function module:OnEnable()
    -- The hook can't be removed; drawLine checks the part is on.
    ItemTooltip.ReplaceLine(drawLine, module)
end
