-- Fast Loot: with auto loot on, take every item the moment the loot is ready instead of waiting
-- for the loot window to open and empty one slot at a time. It follows the game's own auto loot
-- setting and its modifier key, so looting by hand still works the same way.
local _, ns = ...

local GetTime, GetNumLootItems, LootSlot = GetTime, GetNumLootItems, LootSlot
local IsModifiedClick, C_CVar = IsModifiedClick, C_CVar

local L = ns.L

local module = ns.NewModule("FastLoot", L.FASTLOOT_DESC, { enabled = true })
module.title = L.FASTLOOT_TITLE

-- LOOT_READY can fire more than once for the same corpse; loot it once.
local DELAY = 0.3
local last = 0

local function onLootReady()
    local now = GetTime()
    if now - last < DELAY then
        return
    end
    -- Auto loot is the CVar, flipped while the auto loot modifier (Shift by default) is held.
    if C_CVar.GetCVarBool("autoLootDefault") == IsModifiedClick("AUTOLOOTTOGGLE") then
        return
    end
    last = now
    -- Last slot first, so taking one doesn't shift the ones still to take.
    for i = GetNumLootItems(), 1, -1 do
        LootSlot(i)
    end
end

function module:OnEnable()
    self:On("LOOT_READY", onLootReady)
end

-- Turning off stops LOOT_READY by itself (module:On).
function module:OnDisable()
end
