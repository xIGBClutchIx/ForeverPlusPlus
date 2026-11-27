local _, ns = ...
local L = ns.NewLocale("zhCN")
if not L then
    return
end

-- Lib/Text.lua: lengths of time, for slider labels and price lines
L.TEXT_SECONDS = { "%d秒" }
L.TEXT_MINUTES = { "%d分钟" }
L.TEXT_HOURS = { "%d小时" }
L.TEXT_AGO_NOW = "刚刚"
L.TEXT_AGO_MINUTES = "%d分钟前" -- minutes
L.TEXT_AGO_HOURS = "%d小时前" -- hours
L.TEXT_AGO_DAYS = "%d天前" -- days
L.TEXT_YARDS = "%s码" -- a distance; the game's own words are used when it has them
L.SLIDER_YARDS = "%d码" -- a slider's value in yards, worded like TEXT_YARDS

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
L.KEY_NONE = "无"
-- Added to a key dropdown's description with the controller interface on; each %s is a trigger
-- as the player's controller shows it
L.KEY_PAD_NOTE = "开启手柄界面时，改为按住%s或%s。"
L.SKIP_KEY = "跳过按键" -- the option of every module that a held key skips

-- Lib/MapPins.lua: icons on the world map.
-- Click hints are written as Blizzard's instruction lines are: in angle brackets, the keys and the
-- click as separate words with no hyphen or plus ("Ctrl click"), no full stop. One click to a line.
L.MAPPINS_HINT_WAYPOINT = "<按住Ctrl点击以设置地图标记>"
-- The options of icons on the world map: their size, opacity, and whether continent maps show
-- them, the same in every module that has them.
L.MAPPINS_SIZE = "图标尺寸"
L.MAPPINS_SIZE_DESC = "图标相对于正常尺寸的大小。"
L.MAPPINS_OPACITY = "不透明度"
L.MAPPINS_OPACITY_DESC = "图标的不透明程度。数值越低，越能透过图标看到地图。"
L.MAPPINS_CONTINENTS = "在大陆地图上"
L.MAPPINS_CONTINENTS_DESC = "除了区域地图，也在大陆地图和世界地图上显示。"
-- Lib/Sounds.lua: the alert sounds, in every Sound dropdown
L.SOUND_NAME = "声音"
L.SOUND_OFF = "关闭"
L.SOUND_BUZZ = "错误提示音"
L.SOUND_DENIED = "拒绝"
L.SOUND_HORN = "战争号角"
L.SOUND_BOSS = "首领预警"
L.SOUND_GM = "GM提示"
L.SOUND_ALARM = "闹钟"
L.SOUND_WHISPER = "悄悄话"

-- Core: /fpp and chat
L.ON = "开启"
L.OFF = "关闭"
L.MODULE_STATE = "%s：%s。" -- module name, on/off
L.MODULE_ALWAYS_ON = "%s是一个工具，始终开启。" -- module title, such as Self Test
L.NO_MODULE = "没有名为%s的模块"
L.COMMAND_NEEDS_MODULE = "/fpp %s需要“%s”，但它在模块页面上处于关闭状态。" -- command, title
L.SLASH_MODULES = "模块（/fpp toggle <name>，/fpp list）："
L.SLASH_OPEN = "打开设置"
L.SLASH_LIST = "列出所有模块及其开关状态"
L.SLASH_TOGGLE = "开启或关闭一个模块，或其中的一个复选框"
L.SLASH_RESET = "将所有设置恢复默认（会重新加载）"
L.RESET_CONFIRM = "将Forever++的所有设置恢复默认，并清除它保存的所有数据，例如拍卖价格和飞行时间？"
    .. "这会重新加载界面。"
L.SLASH_OPTIONS = "列出它的选项及其数值"
L.SLASH_SET = "修改一个选项（on/off、一个选项值或一个数字）"
L.SLASH_TAKEN = "%s已被另一个插件占用，因此Forever++将其留给该插件。"

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s：%s。选项（/fpp set %s <option> <value>）：" -- module, on/off, module
L.OPTIONS_NONE = "无"
L.OPTIONS_DEBUG = "，调试"
L.SET_USAGE = "用法：/fpp set <module> <option> [value]"
L.MODULE_STATE_ALLOWED = "%s：%s（on, off）。" -- module name, on/off
L.NO_OPTION = "%s没有选项%s。/fpp options %s可列出所有选项。" -- module, option, module
L.OPTION_STATE = "%s %s：%s。" -- module, option, value
L.OPTION_STATE_ALLOWED = "%s %s：|cffffd100%s|r（%s）。" -- module, option, value, allowed values
L.CHAT_MESSAGES = "聊天信息" -- a module's checkbox for what it says in chat by itself

-- Lib/Profiles.lua: profiles, and /fpp profiles
L.PROFILES_DEFAULT = "默认" -- the profile everyone starts with, which is always there
L.PROFILES_NAME_EMPTY = "配置需要一个名字。"
L.PROFILES_NAME_TAKEN = "已经有一个名为%s的配置。" -- name
L.PROFILES_DEFAULT_ALWAYS = "“默认”配置始终存在，无法重命名或删除。"
L.SLASH_PROFILE = "列出所有配置，或将此角色切换到其中一个"
L.PROFILES_HEADER = "配置（/fpp profiles <name>可切换）："
L.PROFILES_CHARACTERS = { "%d个角色" } -- how many use a profile
L.PROFILES_SWITCHED = "现在使用%s配置。" -- profile name
L.PROFILES_AFTER_COMBAT = "战斗结束后将切换到%s配置。" -- profile name
L.PROFILES_NO_SUCH = "没有名为%s的配置。/fpp profiles可列出所有配置。" -- what was typed

-- Settings
-- The Modules page's groups of modules.
L.CATEGORY_AUTOMATION = "自动化"
L.CATEGORY_CHARACTER = "角色"
L.CATEGORY_CHAT = "聊天"
L.CATEGORY_INTERFACE = "界面"
L.CATEGORY_ITEMS = "物品"
L.CATEGORY_MAP = "地图"
L.CATEGORY_QUESTS = "任务"
L.CATEGORY_SYSTEM = "系统"
L.CATEGORY_UNITS = "单位"
L.CATEGORY_OTHER = "其他"
L.DEBUG = "调试"
L.SETTINGS_AFTER_COMBAT = "战斗结束后将打开设置。"
L.MODULES = "模块" -- the page with every module's checkbox, the top Forever++ entry
L.ABOUT = "关于" -- the page with the version, links, credits, and commands
-- The selected module on the Modules page
L.SETTINGS_ENABLED = "启用" -- the module's own on/off checkbox, under its description
-- What a greyed-out option needs (`needs`), in red in its tooltip: an addon's or module's name
L.SETTINGS_NEEDS_ADDON = "需要%s插件。"
L.SETTINGS_NEEDS_MODULE = "需要开启%s模块。"
L.SETTINGS_NEEDS_CLIENT = "当前版本的游戏缺少它所需的功能。"
-- A notice on a module whose Blizzard frame the controller interface hides (ns.Gamepad.HidesNotice).
L.SETTINGS_CONTROLLER_HIDDEN = "在手柄界面下无效"
L.SETTINGS_CONTROLLER_HIDDEN_DESC = "手柄界面会隐藏此模块改动的内容，并以自己的界面代替，因此开启手柄界面时"
    .. "此模块不起作用。"
-- And on one that needs a mouse, a held key, or a window its cursor can't reach (LimitedNotice).
L.SETTINGS_CONTROLLER_LIMITED = "在手柄界面下受限"
L.SETTINGS_CONTROLLER_LIMITED_DESC = "此模块的部分或全部功能需要鼠标点击、拖曳、按住某个键，或是手柄光标"
    .. "无法到达的窗口，因此开启手柄界面时这些功能不起作用。"
-- An option XP Bar Text and Reputation Bar Text share (Lib/StatusBars.lua)
L.STATUSBARS_SOLID = "整条显示"
L.STATUSBARS_SOLID_DESC = "去掉状态条上的分隔线，使其成为完整的一条。"
-- The tooltip of the padlock in a locked module's checkbox's place
L.SETTINGS_LOCKED = "已关闭并锁定：游戏改动导致此模块的功能失效。详情见其设置。"
L.SETTINGS_OPTIONS = "选项" -- the header over its options
L.SETTINGS_NO_OPTIONS = "此模块没有选项。"
L.SETTINGS_CONFLICT_GO = "前往%s" -- an option's name
-- A mark on an item or action button icon (Lib/ItemButtons.lua): its corner, size, and padding,
-- the same in every module that has one.
L.ICONMARK_CORNER = "角落"
L.ICONMARK_CORNER_TOPLEFT = "左上"
L.ICONMARK_CORNER_TOPRIGHT = "右上"
L.ICONMARK_CORNER_BOTTOMLEFT = "左下"
L.ICONMARK_CORNER_BOTTOMRIGHT = "右下"
L.ICONMARK_PIXELS = "%d像素" -- a size or padding slider's value
L.ICONMARK_PADDING = "内边距"
L.ICONMARK_PADDING_DESC = "标记离所在角落的距离：设为2时，左上角的标记会向右、向下各移动2像素。"
-- Under a mark's Corner option while Upgrade Arrows has an arrow in the same corner
L.ICONMARK_CONFLICT_ARROW = "“升级箭头”也会在这个角落显示箭头，两者会重叠。请为其中一个选择别的角落。"
L.ICONMARK_CONFLICT_DOWN = "“升级箭头”也会在这个角落显示降级箭头，两者会重叠。请为其中一个选择别的角落。"
L.ICONMARK_SECTION_SHOW = "显示位置" -- the header over the places a module marks items in
L.ICONMARK_PLACE_BAGS = "背包"
L.ICONMARK_PLACE_MERCHANT = "商人"
L.ICONMARK_PLACE_AUCTION = "拍卖行"
L.ICONMARK_PLACE_LOOT = "战利品"
L.ICONMARK_PLACE_QUESTS = "任务奖励"
L.SETTINGS_PAGE_NOTE = "开启时，它的%s页面会出现在侧边栏的Forever++下。选择其他页面后，该页面才会出现"
    .. "或消失。"
L.SETTINGS_TURN_ON = "开启" -- the button on a "Blizzard's ... is off" row
L.SETTINGS_RESET = "重置为默认" -- the arrow at the end of an option's row while it's changed
L.SETTINGS_RESET_TO = "默认：%s" -- what the option goes back to
L.SETTINGS_RESET_PAIR = "%s，%s" -- a checkbox's default, then its slider's, in one row
L.SETTINGS_CHECKED = "勾选" -- a checkbox's default
L.SETTINGS_UNCHECKED = "不勾选"
L.SETTINGS_SEARCH = "搜索模块" -- gray text in the Modules page's empty search box
L.SETTINGS_NO_MATCH = "没有与“%s”匹配的模块。" -- the search text
L.SETTINGS_NEW_ONLY = "新" -- the checkbox beside the search box that lists only modules marked NEW
L.SETTINGS_NOTHING_NEW = "没有新内容。" -- the Modules list while that checkbox is on and nothing is new

-- Settings: the Profiles page
L.PROFILES = "配置"
L.PROFILES_USES = "%s使用" -- a character's name, before the dropdown of its profile
L.PROFILES_USES_TITLE = "此角色的配置"
L.PROFILES_USES_DESC = "%s使用的配置。你在Forever++中所做的更改都会保存到这个配置，对使用它的每个角色"
    .. "都生效。" -- character
L.PROFILES_NEW_CHARACTERS = "新角色使用"
L.PROFILES_NEW_CHARACTERS_DESC = "角色第一次登录时使用的配置。"
L.PROFILES_NEW = "新配置"
L.PROFILES_NEW_DESC = "新建一个配置：复制所选配置、使用默认设置，或基于%s。" -- a preset's name, or PRESETS_A_PRESET
L.PROFILES_NEW_ASK = "为新配置命名。"
L.PROFILES_NEW_FROM = "将%s创建为%s的副本、使用默认设置，还是基于%s？" -- new name, selected profile, a preset's name or PRESETS_A_PRESET
L.PROFILES_PRESET = "基于" -- beside the dropdown of the preset a profile follows
L.PROFILES_PRESET_NONE = "无" -- a profile based on no preset
L.PROFILES_PRESET_DESC = "%s所跟随的预设：你没有自己设置的内容都读取预设，因此会随以后的版本对预设的"
    .. "改动而更新，撤销箭头会把设置恢复为预设的数值。选择预设会保留你设置过的每一项。选择“无”则"
    .. "把配置当前的内容保留为你自己的设置，并不再跟随预设。" -- profile
L.PROFILES_PRESET_AFTER_COMBAT = "战斗结束后将更改%s所基于的预设。" -- profile
L.PRESETS_A_PRESET = "一个预设" -- in PROFILES_NEW_DESC and PROFILES_NEW_FROM, with more than one
L.PRESETS_MORE = "预设……" -- a popup button that opens a menu of every preset
L.PRESETS_NO_SUCH = "没有名为%s的预设。" -- what was asked for
L.PRESETS_DEVELOPER_DESC = "默认设置，外加开发者使用的模块和选项。"
L.PROFILES_COPY_OF = "%s的副本" -- a profile
L.PROFILES_FROM_DEFAULTS = "使用默认设置"
L.PROFILES_IN_USE = "此角色正在使用"
L.PROFILES_SUMMARY = "开启了%d个模块，%d项设置与默认不同。"
L.PROFILES_USED_BY = "使用者：%s。" -- character names
L.PROFILES_UNUSED = "没有角色使用。"
L.PROFILES_USE = "用于此角色"
L.PROFILES_USE_DESC = "立即将%s切换到%s，无需重新加载。" -- character, profile
L.PROFILES_RENAME = "重命名"
L.PROFILES_RENAME_DESC = "为%s换一个名字。" -- profile
L.PROFILES_RENAME_ASK = "将%s重命名为：" -- profile
L.PROFILES_DELETE = "删除"
L.PROFILES_DELETE_DESC = "删除%s。使用它的角色将改回“默认”。" -- profile
L.PROFILES_DELETE_ASK = "删除%s？使用它的角色将改回“默认”。" -- profile
L.PROFILES_CHARACTERS_HEADER = "角色"
L.PROFILES_CHARACTER_LINE = "等级%d %s" -- level, class
L.PROFILES_THIS_CHARACTER = "此角色"
L.PROFILES_USES_OTHER = "使用%s" -- the profile another character uses
L.PROFILES_CHECK_DESC = "勾选以让%s使用%s。" -- character, profile
L.PROFILES_UNCHECK_DESC = "取消勾选以让%s改回“默认”。" -- character
L.PROFILES_ON_DEFAULT_DESC = "每个角色都要使用一个配置。要让%s不再使用“默认”，请在另一个配置上勾选它。" -- character
L.PROFILES_FORGET_HINT = "右键点击以忘记此角色。"
L.PROFILES_FORGET_ASK = "忘记%s？它会从列表中消失，直到再次登录。" -- character
L.PROFILES_NOTE = "一个配置包括：开启了哪些模块、它们的设置、你在编辑模式中摆放的Forever++框体和用"
    .. "“可移动窗口”摆放的窗口位置，以及小地图按钮的快捷开关。拍卖价格、采集点、遇到过的玩家，以及每个"
    .. "角色自己保存的内容（例如天赋规划）不包括在内。"
L.PROFILES_SHARE = "分享"
L.PROFILES_EXPORT = "导出"
L.PROFILES_EXPORT_DESC = "将%s显示为一行文本，可以复制后发给别人，或留作备份。" -- profile
L.PROFILES_EXPORT_ASK = "%s的文本。按Ctrl+C复制后发给别人，或留作备份。" -- profile
L.PROFILES_IMPORT = "导入"
L.PROFILES_IMPORT_DESC = "粘贴别人导出的配置，作为新配置导入，或覆盖%s。" -- profile
L.PROFILES_IMPORT_ASK = "按Ctrl+V粘贴别人导出的配置。"
-- What the pasted text holds: name, Forever++ version, modules on, settings changed
L.PROFILES_IMPORT_FOUND = "%s，由Forever++ %s创建。\n开启了%d个模块，%d项设置与默认不同。"
L.PROFILES_IMPORT_NEW = "作为新配置导入"
L.PROFILES_IMPORT_REPLACE = "覆盖%s" -- the selected profile
L.PROFILES_IMPORT_BAD = "这不是Forever++的配置。请复制整行后再粘贴一次。"
L.PROFILES_IMPORT_CANT = "此客户端无法读取压缩的配置。"
L.PROFILES_IMPORT_NEWER = "该配置来自更新版本的Forever++。请更新后再导入。"
L.PROFILES_IMPORTED = "导入的配置" -- the name of an import whose own name is empty
L.PROFILES_IMPORT_DONE = "已导入%s。" -- profile
L.PROFILES_MODULES_NOTE = "配置：%s" -- beside the Modules page's title, with more than one
L.DEFAULTS_ASK_PROFILE = "将%s配置的Forever++设置恢复默认？使用该配置的每个角色都会随之改变。游戏的其他"
    .. "设置保持不变。" -- profile

-- Settings: Changelog page. The notes themselves are in Changelog.lua.
L.CHANGELOG = "更新日志"
L.CHANGELOG_RELEASE = "%s（%s）" -- version, date
L.CHANGELOG_UNRELEASED = "未发布"
L.CHANGELOG_SEARCH = "搜索更新" -- gray text in the Changelog page's empty search box
L.CHANGELOG_BY_MODULE = "按模块" -- checkbox that groups a release's notes under their modules
L.CHANGELOG_GENERAL = "综合" -- heading, with By Module on, for notes about no one module
L.CHANGELOG_NO_MATCH = "没有与“%s”匹配的更新。" -- the search text
L.CHANGELOG_CHANGES = { "%d项更新" } -- how many entries a release has
L.CHANGELOG_ADDED = "新增"
L.CHANGELOG_CHANGED = "改动"
L.CHANGELOG_FIXED = "修复"
L.CHANGELOG_REMOVED = "移除"
L.CHANGELOG_CONTROLLER = "手柄界面"
L.CHANGELOG_SETTINGS = "设置"
L.CHANGELOG_COMMANDS = "命令"

-- Settings: the About page
L.HOME_TAGLINE = "为WoW Forever的默认界面带来的小型增添与改动。"
L.HOME_DEFAULTS = "默认设置"
-- The popup of the Defaults button at the top right of the Modules, Changelog, and About pages
L.DEFAULTS_ASK = "将Forever++的所有设置恢复默认？这会替换你当前的Forever++设置。游戏的其他设置保持不变。"
L.DEFAULTS_DEVELOPER = "开发者的默认设置"
L.DEFAULTS_RECOMMENDED = "推荐的默认设置"
L.HOME_MODULES_ON = "已开启%d/%d个模块" -- on, total
L.HOME_GAME_BUILD = "游戏%s（%s）" -- version, build
-- The Language dropdown on the About page. A language's own name is never translated (Core.lua).
L.LANGUAGE = "语言"
L.LANGUAGE_CLIENT = "游戏客户端：%s" -- the client's language, as the dropdown names it
L.LANGUAGE_DESC = "Forever++文字使用的语言。“游戏客户端”表示跟随游戏本身的语言。更改后会重新加载界面。"
L.LANGUAGE_WARNING = "选择游戏客户端以外的语言时，部分文字可能无法正常显示（会变成方块），"
    .. "而且Forever++中的游戏自带名称仍为英文。"
L.LANGUAGE_RELOAD = "以%s显示Forever++？这会重新加载界面。" -- the language's name
L.HOME_LINKS = "链接"
L.HOME_LINK_CURSEFORGE = "CurseForge"
L.HOME_LINK_WAGO = "Wago"
L.HOME_LINK_SOURCE = "源代码"
L.HOME_LINK_RELEASES = "发布版本"
L.HOME_LINK_BUG = "报告错误"
L.HOME_LINK_REQUEST = "功能建议"
L.HOME_LINK_HINT = "点击一个即可复制它的链接。"
L.HOME_COPY = "按Ctrl+C复制链接。"
L.HOME_CREDITS = "制作人员"
L.HOME_AUTHOR = "作者"
L.HOME_EVERYONE = "所有人" -- the last name in the credits: the players
L.HOME_EVERYONE_THANKS = "感谢大家源源不断的错误报告、建议和反馈。"
L.HOME_WORKS_WITH = "兼容插件"
L.HOME_QUEST_DATA = "为%s提供任务数据" -- the modules that read QuestieDB
L.HOME_SUPPORT = "在%s中提供额外支持" -- the module or option another addon adds to
L.HOME_COMMANDS = "命令"
L.HOME_COMMANDS_GENERAL = "综合" -- the commands no one module owns
L.HOME_COMMANDS_SEARCH = "搜索"
L.HOME_COMMANDS_HINT = "<点击以在聊天中输入命令>"

-- Edit Mode dialog for our own frames (Lib/EditMode.lua)
L.EDITMODE_SCALE = "缩放"
L.SETTINGS_EDIT_MODE_NOTE = "它的位置和布局在编辑模式中设置：按Esc，选择编辑模式，然后点击它。" -- a gray row on a module with Edit Mode settings
L.SETTINGS_EDIT_MODE_NOTE_DESC = "它的位置、缩放和布局设置位于编辑模式的对话框以及那里的右键菜单中，就在"
    .. "它们所改动的框体旁边。"

-- The gray row on a module another addon adds (Lib/Plugins.lua)
L.PLUGIN_NOTICE = "由另一个插件添加。"
L.PLUGIN_NOTICE_ADDON = "由%s插件添加。" -- the addon's folder name
L.PLUGIN_NOTICE_DESC = "此模块不属于Forever++：是另一个插件把它添加到这里的。有问题请告诉那个插件的作者。"
-- Gray rows on a module that reads the QuestieDB addon's data (Lib/QuestieDB.lua)
L.QUESTIEDB_NEEDED = "需要QuestieDB插件。"
L.QUESTIEDB_NEEDED_DESC = "它的任务、生物、物品和物体数据来自QuestieDB，这是一个单独的插件。请下载并安装，"
    .. "在插件列表中启用它，然后重新加载。在此之前无法开启此模块。"
L.QUESTIEDB_LOCKED = "已锁定：此模块需要QuestieDB插件。请下载后重新加载。"
L.QUESTIEDB_PROBLEM = "此版本的QuestieDB与Forever++不兼容。"
L.QUESTIEDB_PROBLEM_DESC = "QuestieDB已开启，但它的回应方式与Forever++读取的方式不符。请更新两者中较旧的那个。"
