# Translations

How Forever++'s text works in more than one language: what a language file is, whose words each string is, and the checks that keep a translation whole and current. `AGENTS.md` has the rules in short; this is the detail.

Forever++ ships English (`enUS`) and Russian (`ruRU`). A language is a commitment: once one ships, every string added or reworded has to be done in it too, in the same change. The checks below make that a failing test instead of something to remember.

## How the game picks a language

- The language follows the game client: `ns.NewLocale(code)` in `Core.lua` gives a locale file the table to fill only when `code` is `GetLocale()` (or `enUS`, the fallback). There is no setting.
- A key a language doesn't set shows in English. A missing key never errors.
- A setting for "English on a non-English client" isn't there, and isn't simple: module titles and option names are read from the locale as the files load, before saved settings exist. It would need a reload after changing it.

## The files

| Path | What it is |
| --- | --- |
| `Locales/enUS/*.lua` | Every key, in English, a file per category. The source: its comments say whose words each string is. |
| `Locales/<code>/*.lua` | A language: the same file names, the same key order, UTF-8. Plus `Places.lua` for place names. |
| `tools/datagen/localenotes.lua` | Reads the notes in the enUS files' comments. |
| `Locales/Game.lua` | Each `[game]` key with the client's global string for it, for `ns.GameText`. Generated; loaded after every language. |
| `tools/datagen/gametext.lua` | Writes `tests/data/GameText.lua` from the client's tables. |
| `tools/datagen/gamekeys.lua` | Writes `Locales/Game.lua` from the notes. |
| `tests/data/GameText.lua` | The client's own text, in every language we ship, for the tags enUS names, and its names for our places. Generated. |
| `tests/locales/<code>.txt` | A language's record of the English each string was translated from. |
| `tests/lib/locales.lua`, `tests/locales.lua` | The checks, and the command that prints them. |

## Whose words a string is

Every key is one of three things, and enUS says which in a comment.

### Ours

No note. We wrote the English and a translator words it in their language: descriptions, our option names, our chat messages. Most keys.

### The game's: `[game: TAG]`

```lua
L.SELLPRICE_TITLE = "Sell Price" -- [game: SELL_PRICE]
L.PROFTOOLTIPS_BEAST = "Beast" -- [game: CreatureType.1]
```

The string is the game's own text, word for word: a stat, a profession, a Blizzard button or setting we mirror, a creature type we match against a tooltip. `TAG` is its name in the client's `GlobalStrings` table, or `Table.ID` for a row's name in another table (only `CreatureType` today).

- At run time the string comes from the game itself. `Locales/Game.lua` (generated from these notes) lists each key with its tag, and `ns.GameText` in `Core.lua` reads the client's global string of that name, in the player's language, after the locale files have loaded. So the order is the game's text, then the language file's, then enUS. A language we have no translation for still gets these.
- An English client keeps enUS's text: the test holds it to the client's English, so a patch can't change it under us unnoticed.
- So a language file leaves these keys out: `ruRU` has none of the 94 the game supplies. The test doesn't count them as missing.
- A language keeps its own copy where the game can't supply one, and the test holds that copy to the client's text: a `Table.ID` tag (never a global), and a tag in `NOT_GLOBAL` in `tools/datagen/localenotes.lua` (found missing in game: `MENU_EDIT_SELECT_ALL`).
- Self Test's "game text" section says whether the running client has every global (2026-11-26, build 1.60.1.71139: 94 of 95). Run it after adding a `[game]` note: a tag that fails goes in `NOT_GLOBAL`, and each language then carries the string.
- enUS has to equal the client's English too, so a note can't be put on the wrong string.
- Add the note when a string of ours is the game's name for something. Don't add it to a general word that happens to match one ("None", "Always", "Blue"): the same English is often several things in the game, with different genders and forms in other languages.
- To find a tag, search the table: `https://wago.tools/db2/GlobalStrings?build=<build>` (or the CSV in `tools/datagen/cache/<build>/GlobalStrings.enUS.csv` after a run).

### Ours, naming the game's: `[quotes: TAG]`

```lua
-- [quotes: STATUS_TEXT]
L.DRUIDMANABAR_TEXT_DESC = "Show your mana on the bar as the game's Status Text setting does on ..."
```

A sentence of ours that names something of the game's. Every language has the client's text for each tag somewhere in the string, written as the client writes it (so in its dictionary form: put it in quotes, don't decline it). Several tags are split by commas. The note goes on the comment line above the key, or after the string.

### English everywhere: `[english]` ... `[/english]`

```lua
-- [english]
L.AUTOSTOW_LOG = "Log Stowing"
L.AUTOSTOW_LOG_DESC = "..."
-- [/english]
```

The keys between the two lines stay English in every language, and a language leaves them out. Two kinds:

- What only someone debugging the addon reads: the Debug page, test buttons, printed logs and dumps, the tool pages' details, and the bug report people paste to us (so we can read it).
- A name another language mustn't change: the Smart Buff macro's name.

Everything outside a block has to be translated. When in doubt, a player-facing string is outside.

## Place names

A place on the map (`Data/PointsOfInterest.lua`) is translated under the English name itself, in the language's `Places.lua`: `L["Booty Bay"] = "..."`. The name is the client's: `GameText.lua` has it for every place the client's `TaxiNodes` or `AreaTable` knows, and the test holds `Places.lua` to it. A place in neither table (a city district) is the translator's own.

## What the tests check

`tests/spec/locales.lua`, part of `tests/run.lua`, so CI fails on any of these. `lua tests/locales.lua` prints the same list for every language.

| Check | Fails when | Fix |
| --- | --- | --- |
| has every string | An enUS key outside `[english]` isn't in the language. | Translate it. |
| leaves the `[english]` strings alone | The language sets a key inside an `[english]` block. | Take it out, or move the key out of the block if players read it. |
| was translated from the English as it is now | A key's English changed after its translation was recorded. | Read the new English, fix the translation if it needs it, then `lua tests/locales.lua --update <code> KEY`. |
| has a record of the English behind every string | A translated key has no line in `tests/locales/<code>.txt`. | The same `--update`, after reading it. |
| uses the client's text where enUS says `[game]` | A `[game]` key isn't the client's text. | Copy the client's text from `GameText.lua` (it's written with `\ddd` escapes; `lua tests/locales.lua` names the keys). |
| has the client's text where enUS says `[quotes]` | The client's text for a tag isn't in the string. | Write it in, as the client writes it. |
| names the places as the client does | A place the client names is missing from `Places.lua` or differs. | Use the client's name. |
| enUS's notes are right | A tag isn't in `GameText.lua`, or enUS isn't the client's English for it. | Run the generator, or fix the note. |
| matches enUS | A key enUS doesn't have, a lost or reordered placeholder, a list of forms where enUS has text or the other way round. | Fix the string. |
| asks for its own folder's language, sets no string twice | A file calls `ns.NewLocale` with another code, or defines a key twice. | Fix the file. |

`--update` says "this translation is right for the English as it is now". Run it after reading the string, never to quiet the test: it's the only thing that knows a translation went stale.

## Changing a string

Any change to `Locales/enUS/` is also a change to every other language, in the same commit:

1. **A new key:** add it to enUS with its note if it's the game's (`[game]`, `[quotes]`) or inside an `[english]` block if only a debugger reads it. Then add its translation at the same place in each language's file, and run `lua tests/locales.lua --update <code> KEY`.
2. **Reworded English:** read each language's translation of that key. Change it if the meaning changed, then `--update` that key. A fix that doesn't touch the meaning (a typo) still needs the `--update`.
3. **A removed or renamed key:** remove or rename it in each language too; `--update` drops what's gone.
4. **A new `[game]` or `[quotes]` tag:** run `lua5.1 tools/datagen/generate.lua <build in tools/datagen/BUILD>` so `GameText.lua` and `Locales/Game.lua` have it, and commit both.
5. Run `lua5.1 tests/run.lua locales`.

A translation written by a model is fine as a first pass, with these rules: take the game's terms from `GameText.lua` or the client's tables, not from memory; keep one word for one thing across the files; and say in the change that it hasn't been read by a native speaker when it hasn't.

## A new game build

`table-data.yml` runs the generator for a new build and opens a pull request. `GameText.lua` is one of its files, so if Blizzard rewords a string we mirror, in any language, the diff shows it and the `[game]` or `[quotes]` check fails until the language file follows.

## Looking something up in the client

The install holds one language, so the client folder can't say what the game calls something in another. wago.tools serves each build's tables in every language:

```
https://wago.tools/db2/<Table>/csv?build=<build>&locale=ruRU
```

- `GlobalStrings`: the interface's own strings, by `BaseTag`.
- `CreatureType`, `SkillLine`, `Faction`, `ChrRaces`, `ChrClasses`: the names the game shows.
- `TaxiNodes`, `AreaTable`: flight points and areas.
- `SpellName`, `ItemSparse`: spell and item names, by ID.

Join a language's rows to enUS's by `ID`. An NPC's title under its name isn't in any table: it comes from the server, so it has to be read off a client in that language.

## Adding a language

1. Make `Locales/<code>/` with a file per enUS file (same names, same key order, the section comments kept in English) and `Places.lua`. Each starts with `local _, ns = ...` and `local L = ns.NewLocale("<code>")`, returning when that's nil.
2. Add the files to the TOC after the last language's, in enUS's order, `Places.lua` last.
3. Run the generator, so `GameText.lua` has the language, and copy the client's text for every `[game]` key and place.
4. Translate everything outside the `[english]` blocks. A counted string is a list of the language's forms: one, two (1, then the rest), or three (the Slavic rule), as `ns.Text.Plural` reads them.
5. `lua tests/locales.lua --update <code>`, then `lua5.1 tests/run.lua`.
6. Check `Lib/Fonts.lua`'s `NON_ROMAN` if the language isn't written in Latin letters: the font options are off for those.

## Russian (ruRU): what's known

- Written in 2026-11 by merging two model translations, then checked against the Russian client's own text for build 1.60.1.71139. Not yet read by a native speaker, and not yet seen in game: text that's too long for its place hasn't been looked for.
- **Stable masters:** `AUTOGOSSIP_TITLE_STABLE` is matched against the title under an NPC's name and stays English until someone reads the Russian off a client, so Auto Gossip doesn't know a stable master on a Russian client.
- **City icons:** `BlizzardIcons.lua` strips an English " City" from a city's name to match Blizzard's map pins. Whether Russian city pins match without that is untested.
- **Our own terms**, where the client has no word: "модуль" for a module, "быстрые переключатели" for the quick toggles, "путевая точка" for a `/way` waypoint (the game's map pin is "точка на карте").
