local _, ns = ...
local L = ns.NewLocale("zhTW")
if not L then
    return
end

-- FastLoot
L.FASTLOOT_TITLE = "快速拾取"
L.FASTLOOT_DESC = "開啟自動拾取時，不必等待拾取視窗，一次拿走所有物品。"
L.FASTLOOT_BLIZZARD_OFF = "暴雪的自動拾取已關閉" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "暴雪的自動拾取已關閉，因此只有按住自動拾取鍵（Shift）拾取時才會加快。"

-- AutoRepair
L.AUTOREPAIR_TITLE = "自動修理"
L.AUTOREPAIR_DESC = "與可修理的商人交談時，修理你所有的裝備，並在聊天中顯示花費。"
    .. "按住略過按鍵即可略過。"
L.AUTOREPAIR_FUNDS = "付款方式"
L.AUTOREPAIR_FUNDS_DESC = "用誰的錢支付修理費。"
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "先用公會銀行，再用自己的錢"
L.AUTOREPAIR_FUNDS_GUILD = "僅限公會銀行"
L.AUTOREPAIR_FUNDS_OWN = "僅限自己的錢"
L.AUTOREPAIR_MIN_COST = "最低花費"
L.AUTOREPAIR_MIN_COST_DESC = "只在花費至少達到這個金額時才修理，免得每次短暫拜訪商人都花掉幾枚銅幣。"
L.AUTOREPAIR_MIN_COST_ANY = "任何花費"
L.AUTOREPAIR_KEY_DESC = "與商人交談時按住此鍵，就不會修理裝備。"
L.AUTOREPAIR_CHAT_DESC = "在聊天中顯示修理花費，或無法支付的原因。"
L.AUTOREPAIR_REPAIRED = "修理花費%s。" -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "從公會銀行支付修理費%s。" -- cost
L.AUTOREPAIR_NO_MONEY = "金錢不足，無法修理（%s）。" -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "公會銀行無法支付修理費（%s）。" -- cost

-- AutoOpen
L.AUTOOPEN_TITLE = "自動開啟容器"
L.AUTOOPEN_DESC = "自動打開背包中的容器，例如蚌殼、袋子，以及已解鎖的寶箱。"
    .. "戰鬥中、潛行中、施法中，或開著拾取、商人、郵件、銀行、交易或拍賣視窗時，會等到結束後再打開。"
L.AUTOOPEN_FREE_SLOTS = "保留背包空格"
L.AUTOOPEN_FREE_SLOTS_DESC = "背包空格少於這個數量時不打開任何容器，讓裡面的東西有地方放。"
L.AUTOOPEN_SPECIAL = "打開特殊容器"
L.AUTOOPEN_SPECIAL_DESC = "也打開少數通常留給你自己決定的容器：團隊副本和世界首領的寶石袋、節日禮物，"
    .. "以及裝有任務物品、配方或裝備的箱子。"
L.AUTOOPEN_PICK_LOCKS = "右鍵點擊開鎖"
L.AUTOOPEN_PICK_LOCKS_DESC = "在背包中右鍵點擊上鎖的寶箱，就會對它施放開鎖，然後打開它。"
L.AUTOOPEN_CHAT_DESC = "在聊天中顯示打開了什麼。"
L.AUTOOPEN_OPENED = "已打開%s。" -- one or more item links, each maybe with a count
L.AUTOOPEN_COUNT = "%s x%d" -- item link, how many
-- AutoSellJunk
L.AUTOSELLJUNK_TITLE = "自動出售垃圾"
L.AUTOSELLJUNK_DESC = "與商人交談時，出售背包中的灰色物品，並在聊天中顯示賣得的金額。"
    .. "按住略過按鍵即可略過。"
L.AUTOSELLJUNK_BUYBACK = "確保賣出的物品都能買回"
L.AUTOSELLJUNK_BUYBACK_DESC = "只出售商人買回清單在你自己賣出的物品之外還放得下的垃圾數量，"
    .. "這樣誤賣的東西仍然可以買回。"
L.AUTOSELLJUNK_KEY_DESC = "與商人交談時按住此鍵，就不會出售垃圾。"
L.AUTOSELLJUNK_CHAT_DESC = "在聊天中顯示賣出了幾件物品、賣得多少錢，以及因買回清單已滿而未賣出的數量。"
-- count, money; the forms go by the count
L.AUTOSELLJUNK_SOLD = { "已賣出%d件垃圾物品，獲得%s。" }
-- count, money, how many were left; the forms go by the first count
L.AUTOSELLJUNK_SOLD_FULL = {
    "已賣出%d件垃圾物品，獲得%s。買回清單已滿：%d件未賣出。",
}
L.AUTOSELLJUNK_FULL = { -- count
    "買回清單已滿：%d件垃圾物品未賣出。",
}

-- GatheringTracking
L.GATHERINGTRACKING_TITLE = "採集追蹤"
L.GATHERINGTRACKING_DESC = "讓尋找礦物或尋找草藥保持開啟：在登入、切換區域或死亡後重新開啟，"
    .. "也可以在兩者之間輪流切換。矮人還可以加上尋找財寶。"
L.GATHERINGTRACKING_TRACK = "追蹤"
L.GATHERINGTRACKING_TRACK_DESC = "要保持開啟的追蹤。遊戲一次只能追蹤一種，因此兩者會輪流。"
L.GATHERINGTRACKING_TRACK_BOTH = "礦物和草藥"
L.GATHERINGTRACKING_TRACK_MINERALS = "僅限礦物"
L.GATHERINGTRACKING_TRACK_HERBS = "僅限草藥"
L.GATHERINGTRACKING_REAPPLY = "重新開啟"
L.GATHERINGTRACKING_REAPPLY_DESC = "登入、切換區域或復活後，若沒有任何追蹤，就重新開啟追蹤："
    .. "若上次開啟的是其他追蹤法術（例如追蹤野獸）就開啟它，否則開啟你在這裡選擇的追蹤。"
    .. "你自己關閉追蹤時，會維持關閉直到那時。"
L.GATHERINGTRACKING_TREASURE = "尋找財寶"
L.GATHERINGTRACKING_TREASURE_DESC = "也讓矮人的尋找財寶保持開啟。它會和上方選擇的追蹤輪流，"
    .. "若你兩者都不會，就只保持它開啟。"
L.GATHERINGTRACKING_SWAP = "輪流切換"
L.GATHERINGTRACKING_SWAP_DESC = "當其中一種追蹤開啟時，在你選擇的追蹤之間輪流切換。戰鬥、施法和飛行時會暫停。"
L.GATHERINGTRACKING_SWAP_EVERY_NAME = "切換間隔"
L.GATHERINGTRACKING_SWAP_EVERY_DESC = "每次切換之間等待多久。"
L.GATHERINGTRACKING_MUTE_SWAP = "切換時靜音"
L.GATHERINGTRACKING_MUTE_SWAP_DESC = "每次切換的瞬間暫時關閉遊戲音效，讓追蹤法術不發出聲音。"
    .. "這時正在播放的其他音效可能會被中斷。"
L.GATHERINGTRACKING_ANNOUNCE = "重新開啟時通知"
L.GATHERINGTRACKING_ANNOUNCE_DESC = "追蹤被重新開啟，且遊戲顯示為開啟後，在聊天中通知你。"
    .. "隱藏追蹤增益效果時很有用。"
L.GATHERINGTRACKING_ANNOUNCED = "%s已重新開啟。" -- a tracking spell's name
L.GATHERINGTRACKING_CHAT = "警告訊息"
L.GATHERINGTRACKING_CHAT_DESC = "遊戲阻止「採集追蹤」變更追蹤時，在聊天中通知你。"
L.GATHERINGTRACKING_FAILED = "「採集追蹤」無法變更追蹤：%s" -- error
L.GATHERINGTRACKING_BLOCKED = "遊戲阻止「採集追蹤」變更追蹤。它會停止運作，直到/reload。"

-- AutoStow
L.AUTOSTOW_TITLE = "自動收武器"
L.AUTOSTOW_DESC = "非戰鬥狀態下，武器拿出幾秒後就收起來，無論是戰鬥後留著，還是你自己拔出來的。"
L.AUTOSTOW_DELAY = "延遲"
L.AUTOSTOW_DELAY_DESC = "戰鬥結束或你拔出武器後，武器要拿多久才收起來。"
L.AUTOSTOW_OUTSIDE_ONLY = "僅限副本外"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "在地城、團隊副本和戰場中讓武器保持拿出，因為下一場戰鬥總是近在眼前。"

-- AutoDismount
L.AUTODISMOUNT_TITLE = "自動解除坐騎"
L.AUTODISMOUNT_DESC = "當某個動作因為你騎著坐騎或坐著而失敗時（例如施法、搭乘飛行路線或拾取），"
    .. "自動下坐騎或站起來。"
L.AUTODISMOUNT_DISMOUNT = "解除坐騎"
L.AUTODISMOUNT_DISMOUNT_DESC = "騎乘時施法、與飛行管理員交談或攻擊，就下坐騎。"
L.AUTODISMOUNT_STAND = "站起來"
L.AUTODISMOUNT_STAND_DESC = "坐著時施法、拾取或攻擊，就站起來。"
L.AUTODISMOUNT_UNSHIFT = "離開變形形態"
L.AUTODISMOUNT_UNSHIFT_DESC = "施放無法在變形形態（例如德魯伊的熊形態或獵豹形態）中施放的法術時，離開該形態。"

-- AutoGossip
L.AUTOGOSSIP_TITLE = "自動對話"
L.AUTOGOSSIP_DESC = "當NPC只有一個對話選項，或除了閒聊之外只有一項服務，而且沒有任務時，"
    .. "替你選擇它，讓銀行、商店、訓練師或飛行地圖直接開啟。"
L.AUTOGOSSIP_SECTION_GENERAL = "一般"
L.AUTOGOSSIP_SECTION_NPCS = "自動選擇"
L.AUTOGOSSIP_BANKER = "銀行職員"
L.AUTOGOSSIP_BANKER_DESC = "開啟銀行。"
L.AUTOGOSSIP_VENDOR = "商人和修理"
L.AUTOGOSSIP_VENDOR_DESC = "開啟商店。"
L.AUTOGOSSIP_TRAINER = "訓練師"
L.AUTOGOSSIP_TRAINER_DESC = "開啟訓練師的清單。"
L.AUTOGOSSIP_TAXI = "飛行管理員"
L.AUTOGOSSIP_TAXI_DESC = "開啟飛行地圖。"
L.AUTOGOSSIP_STABLE = "獸欄管理員"
L.AUTOGOSSIP_STABLE_DESC = "開啟獸欄。"
L.AUTOGOSSIP_OTHER = "其他NPC"
L.AUTOGOSSIP_OTHER_DESC = "選擇其他任何NPC唯一的選項，除非遊戲要求你先閱讀它的文字。"
L.AUTOGOSSIP_KEY_DESC = "與NPC交談時按住此鍵，就由你自己選擇選項。"

-- AutoDecline
L.AUTODECLINE_TITLE = "自動拒絕"
L.AUTODECLINE_DESC = "收到決鬥請求時自動拒絕，也可以拒絕隊伍邀請、公會邀請和公會登記表，"
    .. "讓彈出視窗不再擋路。"
L.AUTODECLINE_DUELS = "決鬥"
L.AUTODECLINE_DUELS_DESC = "拒絕決鬥請求。"
L.AUTODECLINE_PARTY_INVITES = "隊伍邀請"
L.AUTODECLINE_PARTY_INVITES_DESC = "也拒絕隊伍邀請。"
L.AUTODECLINE_GUILD_INVITES = "公會邀請"
L.AUTODECLINE_GUILD_INVITES_DESC = "也拒絕公會邀請，即使來自好友。"
L.AUTODECLINE_GUILD_CHARTERS = "公會登記表"
L.AUTODECLINE_GUILD_CHARTERS_DESC = "也拒絕簽署公會登記表的請求，即使來自好友。你自己的登記表仍會開啟。"
L.AUTODECLINE_ALLOW_FRIENDS = "允許好友和公會"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "放行來自好友、Battle.net好友和公會成員的決鬥與隊伍邀請。"
L.AUTODECLINE_CHAT_DESC = "在聊天中顯示拒絕了誰的決鬥、邀請或登記表。"
L.AUTODECLINE_DECLINED = "已拒絕%s的決鬥。" -- player name
L.AUTODECLINE_DECLINED_INVITE = "已拒絕%s的隊伍邀請。" -- player name
L.AUTODECLINE_DECLINED_GUILD_INVITE = "已拒絕%s的公會邀請。" -- player name
L.AUTODECLINE_DECLINED_CHARTER = "已拒絕%s的公會登記表。" -- player name
L.AUTODECLINE_SOMEONE = "某人"

-- AutoConfirm
L.AUTOCONFIRM_TITLE = "自動確認"
L.AUTOCONFIRM_DESC = "當附魔將取代物品原有的附魔時，自動在詢問視窗中回答「是」，"
    .. "讓練附魔時每次附魔只需點擊一次。"
L.AUTOCONFIRM_REPLACE = "取代附魔"
L.AUTOCONFIRM_REPLACE_DESC = "確認會取代物品原有附魔的附魔。"
L.AUTOCONFIRM_BIND = "綁定物品"
L.AUTOCONFIRM_BIND_DESC = "確認會讓物品綁定在你身上的附魔。之後該物品將無法交易或拍賣。"
L.AUTOCONFIRM_TRADEBIND = "交易中綁定"
L.AUTOCONFIRM_TRADEBIND_DESC = "關閉「在交易視窗中施放的附魔可能會綁定物品」的警告，讓交易繼續進行。"

-- AutoRelease
L.AUTORELEASE_TITLE = "自動釋放靈魂"
L.AUTORELEASE_DESC = "在戰場中死亡時自動釋放靈魂，除非你能自己復活，或有人正在復活你。"
L.AUTORELEASE_DELAY = "延遲"
L.AUTORELEASE_DELAY_DESC = "死亡後等待多久才釋放靈魂。"
L.AUTORELEASE_NOW = "立即"
L.AUTORELEASE_KEY_DESC = "死亡時按住此鍵，就會留在倒下的地方。"
L.AUTORELEASE_CHAT_DESC = "在聊天中顯示靈魂已釋放，或未釋放的原因。"
L.AUTORELEASE_RELEASED = "已釋放靈魂。"
L.AUTORELEASE_SELF_RES = "未釋放：你可以自己復活。"
L.AUTORELEASE_RES_OFFER = "未釋放：有人正在復活你。"

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "跳過動畫"
L.SKIPCINEMATICS_DESC = "跳過遊戲的過場動畫和影片，可以全部跳過，或只跳過已經看過的。"
L.SKIPCINEMATICS_SKIP = "跳過"
L.SKIPCINEMATICS_SKIP_DESC = "要跳過哪些過場動畫和影片。已看過的紀錄由你所有角色共用。"
L.SKIPCINEMATICS_SKIP_SEEN = "僅限已看過"
L.SKIPCINEMATICS_SKIP_ALL = "全部"
L.SKIPCINEMATICS_KEY = "觀看按鍵"
L.SKIPCINEMATICS_KEY_DESC = "過場動畫或影片開始時按住此鍵，就會讓它播放。"
L.SKIPCINEMATICS_CHAT_DESC = "跳過過場動畫或影片時，在聊天中通知你。"
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "已跳過一段過場動畫。"
L.SKIPCINEMATICS_SKIPPED_MOVIE = "已跳過一段影片。"
L.SKIPCINEMATICS_RESET = "已看過的動畫"
L.SKIPCINEMATICS_RESET_BUTTON = "清除"
L.SKIPCINEMATICS_RESET_DESC = "忘記你看過哪些過場動畫和影片，讓每一段都再播放一次。"
L.SKIPCINEMATICS_RESET_CONFIRM = "要忘記你看過哪些過場動畫和影片嗎？"
L.SKIPCINEMATICS_RESET_DONE = "已清除看過的動畫紀錄。"


-- FishingCast
L.FISHINGCAST_TITLE = "雙擊右鍵拋竿"
L.FISHINGCAST_DESC = "裝備釣魚竿時，在世界中雙擊右鍵即可施放釣魚。"
L.FISHINGCAST_SPEED = "雙擊間隔"
L.FISHINGCAST_SPEED_DESC = "兩次右鍵點擊之間允許的最長時間。"
L.FISHINGCAST_MS = "%d毫秒" -- milliseconds
L.FISHINGCAST_COMBAT = "戰鬥警告"
L.FISHINGCAST_COMBAT_DESC = "裝備著釣魚竿進入戰鬥時，警告一次。"
L.FISHINGCAST_COMBAT_TEXT = "你裝備著釣魚竿。"
L.FISHINGCAST_LOUDER = "加大浮標音量"
L.FISHINGCAST_LOUDER_DESC = "釣魚時調高音效、調低音樂，讓水花聲更容易聽見。停止釣魚後會恢復你原本的音量。"


-- AutoWeaponBuff
L.AUTOWEAPONBUFF_TITLE = "自動武器強化"
L.AUTOWEAPONBUFF_DESC = "在背包中右鍵點擊磨刀石、平衡石、油、毒藥或魚餌，或從快捷列使用，"
    .. "就直接套用到你的武器上：主手，或只有副手適用時套用到副手。"
L.AUTOWEAPONBUFF_NOTICE = "僅限非戰鬥狀態。" -- a gray row atop the module
L.AUTOWEAPONBUFF_NOTICE_DESC = "遊戲不允許插件在戰鬥中變更點擊背包或快捷列的效果，"
    .. "因此戰鬥結束前，它們會和暴雪原本的功能一樣。"
L.AUTOWEAPONBUFF_WARN = "沒有適用武器時警告"
L.AUTOWEAPONBUFF_WARN_DESC = "當沒有任何已裝備的武器能使用該物品時（例如只裝備刀刃武器卻使用平衡石），"
    .. "在畫面上方以紅字提示，而不是出現游標。"
L.AUTOWEAPONBUFF_WARN_TEXT = "沒有已裝備的武器能使用%s。" -- item name
L.AUTOWEAPONBUFF_WARN_TEXT_ANY = "沒有已裝備的武器能使用它。"
L.AUTOWEAPONBUFF_LEARNED_LINE = "已學到武器強化：%s用於%s。" -- item name, weapon type

-- ComprehendScrolls
L.COMPREHENDSCROLLS_TITLE = "理解卷軸"
L.COMPREHENDSCROLLS_DESC = "在背包中右鍵點擊法師的卷軸，就會對它施放理解卷軸，不必先打開法術書。"
L.COMPREHENDSCROLLS_NOTICE = "僅限非戰鬥狀態。" -- a gray row atop the module
L.COMPREHENDSCROLLS_NOTICE_DESC = "遊戲不允許插件在戰鬥中變更點擊背包的效果，"
    .. "因此戰鬥結束前，右鍵點擊會和暴雪原本的功能一樣。"

-- AutoScreenshot
L.AUTOSCREENSHOT_TITLE = "自動擷圖"
L.AUTOSCREENSHOT_DESC = "在你升級、獲得成就、擊敗首領，以及其他值得留念的時刻自動擷圖。"
L.AUTOSCREENSHOT_SECTION_GENERAL = "一般"
L.AUTOSCREENSHOT_SECTION_EVENTS = "擷圖時機"
L.AUTOSCREENSHOT_HIDE_UI = "隱藏介面"
L.AUTOSCREENSHOT_HIDE_UI_DESC = "擷圖時隱藏介面，就像按Alt+Z一樣。戰鬥中不會隱藏，因為遊戲不允許。"
L.AUTOSCREENSHOT_HIDE_OWN = "你自己的擷圖"
L.AUTOSCREENSHOT_HIDE_OWN_DESC = "以擷圖鍵（Print Screen）手動擷圖時也隱藏介面，"
    .. "即使下方的時機全部關閉也一樣。戰鬥中不會隱藏。"
L.AUTOSCREENSHOT_NO_HDR = "擷圖時關閉HDR"
L.AUTOSCREENSHOT_NO_HDR_DESC = "開啟HDR時，擷圖顏色會顯得泛白。這會在擷圖的瞬間關閉HDR，之後再開啟。"
    .. "HDR關閉時沒有作用。戰鬥中不會套用。"
L.AUTOSCREENSHOT_CHAT_DESC = "在聊天中顯示擷圖的原因。"
L.AUTOSCREENSHOT_PLAYED_TIME = "升級時顯示遊戲時間"
L.AUTOSCREENSHOT_PLAYED_TIME_DESC = "升級時在聊天中顯示你的/played遊戲時間，讓它出現在擷圖中。"
L.AUTOSCREENSHOT_TAKEN = "已擷圖：%s。" -- the checkbox's name, such as Level Up
L.AUTOSCREENSHOT_LEVEL_UP = "升級"
L.AUTOSCREENSHOT_LEVEL_UP_DESC = "當你達到新的等級時。"
L.AUTOSCREENSHOT_ACHIEVEMENT = "成就"
L.AUTOSCREENSHOT_ACHIEVEMENT_DESC = "當你獲得其他角色尚未取得的成就時。"
L.AUTOSCREENSHOT_LOOT = "拾取"
L.AUTOSCREENSHOT_LOOT_DESC = "當你獲得下方品質或更好的物品時。"
L.AUTOSCREENSHOT_LOOT_QUALITY = "拾取品質"
L.AUTOSCREENSHOT_LOOT_QUALITY_DESC = "會觸發擷圖的最低物品品質。"
L.AUTOSCREENSHOT_BOSS_KILL = "擊殺首領"
L.AUTOSCREENSHOT_BOSS_KILL_DESC = "當你的隊伍擊敗地城或團隊副本首領時。"
L.AUTOSCREENSHOT_REPUTATION_DESC = "當你與某個陣營的聲望達到友好、尊敬、崇敬或崇拜時。"
L.AUTOSCREENSHOT_PVP_RANK = "PvP軍銜"
L.AUTOSCREENSHOT_PVP_RANK_DESC = "當你達到新的PvP軍銜時。"
L.AUTOSCREENSHOT_NEW_TITLE = "新頭銜"
L.AUTOSCREENSHOT_NEW_TITLE_DESC = "當你獲得新頭銜時。"
L.AUTOSCREENSHOT_BATTLEGROUND = "戰場結束"
L.AUTOSCREENSHOT_BATTLEGROUND_DESC = "當戰場結束、顯示計分板時。"
L.AUTOSCREENSHOT_DEATH = "死亡"
L.AUTOSCREENSHOT_DEATH_DESC = "當你死亡時。"
