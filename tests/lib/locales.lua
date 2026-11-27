-- What tests/spec/locales.lua and tests/locales.lua both need to hold another language's locale
-- files to enUS and to the game: the files and their notes, the client's own text
-- (tests/data/GameText.lua), and each language's record of the English it was translated from
-- (tests/locales/<code>.txt). Plain Lua 5.1, run from the repo root; nothing of the addon loads.
local Locales = {}

local ROOT = "ForeverPlusPlus/"
local Notes = dofile("tools/datagen/localenotes.lua")

local function read(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local text = file:read("*a")
    file:close()
    return text
end

-- The locale files the TOC loads: code -> list of paths, and the codes in the TOC's order.
local function tocFiles()
    local byCode, codes = {}, {}
    for line in (read(ROOT .. "ForeverPlusPlus.toc") or ""):gmatch("[^\r\n]+") do
        local code, name = line:match("^Locales[/\\](%a%a%u%u)[/\\](.+%.lua)$")
        if code then
            if not byCode[code] then
                byCode[code] = {}
                codes[#codes + 1] = code
            end
            table.insert(byCode[code], ROOT .. "Locales/" .. code .. "/" .. name:gsub("\\", "/"))
        end
    end
    return byCode, codes
end

-- A locale file's strings, into `strings`. Returns the codes it asked ns.NewLocale for.
local function load(path, strings)
    local asked = {}
    local chunk = assert(loadfile(path))
    chunk("ForeverPlusPlus", { NewLocale = function(code)
        asked[#asked + 1] = code
        return strings
    end })
    return asked
end

---A value's fingerprint: the same text gives the same eight hex digits. A list of forms counts
---each form.
---@param value string|string[]
---@return string
function Locales.Hash(value)
    local text = type(value) == "table" and table.concat(value, "\0") or tostring(value)
    local hash = 5381
    for index = 1, #text do
        hash = (hash * 33 + text:byte(index)) % 4294967296
    end
    return ("%08x"):format(hash)
end

---Everything about the English: its strings, each key's notes, and the keys in file order.
---@return table english { strings, notes = key -> entry, order = { keys }, problems = { text } }
function Locales.English()
    local byCode = tocFiles()
    local english = { strings = {}, notes = {}, order = {}, problems = {} }
    for _, path in ipairs(byCode.enUS or {}) do
        load(path, english.strings)
        local entries, problem = Notes.Read(read(path))
        if problem then
            english.problems[#english.problems + 1] = path .. ": " .. problem
        end
        for _, entry in ipairs(entries) do
            english.notes[entry.key] = entry
            english.order[#english.order + 1] = entry.key
        end
    end
    return english
end

---The other languages the TOC loads, in its order.
---@return string[]
function Locales.Languages()
    local _, codes = tocFiles()
    local list = {}
    for _, code in ipairs(codes) do
        if code ~= "enUS" then
            list[#list + 1] = code
        end
    end
    return list
end

---A language's strings, and the files that asked for another language's table.
---@param code string
---@return table strings
---@return string[] wrong paths
function Locales.Language(code)
    local byCode = tocFiles()
    local strings, wrong = {}, {}
    for _, path in ipairs(byCode[code] or {}) do
        for _, asked in ipairs(load(path, strings)) do
            if asked ~= code then
                wrong[#wrong + 1] = path
            end
        end
    end
    return strings, wrong
end

---The client's own text, as tools/datagen/gametext.lua wrote it.
---@return table { build, languages, text = tag -> { code = text }, places = name -> { code = { names } } }
function Locales.GameText()
    return dofile("tests/data/GameText.lua")
end

local function baselinePath(code)
    return "tests/locales/" .. code .. ".txt"
end

---A language's record: key -> the fingerprint of the English its translation was made from.
---@param code string
---@return table
function Locales.ReadBaseline(code)
    local known = {}
    for line in (read(baselinePath(code)) or ""):gmatch("[^\r\n]+") do
        local hash, key = line:match("^(%x+)\t(.+)$")
        if hash then
            known[key] = hash
        end
    end
    return known
end

---Writes a language's record, sorted, so the same state gives the same bytes.
---@param code string
---@param known table key -> fingerprint
function Locales.WriteBaseline(code, known)
    local keys = {}
    for key in pairs(known) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    local out = {
        "# The English each " .. code .. " string was translated from, as a fingerprint of the enUS text.",
        "# tests/spec/locales.lua fails when the English has changed since: read the new English, fix",
        "# the translation if it needs it, then run: lua tests/locales.lua --update " .. code .. " KEY ...",
    }
    for _, key in ipairs(keys) do
        out[#out + 1] = known[key] .. "\t" .. key
    end
    local file = assert(io.open(baselinePath(code), "wb"))
    file:write(table.concat(out, "\n") .. "\n")
    file:close()
end

---What is wrong with a language, each as a sorted list of texts (empty when nothing is):
---  missing   keys enUS has that it doesn't, outside the [english] blocks
---  english   keys it sets that enUS marks [english]
---  stale     keys whose English changed since the translation was recorded
---  untracked keys it sets with no record of the English they came from
---  game      [game: TAG] keys whose text isn't the client's
---  quotes    [quotes: TAG] keys without the client's text for a tag
---  places    place names the client has that are missing or aren't the client's
---  notes     notes in enUS itself that are wrong (the same for every language)
---@param code string
---@param english table Locales.English()
---@param game table Locales.GameText()
---@return table
function Locales.Problems(code, english, game)
    local strings = Locales.Language(code)
    local known = Locales.ReadBaseline(code)
    local found = { missing = {}, english = {}, stale = {}, untracked = {}, game = {}, quotes = {},
        places = {}, notes = {} }
    for _, text in ipairs(english.problems) do
        found.notes[#found.notes + 1] = text
    end
    for _, key in ipairs(english.order) do
        local note, ours, theirs = english.notes[key], english.strings[key], strings[key]
        if note.english then
            if theirs ~= nil then
                found.english[#found.english + 1] = key
            end
        elseif theirs == nil then
            found.missing[#found.missing + 1] = key
        elseif known[key] == nil then
            found.untracked[#found.untracked + 1] = key
        elseif known[key] ~= Locales.Hash(ours) then
            found.stale[#found.stale + 1] = key
        end
        if note.game then
            local text = game.text[note.game]
            if not text then
                found.notes[#found.notes + 1] = key .. " names " .. note.game .. ", which GameText.lua lacks"
            elseif text.enUS ~= ours then
                found.notes[#found.notes + 1] = key .. " isn't the client's " .. note.game .. " in English"
            elseif theirs ~= nil and text[code] and text[code] ~= "" and theirs ~= text[code] then
                found.game[#found.game + 1] = key .. " (" .. note.game .. ")"
            end
        end
        for _, tag in ipairs(note.quotes) do
            local text = game.text[tag]
            if not text then
                found.notes[#found.notes + 1] = key .. " names " .. tag .. ", which GameText.lua lacks"
            elseif type(ours) ~= "string" or not ours:find(text.enUS, 1, true) then
                found.notes[#found.notes + 1] = key .. " doesn't have the client's " .. tag .. " in English"
            elseif type(theirs) == "string" and text[code] and text[code] ~= ""
                and not theirs:find(text[code], 1, true) then
                found.quotes[#found.quotes + 1] = key .. " (" .. tag .. ")"
            end
        end
    end
    for name, names in pairs(game.places) do
        local theirs, match = strings[name], false
        for _, option in ipairs(names[code] or {}) do
            if option == theirs then
                match = true
            end
        end
        if #(names[code] or {}) > 0 and not match then
            found.places[#found.places + 1] = name
        end
    end
    for _, list in pairs(found) do
        table.sort(list)
    end
    return found
end

return Locales
