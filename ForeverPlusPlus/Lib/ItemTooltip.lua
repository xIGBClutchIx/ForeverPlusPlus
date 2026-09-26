-- Price lines in item tooltips, kept together where Blizzard puts the sell price. Modules add a
-- line with `OnPrices`, and one module may redraw the sell price line itself with
-- `ReplaceSellPrice`. Lines go right after the sell price, or at the end when the item has none.
-- Nothing is hooked until a module first calls in.
local _, ns = ...

local ipairs, setmetatable, format = ipairs, setmetatable, string.format
local TooltipDataProcessor, Enum, C_Item, GameTooltip = TooltipDataProcessor, Enum, C_Item, GameTooltip
local IsShiftKeyDown, GetMoneyString, C_CurrencyInfo = IsShiftKeyDown, GetMoneyString, C_CurrencyInfo
local HIGHLIGHT_FONT_COLOR, GRAY_FONT_COLOR = HIGHLIGHT_FONT_COLOR, GRAY_FONT_COLOR

local L = ns.L

local ItemTooltip = {}
ns.ItemTooltip = ItemTooltip

local providers = {} -- fn(tooltip, data), in the order added
local replacer -- fn(tooltip, data, lineData) -> true when it drew the sell price line
local done = setmetatable({}, { __mode = "k" }) -- tooltip -> price lines already added
local current = setmetatable({}, { __mode = "k" }) -- tooltip -> item data being drawn

-- The item a line belongs to: from the item pre call, or else the tooltip's own data (probe:
-- GetPrimaryTooltipData is Mainline's tooltip data mixin).
local function itemData(tooltip)
    if current[tooltip] then
        return current[tooltip]
    end
    local data = tooltip.GetPrimaryTooltipData and tooltip:GetPrimaryTooltipData()
    if data and data.type == Enum.TooltipDataType.Item then
        return data
    end
end

local function addPrices(tooltip, data)
    done[tooltip] = true
    for _, fn in ipairs(providers) do
        fn(tooltip, data)
    end
end

local function onSellPricePre(tooltip, lineData)
    local data = replacer and itemData(tooltip)
    if data and replacer(tooltip, data, lineData) then
        addPrices(tooltip, data)
        return true -- Blizzard's line is skipped; ours is in its place
    end
end

local function onSellPricePost(tooltip)
    local data = not done[tooltip] and itemData(tooltip)
    if data then
        addPrices(tooltip, data)
    end
end

local function onItemPre(tooltip, data)
    current[tooltip] = data
    done[tooltip] = nil
end

local function onItem(tooltip, data)
    if not done[tooltip] and data then
        addPrices(tooltip, data)
    end
    done[tooltip] = nil
    current[tooltip] = nil
end

-- Redraws the item tooltip when Shift goes up or down, so lines that depend on it change.
local function onModifier(_, key)
    local shift = key == "LSHIFT" or key == "RSHIFT"
    if shift and GameTooltip:IsShown() and GameTooltip.RefreshData then
        GameTooltip:RefreshData()
    end
end

local hooked = false

local function hook()
    if hooked then
        return
    end
    hooked = true
    local lineType = Enum.TooltipDataLineType and Enum.TooltipDataLineType.SellPrice
    if lineType and TooltipDataProcessor.AddLinePreCall then
        TooltipDataProcessor.AddLinePreCall(lineType, onSellPricePre)
    end
    if lineType and TooltipDataProcessor.AddLinePostCall then
        TooltipDataProcessor.AddLinePostCall(lineType, onSellPricePost)
    end
    if TooltipDataProcessor.AddTooltipPreCall then
        TooltipDataProcessor.AddTooltipPreCall(Enum.TooltipDataType.Item, onItemPre)
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItem)
    ns.On("MODIFIER_STATE_CHANGED", onModifier)
end

---Calls `fn(tooltip, data)` on every item tooltip, where the price lines go. Hooks can't be
---removed, so `fn` checks whether its module is on.
---@param fn fun(tooltip: table, data: table)
function ItemTooltip.OnPrices(fn)
    hook()
    providers[#providers + 1] = fn
end

---Lets `fn(tooltip, data, lineData)` draw the sell price line instead of Blizzard. It returns
---true when it drew one; otherwise Blizzard's line shows.
---@param fn fun(tooltip: table, data: table, lineData: table): boolean?
function ItemTooltip.ReplaceSellPrice(fn)
    hook()
    replacer = fn
end

---How many items the hovered stack holds, or 1 when it can't tell (links, merchants).
---@param data table tooltip data
---@return number
function ItemTooltip.StackCount(data)
    if data.guid and C_Item.GetItemLocation and C_Item.GetStackCount then
        local location = C_Item.GetItemLocation(data.guid)
        if location and location:IsValid() then
            return C_Item.GetStackCount(location) or 1
        end
    end
    return 1
end

---How many items a price line counts: the whole stack, or one while Shift is held. `mode`
---"one" turns that round (one, and the stack with Shift).
---@param data table tooltip data
---@param mode string "stack" or "one"
---@return number
function ItemTooltip.PriceCount(data, mode)
    local stack = (mode == "one") == IsShiftKeyDown()
    return stack and ItemTooltip.StackCount(data) or 1
end

local function money(amount)
    -- Probe: GetMoneyString is Mainline FrameXML; the coin text is the fallback.
    if GetMoneyString then
        return GetMoneyString(amount, true)
    end
    return C_CurrencyInfo.GetCoinTextureString(amount)
end

---Adds a price line: the name and a gray "x20" on the left, the coins on the right, so every
---price line's coins line up.
---@param tooltip table
---@param name string such as "Sell Price"
---@param amount number copper, for all `count` items
---@param count number how many items the price is for
function ItemTooltip.AddPrice(tooltip, name, amount, count)
    local quantity = GRAY_FONT_COLOR:WrapTextInColorCode(format(L.PRICE_QUANTITY, count))
    local r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB()
    tooltip:AddDoubleLine(format(L.PRICE_LINE, name, quantity), money(amount), r, g, b, r, g, b)
end
