# Upgrade Arrows stat weights

The default weights Upgrade Arrows judges gear by, for all 27 talent trees and the Feral Bear profile, and where each number comes from. The code is `ForeverPlusPlus/Modules/Items/UpgradeArrows/Weights.lua` (templates and per-tree nudges) and `ForeverPlusPlus/Lib/ItemStats.lua` (reading gear and the game's conversions). Reviewed 2026-10-22.

These are Forever++'s own numbers, worked out from Classic 1.x mechanics and Forever's own conversions. No other addon's weight table was used. Only the defaults change: weights a player set or imported are saved apart and stay as they are.

## What a weight means

- A weight is what one point of a stat is worth, or 1% of a chance stat (hit, crit, haste, expertise, dodge, parry, block). An item's score is its stats times the weights, added up.
- The scale, so numbers compare across stats:
  - Melee and Hunters: 1 attack power is 0.5, so 1 Strength is 1.0 for a class that gets 2 attack power from it.
  - Casters: 1 spell damage is 1.0. Healers: 1 healing is 1.0. Tanks: 1 Stamina is 1.0.
- Strength, Agility, Stamina, and Intellect aren't set by hand for your own class. They're worked out from what the game says one point gives your character (attack power, crit, dodge, armor, shield block value, health, spell crit, mana) times those stats' weights, and change as you level. The tables below show them at Classic level 60 rates.
- Weights are linear: they don't know about caps. Hit is worth less once you reach 8% (melee) or 17% (spells) against raid bosses, and Defense less past being uncrittable.

## What was wrong

1. **Hit and crit on gear counted about 10 times too much.** Forever's gear carries ratings (10 hit is 1%, 14 crit is 1%) though tooltips show percent, and the weights were per 1%. A ring with 0.4% hit scored as 4%, which made everything else on an item look worthless next to it. Gear's ratings are now turned into percent with the game's own conversion (Forever's level 60 table when the game doesn't answer).
2. **Agility and Intellect never used the game's conversions.** The crit-per-Agility and spell-crit-per-Intellect calls were made without the stat's amount and raised errors (Gear Probe, build 70425), and dodge was read as a percent when the game gives a fraction. So Agility and Intellect fell back to fixed guesses, and Intellect was worth 0 for Retribution and Protection Paladins. They're now called the way Forever's character sheet calls them.
3. **Casters and healers ignored hit and crit gear.** Forever has one Hit and one Critical Strike stat for melee and spells; casters only weighted spell hit and spell crit, which gear never carries. The one stat now counts for both sides.
4. **Healers counted Spell Power at 0.3.** On Forever "Increases damage and healing done by magical spells" reads as Spell Power. It now counts as healing too.
5. **Weapon DPS was worth too little.** 14 attack power is 1 DPS, so a main hand's DPS is worth 7 (Strength 1.0 scale) before talents that hit with the weapon. It was 3 to 5, and off hands 1.5 to 2.5.
6. **Feral Druids counted weapon DPS**, which does nothing in Cat or Bear Form, and Cat Form's 1 attack power per Agility was missing out of form.
7. **Strength's shield block value** wasn't counted for tanks (1 per 20 Strength).

## Mechanics used

| Mechanic | Value | Source |
| --- | --- | --- |
| Attack power per Strength | 2 for Warriors, Paladins, Shamans, Druids; 1 for others | foreverdb.net/stats; Forever's character sheet (live, `GetAttackPowerForStat`) |
| Attack power per Agility | 1 for Rogues, Hunters, and Druids in Cat Form; 2 ranged for Warriors, Hunters, Rogues | foreverdb.net/stats; Icy Veins Classic Hunter |
| Weapon DPS | 14 attack power is 1 DPS | foreverdb.net/stats; Classic rule |
| Crit per Agility at 60 | 1% per 20 (most classes), 29 (Rogue), 53 (Hunter) | rankedboost Forever Agility page; vanilla-wow wiki Critical strike; Icy Veins Classic pages |
| Health, mana | 10 per Stamina, 15 per Intellect | foreverdb.net/stats; Icy Veins Classic Paladin pages |
| Block value | 1 per 20 Strength (Warriors, Paladins, Shamans) | foreverdb.net/stats; `BLOCK_VALUE_PER_STRENGTH` in the character sheet |
| Defense | each point 0.04% dodge, parry, block, miss, and less crit taken; 440 to be uncrittable | foreverdb.net/stats; Icy Veins Classic Protection Paladin |
| Gear ratings per 1% at 60 | hit 10, crit 14, haste 10, expertise 10, dodge 12, parry 15, block 5 | wowsims/forever PR #571; foreverdb.net/stats; NaowhForever PR #137 (in game) |
| Hit to never miss a boss | 8% melee and ranged, 17% spells, 27% dual wield white hits | foreverdb.net/stats |
| Hit and crit | one stat each for melee, ranged, and spells | outputlag.com (Blizzard's Forever panel); NaowhForever PR #137 |

## How the root numbers were worked out

- **Melee hit and crit (10 per 1%).** 1% more crit or hit is about 1% more damage. With level 50 to 60 gear (about 800 attack power and a 50 DPS weapon) a swing's damage is about 50 + 800/14 = 107 DPS, so 1% is about 1.07 DPS, or 15 attack power; Flurry, Deep Wounds, and rage from crits make it about 20 attack power, so 10 on the Strength scale. Arms and Retribution crit 11 (Deep Wounds, Impale, Vengeance), Fury and Combat hit 11 (dual wielding misses 27% of white swings, so hit past 8% still counts). It's worth less while leveling and more in raid gear.
- **Hunter hit and crit (12, Marksmanship crit 13).** Icy Veins' Classic Hunter page puts 1% of either at about 32 ranged attack power at 60 (16 on this scale) with raid gear; 12 sits between that and leveling gear. Mortal Shots makes crits count more for Marksmanship.
- **Weapon DPS.** 1 DPS is 14 attack power, so 7. Two-handers for Arms (Mortal Strike), Retribution (Seal of Command), and Enhancement (Windfury) 8, since specials add the weapon's damage. Off hands do half damage, so 3.5, and 4.5 with Dual Wield Specialization (Fury, Combat). Hunters' ranged weapon 7.5 (8 for Marksmanship), since Aimed Shot and Multi-Shot add its damage. Feral 0.
- **Haste and expertise (melee 7 and 8, casters 6, healers 3).** Not in Classic; Forever's sheet has them. 1% haste is a little under 1% more swings, and 1% expertise takes 1% off the target's dodge, close to 1% hit. A judgment, kept a bit under hit and crit.
- **Casters.** Spell hit 10 and crit 7 per 1% against 1 spell damage, with the crit trees higher (Fire and Destruction 9, Elemental 9, Frost and Balance 8). Unchanged from before; what changed is that gear's Hit and Crit now reach them.
- **Healers.** 1 healing is 1; Spell Power heals too, and its damage part is 0.1 (0.2 for Priests, who Smite while leveling). Mana per 5 is 1.5 (Resto Shaman 1.7, Holy Paladin 2, since Spirit does little for Paladins). Holy Paladin crit 8 per 1%: Illumination gives a crit's mana back, about 6 mana a cast per 1% on Holy Light.
- **Tanks.** 1 Stamina is 1, so 1 health is 0.1. Defense 1.5 a point (0.16% avoidance and 0.04% less crit taken), dodge 8 and parry 7 per 1%, block 3 (3.5 for Protection Paladins, with Redoubt and Holy Shield), block value 0.3, armor 0.04 (about 100 armor is 1% less damage taken at 60, worth about 4 Stamina). Threat: hit 6 and crit 3 per 1%, weapon DPS 2. Protection Paladins add spell damage 0.5 (Holy Shield, Consecration, Seal of Righteousness, and Retribution Aura threat), spell hit 2, mana 0.03 a point, and mana per 5 1. Bears weight armor 0.1, since Dire Bear Form multiplies item armor.
- **Damage dealers' Stamina and armor.** Stamina 0.3 (health 0.03) for melee and casters, and armor 0.01 for melee (100 armor is worth 1 Strength), so plate and mail count for a little while leveling.
- **Paladin mana.** Retribution weights mana 0.015 a point (Intellect about 0.24), mana per 5 0.5, and spell damage 0.25 (Seal of Command, Judgement, Consecration); Enhancement Shamans mana 0.01 and spell damage 0.15 (shocks).

## Warrior and Paladin, before and after

"Before" is what the profiles used in play: Agility and Intellect fell back to fixed guesses (0.6 Agility, 0 Intellect for Paladin melee and tanks), and hit and crit gear counted per point of rating, so 1% of hit was really worth 10 times the weight shown (100 for Arms) and 1% of crit 14 times. That, more than any weight, is why other stats looked worth nothing beside them.

| Tree | Hit per 1% | Crit per 1% | Weapon DPS | Agility | Intellect | Other |
| --- | --- | --- | --- | --- | --- | --- |
| Arms | 10 (was 10) | 11 (was 9) | 8 (was 5) | 0.57 (was 0.6 guess) | 0 | haste 7, expertise 8, armor 0.01 |
| Fury | 11 (was 11) | 10 (was 8) | 7, off hand 4.5 (was 4, 2.5) | 0.52 (was 0.6) | 0 | haste 7, expertise 8, armor 0.01 |
| Protection Warrior | 6 (was 4) | 3 (was 2) | 2 (was 1) | 0.63 (was 0.7) | 0 | Strength 0.52 with block value; Stamina 1 is the scale (was 1.2) |
| Holy Paladin | | spell crit 8 (was 4, and missed gear crit) | | | 0.75 (was 0.7 guess) | Spell Power counts as healing (was 0.3); mana per 5 2 (was 1.5); Spirit 0.15 (was 0.5) |
| Protection Paladin | 6, spell hit 2 | 3 | 1 | 0.63 | 0.45 (was 0) | spell damage 0.5 (was 0.3), mana per 5 1, block 3.5 |
| Retribution | 10 + spell 1 | 11 + spell 1 | 8 (was 5) | 0.57 | 0.24 (was 0) | spell damage 0.25 (was 0.2), mana per 5 0.5 |

## Every tree

The weights each tree starts with, with Strength, Agility, Stamina, and Intellect at Classic level 60 rates for that tree's own class (the game's own rates replace them in play). An empty cell is 0.

### Melee and ranged

| Tree | STR | AGI | STA | AP | RAP | HIT | CRIT | HASTE | EXPERTISE | ARMOR | DPS | DPS_OFF | DPS_RANGED | INT | SP | SPELLHIT | SPELLCRIT | MP5 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior Arms | 1 | 0.57 | 0.3 | 0.5 |  | 10 | 11 | 7 | 8 | 0.01 | 8 |  |  |  |  |  |  |  |
| Warrior Fury | 1 | 0.52 | 0.3 | 0.5 |  | 11 | 10 | 7 | 8 | 0.01 | 7 | 4.5 |  |  |  |  |  |  |
| Paladin Retribution | 1 | 0.57 | 0.3 | 0.5 |  | 10 | 11 | 7 | 8 | 0.01 | 8 |  |  | 0.24 | 0.25 | 1 | 1 | 0.5 |
| Hunter Beast Mastery | 0.1 | 1.35 | 0.3 | 0.1 | 0.5 | 12 | 12 | 7 |  | 0.01 | 0.2 |  | 7.5 | 0.38 |  |  |  | 0.3 |
| Hunter Marksmanship | 0.1 | 1.47 | 0.3 | 0.1 | 0.55 | 12 | 13 | 7 |  | 0.01 | 0.2 |  | 8 | 0.3 |  |  |  | 0.3 |
| Hunter Survival | 0.1 | 1.35 | 0.3 | 0.1 | 0.5 | 12 | 12 | 7 |  | 0.01 | 0.2 |  | 7.5 | 0.3 |  |  |  | 0.3 |
| Rogue Assassination | 0.5 | 0.9 | 0.3 | 0.5 |  | 10 | 11 | 7 | 8 | 0.01 | 7 | 3.5 |  |  |  |  |  |  |
| Rogue Combat | 0.5 | 0.86 | 0.3 | 0.5 |  | 11 | 10 | 7 | 8 | 0.01 | 7 | 4.5 |  |  |  |  |  |  |
| Rogue Subtlety | 0.5 | 0.86 | 0.3 | 0.5 |  | 10 | 10 | 7 | 8 | 0.01 | 7.5 | 3.5 |  |  |  |  |  |  |
| Shaman Enhancement | 1 | 0.57 | 0.3 | 0.5 |  | 10 | 11 | 7 | 8 | 0.01 | 8 | 0.5 |  | 0.15 | 0.15 |  |  |  |
| Druid Feral (cat) | 1 | 1.07 | 0.3 | 0.5 |  | 10 | 11 | 7 | 8 | 0.01 |  |  |  |  |  |  |  |  |

### Casters and healers

| Tree | SP | HEAL | SPELLHIT | SPELLCRIT | HASTE | INT | SPI | MP5 | STA | DPS_RANGED |
|---|---|---|---|---|---|---|---|---|---|---|
| Paladin Holy | 0.1 | 1 |  | 8 | 3 | 0.75 | 0.15 | 2 | 0.2 | 0.5 |
| Priest Discipline | 0.2 | 1 |  | 3 | 3 | 0.65 | 0.9 | 1.5 | 0.2 | 0.5 |
| Priest Holy | 0.2 | 1 |  | 4 | 3 | 0.67 | 0.9 | 1.5 | 0.2 | 0.5 |
| Priest Shadow | 1 |  | 11 | 7 | 6 | 0.42 | 0.4 | 0.6 | 0.3 | 1.2 |
| Shaman Elemental | 1 |  | 10 | 9 | 6 | 0.45 | 0.15 | 0.6 | 0.3 | 1.2 |
| Shaman Restoration | 0.1 | 1 |  | 4 | 3 | 0.67 | 0.5 | 1.7 | 0.2 | 0.5 |
| Mage Arcane | 1 |  | 10 | 6 | 6 | 0.55 | 0.15 | 0.6 | 0.3 | 1.2 |
| Mage Fire | 1 |  | 10 | 9 | 6 | 0.45 | 0.15 | 0.6 | 0.3 | 1.2 |
| Mage Frost | 1 |  | 10 | 8 | 6 | 0.43 | 0.3 | 0.6 | 0.3 | 1.2 |
| Warlock Affliction | 1 |  | 10 | 7 | 6 | 0.42 | 0.25 | 0.2 | 0.3 | 1.2 |
| Warlock Demonology | 1 |  | 10 | 7 | 6 | 0.42 | 0.15 | 0.2 | 0.4 | 1.2 |
| Warlock Destruction | 1 |  | 10 | 9 | 6 | 0.45 | 0.15 | 0.2 | 0.3 | 1.2 |
| Druid Balance | 1 |  | 10 | 8 | 6 | 0.43 | 0.3 | 0.6 | 0.3 | 1.2 |
| Druid Restoration | 0.1 | 1 |  | 3 | 3 | 0.65 | 0.9 | 1.5 | 0.2 | 0.5 |

### Tanks

| Tree | STA | DEF | DODGE | PARRY | BLOCK | BLOCKVALUE | ARMOR | STR | AGI | AP | HIT | CRIT | EXPERTISE | SP | SPELLHIT | INT | MP5 | DPS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior Protection | 1 | 1.5 | 8 | 7 | 3 | 0.3 | 0.04 | 0.52 | 0.63 | 0.25 | 6 | 3 | 4 |  |  |  |  | 2 |
| Paladin Protection | 1 | 1.5 | 8 | 7 | 3.5 | 0.35 | 0.04 | 0.52 | 0.63 | 0.25 | 6 | 3 | 4 | 0.5 | 2 | 0.45 | 1 | 1 |
| Druid Feral Bear | 1 | 1 | 8 |  |  |  | 0.1 | 0.4 | 0.75 | 0.2 | 5 | 3 |  |  |  |  |  |  |

## Still to check in game

- That `C_Item.GetItemStats` gives gear's hit as a rating: on an item whose tooltip says "+0.5% hit", `/dump C_Item.GetItemStats(link)` should show `ITEM_MOD_HIT_RATING_SHORT = 5`. If it shows 0.5, the rating conversion in `Lib/ItemStats.lua` (`RATINGS`) must go.
- What Gear Probe's new "rating rates" lines say: whether the client answers the conversion itself (`client`) or the level 60 table is used (`seed`), and whether ratings convert differently below 60.
- That a gear Hit line raises spell hit too (`GetSpellHitModifier` or `GetCombatRatingBonus(CR_HIT_SPELL)` before and after equipping).
- How a Forever healing item ("healing by up to 42 and damage by up to 14") splits into keys.
- Pawn-format strings name hit and crit "HitRating" and "CritRating"; ours write and read them per 1%, as before. A string from a sim that weighs per rating point needs its hit and crit multiplied by 10 and 14.

## Sources

- Forever's character sheet: [Gethe/wow-ui-source `forever`, Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua) (read 2026-10-22).
- Gear Probe log, build 70425, level 20 Mage (2026-10-16): stat keys, strings, and the conversion calls' errors.
- [foreverdb.net/stats](https://foreverdb.net/stats): Forever's ratings, attack power per stat by class, block value, Defense, hit to cap.
- [wowsims/forever PR #571](https://github.com/wowsims/forever/pull/571): the level 60 rating table.
- [NaowhForever PR #137](https://github.com/nwh-gaming-ab/NaowhForever/pull/137): gear hit is a rating, checked in game (Pyrewood Signet Ring, 4 hit is 0.4%); one hit and crit for melee and spells. Facts only; its weights weren't used.
- [rankedboost: Agility in WoW Forever](https://rankedboost.com/world-of-warcraft/forever/stats/agility/) and [Critical Strike in WoW Forever](https://rankedboost.com/world-of-warcraft/forever/stats/crit/): Agility per 1% crit by class.
- [outputlag.com: Forever unifies hit and crit](https://outputlag.com/news/world-of-warcraft-forever-unifies-hit-and-crit-stats-and-gives-healing-gear-bonus-damage/) and [method.gg: hit chance in WoW Forever](https://www.method.gg/wow-forever/how-does-hit-chance-work-in-wow-forever).
- Icy Veins Classic stat priorities: [Retribution](https://www.icy-veins.com/wow-classic/retribution-paladin-dps-pve-stat-priority), [Protection Paladin](https://icy-veins.com/wow-classic/protection-paladin-tank-pve-stat-priority), [Holy Paladin](https://icy-veins.com/wow-classic/holy-paladin-healer-pve-stat-priority), [Hunter](https://icy-veins.com/wow-classic/hunter-dps-pve-stat-priority) (1% hit or crit about 32 attack power at 60).
- [vanilla-wow wiki: Critical strike](https://vanilla-wow.fandom.com/wiki/Critical_strike): Classic Agility per crit by class.
