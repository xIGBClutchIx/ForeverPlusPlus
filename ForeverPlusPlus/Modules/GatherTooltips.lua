-- Gathering Tooltips: the skill a herb, vein, or skinnable beast needs, in its tooltip, colored
-- against the player's skill the way a trainer colors recipes: red can't yet, then orange,
-- yellow, green, and gray as it gets easier. Herbs, ore, and stone items say the skill that
-- gathers them. Only for professions the player has, or always (red without it). Ideas from
-- GatherSkillTooltip; none of its
-- code.
--
-- Fishing isn't here: in Classic what a pool or a fish needs depends on the zone, not on it.
-- Node names are matched in English; another language needs its own names in NODES.
local _, ns = ...

local type, gsub, gmatch, match = type, string.gsub, string.gmatch, string.match
local format = string.format
local TooltipDataProcessor, Enum = TooltipDataProcessor, Enum
local UnitIsPlayer, UnitPlayerControlled, UnitCreatureType = UnitIsPlayer, UnitPlayerControlled, UnitCreatureType
local UnitLevel, UnitIsDead, UnitCanAttack = UnitLevel, UnitIsDead, UnitCanAttack

local L = ns.L
local readable = ns.IsReadable
local Professions = ns.Professions
local ItemTooltip = ns.ItemTooltip

local HERB, MINE, SKIN = Professions.HERBALISM, Professions.MINING, Professions.SKINNING

local module = ns.NewModule("GatherTooltips", L.GATHERTOOLTIPS_DESC, {
    enabled = true,
    show = "known", -- "known" (only for professions you have) or "always"
    herbalism = true,
    mining = true,
    skinning = true,
    items = true,
})
module.title = L.GATHERTOOLTIPS_TITLE
module.category = "items"

module.options = {
    {
        key = "show", name = L.GATHERTOOLTIPS_SHOW, description = L.GATHERTOOLTIPS_SHOW_DESC,
        choices = {
            { "known", L.GATHERTOOLTIPS_SHOW_KNOWN },
            { "always", L.GATHERTOOLTIPS_SHOW_ALWAYS },
        },
    },
    { key = "herbalism", name = L.GATHERTOOLTIPS_HERBALISM, description = L.GATHERTOOLTIPS_HERBALISM_DESC },
    { key = "mining", name = L.GATHERTOOLTIPS_MINING, description = L.GATHERTOOLTIPS_MINING_DESC },
    { key = "skinning", name = L.GATHERTOOLTIPS_SKINNING, description = L.GATHERTOOLTIPS_SKINNING_DESC },
    { key = "items", name = L.GATHERTOOLTIPS_ITEMS, description = L.GATHERTOOLTIPS_ITEMS_DESC },
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
}

local OPTION = { [HERB] = "herbalism", [MINE] = "mining", [SKIN] = "skinning" }
local FALLBACK_NAME = {
    [HERB] = L.GATHERTOOLTIPS_HERBALISM_NAME,
    [MINE] = L.GATHERTOOLTIPS_MINING_NAME,
    [SKIN] = L.GATHERTOOLTIPS_SKINNING_NAME,
}

-- Beast and Dragonkin, the creature types that can be skinned (UnitCreatureType's second value).
local SKINNABLE_TYPES = { [1] = true, [2] = true }
local SKINNABLE_NAMES = { [L.GATHERTOOLTIPS_BEAST] = true, [L.GATHERTOOLTIPS_DRAGONKIN] = true }

-- Colors -------------------------------------------------------------------------------------
-- Blizzard's difficulty colors, the same a trainer uses for recipes. Probe: QuestDifficultyColors
-- is FrameXML's; the values after it are its own.

local COLORS = QuestDifficultyColors or {}
local RED = COLORS.impossible or { r = 1, g = 0.1, b = 0.1 }
local ORANGE = COLORS.verydifficult or { r = 1, g = 0.5, b = 0.25 }
local YELLOW = COLORS.difficult or { r = 1, g = 1, b = 0 }
local GREEN = COLORS.standard or { r = 0.25, g = 0.75, b = 0.25 }
local GRAY = COLORS.trivial or { r = 0.5, g = 0.5, b = 0.5 }

-- How hard `need` is at `rank`: a gather gives a skill point every time while orange, often while
-- yellow, sometimes while green, and never once gray.
local function difficulty(rank, need)
    if rank < need then
        return RED
    elseif rank < need + 25 then
        return ORANGE
    elseif rank < need + 50 then
        return YELLOW
    elseif rank < need + 100 then
        return GREEN
    end
    return GRAY
end

-- The line for a skill line and skill, colored, or nil when it's off or the player doesn't have
-- the profession and `show` is "known". Without the profession it's red: you can't gather it.
-- `text` is L.GATHERTOOLTIPS_REQUIRES or _GATHERED.
local function skillLine(line, need, text)
    if not module.db[OPTION[line]] then
        return nil
    end
    local rank, name = Professions.Rank(line)
    if not rank and module.db.show ~= "always" then
        return nil
    end
    local color = rank and difficulty(rank, need) or RED
    return format(text, name or FALLBACK_NAME[line], need), color
end

local function addLine(tooltip, text, color)
    tooltip:AddLine(text, color.r, color.g, color.b)
end

-- World objects and minimap pins -------------------------------------------------------------

-- An object's name without the color codes, icons, and spaces a tooltip may wrap it in.
local function clean(text)
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = gsub(text, "|r", "")
    text = gsub(text, "|T.-|t", "")
    text = gsub(text, "|A.-|a", "")
    return match(text, "^%s*(.-)%s*$")
end

-- A herb or vein under the mouse, or a minimap pin: one name, or several on separate lines
-- when pins overlap. Each known one gets its line, with its name when there are several.
local function onObject(tooltip, data)
    if not (module.enabled and data and readable(data.lines) and type(data.lines) == "table") then
        return
    end
    local first = data.lines[1]
    local text = first and first.leftText
    if not (readable(text) and type(text) == "string") then
        return
    end
    local found, count = {}, 0
    for part in gmatch(text .. "\n", "(.-)\n") do
        local name = clean(part)
        local node = NODES[name]
        if node and not found[name] then
            count = count + 1
            found[count] = name
            found[name] = true
        end
    end
    for i = 1, count do
        local name = found[i]
        local node = NODES[name]
        local line, color = skillLine(node[1], node[2], L.GATHERTOOLTIPS_REQUIRES)
        if line then
            addLine(tooltip, count > 1 and format(L.GATHERTOOLTIPS_NAMED, name, line) or line, color)
        end
    end
end

-- Creatures ----------------------------------------------------------------------------------

-- The Skinning skill a creature of `level` needs.
local function skinningNeed(level)
    if level <= 10 then
        return 1
    elseif level <= 20 then
        return level * 10 - 100
    end
    return level * 5
end

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

local function onUnit(tooltip, data)
    if not (module.enabled and module.db.skinning and data and tooltip.GetUnit) then
        return
    end
    local _, unit = tooltip:GetUnit()
    if not (readable(unit) and type(unit) == "string") or not canSkin(unit) then
        return
    end
    local level = UnitLevel(unit)
    if not (readable(level) and type(level) == "number" and level > 0) then
        return -- a "??" boss, or secret
    end
    local line, color = skillLine(SKIN, skinningNeed(level), L.GATHERTOOLTIPS_REQUIRES)
    if line then
        addLine(tooltip, line, color)
    end
end

-- Items --------------------------------------------------------------------------------------

local function onItem(tooltip, data)
    if not (module.enabled and module.db.items) then
        return
    end
    local id = ItemTooltip.ItemID(data)
    local item = id and ITEMS[id]
    if item then
        local line, color = skillLine(item[1], item[2], L.GATHERTOOLTIPS_GATHERED)
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
    if types.Object then
        TooltipDataProcessor.AddTooltipPostCall(types.Object, onObject)
    end
    -- Probe: MinimapMouseover is Mainline's type for minimap pins.
    if types.MinimapMouseover then
        TooltipDataProcessor.AddTooltipPostCall(types.MinimapMouseover, onObject)
    end
    TooltipDataProcessor.AddTooltipPostCall(types.Unit, onUnit)
    ItemTooltip.OnInfo(onItem)
end

function module:OnDisable()
end
