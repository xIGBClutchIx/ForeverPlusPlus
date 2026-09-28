-- The player's profession skills by skill line, read once and again only after they change.
-- Nothing is listened to until a module first asks.
local _, ns = ...

local type = type
local GetProfessions, GetProfessionInfo = GetProfessions, GetProfessionInfo

local Professions = {
    HERBALISM = 182,
    MINING = 186,
    SKINNING = 393,
    FISHING = 356,
}
ns.Professions = Professions

-- Blizzard's difficulty colors, the same a trainer uses for recipes. Probe: QuestDifficultyColors
-- is FrameXML's; the values after it are its own.
local COLORS = QuestDifficultyColors or {}
local RED = COLORS.impossible or { r = 1, g = 0.1, b = 0.1 }
local ORANGE = COLORS.verydifficult or { r = 1, g = 0.5, b = 0.25 }
local YELLOW = COLORS.difficult or { r = 1, g = 1, b = 0 }
local GREEN = COLORS.standard or { r = 0.25, g = 0.75, b = 0.25 }
local GRAY = COLORS.trivial or { r = 0.5, g = 0.5, b = 0.5 }

---How hard gathering something that needs `need` is at skill `rank`, as a color (r, g, b): red
---can't yet, then orange (a skill point every time), yellow (often), green (sometimes), and gray
---(never). Without a rank (the player doesn't have the profession) it's red.
---@param rank number?
---@param need number
---@return table color
function Professions.Difficulty(rank, need)
    if not rank or rank < need then
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

---The Skinning skill a creature of `level` needs.
---@param level number
---@return number
function Professions.SkinningNeed(level)
    if level <= 10 then
        return 1
    elseif level <= 20 then
        return level * 10 - 100
    end
    return level * 5
end

local known -- skill line -> { rank, name }, or nil until read
local listening = false

local function readable(value)
    return ns.IsReadable(value) and value ~= nil
end

local function add(index)
    if not index then
        return
    end
    local name, icon, level, _, _, _, line, modifier = GetProfessionInfo(index)
    if readable(line) and readable(level) and type(level) == "number" then
        -- The modifier (from gear or racials) counts toward what the player can gather.
        local rank = level + (readable(modifier) and type(modifier) == "number" and modifier or 0)
        known[line] = { rank = rank, name = readable(name) and name or nil,
            icon = readable(icon) and icon or nil }
    end
end

local function read()
    known = {}
    -- Two primary professions, archaeology, fishing, cooking; any may be nil.
    local first, second, archaeology, fishing, cooking = GetProfessions()
    add(first)
    add(second)
    add(archaeology)
    add(fishing)
    add(cooking)
end

local function forget()
    known = nil
end

---The player's skill in a profession (with bonuses from gear), its name in the client's language,
---and its icon, or nil when the player doesn't have it. `line` is a skill line ID such as
---`Professions.HERBALISM`.
---@param line number
---@return number? rank
---@return string? name
---@return number|string|nil icon
function Professions.Rank(line)
    if not (GetProfessions and GetProfessionInfo) then
        return nil
    end
    if not listening then
        listening = true
        ns.On("SKILL_LINES_CHANGED", forget)
        ns.On("CHAT_MSG_SKILL", forget)
    end
    if not known then
        read()
    end
    local info = known[line]
    if info then
        return info.rank, info.name, info.icon
    end
end
