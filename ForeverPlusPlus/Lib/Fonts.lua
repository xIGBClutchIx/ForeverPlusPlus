-- The game's own font files a module lets the player pick from, so every font choice lists the same
-- faces under the same names.
local _, ns = ...

local ipairs, GetLocale = ipairs, GetLocale
local L = ns.L

local Fonts = {}
ns.Fonts = Fonts

-- File, then name, as a dropdown's `choices` take them.
Fonts.CHOICES = {
    { "Fonts\\FRIZQT__.TTF", L.FONT_FRIZQT },
    { "Fonts\\ARIALN.TTF", L.FONT_ARIALN },
    { "Fonts\\skurri.ttf", L.FONT_SKURRI },
    { "Fonts\\MORPHEUS.TTF", L.FONT_MORPHEUS },
}

-- SetFont takes a single file, so the alphabets the game's fonts cover with fallbacks (Korean,
-- Chinese, Cyrillic) would draw blank in another face.
local NON_ROMAN = { koKR = true, zhCN = true, zhTW = true, ruRU = true }

---Whether this client's language can be drawn in one of `Fonts.CHOICES`.
---@return boolean
function Fonts.CanChange()
    return not NON_ROMAN[GetLocale()]
end

---`Fonts.CHOICES` after `first`, a choice of the caller's own such as { "default", "Default" }.
---@param first table
---@return table choices
function Fonts.ChoicesAfter(first)
    local choices = { first }
    for _, choice in ipairs(Fonts.CHOICES) do
        choices[#choices + 1] = choice
    end
    return choices
end
