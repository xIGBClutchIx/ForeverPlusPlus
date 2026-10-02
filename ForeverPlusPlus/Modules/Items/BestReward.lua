-- Best Quest Reward: puts a small gold coin on the quest reward choice that sells to a vendor for
-- the most (sell price times how many you get), in the quest window and the quest's details on
-- the map. It only marks; the choice is still yours. Rewards that tie for the most are all
-- marked, and nothing is marked when every choice sells for the same or for nothing.
--
-- The reward buttons are Blizzard's (QuestInfo_Display fills them, both for a quest giver and the
-- quest log). Probe: those names are Mainline's, unverified on Forever. Our coin is our own
-- texture on the button's icon; nothing is written onto Blizzard's frames.
local _, ns = ...

local _G, setmetatable, pairs, ipairs, select, type = _G, setmetatable, pairs, ipairs, select, type
local C_Item = C_Item

local L = ns.L

local module = ns.NewModule("BestReward", L.BESTREWARD_DESC, { enabled = true })
module.title = L.BESTREWARD_TITLE
module.category = "items"

local COIN_TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"
local COIN_SIZE = 16

local coins = setmetatable({}, { __mode = "k" }) -- reward button -> our coin texture
local waiting -- the rewards frame whose items weren't cached, until GET_ITEM_INFO_RECEIVED

local function setCoin(button, on)
    local coin = coins[button]
    if not on then
        if coin then
            coin:Hide()
        end
        return
    end
    if not coin then
        local icon = button.Icon or button.icon or button
        coin = button:CreateTexture(nil, "OVERLAY", nil, 7)
        coin:SetTexture(COIN_TEXTURE)
        coin:SetSize(COIN_SIZE, COIN_SIZE)
        coin:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 3)
        coins[button] = coin
    end
    coin:Show()
end

local function clearCoins()
    for button in pairs(coins) do
        setCoin(button, false)
    end
end

-- How many of the choice you get and its item ID, from the quest log or the quest giver.
local function choiceInfo(index, questLog)
    local count, itemID, link
    if questLog then
        if _G.GetQuestLogChoiceInfo then
            count, _, _, itemID = select(3, _G.GetQuestLogChoiceInfo(index))
        end
        link = _G.GetQuestLogItemLink and _G.GetQuestLogItemLink("choice", index)
    else
        if _G.GetQuestItemInfo then
            count, _, _, itemID = select(3, _G.GetQuestItemInfo("choice", index))
        end
        link = _G.GetQuestItemLink and _G.GetQuestItemLink("choice", index)
    end
    if type(itemID) ~= "number" and link then
        itemID = C_Item.GetItemInfoInstant(link)
    end
    if type(count) ~= "number" or count < 1 then
        count = 1
    end
    return count, itemID
end

-- What the choice sells for in all, or nil while its item isn't cached (asked for meanwhile).
local function choiceValue(index, questLog)
    local count, itemID = choiceInfo(index, questLog)
    if not itemID then
        return nil
    end
    local price = select(11, C_Item.GetItemInfo(itemID))
    if type(price) ~= "number" then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end
    return price * count
end

local function update(rewardsFrame)
    local info = _G.QuestInfoFrame
    local buttons = rewardsFrame and rewardsFrame.RewardButtons
    if not (info and type(buttons) == "table") then
        return
    end
    -- The item choices among the frame's buttons, by choice index.
    local choices = {}
    for _, button in ipairs(buttons) do
        setCoin(button, false)
        -- Currency choices have no sell price; objectType is Mainline's, so missing means item.
        local object = button.objectType
        if button:IsShown() and button.type == "choice" and (object == nil or object == "item") then
            choices[#choices + 1] = button
        end
    end
    waiting = nil
    if #choices < 2 then
        return
    end
    local values, best, lowest = {}, 0, nil
    for i, button in ipairs(choices) do
        local value = choiceValue(button:GetID(), info.questLog)
        if not value then
            -- Mark nothing until every choice's price is known, then look again.
            waiting = rewardsFrame
            return
        end
        values[i] = value
        if value > best then
            best = value
        end
        if not lowest or value < lowest then
            lowest = value
        end
    end
    if best <= 0 or best == lowest then
        return
    end
    for i, button in ipairs(choices) do
        setCoin(button, values[i] == best)
    end
end

local function onDisplay()
    local info = _G.QuestInfoFrame
    update(info and info.rewardsFrame)
end

local function onItemInfo()
    local frame = waiting
    if frame and frame:IsVisible() then
        update(frame)
    end
end

function module:OnEnable()
    if type(_G.QuestInfo_Display) == "function" then
        self:Hook("QuestInfo_Display", onDisplay)
    end
    self:On("GET_ITEM_INFO_RECEIVED", onItemInfo)
    local info = _G.QuestInfoFrame
    if info and info.rewardsFrame and info.rewardsFrame:IsVisible() then
        onDisplay()
    end
end

function module:OnDisable()
    waiting = nil
    clearCoins()
end
