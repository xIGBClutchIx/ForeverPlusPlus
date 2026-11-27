local _, ns = ...
local L = ns.NewLocale("zhTW")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "聊天複製"
L.CHATCOPY_DESC = "在聊天視窗旁加入一個按鈕，將聊天內容開啟為可選取和複製的文字。"
L.CHATCOPY_TOOLTIP = "複製聊天"
L.CHATCOPY_TOOLTIP_DESC = "將聊天內容開啟為可選取和複製的文字。"
L.CHATCOPY_STAMPS = "點擊時間標記"
L.CHATCOPY_STAMPS_DESC = "點擊聊天訊息的時間標記即可複製該行。需要開啟遊戲的聊天時間標記。"
L.CHATCOPY_STAMPS_PROMPT = "按Ctrl+C複製這行聊天訊息。"
L.CHATCOPY_BUTTON_HIDDEN = "聊天按鈕已隱藏，因此它的按鈕無法顯示。"
L.CHATCOPY_BUTTON_HIDDEN_DESC = "暴雪在聊天視窗旁的按鈕已被隱藏，很可能是其他聊天插件所為，"
    .. "而「聊天複製」的按鈕和它們放在一起。「點擊時間標記」仍可使用。"
L.CHATCOPY_HIDDEN = "（已被遊戲隱藏）"
L.CHATCOPY_EMPTY = "（尚無聊天內容）"
L.CHATCOPY_SELECT_ALL = "全選"
L.CHATCOPY_SELECT_HINT = "按Ctrl+C複製。"

-- ChatSounds
L.CHATSOUNDS_TITLE = "聊天音效"
L.CHATSOUNDS_DESC = "有人在公會、幹部、隊伍或團隊頻道發言時播放音效。每種頻道都有自己的核取方塊和音效，"
    .. "你自己的訊息不會播放音效。"
L.CHATSOUNDS_NOTICE = "悄悄話已經會播放遊戲本身的音效。"
L.CHATSOUNDS_NOTICE_DESC = "遊戲本身就會為悄悄話播放音效，因此這裡沒有悄悄話的選項。"
L.CHATSOUNDS_GUILD = "公會"
L.CHATSOUNDS_GUILD_DESC = "有人在公會頻道發言時播放音效。"
L.CHATSOUNDS_OFFICER = "幹部"
L.CHATSOUNDS_OFFICER_DESC = "有人在幹部頻道發言時播放音效。"
L.CHATSOUNDS_PARTY = "隊伍"
L.CHATSOUNDS_PARTY_DESC = "有人在隊伍頻道發言時播放音效。"
L.CHATSOUNDS_RAID = "團隊"
L.CHATSOUNDS_RAID_DESC = "有人在團隊頻道發言時播放音效。團隊警告已經會播放遊戲本身的音效。"
L.CHATSOUNDS_SOUND_DESC = "播放的音效。選擇音效時會播放一次。在音效後兩秒內出現的訊息不會再播放。"

-- ChatLevels
L.CHATLEVELS_TITLE = "聊天等級"
L.CHATLEVELS_DESC = "在聊天中每位玩家的名字前顯示其等級，並像該等級的任務一樣著色。"
    .. "Forever++會記住與你組隊的玩家、你的公會和好友、/who查詢結果，以及你選取或在附近看到的玩家的等級。"
L.CHATLEVELS_TEST = "測試聊天"
L.CHATLEVELS_TEST_BUTTON = "顯示"
L.CHATLEVELS_TEST_DESC = "在你的第一個聊天視窗中加入幾行虛構玩家的虛構交易頻道訊息，"
    .. "附上他們的等級和職業顏色。其他人看不到。"
L.CHATLEVELS_TEST_LINE = "[2. 交] %s：%s" -- after a short trade channel, the name link and the line
L.CHATLEVELS_TEST_1 = "血色修道院缺治療，滿了就出發"
L.CHATLEVELS_TEST_2 = "收魔紋布，價格好談"
L.CHATLEVELS_TEST_3 = "有人知道迪菲亞在哪裡嗎？"
L.CHATLEVELS_TEST_4 = "賣厚皮，20組，密我"

-- ShortChannelNames
L.SHORTCHANNELNAMES_TITLE = "簡短頻道名稱"
L.SHORTCHANNELNAMES_DESC = "將聊天頻道顯示為[1]、[綜]或[1. 綜]，而不是[1. 綜合]。"
L.SHORTCHANNELNAMES_STYLE = "風格"
L.SHORTCHANNELNAMES_STYLE_DESC = "頻道的顯示方式：編號、第一個字、縮寫（LookingForGroup縮寫為LFG）、"
    .. "不含區域的名稱，或編號加上其中一種。"
L.SHORTCHANNELNAMES_NUMBER = "編號：[1]"
L.SHORTCHANNELNAMES_LETTER = "首字：[綜]"
L.SHORTCHANNELNAMES_INITIALS = "縮寫：[LFG]"
L.SHORTCHANNELNAMES_NAME = "名稱：[綜合]"
L.SHORTCHANNELNAMES_BOTH = "編號和首字：[1. 綜]"
L.SHORTCHANNELNAMES_NUMBER_INITIALS = "編號和縮寫：[1. LFG]"
L.SHORTCHANNELNAMES_NUMBER_NAME = "編號和名稱：[1. 綜合]"
L.SHORTCHANNELNAMES_CHAT_TYPES = "公會、隊伍和團隊"
L.SHORTCHANNELNAMES_CHAT_TYPES_DESC = "也將[公會]、[幹部]、[隊伍]、[團隊]、[團隊警告]和[副本]縮短為"
    .. "[公]、[官]、[隊]、[團]、[警]和[副]，隊長、團長和副本隊長縮短為[隊長]、[團長]和[副長]，"
    .. "隊伍嚮導縮短為[嚮導]。"
L.SHORTCHANNELNAMES_GUILD = "公"
L.SHORTCHANNELNAMES_OFFICER = "官"
L.SHORTCHANNELNAMES_PARTY = "隊"
L.SHORTCHANNELNAMES_PARTY_LEADER = "隊長"
L.SHORTCHANNELNAMES_PARTY_GUIDE = "嚮導"
L.SHORTCHANNELNAMES_RAID = "團"
L.SHORTCHANNELNAMES_RAID_LEADER = "團長"
L.SHORTCHANNELNAMES_RAID_WARNING = "警"
L.SHORTCHANNELNAMES_INSTANCE = "副"
L.SHORTCHANNELNAMES_INSTANCE_LEADER = "副長"

-- QuestLinks
L.QUESTLINKS_TITLE = "任務連結"
L.QUESTLINKS_DESC = "將使用Questie的玩家在聊天中連結的任務（例如[[34] A Grim Task (304)]），"
    .. "變成可以點擊查看任務的任務連結，就像他們從任務日誌連結的一樣。"

-- ChatHistory
L.CHATHISTORY_TITLE = "聊天記錄"
L.CHATHISTORY_DESC = "登出或重新載入時保留聊天視窗最近的訊息，並在登入時重新顯示。悄悄話不會保留。"
L.CHATHISTORY_LINES = "保留行數"
L.CHATHISTORY_LINES_DESC = "每個聊天視窗要保留幾行最近的訊息。"
L.CHATHISTORY_DIVIDER = "-- 先前的聊天 --"
L.CHATHISTORY_DIVIDER_OPTION = "先前聊天分隔線"
L.CHATHISTORY_DIVIDER_DESC = "在恢復的聊天和新的聊天之間顯示一條灰色分隔線。"

-- ChatArrowKeys
L.CHATARROWKEYS_TITLE = "聊天方向鍵"
L.CHATARROWKEYS_DESC = "在聊天中輸入時，不必按住Alt，上下鍵就能叫回你之前送出的內容，左右鍵可在文字中移動。"
    .. "聊天框開啟時，方向鍵不會移動你的角色。"

-- SocialButton
L.SOCIALBUTTON_TITLE = "社交按鈕"
L.SOCIALBUTTON_DESC = "將社交（快速加入）按鈕移到聊天視窗其他按鈕的旁邊。"
L.SOCIALBUTTON_MENU = "社交"

-- The column of chat buttons (Lib/Chat.lua), for every module with a button in it.
L.CHAT_BUTTON_FOLDED = "聊天視窗太矮，放不下它的按鈕，因此它在聊天選單中。"
L.CHAT_BUTTON_FOLDED_DESC = "按鈕放不進聊天視窗旁的對話泡泡按鈕上方，因此改列在該按鈕選單的最下方。"
    .. "將聊天視窗拉高即可讓它回來。"

-- ChatButtonsEveryTab
L.CHATBUTTONSEVERYTAB_TITLE = "每個分頁都顯示聊天按鈕"
L.CHATBUTTONSEVERYTAB_DESC = "無論目前是哪個聊天分頁，都讓聊天視窗旁的按鈕留在原處：遊戲內建的聊天選單和頻道按鈕，"
    .. "以及 Forever++ 加入的按鈕。遊戲只在第一個分頁顯示它們。"

-- ChatFont
L.CHATFONT_TITLE = "聊天字型"
L.CHATFONT_DESC = "以遊戲的另一種字型顯示聊天視窗。大小維持你的設定，關閉後會恢復暴雪的字型。"
L.CHATFONT_FONT = "字型"
L.CHATFONT_FONT_DESC = "聊天視窗使用的字型。"
L.CHATFONT_INPUT = "聊天輸入"
L.CHATFONT_INPUT_DESC = "你在聊天框輸入的文字也使用這個字型。大小維持不變。"

-- ChatBorder
L.CHATBORDER_TITLE = "聊天邊框"
L.CHATBORDER_DESC = "以遊戲本身的框架圖案為每個聊天視窗加上邊框。與聊天視窗本身淡淡的邊框不同，"
    .. "無論視窗背景如何設定都會顯示。關閉後即移除。"
L.CHATBORDER_STYLE = "鑲邊"
L.CHATBORDER_STYLE_DESC = "聊天視窗周圍的邊框，使用暴雪本身的圖案。"
L.CHATBORDER_STYLE_THIN = "細" -- the tooltip border
L.CHATBORDER_STYLE_STONE = "石框" -- the dialog border
L.CHATBORDER_STYLE_GOLD = "金框" -- the gold dialog border
L.CHATBORDER_COLOR = "顏色"
L.CHATBORDER_COLOR_DESC = "邊框的顏色。「預設」會維持遊戲原本繪製的圖案。"
L.CHATBORDER_COLOR_DEFAULT = "預設"
L.CHATBORDER_COLOR_CLASS = "職業顏色"
L.CHATBORDER_COLOR_GOLD = "金色"
L.CHATBORDER_COLOR_GRAY = "灰色"
L.CHATBORDER_COLOR_BLACK = "黑色"
L.CHATBORDER_COLOR_BLUE = "藍色"
L.CHATBORDER_COLOR_GREEN = "綠色"
L.CHATBORDER_COLOR_RED = "紅色"
L.CHATBORDER_OPACITY = "透明度"
L.CHATBORDER_OPACITY_DESC = "邊框的不透明程度。"
L.CHATBORDER_FADE = "隨聊天淡化"
L.CHATBORDER_FADE_DESC = "像遊戲淡化視窗分頁一樣，滑鼠離開聊天視窗時淡化邊框，滑鼠回到聊天上時再顯示。"
L.CHATBORDER_SECTION_EDITBOX = "輸入框"
L.CHATBORDER_EDITBOX = "包含輸入框"
L.CHATBORDER_EDITBOX_DESC = "以相同的邊框繪製你輸入聊天的輸入框，與聊天視窗的邊框相連，取代遊戲原本的輸入框。"
L.CHATBORDER_EDITBOX_CHANNEL = "輸入時顯示頻道顏色"
L.CHATBORDER_EDITBOX_CHANNEL_DESC = "輸入時，依你正在輸入的頻道為輸入框邊框著色，例如公會為綠色、悄悄話為粉紅色，"
    .. "就像遊戲點亮它自己的輸入框一樣。"
L.CHATBORDER_FADE_OPACITY = "淡化透明度"
L.CHATBORDER_FADE_OPACITY_DESC = "滑鼠離開聊天視窗時邊框保留多少。遊戲會讓最前面的分頁保留40%，"
    .. "設為0%時，滑鼠指向聊天之前都看不到邊框。"

-- PersistentChat
L.PERSISTENTCHAT_TITLE = "聊天保持可見" -- Persistent Chat up to 1.4.0
L.PERSISTENTCHAT_DESC = "讓聊天文字一直留在畫面上，而不是過一段時間後淡出。關閉後會恢復暴雪的淡出。"

-- HideCombatLogTab
L.HIDECOMBATLOGTAB_TITLE = "隱藏戰鬥記錄分頁"
L.HIDECOMBATLOGTAB_DESC = "當戰鬥記錄停駐在聊天視窗時，移除它的分頁。記錄本身仍會繼續運作。"

-- MovableCombatLogTab
L.MOVABLECOMBATLOGTAB_TITLE = "可移動戰鬥記錄分頁"
L.MOVABLECOMBATLOGTAB_DESC = "讓戰鬥記錄的分頁可以拖曳到聊天分頁中的任何位置，甚至是你建立的分頁之後，"
    .. "而不是固定在「綜合」之後。"

-- ChatTabResize
L.CHATTABRESIZE_TITLE = "拖曳分頁調整聊天大小"
L.CHATTABRESIZE_DESC = "上下拖曳「綜合」聊天分頁，讓主聊天視窗變高或變矮。"
L.CHATTABRESIZE_NOTICE = "新的高度只維持到重新載入"
L.CHATTABRESIZE_NOTICE_DESC = "編輯模式保存著聊天視窗的高度，在/reload或更換版面配置後會恢復它。要保留高度，"
    .. "請在編輯模式中設定。"

-- HideChatButtons
L.HIDECHATBUTTONS_TITLE = "隱藏聊天按鈕"
L.HIDECHATBUTTONS_DESC = "隱藏聊天視窗旁的按鈕，直到滑鼠指向聊天，並隨著分頁淡入淡出。"

-- HideChatTabs
L.HIDECHATTABS_TITLE = "隱藏聊天分頁"
L.HIDECHATTABS_DESC = "隱藏聊天視窗的分頁，直到滑鼠指向聊天，並像遊戲淡化分頁一樣淡入淡出。"
    .. "有新訊息的分頁仍會閃爍，隱藏的分頁仍可點擊。"

-- EditBoxOnTop
L.EDITBOXONTOP_TITLE = "輸入框置頂"
L.EDITBOXONTOP_DESC = "將輸入聊天的輸入框放在聊天視窗分頁的上方，而不是視窗下方。關閉後會恢復原位。"

-- UndimmedEditBox
L.UNDIMMEDEDITBOX_TITLE = "輸入框不變暗"
L.UNDIMMEDEDITBOX_DESC = "未輸入時，讓聊天輸入框保持完整顯示，而不是變暗。"
L.UNDIMMEDEDITBOX_NOT_IM = "需要將「聊天方式」設為「以即時通訊方式」"
L.UNDIMMEDEDITBOX_NOT_IM_DESC = "使用其他聊天方式時，遊戲會在你輸入前隱藏輸入框，因此無需保持明亮。"

-- WhisperWindow
L.WHISPERWINDOW_TITLE = "悄悄話視窗"
L.WHISPERWINDOW_DESC = "將悄悄話放在專屬的視窗中，每個人一段對話，並附有回覆用的輸入框。對話會為每個角色儲存。"
L.WHISPERWINDOW_WINDOW_TITLE = "悄悄話"
L.WHISPERWINDOW_SECTION_WINDOW = "視窗"
L.WHISPERWINDOW_SECTION_OPACITY = "透明度"
L.WHISPERWINDOW_OPEN = "收到悄悄話時開啟"
L.WHISPERWINDOW_OPEN_DESC = "收到悄悄話，或你從聊天中送出悄悄話時，開啟視窗。戰鬥中會等到戰鬥結束。"
L.WHISPERWINDOW_HIDE = "在聊天中隱藏悄悄話"
L.WHISPERWINDOW_HIDE_DESC = "悄悄話視窗收到悄悄話後，不在聊天視窗中顯示悄悄話，以及暫離和忙碌的自動回覆。"
    .. "遊戲隱藏文字的悄悄話仍會顯示在聊天中。"
L.WHISPERWINDOW_BUTTON = "聊天按鈕"
L.WHISPERWINDOW_BUTTON_DESC = "在聊天視窗旁加入一個按鈕，可開啟悄悄話視窗並計算未讀的悄悄話。"
    .. "聊天視窗太矮放不下時，它會在對話泡泡按鈕的選單中，改由對話泡泡計算悄悄話。"
L.WHISPERWINDOW_BUTTON_HIDDEN = "聊天按鈕已隱藏，因此「聊天按鈕」無法顯示。"
L.WHISPERWINDOW_BUTTON_HIDDEN_DESC = "暴雪在聊天視窗旁的按鈕已被隱藏，很可能是其他聊天插件所為，"
    .. "而「聊天按鈕」和它們放在一起。請用/fpp whispers或下方的「顯示」開啟視窗。"
L.WHISPERWINDOW_ALPHA = "透明度"
L.WHISPERWINDOW_ALPHA_DESC = "你站著不動、滑鼠指向視窗或在其中輸入時，視窗的不透明程度。"
L.WHISPERWINDOW_MOVING = "移動時"
L.WHISPERWINDOW_MOVING_DESC = "非戰鬥狀態下移動時，視窗的不透明程度。"
L.WHISPERWINDOW_COMBAT = "戰鬥中"
L.WHISPERWINDOW_COMBAT_DESC = "戰鬥中視窗的不透明程度。"
L.WHISPERWINDOW_SHOW = "悄悄話"
L.WHISPERWINDOW_SHOW_BUTTON = "顯示"
L.WHISPERWINDOW_SHOW_DESC = "開啟悄悄話視窗。"
L.WHISPERWINDOW_CLEAR = "清除"
L.WHISPERWINDOW_CLEAR_NAME = "已儲存的對話"
L.WHISPERWINDOW_CLEAR_DESC = "忘記此角色的所有對話。"
L.WHISPERWINDOW_CLEAR_CONFIRM = "要忘記此角色的所有對話嗎？"
L.WHISPERWINDOW_COMMAND = "開啟悄悄話視窗，可指定名字開啟與該玩家的對話"
L.WHISPERWINDOW_COMMAND_USAGE = "[name]"
L.WHISPERWINDOW_TOOLTIP = "悄悄話"
L.WHISPERWINDOW_TOOLTIP_DESC = "開啟你的對話。"
L.WHISPERWINDOW_SUMMARY = { "%d段對話" } -- how many
L.WHISPERWINDOW_SUMMARY_UNREAD = "%s，%d則未讀" -- "3 conversations", unread whispers
L.WHISPERWINDOW_PREVIEW_YOU = "你：%s" -- your last whisper, in the list
L.WHISPERWINDOW_REPLY_HINT = "對%s說悄悄話" -- name
L.WHISPERWINDOW_UNREAD = "%d則新訊息" -- unread whispers in a conversation
L.WHISPERWINDOW_NONE = "未選擇對話。"
L.WHISPERWINDOW_YOU = "你"
L.WHISPERWINDOW_LINE = "%s %s：%s" -- time, who, the whisper
L.WHISPERWINDOW_INFO_LINE = "%s %s" -- time, what happened
L.WHISPERWINDOW_FULL_NAME = "%s %s" -- first name, surname
L.WHISPERWINDOW_LEVEL = "等級%d"
L.WHISPERWINDOW_PLAYING = "正在玩%s" -- a Battle.net friend's character
L.WHISPERWINDOW_GUILD_NAME = "<%s>" -- their guild, as Blizzard's tooltips show it
L.WHISPERWINDOW_FRIEND = "好友"
L.WHISPERWINDOW_GUILD = "公會"
L.WHISPERWINDOW_OFFLINE = "離線"
L.WHISPERWINDOW_UNKNOWN = "好友、公會成員和附近的玩家會顯示等級和區域。"
L.WHISPERWINDOW_AFK = "暫離：%s" -- the away message
L.WHISPERWINDOW_DND = "忙碌：%s" -- the busy message
L.WHISPERWINDOW_INVITE = "邀請"
L.WHISPERWINDOW_MENU_COMBAT = "戰鬥後顯示更多" -- a gray line in the short menu a name gets in combat
L.WHISPERWINDOW_REMOVE = "移除對話"
L.WHISPERWINDOW_REMOVE_CONFIRM = "要忘記你與%s的對話嗎？" -- name
L.WHISPERWINDOW_NEW = "新悄悄話"
L.WHISPERWINDOW_NEW_PROMPT = "要對誰說悄悄話？"
L.WHISPERWINDOW_LOCKED = "這裡目前限制聊天。"
L.WHISPERWINDOW_TEST = "測試對話"
L.WHISPERWINDOW_TEST_BUTTON = "發送"
L.WHISPERWINDOW_TEST_DESC = "在悄悄話視窗中加入一段虛構的對話，與一位夜精靈德魯伊來回幾則悄悄話，看看外觀如何。"
    .. "它不會開啟視窗，所以這些悄悄話在聊天按鈕上會算作未讀。回覆它不會送到任何地方。"
L.WHISPERWINDOW_TEST_NAME = "月語測試員"
L.WHISPERWINDOW_TEST_RACE = "夜精靈"
L.WHISPERWINDOW_TEST_CLASS = "德魯伊"
L.WHISPERWINDOW_BNET_OFFLINE = "這位Battle.net好友不在線上。"
