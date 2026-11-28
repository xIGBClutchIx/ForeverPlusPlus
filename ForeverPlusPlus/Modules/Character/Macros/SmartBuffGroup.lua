-- Macros' Smart Buff with Buff Your Group on: whom in the group the macro buffs next, and whether
-- with a buff's group version (Prayer of Fortitude, Gift of the Wild, a Greater Blessing). Only the
-- rules, with no frames and no calls to the game, so the offline tests run them; SmartBuff.lua
-- reads the group and hands them here.
local _, ns = ...

local ipairs = ipairs

local internal = ns.modules.Macros.internal

-- The members a group version of `entry` reaches from `member`: everyone, or those of their class.
-- Nil when it can't be told (a class that couldn't be read).
local function reachKey(entry, member)
    if entry.reach == "class" then
        return member.class
    end
    return "all"
end

---Whom the macro buffs next, and whether with the group version of their buff. `members` is the
---group in the order to buff it, you first: each `{ entry, class, ready }`, where `entry` is the
---buff they'd get from you (Data/Buffs.lua's) or nil when they need nothing, `class` their class
---token or nil, and `ready` whether they can be buffed now (alive, near enough). A group version
---(the entry's `reach`, "all" or "class") goes to the reach with the most members who'd get that
---buff, when at least `minimum` would and `canWide(entry)` says you can cast it now (it's known,
---and you have its reagent); a tie goes to the earliest member. Otherwise the first ready member
---who needs a buff gets their single one. Only ready members count. A class's group version
---(a Greater Blessing) also needs every member of that class, ready or not, to be getting that
---same buff: it would replace another Blessing of yours on one who isn't.
---@param members table[]
---@param minimum? number nil or 0: never a group version
---@param canWide fun(entry: table): boolean
---@return number? index the member to cast on, or nil when nobody ready needs anything
---@return boolean wide whether to cast the group version of their buff
---@return table<number, boolean> wideFor every member whose buff is better cast as its group version
function internal.PlanGroup(members, minimum, canWide)
    local wideFor = {}
    local counts = {} -- entry -> reach key -> how many ready members would get it
    local allowed = {} -- entry -> whether its group version can be cast now
    local mixed = {} -- class -> true when its members aren't all getting the same buff
    local classEntry = {} -- class -> the buff its members are getting (false for none)
    for _, member in ipairs(members) do
        local class = member.class
        if class then
            local entry = member.entry or false
            if classEntry[class] == nil then
                classEntry[class] = entry
            elseif classEntry[class] ~= entry then
                mixed[class] = true
            end
        end
    end
    if minimum and minimum > 0 then
        for _, member in ipairs(members) do
            local entry = member.ready and member.entry
            if entry and entry.reach then
                if allowed[entry] == nil then
                    allowed[entry] = canWide(entry) and true or false
                end
                local key = allowed[entry] and reachKey(entry, member)
                if key and not (entry.reach == "class" and mixed[key]) then
                    counts[entry] = counts[entry] or {}
                    counts[entry][key] = (counts[entry][key] or 0) + 1
                end
            end
        end
    end
    local best, bestCount, first
    for index, member in ipairs(members) do
        local entry = member.ready and member.entry
        if entry then
            first = first or index
            local key = counts[entry] and reachKey(entry, member)
            local count = key and counts[entry][key] or 0
            if count >= (minimum or 0) and count > 0 then
                wideFor[index] = true
                if not best or count > bestCount then
                    best, bestCount = index, count
                end
            end
        end
    end
    if best then
        return best, true, wideFor
    end
    return first, false, wideFor
end
