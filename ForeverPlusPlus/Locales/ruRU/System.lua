local _, ns = ...
local L = ns.NewLocale("ruRU")
if not L then
    return
end

-- ErrorCatcher
L.ERRORCATCHER_TITLE = "Перехват ошибок"
L.ERRORCATCHER_DESC = "Тихо перехватывать ошибки Lua и заблокированные действия вместо окна ошибок "
    .. "Blizzard и читать их потом в окне, из которого можно копировать, – командой /fpp errors "
    .. "или через кнопку у мини-карты."
L.ERRORCATCHER_CHAT_DESC = "Сообщать в чате о перехваченной ошибке."
L.ERRORCATCHER_SOUND_DESC = "Проигрывать звук при перехвате ошибки, не чаще раза в 10 секунд. При "
    .. "выборе звук проигрывается."
L.ERRORCATCHER_SHOW = "Ошибки"
L.ERRORCATCHER_SHOW_BUTTON = "Показать"
L.ERRORCATCHER_SHOW_DESC = "Открыть окно с перехваченными ошибками."
L.ERRORCATCHER_CLEAR = "Очистить"
L.ERRORCATCHER_CLEAR_NAME = "Сохраненные ошибки"
L.ERRORCATCHER_CLEAR_DESC = "Забыть все сохраненные ошибки из всех сеансов."
L.ERRORCATCHER_CLEAR_CONFIRM = "Забыть все сохраненные ошибки?"
L.ERRORCATCHER_COMMAND = "показать перехваченные ошибки Lua"
L.ERRORCATCHER_CAUGHT = "Перехвачена ошибка: %s Введите /fpp errors, чтобы посмотреть." -- first line of the error
L.ERRORCATCHER_CAUGHT_LOADING = "Ошибок перехвачено при входе в игру: %d. Введите /fpp errors, "
    .. "чтобы посмотреть."
L.ERRORCATCHER_OTHER_HANDLER = "Ошибки Lua перехватывает другая модификация, например BugGrabber, "
    .. "поэтому «Перехват ошибок» видит только заблокированные действия и предупреждения."
L.ERRORCATCHER_OTHER_HANDLER_DESC = "Ошибки Lua уходят в ту модификацию, например в окно BugSack. "
    .. "Окно ошибок Blizzard и его сообщение о заблокированном действии тоже остаются за ней."
L.ERRORCATCHER_BLOCKED = "%s: модификация %s попыталась вызвать защищенную функцию %s." -- event, addon, function
-- Where: the first few of Blizzard's functions on the stack, such as "SmartNavigation.lua:84 < Menu.lua:2143"
L.ERRORCATCHER_BLOCKED_SILENT = "Игра сообщила, что действие интерфейса заблокировано из-за "
    .. "модификации, не назвав ее, в %s."
L.ERRORCATCHER_SECRET = "(Игра скрыла текст этой ошибки.)"
L.ERRORCATCHER_UNKNOWN = "неизвестно"
L.ERRORCATCHER_THIS_SESSION = "Этот сеанс"
L.ERRORCATCHER_LAST_SESSION = "Прошлый сеанс"
L.ERRORCATCHER_ALL = "Все сеансы"
L.ERRORCATCHER_FILTER = "%s (%d)" -- a filter above, how many errors it shows
L.ERRORCATCHER_SUMMARY = "В этом сеансе: %d, сохранено: %d" -- errors this session, errors saved
L.ERRORCATCHER_NONE = "Ошибок не перехвачено."
L.ERRORCATCHER_KIND_BLOCKED = "Заблокированное действие"
L.ERRORCATCHER_KIND_TAINT = "Порча (taint)"
L.ERRORCATCHER_POSITION = "%d из %d" -- this one, how many
L.ERRORCATCHER_ROW_INFO = "%dx, %s" -- times seen, how long ago ("12m ago")
-- times, session, first and last time it happened, how long ago ("12m ago")
-- The forms go by the times.
L.ERRORCATCHER_META = {
    "Встречалась %d раз в сеансе %d, впервые в %s, последний раз в %s (%s).",
    "Встречалась %d раза в сеансе %d, впервые в %s, последний раз в %s (%s).",
    "Встречалась %d раз в сеансе %d, впервые в %s, последний раз в %s (%s).",
}
L.ERRORCATCHER_STACK = "Стек:"
L.ERRORCATCHER_LOCALS = "Локальные переменные:"
L.ERRORCATCHER_NO_STACK = "Стека нет: у заблокированных действий и предупреждений его не бывает."
-- What was going on when an action was blocked, in place of a stack.
L.ERRORCATCHER_CONTEXT = "Обстановка в тот момент:"
L.ERRORCATCHER_CONTEXT_COMBAT = "В бою: %s"
L.ERRORCATCHER_CONTEXT_INSTANCE = "Подземелье: %s" -- none, party, raid, pvp, arena, scenario
L.ERRORCATCHER_CONTEXT_MOUSE = "Под курсором: %s" -- a frame's name, such as TargetFrame
L.ERRORCATCHER_CONTEXT_MENUS = "Открытые меню: %s" -- menu tags, such as MENU_UNIT_TARGET
L.ERRORCATCHER_CONTEXT_GAMEPAD = "Интерфейс контроллера: %s"
L.ERRORCATCHER_CONTEXT_TAINT_LOG = "Журнал порчи включен: %s"
-- Values in the controller navigation's tables that addon code wrote, each on a line of its own.
L.ERRORCATCHER_CONTEXT_STATE = "Состояние контроллера, записанное модификацией: %s"
-- The value's name, the addon, the time first seen, and the windows open then.
L.ERRORCATCHER_CONTEXT_STATE_LINE = "  %s – %s, впервые в %s, открытые окна: %s"
-- A value's name, and how many more beside it in the same table were written at the same time.
L.ERRORCATCHER_CONTEXT_STATE_MORE = "%s (и еще рядом: %d)"
-- When the watch began: a value first seen at this time was already written before it.
L.ERRORCATCHER_CONTEXT_STATE_SINCE = "  (наблюдение с %s)"
L.ERRORCATCHER_CONTEXT_YES = "да"
L.ERRORCATCHER_CONTEXT_NO = "нет"
L.ERRORCATCHER_CONTEXT_NONE = "нет"
L.ERRORCATCHER_TAINT_HINT = "Включите «Журнал порчи» в настройках модуля «Перехват ошибок», и в "
    .. "следующий раз игра запишет в Logs\\taint.log в папке игры, код какой модификации стал "
    .. "причиной."
L.ERRORCATCHER_TAINT_LOG = "Журнал порчи"
L.ERRORCATCHER_TAINT_LOG_DESC = "Одна из настроек самой игры: записывает в Logs\\taint.log в папке "
    .. "игры, код какой модификации стоит за каждым заблокированным действием. Включайте ее, пока "
    .. "ищете виновника, и выключайте после, потому что файл быстро растет."
L.ERRORCATCHER_COPY = "Копировать отчет"
L.ERRORCATCHER_COPY_HINT = "Выделено. Нажмите Ctrl+C, чтобы скопировать."
L.ERRORCATCHER_TEST = "Пробная ошибка"
L.ERRORCATCHER_TEST_BUTTON = "Вызвать"
L.ERRORCATCHER_TEST_DESC = "Намеренно вызвать ошибку Lua, чтобы проверить, что «Перехват ошибок» "
    .. "(или, если он выключен, окно ошибок Blizzard) ее ловит."
L.ERRORCATCHER_TEST_MESSAGE = "Пробная ошибка Forever++. Все в порядке."

-- AddOnsList
L.ADDONSLIST_TITLE = "Список модификаций"
L.ADDONSLIST_DESC = "Показывать список модификаций без заголовков категорий, включенные – первыми."
L.ADDONSLIST_ENABLEDFIRST = "Включенные первыми"
L.ADDONSLIST_ENABLEDFIRST_DESC = "Показывать включенные модификации выше выключенных."
L.ADDONSLIST_UNGROUP = "Выключенные отдельно"
L.ADDONSLIST_UNGROUP_DESC = "Переносить выключенные модификации из их группы в часть списка с "
    .. "выключенными, чтобы в группе были видны только включенные."
L.ADDONSLIST_NOTES = "Поиск по описаниям"
L.ADDONSLIST_NOTES_DESC = "Искать слова также в описаниях модификаций."
L.ADDONSLIST_SETS = "Наборы модификаций"
L.ADDONSLIST_SETS_DESC = "Добавить выпадающий список «Наборы» рядом с «Отключить все», чтобы "
    .. "сохранять под названием, какие модификации включены, и потом снова включать этот набор для "
    .. "персонажа, которого показывает список. Forever++ остается включенным. Нажмите «Окей», чтобы "
    .. "перезагрузить интерфейс с набором."
L.ADDONSLIST_SETS_BUTTON = "Наборы"
L.ADDONSLIST_SETS_NONE = "Нет сохраненных наборов"
L.ADDONSLIST_SETS_SAVE = "Сохранить текущий набор..."
L.ADDONSLIST_SETS_SAVE_PROMPT = "Сохранить включенные сейчас модификации как набор с названием:"
L.ADDONSLIST_SETS_REPLACE_CONFIRM = "Заменить набор «%s» модификациями, включенными сейчас?"
L.ADDONSLIST_SETS_DELETE = "Удалить набор"
L.ADDONSLIST_SETS_DELETE_CONFIRM = "Удалить набор «%s»?"
L.ADDONSLIST_SETS_SAVED = "Набор «%s» сохранен."
L.ADDONSLIST_SETS_MISSING = "Не установлено модификаций из набора «%s»: %d."
L.ADDONSLIST_CHAT_DESC = "Сообщать в чате о сохранении набора и о том, сколько модификаций набора не "
    .. "установлено, когда вы его включаете."

-- MinimapButton
L.MINIMAPBUTTON_TITLE = "Кнопка у мини-карты"
L.MINIMAPBUTTON_DESC = "Кнопка Forever++ у мини-карты, в отсеке модификаций или и там и там: щелчок "
    .. "открывает быстрые переключатели (какие модули в них есть, выбирается ниже в «Быстрых "
    .. "переключателях»), правый щелчок – настройки, а Shift+щелчок – перехваченные ошибки."
L.MINIMAPBUTTON_SECTION_BUTTON = "Кнопка"
L.MINIMAPBUTTON_SECTION_TOGGLES = "Быстрые переключатели"
L.MINIMAPBUTTON_SECTION_ERRORS = "Ошибки"
L.MINIMAPBUTTON_WHERE = "Где показывать"
L.MINIMAPBUTTON_WHERE_DESC = "Где находится кнопка: у мини-карты, в отсеке модификаций под ней или и "
    .. "там и там. Перетащите кнопку, чтобы передвинуть ее по краю мини-карты."
L.MINIMAPBUTTON_WHERE_MINIMAP = "У мини-карты"
L.MINIMAPBUTTON_WHERE_COMPARTMENT = "В отсеке модификаций"
L.MINIMAPBUTTON_WHERE_BOTH = "И там и там"
L.MINIMAPBUTTON_COMPARTMENT_COUNT = "%s (%d)" -- Forever++, errors this session
L.MINIMAPBUTTON_TIP_SESSION = "Ошибки этого сеанса"
L.MINIMAPBUTTON_TIP_SAVED = "Сохраненные ошибки"
L.MINIMAPBUTTON_TIP_NONE = "Нет" -- a count of 0 errors
-- The quick toggles' groups, by what you're doing (Menu Order's Activity).
L.MINIMAPBUTTON_GROUP_LOOT = "Торговцы и добыча"
L.MINIMAPBUTTON_GROUP_NPCS = "NPC и задания"
L.MINIMAPBUTTON_GROUP_WORLD = "В мире"
L.MINIMAPBUTTON_GROUP_NAMEPLATES = "Индикаторы здоровья"
L.MINIMAPBUTTON_GROUP_GATHERING = "Сбор ресурсов"
L.MINIMAPBUTTON_GATHERING_SHOWS = "Карта сбора показывает" -- over its kinds' checkboxes: Herbs, Ore...
L.MINIMAPBUTTON_GROUP_OTHER = "Прочее"
-- The button in the module's settings that picks the quick toggles: a menu with a submenu per
-- module category, with checkboxes; and the line at the bottom of the quick toggles that opens it.
L.MINIMAPBUTTON_CUSTOMIZE_NAME = "Быстрые переключатели"
L.MINIMAPBUTTON_CUSTOMIZE = "Настроить"
L.MINIMAPBUTTON_CUSTOMIZE_DESC = "Выбрать по категориям, какие модули есть в быстрых переключателях."
L.MINIMAPBUTTON_CUSTOMIZE_OPEN = "Настроить..."
-- The quick toggles' submenu of profiles, with more than one: the profile in use
L.MINIMAPBUTTON_PROFILE = "Профиль: %s"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN_DESC = "Выбрать, какие модули есть в этом меню, в настройках модуля "
    .. "«Кнопка у мини-карты»."
L.MINIMAPBUTTON_CUSTOMIZE_RESET = "Восстановить значения по умолчанию"
L.MINIMAPBUTTON_MENU_CUSTOMIZE = "«Настроить» в меню"
L.MINIMAPBUTTON_MENU_CUSTOMIZE_DESC = "Показывать «Настроить...» внизу быстрых переключателей. Если "
    .. "выключено, выбирайте их кнопкой «Настроить» ниже."
L.MINIMAPBUTTON_MENU_PROFILES = "Профили в меню"
L.MINIMAPBUTTON_MENU_PROFILES_DESC = "Показывать в быстрых переключателях подменю «Профиль» для смены "
    .. "профиля, когда у вас их больше одного."
-- The tooltip's hints: what a click does, then the click.
L.MINIMAPBUTTON_HINT_SETTINGS = "Открыть настройки"
L.MINIMAPBUTTON_HINT_WELCOME = "О Forever++"
L.MINIMAPBUTTON_HINT_TOGGLES = "Быстрые переключатели"
L.MINIMAPBUTTON_HINT_ERRORS = "Показать ошибки"
L.MINIMAPBUTTON_HINT_CLEAR = "Очистить ошибки сеанса"
L.MINIMAPBUTTON_HINT_CLEAR_ALL = "Очистить все ошибки"
L.MINIMAPBUTTON_HINT_MOVE = "Переместить кнопку"
L.MINIMAPBUTTON_PLACE_NAME = "Положение кнопки"
L.MINIMAPBUTTON_PLACE_RESET_DESC = "Вернуть кнопку на край мини-карты, где она была изначально. "
    .. "Перетащите ее, чтобы поставить в любое место на мини-карте или рядом с ней."
-- The tooltip's legend: what each click does, the click at the right in green.
L.MINIMAPBUTTON_LEFT_CLICK = "Щелчок"
L.MINIMAPBUTTON_RIGHT_CLICK = "Правый щелчок"
L.MINIMAPBUTTON_KEY_LEFT_CLICK = "Щелчок с %s" -- a key, such as Shift
L.MINIMAPBUTTON_KEY_RIGHT_CLICK = "Правый щелчок с %s" -- the same, with Click Opens Quick Toggles on
L.MINIMAPBUTTON_SWAP = "Щелчок – быстрые переключатели"
L.MINIMAPBUTTON_SWAP_DESC = "Щелчок открывает быстрые переключатели, а правый щелчок – настройки. "
    .. "Если выключено, наоборот."
L.MINIMAPBUTTON_KEYS_LEFT = "Клавиши ошибок на щелчке"
L.MINIMAPBUTTON_KEYS_LEFT_DESC = "Оставлять клавиши ошибок на обычном щелчке, например Shift+щелчок "
    .. "для показа ошибок, а не переносить их на правый щелчок вместе с настройками."
L.MINIMAPBUTTON_MENU_SIDE = "Сторона меню"
L.MINIMAPBUTTON_MENU_SIDE_DESC = "В какую сторону от курсора открываются быстрые переключатели: как "
    .. "Blizzard открывает свои меню, влево или вправо от него."
L.MINIMAPBUTTON_MENU_SIDE_AUTO = "Авто"
L.MINIMAPBUTTON_MENU_SIDE_LEFT = "Слева"
L.MINIMAPBUTTON_MENU_SIDE_RIGHT = "Справа"
L.MINIMAPBUTTON_MENU_ORDER = "Порядок меню"
L.MINIMAPBUTTON_MENU_ORDER_DESC = "Как устроены быстрые переключатели: группами по занятию («Торговцы "
    .. "и добыча», «NPC и задания» и так далее), по категориям страницы «Модули» или одним списком "
    .. "по алфавиту."
L.MINIMAPBUTTON_MENU_ORDER_GROUPS = "По занятию"
L.MINIMAPBUTTON_MENU_ORDER_CATEGORY = "По категории"
L.MINIMAPBUTTON_MENU_ORDER_TITLE = "По алфавиту"
L.MINIMAPBUTTON_LEFT_DRAG = "Перетаскивание"
L.MINIMAPBUTTON_ERRORS_KEY = "Клавиша показа ошибок"
L.MINIMAPBUTTON_ERRORS_KEY_DESC = "Клавиша, которую нужно удерживать при щелчке по кнопке, чтобы "
    .. "показать ошибки, пока включен «Перехват ошибок»."
L.MINIMAPBUTTON_CLEAR_KEY = "Клавиша очистки сеанса"
L.MINIMAPBUTTON_CLEAR_KEY_DESC = "Клавиша, которую нужно удерживать при щелчке по кнопке, чтобы "
    .. "очистить ошибки этого сеанса, пока включен «Перехват ошибок»."
L.MINIMAPBUTTON_CLEAR_ALL_KEY = "Клавиша полной очистки"
L.MINIMAPBUTTON_CLEAR_ALL_KEY_DESC = "Клавиша, которую нужно удерживать при щелчке по кнопке, чтобы "
    .. "очистить все сохраненные ошибки из всех сеансов, пока включен «Перехват ошибок». Сначала "
    .. "спрашивает подтверждение."

-- Commands
L.COMMANDS_TITLE = "Команды чата"
L.COMMANDS_DESC = "Добавить короткие команды: /rl для перезагрузки интерфейса, /clear для очистки "
    .. "окна чата, /kb для назначения клавиш и /pull для запуска таймера пула. /way – в модуле "
    .. "«Путевые точки»."
L.COMMANDS_RELOAD = "/rl"
L.COMMANDS_RELOAD_DESC = "/rl перезагружает интерфейс, как /reload. Если /rl уже есть у другой "
    .. "модификации, команда остается за ней."
L.COMMANDS_RELOAD_HELP = "перезагрузить интерфейс" -- a line of /fpp help, like the SLASH_ ones
L.COMMANDS_CLEAR_HELP = "очистить окно чата, в котором введена команда"
L.COMMANDS_CLEAR = "/clear"
L.COMMANDS_CLEAR_DESC = "/clear очищает окно чата, в котором вы ее ввели. Если /clear уже есть у "
    .. "другой модификации, команда остается за ней."
L.COMMANDS_KEYBIND = "/kb"
L.COMMANDS_KEYBIND_DESC = "/kb открывает «Режим быстрой привязки клавиш», как его кнопка в меню "
    .. "«Назначение клавиш»: наведите курсор на кнопку действия и нажмите клавишу. Только вне боя. "
    .. "Если /kb уже есть у другой модификации, команда остается за ней."
L.COMMANDS_KEYBIND_HELP = "открыть «Режим быстрой привязки клавиш»"
L.COMMANDS_KEYBIND_BLOCKED = "«Режим быстрой привязки клавиш» нельзя открыть в бою или в режиме "
    .. "редактирования."
L.COMMANDS_PULL = "/pull"
L.COMMANDS_PULL_DESC = "/pull 10 запускает игровой таймер пула, тот же отсчет, что и /countdown, "
    .. "на 10 секунд, а без числа – тоже на 10. /pull 0 останавливает его. Если /pull уже есть у "
    .. "модификации для боссов или другой модификации, команда остается за ней."
L.COMMANDS_PULL_HELP = "запустить игровой отсчет до пула, 10 секунд, если число не указано"
L.COMMANDS_PULL_USAGE = "Введите /pull и число секунд отсчета, например /pull 10, или /pull 0, "
    .. "чтобы остановить его."

-- HideBetaFeedback
L.HIDEBETAFEEDBACK_TITLE = "Скрыть отзывы о бета-версии"
L.HIDEBETAFEEDBACK_DESC = "Скрывать в подсказках строку бета-версии с предложением нажать F6, чтобы "
    .. "сообщить о проблеме, и ее кнопку отчета об ошибке. F6 по-прежнему отправляет отчет."
L.HIDEBETAFEEDBACK_TOOLTIP = "Скрывать напоминание в подсказках"
L.HIDEBETAFEEDBACK_TOOLTIP_DESC = "Скрывать в подсказках строку с предложением нажать F6, чтобы "
    .. "сообщить о проблеме."
L.HIDEBETAFEEDBACK_BUTTON = "Скрывать кнопку отчета об ошибке"
L.HIDEBETAFEEDBACK_BUTTON_DESC = "Скрывать плавающую кнопку отчета об ошибке."
L.HIDEBETAFEEDBACK_QUEST = "Скрывать отзывы о заданиях"
L.HIDEBETAFEEDBACK_QUEST_DESC = "Скрывать кнопки отзывов в окнах заданий."

-- MovableFramerate
L.MOVABLEFRAMERATE_TITLE = "Перемещаемый счетчик кадров"
L.MOVABLEFRAMERATE_DESC = "Перемещать текст частоты кадров (Ctrl+R) и менять его размер в режиме "
    .. "редактирования, как собственные рамки Blizzard. Пока вы его не переместите, он остается там, "
    .. "где его ставит Blizzard."
