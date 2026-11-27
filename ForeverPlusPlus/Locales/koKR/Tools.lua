local _, ns = ...
local L = ns.NewLocale("koKR")
if not L then
    return
end

-- ConsoleVariables
L.CONSOLEVARIABLES_TITLE = "콘솔 변수"
-- Debug (its title, L.DEBUG, is in Core.lua)
L.DEBUG_DESC = "모든 모듈의 디버그 옵션과 시험 도구(자체 시험, 장비 조사, 스크린샷)를 설정 사이드바의 디버그 "
    .. "페이지에 표시하고, 그 명령어를 켭니다."
L.DEBUG_NOTICE = "디버그를 끄면 모든 디버그 옵션이 기본값으로 돌아갑니다." -- a gray row atop the module
L.DEBUG_NOTICE_DESC = "여기서 설정한 것이 보이지 않는 곳에서 계속 작동하지 않도록 하기 위해서입니다."
-- ConsoleVariables
L.CONSOLEVARIABLES_DESC = "설정의 한 페이지에서 게임의 콘솔 변수(CVar)를 살펴보고 바꾸며, 게임이 접속할 때마다 "
    .. "되돌리는 것까지 원하는 변수를 잠가 유지합니다."
L.CONSOLEVARIABLES_CHAT_DESC = "잠근 콘솔 변수를 그 값으로 유지할 수 없으면 대화창에 알립니다."
-- A gray row atop the module while it's off with console variables locked
L.CONSOLEVARIABLES_LOCKS_OFF = "이 모듈이 꺼져 있는 동안에는 잠근 콘솔 변수가 유지되지 않습니다."
L.CONSOLEVARIABLES_LOCKS_OFF_DESC = "다시 켤 때까지 게임이 정하는 값으로 돌아갑니다."
L.CONSOLEVARIABLES_COMMAND = "콘솔 변수 열기, [search]로 검색"
L.CONSOLEVARIABLES_NO_PAGE = "이 클라이언트의 설정에서는 콘솔 변수 페이지를 열 수 없습니다."
L.CONSOLEVARIABLES_AFTER_COMBAT = "%s: 전투가 끝나면 바뀝니다." -- CVar name
L.CONSOLEVARIABLES_REFUSED = "%s: 바꿀 수 없습니다." -- CVar name
L.CONSOLEVARIABLES_KEPT = "%s: %s 값을 유지했습니다. 게임이 %s 값을 받아들이지 않았습니다." -- CVar name, its value, the typed one
L.CONSOLEVARIABLES_SEARCH = "콘솔 변수 검색" -- gray text in the empty search box
L.CONSOLEVARIABLES_POPULAR = "인기" -- the group of CVars players most often look for
L.CONSOLEVARIABLES_FAVORITES = "즐겨찾기" -- the group of CVars the player starred
L.CONSOLEVARIABLES_LOCKED = "잠김" -- the group of CVars the player locked at a value
L.CONSOLEVARIABLES_CHANGED = "변경됨" -- the group of CVars not at their default
L.CONSOLEVARIABLES_ALL = "전체"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CONSOLEVARIABLES_CATEGORY_GRAPHICS = "그래픽"
L.CONSOLEVARIABLES_CATEGORY_CONSOLE = "콘솔"
L.CONSOLEVARIABLES_CATEGORY_COMBAT = "전투"
L.CONSOLEVARIABLES_CATEGORY_GAME = "게임"
L.CONSOLEVARIABLES_CATEGORY_DEFAULT = "일반" -- Default
L.CONSOLEVARIABLES_CATEGORY_NET = "네트워크"
L.CONSOLEVARIABLES_CATEGORY_SOUND = "소리"
L.CONSOLEVARIABLES_CATEGORY_GM = "게임 마스터" -- Gm
L.CONSOLEVARIABLES_CATEGORY_REVEAL = "공개됨" -- Reveal
L.CONSOLEVARIABLES_CATEGORY_NONE = "기타" -- None
L.CONSOLEVARIABLES_NO_MATCH = "\"%s\"에 해당하는 콘솔 변수가 없습니다." -- the search text
L.CONSOLEVARIABLES_NONE_CHANGED = "모든 콘솔 변수가 기본값입니다."
L.CONSOLEVARIABLES_NO_FAVORITES = "콘솔 변수의 별을 클릭하면 여기에 보관합니다."
L.CONSOLEVARIABLES_NO_LIST = "이 클라이언트는 콘솔 변수 목록을 제공하지 않습니다. 찾으려면 변수의 전체 이름으로 "
    .. "검색하십시오."
L.CONSOLEVARIABLES_DEFAULT = "기본값"
L.CONSOLEVARIABLES_VALUE_IS = "값: %s"
L.CONSOLEVARIABLES_DEFAULT_IS = "기본값: %s"
L.CONSOLEVARIABLES_ON_OFF = "보통 0은 끄기, 1은 켜기입니다."
L.CONSOLEVARIABLES_ON_OFF_HINT = "보통 0은 끄기, 1은 켜기입니다. 맞지 않으면 다른 값을 받는 변수이니 찾아보십시오."
L.CONSOLEVARIABLES_ACCOUNT = "계정에 저장됩니다."
L.CONSOLEVARIABLES_CHARACTER = "이 캐릭터에 저장됩니다."
L.CONSOLEVARIABLES_READ_ONLY = "바꿀 수 없습니다."
L.CONSOLEVARIABLES_SECURE = "보호됨: 바꾼 내용은 전투가 끝날 때까지 기다립니다."
L.CONSOLEVARIABLES_NO_LOCKS = "콘솔 변수의 자물쇠를 클릭하면 접속하거나 바뀔 때마다 그 값을 유지합니다."
-- Locks: a locked CVar is put back to its value at login and whenever something changes it.
L.CONSOLEVARIABLES_LOCKED_AT = "%s 값으로 잠김: 접속할 때마다, 그리고 무언가 바꿀 때마다 되돌립니다." -- the locked value
L.CONSOLEVARIABLES_LOCK_HINT = "<이 값을 유지하려면 자물쇠 클릭>" -- tooltip of an open lock
L.CONSOLEVARIABLES_UNLOCK_HINT = "<유지를 멈추려면 자물쇠 클릭>" -- tooltip of a closed lock
L.CONSOLEVARIABLES_LOCK_STOPPED = "유지되지 않아, UI를 재시작하거나 다시 접속할 때까지 유지하지 않습니다."
L.CONSOLEVARIABLES_LOCK_FAILED = "%s 변수를 잠근 값(%s)으로 되돌리지 못했습니다 (현재 %s). UI를 재시작하거나 "
    .. "다시 접속할 때까지 잠금을 멈춥니다." -- CVar name, the locked value, its value now
L.CONSOLEVARIABLES_LOCK_FIGHT = "%s 변수를 다른 무언가가 계속 바꾸고 있습니다. UI를 재시작하거나 다시 접속할 "
    .. "때까지 잠금을 멈춥니다." -- CVar name
-- Popular: the section headers, then each CVar's plain name and what it does.
L.CONSOLEVARIABLES_POP_CAMERA = "시점"
L.CONSOLEVARIABLES_POP_EFFECTS = "화면 효과"
L.CONSOLEVARIABLES_POP_NAMEPLATES = "이름표"
L.CONSOLEVARIABLES_POP_MAP = "지도"
L.CONSOLEVARIABLES_POP_CHAT = "대화"
L.CONSOLEVARIABLES_POP_COMBAT = "전투"
L.CONSOLEVARIABLES_POP_INTERFACE = "인터페이스"
L.CONSOLEVARIABLES_POP_GRAPHICS = "그래픽"
L.CONSOLEVARIABLES_POP_SCREENSHOTS = "스크린샷"
L.CONSOLEVARIABLES_POP_MOUSE = "마우스"
L.CONSOLEVARIABLES_POP_ZOOM_DESC = "카메라를 얼마나 멀리 뺄 수 있는지 정합니다. 설정 창은 2.0까지지만, 이 변수로는 더 "
    .. "멀리 갈 수 있습니다."
L.CONSOLEVARIABLES_POP_ZOOM_SPEED = "확대/축소 속도"
L.CONSOLEVARIABLES_POP_ZOOM_SPEED_DESC = "마우스 휠로 카메라를 확대/축소하는 속도입니다. 기본값 20, 최대 50."
L.CONSOLEVARIABLES_POP_COLLISION = "카메라 충돌"
L.CONSOLEVARIABLES_POP_COLLISION_DESC = "1이면 나무와 벽이 나와 카메라 사이에 들어와도 잠시 뒤에 카메라가 당겨지고, "
    .. "0이면 바로 당겨집니다."
L.CONSOLEVARIABLES_POP_GLOW = "화면 광채"
L.CONSOLEVARIABLES_POP_GLOW_DESC = "화면 전체에 깔리는 부드러운 광채입니다. 0이면 꺼져 더 선명해집니다."
L.CONSOLEVARIABLES_POP_DEATH_DESC = "죽어 있는 동안의 회색 흐림 효과입니다. 0이면 꺼집니다."
L.CONSOLEVARIABLES_POP_PLATE_RANGE = "이름표 거리"
L.CONSOLEVARIABLES_POP_PLATE_RANGE_DESC = "이름표가 보이는 최대 거리(미터)입니다. 기본값 45. 이 캐릭터에 "
    .. "저장됩니다."
L.CONSOLEVARIABLES_POP_PLATE_SPACING = "이름표 간격"
L.CONSOLEVARIABLES_POP_PLATE_SPACING_DESC = "겹쳐 쌓인 이름표 사이의 간격입니다. 낮을수록 촘촘합니다. 기본값 1.1."
L.CONSOLEVARIABLES_POP_PLATE_FAR = "먼 이름표 투명도"
L.CONSOLEVARIABLES_POP_PLATE_FAR_DESC = "먼 이름표가 얼마나 흐린지, 0에서 1까지입니다. 기본값 0.6, 1이면 흐려지지 "
    .. "않습니다."
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN = "가려진 개체 투명도"
L.CONSOLEVARIABLES_POP_PLATE_HIDDEN_DESC = "벽 뒤에 있는 개체의 이름표가 얼마나 흐린지, 0에서 1까지입니다. 기본값 "
    .. "0.4."
L.CONSOLEVARIABLES_POP_PLATE_TARGET = "대상 이름표 크기"
L.CONSOLEVARIABLES_POP_PLATE_TARGET_DESC = "대상의 이름표를 얼마나 크게 할지 정합니다. 기본값 1.2, 1이면 같은 "
    .. "크기입니다."
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED = "간소화 이름표 크기"
L.CONSOLEVARIABLES_POP_PLATE_SIMPLIFIED_DESC = "간소화된 이름표의 크기입니다. 기본값 0.3. 게임이 접속할 때 기본값으로 "
    .. "되돌릴 수 있으니, 유지하려면 잠그십시오."
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS = "적 토템 이름표"
L.CONSOLEVARIABLES_POP_PLATE_TOTEMS_DESC = "1이면 적 토템에 이름표를 표시해 찾아서 대상으로 잡을 수 있습니다."
L.CONSOLEVARIABLES_POP_PLATE_PETS = "적 소환수 이름표"
L.CONSOLEVARIABLES_POP_PLATE_PETS_DESC = "1이면 적 플레이어의 소환수에 이름표를 표시합니다."
L.CONSOLEVARIABLES_POP_COMBO = "연계 점수 위치"
L.CONSOLEVARIABLES_POP_COMBO_DESC = "연계 점수를 표시할 곳입니다. 1이면 대상 개체창, 2이면 내 개체창입니다."
L.CONSOLEVARIABLES_POP_FOG_END = "안개 거리"
L.CONSOLEVARIABLES_POP_FOG_END_DESC = "원거리 안개가 가장 짙어지는 거리입니다. 기본값 1600. '가시 거리'와 함께 "
    .. "높이십시오."
L.CONSOLEVARIABLES_POP_FOG_START = "안개 시작"
L.CONSOLEVARIABLES_POP_FOG_START_DESC = "원거리 안개가 시작되는 거리입니다. 기본값 800."
L.CONSOLEVARIABLES_POP_GRASS = "풀 밀도"
L.CONSOLEVARIABLES_POP_GRASS_DESC = "풀과 지면 장식물이 얼마나 빽빽한지 정합니다. 기본값 16, 높을수록 프레임이 "
    .. "떨어집니다."
L.CONSOLEVARIABLES_POP_GRASS_DIST = "풀 거리"
L.CONSOLEVARIABLES_POP_GRASS_DIST_DESC = "풀을 그리는 거리입니다. 기본값 70."
L.CONSOLEVARIABLES_POP_ROTATE_DESC = "1이면 미니맵이 나와 함께 돌아, 위쪽이 내가 보는 방향이 됩니다."
L.CONSOLEVARIABLES_POP_MAP_FADE = "세계 지도 흐림"
L.CONSOLEVARIABLES_POP_MAP_FADE_DESC = "1이면 움직이는 동안 세계 지도가 흐려지고, 0이면 그대로 둡니다."
L.CONSOLEVARIABLES_POP_CHAT_SCROLL = "대화 마우스 휠"
L.CONSOLEVARIABLES_POP_CHAT_SCROLL_DESC = "1이면 마우스 휠로 대화를 스크롤합니다."
L.CONSOLEVARIABLES_POP_LOOT_SPAM = "전체 주사위 굴림"
L.CONSOLEVARIABLES_POP_LOOT_SPAM_DESC = "1이면 모든 플레이어의 주사위 굴림을 대화창에 표시하고, 0이면 획득자만 "
    .. "표시합니다."
L.CONSOLEVARIABLES_POP_QUEUE = "주문 대기열 시간"
L.CONSOLEVARIABLES_POP_QUEUE_DESC = "다음 주문을 얼마나 일찍 대기열에 넣을 수 있는지(밀리초), 0에서 400까지입니다. "
    .. "기본값 400."
L.CONSOLEVARIABLES_POP_STOP_ATTACK = "대상 변경 시 공격 중지"
L.CONSOLEVARIABLES_POP_STOP_ATTACK_DESC = "1이면 대상을 바꿀 때 자동 공격을 멈춥니다."
L.CONSOLEVARIABLES_POP_TEXT_SIZE = "전투 문자 크기"
L.CONSOLEVARIABLES_POP_TEXT_SIZE_DESC = "떠오르는 전투 숫자의 크기입니다. 기본값 1."
L.CONSOLEVARIABLES_POP_ERRORS = "Lua 오류 표시"
L.CONSOLEVARIABLES_POP_ERRORS_DESC = "1이면 애드온에 오류가 나면 게임의 창을 띄웁니다."
L.CONSOLEVARIABLES_POP_COMPARE = "항상 아이템 비교"
L.CONSOLEVARIABLES_POP_COMPARE_DESC = "1이면 Shift를 누르지 않아도 아이템 툴팁 옆에 착용 중인 장비를 표시합니다."
L.CONSOLEVARIABLES_POP_PUSH_SPELLS = "새 주문을 행동 단축바에"
L.CONSOLEVARIABLES_POP_PUSH_SPELLS_DESC = "1이면 배운 주문을 저절로 행동 단축바에 놓습니다. 이 캐릭터에 "
    .. "저장됩니다."
L.CONSOLEVARIABLES_POP_LOOT_RATE = "자동 전리품 획득 간격"
L.CONSOLEVARIABLES_POP_LOOT_RATE_DESC = "자동 전리품 획득이 아이템을 하나씩 가져오는 사이의 간격(밀리초)입니다. "
    .. "낮을수록 빠릅니다. 기본값 150."
L.CONSOLEVARIABLES_POP_FARCLIP_DESC = "월드를 그리는 거리입니다. 기본값 1000, 높을수록 프레임이 떨어집니다."
L.CONSOLEVARIABLES_POP_WEATHER = "날씨"
L.CONSOLEVARIABLES_POP_WEATHER_DESC = "비와 눈이 얼마나 보이는지, 0(없음)에서 3까지입니다. 기본값 2."
L.CONSOLEVARIABLES_POP_SHOT_QUALITY = "스크린샷 품질"
L.CONSOLEVARIABLES_POP_SHOT_QUALITY_DESC = "1에서 10까지, 높을수록 선명하고 파일이 큽니다. 기본값 3."
L.CONSOLEVARIABLES_POP_SHOT_FORMAT = "스크린샷 형식"
L.CONSOLEVARIABLES_POP_SHOT_FORMAT_DESC = "jpeg(작은 파일), png, 또는 tga(손실 없음, 큰 파일)입니다."
L.CONSOLEVARIABLES_POP_RAW_MOUSE = "마우스 원시 입력"
L.CONSOLEVARIABLES_POP_RAW_MOUSE_DESC = "1이면 마우스를 직접 읽어, 카메라 조작을 놓을 때 커서가 튀는 현상을 막을 수 "
    .. "있습니다."

-- SelfTest
L.SELFTEST_TITLE = "자체 시험"
L.SELFTEST_DESC = "디버깅을 위해 Forever++가 쓰는 클라이언트 API를 조사하고 그 결과를 저장합니다."

-- Screenshots
L.SCREENSHOTS_TITLE = "스크린샷"
L.SCREENSHOTS_DESC = "Forever++ 페이지와 게시물에 쓸 수 있도록, 게임 자체 창에 표시된 Forever++의 스크린샷을 "
    .. "차례로 찍습니다."

-- Controller Mode
L.CONTROLLERMODE_TITLE = "게임패드 모드"
L.CONTROLLERMODE_DESC = "게임패드 인터페이스용과 키보드 및 마우스용 설정을 따로 둡니다. 각각 Forever++ 프로필, 편집 "
    .. "모드 구성, 애드온 세트입니다. 다른 인터페이스로 접속하면 그 설정으로 전환합니다."
L.CONTROLLERMODE_NOTE = "인터페이스마다 쓸 것을 고르십시오. 이 캐릭터가 다른 인터페이스로 접속하면 Forever++가 그 "
    .. "프로필과 편집 모드 구성으로 전환하며, 불러온 애드온이 그 세트와 다를 때만 UI 재시작을 묻습니다. 직접 바꾼 "
    .. "내용은 인터페이스가 다시 바뀔 때까지 유지됩니다. 이 선택은 모든 프로필이 함께 쓰며, 여기서 고른 프로필에서는 "
    .. "'게임패드 모드'가 켜집니다."
L.CONTROLLERMODE_NOW = "게임이 현재 표시 중인 인터페이스: %s" -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_GAMEPAD = "게임패드"
L.CONTROLLERMODE_MKB = "키보드 및 마우스"
L.CONTROLLERMODE_NO_CHANGE = "바꾸지 않음"
L.CONTROLLERMODE_PROFILE = "Forever++ 프로필"
L.CONTROLLERMODE_PROFILE_DESC = "이 인터페이스에서 이 캐릭터가 전환할 프로필입니다."
L.CONTROLLERMODE_LAYOUT = "편집 모드 구성"
L.CONTROLLERMODE_LAYOUT_DESC = "이 인터페이스에서 쓸 편집 모드 구성입니다. 게임은 구성을 만든 인터페이스에서만 그 "
    .. "구성을 보여 줍니다."
L.CONTROLLERMODE_ADDONS_NONE = "바꾸지 않음"
L.CONTROLLERMODE_ADDONS_SAVED = "애드온 %d개 켜짐" -- number of addons
L.CONTROLLERMODE_ADDONS_SAVE = "현재 상태 사용"
L.CONTROLLERMODE_ADDONS_SAVE_DESC = "이 캐릭터가 지금 켜 둔 애드온을 이 인터페이스의 세트로 저장합니다. 나중에 설치한 "
    .. "애드온은 다시 저장할 때까지 그대로 둡니다."
L.CONTROLLERMODE_ADDONS_CLEAR = "지우기"
L.CONTROLLERMODE_ADDONS_CLEAR_DESC = "이 인터페이스의 세트를 지워, 애드온을 그대로 둡니다."
L.CONTROLLERMODE_APPLY = "지금 적용"
L.CONTROLLERMODE_APPLY_DESC = "게임이 지금 표시 중인 인터페이스의 설정으로 전환합니다."
L.CONTROLLERMODE_NOTHING = "%s: 바꿀 것이 없습니다." -- Controller, or Keyboard and Mouse
L.CONTROLLERMODE_RELOAD = "Forever++ 게임패드 모드: 켜진 애드온이 %s용으로 저장한 세트와 다릅니다." -- interface
L.CONTROLLERMODE_RELOAD_ON = "켜기: %s" -- addon names
L.CONTROLLERMODE_RELOAD_OFF = "끄기: %s" -- addon names
L.CONTROLLERMODE_RELOAD_ASK = "바꾸고 지금 UI를 재시작하시겠습니까?"
L.CONTROLLERMODE_AND_MORE = "%s 외 %d개" -- addon names, number of addons

-- Taint Watcher
L.TAINTWATCHER_TITLE = "오염 감시"
L.TAINTWATCHER_DESC = "퀘스트 추적기, 퀘스트 목록, 세계 지도, 게임의 창 목록에 애드온이 써 넣은 값을 감시합니다. 이런 "
    .. "값 때문에 나중에 게임이 \"애드온으로 인해 인터페이스 작동이 실패했습니다.\"라고 알립니다. 찾은 값은 "
    .. "시각과 함께 '오류 수집기'와 /fpp taint에 나열됩니다. 무엇이 문제를 일으켰는지 찾을 때 씁니다."
-- Profiler
L.PROFILER_TITLE = "CPU 프로파일러"
L.PROFILER_DESC = "설정의 한 페이지에서 각 모듈이 CPU를 얼마나 쓰는지 보고, 무엇이 느린지 찾습니다."

-- Gear Probe
L.GEARPROBE_TITLE = "장비 조사"
L.GEARPROBE_DESC = "'업그레이드 화살표' 작업을 위해, 이 클라이언트가 장비, 특성 탭, 능력치에 대해 알려 주는 내용을 "
    .. "읽습니다."
