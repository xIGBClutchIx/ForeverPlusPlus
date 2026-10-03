-- Talent plans: an ordered list of talent points, one node ID per point, checked against a
-- Classic talent tree's rules (points in the tab before a row opens, a maxed prerequisite before
-- an arrow's talent, a node's maximum rank). Pure logic with no frames, so tests/run.lua checks it.
--
-- A tree is { nodes = { [nodeID] = node }, order = { nodeID, ... } }, where a node is
-- { max = ranks, tab = groupID, req = points needed in that tab, prereqs = { { id, required } } }
-- and `order` lists the nodes top row first. A prerequisite with `required` must be maxed;
-- of the ones without it, any one maxed is enough (C_Traits' Required and Sufficient edges).
local _, ns = ...

local ipairs, max, remove = ipairs, math.max, table.remove

local TalentPlan = {}
ns.TalentPlan = TalentPlan

-- Classic gives the first talent point at level 10, then one each level.
TalentPlan.FIRST_LEVEL = 10

---Whether one more point can go into a node, after the points counted so far.
---@param tree table
---@param counts table nodeID -> ranks so far
---@param tabs table tab -> points so far
---@param id number nodeID
---@return boolean ok
---@return string? reason "unknown", "max", "tier" or "prereq"
function TalentPlan.CanTake(tree, counts, tabs, id)
    local node = tree.nodes[id]
    if not node then
        return false, "unknown"
    end
    if (counts[id] or 0) >= node.max then
        return false, "max"
    end
    if (tabs[node.tab] or 0) < (node.req or 0) then
        return false, "tier"
    end
    local any, anyMet = false, false
    for _, pre in ipairs(node.prereqs or {}) do
        local source = tree.nodes[pre.id]
        local met = source and (counts[pre.id] or 0) >= source.max
        if pre.required then
            if not met then
                return false, "prereq"
            end
        else
            any = true
            anyMet = anyMet or met
        end
    end
    if any and not anyMet then
        return false, "prereq"
    end
    return true
end

---Plays the plan's first `limit` points (all by default) in order.
---@param tree table
---@param picks table nodeIDs in order
---@param limit? number
---@return table counts nodeID -> ranks
---@return table tabs tab -> points
---@return number? bad the first point that breaks a rule, or nil when all are fine
---@return string? reason why it breaks one
function TalentPlan.Simulate(tree, picks, limit)
    local counts, tabs = {}, {}
    local last = limit and limit < #picks and limit or #picks
    for i = 1, last do
        local id = picks[i]
        local ok, reason = TalentPlan.CanTake(tree, counts, tabs, id)
        if not ok then
            return counts, tabs, i, reason
        end
        counts[id] = (counts[id] or 0) + 1
        local tab = tree.nodes[id].tab
        tabs[tab] = (tabs[tab] or 0) + 1
    end
    return counts, tabs
end

---Adds a point to a node at the end of the plan, when the rules and the points allow it.
---@param tree table
---@param picks table changed in place
---@param id number nodeID
---@param points number the most points the plan may hold
---@return boolean ok
---@return string? reason "points", or a reason from CanTake
function TalentPlan.Add(tree, picks, id, points)
    if #picks >= points then
        return false, "points"
    end
    local counts, tabs = TalentPlan.Simulate(tree, picks)
    local ok, reason = TalentPlan.CanTake(tree, counts, tabs, id)
    if not ok then
        return false, reason
    end
    picks[#picks + 1] = id
    return true
end

---Takes a node's last point out of the plan's first `limit` points, unless a later point needs it.
---@param tree table
---@param picks table changed in place
---@param id number nodeID
---@param limit? number
---@return boolean ok
---@return string? reason "none" (no point there) or "needed"
function TalentPlan.Remove(tree, picks, id, limit)
    local last = limit and limit < #picks and limit or #picks
    local index
    for i = last, 1, -1 do
        if picks[i] == id then
            index = i
            break
        end
    end
    if not index then
        return false, "none"
    end
    local rest = {}
    for i, pick in ipairs(picks) do
        if i ~= index then
            rest[#rest + 1] = pick
        end
    end
    local _, _, bad = TalentPlan.Simulate(tree, rest)
    if bad then
        return false, "needed"
    end
    remove(picks, index)
    return true
end

---An order for talents already learned (the game doesn't say which came first): top rows first,
---each point taken as soon as the rules allow it.
---@param tree table
---@param ranks table nodeID -> ranks learned
---@return table picks
function TalentPlan.FromRanks(tree, ranks)
    local picks, counts, tabs = {}, {}, {}
    local progress = true
    while progress do
        progress = false
        for _, id in ipairs(tree.order) do
            if (counts[id] or 0) < (ranks[id] or 0) and TalentPlan.CanTake(tree, counts, tabs, id) then
                picks[#picks + 1] = id
                counts[id] = (counts[id] or 0) + 1
                local tab = tree.nodes[id].tab
                tabs[tab] = (tabs[tab] or 0) + 1
                progress = true
                break
            end
        end
    end
    return picks
end

---The plan's next point that isn't learned yet.
---@param picks table
---@param ranks table nodeID -> ranks learned
---@return number? index its place in the plan
---@return number? id its nodeID
function TalentPlan.Next(picks, ranks)
    local counts = {}
    for i, id in ipairs(picks) do
        counts[id] = (counts[id] or 0) + 1
        if counts[id] > (ranks[id] or 0) then
            return i, id
        end
    end
end

---The level of the first talent point, from the player's level and the points they have earned,
---so a server that gives points differently is still counted right. With none earned yet, it's
---Classic's level 10.
---@param level number the player's level
---@param earned? number points earned (spent and unspent)
---@return number
function TalentPlan.FirstLevel(level, earned)
    if earned and earned > 0 then
        return level - earned + 1
    end
    return TalentPlan.FIRST_LEVEL
end

---How many talent points a character has at a level.
---@param level number
---@param first number the level of the first point
---@return number
function TalentPlan.PointsAt(level, first)
    return max(0, level - first + 1)
end

---The level a plan's point comes at.
---@param index number its place in the plan
---@param first number the level of the first point
---@return number
function TalentPlan.LevelOf(index, first)
    return first + index - 1
end
