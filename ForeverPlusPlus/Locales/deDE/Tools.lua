local _, ns = ...
local L = ns.NewLocale("deDE")
if not L then
    return
end

-- ConsoleVariables
L.CONSOLEVARIABLES_TITLE = "Konsolenvariablen"
-- Debug (its title, L.DEBUG, is in Core.lua)
L.DEBUG_DESC = "Zeigt die Debug-Optionen jedes Moduls und die Testwerkzeuge (Selbsttest, "
    .. "Ausrüstungsprüfung, Screenshots) auf einer Seite „Debug“ in der Seitenleiste der Einstellungen und schaltet ihre "
    .. "Befehle ein."
L.DEBUG_NOTICE = "Das Ausschalten von Debug setzt jede Debug-Option auf Standard zurück." -- a gray row atop the module
L.DEBUG_NOTICE_DESC = "Damit nichts, was hier eingestellt ist, unbemerkt weiterwirkt."
-- ConsoleVariables
L.CONSOLEVARIABLES_DESC = "Durchsucht die Konsolenvariablen (CVars) des Spiels auf einer Seite in den "
    .. "Einstellungen, ändert sie und sperrt die, die Ihr behalten wollt, auch solche, die das Spiel "
    .. "bei jedem Einloggen zurücksetzt."
L.CONSOLEVARIABLES_CHAT_DESC = "Meldet im Chat, wenn eine gesperrte Konsolenvariable ihren Wert nicht "
    .. "halten kann."
-- A gray row atop the module while it's off with console variables locked
L.CONSOLEVARIABLES_LOCKS_OFF = "Gesperrte Konsolenvariablen werden nicht gehalten, solange dies aus ist."
L.CONSOLEVARIABLES_LOCKS_OFF_DESC = "Sie kehren zu dem zurück, was das Spiel setzt, bis es wieder an ist."
L.CONSOLEVARIABLES_COMMAND = "öffnet Konsolenvariablen, mit Suche nach [search]"
L.CONSOLEVARIABLES_NO_PAGE = "Die Einstellungen dieses Clients können die Seite „Konsolenvariablen“ "
    .. "nicht öffnen."
L.CONSOLEVARIABLES_AFTER_COMBAT = "%s ändert sich nach dem Kampf." -- CVar name
L.CONSOLEVARIABLES_REFUSED = "%s kann nicht geändert werden." -- CVar name
L.CONSOLEVARIABLES_KEPT = "%s behält %s: Das Spiel hat %s nicht angenommen." -- CVar name, its value, the typed one
L.CONSOLEVARIABLES_SEARCH = "Konsolenvariablen suchen" -- gray text in the empty search box
L.CONSOLEVARIABLES_POPULAR = "Beliebt" -- the group of CVars players most often look for
L.CONSOLEVARIABLES_FAVORITES = "Favoriten" -- the group of CVars the player starred
L.CONSOLEVARIABLES_LOCKED = "Gesperrt" -- the group of CVars the player locked at a value
L.CONSOLEVARIABLES_CHANGED = "Geändert" -- the group of CVars not at their default
L.CONSOLEVARIABLES_ALL = "Alle"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CONSOLEVARIABLES_CATEGORY_GRAPHICS = "Grafik"
L.CONSOLEVARIABLES_CATEGORY_CONSOLE = "Konsole"
L.CONSOLEVARIABLES_CATEGORY_COMBAT = "Kampf"
L.CONSOLEVARIABLES_CATEGORY_GAME = "Spiel"
L.CONSOLEVARIABLES_CATEGORY_DEFAULT = "Allgemein" -- Default
L.CONSOLEVARIABLES_CATEGORY_NET = "Netzwerk"
L.CONSOLEVARIABLES_CATEGORY_SOUND = "Sound"
L.CONSOLEVARIABLES_CATEGORY_GM = "Spielleiter" -- Gm
L.CONSOLEVARIABLES_CATEGORY_REVEAL = "Aufgedeckt" -- Reveal
L.CONSOLEVARIABLES_CATEGORY_NONE = "Sonstiges" -- None
L.CONSOLEVARIABLES_NO_MATCH = "Keine Konsolenvariablen passen zu „%s“." -- the search text
L.CONSOLEVARIABLES_NONE_CHANGED = "Jede Konsolenvariable steht auf Standard."
L.CONSOLEVARIABLES_NO_FAVORITES = "Klickt auf den Stern einer Konsolenvariable, um sie hier zu behalten."
L.CONSOLEVARIABLES_NO_LIST = "Dieser Client listet seine Konsolenvariablen nicht auf. Sucht nach dem "
    .. "vollen Namen einer Variable, um sie zu finden."
L.CONSOLEVARIABLES_DEFAULT = "Standard"
L.CONSOLEVARIABLES_VALUE_IS = "Wert: %s"
L.CONSOLEVARIABLES_DEFAULT_IS = "Standard: %s"
L.CONSOLEVARIABLES_ON_OFF = "0 ist meist aus, 1 meist an."
L.CONSOLEVARIABLES_ON_OFF_HINT = "0 ist meist aus und 1 an. Passt das nicht, nimmt sie andere Werte an: "
    .. "Schlagt sie nach."
L.CONSOLEVARIABLES_ACCOUNT = "Für Euren Account gespeichert."
L.CONSOLEVARIABLES_CHARACTER = "Für diesen Charakter gespeichert."
L.CONSOLEVARIABLES_READ_ONLY = "Kann nicht geändert werden."
L.CONSOLEVARIABLES_SECURE = "Geschützt: Änderungen warten bis zum Kampfende."
L.CONSOLEVARIABLES_NO_LOCKS = "Klickt auf das Schloss einer Konsolenvariable, um ihren Wert über jedes "
    .. "Einloggen und jede Änderung hinweg zu behalten."
-- Locks: a locked CVar is put back to its value at login and whenever something changes it.
L.CONSOLEVARIABLES_LOCKED_AT = "Gesperrt auf %s: wird bei jedem Einloggen und bei jeder Änderung "
    .. "zurückgesetzt." -- the locked value
L.CONSOLEVARIABLES_LOCK_HINT = "<Auf das Schloss klicken, um diesen Wert zu behalten>" -- tooltip of an open lock
L.CONSOLEVARIABLES_UNLOCK_HINT = "<Auf das Schloss klicken, um ihn nicht mehr zu behalten>" -- tooltip of a closed lock
L.CONSOLEVARIABLES_LOCK_STOPPED = "Bis zum Neuladen oder nächsten Einloggen nicht gehalten: Er hielt "
    .. "nicht."
L.CONSOLEVARIABLES_LOCK_FAILED = "%s konnte nicht auf den gesperrten Wert %s zurückgesetzt werden (er "
    .. "ist %s). Die Sperre wartet bis zum Neuladen oder nächsten Einloggen." -- CVar name, the locked value, its value now
L.CONSOLEVARIABLES_LOCK_FIGHT = "%s wird ständig von etwas anderem geändert. Die Sperre wartet bis zum "
    .. "Neuladen oder nächsten Einloggen." -- CVar name
-- Popular: the section headers, then each CVar's plain name and what it does.
L.CONSOLEVARIABLES_POP_CAMERA = "Kamera"
L.CONSOLEVARIABLES_POP_EFFECTS = "Bildschirmeffekte"
L.CONSOLEVARIABLES_POP_NAMEPLATES = "Namensplaketten"
L.CONSOLEVARIABLES_POP_MAP = "Karte"
L.CONSOLEVARIABLES_POP_CHAT = "Chat"
L.CONSOLEVARIABLES_POP_COMBAT = "Kampf"
L.CONSOLEVARIABLES_POP_INTERFACE = "Interface"
L.CONSOLEVARIABLES_POP_GRAPHICS = "Grafik"
L.CONSOLEVARIABLES_POP_SCREENSHOTS = "Screenshots"
L.CONSOLEVARIABLES_POP_MOUSE = "Maus"
L.CONSOLEVARIABLES_POP_ZOOM_DESC = "Wie weit Ihr herauszoomen könnt. Die Optionen enden bei 2.0; dies "
    .. "kann weiter gehen."
L.CONSOLEVARIABLES_POP_ZOOM_SPEED = "Zoomgeschwindigkeit"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED_DESC = "Wie schnell das Mausrad die Kamera zoomt. Standard 20, bis 50."
L.CONSOLEVARIABLES_POP_COLLISION = "Kamerakollision"
L.CONSOLEVARIABLES_POP_COLLISION_DESC = "1 lässt Bäume und Wände zwischen Euch und die Kamera, bevor sie "
    .. "näher springt; 0 springt sofort."
L.CONSOLEVARIABLES_POP_GLOW = "Bildschirmglühen"
L.CONSOLEVARIABLES_POP_GLOW_DESC = "Das weiche Glühen über dem ganzen Bild. 0 schaltet es für ein "
    .. "schärferes Bild aus."
L.CONSOLEVARIABLES_POP_DEATH_DESC = "Die graue Unschärfe, solange Ihr tot seid. 0 schaltet sie aus."
L.CONSOLEVARIABLES_POP_PLATE_RANGE = "Reichweite der Namensplaketten"
L.CONSOLEVARIABLES_POP_PLATE_RANGE_DESC = "Wie weit entfernt Namensplaketten erscheinen, in Metern. "
    .. "Standard 45. Für diesen Charakter gespeichert."
L.CONSOLEVARIABLES_POP_PLATE_SPACING = "Abstand der Namensplaketten"
L.CONSOLEVARIABLES_POP_PLATE_SPACING_DESC = "Wie weit gestapelte Namensplaketten auseinander sitzen. "
    .. "Niedriger rückt sie enger. Standard 1.1."
L.CONSOLEVARIABLES_POP_PLATE_FAR = "Deckkraft ferner Plaketten"
L.CONSOLEVARIABLES_POP_PLATE_FAR_DESC = "Wie blass ferne Namensplaketten sind, 0 bis 1. Standard 0.6; 1 "
    .. "verblasst nie."
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN = "Deckkraft verdeckter Einheiten"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN_DESC = "Wie blass die Namensplaketten von Einheiten hinter Wänden "
    .. "sind, 0 bis 1. Standard 0.4."
L.CONSOLEVARIABLES_POP_PLATE_TARGET = "Größe der Zielplakette"
L.CONSOLEVARIABLES_POP_PLATE_TARGET_DESC = "Wie viel größer die Namensplakette Eures Ziels ist. Standard "
    .. "1.2; 1 ist gleich groß."
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED = "Größe vereinfachter Plaketten"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED_DESC = "Wie groß vereinfachte Namensplaketten sind. Standard 0.3. "
    .. "Das Spiel kann sie beim Einloggen auf Standard zurücksetzen, sperrt sie also, um Euren Wert "
    .. "zu behalten."
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS = "Plaketten gegnerischer Totems"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS_DESC = "1 zeigt Namensplaketten auf gegnerischen Totems, damit Ihr "
    .. "sie findet und anvisieren könnt."
L.CONSOLEVARIABLES_POP_PLATE_PETS = "Plaketten gegnerischer Begleiter"
L.CONSOLEVARIABLES_POP_PLATE_PETS_DESC = "1 zeigt Namensplaketten auf den Begleitern gegnerischer "
    .. "Spieler."
L.CONSOLEVARIABLES_POP_COMBO = "Position der Combopunkte"
L.CONSOLEVARIABLES_POP_COMBO_DESC = "Wo Combopunkte erscheinen: 1 am Fenster Eures Ziels, 2 an Eurem."
L.CONSOLEVARIABLES_POP_FOG_END = "Nebelentfernung"
-- [quotes: FARCLIP]
L.CONSOLEVARIABLES_POP_FOG_END_DESC = "Wie weit entfernt der Distanznebel am dichtesten ist. Standard "
    .. "1600; erhöht ihn zusammen mit der „Sichtweite“."
L.CONSOLEVARIABLES_POP_FOG_START = "Nebelbeginn"
L.CONSOLEVARIABLES_POP_FOG_START_DESC = "Wie weit entfernt der Distanznebel beginnt. Standard 800."
L.CONSOLEVARIABLES_POP_GRASS = "Grasdichte"
L.CONSOLEVARIABLES_POP_GRASS_DESC = "Wie dicht Gras und Bodenbewuchs sind. Standard 16; höher kostet "
    .. "Bildrate."
L.CONSOLEVARIABLES_POP_GRASS_DIST = "Grasentfernung"
L.CONSOLEVARIABLES_POP_GRASS_DIST_DESC = "Wie weit entfernt Gras gezeichnet wird. Standard 70."
L.CONSOLEVARIABLES_POP_ROTATE_DESC = "1 dreht die Minikarte mit Euch, sodass oben Eure Blickrichtung ist."
L.CONSOLEVARIABLES_POP_MAP_FADE = "Weltkarte verblassen"
L.CONSOLEVARIABLES_POP_MAP_FADE_DESC = "1 blendet die Weltkarte beim Bewegen ab. 0 hält sie deckend."
L.CONSOLEVARIABLES_POP_CHAT_SCROLL = "Mausrad im Chat"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL_DESC = "1 scrollt den Chat mit dem Mausrad."
L.CONSOLEVARIABLES_POP_LOOT_SPAM = "Alle Beutewürfe"
L.CONSOLEVARIABLES_POP_LOOT_SPAM_DESC = "1 zeigt den Wurf jedes Spielers im Chat; 0 nur den Gewinner."
L.CONSOLEVARIABLES_POP_QUEUE = "Zauberwarteschlange"
L.CONSOLEVARIABLES_POP_QUEUE_DESC = "Wie früh Ihr den nächsten Zauber einreihen könnt, in "
    .. "Millisekunden, 0 bis 400. Standard 400."
L.CONSOLEVARIABLES_POP_STOP_ATTACK = "Angriff bei Zielwechsel stoppen"
L.CONSOLEVARIABLES_POP_STOP_ATTACK_DESC = "1 stoppt Euren automatischen Angriff, wenn Ihr das Ziel "
    .. "wechselt."
L.CONSOLEVARIABLES_POP_TEXT_SIZE = "Größe des Kampftexts"
L.CONSOLEVARIABLES_POP_TEXT_SIZE_DESC = "Wie groß die schwebenden Kampfzahlen sind. Standard 1."
L.CONSOLEVARIABLES_POP_ERRORS = "Lua-Fehler anzeigen"
L.CONSOLEVARIABLES_POP_ERRORS_DESC = "1 öffnet das Fenster des Spiels, wenn ein Addon einen Fehler hat."
L.CONSOLEVARIABLES_POP_COMPARE = "Gegenstände immer vergleichen"
L.CONSOLEVARIABLES_POP_COMPARE_DESC = "1 zeigt ohne Umschalttaste neben dem Tooltip eines Gegenstands, "
    .. "was Ihr tragt."
L.CONSOLEVARIABLES_POP_PUSH_SPELLS = "Neue Zauber auf Aktionsleiste"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS_DESC = "1 legt erlernte Zauber von selbst auf Eure Aktionsleisten. Für "
    .. "diesen Charakter gespeichert."
L.CONSOLEVARIABLES_POP_LOOT_RATE = "Tempo von Schnell-Plündern"
L.CONSOLEVARIABLES_POP_LOOT_RATE_DESC = "Millisekunden zwischen den Gegenständen, die Schnell-Plündern "
    .. "nimmt. Niedriger ist schneller. Standard 150."
L.CONSOLEVARIABLES_POP_FARCLIP_DESC = "Wie weit die Welt gezeichnet wird. Standard 1000; höher kostet "
    .. "Bildrate."
L.CONSOLEVARIABLES_POP_WEATHER = "Wetter"
L.CONSOLEVARIABLES_POP_WEATHER_DESC = "Wie viel Regen und Schnee Ihr seht, 0 (keiner) bis 3. Standard 2."
L.CONSOLEVARIABLES_POP_SHOT_QUALITY = "Screenshot-Qualität"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY_DESC = "1 bis 10, höher ist schärfer und größer. Standard 3."
L.CONSOLEVARIABLES_POP_SHOT_FORMAT = "Screenshot-Format"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT_DESC = "jpeg (kleine Dateien), png oder tga (verlustfrei, große "
    .. "Dateien)."
L.CONSOLEVARIABLES_POP_RAW_MOUSE = "Direkte Mauseingabe"
L.CONSOLEVARIABLES_POP_RAW_MOUSE_DESC = "1 liest die Maus direkt, was das Springen des Mauszeigers beim "
    .. "Loslassen der Kamera verhindern kann."

-- SelfTest
L.SELFTEST_TITLE = "Selbsttest"
L.SELFTEST_DESC = "Prüft die Client-APIs, auf die Forever++ angewiesen ist, und speichert ihr "
    .. "Verhalten zur Fehlersuche."

-- Screenshots
L.SCREENSHOTS_TITLE = "Screenshots"
L.SCREENSHOTS_DESC = "Macht nacheinander Screenshots von Forever++ in den Fenstern des Spiels, für "
    .. "seine Seiten und Beiträge."

-- Controller Mode
L.CONTROLLERMODE_TITLE = "Controller-Modus"
L.CONTROLLERMODE_DESC = "Hält eine Einrichtung für die Controller-Oberfläche und eine für Tastatur und "
    .. "Maus: je ein Profil von Forever++, ein Layout des Bearbeitungsmodus und ein Addon-Set. Beim "
    .. "Einloggen mit der anderen Oberfläche wird zu deren Einrichtung gewechselt."
L.CONTROLLERMODE_NOTE = "Wählt, was jede Oberfläche nutzt. Loggt sich dieser Charakter mit der anderen "
    .. "ein, wechselt Forever++ zu deren Profil und Layout und fragt nur dann nach einem Neuladen, wenn "
    .. "die geladenen Addons nicht ihr Set sind. Was Ihr von Hand ändert, bleibt bis zum nächsten "
    .. "Wechsel der Oberfläche. Diese Auswahl gilt für alle Profile, und in einem hier gewählten Profil "
    .. "ist der Controller-Modus eingeschaltet."
L.CONTROLLERMODE_NOW = "Das Spiel zeigt: %s" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_GAMEPAD = "Controller"
L.CONTROLLERMODE_MKB = "Tastatur und Maus"
L.CONTROLLERMODE_NO_CHANGE = "Nicht ändern"
L.CONTROLLERMODE_PROFILE = "Profil von Forever++"
L.CONTROLLERMODE_PROFILE_DESC = "Das Profil, zu dem dieser Charakter mit dieser Oberfläche wechselt."
L.CONTROLLERMODE_LAYOUT = "Bearbeitungsmoduslayout"
L.CONTROLLERMODE_LAYOUT_DESC = "Das Layout des Bearbeitungsmodus für diese Oberfläche. Das Spiel bietet "
    .. "ein Layout nur für die Oberfläche an, für die es erstellt wurde."
L.CONTROLLERMODE_ADDONS_NONE = "Nicht ändern"
L.CONTROLLERMODE_ADDONS_SAVED = "%d Addons an" -- number of addons
L.CONTROLLERMODE_ADDONS_SAVE = "Aktuelle verwenden"
L.CONTROLLERMODE_ADDONS_SAVE_DESC = "Speichert, welche Addons dieser Charakter jetzt an hat, als Set "
    .. "dieser Oberfläche. Ein später installiertes Addon bleibt unberührt, bis Ihr erneut speichert."
L.CONTROLLERMODE_ADDONS_CLEAR = "Löschen"
L.CONTROLLERMODE_ADDONS_CLEAR_DESC = "Vergisst das Set dieser Oberfläche, sodass ihre Addons unberührt "
    .. "bleiben."
L.CONTROLLERMODE_APPLY = "Jetzt einrichten"
L.CONTROLLERMODE_APPLY_DESC = "Wechselt zur Einrichtung der Oberfläche, die das Spiel gerade zeigt."
L.CONTROLLERMODE_NOTHING = "Nichts zu ändern für: %s" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_RELOAD = "Controller-Modus von Forever++: Eure Addons entsprechen nicht dem Set für: "
    .. "%s" -- interface
L.CONTROLLERMODE_RELOAD_ON = "Einschalten: %s" -- addon names
L.CONTROLLERMODE_RELOAD_OFF = "Ausschalten: %s" -- addon names
L.CONTROLLERMODE_RELOAD_ASK = "Ändern und jetzt neu laden?"
L.CONTROLLERMODE_AND_MORE = "%s und %d weitere" -- addon names, number of addons

-- Taint Watcher
L.TAINTWATCHER_TITLE = "Taint-Wächter"
L.TAINTWATCHER_DESC = "Überwacht Questverfolgung, Questlog, Weltkarte und die Fensterliste des Spiels "
    .. "auf Werte, die ein Addon hineingeschrieben hat, was später das Spiel „Interface-Aktion auf "
    .. "Grund eines Addons fehlgeschlagen“ melden lässt. Jeder Fund steht mit Uhrzeit in Fehlerfänger "
    .. "und bei /fpp taint. Zum Finden dessen, was etwas kaputt gemacht hat."
-- Profiler
L.PROFILER_TITLE = "CPU-Profiler"
L.PROFILER_DESC = "Zeigt auf einer Seite in den Einstellungen, wie viel CPU jedes Modul braucht, um zu "
    .. "finden, was langsam ist."

-- Gear Probe
L.GEARPROBE_TITLE = "Ausrüstungsprüfung"
L.GEARPROBE_DESC = "Liest, was dieser Client über Eure Ausrüstung, Talentreiter und Werte sagt, für die "
    .. "Arbeit an Verbesserungspfeile."
