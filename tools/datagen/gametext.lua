-- tests/data/GameText.lua: the client's own text, in English and in each language the addon is
-- translated into, for what the locale files say is the game's wording. tests/spec/locales.lua
-- holds every language to it, so a translation can't drift from the game, and a new build that
-- rewords something shows up as a failing test.
--
--   text    each tag an enUS key names with [game: TAG] or [quotes: TAG] (localenotes.lua): a
--           GlobalStrings tag, or "Table.ID" for a row's name in CreatureType.
--   places  each place name in Data/PointsOfInterest.lua that the client has as a flight point
--           (TaxiNodes) or an area (AreaTable), by its English name, with the client's names for
--           it in each language. A flight point's ", Zone" ending is left off.
local CSV = require("csv")
local Lua = require("luaout")
local Notes = require("localenotes")

local M = {
    path = "tests/data/GameText.lua",
    tables = {},
    -- Read once per language, as tables["<code>.<name>"]; tables.languages lists the codes.
    localized = { "GlobalStrings", "CreatureType", "TaxiNodes", "AreaTable" },
}

-- Row names by table, for "Table.ID" tags: the column that holds the name.
local NAMED = { CreatureType = "Name_lang" }

-- For summary.lua: an entry's key and its line.
function M.Entry(line)
    local key = line:match('^        %[(".-")%] = {') or line:match('^        ([%w_%.]+) = {')
    if key then
        return key, line
    end
end

local function readFile(path)
    local file = assert(io.open(path, "rb"), "can't read " .. path)
    local text = file:read("*a")
    file:close()
    return text
end

-- The enUS locale files, from the TOC.
local function localeFiles(root)
    local list = {}
    for line in readFile(root .. "/ForeverPlusPlus/ForeverPlusPlus.toc"):gmatch("[^\r\n]+") do
        local name = line:match("^Locales[/\\]enUS[/\\](.+%.lua)$")
        if name then
            list[#list + 1] = root .. "/ForeverPlusPlus/Locales/enUS/" .. name
        end
    end
    return list
end

-- A flight point's name without its zone: ", Zone" in most languages, the comma full width in
-- Chinese (U+FF0C, three bytes in UTF-8), and " (Zone)" in Korean.
local function shortName(name)
    name = name:gsub(",.*$", "")
    name = name:gsub("\239\188\140.*$", "")
    return (name:gsub("%s+%b()$", ""))
end

function M.Build(t, build, script, root)
    local languages = t.languages
    -- The tags the locale files name.
    local wanted, order = {}, {}
    for _, path in ipairs(localeFiles(root)) do
        local entries, problem = Notes.Read(readFile(path))
        if problem then
            error(path .. ": " .. problem)
        end
        for _, entry in ipairs(entries) do
            local list = { entry.game }
            for _, tag in ipairs(entry.quotes) do
                list[#list + 1] = tag
            end
            for _, tag in ipairs(list) do
                if not wanted[tag] then
                    wanted[tag] = true
                    order[#order + 1] = tag
                end
            end
        end
    end
    table.sort(order)

    -- Each language's text by tag.
    local text = {}
    for _, code in ipairs(languages) do
        local strings = {}
        for _, row in ipairs(CSV.Records(t[code .. ".GlobalStrings"], "GlobalStrings", { "BaseTag", "TagText_lang" })) do
            if wanted[row.BaseTag] then
                strings[row.BaseTag] = row.TagText_lang
            end
        end
        for name, column in pairs(NAMED) do
            for _, row in ipairs(CSV.Records(t[code .. "." .. name], name, { "ID", column })) do
                local tag = name .. "." .. row.ID
                if wanted[tag] then
                    strings[tag] = row[column]
                end
            end
        end
        text[code] = strings
    end
    for _, tag in ipairs(order) do
        if not text.enUS[tag] or text.enUS[tag] == "" then
            error("the client has no text for " .. tag)
        end
    end

    -- The places: English name -> each language's names, by row ID.
    local english = {} -- lower-case English name -> list of { table, id }
    local function index(name, column)
        for _, row in ipairs(CSV.Records(t["enUS." .. name], name, { "ID", column })) do
            local key = shortName(row[column]):lower()
            if key ~= "" then
                english[key] = english[key] or {}
                table.insert(english[key], { name, row.ID })
            end
        end
    end
    index("TaxiNodes", "Name_lang")
    index("AreaTable", "AreaName_lang")
    local names = {} -- code -> table -> ID -> name
    for _, code in ipairs(languages) do
        names[code] = { TaxiNodes = {}, AreaTable = {} }
        for _, row in ipairs(CSV.Records(t[code .. ".TaxiNodes"], "TaxiNodes", { "ID", "Name_lang" })) do
            names[code].TaxiNodes[row.ID] = shortName(row.Name_lang)
        end
        for _, row in ipairs(CSV.Records(t[code .. ".AreaTable"], "AreaTable", { "ID", "AreaName_lang" })) do
            names[code].AreaTable[row.ID] = row.AreaName_lang
        end
    end
    local places, seen = {}, {}
    for name in readFile(root .. "/ForeverPlusPlus/Data/PointsOfInterest.lua"):gmatch('"([A-Z][%a\' ]+)"') do
        local rows = english[name:lower()]
        if rows and not seen[name] then
            seen[name] = true
            places[#places + 1] = name
        end
    end
    table.sort(places)

    local out = {
        "-- The client's own text for what the locale files call the game's wording, and its names for the",
        "-- places in Data/PointsOfInterest.lua. Read by tests/spec/locales.lua; not shipped.",
        "--",
        "-- Generated by " .. script .. " from wago.tools' tables for build " .. build .. ".",
        "-- Don't edit it by hand: run the script again after a patch, or after adding a [game: TAG].",
        "return {",
        ("    build = %s,"):format(Lua.String(build)),
        "    languages = {",
    }
    for _, code in ipairs(languages) do
        out[#out + 1] = ("        %s,"):format(Lua.String(code))
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "    text = {"
    for _, tag in ipairs(order) do
        local parts = {}
        for _, code in ipairs(languages) do
            parts[#parts + 1] = ("%s = %s"):format(code, Lua.String(text[code][tag] or ""))
        end
        out[#out + 1] = ("        [%s] = { %s },"):format(Lua.String(tag), table.concat(parts, ", "))
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "    places = {"
    for _, name in ipairs(places) do
        local parts = {}
        for _, code in ipairs(languages) do
            if code ~= "enUS" then
                local found, list = {}, {}
                for _, row in ipairs(english[name:lower()]) do
                    local theirs = names[code][row[1]][row[2]]
                    if theirs and theirs ~= "" and not found[theirs] then
                        found[theirs] = true
                        list[#list + 1] = Lua.String(theirs)
                    end
                end
                table.sort(list)
                parts[#parts + 1] = ("%s = { %s }"):format(code, table.concat(list, ", "))
            end
        end
        out[#out + 1] = ("        [%s] = { %s },"):format(Lua.String(name), table.concat(parts, ", "))
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "}"
    return table.concat(out, "\n") .. "\n"
end

return M
