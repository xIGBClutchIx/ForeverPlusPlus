local _, ns = ...
local L = ns.NewLocale("zhTW")
if not L then
    return
end

-- CharacterWindow
L.CHARACTERWINDOW_TITLE = "角色視窗"
L.CHARACTERWINDOW_DESC = "整理角色視窗：裝備、頭銜和寵物改為側邊分頁，屬性從最上方開始，"
    .. "以職業顏色顯示你的等級和名字，並在每件物品旁顯示耐久度條。"
L.CHARACTERWINDOW_SIDETABS = "側邊分頁"
L.CHARACTERWINDOW_SIDETABS_DESC = "將裝備、頭銜和寵物分頁移到聲望、技能等分頁旁，並移除屬性上方的頭像，"
    .. "讓屬性從最上方開始。它們和其他分頁的用法一樣：選擇「角色」分頁即可回到屬性。"
L.CHARACTERWINDOW_COLORTITLE = "彩色標題"
L.CHARACTERWINDOW_COLORTITLE_DESC = "在視窗標題中，以金色顯示你的等級，後面接著以職業顏色顯示的名字，"
    .. "取代遊戲在視窗上方的等級那一行。"
L.CHARACTERWINDOW_TITLE_FORMAT = "%s %s" -- level, name
L.CHARACTERWINDOW_DURABILITY = "耐久度條"
L.CHARACTERWINDOW_DURABILITY_DESC = "在每件物品旁顯示一條小條，以綠色到紅色表示磨損程度，"
    .. "並選擇哪些物品要顯示。沒有耐久度的物品永遠不會顯示。"
L.CHARACTERWINDOW_DURABILITY_ALWAYS = "永遠"
L.CHARACTERWINDOW_DURABILITY_WORN = "僅限有磨損時"
L.CHARACTERWINDOW_DURABILITY_HALF = "低於50%"
L.CHARACTERWINDOW_DURABILITY_QUARTER = "低於25%"
L.CHARACTERWINDOW_DURABILITY_OFF = "關閉"
L.CHARACTERWINDOW_WEAPONSKILLS = "已裝備的武器技能"
L.CHARACTERWINDOW_WEAPONSKILLS_DESC = "在技能分頁中，將你已裝備之武器的武器技能條改為綠色，而不是藍色。"
L.CHARACTERWINDOW_SECTION_ITEMS = "物品"
L.CHARACTERWINDOW_ITEMLEVEL = "已裝備物品等級"
L.CHARACTERWINDOW_ITEMLEVEL_DESC = "在每件物品的圖示上以其品質顏色顯示物品等級。"
L.CHARACTERWINDOW_ENCHANTS = "附魔標記"
L.CHARACTERWINDOW_ENCHANTS_DESC = "在可附魔物品靠近角色的一角加上標記：已附魔為綠色，未附魔為紅色。"
    .. "戒指、飾品、襯衣和外袍無法附魔，不會標記；腰帶只在有附魔時標記。"
L.CHARACTERWINDOW_ENCHANT_MARK = "附"
L.CHARACTERWINDOW_INSPECT = "觀察視窗"
L.CHARACTERWINDOW_INSPECT_DESC = "在你觀察的玩家的物品上也顯示這些資訊。"

-- Durability Warning
L.DURABILITYWARNING_TITLE = "耐久度警告"
L.DURABILITYWARNING_DESC = "當你身上磨損最嚴重的裝備耐久度低於你選擇的數值時警告一次，"
    .. "裝備損壞時再警告一次，讓你及時修理。只有在修理之後才會再次警告。"
L.DURABILITYWARNING_THRESHOLD = "警告門檻"
L.DURABILITYWARNING_THRESHOLD_DESC = "當你穿著的物品耐久度低於這個數值時警告。"
L.DURABILITYWARNING_BROKEN = "損壞時警告"
L.DURABILITYWARNING_BROKEN_DESC = "當你穿著的物品損壞、不再提供屬性時，再警告一次。"
L.DURABILITYWARNING_ALERT = "畫面提示"
L.DURABILITYWARNING_ALERT_DESC = "在畫面中央以紅字顯示警告，也就是遊戲顯示「物品欄已滿。」的位置。"
L.DURABILITYWARNING_SOUND_DESC = "警告時播放音效。選擇音效時會播放一次。"
L.DURABILITYWARNING_CHAT_DESC = "在聊天中顯示哪件物品磨損以及剩餘多少。登入時已經磨損的裝備，"
    .. "在載入完成後只會顯示這一行。"
L.DURABILITYWARNING_LOW_ITEM = "%s的耐久度剩下%d%%。請盡快修理。" -- item link, percent
L.DURABILITYWARNING_LOW_GEAR = "你的裝備耐久度剩下%d%%。請盡快修理。" -- percent
L.DURABILITYWARNING_BROKEN_ITEM = "%s已損壞。修理後即可恢復其屬性。" -- item link
L.DURABILITYWARNING_BROKEN_GEAR = "你穿著的一件物品已損壞。修理後即可恢復其屬性。"
L.DURABILITYWARNING_ALERT_LOW = "你的裝備耐久度剩下%d%%" -- percent
L.DURABILITYWARNING_ALERT_BROKEN = "你穿著的一件物品已損壞"
L.DURABILITYWARNING_TEST = "測試警告"
L.DURABILITYWARNING_TEST_BUTTON = "測試"
L.DURABILITYWARNING_TEST_DESC = "立即以所有已開啟的方式發出耐久度過低警告。"

-- Talent Planner
L.TALENTPLANNER_TITLE = "天賦規劃"
L.TALENTPLANNER_DESC = "在天賦視窗加入「規劃天賦」按鈕：依順序自由配置天賦，"
    .. "最多到你選擇之等級所擁有的點數，並在升級時依照規劃進行。"
L.TALENTPLANNER_GLOW = "標示下一個天賦"
L.TALENTPLANNER_GLOW_DESC = "當你有點數可用時，讓規劃中的下一個天賦發出金光。"
L.TALENTPLANNER_TOOLTIP = "提示資訊"
L.TALENTPLANNER_TOOLTIP_DESC = "在天賦的提示資訊中加入規劃在哪些等級點這個天賦。"
L.TALENTPLANNER_REMINDER = "升級提醒"
L.TALENTPLANNER_REMINDER_DESC = "獲得天賦點數時，在聊天中顯示規劃中的下一個天賦。"
-- talent, the rank this point takes it to, its most ranks
L.TALENTPLANNER_REMINDER_LINE = "有天賦點數可用。規劃中的下一個：%s（%d/%d）。"
L.TALENTPLANNER_PLAN = "規劃天賦"
L.TALENTPLANNER_DONE = "完成規劃"
L.TALENTPLANNER_PLAN_DESC = "配置天賦而不學習它們。每次點擊會依序在規劃中加入一點，讓你升級時照著點。"
    .. "規劃會儲存在此角色上。"
L.TALENTPLANNER_CLICK = "<點擊以加入一點>\n<右鍵點擊以移除一點>\n<按住Shift鍵可一次加入或移除所有等級>"
L.TALENTPLANNER_CLICK_MAXED = "<右鍵點擊以移除一點>\n<按住Shift鍵可一次移除所有等級>" -- at its highest rank
-- With the controller interface on, where there are no clicks
-- Each %s is a button as the player's controller shows it (Gamepad.Label): A, then Y
L.TALENTPLANNER_CLICK_PAD = "<按%s以加入一點>\n<按%s以移除一點>"
L.TALENTPLANNER_CLICK_PAD_MAXED = "<按%s以移除一點>" -- at its highest rank
L.TALENTPLANNER_PLANNED = "規劃等級："
L.TALENTPLANNER_POINTS = "已規劃點數：%d/%d" -- planned, points at the plan's level
L.TALENTPLANNER_MORE = "（此等級之後還有%d點）"
L.TALENTPLANNER_NEXT = "下一個：%s（等級%d）" -- talent name, level
L.TALENTPLANNER_COMPLETE = "天賦規劃已完成。"
L.TALENTPLANNER_ORDER = "天賦順序"
L.TALENTPLANNER_UPCOMING = "接下來的天賦"
L.TALENTPLANNER_LEVEL_ONE = "等級%d"
L.TALENTPLANNER_LEVEL_RANGE = "等級%d-%d" -- first and last level
L.TALENTPLANNER_MORE_LINES = "...以及其他%d個"
L.TALENTPLANNER_LEVEL = "等級"
L.TALENTPLANNER_LEVEL_DESC = "只規劃角色在這個等級時擁有的天賦點數。"
L.TALENTPLANNER_CLEAR = "清除"
L.TALENTPLANNER_CLEAR_DESC = "從規劃中移除所有點數。"
L.TALENTPLANNER_CLEAR_CONFIRM = "要清除你的天賦規劃嗎？"
L.TALENTPLANNER_RESET = "重置"
L.TALENTPLANNER_RESET_DESC = "從你已學會的天賦重新開始規劃。"
L.TALENTPLANNER_RESET_CONFIRM = "要從你已學會的天賦重新開始天賦規劃嗎？"
L.TALENTPLANNER_NO_POINTS = "等級%d時已沒有剩餘的天賦點數。"
L.TALENTPLANNER_MAXED = "這個天賦已達最高等級。"
L.TALENTPLANNER_TIER = "需要在%2$s投入%1$d點。" -- points, tab name
L.TALENTPLANNER_PREREQ = "需要%s達到最高等級。" -- talent names
L.TALENTPLANNER_NEEDED = "在這之後規劃的天賦需要這一點。"
L.TALENTPLANNER_PLAN_NAME = "規劃%d"
L.TALENTPLANNER_NEW = "新規劃"
L.TALENTPLANNER_NEW_PROMPT = "為新的天賦規劃命名。它會從你已學會的天賦開始。"
L.TALENTPLANNER_RENAME = "重新命名規劃"
L.TALENTPLANNER_RENAME_PROMPT = "重新命名這個天賦規劃："
L.TALENTPLANNER_SHARE = "分享規劃"
L.TALENTPLANNER_SHARE_PROMPT = "按Ctrl+C複製這個天賦規劃。同職業的任何角色都能以「匯入規劃」讀取它。"
L.TALENTPLANNER_IMPORT = "匯入規劃"
L.TALENTPLANNER_IMPORT_DESC = "貼上從Forever++分享的天賦規劃，或talentsforever.com、"
    .. "wowforevertalents.com的配點連結，作為新的規劃。"
L.TALENTPLANNER_IMPORT_PROMPT = "貼上分享的天賦規劃，或talentsforever.com、wowforevertalents.com的"
    .. "配點連結（Ctrl+V）："
L.TALENTPLANNER_IMPORT_BAD = "這不是分享的天賦規劃，也不是talentsforever.com或wowforevertalents.com的配點連結。"
L.TALENTPLANNER_IMPORT_CLASS = "這個天賦規劃屬於其他職業。"
L.TALENTPLANNER_IMPORT_INVALID = "這個天賦規劃與此天賦樹不符。"
-- The %s in these three is the site the link is from, such as talentsforever.com.
L.TALENTPLANNER_IMPORT_OLD = "這個連結來自較舊版本的%s。請在該網站開啟後重新複製連結。"
L.TALENTPLANNER_IMPORT_NEW = "這個連結來自比此版本Forever++能讀取的更新版本的%s。請更新Forever++後再匯入。"
L.TALENTPLANNER_IMPORT_TREE = "你的天賦樹與該連結在%s上製作時的天賦樹不同，因此無法確定點數的位置。"
L.TALENTPLANNER_IMPORT_RANK = "這個連結在某個天賦上投入的點數超過該天賦的等級上限。"
L.TALENTPLANNER_IMPORT_POINTS = "這個連結使用了%d點天賦點數，超過角色擁有的%d點。"
L.TALENTPLANNER_DELETE = "刪除規劃"
L.TALENTPLANNER_DELETE_CONFIRM = "要刪除這個天賦規劃嗎？"

-- Macros
L.MACROS_DESC = "Forever++在你的通用巨集中建立並持續更新的巨集，每個都有自己的核取方塊，"
    .. "關閉時就會刪除。從巨集視窗（/macro）拖曳，或使用它的「撿拾」按鈕。"
L.MACROS_NOTICE = "戰鬥中無法變更巨集：戰鬥結束後才會更新。"
L.MACROS_NOTICE_DESC = "遊戲不允許插件在戰鬥中建立或變更巨集。戰鬥結束前，巨集會維持上一次的內容，"
    .. "若內容不符合你的新目標，它的按鈕會顯示警告。"
L.MACROS_FAILED = "無法建立%s巨集：%s" -- the macro's name, then why
L.MACROS_FULL_REASON = "已經沒有空間可以再建立通用巨集"
L.MACROS_MISSING = "%s巨集尚未建立"
L.MACROS_IN_COMBAT = "戰鬥中無法撿拾巨集。"
L.MACROS_PICKUP_BUTTON = "撿拾"
L.MACROS_SMARTBUFF = "智慧增益"
-- The macro's name, at most 16 letters. The same in every language: the module finds its macro
-- by this name, so another name would make a second one.
L.MACROS_SMARTBUFF_DESC = "一個巨集，會為你的友方目標（沒有目標時則是你自己）施放他應該從你身上得到的增益效果，"
    .. "並使用他能接受的最高等級：依職業施放力量祝福或智慧祝福、真言術：韌、秘法智慧、野性印記等；"
    .. "若這些都不適合他，就施放他可能用不上、但不會取代你其他增益的效果。"
    .. "他已經有的增益，或更強的同類效果（例如強效祝福或堅韌禱言）會被略過；"
    .. "若他無法從你身上得到任何增益，就改為對你施放；兩者都沒有可施放的時，它的按鈕會顯示紅色的X。"
    .. "戰鬥中它無法變更：當它會施放錯誤的增益時會顯示警告。"
L.MACROS_SMARTBUFF_RECAST = "重新施放門檻"
L.MACROS_SMARTBUFF_RECAST_DESC = "剩餘時間少於這個比例的增益會被視為缺少，巨集會再次施放："
    .. "設為50%時，30分鐘的增益會在最後15分鐘內重新施放。"
L.MACROS_SMARTBUFF_RECAST_FORMAT = "%d%%"
L.MACROS_SMARTBUFF_TARGET = "你的目標"
L.MACROS_SMARTBUFF_HAS = "%s已經有%s" -- the target, then the buff
L.MACROS_SMARTBUFF_HAS_SELF = "%s已經有%s，改為對你施放"
L.MACROS_SMARTBUFF_HAS_ALL = "%s已經有你能給予的所有增益"
L.MACROS_SMARTBUFF_HAS_ALL_SELF = "%s已經有你能給予的所有增益，改為對你施放"
L.MACROS_SMARTBUFF_CANT = "無法對%s施放增益"
L.MACROS_SMARTBUFF_CANT_SELF = "無法對%s施放增益，改為對你施放"
L.MACROS_SMARTBUFF_NOTHING = "你已經有你能擁有的所有增益"
L.MACROS_SMARTBUFF_COMMAND = "顯示智慧增益如何判斷你的友方目標（或你自己）：你的每一個增益、"
    .. "他有哪些，以及它會施放什麼"
L.MACROS_SMARTBUFF_STALE = "智慧增益無法在戰鬥中變更"
L.MACROS_SMARTBUFF_PICKUP = "智慧增益巨集"
L.MACROS_SMARTBUFF_PICKUP_DESC = "將智慧增益巨集放到游標上，以便拖放到快捷列。"

-- Professions
L.PROFESSIONS_DESC = "在專業視窗中加入：依技能提升機率著色的配方、每個配方還能提升幾次技能、"
    .. "配方改變顏色之等級的進度條、配方的製作成本與產物價值的比較，以及你尚未學會的配方。"
    .. "每一項都有自己的核取方塊。"
L.PROFESSIONS_NO_PRICES = "「製作成本」沒有拍賣價格：「物品提示資訊」的「顯示拍賣價格」已關閉。"
L.PROFESSIONS_NO_PRICES_DESC = "沒有拍賣價格時，「製作成本」只會計算商人的售價和收購價，"
    .. "因此大多數總額會顯示「無價格」，大多數配方也不會顯示利潤。"
-- Recipe Colors
L.PROFESSIONS_COLORS = "配方顏色"
L.PROFESSIONS_COLORS_DESC = "依技能提升機率為配方清單中的配方著色：橘色一定提升、黃色通常提升、"
    .. "綠色偶爾提升、灰色不會提升。"
L.PROFESSIONS_HIGHLIGHT = "列醒目提示著色"
L.PROFESSIONS_HIGHLIGHT_DESC = "讓配方被選取和滑鼠指向時的醒目提示顏色與其名稱相同。"
L.PROFESSIONS_GRAY = "已完成的配方顯示灰色"
L.PROFESSIONS_GRAY_DESC = "以灰色顯示你已學會、但無法再提升技能的配方。"
-- Skill-Ups Left
L.PROFESSIONS_SKILLUPS = "剩餘技能提升"
L.PROFESSIONS_SKILLUPS_DESC = "顯示你已學會的每個配方還能提升技能多久：在它那一列顯示數字，"
    .. "並在選取的配方名稱下方顯示一行。"
L.PROFESSIONS_POINTS = "配方清單中的技能提升"
L.PROFESSIONS_POINTS_DESC = "在每個仍能提升技能的配方最後顯示一個數字：變成灰色前還剩幾次提升，或它在多少技能時變成灰色。"
L.PROFESSIONS_POINTS_LEFT = "剩餘次數"
L.PROFESSIONS_POINTS_GRAY = "變灰等級"
L.PROFESSIONS_POINTS_OFF = "關閉"
L.PROFESSIONS_DETAIL = "選取配方的技能提升"
L.PROFESSIONS_DETAIL_DESC = "在選取的配方名稱下方，顯示它在多少技能時停止提升，以及還剩幾次。"
    .. "顯示「技能進度條」時，會由其進度條取代。"
L.PROFESSIONS_DETAIL_UNTIL = "技能提升至%d" -- the skill a recipe turns gray at
L.PROFESSIONS_DETAIL_MORE = "技能提升至%d %s" -- the skill, then PROFESSIONS_DETAIL_LEFT in gray
L.PROFESSIONS_DETAIL_LEFT = "（還有%d次）"
L.PROFESSIONS_DETAIL_DONE = "無法再提升技能（%d時變灰）"
-- Skill Bar
L.PROFESSIONS_BAR = "技能進度條"
L.PROFESSIONS_BAR_DESC = "在選取的配方名稱下方，顯示它變成黃色、綠色和灰色之技能等級的進度條，並標示你的技能。"
L.PROFESSIONS_BAR_LEVELS = "進度條上顯示等級"
L.PROFESSIONS_BAR_LEVELS_DESC = "在進度條上寫出每種顏色開始的技能等級。無論如何，指向進度條都會列出它們。"
L.PROFESSIONS_BAR_ESTIMATE = "「技能進度條」的等級是估計值。"
L.PROFESSIONS_BAR_ESTIMATE_DESC = "遊戲的配方資訊只提供配方何時變成灰色。黃色等級來自遊戲的資料表，"
    .. "綠色則像經典版一樣取兩者的中間值。等級與遊戲顯示的顏色不符的配方不會顯示進度條。"
L.PROFESSIONS_BAR_YELLOW = "黃色"
L.PROFESSIONS_BAR_GREEN = "綠色"
L.PROFESSIONS_BAR_GRAY = "灰色"
L.PROFESSIONS_BAR_SKILL = "你的技能"
L.PROFESSIONS_BAR_NOTE = "黃色和灰色來自遊戲的資料；綠色取兩者的中間值。"
-- Unlearned Recipes
L.PROFESSIONS_UNLEARNED = "未學配方"
L.PROFESSIONS_UNLEARNED_DESC = "配方清單「過濾方式」選單中的「顯示未學習的配方」，會像現代版遊戲一樣，"
    .. "把這個專業中你尚未學會的配方列在清單裡，並顯示學習所需的技能（綠色為現在、黃色為即將、"
    .. "紅色為之後），在其頁面中還會顯示教導它的配方物品。「未學」子選單可篩選它們。"
-- Shown where the client lacks Blizzard's own strings for these.
L.PROFESSIONS_UNLEARNED_MENU = "未學"
L.PROFESSIONS_UNLEARNED_SOURCES = "來源"
L.PROFESSIONS_UNLEARNED_LEARNED_DESC = "在配方清單中列出你已學會的配方。開啟「顯示未學習的配方」時關閉此項，"
    .. "就只會看到尚未學會的。清單的「過濾方式」選單中也有相同的核取方塊。"
L.PROFESSIONS_UNLEARNED_SHOW_DESC = "在配方清單中列出你尚未學會的配方，各自放在已學配方的同一類別中。"
    .. "清單的「過濾方式」選單中也有相同的核取方塊。"
L.PROFESSIONS_UNLEARNED_ITEMS = "配方物品"
L.PROFESSIONS_UNLEARNED_ITEMS_DESC = "由配方物品（設計圖、圖樣、公式）教導的配方。"
L.PROFESSIONS_UNLEARNED_OTHERS = "訓練師和其他"
L.PROFESSIONS_UNLEARNED_OTHERS_DESC = "沒有配方物品教導的配方：來自訓練師等。"
L.PROFESSIONS_UNLEARNED_WHEN = "可學習時機"
L.PROFESSIONS_UNLEARNED_NOW = "現在"
L.PROFESSIONS_UNLEARNED_NOW_DESC = "你的技能已足以學習的配方。"
L.PROFESSIONS_UNLEARNED_SOON = "即將"
L.PROFESSIONS_UNLEARNED_SOON_DESC = "你還差幾點技能就能學習的配方。"
L.PROFESSIONS_UNLEARNED_UNKNOWN = "未知"
L.PROFESSIONS_UNLEARNED_UNKNOWN_DESC = "所需技能尚未知道的配方：大多是訓練師的配方，"
    .. "直到你開啟教導它們的訓練師為止。"
L.PROFESSIONS_UNLEARNED_WITHIN = "「即將」的範圍"
L.PROFESSIONS_UNLEARNED_WITHIN_DESC = "配方距離你的技能還差多少點時，仍算是即將可以學習。"
L.PROFESSIONS_UNLEARNED_LATER = "之後"
L.PROFESSIONS_UNLEARNED_LATER_DESC = "距離學會還差較多技能點數，或所需技能點數超過目前專業等級上限的配方。"
L.PROFESSIONS_UNLEARNED_BAGS = "背包中的配方"
L.PROFESSIONS_UNLEARNED_BAGS_DESC = "只限你正攜帶其配方物品的配方。"
L.PROFESSIONS_UNLEARNED_LIMITS = "「未學配方」會在你開啟訓練師時，得知其配方所需的技能。"
L.PROFESSIONS_UNLEARNED_LIMITS_DESC = "遊戲的資料表會提供配方物品所需的技能，但不包含訓練師要求的技能。"
    .. "這會從你開啟的每位專業訓練師記錄下來，供整個帳號使用；在那之前，該配方會列在「未知」底下。"
L.PROFESSIONS_UNLEARNED_TAUGHT = "學習來源：%s" -- the item, with what follows it
L.PROFESSIONS_UNLEARNED_OWNED = "%s |cff20ff20（在你的背包中）|r" -- the item's name
L.PROFESSIONS_UNLEARNED_PRICED = "%s  %s" -- the item, its auction price
-- Crafting Costs
L.PROFESSIONS_CRAFTING = "製作成本"
L.PROFESSIONS_CRAFTING_DESC = "為選取的配方顯示總成本、價值和預估利潤（扣除拍賣場5%手續費後），"
    .. "以及所用拍賣價格中最舊的掃描時間。商人售價較便宜時，材料以商人售價計算；"
    .. "沒有拍賣價格的物品，以商人的收購價計算其價值。"
L.PROFESSIONS_CRAFTING_ROWS = "配方清單中顯示利潤"
L.PROFESSIONS_CRAFTING_ROWS_DESC = "在配方清單中每個配方那一列的右側顯示預估利潤，賺錢為綠色、虧損為紅色。"
    .. "不產生物品的附魔則不顯示。"
L.PROFESSIONS_CRAFTING_TOOLTIP = "配方上顯示製作成本"
L.PROFESSIONS_CRAFTING_TOOLTIP_DESC = "在學會之前，於設計圖、圖樣或公式的提示資訊中顯示製作該配方的成本："
    .. "與專業視窗中相同的總成本。"
L.PROFESSIONS_CRAFTING_SELL = "出售管道"
L.PROFESSIONS_CRAFTING_SELL_DESC = "價值和預估利潤假設製作出的物品在哪裡售出。"
    .. "「較高價格」會取拍賣場（扣除手續費後）或商人中付得較多的一方。"
    .. "在拍賣價值下方，「商人價值」會顯示商人會付多少錢。"
L.PROFESSIONS_CRAFTING_SELL_AUCTION = "拍賣場"
L.PROFESSIONS_CRAFTING_SELL_VENDOR = "商人"
L.PROFESSIONS_CRAFTING_SELL_BEST = "較高價格"
L.PROFESSIONS_CRAFT_VENDOR_VALUE = "商人價值"
L.PROFESSIONS_CRAFTING_WRITS = "完成工匠令狀的成本"
L.PROFESSIONS_CRAFTING_WRITS_DESC = "在工匠令狀的提示資訊中，顯示它要求的物品的製作成本，以及在拍賣場購買的成本。"
L.PROFESSIONS_WRIT_BUY = "購買成本"
L.PROFESSIONS_WRIT_COUNT = "%d個"
L.PROFESSIONS_CRAFT_NO_PRICE = "無價格"
L.PROFESSIONS_CRAFT_EACH = "%s  %s" -- coins, then a gray note
L.PROFESSIONS_CRAFT_COST = "總成本"
L.PROFESSIONS_CRAFT_TOOLTIP = "製作成本"
L.PROFESSIONS_CRAFT_PARTIAL = "並非所有材料都有價格"
L.PROFESSIONS_CRAFT_VALUE = "價值"
L.PROFESSIONS_CRAFT_VALUE_COUNT = "價值 x%s" -- how many the recipe makes
L.PROFESSIONS_CRAFT_RANGE = "%d-%d" -- fewest and most the recipe makes
L.PROFESSIONS_CRAFT_VENDOR = "商人"
L.PROFESSIONS_CRAFT_PROFIT = "預估利潤"
L.PROFESSIONS_CRAFT_AGE = "最舊價格"

-- SpellRanks
L.SPELLRANKS_TITLE = "法術等級"
L.SPELLRANKS_PART_SCAN = "掃描法術書" -- its row on the Profiler page
L.SPELLRANKS_DESC = "標示快捷列上你已學會更高等級的法術，並在其提示資訊中註明最高等級。"
    .. "/fpp ranks會列出它們。"
L.SPELLRANKS_STYLE = "標示樣式"
L.SPELLRANKS_STYLE_DESC = "如何標示放有低等級法術的快捷列按鈕。"
L.SPELLRANKS_STYLE_BADGE = "警告徽章"
L.SPELLRANKS_STYLE_TINT = "紅色覆蓋"
L.SPELLRANKS_CORNER_DESC = "警告徽章要顯示在快捷列按鈕的哪個角落。"
L.SPELLRANKS_SIZE = "徽章大小"
L.SPELLRANKS_SIZE_DESC = "警告徽章在標準快捷列按鈕上的大小。在較小或較大的按鈕上會等比例縮放。"
L.SPELLRANKS_TOOLTIP = "提示資訊"
L.SPELLRANKS_TOOLTIP_DESC = "在有更高等級的法術提示資訊中，加入你已學會的最高等級。"
L.SPELLRANKS_REPLACE = "使用最高等級"
L.SPELLRANKS_REPLACE_DESC = "學會法術時，以及開啟此選項時，以你已學會的最高等級取代快捷列上所有較低的等級。"
    .. "只在非戰鬥狀態下進行，且不包括巨集。若你刻意在快捷列上保留較低等級，請保持關閉。"
L.SPELLRANKS_REPLACED = { -- count
    "已將%d個法術換成快捷列上的最高等級。",
}
L.SPELLRANKS_CHAT_DESC = "學會新法術或升級後，在聊天中顯示快捷列上有幾個法術有更高等級，"
    .. "以及「使用最高等級」取代了幾個。"
L.SPELLRANKS_BEST = "已學會更高等級："
L.SPELLRANKS_BEST_RANK = "等級%d" -- the best rank known
L.SPELLRANKS_FOUND = { -- count
    "快捷列上有%d個法術有更高等級。/fpp ranks會列出它們。",
}
L.SPELLRANKS_COMMAND = "列出快捷列上有更高等級的法術"
L.SPELLRANKS_OFF = "「法術等級」已關閉。"
L.SPELLRANKS_NONE = "快捷列上的每個法術都已是最高等級。"
L.SPELLRANKS_LINE = "快捷列%d，欄位%d：%s為等級%d，已學會等級%d。" -- bar, slot, spell link, ranks

-- TrainAll
L.TRAINALL_TITLE = "全部訓練"
L.TRAINALL_DESC = "在訓練師視窗加入「全部訓練」按鈕，學習所有你能學且付得起的技能。新的專業則留給你自己選擇。"
L.TRAINALL_BUTTON = "全部訓練"
L.TRAINALL_TOOLTIP = { "以%2$s學習%1$d項技能。" } -- count, money
L.TRAINALL_NOTHING = "這裡沒有你能學且付得起的技能。"

-- BuffTimers
L.BUFFTIMERS_TITLE = "增益計時"
L.BUFFTIMERS_DESC = "以時鐘格式（例如1:23）顯示增益和減益效果的剩餘時間，取代「2分」這類四捨五入的分鐘數。"
    .. "它也能依剩餘時間排序你的增益，並把追蹤類增益移出增益列。"
L.BUFFTIMERS_NOTICE = "戰鬥中可能會改為顯示暴雪本身的計時。" -- a gray row atop the module
L.BUFFTIMERS_NOTICE_DESC = "戰鬥中遊戲可能會對插件隱藏光環時間。這時會顯示暴雪四捨五入的計時，"
    .. "直到能再次讀取為止。"
L.BUFFTIMERS_BLIZZARD_OFF = "暴雪的增益持續時間已關閉" -- a gray row atop the module, with a button
L.BUFFTIMERS_BLIZZARD_OFF_DESC = "暴雪的增益持續時間已關閉，因此你的增益和減益效果下方不會顯示時間，"
    .. "包括我們的。"
L.BUFFTIMERS_LIMIT = "顯示時鐘"
L.BUFFTIMERS_LIMIT_DESC = "哪些光環使用時鐘格式。較長的光環維持暴雪的計時。"
L.BUFFTIMERS_LIMIT_1M = "少於1分鐘"
L.BUFFTIMERS_LIMIT_10M = "少於10分鐘"
L.BUFFTIMERS_LIMIT_1H = "少於1小時"
L.BUFFTIMERS_LIMIT_ALL = "永遠"
L.BUFFTIMERS_SORT = "增益排序"
L.BUFFTIMERS_SORT_DESC = "依剩餘時間排列你的增益，讓最快結束的在一端、永不結束的在另一端。"
    .. "在垂直排列的增益列中，左側即為上方。"
L.BUFFTIMERS_SORT_OFF = "關閉"
L.BUFFTIMERS_SORT_LEFT = "最短的在左"
L.BUFFTIMERS_SORT_RIGHT = "最短的在右"
L.BUFFTIMERS_SORT_NOTICE = "戰鬥中增益可能會恢復暴雪的順序。" -- a gray row atop the module
L.BUFFTIMERS_SORT_NOTICE_DESC = "戰鬥中遊戲可能會對插件隱藏增益時間。這時獲得或失去增益，"
    .. "會讓你的增益恢復暴雪的順序，直到能再次讀取時間為止。"
L.BUFFTIMERS_HIDE_TRACKING = "隱藏追蹤增益"
L.BUFFTIMERS_HIDE_TRACKING_DESC = "不在增益列顯示小地圖追蹤，例如尋找草藥和尋找礦物。"
    .. "追蹤仍會運作，你可以從小地圖的追蹤選單變更。"
L.BUFFTIMERS_HIDE_NOTICE = "戰鬥中追蹤增益可能會再次出現。" -- a gray row atop the module
L.BUFFTIMERS_HIDE_NOTICE_DESC = "戰鬥中遊戲可能會對插件隱藏哪個增益是哪個。這時獲得或失去增益，"
    .. "會顯示追蹤增益，直到能再次讀取為止。"

-- XPBarText
L.XPBARTEXT_TITLE = "經驗條文字"
L.XPBARTEXT_DESC = "在經驗值欄位上一直顯示你的經驗值，包括百分比、休息經驗值，以及任務將給予的經驗值；"
    .. "若回報任務就能升級，則以綠色顯示。"
L.XPBARTEXT_ALWAYS = "永遠顯示文字"
L.XPBARTEXT_ALWAYS_DESC = "一直顯示文字。關閉後，只有滑鼠指向經驗條時才會顯示，和暴雪的一樣。"
L.XPBARTEXT_PERCENT = "顯示百分比"
L.XPBARTEXT_PERCENT_DESC = "以升到下一級所需經驗值為基準，用百分比顯示目前進度、休息經驗值和任務經驗值。"
L.XPBARTEXT_RESTED = "顯示休息經驗值"
L.XPBARTEXT_RESTED_DESC = "顯示你還剩多少休息經驗值。"
L.XPBARTEXT_QUESTS = "顯示任務經驗值"
L.XPBARTEXT_QUESTS_DESC = "顯示任務日誌中任務給予的經驗值：只限可以回報的，或全部任務。"
L.XPBARTEXT_QUESTS_COMPLETE = "可以回報的"
L.XPBARTEXT_QUESTS_ALL = "所有任務"
L.XPBARTEXT_QUESTS_OFF = "關閉"
L.XPBARTEXT_QUEST_COLOR = "任務可升級時顯示綠色"
L.XPBARTEXT_QUEST_COLOR_DESC = "若回報這些任務就能升級，以綠色顯示任務經驗值文字。"
L.XPBARTEXT_RATE = "顯示每小時經驗值"
L.XPBARTEXT_RATE_DESC = "在你玩了一分鐘並獲得一些經驗值後，顯示登入以來的每小時經驗值，以及照此速度升級所需的時間。"
L.XPBARTEXT_QUEST_BAR = "在經驗條顯示可回報任務的經驗值"
L.XPBARTEXT_QUEST_BAR_DESC = "像顯示休息經驗值一樣，在你的經驗值之後，以綠色延伸可回報任務的經驗值。"
L.XPBARTEXT_SECTION_TEXT = "文字"
L.XPBARTEXT_SECTION_BAR = "經驗條和提示資訊"
L.XPBARTEXT_TOOLTIP = "詳細提示資訊"
L.XPBARTEXT_TOOLTIP_DESC = "在經驗條的提示資訊中加入升級所需經驗值、休息經驗值、任務經驗值，"
    .. "以及登入以來的每小時經驗值和升級所需時間。"
L.XPBARTEXT_TIP_LEFT = "距離升級："
L.XPBARTEXT_TIP_RESTED = "休息："
L.XPBARTEXT_TIP_READY = "可回報任務："
L.XPBARTEXT_TIP_ALL = "所有任務："
L.XPBARTEXT_TIP_RATE = "每小時經驗值："
L.XPBARTEXT_TIP_TIME = "升級所需時間："
L.XPBARTEXT_XP = "經驗值：%s / %s" -- current, needed for the level
L.XPBARTEXT_WITH_PERCENT = "%s（%d%%）" -- the XP text, its percent
L.XPBARTEXT_AMOUNT = "%s（%d%%）" -- an amount of XP, as a percent of the level
L.XPBARTEXT_RESTED_TEXT = "休息：%s"
L.XPBARTEXT_QUESTS_TEXT = "任務：%s"
L.XPBARTEXT_RATE_TEXT = "%s/小時（升級需%s）" -- XP per hour, time to level as a clock

-- RepBarText
L.REPBARTEXT_TITLE = "聲望條文字"
L.REPBARTEXT_DESC = "在聲望條上一直顯示你的聲望，包括百分比和關係。它的提示資訊還會顯示距離下一個關係還差多少，"
    .. "以及登入以來獲得了多少。"
L.REPBARTEXT_ALWAYS = "永遠顯示文字"
L.REPBARTEXT_ALWAYS_DESC = "一直顯示文字。關閉後，只有滑鼠指向聲望條時才會顯示。"
L.REPBARTEXT_PERCENT = "顯示百分比"
L.REPBARTEXT_PERCENT_DESC = "顯示你在目前關係中的進度。"
L.REPBARTEXT_STANDING = "顯示關係"
L.REPBARTEXT_STANDING_DESC = "在陣營名稱後顯示你的關係，例如友好。"
L.REPBARTEXT_RATE = "顯示每小時聲望"
L.REPBARTEXT_RATE_DESC = "顯示登入以來的每小時聲望，以及照此速度達到下一個關係所需的時間。"
L.REPBARTEXT_TOOLTIP = "提示資訊"
L.REPBARTEXT_TOOLTIP_DESC = "為聲望條加上提示資訊，顯示你的關係、距離下一個關係還差多少聲望，"
    .. "以及登入以來獲得了多少和速度。"
L.REPBARTEXT_AUTO_WATCH = "追蹤獲得聲望的陣營"
L.REPBARTEXT_AUTO_WATCH_DESC = "獲得某個陣營的聲望時，將聲望條切換到該陣營。聲望視窗中位於收合標題下的陣營不會被偵測到。"
L.REPBARTEXT_NAME_STANDING = "%s（%s）" -- the faction, your standing
L.REPBARTEXT_REP = "%s：%s / %s" -- the faction (and standing), reputation into it, what it needs
L.REPBARTEXT_WITH_PERCENT = "%s（%d%%）" -- the reputation text, its percent
L.REPBARTEXT_AMOUNT = "%s（%d%%）" -- an amount of reputation, as a percent of the standing
L.REPBARTEXT_RATE_TEXT = "%s/小時（%s後達到%s）" -- reputation per hour, time as a clock, the next standing
L.REPBARTEXT_TIP_STANDING = "關係："
L.REPBARTEXT_TIP_LEFT = "距離%s：" -- the next standing
L.REPBARTEXT_TIP_SESSION = "本次登入："
L.REPBARTEXT_TIP_RATE = "每小時聲望："
L.REPBARTEXT_TIP_TIME = "達到%s所需時間：" -- the next standing
