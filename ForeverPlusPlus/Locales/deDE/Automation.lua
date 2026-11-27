local _, ns = ...
local L = ns.NewLocale("deDE")
if not L then
    return
end

-- FastLoot
L.FASTLOOT_TITLE = "Schnelles Plündern"
L.FASTLOOT_DESC = "Nimmt mit Schnell-Plündern alles auf einmal, statt auf das Beutefenster zu warten."
L.FASTLOOT_BLIZZARD_OFF = "Blizzards Schnell-Plündern ist aus" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "Blizzards Schnell-Plündern ist aus, daher geht nur die Beute schnell, "
    .. "die Ihr mit gehaltener Plündertaste (Umschalt) nehmt."

-- AutoRepair
L.AUTOREPAIR_TITLE = "Automatisch reparieren"
L.AUTOREPAIR_DESC = "Repariert Eure gesamte Ausrüstung, wenn Ihr mit einem Händler sprecht, der "
    .. "repariert, und nennt die Kosten im Chat. Haltet die Taste zum Überspringen, um es "
    .. "auszulassen."
L.AUTOREPAIR_FUNDS = "Bezahlen mit"
L.AUTOREPAIR_FUNDS_DESC = "Wessen Geld die Reparaturen bezahlt."
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "Gildenbank, dann eigenes Geld"
L.AUTOREPAIR_FUNDS_GUILD = "Nur Gildenbank"
L.AUTOREPAIR_FUNDS_OWN = "Nur eigenes Geld"
L.AUTOREPAIR_MIN_COST = "Mindestkosten"
L.AUTOREPAIR_MIN_COST_DESC = "Repariert nur, wenn es mindestens so viel kostet, damit ein kurzer "
    .. "Halt beim Händler nicht jedes Mal ein paar Kupfer ausgibt."
L.AUTOREPAIR_MIN_COST_ANY = "Beliebige Kosten"
L.AUTOREPAIR_KEY_DESC = "Haltet diese Taste, während Ihr mit dem Händler sprecht, um Eure Ausrüstung "
    .. "nicht zu reparieren."
L.AUTOREPAIR_CHAT_DESC = "Nennt im Chat die Reparaturkosten oder warum sie nicht bezahlt werden "
    .. "konnten."
L.AUTOREPAIR_REPAIRED = "Repariert für %s." -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "Repariert für %s aus der Gildenbank." -- cost
L.AUTOREPAIR_NO_MONEY = "Nicht genug Geld für die Reparatur (%s)." -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "Die Gildenbank kann die Reparatur nicht bezahlen (%s)." -- cost

-- AutoOpen
L.AUTOOPEN_TITLE = "Behälter automatisch öffnen"
L.AUTOOPEN_DESC = "Öffnet die Behälter in Euren Taschen von selbst, etwa Muscheln, Säcke und "
    .. "Schließkassetten, sobald sie aufgeschlossen sind. Es wartet Kampf, Verstohlenheit, Zaubern "
    .. "und jedes Beute-, Händler-, Post-, Bank-, Handels- oder Auktionsfenster ab."
L.AUTOOPEN_FREE_SLOTS = "Taschenplätze frei halten"
L.AUTOOPEN_FREE_SLOTS_DESC = "Öffnet keine Behälter, solange weniger als die eingestellte "
    .. "Anzahl an Taschenplätzen frei ist, damit der Inhalt Platz hat."
L.AUTOOPEN_SPECIAL = "Besondere Behälter öffnen"
L.AUTOOPEN_SPECIAL_DESC = "Öffnet auch die wenigen Behälter, über die Ihr sonst selbst entscheidet: "
    .. "Edelsteinsäcke von Schlachtzugs- und Weltbossen, Feiertagsgeschenke sowie Truhen und Kisten "
    .. "mit einem Questgegenstand, einem Rezept oder einem Ausrüstungsteil."
L.AUTOOPEN_PICK_LOCKS = "Schlösser per Rechtsklick knacken"
L.AUTOOPEN_PICK_LOCKS_DESC = "Rechtsklickt eine verschlossene Schließkassette in Euren Taschen, um "
    .. "„Schloss knacken“ darauf zu wirken; danach wird sie geöffnet."
L.AUTOOPEN_CHAT_DESC = "Nennt im Chat, was geöffnet wurde."
L.AUTOOPEN_OPENED = "Geöffnet: %s" -- one or more item links, each maybe with a count
L.AUTOOPEN_COUNT = "%s x%d" -- item link, how many
-- AutoSellJunk
L.AUTOSELLJUNK_TITLE = "Plunder automatisch verkaufen"
L.AUTOSELLJUNK_DESC = "Verkauft die grauen Gegenstände in Euren Taschen, wenn Ihr mit einem Händler "
    .. "sprecht, und nennt den Erlös im Chat. Haltet die Taste zum Überspringen, um es auszulassen."
L.AUTOSELLJUNK_BUYBACK = "Rückkaufplätze beachten"
L.AUTOSELLJUNK_BUYBACK_DESC = "Verkauft nur so viel Plunder, wie neben Euren eigenen Verkäufen in die "
    .. "Rückkaufliste des Händlers passt, damit Ihr versehentlich Verkauftes noch zurückkaufen könnt."
L.AUTOSELLJUNK_KEY_DESC = "Haltet diese Taste, während Ihr mit dem Händler sprecht, um Euren Plunder "
    .. "zu behalten."
L.AUTOSELLJUNK_CHAT_DESC = "Nennt im Chat, wie viele Gegenstände verkauft wurden und für wie viel, "
    .. "und wie viele unverkauft blieben, weil die Rückkaufliste voll war."
-- count, money; the forms go by the count
L.AUTOSELLJUNK_SOLD = { "%d Plunderteil für %s verkauft.", "%d Plunderteile für %s verkauft." }
-- count, money, how many were left; the forms go by the first count
L.AUTOSELLJUNK_SOLD_FULL = {
    "%d Plunderteil für %s verkauft. Rückkauf ist voll: %d unverkauft.",
    "%d Plunderteile für %s verkauft. Rückkauf ist voll: %d unverkauft.",
}
L.AUTOSELLJUNK_FULL = { -- count
    "Rückkauf ist voll: %d Plunderteil bleibt unverkauft.",
    "Rückkauf ist voll: %d Plunderteile bleiben unverkauft.",
}

-- GatheringTracking
L.GATHERINGTRACKING_TITLE = "Rohstoffsuche"
L.GATHERINGTRACKING_DESC = "Hält „Mineraliensuche“ oder „Kräutersuche“ an: schaltet sie nach dem "
    .. "Einloggen, einem Zonenwechsel oder dem Tod wieder ein und wechselt auf Wunsch zwischen "
    .. "beiden. Ein Zwerg kann „Schatzsucher“ dazunehmen."
L.GATHERINGTRACKING_TRACK = "Aufspüren"
L.GATHERINGTRACKING_TRACK_DESC = "Welche Sucharten aktiv bleiben sollen. Im Spiel kann jeweils nur "
    .. "eine Suchart aktiv sein, daher wechseln sich beide ab."
L.GATHERINGTRACKING_TRACK_BOTH = "Mineralien und Kräuter"
L.GATHERINGTRACKING_TRACK_MINERALS = "Nur Mineralien"
L.GATHERINGTRACKING_TRACK_HERBS = "Nur Kräuter"
L.GATHERINGTRACKING_REAPPLY = "Wieder einschalten"
L.GATHERINGTRACKING_REAPPLY_DESC = "Schaltet das Aufspüren nach dem Einloggen, einem Zonenwechsel oder "
    .. "der Wiederbelebung wieder ein, wenn nichts aufgespürt wird: einen anderen Aufspürzauber wie "
    .. "„Wildtiere aufspüren“, wenn der zuletzt an war, sonst das hier Gewählte. Schaltet Ihr es "
    .. "selbst aus, bleibt es bis dahin aus."
L.GATHERINGTRACKING_TREASURE = "Schatzsucher"
L.GATHERINGTRACKING_TREASURE_DESC = "Hält auch „Schatzsucher“ des Zwergs an. Es wechselt sich mit dem "
    .. "oben gewählten Aufspüren ab oder bleibt allein an, wenn Ihr keines davon kennt."
L.GATHERINGTRACKING_SWAP = "Zwischen ihnen wechseln"
L.GATHERINGTRACKING_SWAP_DESC = "Wechselt zwischen den gewählten Sucharten, solange eine davon aktiv "
    .. "ist. Im Kampf, beim Zaubern und während eines Flugs findet kein Wechsel statt."
L.GATHERINGTRACKING_SWAP_EVERY_NAME = "Wechselintervall"
L.GATHERINGTRACKING_SWAP_EVERY_DESC = "Wie lange zwischen zwei Wechseln gewartet wird."
L.GATHERINGTRACKING_MUTE_SWAP = "Wechselgeräusch stumm"
L.GATHERINGTRACKING_MUTE_SWAP_DESC = "Schaltet die Soundeffekte des Spiels für den Moment jedes Wechsels "
    .. "aus, damit der Aufspürzauber still ist. Ein Sound, der genau dann spielt, kann abbrechen."
L.GATHERINGTRACKING_ANNOUNCE = "Wiedereinschalten melden"
L.GATHERINGTRACKING_ANNOUNCE_DESC = "Meldet im Chat, wenn das Aufspüren für Euch wieder eingeschaltet "
    .. "wurde, sobald das Spiel es als an zeigt. Nützlich bei ausgeblendetem Aufspür-Buff."
L.GATHERINGTRACKING_ANNOUNCED = "%s ist wieder an." -- a tracking spell's name
L.GATHERINGTRACKING_CHAT = "Warnmeldungen"
L.GATHERINGTRACKING_CHAT_DESC = "Meldet im Chat, wenn das Spiel Rohstoffsuche daran hindert, das "
    .. "Aufspüren zu ändern."
L.GATHERINGTRACKING_FAILED = "Rohstoffsuche konnte das Aufspüren nicht ändern: %s" -- error
L.GATHERINGTRACKING_BLOCKED = "Das Spiel hat Rohstoffsuche daran gehindert, das Aufspüren zu ändern. "
    .. "Es ruht bis /reload."

-- AutoStow
L.AUTOSTOW_TITLE = "Waffen automatisch wegstecken"
L.AUTOSTOW_DESC = "Steckt Eure Waffen weg, sobald sie außerhalb des Kampfes ein paar Sekunden gezogen "
    .. "waren, ob ein Kampf sie gezogen ließ oder Ihr sie selbst gezogen habt."
L.AUTOSTOW_DELAY = "Verzögerung"
L.AUTOSTOW_DELAY_DESC = "Wie lange Eure Waffen nach dem Kampf oder nach dem Ziehen noch gezogen "
    .. "bleiben, bevor sie weggesteckt werden."
L.AUTOSTOW_OUTSIDE_ONLY = "Nur außerhalb von Instanzen"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "Lässt Eure Waffen in Dungeons, Schlachtzügen und auf Schlachtfeldern "
    .. "gezogen, wo der nächste Kampf nie weit ist."

-- AutoDismount
L.AUTODISMOUNT_TITLE = "Automatisch absitzen"
L.AUTODISMOUNT_DESC = "Steigt vom Reittier ab oder steht auf, wenn etwas fehlschlägt, weil Ihr "
    .. "reitet oder sitzt, etwa ein Zauber, ein Flug beim Flugmeister oder das Plündern."
L.AUTODISMOUNT_DISMOUNT = "Absitzen"
L.AUTODISMOUNT_DISMOUNT_DESC = "Steigt vom Reittier ab, wenn Ihr beim Reiten einen Zauber wirkt, mit "
    .. "einem Flugmeister sprecht oder angreift."
L.AUTODISMOUNT_STAND = "Aufstehen"
L.AUTODISMOUNT_STAND_DESC = "Steht auf, wenn Ihr im Sitzen einen Zauber wirkt, plündert oder angreift."
L.AUTODISMOUNT_UNSHIFT = "Gestalt verlassen"
L.AUTODISMOUNT_UNSHIFT_DESC = "Verlässt eine Gestalt, etwa die Bären- oder Katzengestalt eines Druiden, "
    .. "wenn Ihr einen Zauber wirkt, der darin nicht gewirkt werden kann."

-- MountGear
L.MOUNTGEAR_TITLE = "Reittempo-Ausrüstung"
L.MOUNTGEAR_DESC = "Legt beim Aufsitzen die Ausrüstung aus Euren Taschen an, die Euer Reittier "
    .. "schneller macht, und beim Absitzen wieder Eure eigene. Eure eigene Ausrüstung wird auch über "
    .. "ein Neuladen oder Ausloggen hinweg gemerkt."
L.MOUNTGEAR_NOTICE = "Wartet das Kampfende ab"
L.MOUNTGEAR_NOTICE_DESC = "Im Kampf lässt sich keine Ausrüstung wechseln. Sitzt Ihr in einem Kampf "
    .. "ab, wird Eure eigene Ausrüstung daher nach dem Kampf wieder angelegt. Ein wieder angelegter "
    .. "Schmuck kann 30 Sekunden lang nicht benutzt werden, wie jeder Schmuck, den Ihr anlegt. Nur "
    .. "Ausrüstung, die bereits an Euch gebunden ist, wird angelegt."
L.MOUNTGEAR_TRINKET = "Schmuck"
L.MOUNTGEAR_TRINKET_DESC = "Legt „Karotte am Stiel“ an."
L.MOUNTGEAR_TRINKET_SLOT = "Schmuckplatz"
L.MOUNTGEAR_TRINKET_SLOT_DESC = "Welches Eurer beiden Schmuckstücke „Karotte am Stiel“ ersetzt."
L.MOUNTGEAR_TRINKET_UPPER = "Oben"
L.MOUNTGEAR_TRINKET_LOWER = "Unten"
L.MOUNTGEAR_GLOVES = "Handschuhe"
L.MOUNTGEAR_GLOVES_DESC = "Legt Handschuhe mit „Handschuhe - Reitfertigkeit“ an."
L.MOUNTGEAR_BOOTS = "Stiefel"
L.MOUNTGEAR_BOOTS_DESC = "Legt Stiefel mit „Mithrilsporen“ an."
L.MOUNTGEAR_INSTANCES = "In Dungeons und Schlachtfeldern"
L.MOUNTGEAR_INSTANCES_DESC = "Wechselt die Ausrüstung auch in Dungeons, Schlachtzügen und auf "
    .. "Schlachtfeldern. Aus, bleibt dort Eure eigene Ausrüstung angelegt."
L.MOUNTGEAR_CHAT_DESC = "Nennt im Chat, wenn Eure eigene Ausrüstung nicht wieder angelegt werden konnte."
L.MOUNTGEAR_MISSING = "%s konnte nicht wieder angelegt werden: Es ist nicht in Euren Taschen." -- an item link
L.MOUNTGEAR_BAGS_FULL = "Eure Taschen sind voll, daher bleibt %s angelegt." -- an item link

-- AutoGossip
L.AUTOGOSSIP_TITLE = "Automatischer Dialog"
L.AUTOGOSSIP_DESC = "Hat ein NSC keine Quests und bietet nur eine Dialogoption oder neben dem Plaudern "
    .. "nur einen Dienst an, wählt das Modul die passende Option für Euch. So öffnet sich sofort die "
    .. "Bank, das Händlerfenster, das Lehrerfenster oder die Flugkarte."
L.AUTOGOSSIP_SECTION_GENERAL = "Allgemein"
L.AUTOGOSSIP_SECTION_NPCS = "Wählen für"
L.AUTOGOSSIP_BANKER = "Bankiers"
L.AUTOGOSSIP_BANKER_DESC = "Öffnet die Bank."
L.AUTOGOSSIP_VENDOR = "Händler und Reparaturen"
L.AUTOGOSSIP_VENDOR_DESC = "Öffnet den Laden."
L.AUTOGOSSIP_TRAINER = "Lehrer"
L.AUTOGOSSIP_TRAINER_DESC = "Öffnet die Liste des Lehrers."
L.AUTOGOSSIP_TAXI = "Flugmeister"
L.AUTOGOSSIP_TAXI_DESC = "Öffnet die Flugkarte."
L.AUTOGOSSIP_STABLE = "Stallmeister"
L.AUTOGOSSIP_STABLE_DESC = "Öffnet den Stall."
L.AUTOGOSSIP_OTHER = "Andere NSCs"
L.AUTOGOSSIP_OTHER_DESC = "Wählt die einzige Option jedes anderen NSCs, außer das Spiel bittet Euch, "
    .. "zuerst seinen Text zu lesen."
L.AUTOGOSSIP_KEY_DESC = "Haltet diese Taste, während Ihr mit einem NSC sprecht, um seine Optionen "
    .. "selbst zu wählen."

-- AutoDecline
L.AUTODECLINE_TITLE = "Automatisch ablehnen"
L.AUTODECLINE_DESC = "Lehnt Duellanfragen und auf Wunsch Gruppeneinladungen, Gildeneinladungen und "
    .. "Gildensatzungen gleich bei Eingang ab, damit Euch das Fenster nie im Weg ist."
L.AUTODECLINE_DUELS = "Duelle"
L.AUTODECLINE_DUELS_DESC = "Lehnt Duellanfragen ab."
L.AUTODECLINE_PARTY_INVITES = "Gruppeneinladungen"
L.AUTODECLINE_PARTY_INVITES_DESC = "Lehnt auch Gruppeneinladungen ab."
L.AUTODECLINE_GUILD_INVITES = "Gildeneinladungen"
L.AUTODECLINE_GUILD_INVITES_DESC = "Lehnt auch Gildeneinladungen ab, selbst von Freunden."
L.AUTODECLINE_GUILD_CHARTERS = "Gildensatzungen"
L.AUTODECLINE_GUILD_CHARTERS_DESC = "Lehnt auch Bitten ab, eine Gildensatzung zu unterschreiben, "
    .. "selbst von Freunden. Eure eigene Satzung öffnet sich weiterhin."
L.AUTODECLINE_ALLOW_FRIENDS = "Freunde und Gilde zulassen"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "Lässt Duelle und Gruppeneinladungen von Euren Freunden, "
    .. "Battle.net-Freunden und Gildenmitgliedern durch."
L.AUTODECLINE_CHAT_DESC = "Meldet im Chat, von wem die abgelehnte Duellanfrage, Einladung oder Bitte "
    .. "um eine Unterschrift unter die Gildensatzung kam."
L.AUTODECLINE_DECLINED = "Duell abgelehnt von: %s" -- player name
L.AUTODECLINE_DECLINED_INVITE = "Gruppeneinladung abgelehnt von: %s" -- player name
L.AUTODECLINE_DECLINED_GUILD_INVITE = "Gildeneinladung abgelehnt von: %s" -- player name
L.AUTODECLINE_DECLINED_CHARTER = "Gildensatzung abgelehnt von: %s" -- player name
L.AUTODECLINE_SOMEONE = "Unbekannt"

-- AutoConfirm
L.AUTOCONFIRM_TITLE = "Automatisch bestätigen"
L.AUTOCONFIRM_DESC = "Antwortet mit Ja auf das Fenster, das nachfragt, bevor eine Verzauberung die "
    .. "vorhandene eines Gegenstands ersetzt, damit das Leveln von Verzauberkunst einen Klick pro "
    .. "Verzauberung braucht."
L.AUTOCONFIRM_REPLACE = "Verzauberung ersetzen"
L.AUTOCONFIRM_REPLACE_DESC = "Bestätigt eine Verzauberung, die die vorhandene des Gegenstands ersetzt."
L.AUTOCONFIRM_BIND = "Gegenstand binden"
L.AUTOCONFIRM_BIND_DESC = "Bestätigt eine Verzauberung, die den Gegenstand an Euch bindet. Danach "
    .. "kann er weder gehandelt noch im Auktionshaus verkauft werden."
L.AUTOCONFIRM_TRADEBIND = "Binden beim Handel"
L.AUTOCONFIRM_TRADEBIND_DESC = "Schließt die Warnung, dass eine im Handelsfenster gewirkte "
    .. "Verzauberung den Gegenstand binden kann, damit der Handel weitergehen kann."

-- AutoRelease
L.AUTORELEASE_TITLE = "Geist automatisch freilassen"
L.AUTORELEASE_DESC = "Lässt Euren Geist frei, wenn Ihr auf einem Schlachtfeld sterbt, außer Ihr könnt "
    .. "Euch selbst wiederbeleben oder jemand belebt Euch gerade wieder."
L.AUTORELEASE_DELAY = "Verzögerung"
L.AUTORELEASE_DELAY_DESC = "Wie lange nach dem Tod gewartet wird, bevor der Geist freigelassen wird."
L.AUTORELEASE_NOW = "Sofort"
L.AUTORELEASE_KEY_DESC = "Haltet diese Taste, während Ihr tot seid, um liegen zu bleiben."
L.AUTORELEASE_CHAT_DESC = "Meldet im Chat, wenn Euer Geist freigelassen wurde oder warum nicht."
L.AUTORELEASE_RELEASED = "Geist freigelassen."
L.AUTORELEASE_SELF_RES = "Nicht freigelassen: Ihr könnt Euch selbst wiederbeleben."
L.AUTORELEASE_RES_OFFER = "Nicht freigelassen: Jemand belebt Euch gerade wieder."

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "Videosequenzen überspringen"
L.SKIPCINEMATICS_DESC = "Überspringt die Videosequenzen und Filme des Spiels, alle oder nur die "
    .. "bereits gesehenen."
L.SKIPCINEMATICS_SKIP = "Überspringen"
L.SKIPCINEMATICS_SKIP_DESC = "Welche Videosequenzen und Filme übersprungen werden. Gesehene zählen über "
    .. "alle Eure Charaktere."
L.SKIPCINEMATICS_SKIP_SEEN = "Nur gesehene"
L.SKIPCINEMATICS_SKIP_ALL = "Alle"
L.SKIPCINEMATICS_KEY = "Taste zum Ansehen"
L.SKIPCINEMATICS_KEY_DESC = "Haltet diese Taste beim Start einer Videosequenz oder eines Films "
    .. "gedrückt, damit die Wiedergabe weiterläuft."
L.SKIPCINEMATICS_CHAT_DESC = "Meldet im Chat, wenn eine Videosequenz oder ein Film übersprungen wird."
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "Videosequenz übersprungen."
L.SKIPCINEMATICS_SKIPPED_MOVIE = "Film übersprungen."
L.SKIPCINEMATICS_RESET = "Gesehene Videosequenzen"
L.SKIPCINEMATICS_RESET_BUTTON = "Löschen"
L.SKIPCINEMATICS_RESET_DESC = "Vergisst, welche Videosequenzen und Filme Ihr gesehen habt, damit jede "
    .. "noch einmal läuft."
L.SKIPCINEMATICS_RESET_CONFIRM = "Vergessen, welche Videosequenzen und Filme Ihr gesehen habt?"
L.SKIPCINEMATICS_RESET_DONE = "Gesehene Videosequenzen gelöscht."


-- FishingCast
L.FISHINGCAST_TITLE = "Angeln per Doppelklick"
L.FISHINGCAST_DESC = "Doppelter Rechtsklick in die Welt mit angelegter Angelrute wirkt „Angeln“."
L.FISHINGCAST_SPEED = "Doppelklick-Intervall"
L.FISHINGCAST_SPEED_DESC = "Wie schnell der zweite Rechtsklick auf den ersten folgen muss."
L.FISHINGCAST_MS = "%d ms" -- milliseconds
L.FISHINGCAST_COMBAT = "Kampfwarnung"
L.FISHINGCAST_COMBAT_DESC = "Warnt einmal, wenn ein Kampf beginnt, während eine Angelrute angelegt ist."
L.FISHINGCAST_COMBAT_TEXT = "Ihr habt eine Angelrute angelegt."
L.FISHINGCAST_LOUDER = "Lauterer Schwimmer"
L.FISHINGCAST_LOUDER_DESC = "Dreht beim Angeln die Soundeffekte lauter und die Musik leiser, damit "
    .. "das Platschen gut zu hören ist. Eure eigenen Lautstärken kehren zurück, wenn Ihr aufhört."


-- AutoWeaponBuff
L.AUTOWEAPONBUFF_TITLE = "Automatische Waffenbuffs"
L.AUTOWEAPONBUFF_DESC = "Rechtsklickt einen Wetzstein, Gewichtsstein, ein Öl, Gift oder einen Köder "
    .. "in Euren Taschen oder benutzt ihn von einer Aktionsleiste, um ihn direkt auf Eure Waffe zu "
    .. "bringen: auf die Waffenhand oder auf die Schildhand, wenn er nur dort passt."
L.AUTOWEAPONBUFF_NOTICE = "Funktioniert nur außerhalb des Kampfes." -- a gray row atop the module
L.AUTOWEAPONBUFF_NOTICE_DESC = "Das Spiel lässt Addons im Kampf nicht ändern, was ein Klick in "
    .. "Taschen oder Aktionsleisten tut, daher wirken sie bis zum Kampfende wie bei Blizzard."
L.AUTOWEAPONBUFF_WARN = "Warnen, wenn keine Waffe passt"
L.AUTOWEAPONBUFF_WARN_DESC = "Kann keine angelegte Waffe den Gegenstand aufnehmen, etwa ein "
    .. "Gewichtsstein bei reinen Klingen, steht das rot oben im Bild, statt dass ein Zeiger erscheint."
L.AUTOWEAPONBUFF_WARN_TEXT = "%s lässt sich auf keine angelegte Waffe anwenden." -- item name
L.AUTOWEAPONBUFF_WARN_TEXT_ANY = "Das lässt sich auf keine angelegte Waffe anwenden."
L.AUTOWEAPONBUFF_LEARNED_LINE = "Waffenbuff gelernt: %s gehört auf: %s" -- item name, weapon type

-- ComprehendScrolls
L.COMPREHENDSCROLLS_TITLE = "Schriftrollen verstehen"
L.COMPREHENDSCROLLS_DESC = "Rechtsklickt eine Magierschriftrolle in Euren Taschen, um „Schriftrolle "
    .. "verstehen“ darauf zu wirken, ohne vorher das Zauberbuch zu öffnen."
L.COMPREHENDSCROLLS_NOTICE = "Funktioniert nur außerhalb des Kampfes." -- a gray row atop the module
L.COMPREHENDSCROLLS_NOTICE_DESC = "Das Spiel lässt Addons im Kampf nicht ändern, was ein Klick in "
    .. "Taschen tut, daher wirkt ein Rechtsklick bis zum Kampfende wie bei Blizzard."

-- AutoScreenshot
L.AUTOSCREENSHOT_TITLE = "Automatische Screenshots"
L.AUTOSCREENSHOT_DESC = "Macht einen Screenshot, wenn Ihr aufsteigt, einen Erfolg erringt oder einen "
    .. "Boss besiegt, und in anderen Momenten, die es wert sind."
L.AUTOSCREENSHOT_SECTION_GENERAL = "Allgemein"
L.AUTOSCREENSHOT_SECTION_EVENTS = "Screenshot machen bei"
L.AUTOSCREENSHOT_HIDE_UI = "Interface verbergen"
L.AUTOSCREENSHOT_HIDE_UI_DESC = "Verbirgt das Interface für den Screenshot, wie Alt+Z. Nicht im Kampf, "
    .. "wo das Spiel es nicht erlaubt."
L.AUTOSCREENSHOT_HIDE_OWN = "Eigene Screenshots"
L.AUTOSCREENSHOT_HIDE_OWN_DESC = "Verbirgt das Interface auch bei Screenshots, die Ihr mit der "
    .. "Screenshot-Taste (Druck) macht, selbst wenn alle Momente unten aus sind. Nicht im Kampf."
L.AUTOSCREENSHOT_NO_HDR = "HDR für die Aufnahme aus"
L.AUTOSCREENSHOT_NO_HDR_DESC = "Mit HDR wirken Screenshots blass. Dies schaltet HDR für den Moment der "
    .. "Aufnahme aus und danach wieder ein. Ohne HDR bewirkt es nichts. Nicht im Kampf."
L.AUTOSCREENSHOT_CHAT_DESC = "Nennt im Chat, warum ein Screenshot gemacht wurde."
L.AUTOSCREENSHOT_PLAYED_TIME = "Spielzeit beim Aufstieg"
L.AUTOSCREENSHOT_PLAYED_TIME_DESC = "Zeigt beim Aufsteigen Eure Spielzeit (/played) im Chat, damit sie "
    .. "auf dem Screenshot ist."
L.AUTOSCREENSHOT_TAKEN = "Screenshot gemacht: %s." -- the checkbox's name, such as Level Up
L.AUTOSCREENSHOT_LEVEL_UP = "Aufsteigen"
L.AUTOSCREENSHOT_LEVEL_UP_DESC = "Wenn Ihr eine neue Stufe erreicht."
L.AUTOSCREENSHOT_ACHIEVEMENT = "Erfolg"
L.AUTOSCREENSHOT_ACHIEVEMENT_DESC = "Wenn Ihr einen Erfolg erringt, den Ihr nicht schon auf einem "
    .. "anderen Charakter habt."
L.AUTOSCREENSHOT_LOOT = "Beute"
L.AUTOSCREENSHOT_LOOT_DESC = "Wenn Ihr einen Gegenstand erhaltet, der mindestens die unten gewählte "
    .. "Qualität hat."
L.AUTOSCREENSHOT_LOOT_QUALITY = "Beutequalität"
L.AUTOSCREENSHOT_LOOT_QUALITY_DESC = "Die niedrigste Gegenstandsqualität, die einen Screenshot auslöst."
L.AUTOSCREENSHOT_BOSS_KILL = "Bosssieg"
L.AUTOSCREENSHOT_BOSS_KILL_DESC = "Wenn Eure Gruppe einen Dungeon- oder Schlachtzugsboss besiegt."
L.AUTOSCREENSHOT_REPUTATION_DESC = "Wenn Ihr bei einer Fraktion „Freundlich“, „Wohlwollend“, "
    .. "„Respektvoll“ oder „Ehrfürchtig“ erreicht."
L.AUTOSCREENSHOT_PVP_RANK = "PvP-Rang"
L.AUTOSCREENSHOT_PVP_RANK_DESC = "Wenn Ihr einen neuen PvP-Rang erreicht."
L.AUTOSCREENSHOT_NEW_TITLE = "Neuer Titel"
L.AUTOSCREENSHOT_NEW_TITLE_DESC = "Wenn Ihr einen neuen Titel erringt."
L.AUTOSCREENSHOT_BATTLEGROUND = "Schlachtfeldende"
L.AUTOSCREENSHOT_BATTLEGROUND_DESC = "Beim Ende des Schlachtfelds, sobald die Punkteübersicht angezeigt wird."
L.AUTOSCREENSHOT_DEATH = "Tod"
L.AUTOSCREENSHOT_DEATH_DESC = "Wenn Ihr sterbt."
