# Forever++

A World of Warcraft addon for **WoW Forever** that adds to and changes the default UI, one small module at a time. It doesn't replace the UI.

## Install

Link the addon folder into the Forever client's AddOns folder once, so edits here show up after a `/reload`. In a Command Prompt:

```
mklink /J "D:\BattleNet\World of Warcraft\_classic_beta_\Interface\AddOns\ForeverPlusPlus" "C:\Users\camer\repos\xigbclutchix\ForeverPlusPlus\ForeverPlusPlus"
```

## Use

- Game Menu > Options > AddOns > Forever++ has a checkbox for each module. Modules with options get their own page under it, and testing options are on the Debug page.
- `/fpp` opens the Forever++ settings.
- `/fpp list` lists the modules and whether each is on.
- `/fpp toggle <name>` turns one on or off.
- `/fpp options <name>` lists a module's options and their values.
- `/fpp set <name> <option> <value>` changes one: `on`/`off` for a checkbox, a choice key for a dropdown (for example `/fpp set FriendlyPlates level after`). Leave out the value to see the current one and what it can be.
- `/fpp toggle <name> <option> [value]` does the same as `set`.
- `/fpp reset` puts every setting back to its default and reloads.
- `/fpp cvar [search]` opens the Console Variables page: every CVar with its value and default. Type a new value and press Enter, or click Default. Changes made in combat wait until it ends.

## Layout

| File | What |
|---|---|
| `ForeverPlusPlus.toc` | Load order and metadata; `## Interface: 16001` (Forever) |
| `Core.lua` | The shared namespace: events (`ns.On`, `ns.Off`), saved settings, modules (`ns.NewModule`), `/fpp`, `ns.Print`, the locale table `ns.L` |
| `Locales/*.lua` | Player-facing text: `enUS.lua` has every string and is the fallback for other languages |
| `Lib/*.lua` | Shared services for modules: secret-value helpers, CVar changes, nameplate tracking, group/friend/guild checks |
| `Modules/` | One change each; a bigger module gets its own folder |
| `Settings.lua` | The Forever++ pages in Settings > AddOns: module checkboxes, a page per module, and Debug |
| `Init.lua` | Loaded last; starts the modules at `PLAYER_LOGIN` |

Settings are saved in `ForeverPlusPlusDB`, one table per module (`ForeverPlusPlusDB.modules.<Name>`), filled from the module's defaults.

## Add a module

1. Create `Modules/YourThing.lua` starting with `local _, ns = ...`, and add it to the TOC before `Init.lua`.
2. `ns.NewModule("YourThing", ns.L.YOURTHING_DESC, { enabled = true, ... })`. The description is the tooltip in Settings; set `module.title = ns.L.YOURTHING_TITLE` for the name shown there. Put the English for every string the player sees in `Locales/enUS.lua`, keyed with the module's name.
3. Do the work in `OnEnable`; undo it in `OnDisable` if it can be undone without a reload.
4. Read settings from `module.db`. For an extra option in Settings, list it in `module.options` (`{ key, name, description }`, with its default in `defaults`); it's a checkbox, or a dropdown if it has `choices = { { value, label }, ... }`, and goes on the Debug page with `debug = true`. React in `module:OnOptionChanged(key)`.
5. For a page the module draws itself (a list, say), give it `module:BuildPage(frame)`: it gets its own page in Settings, built the first time it's shown, and `ns.OpenSettings(module.name)` opens it. `ns.AddCommand(name, usage, description, fn)` adds `/fpp <name>`.

Change Blizzard frames with `hooksecurefunc` or `HookScript`, and don't touch protected frames in combat (wrap it in `ns.AfterCombat`).

Settings for a module that's no longer there, or an option it dropped, are cleared when the addon loads, and a dropdown whose saved value isn't a choice any more goes back to its default.
