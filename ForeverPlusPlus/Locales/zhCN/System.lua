local _, ns = ...
local L = ns.NewLocale("zhCN")
if not L then
    return
end

-- ErrorCatcher
L.ERRORCATCHER_TITLE = "错误捕获"
L.ERRORCATCHER_DESC = "悄悄捕获Lua错误和被阻止的操作，而不是弹出暴雪的错误窗口，之后可在一个能复制内容的窗口"
    .. "中查看，使用/fpp errors或小地图按钮打开。"
L.ERRORCATCHER_CHAT_DESC = "捕获到错误时在聊天中提示。"
L.ERRORCATCHER_SOUND_DESC = "捕获到错误时播放声音，最多每10秒一次。选择一个声音时会播放它。"
L.ERRORCATCHER_SHOW = "错误"
L.ERRORCATCHER_SHOW_BUTTON = "显示"
L.ERRORCATCHER_SHOW_DESC = "打开显示目前已捕获错误的窗口。"
L.ERRORCATCHER_CLEAR = "清除"
L.ERRORCATCHER_CLEAR_NAME = "已保存的错误"
L.ERRORCATCHER_CLEAR_DESC = "忘记所有已保存的错误，包括每一次登录的。"
L.ERRORCATCHER_CLEAR_CONFIRM = "忘记所有已保存的错误？"
L.ERRORCATCHER_COMMAND = "显示已捕获的Lua错误"
L.ERRORCATCHER_CAUGHT = "捕获到一个错误：%s 输入/fpp errors查看。" -- first line of the error
L.ERRORCATCHER_CAUGHT_LOADING = "登录时捕获到%d个错误。输入/fpp errors查看。"
L.ERRORCATCHER_OTHER_HANDLER = "另一个插件（例如BugGrabber）正在捕获Lua错误，因此“错误捕获”只能看到被阻止的"
    .. "操作和警告。"
L.ERRORCATCHER_OTHER_HANDLER_DESC = "Lua错误会交给那个插件处理，例如BugSack的窗口。暴雪的错误窗口及其被阻止操作的"
    .. "弹出窗口也交由它处理。"
L.ERRORCATCHER_BLOCKED = "%s：%s试图调用受保护的函数%s。" -- event, addon, function
-- Where: the first few of Blizzard's functions on the stack, such as "SmartNavigation.lua:84 < Menu.lua:2143"
L.ERRORCATCHER_BLOCKED_SILENT = "游戏提示“插件导致界面行为失效”，但没有指明是哪个插件，位置：%s。"
L.ERRORCATCHER_SECRET = "（游戏隐藏了此错误的文字。）"
L.ERRORCATCHER_UNKNOWN = "未知"
L.ERRORCATCHER_THIS_SESSION = "本次登录"
L.ERRORCATCHER_LAST_SESSION = "上次登录"
L.ERRORCATCHER_ALL = "所有登录"
L.ERRORCATCHER_FILTER = "%s（%d）" -- a filter above, how many errors it shows
L.ERRORCATCHER_SUMMARY = "本次登录%d个，已保存%d个" -- errors this session, errors saved
L.ERRORCATCHER_NONE = "未捕获到错误。"
L.ERRORCATCHER_KIND_BLOCKED = "被阻止的操作"
L.ERRORCATCHER_KIND_TAINT = "污染"
L.ERRORCATCHER_POSITION = "%d/%d" -- this one, how many
L.ERRORCATCHER_ROW_INFO = "%d次，%s" -- times seen, how long ago ("12m ago")
-- times, session, first and last time it happened, how long ago ("12m ago")
-- The forms go by the times.
L.ERRORCATCHER_META = {
    "出现%d次，第%d次登录，首次于%s，最近于%s（%s）。",
}
L.ERRORCATCHER_STACK = "调用栈："
L.ERRORCATCHER_LOCALS = "局部变量："
L.ERRORCATCHER_NO_STACK = "没有调用栈：被阻止的操作和警告不附带调用栈。"
-- What was going on when an action was blocked, in place of a stack.
L.ERRORCATCHER_CONTEXT = "发生时："
L.ERRORCATCHER_CONTEXT_COMBAT = "战斗中：%s"
L.ERRORCATCHER_CONTEXT_INSTANCE = "副本：%s" -- none, party, raid, pvp, arena, scenario
L.ERRORCATCHER_CONTEXT_MOUSE = "鼠标指向：%s" -- a frame's name, such as TargetFrame
L.ERRORCATCHER_CONTEXT_MENUS = "打开的菜单：%s" -- menu tags, such as MENU_UNIT_TARGET
L.ERRORCATCHER_CONTEXT_GAMEPAD = "手柄界面：%s"
L.ERRORCATCHER_CONTEXT_TAINT_LOG = "污染日志开启：%s"
-- Values in the controller navigation's tables that addon code wrote, each on a line of its own.
L.ERRORCATCHER_CONTEXT_STATE = "被插件写入的手柄状态：%s"
-- The value's name, the addon, the time first seen, and the windows open then.
L.ERRORCATCHER_CONTEXT_STATE_LINE = "  %s，由%s写入，首次发现于%s，当时打开的窗口：%s"
-- A value's name, and how many more beside it in the same table were written at the same time.
L.ERRORCATCHER_CONTEXT_STATE_MORE = "%s（同时还有%d个）"
-- When the watch began: a value first seen at this time was already written before it.
L.ERRORCATCHER_CONTEXT_STATE_SINCE = "  （自%s起监视）"
L.ERRORCATCHER_CONTEXT_YES = "是"
L.ERRORCATCHER_CONTEXT_NO = "否"
L.ERRORCATCHER_CONTEXT_NONE = "无"
L.ERRORCATCHER_TAINT_HINT = "在“错误捕获”的设置中开启“污染日志”，下次再发生时，游戏会把导致它的插件代码写入"
    .. "游戏文件夹中的Logs\\taint.log。"
L.ERRORCATCHER_TAINT_LOG = "污染日志"
L.ERRORCATCHER_TAINT_LOG_DESC = "游戏自己的一项设置：它会把每次被阻止的操作背后是哪个插件的代码写入游戏文件夹中的"
    .. "Logs\\taint.log。排查问题时开启，排查完后关闭，因为这个文件增长得很快。"
L.ERRORCATCHER_COPY = "复制错误报告"
L.ERRORCATCHER_COPY_HINT = "已选中。按Ctrl+C复制。"
L.ERRORCATCHER_TEST = "测试错误"
L.ERRORCATCHER_TEST_BUTTON = "抛出"
L.ERRORCATCHER_TEST_DESC = "故意引发一个Lua错误，检查“错误捕获”（关闭时则是暴雪的错误窗口）能否捕获它。"
L.ERRORCATCHER_TEST_MESSAGE = "Forever++测试错误。一切正常。"

-- AddOnsList
L.ADDONSLIST_TITLE = "插件列表"
L.ADDONSLIST_DESC = "显示没有分类标题的插件列表，已启用的插件排在最前。"
L.ADDONSLIST_ENABLEDFIRST = "已启用的优先"
L.ADDONSLIST_ENABLEDFIRST_DESC = "把已启用的插件排在已禁用的插件上方。"
L.ADDONSLIST_UNGROUP = "取消禁用插件的分组"
L.ADDONSLIST_UNGROUP_DESC = "把已禁用的插件移出其分组，放到列表中已禁用的部分，让分组只显示已开启的插件。"
L.ADDONSLIST_NOTES = "搜索说明"
L.ADDONSLIST_NOTES_DESC = "让搜索框也能在插件的说明中查找文字。"
L.ADDONSLIST_SETS = "插件组合"
L.ADDONSLIST_SETS_DESC = "在“全部禁用”旁加入“组合”下拉菜单，可为列表显示的角色把当前开启的插件以一个名字保存，"
    .. "之后再重新开启这一组合。Forever++始终保持开启。点击“确定”即可按该组合重新加载。"
L.ADDONSLIST_SETS_BUTTON = "组合"
L.ADDONSLIST_SETS_NONE = "没有已保存的组合"
L.ADDONSLIST_SETS_SAVE = "保存当前组合……"
L.ADDONSLIST_SETS_SAVE_PROMPT = "把当前开启的插件保存为组合，名称："
L.ADDONSLIST_SETS_REPLACE_CONFIRM = "用当前开启的插件替换插件组合“%s”？"
L.ADDONSLIST_SETS_DELETE = "删除组合"
L.ADDONSLIST_SETS_DELETE_CONFIRM = "删除插件组合“%s”？"
L.ADDONSLIST_SETS_SAVED = "已保存插件组合%s。"
L.ADDONSLIST_SETS_MISSING = "插件组合%s中未安装的插件：%d个。"
L.ADDONSLIST_CHAT_DESC = "保存组合时，以及开启组合时有多少插件未安装，在聊天中提示。"

-- MinimapButton
L.MINIMAPBUTTON_TITLE = "小地图按钮"
L.MINIMAPBUTTON_DESC = "在小地图上、插件收纳栏中或两处都放一个Forever++按钮：点击打开快捷开关（下面的“快捷开关”"
    .. "决定其中有哪些模块），右键点击打开设置，按住Shift点击查看已捕获的错误。"
L.MINIMAPBUTTON_SECTION_BUTTON = "按钮"
L.MINIMAPBUTTON_SECTION_TOGGLES = "快捷开关"
L.MINIMAPBUTTON_SECTION_ERRORS = "错误"
L.MINIMAPBUTTON_WHERE = "显示位置"
L.MINIMAPBUTTON_WHERE_DESC = "按钮放在哪里：小地图上、其下方的插件收纳栏中，或两处都放。拖动小地图按钮可让它绕着"
    .. "小地图移动。"
L.MINIMAPBUTTON_WHERE_MINIMAP = "小地图"
L.MINIMAPBUTTON_WHERE_COMPARTMENT = "插件收纳栏"
L.MINIMAPBUTTON_WHERE_BOTH = "两者"
L.MINIMAPBUTTON_COMPARTMENT_COUNT = "%s（%d）" -- Forever++, errors this session
L.MINIMAPBUTTON_TIP_SESSION = "本次登录的错误"
L.MINIMAPBUTTON_TIP_SAVED = "已保存的错误"
L.MINIMAPBUTTON_TIP_NONE = "无" -- a count of 0 errors
-- The quick toggles' groups, by what you're doing (Menu Order's Activity).
L.MINIMAPBUTTON_GROUP_LOOT = "商人和战利品"
L.MINIMAPBUTTON_GROUP_NPCS = "NPC和任务"
L.MINIMAPBUTTON_GROUP_WORLD = "野外"
L.MINIMAPBUTTON_GROUP_NAMEPLATES = "姓名板"
L.MINIMAPBUTTON_GROUP_GATHERING = "采集"
L.MINIMAPBUTTON_GATHERING_SHOWS = "采集地图显示" -- over its kinds' checkboxes: Herbs, Ore...
L.MINIMAPBUTTON_GROUP_OTHER = "其他"
-- The button in the module's settings that picks the quick toggles: a menu with a submenu per
-- module category, with checkboxes; and the line at the bottom of the quick toggles that opens it.
L.MINIMAPBUTTON_CUSTOMIZE_NAME = "快捷开关"
L.MINIMAPBUTTON_CUSTOMIZE = "自定义"
L.MINIMAPBUTTON_CUSTOMIZE_DESC = "按分类选择按钮的快捷开关中有哪些模块。"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN = "自定义……"
-- The quick toggles' submenu of profiles, with more than one: the profile in use
L.MINIMAPBUTTON_PROFILE = "配置：%s"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN_DESC = "在“小地图按钮”的设置中选择此菜单中有哪些模块。"
L.MINIMAPBUTTON_CUSTOMIZE_RESET = "重置为默认"
L.MINIMAPBUTTON_MENU_CUSTOMIZE = "菜单中显示自定义"
L.MINIMAPBUTTON_MENU_CUSTOMIZE_DESC = "在快捷开关底部显示“自定义……”。关闭时，用下面的“自定义”按钮选择。"
L.MINIMAPBUTTON_MENU_PROFILES = "菜单中显示配置"
L.MINIMAPBUTTON_MENU_PROFILES_DESC = "当你有不止一个配置时，在快捷开关中显示“配置”子菜单，用来切换配置。"
-- The tooltip's hints: what a click does, then the click.
L.MINIMAPBUTTON_HINT_SETTINGS = "打开设置"
L.MINIMAPBUTTON_HINT_WELCOME = "关于Forever++"
L.MINIMAPBUTTON_HINT_TOGGLES = "快捷开关"
L.MINIMAPBUTTON_HINT_ERRORS = "显示错误"
L.MINIMAPBUTTON_HINT_CLEAR = "清除本次登录的错误"
L.MINIMAPBUTTON_HINT_CLEAR_ALL = "清除所有错误"
L.MINIMAPBUTTON_HINT_MOVE = "移动按钮"
L.MINIMAPBUTTON_PLACE_NAME = "按钮位置"
L.MINIMAPBUTTON_PLACE_RESET_DESC = "把小地图按钮放回小地图边缘的初始位置。拖动它可以放到小地图上或周围的任何地方。"
-- The tooltip's legend: what each click does, the click at the right in green. Named as Blizzard's
-- instruction lines name clicks ("Ctrl click", "Right click"): separate words, no hyphen.
L.MINIMAPBUTTON_LEFT_CLICK = "点击"
L.MINIMAPBUTTON_RIGHT_CLICK = "右键点击"
L.MINIMAPBUTTON_KEY_LEFT_CLICK = "按住%s点击" -- a key, such as Shift
L.MINIMAPBUTTON_KEY_RIGHT_CLICK = "按住%s右键点击" -- the same, with Click Opens Quick Toggles on
L.MINIMAPBUTTON_SWAP = "点击打开快捷开关"
L.MINIMAPBUTTON_SWAP_DESC = "点击打开快捷开关，右键点击打开设置。关闭时则相反。"
L.MINIMAPBUTTON_KEYS_LEFT = "错误按键用于点击"
L.MINIMAPBUTTON_KEYS_LEFT_DESC = "让错误相关的按键保留在点击上（例如按住Shift点击显示错误），而不是和设置一起移到"
    .. "右键点击上。"
L.MINIMAPBUTTON_MENU_SIDE = "菜单方向"
L.MINIMAPBUTTON_MENU_SIDE_DESC = "快捷开关从光标处向哪个方向打开：与暴雪的菜单相同，或在光标的左侧或右侧。"
L.MINIMAPBUTTON_MENU_SIDE_AUTO = "自动"
L.MINIMAPBUTTON_MENU_SIDE_LEFT = "左"
L.MINIMAPBUTTON_MENU_SIDE_RIGHT = "右"
L.MINIMAPBUTTON_MENU_ORDER = "菜单排列"
L.MINIMAPBUTTON_MENU_ORDER_DESC = "快捷开关如何排列：按你正在做的事分组（商人和战利品、NPC和任务等），按模块页面的"
    .. "分类，或按字母顺序排成一个列表。"
L.MINIMAPBUTTON_MENU_ORDER_GROUPS = "活动"
L.MINIMAPBUTTON_MENU_ORDER_CATEGORY = "分类"
L.MINIMAPBUTTON_MENU_ORDER_TITLE = "按字母顺序"
L.MINIMAPBUTTON_LEFT_DRAG = "拖曳"
L.MINIMAPBUTTON_ERRORS_KEY = "显示错误按键"
L.MINIMAPBUTTON_ERRORS_KEY_DESC = "“错误捕获”开启时，点击按钮显示错误需要按住的键。"
L.MINIMAPBUTTON_CLEAR_KEY = "清除本次登录按键"
L.MINIMAPBUTTON_CLEAR_KEY_DESC = "“错误捕获”开启时，点击按钮清除本次登录的错误需要按住的键。"
L.MINIMAPBUTTON_CLEAR_ALL_KEY = "全部清除按键"
L.MINIMAPBUTTON_CLEAR_ALL_KEY_DESC = "“错误捕获”开启时，点击按钮清除每一次登录保存的所有错误需要按住的键。清除前会先询问。"

-- Commands
L.COMMANDS_TITLE = "斜杠命令"
L.COMMANDS_DESC = "添加简短的斜杠命令：/rl重新加载界面，/clear清空聊天窗口，/kb设置按键，/pull开始"
    .. "开怪倒计时。/way在“路径点”中。"
L.COMMANDS_RELOAD = "/rl"
L.COMMANDS_RELOAD_DESC = "/rl重新加载界面，与/reload相同。如果另一个插件已经有/rl，则留给它。"
L.COMMANDS_RELOAD_HELP = "重新加载界面" -- a line of /fpp help, like the SLASH_ ones
L.COMMANDS_CLEAR_HELP = "清空输入命令的聊天窗口"
L.COMMANDS_CLEAR = "/clear"
L.COMMANDS_CLEAR_DESC = "/clear清空你输入它的聊天窗口。如果另一个插件已经有/clear，则留给它。"
L.COMMANDS_KEYBIND = "/kb"
L.COMMANDS_KEYBIND_DESC = "/kb打开“快速快捷键模式”，与“按键设置”中的按钮相同：将鼠标指向一个动作按钮，"
    .. "然后按下按键。仅限非战斗状态。如果另一个插件已经有/kb，则留给它。"
L.COMMANDS_KEYBIND_HELP = "打开“快速快捷键模式”"
L.COMMANDS_KEYBIND_BLOCKED = "战斗中或编辑模式打开时无法打开“快速快捷键模式”。"
L.COMMANDS_PULL = "/pull"
L.COMMANDS_PULL_DESC = "/pull 10开始游戏的开怪计时，也就是/countdown开始的倒计时，持续10秒；不写数字时"
    .. "也是10秒。/pull 0停止它。如果首领插件或另一个插件已经有/pull，则留给它。"
L.COMMANDS_PULL_HELP = "开始游戏的开怪倒计时，不写数字时为10秒"
L.COMMANDS_PULL_USAGE = "输入/pull和倒计时的秒数，例如/pull 10；输入/pull 0停止倒计时。"

-- HideBetaFeedback
L.HIDEBETAFEEDBACK_TITLE = "隐藏测试版反馈"
L.HIDEBETAFEEDBACK_DESC = "隐藏测试版在提示信息中“按F6提交问题”的一行及其错误报告按钮。F6仍可提交问题。"
L.HIDEBETAFEEDBACK_TOOLTIP = "隐藏提示信息中的提醒"
L.HIDEBETAFEEDBACK_TOOLTIP_DESC = "隐藏提示信息中“按F6提交问题”的一行。"
L.HIDEBETAFEEDBACK_BUTTON = "隐藏错误报告按钮"
L.HIDEBETAFEEDBACK_BUTTON_DESC = "隐藏浮动的错误报告按钮。"
L.HIDEBETAFEEDBACK_QUEST = "隐藏任务反馈"
L.HIDEBETAFEEDBACK_QUEST_DESC = "隐藏任务窗口上的反馈按钮。"

-- MovableFramerate
L.MOVABLEFRAMERATE_TITLE = "可移动帧率显示"
L.MOVABLEFRAMERATE_DESC = "像暴雪自己的框体一样，在编辑模式中移动帧数文字（Ctrl+R）并调整其大小。在你移动它之前，"
    .. "它保持在暴雪默认的位置。"
