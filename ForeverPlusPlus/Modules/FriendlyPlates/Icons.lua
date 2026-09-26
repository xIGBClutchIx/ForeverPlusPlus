-- Friendly Player Nameplates: the group and friend icons beside the name. Friends get the
-- Battle.net logo; group members get their role, or the Looking for Group icon.
local _, ns = ...

local ipairs = ipairs
local UnitGroupRolesAssigned, GetTexCoordsForRoleSmallCircle =
    UnitGroupRolesAssigned, GetTexCoordsForRoleSmallCircle

local module = ns.modules.FriendlyPlates
local P = module.internal
local readable = ns.IsReadable
local Units = ns.Units

-- `round` crops a spell-style icon round, like a minimap button; `role` picks that role from
-- Blizzard's round role icons.
local ART = {
    battlenet = { file = "Interface\\FriendsFrame\\Battlenet-Battleneticon" },
    looking = { file = "Interface\\Icons\\INV_Misc_GroupLooking", round = true },
    TANK = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", role = "TANK" },
    HEALER = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", role = "HEALER" },
    DAMAGER = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", role = "DAMAGER" },
}
local ORDER = { "group", "friend" }
local SCALE = 1.4 -- icon size against the name's font size
local ROUND_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- Which art an icon uses for this unit.
local function artFor(kind, unit)
    if kind == "friend" then
        return "battlenet"
    end
    if module.db.groupIcon ~= "looking" then
        local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
        -- No role (or not in a group, while testing) falls back to the LFG icon.
        return readable(role) and ART[role] and role or "looking"
    end
    return "looking"
end

-- Sets an icon's art; only does the work when it changed.
local function setArt(icon, key)
    if icon.art == key then
        return
    end
    icon.art = key
    local art = ART[key]
    icon:SetTexture(art.file)
    if art.role and GetTexCoordsForRoleSmallCircle then
        icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(art.role))
    elseif art.round then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        icon:SetTexCoord(0, 1, 0, 1)
    end
    if art.round and not icon.masked then
        icon:AddMaskTexture(icon.mask)
        icon.masked = true
    elseif not art.round and icon.masked then
        icon:RemoveMaskTexture(icon.mask)
        icon.masked = false
    end
end

local function shouldShow(kind, record, unit)
    if not (record.isPlayer and module.db.socialIcons) then
        return false
    end
    if module.db.testIcons == kind then
        return true
    end
    if kind == "group" then
        return Units.InGroup(unit)
    end
    return Units.IsFriend(unit)
end

---Makes one set of icons (hidden) on `parent`.
---@param parent table
---@return table icons kind -> texture
function P.CreateIcons(parent)
    local icons = {}
    for _, kind in ipairs(ORDER) do
        local icon = parent:CreateTexture(nil, "OVERLAY")
        icon.mask = parent:CreateMaskTexture()
        icon.mask:SetTexture(ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        icon.mask:SetAllPoints(icon)
        icon:Hide()
        icons[kind] = icon
    end
    return icons
end

---Where icons after Blizzard's name should start. Its name string can be wider than its text
---(stretched across the bar), so its right edge isn't where the text ends; measure from the side
---it's justified to instead. Nil falls back to the right edge.
---@param name table Blizzard's name FontString
---@return table? offset { point on the name, x }
function P.BarIconOffset(name)
    local width, justify = name:GetStringWidth(), name:GetJustifyH()
    if not (readable(width) and width and width > 0) then
        return nil
    end
    if justify == "LEFT" then
        return { "LEFT", width }
    elseif justify == "CENTER" then
        return { "CENTER", width / 2 }
    end
end

---Shows the icons this unit gets, in a row going away from `anchor` (leftward when `left`).
---@param icons table from P.CreateIcons
---@param anchor table the region to start from
---@param left boolean
---@param fontSize number the name's font size
---@param record table the plate's record (isPlayer)
---@param unit string
---@param offset? table from P.BarIconOffset
---@return number width the icons take
function P.PlaceIcons(icons, anchor, left, fontSize, record, unit, offset)
    local size = fontSize * SCALE
    local previous, width, first = anchor, 0, true
    for _, kind in ipairs(ORDER) do
        local icon = icons[kind]
        local show = shouldShow(kind, record, unit)
        icon:ClearAllPoints()
        if show then
            setArt(icon, artFor(kind, unit))
            icon:SetSize(size, size)
            if first and offset then
                icon:SetPoint("LEFT", previous, offset[1], offset[2] + P.GAP, 0)
            elseif left then
                icon:SetPoint("RIGHT", previous, "LEFT", -P.GAP, 0)
            else
                icon:SetPoint("LEFT", previous, "RIGHT", P.GAP, 0)
            end
            previous, first = icon, false
            width = width + size + P.GAP
        end
        icon:SetShown(show)
    end
    return width
end
