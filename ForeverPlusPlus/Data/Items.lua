-- Hand-kept lists of items a module acts on. Each module makes its list a ns.GameData set, so
-- Self Test checks the client still has the items and play can teach more; a fix to a list is
-- made here. A list the client's tables can give is generated instead (Lib/Generated/).
local _, ns = ...

ns.Data = ns.Data or {}

-- Auto Open Containers: containers left for the player to open, unless Open Special Containers
-- is on. What's inside is rolled on or traded in a raid, is a holiday gift, or is a quest's or a
-- recipe's one chance. From Open Sesame's default ignore list for Forever (Data/Camelot/
-- Default-Ignore-Items-Camelot.lua, MIT, hand-picked by its maintainer, read 2026-11-11).
ns.Data.autoOpenKept = {
    [17962] = true, -- Blue Sack of Gems (world bosses, Nefarian)
    [17963] = true, -- Green Sack of Gems
    [17964] = true, -- Gray Sack of Gems
    [17965] = true, -- Yellow Sack of Gems
    [17969] = true, -- Red Sack of Gems
    [13874] = true, -- Heavy Crate (Gahz'ranka)
    [11937] = true, -- Fat Sack of Coins (Fire Opal Necklace)
    [6352] = true, -- Waterlogged Crate (Hammer of the Vesper)
    [8049] = true, -- Gnarlpine Necklace (Tallonkai's Jewel)
    [9276] = true, -- Pirate's Footlocker (Ship Schedule, map fragments)
    [21150] = true, -- Iron Bound Trunk (Weather-Beaten Journal)
    [21228] = true, -- Mithril Bound Trunk (Weather-Beaten Journal)
    [20708] = true, -- Tightly Sealed Trunk (Weather-Beaten Journal)
    [21113] = true, -- Watertight Trunk (Weather-Beaten Journal)
    [20767] = true, -- Scum Covered Bag (Plans: Wicked Mithril Blade)
    [21979] = true, -- Gift of Adoration: Darnassus (Love is in the Air)
    [21980] = true, -- Gift of Adoration: Ironforge
    [22164] = true, -- Gift of Adoration: Orgrimmar
    [21981] = true, -- Gift of Adoration: Stormwind
    [22165] = true, -- Gift of Adoration: Thunder Bluff
    [22166] = true, -- Gift of Adoration: Undercity
    [22155] = true, -- Pledge of Adoration: Darnassus
    [22154] = true, -- Pledge of Adoration: Ironforge
    [22156] = true, -- Pledge of Adoration: Orgrimmar
    [21975] = true, -- Pledge of Adoration: Stormwind
    [22158] = true, -- Pledge of Adoration: Thunder Bluff
    [22157] = true, -- Pledge of Adoration: Undercity
}

-- Character Window's enchant marks: the items a permanent enchant can go on, by item type
-- (INVTYPE_*), and weapons by subclass ("weapon:" .. Enum.ItemWeaponSubclass), so a fishing pole,
-- a wand, or a thrown weapon isn't marked. Read from the spells with a SpellEffect of Effect 53
-- (enchant item, permanent) and their SpellEquippedItems rows, build 1.60.1.71139: Enchanting,
-- the Arcanums and Librams, the shoulder inscriptions, armor kits, spurs, shield spikes, weapon
-- chains, and Engineering's scopes. Forever adds Enchanting's necklace and off-hand enchants.
-- Rings, trinkets, shirts, and tabards take none. Belts take only Engineering's tinkers, so a
-- belt without one isn't marked; false keeps play from teaching otherwise.
ns.Data.enchantable = {
    INVTYPE_HEAD = true,
    INVTYPE_NECK = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CLOAK = true,
    INVTYPE_CHEST = true,
    INVTYPE_ROBE = true,
    INVTYPE_WRIST = true,
    INVTYPE_HAND = true,
    INVTYPE_WAIST = false,
    INVTYPE_LEGS = true,
    INVTYPE_FEET = true,
    INVTYPE_SHIELD = true,
    INVTYPE_HOLDABLE = true,
    ["weapon:0"] = true, -- one-handed axes
    ["weapon:1"] = true, -- two-handed axes
    ["weapon:2"] = true, -- bows (scopes)
    ["weapon:3"] = true, -- guns (scopes)
    ["weapon:4"] = true, -- one-handed maces
    ["weapon:5"] = true, -- two-handed maces
    ["weapon:6"] = true, -- polearms
    ["weapon:7"] = true, -- one-handed swords
    ["weapon:8"] = true, -- two-handed swords
    ["weapon:10"] = true, -- staves
    ["weapon:13"] = true, -- fist weapons
    ["weapon:14"] = true, -- miscellaneous
    ["weapon:15"] = true, -- daggers
    ["weapon:17"] = true, -- spears
    ["weapon:18"] = true, -- crossbows (scopes)
}
