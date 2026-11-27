local _, ns = ...
local L = ns.NewLocale("zhCN")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "复制聊天"
L.CHATCOPY_DESC = "在聊天窗口旁加入一个按钮，把聊天内容打开为可以选择和复制的文本。"
L.CHATCOPY_TOOLTIP = "复制聊天"
L.CHATCOPY_TOOLTIP_DESC = "把聊天内容打开为可以选择和复制的文本。"
L.CHATCOPY_STAMPS = "点击时间戳"
L.CHATCOPY_STAMPS_DESC = "点击聊天行的时间戳即可复制该行。需要开启游戏的聊天时间戳。"
L.CHATCOPY_STAMPS_PROMPT = "按Ctrl+C复制这一行聊天。"
L.CHATCOPY_BUTTON_HIDDEN = "聊天按钮已被隐藏，因此它的按钮无法显示。"
L.CHATCOPY_BUTTON_HIDDEN_DESC = "聊天窗口旁暴雪的按钮已被隐藏，很可能是其他聊天插件所为，而“复制聊天”的按钮与它们在"
    .. "一起。“点击时间戳”仍然有效。"
L.CHATCOPY_HIDDEN = "（已被游戏隐藏）"
L.CHATCOPY_EMPTY = "（还没有聊天内容）"
L.CHATCOPY_SELECT_ALL = "全选" -- [game: MENU_EDIT_SELECT_ALL]
L.CHATCOPY_SELECT_HINT = "按Ctrl+C复制。"

-- ChatSounds
L.CHATSOUNDS_TITLE = "聊天声音"
L.CHATSOUNDS_DESC = "有人在公会、官员、小队或团队聊天中发言时播放声音。每种聊天都有自己的复选框和声音，你自己的"
    .. "消息不会播放声音。"
L.CHATSOUNDS_NOTICE = "悄悄话已经会播放游戏自己的声音。"
L.CHATSOUNDS_NOTICE_DESC = "游戏本身就会为悄悄话播放声音，因此这里没有悄悄话的选项。"
L.CHATSOUNDS_GUILD = "公会"
L.CHATSOUNDS_GUILD_DESC = "有人在公会聊天中发言时播放声音。"
L.CHATSOUNDS_OFFICER = "官员"
L.CHATSOUNDS_OFFICER_DESC = "有人在官员聊天中发言时播放声音。"
L.CHATSOUNDS_PARTY = "小队"
L.CHATSOUNDS_PARTY_DESC = "有人在小队聊天中发言时播放声音。"
L.CHATSOUNDS_RAID = "团队"
L.CHATSOUNDS_RAID_DESC = "有人在团队聊天中发言时播放声音。团队通知已经会播放游戏自己的声音。"
L.CHATSOUNDS_SOUND_DESC = "播放的声音。选择一个声音时会播放它。在一次声音后两秒内出现的消息不会播放声音。"

-- ChatLevels
L.CHATLEVELS_TITLE = "聊天等级"
L.CHATLEVELS_DESC = "在聊天中每个玩家的名字前显示其等级，按同等级任务的颜色着色。Forever++会记住与你组队的"
    .. "玩家、你的公会和好友、/who的结果，以及你选为目标或在附近看到的玩家的等级。"
L.CHATLEVELS_TEST = "测试聊天"
L.CHATLEVELS_TEST_BUTTON = "显示"
L.CHATLEVELS_TEST_DESC = "在你的第一个聊天窗口中加入几行虚构玩家的虚构交易频道消息，带有他们的等级和职业颜色。"
    .. "其他人看不到。"
L.CHATLEVELS_TEST_LINE = "[2. 交易] %s：%s" -- after a short trade channel, the name link and the line
L.CHATLEVELS_TEST_1 = "血色修道院缺治疗，来了就走"
L.CHATLEVELS_TEST_2 = "收魔纹布，价格从优"
L.CHATLEVELS_TEST_3 = "有人知道迪菲亚在哪儿吗？"
L.CHATLEVELS_TEST_4 = "出售重皮，20组，密我"

-- ShortChannelNames
L.SHORTCHANNELNAMES_TITLE = "简短频道名称"
L.SHORTCHANNELNAMES_DESC = "把聊天频道显示为[1]、[综]或[1. 综]，而不是[1. 综合]。"
L.SHORTCHANNELNAMES_STYLE = "样式"
L.SHORTCHANNELNAMES_STYLE_DESC = "频道的显示方式：编号、第一个字、首字母缩写（例如LookingForGroup为LFG）、去掉区域的"
    .. "名称，或编号加上其中之一。"
L.SHORTCHANNELNAMES_NUMBER = "编号：[1]"
L.SHORTCHANNELNAMES_LETTER = "首字：[综]"
L.SHORTCHANNELNAMES_INITIALS = "缩写：[LFG]"
L.SHORTCHANNELNAMES_NAME = "名称：[综合]"
L.SHORTCHANNELNAMES_BOTH = "编号和首字：[1. 综]"
L.SHORTCHANNELNAMES_NUMBER_INITIALS = "编号和缩写：[1. LFG]"
L.SHORTCHANNELNAMES_NUMBER_NAME = "编号和名称：[1. 综合]"
L.SHORTCHANNELNAMES_CHAT_TYPES = "公会、小队和团队"
L.SHORTCHANNELNAMES_CHAT_TYPES_DESC = "也把[公会]、[官员]、[小队]、[团队]、[团队通知]和[副本]缩写为[公]、[官]、[队]、"
    .. "[团]、[通]和[副]，它们的领袖缩写为[队长]、[团长]和[副长]，小队向导缩写为[向导]。"
L.SHORTCHANNELNAMES_GUILD = "公"
L.SHORTCHANNELNAMES_OFFICER = "官"
L.SHORTCHANNELNAMES_PARTY = "队"
L.SHORTCHANNELNAMES_PARTY_LEADER = "队长"
L.SHORTCHANNELNAMES_PARTY_GUIDE = "向导"
L.SHORTCHANNELNAMES_RAID = "团"
L.SHORTCHANNELNAMES_RAID_LEADER = "团长"
L.SHORTCHANNELNAMES_RAID_WARNING = "通"
L.SHORTCHANNELNAMES_INSTANCE = "副"
L.SHORTCHANNELNAMES_INSTANCE_LEADER = "副长"

-- QuestLinks
L.QUESTLINKS_TITLE = "任务链接"
L.QUESTLINKS_DESC = "把使用Questie的玩家在聊天中链接的任务（例如[[34] 严峻的任务 (304)]）变成可点击查看的任务链接，"
    .. "就像他们是从任务日志中链接的一样。"

-- ChatHistory
L.CHATHISTORY_TITLE = "聊天记录"
L.CHATHISTORY_DESC = "登出或重新加载时保留聊天窗口最近的消息，登录时重新显示。悄悄话不会保留。"
L.CHATHISTORY_LINES = "保存行数"
L.CHATHISTORY_LINES_DESC = "每个聊天窗口保留多少行最近的消息。"
L.CHATHISTORY_DIVIDER = "-- 之前的聊天 --"
L.CHATHISTORY_DIVIDER_OPTION = "之前聊天分隔线"
L.CHATHISTORY_DIVIDER_DESC = "在恢复的聊天和新聊天之间显示一条灰色分隔线。"

-- ChatArrowKeys
L.CHATARROWKEYS_TITLE = "聊天方向键"
L.CHATARROWKEYS_DESC = "在聊天中输入时，无需按住Alt，上下键可调出你之前发送的内容，左右键可在文字间移动。聊天框"
    .. "打开时，方向键不会移动你的角色。"

-- SocialButton
L.SOCIALBUTTON_TITLE = "社交按钮"
L.SOCIALBUTTON_DESC = "把社交（快速加入）按钮移到下方，与聊天窗口的其他按钮放在一起。"
L.SOCIALBUTTON_MENU = "社交"
-- The column of chat buttons (Lib/Chat.lua), for every module with a button in it.
L.CHAT_BUTTON_FOLDED = "聊天窗口太矮，放不下它的按钮，因此它被放进了聊天菜单。"
L.CHAT_BUTTON_FOLDED_DESC = "该按钮在聊天窗口旁的对话气泡按钮上方放不下，因此改为列在那个按钮菜单的底部。把聊天"
    .. "窗口调高即可恢复。"
L.CHAT_BUTTON_EVERY_TAB = "每个标签都显示按钮"
L.CHAT_BUTTON_EVERY_TAB_DESC = "无论当前是哪个聊天标签，都让按钮留在聊天窗口旁。游戏自带的聊天按钮只在第一个标签显示。"

-- ChatFont
L.CHATFONT_TITLE = "聊天字体"
L.CHATFONT_DESC = "用游戏的另一种字体显示聊天窗口。字号保持你的设置，关闭后恢复暴雪的字体。"
L.CHATFONT_FONT = "字体"
L.CHATFONT_FONT_DESC = "聊天窗口使用的字体。"
L.CHATFONT_INPUT = "聊天输入框"
L.CHATFONT_INPUT_DESC = "你在聊天框中输入的文字也使用该字体。字号保持不变。"

-- ChatBorder
L.CHATBORDER_TITLE = "聊天边框"
L.CHATBORDER_DESC = "用游戏自己的框体美术为每个聊天窗口绘制边框。与聊天窗口自带的淡淡边框不同，无论窗口的背景"
    .. "如何设置，它都会显示。关闭后边框消失。"
L.CHATBORDER_STYLE = "边框"
L.CHATBORDER_STYLE_DESC = "聊天窗口周围的边框，使用暴雪自己的美术。"
L.CHATBORDER_STYLE_THIN = "纤细" -- the tooltip border
L.CHATBORDER_STYLE_STONE = "石质" -- the dialog border
L.CHATBORDER_STYLE_GOLD = "金色" -- the gold dialog border
L.CHATBORDER_COLOR = "颜色"
L.CHATBORDER_COLOR_DESC = "边框的颜色。“默认”保持游戏绘制的原样。"
L.CHATBORDER_COLOR_DEFAULT = "默认"
L.CHATBORDER_COLOR_CLASS = "职业颜色"
L.CHATBORDER_COLOR_GOLD = "金色"
L.CHATBORDER_COLOR_GRAY = "灰色"
L.CHATBORDER_COLOR_BLACK = "黑色"
L.CHATBORDER_COLOR_BLUE = "蓝色"
L.CHATBORDER_COLOR_GREEN = "绿色"
L.CHATBORDER_COLOR_RED = "红色"
L.CHATBORDER_OPACITY = "不透明度"
L.CHATBORDER_OPACITY_DESC = "边框的不透明程度。"
L.CHATBORDER_FADE = "随聊天淡化"
L.CHATBORDER_FADE_DESC = "像游戏淡化窗口标签那样，鼠标离开聊天窗口时淡化边框，鼠标回到聊天上时恢复。"
L.CHATBORDER_SECTION_EDITBOX = "输入框"
L.CHATBORDER_EDITBOX = "包括输入框"
L.CHATBORDER_EDITBOX_DESC = "用同样的边框绘制你输入聊天的框，与聊天窗口的边框相连，代替游戏自己的输入框。"
L.CHATBORDER_EDITBOX_CHANNEL = "输入时显示聊天颜色"
L.CHATBORDER_EDITBOX_CHANNEL_DESC = "输入时，按你正在使用的聊天类型为输入框边框着色，例如公会为绿色、悄悄话为粉色，"
    .. "就像游戏点亮自己的输入框那样。"
L.CHATBORDER_FADE_OPACITY = "淡化后不透明度"
L.CHATBORDER_FADE_OPACITY_DESC = "鼠标离开聊天窗口时边框保留的程度。游戏会保留前方标签的40%；设为0%时，鼠标指向聊天"
    .. "之前都看不到边框。"

-- PersistentChat
L.PERSISTENTCHAT_TITLE = "聊天保持显示" -- Persistent Chat up to 1.4.0
L.PERSISTENTCHAT_DESC = "让聊天文字一直留在屏幕上，而不是过一段时间后淡出。关闭后恢复暴雪的淡出。"

-- HideCombatLogTab
L.HIDECOMBATLOGTAB_TITLE = "隐藏战斗记录标签"
L.HIDECOMBATLOGTAB_DESC = "战斗记录停靠在聊天窗口中时，去掉它的标签。战斗记录本身仍然正常工作。"

-- MovableCombatLogTab
L.MOVABLECOMBATLOGTAB_TITLE = "可移动战斗记录标签"
L.MOVABLECOMBATLOGTAB_DESC = "让战斗记录的标签可以拖到聊天标签中的任意位置，甚至在你创建的标签之后，而不是固定在"
    .. "“综合”之后。"

-- HideChatButtons
L.HIDECHATBUTTONS_TITLE = "隐藏聊天按钮"
L.HIDECHATBUTTONS_DESC = "隐藏聊天窗口旁的按钮，直到鼠标指向聊天，并随其标签淡入淡出。"

-- HideChatTabs
L.HIDECHATTABS_TITLE = "隐藏聊天标签"
L.HIDECHATTABS_DESC = "隐藏聊天窗口的标签，直到鼠标指向聊天，并像游戏调暗它们那样淡入淡出。有新消息的标签仍会"
    .. "闪烁，隐藏的标签仍可点击。"

-- EditBoxOnTop
L.EDITBOXONTOP_TITLE = "输入框置顶"
L.EDITBOXONTOP_DESC = "把你输入聊天的框放在聊天窗口的标签上方，而不是窗口下方。关闭后恢复原位。"

-- WhisperWindow
L.WHISPERWINDOW_TITLE = "悄悄话窗口"
L.WHISPERWINDOW_DESC = "把悄悄话放在单独的窗口中，每人一个对话，并带有回复框。对话会为每个角色保存。"
L.WHISPERWINDOW_WINDOW_TITLE = "悄悄话"
L.WHISPERWINDOW_SECTION_WINDOW = "窗口"
L.WHISPERWINDOW_SECTION_OPACITY = "不透明度"
L.WHISPERWINDOW_OPEN = "收到悄悄话时打开"
L.WHISPERWINDOW_OPEN_DESC = "收到悄悄话，或你从聊天中发送悄悄话时打开窗口。战斗中会等到战斗结束。"
L.WHISPERWINDOW_HIDE = "在聊天中隐藏悄悄话"
L.WHISPERWINDOW_HIDE_DESC = "悄悄话窗口收到悄悄话后，不再在聊天窗口中显示它们以及离开和忙碌的自动回复。游戏隐藏了"
    .. "文字的悄悄话仍会在聊天中显示。"
L.WHISPERWINDOW_BUTTON = "聊天按钮"
L.WHISPERWINDOW_BUTTON_DESC = "在聊天窗口旁加入一个按钮，用来打开悄悄话窗口并显示未读悄悄话的数量。聊天窗口太矮时，"
    .. "它会放在对话气泡按钮的菜单中，由对话气泡显示悄悄话数量。"
L.WHISPERWINDOW_BUTTON_HIDDEN = "聊天按钮已被隐藏，因此“聊天按钮”无法显示。"
L.WHISPERWINDOW_BUTTON_HIDDEN_DESC = "聊天窗口旁暴雪的按钮已被隐藏，很可能是其他聊天插件所为，而“聊天按钮”与它们在一起。"
    .. "可以用/fpp whispers或下面的“显示”打开窗口。"
L.WHISPERWINDOW_ALPHA = "不透明度"
L.WHISPERWINDOW_ALPHA_DESC = "你静止不动时，以及鼠标指向窗口或你在其中输入时，窗口的不透明程度。"
L.WHISPERWINDOW_MOVING = "移动时"
L.WHISPERWINDOW_MOVING_DESC = "非战斗状态下你移动时窗口的不透明程度。"
L.WHISPERWINDOW_COMBAT = "战斗中"
L.WHISPERWINDOW_COMBAT_DESC = "战斗中窗口的不透明程度。"
L.WHISPERWINDOW_SHOW = "悄悄话"
L.WHISPERWINDOW_SHOW_BUTTON = "显示"
L.WHISPERWINDOW_SHOW_DESC = "打开悄悄话窗口。"
L.WHISPERWINDOW_CLEAR = "清除"
L.WHISPERWINDOW_CLEAR_NAME = "已保存的对话"
L.WHISPERWINDOW_CLEAR_DESC = "忘记此角色的所有对话。"
L.WHISPERWINDOW_CLEAR_CONFIRM = "忘记此角色的所有对话？"
L.WHISPERWINDOW_COMMAND = "打开悄悄话窗口，可指定名字打开与其的对话"
L.WHISPERWINDOW_COMMAND_USAGE = "[name]"
L.WHISPERWINDOW_TOOLTIP = "悄悄话"
L.WHISPERWINDOW_TOOLTIP_DESC = "打开你的对话。"
L.WHISPERWINDOW_SUMMARY = { "%d个对话" } -- how many
L.WHISPERWINDOW_SUMMARY_UNREAD = "%s，%d条未读" -- "3 conversations", unread whispers
L.WHISPERWINDOW_PREVIEW_YOU = "你：%s" -- your last whisper, in the list
L.WHISPERWINDOW_REPLY_HINT = "对%s说悄悄话" -- name
L.WHISPERWINDOW_UNREAD = "%d条新消息" -- unread whispers in a conversation
L.WHISPERWINDOW_NONE = "未选择对话。"
L.WHISPERWINDOW_YOU = "你"
L.WHISPERWINDOW_LINE = "%s %s：%s" -- time, who, the whisper
L.WHISPERWINDOW_INFO_LINE = "%s %s" -- time, what happened
L.WHISPERWINDOW_FULL_NAME = "%s %s" -- first name, surname
L.WHISPERWINDOW_LEVEL = "等级%d"
L.WHISPERWINDOW_PLAYING = "正在玩%s" -- a Battle.net friend's character
L.WHISPERWINDOW_GUILD_NAME = "<%s>" -- their guild, as Blizzard's tooltips show it
L.WHISPERWINDOW_FRIEND = "好友"
L.WHISPERWINDOW_GUILD = "公会"
L.WHISPERWINDOW_OFFLINE = "离线"
L.WHISPERWINDOW_UNKNOWN = "好友、公会成员和附近的玩家会显示等级和所在区域。"
L.WHISPERWINDOW_AFK = "离开：%s" -- the away message
L.WHISPERWINDOW_DND = "忙碌：%s" -- the busy message
L.WHISPERWINDOW_INVITE = "邀请"
L.WHISPERWINDOW_MENU_COMBAT = "战斗结束后显示更多" -- a gray line in the short menu a name gets in combat
L.WHISPERWINDOW_REMOVE = "移除对话"
L.WHISPERWINDOW_REMOVE_CONFIRM = "忘记你与%s的对话？" -- name
L.WHISPERWINDOW_NEW = "新悄悄话"
L.WHISPERWINDOW_NEW_PROMPT = "对谁说悄悄话？"
L.WHISPERWINDOW_LOCKED = "此处目前限制聊天。"
L.WHISPERWINDOW_TEST = "测试对话"
L.WHISPERWINDOW_TEST_BUTTON = "发送"
L.WHISPERWINDOW_TEST_DESC = "在悄悄话窗口中加入一段虚构的对话，与一位暗夜精灵德鲁伊来回几句悄悄话，用来查看外观。它不会"
    .. "打开窗口，因此这些悄悄话在聊天按钮上算作未读。对它的回复不会发给任何人。"
L.WHISPERWINDOW_TEST_NAME = "测试·月语"
L.WHISPERWINDOW_TEST_RACE = "暗夜精灵"
L.WHISPERWINDOW_TEST_CLASS = "德鲁伊"
L.WHISPERWINDOW_BNET_OFFLINE = "这位战网好友不在线。"
