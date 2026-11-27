local _, ns = ...
local L = ns.NewLocale("ruRU")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "Копирование чата"
L.CHATCOPY_DESC = "Добавить рядом с окном чата кнопку, которая открывает чат как текст, который можно "
    .. "выделить и скопировать."
L.CHATCOPY_TOOLTIP = "Копировать чат"
L.CHATCOPY_TOOLTIP_DESC = "Открыть чат как текст, который можно выделить и скопировать."
L.CHATCOPY_STAMPS = "Щелчок по времени"
L.CHATCOPY_STAMPS_DESC = "Щелкните по времени у строки чата, чтобы скопировать эту строку. Нужно, "
    .. "чтобы в игре было включено время сообщений в чате."
L.CHATCOPY_STAMPS_PROMPT = "Нажмите Ctrl+C, чтобы скопировать эту строку чата."
L.CHATCOPY_BUTTON_HIDDEN = "Кнопки чата скрыты, поэтому кнопка модуля не видна."
L.CHATCOPY_BUTTON_HIDDEN_DESC = "Кнопки Blizzard рядом с окном чата скрыты, скорее всего другой "
    .. "модификацией чата, а кнопка «Копирования чата» стоит вместе с ними. «Щелчок по времени» "
    .. "по-прежнему работает."
L.CHATCOPY_HIDDEN = "(скрыто игрой)"
L.CHATCOPY_EMPTY = "(в чате пока пусто)"
L.CHATCOPY_SELECT_ALL = "Выбрать все"
L.CHATCOPY_SELECT_HINT = "Нажмите Ctrl+C, чтобы скопировать."

-- ChatSounds
L.CHATSOUNDS_TITLE = "Звуки чата"
L.CHATSOUNDS_DESC = "Проигрывать звук, когда кто-то пишет в чат гильдии, офицеров, группы или рейда. "
    .. "У каждого вида чата свой флажок и звук, а ваши собственные сообщения звука не дают."
L.CHATSOUNDS_NOTICE = "Для шепота игра уже проигрывает свой звук."
L.CHATSOUNDS_NOTICE_DESC = "Игра сама проигрывает звук при шепоте, поэтому параметра для шепота "
    .. "здесь нет."
L.CHATSOUNDS_GUILD = "Гильдия"
L.CHATSOUNDS_GUILD_DESC = "Проигрывать звук, когда кто-то пишет в чат гильдии."
L.CHATSOUNDS_OFFICER = "Офицеры"
L.CHATSOUNDS_OFFICER_DESC = "Проигрывать звук, когда кто-то пишет в чат офицеров."
L.CHATSOUNDS_PARTY = "Группа"
L.CHATSOUNDS_PARTY_DESC = "Проигрывать звук, когда кто-то пишет в чат группы."
L.CHATSOUNDS_RAID = "Рейд"
L.CHATSOUNDS_RAID_DESC = "Проигрывать звук, когда кто-то пишет в чат рейда. Для объявлений рейду "
    .. "игра уже проигрывает свой."
L.CHATSOUNDS_SOUND_DESC = "Проигрываемый звук. При выборе звук проигрывается. Строки, пришедшие в "
    .. "течение двух секунд после звука, звука не дают."

-- ChatLevels
L.CHATLEVELS_TITLE = "Уровни в чате"
L.CHATLEVELS_DESC = "Показывать уровень каждого игрока перед его именем в чате, окрашенный как "
    .. "задание этого уровня. Forever++ запоминает уровни игроков из вашей группы, гильдии и друзей, "
    .. "из результатов /who, а также игроков, которых вы выбираете целью или видите поблизости."
L.CHATLEVELS_TEST = "Проверка чата"
L.CHATLEVELS_TEST_BUTTON = "Показать"
L.CHATLEVELS_TEST_DESC = "Добавить в первое окно чата несколько вымышленных строк торгового канала "
    .. "от вымышленных игроков с их уровнями и цветами классов. Никто, кроме вас, их не увидит."
L.CHATLEVELS_TEST_LINE = "[2. Т] %s: %s" -- after a short trade channel, the name link and the line
L.CHATLEVELS_TEST_1 = "Ищем лекаря в Монастырь Алого ордена и выходим"
L.CHATLEVELS_TEST_2 = "Куплю магическую ткань, хорошо заплачу"
L.CHATLEVELS_TEST_3 = "кто знает, где Братство Справедливости?"
L.CHATLEVELS_TEST_4 = "Продаю толстую кожу, 20 стопок, пишите"

-- ShortChannelNames
L.SHORTCHANNELNAMES_TITLE = "Короткие названия каналов"
L.SHORTCHANNELNAMES_DESC = "Показывать каналы чата как [1], [О] или [1. О] вместо [1. Общий]."
L.SHORTCHANNELNAMES_STYLE = "Вид"
L.SHORTCHANNELNAMES_STYLE_DESC = "Как показывается канал: номером, первой буквой, начальными буквами "
    .. "слов (ПС для ПоискСпутников), названием без зоны или номером вместе с одним из них."
L.SHORTCHANNELNAMES_NUMBER = "Номер: [1]"
L.SHORTCHANNELNAMES_LETTER = "Буква: [О]"
L.SHORTCHANNELNAMES_INITIALS = "Начальные буквы: [ПС]"
L.SHORTCHANNELNAMES_NAME = "Название: [Общий]"
L.SHORTCHANNELNAMES_BOTH = "Номер и буква: [1. О]"
L.SHORTCHANNELNAMES_NUMBER_INITIALS = "Номер и начальные буквы: [1. ПС]"
L.SHORTCHANNELNAMES_NUMBER_NAME = "Номер и название: [1. Общий]"
L.SHORTCHANNELNAMES_CHAT_TYPES = "Гильдия, группа и рейд"
L.SHORTCHANNELNAMES_CHAT_TYPES_DESC = "Сокращать также [Гильдия], [Офицер], [Группа], [Рейд], "
    .. "[Объявление рейду] и [Подземелье] до [Г], [О], [Гр], [Р], [ОР] и [П], их лидеров – до [ЛГр], "
    .. "[ЛР] и [ЛП], а проводника группы – до [ПГр]."
L.SHORTCHANNELNAMES_GUILD = "Г"
L.SHORTCHANNELNAMES_OFFICER = "О"
L.SHORTCHANNELNAMES_PARTY = "Гр"
L.SHORTCHANNELNAMES_PARTY_LEADER = "ЛГр"
L.SHORTCHANNELNAMES_PARTY_GUIDE = "ПГр"
L.SHORTCHANNELNAMES_RAID = "Р"
L.SHORTCHANNELNAMES_RAID_LEADER = "ЛР"
L.SHORTCHANNELNAMES_RAID_WARNING = "ОР"
L.SHORTCHANNELNAMES_INSTANCE = "П"
L.SHORTCHANNELNAMES_INSTANCE_LEADER = "ЛП"

-- QuestLinks
L.QUESTLINKS_TITLE = "Ссылки на задания"
L.QUESTLINKS_DESC = "Превращать задания, которые игроки с Questie упоминают в чате, например "
    .. "[[34] Мрачное поручение (304)], в ссылки на задания, по которым можно щелкнуть и посмотреть "
    .. "задание, как будто его прислали из журнала заданий."

-- ChatHistory
L.CHATHISTORY_TITLE = "История чата"
L.CHATHISTORY_DESC = "Сохранять последние строки окон чата при выходе или перезагрузке и показывать "
    .. "их снова при входе. Шепот не сохраняется."
L.CHATHISTORY_LINES = "Сохранять строк"
L.CHATHISTORY_LINES_DESC = "Сколько последних строк каждого окна чата сохраняется."
L.CHATHISTORY_DIVIDER = "-- Предыдущие сообщения --"
L.CHATHISTORY_DIVIDER_OPTION = "Разделитель истории"
L.CHATHISTORY_DIVIDER_DESC = "Показывать серую строку между восстановленным и новым чатом."

-- ChatArrowKeys
L.CHATARROWKEYS_TITLE = "Стрелки в чате"
L.CHATARROWKEYS_DESC = "Пока вы набираете текст в чате, стрелки вверх и вниз возвращают отправленное "
    .. "ранее, а влево и вправо двигают курсор по тексту – без удержания Alt. Пока поле ввода чата "
    .. "открыто, стрелки не двигают персонажа."

-- SocialButton
L.SOCIALBUTTON_TITLE = "Кнопка общения"
L.SOCIALBUTTON_DESC = "Перенести кнопку общения (быстрого присоединения) вниз, к остальным кнопкам "
    .. "окна чата."
L.SOCIALBUTTON_MENU = "Общение"

-- The column of chat buttons (Lib/Chat.lua), for every module with a button in it.
L.CHAT_BUTTON_FOLDED = "Окно чата слишком низкое для кнопки, поэтому она в меню чата."
L.CHAT_BUTTON_FOLDED_DESC = "Кнопка не поместилась над кнопкой с облачком рядом с окном чата, "
    .. "поэтому она указана внизу меню этой кнопки. Сделайте окно чата выше, чтобы вернуть ее."
L.CHAT_BUTTON_EVERY_TAB = "Кнопка на каждой вкладке"
L.CHAT_BUTTON_EVERY_TAB_DESC = "Оставлять кнопку рядом с окном чата, какая бы вкладка чата ни была открыта. "
    .. "Собственные кнопки чата игры есть только на первой вкладке."

-- ChatFont
L.CHATFONT_TITLE = "Шрифт чата"
L.CHATFONT_DESC = "Рисовать окна чата другим игровым шрифтом. Размер остается заданным вами, а при "
    .. "выключении возвращается шрифт Blizzard."
L.CHATFONT_FONT = "Шрифт"
L.CHATFONT_FONT_DESC = "Шрифт окон чата."
L.CHATFONT_INPUT = "Поле ввода"
L.CHATFONT_INPUT_DESC = "Использовать этот шрифт и для текста, который вы вводите в поле чата. Его "
    .. "размер не меняется."

-- ChatBorder
L.CHATBORDER_TITLE = "Рамка чата"
L.CHATBORDER_DESC = "Рисовать рамку вокруг каждого окна чата из игровой графики рамок. В отличие от "
    .. "собственной бледной рамки окна, она видна при любом фоне окна. При выключении она пропадает."
L.CHATBORDER_STYLE = "Рамка"
L.CHATBORDER_STYLE_DESC = "Рамка вокруг окон чата из графики Blizzard."
L.CHATBORDER_STYLE_THIN = "Тонкая" -- the tooltip border
L.CHATBORDER_STYLE_STONE = "Каменная" -- the dialog border
L.CHATBORDER_STYLE_GOLD = "Золотая" -- the gold dialog border
L.CHATBORDER_COLOR = "Цвет"
L.CHATBORDER_COLOR_DESC = "Цвет рамки. «Стандартный» оставляет графику такой, какой ее рисует игра."
L.CHATBORDER_COLOR_DEFAULT = "По умолчанию"
L.CHATBORDER_COLOR_CLASS = "Цвет класса"
L.CHATBORDER_COLOR_GOLD = "Золотой"
L.CHATBORDER_COLOR_GRAY = "Серый"
L.CHATBORDER_COLOR_BLACK = "Черный"
L.CHATBORDER_COLOR_BLUE = "Синий"
L.CHATBORDER_COLOR_GREEN = "Зеленый"
L.CHATBORDER_COLOR_RED = "Красный"
L.CHATBORDER_OPACITY = "Непрозрачность"
L.CHATBORDER_OPACITY_DESC = "Насколько плотной выглядит рамка."
L.CHATBORDER_FADE = "Затухать вместе с чатом"
L.CHATBORDER_FADE_DESC = "Приглушать рамку, когда курсор покидает окно чата, как игра приглушает "
    .. "вкладки окна, и возвращать ее, когда курсор снова над чатом."
L.CHATBORDER_SECTION_EDITBOX = "Поле ввода"
L.CHATBORDER_EDITBOX = "С полем ввода"
L.CHATBORDER_EDITBOX_DESC = "Рисовать поле ввода чата с такой же рамкой, соединенной с рамкой окна "
    .. "чата, вместо собственного поля игры."
L.CHATBORDER_EDITBOX_CHANNEL = "Цвет чата при наборе"
L.CHATBORDER_EDITBOX_CHANNEL_DESC = "Во время набора окрашивать рамку поля ввода в цвет чата, в "
    .. "который вы пишете, например зеленым для гильдии и розовым для шепота, как игра подсвечивает "
    .. "свое поле."
L.CHATBORDER_FADE_OPACITY = "Непрозрачность при затухании"
L.CHATBORDER_FADE_OPACITY_DESC = "Сколько остается от рамки, пока курсор не над окном чата. Игра "
    .. "оставляет 40% от передней вкладки, а при 0% рамку не видно, пока курсор не окажется над чатом."

-- PersistentChat
L.PERSISTENTCHAT_TITLE = "Чат без затухания" -- Persistent Chat up to 1.4.0
L.PERSISTENTCHAT_DESC = "Оставлять текст чата на экране, а не убирать его через некоторое время. При "
    .. "выключении возвращается затухание Blizzard."

-- HideCombatLogTab
L.HIDECOMBATLOGTAB_TITLE = "Скрыть вкладку журнала боя"
L.HIDECOMBATLOGTAB_DESC = "Убирать вкладку журнала боя из окна чата, пока журнал закреплен там. Сам "
    .. "журнал продолжает работать."

-- MovableCombatLogTab
L.MOVABLECOMBATLOGTAB_TITLE = "Перемещаемая вкладка журнала боя"
L.MOVABLECOMBATLOGTAB_DESC = "Разрешить перетаскивать вкладку журнала боя в любое место среди вкладок "
    .. "чата, даже после созданных вами, а не держать ее сразу после «Общего»."

-- HideChatButtons
L.HIDECHATBUTTONS_TITLE = "Скрыть кнопки чата"
L.HIDECHATBUTTONS_DESC = "Скрывать кнопки рядом с окном чата, пока курсор не над чатом; они "
    .. "появляются и исчезают вместе с его вкладками."

-- HideChatTabs
L.HIDECHATTABS_TITLE = "Скрыть вкладки чата"
L.HIDECHATTABS_DESC = "Скрывать вкладки окон чата, пока курсор не над чатом; они появляются и "
    .. "исчезают, как их приглушает игра. Вкладка с новым сообщением по-прежнему мигает, а по "
    .. "скрытой вкладке можно щелкать."

-- EditBoxOnTop
L.EDITBOXONTOP_TITLE = "Поле ввода сверху"
L.EDITBOXONTOP_DESC = "Ставить поле ввода чата над вкладками окна чата, а не под окном. При "
    .. "выключении оно возвращается на место."

-- WhisperWindow
L.WHISPERWINDOW_TITLE = "Окно шепота"
L.WHISPERWINDOW_DESC = "Держать шепот в отдельном окне – по разговору на каждого собеседника, с полем "
    .. "для ответа. Разговоры сохраняются для каждого персонажа."
L.WHISPERWINDOW_WINDOW_TITLE = "Шепот"
L.WHISPERWINDOW_SECTION_WINDOW = "Окно"
L.WHISPERWINDOW_SECTION_OPACITY = "Непрозрачность"
L.WHISPERWINDOW_OPEN = "Открывать при шепоте"
L.WHISPERWINDOW_OPEN_DESC = "Открывать окно, когда приходит шепот или когда вы шепчете кому-то из "
    .. "чата. В бою ожидает окончания боя."
L.WHISPERWINDOW_HIDE = "Скрывать шепот в чате"
L.WHISPERWINDOW_HIDE_DESC = "Не показывать в окнах чата шепот и автоответы «Нет на месте» и «Не "
    .. "беспокоить», раз они уже есть в окне шепота. Шепот, текст которого скрывает игра, все равно "
    .. "показывается в чате."
L.WHISPERWINDOW_BUTTON = "Кнопка в чате"
L.WHISPERWINDOW_BUTTON_DESC = "Добавить рядом с окном чата кнопку, которая открывает окно шепота и "
    .. "считает непрочитанный шепот. Если окно чата для нее слишком низкое, она в меню кнопки с "
    .. "облачком, и шепот считает облачко."
L.WHISPERWINDOW_BUTTON_HIDDEN = "Кнопки чата скрыты, поэтому кнопка в чате не видна."
L.WHISPERWINDOW_BUTTON_HIDDEN_DESC = "Кнопки Blizzard рядом с окном чата скрыты, скорее всего другой "
    .. "модификацией чата, а кнопка в чате стоит вместе с ними. Открывайте окно командой "
    .. "/fpp whispers или кнопкой «Показать» ниже."
L.WHISPERWINDOW_ALPHA = "Непрозрачность"
L.WHISPERWINDOW_ALPHA_DESC = "Насколько плотным выглядит окно, пока вы стоите на месте, а также пока "
    .. "над ним курсор или вы в нем пишете."
L.WHISPERWINDOW_MOVING = "В движении"
L.WHISPERWINDOW_MOVING_DESC = "Насколько плотным выглядит окно, пока вы двигаетесь вне боя."
L.WHISPERWINDOW_COMBAT = "В бою"
L.WHISPERWINDOW_COMBAT_DESC = "Насколько плотным выглядит окно в бою."
L.WHISPERWINDOW_SHOW = "Шепот"
L.WHISPERWINDOW_SHOW_BUTTON = "Показать"
L.WHISPERWINDOW_SHOW_DESC = "Открыть окно шепота."
L.WHISPERWINDOW_CLEAR = "Очистить"
L.WHISPERWINDOW_CLEAR_NAME = "Сохраненные разговоры"
L.WHISPERWINDOW_CLEAR_DESC = "Забыть все разговоры этого персонажа."
L.WHISPERWINDOW_CLEAR_CONFIRM = "Забыть все разговоры этого персонажа?"
L.WHISPERWINDOW_COMMAND = "открыть окно шепота на разговоре с указанным именем"
L.WHISPERWINDOW_COMMAND_USAGE = "[name]"
L.WHISPERWINDOW_TOOLTIP = "Шепот"
L.WHISPERWINDOW_TOOLTIP_DESC = "Открыть ваши разговоры."
L.WHISPERWINDOW_SUMMARY = { "%d разговор", "%d разговора", "%d разговоров" } -- how many
L.WHISPERWINDOW_SUMMARY_UNREAD = "%s, непрочитанных: %d" -- "3 conversations", unread whispers
L.WHISPERWINDOW_PREVIEW_YOU = "Вы: %s" -- your last whisper, in the list
L.WHISPERWINDOW_REPLY_HINT = "Шепнуть: %s" -- name
L.WHISPERWINDOW_UNREAD = "Новых: %d" -- unread whispers in a conversation
L.WHISPERWINDOW_NONE = "Разговор не выбран."
L.WHISPERWINDOW_YOU = "Вы"
L.WHISPERWINDOW_LINE = "%s %s: %s" -- time, who, the whisper
L.WHISPERWINDOW_INFO_LINE = "%s %s" -- time, what happened
L.WHISPERWINDOW_FULL_NAME = "%s %s" -- first name, surname
L.WHISPERWINDOW_LEVEL = "Уровень %d"
L.WHISPERWINDOW_PLAYING = "Играет: %s" -- a Battle.net friend's character
L.WHISPERWINDOW_GUILD_NAME = "<%s>" -- their guild, as Blizzard's tooltips show it
L.WHISPERWINDOW_FRIEND = "Друг"
L.WHISPERWINDOW_GUILD = "Гильдия"
L.WHISPERWINDOW_OFFLINE = "Не в сети"
L.WHISPERWINDOW_UNKNOWN = "Уровень и зона видны для друзей, согильдийцев и игроков поблизости."
L.WHISPERWINDOW_AFK = "Нет на месте: %s" -- the away message
L.WHISPERWINDOW_DND = "Не беспокоить: %s" -- the busy message
L.WHISPERWINDOW_INVITE = "Пригласить"
L.WHISPERWINDOW_MENU_COMBAT = "Остальное после боя" -- a gray line in the short menu a name gets in combat
L.WHISPERWINDOW_REMOVE = "Удалить разговор"
L.WHISPERWINDOW_REMOVE_CONFIRM = "Забыть разговор с игроком %s?" -- name
L.WHISPERWINDOW_NEW = "Новый шепот"
L.WHISPERWINDOW_NEW_PROMPT = "Кому шепнуть?"
L.WHISPERWINDOW_LOCKED = "Сейчас здесь чат ограничен."
L.WHISPERWINDOW_TEST = "Пробный разговор"
L.WHISPERWINDOW_TEST_BUTTON = "Отправить"
L.WHISPERWINDOW_TEST_DESC = "Добавить в окно шепота вымышленный разговор – несколько реплик с "
    .. "друидом из ночных эльфов, – чтобы посмотреть, как он выглядит. Окно при этом не открывается, "
    .. "поэтому его шепот считается непрочитанным на кнопке в чате. Ответы на него никуда не уходят."
L.WHISPERWINDOW_TEST_NAME = "Тестик Луношепот"
L.WHISPERWINDOW_TEST_RACE = "Ночной эльф"
L.WHISPERWINDOW_TEST_CLASS = "Друид"
L.WHISPERWINDOW_BNET_OFFLINE = "Этого друга Battle.net нет в сети."
