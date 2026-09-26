# WoW: Forever client API notes

What we know about the addon API on the WoW: Forever client, where each fact came from, and how sure we are. `AGENTS.md` has the short version; this file has the detail and the sources.

Last reviewed 2026-09-25, against build **1.60.1.70009** (the build in `D:\BattleNet\World of Warcraft\.build.info`, product `wow_classic_beta`). Forever is a beta: recheck anything marked below before relying on it after a patch.

## How to read the tags

Every fact carries one tag saying how it was established:

| Tag | Meaning |
| --- | --- |
| **[local]** | Read from this machine's client install or its saved files. |
| **[in-game]** | Tested in the live client by Cameron (the `/cui` checks recorded in ClutchUI's `docs/flavors.md`). |
| **[dump]** | Present in a captured API dump of the Forever client (see [Sources](#sources)). Shows the API exists, not that it behaves like Retail. |
| **[addon]** | Inferred from how an installed Forever addon uses it. The addon works for players, but we have not tested that exact call. |
| **[web]** | Reported by someone else online. Not checked by us. |
| **Unverified** | Plausible but unconfirmed, or sources disagree. Check before depending on it. |

When you confirm or rule out something here, change its tag, add the date, and say how you checked.

## Client identity

- Build 1.60.1.70009, interface **16001**, product `wow_classic_beta`, exe `WowB.exe`, folder `_classic_beta_`. **[local]** (`.build.info`, `WTF\Config.wtf` has `engineSurveyPatch "16001"`)
- Internal codename is **Camelot**. It shows up in TOC suffixes, TOC game types, and addon code. **[local]** (installed addons) **[web]** (wiki)
- `GetBuildInfo()` returns `"1.60.1", <build>, <date>, 16001`. **[in-game]** (`/cui` printed `interface=16001`) **[dump]** (`client.interface = 16001`)
- `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` (1), same as Retail. It can't tell Forever from Retail. **[in-game]** (`/cui` printed `project=1`) **[dump]**
- Launch is set for 2026-11-04. **[web]**

### Detecting Forever at runtime

Use the interface number with both ends of a range: `local iface = select(4, GetBuildInfo()); local isForever = iface >= 16000 and iface < 17000`.

- Never test "starts with 1" or "five digits": Classic Era is 11509 and would match. Manners' `Flavour.lua` explains this trap in detail. **[addon]**
- Many Retail addons test `>= 100000` to mean "modern client". On Forever that fails, so ported Retail code takes Classic paths. **[web]** (forever-addon-kit)
- Other addons use `[16000, 17000)` (ClutchUI, WhisperMessenger, Manners) or `[16000, 20000)` (Auctionator, D4Lib, ManiaTip, AceDB in UnifiedProfileManager). **[addon]**
- Prefer probing the API you need over any version check.

## TOC and loading

- Ship one plain `ForeverPlusPlus.toc` with `## Interface: 16001`. That works. **[local]** (this addon loads and saves)
- **TOC suffixes: `_Camelot` wins on build 70009.** A test addon with `FppTocProbe.toc`, `FppTocProbe_Camelot.toc`, and `FppTocProbe_Mainline.toc`, all at 16001, loaded **`_Camelot`**. **[in-game]** (2026-09-25)
  - That matches warcraft.wiki.gg: expansion suffixes (`_Camelot`, `_Standard`, ...) beat family suffixes (`_Mainline`, `_Classic`), which beat the plain name. **[web]**
  - An earlier test on 2026-09-23 (`_Mainline` at 120100, `_Camelot` and plain at 16001) loaded **`_Mainline`**. **[in-game]** (ClutchUI `docs/flavors.md`) Either the build changed or the setup differed. Recheck after patches.
  - Installed addons that ship a `_Camelot.toc`: AutoStow, AzerothCompendium, Chatify, Manners, MapUtils, TwitchEmotes, WhisperMessenger. **[local]**
- **Per-file load conditions** in the TOC file list: `file.lua [AllowLoadGameType camelot]` and `[ExcludeLoadGameType ...]`.
  - The wiki lists game type `camelot` = Forever, `standard` = Midnight only, `mainline` = Midnight **and** Forever (plus Plunderstorm and other modes), `classic` = the Classic expansions. **[web]**
  - BugSack (`forever.lua [ExcludeLoadGameType standard, classic][AllowLoadGameType camelot]`), Auctionator (`Source_Forever\Constants.lua`), and AlreadyKnown (`[AllowLoadGameType classic, camelot]`) rely on this. **[addon]**
  - Auctionator also loads `[AllowLoadGameType mainline]` files on Forever and branches on `IsForever` inside them, which fits `mainline` including Forever. **[addon]**
  - Tested on Forever: `[AllowLoadGameType camelot]` and `[AllowLoadGameType mainline]` load, `[AllowLoadGameType standard]` and `[AllowLoadGameType classic]` don't, and `[ExcludeLoadGameType standard]` loads. **[in-game]** (2026-09-25, FppTocProbe)
  - So `camelot` (or excluding `standard`) splits Forever-only files from Retail at load time. `mainline` can't, since it matches both. That Retail skips `camelot` files comes from the wiki **[web]**; we didn't run the probe on Retail.
- `## Category`, `## IconTexture`, localized `## Title-xxXX` / `## Notes-xxXX` fields are used by installed Forever addons. **[addon]**

## SavedVariables

- **They persist now.** ClutchUI's `loadCount` in `WTF\Account\70453270#1\SavedVariables\ClutchUI.lua` reached 7 (it only increments when the saved table is read back), and `ForeverPlusPlus.lua` holds this addon's module state. **[local]** (checked 2026-09-25)
- History: on 2026-09-23 they were written but never read back, so every session started from defaults. **[in-game]** (ClutchUI `loads=` stayed at 1) **[web]** (forever-addon-kit, EU forum thread)
- The fix landed by 2026-09-24. If settings stop sticking after a patch, check this first.
- Beta-era workarounds seen elsewhere, in case it regresses: `CreateMacro` survives a cold start; CVars registered with `C_CVar.RegisterCVar` survive `/reload` but not a restart. **[web]** (forever-addon-kit)

## Realms, names, and game rules

- Forever is realmless in the usual sense. Characters live under ruleset "realms" named like `Classic Beta PvE` and `Classic Beta PvP` in `WTF\Account\<acct>\`. **[local]**
- `UnitName` returns a **surname** as its second value, not a realm: `UnitName("player")` gave `"Clutch", "Bloodfury"`. **[in-game]** (2026-09-25) `C_PlayerInfo.ShouldDisplaySurname()` exists. **[dump]** **[addon]** (Chatify's mention code)
  - Names can appear as `First Surname` or `First-Surname`; never parse the part after `-` as a realm. **[addon]** (Chatify `Config.lua`)
  - ManiaTip hides realm text on Forever. **[addon]**
- AceDB (in UnifiedProfileManager and Manners) keys profiles by ruleset on Forever, using `C_GameRules.IsGameRuleActive(Enum.GameRule.HardcoreRuleset / RPRuleset / PvPRuleset)`. **[addon]**
- Beta game rules reported active: `DisableCampsites`, `TransmogEnabled = 0`, `EncounterJournalDisabled`. **[web]** (forever-addon-kit)
- `MicroMenu:GenerateButtonInfos()` lists the micro buttons, and some carry a `gameRule` that hides them. D4Lib uses that on Forever instead of a hard-coded list. **[addon]**

## Removed Classic globals, and their replacements

Absent from the dump **[dump]**, and ForeverPlusPlus should use the right-hand column:

| Gone | Use |
| --- | --- |
| `GetItemInfo`, `GetItemInfoInstant` | `C_Item.GetItemInfo`, `C_Item.GetItemInfoInstant` |
| `GetSpellInfo` | `C_Spell.GetSpellInfo` (returns a table) |
| `UnitAura` | `C_UnitAuras.*` |
| `GetContainerItemInfo` | `C_Container.GetContainerItemInfo` |
| `IsAddOnLoaded`, `GetAddOnMetadata` | `C_AddOns.IsAddOnLoaded`, `C_AddOns.GetAddOnMetadata` |
| `SetDesaturation` | `texture:SetDesaturated(bool)` |
| `GetMouseFocus` | `GetMouseFoci()` |
| `EasyMenu` | `MenuUtil` / `Menu` |
| `GetQuestLogTitle`, `GetNumQuestLogEntries` | `C_QuestLog.*` |
| `GetSpecialization`, `GetSpecializationInfo` (globals) | `C_SpecializationInfo.GetSpecialization`, `C_SpecializationInfo.GetSpecializationInfo` |
| `GetTalentInfo`, `GetTalentTabInfo`, `GetNumTalentTabs`, `GetActiveTalentGroup` | `C_SpecializationInfo` / `C_Traits` (see Talents) |
| `CombatLogGetCurrentEventInfo` | Nothing. See Combat data. |
| `GetMerchantItemInfo` | Absent **[web]**; check `C_MerchantFrame` before use. |

Still present **[dump]**: `ReloadUI`, `hooksecurefunc`, `InCombatLockdown`, `GetRealmName`, `UnitFullName`, `GetNumSpecializations`, `GetCVar` / `SetCVar`, `ChatFrame_AddMessageEventFilter`, `UIDropDownMenu_Initialize`, `PlaySound`, `UnitHealthPercent`, `UnitHealthMissing`.

- `ReloadUI()` works: `/run pcall(ReloadUI)` reloaded the UI. **[in-game]** (2026-09-25, build 70009) forever-addon-kit reported it protected on an earlier build **[web]**. A call from an addon's own button (tainted code) hasn't been tested; if one is blocked, tell players to type `/reload`.
- Registering an event the client doesn't have (for example `LEARNED_SPELL_IN_TAB`) throws and aborts the file. Only register events that exist, or `pcall` it. **[web]**

## Namespaces that exist

From the dumps **[dump]**: `C_AddOns`, `C_Item`, `C_Spell`, `C_Container`, `C_UnitAuras`, `C_TooltipInfo`, `C_QuestLog`, `C_Map`, `C_ChatInfo`, `C_EditMode`, `C_Traits`, `C_ClassTalents`, `C_SpecializationInfo`, `C_GameRules`, `C_PlayerInfo`, `C_Secrets`, `C_RestrictedActions`, `C_CurveUtil`, `C_EncodingUtil`, `C_DamageMeter`, `C_SwingTimer`, `C_CooldownViewer`, `C_AuctionHouse`, `C_TradeSkillUI`, `C_SeasonInfo`, `C_AddOnProfiler`.

- Retail-only systems also exist in the API (`C_MythicPlus`, `C_ChallengeMode`, `C_Garrison`, `C_DelvesUI`, `C_Housing`, `C_Transmog`, `C_CraftingOrders`, `C_EncounterJournal`, `C_LFGList`). Existing is not the same as usable: the content may be off. Don't build on them without checking in game.
- There is no `C_Seasons`, `C_Engraving` (Season of Discovery), `C_ClassicPlus`, or `C_Camelot`. **[dump]**
- The UI helpers `Settings`, `Menu`, `MenuUtil`, `TooltipDataProcessor`, `ChatFrameUtil`, and `BackdropTemplateMixin` are tables, so the dumps (functions and named frames) don't list them. `Settings.RegisterAddOnCategory`, `Menu.ModifyMenu`, and `TooltipDataProcessor.AddTooltipPostCall` are all functions. **[in-game]** (2026-09-25, `/dump`) The others are used by installed Forever addons **[addon]**; probe before use.
- Settings pages: `Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, name, default, get, set)` with `Settings.CreateCheckbox`, and `CreateSettingsListSectionHeaderInitializer` are used this way by BugSack `config.lua` and ArcaneWizardLibrary. **[addon]** `Settings.NotifyUpdate` (to refresh a checkbox changed from `/fpp`) is **Unverified**; Forever++ probes for it.
- Named frames present **[dump]**: `AddonCompartmentFrame`, `EditModeManagerFrame`, `MicroMenu`, `ObjectiveTrackerFrame`, `ContainerFrameCombinedBags`, `CooldownViewerSettings`, `DamageMeter`, `PlayerFrame`, `TargetFrame`, `BuffFrame`, `MinimapCluster`, `CharacterFrame`, `WorldMapFrame`, `MerchantFrame`, `GossipFrame`, `QuestFrame`, `LootFrame`.
- Not in the named-frame dump, likely load-on-demand or missing: `ProfessionsFrame`, `AuctionHouseFrame`, `PlayerSpellsFrame`, `ClassTalentFrame`, `SpellBookFrame`. **Unverified.** Hook them on `ADDON_LOADED`, and check they exist.

## Talents and specs

- Classic-style talent trees with points per tree, on Retail's trait system (`C_Traits`). A separate "Legacy" tree panel opens with `ToggleLegacySystemUI` and unlocks at level 25. **[web]** (forever-addon-kit)
- `C_SpecializationInfo.GetSpecializationInfo(index, ...)` returns `specId, name, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked`. **[dump]** (Atraeau api.json)
  - On Cameron's Warrior, `GetSpecializationInfo(1)` returned `1491, "Warrior", "", 626008, "DAMAGER", 4, 0, nil, 0, true`, and `C_SpecializationInfo.GetSpecialization()` returned `1`. **[in-game]** (2026-09-25)
  - So the "spec" is the whole class: the name is the class name, the description is empty, and `pointsSpent` was 0 with 6 points spent in Arms. It doesn't count talent points, so it can't find a talent tree.
  - D4Lib picks the tree with the most `pointsSpent` as the player's "spec" **[addon]**. Given the result above, that finds nothing, and it passes a table where the dump documents positional arguments.
- Spec IDs are new (Warrior 1491 **[in-game]**; Paladin 1486 **[web]**), so Retail spec-ID tables are wrong here.
- Talent points live in `C_Traits`, in a config of a Forever-only type. **[in-game]** (2026-09-25, Warrior with 6 points in Arms)
  - `Enum.TraitConfigType` has `Invalid 0, Combat 1, Profession 2, Generic 3, CamelotCombat 4`.
  - `C_ClassTalents.GetActiveConfigID()` returned a `CamelotCombat` config named `"Warrior"` with a single tree, `treeIDs = { 1117 }`. There is no Retail-style `Combat` config.
  - `C_Traits.GetTreeCurrencyInfo(configID, 1117, false)` returned one currency (3820) with `spent = 6, quantity = 0, maxQuantity = 6`. That's the total across all three talent tabs, not per tab.
  - The tabs are trait **groups**. `C_Traits.GetGroupDisplayInfoByTreeID(1117)` returned three entries with `groupID`, `displayName`, `icon`, `orderIndex`, and `skillLineID`: Arms 11650, Fury 11657, Protection 11670.
  - Purchased nodes (`C_Traits.GetNodeInfo(configID, nodeID)`) have `subTreeID = nil`, and `posX` / `posY` in tree coordinates. Two Arms nodes had `groupIDs[1] = 11650`; a third had `groupIDs[1] = 11649`, a group that isn't a tab.
  - A node's tab is whichever of its `groupIDs` matches a display group, not the first one. That third node's `groupIDs` were `{ 11649, 12820, 12821, 12822, 12823, 12824, 11650 }`: the tab (11650) came last. What 11649 and 12820-12824 gate (tiers?) is unknown.
  - **Points per tab:** `C_Traits.GetGroupCurrencyInfo(configID, { 11650, 11657, 11670 })` returned `{ traitNodeGroupID = 11650, currencyInfos = { { traitCurrencyID = 3820, spent = 6, quantity = 0, maxQuantity = 6 } } }`. Fury and Protection, with nothing spent, were left out of the result entirely, so treat a missing group as 0.

## Secret values and combat data

Forever inherits Midnight's addon restrictions. `AGENTS.md` has the rules for writing code; this is the evidence.

- `issecretvalue`, `canaccessvalue`, `issecrettable`, `scrub`, `secretwrap` exist, as does `C_Secrets` with 27 predicates (`HasSecretRestrictions`, `ShouldAurasBeSecret`, `ShouldUnitHealthMaxBeSecret`, `GetSpellAuraSecrecy`, ...). **[in-game]** (`/cui` printed `secrets=true, curves=true`) **[dump]**
- In a solo open-world fight, `UnitHealth`, `UnitHealthPercent`, and `UnitHealthMissing` were secret for player and target, and the target's `UnitHealthMax` was secret. The player's `UnitHealthMax` and all `UNIT_COMBAT` amounts stayed readable. **[web]** (forever-addon-kit)
- In combat, while `C_Secrets.ShouldAurasBeSecret()` is true, reading a secret aura throws, including your own buffs. Secrecy is per spell: `C_Secrets.GetSpellAuraSecrecy(id)`. **[web]**
- `Cooldown:SetCooldown` rejects secret numbers from addon code. Get a duration object from `C_Spell.GetSpellCooldownDuration` and pass it to `Cooldown:SetCooldownFromDurationObject`. **[web]**
- Range checks stay readable in open-world combat (`C_Spell.IsSpellInRange`, `CheckInteractDistance`, some `C_Item.IsItemInRange` distances). **[web]**
- `COMBAT_LOG_EVENT_UNFILTERED` never fires for addons. **[addon]** (Manners `Core.lua`) **[web]** Use `C_DamageMeter` (Blizzard's built-in meter) or events like `UNIT_COMBAT`.
- Swing timer events `PLAYER_SWING(duration, swingType)` and `PLAYER_SWING_RANGE_UPDATE`, with `Enum.PlayerSwingType` MainHand 0, OffHand 1, Ranged 2. `C_SwingTimer.IsTargetWithinSwingRange` returns nil to addons. **[dump]** **[web]**
- Chatify doesn't attach chat message filters by default on Retail and Forever because of these restrictions. **[addon]**

## Secure code and Blizzard systems

- `/cui` confirmed `C_EditMode`, `C_CurveUtil`, and `C_EncodingUtil` exist. **[in-game]**
- Secure snippets (`WrapScript`, `_onstate-*`, `RunAttribute`) failed before build 70009 because `loadstring_untainted` was deleted too early. Build 70009 fixed the load order. **[web]** (forever-addon-kit, forever-bugs #74) Confirmed: a `SecureHandlerBaseTemplate` frame's `Execute(f, "return 42")` returned `true 42`. **[in-game]** (2026-09-25, build 70009)
  - Never probe `loadstring_untainted` to decide whether snippets work: it is nil after load on every client, Retail included.
- Blizzard's Cooldown Manager is off by default and, from build 70009, has data for Druid, Mage, Priest, Warrior, and Warlock only. It doesn't support spell ranks. **[web]**
- After 100 Lua errors in a session, the client stops passing errors to handlers (BugSack goes quiet). Fix error floods first. **[web]**
- Auction house is the modern (Retail) one, but copper prices are allowed and durations are 2, 8, and 24 hours. **[addon]** (Auctionator `Source_Forever`, `IsForever` branches)
  - A whole-house scan works as an empty browse search: `C_AuctionHouse.SendBrowseQuery({ searchString = "", sorts = {}, filters = {}, itemClassFilters = {} })`, then `RequestMoreBrowseResults()` on each `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` / `_ADDED` until `HasFullBrowseResults()`. Each result has `itemKey.itemID`, `minPrice` (taken as a unit price), and `totalQuantity`. **[addon]** (Auctionator `Source_ModernAH/IncrementalScan`, its default scan; `TimeOfLastBrowseScan` is set in the saved Auctionator.lua on this client)
  - `ReplicateItems`, `GetNumReplicateItems`, `GetReplicateItemInfo`, `GetReplicateItemLink`, and `REPLICATE_ITEM_LIST_UPDATE` are in the build 70009 exe, but no one has shown a replicate scan finishing on Forever (Auctionator's is off by default). **[exe]** Unverified in game.
- The Professions window exists but has no crafting orders page. **[addon]** (Auctionator `Professions.lua`)

## Console variables

- `C_Console.GetAllCommands()` (entries with `command`, `help`, `commandType`, where `Enum.ConsoleCommandType.Cvar` marks a CVar) and `C_CVar.GetCVarInfo(name)` (value, default, account, character, locked, secure, read only) are Mainline's. No installed Forever addon uses either. **Unverified**; the CVarBrowser module probes both, and falls back to `C_CVar.GetCVar` / `GetCVarDefault` and exact-name search.
- `Settings.RegisterCanvasLayoutSubcategory` works on Forever. **[addon]** (Auctionator `PanelConfig.lua`, AceConfigDialog in several addons)

## Nameplates

- Nameplates are Mainline's: `C_NamePlate.GetNamePlateForUnit` / `GetNamePlates`, `NAME_PLATE_UNIT_ADDED` / `REMOVED`, and `plate.UnitFrame` with `HealthBarsContainer` (holding `healthBar`) and `name`. **[addon]** (ForeverNameplateFont `Core.lua`, MyQuestPlates `Compat.lua`)
- A friendly player's `plate.UnitFrame` has these keys, among others: `name` (FontString), `healthBar` (StatusBar), `HealthBarsContainer`, `LevelFrame`, `PlayerLevelDiffFrame`, `ClassificationFrame`, `CastBarsContainer`, `AurasFrame`, `RaidTargetFrame`, `WidgetContainer`, `SoftTargetFrame`, `selectionHighlight`, and the aggro and heal-prediction textures. `LevelFrame` is the level badge at the bar's right end, which Retail doesn't have. **[in-game]** (2026-09-26, build 70009, `/run` listing the frame's widget fields)
- Friendly player plates use CVar `nameplateShowFriendlyPlayers` (older name `nameplateShowFriends`), and Blizzard's names-only mode is `nameplateShowOnlyNameForFriendlyPlayerUnits` (older `nameplateShowOnlyNames`). ForeverNameplateFont tries the new name first and falls back. **[addon]** Which names this client has is **Unverified**; the FriendlyPlates module probes with `C_CVar.GetCVar`.
- Nameplate CVars can't be set in combat on Retail; Forever++ assumes the same and waits for `PLAYER_REGEN_ENABLED`. **Unverified** on Forever.
- `C_CurveUtil.CreateCurve()` with `AddPoint` / `SetType(Enum.LuaCurveType.Step)`, evaluated by `UnitHealthPercent(unit, true, curve)`, turns a possibly secret health fraction into an alpha for `SetAlpha`. That's the Midnight pattern (ClutchUI uses `UnitHealthPercent` with `CurveConstants.ScaleTo100`) **[addon]**; the step curve and `SetAlpha` taking its result are **Unverified** on Forever.

## Looting and repairs

- Fast looting works the Retail way: `LOOT_READY`, then `LootSlot(i)` from `GetNumLootItems()` down to 1, when `autoLootDefault` differs from `IsModifiedClick("AUTOLOOTTOGGLE")`. **[addon]** (Leatrix_Plus `Leatrix_Plus.lua`, BleakfibersQuestTracker `SocialModule.lua`)
- `CanMerchantRepair`, `GetRepairAllCost`, `RepairAllItems(guildBank)`, `CanGuildBankRepair` and `IsInGuild` are there. **[addon]** (Leatrix_Plus `Leatrix_Plus.lua`, repairs at `MERCHANT_SHOW`) `GetGuildBankWithdrawMoney` returning -1 for no limit, and a failed guild bank repair raising `UI_ERROR_MESSAGE` (the AutoRepair module's fallback to the player's own money), are Retail behavior and **Unverified** on Forever.

## Fonts

- Text measured before its font file has loaded reads as 0 tall on Forever, even after preloading. Measure with a floor of the font size. **[in-game]** (ClutchUI `Style.TextHeight`, `docs/fonts.md`)

## Open questions

Check these in the live client and move them up with a tag and date:

- [x] `_Camelot.toc` beats `_Mainline.toc` and the plain TOC on 70009. (2026-09-25)
- [x] `[AllowLoadGameType camelot]` loads on Forever and `standard` doesn't. (2026-09-25)
- [ ] Does `C_Console.GetAllCommands()` list CVars on Forever, and does `Enum.ConsoleCommandType.Cvar` exist?
- [ ] Is `ReloadUI()` blocked when called from an addon's own button? (From `/run` it works.)
- [x] Secure snippets run on 70009. (2026-09-25)
- [x] `Settings.RegisterAddOnCategory`, `Menu.ModifyMenu`, and `TooltipDataProcessor.AddTooltipPostCall` are present. (2026-09-25)
- [x] `C_SpecializationInfo.GetSpecializationInfo(1)` returns a class-level spec with 0 points. (2026-09-25, see Talents)
- [x] Talent points are in `C_Traits`, one `CamelotCombat` config with one tree per class. (2026-09-25, see Talents)
- [x] The three talent tabs are trait groups from `C_Traits.GetGroupDisplayInfoByTreeID`. (2026-09-25)
- [x] Nodes list their tab's group in `groupIDs` (not always first), and `C_Traits.GetGroupCurrencyInfo` gives points spent per tab. (2026-09-25)
- [ ] Does `GetGroupCurrencyInfo` return an entry for a tab once it has points, with points in two tabs? (Only one tab had points when tested.)

## Sources

Local, read only:
- `D:\BattleNet\World of Warcraft\.build.info`, `_classic_beta_\WTF\Config.wtf`, `_classic_beta_\WTF\Account\70453270#1\` (realm folders, `SavedVariables\ClutchUI.lua`, `SavedVariables\ForeverPlusPlus.lua`).
- Installed addons in `_classic_beta_\Interface\AddOns`: Auctionator (v339), BugSack (v12.1.2), AlreadyKnown (1.103), Chatify (3.6, `Forever.lua`, `Config.lua`), Manners (1.0.0-beta.6, `Flavour.lua`, `Core.lua`), MapUtils / AzerothCompendium (D4Lib), ManiaTip (v15), UnifiedProfileManager (AceDB), ClutchUI.
- ClutchUI repo, `docs/flavors.md`, `docs/midnight-secrets.md`, `docs/fonts.md`: Cameron's in-game checks from 2026-09-23.

Web (checked 2026-09-25):
- [TOC format, warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/TOC_format): game types and suffix precedence.
- [Thunderz96/forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit) (README, updated 2026-09-24): measured findings; `data/forever_api.json` is an API dump from build 69893.
- [Atraeau/WoW-Addons](https://github.com/Atraeau/WoW-Addons): `docs/api.json` and [browsable reference](https://atraeau.github.io/WoW-Addons/), generated from the client's own `APIDocumentation` on build 69913 (2026-09-20). Good for signatures.
- [ClassicWoWCommunity/forever-bugs #74](https://github.com/ClassicWoWCommunity/forever-bugs/issues/74): the secure snippet load-order bug.
- [Blizzard: Forever beta development notes, updated 2026-09-24](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-september-24/2360696) and [known issues, 2026-09-17](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-known-issues-september-17/2352687).
- [Forever addons: the modern API and beta compatibility (classicwowforever.com)](https://classicwowforever.com/guides/wow-forever-addons-api-compatibility/): launch date, Blizzard's 2026-09-17 Q&A confirming the modern API.

Both API dumps predate build 70009. To refresh, regenerate one in game (Atraeau's `WowApiExport` or forever-addon-kit's `ForeverBeacon`) rather than trusting these copies.
