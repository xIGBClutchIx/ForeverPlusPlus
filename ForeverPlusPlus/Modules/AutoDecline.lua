-- Auto Decline: turns down duel requests as they arrive, closes the popup, and says in chat who
-- asked. Friends and guildmates can be let through, and pet battle duels declined too where the
-- client has them.
local _, ns = ...

local format, type = string.format, type
local CancelDuel, StaticPopup_Hide, C_PetBattles = CancelDuel, StaticPopup_Hide, C_PetBattles

local L = ns.L
local Units = ns.Units

-- Probe: pet battles are a Mainline system that Forever's level 60 game may not have.
local hasPetDuels = C_PetBattles and C_PetBattles.CancelPVPDuel and true or false

local module = ns.NewModule("AutoDecline", L.AUTODECLINE_DESC, {
    enabled = false,
    allowFriends = false,
    petDuels = true,
    chat = true,
})
module.title = L.AUTODECLINE_TITLE
module.category = "automation"

module.options = {
    { key = "allowFriends", name = L.AUTODECLINE_ALLOW_FRIENDS, description = L.AUTODECLINE_ALLOW_FRIENDS_DESC },
}
if hasPetDuels then
    module.options[#module.options + 1] =
        { key = "petDuels", name = L.AUTODECLINE_PET_DUELS, description = L.AUTODECLINE_PET_DUELS_DESC }
end
module.options[#module.options + 1] = ns.ChatOption(L.AUTODECLINE_CHAT_DESC)

-- The name can't be read (secret) or is missing: say "someone" rather than skip the message.
local function who(name)
    if ns.IsReadable(name) and type(name) == "string" and name ~= "" then
        return name
    end
    return L.AUTODECLINE_SOMEONE
end

local function allowed(name)
    return module.db.allowFriends and (Units.IsFriendName(name) or Units.IsGuildmateName(name))
end

-- Blizzard's UIParent shows the popup on the same event, before ours runs (it registered first).
local function hidePopup(which)
    if StaticPopup_Hide then
        StaticPopup_Hide(which)
    end
end

local function onDuel(_, name)
    if allowed(name) then
        return
    end
    CancelDuel()
    hidePopup("DUEL_REQUESTED")
    module:Print(format(L.AUTODECLINE_DECLINED, who(name)))
end

local function onPetDuel(_, name)
    if not module.db.petDuels or allowed(name) then
        return
    end
    C_PetBattles.CancelPVPDuel()
    hidePopup("PET_BATTLE_PVP_DUEL_REQUESTED")
    module:Print(format(L.AUTODECLINE_DECLINED_PET, who(name)))
end

function module:OnEnable()
    self:On("DUEL_REQUESTED", onDuel)
    if hasPetDuels then
        self:On("PET_BATTLE_PVP_DUEL_REQUESTED", onPetDuel)
    end
    if self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end

-- Its events stop by themselves; there's nothing else to undo.
function module:OnDisable()
end

function module:OnOptionChanged(key)
    if key == "allowFriends" and self.enabled and self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end
