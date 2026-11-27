-- Reads what an enUS locale file says about its own keys, in its comments, for the game text
-- generator (gametext.lua) and the locales spec (tests/spec/locales.lua):
--
--   L.KEY = "Sell Price" -- [game: SELL_PRICE]
--       The text is the game's own, word for word: every language uses the client's text for that
--       tag. A tag is one of GlobalStrings' (its BaseTag), or "Table.ID" for a row's name in
--       another table (CreatureType.1).
--   L.KEY = "... as the game's Status Text setting ..." -- [quotes: STATUS_TEXT]
--       The text names something of the game's inside a sentence of ours: every language has the
--       client's text for each tag in it, as written. Several tags are split by commas.
--   -- [english] ... -- [/english]
--       The keys between the two lines stay English in every language: what only someone
--       debugging the addon reads, and text another language must not change. Each marker is a
--       line of its own, written exactly so.
--
-- A note is in the comment at the end of the key's first line, or in the comment lines right
-- above the key. Plain Lua 5.1, no addon code.
local Notes = {}

-- GlobalStrings tags the running client doesn't have as a Lua global, so the game can't hand us
-- their text at run time and each language keeps its own copy. From Self Test's "game text"
-- section (Forever 1.60.1.71139, 2026-11-26: the other 94 tags enUS names were all globals).
Notes.NOT_GLOBAL = {
    MENU_EDIT_SELECT_ALL = true,
}

---Whether the running game has a tag's text as a global string: a GlobalStrings tag, and not one
---found missing in game. A "Table.ID" tag is a row of another table, never a global.
---@param tag string
---@return boolean
function Notes.IsGlobal(tag)
    return not tag:find(".", 1, true) and not Notes.NOT_GLOBAL[tag]
end

local function tags(comment, kind, into)
    for list in comment:gmatch("%[" .. kind .. ":%s*([^%]]-)%s*%]") do
        for tag in list:gmatch("[^,%s]+") do
            into[#into + 1] = tag
        end
    end
end

---The keys of an enUS file's text, in order, each with its notes.
---@param text string the file's text
---@return table[] entries { key, line, english = boolean, game = tag or nil, quotes = { tags } }
---@return string|nil problem a marker out of place, as "line N: ..."
function Notes.Read(text)
    local entries, above, english, number = {}, {}, false, 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        number = number + 1
        line = line:gsub("\r$", "")
        local key = line:match("^L%.([%w_]+)%s*=")
        if line == "-- [english]" then
            if english then
                return entries, "line " .. number .. ": [english] inside [english]"
            end
            english, above = true, {}
        elseif line == "-- [/english]" then
            if not english then
                return entries, "line " .. number .. ": [/english] with no [english]"
            end
            english, above = false, {}
        elseif key then
            local entry = { key = key, line = number, english = english, quotes = {} }
            local found = {}
            for _, comment in ipairs(above) do
                tags(comment, "game", found)
                tags(comment, "quotes", entry.quotes)
            end
            -- The comment after the string: the last "--" outside it is close enough, since a
            -- note never has a quote in it.
            local comment = line:match('^.*"%s*,?%s*(%-%-.*)$') or line:match("^[^\"]*(%-%-.*)$") or ""
            tags(comment, "game", found)
            tags(comment, "quotes", entry.quotes)
            entry.game = found[1]
            entries[#entries + 1] = entry
            above = {}
        elseif line:match("^%-%-") then
            above[#above + 1] = line
        elseif not line:match("^%s+%S") and not line:match("^}") then
            above = {} -- a blank line ends the comments above a key; a continued string doesn't
        end
    end
    if english then
        return entries, "an [english] is never closed"
    end
    return entries, nil
end

return Notes
