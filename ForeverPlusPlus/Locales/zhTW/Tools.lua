local _, ns = ...
local L = ns.NewLocale("zhTW")
if not L then
    return
end

-- ConsoleVariables
L.CONSOLEVARIABLES_TITLE = "主控台變數"
-- Debug (its title, L.DEBUG, is in Core.lua)
L.DEBUG_DESC = "在設定側邊欄的「偵錯」頁面中顯示每個模組的偵錯選項和測試工具（自我測試、裝備探測、擷圖），"
    .. "並開啟它們的指令。"
L.DEBUG_NOTICE = "關閉「偵錯」會將所有偵錯選項恢復為預設值。" -- a gray row atop the module
L.DEBUG_NOTICE_DESC = "這樣在這裡設定的東西就不會在你看不到的地方繼續運作。"
-- ConsoleVariables
L.CONSOLEVARIABLES_DESC = "在設定中的頁面瀏覽遊戲的主控台變數（CVar）並加以變更，"
    .. "還能鎖定你想保留的變數，即使是遊戲每次登入都會改回的變數也一樣。"
L.CONSOLEVARIABLES_CHAT_DESC = "已鎖定的主控台變數無法維持其數值時，在聊天中通知你。"
-- A gray row atop the module while it's off with console variables locked
L.CONSOLEVARIABLES_LOCKS_OFF = "這個模組關閉時，已鎖定的主控台變數不會被保留。"
L.CONSOLEVARIABLES_LOCKS_OFF_DESC = "在它再次開啟之前，這些變數會恢復為遊戲設定的值。"
L.CONSOLEVARIABLES_COMMAND = "開啟「主控台變數」，並搜尋[search]"
L.CONSOLEVARIABLES_NO_PAGE = "這個用戶端的設定無法開啟「主控台變數」頁面。"
L.CONSOLEVARIABLES_AFTER_COMBAT = "%s會在戰鬥結束後變更。" -- CVar name
L.CONSOLEVARIABLES_REFUSED = "%s無法變更。" -- CVar name
L.CONSOLEVARIABLES_KEPT = "%s維持為%s：遊戲不接受%s。" -- CVar name, its value, the typed one
L.CONSOLEVARIABLES_SEARCH = "搜尋主控台變數" -- gray text in the empty search box
L.CONSOLEVARIABLES_POPULAR = "常用" -- the group of CVars players most often look for
L.CONSOLEVARIABLES_FAVORITES = "最愛" -- the group of CVars the player starred
L.CONSOLEVARIABLES_LOCKED = "已鎖定" -- the group of CVars the player locked at a value
L.CONSOLEVARIABLES_CHANGED = "已變更" -- the group of CVars not at their default
L.CONSOLEVARIABLES_ALL = "全部"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CONSOLEVARIABLES_CATEGORY_GRAPHICS = "影像"
L.CONSOLEVARIABLES_CATEGORY_CONSOLE = "主控台"
L.CONSOLEVARIABLES_CATEGORY_COMBAT = "戰鬥"
L.CONSOLEVARIABLES_CATEGORY_GAME = "遊戲"
L.CONSOLEVARIABLES_CATEGORY_DEFAULT = "一般" -- Default
L.CONSOLEVARIABLES_CATEGORY_NET = "網路"
L.CONSOLEVARIABLES_CATEGORY_SOUND = "音效"
L.CONSOLEVARIABLES_CATEGORY_GM = "遊戲管理員" -- Gm
L.CONSOLEVARIABLES_CATEGORY_REVEAL = "揭示" -- Reveal
L.CONSOLEVARIABLES_CATEGORY_NONE = "其他" -- None
L.CONSOLEVARIABLES_NO_MATCH = "沒有符合「%s」的主控台變數。" -- the search text
L.CONSOLEVARIABLES_NONE_CHANGED = "每個主控台變數都是預設值。"
L.CONSOLEVARIABLES_NO_FAVORITES = "點擊主控台變數上的星號，即可將它保留在這裡。"
L.CONSOLEVARIABLES_NO_LIST = "這個用戶端不會列出它的主控台變數。請搜尋變數的完整名稱來找到它。"
L.CONSOLEVARIABLES_DEFAULT = "預設"
L.CONSOLEVARIABLES_VALUE_IS = "數值：%s"
L.CONSOLEVARIABLES_DEFAULT_IS = "預設值：%s"
L.CONSOLEVARIABLES_ON_OFF = "0通常代表關閉，1通常代表開啟。"
L.CONSOLEVARIABLES_ON_OFF_HINT = "0通常代表關閉，1代表開啟。若不是這樣，它會接受其他數值：請查詢一下。"
L.CONSOLEVARIABLES_ACCOUNT = "為你的帳號儲存。"
L.CONSOLEVARIABLES_CHARACTER = "為此角色儲存。"
L.CONSOLEVARIABLES_READ_ONLY = "無法變更。"
L.CONSOLEVARIABLES_SECURE = "受保護：變更會等到戰鬥結束。"
L.CONSOLEVARIABLES_NO_LOCKS = "點擊主控台變數上的鎖，即可讓它的數值在每次登入和變更後都維持不變。"
-- Locks: a locked CVar is put back to its value at login and whenever something changes it.
L.CONSOLEVARIABLES_LOCKED_AT = "鎖定為%s：每次登入以及任何東西變更它時，都會恢復為此數值。" -- the locked value
L.CONSOLEVARIABLES_LOCK_HINT = "<點擊鎖以保留此數值>" -- tooltip of an open lock
L.CONSOLEVARIABLES_UNLOCK_HINT = "<點擊鎖以停止保留>" -- tooltip of a closed lock
L.CONSOLEVARIABLES_LOCK_STOPPED = "在你重新載入或再次登入之前不會保留：它無法維持。"
L.CONSOLEVARIABLES_LOCK_FAILED = "%s無法恢復為鎖定的%s（目前為%s）。它的鎖會等到你重新載入或再次登入。" -- CVar name, the locked value, its value now
L.CONSOLEVARIABLES_LOCK_FIGHT = "%s一直被其他東西變更。它的鎖會等到你重新載入或再次登入。" -- CVar name
-- Popular: the section headers, then each CVar's plain name and what it does.
L.CONSOLEVARIABLES_POP_CAMERA = "鏡頭"
L.CONSOLEVARIABLES_POP_EFFECTS = "畫面效果"
L.CONSOLEVARIABLES_POP_NAMEPLATES = "名條"
L.CONSOLEVARIABLES_POP_MAP = "地圖"
L.CONSOLEVARIABLES_POP_CHAT = "聊天"
L.CONSOLEVARIABLES_POP_COMBAT = "戰鬥"
L.CONSOLEVARIABLES_POP_INTERFACE = "介面"
L.CONSOLEVARIABLES_POP_GRAPHICS = "影像"
L.CONSOLEVARIABLES_POP_SCREENSHOTS = "擷圖"
L.CONSOLEVARIABLES_POP_MOUSE = "滑鼠"
L.CONSOLEVARIABLES_POP_ZOOM_DESC = "鏡頭最遠可以拉多遠。選項中最多到2.0；這裡可以更遠。"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED = "縮放速度"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED_DESC = "滑鼠滾輪縮放鏡頭的速度。預設20，最高50。"
L.CONSOLEVARIABLES_POP_COLLISION = "鏡頭碰撞"
L.CONSOLEVARIABLES_POP_COLLISION_DESC = "1會讓樹木和牆壁擋在你和鏡頭之間一陣子才拉近鏡頭；0則會立即拉近。"
L.CONSOLEVARIABLES_POP_GLOW = "畫面光暈"
L.CONSOLEVARIABLES_POP_GLOW_DESC = "覆蓋整個畫面的柔和光暈。0會關閉它，讓畫面更銳利。"
L.CONSOLEVARIABLES_POP_DEATH_DESC = "死亡時的灰色模糊效果。0會關閉它。"
L.CONSOLEVARIABLES_POP_PLATE_RANGE = "名條距離"
L.CONSOLEVARIABLES_POP_PLATE_RANGE_DESC = "名條在多遠以內顯示，以碼為單位。預設45。為此角色儲存。"
L.CONSOLEVARIABLES_POP_PLATE_SPACING = "名條間距"
L.CONSOLEVARIABLES_POP_PLATE_SPACING_DESC = "堆疊的名條之間相隔多遠。數值越低越緊密。預設1.1。"
L.CONSOLEVARIABLES_POP_PLATE_FAR = "遠處名條透明度"
L.CONSOLEVARIABLES_POP_PLATE_FAR_DESC = "遠處名條的淡化程度，0到1。預設0.6；1永不淡化。"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN = "隱藏單位透明度"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN_DESC = "牆後單位名條的淡化程度，0到1。預設0.4。"
L.CONSOLEVARIABLES_POP_PLATE_TARGET = "目標名條大小"
L.CONSOLEVARIABLES_POP_PLATE_TARGET_DESC = "你目標的名條要放大多少。預設1.2；1為相同大小。"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED = "簡化名條大小"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED_DESC = "簡化名條的大小。預設0.3。遊戲可能會在登入時將它改回預設值，"
    .. "所以請鎖定它以保留你的數值。"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS = "敵方圖騰名條"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS_DESC = "1會在敵方圖騰上顯示名條，讓你能找到並選取它們。"
L.CONSOLEVARIABLES_POP_PLATE_PETS = "敵方寵物名條"
L.CONSOLEVARIABLES_POP_PLATE_PETS_DESC = "1會在敵方玩家的寵物上顯示名條。"
L.CONSOLEVARIABLES_POP_COMBO = "連擊點數位置"
L.CONSOLEVARIABLES_POP_COMBO_DESC = "連擊點數顯示的位置：1在目標框架上，2在你的框架上。"
L.CONSOLEVARIABLES_POP_FOG_END = "霧氣距離"
-- [quotes: FARCLIP]
L.CONSOLEVARIABLES_POP_FOG_END_DESC = "遠方霧氣最濃的距離。預設1600；可配合「視野距離」調高。"
L.CONSOLEVARIABLES_POP_FOG_START = "霧氣起始"
L.CONSOLEVARIABLES_POP_FOG_START_DESC = "遠方霧氣開始出現的距離。預設800。"
L.CONSOLEVARIABLES_POP_GRASS = "草地密度"
L.CONSOLEVARIABLES_POP_GRASS_DESC = "草地和地面雜物的密度。預設16；越高越耗幀數。"
L.CONSOLEVARIABLES_POP_GRASS_DIST = "草地距離"
L.CONSOLEVARIABLES_POP_GRASS_DIST_DESC = "草地繪製的距離。預設70。"
L.CONSOLEVARIABLES_POP_ROTATE_DESC = "1會讓小地圖跟著你轉動，讓上方永遠是你面向的方向。"
L.CONSOLEVARIABLES_POP_MAP_FADE = "世界地圖淡化"
L.CONSOLEVARIABLES_POP_MAP_FADE_DESC = "1會在你移動時淡化世界地圖。0讓它保持不透明。"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL = "聊天滑鼠滾輪"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL_DESC = "1會讓滑鼠滾輪捲動聊天。"
L.CONSOLEVARIABLES_POP_LOOT_SPAM = "完整拾取擲骰"
L.CONSOLEVARIABLES_POP_LOOT_SPAM_DESC = "1會在聊天中顯示每位玩家的擲骰；0只顯示贏家。"
L.CONSOLEVARIABLES_POP_QUEUE = "法術佇列時間"
L.CONSOLEVARIABLES_POP_QUEUE_DESC = "你可以多早預先排入下一個法術，以毫秒為單位，0到400。預設400。"
L.CONSOLEVARIABLES_POP_STOP_ATTACK = "切換目標時停止攻擊"
L.CONSOLEVARIABLES_POP_STOP_ATTACK_DESC = "1會在你切換目標時停止自動攻擊。"
L.CONSOLEVARIABLES_POP_TEXT_SIZE = "戰鬥文字大小"
L.CONSOLEVARIABLES_POP_TEXT_SIZE_DESC = "浮動戰鬥數字的大小。預設1。"
L.CONSOLEVARIABLES_POP_ERRORS = "顯示Lua錯誤"
L.CONSOLEVARIABLES_POP_ERRORS_DESC = "1會在插件發生錯誤時彈出遊戲的錯誤視窗。"
L.CONSOLEVARIABLES_POP_COMPARE = "總是比較物品"
L.CONSOLEVARIABLES_POP_COMPARE_DESC = "1會在物品提示資訊旁顯示你身上的裝備，不必按住Shift。"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS = "新法術放上快捷列"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS_DESC = "1會自動把你學會的法術放上快捷列。為此角色儲存。"
L.CONSOLEVARIABLES_POP_LOOT_RATE = "自動拾取速度"
L.CONSOLEVARIABLES_POP_LOOT_RATE_DESC = "自動拾取每件物品之間的毫秒數。數值越低越快。預設150。"
L.CONSOLEVARIABLES_POP_FARCLIP_DESC = "世界繪製的距離。預設1000；越高越耗幀數。"
L.CONSOLEVARIABLES_POP_WEATHER = "天氣"
L.CONSOLEVARIABLES_POP_WEATHER_DESC = "你看到的雨雪多寡，0（無）到3。預設2。"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY = "擷圖品質"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY_DESC = "1到10，越高越清晰、檔案越大。預設3。"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT = "擷圖格式"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT_DESC = "jpeg（檔案小）、png或tga（無損，檔案大）。"
L.CONSOLEVARIABLES_POP_RAW_MOUSE = "原始滑鼠輸入"
L.CONSOLEVARIABLES_POP_RAW_MOUSE_DESC = "1會直接讀取滑鼠，可以避免放開鏡頭時游標跳動。"

-- SelfTest
L.SELFTEST_TITLE = "自我測試"
L.SELFTEST_DESC = "探測Forever++所依賴的用戶端API並儲存其結果，供偵錯使用。"

-- Screenshots
L.SCREENSHOTS_TITLE = "擷圖"
L.SCREENSHOTS_DESC = "在遊戲本身的視窗中逐一擷取Forever++的畫面，用於其頁面和貼文。"

-- Controller Mode
L.CONTROLLERMODE_TITLE = "控制器模式"
L.CONTROLLERMODE_DESC = "為控制器介面和鍵盤與滑鼠各保留一套設定：各自的Forever++設定檔、編輯模式版面配置和一組插件。"
    .. "以另一種介面登入時，會切換到它的設定。"
L.CONTROLLERMODE_NOTE = "選擇每種介面要使用什麼。此角色以另一種介面登入時，Forever++會切換到其設定檔和編輯模式版面配置，"
    .. "只有在載入的插件不是其插件組合時才會要求重新載入。你手動變更的內容會保留，直到介面再次改變。"
    .. "這些選擇由所有設定檔共用，在這裡選擇的設定檔會開啟「控制器模式」。"
L.CONTROLLERMODE_NOW = "遊戲目前顯示：%s" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_GAMEPAD = "控制器"
L.CONTROLLERMODE_MKB = "鍵盤與滑鼠"
L.CONTROLLERMODE_NO_CHANGE = "不變更"
L.CONTROLLERMODE_PROFILE = "Forever++設定檔"
L.CONTROLLERMODE_PROFILE_DESC = "此角色在這種介面下切換到的設定檔。"
L.CONTROLLERMODE_LAYOUT = "編輯模式版面配置"
L.CONTROLLERMODE_LAYOUT_DESC = "在這種介面下使用的編輯模式版面配置。遊戲只會在版面配置所屬的介面上提供它。"
L.CONTROLLERMODE_ADDONS_NONE = "不變更"
L.CONTROLLERMODE_ADDONS_SAVED = "已開啟%d個插件" -- number of addons
L.CONTROLLERMODE_ADDONS_SAVE = "使用目前的"
L.CONTROLLERMODE_ADDONS_SAVE_DESC = "將此角色目前開啟的插件儲存為這種介面的插件組合。之後安裝的插件不受影響，直到你再次儲存。"
L.CONTROLLERMODE_ADDONS_CLEAR = "清除"
L.CONTROLLERMODE_ADDONS_CLEAR_DESC = "忘記這種介面的插件組合，讓它的插件不受影響。"
L.CONTROLLERMODE_APPLY = "立即套用"
L.CONTROLLERMODE_APPLY_DESC = "切換到遊戲目前所顯示之介面的設定。"
L.CONTROLLERMODE_NOTHING = "%s沒有需要變更的內容。" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_RELOAD = "Forever++控制器模式：你的插件不是為%s儲存的插件組合。" -- interface
L.CONTROLLERMODE_RELOAD_ON = "開啟：%s" -- addon names
L.CONTROLLERMODE_RELOAD_OFF = "關閉：%s" -- addon names
L.CONTROLLERMODE_RELOAD_ASK = "要變更它們並立即重新載入嗎？"
L.CONTROLLERMODE_AND_MORE = "%s，以及其他%d個" -- addon names, number of addons

-- Taint Watcher
L.TAINTWATCHER_TITLE = "汙染監看器"
L.TAINTWATCHER_DESC = "監看任務追蹤器、任務日誌、世界地圖和遊戲的視窗清單中是否有插件寫入的值，"
    .. "這正是之後讓遊戲顯示「介面功能因插件而失效」的原因。每個發現的值都會連同時間"
    .. "列在錯誤捕捉器和/fpp taint中。用來找出是什麼弄壞了東西。"
-- Profiler
L.PROFILER_TITLE = "CPU分析器"
L.PROFILER_DESC = "在設定中的頁面查看每個模組占用多少CPU，以找出哪裡變慢。"

-- Gear Probe
L.GEARPROBE_TITLE = "裝備探測"
L.GEARPROBE_DESC = "讀取這個用戶端對你的裝備、天賦分頁和屬性所提供的資訊，供開發「升級箭頭」使用。"
