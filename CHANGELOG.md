# Changelog

What changed in each release of Forever++. The same notes show in game under Settings > AddOns > Forever++ > Changelog, from [`ForeverPlusPlus/Changelog.lua`](ForeverPlusPlus/Changelog.lua); change both together.

## 0.1.0 (2026-09-27)

The first release.

### Automation

- **Auto Gossip**: when an NPC has only one thing to say and no quests, picks it for you, so the bank, shop, trainer, flight map, or stable opens straight away. Each kind can be turned off, and holding Shift lets you choose yourself.
- **Auto Repair**: repairs your gear at any merchant who repairs and says in chat what it cost. Choose whether the guild bank or your own money pays, and a minimum cost. Hold Shift to skip it.
- **Auto Stow**: puts your weapons away a few seconds after combat ends, with a choice of delay, and can leave them out in dungeons, raids, and battlegrounds.
- **Fast Loot**: with auto loot on, takes everything at once instead of waiting for the loot window. Warns in Settings when Blizzard's auto loot is off.
- **Gathering Tracking**: keeps Find Minerals or Find Herbs on after logging in, zoning, or dying, and can swap between the two every few seconds.

### Items

- **Auction Prices**: scans the auction house when you open it and shows the lowest buyout in item tooltips, with how old the scan is. `/fpp scan` scans now and `/fpp resetprices` forgets the saved prices.
- **Durability Bars**: a small bar beside each item on the character window with how worn it is.
- **Sell Price**: the vendor price of the whole stack in item tooltips. Hold Shift for one item. Price lines from Sell Price and Auction Prices line up with each other.

### Interface

- **Hide Beta Feedback**: hides the beta's "Press F6 to submit an issue" tooltip line and the bug report button. Off by default, and only on beta and PTR clients.
- **Tooltips**: colors unit and item tooltips by class, reaction, or quality, and adds player titles and who a unit is targeting. Can show tooltips at the mouse and hide unit tooltips in combat.

### Nameplates

- **NPC Nameplates**: always shows friendly NPCs' names with their title. The health bar appears only when they're hurt or in combat.
- **Player Nameplates**: always shows friendly players' names with their guild, and icons for group members and Battle.net friends. The health bar appears only when they're hurt or in combat.
- Both warn in Settings when Blizzard's friendly nameplates are off, with a button to turn them on.

### Tools

- **Console Variables**: a page in Settings to browse, search, and change the game's console variables (CVars). `/fpp cvar` opens it.

### Settings and commands

- Everything lives in Game Menu > Options > AddOns > Forever++: a checkbox per module grouped by category, a page per module with options, Debug, Changelog, and About.
- `/fpp` (or `/forever++`) opens the settings; `/fpp list`, `toggle`, `options`, `set`, and `reset` do the same from chat.
- Every module turns on and off without a reload.
