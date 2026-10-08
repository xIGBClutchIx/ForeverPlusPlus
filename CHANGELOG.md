# Changelog

What changed in each release of Forever++. The same notes show in game under Settings > AddOns > Forever++ > Changelog, from [`ForeverPlusPlus/Changelog.lua`](ForeverPlusPlus/Changelog.lua); change both together.

## Unreleased

### Added

- **Talent Planner** (new, on by default, in Interface): a Plan Talents button on the talent window. Place talents freely without learning them, in order, up to the points you have at a level you choose, then follow the plan as you level: its next talent glows, tooltips say at which level each rank comes, and hovering the line beside the button lists the plan in order. A dropdown keeps several named plans, and shares or imports one as a line of text.
- **Commands** (new, on by default, in Interface): short slash commands, each with its own checkbox. `/way [zone] x y` puts the game's map pin on a spot and tracks it (`/way clear` takes it away), `/rl` reloads the UI, and `/clear` empties a chat window. A command another addon already has, like TomTom's `/way`, is left to it.
- **Settings**: a search box at the top of the Modules page shows only the modules whose name or description has what you type, under their category headers. Clear it to see every module again.
- **Auto Quest** (new, off by default, in Automation): accepts quests and turns in finished ones as you talk to quest givers, one by one down a quest giver's list. It never picks a reward when there's a choice. Accepting and turning in have their own checkboxes, repeatable and shared quests can be left out, and holding Shift (or Ctrl, Alt, or no key) lets you do it yourself.

### Changed

- **Auction Prices**: Crafting Costs shows Estimated Profit, after the auction house's 5% cut, and, at the top, how old the oldest auction price in the totals is.
- **Class Colors**: new Friends and Who List option (on by default) shows online friends' names in the friends list and names in the who list in their class color.
- **Chat Copy**: the window shows chat lines in their chat colors, with names in their class colors and links in theirs, the way they look in chat. Copying still gives plain text.
- **Error Catcher**: new Button option puts its button on the minimap, in the addon compartment, both, or neither. The minimap is still the default.
- **Settings**: Clutch's Default is now Developer's Defaults, and the welcome page's Defaults button is now Recommended Defaults, matching the Defaults popup on the Modules and Debug pages.
- **Points of Interest**: new Ley Lines option shows Skyborne ley lines and elemental convergences on the map. A spot is saved when a Skyborne gets the 15-minute buff from Read Ley Line or Skysight there, and every character on the account sees it. Shown to Skyborne for their own kind by default, or to everyone, or to no one.

### Fixed

- **Character Frame Enhancements**: works with Forever's new Titles tab. Titles gets its own side tab, the Pet tab opens your pet's stats again instead of Titles, the titles list starts at the top like the stats, and the pet pane keeps your pet's level and loyalty. Your pet's tab also comes and goes with your pet while another tab is open.

## 0.7.0 (2026-10-02)

### Added

- **Best Quest Reward** (new, on by default, in Items): marks the quest reward that sells to a vendor for the most with a gold coin, in the quest window and the quest log.
- **Item Count** (new, off by default, in Items): shows in an item's tooltip how many you own, in your bags and in your bank.
- **Easy Delete** (new, off by default, in Items): types DELETE for you when you destroy a good item.
- **Movable Framerate** (new, off by default, in Interface): move and resize the framerate text (Ctrl+R) in Edit Mode.
- **Auction Prices**: new Crafting Costs option shows a recipe's total cost, value, and profit in the professions window. Reagent tooltips there now price the amount the recipe needs, for Sell Price too.
- **Fishing Cast**: new Combat Warning option warns you when combat starts with a fishing pole equipped.
- **Points of Interest** and **Zone Info**: Forever's new boats and skyships, and the Excavation Site and City of Dalaran dungeons.

### Changed

- **Points of Interest**: Forever's flight masters are named for their places, and its dungeons show in your language.
- **Error Catcher**: a redesigned window with a list of errors and a Copy Bug Report button. Right-click the minimap button to open Forever++ settings.
- **Spell Ranks**: "Higher Rank Known:" in spell tooltips now looks like the other tooltip lines.

### Fixed

- **Edit Mode**: the arrow keys nudge Combat Alert, Currency Bar, and Flight Timer again.
- **Auction Prices**: a price's age is when the item was last seen, not the last scan. Saved prices are cleared once.
- **Sell Price**: no more Lua error on a vendor's buyback tab.

## 0.6.0 (2026-10-01)

### Added

- **Quest Tracker** (new, on by default, in Interface): restyles Blizzard's quest tracker with a font, size, and outline, a dark box behind it that fits your quests, and fading in combat. It's still Blizzard's tracker, so Edit Mode and quest items work as before.
- **Error Catcher** (new, on by default, in Interface): catches Lua errors and blocked actions in place of Blizzard's error popup, saves them per session, and shows them in a window you can copy from (`/fpp errors` or the minimap button). Ctrl-right-click the minimap button to clear this session's errors.
- **Character Frame Enhancements** (new, on by default, in Interface): moves the Character window's Equipment and Pet tabs to the side with the others, removes the portrait and level line so the stats start at the top, and shows your level and name in your class color as the title.
- **Forever Quest Icons** (new, on by default, in Interface): marks quests that are new to Forever with an infinity sign (or the Forever logo) after their name in the quest log, the objective tracker, and quest givers' lists. Idea from ForeverQuestTint.
- **Quest Nameplates**: new Party Progress option to count everyone's progress added up (the default), only yours, or the party member furthest from done. Creatures only a party member needs now show too.
- **Class Colors**: the Names checkbox is now a Name Color choice (Default, White, or Class Color), and a new Name Backgrounds option (on by default) tints the bar behind a player's name on the target and focus frames in their class color.

### Changed

- **Persistent Chat**: renamed from Chat Fading, and now on by default.
- **Auto Repair** and **Auto Sell Junk**: holding Shift to skip is now an option (on by default).
- **Settings**: the Defaults button on the Modules and Debug pages now offers Clutch's Defaults or Recommended Defaults and resets only Forever++. Blizzard's All Settings reset no longer touches Forever++.
- **Settings**: Clutch's Default also sets Zone Info's Dungeons and Fishing to Hold Detail Key.
- **Settings**: Combat Alert, Currency Bar, and Flight Timer are sized and reset only in Edit Mode now.

### Fixed

- **Fishing Cast**: double right-click now casts Fishing.
- **Tooltips**: levels and class names are colored again, player titles show, and the Target line shows the target's name instead of its level.
- **Flight Timer**: no longer draws over other windows.

## 0.5.0 (2026-10-01)

### Added

- **Chat Fading** (new, off by default, in Chat): keeps chat text on screen instead of fading it out after a while.

### Changed

- **Hide Beta Feedback**: also hides the beta's feedback buttons on quest windows (quest, gossip, and quest log), with its own checkbox.
- **Quest Nameplates**: the icon matches the objective: Blizzard's attack, pickup, or interact icon for kill, item, or object objectives, and the quest icon for the rest. A creature whose objective is done shows a green check and its final count (8/8), unless you turn off Show Completed, and the count can be turned off to leave just the check.
- **Player Nameplates and NPC Nameplates**: on name-only plates the buffs sit centered above the name instead of far off to the left. A Buffs setting puts them above, before, or after the name, or back in Blizzard's spot.
- **Profession Tooltips**: the game's own bare "Mining" line under a vein is replaced by "Requires Mining (1)" in the difficulty color instead of showing both. When Blizzard already says "Requires Mining (1)", a bare name line below it shows your skill ("Your Mining skill: 150").
- **Chat History**: the "Earlier chat" line between old and new chat is now an option, off by default.

### Fixed

- **Hide Beta Feedback**: the feedback box on quest windows no longer fades back in.
- **Forever++**: an error in one module no longer stops the others from loading, turning on, or turning off.

## 0.4.0 (2026-09-30)

### Added

- **Settings**: Defaults and Clutch's Default buttons on the welcome page, each asking first. Defaults resets every module's settings; Clutch's Default also turns on Fishing Cast, Skip Cinematics, Auto Screenshot, Currency Bar, Hide Beta Feedback, and Short Channel Names.
- **Edit Mode**: Combat Alert, Currency Bar, and Flight Timer work like Blizzard's own frames: click one to select it, then drag it (it snaps to the screen and other frames), nudge it with the arrow keys, or use its Scale slider and Reset To Default Position, also on right-click.
- **Chat** (new category): **Chat Copy** adds a button beside the chat window that opens the chat as plain text to copy. **Short Channel Names** shows [1] instead of [1. General] (off by default). **Chat History** shows each window's latest lines again after a logout or reload. **Social Button** moves the Quick Join button beside the chat's other buttons. **Chat Font** draws chat, and by default the chat input box, in Friz Quadrata or another Blizzard font (not on Korean, Chinese, or Russian clients).
- **Currency Bar** (new, off by default, in Interface): a small box showing your gold and, if you choose, the currencies you show on your Backpack. Hover it for what this session gained or spent. Move it in Edit Mode.
- **Auto Decline**: also turns down party invites, without the invite sound (off by default). Duels and party invites each have their own checkbox.
- **Fishing Cast** (new, off by default, in Automation): double right-click with a fishing pole equipped to cast Fishing.
- **AddOns List** (new, in Interface): the AddOns list without category headers, enabled addons first.
- **Spell Ranks** (new, in Interface): marks action bar spells that have a higher rank you already know, and adds the best rank to the tooltip. `/fpp ranks` lists them.
- **Recipe Colors** (new): colors recipes in the professions window by your chance of a skill-up, like the old trade skill window.
- **Quest Nameplates** (new): a quest icon and your progress beside the health bar of creatures you need for a quest.
- **Already Known** (new): a green check on recipes, mounts, pets, toys, and other items you already know, on merchants, the auction house, bags, mail, and loot.
- **Combat Alert** (new, off by default, in Interface): floats "Entering Combat" or "Leaving Combat" up from the middle of the screen.
- **Auto Sell Junk** (new, off by default): sells your gray items when a merchant opens. Hold Shift to skip it.
- **Flight Timer** (new): times each flight you take, then counts the next one down in a bar and shows the flight time on the flight map.
- **Profession Tooltips** (was Gathering Tooltips): also shows the Lockpicking skill a lockbox or locked chest needs, and lets blacksmiths see which skeleton key opens it.
- **Zone Info**: a Detail Key shows fishing, dungeons, herbs, ore, and skinning only while you hold it, and the panel can sit in a top corner of the map.
- **Player Nameplates**: an Icon Position option puts the role, friend, and recent ally icons before or after the name.
- **Tooltips**: a Faction Color option colors the Horde or Alliance line on a unit red or blue.

### Changed

- **Profession Tooltips**: recolors Blizzard's "Requires Mining (1)" line against your skill instead of adding a second one.
- **Zone Info** and **Points of Interest**: map tooltips look the same: white title, gold kind of place, Horde red and Alliance blue, and each dungeon or raid on one row with its icon.
- **Player Nameplates**: recent allies get an icon instead of a light blue name. Recent Allies is a dropdown: Off, Colored Name, or Icon.
- **Player Nameplates** and **NPC Nameplates**: Name Size is 80% by default.
- **Skip Cinematics**: Forget asks you to confirm first.

### Fixed

- **Points of Interest**: no second icon beside ours for Undercity or for dungeon and raid entrances. Learned flight points show as learned again, including with translated names; visit a flight master once to pick yours up.
- **Player Nameplates**: no more "action blocked" error at login.
- **Auction Prices**: posting works while a scan runs.
- **Player Nameplates** and **NPC Nameplates**: the guild or title no longer overlaps the cast bar.
- **Profession Tooltips**: the skill line sits under the name, above quest lines, also on minimap pins.

## 0.3.0 (2026-09-28)

### Added

- **Points of Interest**: dungeons, raids, capitals, flight masters, boats, zeppelins, and spirit healers on the world map, in a new Map category. Learned flight masters show in the minimap's white.
- **Zone Info**: a panel on the world map with the zone's level range, who holds it, its dungeons, fishing skill, and its herbs, ore, and skinning.
- **Unexplored Areas**: shows the parts of zone maps you haven't explored yet, with a tint.
- **Coordinates**: your coordinates and the cursor's in the world map's title bar.
- **Hide Filter Reset**: hides the reset button on the world map's filter dropdown.

### Changed

- **Class Colors**: hostile NPCs' health bars are red, neutral ones yellow, and tagged ones gray.
- **Bag Slot Counter**: adds up every bag on the backpack button by default.
- **Auto Stow**: the delay is a slider.
- **Auto Release**: the delay is a slider.
- **Gathering Tracking**: Swap is a slider.
- **Auction Prices**: Red After is a slider.
- **Player Nameplates**: a Name Size slider.
- **NPC Nameplates**: a Name Size slider.

### Fixed

- **Player Nameplates**: Chinese, Korean, and Cyrillic names show again.
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
