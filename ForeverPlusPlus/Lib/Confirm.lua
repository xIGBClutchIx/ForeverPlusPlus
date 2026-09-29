-- A yes/no confirmation in Blizzard's own popup, for anything that throws data away, such as a
-- module's Reset button in Settings.
local _, ns = ...

local StaticPopupDialogs, StaticPopup_Show, YES, NO = StaticPopupDialogs, StaticPopup_Show, YES, NO

---Asks the player to confirm, then calls `onAccept`. The same `key` always asks the same question
---and does the same thing: the popup is made the first time it's used.
---@param key string a name for this question, such as "AUCTIONPRICES_RESET"
---@param text string the question
---@param onAccept function
function ns.Confirm(key, text, onAccept)
    -- Probe: StaticPopup is Blizzard's confirmation dialog; without it, just do it.
    if not (StaticPopupDialogs and StaticPopup_Show) then
        onAccept()
        return
    end
    local which = "FOREVERPLUSPLUS_" .. key
    if not StaticPopupDialogs[which] then
        StaticPopupDialogs[which] = {
            text = text,
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                onAccept()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3, -- clear of the popups the game's own UI uses
        }
    end
    StaticPopup_Show(which)
end
