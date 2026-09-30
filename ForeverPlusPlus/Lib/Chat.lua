-- Chat helpers the Chat modules share: the chat frames, chat lines as plain text, and the column
-- of small buttons beside the main chat window (Blizzard's menu and channel buttons, then ours).
local _, ns = ...

local _G, ipairs, type, gsub = _G, ipairs, type, string.gsub

local Chat = {}
ns.Chat = Chat

---The chat windows that exist, in order.
---@return table[]
function Chat.Frames()
    local frames = {}
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frames[#frames + 1] = frame
        end
    end
    return frames
end

---A chat line without its escape codes: colors, links (their text stays), textures, and atlases.
---Nothing here may be given a secret value; test with `ns.IsReadable` first.
---@param text string
---@return string
function Chat.Plain(text)
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = gsub(text, "|cn[^:|]*:", "")
    text = gsub(text, "|r", "")
    text = gsub(text, "|H[^|]*|h(.-)|h", "%1")
    text = gsub(text, "|T[^|]*|t", "")
    text = gsub(text, "|A[^|]*|a", "")
    text = gsub(text, "||", "|")
    return text
end

-- The button column ----------------------------------------------------------------------------
-- Each module that adds a button gives it a key and an order; they stack under Blizzard's own
-- buttons, lowest order first, so two modules never put theirs in the same spot.

local column = {} -- { key, button, order }, sorted by order
local laying

---The last of Blizzard's own chat buttons, which ours go under.
---@return table?
local function anchor()
    return _G.ChatFrameChannelButton or _G.ChatFrameMenuButton
end

---Puts the buttons in the column back in place. Modules call it again when something moves one.
function Chat.Layout()
    local previous = anchor()
    if not previous then
        return
    end
    laying = true
    for _, entry in ipairs(column) do
        entry.button:ClearAllPoints()
        entry.button:SetPoint("TOP", previous, "BOTTOM", 0, -2)
        previous = entry.button
    end
    laying = false
end

---Whether the column is being laid out right now, so a hook on SetPoint can ignore our own moves.
---@return boolean
function Chat.IsLaying()
    return laying == true
end

---Adds a button to the column (or moves it, when the key is already there).
---@param key string the module's name
---@param button table
---@param order number
function Chat.AddButton(key, button, order)
    Chat.RemoveButton(key, true)
    column[#column + 1] = { key = key, button = button, order = order }
    table.sort(column, function(a, b)
        return a.order < b.order
    end)
    Chat.Layout()
end

---Takes a button out of the column. It stays where it is; the caller puts it back or hides it.
---@param key string
---@param quiet? boolean skip laying out the rest
function Chat.RemoveButton(key, quiet)
    for i, entry in ipairs(column) do
        if entry.key == key then
            table.remove(column, i)
            break
        end
    end
    if not quiet then
        Chat.Layout()
    end
end
