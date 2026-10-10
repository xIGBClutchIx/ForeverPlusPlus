-- The release notes the Changelog page in Settings shows, newest first. The game can't read
-- CHANGELOG.md at the repo root, so this is the same notes as data: change both together.
-- Headings and module names come from ns.L; the notes themselves are English, like CHANGELOG.md.
-- Each release: `version`, `date`, and `sections` of `{ heading, entries }`, where an entry is a
-- line of text or `{ name, text }` (a name shown in gold before its text). Changes not released
-- yet go first, with `version = L.CHANGELOG_UNRELEASED` and no date.
local _, ns = ...

local L = ns.L

ns.changelog = {
    {
        version = L.CHANGELOG_UNRELEASED,
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.TALENTPLANNER_TITLE, "New, on by default, in Interface: a Plan Talents "
                    .. "button on the talent window. Place talents freely without learning them, "
                    .. "in order, up to the points you have at a level you choose, then follow the "
                    .. "plan as you level: its next talent glows, tooltips say at which level "
                    .. "each rank comes, and hovering the line beside the button lists the plan "
                    .. "in order. A dropdown keeps several named plans, and shares or imports one "
                    .. "as a line of text." },
                { L.COMMANDS_TITLE, "New, on by default, in Interface: short slash commands, "
                    .. "each with its own checkbox. /way [zone] x y puts the game's map pin on a "
                    .. "spot and tracks it (/way clear takes it away), /rl reloads the UI, and "
                    .. "/clear empties a chat window. A command another addon already has, like TomTom's /way, is left to it." },
                { L.CHANGELOG_SETTINGS, "A search box at the top of the Modules page shows "
                    .. "only the modules whose name or description has what you type, under "
                    .. "their categories. Clear it to see every module again." },
                { L.CHANGELOG_SETTINGS, "The Modules page marks new modules, and new or changed "
                    .. "options of other modules, with Blizzard's NEW label until you've seen the "
                    .. "page. It opens on the first module with a marked option. Show New Tags on "
                    .. "the Debug page marks everything new since the last release, to check how "
                    .. "they look." },
                { L.AUTOQUEST_TITLE, "New, off by default, in Automation: accepts quests and "
                    .. "turns in finished ones as you talk to quest givers, one by one down a "
                    .. "quest giver's list. It never picks a reward when there's a choice. "
                    .. "Accepting and turning in have their own checkboxes, repeatable and shared "
                    .. "quests can be left out, and holding Shift (or Ctrl, Alt, or no key) lets "
                    .. "you do it yourself." },
                { L.AUTOWEAPONBUFF_TITLE, "New, off by default, in Automation: using a "
                    .. "sharpening stone, weightstone, oil, poison, or fishing lure puts it "
                    .. "straight onto your weapon, without clicking the weapon. Main hand first; "
                    .. "the off hand when only it can take it, or when the main hand already has "
                    .. "a buff and the off hand doesn't (or its buff runs out sooner)." },
                { L.MINIMAPBUTTON_TITLE, "New, on by default, in Interface: Forever++'s own "
                    .. "button on the minimap, in the addon compartment, or both. Click it to open "
                    .. "Forever++ settings; while Error Catcher is on, right-click it to see the "
                    .. "errors, and it shows how many this session caught." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.AUCTIONPRICES_TITLE, "Crafting Costs shows Estimated Profit, after the "
                    .. "auction house's 5% cut, and, at the top, how old the oldest auction "
                    .. "price in the totals is." },
                { L.CLASSCOLORS_TITLE, "New Friends and Who List option (on by default) shows "
                    .. "online friends' names in the friends list and names in the who list in "
                    .. "their class color." },
                { L.CHATCOPY_TITLE, "The window shows chat lines in their chat colors, with "
                    .. "names in their class colors and links in theirs, the way they look in "
                    .. "chat. Copying still gives plain text." },
                { L.ERRORCATCHER_TITLE, "New Button option puts its button on the minimap, in "
                    .. "the addon compartment, both, or neither. The minimap is still the "
                    .. "default." },
                { L.ERRORCATCHER_TITLE, "Its button is now the Minimap Button module, where a "
                    .. "click opens settings and a right-click shows the errors. Turn that module "
                    .. "off for no button. Its Clear Key option moved there too: Ctrl-right-click "
                    .. "still clears this session's errors." },
                { L.CHANGELOG_SETTINGS, "Clutch's Default is now Developer's Defaults, and the "
                    .. "welcome page's Defaults button is now Recommended Defaults, matching the "
                    .. "Defaults popup on the Modules and Debug pages." },
                { L.CHANGELOG_SETTINGS, "The Modules page lists every module on the left, each "
                    .. "with its checkbox, and shows the one you click on the right: its title, "
                    .. "what it does, an Enabled checkbox, and its options and buttons. No "
                    .. "more gears or options opening inside the list. Modules with many options "
                    .. "group them under headers, and options that only matter while another is "
                    .. "on sit under it: Player Nameplates, NPC Nameplates, Zone Info, Points of "
                    .. "Interest, Quest Tracker, Profession Tooltips, and Auction Prices." },
                { L.CHARACTERFRAME_TITLE, "Character Frame Enhancements is now Character "
                    .. "Window, so its name fits the Modules list, and Durability Bars is now its "
                    .. "Durability Bars option instead of a module of its own (always, only when "
                    .. "worn, below 50% or 25%, or off). It still starts on, showing bars always." },
                { L.AUTOSCREENSHOT_TITLE, "Now listed under Automation instead of Interface." },
                { L.CHANGELOG_SETTINGS, "Options changed since you last looked are marked "
                    .. "CHANGED on the Modules page, the way new ones are marked NEW." },
                { L.CHANGELOG_SETTINGS, "Clearer names and descriptions for a few options: Auto "
                    .. "Quest's Skip Key, Item Count's Bag and Bank Labels, Unexplored Areas' Tint "
                    .. "Strength, and Zone Info's Herbs, Ore, and Skinning." },
                { L.POI_TITLE, "New Ley Lines option shows Skyborne ley lines and elemental "
                    .. "convergences on the map. A spot is saved when a Skyborne gets the "
                    .. "15-minute buff from Read Ley Line or Skysight there, and every character "
                    .. "on the account sees it. Shown to Skyborne for their own kind by default, "
                    .. "or to everyone, or to no one." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.CHARACTERFRAME_TITLE, "Works with Forever's new Titles tab. Titles gets its "
                    .. "own side tab, the Pet tab opens your pet's stats again instead of Titles, "
                    .. "the titles list starts at the top and runs further down like the stats, "
                    .. "and the pet pane keeps your pet's level and loyalty. Your pet's tab also "
                    .. "comes and goes with your pet while another tab is open, and a tab you "
                    .. "can't use yet (no titles, no pet) says why when you point at it. The side "
                    .. "tabs sit as close together as Blizzard's, and get a little smaller when "
                    .. "needed, so the last one stays on the window." },
                { L.CVARBROWSER_TITLE, "An empty list says why (nothing matches the search, or "
                    .. "nothing is changed), and a row stays highlighted with its tooltip while "
                    .. "you point at its value box or Default button." },
                { L.ERRORCATCHER_TITLE, "The Test Error button on the Debug page works with "
                    .. "Error Catcher off too, to check Blizzard's error window." },
            } },
        },
    },
    {
        version = "0.7.0",
        date = "2026-10-02",
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.BESTREWARD_TITLE, "New, on by default, in Items: marks the quest reward that "
                    .. "sells to a vendor for the most with a gold coin, in the quest window and "
                    .. "the quest log." },
                { L.ITEMCOUNT_TITLE, "New, off by default, in Items: shows in an item's tooltip "
                    .. "how many you own, in your bags and in your bank." },
                { L.EASYDELETE_TITLE, "New, off by default, in Items: types DELETE for you when "
                    .. "you destroy a good item." },
                { L.FRAMERATE_TITLE, "New, off by default, in Interface: move and resize the "
                    .. "framerate text (Ctrl+R) in Edit Mode." },
                { L.AUCTIONPRICES_TITLE, "New Crafting Costs option shows a recipe's total cost, "
                    .. "value, and profit in the professions window. Reagent tooltips there now "
                    .. "price the amount the recipe needs, for Sell Price too." },
                { L.FISHINGCAST_TITLE, "New Combat Warning option warns you when combat starts "
                    .. "with a fishing pole equipped." },
                { L.POI_TITLE .. ", " .. L.ZONEINFO_TITLE, "Forever's new boats and skyships, "
                    .. "and the Excavation Site and City of Dalaran dungeons." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.POI_TITLE, "Forever's flight masters are named for their places, and its "
                    .. "dungeons show in your language." },
                { L.ERRORCATCHER_TITLE, "A redesigned window with a list of errors and a Copy Bug "
                    .. "Report button. Right-click the minimap button to open Forever++ settings." },
                { L.SPELLRANKS_TITLE, "\"Higher Rank Known:\" in spell tooltips now looks like "
                    .. "the other tooltip lines." },
            } },
            { L.CHANGELOG_FIXED, {
                { "Edit Mode", "The arrow keys nudge Combat Alert, Currency Bar, and Flight Timer "
                    .. "again." },
                { L.AUCTIONPRICES_TITLE, "A price's age is when the item was last seen, not the "
                    .. "last scan. Saved prices are cleared once." },
                { L.SELLPRICE_TITLE, "No more Lua error on a vendor's buyback tab." },
            } },
        },
    },
    {
        version = "0.6.0",
        date = "2026-10-01",
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.QUESTTRACKER_TITLE, "New, on by default, in Interface: restyles Blizzard's "
                    .. "quest tracker with a font, size, and outline, a dark box behind it that "
                    .. "fits your quests, and fading in combat. It's still Blizzard's tracker, so "
                    .. "Edit Mode and quest items work as before." },
                { L.ERRORCATCHER_TITLE, "New, on by default, in Interface: catches Lua errors "
                    .. "and blocked actions in place of Blizzard's error popup, saves them per "
                    .. "session, and shows them in a window you can copy from (/fpp errors or the "
                    .. "minimap button). Ctrl-right-click the minimap button to clear this "
                    .. "session's errors." },
                { "Character Frame Enhancements", "New, on by default, in Interface: moves the Character "
                    .. "window's Equipment and Pet tabs to the side with the others, removes the "
                    .. "portrait and level line so the stats start at the top, and shows your "
                    .. "level and name in your class color as the title." },
                { L.QUESTICONS_TITLE, "New, on by default, in Interface: marks quests that are "
                    .. "new to Forever with an infinity sign (or the Forever logo) after their "
                    .. "name in the quest log, the objective tracker, and quest givers' lists. "
                    .. "Idea from ForeverQuestTint." },
                { L.QUESTPLATES_TITLE, "New Party Progress option to count everyone's progress "
                    .. "added up (the default), only yours, or the party member furthest from "
                    .. "done. Creatures only a party member needs now show too." },
                { L.CLASSCOLORS_TITLE, "The Names checkbox is now a Name Color choice (Default, "
                    .. "White, or Class Color), and a new Name Backgrounds option (on by default) "
                    .. "tints the bar behind a player's name on the target and focus frames in "
                    .. "their class color." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.CHATFADING_TITLE, "Renamed from Chat Fading, and now on by default." },
                { L.AUTOREPAIR_TITLE, "Holding Shift to skip is now an option (on by default)." },
                { L.AUTOSELLJUNK_TITLE, "Holding Shift to skip is now an option (on by default)." },
                { L.CHANGELOG_SETTINGS, "The Defaults button on the Modules and Debug pages now "
                    .. "offers Clutch's Defaults or Recommended Defaults and resets only "
                    .. "Forever++. Blizzard's All Settings reset no longer touches Forever++." },
                { L.CHANGELOG_SETTINGS, "Clutch's Default also sets Zone Info's Dungeons and "
                    .. "Fishing to Hold Detail Key." },
                { L.CHANGELOG_SETTINGS, "Combat Alert, Currency Bar, and Flight Timer are sized "
                    .. "and reset only in Edit Mode now." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.FISHINGCAST_TITLE, "Double right-click now casts Fishing." },
                { L.TOOLTIPS_TITLE, "Levels and class names are colored again, player titles "
                    .. "show, and the Target line shows the target's name instead of its level." },
                { L.FLIGHTTIMER_TITLE, "No longer draws over other windows." },
            } },
        },
    },
    {
        version = "0.5.0",
        date = "2026-10-01",
        sections = {
            { L.CHANGELOG_ADDED, {
                { "Chat Fading", "New, off by default, in Chat: keeps chat text on screen "
                    .. "instead of fading it out after a while." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.HIDEFEEDBACK_TITLE, "Also hides the beta's feedback buttons on quest windows "
                    .. "(quest, gossip, and quest log), with its own checkbox." },
                { L.QUESTPLATES_TITLE, "The icon matches the objective: Blizzard's attack, pickup, "
                    .. "or interact icon for kill, item, or object objectives, and the quest icon "
                    .. "for the rest. A creature whose objective is done shows a green check "
                    .. "and its final count (8/8), unless you turn off Show Completed; the count can be "
                    .. "turned off to leave just the check." },
                { L.PLAYERPLATES_TITLE .. " and " .. L.NPCPLATES_TITLE, "On name-only plates the "
                    .. "buffs sit centered above the name instead of far off to the left. A Buffs "
                    .. "setting puts them above, before, or after the name, or back in Blizzard's "
                    .. "spot." },
                { L.PROFTOOLTIPS_TITLE, "The game's own bare \"Mining\" line under a vein is "
                    .. "replaced by \"Requires Mining (1)\" in the difficulty color instead of showing "
                    .. "both. When Blizzard already says \"Requires Mining (1)\", a bare name line "
                    .. "below it shows your skill (\"Your Mining skill: 150\")." },
                { L.CHATHISTORY_TITLE, "The \"Earlier chat\" line between old and new chat is "
                    .. "now an option, off by default." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.HIDEFEEDBACK_TITLE, "The feedback box on quest windows no longer fades "
                    .. "back in." },
                { "Forever++", "An error in one module no longer stops the others from loading, "
                    .. "turning on, or turning off." },
            } },
        },
    },
    {
        version = "0.4.0",
        date = "2026-09-30",
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.CHANGELOG_SETTINGS, "Defaults and Clutch's Default buttons on the welcome "
                    .. "page, each asking first. Defaults resets every module's settings; "
                    .. "Clutch's Default also turns on Fishing Cast, Skip Cinematics, Auto "
                    .. "Screenshot, Currency Bar, Hide Beta Feedback, and Short Channel Names." },
                { "Edit Mode", "Combat Alert, Currency Bar, and Flight Timer work like "
                    .. "Blizzard's own frames: click one to select it, then drag it (it snaps to "
                    .. "the screen and other frames), nudge it with the arrow keys, or use its "
                    .. "Scale slider and Reset To Default Position, also on right-click." },
                { L.CATEGORY_CHAT, "New category. Chat Copy adds a button beside the chat "
                    .. "window that opens the chat as plain text to copy. Short Channel Names "
                    .. "shows [1] instead of [1. General] (off by default). Chat History shows "
                    .. "each window's latest lines again after a logout or reload. Social Button "
                    .. "moves the Quick Join button beside the chat's other buttons. Chat Font "
                    .. "draws chat, and by default the chat input box, in Friz Quadrata or "
                    .. "another Blizzard font (not on Korean, Chinese, or Russian clients)." },
                { L.CURRENCYBAR_TITLE, "New, off by default, in Interface. A small box showing "
                    .. "your gold and, if you choose, the currencies you show on your Backpack. "
                    .. "Hover it for what this session gained or spent. Move it in Edit Mode." },
                { L.AUTODECLINE_TITLE, "Also turns down party invites, without the invite sound "
                    .. "(off by default). Duels and party invites each have their own checkbox." },
                { L.FISHINGCAST_TITLE, "New, off by default, in Automation. Double right-click "
                    .. "with a fishing pole equipped to cast Fishing." },
                { L.ADDONLIST_TITLE, "New, in Interface. The AddOns list without category "
                    .. "headers, enabled addons first." },
                { L.SPELLRANKS_TITLE, "New, in Interface. Marks action bar spells that have a "
                    .. "higher rank you already know, and adds the best rank to the tooltip. "
                    .. "/fpp ranks lists them." },
                { L.RECIPECOLORS_TITLE, "New. Colors recipes in the professions window by your "
                    .. "chance of a skill-up, like the old trade skill window." },
                { L.QUESTPLATES_TITLE, "New. A quest icon and your progress beside the health "
                    .. "bar of creatures you need for a quest." },
                { L.ALREADYKNOWN_TITLE, "New. A green check on recipes, mounts, pets, toys, and "
                    .. "other items you already know, on merchants, the auction house, bags, "
                    .. "mail, and loot." },
                { L.COMBATALERT_TITLE, "New, off by default, in Interface. Floats \"Entering "
                    .. "Combat\" or \"Leaving Combat\" up from the middle of the screen." },
                { L.AUTOSELLJUNK_TITLE, "New, off by default. Sells your gray items when a "
                    .. "merchant opens. Hold Shift to skip it." },
                { L.FLIGHTTIMER_TITLE, "New. Times each flight you take, then counts the next "
                    .. "one down in a bar and shows the flight time on the flight map." },
                { L.PROFTOOLTIPS_TITLE, "Was Gathering Tooltips. Also shows the Lockpicking "
                    .. "skill a lockbox or locked chest needs, and lets blacksmiths see which "
                    .. "skeleton key opens it." },
                { L.ZONEINFO_TITLE, "A Detail Key shows fishing, dungeons, herbs, ore, and "
                    .. "skinning only while you hold it, and the panel can sit in a top corner "
                    .. "of the map." },
                { L.PLAYERPLATES_TITLE, "An Icon Position option puts the role, friend, and "
                    .. "recent ally icons before or after the name." },
                { L.TOOLTIPS_TITLE, "A Faction Color option colors the Horde or Alliance line on "
                    .. "a unit red or blue." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.PROFTOOLTIPS_TITLE, "Recolors Blizzard's \"Requires Mining (1)\" line "
                    .. "against your skill instead of adding a second one." },
                { L.ZONEINFO_TITLE .. " and " .. L.POI_TITLE, "Map tooltips look the same: white "
                    .. "title, gold kind of place, Horde red and Alliance blue, and each dungeon "
                    .. "or raid on one row with its icon." },
                { L.PLAYERPLATES_TITLE, "Recent allies get an icon instead of a light blue name. "
                    .. "Recent Allies is a dropdown: Off, Colored Name, or Icon." },
                { L.PLAYERPLATES_TITLE .. " and " .. L.NPCPLATES_TITLE, "Name Size is 80% by "
                    .. "default." },
                { L.SKIPCINEMATICS_TITLE, "Forget asks you to confirm first." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.POI_TITLE, "No second icon beside ours for Undercity or for dungeon and "
                    .. "raid entrances. Learned flight points show as learned again, including "
                    .. "with translated names; visit a flight master once to pick yours up." },
                { L.PLAYERPLATES_TITLE, "No more \"action blocked\" error at login." },
                { L.AUCTIONPRICES_TITLE, "Posting works while a scan runs." },
                { L.PLAYERPLATES_TITLE .. " and " .. L.NPCPLATES_TITLE, "The guild or title no "
                    .. "longer overlaps the cast bar." },
                { L.PROFTOOLTIPS_TITLE, "The skill line sits under the name, above quest lines, "
                    .. "also on minimap pins." },
            } },
        },
    },
    {
        version = "0.3.0",
        date = "2026-09-28",
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.POI_TITLE, "Dungeons, raids, capitals, flight masters, boats, zeppelins, "
                    .. "and spirit healers on the world map, in a new Map category. Learned "
                    .. "flight masters show in the minimap's white." },
                { L.ZONEINFO_TITLE, "A panel on the world map with the zone's level range, who "
                    .. "holds it, its dungeons, fishing skill, and its herbs, ore, and skinning." },
                { L.UNEXPLORED_TITLE, "Shows the parts of zone maps you haven't explored yet, "
                    .. "with a tint." },
                { L.COORDS_TITLE, "Your coordinates and the cursor's in the world map's title "
                    .. "bar." },
                { L.HIDEFILTERRESET_TITLE, "Hides the reset button on the world map's filter "
                    .. "dropdown." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.CLASSCOLORS_TITLE, "Hostile NPCs' health bars are red, neutral ones yellow, "
                    .. "and tagged ones gray." },
                { L.BAGSLOTS_TITLE, "Adds up every bag on the backpack button by default." },
                { L.AUTOSTOW_TITLE, "The delay is a slider." },
                { L.AUTORELEASE_TITLE, "The delay is a slider." },
                { L.GATHERTRACKING_TITLE, "Swap is a slider." },
                { L.AUCTIONPRICES_TITLE, "Red After is a slider." },
                { L.PLAYERPLATES_TITLE, "A Name Size slider." },
                { L.NPCPLATES_TITLE, "A Name Size slider." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.PLAYERPLATES_TITLE, "Chinese, Korean, and Cyrillic names show again." },
                { L.NPCPLATES_TITLE, "Same fix for NPC names and titles." },
            } },
        },
    },
    {
        version = "0.2.0",
        date = "2026-09-27",
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.AUTODECLINE_TITLE, "Turns down duel requests and closes the popup. Includes "
                    .. "letting friends and guildmates through, and saying in chat who was "
                    .. "declined. Off by default." },
                { L.AUTODISMOUNT_TITLE, "Gets you off your mount or stands you up when a spell, "
                    .. "flight, loot, or attack fails because you're mounted or sitting. Includes "
                    .. "separate Dismount and Stand Up options, and leaving shapeshift forms (off "
                    .. "by default)." },
                { L.AUTORELEASE_TITLE, "Releases your spirit when you die in a battleground. "
                    .. "Includes a delay, and staying put when a soulstone, reincarnation, or "
                    .. "someone else can resurrect you. Off by default." },
                { L.AUTOSCREENSHOT_TITLE, "Takes a screenshot a moment after you level up, earn an "
                    .. "achievement, or defeat a boss, so Blizzard's toast is in it. Includes "
                    .. "checkboxes for loot of a chosen quality, reputation standings, PvP ranks, "
                    .. "new titles, battleground ends, and deaths, hiding the interface for the "
                    .. "shot, and a chat line saying why. Off by default." },
                { L.BAGSLOTS_TITLE, "How many bag slots are free, on the bag buttons. Includes "
                    .. "each bag's own count or the total on the backpack, the reagent bag on its "
                    .. "own button, added to the backpack, or hidden, counting special bags such "
                    .. "as quivers and herb bags, and the text's size and position." },
                { L.CLASSCOLORS_TITLE, "Players' health bars and names in their class color on "
                    .. "the player, target, focus, party, and target-of-target frames. Includes "
                    .. "health bars and names (off by default) separately, and a checkbox for each "
                    .. "frame." },
                { L.PROFTOOLTIPS_TITLE,"The skill a herb, ore, or skinnable beast needs, in "
                    .. "its tooltip in the world or on the minimap, colored red, orange, yellow, "
                    .. "green, or gray against your skill like trainer recipes. Herb, ore, and "
                    .. "stone items say the skill that gathers them. Includes showing it only for "
                    .. "professions you have or always, and a checkbox each for herbs, ore, "
                    .. "creatures, and items." },
                { L.SKIPCINEMATICS_TITLE, "Skips the game's cinematics and movies. Off by "
                    .. "default. Includes skipping only ones already seen on any character or "
                    .. "every one, holding Shift to watch, and a Forget button for the seen list." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.PLAYERPLATES_TITLE, "Recent allies' names in the game's light blue, instead "
                    .. "of the Name Color. Includes a checkbox to turn it off." },
                { L.CHANGELOG_SETTINGS, "Fewer entries in the sidebar. Forever++ opens on a "
                    .. "welcome page, and every module is on one Modules page, where the gear "
                    .. "beside a module shows its options under it. About is part of the welcome "
                    .. "page." },
            } },
        },
    },
    {
        version = "0.1.0",
        date = "2026-09-27",
        sections = {
            { L.CHANGELOG_ADDED, {
                { L.AUCTIONPRICES_TITLE, "Scans the auction house when you open it and shows the "
                    .. "lowest buyout in item tooltips. Includes how long ago the item was scanned "
                    .. "(colored by age), the same price options as Sell Price, /fpp scan, and a "
                    .. "Reset button and /fpp resetprices to forget saved prices." },
                { L.AUTOGOSSIP_TITLE, "Picks an NPC's only option when it has nothing else to say "
                    .. "and no quests. Includes a choice for bankers, vendors, trainers, flight "
                    .. "masters, stable masters, and other NPCs, and holding Shift to choose "
                    .. "yourself." },
                { L.AUTOREPAIR_TITLE, "Repairs your gear at merchants and says in chat what it "
                    .. "cost. Includes paying from the guild bank first, the guild bank only, or "
                    .. "your own money, a minimum cost, and holding Shift to skip it." },
                { L.AUTOSTOW_TITLE, "Puts your weapons away after combat. Includes the delay and "
                    .. "leaving them out in dungeons, raids, and battlegrounds." },
                { L.CVARBROWSER_TITLE, "A Settings page to browse, search, and change the game's "
                    .. "console variables (CVars). Includes a Changed Only filter and "
                    .. "/fpp cvar [search]." },
                { "Durability Bars", "A bar beside each item on the character window with how "
                    .. "worn it is. Includes showing bars always, only when worn, below 50%, or "
                    .. "below 25%." },
                { L.FASTLOOT_TITLE, "With auto loot on, takes everything at once. Includes a warning "
                    .. "in Settings, with a Turn On button, when Blizzard's auto loot is off." },
                { L.GATHERTRACKING_TITLE, "Keeps Find Minerals or Find Herbs on. Includes minerals, "
                    .. "herbs, or both, turning tracking back on after logging in, zoning, or dying, "
                    .. "and swapping between the two every few seconds." },
                { L.HIDEFEEDBACK_TITLE, "Hides the beta's \"Press F6 to submit an issue\" tooltip "
                    .. "line and the bug report button, each on its own. Off by default, and only on "
                    .. "beta and PTR clients." },
                { L.NPCPLATES_TITLE, "Friendly NPCs' names with their title, and a health bar only "
                    .. "when they're hurt or in combat. Includes name color, where the level goes, "
                    .. "and when and in what color titles show." },
                { L.PLAYERPLATES_TITLE, "Friendly players' names with their guild, and a health bar "
                    .. "only when they're hurt or in combat. Includes class-colored names, where the "
                    .. "level goes, guild line and color, highlighting guildmates, and role icons "
                    .. "for group members and Battle.net icons for friends." },
                { L.SELLPRICE_TITLE, "The vendor price in item tooltips. Includes the whole stack "
                    .. "or one item (Shift shows the other), lining up with other price lines, and "
                    .. "the quantity color." },
                { L.TOOLTIPS_TITLE, "Colors unit and item tooltips. Includes borders by class, "
                    .. "reaction, or item quality, name, guild, level, and class name colors, player "
                    .. "titles, a Target line, anchoring to the cursor, and hiding unit tooltips in "
                    .. "combat." },
                { L.CHANGELOG_SETTINGS, "Forever++ in Game Menu > Options > AddOns. Includes a "
                    .. "checkbox per module grouped by category, a page per module with options, "
                    .. "Debug, Changelog, and About. Every module turns on and off without a "
                    .. "reload." },
                { L.CHANGELOG_COMMANDS, "/fpp or /forever++ opens the settings. Includes list, "
                    .. "toggle, options, set, and reset." },
            } },
        },
    },
}
