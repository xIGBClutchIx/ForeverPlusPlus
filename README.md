# Forever++

A World of Warcraft addon for **WoW Forever** that adds to and changes the default UI, one small module at a time. It doesn't replace the UI.

## Install

Link the addon folder into the Forever client's AddOns folder once, so edits here show up after a `/reload`. In a Command Prompt:

```
mklink /J "D:\BattleNet\World of Warcraft\_classic_beta_\Interface\AddOns\ForeverPlusPlus" "C:\Users\camer\repos\xigbclutchix\ForeverPlusPlus\ForeverPlusPlus"
```

## Use

- `/fpp` lists the modules and whether each is on.
- `/fpp toggle <name>` turns one on or off.
- `/fpp reset` puts every setting back to its default and reloads.

## Layout

| File | What |
|---|---|
| `ForeverPlusPlus.toc` | Load order and metadata; `## Interface: 16001` (Forever) |
| `Core.lua` | The shared namespace: events (`ns.On`, `ns.Off`), saved settings, modules (`ns.NewModule`), `/fpp`, `ns.Print` |
| `Modules/*.lua` | One change each. `Example.lua` is a template |
| `Init.lua` | Loaded last; starts the modules at `PLAYER_LOGIN` |

Settings are saved in `ForeverPlusPlusDB`, one table per module (`ForeverPlusPlusDB.modules.<Name>`), filled from the module's defaults.

## Add a module

1. Copy `Modules/Example.lua` to `Modules/YourThing.lua` and add it to the TOC before `Init.lua`.
2. `ns.NewModule("YourThing", "One line on what it does.", { enabled = true, ... })`.
3. Do the work in `OnEnable`; undo it in `OnDisable` if it can be undone without a reload.
4. Read settings from `module.db`.

Change Blizzard frames with `hooksecurefunc` or `HookScript`, and don't touch protected frames in combat (`InCombatLockdown()`).
