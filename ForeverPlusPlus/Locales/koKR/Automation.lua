local _, ns = ...
local L = ns.NewLocale("koKR")
if not L then
    return
end

-- FastLoot
L.FASTLOOT_TITLE = "빠른 전리품 획득"
L.FASTLOOT_DESC = "자동 전리품 획득이 켜져 있을 때 전리품창을 기다리지 않고 한 번에 모두 가져옵니다."
L.FASTLOOT_BLIZZARD_OFF = "블리자드 자동 전리품 획득이 꺼져 있습니다" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "블리자드 자동 전리품 획득이 꺼져 있어, 자동 전리품 획득 키(Shift)를 누른 "
    .. "채 가져오는 전리품만 빠르게 획득합니다."

-- AutoRepair
L.AUTOREPAIR_TITLE = "자동 수리"
L.AUTOREPAIR_DESC = "수리할 수 있는 상인과 대화하면 모든 장비를 수리하고 비용을 대화창에 알립니다. 건너뛰려면 "
    .. "건너뛰기 키를 누르고 있으십시오."
L.AUTOREPAIR_FUNDS = "지불 방법"
L.AUTOREPAIR_FUNDS_DESC = "수리 비용을 누구의 돈으로 낼지 정합니다."
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "길드 은행 먼저, 다음 내 돈"
L.AUTOREPAIR_FUNDS_GUILD = "길드 은행만"
L.AUTOREPAIR_FUNDS_OWN = "내 돈만"
L.AUTOREPAIR_MIN_COST = "최소 비용"
L.AUTOREPAIR_MIN_COST_DESC = "비용이 이 금액 이상일 때만 수리하여, 상인에게 잠깐 들를 때마다 동화 몇 닢씩 쓰지 "
    .. "않게 합니다."
L.AUTOREPAIR_MIN_COST_ANY = "금액 무관"
L.AUTOREPAIR_KEY_DESC = "상인과 대화할 때 이 키를 누르고 있으면 장비를 수리하지 않습니다."
L.AUTOREPAIR_CHAT_DESC = "수리 비용이나 비용을 낼 수 없었던 이유를 대화창에 알립니다."
L.AUTOREPAIR_REPAIRED = "수리 비용: %s." -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "길드 은행에서 수리 비용을 냈습니다: %s." -- cost
L.AUTOREPAIR_NO_MONEY = "수리할 돈이 부족합니다 (%s)." -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "길드 은행으로 수리 비용을 낼 수 없습니다 (%s)." -- cost

-- AutoOpen
L.AUTOOPEN_TITLE = "자동 상자 열기"
L.AUTOOPEN_DESC = "가방에 있는 대합, 자루, 잠금이 풀린 금고 같은 용기를 저절로 엽니다. 전투, 은신, "
    .. "시전 중이거나 전리품, 상인, 우편, 은행, 거래, 경매 창이 열려 있으면 끝날 때까지 기다립니다."
L.AUTOOPEN_FREE_SLOTS = "빈 가방 칸 유지"
L.AUTOOPEN_FREE_SLOTS_DESC = "빈 가방 칸이 이 수보다 적으면 아무것도 열지 않아, 안에 든 물건이 들어갈 자리를 "
    .. "남겨 둡니다."
L.AUTOOPEN_SPECIAL = "특별한 용기도 열기"
L.AUTOOPEN_SPECIAL_DESC = "보통은 직접 결정하도록 남겨 두는 몇몇 용기도 엽니다. 공격대와 필드 우두머리의 보석 "
    .. "자루, 명절 선물, 그리고 퀘스트 아이템이나 제조법, 장비가 든 궤짝과 상자입니다."
L.AUTOOPEN_PICK_LOCKS = "오른쪽 클릭으로 자물쇠 따기"
L.AUTOOPEN_PICK_LOCKS_DESC = "가방에서 잠긴 금고를 오른쪽 클릭하면 자물쇠 따기를 시전하고, 이어서 "
    .. "엽니다."
L.AUTOOPEN_CHAT_DESC = "무엇을 열었는지 대화창에 알립니다."
L.AUTOOPEN_OPENED = "열었습니다: %s." -- one or more item links, each maybe with a count
L.AUTOOPEN_COUNT = "%s x%d" -- item link, how many
-- AutoSellJunk
L.AUTOSELLJUNK_TITLE = "자동 잡동사니 판매"
L.AUTOSELLJUNK_DESC = "상인과 대화하면 가방에 있는 회색 아이템을 팔고, 판매 금액을 대화창에 알립니다. "
    .. "건너뛰려면 건너뛰기 키를 누르고 있으십시오."
L.AUTOSELLJUNK_BUYBACK = "모두 재매입 가능하게"
L.AUTOSELLJUNK_BUYBACK_DESC = "직접 판 아이템 외에 상인의 재매입 목록에 남은 자리만큼만 잡동사니를 팔아, 실수로 "
    .. "판 물건도 다시 살 수 있게 합니다."
L.AUTOSELLJUNK_KEY_DESC = "상인과 대화할 때 이 키를 누르고 있으면 잡동사니를 팔지 않습니다."
L.AUTOSELLJUNK_CHAT_DESC = "판 아이템의 개수와 판매 금액, 그리고 재매입 목록이 가득 차서 팔지 못한 개수를 "
    .. "대화창에 알립니다."
-- count, money; the forms go by the count
L.AUTOSELLJUNK_SOLD = { "잡동사니 %d개를 %s에 팔았습니다." }
-- count, money, how many were left; the forms go by the first count
L.AUTOSELLJUNK_SOLD_FULL = {
    "잡동사니 %d개를 %s에 팔았습니다. 재매입 목록이 가득 찼습니다: %d개는 팔지 않았습니다.",
}
L.AUTOSELLJUNK_FULL = { -- count
    "재매입 목록이 가득 찼습니다: 잡동사니 %d개는 팔지 않았습니다.",
}

-- GatheringTracking
L.GATHERINGTRACKING_TITLE = "채집 추적"
L.GATHERINGTRACKING_DESC = "광물 찾기나 약초 찾기를 켜 둡니다. 접속하거나, 지역을 이동하거나, 죽은 뒤에 다시 "
    .. "켜고, 원하면 둘을 번갈아 씁니다. 드워프는 보물 찾기를 더할 수 있습니다."
L.GATHERINGTRACKING_TRACK = "추적"
L.GATHERINGTRACKING_TRACK_DESC = "켜 둘 추적입니다. 게임은 한 번에 하나만 추적하므로 둘을 고르면 번갈아 "
    .. "켭니다."
L.GATHERINGTRACKING_TRACK_BOTH = "광물과 약초"
L.GATHERINGTRACKING_TRACK_MINERALS = "광물만"
L.GATHERINGTRACKING_TRACK_HERBS = "약초만"
L.GATHERINGTRACKING_REAPPLY = "다시 켜기"
L.GATHERINGTRACKING_REAPPLY_DESC = "접속하거나, 지역을 이동하거나, 되살아난 뒤 아무것도 추적하고 있지 않으면 "
    .. "추적을 다시 켭니다. 마지막에 야수 추적 같은 다른 추적 주문이 켜져 있었다면 그것을, 아니면 여기서 "
    .. "고른 추적을 켭니다. 직접 끄면 그때까지는 꺼진 채로 둡니다."
L.GATHERINGTRACKING_TREASURE = "보물 찾기"
L.GATHERINGTRACKING_TREASURE_DESC = "드워프의 보물 찾기도 켜 둡니다. 위에서 고른 추적과 번갈아 켜며, 둘 다 "
    .. "모르면 보물 찾기만 켜 둡니다."
L.GATHERINGTRACKING_SWAP = "번갈아 켜기"
L.GATHERINGTRACKING_SWAP_DESC = "고른 추적 중 하나가 켜져 있는 동안 둘을 번갈아 켭니다. 전투, 시전, 비행 "
    .. "중에는 기다립니다."
L.GATHERINGTRACKING_SWAP_EVERY_NAME = "전환 간격"
L.GATHERINGTRACKING_SWAP_EVERY_DESC = "전환 사이에 기다리는 시간입니다."
L.GATHERINGTRACKING_MUTE_SWAP = "전환 소리 끄기"
L.GATHERINGTRACKING_MUTE_SWAP_DESC = "전환하는 순간마다 게임의 효과음을 꺼서 추적 주문이 소리 없이 시전되게 "
    .. "합니다. 그 순간에 재생되던 다른 소리가 끊길 수 있습니다."
L.GATHERINGTRACKING_ANNOUNCE = "다시 켜지면 알림"
L.GATHERINGTRACKING_ANNOUNCE_DESC = "추적이 자동으로 다시 켜져 게임에 켜진 것으로 표시되면 대화창에 "
    .. "알립니다. 추적 강화 효과를 숨겨 두었을 때 유용합니다."
L.GATHERINGTRACKING_ANNOUNCED = "다시 켜졌습니다: %s." -- a tracking spell's name
L.GATHERINGTRACKING_CHAT = "경고 메시지"
L.GATHERINGTRACKING_CHAT_DESC = "게임이 '채집 추적'의 추적 변경을 막으면 대화창에 알립니다."
L.GATHERINGTRACKING_FAILED = "'채집 추적'이 추적을 바꾸지 못했습니다: %s" -- error
L.GATHERINGTRACKING_BLOCKED = "게임이 '채집 추적'의 추적 변경을 막았습니다. /reload 할 때까지 "
    .. "멈춥니다."

-- AutoStow
L.AUTOSTOW_TITLE = "자동 무기 넣기"
L.AUTOSTOW_DESC = "전투 중이 아닐 때 무기를 꺼낸 지 몇 초가 지나면 다시 넣습니다. 전투 뒤에 꺼낸 채 남았든 "
    .. "직접 꺼냈든 마찬가지입니다."
L.AUTOSTOW_DELAY = "대기 시간"
L.AUTOSTOW_DELAY_DESC = "전투가 끝나거나 무기를 꺼낸 뒤, 무기를 넣기 전까지 꺼내 둘 시간입니다."
L.AUTOSTOW_OUTSIDE_ONLY = "인스턴스 밖에서만"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "다음 전투가 늘 가까운 던전, 공격대, 전장에서는 무기를 꺼낸 채로 "
    .. "둡니다."

-- AutoDismount
L.AUTODISMOUNT_TITLE = "자동 탈것 내리기"
L.AUTODISMOUNT_DESC = "주문 시전, 비행 경로 이용, 전리품 획득처럼 탈것에 타고 있거나 앉아 있어서 실패하는 "
    .. "행동을 하면 탈것에서 내리거나 일어섭니다."
L.AUTODISMOUNT_DISMOUNT = "탈것 내리기"
L.AUTODISMOUNT_DISMOUNT_DESC = "탈것에 탄 채로 주문을 시전하거나, 비행 조련사와 대화하거나, 공격하면 탈것에서 "
    .. "내립니다."
L.AUTODISMOUNT_STAND = "일어서기"
L.AUTODISMOUNT_STAND_DESC = "앉은 채로 주문을 시전하거나, 전리품을 획득하거나, 공격하면 일어섭니다."
L.AUTODISMOUNT_UNSHIFT = "변신 해제"
L.AUTODISMOUNT_UNSHIFT_DESC = "드루이드의 곰 변신이나 표범 변신처럼, 변신 중에 시전할 수 없는 주문을 "
    .. "시전하면 변신을 해제합니다."

-- AutoGossip
L.AUTOGOSSIP_TITLE = "자동 대화"
L.AUTOGOSSIP_DESC = "NPC에게 할 말이 하나뿐이거나 잡담 외에 서비스가 하나뿐이고 퀘스트가 없으면 대신 "
    .. "골라, 은행, 상점, 기술 목록, 비행 지도가 바로 열리게 합니다."
L.AUTOGOSSIP_SECTION_GENERAL = "일반"
L.AUTOGOSSIP_SECTION_NPCS = "자동 선택 대상"
L.AUTOGOSSIP_BANKER = "은행원"
L.AUTOGOSSIP_BANKER_DESC = "은행을 엽니다."
L.AUTOGOSSIP_VENDOR = "상인 및 수리"
L.AUTOGOSSIP_VENDOR_DESC = "상점을 엽니다."
L.AUTOGOSSIP_TRAINER = "기술 전문가"
L.AUTOGOSSIP_TRAINER_DESC = "전문가의 기술 목록을 엽니다."
L.AUTOGOSSIP_TAXI = "비행 조련사"
L.AUTOGOSSIP_TAXI_DESC = "비행 지도를 엽니다."
L.AUTOGOSSIP_STABLE = "야수 관리인"
L.AUTOGOSSIP_STABLE_DESC = "야수 우리를 엽니다."
L.AUTOGOSSIP_OTHER = "그 밖의 NPC"
L.AUTOGOSSIP_OTHER_DESC = "다른 NPC의 유일한 선택지를 고릅니다. 게임이 먼저 내용을 읽으라고 하는 경우는 "
    .. "제외합니다."
L.AUTOGOSSIP_KEY_DESC = "NPC와 대화할 때 이 키를 누르고 있으면 선택지를 직접 고릅니다."

-- AutoDecline
L.AUTODECLINE_TITLE = "자동 거절"
L.AUTODECLINE_DESC = "결투 신청과, 원하면 파티 초대, 길드 초대, 길드 창단허가서도 오는 즉시 거절해 팝업이 "
    .. "방해하지 않게 합니다."
L.AUTODECLINE_DUELS = "결투"
L.AUTODECLINE_DUELS_DESC = "결투 신청을 거절합니다."
L.AUTODECLINE_PARTY_INVITES = "파티 초대"
L.AUTODECLINE_PARTY_INVITES_DESC = "파티 초대도 거절합니다."
L.AUTODECLINE_GUILD_INVITES = "길드 초대"
L.AUTODECLINE_GUILD_INVITES_DESC = "친구가 보낸 것이라도 길드 초대를 거절합니다."
L.AUTODECLINE_GUILD_CHARTERS = "길드 창단허가서"
L.AUTODECLINE_GUILD_CHARTERS_DESC = "친구가 보낸 것이라도 길드 창단허가서 서명 요청을 거절합니다. 내 "
    .. "창단허가서는 그대로 열립니다."
L.AUTODECLINE_ALLOW_FRIENDS = "친구와 길드는 허용"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "친구, Battle.net 친구, 길드원이 보낸 결투 신청과 파티 초대는 "
    .. "거절하지 않습니다."
L.AUTODECLINE_CHAT_DESC = "누구의 결투 신청, 초대, 창단허가서를 거절했는지 대화창에 알립니다."
L.AUTODECLINE_DECLINED = "결투 신청을 거절했습니다: %s" -- player name
L.AUTODECLINE_DECLINED_INVITE = "파티 초대를 거절했습니다: %s" -- player name
L.AUTODECLINE_DECLINED_GUILD_INVITE = "길드 초대를 거절했습니다: %s" -- player name
L.AUTODECLINE_DECLINED_CHARTER = "길드 창단허가서를 거절했습니다: %s" -- player name
L.AUTODECLINE_SOMEONE = "알 수 없음"

-- AutoConfirm
L.AUTOCONFIRM_TITLE = "자동 확인"
L.AUTOCONFIRM_DESC = "마법부여가 아이템에 있던 효과를 바꾸기 전에 묻는 팝업에 '예'로 답해, 마법부여 숙련도를 "
    .. "올릴 때 마법부여 한 번에 클릭 한 번이면 되게 합니다."
L.AUTOCONFIRM_REPLACE = "마법부여 교체"
L.AUTOCONFIRM_REPLACE_DESC = "아이템에 이미 있는 효과를 바꾸는 마법부여를 확인합니다."
L.AUTOCONFIRM_BIND = "아이템 귀속"
L.AUTOCONFIRM_BIND_DESC = "아이템을 자신에게 귀속시키는 마법부여를 확인합니다. 그 뒤로는 아이템을 거래하거나 "
    .. "경매에 팔 수 없습니다."
L.AUTOCONFIRM_TRADEBIND = "거래 중 귀속"
L.AUTOCONFIRM_TRADEBIND_DESC = "거래창에서 시전한 마법부여가 아이템을 귀속시킬 수 있다는 경고를 닫아 거래가 "
    .. "계속되게 합니다."

-- AutoRelease
L.AUTORELEASE_TITLE = "자동 영혼 전환"
L.AUTORELEASE_DESC = "전장에서 죽으면 영혼으로 전환합니다. 스스로 부활할 수 있거나 누군가 부활시키고 있으면 "
    .. "전환하지 않습니다."
L.AUTORELEASE_DELAY = "대기 시간"
L.AUTORELEASE_DELAY_DESC = "죽은 뒤 영혼으로 전환하기 전까지 기다리는 시간입니다."
L.AUTORELEASE_NOW = "즉시"
L.AUTORELEASE_KEY_DESC = "죽어 있는 동안 이 키를 누르고 있으면 쓰러진 자리에 그대로 있습니다."
L.AUTORELEASE_CHAT_DESC = "영혼으로 전환했을 때나 전환하지 않은 이유를 대화창에 알립니다."
L.AUTORELEASE_RELEASED = "영혼으로 전환했습니다."
L.AUTORELEASE_SELF_RES = "전환하지 않음: 스스로 부활할 수 있습니다."
L.AUTORELEASE_RES_OFFER = "전환하지 않음: 누군가 부활시키고 있습니다."

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "동영상 건너뛰기"
L.SKIPCINEMATICS_DESC = "게임의 인게임 영상과 동영상을 모두, 또는 이미 본 것만 건너뜁니다."
L.SKIPCINEMATICS_SKIP = "건너뛰기"
L.SKIPCINEMATICS_SKIP_DESC = "건너뛸 인게임 영상과 동영상입니다. 본 영상은 모든 캐릭터에 걸쳐 "
    .. "기록됩니다."
L.SKIPCINEMATICS_SKIP_SEEN = "본 것만"
L.SKIPCINEMATICS_SKIP_ALL = "모두"
L.SKIPCINEMATICS_KEY = "시청 키"
L.SKIPCINEMATICS_KEY_DESC = "인게임 영상이나 동영상이 시작될 때 이 키를 누르고 있으면 재생합니다."
L.SKIPCINEMATICS_CHAT_DESC = "인게임 영상이나 동영상을 건너뛰면 대화창에 알립니다."
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "인게임 영상을 건너뛰었습니다."
L.SKIPCINEMATICS_SKIPPED_MOVIE = "동영상을 건너뛰었습니다."
L.SKIPCINEMATICS_RESET = "본 영상 기록"
L.SKIPCINEMATICS_RESET_BUTTON = "지우기"
L.SKIPCINEMATICS_RESET_DESC = "어떤 인게임 영상과 동영상을 봤는지 잊어, 각각 한 번씩 다시 재생되게 "
    .. "합니다."
L.SKIPCINEMATICS_RESET_CONFIRM = "어떤 인게임 영상과 동영상을 봤는지 기록을 지우시겠습니까?"
L.SKIPCINEMATICS_RESET_DONE = "본 영상 기록을 지웠습니다."


-- FishingCast
L.FISHINGCAST_TITLE = "낚시 시전"
L.FISHINGCAST_DESC = "낚싯대를 장착한 상태에서 월드를 두 번 오른쪽 클릭하면 낚시를 시전합니다."
L.FISHINGCAST_SPEED = "두 번 클릭 간격"
L.FISHINGCAST_SPEED_DESC = "첫 번째 오른쪽 클릭 뒤 두 번째 오른쪽 클릭까지 허용하는 최대 간격입니다."
L.FISHINGCAST_MS = "%dms" -- milliseconds
L.FISHINGCAST_COMBAT = "전투 경고"
L.FISHINGCAST_COMBAT_DESC = "낚싯대를 장착한 채 전투가 시작되면 한 번 경고합니다."
L.FISHINGCAST_COMBAT_TEXT = "낚싯대를 장착하고 있습니다."
L.FISHINGCAST_LOUDER = "찌 소리 키우기"
L.FISHINGCAST_LOUDER_DESC = "낚시하는 동안 효과음을 키우고 배경음악을 줄여 물 튀는 소리를 잘 들리게 합니다. "
    .. "낚시를 멈추면 원래 음량으로 돌아갑니다."


-- AutoWeaponBuff
L.AUTOWEAPONBUFF_TITLE = "자동 무기 강화"
L.AUTOWEAPONBUFF_DESC = "가방에서 숫돌, 무게추, 오일, 독, 미끼를 오른쪽 클릭하거나 행동 단축바에서 사용하면 "
    .. "바로 무기에 바릅니다. 주장비에 바르며, 보조장비에만 맞으면 보조장비에 바릅니다."
L.AUTOWEAPONBUFF_NOTICE = "전투 중이 아닐 때만 작동합니다." -- a gray row atop the module
L.AUTOWEAPONBUFF_NOTICE_DESC = "게임은 전투 중에 애드온이 가방이나 행동 단축바 클릭의 동작을 바꾸지 못하게 "
    .. "하므로, 전투가 끝날 때까지는 블리자드 기본 동작대로 작동합니다."
L.AUTOWEAPONBUFF_WARN = "맞는 무기가 없으면 경고"
L.AUTOWEAPONBUFF_WARN_DESC = "날붙이 무기만 장착하고 무게추를 쓸 때처럼 장착한 무기 중 아이템을 바를 수 있는 "
    .. "것이 없으면, 커서를 띄우는 대신 화면 위쪽에 붉은 글씨로 알립니다."
L.AUTOWEAPONBUFF_WARN_TEXT = "장착한 무기 중 다음을 바를 수 있는 것이 없습니다: %s" -- item name
L.AUTOWEAPONBUFF_WARN_TEXT_ANY = "장착한 무기 중 그것을 바를 수 있는 것이 없습니다."
L.AUTOWEAPONBUFF_LEARNED_LINE = "무기 강화 학습: %s - %s에 사용." -- item name, weapon type

-- ComprehendScrolls
L.COMPREHENDSCROLLS_TITLE = "두루마리 이해"
L.COMPREHENDSCROLLS_DESC = "가방에 있는 마법사의 두루마리를 오른쪽 클릭하면, 마법책을 열지 않고 바로 두루마리 "
    .. "이해를 시전합니다."
L.COMPREHENDSCROLLS_NOTICE = "전투 중이 아닐 때만 작동합니다." -- a gray row atop the module
L.COMPREHENDSCROLLS_NOTICE_DESC = "게임은 전투 중에 애드온이 가방 클릭의 동작을 바꾸지 못하게 하므로, 전투가 "
    .. "끝날 때까지는 오른쪽 클릭이 블리자드 기본 동작대로 작동합니다."

-- AutoScreenshot
L.AUTOSCREENSHOT_TITLE = "자동 스크린샷"
L.AUTOSCREENSHOT_DESC = "레벨이 오르거나, 업적을 달성하거나, 우두머리를 처치하는 등 남겨 둘 만한 순간에 "
    .. "스크린샷을 찍습니다."
L.AUTOSCREENSHOT_SECTION_GENERAL = "일반"
L.AUTOSCREENSHOT_SECTION_EVENTS = "스크린샷을 찍을 때"
L.AUTOSCREENSHOT_HIDE_UI = "인터페이스 숨기기"
L.AUTOSCREENSHOT_HIDE_UI_DESC = "Alt+Z처럼 스크린샷을 찍는 동안 인터페이스를 숨깁니다. 게임이 허용하지 않는 "
    .. "전투 중에는 숨기지 않습니다."
L.AUTOSCREENSHOT_HIDE_OWN = "직접 찍는 스크린샷"
L.AUTOSCREENSHOT_HIDE_OWN_DESC = "아래 순간을 모두 꺼 두었더라도, 스크린샷 키(Print Screen)로 직접 찍는 "
    .. "스크린샷에서도 인터페이스를 숨깁니다. 전투 중에는 숨기지 않습니다."
L.AUTOSCREENSHOT_NO_HDR = "찍을 때 HDR 끄기"
L.AUTOSCREENSHOT_NO_HDR_DESC = "HDR이 켜져 있으면 스크린샷이 뿌옇게 나옵니다. 스크린샷을 찍는 순간에만 HDR을 "
    .. "끄고 찍은 뒤 다시 켭니다. HDR이 꺼져 있으면 아무 효과가 없습니다. 전투 중에는 작동하지 않습니다."
L.AUTOSCREENSHOT_CHAT_DESC = "스크린샷을 찍은 이유를 대화창에 알립니다."
L.AUTOSCREENSHOT_PLAYED_TIME = "레벨업 시 플레이 시간"
L.AUTOSCREENSHOT_PLAYED_TIME_DESC = "레벨이 오르면 /played 플레이 시간을 대화창에 표시해 스크린샷에 함께 "
    .. "담기게 합니다."
L.AUTOSCREENSHOT_TAKEN = "스크린샷을 찍었습니다: %s." -- the checkbox's name, such as Level Up
L.AUTOSCREENSHOT_LEVEL_UP = "레벨업"
L.AUTOSCREENSHOT_LEVEL_UP_DESC = "새 레벨에 도달했을 때."
L.AUTOSCREENSHOT_ACHIEVEMENT = "업적"
L.AUTOSCREENSHOT_ACHIEVEMENT_DESC = "다른 캐릭터로 이미 달성하지 않은 업적을 달성했을 때."
L.AUTOSCREENSHOT_LOOT = "전리품"
L.AUTOSCREENSHOT_LOOT_DESC = "아래 등급 이상의 아이템을 받았을 때."
L.AUTOSCREENSHOT_LOOT_QUALITY = "전리품 등급"
L.AUTOSCREENSHOT_LOOT_QUALITY_DESC = "스크린샷을 찍는 가장 낮은 아이템 등급입니다."
L.AUTOSCREENSHOT_BOSS_KILL = "우두머리 처치"
L.AUTOSCREENSHOT_BOSS_KILL_DESC = "파티가 던전이나 공격대 우두머리를 처치했을 때."
L.AUTOSCREENSHOT_REPUTATION_DESC = "어떤 진영과 약간 우호적, 우호적, 매우 우호적, 확고한 동맹 관계에 도달했을 "
    .. "때."
L.AUTOSCREENSHOT_PVP_RANK = "PvP 계급"
L.AUTOSCREENSHOT_PVP_RANK_DESC = "새 PvP 계급에 도달했을 때."
L.AUTOSCREENSHOT_NEW_TITLE = "새 칭호"
L.AUTOSCREENSHOT_NEW_TITLE_DESC = "새 칭호를 얻었을 때."
L.AUTOSCREENSHOT_BATTLEGROUND = "전장 종료"
L.AUTOSCREENSHOT_BATTLEGROUND_DESC = "전장이 끝나 점수판이 떠 있을 때."
L.AUTOSCREENSHOT_DEATH = "죽었을 때"
L.AUTOSCREENSHOT_DEATH_DESC = "죽었을 때."
