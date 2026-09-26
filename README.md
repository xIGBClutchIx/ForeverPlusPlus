# Forever++

A World of Warcraft addon for **WoW Forever** that adds to and changes the default UI, one small module at a time. It doesn't replace the UI.

## Install

Link the addon folder into the Forever client's AddOns folder once, so edits here show up after a `/reload`. In a Command Prompt:

```
mklink /J "D:\BattleNet\World of Warcraft\_classic_beta_\Interface\AddOns\ForeverPlusPlus" "C:\Users\camer\repos\xigbclutchix\ForeverPlusPlus\ForeverPlusPlus"
```

## Use

- Game Menu > Options > AddOns > Forever++ has a checkbox for each module. Modules with options get their own page under it, and testing options are on the Debug page.
- `/fpp` lists the modules and whether each is on.
- `/fpp toggle <name>` turns one on or off.
- `/fpp reset` puts every setting back to its default and reloads.

## Layout

| File | What |
|---|---|
| `ForeverPlusPlus.toc` | Load order and metadata; `## Interface: 16001` (Forever) |
| `Core.lua` | The shared namespace: events (`ns.On`, `ns.Off`), saved settings, modules (`ns.NewModule`), `/fpp`, `ns.Print` |
| `Modules/*.lua` | One change each |
| `Settings.lua` | The Forever++ pages in Settings > AddOns: module checkboxes, a page per module, and Debug |
| `Init.lua` | Loaded last; starts the modules at `PLAYER_LOGIN` |

Settings are saved in `ForeverPlusPlusDB`, one table per module (`ForeverPlusPlusDB.modules.<Name>`), filled from the module's defaults.

## Add a module

1. Create `Modules/YourThing.lua` starting with `local _, ns = ...`, and add it to the TOC before `Init.lua`.
2. `ns.NewModule("YourThing", "One line on what it does.", { enabled = true, ... })`. The description is the tooltip in Settings; set `module.title = "Your Thing"` for the name shown there.
3. Do the work in `OnEnable`; undo it in `OnDisable` if it can be undone without a reload.
4. Read settings from `module.db`. For an extra option in Settings, list it in `module.options` (`{ key, name, description }`, with its default in `defaults`); it's a checkbox, or a dropdown if it has `choices = { { value, label }, ... }`, and goes on the Debug page with `debug = true`. React in `module:OnOptionChanged(key)`.

Change Blizzard frames with `hooksecurefunc` or `HookScript`, and don't touch protected frames in combat (`InCombatLockdown()`).
