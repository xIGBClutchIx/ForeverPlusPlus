local _, ns = ...
local L = ns.NewLocale("zhCN")
if not L then
    return
end

-- CharacterWindow
L.CHARACTERWINDOW_TITLE = "角色窗口"
L.CHARACTERWINDOW_DESC = "整理角色窗口：装备、头衔和宠物改为侧边标签，属性从顶部开始，等级和名字使用你的职业"
    .. "颜色，每件物品旁显示耐久度条。"
L.CHARACTERWINDOW_SIDETABS = "侧边标签"
L.CHARACTERWINDOW_SIDETABS_DESC = "把装备、头衔和宠物标签移到声望、技能等标签旁边，并去掉属性上方的头像，让属性从顶部"
    .. "开始。它们与其他标签用法相同：选择“角色”标签即可回到属性。"
L.CHARACTERWINDOW_COLORTITLE = "彩色标题"
L.CHARACTERWINDOW_COLORTITLE_DESC = "在窗口标题中，于你的名字（职业颜色）前显示你的等级（金色），代替窗口顶部游戏自己的"
    .. "等级一行。"
L.CHARACTERWINDOW_TITLE_FORMAT = "%s %s" -- level, name
L.CHARACTERWINDOW_DURABILITY = "耐久度条"
L.CHARACTERWINDOW_DURABILITY_DESC = "每件物品旁的小条，从绿色到红色显示其磨损程度，并可选择哪些物品显示。没有耐久度的"
    .. "物品从不显示。"
L.CHARACTERWINDOW_DURABILITY_ALWAYS = "总是"
L.CHARACTERWINDOW_DURABILITY_WORN = "仅在磨损时"
L.CHARACTERWINDOW_DURABILITY_HALF = "低于50%"
L.CHARACTERWINDOW_DURABILITY_QUARTER = "低于25%"
L.CHARACTERWINDOW_DURABILITY_OFF = "关闭"
L.CHARACTERWINDOW_WEAPONSKILLS = "已装备武器的技能"
L.CHARACTERWINDOW_WEAPONSKILLS_DESC = "在技能标签中，把你已装备的武器所对应的武器技能条显示为绿色，而不是蓝色。"
L.CHARACTERWINDOW_SECTION_ITEMS = "物品"
L.CHARACTERWINDOW_ITEMLEVEL = "已装备物品等级"
L.CHARACTERWINDOW_ITEMLEVEL_DESC = "在每件物品的图标上以其品质颜色显示物品等级。"
L.CHARACTERWINDOW_ENCHANTS = "附魔标记"
L.CHARACTERWINDOW_ENCHANTS_DESC = "在可附魔物品靠近角色的一角加上标记：已附魔为绿色，未附魔为红色。"
    .. "戒指、饰品、衬衣和战袍无法附魔，不会标记；腰带只在有附魔时标记。"
L.CHARACTERWINDOW_ENCHANT_MARK = "附"
L.CHARACTERWINDOW_INSPECT = "观察窗口"
L.CHARACTERWINDOW_INSPECT_DESC = "在你观察的玩家的物品上也显示这些信息。"

-- Durability Warning
L.DURABILITYWARNING_TITLE = "耐久度警告"
L.DURABILITYWARNING_DESC = "当你身上磨损最严重的装备低于你选择的耐久度时提醒一次，装备损坏时再提醒一次，让你及时"
    .. "修理。只有修理之后才会再次提醒。"
L.DURABILITYWARNING_THRESHOLD = "低于此值时警告"
L.DURABILITYWARNING_THRESHOLD_DESC = "你穿着的物品耐久度低于此值时警告。"
L.DURABILITYWARNING_BROKEN = "损坏时警告"
L.DURABILITYWARNING_BROKEN_DESC = "你穿着的物品损坏、不再提供属性时，再警告一次。"
L.DURABILITYWARNING_ALERT = "屏幕提示"
L.DURABILITYWARNING_ALERT_DESC = "在屏幕中央以红字显示警告，即游戏提示“物品栏已满”的位置。"
L.DURABILITYWARNING_SOUND_DESC = "警告时播放声音。选择一个声音时会播放它。"
L.DURABILITYWARNING_CHAT_DESC = "在聊天中说明哪件物品磨损了，还剩多少。登录时就已磨损的装备，在载入完成后只会收到"
    .. "这一行提示。"
L.DURABILITYWARNING_LOW_ITEM = "%s的耐久度为%d%%。请尽快修理。" -- item link, percent
L.DURABILITYWARNING_LOW_GEAR = "你的装备耐久度为%d%%。请尽快修理。" -- percent
L.DURABILITYWARNING_BROKEN_ITEM = "%s已损坏。修理后才能恢复其属性。" -- item link
L.DURABILITYWARNING_BROKEN_GEAR = "你穿着的一件物品已损坏。修理后才能恢复其属性。"
L.DURABILITYWARNING_ALERT_LOW = "你的装备耐久度为%d%%" -- percent
L.DURABILITYWARNING_ALERT_BROKEN = "你穿着的一件物品已损坏"
L.DURABILITYWARNING_TEST = "测试警告"
L.DURABILITYWARNING_TEST_BUTTON = "测试"
L.DURABILITYWARNING_TEST_DESC = "立即以所有已开启的方式发出低耐久度警告。"

-- Talent Planner
L.TALENTPLANNER_TITLE = "天赋规划"
L.TALENTPLANNER_DESC = "在天赋窗口中加入“规划天赋”按钮：按顺序自由放置天赋，最多到你所选等级拥有的点数，"
    .. "并在升级时按规划加点。"
L.TALENTPLANNER_GLOW = "高亮下一个天赋"
L.TALENTPLANNER_GLOW_DESC = "当你有可用的天赋点数时，让规划中的下一个天赋发出金光。"
L.TALENTPLANNER_TOOLTIP = "提示信息"
L.TALENTPLANNER_TOOLTIP_DESC = "在天赋的提示信息中加入规划在哪些等级选取它。"
L.TALENTPLANNER_REMINDER = "升级提醒"
L.TALENTPLANNER_REMINDER_DESC = "获得天赋点数时，在聊天中提示规划中的下一个天赋。"
-- talent, the rank this point takes it to, its most ranks
L.TALENTPLANNER_REMINDER_LINE = "有可用的天赋点数。规划中的下一个：%s（%d/%d）。"
L.TALENTPLANNER_PLAN = "规划天赋"
L.TALENTPLANNER_DONE = "完成规划"
L.TALENTPLANNER_PLAN_DESC = "放置天赋而不学习它们。每次点击都会按顺序向规划中加一点，让你在升级时照着加点。"
    .. "规划会为此角色保存。"
L.TALENTPLANNER_CLICK = "<点击以增加一点>\n<右键点击以移除一点>\n<按住Shift以一次增加或移除所有等级>"
L.TALENTPLANNER_CLICK_MAXED = "<右键点击以移除一点>\n<按住Shift以一次移除所有等级>" -- at its highest rank
-- With the controller interface on, where there are no clicks
-- Each %s is a button as the player's controller shows it (Gamepad.Label): A, then Y
L.TALENTPLANNER_CLICK_PAD = "<按%s以增加一点>\n<按%s以移除一点>"
L.TALENTPLANNER_CLICK_PAD_MAXED = "<按%s以移除一点>" -- at its highest rank
L.TALENTPLANNER_PLANNED = "规划等级："
L.TALENTPLANNER_POINTS = "已规划点数：%d/%d" -- planned, points at the plan's level
L.TALENTPLANNER_MORE = "（此等级之后还有%d点）"
L.TALENTPLANNER_NEXT = "下一个：%s（等级%d）" -- talent name, level
L.TALENTPLANNER_COMPLETE = "天赋规划已完成。"
L.TALENTPLANNER_ORDER = "天赋顺序"
L.TALENTPLANNER_UPCOMING = "即将选取的天赋"
L.TALENTPLANNER_LEVEL_ONE = "等级%d"
L.TALENTPLANNER_LEVEL_RANGE = "等级%d-%d" -- first and last level
L.TALENTPLANNER_MORE_LINES = "……还有%d个"
L.TALENTPLANNER_LEVEL = "等级"
L.TALENTPLANNER_LEVEL_DESC = "只规划角色在这个等级拥有的天赋点数。"
L.TALENTPLANNER_CLEAR = "清除"
L.TALENTPLANNER_CLEAR_DESC = "从规划中移除所有点数。"
L.TALENTPLANNER_CLEAR_CONFIRM = "清除你的天赋规划？"
L.TALENTPLANNER_RESET = "重置"
L.TALENTPLANNER_RESET_DESC = "从你已学会的天赋重新开始规划。"
L.TALENTPLANNER_RESET_CONFIRM = "从你已学会的天赋重新开始你的天赋规划？"
L.TALENTPLANNER_NO_POINTS = "在等级%d已没有剩余的天赋点数。"
L.TALENTPLANNER_MAXED = "该天赋已达到最高等级。"
L.TALENTPLANNER_TIER = "需要在%2$s中投入%1$d点。" -- points, tab name
L.TALENTPLANNER_PREREQ = "需要%s达到最高等级。" -- talent names
L.TALENTPLANNER_NEEDED = "在它之后规划的天赋需要这一点。"
L.TALENTPLANNER_PLAN_NAME = "规划%d"
L.TALENTPLANNER_NEW = "新建规划"
L.TALENTPLANNER_NEW_PROMPT = "为新的天赋规划命名。它将从你已学会的天赋开始。"
L.TALENTPLANNER_RENAME = "重命名规划"
L.TALENTPLANNER_RENAME_PROMPT = "重命名这个天赋规划："
L.TALENTPLANNER_SHARE = "分享规划"
L.TALENTPLANNER_SHARE_PROMPT = "按Ctrl+C复制这个天赋规划。同一职业的任何角色都可以用“导入规划”读取它。"
L.TALENTPLANNER_IMPORT = "导入规划"
L.TALENTPLANNER_IMPORT_DESC = "粘贴从Forever++分享的天赋规划，或来自talentsforever.com或wowforevertalents.com的"
    .. "天赋链接，作为新的规划。"
L.TALENTPLANNER_IMPORT_PROMPT = "粘贴分享的天赋规划，或来自talentsforever.com或wowforevertalents.com的天赋链接"
    .. "（Ctrl+V）："
L.TALENTPLANNER_IMPORT_BAD = "这不是分享的天赋规划，也不是来自talentsforever.com或wowforevertalents.com的天赋链接。"
L.TALENTPLANNER_IMPORT_CLASS = "该天赋规划属于另一个职业。"
L.TALENTPLANNER_IMPORT_INVALID = "该天赋规划与此天赋树不符。"
-- The %s in these three is the site the link is from, such as talentsforever.com.
L.TALENTPLANNER_IMPORT_OLD = "该链接来自旧版本的%s。请在那里打开它，再复制一次链接。"
L.TALENTPLANNER_IMPORT_NEW = "该链接来自比此版本Forever++所能读取的更新的%s。请更新Forever++后再导入。"
L.TALENTPLANNER_IMPORT_TREE = "你的天赋树与该链接在%s上创建时的天赋树不同，因此无法确定其点数的位置。"
L.TALENTPLANNER_IMPORT_RANK = "该链接在某个天赋上投入的等级超过了它的上限。"
L.TALENTPLANNER_IMPORT_POINTS = "该链接使用了%d个天赋点数，超过了角色拥有的%d个。"
L.TALENTPLANNER_DELETE = "删除规划"
L.TALENTPLANNER_DELETE_CONFIRM = "删除这个天赋规划？"

-- Macros
L.MACROS_DESC = "由Forever++在你的通用宏中创建并保持更新的宏，每个都有自己的复选框，关闭时会被删除。从宏命令"
    .. "窗口（/macro）中拖出，或使用其“拾取”按钮。"
L.MACROS_NOTICE = "战斗中宏无法更改：战斗结束后才会更新。"
L.MACROS_NOTICE_DESC = "游戏不允许插件在战斗中创建或更改宏。在战斗结束前，宏保持最后的内容；当它对你的新目标"
    .. "已过时，其按钮会显示警告。"
L.MACROS_FAILED = "无法创建%s宏：%s" -- the macro's name, then why
L.MACROS_FULL_REASON = "已经没有空位放置另一个通用宏"
L.MACROS_MISSING = "%s宏尚未创建"
L.MACROS_IN_COMBAT = "战斗中无法拾取宏。"
L.MACROS_PICKUP_BUTTON = "拾取"
L.MACROS_SMARTBUFF = "智能增益"
-- The macro's name, at most 16 letters. The same in every language: the module finds its macro
-- by this name, so another name would make a second one.
L.MACROS_SMARTBUFF_DESC = "一个宏，对你的友方目标（没有目标时对你自己）施放其应从你这里获得的增益效果，使用你"
    .. "已学会且对方可以接受的最高等级：按职业选择力量祝福或智慧祝福、真言术：韧、奥术智慧、野性印记等；当"
    .. "这些都不适合对方时，只要不会替换掉你自己的增益，就施放一个对方可能用不上的。对方已有的增益，或更强的"
    .. "增益（例如强效祝福或坚韧祷言），会被跳过；当对方无法从你这里获得增益时，就为你自己施放；两者都没有"
    .. "可施放的增益时，其按钮会显示红色的X。战斗中它无法更改：当它会施放错误的增益时会显示警告。"
L.MACROS_SMARTBUFF_RECAST = "低于此值时重新施放"
L.MACROS_SMARTBUFF_RECAST_DESC = "剩余时间少于此比例的增益视为缺失，宏会再次施放：设为50%时，30分钟的增益会在最后"
    .. "15分钟内重新施放。"
L.MACROS_SMARTBUFF_RECAST_FORMAT = "%d%%"
L.MACROS_SMARTBUFF_TARGET = "你的目标"
L.MACROS_SMARTBUFF_HAS = "%s已经有%s" -- the target, then the buff
L.MACROS_SMARTBUFF_HAS_SELF = "%s已经有%s，改为对你施放"
L.MACROS_SMARTBUFF_HAS_ALL = "%s已经有你能给予的所有增益"
L.MACROS_SMARTBUFF_HAS_ALL_SELF = "%s已经有你能给予的所有增益，改为对你施放"
L.MACROS_SMARTBUFF_CANT = "%s无法获得增益"
L.MACROS_SMARTBUFF_CANT_SELF = "%s无法获得增益，改为对你施放"
L.MACROS_SMARTBUFF_NOTHING = "你已经拥有你能拥有的所有增益"
L.MACROS_SMARTBUFF_COMMAND = "显示“智能增益”如何判断你的友方目标（或你自己）：你的每种增益、对方已有哪些，以及它会"
    .. "施放什么"
L.MACROS_SMARTBUFF_STALE = "战斗中“智能增益”无法更改"
L.MACROS_SMARTBUFF_PICKUP = "智能增益宏"
L.MACROS_SMARTBUFF_PICKUP_DESC = "把“智能增益”宏放到你的光标上，以便拖到动作条上。"

-- Professions
L.PROFESSIONS_DESC = "在专业窗口中添加：按技能提升几率着色的配方、每个配方剩余的技能提升次数、显示配方变色"
    .. "等级的条、配方的制作成本与产出价值的对比，以及你尚未学会的配方。每一项都有自己的复选框。"
L.PROFESSIONS_NO_PRICES = "“制作成本”没有拍卖价格：“物品提示信息”的“显示拍卖价格”已关闭。"
L.PROFESSIONS_NO_PRICES_DESC = "没有拍卖价格时，“制作成本”只计算商人的售价和收购价，因此大多数总计会显示“无价格”，"
    .. "大多数配方也不显示利润。"
-- Recipe Colors
L.PROFESSIONS_COLORS = "配方颜色"
L.PROFESSIONS_COLORS_DESC = "在配方列表中按技能提升几率为配方着色：橙色必定提升，黄色通常提升，绿色有时提升，灰色"
    .. "不再提升。"
L.PROFESSIONS_HIGHLIGHT = "高亮行着色"
L.PROFESSIONS_HIGHLIGHT_DESC = "让配方的选中高亮和鼠标指向高亮与其名字颜色一致。"
L.PROFESSIONS_GRAY = "灰显已练满的配方"
L.PROFESSIONS_GRAY_DESC = "用灰色显示你已学会但不能再提升技能的配方。"
-- Skill-Ups Left
L.PROFESSIONS_SKILLUPS = "剩余技能提升"
L.PROFESSIONS_SKILLUPS_DESC = "显示你已学会的每个配方还能提升技能多久：在其所在行显示一个数字，并在所选配方的名字"
    .. "下方显示一行。"
L.PROFESSIONS_POINTS = "配方列表中的技能提升"
L.PROFESSIONS_POINTS_DESC = "在每个仍能提升技能的配方末尾显示一个数字：它变灰之前还剩多少次技能提升，或它变灰时的"
    .. "技能等级。"
L.PROFESSIONS_POINTS_LEFT = "剩余次数"
L.PROFESSIONS_POINTS_GRAY = "变灰等级"
L.PROFESSIONS_POINTS_OFF = "关闭"
L.PROFESSIONS_DETAIL = "所选配方的技能提升"
L.PROFESSIONS_DETAIL_DESC = "在所选配方的名字下方，显示它停止提升技能时的技能等级，以及还剩多少次。显示“技能条”的"
    .. "条时，由它代替这一行。"
L.PROFESSIONS_DETAIL_UNTIL = "技能提升至%d" -- the skill a recipe turns gray at
L.PROFESSIONS_DETAIL_MORE = "技能提升至%d %s" -- the skill, then PROFESSIONS_DETAIL_LEFT in gray
L.PROFESSIONS_DETAIL_LEFT = "（还剩%d次）"
L.PROFESSIONS_DETAIL_DONE = "不再提升技能（%d时变灰）"
-- Skill Bar
L.PROFESSIONS_BAR = "技能条"
L.PROFESSIONS_BAR_DESC = "在所选配方的名字下方显示一条，标出它变黄、变绿和变灰的技能等级，并标出你的技能。"
L.PROFESSIONS_BAR_LEVELS = "条上显示等级"
L.PROFESSIONS_BAR_LEVELS_DESC = "在条上写出每种颜色开始的技能等级。无论是否开启，指向条时都会列出它们。"
L.PROFESSIONS_BAR_ESTIMATE = "“技能条”的等级是估计值。"
L.PROFESSIONS_BAR_ESTIMATE_DESC = "游戏的配方信息只给出配方变灰的等级。黄色等级来自游戏的数据表，绿色则像经典旧世"
    .. "那样取两者的中间值。等级与游戏所显示颜色不符的配方不显示技能条。"
L.PROFESSIONS_BAR_YELLOW = "黄色"
L.PROFESSIONS_BAR_GREEN = "绿色"
L.PROFESSIONS_BAR_GRAY = "灰色"
L.PROFESSIONS_BAR_SKILL = "你的技能"
L.PROFESSIONS_BAR_NOTE = "黄色和灰色来自游戏数据；绿色取两者中间。"
-- Unlearned Recipes
L.PROFESSIONS_UNLEARNED = "未学习的配方"
L.PROFESSIONS_UNLEARNED_DESC = "配方列表“过滤器”菜单中的“显示未学习”会像现代版游戏那样，把该专业中你尚未学会的配方"
    .. "列在列表中，并显示学习每个配方所需的技能（绿色表示现在可学，黄色表示很快可学，红色表示以后可学），"
    .. "在其页面上显示教授它的配方物品。“未学习”子菜单可筛选它们。"
-- Shown where the client lacks Blizzard's own strings for these.
L.PROFESSIONS_UNLEARNED_MENU = "未学习"
L.PROFESSIONS_UNLEARNED_SOURCES = "来源"
L.PROFESSIONS_UNLEARNED_LEARNED_DESC = "在配方列表中列出你已学会的配方。开启“显示未学习”时关闭此项，即可只看你尚未学会"
    .. "的配方。列表的“过滤器”菜单中也有同样的复选框。"
L.PROFESSIONS_UNLEARNED_SHOW_DESC = "在配方列表中列出你尚未学会的配方，每个都放在你已学会配方的对应分类中。列表的"
    .. "“过滤器”菜单中也有同样的复选框。"
L.PROFESSIONS_UNLEARNED_ITEMS = "配方物品"
L.PROFESSIONS_UNLEARNED_ITEMS_DESC = "由配方物品（设计图、图样、配方）教授的配方。"
L.PROFESSIONS_UNLEARNED_OTHERS = "训练师及其他"
L.PROFESSIONS_UNLEARNED_OTHERS_DESC = "不由配方物品教授的配方：来自训练师等。"
L.PROFESSIONS_UNLEARNED_WHEN = "可学习"
L.PROFESSIONS_UNLEARNED_NOW = "现在"
L.PROFESSIONS_UNLEARNED_NOW_DESC = "你的技能已足够学习的配方。"
L.PROFESSIONS_UNLEARNED_SOON = "很快"
L.PROFESSIONS_UNLEARNED_SOON_DESC = "你的技能还差几点的配方。"
L.PROFESSIONS_UNLEARNED_UNKNOWN = "未知"
L.PROFESSIONS_UNLEARNED_UNKNOWN_DESC = "所需技能尚不明确的配方：大多是训练师的配方，要等你打开教授它们的训练师后才能知道。"
L.PROFESSIONS_UNLEARNED_WITHIN = "“很快”的范围"
L.PROFESSIONS_UNLEARNED_WITHIN_DESC = "配方所需技能比你高多少点以内，仍算作很快可学。"
L.PROFESSIONS_UNLEARNED_LATER = "稍后"
L.PROFESSIONS_UNLEARNED_LATER_DESC = "距离学会还差较多技能点，或所需技能点超过当前专业等级上限的配方。"
L.PROFESSIONS_UNLEARNED_BAGS = "背包中的配方"
L.PROFESSIONS_UNLEARNED_BAGS_DESC = "只显示你正携带其配方物品的配方。"
L.PROFESSIONS_UNLEARNED_LIMITS = "“未学习的配方”会在你打开训练师时得知训练师配方所需的技能。"
L.PROFESSIONS_UNLEARNED_LIMITS_DESC = "游戏的数据表给出了配方物品所需的技能，但没有给出训练师要求的技能。后者会从你打开"
    .. "的每个专业训练师处得知，并为整个账号记住；在此之前，该配方列在“未知”下。"
L.PROFESSIONS_UNLEARNED_TAUGHT = "学习自：%s" -- the item, with what follows it
L.PROFESSIONS_UNLEARNED_OWNED = "%s |cff20ff20（在你的背包中）|r" -- the item's name
L.PROFESSIONS_UNLEARNED_PRICED = "%s  %s" -- the item, its auction price
-- Crafting Costs
L.PROFESSIONS_CRAFTING = "制作成本"
L.PROFESSIONS_CRAFTING_DESC = "为所选配方显示总成本、价值和预计利润（扣除拍卖行5%的手续费后），以及所用最旧拍卖"
    .. "价格的时间。材料在商人售价更低时按商人售价计算，没有拍卖价格的物品按商人收购价计算价值。"
L.PROFESSIONS_CRAFTING_ROWS = "配方列表中的利润"
L.PROFESSIONS_CRAFTING_ROWS_DESC = "在配方列表中每个配方所在行的右侧显示其预计利润，盈利为绿色，亏损为红色。不产出物品的"
    .. "附魔不显示。"
L.PROFESSIONS_CRAFTING_SORT = "配方列表排序"
L.PROFESSIONS_CRAFTING_SORT_DESC = "将配方列表每个分类中的配方按预计利润（从高到低）或总成本（从低到高）排序，"
    .. "并在每行显示该数值。缺少价格的配方排在最后。专业窗口的筛选菜单中也有此选项。"
L.PROFESSIONS_CRAFTING_SORT_DEFAULT = "默认"
L.PROFESSIONS_CRAFTING_FLAT = "不分类"
L.PROFESSIONS_CRAFTING_FLAT_DESC = "把所有配方排在一个列表中，不分类，收藏的配方也排在其中，这样最好的排在最上面。"
    .. "筛选菜单中也有此选项。"
L.PROFESSIONS_CRAFTING_TOOLTIP = "配方上的制作成本"
L.PROFESSIONS_CRAFTING_TOOLTIP_DESC = "在学习之前，于设计图、图样或配方的提示信息中显示制作该配方的成本：与专业窗口中的"
    .. "总成本相同。"
L.PROFESSIONS_CRAFTING_SELL = "出售渠道"
L.PROFESSIONS_CRAFTING_SELL_DESC = "价值和预计利润按在哪里出售制作的物品来计算。“较高价格”取拍卖行（扣除手续费后）和"
    .. "商人中出价更高的一方。在拍卖价值下方，“商人价值”显示商人的收购价。"
L.PROFESSIONS_CRAFTING_SELL_AUCTION = "拍卖行"
L.PROFESSIONS_CRAFTING_SELL_VENDOR = "商人"
L.PROFESSIONS_CRAFTING_SELL_BEST = "较高价格"
L.PROFESSIONS_CRAFT_VENDOR_VALUE = "商人价值"
L.PROFESSIONS_CRAFTING_WRITS = "完成工匠文书的成本"
L.PROFESSIONS_CRAFTING_WRITS_DESC = "在工匠文书的提示信息中显示其所需物品的制作成本，以及在拍卖行购买的价格。"
L.PROFESSIONS_WRIT_BUY = "购买成本"
L.PROFESSIONS_WRIT_COUNT = "%d个"
L.PROFESSIONS_CRAFT_NO_PRICE = "无价格"
L.PROFESSIONS_CRAFT_EACH = "%s  %s" -- coins, then a gray note
L.PROFESSIONS_CRAFT_COST = "总成本"
L.PROFESSIONS_CRAFT_TOOLTIP = "制作成本"
L.PROFESSIONS_CRAFT_PARTIAL = "并非所有材料都有价格"
L.PROFESSIONS_CRAFT_VALUE = "价值"
L.PROFESSIONS_CRAFT_VALUE_COUNT = "价值 x%s" -- how many the recipe makes
L.PROFESSIONS_CRAFT_RANGE = "%d-%d" -- fewest and most the recipe makes
L.PROFESSIONS_CRAFT_VENDOR = "商人"
L.PROFESSIONS_CRAFT_PROFIT = "预计利润"
L.PROFESSIONS_CRAFT_AGE = "最旧价格"

-- SpellRanks
L.SPELLRANKS_TITLE = "法术等级"
L.SPELLRANKS_PART_SCAN = "扫描法术书" -- its row on the Profiler page
L.SPELLRANKS_DESC = "标记动作条上那些你已学会更高等级的法术，并在其提示信息中注明最高等级。/fpp ranks可列出它们。"
L.SPELLRANKS_STYLE = "标记样式"
L.SPELLRANKS_STYLE_DESC = "如何标记法术等级过时的动作按钮。"
L.SPELLRANKS_STYLE_BADGE = "警告标志"
L.SPELLRANKS_STYLE_TINT = "红色色调"
L.SPELLRANKS_CORNER_DESC = "警告标志显示在动作按钮的哪个角落。"
L.SPELLRANKS_SIZE = "标志大小"
L.SPELLRANKS_SIZE_DESC = "警告标志在标准动作按钮上的大小。在更小或更大的按钮上会按比例缩放。"
L.SPELLRANKS_TOOLTIP = "提示信息"
L.SPELLRANKS_TOOLTIP_DESC = "在有更高等级的法术的提示信息中加入你已学会的最高等级。"
L.SPELLRANKS_REPLACE = "使用最高等级"
L.SPELLRANKS_REPLACE_DESC = "学会法术时，以及开启此项时，把动作条上所有较低等级替换为你已学会的最高等级。仅在非"
    .. "战斗状态下进行，不包括宏。如果你特意在动作条上保留低等级，请不要开启。"
L.SPELLRANKS_REPLACED = { -- count
    "已把%d个法术的最高等级放到你的动作条上。",
}
L.SPELLRANKS_CHAT_DESC = "学会新法术或升级后，在聊天中提示动作条上有多少法术有更高等级，以及“使用最高等级”替换了多少。"
L.SPELLRANKS_BEST = "已学会更高等级："
L.SPELLRANKS_BEST_RANK = "等级 %d" -- the best rank known
L.SPELLRANKS_FOUND = { -- count
    "动作条上有%d个法术有更高等级。/fpp ranks可列出它们。",
}
L.SPELLRANKS_COMMAND = "列出动作条上有更高等级的法术"
L.SPELLRANKS_OFF = "“法术等级”已关闭。"
L.SPELLRANKS_NONE = "你动作条上的每个法术都已是最高等级。"
L.SPELLRANKS_LINE = "动作条%d，栏位%d：%s为等级%d，已学会等级%d。" -- bar, slot, spell link, ranks

-- TrainAll
L.TRAINALL_TITLE = "全部训练"
L.TRAINALL_DESC = "在训练师窗口中加入“全部训练”按钮，学习所有你能学且负担得起的技能。新的专业留给你自己选择。"
L.TRAINALL_BUTTON = "全部训练"
L.TRAINALL_TOOLTIP = { "学习%d项技能，花费%s。" } -- count, money
L.TRAINALL_NOTHING = "这里没有你能学且负担得起的技能。"

-- BuffTimers
L.BUFFTIMERS_TITLE = "增益计时"
L.BUFFTIMERS_DESC = "以时钟形式（例如1:23）显示增益和负面效果的剩余时间，而不是“2分”这样取整的分钟数。它还可以"
    .. "按剩余时间排序你的增益，并把追踪类增益移出增益栏。"
L.BUFFTIMERS_NOTICE = "战斗中可能会改为显示暴雪自己的计时。" -- a gray row atop the module
L.BUFFTIMERS_NOTICE_DESC = "战斗中游戏可能会对插件隐藏光环的时间。此时会显示暴雪取整的计时，直到能再次读取为止。"
L.BUFFTIMERS_BLIZZARD_OFF = "暴雪的增益持续时间已关闭" -- a gray row atop the module, with a button
L.BUFFTIMERS_BLIZZARD_OFF_DESC = "暴雪的增益持续时间已关闭，因此增益和负面效果下方不显示时间，我们的也不例外。"
L.BUFFTIMERS_LIMIT = "显示时钟"
L.BUFFTIMERS_LIMIT_DESC = "哪些光环显示时钟。更长的保留暴雪的计时。"
L.BUFFTIMERS_LIMIT_1M = "1分钟以下"
L.BUFFTIMERS_LIMIT_10M = "10分钟以下"
L.BUFFTIMERS_LIMIT_1H = "1小时以下"
L.BUFFTIMERS_LIMIT_ALL = "总是"
L.BUFFTIMERS_SORT = "增益排序"
L.BUFFTIMERS_SORT_DESC = "按剩余时间排列你的增益，让最先结束的位于一端，永不结束的位于另一端。在垂直的增益栏中，"
    .. "左侧即顶部。"
L.BUFFTIMERS_SORT_OFF = "关闭"
L.BUFFTIMERS_SORT_LEFT = "最短的在左"
L.BUFFTIMERS_SORT_RIGHT = "最短的在右"
L.BUFFTIMERS_SORT_NOTICE = "战斗中增益可能会恢复暴雪的顺序。" -- a gray row atop the module
L.BUFFTIMERS_SORT_NOTICE_DESC = "战斗中游戏可能会对插件隐藏增益的时间。此时获得或失去增益会使你的增益恢复暴雪的"
    .. "顺序，直到能再次读取时间为止。"
L.BUFFTIMERS_HIDE_TRACKING = "隐藏追踪增益"
L.BUFFTIMERS_HIDE_TRACKING_DESC = "不在增益栏中显示小地图追踪（例如寻找草药和寻找矿物）。追踪仍然有效，可在小地图的"
    .. "追踪菜单中更改。"
L.BUFFTIMERS_HIDE_NOTICE = "战斗中追踪增益可能会再次显示。" -- a gray row atop the module
L.BUFFTIMERS_HIDE_NOTICE_DESC = "战斗中游戏可能会对插件隐藏哪个增益是哪个。此时获得或失去增益会显示追踪增益，直到"
    .. "能再次读取为止。"

-- XPBarText
L.XPBARTEXT_TITLE = "经验条文字"
L.XPBARTEXT_DESC = "在经验条上始终显示你的经验值，包括百分比、休息奖励经验值，以及任务将给予的经验值；交付"
    .. "任务就能升级时显示为绿色。"
L.XPBARTEXT_ALWAYS = "总是显示文字"
L.XPBARTEXT_ALWAYS_DESC = "始终显示文字。关闭后，像暴雪默认那样只在鼠标指向经验条时显示。"
L.XPBARTEXT_PERCENT = "显示百分比"
L.XPBARTEXT_PERCENT_DESC = "以升到下一级所需经验值为基准，用百分比显示当前进度、休息奖励经验值和任务经验值。"
L.XPBARTEXT_RESTED = "显示休息奖励经验值"
L.XPBARTEXT_RESTED_DESC = "显示剩余的休息奖励经验值。"
L.XPBARTEXT_QUESTS = "显示任务经验值"
L.XPBARTEXT_QUESTS_DESC = "显示任务日志中的任务给予的经验值：只算可以交付的，或全部。"
L.XPBARTEXT_QUESTS_COMPLETE = "可以交付的"
L.XPBARTEXT_QUESTS_ALL = "所有任务"
L.XPBARTEXT_QUESTS_OFF = "关闭"
L.XPBARTEXT_QUEST_COLOR = "任务可升级时显示绿色"
L.XPBARTEXT_QUEST_COLOR_DESC = "交付这些任务就能升级时，以绿色显示任务经验值文字。"
L.XPBARTEXT_RATE = "显示每小时经验值"
L.XPBARTEXT_RATE_DESC = "在你游戏一分钟并获得一些经验值后，显示登录以来的每小时经验值，以及按此速度升级所需的时间。"
L.XPBARTEXT_QUEST_BAR = "在经验条显示可交付任务的经验值"
L.XPBARTEXT_QUEST_BAR_DESC = "像显示休息奖励经验值那样，在你的经验值之后用绿色继续填充可交付任务的经验值。"
L.XPBARTEXT_SECTION_TEXT = "文本"
L.XPBARTEXT_SECTION_BAR = "经验条和提示信息"
L.XPBARTEXT_TOOLTIP = "详细提示信息"
L.XPBARTEXT_TOOLTIP_DESC = "在经验条的提示信息中加入升级所需的经验值、休息奖励经验值、任务经验值，以及登录以来的"
    .. "每小时经验值和升级所需时间。"
L.XPBARTEXT_TIP_LEFT = "升级还需："
L.XPBARTEXT_TIP_RESTED = "休息奖励经验值："
L.XPBARTEXT_TIP_READY = "可交付任务："
L.XPBARTEXT_TIP_ALL = "所有任务："
L.XPBARTEXT_TIP_RATE = "每小时经验值："
L.XPBARTEXT_TIP_TIME = "升级所需时间："
L.XPBARTEXT_XP = "经验值：%s / %s" -- current, needed for the level
L.XPBARTEXT_WITH_PERCENT = "%s（%d%%）" -- the XP text, its percent
L.XPBARTEXT_AMOUNT = "%s（%d%%）" -- an amount of XP, as a percent of the level
L.XPBARTEXT_RESTED_TEXT = "休息奖励：%s"
L.XPBARTEXT_QUESTS_TEXT = "任务：%s"
L.XPBARTEXT_RATE_TEXT = "%s/小时（%s后升级）" -- XP per hour, time to level as a clock

-- RepBarText
L.REPBARTEXT_TITLE = "声望条文字"
L.REPBARTEXT_DESC = "在声望条上始终显示你的声望，包括百分比和关系。其提示信息会加入距下一级关系还需多少，以及"
    .. "登录以来获得的声望。"
L.REPBARTEXT_ALWAYS = "总是显示文字"
L.REPBARTEXT_ALWAYS_DESC = "始终显示文字。关闭后，只在鼠标指向声望条时显示。"
L.REPBARTEXT_PERCENT = "显示百分比"
L.REPBARTEXT_PERCENT_DESC = "显示你在当前关系中的进度。"
L.REPBARTEXT_STANDING = "显示关系"
L.REPBARTEXT_STANDING_DESC = "在阵营名称后显示你的关系，例如友善。"
L.REPBARTEXT_RATE = "显示每小时声望"
L.REPBARTEXT_RATE_DESC = "显示登录以来的每小时声望，以及按此速度达到下一级关系所需的时间。"
L.REPBARTEXT_TOOLTIP = "提示信息"
L.REPBARTEXT_TOOLTIP_DESC = "为声望条加上提示信息，显示你的关系、距下一级关系还需的声望，以及登录以来获得的声望和速度。"
L.REPBARTEXT_AUTO_WATCH = "追踪获得声望的阵营"
L.REPBARTEXT_AUTO_WATCH_DESC = "你获得某个阵营的声望时，让声望条改为显示该阵营。声望窗口中位于已折叠标题下的阵营不会被发现。"
L.REPBARTEXT_NAME_STANDING = "%s（%s）" -- the faction, your standing
L.REPBARTEXT_REP = "%s：%s / %s" -- the faction (and standing), reputation into it, what it needs
L.REPBARTEXT_WITH_PERCENT = "%s（%d%%）" -- the reputation text, its percent
L.REPBARTEXT_AMOUNT = "%s（%d%%）" -- an amount of reputation, as a percent of the standing
L.REPBARTEXT_RATE_TEXT = "%s/小时（%s后达到%s）" -- reputation per hour, time as a clock, the next standing
L.REPBARTEXT_TIP_STANDING = "关系："
L.REPBARTEXT_TIP_LEFT = "距离%s：" -- the next standing
L.REPBARTEXT_TIP_SESSION = "本次登录："
L.REPBARTEXT_TIP_RATE = "每小时声望："
L.REPBARTEXT_TIP_TIME = "达到%s所需时间：" -- the next standing
