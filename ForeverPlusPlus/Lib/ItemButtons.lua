-- Blizzard's item buttons, for modules that mark items on them: the bag windows and their buttons,
-- the merchant's buttons, a tint laid over an icon, and an item's tooltip lines.
local _, ns = ...

local _G = _G
local C_TooltipInfo = C_TooltipInfo

local ItemButtons = {}
ns.ItemButtons = ItemButtons

---Blizzard's bag windows that are there: the combined bags, then one per bag.
---@return table[]
function ItemButtons.Frames()
    local list = { _G.ContainerFrameCombinedBags }
    for i = 1, _G.NUM_CONTAINER_FRAMES or 13 do
        list[#list + 1] = _G["ContainerFrame" .. i]
    end
    return list
end

---Calls `fn(button, icon, bag, slot)` for each item button in a bag window.
---@param frame table a bag window from `ItemButtons.Frames`
---@param fn function
function ItemButtons.EachBagButton(frame, fn)
    if not frame.EnumerateValidItems then
        return
    end
    for _, button in frame:EnumerateValidItems() do
        local bag = button.GetBagID and button:GetBagID() or button:GetParent():GetID()
        fn(button, button.icon or button.Icon, bag, button:GetID())
    end
end

---The icon of the merchant's `i`th button on the page, or nil.
---@param i number
---@return table?
function ItemButtons.MerchantIcon(i)
    local button = _G["MerchantItem" .. i .. "ItemButton"]
    return button and (button.icon or _G["MerchantItem" .. i .. "ItemButtonIconTexture"])
end

---Calls `fn(icon, index)` for each button on the merchant's page, with the merchant item index it
---shows (for GetMerchantItemLink). Does nothing without the merchant window.
---@param fn function
function ItemButtons.EachMerchantItem(fn)
    local frame = _G.MerchantFrame
    if not (frame and _G.GetMerchantItemLink) then
        return
    end
    local perPage = _G.MERCHANT_ITEMS_PER_PAGE or 10
    for i = 1, perPage do
        fn(ItemButtons.MerchantIcon(i), ((frame.page or 1) - 1) * perPage + i)
    end
end

---A new texture just above an icon that multiplies it by a color (MOD blend), so it looks like a
---vertex color without touching the icon's own, which Blizzard sets itself. The caller keeps it.
---@param icon table a Texture
---@param color number[] { r, g, b }
---@return table texture
function ItemButtons.Tint(icon, color)
    local layer, sublevel = icon:GetDrawLayer()
    sublevel = sublevel or 0
    local tint = icon:GetParent():CreateTexture(nil, layer, nil, sublevel < 7 and sublevel + 1 or 7)
    tint:SetColorTexture(color[1], color[2], color[3])
    tint:SetBlendMode("MOD")
    tint:SetAllPoints(icon)
    return tint
end

---An item's tooltip lines, or nil while the game has no tooltip for it yet (not cached), so that
---isn't taken for an answer.
---@param link string
---@return table[]?
function ItemButtons.TooltipLines(link)
    local data = C_TooltipInfo and C_TooltipInfo.GetHyperlink(link)
    local lines = data and data.lines
    if not lines or #lines == 0 then
        return nil
    end
    return lines
end
