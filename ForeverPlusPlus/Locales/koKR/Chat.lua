local _, ns = ...
local L = ns.NewLocale("koKR")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "대화 복사"
L.CHATCOPY_DESC = "대화창 옆에 대화 내용을 선택하고 복사할 수 있는 텍스트로 여는 버튼을 더합니다."
L.CHATCOPY_TOOLTIP = "대화 복사"
L.CHATCOPY_TOOLTIP_DESC = "대화 내용을 선택하고 복사할 수 있는 텍스트로 엽니다."
L.CHATCOPY_STAMPS = "시각 클릭"
L.CHATCOPY_STAMPS_DESC = "대화 줄의 시각을 클릭하면 그 줄을 복사합니다. 게임의 대화 시각 설정이 켜져 있어야 "
    .. "합니다."
L.CHATCOPY_STAMPS_PROMPT = "Ctrl+C를 눌러 이 대화 줄을 복사하십시오."
L.CHATCOPY_BUTTON_HIDDEN = "대화 버튼이 숨겨져 있어 이 버튼을 표시할 수 없습니다."
L.CHATCOPY_BUTTON_HIDDEN_DESC = "대화창 옆의 블리자드 버튼이 숨겨져 있습니다. 아마 다른 대화 애드온 때문이며, '대화 "
    .. "복사' 버튼도 그 버튼들과 함께 있습니다. '시각 클릭'은 그대로 작동합니다."
L.CHATCOPY_HIDDEN = "(게임이 숨김)"
L.CHATCOPY_EMPTY = "(아직 대화 없음)"
L.CHATCOPY_SELECT_ALL = "모두 선택"
L.CHATCOPY_SELECT_HINT = "Ctrl+C를 눌러 복사하십시오."

-- ChatSounds
L.CHATSOUNDS_TITLE = "대화 소리"
L.CHATSOUNDS_DESC = "누군가 길드, 길드관리자, 파티, 공격대 대화에 글을 쓰면 소리를 재생합니다. 대화 종류마다 "
    .. "체크박스와 소리가 따로 있으며, 내가 쓴 메시지에는 소리가 나지 않습니다."
L.CHATSOUNDS_NOTICE = "귓속말에는 이미 게임 자체의 소리가 납니다."
L.CHATSOUNDS_NOTICE_DESC = "게임이 귓속말에 직접 소리를 내므로 여기에는 귓속말 옵션이 없습니다."
L.CHATSOUNDS_GUILD = "길드"
L.CHATSOUNDS_GUILD_DESC = "누군가 길드 대화에 글을 쓰면 소리를 재생합니다."
L.CHATSOUNDS_OFFICER = "길드관리자"
L.CHATSOUNDS_OFFICER_DESC = "누군가 길드관리자 대화에 글을 쓰면 소리를 재생합니다."
L.CHATSOUNDS_PARTY = "파티"
L.CHATSOUNDS_PARTY_DESC = "누군가 파티 대화에 글을 쓰면 소리를 재생합니다."
L.CHATSOUNDS_RAID = "공격대"
L.CHATSOUNDS_RAID_DESC = "누군가 공격대 대화에 글을 쓰면 소리를 재생합니다. 공격대 경보에는 이미 게임 자체의 "
    .. "소리가 납니다."
L.CHATSOUNDS_SOUND_DESC = "재생할 소리입니다. 소리를 고르면 한 번 재생됩니다. 소리가 난 뒤 2초 안에 오는 줄에는 "
    .. "소리가 나지 않습니다."

-- ChatLevels
L.CHATLEVELS_TITLE = "대화 레벨"
L.CHATLEVELS_DESC = "대화에서 각 플레이어의 이름 앞에 레벨을, 그 레벨의 퀘스트처럼 색을 입혀 표시합니다. "
    .. "Forever++는 함께 파티한 플레이어, 길드원과 친구, /who 결과, 대상으로 잡거나 주변에서 본 플레이어의 레벨을 "
    .. "기억합니다."
L.CHATLEVELS_TEST = "대화 시험"
L.CHATLEVELS_TEST_BUTTON = "표시"
L.CHATLEVELS_TEST_DESC = "가상의 플레이어가 쓴 가짜 거래 대화 몇 줄을 레벨과 직업 색상과 함께 첫 번째 대화창에 "
    .. "더합니다. 다른 사람에게는 보이지 않습니다."
L.CHATLEVELS_TEST_LINE = "[2. 거래] %s: %s" -- after a short trade channel, the name link and the line
L.CHATLEVELS_TEST_1 = "붉은십자군 수도원 힐러 구합니다, 구하면 바로 출발"
L.CHATLEVELS_TEST_2 = "마법 옷감 삽니다, 값 잘 쳐 드려요"
L.CHATLEVELS_TEST_3 = "데피아즈 어디 있는지 아는 분?"
L.CHATLEVELS_TEST_4 = "질긴 가죽 20묶음 팝니다, 귓 주세요"

-- ShortChannelNames
L.SHORTCHANNELNAMES_TITLE = "짧은 채널 이름"
L.SHORTCHANNELNAMES_DESC = "대화 채널을 [1. 공개] 대신 [1], [공], [1. 공]처럼 표시합니다."
L.SHORTCHANNELNAMES_STYLE = "양식"
L.SHORTCHANNELNAMES_STYLE_DESC = "채널을 표시하는 방식입니다. 번호, 첫 글자, 머리글자(LookingForGroup이면 LFG), "
    .. "지역 이름을 뺀 이름, 또는 번호와 그중 하나입니다."
L.SHORTCHANNELNAMES_NUMBER = "번호: [1]"
L.SHORTCHANNELNAMES_LETTER = "글자: [공]"
L.SHORTCHANNELNAMES_INITIALS = "머리글자: [LFG]"
L.SHORTCHANNELNAMES_NAME = "이름: [공개]"
L.SHORTCHANNELNAMES_BOTH = "번호와 글자: [1. 공]"
L.SHORTCHANNELNAMES_NUMBER_INITIALS = "번호와 머리글자: [1. LFG]"
L.SHORTCHANNELNAMES_NUMBER_NAME = "번호와 이름: [1. 공개]"
L.SHORTCHANNELNAMES_CHAT_TYPES = "길드, 파티, 공격대"
L.SHORTCHANNELNAMES_CHAT_TYPES_DESC = "[길드], [길드관리자], [파티], [공격대], [공격대 경보], [인스턴스]도 "
    .. "[길], [관], [파], [공대], [경], [인]으로, 그 지휘자의 것은 [파장], [공대장], [인장]으로, 파티 안내자의 것은 "
    .. "[안]으로 줄입니다."
L.SHORTCHANNELNAMES_GUILD = "길"
L.SHORTCHANNELNAMES_OFFICER = "관"
L.SHORTCHANNELNAMES_PARTY = "파"
L.SHORTCHANNELNAMES_PARTY_LEADER = "파장"
L.SHORTCHANNELNAMES_PARTY_GUIDE = "안"
L.SHORTCHANNELNAMES_RAID = "공대"
L.SHORTCHANNELNAMES_RAID_LEADER = "공대장"
L.SHORTCHANNELNAMES_RAID_WARNING = "경"
L.SHORTCHANNELNAMES_INSTANCE = "인"
L.SHORTCHANNELNAMES_INSTANCE_LEADER = "인장"

-- QuestLinks
L.QUESTLINKS_TITLE = "퀘스트 링크"
L.QUESTLINKS_DESC = "Questie를 쓰는 플레이어가 대화에 [[34] 끔찍한 임무 (304)]처럼 링크한 퀘스트를, 퀘스트 목록에서 "
    .. "링크한 것처럼 클릭해서 볼 수 있는 퀘스트 링크로 바꿉니다."

-- ChatHistory
L.CHATHISTORY_TITLE = "대화 기록"
L.CHATHISTORY_DESC = "접속을 종료하거나 UI를 재시작할 때 대화창의 최근 줄을 보관했다가 접속하면 다시 보여 줍니다. "
    .. "귓속말은 보관하지 않습니다."
L.CHATHISTORY_LINES = "저장할 줄 수"
L.CHATHISTORY_LINES_DESC = "대화창마다 보관할 최근 줄의 수입니다."
L.CHATHISTORY_DIVIDER = "-- 이전 대화 --"
L.CHATHISTORY_DIVIDER_OPTION = "이전 대화 구분선"
L.CHATHISTORY_DIVIDER_DESC = "되살린 대화와 새 대화 사이에 회색 줄을 표시합니다."

-- ChatArrowKeys
L.CHATARROWKEYS_TITLE = "대화 방향키"
L.CHATARROWKEYS_DESC = "대화를 입력하는 동안 Alt를 누르지 않아도 위아래 방향키로 전에 보낸 내용을 불러오고, "
    .. "왼쪽과 오른쪽 방향키로 글자 사이를 움직입니다. 대화 입력창이 열려 있는 동안 방향키로 캐릭터가 움직이지 "
    .. "않습니다."

-- SocialButton
L.SOCIALBUTTON_TITLE = "소셜 버튼"
L.SOCIALBUTTON_DESC = "소셜(빠른 참여) 버튼을 대화창의 다른 버튼 옆 아래쪽으로 옮깁니다."
L.SOCIALBUTTON_MENU = "소셜"

-- The column of chat buttons (Lib/Chat.lua), for every module with a button in it.
L.CHAT_BUTTON_FOLDED = "대화창이 너무 낮아 버튼이 들어가지 않으므로 대화 메뉴에 있습니다."
L.CHAT_BUTTON_FOLDED_DESC = "버튼이 대화창 옆 말풍선 버튼 위에 들어가지 않아, 대신 그 버튼 메뉴의 맨 아래에 "
    .. "있습니다. 대화창을 더 높이면 돌아옵니다."

-- ChatFont
L.CHATFONT_TITLE = "대화 글꼴"
L.CHATFONT_DESC = "대화창을 게임의 다른 글꼴로 표시합니다. 크기는 정해 둔 그대로이며, 끄면 블리자드 글꼴로 "
    .. "돌아갑니다."
L.CHATFONT_FONT = "글꼴"
L.CHATFONT_FONT_DESC = "대화창에 쓸 글꼴입니다."
L.CHATFONT_INPUT = "대화 입력"
L.CHATFONT_INPUT_DESC = "대화 입력창에 입력하는 글자에도 이 글꼴을 씁니다. 크기는 그대로입니다."

-- ChatBorder
L.CHATBORDER_TITLE = "대화창 테두리"
L.CHATBORDER_DESC = "게임 자체의 창 그림으로 각 대화창 둘레에 테두리를 그립니다. 대화창 자체의 흐릿한 테두리와 "
    .. "달리 창 배경 설정과 관계없이 보입니다. 끄면 사라집니다."
L.CHATBORDER_STYLE = "외곽선"
L.CHATBORDER_STYLE_DESC = "블리자드 자체 그림으로 된, 대화창 둘레의 테두리입니다."
L.CHATBORDER_STYLE_THIN = "얇음" -- the tooltip border
L.CHATBORDER_STYLE_STONE = "돌" -- the dialog border
L.CHATBORDER_STYLE_GOLD = "금색" -- the gold dialog border
L.CHATBORDER_COLOR = "색상"
L.CHATBORDER_COLOR_DESC = "테두리의 색상입니다. '기본'은 게임이 그리는 그림 그대로 둡니다."
L.CHATBORDER_COLOR_DEFAULT = "기본"
L.CHATBORDER_COLOR_CLASS = "직업 색상"
L.CHATBORDER_COLOR_GOLD = "금색"
L.CHATBORDER_COLOR_GRAY = "회색"
L.CHATBORDER_COLOR_BLACK = "검은색"
L.CHATBORDER_COLOR_BLUE = "푸른색"
L.CHATBORDER_COLOR_GREEN = "녹색"
L.CHATBORDER_COLOR_RED = "붉은색"
L.CHATBORDER_OPACITY = "투명도"
L.CHATBORDER_OPACITY_DESC = "테두리가 얼마나 불투명한지 정합니다."
L.CHATBORDER_FADE = "대화창과 함께 흐려짐"
L.CHATBORDER_FADE_DESC = "게임이 대화창 탭을 흐리게 하듯, 마우스가 대화창을 벗어나면 테두리를 흐리게 하고 마우스가 "
    .. "다시 대화창 위로 오면 되돌립니다."
L.CHATBORDER_SECTION_EDITBOX = "입력창"
L.CHATBORDER_EDITBOX = "입력창 포함"
L.CHATBORDER_EDITBOX_DESC = "대화를 입력하는 창도 게임 자체 상자 대신 같은 테두리로, 대화창의 테두리와 이어서 "
    .. "그립니다."
L.CHATBORDER_EDITBOX_CHANNEL = "입력 중 대화 색상"
L.CHATBORDER_EDITBOX_CHANNEL_DESC = "게임이 자체 입력창을 밝히듯, 입력하는 동안 입력창 테두리를 입력 중인 대화의 "
    .. "색으로 칠합니다. 길드는 녹색, 귓속말은 분홍색 같은 식입니다."
L.CHATBORDER_FADE_OPACITY = "흐려진 투명도"
L.CHATBORDER_FADE_OPACITY_DESC = "마우스가 대화창에서 벗어나 있는 동안 테두리가 얼마나 남을지 정합니다. 게임은 앞쪽 "
    .. "탭을 40% 남기며, 0%이면 마우스를 대화창 위에 올릴 때까지 테두리가 보이지 않습니다."

-- PersistentChat
L.PERSISTENTCHAT_TITLE = "대화 항상 표시"
L.PERSISTENTCHAT_DESC = "대화 글자를 시간이 지나도 흐려지게 하지 않고 화면에 남겨 둡니다. 끄면 블리자드의 흐려짐이 "
    .. "돌아옵니다."

-- HideCombatLogTab
L.HIDECOMBATLOGTAB_TITLE = "전투 기록 탭 숨기기"
L.HIDECOMBATLOGTAB_DESC = "전투 기록이 대화창에 붙어 있는 동안 그 탭을 대화창에서 뺍니다. 전투 기록 자체는 계속 "
    .. "작동합니다."

-- MovableCombatLogTab
L.MOVABLECOMBATLOGTAB_TITLE = "전투 기록 탭 이동"
L.MOVABLECOMBATLOGTAB_DESC = "전투 기록 탭이 일반 탭 바로 뒤에 고정되지 않고, 직접 만든 탭 뒤까지 대화 탭 사이 "
    .. "어디로든 끌어 옮길 수 있게 합니다."

-- HideChatButtons
L.HIDECHATBUTTONS_TITLE = "대화 버튼 숨기기"
L.HIDECHATBUTTONS_DESC = "마우스가 대화창 위에 오기 전까지 대화창 옆의 버튼을 숨기고, 탭과 함께 나타나고 "
    .. "흐려지게 합니다."

-- HideChatTabs
L.HIDECHATTABS_TITLE = "대화 탭 숨기기"
L.HIDECHATTABS_DESC = "마우스가 대화창 위에 오기 전까지 대화창의 탭을 숨기고, 게임이 탭을 어둡게 하듯 나타나고 "
    .. "흐려지게 합니다. 새 메시지가 있는 탭은 그대로 깜박이며, 숨긴 탭도 클릭할 수 있습니다."

-- EditBoxOnTop
L.EDITBOXONTOP_TITLE = "입력창 위로"
L.EDITBOXONTOP_DESC = "대화를 입력하는 창을 대화창 아래 대신 대화창 탭 위에 놓습니다. 끄면 원래 자리로 "
    .. "돌아갑니다."

-- WhisperWindow
L.WHISPERWINDOW_TITLE = "귓속말 창"
L.WHISPERWINDOW_DESC = "귓속말을 사람마다 대화 하나씩, 답장할 입력창과 함께 별도의 창에 모아 둡니다. 대화는 "
    .. "캐릭터마다 저장됩니다."
L.WHISPERWINDOW_WINDOW_TITLE = "귓속말"
L.WHISPERWINDOW_SECTION_WINDOW = "창"
L.WHISPERWINDOW_SECTION_OPACITY = "투명도"
L.WHISPERWINDOW_OPEN = "귓속말이 오면 열기"
L.WHISPERWINDOW_OPEN_DESC = "귓속말이 오거나 대화창에서 귓속말을 보내면 창을 엽니다. 전투 중에는 전투가 끝날 "
    .. "때까지 기다립니다."
L.WHISPERWINDOW_HIDE = "대화창에서 귓속말 숨기기"
L.WHISPERWINDOW_HIDE_DESC = "귓속말 창이 받은 귓속말과 자리 비움, 다른 용무 중 자동 응답을 대화창에서 뺍니다. 게임이 "
    .. "내용을 숨긴 귓속말은 그대로 대화창에 표시됩니다."
L.WHISPERWINDOW_BUTTON = "대화 버튼"
L.WHISPERWINDOW_BUTTON_DESC = "대화창 옆에 귓속말 창을 열고 읽지 않은 귓속말을 세는 버튼을 더합니다. 버튼이 들어가지 "
    .. "않을 만큼 낮은 대화창에서는 말풍선 버튼 메뉴에 들어가며, 말풍선이 대신 귓속말을 셉니다."
L.WHISPERWINDOW_BUTTON_HIDDEN = "대화 버튼이 숨겨져 있어 '대화 버튼'을 표시할 수 없습니다."
L.WHISPERWINDOW_BUTTON_HIDDEN_DESC = "대화창 옆의 블리자드 버튼이 숨겨져 있습니다. 아마 다른 대화 애드온 때문이며, "
    .. "'대화 버튼'도 그 버튼들과 함께 있습니다. /fpp whispers나 아래의 '표시'로 창을 여십시오."
L.WHISPERWINDOW_ALPHA = "투명도"
L.WHISPERWINDOW_ALPHA_DESC = "가만히 서 있는 동안, 그리고 마우스를 올리거나 입력하는 동안 창이 얼마나 불투명한지 "
    .. "정합니다."
L.WHISPERWINDOW_MOVING = "이동 중"
L.WHISPERWINDOW_MOVING_DESC = "전투 중이 아닐 때 움직이는 동안 창이 얼마나 불투명한지 정합니다."
L.WHISPERWINDOW_COMBAT = "전투 중"
L.WHISPERWINDOW_COMBAT_DESC = "전투 중에 창이 얼마나 불투명한지 정합니다."
L.WHISPERWINDOW_SHOW = "귓속말"
L.WHISPERWINDOW_SHOW_BUTTON = "표시"
L.WHISPERWINDOW_SHOW_DESC = "귓속말 창을 엽니다."
L.WHISPERWINDOW_CLEAR = "지우기"
L.WHISPERWINDOW_CLEAR_NAME = "저장된 대화"
L.WHISPERWINDOW_CLEAR_DESC = "이 캐릭터의 대화를 모두 지웁니다."
L.WHISPERWINDOW_CLEAR_CONFIRM = "이 캐릭터의 대화를 모두 지우시겠습니까?"
L.WHISPERWINDOW_COMMAND = "귓속말 창을 열고, 이름을 주면 그 사람과의 대화를 엶"
L.WHISPERWINDOW_COMMAND_USAGE = "[이름]"
L.WHISPERWINDOW_TOOLTIP = "귓속말"
L.WHISPERWINDOW_TOOLTIP_DESC = "대화 목록을 엽니다."
L.WHISPERWINDOW_SUMMARY = { "대화 %d개" } -- how many
L.WHISPERWINDOW_SUMMARY_UNREAD = "%s, 읽지 않음 %d개" -- "3 conversations", unread whispers
L.WHISPERWINDOW_PREVIEW_YOU = "나: %s" -- your last whisper, in the list
L.WHISPERWINDOW_REPLY_HINT = "%s에게 귓속말" -- name
L.WHISPERWINDOW_UNREAD = "새 귓속말 %d개" -- unread whispers in a conversation
L.WHISPERWINDOW_NONE = "고른 대화가 없습니다."
L.WHISPERWINDOW_YOU = "당신"
L.WHISPERWINDOW_LINE = "%s %s: %s" -- time, who, the whisper
L.WHISPERWINDOW_INFO_LINE = "%s %s" -- time, what happened
L.WHISPERWINDOW_FULL_NAME = "%s %s" -- first name, surname
L.WHISPERWINDOW_LEVEL = "레벨 %d"
L.WHISPERWINDOW_PLAYING = "플레이 중: %s" -- a Battle.net friend's character
L.WHISPERWINDOW_GUILD_NAME = "<%s>" -- their guild, as Blizzard's tooltips show it
L.WHISPERWINDOW_FRIEND = "친구"
L.WHISPERWINDOW_GUILD = "길드"
L.WHISPERWINDOW_OFFLINE = "오프라인"
L.WHISPERWINDOW_UNKNOWN = "레벨과 지역은 친구, 길드원, 주변 플레이어에게만 표시됩니다."
L.WHISPERWINDOW_AFK = "자리 비움: %s" -- the away message
L.WHISPERWINDOW_DND = "다른 용무 중: %s" -- the busy message
L.WHISPERWINDOW_INVITE = "초대"
L.WHISPERWINDOW_MENU_COMBAT = "전투가 끝나면 더 보기" -- a gray line in the short menu a name gets in combat
L.WHISPERWINDOW_REMOVE = "대화 삭제"
L.WHISPERWINDOW_REMOVE_CONFIRM = "%s 님과의 대화를 지우시겠습니까?" -- name
L.WHISPERWINDOW_NEW = "새 귓속말"
L.WHISPERWINDOW_NEW_PROMPT = "누구에게 귓속말을 보내시겠습니까?"
L.WHISPERWINDOW_LOCKED = "지금 이곳에서는 대화가 제한되어 있습니다."
L.WHISPERWINDOW_TEST = "대화 시험"
L.WHISPERWINDOW_TEST_BUTTON = "보내기"
L.WHISPERWINDOW_TEST_DESC = "모양을 볼 수 있도록 나이트 엘프 드루이드와 귓속말을 몇 번 주고받은 가짜 대화를 귓속말 "
    .. "창에 더합니다. 창을 열지 않으므로 대화 버튼에서 읽지 않은 귓속말로 셉니다. 답장은 아무에게도 가지 "
    .. "않습니다."
L.WHISPERWINDOW_TEST_NAME = "테스티 달속삭임"
L.WHISPERWINDOW_TEST_RACE = "나이트 엘프"
L.WHISPERWINDOW_TEST_CLASS = "드루이드"
L.WHISPERWINDOW_BNET_OFFLINE = "이 Battle.net 친구는 접속해 있지 않습니다."
