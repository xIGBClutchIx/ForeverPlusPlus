<p align="center"><img src="docs/project-icon.png" alt="Forever++" width="128"></p>

# Forever++

A World of Warcraft addon for **WoW: Forever** that adds to and changes the default UI in small, separate modules. It doesn't replace the UI: every change is meant to look like Blizzard shipped it, needs no setup, and can be turned off on its own.

## Modules

Everything is on by default except where noted. Each module can be turned off, and most have options.

| Module | What it does |
|---|---|
| **Automation** | |
| Auto Decline | Turns down duel requests and closes the popup, and says in chat who asked. Can let friends and guildmates through. Off by default. |
| Auto Dismount | Gets you off your mount or stands you up when a spell, flight, loot, or attack fails because you're mounted or sitting. Can also leave shapeshift forms (off by default). |
| Auto Gossip | When an NPC has only one thing to say and no quests, picks it for you, so the bank, shop, or flight map opens straight away. Hold Shift to choose yourself. |
| Auto Release | Releases your spirit when you die in a battleground, unless you can resurrect yourself or someone is resurrecting you. Off by default. |
| Auto Repair | Repairs your gear at any merchant who repairs and says in chat what it cost. Hold Shift to skip it. |
| Auto Stow | Puts your weapons away a few seconds after combat ends. |
| Fast Loot | With auto loot on, takes everything at once instead of waiting for the loot window. |
| Gathering Tracking | Keeps Find Minerals or Find Herbs on after logging in, zoning, or dying, and can swap between the two. |
| Skip Cinematics | Skips cinematics and movies you've already seen on any character, or every one. Hold Shift to watch. Off by default. |
| **Items** | |
| Auction Prices | Scans the auction house when you open it and shows the lowest buyout in item tooltips, under the sell price. |
| Bag Slot Counter | Shows how many slots each bag has free on its button, or the total on the backpack button, with the reagent bag counted on its own. |
| Durability Bars | Shows a small bar beside each item on the character window with how worn it is. |
| Gathering Tooltips | Shows the skill a herb, ore, or skinnable beast needs in its tooltip, colored like trainer recipes against your skill, and the skill that gathers herb, ore, and stone items. For professions you have, or always. |
| Sell Price | Shows the vendor price of the whole stack in item tooltips. Hold Shift for one item. |
| **Interface** | |
| Auto Screenshot | Takes a screenshot when you level up, earn an achievement, or defeat a boss, and can for good loot, reputation, PvP ranks, titles, battlegrounds, and deaths. Off by default. |
| Hide Beta Feedback | Hides the beta's "Press F6 to submit an issue" tooltip line and bug report button. Off by default, and only on beta and PTR clients. |
| Tooltips | Colors unit and item tooltips by class, reaction, or quality, and adds player titles and who a unit is targeting. |
| **Unit Frames** | |
| Class Colors | Shows players' health bars, and optionally names, in their class color on the player, target, focus, party, and target-of-target frames. |
| **Nameplates** | |
| NPC Nameplates | Always shows friendly NPCs' names with their title. The health bar appears only when they're hurt or in combat. |
| Player Nameplates | Always shows friendly players' names with their guild, and recent allies' names in the game's light blue. The health bar appears only when they're hurt or in combat. |
| **Tools** | |
| Console Variables | A page in Settings to browse and change the game's console variables (CVars). |

## Install

1. Download the zip from the latest [release](https://github.com/xIGBClutchIx/ForeverPlusPlus/releases), or for the newest build, from the latest successful [Check run](https://github.com/xIGBClutchIx/ForeverPlusPlus/actions/workflows/check.yml) on `main` (under Artifacts; needs a GitHub login).
2. Unzip it into the Forever client's AddOns folder, for example `World of Warcraft\_classic_beta_\Interface\AddOns\`, so you end up with `AddOns\ForeverPlusPlus\ForeverPlusPlus.toc`.
3. Start the game, or `/reload` if it's already running.

## Use

Open Game Menu > Options > AddOns > Forever++. It opens on a welcome page with the version, links, and commands. Modules has a checkbox for each module, grouped by category; the gear beside a module shows its options under it. Console Variables is its own page, Debug has testing options, and Changelog has what changed in each release (also in [CHANGELOG.md](CHANGELOG.md)).

| Command | What it does |
|---|---|
| `/fpp` | Opens the Forever++ settings (`/forever++` works too). |
| `/fpp list` | Lists the modules and whether each is on. |
| `/fpp toggle <module> [option]` | Turns a module on or off, or with an option, flips that checkbox. |
| `/fpp options <module>` | Lists a module's options and their values. |
| `/fpp set <module> <option> [value]` | Changes an option: `on`/`off`, or a choice such as `/fpp set PlayerPlates level after`. Leave out the value to see the choices. |
| `/fpp reset` | Puts every setting back to its default and reloads. |
| `/fpp cvar [search]` | Opens Console Variables. |
| `/fpp scan` | Scans the open auction house now. |
| `/fpp resetprices` | Forgets the saved auction prices. |

Settings are saved per account in `ForeverPlusPlusDB`.

## Feedback

Bugs and ideas go in [GitHub issues](https://github.com/xIGBClutchIx/ForeverPlusPlus/issues).

## Contributing

Forever runs the modern Retail client and API, not Classic Era, so read [AGENTS.md](AGENTS.md) first: it has the rules for this repository and how Forever differs. [docs/forever-api.md](docs/forever-api.md) records what's known about the client API. There's no build step; the addon is plain Lua loaded from the TOC.

For development, link the addon folder into the client instead of copying it, so edits show up after `/reload`. In a Command Prompt:

```
mklink /J "<WoW folder>\_classic_beta_\Interface\AddOns\ForeverPlusPlus" "<this repo>\ForeverPlusPlus"
```

### Add a module

1. Create `Modules/YourThing.lua` starting with `local _, ns = ...`, and add it to the TOC before `Init.lua`.
2. Call `ns.NewModule("YourThing", ns.L.YOURTHING_DESC, { enabled = true, ... })`. The description is its tooltip in Settings, and `module.title = ns.L.YOURTHING_TITLE` is the name shown there. Every string the player sees goes in `Locales/enUS.lua`, keyed with the module's name.
3. Do the work in `OnEnable` and undo it in `OnDisable`: modules turn on and off without a reload. A hook can't be removed, so it checks `module.enabled`. Events added with `self:On(event, fn)` stop by themselves.
4. Set `module.category` (`automation`, `items`, `interface`, `unitframes`, or `nameplates`). A tool with nothing to turn off sets `module.alwaysOn = true` and gets no checkbox. A module only for some clients gives `module:IsAvailable()`.
5. Read settings from `module.db`. List options in `module.options` (`{ key, name, description }`, default in `defaults`): a checkbox, or a dropdown with `choices = { { value, label }, ... }`. Add `debug = true` to put one on the Debug page, or a `section` (a locale string) to keep a long list in groups. React in `module:OnOptionChanged(key)`. Buttons go in `module.actions` (`{ name, button, description, fn }`). If it needs a Blizzard setting (a CVar) on, `module.notice = ns.CVars.OffNotice(module, cvar, text, description)` warns in Settings while it's off.
6. Anything the module says in chat by itself goes through `module:Print`, with `chat = true` in `defaults` and `ns.ChatOption(description)` in `module.options`, so the player can turn it off.
7. For a page the module draws itself, give it `module:BuildPage(frame)`; `ns.OpenSettings(module.name)` opens it. `ns.AddCommand(name, usage, description, fn)` adds `/fpp <name>`.

Settings aren't migrated: renaming or dropping an option is fine, and stale saved values are cleared when the addon loads.
