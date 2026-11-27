local _, ns = ...
local L = ns.NewLocale("zhTW")
if not L then
    return
end

-- Lib/Text.lua: lengths of time, for slider labels and price lines
L.TEXT_SECONDS = { "%d秒" }
L.TEXT_MINUTES = { "%d分鐘" }
L.TEXT_HOURS = { "%d小時" }
L.TEXT_AGO_NOW = "剛剛"
L.TEXT_AGO_MINUTES = "%d分鐘前" -- minutes
L.TEXT_AGO_HOURS = "%d小時前" -- hours
L.TEXT_AGO_DAYS = "%d天前" -- days
L.TEXT_YARDS = "%s碼" -- a distance; the game's own words are used when it has them
L.SLIDER_YARDS = "%d碼" -- a slider's value in yards, worded like TEXT_YARDS

-- Lib/ItemStats.lua: an Equip: bonus written as a plain stat, an amount and the stat's name
L.ITEMSTATS_SHORT = "+%s %s"
L.ITEMSTATS_SHORT_PERCENT = "+%s%% %s"
L.ITEMSTATS_SHORT_AND = "%s和%s" -- two short stats of one line

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
L.KEY_NONE = "無"
-- Added to a key dropdown's description with the controller interface on; each %s is a trigger
-- as the player's controller shows it
L.KEY_PAD_NOTE = "開啟控制器介面時，改為按住%s或%s。"
L.SKIP_KEY = "略過按鍵" -- the option of every module that a held key skips

-- Lib/MapPins.lua: icons on the world map.
-- Click hints are written as Blizzard's instruction lines are: in angle brackets, the keys and the
-- click as separate words with no hyphen or plus ("Ctrl click"), no full stop. One click to a line.
L.MAPPINS_HINT_WAYPOINT = "<按住Ctrl鍵點擊以設定地圖標記>"
-- The options of icons on the world map: their size, opacity, and whether continent maps show
-- them, the same in every module that has them.
L.MAPPINS_SIZE = "圖示大小"
L.MAPPINS_SIZE_DESC = "圖示相對於正常大小的比例。"
L.MAPPINS_OPACITY = "透明度"
L.MAPPINS_OPACITY_DESC = "圖示的不透明程度。數值越低，越能看見底下的地圖。"
L.MAPPINS_CONTINENTS = "顯示於大陸地圖"
L.MAPPINS_CONTINENTS_DESC = "除了區域地圖，也在大陸地圖和世界地圖上顯示。"
-- Lib/Sounds.lua: the alert sounds, in every Sound dropdown
L.SOUND_NAME = "音效"
L.SOUND_OFF = "關閉"
L.SOUND_BUZZ = "錯誤提示音"
L.SOUND_DENIED = "拒絕"
L.SOUND_HORN = "戰爭號角"
L.SOUND_BOSS = "首領警告"
L.SOUND_GM = "GM提醒"
L.SOUND_ALARM = "鬧鐘"
L.SOUND_WHISPER = "悄悄話"

-- Core: /fpp and chat
L.ON = "開啟"
L.OFF = "關閉"
L.MODULE_STATE = "%s：%s。" -- module name, on/off
L.MODULE_ALWAYS_ON = "%s是工具，永遠開啟。" -- module title, such as Self Test
L.NO_MODULE = "沒有名為%s的模組"
L.COMMAND_NEEDS_MODULE = "/fpp %s需要「%s」，但它在模組頁面上是關閉的。" -- command, title
L.SLASH_MODULES = "模組（/fpp toggle <name>、/fpp list）："
L.SLASH_OPEN = "開啟設定"
L.SLASH_LIST = "列出所有模組及其開關狀態"
L.SLASH_TOGGLE = "開啟或關閉一個模組，或其中一個核取方塊"
L.SLASH_RESET = "將所有設定恢復為預設值（會重新載入）"
L.RESET_CONFIRM = "要將Forever++的所有設定恢復為預設值，並清除它儲存的所有資料，"
    .. "例如拍賣價格和飛行時間嗎？這會重新載入介面。"
L.SLASH_OPTIONS = "列出它的選項和目前的值"
L.SLASH_SET = "變更一個選項（on/off、選項值或數字）"
L.SLASH_TAKEN = "%s已被其他插件使用，因此Forever++將它留給該插件。"

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s：%s。選項（/fpp set %s <option> <value>）：" -- module, on/off, module
L.OPTIONS_NONE = "無"
L.OPTIONS_DEBUG = "，偵錯"
L.SET_USAGE = "用法：/fpp set <module> <option> [value]"
L.MODULE_STATE_ALLOWED = "%s：%s（on、off）。" -- module name, on/off
L.NO_OPTION = "%s沒有名為%s的選項。輸入/fpp options %s可列出所有選項。" -- module, option, module
L.OPTION_STATE = "%s %s：%s。" -- module, option, value
L.OPTION_STATE_ALLOWED = "%s %s：|cffffd100%s|r（%s）。" -- module, option, value, allowed values
L.CHAT_MESSAGES = "聊天訊息" -- a module's checkbox for what it says in chat by itself

-- Lib/Profiles.lua: profiles, and /fpp profiles
L.PROFILES_DEFAULT = "預設" -- the profile everyone starts with, which is always there
L.PROFILES_NAME_EMPTY = "設定檔需要一個名稱。"
L.PROFILES_NAME_TAKEN = "已經有名為%s的設定檔。" -- name
L.PROFILES_DEFAULT_ALWAYS = "「預設」設定檔永遠存在，無法重新命名或刪除。"
L.SLASH_PROFILE = "列出所有設定檔，或將此角色切換至其中一個"
L.PROFILES_HEADER = "設定檔（/fpp profiles <name>可切換）："
L.PROFILES_CHARACTERS = { "%d個角色" } -- how many use a profile
L.PROFILES_SWITCHED = "現在使用%s設定檔。" -- profile name
L.PROFILES_AFTER_COMBAT = "戰鬥結束後將切換至%s設定檔。" -- profile name
L.PROFILES_NO_SUCH = "沒有名為%s的設定檔。輸入/fpp profiles可列出所有設定檔。" -- what was typed

-- Settings
-- The Modules page's groups of modules.
L.CATEGORY_AUTOMATION = "自動化"
L.CATEGORY_CHARACTER = "角色"
L.CATEGORY_CHAT = "聊天"
L.CATEGORY_INTERFACE = "介面"
L.CATEGORY_ITEMS = "物品"
L.CATEGORY_MAP = "地圖"
L.CATEGORY_QUESTS = "任務"
L.CATEGORY_SYSTEM = "系統"
L.CATEGORY_UNITS = "單位"
L.CATEGORY_OTHER = "其他"
L.DEBUG = "偵錯"
L.SETTINGS_AFTER_COMBAT = "設定將在戰鬥結束後開啟。"
L.MODULES = "模組" -- the page with every module's checkbox, the top Forever++ entry
L.ABOUT = "關於" -- the page with the version, links, credits, and commands
-- The selected module on the Modules page
L.SETTINGS_ENABLED = "啟用" -- the module's own on/off checkbox, under its description
-- What a greyed-out option needs (`needs`), in red in its tooltip: an addon's or module's name
L.SETTINGS_NEEDS_ADDON = "需要%s插件。"
L.SETTINGS_NEEDS_MODULE = "需要開啟「%s」模組。"
L.SETTINGS_NEEDS_CLIENT = "這個版本的遊戲缺少它所需的功能。"
-- A notice on a module whose Blizzard frame the controller interface hides (ns.Gamepad.HidesNotice).
L.SETTINGS_CONTROLLER_HIDDEN = "在控制器介面下無作用"
L.SETTINGS_CONTROLLER_HIDDEN_DESC = "控制器介面會隱藏這個模組所變更的內容，並以自己的介面取代，"
    .. "因此控制器介面開啟時，這個模組沒有作用。"
-- And on one that needs a mouse, a held key, or a window its cursor can't reach (LimitedNotice).
L.SETTINGS_CONTROLLER_LIMITED = "在控制器介面下功能受限"
L.SETTINGS_CONTROLLER_LIMITED_DESC = "這個模組的部分或全部功能需要滑鼠點擊、拖曳、按住按鍵，"
    .. "或是控制器游標無法觸及的視窗，因此控制器介面開啟時無作用。"
-- An option XP Bar Text and Reputation Bar Text share (Lib/StatusBars.lua)
L.STATUSBARS_SOLID = "完整進度條"
L.STATUSBARS_SOLID_DESC = "移除進度條上的分隔線，讓它成為一條完整的進度條。"
-- The tooltip of the padlock in a locked module's checkbox's place
L.SETTINGS_LOCKED = "已關閉並鎖定：遊戲使這個模組的功能失效。詳情請見它的設定。"
L.SETTINGS_OPTIONS = "選項" -- the header over its options
L.SETTINGS_NO_OPTIONS = "這個模組沒有選項。"
L.SETTINGS_CONFLICT_GO = "前往%s" -- an option's name
-- A mark on an item or action button icon (Lib/ItemButtons.lua): its corner, size, and padding,
-- the same in every module that has one.
L.ICONMARK_CORNER = "角落"
L.ICONMARK_CORNER_TOPLEFT = "左上"
L.ICONMARK_CORNER_TOPRIGHT = "右上"
L.ICONMARK_CORNER_BOTTOMLEFT = "左下"
L.ICONMARK_CORNER_BOTTOMRIGHT = "右下"
L.ICONMARK_PIXELS = "%d像素" -- a size or padding slider's value
L.ICONMARK_PADDING = "內邊距"
L.ICONMARK_PADDING_DESC = "標示與所在角落的距離：設為2時，左上角的標示會向右移2像素、向下移2像素。"
-- Under a mark's Corner option while Upgrade Arrows has an arrow in the same corner
L.ICONMARK_CONFLICT_ARROW = "「升級箭頭」也會在這個角落顯示箭頭，兩者會重疊。請為其中一個選擇其他角落。"
L.ICONMARK_CONFLICT_DOWN = "「升級箭頭」也會在這個角落顯示降級箭頭，兩者會重疊。請為其中一個選擇其他角落。"
L.ICONMARK_SECTION_SHOW = "顯示位置" -- the header over the places a module marks items in
L.ICONMARK_PLACE_BAGS = "背包"
L.ICONMARK_PLACE_MERCHANT = "商人"
L.ICONMARK_PLACE_AUCTION = "拍賣場"
L.ICONMARK_PLACE_LOOT = "拾取"
L.ICONMARK_PLACE_QUESTS = "任務獎勵"
L.SETTINGS_PAGE_NOTE = "開啟時，它的「%s」頁面會出現在側邊欄的Forever++底下。"
    .. "選擇其他頁面後，該頁面才會出現或消失。"
L.SETTINGS_TURN_ON = "開啟" -- the button on a "Blizzard's ... is off" row
L.SETTINGS_RESET = "重置為預設" -- the arrow at the end of an option's row while it's changed
L.SETTINGS_RESET_TO = "預設值：%s" -- what the option goes back to
L.SETTINGS_RESET_PAIR = "%s，%s" -- a checkbox's default, then its slider's, in one row
L.SETTINGS_CHECKED = "已勾選" -- a checkbox's default
L.SETTINGS_UNCHECKED = "未勾選"
L.SETTINGS_SEARCH = "搜尋模組" -- gray text in the Modules page's empty search box
L.SETTINGS_NO_MATCH = "沒有符合「%s」的模組。" -- the search text
L.SETTINGS_NEW_ONLY = "新" -- the checkbox beside the search box that lists only modules marked NEW
L.SETTINGS_NOTHING_NEW = "沒有新內容。" -- the Modules list while that checkbox is on and nothing is new

-- Settings: the Profiles page
L.PROFILES = "設定檔"
L.PROFILES_USES = "%s使用" -- a character's name, before the dropdown of its profile
L.PROFILES_USES_TITLE = "此角色的設定檔"
L.PROFILES_USES_DESC = "%s使用的設定檔。你在Forever++中所做的變更都會儲存到這個設定檔，"
    .. "所有使用它的角色都會套用。" -- character
L.PROFILES_NEW_CHARACTERS = "新角色使用"
L.PROFILES_NEW_CHARACTERS_DESC = "角色第一次登入時使用的設定檔。"
L.PROFILES_NEW = "新增設定檔"
L.PROFILES_NEW_DESC = "建立設定檔：複製目前選擇的設定檔、從預設值建立，或從%s建立。" -- a preset's name, or PRESETS_A_PRESET
L.PROFILES_NEW_ASK = "為新設定檔命名。"
L.PROFILES_NEW_FROM = "要將%s建立為%s的複本、從預設值建立，還是從%s建立？" -- new name, selected profile, a preset's name or PRESETS_A_PRESET
L.PROFILES_PRESET = "基於" -- beside the dropdown of the preset a profile follows
L.PROFILES_PRESET_NONE = "無" -- a profile based on no preset
L.PROFILES_PRESET_DESC = "%s所依循的範本：你沒有自行設定的部分會讀取範本的值，"
    .. "因此日後版本更新範本時會跟著更新，而復原箭頭會將設定恢復為範本的值。"
    .. "選擇範本會保留你自行選擇的所有設定。選擇「無」會將設定檔目前的內容保留為你自己的設定，"
    .. "並不再依循範本。" -- profile
L.PROFILES_PRESET_AFTER_COMBAT = "戰鬥結束後將變更%s所基於的範本。" -- profile
L.PRESETS_A_PRESET = "範本" -- in PROFILES_NEW_DESC and PROFILES_NEW_FROM, with more than one
L.PRESETS_MORE = "範本..." -- a popup button that opens a menu of every preset
L.PRESETS_NO_SUCH = "沒有名為%s的範本。" -- what was asked for
L.PRESETS_DEVELOPER_DESC = "在預設值之上，加上開發者自己使用的模組和選項。"
L.PROFILES_COPY_OF = "%s的複本" -- a profile
L.PROFILES_FROM_DEFAULTS = "從預設值"
L.PROFILES_IN_USE = "此角色正在使用"
L.PROFILES_SUMMARY = "已開啟%d個模組，%d項設定與預設值不同。"
L.PROFILES_USED_BY = "使用者：%s。" -- character names
L.PROFILES_UNUSED = "沒有角色使用。"
L.PROFILES_USE = "此角色使用"
L.PROFILES_USE_DESC = "立即將%s切換為%s，不需重新載入。" -- character, profile
L.PROFILES_RENAME = "重新命名"
L.PROFILES_RENAME_DESC = "為%s取另一個名稱。" -- profile
L.PROFILES_RENAME_ASK = "將%s重新命名為：" -- profile
L.PROFILES_DELETE = "刪除"
L.PROFILES_DELETE_DESC = "刪除%s。使用它的角色會改回「預設」。" -- profile
L.PROFILES_DELETE_ASK = "要刪除%s嗎？使用它的角色會改回「預設」。" -- profile
L.PROFILES_CHARACTERS_HEADER = "角色"
L.PROFILES_CHARACTER_LINE = "等級%d %s" -- level, class
L.PROFILES_THIS_CHARACTER = "此角色"
L.PROFILES_USES_OTHER = "使用%s" -- the profile another character uses
L.PROFILES_CHECK_DESC = "勾選以讓%s使用%s。" -- character, profile
L.PROFILES_UNCHECK_DESC = "取消勾選以讓%s改回「預設」。" -- character
L.PROFILES_ON_DEFAULT_DESC = "每個角色都會使用一個設定檔。若要讓%s不再使用「預設」，"
    .. "請在其他設定檔中勾選它。" -- character
L.PROFILES_FORGET_HINT = "右鍵點擊以忘記這個角色。"
L.PROFILES_FORGET_ASK = "要忘記%s嗎？它會從這個清單中移除，直到再次登入。" -- character
L.PROFILES_NOTE = "設定檔包含哪些模組開啟、模組的設定、你在編輯模式中放置Forever++框架的位置、"
    .. "以「可移動視窗」移動的視窗位置，以及小地圖按鈕的快速切換。"
    .. "拍賣價格、採集點、見過的玩家，以及每個角色各自保存的內容（例如天賦規劃）不包含在內。"
L.PROFILES_SHARE = "分享"
L.PROFILES_EXPORT = "匯出"
L.PROFILES_EXPORT_DESC = "將%s顯示為一行文字，可複製後傳給別人，或保存作為備份。" -- profile
L.PROFILES_EXPORT_ASK = "%s的文字內容。按Ctrl+C複製後傳給別人，或保存作為備份。" -- profile
L.PROFILES_IMPORT = "匯入"
L.PROFILES_IMPORT_DESC = "貼上別人匯出的設定檔，作為新設定檔，或覆蓋%s。" -- profile
L.PROFILES_IMPORT_ASK = "按Ctrl+V貼上別人匯出的設定檔。"
-- What the pasted text holds: name, Forever++ version, modules on, settings changed
L.PROFILES_IMPORT_FOUND = "%s，以Forever++ %s製作。\n已開啟%d個模組，%d項設定與預設值不同。"
L.PROFILES_IMPORT_NEW = "匯入為新設定檔"
L.PROFILES_IMPORT_REPLACE = "取代%s" -- the selected profile
L.PROFILES_IMPORT_BAD = "這不是Forever++設定檔。請複製完整的一行後再貼上一次。"
L.PROFILES_IMPORT_CANT = "這個用戶端無法讀取壓縮的設定檔。"
L.PROFILES_IMPORT_NEWER = "這個設定檔來自較新版本的Forever++。請更新後再匯入。"
L.PROFILES_IMPORTED = "匯入的設定檔" -- the name of an import whose own name is empty
L.PROFILES_IMPORT_DONE = "已匯入%s。" -- profile
L.PROFILES_MODULES_NOTE = "設定檔：%s" -- beside the Modules page's title, with more than one
L.DEFAULTS_ASK_PROFILE = "要將%s設定檔的Forever++設定恢復為預設值嗎？所有使用它的角色也會跟著改變。"
    .. "遊戲的其他設定維持不變。" -- profile

-- Settings: Changelog page. The notes themselves are in Changelog.lua.
L.CHANGELOG = "更新記錄"
L.CHANGELOG_RELEASE = "%s（%s）" -- version, date
L.CHANGELOG_UNRELEASED = "尚未發布"
L.CHANGELOG_SEARCH = "搜尋更新內容" -- gray text in the Changelog page's empty search box
L.CHANGELOG_BY_MODULE = "依模組分類" -- checkbox that groups a release's notes under their modules
L.CHANGELOG_GENERAL = "一般" -- heading, with By Module on, for notes about no one module
L.CHANGELOG_NO_MATCH = "沒有符合「%s」的更新內容。" -- the search text
L.CHANGELOG_CHANGES = { "%d項變更" } -- how many entries a release has
L.CHANGELOG_ADDED = "新增"
L.CHANGELOG_CHANGED = "變更"
L.CHANGELOG_FIXED = "修正"
L.CHANGELOG_REMOVED = "移除"
L.CHANGELOG_CONTROLLER = "控制器介面"
L.CHANGELOG_SETTINGS = "設定"
L.CHANGELOG_COMMANDS = "指令"

-- Settings: the About page
L.HOME_TAGLINE = "為WoW Forever的預設介面帶來各種小小的增添與改變。"
L.HOME_DEFAULTS = "預設值"
-- The popup of the Defaults button at the top right of the Modules, Changelog, and About pages
L.DEFAULTS_ASK = "要將Forever++的所有設定恢復為預設值嗎？這會取代你目前的Forever++設定。"
    .. "遊戲的其他設定維持不變。"
L.DEFAULTS_DEVELOPER = "開發者的預設值"
L.DEFAULTS_RECOMMENDED = "建議的預設值"
L.HOME_MODULES_ON = "已開啟%d個模組，共%d個" -- on, total
L.HOME_GAME_BUILD = "遊戲 %s（%s）" -- version, build
L.HOME_LINKS = "連結"
L.HOME_LINK_CURSEFORGE = "CurseForge"
L.HOME_LINK_WAGO = "Wago"
L.HOME_LINK_SOURCE = "原始碼"
L.HOME_LINK_RELEASES = "版本發布"
L.HOME_LINK_BUG = "回報錯誤"
L.HOME_LINK_REQUEST = "功能建議"
L.HOME_LINK_HINT = "點擊一個連結以複製網址。"
L.HOME_COPY = "按Ctrl+C複製連結。"
L.HOME_CREDITS = "製作人員"
L.HOME_AUTHOR = "作者"
L.HOME_EVERYONE = "所有人" -- the last name in the credits: the players
L.HOME_EVERYONE_THANKS = "感謝你們持續不斷的錯誤回報、建議與意見回饋。"
L.HOME_WORKS_WITH = "相容插件"
L.HOME_QUEST_DATA = "%s的任務資料" -- the modules that read QuestieDB
L.HOME_SUPPORT = "在%s中提供額外支援" -- the module or option another addon adds to
L.HOME_COMMANDS = "指令"
L.HOME_COMMANDS_GENERAL = "一般" -- the commands no one module owns
L.HOME_COMMANDS_SEARCH = "搜尋"
L.HOME_COMMANDS_HINT = "<點擊以在聊天中輸入指令>"

-- Edit Mode dialog for our own frames (Lib/EditMode.lua)
L.EDITMODE_SCALE = "比例"
L.SETTINGS_EDIT_MODE_NOTE = "它的位置和版面配置在編輯模式中設定：按Esc，選擇編輯模式，"
    .. "然後點擊它。" -- a gray row on a module with Edit Mode settings
L.SETTINGS_EDIT_MODE_NOTE_DESC = "它的位置、比例和版面配置設定，位於編輯模式中的設定對話框"
    .. "和右鍵選單裡，就在它們所調整的框架旁邊。"

-- The gray row on a module another addon adds (Lib/Plugins.lua)
L.PLUGIN_NOTICE = "由其他插件新增。"
L.PLUGIN_NOTICE_ADDON = "由%s插件新增。" -- the addon's folder name
L.PLUGIN_NOTICE_DESC = "這個模組不屬於Forever++：是其他插件將它加到這裡的。"
    .. "如有問題，請告知該插件的作者。"
-- Gray rows on a module that reads the QuestieDB addon's data (Lib/QuestieDB.lua)
L.QUESTIEDB_NEEDED = "需要QuestieDB插件。"
L.QUESTIEDB_NEEDED_DESC = "它的任務、生物、物品和物件資料來自QuestieDB，這是另一個獨立的插件。"
    .. "請下載並安裝，在插件清單中開啟它，然後重新載入。在此之前，這個模組無法開啟。"
L.QUESTIEDB_LOCKED = "已鎖定：這個模組需要QuestieDB插件。請下載後重新載入。"
L.QUESTIEDB_PROBLEM = "這個版本的QuestieDB與Forever++不相容。"
L.QUESTIEDB_PROBLEM_DESC = "QuestieDB已開啟，但它回應的方式與Forever++讀取的方式不符。"
    .. "請更新兩者中較舊的那一個。"
