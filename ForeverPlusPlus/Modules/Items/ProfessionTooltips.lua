-- Profession Tooltips: the skill a herb, vein, skinnable beast, or locked lockbox or chest needs,
-- in its tooltip, colored against the player's skill the way a trainer colors recipes: red can't
-- yet, then orange, yellow, green, and gray as it gets easier. Herbs, ore, and stone items say
-- the skill that gathers them. Gathering is shown only for professions the player has, or always
-- (red without it); Lockpicking only for characters who can pick locks. Ideas from
-- GatherSkillTooltip; none of its code.
--
-- Fishing isn't here: in Classic what a pool or a fish needs depends on the zone, not on it.
-- Node names are matched in English; another language needs its own names in NODES.
local _, ns = ...

local type, ipairs, setmetatable = type, ipairs, setmetatable
local gsub, gmatch, match, find, concat = string.gsub, string.gmatch, string.match, string.find, table.concat
local format = string.format
local TooltipDataProcessor, Enum = TooltipDataProcessor, Enum
local UnitIsPlayer, UnitPlayerControlled, UnitCreatureType = UnitIsPlayer, UnitPlayerControlled, UnitCreatureType
local UnitLevel, UnitIsDead, UnitCanAttack = UnitLevel, UnitIsDead, UnitCanAttack

local L = ns.L
local Colors = ns.Colors
local readable = ns.IsReadable
local Professions = ns.Professions
local ItemTooltip = ns.ItemTooltip

local HERB, MINE, SKIN = Professions.HERBALISM, Professions.MINING, Professions.SKINNING
local LOCK, SMITH = Professions.LOCKPICKING, Professions.BLACKSMITHING
local select = select
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR

local module = ns.NewModule("ProfessionTooltips", L.PROFTOOLTIPS_DESC, {
    enabled = true,
    show = "known", -- "known" (only for professions you have) or "always"; gathering only
    herbalism = true,
    mining = true,
    skinning = true,
    lockpicking = true,
    blacksmithing = true,
    items = true,
})
module.title = L.PROFTOOLTIPS_TITLE
module.category = "items"

module.options = {
    {
        key = "show", name = L.PROFTOOLTIPS_SHOW, description = L.PROFTOOLTIPS_SHOW_DESC,
        choices = {
            { "known", L.PROFTOOLTIPS_SHOW_KNOWN },
            { "always", L.PROFTOOLTIPS_SHOW_ALWAYS },
        },
    },
    { key = "herbalism", name = L.PROFTOOLTIPS_HERBALISM, description = L.PROFTOOLTIPS_HERBALISM_DESC },
    { key = "mining", name = L.PROFTOOLTIPS_MINING, description = L.PROFTOOLTIPS_MINING_DESC },
    { key = "skinning", name = L.PROFTOOLTIPS_SKINNING, description = L.PROFTOOLTIPS_SKINNING_DESC },
    { key = "lockpicking", name = L.PROFTOOLTIPS_LOCKPICKING, description = L.PROFTOOLTIPS_LOCKPICKING_DESC },
    {
        key = "blacksmithing", name = L.PROFTOOLTIPS_BLACKSMITHING,
        description = L.PROFTOOLTIPS_BLACKSMITHING_DESC,
    },
    { key = "items", name = L.PROFTOOLTIPS_ITEMS, description = L.PROFTOOLTIPS_ITEMS_DESC },
}

-- Data ---------------------------------------------------------------------------------------
-- The skill each gathers at, from Classic. Forever may change some; fix them here.

local NODES = { -- object name -> { skill line, skill }
    ["Peacebloom"] = { HERB, 1 },
    ["Silverleaf"] = { HERB, 1 },
    ["Earthroot"] = { HERB, 15 },
    ["Mageroyal"] = { HERB, 50 },
    ["Briarthorn"] = { HERB, 70 },
    ["Stranglekelp"] = { HERB, 85 },
    ["Bruiseweed"] = { HERB, 100 },
    ["Wild Steelbloom"] = { HERB, 115 },
    ["Grave Moss"] = { HERB, 120 },
    ["Kingsblood"] = { HERB, 125 },
    ["Liferoot"] = { HERB, 150 },
    ["Fadeleaf"] = { HERB, 160 },
    ["Goldthorn"] = { HERB, 170 },
    ["Khadgar's Whisker"] = { HERB, 185 },
    ["Wintersbite"] = { HERB, 195 },
    ["Firebloom"] = { HERB, 205 },
    ["Purple Lotus"] = { HERB, 210 },
    ["Arthas' Tears"] = { HERB, 220 },
    ["Sungrass"] = { HERB, 230 },
    ["Blindweed"] = { HERB, 235 },
    ["Ghost Mushroom"] = { HERB, 245 },
    ["Gromsblood"] = { HERB, 250 },
    ["Golden Sansam"] = { HERB, 260 },
    ["Dreamfoil"] = { HERB, 270 },
    ["Mountain Silversage"] = { HERB, 280 },
    ["Plaguebloom"] = { HERB, 285 },
    ["Icecap"] = { HERB, 290 },
    ["Black Lotus"] = { HERB, 300 },

    ["Copper Vein"] = { MINE, 1 },
    ["Tin Vein"] = { MINE, 65 },
    ["Incendicite Mineral Vein"] = { MINE, 65 },
    ["Silver Vein"] = { MINE, 75 },
    ["Ooze Covered Silver Vein"] = { MINE, 75 },
    ["Lesser Bloodstone Deposit"] = { MINE, 75 },
    ["Iron Deposit"] = { MINE, 125 },
    ["Ooze Covered Iron Deposit"] = { MINE, 125 },
    ["Indurium Mineral Vein"] = { MINE, 150 },
    ["Gold Vein"] = { MINE, 155 },
    ["Ooze Covered Gold Vein"] = { MINE, 155 },
    ["Mithril Deposit"] = { MINE, 175 },
    ["Ooze Covered Mithril Deposit"] = { MINE, 175 },
    ["Truesilver Deposit"] = { MINE, 230 },
    ["Ooze Covered Truesilver Deposit"] = { MINE, 230 },
    ["Dark Iron Deposit"] = { MINE, 230 },
    ["Small Thorium Vein"] = { MINE, 245 },
    ["Ooze Covered Thorium Vein"] = { MINE, 245 },
    ["Rich Thorium Vein"] = { MINE, 275 },
    ["Ooze Covered Rich Thorium Vein"] = { MINE, 275 },
    ["Hakkari Thorium Vein"] = { MINE, 275 },
    ["Small Obsidian Chunk"] = { MINE, 305 },
    ["Large Obsidian Chunk"] = { MINE, 305 },

    -- Locked chests in the world; add more (and doors) here as they're confirmed in game.
    ["Solid Chest"] = { LOCK, 1 },
    ["Large Solid Chest"] = { LOCK, 1 },
}

local ITEMS = { -- item ID -> { skill line, skill }
    [2447] = { HERB, 1 }, -- Peacebloom
    [765] = { HERB, 1 }, -- Silverleaf
    [2449] = { HERB, 15 }, -- Earthroot
    [785] = { HERB, 50 }, -- Mageroyal
    [2450] = { HERB, 70 }, -- Briarthorn
    [3820] = { HERB, 85 }, -- Stranglekelp
    [2453] = { HERB, 100 }, -- Bruiseweed
    [3355] = { HERB, 115 }, -- Wild Steelbloom
    [3369] = { HERB, 120 }, -- Grave Moss
    [3356] = { HERB, 125 }, -- Kingsblood
    [3357] = { HERB, 150 }, -- Liferoot
    [3818] = { HERB, 160 }, -- Fadeleaf
    [3821] = { HERB, 170 }, -- Goldthorn
    [3358] = { HERB, 185 }, -- Khadgar's Whisker
    [3819] = { HERB, 195 }, -- Wintersbite
    [4625] = { HERB, 205 }, -- Firebloom
    [8831] = { HERB, 210 }, -- Purple Lotus
    [8836] = { HERB, 220 }, -- Arthas' Tears
    [8838] = { HERB, 230 }, -- Sungrass
    [8839] = { HERB, 235 }, -- Blindweed
    [8845] = { HERB, 245 }, -- Ghost Mushroom
    [8846] = { HERB, 250 }, -- Gromsblood
    [13464] = { HERB, 260 }, -- Golden Sansam
    [13463] = { HERB, 270 }, -- Dreamfoil
    [13465] = { HERB, 280 }, -- Mountain Silversage
    [13466] = { HERB, 285 }, -- Plaguebloom
    [13467] = { HERB, 290 }, -- Icecap
    [13468] = { HERB, 300 }, -- Black Lotus

    [2770] = { MINE, 1 }, -- Copper Ore
    [2835] = { MINE, 1 }, -- Rough Stone
    [2771] = { MINE, 65 }, -- Tin Ore
    [2836] = { MINE, 65 }, -- Coarse Stone
    [3340] = { MINE, 65 }, -- Incendicite Ore
    [2775] = { MINE, 75 }, -- Silver Ore
    [4278] = { MINE, 75 }, -- Lesser Bloodstone Ore
    [2772] = { MINE, 125 }, -- Iron Ore
    [2838] = { MINE, 125 }, -- Heavy Stone
    [5833] = { MINE, 150 }, -- Indurium Ore
    [2776] = { MINE, 155 }, -- Gold Ore
    [3858] = { MINE, 175 }, -- Mithril Ore
    [7912] = { MINE, 175 }, -- Solid Stone
    [7911] = { MINE, 230 }, -- Truesilver Ore
    [11370] = { MINE, 230 }, -- Dark Iron Ore
    [10620] = { MINE, 245 }, -- Thorium Ore
    [12365] = { MINE, 245 }, -- Dense Stone

    -- Locked boxes: the Lockpicking skill to open them.
    [16882] = { LOCK, 1 }, -- Battered Junkbox
    [16883] = { LOCK, 25 }, -- Worn Junkbox
    [16884] = { LOCK, 70 }, -- Sturdy Junkbox
    [16885] = { LOCK, 175 }, -- Heavy Junkbox
    [6712] = { LOCK, 1 }, -- Practice Lockbox
    [4632] = { LOCK, 1 }, -- Ornate Bronze Lockbox
    [4633] = { LOCK, 25 }, -- Heavy Bronze Lockbox
    [4634] = { LOCK, 70 }, -- Iron Lockbox
    [4636] = { LOCK, 125 }, -- Strong Iron Lockbox
    [4637] = { LOCK, 175 }, -- Steel Lockbox
    [4638] = { LOCK, 225 }, -- Reinforced Steel Lockbox
    [5758] = { LOCK, 225 }, -- Mithril Lockbox
    [5759] = { LOCK, 275 }, -- Thorium Lockbox
    [5760] = { LOCK, 350 }, -- Eternium Lockbox
}

-- Blacksmiths make skeleton keys that open locks like Lockpicking: item ID, the skill it opens
-- up to, and the Blacksmithing skill that makes it. From Classic; fix them here.
local KEYS = {
    { id = 15869, skill = 100, smith = 100 }, -- Silver Skeleton Key
    { id = 15870, skill = 150, smith = 150 }, -- Golden Skeleton Key
    { id = 15871, skill = 200, smith = 200 }, -- Truesilver Skeleton Key
    { id = 15872, skill = 275, smith = 275 }, -- Arcanite Skeleton Key
}
local KEY_SKILL = {}
for _, key in ipairs(KEYS) do
    KEY_SKILL[key.id] = key.skill
end

local OPTION = { [HERB] = "herbalism", [MINE] = "mining", [SKIN] = "skinning", [LOCK] = "lockpicking" }
local FALLBACK_NAME = {
    [HERB] = L.PROFTOOLTIPS_HERBALISM_NAME,
    [MINE] = L.PROFTOOLTIPS_MINING_NAME,
    [SKIN] = L.PROFTOOLTIPS_SKINNING_NAME,
    [LOCK] = L.PROFTOOLTIPS_LOCKPICKING_NAME,
}

-- Beast and Dragonkin, the creature types that can be skinned (UnitCreatureType's second value).
local SKINNABLE_TYPES = { [1] = true, [2] = true }
local SKINNABLE_NAMES = { [L.PROFTOOLTIPS_BEAST] = true, [L.PROFTOOLTIPS_DRAGONKIN] = true }

-- The Lockpicking skill the player can open locks with: a rogue's own, or, with the Blacksmithing
-- option, that of the best skeleton key their Blacksmithing lets them make (0 when none yet).
-- Nil for anyone with neither.
local function lockRank()
    local rank, name = Professions.Rank(LOCK)
    if module.db.blacksmithing then
        local smith = Professions.Rank(SMITH)
        if smith then
            local best = 0
            for _, key in ipairs(KEYS) do
                if smith >= key.smith and key.skill > best then
                    best = key.skill
                end
            end
            rank = rank and rank > best and rank or best
        end
    end
    return rank, name
end

-- The line for a skill line and skill, colored, or nil when it's off or the player doesn't have
-- the profession and `show` is "known". Without the profession it's red: you can't gather it.
-- Lockpicking is never shown to characters who can't pick locks, whatever `show` says.
-- `text` is L.PROFTOOLTIPS_REQUIRES or _GATHERED.
local function skillLine(line, need, text)
    if not module.db[OPTION[line]] then
        return nil
    end
    local rank, name
    if line == LOCK then
        rank, name = lockRank()
        if not rank then
            return nil
        end
    else
        rank, name = Professions.Rank(line)
        if not rank and module.db.show ~= "always" then
            return nil
        end
    end
    local color = Professions.Difficulty(rank, need)
    return format(text, name or FALLBACK_NAME[line], need), color, rank, name or FALLBACK_NAME[line]
end

-- The "your skill" text that stands in for a bare profession name line under Blizzard's
-- requirement, colored like it: nil when the player has no skill to show.
local function yourSkill(color, rank, name)
    if rank then
        return Colors.Text(color, format(L.PROFTOOLTIPS_YOURS, name, rank))
    end
end

local function addLine(tooltip, text, color)
    tooltip:AddLine(text, color.r, color.g, color.b)
end

-- Blizzard's own "Requires Mining (1)" line on a node or creature: it's recolored in place
-- instead of adding ours. The pattern comes from its string, so it works in any language.
local REQUIRES = gsub(ITEM_MIN_SKILL or L.PROFTOOLTIPS_REQUIRES, "([%(%)%.%-%+%[%]%*%?%^%$])", "%%%1")
REQUIRES = gsub(REQUIRES, "%%s", "(.+)")
REQUIRES = "^" .. gsub(REQUIRES, "%%d", "(%%d+)") .. "$"

-- World objects and minimap pins -------------------------------------------------------------

-- An object's name without the color codes, icons, and spaces a tooltip may wrap it in.
local function clean(text)
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = gsub(text, "|r", "")
    text = gsub(text, "|T.-|t", "")
    text = gsub(text, "|A.-|a", "")
    return match(text, "^%s*(.-)%s*$")
end

local leftLine = ns.Text.LeftLine

-- The skill line and its color for the node named in `text`, or nil.
local function nodeLine(text)
    local node = NODES[clean(text)]
    if node then
        return skillLine(node[1], node[2], L.PROFTOOLTIPS_REQUIRES)
    end
end

-- The color for Blizzard's requirement line `text` for skill line `line`, and its text without
-- codes; nil when `text` isn't such a line, or the option is off or the profession not shown.
local function requiresColor(text, line)
    local plain = clean(text)
    local _, digits = match(plain, REQUIRES)
    local need = tonumber(digits)
    if need then
        local _, color, rank, name = skillLine(line, need, L.PROFTOOLTIPS_REQUIRES)
        return color, plain, true, rank, name
    end
end

-- Whether `text` is just the profession's name (Blizzard or another addon repeating it under the
-- requirement), in either the client's language or ours.
local function isProfessionName(text, line)
    local plain = clean(text)
    local _, name = Professions.Rank(line)
    return plain == FALLBACK_NAME[line] or (name ~= nil and plain == name)
end

-- The index of the line after `index` in data when it only repeats the profession's name, or nil.
local function findNameLine(data, index, line)
    local entry = data.lines[index + 1]
    local text = entry and entry.leftText
    if readable(text) and type(text) == "string" and isProfessionName(text, line) then
        return index + 1
    end
end

-- The first of data's lines after the first that is Blizzard's requirement line: its index, or nil.
local function findRequires(data)
    local lines = data.lines
    if not (readable(lines) and type(lines) == "table") then
        return nil
    end
    for i = 2, #lines do
        local text = lines[i] and lines[i].leftText
        if readable(text) and type(text) == "string" and match(clean(text), REQUIRES) then
            return i
        end
    end
end

-- Recolors Blizzard's requirement line on `tooltip`, once it's drawn: `job` is { index, skill
-- line, text }.
local function restyle(tooltip, job)
    local fontString = leftLine(tooltip, job[1])
    if job[5] then
        -- Blizzard's bare profession name line: it says what we would, so ours replaces it.
        local text, color = skillLine(job[2], job[5], L.PROFTOOLTIPS_REQUIRES)
        if fontString and text then
            fontString:SetText(Colors.Text(color, text))
        end
        return
    end
    local color, _, _, rank, name = requiresColor(job[3], job[2])
    if fontString and color then
        fontString:SetText(Colors.Text(color, clean(job[3])))
        -- A bare name line below it becomes the player's skill against that requirement.
        local nameString = job[4] and leftLine(tooltip, job[4])
        local text = nameString and yourSkill(color, rank, name)
        if text then
            nameString:SetText(text)
        end
    end
end

local restyling = setmetatable({}, { __mode = "k" }) -- tooltip -> job for its post call

-- A herb or vein under the mouse, or a minimap pin. A world object's tooltip has its name alone
-- on the first line, and the skill line is added after it. A minimap pin's first line holds
-- everything on separate lines, overlapping pins and their quest objectives too, so the skill
-- line goes into that text under its node's name.
local function addNodeLines(tooltip, data)
    if not (module.enabled and readable(data.lines) and type(data.lines) == "table") then
        return
    end
    local first = data.lines[1]
    local text = first and first.leftText
    if not (readable(text) and type(text) == "string") then
        return
    end
    text = gsub(text, "|n", "\n")
    if not find(text, "\n", 1, true) then
        local node = NODES[clean(text)]
        if not node then
            return
        end
        -- Blizzard already says what it needs: recolor that once it's drawn, don't add another.
        local index = findRequires(data)
        if index then
            restyling[tooltip] = { index, node[1], data.lines[index].leftText,
                findNameLine(data, index, node[1]) }
            return
        end
        -- The game's own "Mining" line under a vein: ours takes its place instead of repeating it.
        for i = 2, #data.lines do
            local other = data.lines[i] and data.lines[i].leftText
            if readable(other) and type(other) == "string" and isProfessionName(other, node[1]) then
                restyling[tooltip] = { i, node[1], other, nil, node[2] }
                return
            end
        end
        local line, color = nodeLine(text)
        if line then
            addLine(tooltip, line, color)
        end
        return
    end
    local raw, parts, changed = {}, {}, false
    for part in gmatch(text .. "\n", "(.-)\n") do
        raw[#raw + 1] = part
    end
    local i = 1
    while i <= #raw do
        local part = raw[i]
        parts[#parts + 1] = part
        local node = NODES[clean(part)]
        local nextPart = raw[i + 1]
        local color, plain, rank, skillName = nil, nil, nil, nil
        if node and nextPart then
            color, plain, _, rank, skillName = requiresColor(nextPart, node[1])
        end
        if node and nextPart and match(clean(nextPart), REQUIRES) then
            -- Blizzard's own line follows the name: color it, and a bare name line after it
            -- becomes the player's skill.
            if color then
                parts[#parts + 1] = Colors.Text(color, plain)
                changed = true
                local after = raw[i + 2]
                local yours = after and isProfessionName(after, node[1]) and yourSkill(color, rank, skillName)
                if yours then
                    parts[#parts + 1] = yours
                    i = i + 1
                end
            else
                parts[#parts + 1] = nextPart
            end
            i = i + 1
        else
            local line, lineColor = nodeLine(part)
            if line then
                parts[#parts + 1] = Colors.Text(lineColor, line)
                changed = true
                -- The game's own bare name line after it is replaced, not repeated.
                if node and nextPart and isProfessionName(nextPart, node[1]) then
                    i = i + 1
                end
            end
        end
        i = i + 1
    end
    local fontString = changed and leftLine(tooltip, 1)
    if fontString then
        fontString:SetText(concat(parts, "\n"))
    end
end

-- The lines go right under the name, before quest objectives and anything else Blizzard adds:
-- the tooltip's data is kept from its pre call, and they're added once its first line is drawn.
-- Without line calls they go at the end, from the post call.
local pending = setmetatable({}, { __mode = "k" }) -- tooltip -> object data not yet handled

local function onObjectPre(tooltip, data)
    pending[tooltip] = data
    restyling[tooltip] = nil
end

local function onLinePost(tooltip, lineData)
    local data = pending[tooltip]
    local lines = data and data.lines
    if lines and readable(lines) and type(lines) == "table" and lines[1] == lineData then
        pending[tooltip] = nil
        addNodeLines(tooltip, data)
    end
end

local function onObject(tooltip, data)
    local waiting = pending[tooltip]
    pending[tooltip] = nil
    if data and (waiting or not TooltipDataProcessor.AddTooltipPreCall) then
        addNodeLines(tooltip, data)
    end
    local job = restyling[tooltip]
    restyling[tooltip] = nil
    if job and module.enabled then
        restyle(tooltip, job)
    end
end

-- Creatures ----------------------------------------------------------------------------------

-- Whether a unit value is readable and true. Unit state can be secret; then it counts as no.
local function yes(value)
    return readable(value) and not not value
end

local function canSkin(unit)
    if yes(UnitIsPlayer(unit)) or yes(UnitPlayerControlled(unit)) then
        return false
    end
    -- Probe: the type's ID is a second value on Mainline; without it, the name the game shows.
    local name, kind = UnitCreatureType(unit)
    if readable(kind) and type(kind) == "number" then
        if not SKINNABLE_TYPES[kind] then
            return false
        end
    elseif not (readable(name) and SKINNABLE_NAMES[name]) then
        return false
    end
    -- Dead ones, or ones you could fight: not a friendly flight master's gryphon.
    return yes(UnitIsDead(unit)) or yes(UnitCanAttack("player", unit))
end

local unitData = setmetatable({}, { __mode = "k" }) -- tooltip -> the unit's tooltip data

local function addSkinLine(tooltip)
    if not (module.enabled and module.db.skinning and tooltip.GetUnit) then
        return
    end
    local _, unit = tooltip:GetUnit()
    if not (readable(unit) and type(unit) == "string") or not canSkin(unit) then
        return
    end
    -- Blizzard already says what it needs: recolor that once it's drawn, don't add another.
    local data = unitData[tooltip]
    local index = data and findRequires(data)
    if index then
        restyling[tooltip] = { index, SKIN, data.lines[index].leftText, findNameLine(data, index, SKIN) }
        return
    end
    local level = UnitLevel(unit)
    if not (readable(level) and type(level) == "number" and level > 0) then
        return -- a "??" boss, or secret
    end
    local line, color = skillLine(SKIN, Professions.SkinningNeed(level), L.PROFTOOLTIPS_REQUIRES)
    if line then
        addLine(tooltip, line, color)
    end
end

-- The line goes under the name and level, before the quest lines: it's added just before the
-- first quest line is drawn, or at the end when there's none.
local unitPending = setmetatable({}, { __mode = "k" }) -- tooltip -> true until the line is added

local function onUnitPre(tooltip, data)
    unitPending[tooltip] = true
    unitData[tooltip] = data
    restyling[tooltip] = nil
end

local function onQuestLinePre(tooltip)
    if unitPending[tooltip] then
        unitPending[tooltip] = nil
        addSkinLine(tooltip)
    end
end

local function onUnit(tooltip, data)
    local waiting = unitPending[tooltip]
    unitPending[tooltip] = nil
    if data and (waiting or not TooltipDataProcessor.AddTooltipPreCall) then
        addSkinLine(tooltip)
    end
    local job = restyling[tooltip]
    restyling[tooltip] = nil
    unitData[tooltip] = nil
    if job and module.enabled then
        restyle(tooltip, job)
    end
end

-- Items --------------------------------------------------------------------------------------

local function onItem(tooltip, data)
    if not (module.enabled and module.db.items) then
        return
    end
    local id = ItemTooltip.ItemID(data)
    local item = id and ITEMS[id]
    local keySkill = id and module.db.blacksmithing and KEY_SKILL[id]
    if keySkill then
        local name = select(2, lockRank())
        addLine(tooltip, format(L.PROFTOOLTIPS_KEY, name or L.PROFTOOLTIPS_LOCKPICKING_NAME, keySkill),
            NORMAL_FONT_COLOR or { r = 1, g = 0.82, b = 0 })
    end
    if item then
        local text = item[1] == LOCK and L.PROFTOOLTIPS_REQUIRES or L.PROFTOOLTIPS_GATHERED
        local line, color = skillLine(item[1], item[2], text)
        if line then
            addLine(tooltip, line, color)
        end
    end
end

local hooked = false

function module:OnEnable()
    -- Hooks can't be removed; each one checks module.enabled.
    if hooked then
        return
    end
    hooked = true
    local types = Enum.TooltipDataType
    -- Probe: MinimapMouseover is Mainline's type for minimap pins.
    for _, key in ipairs({ "Object", "MinimapMouseover" }) do
        local kind = types[key]
        if kind and TooltipDataProcessor.AddTooltipPreCall then
            TooltipDataProcessor.AddTooltipPreCall(kind, onObjectPre)
        end
        if kind then
            TooltipDataProcessor.AddTooltipPostCall(kind, onObject)
        end
    end
    -- Probe: AllTypes (every line type) and line calls are Mainline's.
    if TooltipDataProcessor.AllTypes and TooltipDataProcessor.AddLinePostCall then
        TooltipDataProcessor.AddLinePostCall(TooltipDataProcessor.AllTypes, onLinePost)
    end
    if TooltipDataProcessor.AddTooltipPreCall then
        TooltipDataProcessor.AddTooltipPreCall(types.Unit, onUnitPre)
    end
    TooltipDataProcessor.AddTooltipPostCall(types.Unit, onUnit)
    -- Probe: quest line types and line pre calls are Mainline's.
    local lineTypes = Enum.TooltipDataLineType
    if lineTypes and TooltipDataProcessor.AddLinePreCall then
        for _, key in ipairs({ "QuestTitle", "QuestObjective", "QuestPlayer" }) do
            if lineTypes[key] then
                TooltipDataProcessor.AddLinePreCall(lineTypes[key], onQuestLinePre)
            end
        end
    end
    ItemTooltip.OnInfo(onItem)
end
