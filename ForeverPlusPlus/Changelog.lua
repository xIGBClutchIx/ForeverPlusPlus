-- The release notes the Changelog page in Settings shows, newest first. The game can't read
-- CHANGELOG.md at the repo root, so this is the same notes as data: change both together.
-- Headings and module names come from ns.L; the notes themselves are English, like CHANGELOG.md.
-- Each release: `version`, `date`, an optional `summary`, and `sections` of `{ heading, entries }`,
-- where an entry is a line of text or `{ name, text }` (a name shown in gold before its text).
local _, ns = ...

local L = ns.L

ns.changelog = {
    {
        version = "0.1.0",
        date = "2026-09-27",
        summary = "The first release.",
        sections = {
            { L.CATEGORY_AUTOMATION, {
                { L.AUTOGOSSIP_TITLE, "When an NPC has only one thing to say and no quests, picks it "
                    .. "for you, so the bank, shop, trainer, flight map, or stable opens straight "
                    .. "away. Each kind can be turned off, and holding Shift lets you choose yourself." },
                { L.AUTOREPAIR_TITLE, "Repairs your gear at any merchant who repairs and says in chat "
                    .. "what it cost. Choose whether the guild bank or your own money pays, and a "
                    .. "minimum cost. Hold Shift to skip it." },
                { L.AUTOSTOW_TITLE, "Puts your weapons away a few seconds after combat ends, with a "
                    .. "choice of delay, and can leave them out in dungeons, raids, and battlegrounds." },
                { L.FASTLOOT_TITLE, "With auto loot on, takes everything at once instead of waiting "
                    .. "for the loot window. Warns in Settings when Blizzard's auto loot is off." },
                { L.GATHERTRACKING_TITLE, "Keeps Find Minerals or Find Herbs on after logging in, "
                    .. "zoning, or dying, and can swap between the two every few seconds." },
            } },
            { L.CATEGORY_ITEMS, {
                { L.AUCTIONPRICES_TITLE, "Scans the auction house when you open it and shows the "
                    .. "lowest buyout in item tooltips, with how old the scan is. /fpp scan scans now "
                    .. "and /fpp resetprices forgets the saved prices." },
                { L.DURABILITYBARS_TITLE, "A small bar beside each item on the character window with "
                    .. "how worn it is." },
                { L.SELLPRICE_TITLE, "The vendor price of the whole stack in item tooltips. Hold "
                    .. "Shift for one item. Price lines from Sell Price and Auction Prices line up "
                    .. "with each other." },
            } },
            { L.CATEGORY_INTERFACE, {
                { L.HIDEFEEDBACK_TITLE, "Hides the beta's \"Press F6 to submit an issue\" tooltip "
                    .. "line and the bug report button. Off by default, and only on beta and PTR "
                    .. "clients." },
                { L.TOOLTIPS_TITLE, "Colors unit and item tooltips by class, reaction, or quality, "
                    .. "and adds player titles and who a unit is targeting. Can show tooltips at the "
                    .. "mouse and hide unit tooltips in combat." },
            } },
            { L.CATEGORY_NAMEPLATES, {
                { L.NPCPLATES_TITLE, "Always shows friendly NPCs' names with their title. The health "
                    .. "bar appears only when they're hurt or in combat." },
                { L.PLAYERPLATES_TITLE, "Always shows friendly players' names with their guild, and "
                    .. "icons for group members and Battle.net friends. The health bar appears only "
                    .. "when they're hurt or in combat." },
                "Both warn in Settings when Blizzard's friendly nameplates are off, with a button to "
                    .. "turn them on.",
            } },
            { L.CHANGELOG_TOOLS, {
                { L.CVARBROWSER_TITLE, "A page in Settings to browse, search, and change the game's "
                    .. "console variables (CVars). /fpp cvar opens it." },
            } },
            { L.CHANGELOG_SETTINGS, {
                "Everything lives in Game Menu > Options > AddOns > Forever++: a checkbox per module "
                    .. "grouped by category, a page per module with options, Debug, Changelog, and "
                    .. "About.",
                "/fpp (or /forever++) opens the settings; /fpp list, toggle, options, set, and reset "
                    .. "do the same from chat.",
                "Every module turns on and off without a reload.",
            } },
        },
    },
}
