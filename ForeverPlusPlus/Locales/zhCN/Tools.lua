local _, ns = ...
local L = ns.NewLocale("zhCN")
if not L then
    return
end

-- ConsoleVariables
L.CONSOLEVARIABLES_TITLE = "控制台变量"
-- Debug (its title, L.DEBUG, is in Core.lua)
L.DEBUG_DESC = "在设置侧边栏的调试页面中显示每个模块的调试选项和测试工具（自检、装备探测、截图），并开启它们的命令。"
L.DEBUG_NOTICE = "关闭调试会把所有调试选项恢复默认。" -- a gray row atop the module
L.DEBUG_NOTICE_DESC = "这样在这里设置的东西就不会在看不见的地方继续生效。"

-- ConsoleVariables
L.CONSOLEVARIABLES_DESC = "在设置中的一个页面上浏览游戏的控制台变量（CVar），修改它们，并锁定你想保留的值，即使是"
    .. "游戏每次登录都会重置的变量。"
L.CONSOLEVARIABLES_CHAT_DESC = "锁定的控制台变量无法保持其数值时，在聊天中提示。"
-- A gray row atop the module while it's off with console variables locked
L.CONSOLEVARIABLES_LOCKS_OFF = "此模块关闭时，锁定的控制台变量不会被保持。"
L.CONSOLEVARIABLES_LOCKS_OFF_DESC = "它们会恢复为游戏设置的值，直到此模块重新开启。"
L.CONSOLEVARIABLES_COMMAND = "打开控制台变量，并搜索[search]"
L.CONSOLEVARIABLES_NO_PAGE = "此客户端的设置无法打开控制台变量页面。"
L.CONSOLEVARIABLES_AFTER_COMBAT = "%s将在战斗结束后更改。" -- CVar name
L.CONSOLEVARIABLES_REFUSED = "%s无法更改。" -- CVar name
L.CONSOLEVARIABLES_KEPT = "%s保持为%s：游戏不接受%s。" -- CVar name, its value, the typed one
L.CONSOLEVARIABLES_SEARCH = "搜索控制台变量" -- gray text in the empty search box
L.CONSOLEVARIABLES_POPULAR = "常用" -- the group of CVars players most often look for
L.CONSOLEVARIABLES_FAVORITES = "收藏" -- the group of CVars the player starred
L.CONSOLEVARIABLES_LOCKED = "已锁定" -- the group of CVars the player locked at a value
L.CONSOLEVARIABLES_CHANGED = "已更改" -- the group of CVars not at their default
L.CONSOLEVARIABLES_ALL = "全部"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CONSOLEVARIABLES_CATEGORY_GRAPHICS = "图形"
L.CONSOLEVARIABLES_CATEGORY_CONSOLE = "控制台"
L.CONSOLEVARIABLES_CATEGORY_COMBAT = "战斗"
L.CONSOLEVARIABLES_CATEGORY_GAME = "游戏"
L.CONSOLEVARIABLES_CATEGORY_DEFAULT = "综合" -- Default
L.CONSOLEVARIABLES_CATEGORY_NET = "网络"
L.CONSOLEVARIABLES_CATEGORY_SOUND = "声音"
L.CONSOLEVARIABLES_CATEGORY_GM = "游戏管理员" -- Gm
L.CONSOLEVARIABLES_CATEGORY_REVEAL = "已揭示" -- Reveal
L.CONSOLEVARIABLES_CATEGORY_NONE = "其他" -- None
L.CONSOLEVARIABLES_NO_MATCH = "没有与“%s”匹配的控制台变量。" -- the search text
L.CONSOLEVARIABLES_NONE_CHANGED = "所有控制台变量都是默认值。"
L.CONSOLEVARIABLES_NO_FAVORITES = "点击控制台变量上的星标即可把它放在这里。"
L.CONSOLEVARIABLES_NO_LIST = "此客户端不会列出它的控制台变量。请搜索变量的完整名称来查找。"
L.CONSOLEVARIABLES_DEFAULT = "默认"
L.CONSOLEVARIABLES_VALUE_IS = "数值：%s"
L.CONSOLEVARIABLES_DEFAULT_IS = "默认：%s"
L.CONSOLEVARIABLES_ON_OFF = "0通常表示关闭，1通常表示开启。"
L.CONSOLEVARIABLES_ON_OFF_HINT = "0通常表示关闭，1表示开启。如果不符，它会接受其他数值：请查阅相关资料。"
L.CONSOLEVARIABLES_ACCOUNT = "为你的账号保存。"
L.CONSOLEVARIABLES_CHARACTER = "为此角色保存。"
L.CONSOLEVARIABLES_READ_ONLY = "无法更改。"
L.CONSOLEVARIABLES_SECURE = "受保护：更改会等到战斗结束。"
L.CONSOLEVARIABLES_NO_LOCKS = "点击控制台变量上的锁，即可在每次登录和更改后保持其数值。"
-- Locks: a locked CVar is put back to its value at login and whenever something changes it.
L.CONSOLEVARIABLES_LOCKED_AT = "锁定为%s：每次登录时以及有东西更改它时都会恢复。" -- the locked value
L.CONSOLEVARIABLES_LOCK_HINT = "<点击锁以保持此数值>" -- tooltip of an open lock
L.CONSOLEVARIABLES_UNLOCK_HINT = "<点击锁以停止保持>" -- tooltip of a closed lock
L.CONSOLEVARIABLES_LOCK_STOPPED = "在你重新加载或重新登录之前不再保持：它无法维持。"
L.CONSOLEVARIABLES_LOCK_FAILED = "%s无法恢复为锁定的%s（当前为%s）。它的锁会等到你重新加载或重新登录。" -- CVar name, the locked value, its value now
L.CONSOLEVARIABLES_LOCK_FIGHT = "%s不断被其他东西更改。它的锁会等到你重新加载或重新登录。" -- CVar name
-- Popular: the section headers, then each CVar's plain name and what it does.
L.CONSOLEVARIABLES_POP_CAMERA = "镜头"
L.CONSOLEVARIABLES_POP_EFFECTS = "屏幕效果"
L.CONSOLEVARIABLES_POP_NAMEPLATES = "姓名板"
L.CONSOLEVARIABLES_POP_MAP = "地图"
L.CONSOLEVARIABLES_POP_CHAT = "聊天"
L.CONSOLEVARIABLES_POP_COMBAT = "战斗"
L.CONSOLEVARIABLES_POP_INTERFACE = "界面"
L.CONSOLEVARIABLES_POP_GRAPHICS = "图形"
L.CONSOLEVARIABLES_POP_SCREENSHOTS = "截图"
L.CONSOLEVARIABLES_POP_MOUSE = "鼠标"
L.CONSOLEVARIABLES_POP_ZOOM_DESC = "镜头最远能拉多远。设置选项中最大为2.0；这里可以更远。"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED = "缩放速度"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED_DESC = "鼠标滚轮缩放镜头的速度。默认20，最高50。"
L.CONSOLEVARIABLES_POP_COLLISION = "镜头碰撞"
L.CONSOLEVARIABLES_POP_COLLISION_DESC = "1允许树木和墙壁先挡在你和镜头之间，镜头再拉近；0则立即拉近。"
L.CONSOLEVARIABLES_POP_GLOW = "屏幕泛光"
L.CONSOLEVARIABLES_POP_GLOW_DESC = "覆盖整个屏幕的柔和泛光。0可关闭它，让画面更锐利。"
L.CONSOLEVARIABLES_POP_DEATH_DESC = "死亡时的灰色模糊。0可关闭它。"
L.CONSOLEVARIABLES_POP_PLATE_RANGE = "姓名板距离"
L.CONSOLEVARIABLES_POP_PLATE_RANGE_DESC = "姓名板在多远的距离内显示，单位为码。默认45。为此角色保存。"
L.CONSOLEVARIABLES_POP_PLATE_SPACING = "姓名板间距"
L.CONSOLEVARIABLES_POP_PLATE_SPACING_DESC = "堆叠的姓名板之间的距离。数值越低越紧凑。默认1.1。"
L.CONSOLEVARIABLES_POP_PLATE_FAR = "远处姓名板不透明度"
L.CONSOLEVARIABLES_POP_PLATE_FAR_DESC = "远处姓名板的淡化程度，0到1。默认0.6；1表示从不淡化。"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN = "被遮挡单位不透明度"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN_DESC = "墙后单位的姓名板的淡化程度，0到1。默认0.4。"
L.CONSOLEVARIABLES_POP_PLATE_TARGET = "目标姓名板大小"
L.CONSOLEVARIABLES_POP_PLATE_TARGET_DESC = "你的目标的姓名板放大多少。默认1.2；1表示大小相同。"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED = "简化姓名板大小"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED_DESC = "简化姓名板的大小。默认0.3。游戏可能在登录时把它恢复默认，因此请锁定"
    .. "以保留你的设置。"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS = "敌方图腾姓名板"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS_DESC = "1在敌方图腾上显示姓名板，便于你找到并选中它们。"
L.CONSOLEVARIABLES_POP_PLATE_PETS = "敌方宠物姓名板"
L.CONSOLEVARIABLES_POP_PLATE_PETS_DESC = "1在敌方玩家的宠物上显示姓名板。"
L.CONSOLEVARIABLES_POP_COMBO = "连击点位置"
L.CONSOLEVARIABLES_POP_COMBO_DESC = "连击点显示的位置：1在目标框体上，2在你的框体上。"
L.CONSOLEVARIABLES_POP_FOG_END = "雾的距离"
-- [quotes: FARCLIP]
L.CONSOLEVARIABLES_POP_FOG_END_DESC = "远处的雾在多远处最浓。默认1600；可随“视野距离”调高。"
L.CONSOLEVARIABLES_POP_FOG_START = "雾的起点"
L.CONSOLEVARIABLES_POP_FOG_START_DESC = "远处的雾从多远处开始。默认800。"
L.CONSOLEVARIABLES_POP_GRASS = "草地密度"
L.CONSOLEVARIABLES_POP_GRASS_DESC = "草和地面杂物的密度。默认16；越高越影响帧数。"
L.CONSOLEVARIABLES_POP_GRASS_DIST = "草地距离"
L.CONSOLEVARIABLES_POP_GRASS_DIST_DESC = "在多远处绘制草地。默认70。"
L.CONSOLEVARIABLES_POP_ROTATE_DESC = "1让小地图随你转动，使上方始终是你面朝的方向。"
L.CONSOLEVARIABLES_POP_MAP_FADE = "世界地图淡化"
L.CONSOLEVARIABLES_POP_MAP_FADE_DESC = "1在你移动时淡化世界地图。0保持不透明。"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL = "聊天鼠标滚轮"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL_DESC = "1允许用鼠标滚轮滚动聊天。"
L.CONSOLEVARIABLES_POP_LOOT_SPAM = "完整掷骰信息"
L.CONSOLEVARIABLES_POP_LOOT_SPAM_DESC = "1在聊天中显示每个玩家的掷骰结果；0只显示获胜者。"
L.CONSOLEVARIABLES_POP_QUEUE = "法术队列窗口"
L.CONSOLEVARIABLES_POP_QUEUE_DESC = "你可以提前多久排入下一个法术，单位为毫秒，0到400。默认400。"
L.CONSOLEVARIABLES_POP_STOP_ATTACK = "切换目标时停止攻击"
L.CONSOLEVARIABLES_POP_STOP_ATTACK_DESC = "1在你切换目标时停止自动攻击。"
L.CONSOLEVARIABLES_POP_TEXT_SIZE = "战斗文字大小"
L.CONSOLEVARIABLES_POP_TEXT_SIZE_DESC = "浮动战斗数字的大小。默认1。"
L.CONSOLEVARIABLES_POP_ERRORS = "显示Lua错误"
L.CONSOLEVARIABLES_POP_ERRORS_DESC = "1在插件出错时弹出游戏的错误窗口。"
L.CONSOLEVARIABLES_POP_COMPARE = "总是比较物品"
L.CONSOLEVARIABLES_POP_COMPARE_DESC = "1无需按住Shift，就在物品提示信息旁显示你身上的装备。"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS = "新法术放到动作条"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS_DESC = "1把你学会的法术自动放到动作条上。为此角色保存。"
L.CONSOLEVARIABLES_POP_LOOT_RATE = "自动拾取速度"
L.CONSOLEVARIABLES_POP_LOOT_RATE_DESC = "自动拾取时每件物品之间的毫秒数。越低越快。默认150。"
L.CONSOLEVARIABLES_POP_FARCLIP_DESC = "游戏世界绘制到多远。默认1000；越高越影响帧数。"
L.CONSOLEVARIABLES_POP_WEATHER = "天气"
L.CONSOLEVARIABLES_POP_WEATHER_DESC = "你能看到多少雨雪，0（无）到3。默认2。"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY = "截图质量"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY_DESC = "1到10，越高越清晰、文件越大。默认3。"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT = "截图格式"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT_DESC = "jpeg（文件小）、png或tga（无损，文件大）。"
L.CONSOLEVARIABLES_POP_RAW_MOUSE = "原始鼠标输入"
L.CONSOLEVARIABLES_POP_RAW_MOUSE_DESC = "1直接读取鼠标输入，可以避免你松开镜头时光标跳动。"

-- SelfTest
L.SELFTEST_TITLE = "自检"
L.SELFTEST_DESC = "探测Forever++依赖的客户端API并保存其结果，用于调试。"

-- Screenshots
L.SCREENSHOTS_TITLE = "截图"
L.SCREENSHOTS_DESC = "在游戏自己的窗口中依次为Forever++截图，用于其页面和帖子。"

-- Controller Mode
L.CONTROLLERMODE_TITLE = "手柄模式"
L.CONTROLLERMODE_DESC = "为手柄界面和键盘鼠标各保留一套设置：各自的Forever++配置、编辑模式布局和插件组合。以另一种"
    .. "界面登录时，会切换到它的那套设置。"
L.CONTROLLERMODE_NOTE = "选择每种界面使用什么。此角色以另一种界面登录时，Forever++会切换到它的配置和编辑模式布局，"
    .. "只有在已载入的插件不是它的组合时才会要求重新加载。你手动做的更改会保留，直到界面再次切换。这些选择由"
    .. "所有配置共享，在这里选择的配置会开启“手柄模式”。"
L.CONTROLLERMODE_NOW = "游戏当前显示：%s" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_GAMEPAD = "手柄"
L.CONTROLLERMODE_MKB = "键盘与鼠标"
L.CONTROLLERMODE_NO_CHANGE = "不更改"
L.CONTROLLERMODE_PROFILE = "Forever++配置"
L.CONTROLLERMODE_PROFILE_DESC = "此角色在这种界面下切换到的配置。"
L.CONTROLLERMODE_LAYOUT = "编辑模式布局"
L.CONTROLLERMODE_LAYOUT_DESC = "这种界面下使用的编辑模式布局。游戏只在布局所属的界面下提供该布局。"
L.CONTROLLERMODE_ADDONS_NONE = "不更改"
L.CONTROLLERMODE_ADDONS_SAVED = "开启了%d个插件" -- number of addons
L.CONTROLLERMODE_ADDONS_SAVE = "使用当前"
L.CONTROLLERMODE_ADDONS_SAVE_DESC = "把此角色当前开启的插件保存为这种界面的组合。之后安装的插件不受影响，直到你再次保存。"
L.CONTROLLERMODE_ADDONS_CLEAR = "清除"
L.CONTROLLERMODE_ADDONS_CLEAR_DESC = "忘记这种界面的组合，让它的插件不受影响。"
L.CONTROLLERMODE_APPLY = "立即设置"
L.CONTROLLERMODE_APPLY_DESC = "切换到游戏当前显示的界面所对应的设置。"
L.CONTROLLERMODE_NOTHING = "%s没有需要更改的内容。" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_RELOAD = "Forever++手柄模式：你的插件不是为%s保存的组合。" -- interface
L.CONTROLLERMODE_RELOAD_ON = "开启：%s" -- addon names
L.CONTROLLERMODE_RELOAD_OFF = "关闭：%s" -- addon names
L.CONTROLLERMODE_RELOAD_ASK = "更改它们并立即重新加载？"
L.CONTROLLERMODE_AND_MORE = "%s，以及其他%d个" -- addon names, number of addons

-- Taint Watcher
L.TAINTWATCHER_TITLE = "污染监视"
L.TAINTWATCHER_DESC = "监视任务追踪栏、任务日志、世界地图和游戏的窗口列表，查找插件写入其中的值，正是这些值之后会"
    .. "让游戏提示“插件导致界面行为失效”。发现的每一项都会连同时间列在“错误捕获”和/fpp taint中。用于查找是什么"
    .. "导致了问题。"

-- Profiler
L.PROFILER_TITLE = "CPU分析器"
L.PROFILER_DESC = "在设置中的一个页面上查看每个模块占用多少CPU，找出哪里慢。"

-- Gear Probe
L.GEARPROBE_TITLE = "装备探测"
L.GEARPROBE_DESC = "读取此客户端关于你的装备、天赋页和属性的信息，用于开发“升级箭头”。"
