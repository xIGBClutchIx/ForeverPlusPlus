-- The state of each translation, and its record of the English it was made from. From the repo
-- root:
--
--   lua tests/locales.lua                       what each language is missing or has to re-read
--   lua tests/locales.lua --update ruRU         record the English of every string ruRU has now
--   lua tests/locales.lua --update ruRU KEY ... record it for those keys only
--   lua tests/locales.lua --english ruRU        print the English of what ruRU has to do, to
--                                               hand to a translator
--
-- tests/spec/locales.lua runs the same checks and fails on any of them, so a string added or
-- reworded in enUS has to be translated, or re-read, in the same change. Updating the record says
-- "this translation is right for the English as it now is": run it after reading the string, never
-- to quiet the test. See docs/translations.md.
local Locales = dofile("tests/lib/locales.lua")

local command, code = arg[1], arg[2]
local english, game = Locales.English(), Locales.GameText()

local function text(value)
    if type(value) == "table" then
        return "{ " .. table.concat(value, " | ") .. " }"
    end
    return (tostring(value):gsub("\n", "\\n"))
end

if command == "--update" then
    assert(code, "usage: lua tests/locales.lua --update <code> [KEY ...]")
    local strings = Locales.Language(code)
    local known = Locales.ReadBaseline(code)
    local only = {}
    for index = 3, #arg do
        only[arg[index]] = true
    end
    local changed = 0
    for _, key in ipairs(english.order) do
        if next(only) == nil or only[key] then
            local hash = strings[key] ~= nil and Locales.Hash(english.strings[key]) or nil
            if known[key] ~= hash then
                known[key] = hash
                changed = changed + 1
            end
        end
    end
    for key in pairs(known) do -- keys enUS no longer has, or the language no longer sets
        if english.strings[key] == nil or strings[key] == nil then
            known[key] = nil
            changed = changed + 1
        end
    end
    Locales.WriteBaseline(code, known)
    print(("%s: recorded the English of %d strings"):format(code, changed))
    os.exit(0)
elseif command == "--english" then
    assert(code, "usage: lua tests/locales.lua --english <code>")
    local found = Locales.Problems(code, english, game)
    for _, kind in ipairs({ "missing", "stale" }) do
        for _, key in ipairs(found[kind]) do
            print(("%s\t%s\t%s"):format(kind, key, text(english.strings[key])))
        end
    end
    os.exit(0)
end

local LABELS = {
    { "missing", "not translated" },
    { "stale", "English changed since the translation" },
    { "untracked", "translated, with no record of the English it came from" },
    { "english", "translated, though enUS marks it [english]" },
    { "game", "not the client's text" },
    { "quotes", "without the client's text for a tag it quotes" },
    { "places", "place names missing or not the client's" },
    { "notes", "notes in enUS that are wrong" },
}
local failed = false
for _, language in ipairs(Locales.Languages()) do
    local found = Locales.Problems(language, english, game)
    print(language .. ", against the client's text for build " .. tostring(game.build) .. ":")
    local clean = true
    for _, label in ipairs(LABELS) do
        local list = found[label[1]]
        if #list > 0 then
            clean, failed = false, true
            print(("  %s (%d): %s"):format(label[2], #list, table.concat(list, ", ")))
        end
    end
    if clean then
        print("  complete and up to date")
    end
end
os.exit(failed and 1 or 0)
