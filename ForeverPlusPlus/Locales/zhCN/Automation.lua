local _, ns = ...
local L = ns.NewLocale("zhCN")
if not L then
    return
end

-- FastLoot
L.FASTLOOT_TITLE = "快速拾取"
L.FASTLOOT_DESC = "开启自动拾取时，一次拿走所有物品，而不必等待拾取窗口。"
L.FASTLOOT_BLIZZARD_OFF = "暴雪的自动拾取已关闭" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "暴雪的自动拾取已关闭，因此只有按住自动拾取按键（Shift）时拾取的物品才会快速拾取。"

-- AutoRepair
L.AUTOREPAIR_TITLE = "自动修理"
L.AUTOREPAIR_DESC = "与能修理的商人交谈时修理你的所有装备，并在聊天中说明花费。按住跳过按键可跳过。"
L.AUTOREPAIR_FUNDS = "付款方式"
L.AUTOREPAIR_FUNDS_DESC = "用谁的钱支付修理费用。"
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "先用公会银行，再用自己的钱"
L.AUTOREPAIR_FUNDS_GUILD = "仅用公会银行"
L.AUTOREPAIR_FUNDS_OWN = "仅用自己的钱"
L.AUTOREPAIR_MIN_COST = "最低花费"
L.AUTOREPAIR_MIN_COST_DESC = "只在花费至少达到这个数额时才修理，以免每次在商人处稍作停留都花掉几个铜币。"
L.AUTOREPAIR_MIN_COST_ANY = "任意花费"
L.AUTOREPAIR_KEY_DESC = "与商人交谈时按住此键，可不修理装备。"
L.AUTOREPAIR_CHAT_DESC = "在聊天中说明修理花费，或无法支付的原因。"
L.AUTOREPAIR_REPAIRED = "修理花费%s。" -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "修理花费%s，由公会银行支付。" -- cost
L.AUTOREPAIR_NO_MONEY = "金钱不足，无法修理（%s）。" -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "公会银行无法支付修理费用（%s）。" -- cost

-- AutoOpen
L.AUTOOPEN_TITLE = "自动打开容器"
L.AUTOOPEN_DESC = "自动打开背包中的容器，例如蚌壳、袋子，以及已解锁的宝箱。在战斗、潜行、施法时，以及"
    .. "拾取、商人、邮件、银行、交易或拍卖窗口打开时，会等待其结束。"
L.AUTOOPEN_FREE_SLOTS = "保留空背包格"
L.AUTOOPEN_FREE_SLOTS_DESC = "空背包格少于此数量时不打开任何容器，让里面的东西有地方放。"
L.AUTOOPEN_SPECIAL = "打开特殊容器"
L.AUTOOPEN_SPECIAL_DESC = "也打开少数通常留给你自己决定的容器：团队副本和世界首领掉落的宝石袋、节日礼物，"
    .. "以及装有任务物品、配方或装备的箱子和板条箱。"
L.AUTOOPEN_PICK_LOCKS = "右键点击开锁"
L.AUTOOPEN_PICK_LOCKS_DESC = "右键点击背包中上锁的宝箱即可对它施放开锁，之后它会被打开。"
L.AUTOOPEN_CHAT_DESC = "在聊天中说明打开了什么。"
L.AUTOOPEN_OPENED = "已打开%s。" -- one or more item links, each maybe with a count
L.AUTOOPEN_COUNT = "%s x%d" -- item link, how many

-- AutoSellJunk
L.AUTOSELLJUNK_TITLE = "自动出售垃圾"
L.AUTOSELLJUNK_DESC = "与商人交谈时出售背包中的灰色物品，并在聊天中说明卖了多少钱。按住跳过按键可跳过。"
L.AUTOSELLJUNK_BUYBACK = "保证都能购回"
L.AUTOSELLJUNK_BUYBACK_DESC = "只出售商人购回列表在你自己卖出的物品之外还能容纳的垃圾数量，这样误卖的东西"
    .. "仍然都能购回。"
L.AUTOSELLJUNK_KEY_DESC = "与商人交谈时按住此键，可不出售垃圾。"
L.AUTOSELLJUNK_CHAT_DESC = "在聊天中说明卖出了多少件物品、卖了多少钱，以及因购回列表已满而未出售的数量。"
-- count, money; the forms go by the count
L.AUTOSELLJUNK_SOLD = { "出售了%d件垃圾物品，获得%s。" }
-- count, money, how many were left; the forms go by the first count
L.AUTOSELLJUNK_SOLD_FULL = {
    "出售了%d件垃圾物品，获得%s。购回列表已满：%d件未出售。",
}
L.AUTOSELLJUNK_FULL = { -- count
    "购回列表已满：%d件垃圾物品未出售。",
}

-- GatheringTracking
L.GATHERINGTRACKING_TITLE = "采集追踪"
L.GATHERINGTRACKING_DESC = "保持寻找矿物或寻找草药开启：在登录、切换区域或死亡后重新开启，也可以在两者之间"
    .. "轮换。矮人还可以加上寻找财宝。"
L.GATHERINGTRACKING_TRACK = "追踪"
L.GATHERINGTRACKING_TRACK_DESC = "保持开启哪种追踪。游戏一次只能追踪一种，因此两者都选时会轮流开启。"
L.GATHERINGTRACKING_TRACK_BOTH = "矿物和草药"
L.GATHERINGTRACKING_TRACK_MINERALS = "仅矿物"
L.GATHERINGTRACKING_TRACK_HERBS = "仅草药"
L.GATHERINGTRACKING_REAPPLY = "重新开启"
L.GATHERINGTRACKING_REAPPLY_DESC = "登录、切换区域或复活后，如果没有在追踪任何东西，就重新开启追踪：如果上次"
    .. "开启的是另一个追踪法术（例如追踪野兽），就开启它，否则开启你在这里的选择。你自己关闭的追踪会"
    .. "一直保持关闭，直到下一次这样的时刻。"
L.GATHERINGTRACKING_TREASURE = "寻找财宝"
L.GATHERINGTRACKING_TREASURE_DESC = "也保持矮人的寻找财宝开启。它会与上面选择的追踪轮流开启；如果你两种都没"
    .. "学会，则只保持它开启。"
L.GATHERINGTRACKING_SWAP = "在它们之间轮换"
L.GATHERINGTRACKING_SWAP_DESC = "当你选择的追踪之一开启时，在它们之间轮换。战斗、施法和飞行期间会暂停。"
L.GATHERINGTRACKING_SWAP_EVERY_NAME = "轮换间隔"
L.GATHERINGTRACKING_SWAP_EVERY_DESC = "两次轮换之间等待的时间。"
L.GATHERINGTRACKING_MUTE_SWAP = "轮换时静音"
L.GATHERINGTRACKING_MUTE_SWAP_DESC = "每次轮换的瞬间关闭游戏音效，让追踪法术不发出声音。恰好在那时播放的其他"
    .. "声音可能会被打断。"
L.GATHERINGTRACKING_ANNOUNCE = "重新开启时提示"
L.GATHERINGTRACKING_ANNOUNCE_DESC = "追踪被重新开启、且游戏显示其已开启时，在聊天中提示。隐藏追踪增益效果时"
    .. "很有用。"
L.GATHERINGTRACKING_ANNOUNCED = "%s已重新开启。" -- a tracking spell's name
L.GATHERINGTRACKING_CHAT = "警告信息"
L.GATHERINGTRACKING_CHAT_DESC = "游戏阻止“采集追踪”更改追踪时，在聊天中提示。"
L.GATHERINGTRACKING_FAILED = "“采集追踪”无法更改追踪：%s" -- error
L.GATHERINGTRACKING_BLOCKED = "游戏阻止了“采集追踪”更改追踪。它会停止工作，直到/reload。"

-- AutoStow
L.AUTOSTOW_TITLE = "自动收起武器"
L.AUTOSTOW_DESC = "非战斗状态下武器拿出几秒后自动收起，无论是战斗后留在手上，还是你自己拔出的。"
L.AUTOSTOW_DELAY = "延迟"
L.AUTOSTOW_DELAY_DESC = "战斗结束或拔出武器后，武器在手上停留多久才收起。"
L.AUTOSTOW_OUTSIDE_ONLY = "仅在副本外"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "在地下城、团队副本和战场中不收起武器，因为下一场战斗总是近在眼前。"

-- AutoDismount
L.AUTODISMOUNT_TITLE = "自动解散坐骑"
L.AUTODISMOUNT_DESC = "骑乘或坐着时，如果施法、搭乘飞行路线或拾取等操作失败，会自动解散坐骑或起身。"
L.AUTODISMOUNT_DISMOUNT = "解散坐骑"
L.AUTODISMOUNT_DISMOUNT_DESC = "骑乘时施放法术、与飞行管理员交谈或攻击时，自动下坐骑。"
L.AUTODISMOUNT_STAND = "站起来"
L.AUTODISMOUNT_STAND_DESC = "坐着时施放法术、拾取或攻击时，自动站起来。"
L.AUTODISMOUNT_UNSHIFT = "取消变形"
L.AUTODISMOUNT_UNSHIFT_DESC = "施放在变形形态（例如德鲁伊的熊形态或猎豹形态）下无法施放的法术时，自动取消变形。"

-- MountGear
L.MOUNTGEAR_TITLE = "坐骑速度装备"
L.MOUNTGEAR_DESC = "上坐骑时，从背包中换上提高坐骑速度的装备，下坐骑时换回你原来的装备。"
    .. "原来的装备在重载界面或登出后仍会记住。"
L.MOUNTGEAR_NOTICE = "等待战斗结束"
L.MOUNTGEAR_NOTICE_DESC = "战斗中无法更换装备，所以如果你在战斗中下坐骑，原来的装备会在战斗结束后换回。"
    .. "重新装备的饰品在30秒内无法使用，和装备任何饰品时一样。只会换上已与你绑定的装备。"
L.MOUNTGEAR_TRINKET = "饰品"
L.MOUNTGEAR_TRINKET_DESC = "换上“棍子上的胡萝卜”。"
L.MOUNTGEAR_TRINKET_SLOT = "饰品栏位"
L.MOUNTGEAR_TRINKET_SLOT_DESC = "“棍子上的胡萝卜”替换你两个饰品中的哪一个。"
L.MOUNTGEAR_TRINKET_UPPER = "上方"
L.MOUNTGEAR_TRINKET_LOWER = "下方"
L.MOUNTGEAR_GLOVES = "手套"
L.MOUNTGEAR_GLOVES_DESC = "换上带有“附魔手套 - 骑乘”的手套。"
L.MOUNTGEAR_BOOTS = "靴子"
L.MOUNTGEAR_BOOTS_DESC = "换上装有“秘银马刺”的靴子。"
L.MOUNTGEAR_INSTANCES = "在地下城和战场中"
L.MOUNTGEAR_INSTANCES_DESC = "在地下城、团队副本和战场中也更换装备。关闭时，你原来的装备会留在身上。"
L.MOUNTGEAR_CHAT_DESC = "无法换回你原来的装备时在聊天中说明。"
L.MOUNTGEAR_MISSING = "无法重新装备%s：它不在你的背包里。" -- an item link
L.MOUNTGEAR_BAGS_FULL = "背包已满，%s仍然穿在身上。" -- an item link

-- AutoGossip
L.AUTOGOSSIP_TITLE = "自动对话"
L.AUTOGOSSIP_DESC = "当NPC只有一个对话选项，或者除了闲聊之外只有一项服务、且没有任务时，自动替你选择，"
    .. "让银行、商店、训练师或飞行地图立即打开。"
L.AUTOGOSSIP_SECTION_GENERAL = "综合"
L.AUTOGOSSIP_SECTION_NPCS = "自动选择"
L.AUTOGOSSIP_BANKER = "银行职员"
L.AUTOGOSSIP_BANKER_DESC = "打开银行。"
L.AUTOGOSSIP_VENDOR = "商人和修理"
L.AUTOGOSSIP_VENDOR_DESC = "打开商店。"
L.AUTOGOSSIP_TRAINER = "训练师"
L.AUTOGOSSIP_TRAINER_DESC = "打开训练师的技能列表。"
L.AUTOGOSSIP_TAXI = "飞行管理员"
L.AUTOGOSSIP_TAXI_DESC = "打开飞行地图。"
L.AUTOGOSSIP_STABLE = "兽栏管理员"
L.AUTOGOSSIP_STABLE_DESC = "打开兽栏。"
L.AUTOGOSSIP_OTHER = "其他NPC"
L.AUTOGOSSIP_OTHER_DESC = "为其他任何NPC选择其唯一的选项，除非游戏要求你先阅读其文字。"
L.AUTOGOSSIP_KEY_DESC = "与NPC交谈时按住此键，可自己选择选项。"
-- The title under a stable master's name, exactly as the game shows it: it's matched against the
-- game's text, and no table of the client's has it (it comes from the server). English until
-- someone reads it off a client in the language (/dump GameTooltipTextLeft2:GetText() over one);
-- until then Auto Gossip doesn't know a stable master there.

-- AutoDecline
L.AUTODECLINE_TITLE = "自动拒绝"
L.AUTODECLINE_DESC = "收到决斗请求时自动拒绝，也可选择拒绝组队邀请、公会邀请和公会登记表，让弹出窗口"
    .. "不再打扰你。"
L.AUTODECLINE_DUELS = "决斗"
L.AUTODECLINE_DUELS_DESC = "拒绝决斗请求。"
L.AUTODECLINE_PARTY_INVITES = "组队邀请"
L.AUTODECLINE_PARTY_INVITES_DESC = "也拒绝组队邀请。"
L.AUTODECLINE_GUILD_INVITES = "公会邀请"
L.AUTODECLINE_GUILD_INVITES_DESC = "也拒绝公会邀请，即使来自好友。"
L.AUTODECLINE_GUILD_CHARTERS = "公会登记表"
L.AUTODECLINE_GUILD_CHARTERS_DESC = "也拒绝签署公会登记表的请求，即使来自好友。你自己的登记表仍会打开。"
L.AUTODECLINE_ALLOW_FRIENDS = "允许好友和公会"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "不拒绝来自你的好友、战网好友和公会成员的决斗和组队邀请。"
L.AUTODECLINE_CHAT_DESC = "在聊天中说明拒绝了谁的决斗、邀请或登记表。"
L.AUTODECLINE_DECLINED = "已拒绝%s的决斗。" -- player name
L.AUTODECLINE_DECLINED_INVITE = "已拒绝%s的组队邀请。" -- player name
L.AUTODECLINE_DECLINED_GUILD_INVITE = "已拒绝%s的公会邀请。" -- player name
L.AUTODECLINE_DECLINED_CHARTER = "已拒绝%s的公会登记表。" -- player name
L.AUTODECLINE_SOMEONE = "某人"

-- AutoConfirm
L.AUTOCONFIRM_TITLE = "自动确认"
L.AUTOCONFIRM_DESC = "附魔要替换物品原有的附魔时，自动对弹出的确认窗口回答“是”，让练习附魔时每次附魔"
    .. "只需点击一次。"
L.AUTOCONFIRM_REPLACE = "替换附魔"
L.AUTOCONFIRM_REPLACE_DESC = "确认会替换物品原有附魔的附魔。"
L.AUTOCONFIRM_BIND = "绑定物品"
L.AUTOCONFIRM_BIND_DESC = "确认会使物品与你绑定的附魔。之后该物品无法交易或在拍卖行出售。"
L.AUTOCONFIRM_TRADEBIND = "交易中绑定"
L.AUTOCONFIRM_TRADEBIND_DESC = "关闭“在交易窗口中施放的附魔可能会绑定物品”的警告，让交易继续进行。"

-- AutoRelease
L.AUTORELEASE_TITLE = "自动释放灵魂"
L.AUTORELEASE_DESC = "在战场中死亡时释放灵魂，除非你可以复活自己，或有人正在复活你。"
L.AUTORELEASE_DELAY = "延迟"
L.AUTORELEASE_DELAY_DESC = "死亡后等待多久再释放。"
L.AUTORELEASE_NOW = "立即"
L.AUTORELEASE_KEY_DESC = "死亡时按住此键，可留在倒下的地方。"
L.AUTORELEASE_CHAT_DESC = "在聊天中说明灵魂已释放，或未释放的原因。"
L.AUTORELEASE_RELEASED = "已释放灵魂。"
L.AUTORELEASE_SELF_RES = "未释放：你可以复活自己。"
L.AUTORELEASE_RES_OFFER = "未释放：有人正在复活你。"

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "跳过过场动画"
L.SKIPCINEMATICS_DESC = "跳过游戏的过场动画和影片，可以全部跳过，或只跳过已看过的。"
L.SKIPCINEMATICS_SKIP = "跳过"
L.SKIPCINEMATICS_SKIP_DESC = "跳过哪些过场动画和影片。已看过的记录在你的所有角色间通用。"
L.SKIPCINEMATICS_SKIP_SEEN = "仅已看过的"
L.SKIPCINEMATICS_SKIP_ALL = "全部"
L.SKIPCINEMATICS_KEY = "观看按键"
L.SKIPCINEMATICS_KEY_DESC = "过场动画或影片开始时按住此键，可让它播放。"
L.SKIPCINEMATICS_CHAT_DESC = "跳过过场动画或影片时在聊天中提示。"
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "已跳过一段过场动画。"
L.SKIPCINEMATICS_SKIPPED_MOVIE = "已跳过一段影片。"
L.SKIPCINEMATICS_RESET = "已看过的过场动画"
L.SKIPCINEMATICS_RESET_BUTTON = "清除"
L.SKIPCINEMATICS_RESET_DESC = "忘记你看过哪些过场动画和影片，让每一段都再播放一次。"
L.SKIPCINEMATICS_RESET_CONFIRM = "忘记你看过哪些过场动画和影片？"
L.SKIPCINEMATICS_RESET_DONE = "已清除看过的过场动画。"

-- FishingCast
L.FISHINGCAST_TITLE = "双击右键抛竿"
L.FISHINGCAST_DESC = "装备鱼竿时，在游戏世界中双击右键即可施放钓鱼。"
L.FISHINGCAST_SPEED = "双击间隔"
L.FISHINGCAST_SPEED_DESC = "两次右键点击之间允许的最长时间。"
L.FISHINGCAST_MS = "%d毫秒" -- milliseconds
L.FISHINGCAST_COMBAT = "战斗警告"
L.FISHINGCAST_COMBAT_DESC = "装备鱼竿时进入战斗，提醒一次。"
L.FISHINGCAST_COMBAT_TEXT = "你装备着鱼竿。"
L.FISHINGCAST_LOUDER = "突出鱼漂水声"
L.FISHINGCAST_LOUDER_DESC = "钓鱼时调高音效、调低音乐，让水花声更容易听到。停止钓鱼后恢复你自己的音量。"

-- FishingKey
L.FISHINGKEY_TITLE = "钓鱼按键"
L.FISHINGKEY_DESC = "一个用来钓鱼的按键：第一次按下时从背包中装备鱼竿，之后施放钓鱼，鱼漂在水上时则拾取它。"
    .. "第二个按键会换回你自己的武器和装备。在“按键设置”中Forever++分类下选择这两个按键。"
L.FISHINGKEY_BINDING = "钓鱼并拾取" -- in Blizzard's Key Bindings
L.FISHINGKEY_BACK_BINDING = "换回自己的装备" -- in Blizzard's Key Bindings
L.FISHINGKEY_NO_KEY = "尚未绑定按键" -- a gray row atop the module, with a button
-- [quotes: KEY_BINDINGS]
L.FISHINGKEY_NO_KEY_DESC = "这一切都使用你在“按键设置”中Forever++分类下选择的按键。"
L.FISHINGKEY_COMBAT = "只在非战斗状态下更换装备"
L.FISHINGKEY_COMBAT_DESC = "游戏只允许在非战斗状态下更换装备和更改按键的功能。战斗中按下按键，会在战斗结束后更换装备；"
    .. "战斗中按键保持原来的功能。"
L.FISHINGKEY_INTERACT = "开启交互键"
L.FISHINGKEY_INTERACT_DESC = "按键通过游戏的交互键拾取鱼漂，而交互键只在游戏的“开启交互按键”设置开启时有效。"
    .. "如果你关闭了它，只在你手持鱼竿时开启它（并让它能够到你的鱼漂），卸下鱼竿后恢复你自己的设置。"
    .. "如果你已开启，则不做任何更改。"
L.FISHINGKEY_GEAR = "钓鱼装备"
L.FISHINGKEY_GEAR_DESC = "装备鱼竿时，也装备背包中为钓鱼加成而穿戴的装备，例如钓鱼帽。只限已与你绑定的装备。"
L.FISHINGKEY_SHIFT = "Shift换回装备"
L.FISHINGKEY_SHIFT_DESC = "按住Shift按下按键时，会像第二个按键一样换回你自己的武器和装备。"
L.FISHINGKEY_CHAT_DESC = "没有可装备的鱼竿，或无法换回你自己的装备时，在聊天中说明。"
L.FISHINGKEY_NO_POLE = "你的背包里没有鱼竿。"
L.FISHINGKEY_UNBOUND = "%s装备后会与你绑定，第一次请自己装备它。" -- an item link
L.FISHINGKEY_BAGS_FULL = "背包已满，%s仍然穿在身上。" -- an item link
L.FISHINGKEY_MISSING = "无法重新装备%s：它不在你的背包里。" -- an item link

-- AutoWeaponBuff
L.AUTOWEAPONBUFF_TITLE = "自动武器强化"
L.AUTOWEAPONBUFF_DESC = "右键点击背包中的磨刀石、平衡石、油、毒药或鱼饵，或在动作条上使用它们，即可直接用在"
    .. "你的武器上：主手，或在只有副手适用时用于副手。"
L.AUTOWEAPONBUFF_NOTICE = "仅在非战斗状态下有效。" -- a gray row atop the module
L.AUTOWEAPONBUFF_NOTICE_DESC = "游戏不允许插件在战斗中更改点击背包或动作条的效果，因此在战斗结束前，它们的"
    .. "作用与暴雪默认的相同。"
L.AUTOWEAPONBUFF_WARN = "没有适用武器时警告"
L.AUTOWEAPONBUFF_WARN_DESC = "当没有已装备的武器能使用该物品时（例如只装备了利刃武器却使用平衡石），在屏幕"
    .. "顶部以红字提示，而不是出现选择光标。"
L.AUTOWEAPONBUFF_WARN_TEXT = "没有已装备的武器可以使用%s。" -- item name
L.AUTOWEAPONBUFF_WARN_TEXT_ANY = "没有已装备的武器可以使用它。"
L.AUTOWEAPONBUFF_LEARNED_LINE = "已学会武器强化：%s用于%s。" -- item name, weapon type

-- ComprehendScrolls
L.COMPREHENDSCROLLS_TITLE = "理解卷轴"
L.COMPREHENDSCROLLS_DESC = "右键点击背包中的法师卷轴即可对它施放理解卷轴，无需先打开法术书。"
L.COMPREHENDSCROLLS_NOTICE = "仅在非战斗状态下有效。" -- a gray row atop the module
L.COMPREHENDSCROLLS_NOTICE_DESC = "游戏不允许插件在战斗中更改点击背包的效果，因此在战斗结束前，右键点击的"
    .. "作用与暴雪默认的相同。"

-- AutoScreenshot
L.AUTOSCREENSHOT_TITLE = "自动截图"
L.AUTOSCREENSHOT_DESC = "在你升级、获得成就或击败首领时，以及其他值得留念的时刻自动截图。"
L.AUTOSCREENSHOT_SECTION_GENERAL = "综合"
L.AUTOSCREENSHOT_SECTION_EVENTS = "截图时机"
L.AUTOSCREENSHOT_HIDE_UI = "隐藏界面"
L.AUTOSCREENSHOT_HIDE_UI_DESC = "截图时像Alt+Z那样隐藏界面。战斗中游戏不允许这样做，因此战斗中无效。"
L.AUTOSCREENSHOT_HIDE_OWN = "你自己的截图"
L.AUTOSCREENSHOT_HIDE_OWN_DESC = "用截图键（Print Screen）自己截图时也隐藏界面，即使下面的时机都已关闭。战斗中无效。"
L.AUTOSCREENSHOT_NO_HDR = "截图时关闭HDR"
L.AUTOSCREENSHOT_NO_HDR_DESC = "开启HDR时，截图会显得发白。此选项在截图的瞬间关闭HDR，截完后重新开启。HDR关闭"
    .. "时不起作用。战斗中无效。"
L.AUTOSCREENSHOT_CHAT_DESC = "在聊天中说明截图的原因。"
L.AUTOSCREENSHOT_PLAYED_TIME = "升级时显示游戏时间"
L.AUTOSCREENSHOT_PLAYED_TIME_DESC = "升级时在聊天中显示你的/played游戏时间，让它出现在截图中。"
L.AUTOSCREENSHOT_TAKEN = "已截图：%s。" -- the checkbox's name, such as Level Up
L.AUTOSCREENSHOT_LEVEL_UP = "升级"
L.AUTOSCREENSHOT_LEVEL_UP_DESC = "当你升到新的等级时。"
L.AUTOSCREENSHOT_ACHIEVEMENT = "成就"
L.AUTOSCREENSHOT_ACHIEVEMENT_DESC = "当你获得一个其他角色尚未获得的成就时。"
L.AUTOSCREENSHOT_LOOT = "战利品"
L.AUTOSCREENSHOT_LOOT_DESC = "当你获得下面所选品质或更高品质的物品时。"
L.AUTOSCREENSHOT_LOOT_QUALITY = "战利品品质"
L.AUTOSCREENSHOT_LOOT_QUALITY_DESC = "触发截图的最低物品品质。"
L.AUTOSCREENSHOT_BOSS_KILL = "击杀首领"
L.AUTOSCREENSHOT_BOSS_KILL_DESC = "当你的队伍击败地下城或团队副本首领时。"
L.AUTOSCREENSHOT_REPUTATION_DESC = "当你与某个阵营的关系达到友善、尊敬、崇敬或崇拜时。"
L.AUTOSCREENSHOT_PVP_RANK = "PvP军衔"
L.AUTOSCREENSHOT_PVP_RANK_DESC = "当你达到新的PvP军衔时。"
L.AUTOSCREENSHOT_NEW_TITLE = "新头衔"
L.AUTOSCREENSHOT_NEW_TITLE_DESC = "当你获得新头衔时。"
L.AUTOSCREENSHOT_BATTLEGROUND = "战场结束"
L.AUTOSCREENSHOT_BATTLEGROUND_DESC = "战场结束时，在显示计分板的情况下截图。"
L.AUTOSCREENSHOT_DEATH = "死亡"
L.AUTOSCREENSHOT_DEATH_DESC = "当你死亡时。"
