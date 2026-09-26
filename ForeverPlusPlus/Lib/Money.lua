-- Money as Blizzard shows it: gold, silver and copper with their coin icons.
local _, ns = ...

local GetMoneyString, C_CurrencyInfo = GetMoneyString, C_CurrencyInfo

---An amount of copper as coin text, the way Blizzard's own tooltips and chat show it.
---@param amount number copper
---@return string
function ns.Money(amount)
    -- Probe: GetMoneyString is Mainline FrameXML; the coin text is the fallback.
    if GetMoneyString then
        return GetMoneyString(amount, true)
    end
    return C_CurrencyInfo.GetCoinTextureString(amount)
end
