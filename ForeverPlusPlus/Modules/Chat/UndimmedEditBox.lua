-- Undimmed Edit Box: the box chat is typed in stays at full strength while nothing is being typed.
--
-- With Chat Style on IM Style the game keeps each window's edit box on screen and dims it to 0.35
-- when it loses the chat (ChatFrameEditBoxMixin:Deactivate), and gives it its full strength back
-- when it's typed in again (ChatFrameUtil.ActivateChat). So after each Deactivate the box's alpha
-- is set to 1 again: the alpha of an unprotected frame, which nothing of Blizzard's reads. With
-- another chat style Deactivate hides the box, so there is nothing to do, and a notice says so.
-- That setting is the player's, so the notice has a button instead of changing it.
-- (wow-ui-source's `forever` branch, read 2026-11-27. Asked for in a CurseForge comment.)
local _, ns = ...

local ipairs, setmetatable = ipairs, setmetatable
local C_CVar = C_CVar

local L = ns.L
local Chat = ns.Chat

local module = ns.NewModule("UndimmedEditBox", L.UNDIMMEDEDITBOX_DESC, {
    enabled = false,
})
module.title = L.UNDIMMEDEDITBOX_TITLE
module.category = "chat"
module.added = "1.10.0"

local CVAR = "chatStyle"
local IM_STYLE = "im"
-- What Blizzard dims an edit box left on screen to, for giving it back.
local DIMMED = 0.35

-- The edit boxes that aren't being typed in, as far as our hooks have heard: the ones to dim
-- again when the module turns off.
local idle = setmetatable({}, { __mode = "k" })

local function imStyle()
    return C_CVar.GetCVar(CVAR) == IM_STYLE
end

module.notice = {
    text = L.UNDIMMEDEDITBOX_NOT_IM,
    description = L.UNDIMMEDEDITBOX_NOT_IM_DESC,
    button = L.SETTINGS_TURN_ON,
    fn = function()
        ns.CVars.Apply(CVAR, IM_STYLE)
    end,
    shown = function()
        return module.db.enabled and C_CVar.GetCVar(CVAR) ~= nil and not imStyle()
    end,
}

-- After Blizzard's Deactivate has dimmed (or hidden) a box. The GM chat's box is never dimmed.
local function onDeactivate(box)
    idle[box] = true
    if not box.isGM then
        box:SetAlpha(1)
    end
end

local function onActivate(box)
    if box then
        idle[box] = nil
    end
end

---Brings a window's edit box to full strength, and keeps it there.
---@param frame table a chat window
local function apply(frame)
    local box = frame.editBox
    if not (box and box.SetAlpha) or box.isGM then
        return
    end
    module:Hook(box, "Deactivate", onDeactivate)
    -- A box being typed in is already at full strength, so every box can be taken as idle here:
    -- the Settings panel has the keyboard while this turns on.
    idle[box] = true
    box:SetAlpha(1)
end

function module:IsAvailable()
    return _G.ChatFrame1 ~= nil and _G.ChatFrame1.editBox ~= nil
end

function module:OnEnable()
    self:Hook(ChatFrameUtil, "ActivateChat", onActivate)
    -- Also a window added later: one made for a whisper, or one a reset brings back.
    Chat.EachWindow(self, apply)
    -- The notice follows Chat Style as the player changes it.
    self:On("CVAR_UPDATE", function(_, name)
        if name == CVAR and ns.RefreshSetting then
            ns.RefreshSetting(module.name)
        end
    end)
end

function module:OnDisable()
    -- Dimmed again as Blizzard left them, the ones not being typed in.
    local dim = imStyle()
    for _, frame in ipairs(Chat.Frames()) do
        local box = frame.editBox
        if box and idle[box] and dim and not box.isGM then
            box:SetAlpha(DIMMED)
        end
    end
end
