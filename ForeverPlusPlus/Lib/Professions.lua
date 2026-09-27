-- The player's profession skills by skill line, read once and again only after they change.
-- Nothing is listened to until a module first asks.
local _, ns = ...

local type = type
local GetProfessions, GetProfessionInfo = GetProfessions, GetProfessionInfo

local Professions = {
    HERBALISM = 182,
    MINING = 186,
    SKINNING = 393,
}
ns.Professions = Professions

local known -- skill line -> { rank, name }, or nil until read
local listening = false

local function readable(value)
    return ns.IsReadable(value) and value ~= nil
end

local function add(index)
    if not index then
        return
    end
    local name, _, level, _, _, _, line, modifier = GetProfessionInfo(index)
    if readable(line) and readable(level) and type(level) == "number" then
        -- The modifier (from gear or racials) counts toward what the player can gather.
        local rank = level + (readable(modifier) and type(modifier) == "number" and modifier or 0)
        known[line] = { rank = rank, name = readable(name) and name or nil }
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

---The player's skill in a profession (with bonuses from gear) and its name in the client's
---language, or nil when the player doesn't have it. `line` is a skill line ID such as
---`Professions.HERBALISM`.
---@param line number
---@return number? rank
---@return string? name
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
        return info.rank, info.name
    end
end
