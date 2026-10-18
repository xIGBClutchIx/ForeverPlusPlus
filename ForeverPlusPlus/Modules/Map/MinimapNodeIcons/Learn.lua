-- Minimap Node Icons' learning: the item a node gives, from the spell the player casts at it and
-- the first item in the loot window that follows.
local _, ns = ...

local type = type
local GetTime, C_Item = GetTime, C_Item
local GetNumLootItems, GetLootSlotInfo, GetLootSlotLink = GetNumLootItems, GetLootSlotInfo, GetLootSlotLink

local readable = ns.IsReadable
local Professions = ns.Professions
local Node = Professions.Node

local module = ns.modules.MinimapNodeIcons
local internal = module.internal

local LEARN_WAIT = 10 -- seconds from a cast to its loot window that still count as one gather

-- internal.pending is the name the player last cast a spell at; pendingAt is when.
local pendingAt

-- Whether `name` is a node whose item isn't known: one the minimap showed without an icon, or one
-- learned from its requirement line alone.
local function wantsItem(name)
    if internal.seen[name] then
        return true
    end
    local node = Node(name)
    return node and not node[3] or false
end

function internal.onCastSent(_, unit, target)
    if unit == "player" and target and ns.IsText(target) and wantsItem(target) then
        internal.pending, pendingAt = target, GetTime()
    end
end

-- The item ID in a loot slot, or nil. Probe: GetLootSlotLink is in Mainline's loot API.
local function slotItem(slot)
    local link = GetLootSlotLink and GetLootSlotLink(slot)
    if not (link and ns.IsText(link)) then
        return nil
    end
    local id = C_Item.GetItemInfoInstant(link)
    return ns.IsNumber(id) and id or nil
end

function internal.onLootOpened()
    local pending = internal.pending
    if not (pending and GetTime() - pendingAt <= LEARN_WAIT) then
        return
    end
    local name = pending
    internal.pending = nil
    for slot = 1, GetNumLootItems() do
        local icon = GetLootSlotInfo(slot)
        if icon and readable(icon) then
            -- The item, for every module and character; its icon alone when the link can't be read.
            local item = slotItem(slot)
            if not (item and Professions.LearnNodeItem(name, item)) then
                module.db.learned[name] = icon
            end
            internal.seen[name] = nil
            return
        end
    end
end
