-- Minimap Node Icons: the herb or ore a tracking dot on the minimap stands for, as that item's
-- icon over the dot, optionally gray for a node on another level (as in a cave), red while the
-- player's skill is too low to gather it, or gray once gathering it no longer raises the skill.
--
-- The game draws the dots itself, lists them nowhere an addon can read, and has no way to change
-- or hide one (Forever's minimap has no SetBlipTexture). But its minimap has UpdateMouseoverAtPoint,
-- which points its mouseover at a spot as if a controller's cursor were there, and the tooltip
-- data for the mouseover names what is under that spot. So:
--   - Finding: the whole minimap is probed on a grid, a few rows each frame, and a patch of probes
--     that read the same name is a dot, at the patch's middle. A zoom finds them all at once.
--   - Following: every frame, each dot found is probed again along a short line across it and one
--     up through it, and its icon goes to the middle of what reads its name. So an icon stays on
--     its dot as the player moves or turns, without working out yards or facing, and a dot that
--     stops answering (gathered, or out of range) loses its icon. On a zoom, each icon first moves
--     by the change in the minimap's view radius, which keeps it near enough for following.
-- Probing stops in combat and while the cursor is on the minimap, where the game's own mouseover
-- and tooltip (which the icons let through) are the player's.
--
-- Names are matched in English through Professions.NODES. Any other name is learned the first
-- time the player gathers it: the spell's target, then the first item in the loot window; a
-- learned node has no known skill, so it's never tinted. Ideas from NodeSight; none of its code.
local _, ns = ...

local ipairs, type, pcall, floor, tonumber = ipairs, type, pcall, math.floor, tonumber
local gmatch, match, tostring, format = string.gmatch, string.match, tostring, string.format
local min, max, concat, tremove = math.min, math.max, table.concat, table.remove
local CreateFrame, Minimap, GetTime, C_Timer = CreateFrame, Minimap, GetTime, C_Timer
local GetCursorPosition = GetCursorPosition
local C_Minimap, C_TooltipInfo, C_Item = C_Minimap, C_TooltipInfo, C_Item
local InCombatLockdown = InCombatLockdown
local GetNumLootItems, GetLootSlotInfo = GetNumLootItems, GetLootSlotInfo

local L = ns.L
local readable = ns.IsReadable
local plain = ns.Text.Plain
local Professions = ns.Professions
local NODES = Professions.NODES

local module = ns.NewModule("MinimapNodeIcons", L.MINIMAPNODEICONS_DESC, {
    enabled = true,
    size = 8, -- icon size on the minimap
    border = true, -- a gold ring around each icon
    levels = true, -- gray while the minimap names the node in gray (another level)
    tint = false, -- red while the skill is too low
    gray = false, -- gray once gathering no longer raises the skill
    detail = "medium", -- a key of STEPS
    chat = true,
    -- Node name -> icon, for names not in NODES, from what gathering them gave. Data, not a setting.
    learned = {},
    -- { space = a key of SPACES }, once a sweep has found a node with it. Data, not a setting.
    calibration = {},
})
module.title = L.MINIMAPNODEICONS_TITLE
module.category = "map"
module.added = "0.9.0"

module.options = {
    {
        key = "size", name = L.MINIMAPNODEICONS_SIZE, description = L.MINIMAPNODEICONS_SIZE_DESC,
        min = 5, max = 20, step = 1, format = "%d",
    },
    { key = "border", name = L.MINIMAPNODEICONS_BORDER, description = L.MINIMAPNODEICONS_BORDER_DESC },
    { key = "levels", name = L.MINIMAPNODEICONS_LEVELS, description = L.MINIMAPNODEICONS_LEVELS_DESC },
    { key = "tint", name = L.MINIMAPNODEICONS_TINT, description = L.MINIMAPNODEICONS_TINT_DESC },
    { key = "gray", name = L.MINIMAPNODEICONS_GRAY, description = L.MINIMAPNODEICONS_GRAY_DESC },
    {
        key = "detail", name = L.MINIMAPNODEICONS_DETAIL, description = L.MINIMAPNODEICONS_DETAIL_DESC,
        choices = {
            { "low", L.MINIMAPNODEICONS_DETAIL_LOW },
            { "medium", L.MINIMAPNODEICONS_DETAIL_MEDIUM },
            { "high", L.MINIMAPNODEICONS_DETAIL_HIGH },
        },
    },
    ns.ChatOption(L.MINIMAPNODEICONS_CHAT_DESC),
}

module.actions = {
    {
        name = L.MINIMAPNODEICONS_CLEAR,
        button = L.MINIMAPNODEICONS_CLEAR_BUTTON,
        description = L.MINIMAPNODEICONS_CLEAR_DESC,
        confirm = L.MINIMAPNODEICONS_CLEAR_CONFIRM,
        fn = function()
            module.db.learned = {}
            ns.Print(L.MINIMAPNODEICONS_CLEAR_DONE)
        end,
    },
}

-- Forever only: the minimap's UpdateMouseoverAtPoint is in its API docs (1.60.1).
function module:IsAvailable()
    return Minimap and Minimap.UpdateMouseoverAtPoint and C_TooltipInfo
        and C_TooltipInfo.GetMinimapMouseover and true or false
end

local HERBS, MINERALS = 2383, 2580 -- Find Herbs, Find Minerals

local STEPS = { low = 8, medium = 6, high = 4 } -- minimap units between finding probes
local PER_FRAME = 40 -- finding probes each frame, so a pass over the minimap takes a few frames
local REACH = 1.5 -- finding hits this many probe spacings apart touch (diagonal neighbors are 1.41)
local FOLLOW_REACH = 12 -- how far (minimap units) each way of a dot following probes look
local FOLLOW_STEP = 2 -- minimap units between following probes
local MISSES = 3 -- frames in a row a dot can not answer before its icon goes
local SAME_SPOT = 4 -- two dots of one name closer than this (minimap units) are one
local EDGE = 2 -- keep probes and icons this far inside the minimap's edge
local LEARN_WAIT = 10 -- seconds from a cast to its loot window that still count as one gather
local RED = { 1, 0.25, 0.25 } -- the icon's vertex color while the skill is too low
local GRAY = { 0.7, 0.7, 0.7 } -- dims a gray (desaturated) icon
local NONE = {}

-- The icon for a node's name, or nil for a name that isn't a node we know.
local function iconFor(name)
    local learned = module.db.learned[name]
    if learned then
        return learned
    end
    local node = NODES[name]
    return node and C_Item.GetItemIconByID(node[3])
end

-- How the player's skill stands against the node named `name`: "low" when it's too low to gather
-- (or they lack the profession), "gray" when gathering it no longer raises the skill, else nil,
-- as for a node whose skill isn't known.
local function standing(name)
    local node = NODES[name]
    if not node then
        return nil
    end
    local rank = Professions.Rank(node[1])
    if not rank or rank < node[2] then
        return "low"
    elseif Professions.Difficulty(rank, node[2]) == Professions.TRIVIAL then
        return "gray"
    end
end

-- Probing ---------------------------------------------------------------------------------------

local blocked = false -- the client refused a probe; stop until /reload

-- What UpdateMouseoverAtPoint's point is measured in isn't documented (see docs/forever-api.md), so
-- each way it could be is tried until a pass finds a node, and the one that does is saved. Each
-- turns minimap units right and up of its center into that space.
local SPACES = {
    -- Screen pixels from the bottom left, like GetCursorPosition.
    cursor = function(right, up)
        local cx, cy = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        return (cx + right) * scale, (cy + up) * scale
    end,
    -- Minimap units from its center.
    center = function(right, up)
        return right, up
    end,
    -- Minimap units from its bottom left.
    corner = function(right, up)
        return Minimap:GetWidth() / 2 + right, Minimap:GetHeight() / 2 + up
    end,
    -- 0 to 1 across and up the minimap.
    unit = function(right, up)
        return 0.5 + right / Minimap:GetWidth(), 0.5 + up / Minimap:GetHeight()
    end,
}
local ORDER = { "cursor", "center", "corner", "unit" }
local trying = 1 -- the space in ORDER tried while none is saved

local function currentSpace()
    return module.db.calibration.space or ORDER[trying]
end

-- A line's own color as r, g, b, or nil. Tooltip data colors are color mixins or plain tables.
local function lineColor(line)
    local color = line.leftColor
    if not (color and readable(color) and type(color) == "table") then
        return nil
    end
    if color.GetRGB then
        return color:GetRGB()
    end
    return color.r, color.g, color.b
end

-- Whether a name's color is gray rather than white or a color: how the minimap may name a node on
-- another level than the player, as in a cave. Unverified; /fpp nodes here prints the color.
local function isGray(r, g, b)
    if not (r and g and b and readable(r) and readable(g) and readable(b)) then
        return false
    end
    local high, low = max(r, g, b), min(r, g, b)
    return high < 0.8 and high - low < 0.08
end

-- The names in a line of a probe's text, one per row (overlapping dots each add one), without the
-- color codes and spaces the game may wrap them in, each with its color: its own color code, or
-- else the line's.
local function addNames(list, text, r, g, b)
    for row in gmatch(text, "[^\n]+") do
        local hex = match(row, "|c%x%x(%x%x%x%x%x%x)")
        local cr, cg, cb = r, g, b
        if hex then
            cr = tonumber(hex:sub(1, 2), 16) / 255
            cg = tonumber(hex:sub(3, 4), 16) / 255
            cb = tonumber(hex:sub(5, 6), 16) / 255
        end
        local name = match(plain(row), "^%s*(.-)%s*$")
        if name ~= "" then
            list[#list + 1] = { name = name, gray = isGray(cr, cg, cb), r = cr, g = cg, b = cb }
        end
    end
end

-- What the minimap's mouseover names now: a list of { name, gray, r, g, b }, or nil.
local function readMouseover()
    local data = C_TooltipInfo.GetMinimapMouseover()
    local lines = data and data.lines
    if not (lines and readable(lines) and type(lines) == "table") then
        return nil
    end
    local list
    for _, line in ipairs(lines) do
        local left = line.leftText
        if readable(left) and type(left) == "string" and left ~= "" then
            list = list or {}
            addNames(list, left, lineColor(line))
        end
    end
    return list
end

-- Points the minimap's mouseover at a spot right and up of its center and returns what it names
-- there, as readMouseover does. Call between startProbing and stopProbing.
local function probe(right, up, space)
    local x, y = (SPACES[space] or SPACES.cursor)(right, up)
    local ok, err = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, x, y)
    if not ok then
        blocked = true
        module:Print(format(L.MINIMAPNODEICONS_FAILED, tostring(err)))
        return nil
    end
    return readMouseover()
end

-- The minimap takes a probe's point only in soft cursor mode (a controller's cursor); otherwise
-- the mouse's spot wins and every probe reads nothing (in game, 2026-10-13). So probes run between
-- these two: on, then the point off the minimap and back to the mouse. This would also end a real
-- controller's soft cursor on the minimap; it takes it up again as it moves.
local function startProbing()
    if Minimap.SetUsingSoftCursor then
        pcall(Minimap.SetUsingSoftCursor, Minimap, true)
    end
end

local function stopProbing()
    pcall(Minimap.UpdateMouseoverAtPoint, Minimap, -10000, -10000)
    if Minimap.SetUsingSoftCursor then
        pcall(Minimap.SetUsingSoftCursor, Minimap, false)
    end
end

-- The spots a finding pass probes, right and up of the minimap's center, inside its circle.
local points, pointsFor

local function grid(half, spacing)
    local key = half .. ":" .. spacing
    if pointsFor == key then
        return points
    end
    points, pointsFor = {}, key
    local radius = half - EDGE
    local n = floor(radius / spacing)
    for i = -n, n do
        for j = -n, n do
            local right, up = i * spacing, j * spacing
            if right * right + up * up <= radius * radius then
                points[#points + 1] = { right, up }
            end
        end
    end
    return points
end

-- Dots ------------------------------------------------------------------------------------------

-- The dots found: { name, icon, right, up, level, misses, standing }, in minimap units right and
-- up of its center. `level` is true while the minimap names it in gray (on another level).
local nodes = {}
local seen = {} -- names the minimap showed that aren't nodes we know, for learning
local tracking = false -- Find Herbs or Find Minerals is on

local function readTracking()
    tracking = false
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(i)
        if type(info) == "table" and info.active and (info.spellID == HERBS or info.spellID == MINERALS) then
            tracking = true
            return
        end
    end
    nodes = {}
end

local function inside(right, up)
    local radius = Minimap:GetWidth() / 2 - EDGE
    return right * right + up * up <= radius * radius
end

-- Following ----------------------------------------------------------------------------------------

-- Probes a line across (or, with `vertical`, up through) a spot and returns the middle of the
-- probes that name `name`, and whether any of them named it in gray; nil when none did.
local function scanLine(name, right, up, vertical, space)
    local first, last, gray
    for offset = -FOLLOW_REACH, FOLLOW_REACH, FOLLOW_STEP do
        local r, u = right, up
        if vertical then
            u = up + offset
        else
            r = right + offset
        end
        if inside(r, u) then
            for _, entry in ipairs(probe(r, u, space) or NONE) do
                if entry.name == name then
                    first = first or offset
                    last = offset
                    gray = gray or entry.gray
                    break
                end
            end
            if blocked then
                return nil
            end
        end
    end
    if first then
        return (first + last) / 2, gray
    end
end

-- Moves a dot's icon to where the dot is now: the middle of what names it up through its last
-- spot, then across that. A dot that moved further than the line reaches is looked for across
-- first. Returns false when it wasn't found.
local function follow(node, space)
    local name = node.name
    local du, gray = scanLine(name, node.right, node.up, true, space)
    if du then
        node.up = node.up + du
        local dr, gray2 = scanLine(name, node.right, node.up, false, space)
        if dr then
            node.right = node.right + dr
        end
        node.level = gray or gray2 or false
        return true
    end
    local dr = scanLine(name, node.right, node.up, false, space)
    if dr then
        node.right = node.right + dr
        du, gray = scanLine(name, node.right, node.up, true, space)
        if du then
            node.up = node.up + du
        end
        node.level = gray or false
        return true
    end
    return false
end

local function followAll(space)
    for i = #nodes, 1, -1 do
        local node = nodes[i]
        if follow(node, space) then
            node.misses = 0
        else
            node.misses = node.misses + 1
        end
        if blocked then
            return
        end
        if node.misses >= MISSES or not inside(node.right, node.up) then
            tremove(nodes, i)
        end
    end
    -- Two dots of one name that met are one.
    for i = #nodes, 2, -1 do
        local a = nodes[i]
        for j = 1, i - 1 do
            local b = nodes[j]
            local dr, du = a.right - b.right, a.up - b.up
            if a.name == b.name and dr * dr + du * du <= SAME_SPOT * SAME_SPOT then
                tremove(nodes, i)
                break
            end
        end
    end
end

-- Finding ------------------------------------------------------------------------------------------

local pass -- the finding pass under way: { index, hits, space, spacing, points }, or nil

local function newPass()
    local spacing = STEPS[module.db.detail] or STEPS.medium
    return { index = 1, hits = {}, space = currentSpace(), spacing = spacing,
        points = grid(Minimap:GetWidth() / 2, spacing) }
end

-- Whether a dot of that name is followed already near a spot.
local function known(name, right, up)
    for _, node in ipairs(nodes) do
        local dr, du = node.right - right, node.up - up
        if node.name == name and dr * dr + du * du <= FOLLOW_REACH * FOLLOW_REACH then
            return true
        end
    end
    return false
end

-- Turns a finished pass's hits into dots: hits of one name that touch are one dot, at their
-- middle. Dots already followed are left to following.
local function finishPass()
    local hits = pass.hits
    if not module.db.calibration.space then
        if #hits > 0 then
            module.db.calibration.space = pass.space
        else
            trying = trying % #ORDER + 1
        end
    end
    local reach = pass.spacing * REACH
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
            local right, up = sumR / #queue, sumU / #queue
            if not known(first.name, right, up) then
                nodes[#nodes + 1] = { name = first.name, icon = first.icon, right = right, up = up,
                    level = gray, misses = 0, standing = standing(first.name) }
            end
        end
    end
    pass = nil
end

-- Probes the next `count` spots of the finding pass (all of them without a count).
local function find(count)
    pass = pass or newPass()
    local list = pass.points
    local last = count and min(pass.index + count - 1, #list) or #list
    for i = pass.index, last do
        local right, up = list[i][1], list[i][2]
        for _, entry in ipairs(probe(right, up, pass.space) or NONE) do
            local icon = iconFor(entry.name)
            if icon then
                pass.hits[#pass.hits + 1] = { name = entry.name, icon = icon, right = right, up = up,
                    gray = entry.gray }
            else
                seen[entry.name] = true
            end
        end
        if blocked then
            pass = nil
            return
        end
    end
    pass.index = last + 1
    if pass.index > #list then
        finishPass()
    end
end

-- Drawing ---------------------------------------------------------------------------------------

local frame -- over the minimap; holds the icons and runs the probes
local pins = {}
local findAll = false -- find every dot this frame, after a zoom

-- The gold ring of the minimap's tracking button, which Blizzard also puts around a 24 pixel spec
-- icon (ItemDisplay.xml): the 64 pixel file with the icon's center 19 right and 18 down of its
-- corner. Scaled to the icon here.
local RING = "Interface\\Minimap\\MiniMap-TrackingBorder"
local RING_ICON, RING_FILE, RING_X, RING_Y = 24, 64, 19, 18

-- A pin: the icon, round, with the ring around it. It takes no mouse, so the minimap's own
-- tooltip for the dot under it shows, with whatever other addons (Profession Tooltips) add.
local function getPin(i)
    local pin = pins[i]
    if not pin then
        pin = CreateFrame("Frame", nil, frame)
        local icon = pin:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- A round icon, like the minimap's own. Probe: the mask is Mainline's portrait mask.
        local mask = pin:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE",
            "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
        local ring = pin:CreateTexture(nil, "OVERLAY")
        ring:SetTexture(RING)
        pin.icon, pin.ring = icon, ring
        pins[i] = pin
    end
    return pin
end

local function hidePins(from)
    for i = from or 1, #pins do
        pins[i]:Hide()
    end
end

-- Puts the ring around a pin of `size`, or hides it.
local function placeRing(pin, size, shown)
    local ring = pin.ring
    if not shown then
        ring:Hide()
        return
    end
    local k = size / RING_ICON
    ring:SetSize(RING_FILE * k, RING_FILE * k)
    ring:ClearAllPoints()
    ring:SetPoint("TOPLEFT", pin, "CENTER", -RING_X * k, RING_Y * k)
    ring:Show()
end

local function draw()
    local db = module.db
    local size = db.size
    local shown = 0
    for _, node in ipairs(nodes) do
        shown = shown + 1
        local pin = getPin(shown)
        local icon = pin.icon
        icon:SetTexture(node.icon)
        local grayed = (db.gray and node.standing == "gray") or (db.levels and node.level) or false
        icon:SetDesaturated(grayed)
        if db.tint and node.standing == "low" then
            icon:SetVertexColor(RED[1], RED[2], RED[3])
        elseif grayed then
            icon:SetVertexColor(GRAY[1], GRAY[2], GRAY[3])
        else
            icon:SetVertexColor(1, 1, 1)
        end
        pin:SetSize(size, size)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER", node.right, node.up)
        pin:Show()
        placeRing(pin, size, db.border)
    end
    hidePins(shown + 1)
end

-- The yards from the minimap's center to its edge, or nil when it can't be read.
local function viewRadius()
    local radius = C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if radius and readable(radius) and type(radius) == "number" and radius > 0 then
        return radius
    end
end

local lastRadius

-- When the zoom changes, every dot moves toward or away from the center by the change in yards
-- shown: move the icons the same way at once, so they stay on their dots through the zoom, and
-- following then fixes what's left. Read every frame, since the radius may change a frame after
-- the zoom event.
local function followZoom()
    local radius = viewRadius()
    if radius and lastRadius and radius ~= lastRadius then
        local k = lastRadius / radius
        for i = #nodes, 1, -1 do
            local node = nodes[i]
            node.right, node.up = node.right * k, node.up * k
            if not inside(node.right, node.up) then
                tremove(nodes, i)
            end
        end
        findAll = true
    end
    lastRadius = radius
end

local function onUpdate()
    followZoom()
    if not tracking or InCombatLockdown() then
        -- In combat the dots aren't followed, so their icons would be left behind.
        hidePins()
        return
    end
    -- The cursor on the minimap: its mouseover and tooltip are the player's. Icons stay put.
    if not blocked and not Minimap:IsMouseOver() then
        startProbing()
        local space = currentSpace()
        followAll(space)
        if not blocked then
            if findAll then
                findAll = false
                pass = nil
                find()
            else
                find(PER_FRAME)
            end
        end
        stopProbing()
    end
    draw()
end

-- Learning names ----------------------------------------------------------------------------------

local pending, pendingAt -- the name the player last cast a spell at, and when

local function onCastSent(_, unit, target)
    if unit == "player" and target and readable(target) and seen[target] then
        pending, pendingAt = target, GetTime()
    end
end

local function onLootOpened()
    if not (pending and GetTime() - pendingAt <= LEARN_WAIT) then
        return
    end
    local name = pending
    pending = nil
    for slot = 1, GetNumLootItems() do
        local icon = GetLootSlotInfo(slot)
        if icon and readable(icon) then
            module.db.learned[name] = icon
            seen[name] = nil
            return
        end
    end
end

-- A skill-up can lift the tint.
local function onSkill()
    for _, node in ipairs(nodes) do
        node.standing = standing(node.name)
    end
end

-- A zoom moves every dot further than following reaches. Each icon moves with it straight away
-- (see followZoom), and the whole minimap is looked over again for dots the zoom brought in.
local function onZoom()
    findAll = true
end

-- /fpp nodes ----------------------------------------------------------------------------------------
-- What the probes see, for finding out in game why no icons show: whether tracking is on, and a
-- whole pass in each space with the names it found. The space whose pass finds the most nodes is
-- saved.

local REPORT_NAMES = 4 -- names listed for each space

local function report()
    if not module:IsAvailable() then
        ns.Print(L.MINIMAPNODEICONS_REPORT_UNAVAILABLE)
        return
    end
    if InCombatLockdown() then
        ns.Print(L.MINIMAPNODEICONS_REPORT_COMBAT)
        return
    end
    readTracking()
    ns.Print(format(L.MINIMAPNODEICONS_REPORT_STATE,
        tracking and L.MINIMAPNODEICONS_REPORT_YES or L.MINIMAPNODEICONS_REPORT_NO,
        floor(Minimap:GetWidth() + 0.5)))
    local list = grid(Minimap:GetWidth() / 2, STEPS.high)
    local best, bestCount = nil, 0
    for _, space in ipairs(ORDER) do
        local names, order, count = {}, {}, 0
        startProbing()
        for _, point in ipairs(list) do
            local found = probe(point[1], point[2], space)
            if blocked then
                stopProbing()
                return
            end
            for _, entry in ipairs(found or NONE) do
                local name = entry.name
                if not names[name] then
                    names[name] = true
                    order[#order + 1] = name
                    if iconFor(name) then
                        count = count + 1
                    end
                end
            end
        end
        stopProbing()
        local shown = {}
        for i = 1, min(#order, REPORT_NAMES) do
            shown[i] = order[i]
        end
        ns.Print(format(L.MINIMAPNODEICONS_REPORT_SPACE, space, #order, count,
            #shown > 0 and concat(shown, ", ") or L.MINIMAPNODEICONS_REPORT_NONE))
        if count > bestCount then
            best, bestCount = space, count
        end
    end
    if best then
        module.db.calibration.space = best
        ns.Print(format(L.MINIMAPNODEICONS_REPORT_SAVED, best))
    else
        module.db.calibration.space = nil
        ns.Print(L.MINIMAPNODEICONS_REPORT_NOTHING)
    end
    nodes, pass, findAll = {}, nil, true
end

-- /fpp nodes here: where the dot under the cursor is against where its icon is. After a few
-- seconds to point at a dot, the cursor's spot and the name the game shows there (with its color)
-- are read, and the nearest icon of that name, all in minimap units right and up of its center.
local HERE_WAIT = 3 -- seconds to put the cursor on a dot

local function measure()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = Minimap:GetCenter()
    local right, up = x / scale - cx, y / scale - cy
    local under = readMouseover()
    local first = under and under[1]
    if not first then
        ns.Print(L.MINIMAPNODEICONS_HERE_NONE)
        return
    end
    ns.Print(format(L.MINIMAPNODEICONS_HERE_CURSOR, first.name, right, up, Minimap:GetZoom()))
    -- The name's color, for telling whether a node on another level is named in gray.
    ns.Print(format(L.MINIMAPNODEICONS_HERE_COLOR, tostring(first.r), tostring(first.g),
        tostring(first.b), first.gray and L.MINIMAPNODEICONS_REPORT_YES or L.MINIMAPNODEICONS_REPORT_NO))
    local nearest, best
    for _, node in ipairs(nodes) do
        local dr, du = node.right - right, node.up - up
        local d = dr * dr + du * du
        if node.name == first.name and (not best or d < best) then
            nearest, best = node, d
        end
    end
    if nearest then
        ns.Print(format(L.MINIMAPNODEICONS_HERE_ICON, nearest.right, nearest.up))
    else
        ns.Print(L.MINIMAPNODEICONS_HERE_MISSED)
    end
end

ns.AddCommand("nodes", "[here]", L.MINIMAPNODEICONS_COMMAND, function(rest)
    if rest and rest:lower():match("^%s*here") then
        if not module:IsAvailable() or InCombatLockdown() then
            ns.Print(L.MINIMAPNODEICONS_REPORT_COMBAT)
            return
        end
        ns.Print(format(L.MINIMAPNODEICONS_HERE_START, HERE_WAIT))
        C_Timer.After(HERE_WAIT, measure)
        return
    end
    report()
end)

-- Turning on and off ------------------------------------------------------------------------------

function module:OnEnable()
    if not frame then
        frame = CreateFrame("Frame", nil, Minimap)
        frame:SetAllPoints(Minimap)
        frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    end
    frame:Show()
    frame:SetScript("OnUpdate", onUpdate)
    readTracking()
    self:On("MINIMAP_UPDATE_TRACKING", readTracking)
    self:On("PLAYER_ENTERING_WORLD", readTracking)
    self:On("UNIT_SPELLCAST_SENT", onCastSent)
    self:On("LOOT_OPENED", onLootOpened)
    self:On("SKILL_LINES_CHANGED", onSkill)
    self:On("MINIMAP_UPDATE_ZOOM", onZoom)
end

function module:OnDisable()
    if frame then
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
    nodes, pass, pending = {}, nil, nil
end

function module:OnOptionChanged(key)
    if key == "detail" then
        pass = nil
    end
end
