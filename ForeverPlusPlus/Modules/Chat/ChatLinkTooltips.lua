-- Chat Link Tooltips: the tooltip of an item, spell, quest, or other link in chat shows while the
-- mouse is over it, with no click.
--
-- Blizzard's chat windows show nothing as the mouse comes over a link: ChatFrameMixin's
-- OnHyperlinkEnter and OnHyperlinkLeave only trigger "ChatFrame.OnHyperlinkEnter" and "...Leave"
-- on EventRegistry, and nothing of Blizzard's listens (ChatFrame.lua, wow-ui-source's `forever`
-- branch, read 2026-11-27). So each window's two scripts are hooked, and a link of a kind the game's
-- tooltip shows (ns.Chat.HasTooltip) goes to GameTooltip:SetHyperlink, the same call a click's
-- ItemRefTooltip makes. Through it the game's tooltip data, so Item Tooltips and Tooltips add
-- their lines as anywhere else. An item or quest the client hasn't loaded yet fills in by itself:
-- GameTooltip refreshes on TOOLTIP_DATA_UPDATE, and SetHyperlink hides it when there's no data.
-- Nothing in it is protected, so it works in combat too. Asked for in GitHub issue #51.
local _, ns = ...

local GameTooltip = GameTooltip

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("ChatLinkTooltips", L.CHATLINKTOOLTIPS_DESC, {
    enabled = true,
    position = "cursor",
})
module.title = L.CHATLINKTOOLTIPS_TITLE
module.category = "chat"
module.added = "1.10.0"

-- There's no mouse over chat with the controller interface.
module.notice = ns.Gamepad.LimitedNotice()

module.options = {
    {
        key = "position",
        name = L.CHATLINKTOOLTIPS_POSITION,
        description = L.CHATLINKTOOLTIPS_POSITION_DESC,
        choices = {
            { "cursor", L.CHATLINKTOOLTIPS_AT_CURSOR },
            { "default", L.CHATLINKTOOLTIPS_AT_DEFAULT },
        },
    },
}

-- The chat window whose link the tooltip shows now, so the mouse leaving hides only our own.
local shownBy

local function onEnter(frame, link)
    if not Chat.HasTooltip(link) then
        return
    end
    if module.db.position == "default" then
        -- Blizzard's own spot, which Tooltips' Anchor to Cursor and Edit Mode's HUD Tooltip move.
        GameTooltip_SetDefaultAnchor(GameTooltip, frame)
    else
        GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    end
    GameTooltip:SetHyperlink(link)
    shownBy = frame
end

local function onLeave(frame)
    if shownBy ~= frame then
        return
    end
    shownBy = nil
    -- Another frame may have taken the tooltip since.
    if GameTooltip:GetOwner() == frame then
        GameTooltip:Hide()
    end
end

local function apply(frame)
    module:HookScript(frame, "OnHyperlinkEnter", onEnter)
    module:HookScript(frame, "OnHyperlinkLeave", onLeave)
end

function module:IsAvailable()
    return _G.ChatFrame1 ~= nil and _G.ChatFrame1.HookScript ~= nil
end

function module:OnEnable()
    -- Also a window added later: one made for a whisper, or one a reset brings back.
    Chat.EachWindow(self, apply)
end

function module:OnDisable()
    if shownBy then
        onLeave(shownBy)
    end
end
