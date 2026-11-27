-- Core: the language the text is in. The client's unless the player chose one, which is read from
-- the saved table as the locale files load (the TOC's LoadSavedVariablesFirst).
local T = ...
local eq = T.eq

-- Nothing saved: the client's language (the stub client is English).
ForeverPlusPlusDB = nil
local c = T.Core()
local core = c.ns
eq(core.Language(), "enUS", "language: the client's when nothing is chosen")
eq(core.ChosenLanguage(), nil, "language: and nothing reads as chosen")
eq(core.NewLocale("zhTW"), nil, "language: another language's file stops")
core.NewLocale("deDE")
local names, codes = {}, {}
for _, entry in ipairs(core.Languages()) do
    codes[#codes + 1] = entry[1]
    names[entry[1]] = entry[2]
end
eq(table.concat(codes, " "), "enUS deDE zhTW", "language: English first, then the rest by their code")
eq(names.enUS .. ", " .. names.deDE, "English (enUS), Deutsch (deDE)", "language: each is named in itself, with its code")

-- A language chosen: its file fills ns.L, and the game's own strings aren't laid over it, since the
-- client only has them in its own language.
ForeverPlusPlusDB = { language = "deDE" }
c = T.Core()
core = c.ns
eq(core.Language(), "deDE", "language: the chosen one")
eq(core.NewLocale("deDE"), core.L, "language: its file fills the text table")
eq(core.NewLocale("ruRU"), nil, "language: and the others stop")
core.L.SELLPRICE_TITLE = "Verkaufspreis"
SELL_PRICE = "Sell Price"
core.GameText({ SELLPRICE_TITLE = "SELL_PRICE" })
eq(core.L.SELLPRICE_TITLE, "Verkaufspreis", "language: the client's strings aren't laid over a chosen language")
SELL_PRICE = nil

-- Choosing: a language with files is saved, anything else follows the client again.
core.SetLanguage("ruRU")
eq(ForeverPlusPlusDB.language, "ruRU", "language: a choice is saved for the next load")
core.SetLanguage("xxXX")
eq(ForeverPlusPlusDB.language, nil, "language: a language without files isn't")
core.SetLanguage(nil)
eq(ForeverPlusPlusDB.language, nil, "language: nor is following the client")
ForeverPlusPlusDB = nil
