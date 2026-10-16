-- Upgrade Arrows: Blizzard's green arrow on gear that beats what you wear, judged by stat weights
-- for your class and talent tree (Weights.lua), in your bags and bank, at merchants, on loot and
-- loot rolls, on quest reward choices, and in the auction house, each with its own checkbox, and
-- the arrow with the percentage to the right of the item's name in its tooltip.
--
-- An item's score is its stats (Lib/ItemStats.lua) times the profile's weights; what it would
-- replace comes from the client's own item comparison (Lib/Equipment.lua), so a ring is judged
-- against the weaker ring and a two-hander against both hands. Scores are kept per item link
-- and forgotten when what you wear, your level, your talents, or the weights change.
--
-- The arrow is our own texture over the icon, with the atlas Blizzard's bag buttons keep in a
-- hidden UpgradeIcon region, in the corner and at the size the Arrow options pick, with the
-- percentage under it; nothing is written onto Blizzard's frames.
local _, ns = ...

local _G, ipairs, type, wipe, select, tonumber = _G, ipairs, type, wipe, select, tonumber
local format, floor, huge = string.format, math.floor, math.huge
local C_Container, C_AddOns, UnitClass = C_Container, C_AddOns, UnitClass

local L = ns.L
local ItemButtons, ItemStats, Equipment, Talents = ns.ItemButtons, ns.ItemStats, ns.Equipment, ns.Talents
local ItemTooltip = ns.ItemTooltip

local module = ns.NewModule("UpgradeArrows", L.UPGRADEARROWS_DESC, {
    enabled = false,
    profile = "auto", -- "auto" (the tab with the most points), "1" to "3" (a tab), or "bear"
    threshold = 0, -- percent an item must beat what you wear by
    corner = "TOPRIGHT", -- where the arrow sits on an icon
    size = 18, -- the arrow's size on a bag icon, in pixels
    percent = false, -- the percentage under the arrow on icons (the tooltip always has it)
    tooltip = true,
    scores = false,
    bags = true,
    bank = true,
    merchant = true,
    loot = true,
    quests = true,
    auction = false,
    weights = {}, -- data: profile key -> { stat -> weight }, what the player changed
})
module.title = L.UPGRADEARROWS_TITLE
module.category = "items"
module.added = "0.10.0"
module.internal = {}
local internal = module.internal

-- The Profile dropdown's choices. The tabs' names fill in once the talent data is there.
local PROFILE_CHOICES = {
    { "auto", L.UPGRADEARROWS_PROFILE_AUTO },
    { "1", format(L.UPGRADEARROWS_PROFILE_TREE, 1) },
    { "2", format(L.UPGRADEARROWS_PROFILE_TREE, 2) },
    { "3", format(L.UPGRADEARROWS_PROFILE_TREE, 3) },
    { "bear", L.UPGRADEARROWS_PROFILE_BEAR },
}

module.options = {
    {
        key = "profile", name = L.UPGRADEARROWS_PROFILE, description = L.UPGRADEARROWS_PROFILE_DESC,
        section = L.UPGRADEARROWS_SECTION_GENERAL, choices = PROFILE_CHOICES,
    },
    {
        key = "threshold", name = L.UPGRADEARROWS_THRESHOLD, description = L.UPGRADEARROWS_THRESHOLD_DESC,
        section = L.UPGRADEARROWS_SECTION_GENERAL, min = 0, max = 25, step = 1, format = "%d%%",
    },
    {
        key = "tooltip", name = L.UPGRADEARROWS_TOOLTIP, description = L.UPGRADEARROWS_TOOLTIP_DESC,
        section = L.UPGRADEARROWS_SECTION_GENERAL,
    },
    {
        key = "scores", name = L.UPGRADEARROWS_SCORES, description = L.UPGRADEARROWS_SCORES_DESC,
        section = L.UPGRADEARROWS_SECTION_GENERAL, requires = "tooltip",
    },
    {
        key = "corner", name = L.UPGRADEARROWS_CORNER, description = L.UPGRADEARROWS_CORNER_DESC,
        section = L.UPGRADEARROWS_SECTION_ARROW,
        choices = {
            { "TOPRIGHT", L.UPGRADEARROWS_CORNER_TOPRIGHT },
            { "TOPLEFT", L.UPGRADEARROWS_CORNER_TOPLEFT },
        },
    },
    {
        key = "size", name = L.UPGRADEARROWS_SIZE, description = L.UPGRADEARROWS_SIZE_DESC,
        section = L.UPGRADEARROWS_SECTION_ARROW, min = 12, max = 32, step = 2, format = "%d px",
    },
    {
        key = "percent", name = L.UPGRADEARROWS_PERCENT_ICON, description = L.UPGRADEARROWS_PERCENT_ICON_DESC,
        section = L.UPGRADEARROWS_SECTION_ARROW,
    },
    { key = "bags", name = L.UPGRADEARROWS_BAGS, description = L.UPGRADEARROWS_BAGS_DESC, section = L.UPGRADEARROWS_SECTION_SHOW },
    { key = "bank", name = L.UPGRADEARROWS_BANK, description = L.UPGRADEARROWS_BANK_DESC, section = L.UPGRADEARROWS_SECTION_SHOW },
    { key = "merchant", name = L.UPGRADEARROWS_MERCHANT, description = L.UPGRADEARROWS_MERCHANT_DESC, section = L.UPGRADEARROWS_SECTION_SHOW },
    { key = "loot", name = L.UPGRADEARROWS_LOOT, description = L.UPGRADEARROWS_LOOT_DESC, section = L.UPGRADEARROWS_SECTION_SHOW },
    { key = "quests", name = L.UPGRADEARROWS_QUESTS, description = L.UPGRADEARROWS_QUESTS_DESC, section = L.UPGRADEARROWS_SECTION_SHOW },
    { key = "auction", name = L.UPGRADEARROWS_AUCTION, description = L.UPGRADEARROWS_AUCTION_DESC, section = L.UPGRADEARROWS_SECTION_SHOW },
}

-- A gray row in Settings while the UpgradeArrow addon is on too, since then every upgrade gets
-- two arrows.
module.notice = {
    text = L.UPGRADEARROWS_OTHER_ADDON,
    description = L.UPGRADEARROWS_OTHER_ADDON_DESC,
    shown = function()
        return module.enabled and C_AddOns and C_AddOns.IsAddOnLoaded
            and ns.IsTrue(C_AddOns.IsAddOnLoaded("UpgradeArrow"))
    end,
}

local ATLAS = "bags-greenarrow" -- the arrow Blizzard's bag buttons keep hidden
local GREEN = { 0.1, 1, 0.1 } -- Blizzard's green font color

-- The profile ---------------------------------------------------------------------------------

local profile -- { key, template, weights, guess }, from Weights.lua

-- Reads the profile the Profile option and the talents give. Guessed (the first tab) while
-- there's no talent data or no points spent, so it's read again when talents change.
local function updateProfile()
    local _, class = UnitClass("player")
    class = ns.IsText(class, true) and class or "?"
    local tabs = Talents.Tabs()
    for i = 1, 3 do
        local tab = tabs and tabs[i]
        if tab and tab.name ~= "" then
            PROFILE_CHOICES[i + 1][2] = tab.name
        end
    end
    local choice = module.db.profile
    local index, guess, bear
    if choice == "bear" and class == "DRUID" then
        bear = true
    elseif tonumber(choice) then
        index = tonumber(choice)
    else
        local best = tabs and Talents.Dominant()
        if best and best.spent > 0 then
            index = best.index
        else
            index, guess = 1, true
        end
    end
    profile = internal.Profile(class, index, bear)
    profile.guess = guess
end

---The profile in use: `{ key, template, weights, guess }`, for the weights page.
---@return table?
function internal.CurrentProfile()
    return profile
end

-- Scores ----------------------------------------------------------------------------------------

local results = {} -- link -> { upgrade, percent, score, rival }, or false for an item that's no upgrade candidate
local waiting = {} -- itemID -> true while the game has no data for it yet

-- The scoring's own row on the Profiler page.
local Profiler = ns.Profiler
local PART_SCORE = Profiler.Part(module, L.UPGRADEARROWS_PART_SCORE)

local function scoreOf(info)
    return ItemStats.Score(ItemStats.Slotted(info.stats, info.slot), profile.weights)
end

-- What an item is worth against what it would replace, or nil while an item involved isn't
-- cached (noted in `waiting`). False for something that can't be an upgrade: not gear, can't be
-- used, or worn already.
local function compute(link)
    local info, itemID = ItemStats.Get(link)
    if not info then
        if itemID then
            waiting[itemID] = true
        end
        return nil
    end
    if not Equipment.Slots(info.slot) or not Equipment.CanUse(link, info.minLevel)
        or Equipment.IsWorn(link) then
        return false
    end
    local score = scoreOf(info)
    local rival
    for _, alternative in ipairs(Equipment.Rivals(link, info.slot)) do
        local sum = 0
        for _, wornLink in ipairs(alternative) do
            local wornInfo, wornID = ItemStats.Get(wornLink)
            if not wornInfo then
                if wornID then
                    waiting[wornID] = true
                end
                return nil
            end
            sum = sum + scoreOf(wornInfo)
        end
        if not rival or sum < rival then
            rival = sum
        end
    end
    rival = rival or 0
    local upgrade, percent = ItemStats.Compare(score, rival, module.db.threshold)
    return { upgrade = upgrade, percent = percent, score = score, rival = rival }
end

-- An item's result, kept per link until something it depends on changes.
local function evaluate(link)
    if not (link and profile) then
        return nil
    end
    local result = results[link]
    if result == nil then
        result = Profiler.Call(PART_SCORE, compute, link)
        if result ~= nil then
            results[link] = result
        end
    end
    return result
end

-- An item's result when it's an upgrade, else false.
local function upgradeOf(link)
    local result = link and evaluate(link)
    return result and result.upgrade and result or false
end

local function forgetScores()
    wipe(results)
end

-- Arrows ----------------------------------------------------------------------------------------

-- A mark on an icon: our own arrow texture in Blizzard's atlas, and the percentage under it in
-- the outlined number font stack counts use. Shown and hidden together (ItemButtons.Overlays
-- only needs Show and Hide); placed each time it shows, since the Arrow options can change.
local function makeMark(icon)
    local frame = icon.CreateTexture and icon or icon:GetParent()
    local arrow = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    arrow:SetAtlas(ATLAS)
    local text = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    text:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    local mark = { icon = icon, arrow = arrow, text = text }
    function mark:Show()
        arrow:Show()
    end
    function mark:Hide()
        arrow:Hide()
        text:Hide()
    end
    return mark
end

-- On item icons the mark sits on the icon itself; on a quest reward button on its icon region.
local arrows = ItemButtons.Overlays(makeMark)
local rewardArrows = ItemButtons.Overlays(function(button)
    return makeMark(button.Icon or button.icon or button)
end)

local hasArt -- whether this client has the atlas (checked at enable)

-- Shows the mark for an upgrade's `result` on an icon (or clears it), the arrow `size` wide in
-- the corner the Arrow options pick, with the percentage under it when there is one.
local function setArrow(set, key, result, size)
    local mark = set:Set(key, hasArt and result)
    if not mark then
        return
    end
    local corner = module.db.corner
    local arrow, text = mark.arrow, mark.text
    arrow:ClearAllPoints()
    arrow:SetPoint(corner, mark.icon, corner, 0, 0)
    arrow:SetSize(size, size)
    local percent = module.db.percent and type(result) == "table" and result.percent
    if percent then
        text:SetText(format(L.UPGRADEARROWS_PERCENT, percent))
        text:ClearAllPoints()
        if corner == "TOPLEFT" then
            text:SetPoint("TOPLEFT", arrow, "BOTTOMLEFT", 1, 1)
        else
            text:SetPoint("TOPRIGHT", arrow, "BOTTOMRIGHT", -1, 1)
        end
        text:Show()
    else
        text:Hide()
    end
end

-- The arrow's size at a place, from the Arrow Size option (a bag icon's), scaled where the icons
-- are smaller.
local function sizeAt(scale)
    return floor(module.db.size * scale + 0.5)
end

local function clearArrows()
    arrows:HideAll()
    rewardArrows:HideAll()
end

-- Bags and bank ---------------------------------------------------------------------------------

local function updateBag(frame)
    local on = module.db.bags
    ItemButtons.EachBagButton(frame, function(_, icon, bag, slot)
        local link = on and C_Container.GetContainerItemLink(bag, slot)
        setArrow(arrows, icon, link and upgradeOf(link), sizeAt(1))
    end)
end

-- Forever's bank is Blizzard's BankPanel with tabs (as Unusable Items Tint reads it).
local function updateBank()
    local panel = _G.BankPanel
    if not (panel and panel.EnumerateValidItems) then
        return
    end
    local on = module.db.bank
    for button in panel:EnumerateValidItems() do
        local link
        if on and button.GetBankTabID and button.GetContainerSlotID then
            link = C_Container.GetContainerItemLink(button:GetBankTabID(), button:GetContainerSlotID())
        end
        setArrow(arrows, button.icon, link and upgradeOf(link), sizeAt(1))
    end
end

local function hookBank()
    module:Hook(_G.BankPanel, "RefreshAllItemsForSelectedTab", updateBank)
    module:Hook(_G.BankPanel, "GenerateItemSlotsForSelectedTab", updateBank)
end

-- Merchants -------------------------------------------------------------------------------------

local function updateMerchant()
    local on = module.db.merchant
    ItemButtons.EachMerchantItem(function(icon, index)
        local link = on and _G.GetMerchantItemLink(index)
        setArrow(arrows, icon, link and upgradeOf(link), sizeAt(1))
    end)
end

-- The buyback tab reuses the same buttons.
local function clearMerchant()
    ItemButtons.EachMerchantItem(function(icon)
        setArrow(arrows, icon, false)
    end)
end

-- Auction house ---------------------------------------------------------------------------------

-- A browse row gives only an item ID, so an item with a random suffix ("of the Bear") is judged
-- by its base stats, without the suffix's.
local function updateAuction()
    local on = module.db.auction
    ItemButtons.EachAuctionRow(function(icon, itemID)
        setArrow(arrows, icon, on and itemID and upgradeOf("item:" .. itemID), sizeAt(0.6))
    end)
end

-- Loot ------------------------------------------------------------------------------------------

local function markLoot(icon, _, link)
    setArrow(arrows, icon, module.db.loot and link and upgradeOf(link), sizeAt(0.9))
end

local function hookLoot()
    ItemButtons.HookLoot(module, markLoot)
end

local function markRoll(icon, link)
    setArrow(arrows, icon, module.db.loot and link and upgradeOf(link), sizeAt(0.9))
end

-- Quest rewards ---------------------------------------------------------------------------------

local rewardsWaiting -- the rewards frame whose items weren't cached, until GET_ITEM_INFO_RECEIVED

-- The link of a reward choice, from the quest giver or the quest log.
local function choiceLink(index, questLog)
    if questLog then
        return _G.GetQuestLogItemLink and _G.GetQuestLogItemLink("choice", index)
    end
    return _G.GetQuestItemLink and _G.GetQuestItemLink("choice", index)
end

-- Marks the choice that's the biggest upgrade (an empty slot beats any percentage); choices
-- that tie are all marked.
local function updateRewards(rewardsFrame)
    local info = _G.QuestInfoFrame
    local buttons = rewardsFrame and rewardsFrame.RewardButtons
    if not (info and type(buttons) == "table") then
        return
    end
    local best, bestValue = {}, nil
    for _, button in ipairs(buttons) do
        setArrow(rewardArrows, button, false)
        local object = button.objectType
        if module.db.quests and button:IsShown() and button.type == "choice"
            and (object == nil or object == "item") then
            local link = choiceLink(button:GetID(), info.questLog)
            local result = ns.IsText(link, true) and evaluate(link)
            if result == nil and link then
                rewardsWaiting = rewardsFrame
            elseif result and result.upgrade then
                local value = result.percent or huge
                if not bestValue or value > bestValue then
                    best, bestValue = { { button, result } }, value
                elseif value == bestValue then
                    best[#best + 1] = { button, result }
                end
            end
        end
    end
    for _, entry in ipairs(best) do
        setArrow(rewardArrows, entry[1], entry[2], sizeAt(1))
    end
end

local function onQuestDisplay()
    local info = _G.QuestInfoFrame
    updateRewards(info and info.rewardsFrame)
end

-- Tooltips --------------------------------------------------------------------------------------

local function round(number)
    return floor(number + 0.5)
end

-- The item a tooltip shows, by its link.
local function tooltipLink(data)
    if ns.IsText(data.hyperlink, true) then
        return data.hyperlink
    end
    local id = ItemTooltip.ItemID(data)
    return id and ("item:" .. id) or nil
end

-- Draws the name line again with the arrow and the percentage at its right, in green, and
-- returns true so Blizzard's is skipped. The name keeps its quality color.
local function onNameLine(tooltip, data, lineData)
    if not (module.enabled and module.db.tooltip and profile) then
        return
    end
    local lines = ns.IsReadable(data.lines) and data.lines
    if not (type(lines) == "table" and lines[1] == lineData) then
        return
    end
    local name = lineData.leftText
    if not ns.IsText(name, true) then
        return
    end
    local result = upgradeOf(tooltipLink(data))
    if not result then
        return
    end
    local right = hasArt and format("|A:%s:0:0|a", ATLAS) or ""
    if result.percent then
        right = right .. " " .. format(L.UPGRADEARROWS_PERCENT, result.percent)
    end
    local r, g, b = 1, 1, 1
    local color = lineData.leftColor
    if ns.IsReadable(color) and type(color) == "table" and color.GetRGB then
        r, g, b = color:GetRGB()
    end
    tooltip:AddDoubleLine(name, right, r, g, b, GREEN[1], GREEN[2], GREEN[3])
    return true
end

-- The Score line, among our other lines about the item.
local function onTooltip(tooltip, data)
    if not (module.enabled and module.db.tooltip and module.db.scores and profile) then
        return
    end
    local result = evaluate(tooltipLink(data))
    if not result then
        return
    end
    local text
    if result.rival > 0 then
        text = format(L.UPGRADEARROWS_SCORE_VALUE, round(result.score), round(result.rival))
    else
        text = format(L.UPGRADEARROWS_SCORE_NONE, round(result.score))
    end
    ItemTooltip.AddInfo(tooltip, L.UPGRADEARROWS_SCORE_LINE, text, "right", "gray")
end

-- Module ----------------------------------------------------------------------------------------

local function refresh()
    ItemButtons.EachOpenBag(updateBag)
    local bank = _G.BankFrame
    if bank and bank:IsShown() then
        updateBank()
    end
    local merchant = _G.MerchantFrame
    if merchant and merchant:IsShown() and (merchant.selectedTab or 1) == 1 then
        updateMerchant()
    end
    updateAuction()
    ItemButtons.EachLootSlot(markLoot)
    ItemButtons.EachRoll(markRoll)
    local info = _G.QuestInfoFrame
    if info and info.rewardsFrame and info.rewardsFrame:IsVisible() then
        updateRewards(info.rewardsFrame)
    end
end

local refreshSoon, cancelRefresh = ns.Frames.Coalesce(function()
    if module.enabled then
        refresh()
    end
end, 0.5)

-- Item data arrives a little after a window opens; look again once it has, for items we
-- couldn't answer for yet. This fires for every item the game loads.
local function onItemInfo(_, itemID)
    if itemID and waiting[itemID] then
        waiting[itemID] = nil
        refreshSoon()
    elseif rewardsWaiting and rewardsWaiting:IsVisible() then
        refreshSoon()
    end
end

-- What you wear decides every rival, so every score is forgotten.
local function onGearChanged()
    forgetScores()
    refreshSoon()
end

-- Leveling and training change what you can use.
local function onPlayerChanged()
    forgetScores()
    refreshSoon()
end

-- Talents may change the profile; when they do, every score goes with it.
local function onTalentsChanged()
    local before = profile and profile.key
    updateProfile()
    if profile.key ~= before or profile.guess then
        forgetScores()
    end
    refreshSoon()
end

function module:OnEnable()
    hasArt = ns.Frames.HasAtlas(ATLAS)
    updateProfile()
    self:Hook("MerchantFrame_UpdateMerchantInfo", updateMerchant)
    self:Hook("MerchantFrame_UpdateBuybackInfo", clearMerchant)
    ItemButtons.HookBags(self, updateBag)
    hookBank()
    hookLoot()
    ItemButtons.HookRolls(self, markRoll)
    ItemButtons.HookAuction(self, updateAuction)
    self:Hook("QuestInfo_Display", onQuestDisplay)
    ItemTooltip.ReplaceLine(onNameLine, self)
    ItemTooltip.OnInfo(onTooltip, self)
    self:On("LOOT_OPENED", hookLoot)
    self:On("GET_ITEM_INFO_RECEIVED", onItemInfo)
    self:On("PLAYER_EQUIPMENT_CHANGED", onGearChanged)
    self:On("PLAYER_LEVEL_UP", onPlayerChanged)
    self:On("SKILL_LINES_CHANGED", onPlayerChanged)
    self:On("PLAYER_ENTERING_WORLD", onTalentsChanged)
    for _, event in ipairs({ "TRAIT_CONFIG_UPDATED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE" }) do
        if ns.HasEvent(event) then
            self:On(event, onTalentsChanged)
        end
    end
    refresh()
end

function module:OnDisable()
    ItemButtons.CancelAuction(updateAuction)
    cancelRefresh()
    forgetScores()
    wipe(waiting)
    rewardsWaiting = nil
    clearArrows()
end

function module:OnOptionChanged(key)
    if not self.enabled then
        return
    end
    if key == "profile" or key == "threshold" then
        updateProfile()
        forgetScores()
    end
    refreshSoon()
end

---Forgets every score, for the weights page after a weight changes.
function internal.WeightsChanged()
    if module.enabled then
        updateProfile()
        forgetScores()
        refreshSoon()
    end
end

-- The stats met on items that no weight covers, so they can be added (Lib/ItemStats.lua).
module.debugActions = {
    {
        name = L.UPGRADEARROWS_UNKNOWN,
        button = L.UPGRADEARROWS_UNKNOWN_BUTTON,
        description = L.UPGRADEARROWS_UNKNOWN_DESC,
        whileOff = true,
        section = L.DEBUG_SECTION_DIAGNOSTICS,
        fn = function()
            local list = ItemStats.Unknown()
            if #list == 0 then
                ns.Print(L.UPGRADEARROWS_UNKNOWN_NONE)
            else
                ns.Print(format(L.UPGRADEARROWS_UNKNOWN_LIST, table.concat(list, ", ")))
            end
        end,
    },
}
