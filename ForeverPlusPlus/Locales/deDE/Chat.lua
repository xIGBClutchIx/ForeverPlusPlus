local _, ns = ...
local L = ns.NewLocale("deDE")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "Chat kopieren"
L.CHATCOPY_DESC = "Fügt neben dem Chatfenster einen Knopf hinzu, der den Chat als Text öffnet, den Ihr "
    .. "markieren und kopieren könnt."
L.CHATCOPY_TOOLTIP = "Chat kopieren"
L.CHATCOPY_TOOLTIP_DESC = "Öffnet den Chat als Text, den Ihr markieren und kopieren könnt."
L.CHATCOPY_STAMPS = "Zeitstempel anklicken"
L.CHATCOPY_STAMPS_DESC = "Klickt auf den Zeitstempel einer Chatzeile, um diese Zeile zu kopieren. "
    .. "Benötigt die eingeschalteten Chatzeitstempel des Spiels."
L.CHATCOPY_STAMPS_PROMPT = "Drückt Strg+C, um diese Chatzeile zu kopieren."
L.CHATCOPY_BUTTON_HIDDEN = "Bei ausgeblendeten Chatknöpfen ist auch der Knopf zum Kopieren ausgeblendet."
L.CHATCOPY_BUTTON_HIDDEN_DESC = "Blizzards Knöpfe neben dem Chatfenster sind ausgeblendet, "
    .. "wahrscheinlich durch ein anderes Chat-Addon, und der Knopf von Chat kopieren sitzt bei ihnen. "
    .. "„Zeitstempel anklicken“ funktioniert weiterhin."
L.CHATCOPY_HIDDEN = "(vom Spiel verborgen)"
L.CHATCOPY_EMPTY = "(noch kein Chat)"
L.CHATCOPY_SELECT_ALL = "Alles markieren"
L.CHATCOPY_SELECT_HINT = "Drückt Strg+C zum Kopieren."

-- ChatSounds
L.CHATSOUNDS_TITLE = "Chatsounds"
L.CHATSOUNDS_DESC = "Spielt einen Sound ab, wenn jemand im Gilden-, Offiziers-, Gruppen- oder "
    .. "Schlachtzugschat schreibt. Jede Chatart hat ihr eigenes Kontrollkästchen und ihren eigenen "
    .. "Sound, und Eure eigenen Nachrichten spielen nichts."
L.CHATSOUNDS_NOTICE = "Das Spiel spielt für Flüstern bereits einen Sound ab."
L.CHATSOUNDS_NOTICE_DESC = "Das Spiel spielt beim Flüstern selbst einen Sound ab, daher gibt es hier "
    .. "keine Option dafür."
L.CHATSOUNDS_GUILD = "Gilde"
L.CHATSOUNDS_GUILD_DESC = "Spielt einen Sound ab, wenn jemand im Gildenchat schreibt."
L.CHATSOUNDS_OFFICER = "Offizier"
L.CHATSOUNDS_OFFICER_DESC = "Spielt einen Sound ab, wenn jemand im Offizierschat schreibt."
L.CHATSOUNDS_PARTY = "Gruppe"
L.CHATSOUNDS_PARTY_DESC = "Spielt einen Sound ab, wenn jemand im Gruppenchat schreibt."
L.CHATSOUNDS_RAID = "Schlachtzug"
L.CHATSOUNDS_RAID_DESC = "Spielt einen Sound ab, wenn jemand im Schlachtzugschat schreibt. "
    .. "Schlachtzugswarnungen spielen schon den eigenen Sound des Spiels."
L.CHATSOUNDS_SOUND_DESC = "Der abgespielte Sound. Bei der Auswahl wird er abgespielt. Zeilen, die "
    .. "innerhalb von zwei Sekunden nach einem Sound kommen, spielen nichts."

-- ChatLevels
L.CHATLEVELS_TITLE = "Stufen im Chat"
L.CHATLEVELS_DESC = "Zeigt die Stufe jedes Spielers vor seinem Namen im Chat, gefärbt wie eine Quest "
    .. "dieser Stufe. Forever++ merkt sich die Stufen von Spielern aus Euren Gruppen, Eurer Gilde und "
    .. "Freundesliste, aus /who-Ergebnissen und von Spielern, die Ihr anvisiert oder in der Nähe seht."
L.CHATLEVELS_TEST = "Chat testen"
L.CHATLEVELS_TEST_BUTTON = "Anzeigen"
L.CHATLEVELS_TEST_DESC = "Fügt Eurem ersten Chatfenster ein paar erfundene Handelschat-Zeilen von "
    .. "erfundenen Spielern mit Stufen und Klassenfarben hinzu. Niemand sonst sieht sie."
L.CHATLEVELS_TEST_LINE = "[2. H] %s: %s" -- after a short trade channel, the name link and the line
L.CHATLEVELS_TEST_1 = "Suchen noch einen Heiler fürs Scharlachrote Kloster, dann geht’s los"
L.CHATLEVELS_TEST_2 = "Kaufe Magiestoff, zahle gut"
L.CHATLEVELS_TEST_3 = "weiß jemand, wo die Defias sind?"
L.CHATLEVELS_TEST_4 = "Verkaufe schweres Leder, 20 Stapel, /w"

-- ShortChannelNames
L.SHORTCHANNELNAMES_TITLE = "Kurze Kanalnamen"
L.SHORTCHANNELNAMES_DESC = "Zeigt Chatkanäle als [1], [A] oder [1. A] statt [1. Allgemein]."
L.SHORTCHANNELNAMES_STYLE = "Stil"
L.SHORTCHANNELNAMES_STYLE_DESC = "Wie ein Kanal erscheint: seine Nummer, sein erster Buchstabe, seine "
    .. "Anfangsbuchstaben (SNG für SucheNachGruppe), sein Name ohne Zone oder die Nummer mit einem "
    .. "davon."
L.SHORTCHANNELNAMES_NUMBER = "Nummer: [1]"
L.SHORTCHANNELNAMES_LETTER = "Buchstabe: [A]"
L.SHORTCHANNELNAMES_INITIALS = "Anfangsbuchstaben: [SNG]"
L.SHORTCHANNELNAMES_NAME = "Name: [Allgemein]"
L.SHORTCHANNELNAMES_BOTH = "Nummer und Buchstabe: [1. A]"
L.SHORTCHANNELNAMES_NUMBER_INITIALS = "Nummer und Anfangsbuchstaben: [1. SNG]"
L.SHORTCHANNELNAMES_NUMBER_NAME = "Nummer und Name: [1. Allgemein]"
L.SHORTCHANNELNAMES_CHAT_TYPES = "Gilde, Gruppe und Schlachtzug"
L.SHORTCHANNELNAMES_CHAT_TYPES_DESC = "Kürzt auch [Gilde], [Offizier], [Gruppe], [Schlachtzug], "
    .. "[Schlachtzugswarnung] und [Instanz] zu [G], [O], [Gr], [S], [SW] und [I], die ihrer Leiter zu "
    .. "[GrL], [SL] und [IL] und den des Gruppenführers zu [GrF]."
L.SHORTCHANNELNAMES_GUILD = "G"
L.SHORTCHANNELNAMES_OFFICER = "O"
L.SHORTCHANNELNAMES_PARTY = "Gr"
L.SHORTCHANNELNAMES_PARTY_LEADER = "GrL"
L.SHORTCHANNELNAMES_PARTY_GUIDE = "GrF"
L.SHORTCHANNELNAMES_RAID = "S"
L.SHORTCHANNELNAMES_RAID_LEADER = "SL"
L.SHORTCHANNELNAMES_RAID_WARNING = "SW"
L.SHORTCHANNELNAMES_INSTANCE = "I"
L.SHORTCHANNELNAMES_INSTANCE_LEADER = "IL"

-- QuestLinks
L.QUESTLINKS_TITLE = "Questlinks"
L.QUESTLINKS_DESC = "Macht die Quests, die Spieler mit Questie im Chat verlinken, etwa [[34] Eine "
    .. "grimmige Aufgabe (304)], zu Questlinks, die Ihr anklicken könnt, um die Quest zu sehen, als "
    .. "hätten sie sie aus ihrem Questlog verlinkt."

-- ChatHistory
L.CHATHISTORY_TITLE = "Chatverlauf"
L.CHATHISTORY_DESC = "Behält die letzten Zeilen der Chatfenster beim Ausloggen oder Neuladen und zeigt "
    .. "sie beim Einloggen wieder. Flüstern wird nicht behalten."
L.CHATHISTORY_LINES = "Gespeicherte Zeilen"
L.CHATHISTORY_LINES_DESC = "Wie viele der letzten Zeilen jedes Chatfensters behalten werden."
L.CHATHISTORY_DIVIDER = "-- Früherer Chat --"
L.CHATHISTORY_DIVIDER_OPTION = "Trennzeile für früheren Chat"
L.CHATHISTORY_DIVIDER_DESC = "Zeigt eine graue Zeile zwischen dem wiederhergestellten und dem neuen "
    .. "Chat."

-- ChatArrowKeys
L.CHATARROWKEYS_TITLE = "Pfeiltasten im Chat"
L.CHATARROWKEYS_DESC = "Beim Tippen im Chat holen Hoch und Runter zurück, was Ihr vorher gesendet habt, "
    .. "und Links und Rechts bewegen sich durch den Text, ohne Alt zu halten. Die Pfeiltasten bewegen "
    .. "Euren Charakter nicht, solange das Chatfeld offen ist."

-- SocialButton
L.SOCIALBUTTON_TITLE = "Geselligkeitsknopf"
L.SOCIALBUTTON_DESC = "Verschiebt den Knopf für Geselligkeit (Schnellbeitritt) nach unten neben die "
    .. "anderen Knöpfe des Chatfensters."
L.SOCIALBUTTON_MENU = "Geselligkeit"

-- The column of chat buttons (Lib/Chat.lua), for every module with a button in it.
L.CHAT_BUTTON_FOLDED = "Das Chatfenster ist zu niedrig für seinen Knopf, daher steht er im Chatmenü."
L.CHAT_BUTTON_FOLDED_DESC = "Der Knopf passte nicht über den Sprechblasenknopf neben dem Chatfenster, "
    .. "daher steht er stattdessen unten im Menü dieses Knopfes. Macht das Chatfenster höher, um ihn "
    .. "zurückzuholen."

-- ChatButtonsEveryTab
L.CHATBUTTONSEVERYTAB_TITLE = "Chatknöpfe auf jedem Reiter"
L.CHATBUTTONSEVERYTAB_DESC = "Lässt die Knöpfe neben dem Chatfenster, egal welcher Chatreiter vorn ist: "
    .. "die Knöpfe des Spiels für Chatmenü und Kanäle und die, die Forever++ hinzufügt. Das Spiel "
    .. "zeigt sie nur auf dem ersten Reiter."

-- ChatFont
L.CHATFONT_TITLE = "Chatschrift"
L.CHATFONT_DESC = "Zeichnet die Chatfenster in einer anderen Schrift des Spiels. Die Größe bleibt, wie "
    .. "Ihr sie eingestellt habt, und beim Ausschalten kehrt Blizzards Schrift zurück."
L.CHATFONT_FONT = "Schrift"
L.CHATFONT_FONT_DESC = "Die Schrift der Chatfenster."
L.CHATFONT_INPUT = "Chateingabe"
L.CHATFONT_INPUT_DESC = "Nutzt die Schrift auch für den Text, den Ihr ins Chatfeld tippt. Seine Größe "
    .. "bleibt, wie sie ist."

-- ChatBorder
L.CHATBORDER_TITLE = "Chatrand"
L.CHATBORDER_DESC = "Zeichnet einen Rand um jedes Chatfenster, in der Rahmengrafik des Spiels. Anders "
    .. "als der blasse eigene Rand des Chatfensters erscheint er, wie auch immer der Hintergrund des "
    .. "Fensters eingestellt ist. Beim Ausschalten verschwindet er."
L.CHATBORDER_STYLE = "Rand"
L.CHATBORDER_STYLE_DESC = "Der Rand um die Chatfenster, in Blizzards eigener Grafik."
L.CHATBORDER_STYLE_THIN = "Dünn" -- the tooltip border
L.CHATBORDER_STYLE_STONE = "Stein" -- the dialog border
L.CHATBORDER_STYLE_GOLD = "Gold" -- the gold dialog border
L.CHATBORDER_COLOR = "Farbe"
L.CHATBORDER_COLOR_DESC = "Die Farbe des Randes. „Standard“ lässt die Grafik, wie das Spiel sie "
    .. "zeichnet."
L.CHATBORDER_COLOR_DEFAULT = "Standard"
L.CHATBORDER_COLOR_CLASS = "Klassenfarbe"
L.CHATBORDER_COLOR_GOLD = "Gold"
L.CHATBORDER_COLOR_GRAY = "Grau"
L.CHATBORDER_COLOR_BLACK = "Schwarz"
L.CHATBORDER_COLOR_BLUE = "Blau"
L.CHATBORDER_COLOR_GREEN = "Grün"
L.CHATBORDER_COLOR_RED = "Rot"
L.CHATBORDER_OPACITY = "Deckkraft"
L.CHATBORDER_OPACITY_DESC = "Wie deckend der Rand ist."
L.CHATBORDER_FADE = "Mit dem Chat verblassen"
L.CHATBORDER_FADE_DESC = "Blendet den Rand ab, wenn die Maus das Chatfenster verlässt, wie das Spiel "
    .. "die Reiter des Fensters abblendet, und holt ihn zurück, wenn die Maus wieder über den Chat "
    .. "kommt."
L.CHATBORDER_SECTION_EDITBOX = "Eingabefeld"
L.CHATBORDER_EDITBOX = "Eingabefeld einbeziehen"
L.CHATBORDER_EDITBOX_DESC = "Zeichnet das Feld, in das Ihr Chat tippt, mit demselben Rand, verbunden "
    .. "mit dem des Chatfensters, anstelle des eigenen Felds des Spiels."
L.CHATBORDER_EDITBOX_CHANNEL = "Chatfarbe beim Tippen"
L.CHATBORDER_EDITBOX_CHANNEL_DESC = "Färbt beim Tippen den Rand des Eingabefelds nach dem Chat, in dem "
    .. "Ihr schreibt, etwa grün für die Gilde und rosa beim Flüstern, so wie das Spiel sein eigenes "
    .. "Feld einfärbt."
L.CHATBORDER_FADE_OPACITY = "Deckkraft verblasst"
L.CHATBORDER_FADE_OPACITY_DESC = "Wie viel vom Rand bleibt, solange die Maus nicht am Chatfenster ist. "
    .. "Das Spiel lässt 40% des vorderen Reiters, und bei 0% ist der Rand unsichtbar, bis die Maus "
    .. "über dem Chat ist."

-- PersistentChat
L.PERSISTENTCHAT_TITLE = "Chat sichtbar halten" -- Persistent Chat up to 1.4.0
L.PERSISTENTCHAT_DESC = "Hält Chattext auf dem Bildschirm, statt ihn nach einer Weile auszublenden. "
    .. "Beim Ausschalten kehrt Blizzards Ausblenden zurück."

-- HideCombatLogTab
L.HIDECOMBATLOGTAB_TITLE = "Kampflog-Reiter ausblenden"
L.HIDECOMBATLOGTAB_DESC = "Nimmt den Reiter des Kampflogs vom Chatfenster, solange das Log dort "
    .. "angedockt ist. Das Log selbst arbeitet weiter."

-- MovableCombatLogTab
L.MOVABLECOMBATLOGTAB_TITLE = "Beweglicher Kampflog-Reiter"
L.MOVABLECOMBATLOGTAB_DESC = "Lässt den Reiter des Kampflogs an jede Stelle zwischen Euren Chatreitern "
    .. "ziehen, auch hinter die selbst erstellten, statt direkt nach Allgemein zu bleiben."

-- HideChatButtons
L.HIDECHATBUTTONS_TITLE = "Chatknöpfe ausblenden"
L.HIDECHATBUTTONS_DESC = "Blendet die Knöpfe neben dem Chatfenster aus, bis die Maus über dem Chat ist, "
    .. "und blendet sie mit seinen Reitern ein und aus."

-- HideChatTabs
L.HIDECHATTABS_TITLE = "Chatreiter ausblenden"
L.HIDECHATTABS_DESC = "Blendet die Reiter der Chatfenster aus, bis die Maus über dem Chat ist, und "
    .. "blendet sie ein und aus, wie das Spiel sie abdunkelt. Ein Reiter mit neuer Nachricht blinkt "
    .. "weiterhin, und ein ausgeblendeter Reiter nimmt weiter Klicks an."

-- EditBoxOnTop
L.EDITBOXONTOP_TITLE = "Eingabefeld oben"
L.EDITBOXONTOP_DESC = "Setzt das Feld, in das Ihr Chat tippt, über die Reiter des Chatfensters statt "
    .. "unter das Fenster. Beim Ausschalten kommt es zurück."

-- WhisperWindow
L.WHISPERWINDOW_TITLE = "Flüsterfenster"
L.WHISPERWINDOW_DESC = "Hält Flüstern in einem eigenen Fenster, ein Gespräch pro Person, mit einem "
    .. "Feld zum Antworten. Gespräche werden für jeden Charakter gespeichert."
L.WHISPERWINDOW_WINDOW_TITLE = "Flüstern"
L.WHISPERWINDOW_SECTION_WINDOW = "Fenster"
L.WHISPERWINDOW_SECTION_OPACITY = "Deckkraft"
L.WHISPERWINDOW_OPEN = "Beim Flüstern öffnen"
L.WHISPERWINDOW_OPEN_DESC = "Öffnet das Fenster, wenn ein Flüstern eingeht oder Ihr eines aus dem Chat "
    .. "sendet. Im Kampf wartet es bis zum Kampfende."
L.WHISPERWINDOW_HIDE = "Flüstern im Chat ausblenden"
L.WHISPERWINDOW_HIDE_DESC = "Lässt Flüstern sowie Abwesend- und Beschäftigt-Antworten aus den "
    .. "Chatfenstern weg, sobald das Flüsterfenster sie hat. Ein Flüstern, dessen Text das Spiel "
    .. "verbirgt, erscheint weiterhin im Chat."
L.WHISPERWINDOW_BUTTON = "Chatknopf"
L.WHISPERWINDOW_BUTTON_DESC = "Fügt neben dem Chatfenster einen Knopf hinzu, der das Flüsterfenster "
    .. "öffnet und ungelesenes Flüstern zählt. Bei einem zu niedrigen Chatfenster steht er im Menü des "
    .. "Sprechblasenknopfs, und die Sprechblase zählt stattdessen das Flüstern."
L.WHISPERWINDOW_BUTTON_HIDDEN = "Die Chatknöpfe sind ausgeblendet, daher kann der Chatknopf nicht "
    .. "erscheinen."
L.WHISPERWINDOW_BUTTON_HIDDEN_DESC = "Blizzards Knöpfe neben dem Chatfenster sind ausgeblendet, "
    .. "wahrscheinlich durch ein anderes Chat-Addon, und der Chatknopf sitzt bei ihnen. Öffnet das "
    .. "Fenster mit /fpp whispers oder mit „Anzeigen“ unten."
L.WHISPERWINDOW_ALPHA = "Deckkraft"
L.WHISPERWINDOW_ALPHA_DESC = "Wie deckend das Fenster ist, während Ihr stillsteht und während die Maus "
    .. "darüber ist oder Ihr darin tippt."
L.WHISPERWINDOW_MOVING = "In Bewegung"
L.WHISPERWINDOW_MOVING_DESC = "Wie deckend das Fenster ist, während Ihr Euch außerhalb des Kampfes "
    .. "bewegt."
L.WHISPERWINDOW_COMBAT = "Im Kampf"
L.WHISPERWINDOW_COMBAT_DESC = "Wie deckend das Fenster im Kampf ist."
L.WHISPERWINDOW_SHOW = "Flüstern"
L.WHISPERWINDOW_SHOW_BUTTON = "Anzeigen"
L.WHISPERWINDOW_SHOW_DESC = "Öffnet das Flüsterfenster."
L.WHISPERWINDOW_CLEAR = "Löschen"
L.WHISPERWINDOW_CLEAR_NAME = "Gespeicherte Gespräche"
L.WHISPERWINDOW_CLEAR_DESC = "Vergisst jedes Gespräch dieses Charakters."
L.WHISPERWINDOW_CLEAR_CONFIRM = "Jedes Gespräch dieses Charakters vergessen?"
L.WHISPERWINDOW_COMMAND = "öffnet das Flüsterfenster, mit einem Namen bei diesem Gespräch"
L.WHISPERWINDOW_COMMAND_USAGE = "[name]"
L.WHISPERWINDOW_TOOLTIP = "Flüstern"
L.WHISPERWINDOW_TOOLTIP_DESC = "Öffnet Eure Gespräche."
L.WHISPERWINDOW_SUMMARY = { "%d Gespräch", "%d Gespräche" } -- how many
L.WHISPERWINDOW_SUMMARY_UNREAD = "%s, %d ungelesen" -- "3 conversations", unread whispers
L.WHISPERWINDOW_PREVIEW_YOU = "Ihr: %s" -- your last whisper, in the list
L.WHISPERWINDOW_REPLY_HINT = "%s anflüstern" -- name
L.WHISPERWINDOW_UNREAD = "%d neu" -- unread whispers in a conversation
L.WHISPERWINDOW_NONE = "Kein Gespräch ausgewählt."
L.WHISPERWINDOW_YOU = "Ihr"
L.WHISPERWINDOW_LINE = "%s %s: %s" -- time, who, the whisper
L.WHISPERWINDOW_INFO_LINE = "%s %s" -- time, what happened
L.WHISPERWINDOW_FULL_NAME = "%s %s" -- first name, surname
L.WHISPERWINDOW_LEVEL = "Stufe %d"
L.WHISPERWINDOW_PLAYING = "Spielt %s" -- a Battle.net friend's character
L.WHISPERWINDOW_GUILD_NAME = "<%s>" -- their guild, as Blizzard's tooltips show it
L.WHISPERWINDOW_FRIEND = "Freund"
L.WHISPERWINDOW_GUILD = "Gilde"
L.WHISPERWINDOW_OFFLINE = "Offline"
L.WHISPERWINDOW_UNKNOWN = "Stufe und Zone erscheinen bei Freunden, Gildenmitgliedern und Spielern in "
    .. "der Nähe."
L.WHISPERWINDOW_AFK = "Abwesend: %s" -- the away message
L.WHISPERWINDOW_DND = "Beschäftigt: %s" -- the busy message
L.WHISPERWINDOW_INVITE = "Einladen"
L.WHISPERWINDOW_MENU_COMBAT = "Mehr nach dem Kampf" -- a gray line in the short menu a name gets in combat
L.WHISPERWINDOW_REMOVE = "Gespräch entfernen"
L.WHISPERWINDOW_REMOVE_CONFIRM = "Euer Gespräch mit %s vergessen?" -- name
L.WHISPERWINDOW_NEW = "Neues Flüstern"
L.WHISPERWINDOW_NEW_PROMPT = "Wen anflüstern?"
L.WHISPERWINDOW_LOCKED = "Der Chat ist hier gerade eingeschränkt."
L.WHISPERWINDOW_TEST = "Testgespräch"
L.WHISPERWINDOW_TEST_BUTTON = "Senden"
L.WHISPERWINDOW_TEST_DESC = "Fügt dem Flüsterfenster ein erfundenes Gespräch hinzu, ein paar Nachrichten "
    .. "hin und her mit einem Nachtelfen-Druiden, um zu sehen, wie es aussieht. Es öffnet das Fenster "
    .. "nicht, daher zählt das Flüstern auf dem Chatknopf als ungelesen. Antworten darauf gehen "
    .. "nirgendwohin."
L.WHISPERWINDOW_TEST_NAME = "Testy Mondflüstern"
L.WHISPERWINDOW_TEST_RACE = "Nachtelf"
L.WHISPERWINDOW_TEST_CLASS = "Druide"
L.WHISPERWINDOW_BNET_OFFLINE = "Dieser Battle.net-Freund ist nicht online."
