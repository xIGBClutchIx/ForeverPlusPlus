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
        version = L.CHANGELOG_UNRELEASED, -- no date until it ships
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
                { L.BAGSLOTS_TITLE, "How many bag slots are free, on the bag buttons. Includes the "
                    .. "total on the backpack or each bag's own count, the reagent bag on its own "
                    .. "button, in the total, or hidden, counting special bags such as quivers and "
                    .. "herb bags, and the text's size and position." },
                { L.CLASSCOLORS_TITLE, "Players' health bars and names in their class color on "
                    .. "the player, target, focus, party, and target-of-target frames. Includes "
                    .. "health bars and names (off by default) separately, and a checkbox for each "
                    .. "frame." },
                { L.GATHERTOOLTIPS_TITLE, "The skill a herb, ore, or skinnable beast needs, in "
                    .. "its tooltip in the world or on the minimap, colored red, orange, yellow, "
                    .. "green, or gray against your skill like trainer recipes. Herb, ore, and "
                    .. "stone items say the skill that gathers them. Includes a checkbox each for "
                    .. "herbs, ore, creatures, and items." },
                { L.SKIPCINEMATICS_TITLE, "Skips the game's cinematics and movies. Off by "
                    .. "default. Includes skipping only ones already seen on any character or "
                    .. "every one, holding Shift to watch, and a Forget button for the seen list." },
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
