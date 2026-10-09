-- English text for the automation modules. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- FastLoot
L.FASTLOOT_TITLE = "Fast Loot"
L.FASTLOOT_DESC = "With auto loot on, take everything at once instead of waiting for the loot "
    .. "window."
L.FASTLOOT_BLIZZARD_OFF = "Blizzard's auto loot is off" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "Blizzard's auto loot is off, so only loot you take while holding "
    .. "the auto loot key (Shift) is fast. Turn it on here or in Blizzard's Controls options."

-- AutoRepair
L.AUTOREPAIR_TITLE = "Auto Repair"
L.AUTOREPAIR_DESC = "Repair all your gear when you talk to a merchant who repairs, and say in chat "
    .. "what it cost. Hold Shift to skip it."
L.AUTOREPAIR_FUNDS = "Pay With"
L.AUTOREPAIR_FUNDS_DESC = "Whose money pays for repairs."
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "Guild Bank, Then Your Own"
L.AUTOREPAIR_FUNDS_GUILD = "Guild Bank Only"
L.AUTOREPAIR_FUNDS_OWN = "Your Own Money Only"
L.AUTOREPAIR_MIN_COST = "Minimum Cost"
L.AUTOREPAIR_MIN_COST_DESC = "Only repair when it costs at least this much, so a quick stop at a "
    .. "merchant doesn't spend a few copper each time."
L.AUTOREPAIR_MIN_COST_ANY = "Any Cost"
L.AUTOREPAIR_SHIFT = "Hold Shift to Skip"
L.AUTOREPAIR_SHIFT_DESC = "Holding Shift as you talk to the merchant leaves your gear unrepaired."
L.AUTOREPAIR_CHAT_DESC = "Say in chat what repairs cost, or why they couldn't be paid for."
L.AUTOREPAIR_REPAIRED = "Repaired for %s." -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "Repaired for %s from the guild bank." -- cost
L.AUTOREPAIR_NO_MONEY = "Not enough money to repair (%s)." -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "The guild bank can't pay for repairs (%s)." -- cost

-- AutoSellJunk
L.AUTOSELLJUNK_TITLE = "Auto Sell Junk"
L.AUTOSELLJUNK_DESC = "Sell the gray items in your bags when you talk to a merchant, and say in "
    .. "chat what they sold for. Hold Shift to skip it."
L.AUTOSELLJUNK_BUYBACK = "Keep Everything Buyable Back"
L.AUTOSELLJUNK_BUYBACK_DESC = "Sell at most 12 items per visit, the number the merchant's buyback "
    .. "list holds, so you can still buy back anything sold by mistake."
L.AUTOSELLJUNK_SHIFT = "Hold Shift to Skip"
L.AUTOSELLJUNK_SHIFT_DESC = "Holding Shift as you talk to the merchant leaves your junk unsold."
L.AUTOSELLJUNK_CHAT_DESC = "Say in chat how many items were sold and what they sold for."
L.AUTOSELLJUNK_SOLD = "Sold %d junk items for %s." -- count, money

-- GatherTracking
L.GATHERTRACKING_TITLE = "Gathering Tracking"
L.GATHERTRACKING_DESC = "Keep Find Minerals or Find Herbs on: turn it back on after logging in, "
    .. "zoning, or dying, and swap between the two if you like."
L.GATHERTRACKING_TRACK = "Track"
L.GATHERTRACKING_TRACK_DESC = "Which tracking to keep on. Only one tracks at a time, so with "
    .. "both, swapping shows each in turn."
L.GATHERTRACKING_TRACK_BOTH = "Minerals and Herbs"
L.GATHERTRACKING_TRACK_MINERALS = "Minerals Only"
L.GATHERTRACKING_TRACK_HERBS = "Herbs Only"
L.GATHERTRACKING_REAPPLY = "Turn Back On"
L.GATHERTRACKING_REAPPLY_DESC = "After logging in, zoning, or coming back to life, turn tracking "
    .. "back on if nothing is being tracked. Turning it off yourself lasts until then."
L.GATHERTRACKING_SWAP = "Swap"
L.GATHERTRACKING_SWAP_DESC = "With both chosen, swap between Find Minerals and Find Herbs while "
    .. "one of them is on. Waits during combat, casting, and flights."
L.GATHERTRACKING_SWAP_OFF = "Never"
L.GATHERTRACKING_SWAP_EVERY = "Every %d Seconds" -- seconds
L.GATHERTRACKING_CHAT_DESC = "Say in chat when the game stops Gathering Tracking from changing "
    .. "tracking."
L.GATHERTRACKING_FAILED = "Gathering Tracking couldn't change tracking: %s" -- error
L.GATHERTRACKING_BLOCKED = "The game blocked Gathering Tracking from changing tracking. It stops "
    .. "until /reload."

-- AutoStow
L.AUTOSTOW_TITLE = "Auto Stow"
L.AUTOSTOW_DESC = "Put your weapons away a few seconds after combat ends, unless you draw or "
    .. "stow them yourself first."
L.AUTOSTOW_DELAY = "Delay"
L.AUTOSTOW_DELAY_DESC = "How long after combat to wait before putting your weapons away."
L.AUTOSTOW_OUTSIDE_ONLY = "Only Out of Instances"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "Leave your weapons out in dungeons, raids and battlegrounds, where "
    .. "the next pull is never far off."

-- AutoDismount
L.AUTODISMOUNT_TITLE = "Auto Dismount"
L.AUTODISMOUNT_DESC = "Get off your mount or stand up when something fails because you're "
    .. "mounted or sitting, like casting a spell, taking a flight, or looting."
L.AUTODISMOUNT_DISMOUNT = "Dismount"
L.AUTODISMOUNT_DISMOUNT_DESC = "Get off your mount when you cast a spell, talk to a flight master, "
    .. "or attack while mounted."
L.AUTODISMOUNT_STAND = "Stand Up"
L.AUTODISMOUNT_STAND_DESC = "Stand up when you cast a spell, loot, or attack while sitting."
L.AUTODISMOUNT_UNSHIFT = "Leave Shapeshift Form"
L.AUTODISMOUNT_UNSHIFT_DESC = "Leave a shapeshift form, like a druid's Bear or Cat Form, when you "
    .. "cast a spell that can't be cast in it."

-- AutoGossip
L.AUTOGOSSIP_TITLE = "Auto Gossip"
L.AUTOGOSSIP_DESC = "When an NPC has only one thing to say and no quests, pick it for you, so "
    .. "the bank, shop, or flight map opens straight away."
L.AUTOGOSSIP_SECTION_GENERAL = "General"
L.AUTOGOSSIP_SECTION_NPCS = "Pick For"
L.AUTOGOSSIP_BANKER = "Bankers"
L.AUTOGOSSIP_BANKER_DESC = "Open the bank."
L.AUTOGOSSIP_VENDOR = "Vendors and Repairs"
L.AUTOGOSSIP_VENDOR_DESC = "Open the shop."
L.AUTOGOSSIP_TRAINER = "Trainers"
L.AUTOGOSSIP_TRAINER_DESC = "Open the trainer's list."
L.AUTOGOSSIP_TAXI = "Flight Masters"
L.AUTOGOSSIP_TAXI_DESC = "Open the flight map."
L.AUTOGOSSIP_STABLE = "Stable Masters"
L.AUTOGOSSIP_STABLE_DESC = "Open the stable."
L.AUTOGOSSIP_OTHER = "Other NPCs"
L.AUTOGOSSIP_OTHER_DESC = "Pick the only option of any other NPC, unless the game asks you to "
    .. "read its text first."
L.AUTOGOSSIP_SHIFT = "Hold Shift to Skip"
L.AUTOGOSSIP_SHIFT_DESC = "Holding Shift while you talk to an NPC leaves its options for you to "
    .. "pick."
L.AUTOGOSSIP_PRINT = "Print Gossip Options"
L.AUTOGOSSIP_PRINT_DESC = "Print every gossip option in chat with its icon and status, to check "
    .. "which kind of NPC it counts as."
L.AUTOGOSSIP_PRINT_HEADER = "Gossip options (title: %s):" -- NPC's title under the name
L.AUTOGOSSIP_PRINT_LINE = "  %s  icon=%s status=%s flags=%s  %s" -- id, icon, status, flags, name
L.AUTOGOSSIP_PRINT_RESULT = "  -> %s" -- the kind picked, or why not (debug codes)
-- The title under a stable master's name, exactly as the game shows it.
L.AUTOGOSSIP_TITLE_STABLE = "Stable Master"

-- AutoQuest
L.AUTOQUEST_TITLE = "Auto Quest"
L.AUTOQUEST_DESC = "Accept quests and turn in finished ones as you talk to quest givers. It never "
    .. "picks a reward for you when there's a choice."
L.AUTOQUEST_ACCEPT = "Accept Quests"
L.AUTOQUEST_ACCEPT_DESC = "Accept new quests, and take them one by one from a quest giver's list."
L.AUTOQUEST_REPEATABLE = "Repeatable Quests"
L.AUTOQUEST_REPEATABLE_DESC = "Also take repeatable and daily quests from a quest giver's list."
L.AUTOQUEST_SHARED = "Shared Quests"
L.AUTOQUEST_SHARED_DESC = "Also accept quests other players share with you."
L.AUTOQUEST_TURN_IN = "Turn In Quests"
L.AUTOQUEST_TURN_IN_DESC = "Turn in finished quests. With more than one reward to choose from, "
    .. "the choice stays yours."
L.AUTOQUEST_KEY = "Pause Key"
L.AUTOQUEST_KEY_DESC = "Hold this key as you talk to a quest giver to accept and turn in "
    .. "yourself."
L.AUTOQUEST_KEY_SHIFT = "Shift"
L.AUTOQUEST_KEY_CTRL = "Ctrl"
L.AUTOQUEST_KEY_ALT = "Alt"
L.AUTOQUEST_KEY_NONE = "None"

-- AutoDecline
L.AUTODECLINE_TITLE = "Auto Decline"
L.AUTODECLINE_DESC = "Turn down duel requests, and optionally party invites, as they arrive, so "
    .. "the popup never gets in your way."
L.AUTODECLINE_DUELS = "Duels"
L.AUTODECLINE_DUELS_DESC = "Turn down duel requests."
L.AUTODECLINE_PARTY_INVITES = "Party Invites"
L.AUTODECLINE_PARTY_INVITES_DESC = "Also turn down party invites, without the invite sound."
L.AUTODECLINE_ALLOW_FRIENDS = "Allow Friends and Guild"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "Let duels and party invites from your friends, Battle.net "
    .. "friends, and guildmates through."
L.AUTODECLINE_CHAT_DESC = "Say in chat whose duel or party invite was turned down."
L.AUTODECLINE_DECLINED = "Declined a duel from %s." -- player name
L.AUTODECLINE_DECLINED_INVITE = "Declined a party invite from %s." -- player name
L.AUTODECLINE_SOMEONE = "someone"

-- AutoRelease
L.AUTORELEASE_TITLE = "Auto Release"
L.AUTORELEASE_DESC = "Release your spirit when you die in a battleground, unless you can "
    .. "resurrect yourself or someone is resurrecting you."
L.AUTORELEASE_DELAY = "Delay"
L.AUTORELEASE_DELAY_DESC = "How long after dying to wait before releasing."
L.AUTORELEASE_NOW = "Right Away"
L.AUTORELEASE_CHAT_DESC = "Say in chat when your spirit was released, or why it wasn't."
L.AUTORELEASE_RELEASED = "Released your spirit."
L.AUTORELEASE_SELF_RES = "Didn't release: you can resurrect yourself."
L.AUTORELEASE_RES_OFFER = "Didn't release: someone is resurrecting you."

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "Skip Cinematics"
L.SKIPCINEMATICS_DESC = "Skip the game's cinematics and movies, every one or only ones you've "
    .. "already seen."
L.SKIPCINEMATICS_SKIP = "Skip"
L.SKIPCINEMATICS_SKIP_DESC = "Which cinematics and movies to skip. Seen ones count across all your "
    .. "characters."
L.SKIPCINEMATICS_SKIP_SEEN = "Only Seen"
L.SKIPCINEMATICS_SKIP_ALL = "All"
L.SKIPCINEMATICS_SHIFT = "Hold Shift to Watch"
L.SKIPCINEMATICS_SHIFT_DESC = "Holding Shift as a cinematic or movie starts lets it play."
L.SKIPCINEMATICS_CHAT_DESC = "Say in chat when a cinematic or movie is skipped."
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "Skipped a cinematic."
L.SKIPCINEMATICS_SKIPPED_MOVIE = "Skipped a movie."
L.SKIPCINEMATICS_RESET = "Seen Cinematics"
L.SKIPCINEMATICS_RESET_BUTTON = "Forget"
L.SKIPCINEMATICS_RESET_DESC = "Forget which cinematics and movies you've seen, so each plays once "
    .. "more."
L.SKIPCINEMATICS_RESET_CONFIRM = "Forget which cinematics and movies you've seen?"
L.SKIPCINEMATICS_RESET_DONE ="Seen cinematics forgotten."
L.SKIPCINEMATICS_PRINT = "Print Cinematic Keys"
L.SKIPCINEMATICS_PRINT_DESC = "Print each cinematic's or movie's key in chat as it starts, with "
    .. "whether it was seen and skipped."
L.SKIPCINEMATICS_PRINT_LINE = "Cinematic %s: seen=%s skip=%s" -- key (movie ID or map:subzone), seen, skip


-- FishingCast
L.FISHINGCAST_TITLE = "Fishing Cast"
L.FISHINGCAST_DESC = "Double right-click in the world with a fishing pole equipped to cast Fishing."
L.FISHINGCAST_SPEED = "Double-Click Speed"
L.FISHINGCAST_SPEED_DESC = "How quickly the second right-click must follow the first."
L.FISHINGCAST_MS = "%d ms" -- milliseconds
L.FISHINGCAST_COMBAT = "Combat Warning"
L.FISHINGCAST_COMBAT_DESC = "Warn once when combat starts while a fishing pole is equipped."
L.FISHINGCAST_COMBAT_TEXT = "You have a fishing pole equipped."


-- AutoWeaponBuff
L.AUTOWEAPONBUFF_TITLE = "Auto Weapon Buff"
L.AUTOWEAPONBUFF_DESC = "Put a sharpening stone, weightstone, oil, poison, or fishing lure straight "
    .. "onto your weapon when you use it, without clicking the weapon. Main hand first, or the off "
    .. "hand when only it can take it or the main hand already has a buff."
L.AUTOWEAPONBUFF_PRINT = "Print Weapon Checks"
L.AUTOWEAPONBUFF_PRINT_DESC = "Print in chat, each time an item waits for a target, which weapons "
    .. "the game says it can go on and which one was picked."
-- debug codes: enchanting spell, item condition, main hand fits, off hand fits, slot picked
L.AUTOWEAPONBUFF_PRINT_LINE = "Weapon buff: enchanting=%s condition=%s main=%s off=%s -> slot %s"
