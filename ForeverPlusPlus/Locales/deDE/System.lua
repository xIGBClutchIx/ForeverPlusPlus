local _, ns = ...
local L = ns.NewLocale("deDE")
if not L then
    return
end

-- ErrorCatcher
L.ERRORCATCHER_TITLE = "Fehlerfänger"
L.ERRORCATCHER_DESC = "Fängt Lua-Fehler und blockierte Aktionen still ab, statt sie in Blizzards "
    .. "Fehlerfenster zu zeigen, damit Ihr sie später in einem Fenster lesen und kopieren könnt, mit "
    .. "/fpp errors oder dem Minikartenknopf."
L.ERRORCATCHER_CHAT_DESC = "Meldet im Chat, wenn ein Fehler abgefangen wird."
L.ERRORCATCHER_SOUND_DESC = "Spielt einen Sound ab, wenn ein Fehler abgefangen wird, höchstens alle "
    .. "10 Sekunden. Bei der Auswahl wird er abgespielt."
L.ERRORCATCHER_SHOW = "Fehler"
L.ERRORCATCHER_SHOW_BUTTON = "Anzeigen"
L.ERRORCATCHER_SHOW_DESC = "Öffnet das Fenster mit den bisher abgefangenen Fehlern."
L.ERRORCATCHER_CLEAR = "Löschen"
L.ERRORCATCHER_CLEAR_NAME = "Gespeicherte Fehler"
L.ERRORCATCHER_CLEAR_DESC = "Vergisst jeden gespeicherten Fehler aus allen Sitzungen."
L.ERRORCATCHER_CLEAR_CONFIRM = "Jeden gespeicherten Fehler vergessen?"
L.ERRORCATCHER_COMMAND = "zeigt die abgefangenen Lua-Fehler"
L.ERRORCATCHER_CAUGHT = "Fehler abgefangen: %s Gebt /fpp errors ein, um ihn zu sehen." -- first line of the error
L.ERRORCATCHER_CAUGHT_LOADING = "%d Fehler beim Einloggen abgefangen. Gebt /fpp errors ein, um sie zu "
    .. "sehen."
L.ERRORCATCHER_OTHER_HANDLER = "Ein anderes Addon, etwa BugGrabber, fängt Lua-Fehler ab. Der "
    .. "Fehlerfänger zeigt daher nur blockierte Aktionen und Warnungen an."
L.ERRORCATCHER_OTHER_HANDLER_DESC = "Lua-Fehler gehen stattdessen an jenes Addon, etwa in das Fenster "
    .. "von BugSack. Blizzards Fehlerfenster und sein Fenster für blockierte Aktionen bleiben ihm "
    .. "ebenfalls überlassen."
L.ERRORCATCHER_BLOCKED = "%s: %s versuchte, die geschützte Funktion %s aufzurufen." -- event, addon, function
-- Where: the first few of Blizzard's functions on the stack, such as "SmartNavigation.lua:84 < Menu.lua:2143"
L.ERRORCATCHER_BLOCKED_SILENT = "Das Spiel meldete „Interface-Aktion auf Grund eines Addons "
    .. "fehlgeschlagen“, ohne eines zu nennen, bei %s."
L.ERRORCATCHER_SECRET = "(Das Spiel hat den Text dieses Fehlers verborgen.)"
L.ERRORCATCHER_UNKNOWN = "unbekannt"
L.ERRORCATCHER_THIS_SESSION = "Diese Sitzung"
L.ERRORCATCHER_LAST_SESSION = "Vorige Sitzung"
L.ERRORCATCHER_ALL = "Alle Sitzungen"
L.ERRORCATCHER_FILTER = "%s (%d)" -- a filter above, how many errors it shows
L.ERRORCATCHER_SUMMARY = "%d in dieser Sitzung, %d gespeichert" -- errors this session, errors saved
L.ERRORCATCHER_NONE = "Keine Fehler abgefangen."
L.ERRORCATCHER_KIND_BLOCKED = "Blockierte Aktion"
L.ERRORCATCHER_KIND_TAINT = "Taint"
L.ERRORCATCHER_POSITION = "%d von %d" -- this one, how many
L.ERRORCATCHER_ROW_INFO = "%dx, %s" -- times seen, how long ago ("12m ago")
-- times, session, first and last time it happened, how long ago ("12m ago")
-- The forms go by the times.
L.ERRORCATCHER_META = {
    "%d-mal gesehen in Sitzung %d, zuerst um %s, zuletzt um %s (%s).",
    "%d-mal gesehen in Sitzung %d, zuerst um %s, zuletzt um %s (%s).",
}
L.ERRORCATCHER_STACK = "Stack:"
L.ERRORCATCHER_LOCALS = "Lokale Variablen:"
L.ERRORCATCHER_NO_STACK = "Keine Aufrufliste vorhanden. Blockierte Aktionen und Warnungen liefern keine."
-- What was going on when an action was blocked, in place of a stack.
L.ERRORCATCHER_CONTEXT = "Als es passierte:"
L.ERRORCATCHER_CONTEXT_COMBAT = "Im Kampf: %s"
L.ERRORCATCHER_CONTEXT_INSTANCE = "Instanz: %s" -- none, party, raid, pvp, arena, scenario
L.ERRORCATCHER_CONTEXT_MOUSE = "Maus über: %s" -- a frame's name, such as TargetFrame
L.ERRORCATCHER_CONTEXT_MENUS = "Offene Menüs: %s" -- menu tags, such as MENU_UNIT_TARGET
L.ERRORCATCHER_CONTEXT_GAMEPAD = "Controller-Oberfläche: %s"
L.ERRORCATCHER_CONTEXT_TAINT_LOG = "Taint-Log an: %s"
-- Values in the controller navigation's tables that addon code wrote, each on a line of its own.
L.ERRORCATCHER_CONTEXT_STATE = "Von einem Addon geschriebener Controller-Zustand: %s"
-- The value's name, the addon, the time first seen, and the windows open then.
L.ERRORCATCHER_CONTEXT_STATE_LINE = "  %s von %s, zuerst gesehen %s, offene Fenster: %s"
-- A value's name, and how many more beside it in the same table were written at the same time.
L.ERRORCATCHER_CONTEXT_STATE_MORE = "%s (und %d weitere daneben)"
-- When the watch began: a value first seen at this time was already written before it.
L.ERRORCATCHER_CONTEXT_STATE_SINCE = "  (beobachtet seit %s)"
L.ERRORCATCHER_CONTEXT_YES = "ja"
L.ERRORCATCHER_CONTEXT_NO = "nein"
L.ERRORCATCHER_CONTEXT_NONE = "keine"
L.ERRORCATCHER_TAINT_HINT = "Schaltet „Taint-Log“ in den Einstellungen von Fehlerfänger ein; wenn dies "
    .. "das nächste Mal passiert, schreibt das Spiel nach Logs\\taint.log im Spielordner, welcher "
    .. "Addon-Code es verursacht hat."
L.ERRORCATCHER_TAINT_LOG = "Taint-Log"
L.ERRORCATCHER_TAINT_LOG_DESC = "Eine Einstellung des Spiels selbst: Es schreibt nach Logs\\taint.log "
    .. "im Spielordner, welcher Addon-Code hinter jeder blockierten Aktion steckt. Schaltet es ein, "
    .. "während Ihr einen Fehler sucht, und danach wieder aus, da die Datei schnell wächst."
L.ERRORCATCHER_COPY = "Fehlerbericht kopieren"
L.ERRORCATCHER_COPY_HINT = "Markiert. Drückt Strg+C zum Kopieren."
L.ERRORCATCHER_TEST = "Testfehler"
L.ERRORCATCHER_TEST_BUTTON = "Auslösen"
L.ERRORCATCHER_TEST_DESC = "Löst absichtlich einen Lua-Fehler aus, um zu prüfen, ob Fehlerfänger "
    .. "(oder, wenn es aus ist, Blizzards Fehlerfenster) ihn abfängt."
L.ERRORCATCHER_TEST_MESSAGE = "Testfehler von Forever++. Alles in Ordnung."

-- AddOnsList
L.ADDONSLIST_TITLE = "Addon-Liste"
L.ADDONSLIST_DESC = "Zeigt die Addon-Liste ohne Kategorieüberschriften, mit aktivierten Addons zuerst."
L.ADDONSLIST_ENABLEDFIRST = "Aktivierte zuerst"
L.ADDONSLIST_ENABLEDFIRST_DESC = "Listet Eure aktivierten Addons über den deaktivierten auf."
L.ADDONSLIST_UNGROUP = "Deaktivierte ausgruppieren"
L.ADDONSLIST_UNGROUP_DESC = "Verschiebt deaktivierte Addons aus ihrer Gruppe in den deaktivierten Teil "
    .. "der Liste, sodass eine Gruppe nur die Addons zeigt, die an sind."
L.ADDONSLIST_NOTES = "Notizen durchsuchen"
L.ADDONSLIST_NOTES_DESC = "Lässt das Suchfeld auch Wörter in den Notizen eines Addons finden."
L.ADDONSLIST_SETS = "Addon-Sets"
L.ADDONSLIST_SETS_DESC = "Fügt neben „Alle deaktivieren“ ein Auswahlmenü „Sets“ hinzu, um unter einem "
    .. "Namen zu speichern, welche Addons an sind, und dieses Set später wieder einzuschalten, für den "
    .. "Charakter, den die Liste zeigt. Forever++ bleibt an. Drückt „OK“, um mit dem Set neu zu laden."
L.ADDONSLIST_SETS_BUTTON = "Sets"
L.ADDONSLIST_SETS_NONE = "Keine gespeicherten Sets"
L.ADDONSLIST_SETS_SAVE = "Aktuelles Set speichern ..."
L.ADDONSLIST_SETS_SAVE_PROMPT = "Die jetzt aktiven Addons als Set speichern unter dem Namen:"
L.ADDONSLIST_SETS_REPLACE_CONFIRM = "Das Addon-Set „%s“ durch die jetzt aktiven Addons ersetzen?"
L.ADDONSLIST_SETS_DELETE = "Set löschen"
L.ADDONSLIST_SETS_DELETE_CONFIRM = "Das Addon-Set „%s“ löschen?"
L.ADDONSLIST_SETS_SAVED = "Addon-Set gespeichert: %s"
L.ADDONSLIST_SETS_MISSING = "Nicht installierte Addons im Addon-Set %s: %d."
L.ADDONSLIST_CHAT_DESC = "Meldet im Chat, wenn ein Set gespeichert wird und wie viele Addons eines Sets "
    .. "beim Einschalten nicht installiert sind."

-- MinimapButton
L.MINIMAPBUTTON_TITLE = "Minikartenknopf"
L.MINIMAPBUTTON_DESC = "Ein Knopf für Forever++ an der Minikarte, im Addon-Fach oder an beiden: Klickt "
    .. "darauf für Schnellschalter (welche Module sie bieten, wählt „Schnellschalter“ unten), "
    .. "rechtsklickt für Einstellungen und Umschalt+Klick für abgefangene Fehler."
L.MINIMAPBUTTON_SECTION_BUTTON = "Knopf"
L.MINIMAPBUTTON_SECTION_TOGGLES = "Schnellschalter"
L.MINIMAPBUTTON_SECTION_ERRORS = "Fehler"
L.MINIMAPBUTTON_WHERE = "Anzeigen in"
L.MINIMAPBUTTON_WHERE_DESC = "Wo der Knopf sitzt: an der Minikarte, im Addon-Fach darunter oder an "
    .. "beiden. Zieht den Minikartenknopf, um ihn um die Minikarte zu verschieben."
L.MINIMAPBUTTON_WHERE_MINIMAP = "Minikarte"
L.MINIMAPBUTTON_WHERE_COMPARTMENT = "Addon-Fach"
L.MINIMAPBUTTON_WHERE_BOTH = "Beides"
L.MINIMAPBUTTON_COMPARTMENT_COUNT = "%s (%d)" -- Forever++, errors this session
L.MINIMAPBUTTON_TIP_SESSION = "Fehler dieser Sitzung"
L.MINIMAPBUTTON_TIP_SAVED = "Gespeicherte Fehler"
L.MINIMAPBUTTON_TIP_NONE = "Keine" -- a count of 0 errors
-- The quick toggles' groups, by what you're doing (Menu Order's Activity).
L.MINIMAPBUTTON_GROUP_LOOT = "Händler und Beute"
L.MINIMAPBUTTON_GROUP_NPCS = "NSCs und Quests"
L.MINIMAPBUTTON_GROUP_WORLD = "Unterwegs in der Welt"
L.MINIMAPBUTTON_GROUP_NAMEPLATES = "Namensplaketten"
L.MINIMAPBUTTON_GROUP_GATHERING = "Sammeln"
L.MINIMAPBUTTON_GATHERING_SHOWS = "Sammelkarte zeigt" -- over its kinds' checkboxes: Herbs, Ore...
L.MINIMAPBUTTON_GROUP_OTHER = "Sonstiges"
-- The button in the module's settings that picks the quick toggles: a menu with a submenu per
-- module category, with checkboxes; and the line at the bottom of the quick toggles that opens it.
L.MINIMAPBUTTON_CUSTOMIZE_NAME = "Schnellschalter"
L.MINIMAPBUTTON_CUSTOMIZE = "Anpassen"
L.MINIMAPBUTTON_CUSTOMIZE_DESC = "Wählt nach Kategorie, welche Module die Schnellschalter des Knopfes "
    .. "bieten."
L.MINIMAPBUTTON_CUSTOMIZE_OPEN = "Anpassen ..."
-- The quick toggles' submenu of profiles, with more than one: the profile in use
L.MINIMAPBUTTON_PROFILE = "Profil: %s"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN_DESC = "Wählt in den Einstellungen des Minikartenknopfs, welche Module "
    .. "dieses Menü bietet."
L.MINIMAPBUTTON_CUSTOMIZE_RESET = "Standardeinstellungen wiederherstellen"
L.MINIMAPBUTTON_MENU_CUSTOMIZE = "Anpassen im Menü"
L.MINIMAPBUTTON_MENU_CUSTOMIZE_DESC = "Zeigt „Anpassen ...“ am Ende der Schnellschalter. Aus wählt Ihr "
    .. "sie mit dem Knopf „Anpassen“ unten."
L.MINIMAPBUTTON_MENU_PROFILES = "Profile im Menü"
L.MINIMAPBUTTON_MENU_PROFILES_DESC = "Zeigt das Untermenü „Profil“ in den Schnellschaltern zum Wechseln "
    .. "der Profile, sobald Ihr mehr als eines habt."
-- The tooltip's hints: what a click does, then the click.
L.MINIMAPBUTTON_HINT_SETTINGS = "Einstellungen öffnen"
L.MINIMAPBUTTON_HINT_WELCOME = "Über Forever++"
L.MINIMAPBUTTON_HINT_TOGGLES = "Schnellschalter"
L.MINIMAPBUTTON_HINT_ERRORS = "Fehler anzeigen"
L.MINIMAPBUTTON_HINT_CLEAR = "Fehler der Sitzung löschen"
L.MINIMAPBUTTON_HINT_CLEAR_ALL = "Alle Fehler löschen"
L.MINIMAPBUTTON_HINT_MOVE = "Knopf verschieben"
L.MINIMAPBUTTON_PLACE_NAME = "Knopfposition"
L.MINIMAPBUTTON_PLACE_RESET_DESC = "Setzt den Minikartenknopf an seinen Startplatz am Rand der "
    .. "Minikarte zurück. Zieht ihn, um ihn irgendwo an oder um die Minikarte zu setzen."
-- The tooltip's legend: what each click does, the click at the right in green.
L.MINIMAPBUTTON_LEFT_CLICK = "Klicken"
L.MINIMAPBUTTON_RIGHT_CLICK = "Rechtsklick"
L.MINIMAPBUTTON_KEY_LEFT_CLICK = "%s-Klick" -- a key, such as Shift
L.MINIMAPBUTTON_KEY_RIGHT_CLICK = "%s-Rechtsklick" -- the same, with Click Opens Quick Toggles on
L.MINIMAPBUTTON_SWAP = "Klick öffnet Schnellschalter"
L.MINIMAPBUTTON_SWAP_DESC = "Ein Klick öffnet die Schnellschalter und ein Rechtsklick die "
    .. "Einstellungen. Aus ist es umgekehrt."
L.MINIMAPBUTTON_KEYS_LEFT = "Fehlertasten beim Klick"
L.MINIMAPBUTTON_KEYS_LEFT_DESC = "Behält die Fehlertasten beim Klick, etwa Umschalt+Klick zum Anzeigen "
    .. "der Fehler, statt sie mit den Einstellungen auf den Rechtsklick zu legen."
L.MINIMAPBUTTON_MENU_SIDE = "Menüseite"
L.MINIMAPBUTTON_MENU_SIDE_DESC = "In welche Richtung sich die Schnellschalter vom Mauszeiger öffnen: wie "
    .. "Blizzard seine Menüs öffnet oder links bzw. rechts davon."
L.MINIMAPBUTTON_MENU_SIDE_AUTO = "Autom."
L.MINIMAPBUTTON_MENU_SIDE_LEFT = "Links"
L.MINIMAPBUTTON_MENU_SIDE_RIGHT = "Rechts"
L.MINIMAPBUTTON_MENU_ORDER = "Menüreihenfolge"
L.MINIMAPBUTTON_MENU_ORDER_DESC = "Wie die Schnellschalter angeordnet sind: in Gruppen nach Tätigkeit "
    .. "(Händler und Beute, NSCs und Quests usw.), unter den Kategorien der Seite „Module“ oder in einer "
    .. "Liste von A bis Z."
L.MINIMAPBUTTON_MENU_ORDER_GROUPS = "Aktivität"
L.MINIMAPBUTTON_MENU_ORDER_CATEGORY = "Kategorie"
L.MINIMAPBUTTON_MENU_ORDER_TITLE = "A bis Z"
L.MINIMAPBUTTON_LEFT_DRAG = "Ziehen"
L.MINIMAPBUTTON_ERRORS_KEY = "Taste: Fehler anzeigen"
L.MINIMAPBUTTON_ERRORS_KEY_DESC = "Die Taste, die Ihr beim Klick auf den Knopf haltet, um die Fehler "
    .. "anzuzeigen, solange Fehlerfänger an ist."
L.MINIMAPBUTTON_CLEAR_KEY = "Taste: Sitzung löschen"
L.MINIMAPBUTTON_CLEAR_KEY_DESC = "Die Taste, die Ihr beim Klick auf den Knopf haltet, um die Fehler "
    .. "dieser Sitzung zu löschen, solange Fehlerfänger an ist."
L.MINIMAPBUTTON_CLEAR_ALL_KEY = "Taste: Alles löschen"
L.MINIMAPBUTTON_CLEAR_ALL_KEY_DESC = "Die Taste, die Ihr beim Klick auf den Knopf haltet, um jeden "
    .. "gespeicherten Fehler aus allen Sitzungen zu löschen, solange Fehlerfänger an ist. Es fragt "
    .. "vorher nach."

-- Commands
L.COMMANDS_TITLE = "Slash-Befehle"
L.COMMANDS_DESC = "Fügt kurze Slash-Befehle hinzu: /rl zum Neuladen des Interface und /clear zum "
    .. "Leeren eines Chatfensters. /way gehört zu Wegpunkte."
L.COMMANDS_RELOAD = "/rl"
L.COMMANDS_RELOAD_DESC = "/rl lädt das Interface neu, wie /reload. Bleibt einem anderen Addon "
    .. "überlassen, das /rl schon hat."
L.COMMANDS_RELOAD_HELP = "lädt das Interface neu" -- a line of /fpp help, like the SLASH_ ones
L.COMMANDS_CLEAR_HELP = "leert das Chatfenster, in das es eingegeben wird"
L.COMMANDS_CLEAR = "/clear"
L.COMMANDS_CLEAR_DESC = "/clear leert das Chatfenster, in das Ihr es eingebt. Bleibt einem anderen "
    .. "Addon überlassen, das /clear schon hat."

-- HideBetaFeedback
L.HIDEBETAFEEDBACK_TITLE = "Beta-Feedback ausblenden"
L.HIDEBETAFEEDBACK_DESC = "Blendet die Beta-Zeile zum Melden eines Problems mit F6 in Tooltips und den "
    .. "Knopf für Fehlerberichte aus. F6 meldet weiterhin ein Problem."
L.HIDEBETAFEEDBACK_TOOLTIP = "Tooltip-Hinweis ausblenden"
L.HIDEBETAFEEDBACK_TOOLTIP_DESC = "Blendet die Zeile zum Melden eines Problems mit F6 in Tooltips aus."
L.HIDEBETAFEEDBACK_BUTTON = "Fehlerberichtknopf ausblenden"
L.HIDEBETAFEEDBACK_BUTTON_DESC = "Blendet den schwebenden Knopf für Fehlerberichte aus."
L.HIDEBETAFEEDBACK_QUEST = "Quest-Feedback ausblenden"
L.HIDEBETAFEEDBACK_QUEST_DESC = "Blendet die Feedback-Knöpfe in Questfenstern aus."

-- MovableFramerate
L.MOVABLEFRAMERATE_TITLE = "Bewegliche Bildrate"
L.MOVABLEFRAMERATE_DESC = "Verschiebt den Bildratentext (Strg+R) im Bearbeitungsmodus und ändert seine "
    .. "Größe, wie bei Blizzards eigenen Rahmen. Bis Ihr ihn verschiebt, bleibt er, wo Blizzard ihn "
    .. "hinsetzt."
