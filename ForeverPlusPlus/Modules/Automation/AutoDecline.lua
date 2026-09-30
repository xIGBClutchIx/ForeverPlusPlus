-- Auto Decline: turns down duel requests, and optionally party invites, as they arrive, closes
-- the popup, and says in chat who asked. Friends and guildmates can be let through.
local _, ns = ...

local format, type = string.format, type
local CancelDuel, DeclineGroup, StaticPopup_Hide, StaticPopup_Show =
    CancelDuel, DeclineGroup, StaticPopup_Hide, StaticPopup_Show

local L = ns.L
local Units = ns.Units

local module = ns.NewModule("AutoDecline", L.AUTODECLINE_DESC, {
    enabled = false,
    allowFriends = false,
    duels = true,
    partyInvites = false,
    chat = true,
})
module.title = L.AUTODECLINE_TITLE
module.category = "automation"

module.options = {
    { key = "duels", name = L.AUTODECLINE_DUELS, description = L.AUTODECLINE_DUELS_DESC },
    { key = "partyInvites", name = L.AUTODECLINE_PARTY_INVITES, description = L.AUTODECLINE_PARTY_INVITES_DESC },
    { key = "allowFriends", name = L.AUTODECLINE_ALLOW_FRIENDS, description = L.AUTODECLINE_ALLOW_FRIENDS_DESC },
    ns.ChatOption(L.AUTODECLINE_CHAT_DESC),
}

-- The name can't be read (secret) or is missing: say "someone" rather than skip the message.
local function who(name)
    if ns.IsReadable(name) and type(name) == "string" and name ~= "" then
        return name
    end
    return L.AUTODECLINE_SOMEONE
end

-- Blizzard's UIParent shows the popup on the same event, before ours runs (it registered first).
local function isAllowed(name)
    return module.db.allowFriends and ns.IsReadable(name) and type(name) == "string"
        and (Units.IsFriendName(name) or Units.IsGuildmateName(name))
end

local function onDuel(_, name)
    if not module.db.duels or isAllowed(name) then
        return
    end
    CancelDuel()
    if StaticPopup_Hide then
        StaticPopup_Hide("DUEL_REQUESTED")
    end
    module:Print(format(L.AUTODECLINE_DECLINED, who(name)))
end

-- The invite popup plays its sound as it opens, so a declined invite must never reach Blizzard's
-- UIParent. While the option is on, UIParent stops hearing the event and we answer it instead: a
-- decline, or for an allowed inviter the same popup Blizzard would have shown.
local function onInvite(_, name)
    if isAllowed(name) then
        if StaticPopup_Show then
            StaticPopup_Show("PARTY_INVITE", name)
        end
        return
    end
    DeclineGroup()
    if StaticPopup_Hide then
        StaticPopup_Hide("PARTY_INVITE")
    end
    module:Print(format(L.AUTODECLINE_DECLINED_INVITE, who(name)))
end

local function holdInvites(hold)
    if hold then
        UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
    else
        UIParent:RegisterEvent("PARTY_INVITE_REQUEST")
    end
end

function module:OnEnable()
    self:On("DUEL_REQUESTED", onDuel)
    if self.db.partyInvites then
        holdInvites(true)
        self:On("PARTY_INVITE_REQUEST", onInvite)
    end
    if self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end

function module:OnDisable()
    holdInvites(false)
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "partyInvites" then
        if self.db.partyInvites then
            holdInvites(true)
            self:On("PARTY_INVITE_REQUEST", onInvite)
        else
            holdInvites(false)
            self:Off("PARTY_INVITE_REQUEST", onInvite)
        end
    end
    if key == "allowFriends" and self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end
