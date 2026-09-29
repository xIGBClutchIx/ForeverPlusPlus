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
    LOCKPICKING = 633,
    BLACKSMITHING = 164,
}
ns.Professions = Professions

-- Blizzard's difficulty colors, the same a trainer uses for recipes. Probe: QuestDifficultyColors
-- is FrameXML's; the values after it are its own.
local COLORS = QuestDifficultyColors or {}
local RED = COLORS.impossible or { r = 1, g = 0.1, b = 0.1 }
local ORANGE = COLORS.verydifficult or { r = 1, g = 0.5, b = 0.25 }
-- Yellow is fixed at the classic (1, 1, 0): this client's QuestDifficultyColors.difficult can be
-- close to the gold of a tooltip title, so "often" wouldn't stand out from the name.
local YELLOW = { r = 1, g = 1, b = 0 }
local GREEN = COLORS.standard or { r = 0.25, g = 0.75, b = 0.25 }
local GRAY = COLORS.trivial or { r = 0.5, g = 0.5, b = 0.5 }
Professions.STANDARD = GREEN -- Blizzard's green for a quest at your level, for "enough"

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

-- Lockpicking isn't a profession in the list above: rogues have it as a skill they learn with
-- Pick Lock, and, as in Classic, it's five times their level up to 300. Probe: the spell book
-- call is Mainline's, the plain global is Classic's.
local PICK_LOCK = 1804
local LOCKPICKING_CAP = 300

local function knowsPickLock()
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(PICK_LOCK)
    end
    return IsSpellKnown and IsSpellKnown(PICK_LOCK)
end

local function lockpicking()
    if not knowsPickLock() then
        return nil
    end
    local level = UnitLevel("player")
    if not (readable(level) and type(level) == "number") then
        return nil
    end
    local rank = level * 5
    if rank > LOCKPICKING_CAP then
        rank = LOCKPICKING_CAP
    end
    local name, icon
    if C_Spell and C_Spell.GetSpellTexture then
        icon = C_Spell.GetSpellTexture(PICK_LOCK)
    end
    -- Probe: the skill line's own name, when the client has profession info for it.
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(Professions.LOCKPICKING)
        name = info and readable(info.professionName) and info.professionName ~= "" and info.professionName or nil
    end
    return rank, name, readable(icon) and icon or nil
end

---The player's skill in a profession (with bonuses from gear), its name in the client's language,
---and its icon, or nil when the player doesn't have it. `line` is a skill line ID such as
---`Professions.HERBALISM`. For `Professions.LOCKPICKING` it's the rogue's Lockpicking skill.
---@param line number
---@return number? rank
---@return string? name
---@return number|string|nil icon
function Professions.Rank(line)
    if line == Professions.LOCKPICKING then
        return lockpicking()
    end
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
