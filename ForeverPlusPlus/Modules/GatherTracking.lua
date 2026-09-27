-- Gathering Tracking: keeps Find Minerals and Find Herbs on. After login, zoning, and coming back
-- to life it turns one back on when nothing is being tracked, and it can swap between the two
-- every few seconds so both kinds of node show on the minimap. Only one tracking spell is on at a
-- time, so swapping is the only way to see both. Never in combat, on a flight, or while casting:
-- tracking is a spell, and casting it would stop a cast or a channel such as mining or fishing.
local _, ns = ...

local ipairs, type, tonumber, tostring, pcall = ipairs, type, tonumber, tostring, pcall
local format = string.format
local C_Minimap, C_Timer = C_Minimap, C_Timer
local InCombatLockdown, UnitIsDeadOrGhost, UnitOnTaxi = InCombatLockdown, UnitIsDeadOrGhost, UnitOnTaxi
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo

local L = ns.L

local HERBS, MINERALS = 2383, 2580 -- Find Herbs, Find Minerals

-- Which spells each `track` choice uses, the one to turn back on first before the other.
local SPELLS = {
    both = { MINERALS, HERBS },
    minerals = { MINERALS },
    herbs = { HERBS },
}

local RETRY = 2 -- seconds between tries while the player can't cast it yet

local module = ns.NewModule("GatherTracking", L.GATHERTRACKING_DESC, {
    enabled = true,
    track = "both", -- a key of SPELLS
    reapply = true,
    swap = "off", -- "off", or seconds between swaps
    chat = true,
})
module.title = L.GATHERTRACKING_TITLE
module.category = "automation"

module.options = {
    {
        key = "track",
        name = L.GATHERTRACKING_TRACK,
        description = L.GATHERTRACKING_TRACK_DESC,
        choices = {
            { "both", L.GATHERTRACKING_TRACK_BOTH },
            { "minerals", L.GATHERTRACKING_TRACK_MINERALS },
            { "herbs", L.GATHERTRACKING_TRACK_HERBS },
        },
    },
    {
        key = "swap",
        name = L.GATHERTRACKING_SWAP,
        description = L.GATHERTRACKING_SWAP_DESC,
        choices = {
            { "off", L.GATHERTRACKING_SWAP_OFF },
            { "3", format(L.GATHERTRACKING_SWAP_EVERY, 3) },
            { "5", format(L.GATHERTRACKING_SWAP_EVERY, 5) },
            { "10", format(L.GATHERTRACKING_SWAP_EVERY, 10) },
            { "30", format(L.GATHERTRACKING_SWAP_EVERY, 30) },
        },
    },
    {
        key = "reapply",
        name = L.GATHERTRACKING_REAPPLY,
        description = L.GATHERTRACKING_REAPPLY_DESC,
    },
    ns.ChatOption(L.GATHERTRACKING_CHAT_DESC),
}

-- Reads the tracking list: the index of each of our spells the player knows, which of them is on,
-- and whether any tracking spell is on (a hunter's Track Beasts counts). Read every time, since it
-- changes as spells are learned. GetTrackingInfo has no secret values.
local function scan()
    local index, ours, any = {}, nil, false
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(i)
        if type(info) == "table" then
            local spellID = info.spellID
            if spellID == HERBS or spellID == MINERALS then
                index[spellID] = i
            end
            if info.active and (info.type == "spell" or (spellID and spellID > 0)) then
                any = true
                if spellID == HERBS or spellID == MINERALS then
                    ours = spellID
                end
            end
        end
    end
    return index, ours, any
end

-- Unit state can be secret; when it is, wait.
local function yes(value)
    return not ns.IsReadable(value) or not not value
end

-- Whether casting a tracking spell now would fail or get in the way.
local function busy()
    return InCombatLockdown() or yes(UnitIsDeadOrGhost("player")) or yes(UnitOnTaxi("player"))
        or yes(UnitCastingInfo("player")) or yes(UnitChannelInfo("player"))
end

local blocked = false -- the client refused SetTracking from an addon; stop until /reload
local last -- the last of our spells seen on, turned back on first

local function track(i)
    local ok, err = pcall(C_Minimap.SetTracking, i, true)
    if not ok and not blocked then
        blocked = true
        module:Print(format(L.GATHERTRACKING_FAILED, tostring(err)))
    end
end

-- Turning tracking back on --------------------------------------------------------------------

local want = false -- turn tracking back on at the next chance
local waiting = false -- a retry is scheduled

local function reapply()
    waiting = false
    if not (want and module.enabled and module.db.reapply) or blocked then
        want = false
        return
    end
    if busy() then
        waiting = true
        C_Timer.After(RETRY, reapply)
        return
    end
    want = false
    local index, _, any = scan()
    if any then
        return -- something is tracked already, maybe by the player's choice
    end
    local spells = SPELLS[module.db.track]
    local first
    for _, spellID in ipairs(spells) do
        if index[spellID] then
            if spellID == last then
                first = spellID
                break
            end
            first = first or spellID
        end
    end
    if first then
        track(index[first])
    end
end

-- Login, /reload, zoning, and coming back to life. The tracking list can lag the event a little.
local function request()
    want = true
    if not waiting then
        waiting = true
        C_Timer.After(1, reapply)
    end
end

-- Swapping ------------------------------------------------------------------------------------

local ticker

local function swap()
    if blocked or busy() then
        return
    end
    local index, ours = scan()
    -- Swap only while one of ours is on: off, or another tracker, is the player's choice.
    local other = (ours == MINERALS and HERBS) or (ours == HERBS and MINERALS)
    if other and module.db.track == "both" and index[other] then
        track(index[other])
    end
end

local function stopSwapping()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function startSwapping()
    stopSwapping()
    local seconds = tonumber(module.db.swap)
    if seconds and not blocked then
        ticker = C_Timer.NewTicker(seconds, swap)
    end
end

-- Events --------------------------------------------------------------------------------------

local function onTrackingChanged()
    local _, ours = scan()
    last = ours or last
end

-- SetTracking may be protected on a later build; it then fails this way instead of erroring.
local function onBlocked(_, addon, action)
    if addon == ns.name and type(action) == "string" and action:find("SetTracking", 1, true)
        and not blocked then
        blocked = true
        stopSwapping()
        module:Print(L.GATHERTRACKING_BLOCKED)
    end
end

local REAPPLY_EVENTS = { "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }

function module:OnEnable()
    for _, event in ipairs(REAPPLY_EVENTS) do
        self:On(event, request)
    end
    self:On("MINIMAP_UPDATE_TRACKING", onTrackingChanged)
    self:On("ADDON_ACTION_BLOCKED", onBlocked)
    self:On("ADDON_ACTION_FORBIDDEN", onBlocked)
    onTrackingChanged()
    startSwapping()
    request()
end

function module:OnDisable()
    stopSwapping()
    want = false
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "swap" then
        startSwapping()
    elseif key == "reapply" and self.db.reapply then
        request()
    end
end
