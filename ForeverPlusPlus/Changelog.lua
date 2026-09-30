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
                { L.CURRENCYBAR_TITLE, "New, off by default, in Interface. A small "
                    .. "tooltip-styled box showing your gold and the currencies you tick Show "
                    .. "on Backpack in the Currency tab. Gold always shows all three coins, even 0 gold. Checkboxes for the gold and the "
                    .. "currencies, one to stack them in a column, and a size slider. Move it in Edit Mode." },
                { L.CATEGORY_CHAT, "New category, four modules, only Short Channel Names off by default. "
                    .. "Chat Copy adds a button beside the chat window that opens the chat as "
                    .. "plain text, already selected, to copy with Ctrl+C, with a slider for how "
                    .. "many lines. Short Channel Names shows channels as [1], [G], or [1. G] instead of "
                    .. "[1. General]. Chat History keeps each chat window's latest lines when "
                    .. "you log out or reload and shows them again at login, with a slider for "
                    .. "how many. Social Button moves the social (Quick Join) button down "
                    .. "beside the chat window's other buttons." },
                { L.AUTODECLINE_TITLE, "New option, off by default, for party invites. "
                    .. "Turns them down without the invite sound. Friends and guildmates can "
                    .. "still be let through, and chat says who was declined. Duels and party "
                    .. "invites now each have their own checkbox, so you can decline only one." },
                { L.FISHINGCAST_TITLE, "New, off by default, in Automation. "
                    .. "Double right-click in the world with a fishing pole equipped to cast "
                    .. "Fishing. It uses a temporary right-click binding that comes off on the "
                    .. "next click, so looting the bobber works as usual, and it never arms in "
                    .. "combat. A slider sets how fast the second click must follow the first." },
                { L.ADDONLIST_TITLE, "New, in Interface. The AddOns list "
                    .. "without category headers, with enabled addons first and the disabled "
                    .. "ones after, each in name order. Options to move disabled addons out of "
                    .. "their group and to search addon notes. Turning it off gives Blizzard's "
                    .. "list back at once." },
                { L.SPELLRANKS_TITLE, "New, in Interface. Marks the spells on "
                    .. "your action bars that have a higher rank you already know, with a "
                    .. "warning badge or a red tint over the button, and adds the best rank you "
                    .. "know to the spell's tooltip. /fpp ranks lists them, and chat says how "
                    .. "many there are after you level up or learn spells." },
                { L.RECIPECOLORS_TITLE, "New. Colors recipes in the professions "
                    .. "window by your chance of a skill-up, orange, yellow, green, or gray, like "
                    .. "the old trade skill window. Options tint the row highlights to match and "
                    .. "gray out recipes you know that can't raise your skill any more." },
                { L.QUESTPLATES_TITLE, "New. A quest icon and your progress "
                    .. "(3/8, or how many are left) beside the health bar of creatures you need "
                    .. "for a quest, from the objective lines of their tooltip. Options for the "
                    .. "progress shown, which side of the bar, and size." },
                { L.ALREADYKNOWN_TITLE, "New. Marks recipes, mounts, pets, toys, "
                    .. "and other items you already know or have with Blizzard's green check on "
                    .. "the icon, or a green tint. It shows on merchants, the auction house's "
                    .. "browse list, bags, mail, and the loot window, each with its own "
                    .. "checkbox." },
                { L.COMBATALERT_TITLE, "New, off by default, in Interface. Floats a red "
                    .. "\"Entering Combat\" or green \"Leaving Combat\" line up and away from "
                    .. "the middle of the screen when combat starts or ends, in Blizzard's "
                    .. "large title font. Each has a checkbox, with a size slider and a "
                    .. "duration slider. Move it in Edit Mode." },
                { L.AUTOSELLJUNK_TITLE, "New, off by default. Sells the gray items in your bags "
                    .. "when a merchant opens and says in chat what they sold for. Hold Shift to "
                    .. "skip it. A checkbox stops at 12 items per visit so everything can be "
                    .. "bought back." },
                { L.FLIGHTTIMER_TITLE, "New. Times every flight you take, "
                    .. "remembered by the game's flight point IDs, then shows a bar counting "
                    .. "the flight down that you can move in Edit Mode, and the flight time on "
                    .. "a flight point's tooltip on the flight map. Each route is timed on its own, "
                    .. "since flights differ each way. A Reset button forgets the times." },
                { L.PROFTOOLTIPS_TITLE, "Was Gathering Tooltips. Also shows the Lockpicking "
                    .. "skill a lockbox or locked chest needs, colored against your skill, for "
                    .. "characters who can pick locks. A Locks checkbox turns it off. A Skeleton Keys checkbox (on by default) "
                    .. "shows it to blacksmiths too, against the best skeleton key they can "
                    .. "make, and puts the skill each skeleton key opens in its tooltip." },
                { L.ZONEINFO_TITLE, "A Detail Key (Shift, Alt, or Ctrl), and fishing, "
                    .. "dungeons, herbs, ore, and skinning can each show only while you hold "
                    .. "it. Long herb and ore lists split into rows of at most four, and the "
                    .. "instances sit apart under a little more space." },
                { L.ZONEINFO_TITLE, "The panel can also sit in a top corner of the map. In a "
                    .. "right corner it is mirrored: the icons go on the right and the text "
                    .. "lines up on the right." },
                { L.PLAYERPLATES_TITLE, "An Icon Position option puts the group role, "
                    .. "friend, and recent ally icons before or after the name (after by "
                    .. "default)." },
                { L.TOOLTIPS_TITLE, "A Faction Color option colors the Horde or Alliance line "
                    .. "on a unit red or blue, as on the map." },
            } },
            { L.CHANGELOG_CHANGED, {
                { L.PROFTOOLTIPS_TITLE, "When Blizzard already shows \"Requires Mining (1)\" on a "
                    .. "vein, herb, or creature, that line is recolored against your skill instead "
                    .. "of a second line being added. Ours is added only when Blizzard's is "
                    .. "missing." },
                { L.ZONEINFO_TITLE .. " and " .. L.POI_TITLE, "Map tooltips now look the same. "
                    .. "The title is white, then what kind of place it is in gold, then "
                    .. "details in white, with the faction in Horde red or Alliance blue on "
                    .. "cities, flight masters, boats, and zeppelins, and level ranges colored "
                    .. "against yours. Each dungeon and raid is one row with Blizzard's icon, in "
                    .. "the zone panel and in an entrance with several (such as Blackrock "
                    .. "Mountain), so a long list no longer wraps through a name or a level "
                    .. "range." },
                { L.PLAYERPLATES_TITLE, "Recent allies get the Recent Allies icon beside "
                    .. "their name by default, so their class color stays. Recent Allies is now "
                    .. "a dropdown: Off, Colored Name (the old light blue name), or Icon." },
                { L.SKIPCINEMATICS_TITLE, "Forget asks you to confirm first, like the Auction "
                    .. "Prices reset." },
            } },
            { L.CHANGELOG_FIXED, {
                { L.POI_TITLE, "No more second icon beside ours for Undercity, or for a "
                    .. "dungeon or raid entrance Blizzard also marks." },
                { L.PLAYERPLATES_TITLE, "No more \"action blocked\" error at login. Recent "
                    .. "allies are marked once the game has loaded the list, such as after "
                    .. "you open the Recent Allies tab." },
                { L.AUCTIONPRICES_TITLE, "Posting works while a scan runs. The scan waits "
                    .. "its turn with the server, gives way to the auction house's own "
                    .. "searches, pauses while an item is in the sell box, and stops if you "
                    .. "search." },
                { L.PLAYERPLATES_TITLE, "The guild moves under the cast bar the moment it "
                    .. "appears, and back only once it has faded, instead of lagging or "
                    .. "overlapping it." },
                { L.NPCPLATES_TITLE, "The title moves under the cast bar the moment it "
                    .. "appears, and back only once it has faded, instead of lagging or "
                    .. "overlapping it." },
                { L.POI_TITLE, "A flight point the game calls undiscovered now says it isn't "
                    .. "learned yet." },
                { L.POI_TITLE, "Flight points you have learned now show as learned. They are "
                    .. "remembered by the game's own flight point ID instead of by name, so "
                    .. "translated names and the two Light's Hope Chapel points no longer get "
                    .. "missed. Visit a flight master once to have yours picked up again." },
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
