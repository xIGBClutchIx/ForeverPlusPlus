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
  - `Core.lua`: the shared `ns`: events (`ns.On`, `ns.Off`), saved settings, modules (`ns.NewModule`, `ns.SetEnabled`), `/fpp`, `ns.Print`.
  - `Modules/*.lua`: one change each. `Example.lua` is the template.
  - `Init.lua`: loaded last; calls `ns.Start()` at `PLAYER_LOGIN`.
- `README.md`: install and usage for people.
- `.luarc.json`: LuaLS settings (Lua 5.1 and the known globals).

There is no build step, packager, or library folder. Plain Lua, loaded straight from the TOC.

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
- TOC suffixes are unreliable on this client (it loaded `_Mainline.toc` over `_Camelot.toc`). Ship one plain `ForeverPlusPlus.toc` only.
- It is a beta. APIs appear, change, and break between patches. Probe (`if C_Foo and C_Foo.Bar then`) instead of assuming, and when something only works on Forever, say so in a comment. (On 2026-09-23 SavedVariables didn't persist across reloads; they did by 2026-09-24. Recheck if settings stop sticking.)

When unsure whether an API exists, check it in game (`/dump C_Foo`, `/api`) or find an installed Forever addon that uses it. Don't guess from Classic Era or old Retail documentation. Record anything you confirm or rule out in this section.

## Working rules

- Keep changes scoped to the request. Don't reformat or revert unrelated code.
- One module per change the player can see. A module must work, and be removable, on its own.
- Default to on only for changes nearly everyone wants; otherwise `enabled = false`.
- When replacing behavior, delete the old path. No compatibility shims or migrations for unreleased settings.
- Add a new file to the TOC, after `Core.lua` and before `Init.lua`.
- Update `README.md` in the same change when commands, install steps, or the layout change.
- Record things learned about the Forever client in "How Forever differs from Classic" above.

## Lua rules

- Lua 5.1. ASCII only in `.lua` and `.toc` files. Four-space indents, LF endings (`.editorconfig`).
- Start every file with `local addonName, ns = ...` (or `local _, ns = ...`). Modules share state through `ns`, never `_G`.
- The only globals are `ForeverPlusPlusDB`, the `SLASH_FOREVERPLUSPLUS*` names, and `SlashCmdList.FOREVERPLUSPLUS`. Add any new client global you use to `.luarc.json`.
- Cache hot globals as file-level locals: `local pairs, CreateFrame = pairs, CreateFrame`.
- Use `ns.On` / `ns.Off` for events, not a new frame per module.
- A module that is off costs nothing: no frames, hooks, events, or `OnUpdate` until `OnEnable`. Undo what you can in `OnDisable`; if a change (such as a hook) can only be undone by `/reload`, leave out `OnDisable` and the core says so.
- Read settings from `module.db`, filled from the defaults passed to `ns.NewModule`.
- Annotate public functions with LuaLS `---@param` / `---@return`. Match the comment style of `Core.lua`: short, plain, and saying why.
- Player-facing text goes through `ns.Print` and stays short.

## Touching Blizzard's UI

The goal is to add to Blizzard frames without tainting or breaking them.

- Hook, don't replace: `hooksecurefunc(obj, "Method", fn)`, `frame:HookScript("OnShow", fn)`. Never `SetScript` on a Blizzard object and never overwrite a Blizzard function or mixin method.
- Never write fields onto Blizzard frames. Keep per-frame state in a weak-keyed table (`setmetatable({}, { __mode = "k" })`).
- Add your own regions and child frames instead of changing Blizzard's. To hide Blizzard art, prefer `SetAlpha(0)` over `Hide()` / `SetParent`.
- Don't move, resize, reparent, show, or hide protected frames (action buttons, unit frames, anything secure) in combat. Check `InCombatLockdown()` and defer the change to `PLAYER_REGEN_ENABLED`.
- Many Blizzard windows are load-on-demand (`Blizzard_*` addons). Hook them after they load: check `C_AddOns.IsAddOnLoaded` and otherwise wait for `ADDON_LOADED` with that name.
- Look native: use `GameFontNormal` and related font objects, Blizzard atlases (`SetAtlas`), and Blizzard templates (`UIPanelButtonTemplate`, `UICheckButtonTemplate`, `BackdropTemplate` with Blizzard's own backdrop info) rather than custom art or fonts.
- If a module ever needs options beyond `/fpp`, put them in Blizzard's Settings panel, not a custom window.

## Git

- Conventional Commits, lowercase: `type(scope): summary`, for example `feat(tooltip): show item level on gear`. Scopes: `core`, a module name in lowercase, `docs`, `toc`.
- Never commit SavedVariables, zips, or anything from the client folder.
- "Commit" means verify, stage, commit, and confirm a clean tree. Don't push unless asked.

## Verification

There are no automated tests. Before calling a change done:

1. Check syntax where a Lua 5.1 interpreter or LuaLS is available (`luac -p` on changed files).
2. In the Forever client: `/reload`, then check `/fpp` lists the module, toggle it off and on, and check BugSack and `Logs\FrameXML.log` for errors.
3. For anything that touches unit, aura, cast, or combat data, also test in combat, where secret values apply.
4. Report exactly what was checked. Name every step that still needs someone in the live client, and never claim in-game testing that didn't happen.
