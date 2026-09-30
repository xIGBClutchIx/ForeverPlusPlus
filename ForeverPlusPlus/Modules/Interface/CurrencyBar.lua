-- Currency Bar: a small box, drawn like a Blizzard tooltip, that shows your gold and the
-- currencies you have ticked "Show on Backpack" in the Currency tab, so they are in view without
-- opening a window. Which currencies show is Blizzard's own choice, not ours. Move it in Edit Mode.
local _, ns = ...

local GetMoney, C_CurrencyInfo, GameTooltip = GetMoney, C_CurrencyInfo, GameTooltip
local CreateFrame, UIParent = CreateFrame, UIParent
local format, max, floor, tconcat = string.format, math.max, math.floor, table.concat
local BreakUpLargeNumbers = BreakUpLargeNumbers

local L = ns.L

local module = ns.NewModule("CurrencyBar", L.CURRENCYBAR_DESC, {
    enabled = false,
    money = true,
    currencies = true,
    vertical = false,
    scale = 100, -- percent
    x = 0, -- the box's offset from the center of the screen
    y = -300,
})
module.title = L.CURRENCYBAR_TITLE
module.category = "interface"

module.options = {
    { key = "money", name = L.CURRENCYBAR_MONEY, description = L.CURRENCYBAR_MONEY_DESC },
    { key = "currencies", name = L.CURRENCYBAR_CURRENCIES, description = L.CURRENCYBAR_CURRENCIES_DESC },
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
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L.CURRENCYBAR_TITLE)
        GameTooltip:AddLine(L.CURRENCYBAR_HINT, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
    box:Hide()
    return box
end

-- Edit Mode ---------------------------------------------------------------------------------------

local function moved(x, y)
    module.db.x, module.db.y = x, y
end

module.actions = {
    {
        name = L.CURRENCYBAR_RESET_POSITION,
        button = L.CURRENCYBAR_RESET_POSITION_BUTTON,
        description = L.CURRENCYBAR_RESET_POSITION_DESC,
        fn = function()
            module.db.x, module.db.y = DEFAULT_X, DEFAULT_Y
            if frame then
                place()
            end
        end,
    },
}

function module:OnEnable()
    if not frame then
        frame = newFrame()
    end
    place()
    update()
    frame:Show()
    self:On("PLAYER_MONEY", update)
    self:On("CURRENCY_DISPLAY_UPDATE", update)
    self:On("PLAYER_ENTERING_WORLD", update)
    ns.EditMode.Register(frame, L.CURRENCYBAR_TITLE, moved)
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
