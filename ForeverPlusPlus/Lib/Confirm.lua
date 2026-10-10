-- A yes/no confirmation in Blizzard's own popup, for anything that throws data away, such as a
-- module's Reset button in Settings, and a popup that asks for a line of text or shows one to copy.
local _, ns = ...

local StaticPopupDialogs, StaticPopup_Show, YES, NO = StaticPopupDialogs, StaticPopup_Show, YES, NO
local StaticPopup_Hide = StaticPopup_Hide
local CANCEL, ACCEPT, CLOSE = CANCEL, ACCEPT, CLOSE

---Asks the player to confirm, then calls `onAccept(arg)`. The same `key` always asks the same
---question: the popup is made the first time it's used. `arg` fills a `%s` in `text`, such as an
---item link, so one key can ask about different things.
---@param key string a name for this question, such as "AUCTIONPRICES_RESET"
---@param text string the question
---@param onAccept fun(arg?: string)
---@param arg? string
function ns.Confirm(key, text, onAccept, arg)
    -- Probe: StaticPopup is Blizzard's confirmation dialog; without it, just do it.
    if not (StaticPopupDialogs and StaticPopup_Show) then
        onAccept(arg)
        return
    end
    local which = "FOREVERPLUSPLUS_" .. key
    if not StaticPopupDialogs[which] then
        StaticPopupDialogs[which] = {
            text = text,
            button1 = YES,
            button2 = NO,
            OnAccept = function(_, data)
                data.onAccept(data.arg)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3, -- clear of the popups the game's own UI uses
        }
    end
    -- This call's function and arg travel with the popup, not in the closure made the first time.
    StaticPopup_Show(which, arg, nil, { onAccept = onAccept, arg = arg })
end

---Closes the popup for `key` if it's showing, for a question that no longer makes sense.
---@param key string
function ns.ConfirmHide(key)
    if StaticPopup_Hide then
        StaticPopup_Hide("FOREVERPLUSPLUS_" .. key)
    end
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

-- The popup's text box. Probe: GetEditBox is Mainline's; older popups had a field.
local function editBoxOf(dialog)
    return dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
end

---Asks for a line of text in Blizzard's popup, with `initial` filled in and selected, then calls
---`onAccept(text)`. Without `onAccept`, it shows `initial` to copy, with only a Close button. A
---`key` always has the same buttons, so use one key per kind of question.
---@param key string a name for this question
---@param text string the question
---@param initial? string
---@param onAccept? fun(text: string)
function ns.Prompt(key, text, initial, onAccept)
    if not (StaticPopupDialogs and StaticPopup_Show) then
        return
    end
    local which = "FOREVERPLUSPLUS_" .. key
    if not StaticPopupDialogs[which] then
        StaticPopupDialogs[which] = {
            text = text,
            button1 = onAccept and ACCEPT or CLOSE,
            button2 = onAccept and CANCEL or nil,
            hasEditBox = true,
            maxLetters = 2000, -- room for a pasted string, past the default limit
            OnShow = function(dialog, data)
                local box = editBoxOf(dialog)
                if box then
                    box:SetText(data.initial or "")
                    box:HighlightText()
                    box:SetFocus()
                end
            end,
            OnAccept = function(dialog, data)
                local box = editBoxOf(dialog)
                if data.onAccept and box then
                    data.onAccept(box:GetText())
                end
            end,
            EditBoxOnEnterPressed = function(box, data)
                if data.onAccept then
                    data.onAccept(box:GetText())
                end
                box:GetParent():Hide()
            end,
            EditBoxOnEscapePressed = function(box)
                box:GetParent():Hide()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show(which, nil, nil, { initial = initial, onAccept = onAccept })
end
