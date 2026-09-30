-- Currency Bar: a small box, drawn like a Blizzard tooltip, that shows your gold and the
-- currencies you have ticked "Show on Backpack" in the Currency tab, so they are in view without
-- opening a window. Hovering it lists your gold and currencies with what this session gained or spent. Which currencies show is Blizzard's own choice, not ours. Move it in Edit Mode.
local _, ns = ...

local GetMoney, C_CurrencyInfo, GameTooltip = GetMoney, C_CurrencyInfo, GameTooltip
local CreateFrame, UIParent = CreateFrame, UIParent
local format, max, floor, tconcat = string.format, math.max, math.floor, table.concat
local BreakUpLargeNumbers = BreakUpLargeNumbers

local L = ns.L
local Colors = ns.Colors

local module = ns.NewModule("CurrencyBar", L.CURRENCYBAR_DESC, {
    enabled = false,
    money = true,
    currencies = false,
    tooltip = true,
    session = true,
    vertical = false,
    scale = 120, -- percent
    x = 0, -- the box's offset from the center of the screen
    y = -300,
})
module.title = L.CURRENCYBAR_TITLE
module.category = "interface"

module.options = {
    { key = "money", name = L.CURRENCYBAR_MONEY, description = L.CURRENCYBAR_MONEY_DESC },
    { key = "currencies", name = L.CURRENCYBAR_CURRENCIES, description = L.CURRENCYBAR_CURRENCIES_DESC },
    { key = "tooltip", name = L.CURRENCYBAR_TOOLTIP, description = L.CURRENCYBAR_TOOLTIP_DESC },
    {
        key = "session", requires = "tooltip",
        name = L.CURRENCYBAR_SESSION, description = L.CURRENCYBAR_SESSION_DESC,
    },
    { key = "vertical", name = L.CURRENCYBAR_VERTICAL, description = L.CURRENCYBAR_VERTICAL_DESC },
    {
        key = "scale",
        name = L.CURRENCYBAR_SCALE,
        description = L.CURRENCYBAR_SCALE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
}

local DEFAULT_X, DEFAULT_Y = 0, -300
local PAD = 10 -- between the text and the box's edge
local ICON = 14 -- a currency's icon, about the size of the text
local MAX_CURRENCIES = 10 -- far more than the Backpack's three, in case Forever allows more

local frame

-- Gold, silver, and copper as Blizzard draws them, but every coin always: 0 gold still shows.
local function coins(amount)
    local gold = floor(amount / 10000)
    local silver = floor(amount / 100) % 100
    local copper = amount % 100
    local icon = "|TInterface/MoneyFrame/UI-%sIcon:" .. ICON .. ":" .. ICON .. ":2:0|t"
    return (BreakUpLargeNumbers and BreakUpLargeNumbers(gold) or gold) .. format(icon, "Gold")
        .. " " .. silver .. format(icon, "Silver") .. " " .. copper .. format(icon, "Copper")
end

-- The parts --------------------------------------------------------------------------------------

-- What to show, in order: the gold, then each Backpack currency as its icon and amount.
local function parts()
    local list = {}
    if module.db.money then
        list[#list + 1] = coins(GetMoney())
    end
    -- Probe: the Backpack currency list is Mainline's.
    if module.db.currencies and C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
        for index = 1, MAX_CURRENCIES do
            local info = C_CurrencyInfo.GetBackpackCurrencyInfo(index)
            if not info then
                break
            end
            list[#list + 1] = format("%d |T%s:%d|t", info.quantity or 0, info.iconFileID or 134400, ICON)
        end
    end
    return list
end

local function update()
    if not frame then
        return
    end
    local list = parts()
    frame.text:SetText(tconcat(list, module.db.vertical and "\n" or "   "))
    local scale = module.db.scale / 100
    frame.inner:SetScale(scale)
    frame:SetSize(max(frame.text:GetStringWidth(), 24) * scale + PAD * 2,
        max(frame.text:GetStringHeight(), 12) * scale + PAD * 2)
end

local function place()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", module.db.x, module.db.y)
end

-- The session ----------------------------------------------------------------------------------

-- What you had when the box turned on, to say what this session gained or spent. Not saved.
local startMoney
local startCurrency = {} -- currency ID -> amount first seen

local function backpackCurrency(index)
    -- Probe: the Backpack currency list is Mainline's.
    return C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo
        and C_CurrencyInfo.GetBackpackCurrencyInfo(index)
end

-- Remembers each Backpack currency the first time it is seen, so later changes count from there.
local function noteCurrencies()
    for index = 1, MAX_CURRENCIES do
        local info = backpackCurrency(index)
        if not info then
            return
        end
        local id = info.currencyTypesID
        if id and startCurrency[id] == nil then
            startCurrency[id] = info.quantity or 0
        end
    end
end

-- "+12" in green or "-12" in red, or plain 0.
local function signed(change, text)
    if change > 0 then
        return Colors.Code(0.1, 1, 0.1) .. "+" .. text .. "|r"
    elseif change < 0 then
        return Colors.Code(1, 0.2, 0.2) .. "-" .. text .. "|r"
    end
    return "0"
end

local function showTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(L.CURRENCYBAR_TITLE)
    local money = GetMoney()
    GameTooltip:AddDoubleLine(L.CURRENCYBAR_MONEY, ns.Money(money), 1, 1, 1)
    if module.db.session and startMoney then
        local change = money - startMoney
        GameTooltip:AddDoubleLine(L.CURRENCYBAR_SESSION, signed(change, ns.Money(math.abs(change))),
            0.8, 0.8, 0.8)
    end
    local header
    for index = 1, MAX_CURRENCIES do
        local info = backpackCurrency(index)
        if not info then
            break
        end
        if not header then
            header = true
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L.CURRENCYBAR_CURRENCIES)
        end
        local quantity = info.quantity or 0
        local text = BreakUpLargeNumbers and BreakUpLargeNumbers(quantity) or quantity
        local change = quantity - (startCurrency[info.currencyTypesID] or quantity)
        if module.db.session and change ~= 0 then
            text = text .. "  " .. signed(change, BreakUpLargeNumbers
                and BreakUpLargeNumbers(math.abs(change)) or math.abs(change))
        end
        GameTooltip:AddDoubleLine(format("|T%s:%d|t %s", info.iconFileID or 134400, ICON, info.name or ""),
            text, 1, 1, 1, 1, 1, 1)
    end
    if not header then
        GameTooltip:AddLine(L.CURRENCYBAR_HINT, 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

-- The frame ---------------------------------------------------------------------------------------

local function newFrame()
    local hasTemplate = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("TooltipBackdropTemplate")
    -- The same box Blizzard draws tooltips in.
    local box = CreateFrame("Frame", nil, UIParent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    box:SetFrameStrata("MEDIUM")
    if not hasTemplate and box.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        box:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        box:SetBackdropColor(0, 0, 0, 0.8)
    end
    -- The text sits in a child that takes the scale, so the box's own position stays put in Edit Mode.
    box.inner = CreateFrame("Frame", nil, box)
    box.inner:SetSize(1, 1)
    box.inner:SetPoint("CENTER")
    box.text = box.inner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    box.text:SetPoint("CENTER")
    box.text:SetJustifyH("CENTER")
    box:EnableMouse(true)
    box:SetScript("OnEnter", function(self)
        if module.db.tooltip then
            showTooltip(self)
        end
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
    box:Hide()
    return box
end

-- Edit Mode ---------------------------------------------------------------------------------------

local function moved(x, y)
    module.db.x, module.db.y = x, y
end

local function resetPosition()
    module.db.x, module.db.y = DEFAULT_X, DEFAULT_Y
    if frame then
        place()
    end
end

-- What Edit Mode's dialog for the box offers.
local editModeOptions = {
    reset = resetPosition,
    scale = {
        min = 50, max = 200, step = 10, format = "%d%%",
        get = function() return module.db.scale end,
        set = function(value)
            module.db.scale = value
            update()
        end,
    },
}

module.actions = {
    {
        name = L.CURRENCYBAR_RESET_POSITION,
        button = L.CURRENCYBAR_RESET_POSITION_BUTTON,
        description = L.CURRENCYBAR_RESET_POSITION_DESC,
        fn = resetPosition,
    },
}

function module:OnEnable()
    if not frame then
        frame = newFrame()
    end
    startMoney = startMoney or GetMoney()
    noteCurrencies()
    place()
    update()
    frame:Show()
    self:On("PLAYER_MONEY", update)
    self:On("CURRENCY_DISPLAY_UPDATE", function()
        noteCurrencies()
        update()
    end)
    self:On("PLAYER_ENTERING_WORLD", function()
        noteCurrencies()
        update()
    end)
    ns.EditMode.Register(frame, L.CURRENCYBAR_TITLE, moved, editModeOptions)
end

function module:OnDisable()
    if frame then
        ns.EditMode.Unregister(frame)
        frame:Hide()
    end
end

function module:OnOptionChanged()
    update()
end
