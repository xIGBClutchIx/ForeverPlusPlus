-- Auto Decline: turns down duel requests as they arrive, closes the popup, and says in chat who
-- asked. Friends and guildmates can be let through.
local _, ns = ...

local format, type = string.format, type
local CancelDuel, StaticPopup_Hide = CancelDuel, StaticPopup_Hide

local L = ns.L
local Units = ns.Units

local module = ns.NewModule("AutoDecline", L.AUTODECLINE_DESC, {
    enabled = false,
    allowFriends = false,
    chat = true,
})
module.title = L.AUTODECLINE_TITLE
module.category = "automation"

module.options = {
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
local function onDuel(_, name)
    if module.db.allowFriends and (Units.IsFriendName(name) or Units.IsGuildmateName(name)) then
        return
    end
    CancelDuel()
    if StaticPopup_Hide then
        StaticPopup_Hide("DUEL_REQUESTED")
    end
    module:Print(format(L.AUTODECLINE_DECLINED, who(name)))
end

function module:OnEnable()
    self:On("DUEL_REQUESTED", onDuel)
    if self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end

-- Its event stops by itself; there's nothing else to undo.
function module:OnDisable()
end

function module:OnOptionChanged(key)
    if key == "allowFriends" and self.enabled and self.db.allowFriends then
        Units.RequestGuildRoster()
    end
end
