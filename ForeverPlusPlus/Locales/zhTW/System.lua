local _, ns = ...
local L = ns.NewLocale("zhTW")
if not L then
    return
end

-- ErrorCatcher
L.ERRORCATCHER_TITLE = "錯誤捕捉器"
L.ERRORCATCHER_DESC = "安靜地捕捉Lua錯誤和被阻擋的動作，而不是顯示在暴雪的錯誤視窗中，"
    .. "之後可以用/fpp errors或小地圖按鈕，在可複製文字的視窗中查看。"
L.ERRORCATCHER_CHAT_DESC = "捕捉到錯誤時在聊天中通知你。"
L.ERRORCATCHER_SOUND_DESC = "捕捉到錯誤時播放音效，最多每10秒一次。選擇音效時會播放一次。"
L.ERRORCATCHER_SHOW = "錯誤"
L.ERRORCATCHER_SHOW_BUTTON = "顯示"
L.ERRORCATCHER_SHOW_DESC = "開啟顯示目前已捕捉錯誤的視窗。"
L.ERRORCATCHER_CLEAR = "清除"
L.ERRORCATCHER_CLEAR_NAME = "已儲存的錯誤"
L.ERRORCATCHER_CLEAR_DESC = "忘記所有登入期間儲存的每一個錯誤。"
L.ERRORCATCHER_CLEAR_CONFIRM = "要忘記所有已儲存的錯誤嗎？"
L.ERRORCATCHER_COMMAND = "顯示捕捉到的Lua錯誤"
L.ERRORCATCHER_CAUGHT = "捕捉到錯誤：%s 輸入/fpp errors即可查看。" -- first line of the error
L.ERRORCATCHER_CAUGHT_LOADING = "登入時捕捉到%d個錯誤。輸入/fpp errors即可查看。"
L.ERRORCATCHER_OTHER_HANDLER = "另一個插件（例如BugGrabber）正在捕捉Lua錯誤，"
    .. "因此錯誤捕捉器只會看到被阻擋的動作和警告。"
L.ERRORCATCHER_OTHER_HANDLER_DESC = "Lua錯誤會改交給該插件處理，例如顯示在BugSack的視窗中。"
    .. "暴雪的錯誤視窗和被阻擋動作的彈出視窗也交由它處理。"
L.ERRORCATCHER_BLOCKED = "%s：%s嘗試呼叫受保護的函式%s。" -- event, addon, function
-- Where: the first few of Blizzard's functions on the stack, such as "SmartNavigation.lua:84 < Menu.lua:2143"
L.ERRORCATCHER_BLOCKED_SILENT = "遊戲顯示「介面功能因插件而失效」，但沒有指出是哪一個插件，位置：%s。"
L.ERRORCATCHER_SECRET = "（遊戲隱藏了這個錯誤的文字。）"
L.ERRORCATCHER_UNKNOWN = "未知"
L.ERRORCATCHER_THIS_SESSION = "本次登入"
L.ERRORCATCHER_LAST_SESSION = "上次登入"
L.ERRORCATCHER_ALL = "所有登入"
L.ERRORCATCHER_FILTER = "%s（%d）" -- a filter above, how many errors it shows
L.ERRORCATCHER_SUMMARY = "本次登入%d個，已儲存%d個" -- errors this session, errors saved
L.ERRORCATCHER_NONE = "沒有捕捉到錯誤。"
L.ERRORCATCHER_KIND_BLOCKED = "被阻擋的動作"
L.ERRORCATCHER_KIND_TAINT = "汙染"
L.ERRORCATCHER_POSITION = "第%d個，共%d個" -- this one, how many
L.ERRORCATCHER_ROW_INFO = "%d次，%s" -- times seen, how long ago ("12m ago")
-- times, session, first and last time it happened, how long ago ("12m ago")
-- The forms go by the times.
L.ERRORCATCHER_META = {
    "出現%d次（第%d次登入），首次於%s，最後一次於%s（%s）。",
}
L.ERRORCATCHER_STACK = "堆疊："
L.ERRORCATCHER_LOCALS = "區域變數："
L.ERRORCATCHER_NO_STACK = "沒有堆疊：被阻擋的動作和警告不會附帶堆疊。"
-- What was going on when an action was blocked, in place of a stack.
L.ERRORCATCHER_CONTEXT = "發生時的狀況："
L.ERRORCATCHER_CONTEXT_COMBAT = "戰鬥中：%s"
L.ERRORCATCHER_CONTEXT_INSTANCE = "副本：%s" -- none, party, raid, pvp, arena, scenario
L.ERRORCATCHER_CONTEXT_MOUSE = "滑鼠指向：%s" -- a frame's name, such as TargetFrame
L.ERRORCATCHER_CONTEXT_MENUS = "開啟的選單：%s" -- menu tags, such as MENU_UNIT_TARGET
L.ERRORCATCHER_CONTEXT_GAMEPAD = "控制器介面：%s"
L.ERRORCATCHER_CONTEXT_TAINT_LOG = "汙染記錄開啟：%s"
-- Values in the controller navigation's tables that addon code wrote, each on a line of its own.
L.ERRORCATCHER_CONTEXT_STATE = "由插件寫入的控制器狀態：%s"
-- The value's name, the addon, the time first seen, and the windows open then.
L.ERRORCATCHER_CONTEXT_STATE_LINE = "  %s，由%s寫入，首次出現於%s，當時開啟的視窗：%s"
-- A value's name, and how many more beside it in the same table were written at the same time.
L.ERRORCATCHER_CONTEXT_STATE_MORE = "%s（以及旁邊的另外%d個）"
-- When the watch began: a value first seen at this time was already written before it.
L.ERRORCATCHER_CONTEXT_STATE_SINCE = "  （自%s起監看）"
L.ERRORCATCHER_CONTEXT_YES = "是"
L.ERRORCATCHER_CONTEXT_NO = "否"
L.ERRORCATCHER_CONTEXT_NONE = "無"
L.ERRORCATCHER_TAINT_HINT = "在錯誤捕捉器的設定中開啟「汙染記錄」，下次發生時，"
    .. "遊戲會把是哪個插件的程式碼造成的寫入遊戲資料夾中的Logs\\taint.log。"
L.ERRORCATCHER_TAINT_LOG = "汙染記錄"
L.ERRORCATCHER_TAINT_LOG_DESC = "遊戲本身的設定之一：它會把每個被阻擋動作背後是哪個插件的程式碼，"
    .. "寫入遊戲資料夾中的Logs\\taint.log。追查問題時開啟，之後再關閉，因為檔案增長得很快。"
L.ERRORCATCHER_COPY = "複製錯誤回報"
L.ERRORCATCHER_COPY_HINT = "已選取。按Ctrl+C複製。"
L.ERRORCATCHER_TEST = "測試錯誤"
L.ERRORCATCHER_TEST_BUTTON = "觸發"
L.ERRORCATCHER_TEST_DESC = "刻意引發一個Lua錯誤，檢查錯誤捕捉器（或它關閉時暴雪的錯誤視窗）是否會捕捉到。"
L.ERRORCATCHER_TEST_MESSAGE = "Forever++測試錯誤。一切正常。"

-- AddOnsList
L.ADDONSLIST_TITLE = "插件列表"
L.ADDONSLIST_DESC = "顯示不含類別標題的插件列表，並把已啟用的插件排在前面。"
L.ADDONSLIST_ENABLEDFIRST = "已啟用的在前"
L.ADDONSLIST_ENABLEDFIRST_DESC = "將已啟用的插件列在已停用的插件上方。"
L.ADDONSLIST_UNGROUP = "停用的不分組"
L.ADDONSLIST_UNGROUP_DESC = "將已停用的插件從其分組移到列表的停用區，讓分組只顯示開啟的插件。"
L.ADDONSLIST_NOTES = "搜尋說明"
L.ADDONSLIST_NOTES_DESC = "讓搜尋框也能找到插件說明中的文字。"
L.ADDONSLIST_SETS = "插件組合"
L.ADDONSLIST_SETS_DESC = "在「全部停用」旁加入「組合」下拉選單，可將目前開啟的插件以一個名稱儲存，"
    .. "之後再為列表顯示的角色重新開啟該組合。Forever++會保持開啟。按「確定」即可以該組合重新載入。"
L.ADDONSLIST_SETS_BUTTON = "組合"
L.ADDONSLIST_SETS_NONE = "沒有已儲存的組合"
L.ADDONSLIST_SETS_SAVE = "儲存目前組合..."
L.ADDONSLIST_SETS_SAVE_PROMPT = "將目前開啟的插件儲存為組合，名稱："
L.ADDONSLIST_SETS_REPLACE_CONFIRM = "要以目前開啟的插件取代插件組合「%s」嗎？"
L.ADDONSLIST_SETS_DELETE = "刪除組合"
L.ADDONSLIST_SETS_DELETE_CONFIRM = "要刪除插件組合「%s」嗎？"
L.ADDONSLIST_SETS_SAVED = "已儲存插件組合%s。"
L.ADDONSLIST_SETS_MISSING = "插件組合%s中未安裝的插件：%d個。"
L.ADDONSLIST_CHAT_DESC = "儲存組合時，以及開啟組合時有多少插件未安裝，在聊天中通知你。"

-- MinimapButton
L.MINIMAPBUTTON_TITLE = "小地圖按鈕"
L.MINIMAPBUTTON_DESC = "在小地圖上、插件收納盒中或兩處都放一個Forever++按鈕：點擊開啟快速切換"
    .. "（由下方的「快速切換」選擇要提供哪些模組），右鍵點擊開啟設定，按住Shift點擊查看捕捉到的錯誤。"
L.MINIMAPBUTTON_SECTION_BUTTON = "按鈕"
L.MINIMAPBUTTON_SECTION_TOGGLES = "快速切換"
L.MINIMAPBUTTON_SECTION_ERRORS = "錯誤"
L.MINIMAPBUTTON_WHERE = "顯示位置"
L.MINIMAPBUTTON_WHERE_DESC = "按鈕的位置：小地圖上、小地圖下方的插件收納盒中，或兩處都放。"
    .. "拖曳小地圖按鈕可沿著小地圖移動它。"
L.MINIMAPBUTTON_WHERE_MINIMAP = "小地圖"
L.MINIMAPBUTTON_WHERE_COMPARTMENT = "插件收納盒"
L.MINIMAPBUTTON_WHERE_BOTH = "兩者"
L.MINIMAPBUTTON_COMPARTMENT_COUNT = "%s（%d）" -- Forever++, errors this session
L.MINIMAPBUTTON_TIP_SESSION = "本次登入的錯誤"
L.MINIMAPBUTTON_TIP_SAVED = "已儲存的錯誤"
L.MINIMAPBUTTON_TIP_NONE = "無" -- a count of 0 errors
-- The quick toggles' groups, by what you're doing (Menu Order's Activity).
L.MINIMAPBUTTON_GROUP_LOOT = "商人和拾取"
L.MINIMAPBUTTON_GROUP_NPCS = "NPC和任務"
L.MINIMAPBUTTON_GROUP_WORLD = "在野外"
L.MINIMAPBUTTON_GROUP_NAMEPLATES = "名條"
L.MINIMAPBUTTON_GROUP_GATHERING = "採集"
L.MINIMAPBUTTON_GATHERING_SHOWS = "採集地圖顯示" -- over its kinds' checkboxes: Herbs, Ore...
L.MINIMAPBUTTON_GROUP_OTHER = "其他"
-- The button in the module's settings that picks the quick toggles: a menu with a submenu per
-- module category, with checkboxes; and the line at the bottom of the quick toggles that opens it.
L.MINIMAPBUTTON_CUSTOMIZE_NAME = "快速切換"
L.MINIMAPBUTTON_CUSTOMIZE = "自訂"
L.MINIMAPBUTTON_CUSTOMIZE_DESC = "依類別選擇按鈕的快速切換要提供哪些模組。"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN = "自訂..."
-- The quick toggles' submenu of profiles, with more than one: the profile in use
L.MINIMAPBUTTON_PROFILE = "設定檔：%s"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN_DESC = "在小地圖按鈕的設定中，選擇這個選單要提供哪些模組。"
L.MINIMAPBUTTON_CUSTOMIZE_RESET = "重置為預設"
L.MINIMAPBUTTON_MENU_CUSTOMIZE = "選單中顯示自訂"
L.MINIMAPBUTTON_MENU_CUSTOMIZE_DESC = "在快速切換的最下方顯示「自訂...」。關閉時，請用下方的「自訂」按鈕選擇。"
L.MINIMAPBUTTON_MENU_PROFILES = "選單中顯示設定檔"
L.MINIMAPBUTTON_MENU_PROFILES_DESC = "當你有一個以上的設定檔時，在快速切換中顯示「設定檔」子選單，用來切換設定檔。"
-- The tooltip's hints: what a click does, then the click.
L.MINIMAPBUTTON_HINT_SETTINGS = "開啟設定"
L.MINIMAPBUTTON_HINT_WELCOME = "關於Forever++"
L.MINIMAPBUTTON_HINT_TOGGLES = "快速切換"
L.MINIMAPBUTTON_HINT_ERRORS = "顯示錯誤"
L.MINIMAPBUTTON_HINT_CLEAR = "清除本次登入的錯誤"
L.MINIMAPBUTTON_HINT_CLEAR_ALL = "清除所有錯誤"
L.MINIMAPBUTTON_HINT_MOVE = "移動按鈕"
L.MINIMAPBUTTON_PLACE_NAME = "按鈕位置"
L.MINIMAPBUTTON_PLACE_RESET_DESC = "將小地圖按鈕放回它一開始所在的小地圖邊緣。拖曳它可放在小地圖上或周圍的任何地方。"
-- The tooltip's legend: what each click does, the click at the right in green. Named as Blizzard's
-- instruction lines name clicks ("Ctrl click", "Right click"): separate words, no hyphen.
L.MINIMAPBUTTON_LEFT_CLICK = "點擊"
L.MINIMAPBUTTON_RIGHT_CLICK = "右鍵點擊"
L.MINIMAPBUTTON_KEY_LEFT_CLICK = "按住%s鍵點擊" -- a key, such as Shift
L.MINIMAPBUTTON_KEY_RIGHT_CLICK = "按住%s鍵右鍵點擊" -- the same, with Click Opens Quick Toggles on
L.MINIMAPBUTTON_SWAP = "點擊開啟快速切換"
L.MINIMAPBUTTON_SWAP_DESC = "點擊開啟快速切換，右鍵點擊開啟設定。關閉時則相反。"
L.MINIMAPBUTTON_KEYS_LEFT = "錯誤按鍵用於點擊"
L.MINIMAPBUTTON_KEYS_LEFT_DESC = "讓錯誤相關的按鍵保留在點擊上（例如按住Shift點擊顯示錯誤），"
    .. "而不是移到和設定一起的右鍵點擊。"
L.MINIMAPBUTTON_MENU_SIDE = "選單方向"
L.MINIMAPBUTTON_MENU_SIDE_DESC = "快速切換從游標往哪個方向開啟：像暴雪開啟選單一樣，或在游標的左側或右側。"
L.MINIMAPBUTTON_MENU_SIDE_AUTO = "自動"
L.MINIMAPBUTTON_MENU_SIDE_LEFT = "左"
L.MINIMAPBUTTON_MENU_SIDE_RIGHT = "右"
L.MINIMAPBUTTON_MENU_ORDER = "選單排序"
L.MINIMAPBUTTON_MENU_ORDER_DESC = "快速切換的排列方式：依你正在做的事分組（商人和拾取、NPC和任務等）、"
    .. "依模組頁面的類別，或依名稱排成一個清單。"
L.MINIMAPBUTTON_MENU_ORDER_GROUPS = "活動"
L.MINIMAPBUTTON_MENU_ORDER_CATEGORY = "類別"
L.MINIMAPBUTTON_MENU_ORDER_TITLE = "依名稱"
L.MINIMAPBUTTON_LEFT_DRAG = "拖曳"
L.MINIMAPBUTTON_ERRORS_KEY = "顯示錯誤按鍵"
L.MINIMAPBUTTON_ERRORS_KEY_DESC = "錯誤捕捉器開啟時，點擊按鈕顯示錯誤時要按住的按鍵。"
L.MINIMAPBUTTON_CLEAR_KEY = "清除本次登入按鍵"
L.MINIMAPBUTTON_CLEAR_KEY_DESC = "錯誤捕捉器開啟時，點擊按鈕清除本次登入錯誤時要按住的按鍵。"
L.MINIMAPBUTTON_CLEAR_ALL_KEY = "全部清除按鍵"
L.MINIMAPBUTTON_CLEAR_ALL_KEY_DESC = "錯誤捕捉器開啟時，點擊按鈕清除所有登入期間儲存的每一個錯誤時要按住的按鍵。"
    .. "會先詢問。"

-- Commands
L.COMMANDS_TITLE = "斜線指令"
L.COMMANDS_DESC = "加入簡短的斜線指令：/rl重新載入介面，/clear清空聊天視窗，/kb設定按鍵，/pull開始"
    .. "開怪倒數。/way位於「導航點」。"
L.COMMANDS_RELOAD = "/rl"
L.COMMANDS_RELOAD_DESC = "/rl會像/reload一樣重新載入介面。若其他插件已使用/rl，則留給該插件。"
L.COMMANDS_RELOAD_HELP = "重新載入介面" -- a line of /fpp help, like the SLASH_ ones
L.COMMANDS_CLEAR_HELP = "清空輸入指令的聊天視窗"
L.COMMANDS_CLEAR = "/clear"
L.COMMANDS_CLEAR_DESC = "/clear會清空你輸入指令的聊天視窗。若其他插件已使用/clear，則留給該插件。"
L.COMMANDS_KEYBIND = "/kb"
L.COMMANDS_KEYBIND_DESC = "/kb會開啟「快速按鍵設定模式」，與「按鍵設定」中的按鈕相同：將滑鼠指向一個動作"
    .. "按鈕，然後按下按鍵。僅限非戰鬥中。若其他插件已使用/kb，則留給該插件。"
L.COMMANDS_KEYBIND_HELP = "開啟「快速按鍵設定模式」"
L.COMMANDS_KEYBIND_BLOCKED = "戰鬥中或編輯模式開啟時無法開啟「快速按鍵設定模式」。"
L.COMMANDS_PULL = "/pull"
L.COMMANDS_PULL_DESC = "/pull 10會開始遊戲的開怪計時，也就是/countdown開始的倒數，持續10秒；不寫數字時"
    .. "也是10秒。/pull 0會停止它。若首領插件或其他插件已使用/pull，則留給該插件。"
L.COMMANDS_PULL_HELP = "開始遊戲的開怪倒數，不寫數字時為10秒"
L.COMMANDS_PULL_USAGE = "輸入/pull和倒數的秒數，例如/pull 10；輸入/pull 0停止倒數。"

-- HideBetaFeedback
L.HIDEBETAFEEDBACK_TITLE = "隱藏測試版意見回饋"
L.HIDEBETAFEEDBACK_DESC = "隱藏測試版在提示資訊中的「Press F6 to submit an issue」一行，以及它的錯誤回報按鈕。"
    .. "F6仍可回報問題。"
L.HIDEBETAFEEDBACK_TOOLTIP = "隱藏提示資訊提醒"
L.HIDEBETAFEEDBACK_TOOLTIP_DESC = "隱藏提示資訊中的「Press F6 to submit an issue」一行。"
L.HIDEBETAFEEDBACK_BUTTON = "隱藏錯誤回報按鈕"
L.HIDEBETAFEEDBACK_BUTTON_DESC = "隱藏浮動的錯誤回報按鈕。"
L.HIDEBETAFEEDBACK_QUEST = "隱藏任務意見回饋"
L.HIDEBETAFEEDBACK_QUEST_DESC = "隱藏任務視窗上的意見回饋按鈕。"

-- MovableFramerate
L.MOVABLEFRAMERATE_TITLE = "可移動幀率顯示"
L.MOVABLEFRAMERATE_DESC = "像暴雪本身的框架一樣，在編輯模式中移動幀數文字（Ctrl+R）並調整大小。"
    .. "在你移動它之前，它會留在暴雪原本的位置。"
