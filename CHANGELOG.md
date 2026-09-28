# Changelog

What changed in each release of Forever++. The same notes show in game under Settings > AddOns > Forever++ > Changelog, from [`ForeverPlusPlus/Changelog.lua`](ForeverPlusPlus/Changelog.lua); change both together.

## Unreleased

### Changed

- **Class Colors**: hostile NPCs' health bars are red, neutral ones yellow, and ones someone else tagged gray, on the same frames. Friendly NPCs stay green. Includes an NPC Health Bars checkbox to turn it off.
- **Bag Slot Counter**: adds up every bag on the backpack button by default, with the reagent bag still on its own button. Per Bag is still a choice.

### Fixed

- **Player Nameplates**: Chinese, Korean, and Cyrillic names show again, instead of coming out blank.
- **NPC Nameplates**: same fix for NPC names and titles.

## 0.2.0 (2026-09-27)

### Added

- **Auto Decline**: turns down duel requests and closes the popup. Includes letting friends and guildmates through, and saying in chat who was declined. Off by default.
- **Auto Dismount**: gets you off your mount or stands you up when a spell, flight, loot, or attack fails because you're mounted or sitting. Includes separate Dismount and Stand Up options, and leaving shapeshift forms (off by default).
- **Auto Release**: releases your spirit when you die in a battleground. Includes a delay, and staying put when a soulstone, reincarnation, or someone else can resurrect you. Off by default.
- **Auto Screenshot**: takes a screenshot a moment after you level up, earn an achievement, or defeat a boss, so Blizzard's toast is in it. Includes checkboxes for loot of a chosen quality, reputation standings, PvP ranks, new titles, battleground ends, and deaths, hiding the interface for the shot, and a chat line saying why. Off by default.
- **Bag Slot Counter**: how many bag slots are free, on the bag buttons. Includes each bag's own count or the total on the backpack, the reagent bag on its own button, added to the backpack, or hidden, counting special bags such as quivers and herb bags, and the text's size and position.
- **Class Colors**: players' health bars and names in their class color on the player, target, focus, party, and target-of-target frames. Includes health bars and names (off by default) separately, and a checkbox for each frame.
- **Gathering Tooltips**: the skill a herb, ore, or skinnable beast needs, in its tooltip in the world or on the minimap, colored red, orange, yellow, green, or gray against your skill like trainer recipes. Herb, ore, and stone items say the skill that gathers them. Includes showing it only for professions you have or always, and a checkbox each for herbs, ore, creatures, and items.
- **Skip Cinematics**: skips the game's cinematics and movies. Off by default. Includes skipping only ones already seen on any character or every one, holding Shift to watch, and a Forget button for the seen list.

### Changed

- **Player Nameplates**: recent allies' names in the game's light blue, instead of the Name Color. Includes a checkbox to turn it off.
- **Settings**: fewer entries in the sidebar. Forever++ opens on a welcome page, and every module is on one Modules page, where the gear beside a module shows its options under it. About is part of the welcome page.

## 0.1.0 (2026-09-27)

### Added

- **Auction Prices**: scans the auction house when you open it and shows the lowest buyout in item tooltips. Includes how long ago the item was scanned (colored by age), the same price options as Sell Price, `/fpp scan`, and a Reset button and `/fpp resetprices` to forget saved prices.
- **Auto Gossip**: picks an NPC's only option when it has nothing else to say and no quests. Includes a choice for bankers, vendors, trainers, flight masters, stable masters, and other NPCs, and holding Shift to choose yourself.
- **Auto Repair**: repairs your gear at merchants and says in chat what it cost. Includes paying from the guild bank first, the guild bank only, or your own money, a minimum cost, and holding Shift to skip it.
- **Auto Stow**: puts your weapons away after combat. Includes the delay and leaving them out in dungeons, raids, and battlegrounds.
- **Console Variables**: a Settings page to browse, search, and change the game's console variables (CVars). Includes a Changed Only filter and `/fpp cvar [search]`.
- **Durability Bars**: a bar beside each item on the character window with how worn it is. Includes showing bars always, only when worn, below 50%, or below 25%.
- **Fast Loot**: with auto loot on, takes everything at once. Includes a warning in Settings, with a Turn On button, when Blizzard's auto loot is off.
- **Gathering Tracking**: keeps Find Minerals or Find Herbs on. Includes minerals, herbs, or both, turning tracking back on after logging in, zoning, or dying, and swapping between the two every few seconds.
- **Hide Beta Feedback**: hides the beta's "Press F6 to submit an issue" tooltip line and the bug report button, each on its own. Off by default, and only on beta and PTR clients.
- **NPC Nameplates**: friendly NPCs' names with their title, and a health bar only when they're hurt or in combat. Includes name color, where the level goes, and when and in what color titles show.
- **Player Nameplates**: friendly players' names with their guild, and a health bar only when they're hurt or in combat. Includes class-colored names, where the level goes, guild line and color, highlighting guildmates, and role icons for group members and Battle.net icons for friends.
- **Sell Price**: the vendor price in item tooltips. Includes the whole stack or one item (Shift shows the other), lining up with other price lines, and the quantity color.
- **Tooltips**: colors unit and item tooltips. Includes borders by class, reaction, or item quality, name, guild, level, and class name colors, player titles, a Target line, anchoring to the cursor, and hiding unit tooltips in combat.
- **Settings**: Forever++ in Game Menu > Options > AddOns. Includes a checkbox per module grouped by category, a page per module with options, Debug, Changelog, and About. Every module turns on and off without a reload.
- **Commands**: `/fpp` or `/forever++` opens the settings. Includes `list`, `toggle`, `options`, `set`, and `reset`.
