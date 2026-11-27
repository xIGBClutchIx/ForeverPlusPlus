local _, ns = ...
local L = ns.NewLocale("ruRU")
if not L then
    return
end

-- FastLoot
L.FASTLOOT_TITLE = "Быстрый сбор добычи"
L.FASTLOOT_DESC = "При включенном автосборе добычи забирать все сразу, не дожидаясь окна добычи."
L.FASTLOOT_BLIZZARD_OFF = "Автосбор добычи Blizzard выключен" -- a gray row under the checkbox, with a button
L.FASTLOOT_BLIZZARD_OFF_DESC = "Автосбор добычи Blizzard выключен, поэтому быстро собирается только "
    .. "добыча, которую вы берете, удерживая клавишу автосбора (Shift)."

-- AutoRepair
L.AUTOREPAIR_TITLE = "Авторемонт"
L.AUTOREPAIR_DESC = "Чинить все снаряжение при разговоре с торговцем, который умеет чинить, и "
    .. "сообщать в чате стоимость. Удерживайте клавишу пропуска, чтобы не чинить."
L.AUTOREPAIR_FUNDS = "Платить"
L.AUTOREPAIR_FUNDS_DESC = "Чьи деньги идут на ремонт."
L.AUTOREPAIR_FUNDS_GUILD_FIRST = "Из банка гильдии, затем свои"
L.AUTOREPAIR_FUNDS_GUILD = "Только из банка гильдии"
L.AUTOREPAIR_FUNDS_OWN = "Только свои деньги"
L.AUTOREPAIR_MIN_COST = "Минимальная стоимость"
L.AUTOREPAIR_MIN_COST_DESC = "Чинить, только если ремонт стоит не меньше этой суммы, чтобы короткая "
    .. "остановка у торговца не тратила каждый раз по нескольку медяков."
L.AUTOREPAIR_MIN_COST_ANY = "Любая"
L.AUTOREPAIR_KEY_DESC = "Удерживайте эту клавишу при разговоре с торговцем, чтобы не чинить снаряжение."
L.AUTOREPAIR_CHAT_DESC = "Сообщать в чате, сколько стоил ремонт или почему его не удалось оплатить."
L.AUTOREPAIR_REPAIRED = "Ремонт: %s." -- cost
L.AUTOREPAIR_REPAIRED_GUILD = "Ремонт за счет банка гильдии: %s." -- cost
L.AUTOREPAIR_NO_MONEY = "Недостаточно денег на ремонт (%s)." -- cost
L.AUTOREPAIR_NO_GUILD_MONEY = "Банк гильдии не может оплатить ремонт (%s)." -- cost

-- AutoOpen
L.AUTOOPEN_TITLE = "Автооткрытие контейнеров"
L.AUTOOPEN_DESC = "Самостоятельно открывать контейнеры в сумках, например раковины, мешки и "
    .. "вскрытые сейфы. Ожидает окончания боя, незаметности, произнесения заклинания и закрытия окон "
    .. "добычи, торговца, почты, банка, обмена или аукциона."
L.AUTOOPEN_FREE_SLOTS = "Оставлять свободные ячейки"
L.AUTOOPEN_FREE_SLOTS_DESC = "Ничего не открывать, пока свободных ячеек в сумках меньше этого "
    .. "числа, чтобы содержимому было куда деться."
L.AUTOOPEN_SPECIAL = "Открывать особые контейнеры"
L.AUTOOPEN_SPECIAL_DESC = "Открывать и те немногие контейнеры, которые обычно оставляются на ваше "
    .. "усмотрение: мешки самоцветов с рейдовых и мировых боссов, праздничные подарки, а также "
    .. "сундуки и ящики с предметом для задания, рецептом или снаряжением."
L.AUTOOPEN_PICK_LOCKS = "Взлом замков правым щелчком"
L.AUTOOPEN_PICK_LOCKS_DESC = "Щелкните правой кнопкой мыши по запертому сейфу в сумке, чтобы "
    .. "применить к нему «Взлом замка», после чего он откроется."
L.AUTOOPEN_CHAT_DESC = "Сообщать в чате, что было открыто."
L.AUTOOPEN_OPENED = "Открыто: %s." -- one or more item links, each maybe with a count
L.AUTOOPEN_COUNT = "%s x%d" -- item link, how many
-- AutoSellJunk
L.AUTOSELLJUNK_TITLE = "Автопродажа хлама"
L.AUTOSELLJUNK_DESC = "Продавать серые предметы из сумок при разговоре с торговцем и сообщать в чате "
    .. "выручку. Удерживайте клавишу пропуска, чтобы не продавать."
L.AUTOSELLJUNK_BUYBACK = "Сохранять возможность выкупа"
L.AUTOSELLJUNK_BUYBACK_DESC = "Продавать хлама не больше, чем помещается в списке выкупа торговца "
    .. "рядом с тем, что вы продали сами, чтобы все проданное по ошибке можно было выкупить."
L.AUTOSELLJUNK_KEY_DESC = "Удерживайте эту клавишу при разговоре с торговцем, чтобы не продавать хлам."
L.AUTOSELLJUNK_CHAT_DESC = "Сообщать в чате, сколько предметов продано и за сколько, и сколько "
    .. "осталось непроданными, потому что список выкупа заполнен."
-- count, money; the forms go by the count
L.AUTOSELLJUNK_SOLD = {
    "Продан %d предмет хлама за %s.",
    "Продано %d предмета хлама за %s.",
    "Продано %d предметов хлама за %s.",
}
-- count, money, how many were left; the forms go by the first count
L.AUTOSELLJUNK_SOLD_FULL = {
    "Продан %d предмет хлама за %s. Список выкупа заполнен, не продано: %d.",
    "Продано %d предмета хлама за %s. Список выкупа заполнен, не продано: %d.",
    "Продано %d предметов хлама за %s. Список выкупа заполнен, не продано: %d.",
}
L.AUTOSELLJUNK_FULL = { -- count
    "Список выкупа заполнен: не продан %d предмет хлама.",
    "Список выкупа заполнен: не продано %d предмета хлама.",
    "Список выкупа заполнен: не продано %d предметов хлама.",
}

-- GatheringTracking
L.GATHERINGTRACKING_TITLE = "Поиск ресурсов"
L.GATHERINGTRACKING_DESC = "Держать включенным «Поиск минералов» или «Поиск трав»: включать снова "
    .. "после входа в игру, смены зоны или смерти и, если хотите, чередовать их. Дворфы могут "
    .. "добавить «Поиск сокровищ»."
L.GATHERINGTRACKING_TRACK = "Отслеживать"
L.GATHERINGTRACKING_TRACK_DESC = "Какое отслеживание держать включенным. Игра отслеживает что-то одно, "
    .. "поэтому оба вида включаются по очереди."
L.GATHERINGTRACKING_TRACK_BOTH = "Минералы и травы"
L.GATHERINGTRACKING_TRACK_MINERALS = "Только минералы"
L.GATHERINGTRACKING_TRACK_HERBS = "Только травы"
L.GATHERINGTRACKING_REAPPLY = "Включать снова"
L.GATHERINGTRACKING_REAPPLY_DESC = "После входа в игру, смены зоны или воскрешения снова включать "
    .. "отслеживание, если ничего не отслеживается: другое заклинание поиска, например «Выслеживание "
    .. "животных», если в последний раз было включено оно, или выбранное здесь. Если выключить "
    .. "отслеживание самому, оно остается выключенным до этого момента."
L.GATHERINGTRACKING_TREASURE = "Поиск сокровищ"
L.GATHERINGTRACKING_TREASURE_DESC = "Держать включенным и «Поиск сокровищ» дворфов. Он чередуется с "
    .. "выбранным выше отслеживанием или остается единственным, если вы не знаете ни того, ни другого."
L.GATHERINGTRACKING_SWAP = "Чередовать"
L.GATHERINGTRACKING_SWAP_DESC = "Переключаться между выбранными видами отслеживания, пока один из "
    .. "них включен. Ожидает во время боя, произнесения заклинаний и полетов."
L.GATHERINGTRACKING_SWAP_EVERY_NAME = "Переключать каждые"
L.GATHERINGTRACKING_SWAP_EVERY_DESC = "Сколько ждать между переключениями."
L.GATHERINGTRACKING_MUTE_SWAP = "Без звука переключения"
L.GATHERINGTRACKING_MUTE_SWAP_DESC = "Выключать звуковые эффекты игры на мгновение каждого "
    .. "переключения, чтобы заклинание поиска звучало беззвучно. Другой звук, играющий в этот момент, "
    .. "может оборваться."
L.GATHERINGTRACKING_ANNOUNCE = "Сообщать о включении"
L.GATHERINGTRACKING_ANNOUNCE_DESC = "Сообщать в чате, когда отслеживание включено снова за вас, как "
    .. "только игра покажет его включенным. Полезно, если эффект отслеживания скрыт."
L.GATHERINGTRACKING_ANNOUNCED = "Снова включено: %s." -- a tracking spell's name
L.GATHERINGTRACKING_CHAT = "Предупреждения"
L.GATHERINGTRACKING_CHAT_DESC = "Сообщать в чате, когда игра не дает модулю «Поиск ресурсов» "
    .. "сменить отслеживание."
L.GATHERINGTRACKING_FAILED = "Модулю «Поиск ресурсов» не удалось сменить отслеживание: %s" -- error
L.GATHERINGTRACKING_BLOCKED = "Игра запретила модулю «Поиск ресурсов» менять отслеживание. Он не "
    .. "будет работать до /reload."

-- AutoStow
L.AUTOSTOW_TITLE = "Автоубирание оружия"
L.AUTOSTOW_DESC = "Убирать оружие, если оно было в руках несколько секунд вне боя, – неважно, "
    .. "осталось оно после боя или вы достали его сами."
L.AUTOSTOW_DELAY = "Задержка"
L.AUTOSTOW_DELAY_DESC = "Сколько оружие остается в руках после боя или после того, как вы его "
    .. "достали, прежде чем будет убрано."
L.AUTOSTOW_OUTSIDE_ONLY = "Только вне подземелий"
L.AUTOSTOW_OUTSIDE_ONLY_DESC = "Не убирать оружие в подземельях, рейдах и на полях боя, где "
    .. "следующий бой всегда рядом."

-- AutoDismount
L.AUTODISMOUNT_TITLE = "Автоспешивание"
L.AUTODISMOUNT_DESC = "Спешиваться или вставать, когда действие не удается, потому что вы верхом "
    .. "или сидите: произнесение заклинания, полет или сбор добычи."
L.AUTODISMOUNT_DISMOUNT = "Спешиваться"
L.AUTODISMOUNT_DISMOUNT_DESC = "Спешиваться, когда вы верхом произносите заклинание, говорите с "
    .. "распорядителем полетов или атакуете."
L.AUTODISMOUNT_STAND = "Вставать"
L.AUTODISMOUNT_STAND_DESC = "Вставать, когда вы сидя произносите заклинание, собираете добычу или "
    .. "атакуете."
L.AUTODISMOUNT_UNSHIFT = "Выходить из облика"
L.AUTODISMOUNT_UNSHIFT_DESC = "Выходить из облика, например облика медведя или кошки у друида, когда "
    .. "вы произносите заклинание, недоступное в нем."

-- AutoGossip
L.AUTOGOSSIP_TITLE = "Автоматический выбор ответа"
L.AUTOGOSSIP_DESC = "Если у NPC только один вариант диалога или одна услуга помимо болтовни и нет "
    .. "заданий, выбирать ее за вас, чтобы банк, лавка, список навыков у наставника или карта "
    .. "полетов открывались сразу."
L.AUTOGOSSIP_SECTION_GENERAL = "Общие"
L.AUTOGOSSIP_SECTION_NPCS = "Выбирать для"
L.AUTOGOSSIP_BANKER = "Банкиры"
L.AUTOGOSSIP_BANKER_DESC = "Открывать банк."
L.AUTOGOSSIP_VENDOR = "Торговцы и ремонт"
L.AUTOGOSSIP_VENDOR_DESC = "Открывать лавку."
L.AUTOGOSSIP_TRAINER = "Наставники"
L.AUTOGOSSIP_TRAINER_DESC = "Открывать список навыков наставника."
L.AUTOGOSSIP_TAXI = "Распорядители полетов"
L.AUTOGOSSIP_TAXI_DESC = "Открывать карту полетов."
L.AUTOGOSSIP_STABLE = "Смотрители стойл"
L.AUTOGOSSIP_STABLE_DESC = "Открывать стойло."
L.AUTOGOSSIP_OTHER = "Другие NPC"
L.AUTOGOSSIP_OTHER_DESC = "Выбирать единственный вариант у любого другого NPC, если только игра не "
    .. "просит сначала прочитать его текст."
L.AUTOGOSSIP_KEY_DESC = "Удерживайте эту клавишу при разговоре с NPC, чтобы выбирать варианты самому."
-- AUTOGOSSIP_TITLE_STABLE is left to enUS: it's matched against the client's own text.

-- AutoDecline
L.AUTODECLINE_TITLE = "Автоотказ"
L.AUTODECLINE_DESC = "Сразу отклонять вызовы на дуэль, а по желанию и приглашения в группу, "
    .. "приглашения в гильдию и хартии гильдий, чтобы окно запроса не мешало."
L.AUTODECLINE_DUELS = "Дуэли"
L.AUTODECLINE_DUELS_DESC = "Отклонять вызовы на дуэль."
L.AUTODECLINE_PARTY_INVITES = "Приглашения в группу"
L.AUTODECLINE_PARTY_INVITES_DESC = "Отклонять также приглашения в группу."
L.AUTODECLINE_GUILD_INVITES = "Приглашения в гильдию"
L.AUTODECLINE_GUILD_INVITES_DESC = "Отклонять также приглашения в гильдию, даже от друзей."
L.AUTODECLINE_GUILD_CHARTERS = "Хартии гильдий"
L.AUTODECLINE_GUILD_CHARTERS_DESC = "Отклонять также просьбы подписать хартию гильдии, даже от друзей. "
    .. "Ваша собственная хартия по-прежнему открывается."
L.AUTODECLINE_ALLOW_FRIENDS = "Кроме друзей и гильдии"
L.AUTODECLINE_ALLOW_FRIENDS_DESC = "Пропускать вызовы на дуэль и приглашения в группу от ваших друзей, "
    .. "друзей Battle.net и согильдийцев."
L.AUTODECLINE_CHAT_DESC = "Сообщать в чате, чей вызов, приглашение или хартия были отклонены."
L.AUTODECLINE_DECLINED = "Отклонен вызов на дуэль: %s." -- player name
L.AUTODECLINE_DECLINED_INVITE = "Отклонено приглашение в группу: %s." -- player name
L.AUTODECLINE_DECLINED_GUILD_INVITE = "Отклонено приглашение в гильдию: %s." -- player name
L.AUTODECLINE_DECLINED_CHARTER = "Запрос на подпись хартии отклонен. Инициатор: %s." -- player name
L.AUTODECLINE_SOMEONE = "кто-то"

-- AutoConfirm
L.AUTOCONFIRM_TITLE = "Автоподтверждение"
L.AUTOCONFIRM_DESC = "Отвечать «Да» на запрос, который появляется перед заменой чар на предмете, "
    .. "чтобы при развитии наложения чар на каждые чары уходил один щелчок."
L.AUTOCONFIRM_REPLACE = "Замена чар"
L.AUTOCONFIRM_REPLACE_DESC = "Подтверждать чары, которые заменяют уже наложенные на предмет."
L.AUTOCONFIRM_BIND = "Привязка предмета"
L.AUTOCONFIRM_BIND_DESC = "Подтверждать чары, которые делают предмет персональным. После этого "
    .. "предмет нельзя будет передать или выставить на аукцион."
L.AUTOCONFIRM_TRADEBIND = "Привязка при обмене"
L.AUTOCONFIRM_TRADEBIND_DESC = "Закрывать предупреждение о том, что чары, наложенные в окне обмена, "
    .. "могут сделать предмет персональным, чтобы обмен продолжился."

-- AutoRelease
L.AUTORELEASE_TITLE = "Автовозвращение духа"
L.AUTORELEASE_DESC = "Покидать тело при смерти на поле боя, если только вы не можете воскресить "
    .. "себя сами или вас кто-то воскрешает."
L.AUTORELEASE_DELAY = "Задержка"
L.AUTORELEASE_DELAY_DESC = "Сколько ждать после смерти, прежде чем покинуть тело."
L.AUTORELEASE_NOW = "Сразу"
L.AUTORELEASE_KEY_DESC = "Удерживайте эту клавишу, пока вы мертвы, чтобы остаться там, где пали."
L.AUTORELEASE_CHAT_DESC = "Сообщать в чате, когда дух покинул тело или почему этого не произошло."
L.AUTORELEASE_RELEASED = "Дух покинул тело."
L.AUTORELEASE_SELF_RES = "Тело не покинуто: вы можете воскресить себя сами."
L.AUTORELEASE_RES_OFFER = "Тело не покинуто: вас кто-то воскрешает."

-- SkipCinematics
L.SKIPCINEMATICS_TITLE = "Пропуск роликов"
L.SKIPCINEMATICS_DESC = "Пропускать заставки и видеоролики игры: все или только уже просмотренные."
L.SKIPCINEMATICS_SKIP = "Пропускать"
L.SKIPCINEMATICS_SKIP_DESC = "Какие заставки и видеоролики пропускать. Просмотренные учитываются для "
    .. "всех ваших персонажей."
L.SKIPCINEMATICS_SKIP_SEEN = "Только просмотренные"
L.SKIPCINEMATICS_SKIP_ALL = "Все"
L.SKIPCINEMATICS_KEY = "Клавиша просмотра"
L.SKIPCINEMATICS_KEY_DESC = "Удерживайте эту клавишу в начале заставки или видеоролика, чтобы "
    .. "посмотреть его."
L.SKIPCINEMATICS_CHAT_DESC = "Сообщать в чате о пропуске заставки или видеоролика."
L.SKIPCINEMATICS_SKIPPED_CINEMATIC = "Заставка пропущена."
L.SKIPCINEMATICS_SKIPPED_MOVIE = "Видеоролик пропущен."
L.SKIPCINEMATICS_RESET = "Просмотренные ролики"
L.SKIPCINEMATICS_RESET_BUTTON = "Очистить"
L.SKIPCINEMATICS_RESET_DESC = "Забыть, какие заставки и видеоролики вы смотрели, чтобы каждый "
    .. "проигрался еще раз."
L.SKIPCINEMATICS_RESET_CONFIRM = "Забыть, какие заставки и видеоролики вы смотрели?"
L.SKIPCINEMATICS_RESET_DONE = "Список просмотренных роликов очищен."


-- FishingCast
L.FISHINGCAST_TITLE = "Заброс удочки"
L.FISHINGCAST_DESC = "Двойной щелчок правой кнопкой мыши по миру с удочкой в руках забрасывает "
    .. "удочку («Рыбная ловля»)."
L.FISHINGCAST_SPEED = "Скорость двойного щелчка"
L.FISHINGCAST_SPEED_DESC = "Как быстро второй щелчок правой кнопкой должен последовать за первым."
L.FISHINGCAST_MS = "%d мс" -- milliseconds
L.FISHINGCAST_COMBAT = "Предупреждение в бою"
L.FISHINGCAST_COMBAT_DESC = "Один раз предупреждать в начале боя, если в руках удочка."
L.FISHINGCAST_COMBAT_TEXT = "У вас в руках удочка."
L.FISHINGCAST_LOUDER = "Громкий поплавок"
L.FISHINGCAST_LOUDER_DESC = "Во время рыбалки делать звуковые эффекты громче, а музыку тише, чтобы "
    .. "всплеск было легко услышать. Ваша громкость возвращается, когда вы закончите."


-- AutoWeaponBuff
L.AUTOWEAPONBUFF_TITLE = "Автоусиление оружия"
L.AUTOWEAPONBUFF_DESC = "Щелкните правой кнопкой мыши по точильному камню, грузу, маслу, яду или "
    .. "приманке в сумке или используйте их с панели команд, чтобы сразу наложить на оружие: в "
    .. "правую руку или в левую, если подходит только оно."
L.AUTOWEAPONBUFF_NOTICE = "Работает только вне боя." -- a gray row atop the module
L.AUTOWEAPONBUFF_NOTICE_DESC = "Игра не дает модификациям менять действие щелчка по сумке или панели "
    .. "команд в бою, поэтому до конца боя они работают как у Blizzard."
L.AUTOWEAPONBUFF_WARN = "Предупреждать, если нет подходящего оружия"
L.AUTOWEAPONBUFF_WARN_DESC = "Если ни одно надетое оружие не подходит для предмета, например груз "
    .. "при одних клинках, сообщать об этом красным вверху экрана вместо курсора выбора цели."
L.AUTOWEAPONBUFF_WARN_TEXT = "Ни одно надетое оружие не подходит: %s." -- item name
L.AUTOWEAPONBUFF_WARN_TEXT_ANY = "Ни одно надетое оружие для этого не подходит."
L.AUTOWEAPONBUFF_LEARNED_LINE = "Усиление оружия: %s, тип оружия – %s." -- item name, weapon type

-- ComprehendScrolls
L.COMPREHENDSCROLLS_TITLE = "Понимание свитков"
L.COMPREHENDSCROLLS_DESC = "Щелкните правой кнопкой мыши по свитку мага в сумке, чтобы применить к "
    .. "нему «Понимание свитка», не открывая книгу заклинаний."
L.COMPREHENDSCROLLS_NOTICE = "Работает только вне боя." -- a gray row atop the module
L.COMPREHENDSCROLLS_NOTICE_DESC = "Игра не дает модификациям менять действие щелчка по сумке в бою, "
    .. "поэтому до конца боя правый щелчок работает как у Blizzard."

-- AutoScreenshot
L.AUTOSCREENSHOT_TITLE = "Автоснимок экрана"
L.AUTOSCREENSHOT_DESC = "Делать снимок экрана при получении уровня, достижения, победе над боссом и "
    .. "в другие памятные моменты."
L.AUTOSCREENSHOT_SECTION_GENERAL = "Общие"
L.AUTOSCREENSHOT_SECTION_EVENTS = "Делать снимок, когда"
L.AUTOSCREENSHOT_HIDE_UI = "Скрывать интерфейс"
L.AUTOSCREENSHOT_HIDE_UI_DESC = "Скрывать интерфейс для снимка, как это делает Alt+Z. Не в бою: там "
    .. "игра этого не позволяет."
L.AUTOSCREENSHOT_HIDE_OWN = "Снимки вручную"
L.AUTOSCREENSHOT_HIDE_OWN_DESC = "Скрывать интерфейс и для снимков, которые вы делаете клавишей "
    .. "снимка экрана (Print Screen), даже если все моменты ниже выключены. Не в бою."
L.AUTOSCREENSHOT_NO_HDR = "Выключать HDR для снимка"
L.AUTOSCREENSHOT_NO_HDR_DESC = "При включенном HDR снимки выходят блеклыми. Этот параметр выключает "
    .. "HDR на момент снимка и потом включает снова. Ничего не делает, если HDR выключен. Не в бою."
L.AUTOSCREENSHOT_CHAT_DESC = "Сообщать в чате, почему сделан снимок."
L.AUTOSCREENSHOT_PLAYED_TIME = "Время в игре при новом уровне"
L.AUTOSCREENSHOT_PLAYED_TIME_DESC = "При получении уровня показывать в чате время в игре (/played), "
    .. "чтобы оно попало на снимок."
L.AUTOSCREENSHOT_TAKEN = "Снимок экрана: %s." -- the checkbox's name, such as Level Up
L.AUTOSCREENSHOT_LEVEL_UP = "Новый уровень"
L.AUTOSCREENSHOT_LEVEL_UP_DESC = "Когда вы получаете новый уровень."
L.AUTOSCREENSHOT_ACHIEVEMENT = "Достижение"
L.AUTOSCREENSHOT_ACHIEVEMENT_DESC = "Когда вы получаете достижение, которого еще нет у другого вашего "
    .. "персонажа."
L.AUTOSCREENSHOT_LOOT = "Добыча"
L.AUTOSCREENSHOT_LOOT_DESC = "Когда вы получаете предмет указанного ниже качества или лучше."
L.AUTOSCREENSHOT_LOOT_QUALITY = "Качество добычи"
L.AUTOSCREENSHOT_LOOT_QUALITY_DESC = "Самое низкое качество предмета, при котором делается снимок."
L.AUTOSCREENSHOT_QUALITY_RARE = "Редкое"
L.AUTOSCREENSHOT_QUALITY_EPIC = "Эпическое"
L.AUTOSCREENSHOT_QUALITY_LEGENDARY = "Легендарное"
L.AUTOSCREENSHOT_BOSS_KILL = "Победа над боссом"
L.AUTOSCREENSHOT_BOSS_KILL_DESC = "Когда ваша группа побеждает босса подземелья или рейда."
L.AUTOSCREENSHOT_REPUTATION = "Репутация"
L.AUTOSCREENSHOT_REPUTATION_DESC = "Когда вы достигаете с фракцией уровня «Дружелюбие», «Уважение», "
    .. "«Почтение» или «Превознесение»."
L.AUTOSCREENSHOT_PVP_RANK = "PvP-звание"
L.AUTOSCREENSHOT_PVP_RANK_DESC = "Когда вы получаете новое PvP-звание."
L.AUTOSCREENSHOT_NEW_TITLE = "Новое звание"
L.AUTOSCREENSHOT_NEW_TITLE_DESC = "Когда вы получаете новое звание."
L.AUTOSCREENSHOT_BATTLEGROUND = "Конец поля боя"
L.AUTOSCREENSHOT_BATTLEGROUND_DESC = "Когда бой на поле боя заканчивается, с открытой таблицей "
    .. "результатов."
L.AUTOSCREENSHOT_DEATH = "Смерть"
L.AUTOSCREENSHOT_DEATH_DESC = "Когда вы погибаете."
