-- Price lines in item tooltips, kept together where Blizzard puts the sell price. Modules add a
-- line with `OnPrices`, and one module may redraw the sell price line itself with
-- `ReplaceSellPrice`. Lines go right after the sell price, or at the end when the item has none.
-- Nothing is hooked until a module first calls in.
local _, ns = ...

local ipairs, setmetatable, format, type = ipairs, setmetatable, string.format, type
local floor, max, UIParent = math.floor, math.max, UIParent
local TooltipDataProcessor, Enum, C_Item, GameTooltip = TooltipDataProcessor, Enum, C_Item, GameTooltip
local IsShiftKeyDown = IsShiftKeyDown
local HIGHLIGHT_FONT_COLOR, GRAY_FONT_COLOR = HIGHLIGHT_FONT_COLOR, GRAY_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR

local L = ns.L
local money = ns.Money

local ItemTooltip = {}
ns.ItemTooltip = ItemTooltip

local providers = {} -- fn(tooltip, data), in the order added
local replacer -- fn(tooltip, data, lineData) -> true when it drew the sell price line
local done = setmetatable({}, { __mode = "k" }) -- tooltip -> price lines already added
local current = setmetatable({}, { __mode = "k" }) -- tooltip -> item data being drawn
local widest = setmetatable({}, { __mode = "k" }) -- tooltip -> widest price line name so far

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

-- An item with no sell price: the price lines go right after its last line of data, before
-- anything added after the data (Forever's "Press F6" reminder is), instead of at the very end.
local function onAnyLinePost(tooltip, lineData)
    local data = not done[tooltip] and current[tooltip]
    local lines = data and data.lines
    if lines and lines[#lines] == lineData then
        addPrices(tooltip, data)
    end
end

local function onItemPre(tooltip, data)
    current[tooltip] = data
    done[tooltip] = nil
    widest[tooltip] = nil
end

local function onItem(tooltip, data)
    if not done[tooltip] and data then
        addPrices(tooltip, data)
    end
    done[tooltip] = nil
    current[tooltip] = nil
    widest[tooltip] = nil
end

-- Redraws the item tooltip when Shift goes up or down, so lines that depend on it change. Other
-- tooltips (units, spells) are left alone.
local function onModifier(_, key)
    local shift = key == "LSHIFT" or key == "RSHIFT"
    if shift and GameTooltip:IsShown() and GameTooltip.RefreshData
        and (not GameTooltip.GetPrimaryTooltipData or itemData(GameTooltip)) then
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
        -- Probe: AllTypes (every line type) is Mainline's; without it, no-sell-price items get
        -- their price lines at the end, from onItem.
        if TooltipDataProcessor.AllTypes and TooltipDataProcessor.AddLinePostCall then
            TooltipDataProcessor.AddLinePostCall(TooltipDataProcessor.AllTypes, onAnyLinePost)
        end
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

---The item's ID, or nil when it has none or it's secret.
---@param data table tooltip data
---@return number?
function ItemTooltip.ItemID(data)
    local id = data.id
    if ns.IsReadable(id) then
        return id
    end
end

-- How many items a price line counts: the whole stack, or one while Shift is held. `mode` "one"
-- turns that round (one, and the stack with Shift).
local function priceCount(data, mode)
    local stack = (mode == "one") == IsShiftKeyDown()
    return stack and ItemTooltip.StackCount(data) or 1
end

-- Alignment ----------------------------------------------------------------------------------
-- "right": coins against the tooltip's right edge. "inline": coins right after the label. Either
-- way a name is padded with a blank texture out to the widest price line above it in the same
-- tooltip, so the quantities line up (spaces only got within a space's width). A line with no
-- price line above it, such as Auction on an item with no sell price, isn't padded. The sell
-- price comes first and is the longest name, so the lines above are all it needs to look at.

-- Blizzard's transparent texture, drawn as a gap of any width inside text.
local SPACER = "|TInterface\\Common\\spacer:1:%d|t"

local measure -- our own hidden font string, for label widths

local COLORS = { gray = GRAY_FONT_COLOR, white = HIGHLIGHT_FONT_COLOR, gold = NORMAL_FONT_COLOR }

local function width(text)
    if not measure then
        measure = UIParent:CreateFontString(nil, "BACKGROUND", "GameTooltipText")
        measure:Hide()
    end
    measure:SetText(text)
    return measure:GetStringWidth()
end

-- A gap that pads the name out to the widest price line name above it in this tooltip.
local function padding(tooltip, name)
    local own = width(name)
    local gap = floor((widest[tooltip] or own) - own + 0.5)
    widest[tooltip] = max(widest[tooltip] or 0, own)
    return gap > 0 and format(SPACER, gap) or ""
end

---Adds a price line: the name and an "x20", then the coins ("Sell Price x20: <coins>"). `db` is
---the module's settings from `PriceDefaults`: `mode` picks how many items it counts, `align`
---places the coins and `color` colors the quantity.
---@param tooltip table
---@param data table tooltip data, for the stack's size
---@param name string such as "Sell Price"
---@param unitPrice number copper for one item
---@param db table
function ItemTooltip.AddPrice(tooltip, data, name, unitPrice, db)
    local count = priceCount(data, db.mode)
    local amount = unitPrice * count
    local color = COLORS[db.color] or GRAY_FONT_COLOR
    local quantity = color:WrapTextInColorCode(format(L.PRICE_QUANTITY, count))
    -- The padding goes before the quantity, so the "x20"s line up.
    local label = format(L.PRICE_LINE, name .. padding(tooltip, name), quantity)
    local r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB()
    if db.align == "inline" then
        tooltip:AddLine(format(L.PRICE_INLINE, label, money(amount)), r, g, b)
    else
        tooltip:AddDoubleLine(label, money(amount), r, g, b, r, g, b)
    end
end

---Adds a line in the price lines' style with text instead of coins ("Scanned: 2h ago"). The
---text goes where `align` puts coins ("right" or "inline"), in `color`: a quantity color's name
---or { r, g, b }.
---@param tooltip table
---@param name string
---@param text string
---@param align string
---@param color string|table "gray", "white", "gold", or { r, g, b }
function ItemTooltip.AddInfo(tooltip, name, text, align, color)
    local label = format(L.PRICE_INFO_LINE, name .. padding(tooltip, name))
    local value
    if type(color) == "table" then
        value = format("|cff%02x%02x%02x%s|r", floor(color[1] * 255 + 0.5),
            floor(color[2] * 255 + 0.5), floor(color[3] * 255 + 0.5), text)
    else
        value = (COLORS[color] or GRAY_FONT_COLOR):WrapTextInColorCode(text)
    end
    local r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB()
    if align == "inline" then
        tooltip:AddLine(format(L.PRICE_INLINE, label, value), r, g, b)
    else
        tooltip:AddDoubleLine(label, value, r, g, b, r, g, b)
    end
end

-- Settings every price line has: what it counts, where its coins go, and the quantity's color.

---Adds a price line's settings, with their defaults, to a module's defaults.
---@param defaults table
---@param color string the quantity's default color: "gray", "white", or "gold"
---@return table defaults
function ItemTooltip.PriceDefaults(defaults, color)
    defaults.mode = "stack" -- "stack" (Shift for one) or "one" (Shift for the stack)
    defaults.align = "right" -- "right" (coins at the tooltip's edge) or "inline" (after the label)
    defaults.color = color
    return defaults
end

---A price line's options followed by the module's own, for its Settings page and /fpp set.
---@param options table the module's own options
---@param section? string a Settings header for the price options, when the page has others
---@return table options
function ItemTooltip.PriceOptions(options, section)
    local all = {
        {
            key = "mode", name = L.PRICE_MODE, description = L.PRICE_MODE_DESC, section = section,
            choices = { { "stack", L.PRICE_MODE_STACK }, { "one", L.PRICE_MODE_ONE } },
        },
        {
            key = "align", name = L.PRICE_ALIGN, description = L.PRICE_ALIGN_DESC, section = section,
            choices = { { "right", L.PRICE_ALIGN_RIGHT }, { "inline", L.PRICE_ALIGN_INLINE } },
        },
        {
            key = "color", name = L.PRICE_COLOR, description = L.PRICE_COLOR_DESC, section = section,
            choices = {
                { "gray", L.PRICE_COLOR_GRAY },
                { "white", L.PRICE_COLOR_WHITE },
                { "gold", L.PRICE_COLOR_GOLD },
            },
        },
    }
    for _, option in ipairs(options) do
        all[#all + 1] = option
    end
    return all
end
