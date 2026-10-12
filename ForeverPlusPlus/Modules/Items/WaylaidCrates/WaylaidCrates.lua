-- Waylaid Crates: help filling Waylaid Crates, in two parts: what each bundle a crate takes costs
-- at auction, in its tooltip (Costs.lua), and a Waylaid Crates entry in the auction house's
-- categories listing what the crates in the bags still need (Category.lua). This file has the
-- settings, reads the bundles from a crate's tooltip for both, and turns each part on and off.
-- Prices and item names come from Item Tooltips' Auction Prices through ns.Prices.
local _, ns = ...

local ipairs, type, tonumber = ipairs, type, tonumber
local _G = _G

local L = ns.L

local module = ns.NewModule("WaylaidCrates", L.WAYLAIDCRATES_DESC, {
    enabled = true,
    costs = "beside", -- each bundle's cost: "off", "below" each bundle, or "beside" it
    list = "bottom", -- the auction house entry: "off", "top" or "bottom" of the categories
})
module.title = L.WAYLAIDCRATES_TITLE
module.category = "items"
module.added = "0.8.5"

-- Before 0.8.5, Bundle Costs was Item Tooltips' Waylaid Crate Costs option.
ns.Migrate(function(saved)
    local old = saved.ItemTooltips
    if not (old and old.crates ~= nil) then
        return
    end
    local db = saved.WaylaidCrates or {}
    saved.WaylaidCrates = db
    ns.MoveSettings(old, db, { costs = "crates" })
    old.crates = nil
end)

module.options = {
    {
        key = "costs", name = L.WAYLAIDCRATES_COSTS, description = L.WAYLAIDCRATES_COSTS_DESC,
        choices = {
            { "off", L.WAYLAIDCRATES_COSTS_OFF },
            { "below", L.WAYLAIDCRATES_COSTS_BELOW },
            { "beside", L.WAYLAIDCRATES_COSTS_BESIDE },
        },
    },
    {
        key = "list", name = L.WAYLAIDCRATES_LIST, description = L.WAYLAIDCRATES_LIST_DESC,
        choices = {
            { "off", L.WAYLAIDCRATES_LIST_OFF },
            { "top", L.WAYLAIDCRATES_LIST_TOP },
            { "bottom", L.WAYLAIDCRATES_LIST_BOTTOM },
        },
    },
}

module.internal = {}
local internal = module.internal

-- Bundles ----------------------------------------------------------------------------------------
-- A Waylaid Crate's Use line lists the bundles that fill it, one per line ("- 6 Bolt of Woolen
-- Cloth"), in the Use line's own text or in lines of their own after it.

local USE = _G.ITEM_SPELL_TRIGGER_ONUSE or "Use:" -- Blizzard's "Use:", in the player's language

-- Color codes come as |cAARRGGBB or as |cnNAME: with one of Blizzard's named colors
-- (|cnHIGHLIGHT_FONT_COLOR:), and end at |r.
internal.HEX_CODE, internal.NAMED_CODE = "|c%x%x%x%x%x%x%x%x", "|cn[%w_]+:"

-- Each line of a text, for gmatch on the text with "\n" added. The crate's text breaks lines
-- with "\r\n", and a "\r" left on a line we draw shows as an empty line after it.
internal.LINES = "(.-)\r?\n"

local LINES = internal.LINES

---A text without its color codes.
---@param text string
---@return string
function internal.StripCodes(text)
    return (text:gsub(internal.NAMED_CODE, ""):gsub(internal.HEX_CODE, ""):gsub("|r", ""))
end

---A tooltip line's text without color codes, or nil when it can't be read.
---@param line table
---@return string|nil
function internal.PlainText(line)
    local text = line.leftText
    if type(text) == "string" and ns.IsReadable(text) then
        return internal.StripCodes(text)
    end
end

---A bundle in the list ("- 6 Bolt of Woolen Cloth"): its count and item name, or nil.
---@param part string
---@return number|nil count
---@return string|nil name
function internal.BundleOf(part)
    local count, name = part:match("^%s*%-%s*(%d+)%s+(.-)%s*$")
    if count and name ~= "" then
        return tonumber(count), name
    end
end

---Whether any of the text's lines is a bundle.
---@param text string
---@return boolean
function internal.HasBundle(text)
    for part in (text .. "\n"):gmatch(LINES) do
        if internal.BundleOf(part) then
            return true
        end
    end
    return false
end

---Whether `lineData` is the Use line or one of the bundle lines right after it.
---@param data table tooltip data
---@param lineData table one of its lines
---@return boolean
function internal.InList(data, lineData)
    local found, chain = false, false
    for _, line in ipairs(data.lines or {}) do
        local text = internal.PlainText(line) or ""
        if not found and text:find(USE, 1, true) == 1 then
            found, chain = true, true
        elseif found then
            chain = chain and internal.HasBundle(text)
        end
        if line == lineData then
            return found and chain
        end
    end
    return false
end

---The bundles an item's tooltip lists after its Use line: { { count, name } }, empty for an item
---that isn't a crate.
---@param data table tooltip data, as C_TooltipInfo gives it
---@return table
function internal.Bundles(data)
    local bundles, found = {}, false
    for _, line in ipairs(data.lines or {}) do
        local text = internal.PlainText(line) or ""
        if not found then
            found = text:find(USE, 1, true) == 1
        elseif not internal.HasBundle(text) then
            break
        end
        if found then
            for part in (text .. "\n"):gmatch(LINES) do
                local count, name = internal.BundleOf(part)
                if count then
                    bundles[#bundles + 1] = { count, name }
                end
            end
        end
    end
    return bundles
end

-- Parts -------------------------------------------------------------------------------------------
-- Each part is on while the module is and its option isn't "off": `enable` and `disable` undo
-- each other, and `optionChanged(key)` hears about changes while it's on.

local parts = {} -- { key, enable, disable, optionChanged?, on }

---Adds a part, turned on and off by the dropdown option `key` (any choice but "off").
---@param key string
---@param part table { enable = fn, disable = fn, optionChanged? = fn(key) }
function internal.AddPart(key, part)
    part.key = key
    parts[#parts + 1] = part
end

---Whether the part with option `key` is on. Hooks can't be removed, so theirs ask this.
---@param key string
---@return boolean
function internal.Active(key)
    return module.enabled and module.db[key] ~= "off" or false
end

local function sync()
    for _, part in ipairs(parts) do
        local on = internal.Active(part.key)
        if on ~= (part.on or false) then
            part.on = on
            if on then
                part.enable()
            else
                part.disable()
            end
        end
    end
end

function module:OnEnable()
    sync()
end

function module:OnDisable()
    sync()
end

function module:OnOptionChanged(key)
    sync()
    for _, part in ipairs(parts) do
        if part.on and part.optionChanged then
            part.optionChanged(key)
        end
    end
end
