-- Chat helpers the Chat modules share: the chat frames, chat lines as plain text, and the column
-- of small buttons beside the main chat window (Blizzard's menu and channel buttons, then ours).
local _, ns = ...

local _G, ipairs, type, tonumber, gsub = _G, ipairs, type, tonumber, string.gsub
local byte, find, format, match, sub = string.byte, string.find, string.format, string.match,
    string.sub
local floor, min, concat = math.floor, math.min, table.concat

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

-- Colored lines -----------------------------------------------------------------------------------
-- A chat line as an edit box can show it in its chat colors: the line's color around it, its own
-- color codes (names, links) kept, and links, textures, and atlases gone. Copying from an edit box
-- copies its raw text, codes and all, so Chat.Uncolor and the offsets below turn colored text and
-- positions in it into plain ones.

local PIPE, LOWER_C, LOWER_R = 124, 99, 114

---A color code for red, green, and blue from 0 to 1.
---@param r number
---@param g number
---@param b number
---@return string
local function hexCode(r, g, b)
    return format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5),
        floor(b * 255 + 0.5))
end

---A named color (|cnIQ4: for an item's quality, |cnNAME: for a color global) as a plain color
---code, which edit boxes show; nil when the name isn't known.
---@param name string
---@return string?
local function namedCode(name)
    local quality = tonumber(match(name, "^IQ(%d+)$"))
    local color
    if quality then
        color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    else
        color = _G[name]
    end
    if type(color) ~= "table" then
        return nil
    end
    local r, g, b = color.r, color.g, color.b
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then
        return hexCode(r, g, b)
    end
end

---A chat line in its chat colors, for an edit box. Nothing here may be given a secret value.
---@param text string
---@param r number?
---@param g number?
---@param b number?
---@return string
function Chat.Colored(text, r, g, b)
    text = gsub(text, "|H[^|]*|h(.-)|h", "%1")
    text = gsub(text, "|T[^|]*|t", "")
    text = gsub(text, "|A[^|]*|a", "")
    -- Item links color their names with |cnIQ1: and the like.
    text = gsub(text, "(|+)cn([^:|]*):", function(pipes, name)
        local code = #pipes % 2 == 1 and namedCode(name)
        if code then
            return sub(pipes, 2) .. code
        end
    end)
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        return text
    end
    local color = hexCode(r, g, b)
    -- An edit box keeps the first color until a |r and ignores a color code inside it, so the
    -- line's color ends before each color of its own (a name, a link) and comes back after it.
    -- An even run of pipes before the letter is escaped pipes, not a code.
    text = gsub(text, "(|+)([cr])", function(pipes, letter)
        if #pipes % 2 == 1 then
            local escaped = sub(pipes, 2)
            if letter == "r" then
                return escaped .. "|r" .. color
            end
            return escaped .. "|r|c"
        end
    end)
    return color .. text .. "|r"
end

---The length of the color code at byte i, or nil when there isn't one.
---@param text string
---@param i number
---@return number?
local function codeLength(text, i)
    if byte(text, i) ~= PIPE then
        return nil
    end
    local nextByte = byte(text, i + 1)
    if nextByte == LOWER_R then
        return 2
    elseif nextByte == LOWER_C then
        local _, last = find(text, "^|c%x%x%x%x%x%x%x%x", i)
        if not last then
            _, last = find(text, "^|cn[^:|]*:", i)
        end
        return last and last - i + 1
    end
end

---Walks colored text: a color code shows nothing and "||" shows one "|". Stops after `rawStop`
---bytes of it or once `shownStop` bytes show, and returns the bytes walked and the bytes shown.
---@param text string
---@param rawStop number?
---@param shownStop number?
---@param pieces table? gets the shown text
---@return number raw
---@return number shown
local function walk(text, rawStop, shownStop, pieces)
    local length = #text
    local i, shown = 1, 0
    while i <= length and not (rawStop and i > rawStop) and not (shownStop and shown >= shownStop) do
        local pipe = find(text, "|", i, true) or length + 1
        if pipe > i then
            local run = pipe - i
            if rawStop then
                run = min(run, rawStop - i + 1)
            end
            if shownStop then
                run = min(run, shownStop - shown)
            end
            if pieces then
                pieces[#pieces + 1] = sub(text, i, i + run - 1)
            end
            i, shown = i + run, shown + run
        else
            local code = codeLength(text, i)
            if code then
                i = i + code
            else
                if pieces then
                    pieces[#pieces + 1] = "|"
                end
                i, shown = i + (byte(text, i + 1) == PIPE and 2 or 1), shown + 1
            end
        end
    end
    return i - 1, shown
end

---Colored text as the plain text it shows.
---@param text string
---@return string
function Chat.Uncolor(text)
    local pieces = {}
    walk(text, nil, nil, pieces)
    return concat(pieces)
end

---Where a position in colored text falls in its plain text (both count bytes before it).
---@param text string colored text
---@param offset number
---@return number
function Chat.PlainOffset(text, offset)
    local _, shown = walk(text, offset)
    return shown
end

---Where a position in plain text falls in its colored text, before any codes there.
---@param text string colored text
---@param offset number
---@return number
function Chat.ColoredOffset(text, offset)
    return (walk(text, nil, offset))
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
