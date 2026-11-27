local _, ns = ...
local L = ns.NewLocale("koKR")
if not L then
    return
end

-- ErrorCatcher
L.ERRORCATCHER_TITLE = "오류 수집기"
L.ERRORCATCHER_DESC = "블리자드 오류 창을 띄우지 않고 Lua 오류와 차단된 동작을 수집합니다. /fpp errors를 "
    .. "입력하거나 미니맵 버튼을 누르면 수집한 내용을 확인하고 복사할 수 있습니다."
L.ERRORCATCHER_CHAT_DESC = "오류를 수집하면 대화창에 알립니다."
L.ERRORCATCHER_SOUND_DESC = "오류를 수집하면 소리를 재생합니다. 많아야 10초에 한 번입니다. 소리를 고르면 한 번 "
    .. "재생됩니다."
L.ERRORCATCHER_SHOW = "오류"
L.ERRORCATCHER_SHOW_BUTTON = "표시"
L.ERRORCATCHER_SHOW_DESC = "지금까지 수집한 오류가 있는 창을 엽니다."
L.ERRORCATCHER_CLEAR = "지우기"
L.ERRORCATCHER_CLEAR_NAME = "저장된 오류"
L.ERRORCATCHER_CLEAR_DESC = "모든 접속에서 저장된 오류를 모두 지웁니다."
L.ERRORCATCHER_CLEAR_CONFIRM = "저장된 오류를 모두 지우시겠습니까?"
L.ERRORCATCHER_COMMAND = "수집한 Lua 오류 표시"
L.ERRORCATCHER_CAUGHT = "오류를 수집했습니다: %s /fpp errors를 입력하면 볼 수 있습니다." -- first line of the error
L.ERRORCATCHER_CAUGHT_LOADING = "접속하는 동안 오류 %d개를 수집했습니다. /fpp errors를 입력하면 볼 수 있습니다."
L.ERRORCATCHER_OTHER_HANDLER = "BugGrabber 같은 다른 애드온이 Lua 오류를 수집하고 있어, '오류 수집기'는 "
    .. "차단된 동작과 경고만 수집합니다."
L.ERRORCATCHER_OTHER_HANDLER_DESC = "Lua 오류는 대신 그 애드온, 예를 들어 BugSack의 창으로 갑니다. 블리자드 "
    .. "오류 창과 차단된 동작 팝업도 그 애드온에 맡깁니다."
L.ERRORCATCHER_BLOCKED = "%s: %s 애드온이 보호된 함수 %s 호출을 시도했습니다." -- event, addon, function
-- Where: the first few of Blizzard's functions on the stack, such as "SmartNavigation.lua:84 < Menu.lua:2143"
L.ERRORCATCHER_BLOCKED_SILENT = "게임이 애드온을 밝히지 않고 \"애드온으로 인해 인터페이스 작동이 "
    .. "실패했습니다.\"라고 알렸습니다. 위치: %s"
L.ERRORCATCHER_SECRET = "(게임이 이 오류의 내용을 숨겼습니다.)"
L.ERRORCATCHER_UNKNOWN = "알 수 없음"
L.ERRORCATCHER_THIS_SESSION = "이번 접속"
L.ERRORCATCHER_LAST_SESSION = "이전 접속"
L.ERRORCATCHER_ALL = "모든 접속"
L.ERRORCATCHER_FILTER = "%s (%d)" -- a filter above, how many errors it shows
L.ERRORCATCHER_SUMMARY = "이번 접속 %d개, 저장됨 %d개" -- errors this session, errors saved
L.ERRORCATCHER_NONE = "수집한 오류가 없습니다."
L.ERRORCATCHER_KIND_BLOCKED = "차단된 동작"
L.ERRORCATCHER_KIND_TAINT = "오염"
L.ERRORCATCHER_POSITION = "%d / %d" -- this one, how many
L.ERRORCATCHER_ROW_INFO = "%d회, %s" -- times seen, how long ago ("12m ago")
-- times, session, first and last time it happened, how long ago ("12m ago")
-- The forms go by the times.
L.ERRORCATCHER_META = {
    "접속 %2$d에서 %1$d회 발생, 처음 %3$s, 마지막 %4$s (%5$s).",
}
L.ERRORCATCHER_STACK = "스택:"
L.ERRORCATCHER_LOCALS = "지역 변수:"
L.ERRORCATCHER_NO_STACK = "스택 없음: 차단된 동작과 경고에는 스택이 없습니다."
-- What was going on when an action was blocked, in place of a stack.
L.ERRORCATCHER_CONTEXT = "발생 당시:"
L.ERRORCATCHER_CONTEXT_COMBAT = "전투 중: %s"
L.ERRORCATCHER_CONTEXT_INSTANCE = "인스턴스: %s" -- none, party, raid, pvp, arena, scenario
L.ERRORCATCHER_CONTEXT_MOUSE = "마우스 위치: %s" -- a frame's name, such as TargetFrame
L.ERRORCATCHER_CONTEXT_MENUS = "열린 메뉴: %s" -- menu tags, such as MENU_UNIT_TARGET
L.ERRORCATCHER_CONTEXT_GAMEPAD = "게임패드 인터페이스: %s"
L.ERRORCATCHER_CONTEXT_TAINT_LOG = "오염 기록 켜짐: %s"
-- Values in the controller navigation's tables that addon code wrote, each on a line of its own.
L.ERRORCATCHER_CONTEXT_STATE = "애드온이 기록한 게임패드 상태: %s"
-- The value's name, the addon, the time first seen, and the windows open then.
L.ERRORCATCHER_CONTEXT_STATE_LINE = "  %s, 기록: %s, 처음 확인 %s, 열린 창: %s"
-- A value's name, and how many more beside it in the same table were written at the same time.
L.ERRORCATCHER_CONTEXT_STATE_MORE = "%s (외 %d개)"
-- When the watch began: a value first seen at this time was already written before it.
L.ERRORCATCHER_CONTEXT_STATE_SINCE = "  (감시 시작 %s)"
L.ERRORCATCHER_CONTEXT_YES = "예"
L.ERRORCATCHER_CONTEXT_NO = "아니요"
L.ERRORCATCHER_CONTEXT_NONE = "없음"
L.ERRORCATCHER_TAINT_HINT = "'오류 수집기' 설정에서 '오염 기록'을 켜면, 다음에 이런 일이 생길 때 게임이 어떤 "
    .. "애드온의 코드가 원인인지 게임 폴더의 Logs\\taint.log에 기록합니다."
L.ERRORCATCHER_TAINT_LOG = "오염 기록"
L.ERRORCATCHER_TAINT_LOG_DESC = "게임 자체 설정 중 하나로, 차단된 동작마다 어떤 애드온의 코드가 원인인지 게임 "
    .. "폴더의 Logs\\taint.log에 기록합니다. 파일이 빨리 커지므로 원인을 찾는 동안에만 켜고 그 뒤에는 "
    .. "끄십시오."
L.ERRORCATCHER_COPY = "버그 신고 복사"
L.ERRORCATCHER_COPY_HINT = "선택했습니다. Ctrl+C를 눌러 복사하십시오."
L.ERRORCATCHER_TEST = "오류 시험"
L.ERRORCATCHER_TEST_BUTTON = "발생"
L.ERRORCATCHER_TEST_DESC = "일부러 Lua 오류를 일으켜 '오류 수집기'(꺼져 있으면 블리자드 오류 창)가 수집하는지 "
    .. "확인합니다."
L.ERRORCATCHER_TEST_MESSAGE = "Forever++ 시험 오류입니다. 아무 문제도 없습니다."

-- AddOnsList
L.ADDONSLIST_TITLE = "애드온 목록"
L.ADDONSLIST_DESC = "애드온 목록을 범주 제목 없이, 사용하는 애드온을 먼저 표시합니다."
L.ADDONSLIST_ENABLEDFIRST = "사용하는 애드온 먼저"
L.ADDONSLIST_ENABLEDFIRST_DESC = "사용하는 애드온을 사용하지 않는 애드온보다 위에 나열합니다."
L.ADDONSLIST_UNGROUP = "사용 안 함 묶음 해제"
L.ADDONSLIST_UNGROUP_DESC = "사용하지 않는 애드온을 묶음에서 빼서 목록의 사용 안 함 부분으로 옮겨, 묶음에는 켜진 "
    .. "애드온만 보이게 합니다."
L.ADDONSLIST_NOTES = "설명 검색"
L.ADDONSLIST_NOTES_DESC = "검색창이 애드온 설명에 있는 낱말도 찾게 합니다."
L.ADDONSLIST_SETS = "애드온 세트"
L.ADDONSLIST_SETS_DESC = "'모두 사용 안 함' 옆에 세트 드롭다운을 더해, 목록에 표시된 캐릭터에 대해 켜 둔 애드온을 "
    .. "이름으로 저장하고 나중에 그 세트를 다시 켤 수 있게 합니다. Forever++는 켜진 채로 둡니다. '확인'을 누르면 "
    .. "세트를 적용해 UI를 재시작합니다."
L.ADDONSLIST_SETS_BUTTON = "세트"
L.ADDONSLIST_SETS_NONE = "저장된 세트 없음"
L.ADDONSLIST_SETS_SAVE = "현재 세트 저장..."
L.ADDONSLIST_SETS_SAVE_PROMPT = "지금 켜 둔 애드온을 저장할 세트 이름:"
L.ADDONSLIST_SETS_REPLACE_CONFIRM = "\"%s\" 애드온 세트를 지금 켜 둔 애드온으로 바꾸시겠습니까?"
L.ADDONSLIST_SETS_DELETE = "세트 삭제"
L.ADDONSLIST_SETS_DELETE_CONFIRM = "\"%s\" 애드온 세트를 삭제하시겠습니까?"
L.ADDONSLIST_SETS_SAVED = "애드온 세트를 저장했습니다: %s."
L.ADDONSLIST_SETS_MISSING = "애드온 세트 %s에서 설치되지 않은 애드온: %d개."
L.ADDONSLIST_CHAT_DESC = "세트를 저장하면, 그리고 세트를 켤 때 설치되지 않은 애드온이 몇 개인지 대화창에 "
    .. "알립니다."

-- MinimapButton
L.MINIMAPBUTTON_TITLE = "미니맵 버튼"
L.MINIMAPBUTTON_DESC = "미니맵, 애드온 보관함, 또는 둘 다에 Forever++ 버튼을 둡니다. 클릭하면 빠른 전환(아래 "
    .. "'빠른 전환'에서 어떤 모듈을 넣을지 고릅니다), 오른쪽 클릭하면 설정, Shift+클릭하면 수집한 오류가 "
    .. "열립니다."
L.MINIMAPBUTTON_SECTION_BUTTON = "버튼"
L.MINIMAPBUTTON_SECTION_TOGGLES = "빠른 전환"
L.MINIMAPBUTTON_SECTION_ERRORS = "오류"
L.MINIMAPBUTTON_WHERE = "표시 위치"
L.MINIMAPBUTTON_WHERE_DESC = "버튼을 둘 곳입니다. 미니맵, 그 아래의 애드온 보관함, 또는 둘 다입니다. 미니맵 버튼을 "
    .. "끌어 미니맵 둘레로 옮길 수 있습니다."
L.MINIMAPBUTTON_WHERE_MINIMAP = "미니맵"
L.MINIMAPBUTTON_WHERE_COMPARTMENT = "애드온 보관함"
L.MINIMAPBUTTON_WHERE_BOTH = "모두"
L.MINIMAPBUTTON_COMPARTMENT_COUNT = "%s (%d)" -- Forever++, errors this session
L.MINIMAPBUTTON_TIP_SESSION = "이번 접속 오류"
L.MINIMAPBUTTON_TIP_SAVED = "저장된 오류"
L.MINIMAPBUTTON_TIP_NONE = "없음" -- a count of 0 errors
-- The quick toggles' groups, by what you're doing (Menu Order's Activity).
L.MINIMAPBUTTON_GROUP_LOOT = "상인 및 전리품"
L.MINIMAPBUTTON_GROUP_NPCS = "NPC 및 퀘스트"
L.MINIMAPBUTTON_GROUP_WORLD = "필드 활동"
L.MINIMAPBUTTON_GROUP_NAMEPLATES = "이름표"
L.MINIMAPBUTTON_GROUP_GATHERING = "채집"
L.MINIMAPBUTTON_GATHERING_SHOWS = "채집 지도 표시 대상" -- over its kinds' checkboxes: Herbs, Ore...
L.MINIMAPBUTTON_GROUP_OTHER = "기타"
-- The button in the module's settings that picks the quick toggles: a menu with a submenu per
-- module category, with checkboxes; and the line at the bottom of the quick toggles that opens it.
L.MINIMAPBUTTON_CUSTOMIZE_NAME = "빠른 전환"
L.MINIMAPBUTTON_CUSTOMIZE = "항목 선택"
L.MINIMAPBUTTON_CUSTOMIZE_DESC = "버튼의 빠른 전환에 넣을 모듈을 범주별로 고릅니다."
L.MINIMAPBUTTON_CUSTOMIZE_OPEN = "항목 선택..."
-- The quick toggles' submenu of profiles, with more than one: the profile in use
L.MINIMAPBUTTON_PROFILE = "프로필: %s"
L.MINIMAPBUTTON_CUSTOMIZE_OPEN_DESC = "미니맵 버튼 설정에서 이 메뉴에 넣을 모듈을 고릅니다."
L.MINIMAPBUTTON_CUSTOMIZE_RESET = "기본값 복원"
L.MINIMAPBUTTON_MENU_CUSTOMIZE = "메뉴에 항목 선택"
L.MINIMAPBUTTON_MENU_CUSTOMIZE_DESC = "빠른 전환 맨 아래에 '항목 선택...'을 표시합니다. 끄면 아래의 '항목 선택' "
    .. "버튼으로 고릅니다."
L.MINIMAPBUTTON_MENU_PROFILES = "메뉴에 프로필"
L.MINIMAPBUTTON_MENU_PROFILES_DESC = "프로필이 둘 이상이면 빠른 전환에 프로필을 전환하는 '프로필' 하위 메뉴를 "
    .. "표시합니다."
-- The tooltip's hints: what a click does, then the click.
L.MINIMAPBUTTON_HINT_SETTINGS = "설정 열기"
L.MINIMAPBUTTON_HINT_WELCOME = "Forever++ 정보"
L.MINIMAPBUTTON_HINT_TOGGLES = "빠른 전환"
L.MINIMAPBUTTON_HINT_ERRORS = "오류 표시"
L.MINIMAPBUTTON_HINT_CLEAR = "이번 접속 오류 지우기"
L.MINIMAPBUTTON_HINT_CLEAR_ALL = "모든 오류 지우기"
L.MINIMAPBUTTON_HINT_MOVE = "버튼 이동"
L.MINIMAPBUTTON_PLACE_NAME = "버튼 위치"
L.MINIMAPBUTTON_PLACE_RESET_DESC = "미니맵 버튼을 처음 위치인 미니맵 가장자리로 되돌립니다. 끌어서 미니맵 위나 "
    .. "주변 어디에든 놓을 수 있습니다."
-- The tooltip's legend: what each click does, the click at the right in green. Named as Blizzard's
-- instruction lines name clicks ("Ctrl click", "Right click"): separate words, no hyphen.
L.MINIMAPBUTTON_LEFT_CLICK = "클릭"
L.MINIMAPBUTTON_RIGHT_CLICK = "오른쪽 클릭"
L.MINIMAPBUTTON_KEY_LEFT_CLICK = "%s 클릭" -- a key, such as Shift
L.MINIMAPBUTTON_KEY_RIGHT_CLICK = "%s 오른쪽 클릭" -- the same, with Click Opens Quick Toggles on
L.MINIMAPBUTTON_SWAP = "클릭으로 빠른 전환 열기"
L.MINIMAPBUTTON_SWAP_DESC = "클릭하면 빠른 전환이, 오른쪽 클릭하면 설정이 열립니다. 끄면 반대입니다."
L.MINIMAPBUTTON_KEYS_LEFT = "오류 키는 클릭에"
L.MINIMAPBUTTON_KEYS_LEFT_DESC = "Shift+클릭으로 오류 표시처럼 오류 키를 설정과 함께 오른쪽 클릭으로 옮기지 않고 "
    .. "클릭에 둡니다."
L.MINIMAPBUTTON_MENU_SIDE = "메뉴 방향"
L.MINIMAPBUTTON_MENU_SIDE_DESC = "빠른 전환이 커서에서 열리는 방향입니다. 블리자드가 메뉴를 여는 방식대로, 또는 "
    .. "커서의 왼쪽이나 오른쪽입니다."
L.MINIMAPBUTTON_MENU_SIDE_AUTO = "자동"
L.MINIMAPBUTTON_MENU_SIDE_LEFT = "왼쪽"
L.MINIMAPBUTTON_MENU_SIDE_RIGHT = "오른쪽"
L.MINIMAPBUTTON_MENU_ORDER = "메뉴 순서"
L.MINIMAPBUTTON_MENU_ORDER_DESC = "빠른 전환의 배치 방식입니다. 하는 일에 따른 묶음('상인 및 전리품', 'NPC 및 "
    .. "퀘스트' 등), 모듈 페이지의 범주, 또는 가나다순 목록 하나입니다."
L.MINIMAPBUTTON_MENU_ORDER_GROUPS = "활동"
L.MINIMAPBUTTON_MENU_ORDER_CATEGORY = "범주"
L.MINIMAPBUTTON_MENU_ORDER_TITLE = "가나다순"
L.MINIMAPBUTTON_LEFT_DRAG = "끌기"
L.MINIMAPBUTTON_ERRORS_KEY = "오류 표시 키"
L.MINIMAPBUTTON_ERRORS_KEY_DESC = "'오류 수집기'가 켜져 있을 때, 버튼을 클릭하면서 누르고 있으면 오류를 보여 주는 "
    .. "키입니다."
L.MINIMAPBUTTON_CLEAR_KEY = "이번 접속 지우기 키"
L.MINIMAPBUTTON_CLEAR_KEY_DESC = "'오류 수집기'가 켜져 있을 때, 버튼을 클릭하면서 누르고 있으면 이번 접속의 오류를 "
    .. "지우는 키입니다."
L.MINIMAPBUTTON_CLEAR_ALL_KEY = "모두 지우기 키"
L.MINIMAPBUTTON_CLEAR_ALL_KEY_DESC = "'오류 수집기'가 켜져 있을 때, 버튼을 클릭하면서 누르고 있으면 모든 접속에서 "
    .. "저장된 오류를 모두 지우는 키입니다. 먼저 확인을 묻습니다."

-- Commands
L.COMMANDS_TITLE = "슬래시 명령어"
L.COMMANDS_DESC = "짧은 슬래시 명령어를 더합니다. /rl은 UI를 재시작하고 /clear는 대화창을 비웁니다. /way는 "
    .. "'웨이포인트'에 있습니다."
L.COMMANDS_RELOAD = "/rl"
L.COMMANDS_RELOAD_DESC = "/rl은 /reload처럼 UI를 재시작합니다. 이미 /rl을 쓰는 다른 애드온이 있으면 그 애드온에 "
    .. "맡깁니다."
L.COMMANDS_RELOAD_HELP = "UI 재시작" -- a line of /fpp help, like the SLASH_ ones
L.COMMANDS_CLEAR_HELP = "입력한 대화창 비우기"
L.COMMANDS_CLEAR = "/clear"
L.COMMANDS_CLEAR_DESC = "/clear는 입력한 대화창을 비웁니다. 이미 /clear를 쓰는 다른 애드온이 있으면 그 애드온에 "
    .. "맡깁니다."

-- HideBetaFeedback
L.HIDEBETAFEEDBACK_TITLE = "베타 피드백 숨기기"
L.HIDEBETAFEEDBACK_DESC = "툴팁에 나오는 베타의 \"Press F6 to submit an issue\" 줄과 버그 신고 버튼을 숨깁니다. "
    .. "F6으로는 여전히 문제를 신고할 수 있습니다."
L.HIDEBETAFEEDBACK_TOOLTIP = "툴팁 알림 숨기기"
L.HIDEBETAFEEDBACK_TOOLTIP_DESC = "툴팁의 \"Press F6 to submit an issue\" 줄을 숨깁니다."
L.HIDEBETAFEEDBACK_BUTTON = "버그 신고 버튼 숨기기"
L.HIDEBETAFEEDBACK_BUTTON_DESC = "떠 있는 버그 신고 버튼을 숨깁니다."
L.HIDEBETAFEEDBACK_QUEST = "퀘스트 피드백 숨기기"
L.HIDEBETAFEEDBACK_QUEST_DESC = "퀘스트 창의 피드백 버튼을 숨깁니다."

-- MovableFramerate
L.MOVABLEFRAMERATE_TITLE = "프레임률 이동"
L.MOVABLEFRAMERATE_DESC = "블리자드 기본 개체창처럼 편집 모드에서 프레임률 표시(Ctrl+R)의 위치와 크기를 바꿉니다. "
    .. "옮기기 전까지는 블리자드가 놓는 자리에 그대로 있습니다."
