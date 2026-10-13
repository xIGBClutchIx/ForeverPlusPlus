-- Auto Decline: turns down duel requests, and optionally party invites, as they arrive, closes
-- the popup, and says in chat who asked. Friends and guildmates can be let through.
local _, ns = ...

local format, type = string.format, type
local CancelDuel, DeclineGroup, StaticPopup_Hide = CancelDuel, DeclineGroup, StaticPopup_Hide

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

-- By GUID when the event gives one (a party invite does), which needs no guild roster loaded;
-- otherwise (a duel) by name.
local function isAllowed(name, guid)
    if not module.db.allowFriends then
        return false
    end
    if Units.IsFriendGUID(guid) or Units.IsGuildmateGUID(guid) then
        return true
    end
    return ns.IsReadable(name) and type(name) == "string"
        and (Units.IsFriendName(name) or Units.IsGuildmateName(name))
end

-- Blizzard shows the duel popup on the same event, before ours runs (it registered first).
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

-- Blizzard_Game shows the invite popup (a group finder invite: LFGInvitePopup) on the same event,
-- before ours runs, so a declined invite's popup is up for an instant and is closed here. An
-- allowed inviter keeps Blizzard's popup as it is. The seventh value is the inviter's GUID.
local function onInvite(_, name, _, _, _, _, _, guid)
    if isAllowed(name, guid) then
        return
    end
    DeclineGroup()
    if StaticPopup_Hide then
        StaticPopup_Hide("PARTY_INVITE")
    end
    if StaticPopupSpecial_Hide and LFGInvitePopup then
        StaticPopupSpecial_Hide(LFGInvitePopup)
    end
    module:Print(format(L.AUTODECLINE_DECLINED_INVITE, who(name)))
end

function module:OnEnable()
    self:On("DUEL_REQUESTED", onDuel)
    if self.db.partyInvites then
        self:On("PARTY_INVITE_REQUEST", onInvite)
    end
    if self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "partyInvites" then
        if self.db.partyInvites then
            self:On("PARTY_INVITE_REQUEST", onInvite)
        else
            self:Off("PARTY_INVITE_REQUEST", onInvite)
        end
    end
    if key == "allowFriends" and self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end
