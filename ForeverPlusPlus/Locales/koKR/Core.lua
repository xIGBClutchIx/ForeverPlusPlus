local _, ns = ...
local L = ns.NewLocale("koKR")
if not L then
    return
end

-- Lib/Text.lua: lengths of time, for slider labels and price lines
L.TEXT_SECONDS = { "%d초" }
L.TEXT_MINUTES = { "%d분" }
L.TEXT_HOURS = { "%d시간" }
L.TEXT_AGO_NOW = "방금"
L.TEXT_AGO_MINUTES = "%d분 전" -- minutes
L.TEXT_AGO_HOURS = "%d시간 전" -- hours
L.TEXT_AGO_DAYS = "%d일 전" -- days
L.TEXT_YARDS = "%s미터" -- a distance; the game's own words are used when it has them
L.SLIDER_YARDS = "%d미터" -- a slider's value in yards, worded like TEXT_YARDS

-- Lib/ItemStats.lua: an Equip: bonus written as a plain stat, an amount and the stat's name
L.ITEMSTATS_SHORT = "+%s %s"
L.ITEMSTATS_SHORT_PERCENT = "+%s%% %s"
L.ITEMSTATS_SHORT_AND = "%s 및 %s" -- two short stats of one line

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
L.KEY_NONE = "없음"
-- Added to a key dropdown's description with the controller interface on; each %s is a trigger
-- as the player's controller shows it
L.KEY_PAD_NOTE = "게임패드 인터페이스를 켠 상태에서는 대신 %s 또는 %s 버튼을 누르고 있으십시오."
L.SKIP_KEY = "건너뛰기 키" -- the option of every module that a held key skips

-- Lib/MapPins.lua: icons on the world map.
L.MAPPINS_HINT_WAYPOINT = "<지도 핀을 설정하려면 Ctrl 클릭>"
-- The options of icons on the world map: their size, opacity, and whether continent maps show
-- them, the same in every module that has them.
L.MAPPINS_SIZE = "아이콘 크기"
L.MAPPINS_SIZE_DESC = "기본 크기에 대한 아이콘의 크기입니다."
L.MAPPINS_OPACITY = "투명도"
L.MAPPINS_OPACITY_DESC = "아이콘이 얼마나 불투명한지 정합니다. 낮을수록 지도가 비쳐 보입니다."
L.MAPPINS_CONTINENTS = "대륙 지도에도"
L.MAPPINS_CONTINENTS_DESC = "지역 지도뿐 아니라 대륙 지도와 세계 지도에도 표시합니다."
-- Lib/Sounds.lua: the alert sounds, in every Sound dropdown
L.SOUND_NAME = "소리"
L.SOUND_OFF = "끄기"
L.SOUND_BUZZ = "오류 버저음"
L.SOUND_DENIED = "거부"
L.SOUND_HORN = "전쟁 뿔피리"
L.SOUND_BOSS = "우두머리 경고"
L.SOUND_GM = "GM 알림"
L.SOUND_ALARM = "알람 시계"
L.SOUND_WHISPER = "귓속말"

-- Core: /fpp and chat
L.ON = "켜짐"
L.OFF = "꺼짐"
L.MODULE_STATE = "%s: %s." -- module name, on/off
L.MODULE_ALWAYS_ON = "%s: 도구이므로 항상 켜져 있습니다." -- module title, such as Self Test
L.NO_MODULE = "%s 모듈이 없습니다"
L.COMMAND_NEEDS_MODULE = "/fpp %s 명령어에는 '%s' 모듈이 필요하지만, 모듈 페이지에서 꺼져 있습니다." -- command, title
L.SLASH_MODULES = "모듈 (/fpp toggle <name>, /fpp list):"
L.SLASH_OPEN = "설정 열기"
L.SLASH_LIST = "모듈 목록과 각 모듈이 켜져 있는지 표시"
L.SLASH_TOGGLE = "모듈이나 모듈의 체크박스 하나를 켜거나 끄기"
L.SLASH_RESET = "모든 설정을 기본값으로 (UI 재시작)"
L.RESET_CONFIRM = "Forever++의 모든 설정을 기본값으로 되돌리고, 경매 가격과 비행 시간처럼 저장한 모든 "
    .. "데이터를 지우시겠습니까? UI를 재시작합니다."
L.SLASH_OPTIONS = "옵션과 현재 값 목록 표시"
L.SLASH_SET = "옵션 하나 변경 (on/off, 선택지, 또는 숫자)"
L.SLASH_TAKEN = "%s 명령어는 이미 다른 애드온이 사용하고 있으므로, Forever++는 그 애드온에 맡깁니다."

-- Core: /fpp options and /fpp set. The values typed (on, off, choice keys) stay as they are.
L.OPTIONS_HEADER = "%s: %s. 옵션 (/fpp set %s <option> <value>):" -- module, on/off, module
L.OPTIONS_NONE = "없음"
L.OPTIONS_DEBUG = ", 디버그"
L.SET_USAGE = "사용법: /fpp set <module> <option> [value]"
L.MODULE_STATE_ALLOWED = "%s: %s (on, off)." -- module name, on/off
L.NO_OPTION = "%s 모듈에는 %s 옵션이 없습니다. /fpp options %s 명령어로 목록을 볼 수 있습니다." -- module, option, module
L.OPTION_STATE = "%s %s: %s." -- module, option, value
L.OPTION_STATE_ALLOWED = "%s %s: |cffffd100%s|r (%s)." -- module, option, value, allowed values
L.CHAT_MESSAGES = "대화창 메시지" -- a module's checkbox for what it says in chat by itself

-- Lib/Profiles.lua: profiles, and /fpp profiles
L.PROFILES_DEFAULT = "기본" -- the profile everyone starts with, which is always there
L.PROFILES_NAME_EMPTY = "프로필에는 이름이 필요합니다."
L.PROFILES_NAME_TAKEN = "이미 '%s' 프로필이 있습니다." -- name
L.PROFILES_DEFAULT_ALWAYS = "'기본' 프로필은 항상 있으므로 이름을 바꾸거나 삭제할 수 없습니다."
L.SLASH_PROFILE = "프로필 목록 표시, 또는 이 캐릭터를 다른 프로필로 전환"
L.PROFILES_HEADER = "프로필 (전환: /fpp profiles <name>):"
L.PROFILES_CHARACTERS = { "캐릭터 %d명" } -- how many use a profile
L.PROFILES_SWITCHED = "이제 '%s' 프로필을 사용합니다." -- profile name
L.PROFILES_AFTER_COMBAT = "전투가 끝나면 '%s' 프로필로 전환합니다." -- profile name
L.PROFILES_NO_SUCH = "'%s' 프로필이 없습니다. /fpp profiles 명령어로 목록을 볼 수 있습니다." -- what was typed

-- Settings
-- The Modules page's groups of modules.
L.CATEGORY_AUTOMATION = "자동화"
L.CATEGORY_CHARACTER = "캐릭터"
L.CATEGORY_CHAT = "대화"
L.CATEGORY_INTERFACE = "인터페이스"
L.CATEGORY_ITEMS = "아이템"
L.CATEGORY_MAP = "지도"
L.CATEGORY_QUESTS = "퀘스트"
L.CATEGORY_SYSTEM = "시스템"
L.CATEGORY_UNITS = "개체" -- unit frames and nameplates
L.CATEGORY_OTHER = "기타"
L.DEBUG = "디버그"
L.SETTINGS_AFTER_COMBAT = "전투가 끝나면 설정이 열립니다."
L.MODULES = "모듈" -- the page with every module's checkbox, the top Forever++ entry
L.ABOUT = "정보" -- the page with the version, links, credits, and commands
-- The selected module on the Modules page
L.SETTINGS_ENABLED = "사용함" -- the module's own on/off checkbox, under its description
-- What a greyed-out option needs (`needs`), in red in its tooltip: an addon's or module's name
L.SETTINGS_NEEDS_ADDON = "%s 애드온이 필요합니다."
L.SETTINGS_NEEDS_MODULE = "%s 모듈을 켜야 합니다."
L.SETTINGS_NEEDS_CLIENT = "이 버전의 게임에는 필요한 기능이 없습니다."
-- A notice on a module whose Blizzard frame the controller interface hides (ns.Gamepad.HidesNotice).
L.SETTINGS_CONTROLLER_HIDDEN = "게임패드 인터페이스에서는 효과 없음"
L.SETTINGS_CONTROLLER_HIDDEN_DESC = "게임패드 인터페이스는 이 모듈이 바꾸는 부분을 숨기고 자체 화면을 대신 "
    .. "보여 주므로, 게임패드 인터페이스가 켜져 있는 동안에는 이 모듈이 아무것도 하지 않습니다."
-- And on one that needs a mouse, a held key, or a window its cursor can't reach (LimitedNotice).
L.SETTINGS_CONTROLLER_LIMITED = "게임패드 인터페이스에서는 일부 제한"
L.SETTINGS_CONTROLLER_LIMITED_DESC = "이 모듈의 일부 또는 전부는 마우스 클릭, 끌기, 키 누르고 있기, 또는 "
    .. "게임패드 커서가 닿지 않는 창이 필요하므로, 게임패드 인터페이스가 켜져 있는 동안에는 작동하지 "
    .. "않습니다."
-- An option XP Bar Text and Reputation Bar Text share (Lib/StatusBars.lua)
L.STATUSBARS_SOLID = "구분선 없는 막대"
L.STATUSBARS_SOLID_DESC = "막대의 구분선을 없애 하나로 이어진 막대로 만듭니다."
-- The tooltip of the padlock in a locked module's checkbox's place
L.SETTINGS_LOCKED = "꺼짐 및 잠김: 게임이 바뀌어 이 모듈의 기능이 작동하지 않습니다. 자세한 내용은 설정에 "
    .. "있습니다."
L.SETTINGS_OPTIONS = "설정" -- the header over its options
L.SETTINGS_NO_OPTIONS = "이 모듈에는 설정이 없습니다."
L.SETTINGS_CONFLICT_GO = "'%s' 설정으로 이동" -- an option's name
-- A mark on an item or action button icon (Lib/ItemButtons.lua): its corner, size, and padding,
-- the same in every module that has one.
L.ICONMARK_CORNER = "모서리"
L.ICONMARK_CORNER_TOPLEFT = "왼쪽 위"
L.ICONMARK_CORNER_TOPRIGHT = "오른쪽 위"
L.ICONMARK_CORNER_BOTTOMLEFT = "왼쪽 아래"
L.ICONMARK_CORNER_BOTTOMRIGHT = "오른쪽 아래"
L.ICONMARK_PIXELS = "%d픽셀" -- a size or padding slider's value
L.ICONMARK_PADDING = "여백"
L.ICONMARK_PADDING_DESC = "표시가 모서리에서 얼마나 안쪽에 놓일지 정합니다. 2로 설정하면 왼쪽 위의 표시가 "
    .. "오른쪽으로 2픽셀, 아래로 2픽셀 이동합니다."
-- Under a mark's Corner option while Upgrade Arrows has an arrow in the same corner
L.ICONMARK_CONFLICT_ARROW = "'업그레이드 화살표'도 이 모서리에 화살표를 표시하므로 둘이 겹칩니다. 둘 중 하나의 "
    .. "모서리를 바꾸십시오."
L.ICONMARK_CONFLICT_DOWN = "'업그레이드 화살표'도 이 모서리에 하향 화살표를 표시하므로 둘이 겹칩니다. 둘 중 "
    .. "하나의 모서리를 바꾸십시오."
L.ICONMARK_SECTION_SHOW = "표시 위치" -- the header over the places a module marks items in
L.ICONMARK_PLACE_BAGS = "가방"
L.ICONMARK_PLACE_MERCHANT = "상인"
L.ICONMARK_PLACE_AUCTION = "경매장"
L.ICONMARK_PLACE_LOOT = "전리품"
L.ICONMARK_PLACE_QUESTS = "퀘스트 보상"
L.SETTINGS_PAGE_NOTE = "켜져 있는 동안 사이드바의 Forever++ 아래에 '%s' 페이지가 있습니다. 그 페이지는 다른 "
    .. "페이지를 고르면 나타나거나 사라집니다."
L.SETTINGS_TURN_ON = "켜기" -- the button on a "Blizzard's ... is off" row
L.SETTINGS_RESET = "기본값 복원" -- the arrow at the end of an option's row while it's changed
L.SETTINGS_RESET_TO = "기본값: %s" -- what the option goes back to
L.SETTINGS_RESET_PAIR = "%s, %s" -- a checkbox's default, then its slider's, in one row
L.SETTINGS_CHECKED = "선택" -- a checkbox's default
L.SETTINGS_UNCHECKED = "선택 안 함"
L.SETTINGS_SEARCH = "모듈 검색" -- gray text in the Modules page's empty search box
L.SETTINGS_NO_MATCH = "\"%s\"에 해당하는 모듈이 없습니다." -- the search text
L.SETTINGS_NEW_ONLY = "신규" -- the checkbox beside the search box that lists only modules marked NEW
L.SETTINGS_NOTHING_NEW = "새로운 항목이 없습니다." -- the Modules list while that checkbox is on and nothing is new

-- Settings: the Profiles page
L.PROFILES = "프로필"
L.PROFILES_USES = "%s의 프로필" -- a character's name, before the dropdown of its profile
L.PROFILES_USES_TITLE = "이 캐릭터의 프로필"
L.PROFILES_USES_DESC = "%s 캐릭터가 사용하는 프로필입니다. Forever++에서 바꾼 내용은 이 프로필에 저장되며, "
    .. "이 프로필을 사용하는 모든 캐릭터에 적용됩니다." -- character
L.PROFILES_NEW_CHARACTERS = "새 캐릭터용 프로필"
L.PROFILES_NEW_CHARACTERS_DESC = "캐릭터가 처음 접속할 때 사용할 프로필입니다."
L.PROFILES_NEW = "새 프로필"
L.PROFILES_NEW_DESC = "선택한 프로필을 복사하거나, 기본값에서, 또는 %s에서 프로필을 새로 만듭니다." -- a preset's name, or PRESETS_A_PRESET
L.PROFILES_NEW_ASK = "새 프로필의 이름을 입력하십시오."
L.PROFILES_NEW_FROM = "'%s' 프로필을 '%s' 프로필의 복사본으로, 기본값에서, 또는 %s에서 만드시겠습니까?" -- new name, selected profile, a preset's name or PRESETS_A_PRESET
L.PROFILES_PRESET = "기반" -- beside the dropdown of the preset a profile follows
L.PROFILES_PRESET_NONE = "없음" -- a profile based on no preset
L.PROFILES_PRESET_DESC = "'%s' 프로필이 따르는 프리셋입니다. 직접 정하지 않은 설정은 프리셋의 값을 읽으므로 "
    .. "이후 버전에서 프리셋이 바뀌면 함께 바뀌며, 되돌리기 화살표는 설정을 프리셋의 값으로 되돌립니다. "
    .. "프리셋을 골라도 직접 정한 설정은 모두 유지됩니다. '없음'을 고르면 프로필의 현재 내용을 직접 정한 "
    .. "설정으로 남기고 더 이상 프리셋을 따르지 않습니다." -- profile
L.PROFILES_PRESET_AFTER_COMBAT = "전투가 끝나면 '%s' 프로필의 기반을 바꿉니다." -- profile
L.PRESETS_A_PRESET = "프리셋" -- in PROFILES_NEW_DESC and PROFILES_NEW_FROM, with more than one
L.PRESETS_MORE = "프리셋..." -- a popup button that opens a menu of every preset
L.PRESETS_NO_SUCH = "'%s' 프리셋이 없습니다." -- what was asked for
L.PRESETS_DEVELOPER_DESC = "기본값에 개발자가 사용하는 모듈과 옵션을 더한 설정입니다."
L.PROFILES_COPY_OF = "%s 복사본" -- a profile
L.PROFILES_FROM_DEFAULTS = "기본값에서"
L.PROFILES_IN_USE = "이 캐릭터가 사용 중"
L.PROFILES_SUMMARY = "모듈 %d개 켜짐, 기본값에서 바뀐 설정 %d개."
L.PROFILES_USED_BY = "사용 캐릭터: %s." -- character names
L.PROFILES_UNUSED = "사용하는 캐릭터가 없습니다."
L.PROFILES_USE = "이 캐릭터에 사용"
L.PROFILES_USE_DESC = "%s 캐릭터를 UI 재시작 없이 바로 '%s' 프로필로 전환합니다." -- character, profile
L.PROFILES_RENAME = "이름 변경"
L.PROFILES_RENAME_DESC = "'%s' 프로필의 이름을 바꿉니다." -- profile
L.PROFILES_RENAME_ASK = "'%s' 프로필의 새 이름:" -- profile
L.PROFILES_DELETE = "삭제"
L.PROFILES_DELETE_DESC = "'%s' 프로필을 삭제합니다. 이 프로필을 사용하던 캐릭터는 '기본'으로 돌아갑니다." -- profile
L.PROFILES_DELETE_ASK = "'%s' 프로필을 삭제하시겠습니까? 이 프로필을 사용하던 캐릭터는 '기본'으로 "
    .. "돌아갑니다." -- profile
L.PROFILES_CHARACTERS_HEADER = "캐릭터"
L.PROFILES_CHARACTER_LINE = "레벨 %d %s" -- level, class
L.PROFILES_THIS_CHARACTER = "이 캐릭터"
L.PROFILES_USES_OTHER = "사용 중: %s" -- the profile another character uses
L.PROFILES_CHECK_DESC = "선택하면 %s 캐릭터가 '%s' 프로필을 사용합니다." -- character, profile
L.PROFILES_UNCHECK_DESC = "선택을 해제하면 %s 캐릭터가 '기본'으로 돌아갑니다." -- character
L.PROFILES_ON_DEFAULT_DESC = "모든 캐릭터는 프로필을 하나씩 사용합니다. %s 캐릭터를 '기본'에서 옮기려면 "
    .. "다른 프로필에서 선택하십시오." -- character
L.PROFILES_FORGET_HINT = "이 캐릭터를 목록에서 지우려면 오른쪽 클릭하십시오."
L.PROFILES_FORGET_ASK = "%s 캐릭터를 목록에서 지우시겠습니까? 다시 접속할 때까지 이 목록에서 사라집니다." -- character
L.PROFILES_NOTE = "프로필에는 켜 둔 모듈과 그 설정, 편집 모드에서 옮긴 Forever++ 개체창과 '창 이동'으로 옮긴 "
    .. "창의 위치, 미니맵 버튼의 빠른 전환이 담깁니다. 경매 가격, 채집 지점, 만난 플레이어, 특성 계획처럼 "
    .. "캐릭터마다 따로 보관하는 내용은 포함되지 않습니다."
L.PROFILES_SHARE = "공유"
L.PROFILES_EXPORT = "내보내기"
L.PROFILES_EXPORT_DESC = "'%s' 프로필을 한 줄의 텍스트로 보여 줍니다. 복사해서 다른 사람에게 보내거나 백업으로 "
    .. "보관할 수 있습니다." -- profile
L.PROFILES_EXPORT_ASK = "'%s' 프로필 텍스트입니다. Ctrl+C로 복사해서 다른 사람에게 보내거나 백업으로 "
    .. "보관하십시오." -- profile
L.PROFILES_IMPORT = "가져오기"
L.PROFILES_IMPORT_DESC = "다른 사람이 내보낸 프로필을 붙여 넣어 새 프로필로 만들거나 '%s' 프로필을 덮어씁니다." -- profile
L.PROFILES_IMPORT_ASK = "다른 사람이 내보낸 프로필을 Ctrl+V로 붙여 넣으십시오."
-- What the pasted text holds: name, Forever++ version, modules on, settings changed
L.PROFILES_IMPORT_FOUND = "%s, Forever++ %s 버전에서 만듦.\n모듈 %d개 켜짐, 기본값에서 바뀐 설정 %d개."
L.PROFILES_IMPORT_NEW = "새 프로필로 가져오기"
L.PROFILES_IMPORT_REPLACE = "'%s' 덮어쓰기" -- the selected profile
L.PROFILES_IMPORT_BAD = "Forever++ 프로필이 아닙니다. 한 줄 전체를 복사해서 다시 붙여 넣으십시오."
L.PROFILES_IMPORT_CANT = "이 클라이언트는 압축된 프로필을 읽을 수 없습니다."
L.PROFILES_IMPORT_NEWER = "더 새로운 Forever++에서 만든 프로필입니다. 업데이트한 뒤 가져오십시오."
L.PROFILES_IMPORTED = "가져온 프로필" -- the name of an import whose own name is empty
L.PROFILES_IMPORT_DONE = "'%s' 프로필을 가져왔습니다." -- profile
L.PROFILES_MODULES_NOTE = "프로필: %s" -- beside the Modules page's title, with more than one
L.DEFAULTS_ASK_PROFILE = "'%s' 프로필의 Forever++ 설정을 기본값으로 되돌리시겠습니까? 이 프로필을 사용하는 "
    .. "모든 캐릭터도 함께 바뀝니다. 게임의 다른 설정은 그대로 유지됩니다." -- profile

-- Settings: Changelog page. The notes themselves are in Changelog.lua.
L.CHANGELOG = "변경 내역"
L.CHANGELOG_RELEASE = "%s (%s)" -- version, date
L.CHANGELOG_UNRELEASED = "출시 전"
L.CHANGELOG_SEARCH = "변경 사항 검색" -- gray text in the Changelog page's empty search box
L.CHANGELOG_BY_MODULE = "모듈별" -- checkbox that groups a release's notes under their modules
L.CHANGELOG_GENERAL = "일반" -- heading, with By Module on, for notes about no one module
L.CHANGELOG_NO_MATCH = "\"%s\"에 해당하는 변경 사항이 없습니다." -- the search text
L.CHANGELOG_CHANGES = { "변경 사항 %d개" } -- how many entries a release has
L.CHANGELOG_ADDED = "추가"
L.CHANGELOG_CHANGED = "변경"
L.CHANGELOG_FIXED = "수정"
L.CHANGELOG_REMOVED = "제거"
L.CHANGELOG_CONTROLLER = "게임패드 인터페이스"
L.CHANGELOG_SETTINGS = "설정"
L.CHANGELOG_COMMANDS = "명령어"

-- Settings: the About page
L.HOME_TAGLINE = "WoW Forever의 기본 UI에 더하는 작은 기능과 변경 사항입니다."
L.HOME_DEFAULTS = "기본 설정"
-- The popup of the Defaults button at the top right of the Modules, Changelog, and About pages
L.DEFAULTS_ASK = "Forever++의 모든 설정을 기본값으로 되돌리시겠습니까? 현재 Forever++ 설정을 대체합니다. "
    .. "게임의 다른 설정은 그대로 유지됩니다."
L.DEFAULTS_DEVELOPER = "개발자 기본 설정"
L.DEFAULTS_RECOMMENDED = "권장 기본 설정"
L.HOME_MODULES_ON = "모듈 %d/%d개 켜짐" -- on, total
L.HOME_GAME_BUILD = "게임 %s (%s)" -- version, build
-- The Language dropdown on the About page. A language's own name is never translated (Core.lua).
L.LANGUAGE = "언어"
L.LANGUAGE_CLIENT = "게임 클라이언트: %s" -- the client's language, as the dropdown names it
L.LANGUAGE_DESC = "Forever++의 문구에 사용할 언어입니다. '게임 클라이언트'는 게임의 언어를 따릅니다. 변경하면 UI를 "
    .. "재시작합니다."
L.LANGUAGE_WARNING = "게임 클라이언트와 다른 언어는 일부 화면에서 제대로 표시되지 않을 수 있습니다. 글자가 네모로 "
    .. "보일 수 있으며, Forever++에 표시되는 게임 고유 용어는 영어로 남습니다."
L.LANGUAGE_RELOAD = "Forever++를 다음 언어로 표시하시겠습니까? %s\n변경하면 UI를 재시작합니다." -- the language's name
L.HOME_LINKS = "링크"
L.HOME_LINK_CURSEFORGE = "CurseForge"
L.HOME_LINK_WAGO = "Wago"
L.HOME_LINK_SOURCE = "소스 코드"
L.HOME_LINK_RELEASES = "릴리스"
L.HOME_LINK_BUG = "버그 신고"
L.HOME_LINK_REQUEST = "기능 요청"
L.HOME_LINK_HINT = "하나를 클릭하면 복사할 링크가 나옵니다."
L.HOME_COPY = "Ctrl+C를 눌러 링크를 복사하십시오."
L.HOME_CREDITS = "제작진"
L.HOME_AUTHOR = "제작자"
L.HOME_EVERYONE = "모두" -- the last name in the credits: the players
L.HOME_EVERYONE_THANKS = "끊임없이 버그를 신고하고, 기능을 요청하고, 의견을 보내 주셔서 감사합니다."
L.HOME_WORKS_WITH = "함께 쓰는 애드온"
L.HOME_QUEST_DATA = "%s의 퀘스트 데이터" -- the modules that read QuestieDB
L.HOME_SUPPORT = "%s 추가 지원" -- the module or option another addon adds to
L.HOME_COMMANDS = "명령어"
L.HOME_COMMANDS_GENERAL = "일반" -- the commands no one module owns
L.HOME_COMMANDS_SEARCH = "검색"
L.HOME_COMMANDS_HINT = "<대화창에 명령어를 입력하려면 클릭>"

-- Edit Mode dialog for our own frames (Lib/EditMode.lua)
L.EDITMODE_SCALE = "크기"
L.SETTINGS_EDIT_MODE_NOTE = "위치와 배치는 편집 모드에서 정합니다. Esc를 누르고 편집 모드를 고른 뒤 이 개체창을 "
    .. "클릭하십시오." -- a gray row on a module with Edit Mode settings
L.SETTINGS_EDIT_MODE_NOTE_DESC = "위치, 크기, 배치 설정은 편집 모드의 대화 상자와 그곳의 오른쪽 클릭 메뉴에서, "
    .. "바꿀 개체창 바로 옆에 있습니다."

-- The gray row on a module another addon adds (Lib/Plugins.lua)
L.PLUGIN_NOTICE = "다른 애드온이 추가한 모듈입니다."
L.PLUGIN_NOTICE_ADDON = "%s 애드온이 추가한 모듈입니다." -- the addon's folder name
L.PLUGIN_NOTICE_DESC = "이 모듈은 Forever++의 일부가 아니며, 다른 애드온이 여기에 추가한 것입니다. 문제가 "
    .. "있으면 그 애드온의 제작자에게 알리십시오."
-- Gray rows on a module that reads the QuestieDB addon's data (Lib/QuestieDB.lua)
L.QUESTIEDB_NEEDED = "QuestieDB 애드온이 필요합니다."
L.QUESTIEDB_NEEDED_DESC = "이 모듈의 퀘스트, 생물, 아이템, 물체 데이터는 별도의 애드온인 QuestieDB에서 "
    .. "가져옵니다. 내려받아 설치하고 애드온 목록에서 켠 뒤 UI를 재시작하십시오. 그 전까지는 이 모듈을 켤 "
    .. "수 없습니다."
L.QUESTIEDB_LOCKED = "잠김: 이 모듈에는 QuestieDB 애드온이 필요합니다. 내려받은 뒤 UI를 재시작하십시오."
L.QUESTIEDB_PROBLEM = "이 버전의 QuestieDB는 Forever++와 맞지 않습니다."
L.QUESTIEDB_PROBLEM_DESC = "QuestieDB가 켜져 있지만 Forever++가 읽는 방식대로 응답하지 않습니다. 둘 중 더 "
    .. "오래된 쪽을 업데이트하십시오."
