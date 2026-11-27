-- Locales: every ns.L string the addon uses is defined in Locales/enUS/, and none is defined twice.
-- A missing one shows as nil in game (or breaks a format call), so it's caught here instead.
-- Another language's files are checked against enUS: its keys, placeholders, and plural forms.
local T = ...
local eq = T.eq

local _, files = T.Toc()

-- The keys a locale file sets, as "L.KEY =" or L["a place"] = at the start of a line, each with
-- its line. `defined` is key -> "file:line" of its first definition, and `twice` gets the rest.
local function scan(path, defined, twice)
    local number = 0
    for line in T.Read(T.ROOT .. path):gmatch("([^\n]*)\n?") do
        number = number + 1
        local key = line:match("^L%.([%w_]+)%s*=") or line:match('^L%["(.-)"%]%s*=')
        if key then
            if defined[key] then
                twice[#twice + 1] = ("%s (%s and %s:%d)"):format(key, defined[key], path, number)
            else
                defined[key] = path .. ":" .. number
            end
        end
    end
end

-- Every enUS file the TOC loads, into a table of its own.
local strings = { L = {} }
strings.NewLocale = function()
    return strings.L
end
local defined = {}
local twice = {}
for _, path in ipairs(files) do
    if path:match("^Locales/enUS/") then
        T.load(path:gsub("%.lua$", ""), strings)
        scan(path, defined, twice)
    end
end
eq(table.concat(twice, ", "), "", "locales: no string is defined twice")

-- The strings each file uses: L.KEY, with or without ns. in front, outside comments.
local function used(text)
    local found, number = {}, 0
    for line in text:gmatch("([^\n]*)\n?") do
        number = number + 1
        local code = line:gsub("%-%-.*$", "")
        for key in code:gmatch("%f[%w_]L%.([%a_][%w_]*)") do
            found[#found + 1] = { key = key, line = number }
        end
    end
    return found
end

local total = 0
for _, path in ipairs(files) do
    if path:match("%.lua$") and not path:match("^Locales/") then
        local text = T.Read(T.ROOT .. path)
        local missing = {}
        for _, use in ipairs(text and used(text) or {}) do
            total = total + 1
            if strings.L[use.key] == nil then
                missing[#missing + 1] = ("%s (line %d)"):format(use.key, use.line)
            end
        end
        eq(table.concat(missing, ", "), "", "locales: every string " .. path .. " uses is defined")
    end
end
-- So a scan that finds nothing can't pass by itself.
eq(total > 1000, true, "locales: the scan finds the strings the files use (" .. total .. ")")

-- A counted string is a list of one to three forms (ns.Text.Plural), each a string.
local function forms(value)
    if type(value) == "string" then
        return { value }
    elseif type(value) == "table" and #value >= 1 and #value <= 3 then
        for _, form in ipairs(value) do
            if type(form) ~= "string" then
                return nil
            end
        end
        return value
    end
end
local counted = 0
for key, value in pairs(strings.L) do
    if type(value) == "table" then
        counted = counted + 1
        eq(forms(value) ~= nil and #value == 2, true, "locales: " .. key .. " has enUS's two forms")
    end
end
eq(counted > 10, true, "locales: the counted strings are found (" .. counted .. ")")

-- What a format string takes, as the kind of each argument in the order the code passes them:
-- "sd" for "%s of %d" and for "%2$d von %1$s". Unnumbered placeholders take the arguments in
-- turn, so a language that moves one has to number them all. Returns nil for a string that
-- numbers some and not others, or leaves a gap, which format can't run.
local function arguments(text)
    local kinds, numbered, plain, highest = {}, false, false, 0
    for index, dollar, kind in text:gsub("%%%%", ""):gmatch("%%(%d*)(%$?)[-+#0]*%d*%.?%d*([a-zA-Z])") do
        local at
        if dollar == "$" then
            numbered = true
            at = tonumber(index)
            if not at or (kinds[at] and kinds[at] ~= kind) then
                return nil
            end
        else
            plain = true
            at = highest + 1
        end
        kinds[at] = kind
        highest = math.max(highest, at)
    end
    if numbered and plain then
        return nil
    end
    for at = 1, highest do
        if not kinds[at] then
            return nil
        end
    end
    return table.concat(kinds)
end
eq(arguments("%2$s of %1$d, 50%%"), "ds", "locales: numbered placeholders are read by their number")
eq(arguments("5% cut of %s, to %.1f"), "sf", "locales: a percent sign in prose isn't a placeholder")
eq(arguments("%1$s and %s"), nil, "locales: numbered and plain placeholders don't mix")

-- The place names Points of Interest and Flight Timer show, which a language translates under the
-- English name itself (L["Booty Bay"] = ...): any quoted text in Data/PointsOfInterest.lua.
local places = T.Read(T.ROOT .. "Data/PointsOfInterest.lua")
local function isPlace(key)
    return places:find('"' .. key .. '"', 1, true) ~= nil
end

local function problems(theirs, english)
    local list = {}
    for key, value in pairs(theirs) do
        local ours = english[key]
        local mine = forms(value)
        if ours == nil then
            if type(value) ~= "string" or not isPlace(key) then
                list[#list + 1] = key .. " isn't an enUS key"
            end
        elseif not mine then
            list[#list + 1] = key .. " isn't text"
        elseif type(value) ~= type(ours) then
            list[#list + 1] = key .. (type(ours) == "table" and " needs a list of forms"
                or " is a list of forms")
        else
            local want = arguments(forms(ours)[1])
            for _, form in ipairs(mine) do
                if arguments(form) ~= want then
                    list[#list + 1] = key .. " has other placeholders"
                    break
                end
            end
        end
    end
    table.sort(list)
    return table.concat(list, ", ")
end
eq(problems({ A = "%2$s zu %1$d", B = "x", C = "%s", D = "%s zu %d", E = { "%d a", "%d b", "%d c" },
        F = { "a" }, G = "x", ["Booty Bay"] = "y" },
        { A = "%d to %s", C = "%d", D = "%d to %s", E = { "%d a", "%d as" }, F = "a",
            G = { "a", "as" } }),
    "B isn't an enUS key, C has other placeholders, D has other placeholders, F is a list of forms, "
        .. "G needs a list of forms", "locales: a language's mistakes are found")

-- Each language's files: they ask for their own folder's code, and set no key twice.
local languages = {} -- code -> its strings
local wrongCode, twiceTheirs, seen = {}, {}, {}
for _, path in ipairs(files) do
    local code = path:match("^Locales/(%w+)/")
    if code and code ~= "enUS" then
        languages[code] = languages[code] or {}
        seen[code] = seen[code] or {}
        local theirs = languages[code]
        T.load(path:gsub("%.lua$", ""), { NewLocale = function(asked)
            if asked ~= code then
                wrongCode[#wrongCode + 1] = path
            end
            return theirs
        end })
        scan(path, seen[code], twiceTheirs)
    end
end
eq(table.concat(wrongCode, ", "), "", "locales: every file asks for its own folder's language")
eq(table.concat(twiceTheirs, ", "), "", "locales: no language sets a string twice")
for code, theirs in pairs(languages) do
    eq(problems(theirs, strings.L), "", "locales: " .. code .. " matches enUS")
end

-- The notes enUS writes about its own keys (tools/datagen/localenotes.lua).
local Locales = dofile("tests/lib/locales.lua")
local Notes = dofile("tools/datagen/localenotes.lua")
do
    local entries, problem = Notes.Read(table.concat({
        'L.A = "Sell Price" -- [game: SELL_PRICE]',
        "-- [quotes: STATUS_TEXT, KEY_BINDINGS]",
        'L.B = "as the Status Text setting, in Key Bindings, "',
        '    .. "does" -- more of it',
        "",
        "-- [english]",
        'L.C = "debug -- not a comment" -- count',
        "-- [/english]",
        'L.D = { "%d a", "%d as" }',
    }, "\n"))
    eq(problem, nil, "notes: a well formed file has no problem")
    eq(#entries, 4, "notes: every key is read")
    eq(entries[1].game, "SELL_PRICE", "notes: [game] after the string")
    eq(table.concat(entries[2].quotes, " "), "STATUS_TEXT KEY_BINDINGS", "notes: [quotes] above the key")
    eq(entries[2].english or entries[4].english, false, "notes: keys outside the block are translated")
    eq(entries[3].english, true, "notes: keys inside [english] stay English")
    eq(entries[3].game, nil, "notes: a key's notes don't reach the next key")
    eq(select(2, Notes.Read("-- [english]\nL.A = \"x\"")) ~= nil, true, "notes: an open [english] is a problem")
    eq(select(2, Notes.Read("-- [/english]")) ~= nil, true, "notes: a stray [/english] is a problem")
    eq(Locales.Hash("abc") == Locales.Hash("abc") and Locales.Hash("abc") ~= Locales.Hash("abd"), true,
        "notes: a fingerprint follows the text")
end

-- Each language is whole and current: everything outside enUS's [english] blocks is translated,
-- from the English as it is now, and what enUS says is the game's wording is the client's own
-- text in that language (tests/data/GameText.lua). `lua tests/locales.lua` prints the same, and
-- docs/translations.md says what to do about each.
local english, game = Locales.English(), Locales.GameText()
eq(table.concat(english.problems, ", "), "", "locales: enUS's [english] markers pair up")
local marked, bound = 0, 0
for _, key in ipairs(english.order) do
    marked = marked + (english.notes[key].english and 1 or 0)
    bound = bound + (english.notes[key].game and 1 or 0)
end
eq(marked > 50 and bound > 50, true, ("locales: the notes are found (%d english, %d game)"):format(marked, bound))
-- Locales/Game.lua, which hands ns.GameText the keys to read from the running game, is the
-- [game] notes that name a global string: forgetting to run the generator after a note fails here.
do
    local given
    T.load("Locales/Game", { GameText = function(keys) given = keys end })
    local want, got = {}, {}
    for _, key in ipairs(english.order) do
        local tag = english.notes[key].game
        if tag and not tag:find(".", 1, true) then
            want[#want + 1] = key .. "=" .. tag
        end
    end
    for key, tag in pairs(given or {}) do
        got[#got + 1] = key .. "=" .. tag
    end
    table.sort(want)
    table.sort(got)
    eq(table.concat(got, " "), table.concat(want, " "), "locales: Locales/Game.lua is enUS's [game] notes")
end

local CHECKS = {
    { "notes", "enUS's notes are right" },
    { "missing", "has every string" },
    { "english", "leaves the [english] strings alone" },
    { "stale", "was translated from the English as it is now" },
    { "untracked", "has a record of the English behind every string" },
    { "game", "uses the client's text where enUS says [game]" },
    { "quotes", "has the client's text where enUS says [quotes]" },
    { "places", "names the places as the client does" },
}
for _, code in ipairs(Locales.Languages()) do
    local found = Locales.Problems(code, english, game)
    for _, check in ipairs(CHECKS) do
        local list = found[check[1]]
        local shown = table.concat(list, ", ", 1, math.min(#list, 12)) .. (#list > 12 and ", ..." or "")
        eq(#list == 0 and "" or ("%d: %s"):format(#list, shown), "", "locales: " .. code .. " " .. check[2])
    end
end
