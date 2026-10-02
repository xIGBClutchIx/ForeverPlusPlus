-- A yes/no confirmation in Blizzard's own popup, for anything that throws data away, such as a
-- module's Reset button in Settings.
local _, ns = ...

local StaticPopupDialogs, StaticPopup_Show, YES, NO = StaticPopupDialogs, StaticPopup_Show, YES, NO
local CANCEL = CANCEL

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

---Asks the player to pick one of two things or cancel, laid out like Blizzard's own Defaults popup
---(`first` | Cancel | `second`), then calls that choice's function. Like ns.Confirm, the popup for
---a `key` is made the first time it's used.
---@param key string a name for this question
---@param text string the question
---@param first string the left button
---@param onFirst function
---@param second string the right button
---@param onSecond function
function ns.ConfirmChoice(key, text, first, onFirst, second, onSecond)
    -- Probe: as ns.Confirm. Without the popup, do nothing: there's no way to know which.
    if not (StaticPopupDialogs and StaticPopup_Show) then
        return
    end
    local which = "FOREVERPLUSPLUS_" .. key
    if not StaticPopupDialogs[which] then
        StaticPopupDialogs[which] = {
            text = text,
            button1 = first,
            button2 = CANCEL,
            button3 = second,
            OnAccept = function()
                onFirst()
            end,
            OnAlt = function()
                onSecond()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show(which)
end
