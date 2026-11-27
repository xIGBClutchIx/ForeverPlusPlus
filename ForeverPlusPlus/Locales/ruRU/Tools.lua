local _, ns = ...
local L = ns.NewLocale("ruRU")
if not L then
    return
end

-- The rest of the tool pages (Self Test, Screenshots, Taint Watcher, CPU Profiler, and Gear Probe)
-- are read only while debugging, so only their titles and descriptions are translated here.

-- ConsoleVariables
L.CONSOLEVARIABLES_TITLE = "Консольные переменные"
-- Debug (its title, L.DEBUG, is in Core.lua)
L.DEBUG_DESC = "Показывать отладочные параметры всех модулей и инструменты проверки (самопроверку, "
    .. "проверку снаряжения, снимки экрана) на странице «Отладка» на боковой панели настроек и "
    .. "включить их команды."
L.DEBUG_NOTICE = "При выключении отладки все отладочные параметры возвращаются к стандартным." -- a gray row atop the module
L.DEBUG_NOTICE_DESC = "Чтобы ничего из заданного здесь не продолжало работать незаметно."
-- ConsoleVariables
L.CONSOLEVARIABLES_DESC = "Просматривать консольные переменные игры (CVar) на странице в настройках, "
    .. "менять их и закреплять нужные, даже те, которые игра сбрасывает при каждом входе."
L.CONSOLEVARIABLES_CHAT_DESC = "Сообщать в чате, если закрепленную консольную переменную не удается "
    .. "удержать на ее значении."
-- A gray row atop the module while it's off with console variables locked
L.CONSOLEVARIABLES_LOCKS_OFF = "Пока модуль выключен, закрепленные переменные не удерживаются."
L.CONSOLEVARIABLES_LOCKS_OFF_DESC = "Они возвращаются к тому, что задает игра, пока модуль снова не "
    .. "включат."
L.CONSOLEVARIABLES_COMMAND = "открыть «Консольные переменные» с поиском [search]"
L.CONSOLEVARIABLES_NO_PAGE = "Настройки этого клиента не могут открыть страницу «Консольные переменные»."
L.CONSOLEVARIABLES_AFTER_COMBAT = "%s изменится после боя." -- CVar name
L.CONSOLEVARIABLES_REFUSED = "%s нельзя изменить." -- CVar name
L.CONSOLEVARIABLES_KEPT = "%s сохраняет значение %s: игра не приняла %s." -- CVar name, its value, the typed one
L.CONSOLEVARIABLES_SEARCH = "Поиск консольных переменных" -- gray text in the empty search box
L.CONSOLEVARIABLES_POPULAR = "Популярные" -- the group of CVars players most often look for
L.CONSOLEVARIABLES_FAVORITES = "Избранное" -- the group of CVars the player starred
L.CONSOLEVARIABLES_LOCKED = "Закрепленные" -- the group of CVars the player locked at a value
L.CONSOLEVARIABLES_CHANGED = "Измененные" -- the group of CVars not at their default
L.CONSOLEVARIABLES_ALL = "Все"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CONSOLEVARIABLES_CATEGORY_GRAPHICS = "Графика"
L.CONSOLEVARIABLES_CATEGORY_CONSOLE = "Консоль"
L.CONSOLEVARIABLES_CATEGORY_COMBAT = "Бой"
L.CONSOLEVARIABLES_CATEGORY_GAME = "Игра"
L.CONSOLEVARIABLES_CATEGORY_DEFAULT = "Общие" -- Default
L.CONSOLEVARIABLES_CATEGORY_NET = "Сеть"
L.CONSOLEVARIABLES_CATEGORY_SOUND = "Звук"
L.CONSOLEVARIABLES_CATEGORY_GM = "Гейм-мастер" -- Gm
L.CONSOLEVARIABLES_CATEGORY_REVEAL = "Раскрытые" -- Reveal
L.CONSOLEVARIABLES_CATEGORY_NONE = "Прочее" -- None
L.CONSOLEVARIABLES_NO_MATCH = "Нет консольных переменных по запросу «%s»." -- the search text
L.CONSOLEVARIABLES_NONE_CHANGED = "Все консольные переменные имеют стандартные значения."
L.CONSOLEVARIABLES_NO_FAVORITES = "Щелкните по звездочке у консольной переменной, чтобы держать ее здесь."
L.CONSOLEVARIABLES_NO_LIST = "Этот клиент не дает списка своих консольных переменных. Чтобы найти "
    .. "переменную, введите ее полное название."
L.CONSOLEVARIABLES_DEFAULT = "По умолчанию"
L.CONSOLEVARIABLES_VALUE_IS = "Значение: %s"
L.CONSOLEVARIABLES_DEFAULT_IS = "По умолчанию: %s"
L.CONSOLEVARIABLES_ON_OFF = "Обычно 0 – выкл., 1 – вкл."
L.CONSOLEVARIABLES_ON_OFF_HINT = "Обычно 0 – выкл., а 1 – вкл. Если это не подходит, переменная "
    .. "принимает другие значения: уточните их."
L.CONSOLEVARIABLES_ACCOUNT = "Сохраняется для учетной записи."
L.CONSOLEVARIABLES_CHARACTER = "Сохраняется для этого персонажа."
L.CONSOLEVARIABLES_READ_ONLY = "Только для чтения."
L.CONSOLEVARIABLES_SECURE = "Защищена: изменения ждут окончания боя."
L.CONSOLEVARIABLES_NO_LOCKS = "Щелкните по замку у консольной переменной, чтобы удерживать ее значение "
    .. "при каждом входе и любом изменении."
-- Locks: a locked CVar is put back to its value at login and whenever something changes it.
L.CONSOLEVARIABLES_LOCKED_AT = "Закреплено значение %s: восстанавливается при каждом входе и при любом "
    .. "изменении." -- the locked value
L.CONSOLEVARIABLES_LOCK_HINT = "<Щелкните по замку, чтобы удерживать это значение>" -- tooltip of an open lock
L.CONSOLEVARIABLES_UNLOCK_HINT = "<Щелкните по замку, чтобы перестать его удерживать>" -- tooltip of a closed lock
L.CONSOLEVARIABLES_LOCK_STOPPED = "Не удерживается до перезагрузки или следующего входа: значение не "
    .. "держалось."
L.CONSOLEVARIABLES_LOCK_FAILED = "Не удалось вернуть %s к закрепленному значению %s (сейчас %s). "
    .. "Закрепление ждет перезагрузки или следующего входа." -- CVar name, the locked value, its value now
L.CONSOLEVARIABLES_LOCK_FIGHT = "%s постоянно меняет что-то другое. Закрепление ждет перезагрузки или "
    .. "следующего входа." -- CVar name
-- Popular: the section headers, then each CVar's plain name and what it does.
L.CONSOLEVARIABLES_POP_CAMERA = "Камера"
L.CONSOLEVARIABLES_POP_EFFECTS = "Эффекты экрана"
L.CONSOLEVARIABLES_POP_NAMEPLATES = "Индикаторы здоровья"
L.CONSOLEVARIABLES_POP_MAP = "Карта"
L.CONSOLEVARIABLES_POP_CHAT = "Чат"
L.CONSOLEVARIABLES_POP_COMBAT = "Бой"
L.CONSOLEVARIABLES_POP_INTERFACE = "Интерфейс"
L.CONSOLEVARIABLES_POP_GRAPHICS = "Графика"
L.CONSOLEVARIABLES_POP_SCREENSHOTS = "Снимки экрана"
L.CONSOLEVARIABLES_POP_MOUSE = "Мышь"
L.CONSOLEVARIABLES_POP_ZOOM = "Макс. отдаление камеры"
L.CONSOLEVARIABLES_POP_ZOOM_DESC = "Насколько далеко можно отвести камеру. В настройках предел – 2.0; "
    .. "здесь можно дальше."
L.CONSOLEVARIABLES_POP_ZOOM_SPEED = "Скорость приближения"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED_DESC = "Как быстро колесико мыши приближает и отдаляет камеру. "
    .. "Стандартно 20, максимум 50."
L.CONSOLEVARIABLES_POP_COLLISION = "Столкновения камеры"
L.CONSOLEVARIABLES_POP_COLLISION_DESC = "При 1 деревья и стены могут оказаться между вами и камерой, "
    .. "прежде чем она прыгнет ближе; при 0 – прыгает сразу."
L.CONSOLEVARIABLES_POP_GLOW = "Свечение экрана"
L.CONSOLEVARIABLES_POP_GLOW_DESC = "Мягкое свечение на весь экран. 0 выключает его для более четкой "
    .. "картинки."
L.CONSOLEVARIABLES_POP_DEATH = "Эффект смерти"
L.CONSOLEVARIABLES_POP_DEATH_DESC = "Серое размытие, пока вы мертвы. 0 выключает его."
L.CONSOLEVARIABLES_POP_PLATE_RANGE = "Дальность индикаторов"
L.CONSOLEVARIABLES_POP_PLATE_RANGE_DESC = "На каком расстоянии видны индикаторы здоровья, в метрах. "
    .. "Стандартно 45. Сохраняется для этого персонажа."
L.CONSOLEVARIABLES_POP_PLATE_SPACING = "Интервал индикаторов"
L.CONSOLEVARIABLES_POP_PLATE_SPACING_DESC = "Насколько далеко друг от друга стоят индикаторы в стопке. "
    .. "Чем меньше, тем плотнее. Стандартно 1.1."
L.CONSOLEVARIABLES_POP_PLATE_FAR = "Непрозрачность дальних индикаторов"
L.CONSOLEVARIABLES_POP_PLATE_FAR_DESC = "Насколько бледны дальние индикаторы, от 0 до 1. Стандартно "
    .. "0.6; при 1 они не бледнеют."
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN = "Непрозрачность индикаторов за препятствиями"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN_DESC = "Насколько бледны индикаторы юнитов за стенами, от 0 до 1. "
    .. "Стандартно 0.4."
L.CONSOLEVARIABLES_POP_PLATE_TARGET = "Размер индикатора цели"
L.CONSOLEVARIABLES_POP_PLATE_TARGET_DESC = "Насколько индикатор вашей цели больше остальных. "
    .. "Стандартно 1.2; при 1 – того же размера."
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED = "Размер упрощенных индикаторов"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED_DESC = "Размер упрощенных индикаторов. Стандартно 0.3. Игра "
    .. "может сбрасывать его при входе, поэтому закрепите его, чтобы сохранить свой."
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS = "Индикаторы вражеских тотемов"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS_DESC = "1 показывает индикаторы вражеских тотемов, чтобы их можно "
    .. "было найти и выбрать целью."
L.CONSOLEVARIABLES_POP_PLATE_PETS = "Индикаторы вражеских питомцев"
L.CONSOLEVARIABLES_POP_PLATE_PETS_DESC = "1 показывает индикаторы питомцев вражеских игроков."
L.CONSOLEVARIABLES_POP_COMBO = "Расположение очков серии приемов"
L.CONSOLEVARIABLES_POP_COMBO_DESC = "Где показываются приемы серии: 1 – на рамке цели, 2 – на вашей."
L.CONSOLEVARIABLES_POP_FOG_END = "Дальность тумана"
L.CONSOLEVARIABLES_POP_FOG_END_DESC = "На каком расстоянии туман гуще всего. Стандартно 1600; "
    .. "увеличивайте вместе с дальностью обзора."
L.CONSOLEVARIABLES_POP_FOG_START = "Начало тумана"
L.CONSOLEVARIABLES_POP_FOG_START_DESC = "На каком расстоянии начинается туман. Стандартно 800."
L.CONSOLEVARIABLES_POP_GRASS = "Густота травы"
L.CONSOLEVARIABLES_POP_GRASS_DESC = "Насколько густы трава и мелкие объекты на земле. Стандартно 16; "
    .. "больше – меньше кадров в секунду."
L.CONSOLEVARIABLES_POP_GRASS_DIST = "Дальность травы"
L.CONSOLEVARIABLES_POP_GRASS_DIST_DESC = "На каком расстоянии рисуется трава. Стандартно 70."
L.CONSOLEVARIABLES_POP_ROTATE = "Вращать мини-карту"
L.CONSOLEVARIABLES_POP_ROTATE_DESC = "1 вращает мини-карту вместе с вами, чтобы верх был там, куда вы "
    .. "смотрите."
L.CONSOLEVARIABLES_POP_MAP_FADE = "Затухание карты мира"
L.CONSOLEVARIABLES_POP_MAP_FADE_DESC = "1 делает карту мира прозрачной, пока вы двигаетесь. 0 "
    .. "оставляет ее плотной."
L.CONSOLEVARIABLES_POP_CHAT_SCROLL = "Колесико мыши в чате"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL_DESC = "1 прокручивает чат колесиком мыши."
L.CONSOLEVARIABLES_POP_LOOT_SPAM = "Все броски за добычу"
L.CONSOLEVARIABLES_POP_LOOT_SPAM_DESC = "1 показывает в чате бросок каждого игрока; 0 – только "
    .. "победителя."
L.CONSOLEVARIABLES_POP_QUEUE = "Окно очереди заклинаний"
L.CONSOLEVARIABLES_POP_QUEUE_DESC = "Насколько заранее можно поставить в очередь следующее "
    .. "заклинание, в миллисекундах, от 0 до 400. Стандартно 400."
L.CONSOLEVARIABLES_POP_STOP_ATTACK = "Прекращать атаку при смене цели"
L.CONSOLEVARIABLES_POP_STOP_ATTACK_DESC = "1 прекращает автоатаку при смене цели."
L.CONSOLEVARIABLES_POP_TEXT_SIZE = "Размер текста боя"
L.CONSOLEVARIABLES_POP_TEXT_SIZE_DESC = "Размер всплывающих чисел в бою. Стандартно 1."
L.CONSOLEVARIABLES_POP_ERRORS = "Показывать ошибки Lua"
L.CONSOLEVARIABLES_POP_ERRORS_DESC = "1 открывает окно игры при ошибке в модификации."
L.CONSOLEVARIABLES_POP_COMPARE = "Всегда сравнивать предметы"
L.CONSOLEVARIABLES_POP_COMPARE_DESC = "1 показывает надетое рядом с подсказкой предмета без удержания "
    .. "Shift."
L.CONSOLEVARIABLES_POP_PUSH_SPELLS = "Новые заклинания на панели"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS_DESC = "1 сам ставит изученные заклинания на панели команд. "
    .. "Сохраняется для этого персонажа."
L.CONSOLEVARIABLES_POP_LOOT_RATE = "Скорость автосбора добычи"
L.CONSOLEVARIABLES_POP_LOOT_RATE_DESC = "Миллисекунды между предметами при автосборе добычи. Чем "
    .. "меньше, тем быстрее. Стандартно 150."
L.CONSOLEVARIABLES_POP_FARCLIP = "Дальность обзора"
L.CONSOLEVARIABLES_POP_FARCLIP_DESC = "На каком расстоянии рисуется мир. Стандартно 1000; больше – "
    .. "меньше кадров в секунду."
L.CONSOLEVARIABLES_POP_WEATHER = "Погода"
L.CONSOLEVARIABLES_POP_WEATHER_DESC = "Сколько дождя и снега вы видите, от 0 (нет) до 3. Стандартно 2."
L.CONSOLEVARIABLES_POP_SHOT_QUALITY = "Качество снимков"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY_DESC = "От 1 до 10, чем больше, тем четче и крупнее файл. "
    .. "Стандартно 3."
L.CONSOLEVARIABLES_POP_SHOT_FORMAT = "Формат снимков"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT_DESC = "jpeg (маленькие файлы), png или tga (без потерь, большие "
    .. "файлы)."
L.CONSOLEVARIABLES_POP_RAW_MOUSE = "Прямой ввод мыши"
L.CONSOLEVARIABLES_POP_RAW_MOUSE_DESC = "1 читает мышь напрямую, что может избавить от скачков курсора, "
    .. "когда вы отпускаете камеру."

-- SelfTest
L.SELFTEST_TITLE = "Самопроверка"
L.SELFTEST_DESC = "Проверить API клиента, от которых зависит Forever++, и сохранить результаты для "
    .. "отладки."

-- Screenshots
L.SCREENSHOTS_TITLE = "Снимки экрана"
L.SCREENSHOTS_DESC = "Делать снимки Forever++ в собственных окнах игры, один за другим, для его "
    .. "страниц и публикаций."

-- Controller Mode
L.CONTROLLERMODE_TITLE = "Режим контроллера"
L.CONTROLLERMODE_DESC = "Держать одну настройку для интерфейса контроллера и другую для клавиатуры и "
    .. "мыши: у каждой свой профиль Forever++, макет режима редактирования и набор модификаций. При "
    .. "входе в игру с другим интерфейсом включается его настройка."
L.CONTROLLERMODE_NOTE = "Выберите, что использует каждый интерфейс. Когда этот персонаж входит в игру с "
    .. "другим интерфейсом, Forever++ переключается на его профиль и макет режима редактирования и "
    .. "предлагает перезагрузку, только если загруженные модификации не совпадают с его набором. То, "
    .. "что вы меняете вручную, остается до следующей смены интерфейса. Этот выбор общий для всех "
    .. "профилей, а в выбранном здесь профиле включен режим контроллера."
L.CONTROLLERMODE_NOW = "Сейчас в игре: %s" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_GAMEPAD = "Контроллер"
L.CONTROLLERMODE_MKB = "Клавиатура и мышь"
L.CONTROLLERMODE_NO_CHANGE = "Не менять"
L.CONTROLLERMODE_PROFILE = "Профиль Forever++"
L.CONTROLLERMODE_PROFILE_DESC = "Профиль, на который этот персонаж переключается с этим интерфейсом."
L.CONTROLLERMODE_LAYOUT = "Макет режима редактирования"
L.CONTROLLERMODE_LAYOUT_DESC = "Макет режима редактирования для этого интерфейса. Игра предлагает "
    .. "макет только для того интерфейса, для которого он создан."
L.CONTROLLERMODE_ADDONS = "Модификации"
L.CONTROLLERMODE_ADDONS_NONE = "Не менять"
L.CONTROLLERMODE_ADDONS_SAVED = "Включено модификаций: %d" -- number of addons
L.CONTROLLERMODE_ADDONS_SAVE = "Использовать текущие"
L.CONTROLLERMODE_ADDONS_SAVE_DESC = "Сохранить, какие модификации сейчас включены у этого персонажа, "
    .. "как набор этого интерфейса. Модификация, установленная позже, не затрагивается, пока вы не "
    .. "сохраните снова."
L.CONTROLLERMODE_ADDONS_CLEAR = "Очистить"
L.CONTROLLERMODE_ADDONS_CLEAR_DESC = "Забыть набор этого интерфейса, чтобы его модификации не "
    .. "затрагивались."
L.CONTROLLERMODE_APPLY = "Настроить сейчас"
L.CONTROLLERMODE_APPLY_DESC = "Переключиться на настройку того интерфейса, который сейчас показывает "
    .. "игра."
L.CONTROLLERMODE_NOTHING = "Для интерфейса «%s» менять нечего." -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_RELOAD = "Режим контроллера Forever++: ваши модификации не совпадают с набором для "
    .. "интерфейса «%s»." -- interface
L.CONTROLLERMODE_RELOAD_ON = "Включить: %s" -- addon names
L.CONTROLLERMODE_RELOAD_OFF = "Выключить: %s" -- addon names
L.CONTROLLERMODE_RELOAD_ASK = "Изменить их и перезагрузить интерфейс сейчас?"
L.CONTROLLERMODE_AND_MORE = "%s и еще %d" -- addon names, number of addons

-- Taint Watcher
L.TAINTWATCHER_TITLE = "Наблюдение за порчей"
L.TAINTWATCHER_DESC = "Следить за списком заданий, журналом заданий, картой мира и списком окон игры, "
    .. "отмечая значения, которые туда записала модификация: именно из-за них игра потом сообщает, что "
    .. "действие интерфейса заблокировано из-за модификации. Каждое найденное значение с временем "
    .. "появляется в «Перехвате ошибок» и в /fpp taint. Помогает найти, что что-то сломало."

-- Profiler
L.PROFILER_TITLE = "Профилировщик ЦП"
L.PROFILER_DESC = "Смотреть на странице в настройках, сколько процессорного времени занимает каждый "
    .. "модуль, чтобы найти, что тормозит."

-- Gear Probe
L.GEARPROBE_TITLE = "Проверка снаряжения"
L.GEARPROBE_DESC = "Считать, что этот клиент сообщает о вашем снаряжении, вкладках талантов и "
    .. "характеристиках, для работы над модулем «Стрелки улучшений»."
