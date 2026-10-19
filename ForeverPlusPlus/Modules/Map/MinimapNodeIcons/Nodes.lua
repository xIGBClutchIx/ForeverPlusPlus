-- Minimap Node Icons' nodes: telling standing still from moving and the trail the dots' answers
-- leave meanwhile, following each node known where its dot should answer, and the finding pass
-- that looks the minimap over for new dots, run a round at a time by tick.
local _, ns = ...

local ipairs, min, abs, tremove = ipairs, math.min, math.abs, table.remove
local floor, sqrt = math.floor, math.sqrt
local Minimap, InCombatLockdown, GetTime = Minimap, InCombatLockdown, GetTime

local L = ns.L
local Professions = ns.Professions
local Requires = ns.GameData.Requires
local Profiler = ns.Profiler

local module = ns.modules.MinimapNodeIcons
local internal = module.internal

local PART_FOLLOW = Profiler.Part(module, L.MINIMAPNODEICONS_PART_FOLLOW)
local PART_FIND = Profiler.Part(module, L.MINIMAPNODEICONS_PART_FIND)

local STILL_FOLLOW = 0.33 -- seconds between rounds of following while standing still: dots don't move
local PER_TICK = 120 -- finding probes each tick, so a pass over the minimap takes a few ticks
-- Seconds between finding passes. Standing still, the minimap's dots seldom change; moving brings
-- new ground into view sooner.
local REST_STILL, REST_MOVING = 1.5, 0.3
local REACH = 1.5 -- finding hits this many probe spacings apart touch (diagonal neighbors are 1.41)
local FOLLOW_REACH = 14 -- how far (minimap units) each way of a dot's spot following probes look
local FOLLOW_STEP = 2 -- minimap units between following probes
local OWN_REACH = 6 -- minimap units from a followed dot within which a hit counts as that dot's
local MISSES = 4 -- ticks in a row a dot can not answer before its icon goes
local SAME_SPOT = 4 -- two dots of one name closer than this (minimap units) are one
local STILL_TICKS = 3 -- ticks without moving before the dots' answers are trusted again
local STILL_YARDS = 0.05 -- less movement than this in a tick is standing still
local LAG_SMOOTH = 0.5 -- how much of each new lag reading replaces the running one
local NUDGE = 0.25 -- how far a round of following moves a node toward its answer while moving
local NONE = internal.NONE

local inside, drawnAt, fromMinimap = internal.inside, internal.drawnAt, internal.fromMinimap
local moveNode = internal.moveNode
local probe, startProbing, stopProbing = internal.probe, internal.startProbing, internal.stopProbing
local currentSpace = internal.currentSpace

-- Standing still and lag --------------------------------------------------------------------------
-- While the player moves, where a dot answers trails where it's drawn by about the same vector for
-- every dot (in game, 2026-10-13). So the answers are only trusted for a node's spot after the
-- player has stood still a few ticks; while moving, the trail is measured from the nodes already
-- placed (answer minus where the icon is) and taken off any new dot found.

local stillTicks = 0 -- ticks in a row without moving
local lastX, lastY, lastAngle -- the player's spot and the minimap's angle at the last tick
local lagR, lagU = 0, 0 -- the running trail, minimap units
local lagKnown = false -- whether the trail was measured since the player last moved off

local function noteMovement(v)
    if not v then
        stillTicks = 0
        return
    end
    local moved = true
    if lastX then
        local east = (v.x - lastX) * v.width
        local north = (v.y - lastY) * v.height
        moved = east * east + north * north > STILL_YARDS * STILL_YARDS
            or (v.angle ~= lastAngle and abs(v.angle - lastAngle) > 0.001)
    end
    lastX, lastY, lastAngle = v.x, v.y, v.angle
    if moved then
        stillTicks = 0
    else
        stillTicks = stillTicks + 1
        if stillTicks >= STILL_TICKS then
            -- Measured afresh when the player moves off again: it depends on the direction.
            lagKnown = false
        end
    end
end

-- A new zone map: the last spot was on the old one.
function internal.forgetSpot()
    lastX = nil
end

local function still()
    return stillTicks >= STILL_TICKS
end
internal.still = still

-- The running trail, right and up in minimap units.
function internal.lag()
    return lagR, lagU
end

local function noteLag(dr, du)
    if lagKnown then
        lagR = lagR + (dr - lagR) * LAG_SMOOTH
        lagU = lagU + (du - lagU) * LAG_SMOOTH
    else
        lagR, lagU, lagKnown = dr, du, true
    end
end

-- Following ----------------------------------------------------------------------------------------

-- Probes a line across (or, with `vertical`, up through) a spot and returns the middle of the
-- probes that name `name`, and whether any of them named it in gray; nil when none did. Two dots
-- of one name can both be on the line: each is an unbroken run of probes that name it, and the
-- run whose middle is nearest the spot is this node's, not the middle of both.
local function scanLine(name, right, up, vertical, space)
    local best, bestGray -- the nearest run's middle so far, and whether it was gray
    local first, last, gray -- the run under way
    local function endRun()
        if first then
            local middle = (first + last) / 2
            if not best or abs(middle) < abs(best) then
                best, bestGray = middle, gray
            end
            first, last, gray = nil, nil, nil
        end
    end
    for offset = -FOLLOW_REACH, FOLLOW_REACH, FOLLOW_STEP do
        local r, u = right, up
        if vertical then
            u = up + offset
        else
            r = right + offset
        end
        local named = false
        if inside(r, u) then
            for _, entry in ipairs(probe(r, u, space) or NONE) do
                if entry.name == name then
                    named = true
                    first = first or offset
                    last = offset
                    gray = gray or entry.gray
                    break
                end
            end
            if internal.blocked then
                return nil
            end
        end
        if not named then
            endRun()
        end
    end
    endRun()
    if best then
        return best, bestGray
    end
end

-- Where a dot named `name` answers near a spot: the middle of what names it up through the spot,
-- then across that, or across first when nothing answers up through it. Nil when nothing does.
local function locate(name, right, up, space)
    local du, gray = scanLine(name, right, up, true, space)
    if du then
        up = up + du
        local dr, gray2 = scanLine(name, right, up, false, space)
        if dr then
            right = right + dr
        end
        return right, up, gray or gray2 or false
    end
    local dr = scanLine(name, right, up, false, space)
    if dr then
        right = right + dr
        du, gray = scanLine(name, right, up, true, space)
        if du then
            up = up + du
        end
        return right, up, gray or false
    end
end

-- Looks for each node again where its dot should answer: where its icon is, plus the trail while
-- the player moves. Standing still, the answer fixes the node's spot; moving, it measures the
-- trail. A node that doesn't answer a few ticks running, or left the minimap, goes.
local function followAll(v, space)
    local nodes = internal.nodes
    local trusted = still()
    if not v then
        lagKnown = false
    end
    for i = #nodes, 1, -1 do
        local node = nodes[i]
        local right, up = drawnAt(node, v)
        local guessR, guessU = right, up
        if v and node.x and not trusted and lagKnown then
            guessR, guessU = right + lagR, up + lagU
        end
        local foundR, foundU, gray = locate(node.name, guessR, guessU, space)
        if internal.blocked then
            return
        end
        if foundR then
            node.misses = 0
            node.level = gray
            node.right, node.up = foundR, foundU
            if v then
                if trusted or not node.x then
                    -- Standing still the answer is where the dot is. A node without a spot yet
                    -- (found with no view) takes this one, trail and all, until the player stops.
                    moveNode(node, fromMinimap(v, foundR, foundU))
                else
                    noteLag(foundR - right, foundU - up)
                    -- Moving, the answer less the trail is where the dot is, give or take: the
                    -- spot creeps toward it each round, so there's little left to fix on stopping.
                    local x, y = fromMinimap(v, foundR - lagR, foundU - lagU)
                    moveNode(node, node.x + (x - node.x) * NUDGE, node.y + (y - node.y) * NUDGE)
                end
            end
        else
            node.misses = node.misses + 1
        end
        local nowR, nowU = drawnAt(node, v)
        if node.misses >= MISSES or not inside(nowR, nowU) then
            tremove(nodes, i)
        end
    end
    -- Two nodes of one name that met are one.
    for i = #nodes, 2, -1 do
        local a = nodes[i]
        local ar, au = drawnAt(a, v)
        for j = 1, i - 1 do
            local b = nodes[j]
            if a.name == b.name then
                local br, bu = drawnAt(b, v)
                local dr, du = ar - br, au - bu
                if dr * dr + du * du <= SAME_SPOT * SAME_SPOT then
                    tremove(nodes, i)
                    break
                end
            end
        end
    end
end

-- Finding ------------------------------------------------------------------------------------------

-- internal.pass is the finding pass under way: { index, hits, space, spacing, points }, or nil.

local function newPass()
    local STEPS = internal.STEPS
    local spacing = STEPS[module.db.detail] or STEPS.medium
    return { index = 1, hits = {}, space = currentSpace(), spacing = spacing,
        points = internal.grid(Minimap:GetWidth() / 2, spacing) }
end

-- The followed node of that name nearest where a dot answered, within `reach`, and where its own
-- dot answers (while moving, its icon plus the trail); nil when there's none that close.
local function nearestKnown(name, right, up, v, reach)
    local best, bestR, bestU, bestD
    for _, node in ipairs(internal.nodes) do
        if node.name == name then
            local nr, nu = drawnAt(node, v)
            if v and node.x and not still() and lagKnown then
                nr, nu = nr + lagR, nu + lagU
            end
            local dr, du = nr - right, nu - up
            local d = dr * dr + du * du
            if d <= reach * reach and (not bestD or d < bestD) then
                best, bestR, bestU, bestD = node, nr, nu, d
            end
        end
    end
    return best, bestR, bestU
end

local function known(name, right, up, v, reach)
    return nearestKnown(name, right, up, v, reach) ~= nil
end

-- Whether two spots that both answer `name` are one dot: every probe on the line between them
-- names it too. Two dots side by side have a gap between them that answers something else.
local function joined(name, ar, au, br, bu, space)
    local dr, du = br - ar, bu - au
    local steps = floor(sqrt(dr * dr + du * du) / FOLLOW_STEP)
    for k = 1, steps - 1 do
        local t = k / steps
        local named = false
        for _, entry in ipairs(probe(ar + dr * t, au + du * t, space) or NONE) do
            if entry.name == name then
                named = true
                break
            end
        end
        if internal.blocked then
            return true -- can't tell: leave it to the next pass
        end
        if not named then
            return false
        end
    end
    return true
end

-- Adds a node for a dot that answered at a spot. Moving, the trail is taken off before the spot
-- is placed on the map: the one measured now, or else the last one measured, which is closer than
-- none; following corrects it from there.
local function addNode(name, icon, right, up, gray, v)
    local node = { name = name, icon = icon, right = right, up = up, level = gray, misses = 0,
        standing = internal.standing(name) }
    if v then
        local placeR, placeU = right, up
        if not still() then
            placeR, placeU = right - lagR, up - lagU
        end
        node.x, node.y = fromMinimap(v, placeR, placeU)
    end
    local nodes = internal.nodes
    nodes[#nodes + 1] = node
end

-- Turns a finished pass's hits into nodes: hits of one name that touch are one dot, at their
-- middle. Dots already followed are left to following. Hits on a followed dot are set aside
-- first, so a second dot of the same name right beside it isn't taken for part of it, and what's
-- left near a followed dot is a new one only with a gap between them.
local function finishPass(v)
    local pass = internal.pass
    local hits = pass.hits
    if not module.db.calibration.space then
        if #hits > 0 then
            module.db.calibration.space = pass.space
        else
            internal.nextSpace()
        end
    end
    local reach = pass.spacing * REACH
    -- Moving before the trail is measured, a followed dot answers somewhere near its icon, not on
    -- it: then anything within following's reach counts as it, as before, so it isn't found twice.
    local own = (not v or still() or lagKnown) and OWN_REACH or FOLLOW_REACH
    local fresh = {}
    for _, hit in ipairs(hits) do
        if not known(hit.name, hit.right, hit.up, v, own) then
            fresh[#fresh + 1] = hit
        end
    end
    hits = fresh
    local taken = {}
    for i, first in ipairs(hits) do
        if not taken[i] then
            taken[i] = true
            local queue, at = { first }, 1
            local sumR, sumU, gray = 0, 0, false
            while at <= #queue do
                local a = queue[at]
                at = at + 1
                sumR, sumU = sumR + a.right, sumU + a.up
                gray = gray or a.gray
                for j, b in ipairs(hits) do
                    if not taken[j] and b.name == a.name then
                        local dr, du = a.right - b.right, a.up - b.up
                        if dr * dr + du * du <= reach * reach then
                            taken[j] = true
                            queue[#queue + 1] = b
                        end
                    end
                end
            end
            -- The hits' middle can fall between two dots (their edges, left after the hits on
            -- each were set aside), so the dot is looked for from there, as following does: it's
            -- the nearest one that answers, or nothing.
            local right, up = locate(first.name, sumR / #queue, sumU / #queue, pass.space)
            if internal.blocked then
                break
            end
            if right then
                -- Near a dot already followed, it's a dot of its own only if something else answers
                -- between them; otherwise it's that one again.
                local near, nr, nu = nearestKnown(first.name, right, up, v, FOLLOW_REACH)
                local separate = not near
                if near and own == OWN_REACH then
                    local dr, du = nr - right, nu - up
                    separate = dr * dr + du * du > OWN_REACH * OWN_REACH
                        and not joined(first.name, nr, nu, right, up, pass.space)
                end
                if separate then
                    addNode(first.name, first.icon, right, up, gray, v)
                end
            end
        end
    end
    internal.pass = nil
end

-- Probes the next `count` spots of the finding pass.
local function find(count, v)
    internal.pass = internal.pass or newPass()
    local pass = internal.pass
    local seen = internal.seen
    local list = pass.points
    local last = min(pass.index + count - 1, #list)
    for i = pass.index, last do
        local right, up = list[i][1], list[i][2]
        local found = probe(right, up, pass.space) or NONE
        for k, entry in ipairs(found) do
            local icon = internal.iconFor(entry.name)
            if icon then
                pass.hits[#pass.hits + 1] = { name = entry.name, icon = icon, right = right, up = up,
                    gray = entry.gray }
            else
                -- Blizzard's "Requires Herbalism (75)" under a name says what that node takes.
                local skill, need = Requires(entry.name)
                if skill then
                    if k > 1 then
                        Professions.LearnRequirement(found[k - 1].name, skill, need)
                    end
                else
                    seen[entry.name] = true
                end
            end
        end
        if internal.blocked then
            internal.pass = nil
            return
        end
    end
    pass.index = last + 1
    if pass.index > #list then
        finishPass(v)
    end
end

-- Rounds of probes ---------------------------------------------------------------------------------

local sinceFollow = 0 -- seconds since the dots were last followed
local restUntil = 0 -- when the next finding pass may start

-- A round of probes: following, then a part of the finding pass, or a rest between passes.
function internal.tick(v)
    noteMovement(v)
    if internal.blocked or InCombatLockdown() or Minimap:IsMouseOver() then
        return
    end
    startProbing()
    local space = currentSpace()
    -- Standing still the dots don't move, so they're followed a few times a second rather than
    -- every tick: still often enough to see one gathered. A finding pass goes on every tick until
    -- it's done, then rests.
    sinceFollow = sinceFollow + internal.TICK
    if not still() or sinceFollow >= STILL_FOLLOW then
        sinceFollow = 0
        Profiler.Call(PART_FOLLOW, followAll, v, space)
    end
    if not internal.blocked then
        -- Asked to look everything over (a zoom, a new map): a new pass now, spread over ticks like
        -- any other rather than all in one frame.
        if internal.findAll then
            internal.findAll, internal.pass, restUntil = false, nil, 0
        end
        if internal.pass or GetTime() >= restUntil then
            Profiler.Call(PART_FIND, find, PER_TICK, v)
            if not internal.pass then -- that finished the pass: rest before the next
                restUntil = GetTime() + (still() and REST_STILL or REST_MOVING)
            end
        end
    end
    stopProbing()
end
