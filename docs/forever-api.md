# WoW: Forever client API notes

What we know about the addon API on the WoW: Forever client, where each fact came from, and how sure we are. `AGENTS.md` has the short version; this file has the detail and the sources.

Last reviewed 2026-09-25, against build **1.60.1.70009** (the build in the client's `.build.info`, product `wow_classic_beta`). Forever is a beta: recheck anything marked below before relying on it after a patch.

## How to read the tags

Every fact carries one tag saying how it was established:

| Tag | Meaning |
| --- | --- |
| **[local]** | Read from a Forever client install: its files, installed addons, or saved files. |
| **[in-game]** | Tested in the live client, with `/dump`, `/run`, or a test addon. |
| **[dump]** | Present in a captured API dump of the Forever client (see [Sources](#sources)). Shows the API exists, not that it behaves like Retail. |
| **[addon]** | Inferred from how an installed Forever addon uses it. The addon works for players, but we have not tested that exact call. |
| **[web]** | Reported by someone else online. Not checked by us. |
| **Unverified** | Plausible but unconfirmed, or sources disagree. Check before depending on it. |

When you confirm or rule out something here, change its tag, add the date, and say how you checked.

## Client identity

- Build 1.60.1.70009, interface **16001**, product `wow_classic_beta`, exe `WowB.exe`, folder `_classic_beta_`. **[local]** (`.build.info`, `WTF\Config.wtf` has `engineSurveyPatch "16001"`)
- Internal codename is **Camelot**. It shows up in TOC suffixes, TOC game types, and addon code. **[local]** (installed addons) **[web]** (wiki)
- `GetBuildInfo()` returns `"1.60.1", <build>, <date>, 16001`. **[in-game]** (2026-09-23) **[dump]** (`client.interface = 16001`)
- `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` (1), same as Retail. It can't tell Forever from Retail. **[in-game]** (2026-09-23) **[dump]**
- Launch is set for 2026-11-04. **[web]**

### Detecting Forever at runtime

Use the interface number with both ends of a range: `local iface = select(4, GetBuildInfo()); local isForever = iface >= 16000 and iface < 17000`.

- Never test "starts with 1" or "five digits": Classic Era is 11509 and would match. Manners' `Flavour.lua` explains this trap in detail. **[addon]**
- Many Retail addons test `>= 100000` to mean "modern client". On Forever that fails, so ported Retail code takes Classic paths. **[web]** (forever-addon-kit)
- Other addons use `[16000, 17000)` (WhisperMessenger, Manners) or `[16000, 20000)` (Auctionator, D4Lib, ManiaTip, AceDB in UnifiedProfileManager). **[addon]**
- Prefer probing the API you need over any version check.

## TOC and loading

- Ship one plain `ForeverPlusPlus.toc` with `## Interface: 16001`. That works. **[local]** (this addon loads and saves)
- **TOC suffixes: `_Camelot` wins on build 70009.** A test addon with `FppTocProbe.toc`, `FppTocProbe_Camelot.toc`, and `FppTocProbe_Mainline.toc`, all at 16001, loaded **`_Camelot`**. **[in-game]** (2026-09-25)
  - That matches warcraft.wiki.gg: expansion suffixes (`_Camelot`, `_Standard`, ...) beat family suffixes (`_Mainline`, `_Classic`), which beat the plain name. **[web]**
  - An earlier test on 2026-09-23 (`_Mainline` at 120100, `_Camelot` and plain at 16001) loaded **`_Mainline`**. **[in-game]** Either the build changed or the setup differed. Recheck after patches.
  - Installed addons that ship a `_Camelot.toc`: AutoStow, AzerothCompendium, Chatify, Manners, MapUtils, TwitchEmotes, WhisperMessenger. **[local]**
- **Per-file load conditions** in the TOC file list: `file.lua [AllowLoadGameType camelot]` and `[ExcludeLoadGameType ...]`.
  - The wiki lists game type `camelot` = Forever, `standard` = Midnight only, `mainline` = Midnight **and** Forever (plus Plunderstorm and other modes), `classic` = the Classic expansions. **[web]**
  - BugSack (`forever.lua [ExcludeLoadGameType standard, classic][AllowLoadGameType camelot]`), Auctionator (`Source_Forever\Constants.lua`), and AlreadyKnown (`[AllowLoadGameType classic, camelot]`) rely on this. **[addon]**
  - Auctionator also loads `[AllowLoadGameType mainline]` files on Forever and branches on `IsForever` inside them, which fits `mainline` including Forever. **[addon]**
  - Tested on Forever: `[AllowLoadGameType camelot]` and `[AllowLoadGameType mainline]` load, `[AllowLoadGameType standard]` and `[AllowLoadGameType classic]` don't, and `[ExcludeLoadGameType standard]` loads. **[in-game]** (2026-09-25, FppTocProbe)
  - So `camelot` (or excluding `standard`) splits Forever-only files from Retail at load time. `mainline` can't, since it matches both. That Retail skips `camelot` files comes from the wiki **[web]**; we didn't run the probe on Retail.
- `## Category`, `## IconTexture`, localized `## Title-xxXX` / `## Notes-xxXX` fields are used by installed Forever addons. **[addon]**

## SavedVariables

- **They persist now.** A load counter that only goes up when the saved table is read back reached 7 across sessions, and `WTF\Account\<acct>\SavedVariables\ForeverPlusPlus.lua` holds this addon's module state. **[local]** (checked 2026-09-25)
- History: on 2026-09-23 they were written but never read back, so every session started from defaults. **[in-game]** (the same counter stayed at 1) **[web]** (forever-addon-kit, EU forum thread)
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
  - On a Warrior, `GetSpecializationInfo(1)` returned `1491, "Warrior", "", 626008, "DAMAGER", 4, 0, nil, 0, true`, and `C_SpecializationInfo.GetSpecialization()` returned `1`. **[in-game]** (2026-09-25)
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

- `issecretvalue`, `canaccessvalue`, `issecrettable`, `scrub`, `secretwrap` exist, as does `C_Secrets` with 27 predicates (`HasSecretRestrictions`, `ShouldAurasBeSecret`, `ShouldUnitHealthMaxBeSecret`, `GetSpellAuraSecrecy`, ...). **[in-game]** (2026-09-23) **[dump]**
- In a solo open-world fight, `UnitHealth`, `UnitHealthPercent`, and `UnitHealthMissing` were secret for player and target, and the target's `UnitHealthMax` was secret. The player's `UnitHealthMax` and all `UNIT_COMBAT` amounts stayed readable. **[web]** (forever-addon-kit)
- In combat, while `C_Secrets.ShouldAurasBeSecret()` is true, reading a secret aura throws, including your own buffs. Secrecy is per spell: `C_Secrets.GetSpellAuraSecrecy(id)`. **[web]**
- `Cooldown:SetCooldown` rejects secret numbers from addon code. Get a duration object from `C_Spell.GetSpellCooldownDuration` and pass it to `Cooldown:SetCooldownFromDurationObject`. **[web]**
- Range checks stay readable in open-world combat (`C_Spell.IsSpellInRange`, `CheckInteractDistance`, some `C_Item.IsItemInRange` distances). **[web]**
- `COMBAT_LOG_EVENT_UNFILTERED` never fires for addons. **[addon]** (Manners `Core.lua`) **[web]** Use `C_DamageMeter` (Blizzard's built-in meter) or events like `UNIT_COMBAT`.
- Swing timer events `PLAYER_SWING(duration, swingType)` and `PLAYER_SWING_RANGE_UPDATE`, with `Enum.PlayerSwingType` MainHand 0, OffHand 1, Ranged 2. `C_SwingTimer.IsTargetWithinSwingRange` returns nil to addons. **[dump]** **[web]**
- Chatify doesn't attach chat message filters by default on Retail and Forever because of these restrictions. **[addon]**

## Secure code and Blizzard systems

- `C_EditMode`, `C_CurveUtil`, and `C_EncodingUtil` exist. **[in-game]** (2026-09-23)
- Secure snippets (`WrapScript`, `_onstate-*`, `RunAttribute`) failed before build 70009 because `loadstring_untainted` was deleted too early. Build 70009 fixed the load order. **[web]** (forever-addon-kit, forever-bugs #74) Confirmed: a `SecureHandlerBaseTemplate` frame's `Execute(f, "return 42")` returned `true 42`. **[in-game]** (2026-09-25, build 70009)
  - Never probe `loadstring_untainted` to decide whether snippets work: it is nil after load on every client, Retail included.
- Blizzard's Cooldown Manager is off by default and, from build 70009, has data for Druid, Mage, Priest, Warrior, and Warlock only. It doesn't support spell ranks. **[web]**
- After 100 Lua errors in a session, the client stops passing errors to handlers (BugSack goes quiet). Fix error floods first. **[web]**
- Auction house is the modern (Retail) one, but copper prices are allowed and durations are 2, 8, and 24 hours. **[addon]** (Auctionator `Source_Forever`, `IsForever` branches)
  - A whole-house scan works as an empty browse search: `C_AuctionHouse.SendBrowseQuery({ searchString = "", sorts = {}, filters = {}, itemClassFilters = {} })`, then `RequestMoreBrowseResults()` on each `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` / `_ADDED` until `HasFullBrowseResults()`. Each result has `itemKey.itemID`, `minPrice` (taken as a unit price), and `totalQuantity`. **[addon]** (Auctionator `Source_ModernAH/IncrementalScan`, its default scan; `TimeOfLastBrowseScan` is set in the saved Auctionator.lua on this client)
  - `ReplicateItems`, `GetNumReplicateItems`, `GetReplicateItemInfo`, `GetReplicateItemLink`, and `REPLICATE_ITEM_LIST_UPDATE` are in the build 70009 exe, but no one has shown a replicate scan finishing on Forever (Auctionator's is off by default). **[exe]** Unverified in game.
- The Professions window exists but has no crafting orders page. **[addon]** (Auctionator `Professions.lua`)
- The beta runs Blizzard's PTR feedback code. `PTR_IssueReporter` is the floating bug report button, and it adds a `" "` line and then "Press F6 to submit an issue for this Item" at the end of tooltips. That line isn't in the tooltip's data lines, so it's added afterwards. Its format strings are `PTR_IssueReporter.BugTooltipString`, `BugTooltipPartialString`, and `MissingBindTooltipString`; it also has `HookIntoTooltip`, `AddTooltip`, `TooltipFrames`, and `Setup*Tooltips` (items, spells, units, quests, currencies, achievements, and more). **[in-game]** (2026-09-26, `/run` probes)
- Whether `IsBetaBuild()` or `IsPublicTestClient()` returns true on Forever's beta is **Unverified**. Two installed addons call `IsPublicTestClient` **[addon]**; Hide Beta Feedback shows only when either is true or `PTR_IssueReporter` already exists at login. Check with `/dump IsBetaBuild(), IsPublicTestClient()`.

## Console variables

- The console's command list is the global `ConsoleGetAllCommands()` (entries with `command`, `help`, `commandType`, where `Enum.ConsoleCommandType.Cvar` marks a CVar), as on Retail. `C_Console` doesn't exist, so `C_Console.GetAllCommands` gave the CVar browser an empty list. **[local]** (2026-09-26, the `ConsoleGetAllCommands`, `ConsoleCommandType` and `Cvar` strings in `WowB.exe` 70009, next to `ConsoleExec`) **[in-game]** (the empty list)
- `C_CVar.GetCVarInfo(name)` returns value, default, account, character, locked, secure, read only. **[local]** (its usage string in `WowB.exe`)
- The client has `autoDismount` ("Automatically dismount when needed"), `autoDismountFlying`, `autoStand` ("Automatically stand when needed") and `autoUnshift` ("Automatically leave shapeshift form when needed"), as on Retail. **[local]** (2026-09-27, the names and help strings together in `WowB.exe` 70009) Their default values, and whether they cover more than casting (flight masters, looting), are **Unverified**.
- `C_ChatInfo.PerformEmote` exists. **[addon]** (Leatrix_Maps hooks it with `hooksecurefunc`) Whether `PerformEmote("STAND")` from an event handler stands the player up is **Unverified**, as is whether `Dismount()` is callable from an addon.
- `Settings.RegisterCanvasLayoutSubcategory` works on Forever. **[addon]** (Auctionator `PanelConfig.lua`, AceConfigDialog in several addons)
- A checkbox with a button beside it: `CreateSettingsCheckboxWithButtonInitializer(setting, buttonText, onClick, nil, clickRequiresSet, tooltip)`, added with `layout:AddInitializer`. **[addon]** (ManiaTip `Libs/Huddle/Modules/Settings.lua`) What the fourth argument is (nil there) is **Unverified**; Forever++ probes for the function.

## Nameplates

- Nameplates are Mainline's: `C_NamePlate.GetNamePlateForUnit` / `GetNamePlates`, `NAME_PLATE_UNIT_ADDED` / `REMOVED`, and `plate.UnitFrame` with `HealthBarsContainer` (holding `healthBar`) and `name`. **[addon]** (ForeverNameplateFont `Core.lua`, MyQuestPlates `Compat.lua`)
- A friendly player's `plate.UnitFrame` has these keys, among others: `name` (FontString), `healthBar` (StatusBar), `HealthBarsContainer`, `LevelFrame`, `PlayerLevelDiffFrame`, `ClassificationFrame`, `CastBarsContainer`, `AurasFrame`, `RaidTargetFrame`, `WidgetContainer`, `SoftTargetFrame`, `selectionHighlight`, and the aggro and heal-prediction textures. `LevelFrame` is the level badge at the bar's right end, which Retail doesn't have. **[in-game]** (2026-09-26, build 70009, `/run` listing the frame's widget fields)
- Never anchor an addon frame to the nameplate base frame (`NamePlateN`, the UnitFrame's parent). `SetPoint` to it fails with "SetPoint would result in anchor family connection", and afterwards Blizzard's own `UpdateAnchors` on plates (Blizzard_NamePlateUnitFrame.lua:699) and the Settings nameplate preview's scroll box fail the same way. Anchoring to the UnitFrame and its children works. **[in-game]** (2026-09-27, BugSack)
- Blizzard's plate setup options include `nameJustificationWhenAboveHealthBar = "CENTER"`, `unitNameAnchorStyle`, `healthBarToNameAboveSpacing = 2`, `castBarToHealthBarSpacing = 2`, `showLevel`. **[in-game]** (2026-09-27, BugSack locals)
- Friendly player plates use CVar `nameplateShowFriendlyPlayers` (older name `nameplateShowFriends`), and Blizzard's names-only mode is `nameplateShowOnlyNameForFriendlyPlayerUnits` (older `nameplateShowOnlyNames`). ForeverNameplateFont tries the new name first and falls back. **[addon]** Which names this client has is **Unverified**; Player Nameplates probes with `C_CVar.GetCVar`.
- Nameplate CVars can't be set in combat on Retail; Forever++ assumes the same and waits for `PLAYER_REGEN_ENABLED`. **Unverified** on Forever.
- `C_CurveUtil.CreateCurve()` with `AddPoint` / `SetType(Enum.LuaCurveType.Step)`, evaluated by `UnitHealthPercent(unit, true, curve)`, turns a possibly secret health fraction into an alpha for `SetAlpha`. That's the Midnight pattern, and a working Forever addon uses `UnitHealthPercent` with `CurveConstants.ScaleTo100` **[addon]**; the step curve and `SetAlpha` taking its result are **Unverified** on Forever.

## Recent allies

- `C_RecentAllies` exists: `IsSystemEnabled`, `IsSystemSupported`, `IsRecentAllyByGUID(guid)`, `IsRecentAllyByFullName(name)`, `GetRecentAllyByGUID`, `GetRecentAllies`, `IsRecentAllyDataReady`, `TryRequestRecentAlliesData`, plus notes and pins. Events: `RECENT_ALLIES_CACHE_UPDATE`, `RECENT_ALLIES_DATA_READY`, `RECENT_ALLY_DATA_UPDATED` (guid), `RECENT_ALLIES_SYSTEM_STATUS_UPDATED`. **[dump]** (both dumps)
- Blizzard's Lua uses it for the Recent Allies tab in the Friends frame (Camelot `FriendsFrame.lua` shows the tab when `IsSystemEnabled()`), for the `friendslist-recentallies-yellow` icon after names in chat (`IsRecentAllyByGUID(senderGUID)`) and whisper tabs, and for the unit menu. The tab calls `TryRequestRecentAlliesData()` when shown and listens for `RECENT_ALLIES_CACHE_UPDATE`; chat asks `IsRecentAllyByGUID` without requesting first. **[web]** (Gethe/wow-ui-source `forever` branch, 1.60.1.70009)
- The light blue is `RECENT_ALLY_FONT_COLOR`, (0.325, 0.788, 1) or `ff53c9ff`, a `GlobalColor` row that `C_UIColor.GetColors()` turns into a global at load. No Blizzard Lua reads it, not even the nameplates (`CompactUnitFrame_UpdateName` colors only by class or selection), so the client draws it itself (in-world names, presumably). **[web]** (wago.tools `GlobalColor` for 1.60.1.70009; the `forever` UI source) The global exists with that value. **[in-game]** (2026-09-27, `/dump RECENT_ALLY_FONT_COLOR:GetRGB()`) Where exactly the game shows it, and whether `IsRecentAllyByGUID` is right without a request first, is **Unverified**.
- Player Nameplates colors recent allies' names with `Units.IsRecentAlly`, falls back to the 70009 value if the global is missing, and requests the data once when it turns on.

## Looting and repairs

- Fast looting works the Retail way: `LOOT_READY`, then `LootSlot(i)` from `GetNumLootItems()` down to 1, when `autoLootDefault` differs from `IsModifiedClick("AUTOLOOTTOGGLE")`. **[addon]** (Leatrix_Plus `Leatrix_Plus.lua`, BleakfibersQuestTracker `SocialModule.lua`)
- `CanMerchantRepair`, `GetRepairAllCost`, `RepairAllItems(guildBank)`, `CanGuildBankRepair` and `IsInGuild` are there. **[addon]** (Leatrix_Plus `Leatrix_Plus.lua`, repairs at `MERCHANT_SHOW`) `GetGuildBankWithdrawMoney` returning -1 for no limit, and a failed guild bank repair raising `UI_ERROR_MESSAGE` (the AutoRepair module's fallback to the player's own money), are Retail behavior and **Unverified** on Forever.

## Minimap tracking

- `C_Minimap.GetNumTrackingTypes()` and `C_Minimap.GetTrackingInfo(i)` work, and the info is a table with `name`, `active`, `type`, and `spellID` (Find Herbs 2383, Find Minerals 2580). It has no secret values, in or out of combat. **[addon]** (GatherSkillTooltip `Warnings.lua`, `Data.lua`; AutoTrackers `AutoTrackers.lua`)
- `C_Minimap.SetTracking(i, true)` turns a tracking spell on, called from a `C_Timer` callback with no keypress. **[addon]** (AutoTrackers restores the saved tracker from a 3 second ticker, out of combat and while alive; installed here with Find Minerals saved on three characters) **[in-game]** (2026-09-26, build 70009: `/run` turned Find Minerals off, and `SetTracking` from a 2 second `C_Timer.After` turned it back on, on foot) Whether it works mounted is **Unverified**.
- The info's `type` is `"spell"` for tracking spells and `"other"` for the town and quest filters (Auctioneer, Flight Master, Track Quest POIs, ...), which have no `spellID`. **[in-game]** (2026-09-26, `/run` listing every entry)
- Blizzard shows nothing on screen when tracking changes. A centered "Find Minerals is off" comes from GatherSkillTooltip's tracking warning, not the client. **[local]** (GatherSkillTooltip `Locales/enUS.lua` `SPELL_OFF`)
- Only one tracking spell is on at a time, as in Classic: turning on Find Herbs turns off Find Minerals. **[addon]** (GatherSkillTooltip treats either one being on as enough when the player has both skills) **Unverified** in game.
- Tracking is lost on death and needs turning back on after resurrection. **[addon]** (AutoTrackers restores on `PLAYER_ALIVE` / `PLAYER_UNGHOST`)

## Weapon sheathing

- `GetSheathState()` (1 nothing drawn, 2 melee, 3 ranged) and `ToggleSheath()` are there, and `ToggleSheath()` works from a `C_Timer` callback with no key press. One toggle puts away everything drawn. `hooksecurefunc("ToggleSheath", fn)` sees the Sheath/Unsheath key. **[addon]** (AutoStow 1.2.2 `AutoStow.lua`, which stows out of combat on a timer) Not yet tested by us in the live client.

## Gossip

- `GOSSIP_SHOW` and `C_GossipInfo.GetActiveQuests` / `GetAvailableQuests` / `SelectActiveQuest` / `SelectAvailableQuest` are used on Forever. **[addon]** (BleakfibersQuestTracker `SocialModule.lua`) No installed addon reads `C_GossipInfo.GetOptions`.
- `C_GossipInfo.GetOptions()` returns Retail's option table (`gossipOptionID`, `name`, `icon`, `status`, `flags`, `spellID`, `selectOptionWhenOnlyOption`) with the Classic gossip icon file IDs. **[in-game]** (2026-09-27, build 70009: a banker gave `96317 132050 0 0 nil false "I would like to check my deposit box."`, a Wind Rider Master `98541 132057 0 0 nil false "I need a ride."`) Probe: `/run for _,o in ipairs(C_GossipInfo.GetOptions())do print(o.gossipOptionID,o.icon,o.status,o.flags,o.spellID,o.selectOptionWhenOnlyOption,o.name)end`
  - An innkeeper had three options: dungeons (132053, the plain gossip icon), browse goods (132060, vendor), and make this inn your home (132052, binder). **[in-game]** (2026-09-27) So innkeepers never have a single option, and AutoGossip has no innkeeper type. The trainer icon (132058) is **Unverified**. Its Debug option prints every option's icon and status.
- Line 2 of `C_TooltipInfo.GetUnit("npc")` is the NPC's title: `Banker`, `Wind Rider Master`. **[in-game]** (2026-09-27) AutoGossip tells stable masters apart by it (`Stable Master` is **Unverified**): `/run local d=C_TooltipInfo.GetUnit("npc")print(d and d.lines[2] and d.lines[2].leftText)`
- Auctioneers open the auction house straight away, with no gossip. **[in-game]** (2026-09-27)
- `C_GossipInfo.ForceGossip()` was true at a Wind Rider Master with one option (`95583`), so Forever sets it on plain service NPCs, not only on ones whose text matters. **[in-game]** (2026-09-27) AutoGossip ignores it for known service types, and `C_GossipInfo.SelectOption(95583)` from `GOSSIP_SHOW` then opened the flight map. **[in-game]** (2026-09-27)

## Death and releasing

- `RepopMe`, `C_DeathInfo.GetSelfResurrectOptions`, `UseSelfResurrectOption`, `HasNoReleaseAura`, `UnitHasIncomingResurrection`, and `RESURRECT_REQUEST` are in the build 70009 exe. **[exe]** No installed addon calls them.
- On Retail, `RepopMe()` isn't protected, and auto-release addons call it from a `C_Timer` after `PLAYER_DEAD`. **[web]** Whether Forever allows that from addon code is **Unverified**; Auto Release relies on it. Check: `/run C_Timer.After(1, RepopMe)` while dead should release with no "blocked" error.
- `IsInInstance()` returning `"pvp"` in Forever's battlegrounds, and which battlegrounds exist, is **Unverified**. Check: `/dump IsInInstance()` in one.

## Cinematics and movies

- In-world cinematics go through `CINEMATIC_START(canBeCancelled, forcedAspectRatio)` and `CinematicFrame`, which Blizzard's `CinematicFrame_OnEvent` shows. `canBeCancelled` false means a vehicle ride or scene, which Blizzard's own cancel (`CinematicFrame_CancelCinematic`) ends with `CancelScene` or `VehicleExit`; true means a real cinematic, ended with `StopCinematic()`. **[web]** (Gethe/wow-ui-source `forever`, `Blizzard_FrameXML/Shared/CinematicFrame.lua`, checked 2026-09-27) Cinematics have no ID, so Skip Cinematics remembers them by map and subzone.
- Movies go through `PLAY_MOVIE(movieID)` and `MovieFrame` (`MovieFrameMixin`, always loaded). `MovieFrame:PlayMovie` sets `MovieFrame.movieID` only when the movie really started, and the skip dialog's confirm button calls `MovieFrame:FinishMovie()`. **[web]** (same repo, `Blizzard_FrameXML/MovieFrame.lua`) `CinematicStarted` / `CinematicFinished` take secret arguments only when untainted, which doesn't matter for plain numbers.
- Unverified: whether `StopCinematic()` from a `C_Timer.After(0)` after `CINEMATIC_START` ends the cinematic, and whether `FinishMovie()` from a `hooksecurefunc` on `MovieFrame.PlayMovie` works without a taint error. Skip Cinematics depends on both; its Debug option prints each key as it starts.

## Screenshots and milestone events

- `Screenshot()` and the `SCREENSHOT_SUCCEEDED` / `SCREENSHOT_FAILED` events are there, and hiding `UIParent` out of combat for a shot works. **[addon]** (Memento v2.30 `core/Capture.lua`, which lists 16001 in its TOC)
- Memento registers `PLAYER_LEVEL_UP`, `ACHIEVEMENT_EARNED`, `CRITERIA_EARNED`, `ENCOUNTER_END`, `PVP_MATCH_COMPLETE`, `PLAYER_DEAD`, `DUEL_FINISHED`, and `NEW_RECIPE_LEARNED` on Forever, but not `SHOW_LOOT_TOAST` or the pet, mount, and toy events. **[addon]** (Memento `Memento.lua`)
- The PvP rank is the renown level of major faction 2800: Blizzard's Character frame reads it with `C_MajorFactions.GetMajorFactionProgressionInfo(2800).renownLevel`, and names it with `PVP_RANK_<n>_<0 Horde, 1 Alliance>`. So a rank up should be `MAJOR_FACTION_RENOWN_LEVEL_CHANGED(2800, new, old)`. **[web]** (the `forever` UI source, `Blizzard_UIPanels_Game/Camelot/PVPRankFrame.lua`) The event firing for it is **Unverified**.
- `GetNumTitles` / `IsTitleKnown` are used by the Camelot Character frame, and `KNOWN_TITLES_UPDATE` is in the event docs. **[web]** (the `forever` UI source) Whether it fires when a title is earned, and whether the list arrives late at login, is **Unverified**.
- Which chat event carries "You are now Friendly with ..." (`FACTION_STANDING_CHANGED`) isn't known: Auto Screenshot listens to `CHAT_MSG_SYSTEM` and `CHAT_MSG_COMBAT_FACTION_CHANGE`. **Unverified**.
- Own loot lines (`LOOT_ITEM_SELF`, `LOOT_ITEM_PUSHED_SELF` and their `_MULTIPLE` forms) in `CHAT_MSG_LOOT` are Retail behavior; whether they can be secret in instances is **Unverified**.

## Fonts

- Text measured before its font file has loaded reads as 0 tall on Forever, even after preloading. Measure with a floor of the font size. **[in-game]** (2026-09-23)

## Open questions

Check these in the live client and move them up with a tag and date:

- [x] `_Camelot.toc` beats `_Mainline.toc` and the plain TOC on 70009. (2026-09-25)
- [x] `[AllowLoadGameType camelot]` loads on Forever and `standard` doesn't. (2026-09-25)
- [ ] Does `ConsoleGetAllCommands()` list every CVar on Forever, or only some?
- [ ] Is `ReloadUI()` blocked when called from an addon's own button? (From `/run` it works.)
- [ ] Does `C_Minimap.SetTracking` from a timer swap Find Minerals and Find Herbs, mounted and not, without an error or a dismount?
- [x] Secure snippets run on 70009. (2026-09-25)
- [x] `Settings.RegisterAddOnCategory`, `Menu.ModifyMenu`, and `TooltipDataProcessor.AddTooltipPostCall` are present. (2026-09-25)
- [x] `C_SpecializationInfo.GetSpecializationInfo(1)` returns a class-level spec with 0 points. (2026-09-25, see Talents)
- [x] Talent points are in `C_Traits`, one `CamelotCombat` config with one tree per class. (2026-09-25, see Talents)
- [x] The three talent tabs are trait groups from `C_Traits.GetGroupDisplayInfoByTreeID`. (2026-09-25)
- [x] Nodes list their tab's group in `groupIDs` (not always first), and `C_Traits.GetGroupCurrencyInfo` gives points spent per tab. (2026-09-25)
- [ ] Does `GetGroupCurrencyInfo` return an entry for a tab once it has points, with points in two tabs? (Only one tab had points when tested.)
- [x] `RECENT_ALLY_FONT_COLOR:GetRGB()` gives (0.325, 0.788, 1). (2026-09-27)
- [ ] Does `RepopMe()` work from an addon's timer after `PLAYER_DEAD`, and does `IsInInstance()` say `"pvp"` in battlegrounds?
- [ ] Does `C_RecentAllies.IsRecentAllyByGUID` answer right after login, before the Recent Allies tab is opened?
- [ ] Do `DUEL_REQUESTED`, `CancelDuel()`, and `StaticPopup_Hide("DUEL_REQUESTED")` work as on Retail? No installed addon uses them. **Unverified** (AutoDecline depends on them.)- [ ] Does `DUEL_REQUESTED` give the name with a surname or realm attached? AutoDecline compares names with anything after a `-` cut off.
- [ ] What are the defaults of `autoDismount`, `autoStand` and `autoUnshift`, and do `Dismount()` and `C_ChatInfo.PerformEmote("STAND")` work from a `UI_ERROR_MESSAGE` handler out of combat?

## Sources

Local, read only:
- The client's `.build.info`, `_classic_beta_\WTF\Config.wtf`, and `_classic_beta_\WTF\Account\<acct>\` (realm folders, `SavedVariables`).
- Forever addons whose code shows an API working: Auctionator (v339), BugSack (v12.1.2), AlreadyKnown (1.103), Chatify (3.6, `Forever.lua`, `Config.lua`), Manners (1.0.0-beta.6, `Flavour.lua`, `Core.lua`), MapUtils / AzerothCompendium (D4Lib), ManiaTip (v15), UnifiedProfileManager (AceDB), Leatrix_Plus, AutoStow, GatherSkillTooltip, Memento (v2.30).

Web (checked 2026-09-25):
- [TOC format, warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/TOC_format): game types and suffix precedence.
- [Thunderz96/forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit) (README, updated 2026-09-24): measured findings; `data/forever_api.json` is an API dump from build 69893.
- [Atraeau/WoW-Addons](https://github.com/Atraeau/WoW-Addons): `docs/api.json` and [browsable reference](https://atraeau.github.io/WoW-Addons/), generated from the client's own `APIDocumentation` on build 69913 (2026-09-20). Good for signatures.
- [Gethe/wow-ui-source, `forever` branch](https://github.com/Gethe/wow-ui-source/tree/forever) (checked 2026-09-27, 1.60.1.70009): Blizzard's own UI code for this client.
- [wago.tools `GlobalColor`](https://wago.tools/db2/GlobalColor?build=1.60.1.70009) (checked 2026-09-27): the client's named colors, which become globals like `RECENT_ALLY_FONT_COLOR`.
- [ClassicWoWCommunity/forever-bugs #74](https://github.com/ClassicWoWCommunity/forever-bugs/issues/74): the secure snippet load-order bug.
- [Blizzard: Forever beta development notes, updated 2026-09-24](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-september-24/2360696) and [known issues, 2026-09-17](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-known-issues-september-17/2352687).
- [Forever addons: the modern API and beta compatibility (classicwowforever.com)](https://classicwowforever.com/guides/wow-forever-addons-api-compatibility/): launch date, Blizzard's 2026-09-17 Q&A confirming the modern API.

Both API dumps predate build 70009. To refresh, regenerate one in game (Atraeau's `WowApiExport` or forever-addon-kit's `ForeverBeacon`) rather than trusting these copies.
