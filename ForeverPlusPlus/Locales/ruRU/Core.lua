local _, ns = ...
local L = ns.NewLocale("ruRU")
if not L then
    return
end

-- Lib/Text.lua: lengths of time, for slider labels and price lines
L.TEXT_SECONDS = { "%d секунда", "%d секунды", "%d секунд" }
L.TEXT_MINUTES = { "%d минута", "%d минуты", "%d минут" }
L.TEXT_HOURS = { "%d час", "%d часа", "%d часов" }
L.TEXT_AGO_NOW = "только что"
L.TEXT_AGO_MINUTES = "%d мин. назад" -- minutes
L.TEXT_AGO_HOURS = "%d ч назад" -- hours
L.TEXT_AGO_DAYS = "%d дн. назад" -- days
L.TEXT_YARDS = "%s м" -- a distance; the game's own words are used when it has them
L.SLIDER_YARDS = "%d м" -- a slider's value in yards, worded like TEXT_YARDS

-- Lib/ItemStats.lua: an Equip: bonus written as a plain stat, an amount and the stat's name
L.ITEMSTATS_SHORT = "+%s %s"
L.ITEMSTATS_SHORT_PERCENT = "+%s%% %s"
L.ITEMSTATS_SHORT_AND = "%s и %s" -- two short stats of one line

-- Lib/Fonts.lua: the game's fonts, in every font dropdown
L.FONT_FRIZQT = "Friz Quadrata"
L.FONT_ARIALN = "Arial Narrow"
L.FONT_SKURRI = "Skurri"
L.FONT_MORPHEUS = "Morpheus"

-- Lib/Frames.lua: our windows' titles
L.FRAMES_WINDOW_TITLE = "%s %s" -- the addon's name (in gray), the window's title

-- Lib/Keys.lua: modifier keys, in every key dropdown
L.KEY_SHIFT = "Shift"
L.KEY_CTRL = "Ctrl"
L.KEY_ALT = "Alt"
L.KEY_NONE = "Нет"
-- Added to a key dropdown's description with the controller interface on; each %s is a trigger
-- as the player's controller shows it
L.KEY_PAD_NOTE = "При включенном интерфейсе контроллера вместо нее удерживайте %s или %s."
L.SKIP_KEY = "Клавиша пропуска" -- the option of every module that a held key skips

-- Lib/MapPins.lua: icons on the world map.
-- Click hints are written as Blizzard's instruction lines are: in angle brackets, the keys and the
-- click as separate words with no hyphen or plus ("Ctrl click"), no full stop. One click to a line.
L.MAPPINS_HINT_WAYPOINT = "<Щелкните, удерживая Ctrl, чтобы поставить точку на карте>"
-- The options of icons on the world map: their size, opacity, and whether continent maps show
-- them, the same in every module that has them.
L.MAPPINS_SIZE = "Размер значков"
L.MAPPINS_SIZE_DESC = "Размер значков относительно обычного."
L.MAPPINS_OPACITY = "Непрозрачность"
L.MAPPINS_OPACITY_DESC = "Насколько плотными выглядят значки. Чем меньше значение, тем лучше "
    .. "видна карта под ними."
L.MAPPINS_CONTINENTS = "На картах континентов"
L.MAPPINS_CONTINENTS_DESC = "Показывать значки также на картах континентов и мира, а не только на "
    .. "картах зон."
-- Lib/Sounds.lua: the alert sounds, in every Sound dropdown
L.SOUND_NAME = "Звук"
L.SOUND_OFF = "Выкл."
L.SOUND_BUZZ = "Сигнал ошибки"
L.SOUND_DENIED = "Отказ"
L.SOUND_HORN = "Боевой рог"
L.SOUND_BOSS = "Предупреждение о боссе"
L.SOUND_RAIDWARNING = "Объявление рейду"
L.SOUND_GM = "Оповещение ГМ"
L.SOUND_ALARM = "Будильник"
L.SOUND_WHISPER = "Шепот"
L.SOUND_READYCHECK = "Проверка готовности"

-- Core: /fpp and chat
L.ON = "вкл"
L.OFF = "выкл"
L.MODULE_STATE = "%s: %s." -- module name, on/off
L.MODULE_ALWAYS_ON = "%s – это инструмент, он всегда включен." -- module title, such as Self Test
L.NO_MODULE = "Модуль не найден: %s"
L.COMMAND_NEEDS_MODULE = "Команде /fpp %s нужен модуль «%s», а он выключен на странице «Модули»." -- command, title
L.SLASH_MODULES = "модули (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "открыть настройки"
L.SLASH_LIST = "вывести список модулей и их состояние"
L.SLASH_TOGGLE = "включить или выключить модуль или один из его флажков"
L.SLASH_RESET = "вернуть все настройки к стандартным (с перезагрузкой)"
L.RESET_CONFIRM = "Вернуть все настройки Forever++ к стандартным и стереть все, что сохранено, "
    .. "например цены аукциона и время полетов? Интерфейс будет перезагружен."
L.SLASH_OPTIONS = "вывести параметры модуля и их значения"
L.SLASH_SET = "изменить параметр (on/off, вариант или число)"
L.SLASH_TAKEN = "Команда %s уже занята другой модификацией, поэтому Forever++ оставляет ее ей."

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s: %s. Параметры (/fpp set %s <option> <value>):" -- module, on/off, module
L.OPTIONS_NONE = "нет"
L.OPTIONS_DEBUG = ", отладка"
L.SET_USAGE = "Использование: /fpp set <module> <option> [value]"
L.MODULE_STATE_ALLOWED = "%s: %s (on, off)." -- module name, on/off
L.NO_OPTION = "У модуля %s нет параметра %s. Список: /fpp options %s." -- module, option, module
L.OPTION_STATE = "%s, %s: %s." -- module, option, value
L.OPTION_STATE_ALLOWED = "%s, %s: |cffffd100%s|r (%s)." -- module, option, value, allowed values
L.CHAT_MESSAGES = "Сообщения в чате" -- a module's checkbox for what it says in chat by itself

-- Lib/Profiles.lua: profiles, and /fpp profiles
L.PROFILES_DEFAULT = "Основной" -- the profile everyone starts with, which is always there
L.PROFILES_NAME_EMPTY = "Профилю нужно название."
L.PROFILES_NAME_TAKEN = "Профиль с названием «%s» уже есть." -- name
L.PROFILES_DEFAULT_ALWAYS = "Профиль «Основной» есть всегда, его нельзя переименовать или удалить."
L.SLASH_PROFILE = "список профилей или переключение этого персонажа на один из них"
L.PROFILES_HEADER = "профили (/fpp profiles <name>, чтобы переключиться):"
L.PROFILES_CHARACTERS = { "%d персонаж", "%d персонажа", "%d персонажей" } -- how many use a profile
L.PROFILES_SWITCHED = "Текущий профиль: %s." -- profile name
L.PROFILES_AFTER_COMBAT = "Профиль сменится после боя: %s." -- profile name
L.PROFILES_NO_SUCH = "Нет профиля «%s». Список: /fpp profiles." -- what was typed

-- Settings
-- The Modules page's groups of modules.
L.CATEGORY_AUTOMATION = "Автоматизация"
L.CATEGORY_CHARACTER = "Персонаж"
L.CATEGORY_CHAT = "Чат"
L.CATEGORY_INTERFACE = "Интерфейс"
L.CATEGORY_ITEMS = "Предметы"
L.CATEGORY_MAP = "Карта"
L.CATEGORY_QUESTS = "Задания"
L.CATEGORY_SYSTEM = "Система"
L.CATEGORY_UNITS = "Рамки и индикаторы"
L.CATEGORY_OTHER = "Прочее"
L.DEBUG = "Отладка"
L.SETTINGS_AFTER_COMBAT = "Настройки откроются после боя."
L.MODULES = "Модули" -- the page with every module's checkbox, the top Forever++ entry
L.ABOUT = "Об аддоне" -- the page with the version, links, credits, and commands
-- The selected module on the Modules page
L.SETTINGS_ENABLED = "Включено" -- the module's own on/off checkbox, under its description
-- What a greyed-out option needs (`needs`), in red in its tooltip: an addon's or module's name
L.SETTINGS_NEEDS_ADDON = "Требуется модификация %s."
L.SETTINGS_NEEDS_MODULE = "Требуется включенный модуль «%s»."
L.SETTINGS_NEEDS_CLIENT = "В этой версии игры нет того, что для этого нужно."
-- A notice on a module whose Blizzard frame the controller interface hides (ns.Gamepad.HidesNotice).
L.SETTINGS_CONTROLLER_HIDDEN = "Не работает с интерфейсом контроллера"
L.SETTINGS_CONTROLLER_HIDDEN_DESC = "Интерфейс контроллера скрывает то, что меняет этот модуль, и "
    .. "показывает вместо этого свое, поэтому, пока он включен, модуль ничего не делает."
-- And on one that needs a mouse, a held key, or a window its cursor can't reach (LimitedNotice).
L.SETTINGS_CONTROLLER_LIMITED = "Ограничен с интерфейсом контроллера"
L.SETTINGS_CONTROLLER_LIMITED_DESC = "Частично или полностью этот модуль требует щелчка мышью, "
    .. "перетаскивания, удержания клавиши или окна, до которого не дотянуться курсором контроллера, "
    .. "и при включенном интерфейсе контроллера ничего не делает."
-- An option XP Bar Text and Reputation Bar Text share (Lib/StatusBars.lua)
L.STATUSBARS_SOLID = "Сплошная полоса"
L.STATUSBARS_SOLID_DESC = "Убрать с полосы разделительные линии, чтобы она была сплошной."
-- The tooltip of the padlock in a locked module's checkbox's place
L.SETTINGS_LOCKED = "Выключен и заблокирован: игра сломала то, что делает этот модуль. Подробнее – "
    .. "в его настройках."
L.SETTINGS_OPTIONS = "Параметры" -- the header over its options
L.SETTINGS_NO_OPTIONS = "У этого модуля нет параметров."
L.SETTINGS_CONFLICT_GO = "Перейти: %s" -- an option's name
-- A mark on an item or action button icon (Lib/ItemButtons.lua): its corner, size, and padding,
-- the same in every module that has one.
L.ICONMARK_CORNER = "Угол"
L.ICONMARK_CORNER_TOPLEFT = "Верхний левый"
L.ICONMARK_CORNER_TOPRIGHT = "Верхний правый"
L.ICONMARK_CORNER_BOTTOMLEFT = "Нижний левый"
L.ICONMARK_CORNER_BOTTOMRIGHT = "Нижний правый"
L.ICONMARK_PIXELS = "%d пикс." -- a size or padding slider's value
L.ICONMARK_PADDING = "Отступ"
L.ICONMARK_PADDING_DESC = "Насколько метка отстоит от своего угла: при значении 2 метка в левом "
    .. "верхнем углу сдвигается на 2 пикселя вправо и на 2 вниз."
-- Under a mark's Corner option while Upgrade Arrows has an arrow in the same corner
L.ICONMARK_CONFLICT_ARROW = "Модуль «Стрелки улучшений» тоже ставит стрелку в этот угол, и они "
    .. "перекрываются. Выберите другой угол для одной из них."
L.ICONMARK_CONFLICT_DOWN = "Модуль «Стрелки улучшений» тоже ставит в этот угол стрелку ухудшения, "
    .. "и они перекрываются. Выберите другой угол для одной из них."
L.ICONMARK_SECTION_SHOW = "Где показывать" -- the header over the places a module marks items in
L.ICONMARK_PLACE_BAGS = "Сумки"
L.ICONMARK_PLACE_BANK = "Банк"
L.ICONMARK_PLACE_MERCHANT = "Торговцы"
L.ICONMARK_PLACE_AUCTION = "Аукцион"
L.ICONMARK_PLACE_LOOT = "Добыча"
L.ICONMARK_PLACE_MAIL = "Почта"
L.ICONMARK_PLACE_QUESTS = "Награды за задания"
L.SETTINGS_PAGE_NOTE = "Пока модуль включен, его страница «%s» есть на боковой панели в разделе "
    .. "Forever++. Страница появляется или пропадает, когда вы выберете другую страницу."
L.SETTINGS_TURN_ON = "Включить" -- the button on a "Blizzard's ... is off" row
L.SETTINGS_RESET = "Восстановить значение по умолчанию"
L.SETTINGS_RESET_TO = "По умолчанию: %s"
L.SETTINGS_RESET_PAIR = "%s, %s" -- a checkbox's default, then its slider's, in one row
L.SETTINGS_CHECKED = "Включено" -- a checkbox's default
L.SETTINGS_UNCHECKED = "Выключено"
L.SETTINGS_SEARCH = "Поиск модулей" -- gray text in the Modules page's empty search box
L.SETTINGS_NO_MATCH = "Нет модулей по запросу «%s»." -- the search text
L.SETTINGS_NEW_ONLY = "Новое" -- the checkbox beside the search box that lists only modules marked NEW
L.SETTINGS_NOTHING_NEW = "Ничего нового." -- the Modules list while that checkbox is on and nothing is new

-- Settings: the Profiles page
L.PROFILES = "Профили"
L.PROFILES_USES = "Профиль персонажа %s" -- a character's name, before the dropdown of its profile
L.PROFILES_USES_TITLE = "Профиль этого персонажа"
L.PROFILES_USES_DESC = "Профиль персонажа %s. Все, что вы меняете в Forever++, сохраняется в нем для "
    .. "всех персонажей, которые его используют." -- character
L.PROFILES_NEW_CHARACTERS = "Для новых персонажей"
L.PROFILES_NEW_CHARACTERS_DESC = "Профиль, с которым персонаж начинает при первом входе в игру."
L.PROFILES_NEW = "Новый профиль"
L.PROFILES_NEW_DESC = "Создать профиль: копию выбранного, из стандартных настроек или из набора «%s»." -- a preset's name, or PRESETS_A_PRESET
L.PROFILES_NEW_ASK = "Введите название нового профиля."
L.PROFILES_NEW_FROM = "Создать «%s» как копию «%s», из стандартных настроек или из набора «%s»?" -- new name, selected profile, a preset's name or PRESETS_A_PRESET
L.PROFILES_PRESET = "Основан на" -- beside the dropdown of the preset a profile follows
L.PROFILES_PRESET_NONE = "Нет" -- a profile based on no preset
L.PROFILES_PRESET_DESC = "Набор, которому следует профиль «%s»: все, что вы не задали сами, берется "
    .. "из набора и меняется вместе с ним в новых версиях, а стрелка отмены возвращает значение из "
    .. "набора. При выборе набора все заданные вами настройки сохраняются. «Нет» оставляет текущие "
    .. "значения профиля как ваши собственные и перестает следовать набору." -- profile
L.PROFILES_PRESET_AFTER_COMBAT = "Основа профиля «%s» сменится после боя." -- profile
L.PRESETS_A_PRESET = "набор" -- in PROFILES_NEW_DESC and PROFILES_NEW_FROM, with more than one
L.PRESETS_MORE = "Наборы..." -- a popup button that opens a menu of every preset
L.PRESETS_NO_SUCH = "Набор не найден: %s."
L.PRESETS_DEVELOPER_DESC = "Стандартные настройки плюс модули и параметры, которыми пользуется "
    .. "разработчик."
L.PROFILES_COPY_OF = "Копия: %s" -- a profile
L.PROFILES_FROM_DEFAULTS = "По умолчанию"
L.PROFILES_IN_USE = "Используется этим персонажем"
L.PROFILES_SUMMARY = "Включено модулей: %d, изменено настроек: %d."
L.PROFILES_USED_BY = "Используют: %s." -- character names
L.PROFILES_UNUSED = "Не используется ни одним персонажем."
L.PROFILES_USE = "Выбрать для этого персонажа"
L.PROFILES_USE_DESC = "Сразу переключает персонажа %s на профиль «%s», без перезагрузки." -- character, profile
L.PROFILES_RENAME = "Переименовать"
L.PROFILES_RENAME_DESC = "Дать профилю «%s» другое название." -- profile
L.PROFILES_RENAME_ASK = "Новое название для «%s»:" -- profile
L.PROFILES_DELETE = "Удалить"
L.PROFILES_DELETE_DESC = "Удалить «%s». Персонажи с этим профилем вернутся на «Основной»." -- profile
L.PROFILES_DELETE_ASK = "Удалить «%s»? Персонажи с этим профилем вернутся на «Основной»." -- profile
L.PROFILES_CHARACTERS_HEADER = "Персонажи"
L.PROFILES_CHARACTER_LINE = "%2$s %1$d-го уровня" -- level, class
L.PROFILES_THIS_CHARACTER = "этот персонаж"
L.PROFILES_USES_OTHER = "профиль: %s" -- the profile another character uses
L.PROFILES_CHECK_DESC = "Установите флажок, чтобы персонаж %s использовал профиль «%s»." -- character, profile
L.PROFILES_UNCHECK_DESC = "Снимите флажок, чтобы вернуть персонажа %s на «Основной»." -- character
L.PROFILES_ON_DEFAULT_DESC = "Каждый персонаж использует какой-то профиль. Чтобы снять персонажа %s "
    .. "с «Основного», отметьте его в другом профиле." -- character
L.PROFILES_FORGET_HINT = "Щелкните правой кнопкой мыши, чтобы забыть этого персонажа."
L.PROFILES_FORGET_ASK = "Забыть персонажа %s? Он пропадет из списка до следующего входа в игру." -- character
L.PROFILES_NOTE = "Профиль – это то, какие модули включены, их настройки, расположение рамок "
    .. "Forever++ в режиме редактирования и окон в модуле «Перемещаемые окна», а также быстрые "
    .. "переключатели кнопки у мини-карты. Цены аукциона, точки сбора, встреченные игроки и личные "
    .. "данные каждого персонажа, например планы талантов, в него не входят."
L.PROFILES_SHARE = "Поделиться"
L.PROFILES_EXPORT = "Экспорт"
L.PROFILES_EXPORT_DESC = "Показывает профиль «%s» строкой текста, чтобы скопировать и отправить "
    .. "кому-нибудь или сохранить как резервную копию." -- profile
L.PROFILES_EXPORT_ASK = "Профиль «%s» в виде текста. Скопируйте его (Ctrl+C) и отправьте кому-нибудь "
    .. "или сохраните как резервную копию." -- profile
L.PROFILES_IMPORT = "Импорт"
L.PROFILES_IMPORT_DESC = "Вставить экспортированный кем-то профиль как новый или поверх «%s»." -- profile
L.PROFILES_IMPORT_ASK = "Вставьте экспортированный кем-то профиль (Ctrl+V)."
-- What the pasted text holds: name, Forever++ version, modules on, settings changed
L.PROFILES_IMPORT_FOUND = "%s, создан в Forever++ %s.\nВключено модулей: %d, изменено настроек: %d."
L.PROFILES_IMPORT_NEW = "Импортировать как новый"
L.PROFILES_IMPORT_REPLACE = "Заменить «%s»" -- the selected profile
L.PROFILES_IMPORT_BAD = "Это не профиль Forever++. Скопируйте строку целиком и вставьте еще раз."
L.PROFILES_IMPORT_CANT = "Этот клиент не может прочитать сжатые профили."
L.PROFILES_IMPORT_NEWER = "Профиль создан в более новой версии Forever++. Обновите аддон, чтобы "
    .. "импортировать его."
L.PROFILES_IMPORTED = "Импортированный профиль" -- the name of an import whose own name is empty
L.PROFILES_IMPORT_DONE = "Импортирован профиль «%s»." -- profile
L.PROFILES_MODULES_NOTE = "Профиль: %s" -- beside the Modules page's title, with more than one
L.DEFAULTS_ASK_PROFILE = "Вернуть настройки Forever++ в профиле «%s» к стандартным? Это затронет "
    .. "всех персонажей с этим профилем. Остальные настройки игры не изменятся." -- profile

-- Settings: Changelog page. The notes themselves are in Changelog.lua.
L.CHANGELOG = "Список изменений"
L.CHANGELOG_RELEASE = "%s (%s)" -- version, date
L.CHANGELOG_UNRELEASED = "Не выпущено"
L.CHANGELOG_SEARCH = "Поиск изменений" -- gray text in the Changelog page's empty search box
L.CHANGELOG_BY_MODULE = "По модулям" -- checkbox that groups a release's notes under their modules
L.CHANGELOG_GENERAL = "Общее" -- heading, with By Module on, for notes about no one module
L.CHANGELOG_NO_MATCH = "Нет изменений по запросу «%s»." -- the search text
L.CHANGELOG_CHANGES = { "%d изменение", "%d изменения", "%d изменений" } -- how many entries a release has
L.CHANGELOG_ADDED = "Добавлено"
L.CHANGELOG_CHANGED = "Изменено"
L.CHANGELOG_FIXED = "Исправлено"
L.CHANGELOG_REMOVED = "Удалено"
L.CHANGELOG_CONTROLLER = "Интерфейс контроллера"
L.CHANGELOG_SETTINGS = "Настройки"
L.CHANGELOG_COMMANDS = "Команды"

-- Settings: the About page
L.HOME_TAGLINE = "Небольшие дополнения и изменения стандартного интерфейса для WoW Forever."
L.HOME_DEFAULTS = "По умолчанию"
-- The popup of the Defaults button at the top right of the Modules, Changelog, and About pages
L.DEFAULTS_ASK = "Вернуть все настройки Forever++ к стандартным? Текущие настройки Forever++ будут "
    .. "заменены. Остальные настройки игры не изменятся."
L.DEFAULTS_DEVELOPER = "Настройки разработчика"
L.DEFAULTS_RECOMMENDED = "Рекомендуемые настройки"
L.HOME_MODULES_ON = "Включено модулей: %d из %d" -- on, total
L.HOME_GAME_BUILD = "Игра %s (%s)" -- version, build
L.HOME_LINKS = "Ссылки"
L.HOME_LINK_CURSEFORGE = "CurseForge"
L.HOME_LINK_WAGO = "Wago"
L.HOME_LINK_SOURCE = "Исходный код"
L.HOME_LINK_RELEASES = "Выпуски"
L.HOME_LINK_BUG = "Сообщить об ошибке"
L.HOME_LINK_REQUEST = "Предложение"
L.HOME_LINK_HINT = "Щелкните по ссылке, чтобы скопировать ее."
L.HOME_COPY = "Нажмите Ctrl+C, чтобы скопировать ссылку."
L.HOME_CREDITS = "Благодарности"
L.HOME_AUTHOR = "Автор"
L.HOME_EVERYONE = "Все игроки" -- the last name in the credits: the players
L.HOME_EVERYONE_THANKS = "Спасибо за постоянные сообщения об ошибках, предложения и отзывы."
L.HOME_WORKS_WITH = "Совместимость"
L.HOME_QUEST_DATA = "Данные заданий для: %s" -- the modules that read QuestieDB
L.HOME_SUPPORT = "Дополнительная поддержка в: %s" -- the module or option another addon adds to
L.HOME_COMMANDS = "Команды"
L.HOME_COMMANDS_GENERAL = "Общие" -- the commands no one module owns
L.HOME_COMMANDS_SEARCH = "Поиск"
L.HOME_COMMANDS_HINT = "<Щелкните, чтобы ввести команду в чат>"

-- Edit Mode dialog for our own frames (Lib/EditMode.lua)
L.EDITMODE_SCALE = "Масштаб"
L.EDITMODE_CLICK_TO_EDIT = "Щелкните для изменения"
L.EDITMODE_RESET_POSITION = "Восстановить положение по умолчанию"
L.SETTINGS_EDIT_MODE_NOTE = "Расположение и вид настраиваются в режиме редактирования: нажмите Esc, "
    .. "выберите «Режим редактирования» и щелкните по рамке." -- a gray row on a module with Edit Mode settings
L.SETTINGS_EDIT_MODE_NOTE_DESC = "Положение, масштаб и вид настраиваются в окне режима "
    .. "редактирования и в контекстном меню рамки там же, рядом с тем, что они меняют."

-- The gray row on a module another addon adds (Lib/Plugins.lua)
L.PLUGIN_NOTICE = "Добавлен другой модификацией."
L.PLUGIN_NOTICE_ADDON = "Добавлен модификацией %s." -- the addon's folder name
L.PLUGIN_NOTICE_DESC = "Этот модуль не входит в Forever++: его добавляет сюда другая модификация. "
    .. "О проблемах с ним сообщайте ее автору."
-- Gray rows on a module that reads the QuestieDB addon's data (Lib/QuestieDB.lua)
L.QUESTIEDB_NEEDED = "Требуется модификация QuestieDB."
L.QUESTIEDB_NEEDED_DESC = "Данные о заданиях, существах, предметах и объектах берутся из QuestieDB, "
    .. "отдельной модификации. Скачайте и установите ее, включите в списке модификаций и "
    .. "перезагрузите интерфейс. До тех пор этот модуль нельзя включить."
L.QUESTIEDB_LOCKED = "Заблокирован: этому модулю нужна модификация QuestieDB. Скачайте ее и "
    .. "перезагрузите интерфейс."
L.QUESTIEDB_PROBLEM = "Эта версия QuestieDB не подходит для Forever++."
L.QUESTIEDB_PROBLEM_DESC = "QuestieDB включена, но отвечает не так, как ожидает Forever++. "
    .. "Обновите ту из двух, что старее."
