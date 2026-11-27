local _, ns = ...
local L = ns.NewLocale("deDE")
if not L then
    return
end

-- Lib/Text.lua: lengths of time, for slider labels and price lines
L.TEXT_SECONDS = { "%d Sekunde", "%d Sekunden" }
L.TEXT_MINUTES = { "%d Minute", "%d Minuten" }
L.TEXT_HOURS = { "%d Stunde", "%d Stunden" }
L.TEXT_AGO_NOW = "gerade eben"
L.TEXT_AGO_MINUTES = "vor %d Min." -- minutes
L.TEXT_AGO_HOURS = "vor %d Std." -- hours
L.TEXT_AGO_DAYS = "vor %d T." -- days
L.TEXT_YARDS = "%s m" -- a distance; the game's own words are used when it has them
L.SLIDER_YARDS = "%d m" -- a slider's value in yards, worded like TEXT_YARDS

-- Lib/ItemStats.lua: an Equip: bonus written as a plain stat, an amount and the stat's name
L.ITEMSTATS_SHORT = "+%s %s"
L.ITEMSTATS_SHORT_PERCENT = "+%s%% %s"
L.ITEMSTATS_SHORT_AND = "%s und %s" -- two short stats of one line

-- Lib/Fonts.lua: the game's fonts, in every font dropdown
L.FONT_FRIZQT = "Friz Quadrata"
L.FONT_ARIALN = "Arial Narrow"
L.FONT_SKURRI = "Skurri"
L.FONT_MORPHEUS = "Morpheus"

-- Lib/Frames.lua: our windows' titles
L.FRAMES_WINDOW_TITLE = "%s %s" -- the addon's name (in gray), the window's title

-- Lib/Keys.lua: modifier keys, in every key dropdown
L.KEY_SHIFT = "Umschalt"
L.KEY_CTRL = "Strg"
L.KEY_ALT = "Alt"
L.KEY_NONE = "Keine"
-- Added to a key dropdown's description with the controller interface on; each %s is a trigger
-- as the player's controller shows it
L.KEY_PAD_NOTE = "Mit der Controller-Oberfläche haltet Ihr stattdessen %s oder %s gedrückt."
L.SKIP_KEY = "Taste zum Überspringen" -- the option of every module that a held key skips

-- Lib/MapPins.lua: icons on the world map.
-- Click hints are written as Blizzard's instruction lines are: in angle brackets, the keys and the
-- click as separate words with no hyphen or plus, no full stop. One click to a line.
L.MAPPINS_HINT_WAYPOINT = "<Strg-Klick, um eine Kartenmarkierung zu setzen>"
-- The options of icons on the world map: their size, opacity, and whether continent maps show
-- them, the same in every module that has them.
L.MAPPINS_SIZE = "Symbolgröße"
L.MAPPINS_SIZE_DESC = "Wie groß die Symbole im Vergleich zu ihrer normalen Größe sind."
L.MAPPINS_OPACITY = "Deckkraft"
L.MAPPINS_OPACITY_DESC = "Wie deckend die Symbole sind. Bei niedrigeren Werten scheint die Karte "
    .. "durch."
L.MAPPINS_CONTINENTS = "Auf Kontinentkarten"
L.MAPPINS_CONTINENTS_DESC = "Zeigt sie auch auf den Kontinent- und Weltkarten an, nicht nur auf den "
    .. "Gebietskarten."
-- Lib/Sounds.lua: the alert sounds, in every Sound dropdown
L.SOUND_NAME = "Sound"
L.SOUND_OFF = "Aus"
L.SOUND_BUZZ = "Fehlersummer"
L.SOUND_DENIED = "Abgelehnt"
L.SOUND_HORN = "Kriegshorn"
L.SOUND_BOSS = "Bosswarnung"
L.SOUND_GM = "GM-Hinweis"
L.SOUND_ALARM = "Wecker"
L.SOUND_WHISPER = "Flüstern"

-- Core: /fpp and chat
L.ON = "an"
L.OFF = "aus"
L.MODULE_STATE = "%s ist %s." -- module name, on/off
L.MODULE_ALWAYS_ON = "%s ist ein Werkzeug und immer an." -- module title, such as Self Test
L.NO_MODULE = "Kein Modul mit dem Namen %s"
L.COMMAND_NEEDS_MODULE = "/fpp %s benötigt das Modul „%s“, das auf der Seite „Module“ aus ist." -- command, title
L.SLASH_MODULES = "Module (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "öffnet die Einstellungen"
L.SLASH_LIST = "listet die Module auf und ob sie an sind"
L.SLASH_TOGGLE = "schaltet ein Modul oder eines seiner Kontrollkästchen an oder aus"
L.SLASH_RESET = "alle Einstellungen auf Standard (lädt neu)"
L.RESET_CONFIRM = "Alle Einstellungen von Forever++ auf Standard zurücksetzen und alles Gespeicherte "
    .. "löschen, etwa Auktionspreise und Flugzeiten? Das Interface wird dabei neu geladen."
L.SLASH_OPTIONS = "listet seine Optionen und ihre Werte auf"
L.SLASH_SET = "ändert eine davon (on/off, eine Auswahl oder eine Zahl)"
L.SLASH_TAKEN = "%s gehört schon einem anderen Addon, deshalb überlässt Forever++ es diesem Addon."

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s ist %s. Optionen (/fpp set %s <option> <value>):" -- module, on/off, module
L.OPTIONS_NONE = "keine"
L.OPTIONS_DEBUG = ", Debug"
L.SET_USAGE = "Verwendung: /fpp set <module> <option> [value]"
L.MODULE_STATE_ALLOWED = "%s ist %s (on, off)." -- module name, on/off
L.NO_OPTION = "%s hat keine Option %s. /fpp options %s listet sie auf." -- module, option, module
L.OPTION_STATE = "%s %s ist %s." -- module, option, value
L.OPTION_STATE_ALLOWED = "%s %s ist |cffffd100%s|r (%s)." -- module, option, value, allowed values
L.CHAT_MESSAGES = "Chatnachrichten" -- a module's checkbox for what it says in chat by itself

-- Lib/Profiles.lua: profiles, and /fpp profiles
L.PROFILES_DEFAULT = "Standard" -- the profile everyone starts with, which is always there
L.PROFILES_NAME_EMPTY = "Ein Profil braucht einen Namen."
L.PROFILES_NAME_TAKEN = "Es gibt schon ein Profil mit dem Namen %s." -- name
L.PROFILES_DEFAULT_ALWAYS = "Standard ist immer vorhanden und kann weder umbenannt noch gelöscht "
    .. "werden."
L.SLASH_PROFILE = "listet die Profile auf oder wechselt diesen Charakter zu einem davon"
L.PROFILES_HEADER = "Profile (/fpp profiles <name> zum Wechseln):"
L.PROFILES_CHARACTERS = { "%d Charakter", "%d Charaktere" } -- how many use a profile
L.PROFILES_SWITCHED = "Aktives Profil: %s" -- profile name
L.PROFILES_AFTER_COMBAT = "Wechsel zum Profil %s nach dem Kampf." -- profile name
L.PROFILES_NO_SUCH = "Kein Profil mit dem Namen %s. /fpp profiles listet sie auf." -- what was typed

-- Settings
-- The Modules page's groups of modules.
L.CATEGORY_AUTOMATION = "Automatisierung"
L.CATEGORY_CHARACTER = "Charakter"
L.CATEGORY_CHAT = "Chat"
L.CATEGORY_INTERFACE = "Interface"
L.CATEGORY_ITEMS = "Gegenstände"
L.CATEGORY_MAP = "Karte"
L.CATEGORY_QUESTS = "Quests"
L.CATEGORY_SYSTEM = "System"
L.CATEGORY_UNITS = "Einheiten" -- unit frames and nameplates
L.CATEGORY_OTHER = "Sonstiges"
L.DEBUG = "Debug"
L.SETTINGS_AFTER_COMBAT = "Die Einstellungen öffnen sich nach dem Kampf."
L.MODULES = "Module" -- the page with every module's checkbox, the top Forever++ entry
L.ABOUT = "Über" -- the page with the version, links, credits, and commands
-- The selected module on the Modules page
L.SETTINGS_ENABLED = "Aktiviert" -- the module's own on/off checkbox, under its description
-- What a greyed-out option needs (`needs`), in red in its tooltip: an addon's or module's name
L.SETTINGS_NEEDS_ADDON = "Benötigt das Addon %s."
L.SETTINGS_NEEDS_MODULE = "Benötigt das eingeschaltete Modul „%s“."
L.SETTINGS_NEEDS_CLIENT = "Dieser Version des Spiels fehlt, was dafür nötig ist."
-- A notice on a module whose Blizzard frame the controller interface hides (ns.Gamepad.HidesNotice).
L.SETTINGS_CONTROLLER_HIDDEN = "Wirkungslos mit der Controller-Oberfläche"
L.SETTINGS_CONTROLLER_HIDDEN_DESC = "Die Controller-Oberfläche blendet aus, was dies ändert, und zeigt "
    .. "stattdessen ihr eigenes an. Solange sie an ist, bewirkt dies nichts."
-- And on one that needs a mouse, a held key, or a window its cursor can't reach (LimitedNotice).
L.SETTINGS_CONTROLLER_LIMITED = "Eingeschränkt mit der Controller-Oberfläche"
L.SETTINGS_CONTROLLER_LIMITED_DESC = "Manches oder alles hiervon braucht einen Mausklick, ein Ziehen, "
    .. "eine gehaltene Taste oder ein Fenster, das der Cursor des Controllers nicht erreicht, und "
    .. "bewirkt nichts, solange die Controller-Oberfläche an ist."
-- An option XP Bar Text and Reputation Bar Text share (Lib/StatusBars.lua)
L.STATUSBARS_SOLID = "Durchgehende Leiste"
L.STATUSBARS_SOLID_DESC = "Entfernt die Trennlinien, sodass die Leiste durchgehend ist."
-- The tooltip of the padlock in a locked module's checkbox's place
L.SETTINGS_LOCKED = "Ausgeschaltet und gesperrt: Das Spiel hat beschädigt, was dieses Modul tut. "
    .. "Seine Einstellungen sagen mehr dazu."
L.SETTINGS_OPTIONS = "Optionen" -- the header over its options
L.SETTINGS_NO_OPTIONS = "Dieses Modul hat keine Optionen."
L.SETTINGS_CONFLICT_GO = "Zu: %s" -- an option's name
-- A mark on an item or action button icon (Lib/ItemButtons.lua): its corner, size, and padding,
-- the same in every module that has one.
L.ICONMARK_CORNER = "Ecke"
L.ICONMARK_CORNER_TOPLEFT = "Oben links"
L.ICONMARK_CORNER_TOPRIGHT = "Oben rechts"
L.ICONMARK_CORNER_BOTTOMLEFT = "Unten links"
L.ICONMARK_CORNER_BOTTOMRIGHT = "Unten rechts"
L.ICONMARK_PIXELS = "%d px" -- a size or padding slider's value
L.ICONMARK_PADDING = "Abstand"
L.ICONMARK_PADDING_DESC = "Wie weit die Markierung von ihrer Ecke nach innen rückt: Bei 2 rückt "
    .. "eine Markierung oben links 2 Pixel nach rechts und 2 nach unten."
-- Under a mark's Corner option while Upgrade Arrows has an arrow in the same corner
L.ICONMARK_CONFLICT_ARROW = "Verbesserungspfeile setzt seinen Pfeil ebenfalls in diese Ecke, "
    .. "sodass sich beide überdecken. Wählt für eines davon eine andere Ecke."
L.ICONMARK_CONFLICT_DOWN = "Verbesserungspfeile setzt seinen Abwärtspfeil ebenfalls in diese Ecke, "
    .. "sodass sich beide überdecken. Wählt für eines davon eine andere Ecke."
L.ICONMARK_SECTION_SHOW = "Anzeigen in" -- the header over the places a module marks items in
L.ICONMARK_PLACE_BAGS = "Taschen"
L.ICONMARK_PLACE_MERCHANT = "Händler"
L.ICONMARK_PLACE_AUCTION = "Auktionshaus"
L.ICONMARK_PLACE_LOOT = "Beute"
L.ICONMARK_PLACE_QUESTS = "Questbelohnungen"
L.SETTINGS_PAGE_NOTE = "Solange es an ist, steht seine Seite „%s“ in der Seitenleiste unter "
    .. "Forever++. Die Seite erscheint oder verschwindet, sobald Ihr eine andere Seite wählt."
L.SETTINGS_TURN_ON = "Einschalten" -- the button on a "Blizzard's ... is off" row
L.SETTINGS_RESET = "Auf Standard zurücksetzen" -- the arrow at the end of an option's row while it's changed
L.SETTINGS_RESET_TO = "Standard: %s" -- what the option goes back to
L.SETTINGS_RESET_PAIR = "%s, %s" -- a checkbox's default, then its slider's, in one row
L.SETTINGS_CHECKED = "Angehakt" -- a checkbox's default
L.SETTINGS_UNCHECKED = "Nicht angehakt"
L.SETTINGS_SEARCH = "Module suchen" -- gray text in the Modules page's empty search box
L.SETTINGS_NO_MATCH = "Keine Module passen zu „%s“." -- the search text
L.SETTINGS_NEW_ONLY = "Neu" -- the checkbox beside the search box that lists only modules marked NEW
L.SETTINGS_NOTHING_NEW = "Nichts Neues." -- the Modules list while that checkbox is on and nothing is new
-- The section headers on the Debug module's page and the Debug module's own buttons stay English
-- (an [english] block in enUS).

-- Settings: the Profiles page
L.PROFILES = "Profile"
L.PROFILES_USES = "Profil von %s" -- a character's name, before the dropdown of its profile
L.PROFILES_USES_TITLE = "Profil dieses Charakters"
L.PROFILES_USES_DESC = "Das Profil, das %s verwendet. Was Ihr in Forever++ ändert, wird darin "
    .. "gespeichert, für jeden Charakter, der es verwendet." -- character
L.PROFILES_NEW_CHARACTERS = "Neue Charaktere verwenden"
L.PROFILES_NEW_CHARACTERS_DESC = "Das Profil, mit dem ein Charakter bei seiner ersten Anmeldung "
    .. "beginnt."
L.PROFILES_NEW = "Neues Profil"
L.PROFILES_NEW_DESC = "Erstellt ein Profil: als Kopie des gewählten, aus den Standardwerten oder aus "
    .. "der Vorlage: %s" -- a preset's name, or PRESETS_A_PRESET
L.PROFILES_NEW_ASK = "Benennt das neue Profil."
L.PROFILES_NEW_FROM = "Neues Profil: %s\nAls Kopie von %s, aus den Standardwerten oder aus der "
    .. "Vorlage: %s?" -- new name, selected profile, a preset's name or PRESETS_A_PRESET
L.PROFILES_PRESET = "Basiert auf" -- beside the dropdown of the preset a profile follows
L.PROFILES_PRESET_NONE = "Keiner" -- a profile based on no preset
L.PROFILES_PRESET_DESC = "Die Vorlage, der %s folgt: Was Ihr nicht selbst festgelegt habt, kommt "
    .. "aus der Vorlage und geht mit, wenn spätere Versionen sie ändern, und ein Rückgängig-Pfeil "
    .. "setzt eine Einstellung auf den Wert der Vorlage zurück. Bei einem Wechsel bleibt jede "
    .. "Einstellung, die Ihr gewählt habt. „Keiner“ übernimmt den jetzigen Stand des Profils als "
    .. "Eure eigenen Einstellungen und folgt der Vorlage nicht mehr." -- profile
L.PROFILES_PRESET_AFTER_COMBAT = "Die Grundlage von %s wird nach dem Kampf geändert." -- profile
L.PRESETS_A_PRESET = "eine Vorlage" -- in PROFILES_NEW_DESC and PROFILES_NEW_FROM, with more than one
L.PRESETS_MORE = "Vorlagen ..." -- a popup button that opens a menu of every preset
L.PRESETS_NO_SUCH = "Keine Vorlage mit dem Namen %s." -- what was asked for
L.PRESETS_DEVELOPER_DESC = "Die Standardwerte, dazu die Module und Optionen, die der Entwickler "
    .. "verwendet."
L.PROFILES_COPY_OF = "Kopie von %s" -- a profile
L.PROFILES_FROM_DEFAULTS = "Aus Standardwerten"
L.PROFILES_IN_USE = "Von diesem Charakter verwendet"
L.PROFILES_SUMMARY = "%d Module an, %d Einstellungen gegenüber Standard geändert."
L.PROFILES_USED_BY = "Verwendet von: %s" -- character names
L.PROFILES_UNUSED = "Kein Charakter verwendet es."
L.PROFILES_USE = "Für diesen Charakter"
L.PROFILES_USE_DESC = "Wechselt %s sofort und ohne Neuladen zum Profil %s." -- character, profile
L.PROFILES_RENAME = "Umbenennen"
L.PROFILES_RENAME_DESC = "Gibt %s einen anderen Namen." -- profile
L.PROFILES_RENAME_ASK = "%s umbenennen in:" -- profile
L.PROFILES_DELETE = "Löschen"
L.PROFILES_DELETE_DESC = "Löscht %s. Charaktere, die es verwenden, wechseln zurück zu Standard." -- profile
L.PROFILES_DELETE_ASK = "%s löschen? Charaktere, die es verwenden, wechseln zurück zu Standard." -- profile
L.PROFILES_CHARACTERS_HEADER = "Charaktere"
L.PROFILES_CHARACTER_LINE = "Stufe %d %s" -- level, class
L.PROFILES_THIS_CHARACTER = "dieser Charakter"
L.PROFILES_USES_OTHER = "verwendet %s" -- the profile another character uses
L.PROFILES_CHECK_DESC = "Anhaken, damit %s das Profil %s verwendet." -- character, profile
L.PROFILES_UNCHECK_DESC = "Abwählen, um %s zurück auf Standard zu setzen." -- character
L.PROFILES_ON_DEFAULT_DESC = "Jeder Charakter verwendet ein Profil. Um %s von Standard wegzunehmen, "
    .. "hakt ihn bei einem anderen Profil an." -- character
L.PROFILES_FORGET_HINT = "Rechtsklicken, um diesen Charakter zu vergessen."
L.PROFILES_FORGET_ASK = "%s vergessen? Er verschwindet aus dieser Liste, bis er sich wieder "
    .. "anmeldet." -- character
L.PROFILES_NOTE = "Ein Profil umfasst, welche Module an sind, ihre Einstellungen, wo Ihr die Rahmen "
    .. "von Forever++ im Bearbeitungsmodus und Fenster mit „Bewegliche Fenster“ platziert habt, und "
    .. "die Schnellschalter des Minikartenknopfs. Auktionspreise, Sammelvorkommen, gesehene Spieler "
    .. "und was jeder Charakter für sich behält, etwa Talentpläne, gehören nicht dazu."
L.PROFILES_SHARE = "Teilen"
L.PROFILES_EXPORT = "Exportieren"
L.PROFILES_EXPORT_DESC = "Zeigt %s als eine Textzeile, die Ihr kopieren und jemandem schicken oder "
    .. "als Sicherung behalten könnt." -- profile
L.PROFILES_EXPORT_ASK = "%s als Text. Kopiert es mit Strg+C und schickt es jemandem oder behaltet "
    .. "es als Sicherung." -- profile
L.PROFILES_IMPORT = "Importieren"
L.PROFILES_IMPORT_DESC = "Fügt ein Profil ein, das jemand exportiert hat, als neues Profil oder "
    .. "anstelle von %s." -- profile
L.PROFILES_IMPORT_ASK = "Fügt mit Strg+V ein Profil ein, das jemand exportiert hat."
-- What the pasted text holds: name, Forever++ version, modules on, settings changed
L.PROFILES_IMPORT_FOUND = "%s, erstellt mit Forever++ %s.\n%d Module an, %d Einstellungen "
    .. "gegenüber Standard geändert."
L.PROFILES_IMPORT_NEW = "Als neues importieren"
L.PROFILES_IMPORT_REPLACE = "Ersetzen: %s" -- the selected profile
L.PROFILES_IMPORT_BAD = "Das ist kein Profil von Forever++. Kopiert die ganze Zeile und fügt sie "
    .. "erneut ein."
L.PROFILES_IMPORT_CANT = "Dieser Client kann komprimierte Profile nicht lesen."
L.PROFILES_IMPORT_NEWER = "Dieses Profil stammt aus einer neueren Version von Forever++. "
    .. "Aktualisiert, um es zu importieren."
L.PROFILES_IMPORTED = "Importiertes Profil" -- the name of an import whose own name is empty
L.PROFILES_IMPORT_DONE = "Importiert: %s" -- profile
L.PROFILES_MODULES_NOTE = "Profil: %s" -- beside the Modules page's title, with more than one
L.DEFAULTS_ASK_PROFILE = "Die Einstellungen von Forever++ im Profil %s auf Standard zurücksetzen? "
    .. "Jeder Charakter, der es verwendet, ändert sich mit. Die übrigen Einstellungen des Spiels "
    .. "bleiben, wie sie sind." -- profile

-- Settings: Changelog page. The notes themselves are in Changelog.lua.
L.CHANGELOG = "Änderungen"
L.CHANGELOG_RELEASE = "%s (%s)" -- version, date
L.CHANGELOG_UNRELEASED = "Unveröffentlicht"
L.CHANGELOG_SEARCH = "Änderungen suchen" -- gray text in the Changelog page's empty search box
L.CHANGELOG_BY_MODULE = "Nach Modul" -- checkbox that groups a release's notes under their modules
L.CHANGELOG_GENERAL = "Allgemein" -- heading, with By Module on, for notes about no one module
L.CHANGELOG_NO_MATCH = "Keine Änderungen passen zu „%s“." -- the search text
L.CHANGELOG_CHANGES = { "%d Änderung", "%d Änderungen" } -- how many entries a release has
L.CHANGELOG_ADDED = "Neu"
L.CHANGELOG_CHANGED = "Geändert"
L.CHANGELOG_FIXED = "Behoben"
L.CHANGELOG_REMOVED = "Entfernt"
L.CHANGELOG_CONTROLLER = "Controller-Oberfläche"
L.CHANGELOG_SETTINGS = "Einstellungen"
L.CHANGELOG_COMMANDS = "Befehle"

-- Settings: the About page
L.HOME_TAGLINE = "Kleine Ergänzungen und Änderungen am Standard-Interface für WoW Forever."
L.HOME_DEFAULTS = "Standard"
-- The popup of the Defaults button at the top right of the Modules, Changelog, and About pages
L.DEFAULTS_ASK = "Alle Einstellungen von Forever++ auf Standard zurücksetzen? Das ersetzt Eure "
    .. "jetzigen Einstellungen von Forever++. Die übrigen Einstellungen des Spiels bleiben, wie sie "
    .. "sind."
L.DEFAULTS_DEVELOPER = "Standard des Entwicklers"
L.DEFAULTS_RECOMMENDED = "Empfohlener Standard"
L.HOME_MODULES_ON = "%d von %d Modulen an" -- on, total
L.HOME_GAME_BUILD = "Spiel %s (%s)" -- version, build
L.HOME_LINKS = "Links"
L.HOME_LINK_CURSEFORGE = "CurseForge"
L.HOME_LINK_WAGO = "Wago"
L.HOME_LINK_SOURCE = "Quellcode"
L.HOME_LINK_RELEASES = "Versionen"
L.HOME_LINK_BUG = "Fehler melden"
L.HOME_LINK_REQUEST = "Wunsch"
L.HOME_LINK_HINT = "Klickt auf einen, um seinen Link zu kopieren."
L.HOME_COPY = "Drückt Strg+C, um den Link zu kopieren."
L.HOME_CREDITS = "Mitwirkende"
L.HOME_AUTHOR = "Autor"
L.HOME_EVERYONE = "Alle" -- the last name in the credits: the players
L.HOME_EVERYONE_THANKS = "Danke für die vielen Fehlermeldungen, Wünsche und Rückmeldungen."
L.HOME_WORKS_WITH = "Funktioniert mit"
L.HOME_QUEST_DATA = "Questdaten für %s" -- the modules that read QuestieDB
L.HOME_SUPPORT = "Zusätzliche Unterstützung in %s" -- the module or option another addon adds to
L.HOME_COMMANDS = "Befehle"
L.HOME_COMMANDS_GENERAL = "Allgemein" -- the commands no one module owns
L.HOME_COMMANDS_SEARCH = "Suchen"
L.HOME_COMMANDS_HINT = "<Klicken, um einen Befehl in den Chat zu schreiben>"

-- Edit Mode dialog for our own frames (Lib/EditMode.lua)
L.EDITMODE_SCALE = "Skalierung"
L.SETTINGS_EDIT_MODE_NOTE = "Wo es sitzt und wie es aufgebaut ist, steht im Bearbeitungsmodus: "
    .. "Drückt Esc, wählt „Bearbeitungsmodus“ und klickt es dann an." -- a gray row on a module with Edit Mode settings
L.SETTINGS_EDIT_MODE_NOTE_DESC = "Seine Position, Skalierung und Anordnung stehen in seinem Dialog im "
    .. "Bearbeitungsmodus und dort in seinem Rechtsklickmenü, neben dem Rahmen, den sie ändern."

-- The gray row on a module another addon adds (Lib/Plugins.lua)
L.PLUGIN_NOTICE = "Von einem anderen Addon hinzugefügt."
L.PLUGIN_NOTICE_ADDON = "Vom Addon %s hinzugefügt." -- the addon's folder name
L.PLUGIN_NOTICE_DESC = "Dieses Modul gehört nicht zu Forever++: Ein anderes Addon fügt es hier "
    .. "hinzu. Meldet Probleme damit dem Autor jenes Addons."
-- Gray rows on a module that reads the QuestieDB addon's data (Lib/QuestieDB.lua)
L.QUESTIEDB_NEEDED = "Benötigt das Addon QuestieDB."
L.QUESTIEDB_NEEDED_DESC = "Seine Daten zu Quests, Kreaturen, Gegenständen und Objekten kommen aus "
    .. "QuestieDB, einem eigenen Addon. Ladet es herunter, installiert es, schaltet es in der "
    .. "Addon-Liste ein und ladet neu. Bis dahin lässt sich dieses Modul nicht einschalten."
L.QUESTIEDB_LOCKED = "Gesperrt: Dieses Modul benötigt das Addon QuestieDB. Ladet es herunter und "
    .. "ladet neu."
L.QUESTIEDB_PROBLEM = "Diese Version von QuestieDB passt nicht zu Forever++."
L.QUESTIEDB_PROBLEM_DESC = "QuestieDB ist an, antwortet aber nicht so, wie Forever++ es liest. "
    .. "Aktualisiert das ältere der beiden."
