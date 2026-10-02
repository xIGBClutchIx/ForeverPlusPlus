# AGENTS.md

Rules for anyone changing this repository, human or AI. `CLAUDE.md` imports this file; edit rules here only.

## What Forever++ is

A World of Warcraft addon for **WoW: Forever** that adds to and changes the default UI in small, separate modules.

- It enhances Blizzard's UI. It is **not** a UI replacement: no new unit frames, action bars, or skins of the whole interface.
- Every change should look like Blizzard shipped it: Blizzard fonts, atlases, templates, colors, and spacing. A player should not be able to tell where Blizzard stops and Forever++ starts.
- Every change should be seamless: no setup, no popups at login, sensible defaults, and nothing that breaks when a module is off.

Names:

| What | Value |
| --- | --- |
| Folder / addon name | `ForeverPlusPlus` |
| Display name | `Forever++` |
| Slash commands | `/fpp`, `/forever++` |
| SavedVariables | `ForeverPlusPlusDB` |
| Interface | `16001` |

## Project map

- `ForeverPlusPlus/`: the shipped addon folder, linked into the client's `Interface\AddOns`.
  - `ForeverPlusPlus.toc`: metadata and load order.
  - `Core.lua`: the shared `ns`: events (`ns.On`, `ns.Off`), `ns.AfterCombat`, saved settings, modules (`ns.NewModule`, `ns.SetEnabled`), `/fpp` (modules add subcommands with `ns.AddCommand`), `ns.Print`, `module:Print` with `ns.ChatOption`, and the locale table `ns.L`.
  - `Locales/<language>/*.lua`: player-facing text, a file per category like `Modules/` (`Core`, `Nameplates`, `Automation`, `Items`, `Interface`, `UnitFrames`, `Chat`, `Map`, `Tools`). `Locales/enUS/` has every key and is the fallback; another language's folder sets only the keys it translates.
  - `Lib/*.lua`: shared services any module can use, loaded before the modules. `Colors.lua` (`ns.Colors`: colors modules share, `Colors.Code` for color codes in text, `Colors.Class` for a unit's class color, `Colors.LevelRange` for a level range against the player's, and `Colors.Faction` for Horde red and Alliance blue), `Secret.lua` (`ns.IsReadable`, `ns.HealthStepCurve`), `Money.lua` (`ns.Money`: copper as coin text), `Confirm.lua` (`ns.Confirm`: a yes/no popup before something throws data away), `Text.lua` (`ns.Text`: font string width, tooltip lines, "3 Seconds" and "12m ago"), `AddOns.lua` (`ns.AddOns`: wait for a load-on-demand addon), `CVars.lua` (`ns.CVars`: set CVars and put the player's values back, waiting out combat, and `Bind` for options that mirror a CVar), `Nameplates.lua` (`ns.Nameplates`: plate added/removed/cast callbacks and Forever's plate parts), `PlateLabel.lua` and `FriendlyPlates.lua` (`ns.PlateLabel`, `ns.FriendlyPlates`: the name-only friendly plates Player Nameplates and NPC Nameplates share), `Units.lua` (`ns.Units`: in my group, a friend, a recent ally, a guildmate), `ItemTooltip.lua` (`ns.ItemTooltip`: price lines together at the sell price, other item lines just above them, stack counts, Shift redraws), `Professions.lua` (`ns.Professions`: the player's profession skills by skill line (and a rogue's Lockpicking), gathering difficulty colors, and the Skinning a creature's level needs), `WorldMap.lua` (`ns.WorldMap`: the world map once its addon has loaded, map data providers, Blizzard's coordinates panel on it, and the player's side for map data), `MapTooltip.lua` (`ns.MapTooltip`: how every tooltip over the world map looks: white title, gold kind line, white details, gray notes, faction colors, and no-break text), `Instances.lua` (`ns.Instances`: the dungeons and raids with their levels, a row for each as maps list them, and their names in the player's language), `MapPins.lua` (`ns.MapPins`: layers of our own icons on the world map, through a map data provider), `EditMode.lua` (`ns.EditMode`: our own frames in Blizzard's Edit Mode, looking and working like Blizzard's: a selection box that turns gold when clicked, dragging with snapping, arrow-key nudging, and a settings dialog and right-click menu with scale and reset position), `Chat.lua` (`ns.Chat`: the chat frames, a chat line as plain text, and the column of buttons beside the chat window). They cost nothing until a module uses them.
  - `Modules/<Category>/`: one change each (see "Add a module" in `README.md`), in a folder for its category: `Automation`, `Items`, `Interface`, `Chat`, `Map`, `UnitFrames`, `Nameplates`, and `Tools`. A small module is one file; a bigger one gets a folder of files that share `module.internal`. Today: Player Nameplates, NPC Nameplates, Quest Nameplates, Console Variables (a tool, no toggle), Self Test (a Debug page button, no toggle), Fast Loot, Auto Repair, Auto Sell Junk, Auction Prices, Already Known, Best Quest Reward, Sell Price, Item Count, Hide Beta Feedback (beta/PTR only), Gathering Tracking, Profession Tooltips, Auto Stow, Durability Bars, Bag Slot Counter, Auto Gossip, Tooltips, Auto Decline, Auto Release, Skip Cinematics, Auto Dismount, Fishing Cast, Auto Screenshot, Recipe Colors, Class Colors, Points of Interest (a folder: the module and its map data), Zone Info (a folder: the module and its zone data), Unexplored Areas (a folder: the module and its generated map art data), Coordinates, Flight Timer, Hide Filter Reset, Combat Alert, AddOns List, Error Catcher, Currency Bar, Character Frame Enhancements, Forever Quest Icons, Quest Tracker, Chat Copy, Short Channel Names, Chat Font, Persistent Chat, Chat History, Social Button (the last six in `Chat`).
  - `Changelog.lua`: the release notes as data (`ns.changelog`) for the Changelog page, since the game can't read `CHANGELOG.md`. Keep the two the same.
  - `Settings.lua`: the Settings pages: the welcome page (version, links, commands), Modules (a checkbox per module, grouped under a header per category, with its options under it behind a gear), a page per module `BuildPage`, Debug, and Changelog.
  - `Init.lua`: loaded last; calls `ns.Start()` at `PLAYER_LOGIN`.
  - `Media/Icon.tga`: the addon icon (64x64, 32-bit uncompressed TGA), used by the TOC's `IconTexture` and the welcome page as `ns.icon`. Made from `docs/project-icon.png`, which the README shows.
- `.github/workflows/check.yml`: on every push, checks Lua 5.1 syntax, ASCII, and that the TOC and the files match, then uploads the addon folder as a zip artifact. Pushing a `v*` tag also makes a GitHub release with the zip and uploads it to CurseForge (secret `CF_API_KEY`, variables `CF_PROJECT_ID` and `CF_GAME_VERSION_IDS`); bump `## Version` in the TOC to match first, and add the release's notes to `CHANGELOG.md` and `Changelog.lua`.
- `README.md`: for players and contributors: the module list, install, settings and commands, and "Add a module". Keep it short; rules and client detail belong here and in `docs/`.
- `docs/forever-api.md`: what we know about the Forever client API, with sources and how sure we are.
- `.luarc.json`: LuaLS settings (Lua 5.1 and the known globals).
- `tests/run.lua`: offline tests for pure-logic `Lib/` code (see "Verification").

There is no build step or library folder. Plain Lua, loaded straight from the TOC; CI only zips the folder.

## The client

- Client folder: `D:\BattleNet\World of Warcraft\_classic_beta_\` (product `wow_classic_beta`, version 1.60.1).
- `Interface\AddOns\ForeverPlusPlus` there is a link to `ForeverPlusPlus/` in this repo, so edits show up after `/reload`.
- **Treat the client folder as read only.** Never create, edit, or delete anything in it, including `WTF`, `Logs`, `Cache`, and other addons. Reading is fine.
- Useful things to read there:
  - `Logs\FrameXML.log`: Lua and XML load errors.
  - `Interface\AddOns\*`: other Forever addons show which APIs work on this client.
  - `WTF\Account\*\SavedVariables\ForeverPlusPlus.lua`: what the addon saved.

## How Forever differs from Classic

Forever is a Classic+ game (level 60 content) that runs the **modern Mainline (12.x "Midnight") client and UI**, not the Classic Era API. Assume Retail APIs and Retail rules, then check.

- `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE`. Don't use it to detect Forever. If a difference matters, use the interface number from `GetBuildInfo()` (range `[16000, 17000)`, and never "starts with 1": Classic Era is 11509), or better, probe for the API.
- Classic-only globals are gone: `GetItemInfo`, `GetSpellInfo`, `UnitAura`, `SetDesaturation`, and similar. Use `C_Item`, `C_Spell`, `C_UnitAuras`, `C_Container`, `C_AddOns`, `C_Timer`, etc.
- The UI is Mainline's: Edit Mode (`EditModeManagerFrame`, `C_EditMode`), the Settings panel (`Settings.RegisterCanvasLayoutCategory` / `RegisterVerticalLayoutCategory` + `Settings.RegisterAddOnCategory`), the `Menu` / `MenuUtil` context menus (`Menu.ModifyMenu` to add to Blizzard menus), `TooltipDataProcessor.AddTooltipPostCall`, `MicroMenu`, `AddonCompartmentFrame`, `ChatFrameUtil`, `BackdropTemplate`.
- **Secret values apply** (`issecretvalue`, `C_Secrets`). Unit health, power, identity, auras, cooldowns, and casts can come back secret, mostly in combat and instances. Never compare, test (`if v then`), do arithmetic on, concatenate, `#`, or use as a table key a value that might be secret. Pass it straight to widget setters (`SetText`, `SetValue`, `SetMinMaxValues`). Don't read state back from Blizzard widgets (`GetText`, `GetValue`, `IsShown`, sizes) and branch on it.
- `COMBAT_LOG_EVENT_UNFILTERED` never fires for addons. There is `C_DamageMeter` instead.
- `UnitName` returns a **surname**, not a realm, as its second value (`C_PlayerInfo.ShouldDisplaySurname`). Don't treat it as a realm.
- Talents/specs go through `C_SpecializationInfo`.
- Ship one plain `ForeverPlusPlus.toc`; this addon targets Forever only, so it needs no suffixes. On build 70009 the client picks `_Camelot.toc` over `_Mainline.toc` and the plain TOC, and per-file `[AllowLoadGameType camelot]` and `mainline` match Forever while `standard` and `classic` don't (an earlier build loaded `_Mainline` instead, so recheck after patches).
- It is a beta. APIs appear, change, and break between patches. Probe (`if C_Foo and C_Foo.Bar then`) instead of assuming, and when something only works on Forever, say so in a comment. (On 2026-09-23 SavedVariables didn't persist across reloads; they did by 2026-09-24. Recheck if settings stop sticking.)

When unsure whether an API exists, check it in game (`/dump C_Foo`, `/api`) or find an installed Forever addon that uses it. Don't guess from Classic Era or old Retail documentation. [docs/forever-api.md](docs/forever-api.md) has the detail behind this section: removed globals and their replacements, TOC loading, realms and surnames, talents, secret values, and open questions, each with its source. Keep the rules here short and record the evidence there.

## Working rules

- Keep changes scoped to the request. Don't reformat or revert unrelated code.
- One module per change the player can see. A module must work, and be removable, on its own.
- Plumbing that a second module could want (tracking nameplates, changing CVars, secret-value helpers) goes in `Lib/`, not inside a module. Modules never reach into each other; they share only `Lib/` and `Core.lua`.
- Default to on only for changes nearly everyone wants; otherwise `enabled = false`.
- When replacing behavior, delete the old path. No backwards compatibility for settings: no shims, migrations, or renamed-key fallbacks. Rename or drop a setting freely; the core clears settings for modules and options that no longer exist, and a dropdown whose saved value isn't a choice any more goes back to its default.
- Add a new file to the TOC, after `Core.lua` and before `Init.lua`: `Locales/` first (`enUS/` before other languages), then `Lib/`, then `Modules/`.
- Update `README.md` in the same change when a module is added, removed, or changes what it does or its default, or when commands or install steps change. Update the module list in "Project map" above too.
- Record things learned about the Forever client in `docs/forever-api.md`, tagged with how you know. Promote a fact to "How Forever differs from Classic" above only when it changes how code must be written.

## Lua rules

- Lua 5.1. ASCII only in `.lua` and `.toc` files. Four-space indents, LF endings (`.editorconfig`).
- Start every file with `local addonName, ns = ...` (or `local _, ns = ...`). Modules share state through `ns`, never `_G`.
- The only globals are `ForeverPlusPlusDB`, the `SLASH_FOREVERPLUSPLUS*` names, and `SlashCmdList.FOREVERPLUSPLUS`. Add any new client global you use to `.luarc.json`.
- Cache hot globals as file-level locals: `local pairs, CreateFrame = pairs, CreateFrame`.
- Use `ns.On` / `ns.Off` for events, not a new frame per module. For events a module listens to while it's on, use `self:On(event, fn)`; they stop by themselves when it turns off.
- A module that is off costs nothing: no frames, hooks, events, or `OnUpdate` until `OnEnable`. Every module turns on and off live, with no `/reload`: `OnDisable` undoes what `OnEnable` did (a module that only adds events with `self:On` and hooks with `self:Hook` needs none, since those stop by themselves). A hook can't be removed, so add it with `self:Hook` / `self:HookScript` (Core), which hook once and do nothing while the module is off; a hook made another way checks `module.enabled` itself.
- Read settings from `module.db`, filled from the defaults passed to `ns.NewModule`.
- Annotate public functions with LuaLS `---@param` / `---@return`. Match the comment style of `Core.lua`: short, plain, and saying why.
- Player-facing text goes through `ns.Print` and stays short. Anything a module says in chat by itself (not in reply to a command) goes through `module:Print` instead, with `chat = true` in its defaults and `ns.ChatOption(description)` in `module.options`, so the player gets a Chat Messages checkbox to silence it.
- Every player-facing string (chat, Settings names, descriptions, dropdown choices) is `ns.L.KEY`, with the English in `Locales/enUS/` (the file for the module's category). Prefix a module's keys with its name (`FRIENDLYPLATES_...`). Use `%s` placeholders instead of joining pieces, since word order differs between languages.

## Touching Blizzard's UI

The goal is to add to Blizzard frames without tainting or breaking them.

- Hook, don't replace: `hooksecurefunc(obj, "Method", fn)`, `frame:HookScript("OnShow", fn)`. Never `SetScript` on a Blizzard object and never overwrite a Blizzard function or mixin method.
- Never write fields onto Blizzard frames. Keep per-frame state in a weak-keyed table (`setmetatable({}, { __mode = "k" })`).
- Add your own regions and child frames instead of changing Blizzard's. To hide Blizzard art, prefer `SetAlpha(0)` over `Hide()` / `SetParent`.
- Don't move, resize, reparent, show, or hide protected frames (action buttons, unit frames, anything secure) in combat. Wrap the change in `ns.AfterCombat(fn)`, which runs it now or once combat ends.
- Many Blizzard windows are load-on-demand (`Blizzard_*` addons). Hook them after they load: check `C_AddOns.IsAddOnLoaded` and otherwise wait for `ADDON_LOADED` with that name.
- Look native: use `GameFontNormal` and related font objects, Blizzard atlases (`SetAtlas`), and Blizzard templates (`UIPanelButtonTemplate`, `UICheckButtonTemplate`, `BackdropTemplate` with Blizzard's own backdrop info) rather than custom art or fonts.
- If a module ever needs options beyond `/fpp`, put them in Blizzard's Settings panel, not a custom window.
- Lines we add to a tooltip look like Blizzard's Sell Price line: a white `Label:` on the left and its value at the right edge (`AddDoubleLine`), with details about the value in gray. Color carries meaning only (difficulty, age, class, faction), never decoration, and icons are Blizzard's art at text height (`|A:atlas:0:0|a`). On item tooltips, go through `ns.ItemTooltip`: facts about the item with `OnInfo` and `AddInfo`, prices with `OnPrices` and `AddPrice`, so our lines sit together above and at the sell price instead of trailing after Blizzard's. Recoloring Blizzard's own line (Profession Tooltips) beats adding a second one.

## Settings

`Settings.lua` builds every page from what modules declare; modules don't create Settings UI themselves (except a `BuildPage` tool page). Details are in "Add a module" in `README.md`.

- Keep the sidebar short: the top Forever++ entry is a welcome page, then Modules, tool pages (`BuildPage`), Debug, and Changelog. A module never gets a sidebar entry for its options.
- The Modules page is the only place modules turn on and off. Give every module a `module.category`: `automation`, `items`, `interface`, `chat`, `map`, `unitframes`, or `nameplates` (anything else lands under Other). It appears under that header, sorted by `module.title`.
- A tool with nothing to turn off sets `module.alwaysOn = true` and gets no checkbox. A module that only makes sense on some clients gives `module:IsAvailable()`; when that's false at login it stays off and out of Settings and `/fpp`.
- Options go in `module.options` (`{ key, name, description }`, default in `defaults`): a checkbox, a dropdown with `choices`, or a slider with `min`, `max`, `step`, and `format`. `requires = key` nests an option under a checkbox option, and `slider = key` puts a checkbox's slider in its row, to keep long option lists short. They sit indented under the module's checkbox, hidden until its gear is clicked. `debug = true` moves one to the Debug page. Buttons go in `module.actions`, after the options. React to changes in `module:OnOptionChanged(key)`.
- A module that silently depends on a Blizzard setting sets `module.notice`: a gray row under its checkbox while that setting is off, with a button that turns it on. For a CVar, use `ns.CVars.OffNotice`.
- For a module with many options, give them a `section` (an `ns.L` string). On the Modules page sections only order the options (headers there looked wrong, and a bare label row broke the page); on the Debug page each change of section starts a header. So list options grouped in the order they should show, usually a general section first.

## Git

- Conventional Commits, lowercase: `type(scope): summary`, for example `feat(tooltip): show item level on gear`. Scopes: `core`, a module name in lowercase, `docs`, `toc`.
- Never commit SavedVariables, zips, or anything from the client folder.
- "Commit" means verify, stage, commit, and confirm a clean tree. Don't push unless asked.

## Verification

`tests/run.lua` is a small set of offline tests for pure-logic `Lib/` code (colors, text and time formatting, instances, map helpers). It needs only Lua 5.1, no client: `lua5.1 tests/run.lua` from the repo root (CI runs it after the syntax check). It loads the real `Lib/` and `Locales/enUS/` files against a few stubbed WoW globals, so a Lib file that caches a global at load needs that global stubbed at the top of the file first. Add a check there when you change or add Lib logic that has no frames in it; don't test frame or UI code, and there is no other automated testing.

Before calling a change done:

1. Run `tests/run.lua`, and check syntax where a Lua 5.1 interpreter or LuaLS is available (`luac -p` on changed files).
2. In the Forever client: `/reload`, then check `/fpp` lists the module, toggle it off and on, and check BugSack and `Logs\FrameXML.log` for errors.
3. For anything that touches unit, aura, cast, or combat data, also test in combat, where secret values apply.
4. Report exactly what was checked. Name every step that still needs someone in the live client, and never claim in-game testing that didn't happen.
