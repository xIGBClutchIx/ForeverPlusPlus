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
                { L.FISHINGCAST_TITLE, "New Combat Warning option (on by default) shows one red "
                    .. "line where Blizzard's errors appear when combat starts while you have a "
                    .. "fishing pole equipped." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.ERRORCATCHER_TITLE, "The window is redesigned: a list of errors on the left "
                    .. "with their kind, count, and age, the one you pick on the right with when "
                    .. "it first and last happened, and the session filter showing how many "
                    .. "errors each choice has. A Copy Bug Report button selects a report with the "
                    .. "addon version, client build, modules on, other addons, and the error's "
                    .. "stack and locals, ready for Ctrl+C." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.AUCTIONPRICES_TITLE, "The age under an auction price is when that item was "
                    .. "last seen, not the last scan, so an item missing from a scan no longer "
                    .. "looks freshly checked. Saved prices are cleared once; the next visit to "
                    .. "the auction house scans again." },
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
                { L.CHARACTERFRAME_TITLE, "New, on by default, in Interface: moves the Character "
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
                { L.DURABILITYBARS_TITLE, "A bar beside each item on the character window with how "
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
