-- The label friendly nameplate modules draw in place of Blizzard's name while the bar is hidden:
-- the name centered on the plate at the bar's height, a "<Subtitle>" line under it (a guild or an
-- NPC's title), the level beside it, and for players the group and friend icons. While the bar is
-- up, a second name of ours sits centered above the bar (Blizzard's stays hidden, since it sits at
-- the bar's left), with the icons after it and the subtitle under the bar.
--
-- A plate module decides what goes in the label through a `style` (see ns.FriendlyPlates):
--   style.db               its settings: level ("before"/"after"/"off"), centerLine, and with
--                          icons, socialIcons, groupIcon ("role"/"looking") and testIcons
--   style.NameColor(unit)  r, g, b for the name
--   style.BarNameColor(unit)  r, g, b for the name while the bar is up (optional; NameColor)
--   style.Subtitle(unit)   the subtitle text (nil for none; may be secret) and when it shows:
--                          "always", "hidden" (only without the bar), or "off"
--   style.SubtitleColor(unit)  { r, g, b }
--   style.icons            true to show the group and friend icons
-- Labels are kept per Blizzard unit frame and shared by every module, since plates are pooled.
local _, ns = ...

local pairs, ipairs, setmetatable, floor = pairs, ipairs, setmetatable, math.floor
local CreateFrame, CreateFontFamily, UnitLevel = CreateFrame, CreateFontFamily, UnitLevel
local UnitGroupRolesAssigned, GetTexCoordsForRoleSmallCircle =
    UnitGroupRolesAssigned, GetTexCoordsForRoleSmallCircle

local readable = ns.IsReadable
local Units, Nameplates = ns.Units, ns.Nameplates

local L = ns.L

local PlateLabel = {}
ns.PlateLabel = PlateLabel

-- Dropdown choices for the settings every plate module has.
PlateLabel.LEVEL_CHOICES = {
    { "before", L.PLATES_LEVEL_BEFORE },
    { "after", L.PLATES_LEVEL_AFTER },
    { "off", L.PLATES_LEVEL_OFF },
}
PlateLabel.SUBTITLE_CHOICES = {
    { "always", L.PLATES_SUBTITLE_ALWAYS },
    { "hidden", L.PLATES_SUBTITLE_HIDDEN },
    { "off", L.PLATES_SUBTITLE_OFF },
}

local GAP = 3 -- pixels between the name, the level, and the icons
local SUBTITLE_SCALE = 0.9 -- the subtitle is a touch smaller than the name

-- Icons ---------------------------------------------------------------------------------------
-- Friends get the Battle.net logo; group members get their role, or the Looking for Group icon.

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
local ICON_SCALE = 1.4 -- icon size against the name's font size
local ROUND_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- Which art an icon uses for this unit.
local function artFor(kind, unit, db)
    if kind == "friend" then
        return "battlenet"
    end
    if db.groupIcon ~= "looking" then
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

local function shouldShow(kind, unit, style)
    local db = style.db
    if not (style.icons and db.socialIcons) then
        return false
    end
    if db.testIcons == kind then
        return true
    end
    if kind == "group" then
        return Units.InGroup(unit)
    end
    return Units.IsFriend(unit)
end

-- One set of icons (hidden) on `parent`: kind -> texture.
local function createIcons(parent)
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

-- Shows the icons this unit gets, in a row going away from `anchor` (leftward when `left`), and
-- returns the width they take.
local function placeIcons(icons, anchor, left, fontSize, unit, style)
    local size = fontSize * ICON_SCALE
    local previous, width = anchor, 0
    for _, kind in ipairs(ORDER) do
        local icon = icons[kind]
        local show = shouldShow(kind, unit, style)
        icon:ClearAllPoints()
        if show then
            setArt(icon, artFor(kind, unit, style.db))
            icon:SetSize(size, size)
            if left then
                icon:SetPoint("RIGHT", previous, "LEFT", -GAP, 0)
            else
                icon:SetPoint("LEFT", previous, "RIGHT", GAP, 0)
            end
            previous = icon
            width = width + size + GAP
        end
        icon:SetShown(show)
    end
    return width
end

-- Label ---------------------------------------------------------------------------------------

local labels = setmetatable({}, { __mode = "k" }) -- Blizzard unit frame -> our label on it

local function newText(parent)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFontObject("SystemFont_NamePlate")
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)
    return text
end

local function createLabel(frame)
    local label = CreateFrame("Frame", nil, frame)
    label:SetAllPoints(frame)
    -- Empty frames to center on: the bar's row, and the cast bar's (see placeRow).
    label.row = CreateFrame("Frame", nil, label)
    label.castRow = CreateFrame("Frame", nil, label)
    -- Debug (Show Plate Center): a thin line down the middle of the row, on a frame of its own so
    -- it shows with or without the bar.
    label.debugFrame = CreateFrame("Frame", nil, frame)
    label.debugFrame:SetAllPoints(frame)
    label.centerLine = label.debugFrame:CreateTexture(nil, "OVERLAY")
    label.centerLine:SetColorTexture(1, 0.2, 0.2, 0.9)
    label.centerLine:SetSize(1, 40)
    label.centerLine:SetPoint("CENTER", label.row, "CENTER")
    label.centerLine:Hide()
    label.name = newText(label)
    label.subtitle = newText(label)
    -- A separate frame so it can fade in with the bar while the rest of the label fades out.
    label.barFrame = CreateFrame("Frame", nil, frame)
    label.barFrame:SetAllPoints(frame)
    label.barSubtitle = newText(label.barFrame)
    -- Our own name for the bar view too: Blizzard's sits at the bar's left, off the unit's center.
    label.barName = newText(label.barFrame)
    label.barRow = CreateFrame("Frame", nil, label.barFrame)
    -- Our copy of the level badge, which sits beside the name instead of at the bar's end.
    label.level = CreateFrame("Frame", nil, label)
    label.level.text = label.level:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label.level.text:SetPoint("CENTER")
    -- One set of icons for each view: beside our name, and beside Blizzard's while the bar is up.
    label.icons = createIcons(label)
    label.barIcons = createIcons(label.barFrame)
    return label
end

---Our label on a Blizzard unit frame, made the first time and shown. Plates are pooled, so it's
---reused.
---@param frame table plate.UnitFrame
---@return table label
function PlateLabel.Show(frame)
    local label = labels[frame]
    if not label then
        label = createLabel(frame)
        labels[frame] = label
    end
    label:Show()
    label.barFrame:Show()
    label.debugFrame:Show()
    return label
end

---Hides a label as its plate goes back to the pool.
---@param label table
function PlateLabel.Hide(label)
    label:Hide()
    label.barFrame:Hide()
    label.debugFrame:Hide()
end

-- Copies the look of Forever's level badge (UnitFrame.LevelFrame): its atlas art and its
-- number's font. The art is copied once per label, since the badge is the same on every plate;
-- the size is retried until Blizzard has laid its badge out.
local function copyBadge(label, levelFrame)
    local badge = label.level
    local width, height = levelFrame:GetSize()
    if readable(width) and readable(height) and width and width > 0 then
        badge:SetSize(width, height)
    elseif not badge.sized then
        badge:SetSize(24, 14)
    end
    badge.sized = true
    if badge.copied then
        return
    end
    badge.copied = true
    local sources = { levelFrame }
    for _, child in pairs({ levelFrame:GetChildren() }) do
        sources[#sources + 1] = child
    end
    for _, source in pairs(sources) do
        for _, region in pairs({ source:GetRegions() }) do
            local kind = region:GetObjectType()
            if kind == "Texture" and region:GetAtlas() then
                local texture = badge:CreateTexture(nil, region:GetDrawLayer())
                texture:SetAtlas(region:GetAtlas())
                texture:SetAllPoints(badge)
                badge.hasArt = true
            elseif kind == "FontString" then
                local file, size, flags = region:GetFont()
                if file and size then
                    badge.text:SetFont(file, size, flags)
                end
            end
        end
    end
end

-- Use the font Blizzard's name is drawn with right now. Its font object can be a different size
-- (nameplates set the size on the string), which made our copy come out small.
-- Blizzard also shrinks the font of a long name to fit its plate, so copying each plate's size
-- made long names tiny. Every label uses the largest size seen instead: the normal one.
local fullSize = 0

-- Blizzard's nameplate font is a font family: a font per alphabet, so Chinese, Korean, and
-- Cyrillic names draw with fonts that have those glyphs. SetFont with the one file GetFont
-- returns (the roman one) drops the rest, and those names came out blank. So at each size we
-- build our own family from Blizzard's members instead.
local ALPHABETS = { "roman", "korean", "simplifiedchinese", "traditionalchinese", "russian" }
local families = {} -- "size flags" -> our font family, or false if it couldn't be made
local familyCount = 0

-- `base`'s font for one alphabet, or nil when it isn't a family (or the client can't say).
local function member(base, alphabet)
    local font = base.GetFontObjectForAlphabet and base:GetFontObjectForAlphabet(alphabet)
    return font and font.GetFont and font or nil
end

---A font family like `base` (Blizzard's name font) with its roman font at `size`; the other
---alphabets keep their sizes relative to it. Nil when the client has no font families.
---@param base table Font
---@param size number
---@param flags string|nil
---@return table|nil
local function fontFamily(base, size, flags)
    flags = flags or ""
    size = floor(size * 10 + 0.5) / 10
    local key = size .. " " .. flags
    local family = families[key]
    if family ~= nil then
        return family or nil
    end
    local roman = CreateFontFamily and member(base, "roman")
    local _, romanHeight = roman and roman:GetFont()
    if not (romanHeight and romanHeight > 0) then
        families[key] = false
        return nil
    end
    local members = {}
    for _, alphabet in ipairs(ALPHABETS) do
        local font = member(base, alphabet)
        local file, height = font and font:GetFont()
        if file and height and height > 0 then
            members[#members + 1] = {
                alphabet = alphabet,
                file = file,
                height = size * height / romanHeight,
                flags = flags,
            }
        end
    end
    -- Font objects need a unique global name; ours are prefixed with the addon's.
    familyCount = familyCount + 1
    family = CreateFontFamily("ForeverPlusPlusPlateFont" .. familyCount, members)
    if family then
        -- The members don't take a shadow, so copy Blizzard's onto each.
        for _, alphabet in ipairs(ALPHABETS) do
            local ours, theirs = member(family, alphabet), member(base, alphabet)
            if ours and theirs then
                ours:SetShadowOffset(theirs:GetShadowOffset())
                ours:SetShadowColor(theirs:GetShadowColor())
            end
        end
    end
    families[key] = family or false
    return family
end

-- Sets a label's text to Blizzard's name font at `size`: our family when the client has them,
-- otherwise Blizzard's font object as it is (the right glyphs, if not always the right size).
local function setFont(text, base, size, flags)
    local family = fontFamily(base, size, flags)
    text:SetFontObject(family or base)
end

local function matchFont(label, name)
    local _, size, flags = name:GetFont()
    local base = name:GetFontObject() or _G.SystemFont_NamePlate
    if not (size and base) then
        return
    end
    if size > fullSize then
        fullSize = size
    end
    size = fullSize
    if label.fontSize == size and label.fontFlags == flags and label.fontBase == base then
        return
    end
    label.fontSize, label.fontFlags, label.fontBase = size, flags, base
    setFont(label.name, base, size, flags)
    label.nameSize = size
    setFont(label.subtitle, base, size * SUBTITLE_SCALE, flags)
    setFont(label.barSubtitle, base, size * SUBTITLE_SCALE, flags)
    setFont(label.barName, base, size, flags)
end

-- Puts the level beside the name; returns the width it takes.
local function placeLevel(label, record, unit, where)
    local badge = label.level
    if not record.levelFrame or where == "off" then
        badge:Hide()
        return 0
    end
    copyBadge(label, record.levelFrame)
    local level = UnitLevel(unit)
    if readable(level) and level <= 0 then
        badge.text:SetText("??")
    else
        badge.text:SetText(level)
    end
    -- Without copied art the badge is just the number, so it's as wide as the number.
    local textWidth = badge.text:GetStringWidth()
    if not badge.hasArt and readable(textWidth) and textWidth > 0 then
        badge:SetWidth(textWidth)
    end
    local width = badge:GetWidth()
    width = readable(width) and width + GAP or 0
    badge:ClearAllPoints()
    if where == "after" then
        badge:SetPoint("LEFT", label.name, "RIGHT", GAP, 0)
    else
        badge:SetPoint("RIGHT", label.name, "LEFT", -GAP, 0)
    end
    badge:Show()
    return width
end

-- The row our label is centered on: the bar's height, but the unit frame's width (the label covers
-- it), since the bar sits left of center with the level badge on its right end. Never anchor to
-- the nameplate base frame (NamePlateN) itself: on 12.x that fails with "anchor family
-- connection" and also breaks Blizzard's own nameplate anchors.
local function placeRow(label, record, style)
    local row = label.row
    row:ClearAllPoints()
    row:SetPoint("TOP", record.container, "TOP")
    row:SetPoint("BOTTOM", record.container, "BOTTOM")
    row:SetPoint("LEFT", label, "LEFT")
    row:SetPoint("RIGHT", label, "RIGHT")
    -- Debug: a thin line through the plate's center, to check the centering in game.
    label.centerLine:SetShown(style.db.centerLine)
    return row
end

local function placeSubtitle(label, record, unit, style, shift)
    local row = placeRow(label, record, style)
    local text, mode = style.Subtitle(unit)
    label.name:ClearAllPoints()
    label.subtitle:ClearAllPoints()
    label.barSubtitle:ClearAllPoints()
    if mode == "off" or not (readable(text) and text and text ~= "") then
        label.name:SetPoint("CENTER", row, "CENTER", shift, 0)
        label.subtitle:Hide()
        label.barSubtitle:Hide()
        return
    end
    local color = style.SubtitleColor(unit)
    label.subtitle:SetTextColor(color[1], color[2], color[3])
    label.barSubtitle:SetTextColor(color[1], color[2], color[3])
    label.name:SetPoint("BOTTOM", row, "CENTER", shift, 1)
    -- While a cast bar is really showing (under the bar), the subtitle moves below it. Only then:
    -- friendly plates can hide cast bars, and a stale cast left a gap under the name.
    local castBar = record.castBar
    if Nameplates.IsCasting(unit) and Nameplates.IsCastBarShown(castBar) then
        -- Centered on the unit like the row, at the cast bar's height.
        local castRow = label.castRow
        castRow:ClearAllPoints()
        castRow:SetPoint("TOP", castBar, "TOP")
        castRow:SetPoint("BOTTOM", castBar, "BOTTOM")
        castRow:SetPoint("LEFT", label, "LEFT")
        castRow:SetPoint("RIGHT", label, "RIGHT")
        label.subtitle:SetPoint("TOP", castRow, "BOTTOM", 0, -1)
        label.barSubtitle:SetPoint("TOP", castRow, "BOTTOM", 0, -1)
    else
        label.subtitle:SetPoint("TOP", row, "CENTER", 0, 0)
        label.barSubtitle:SetPoint("TOP", row, "BOTTOM", 0, -2)
    end
    label.subtitle:SetFormattedText("<%s>", text)
    label.subtitle:Show()
    label.barSubtitle:SetFormattedText("<%s>", text)
    label.barSubtitle:SetShown(mode == "always")
end

---Lays the label out for this unit: name, color, level, icons, subtitle.
---@param label table from PlateLabel.Show
---@param record table the plate: container, name (Blizzard's), levelFrame, castBar
---@param unit string
---@param style table see the top of this file
function PlateLabel.Layout(label, record, unit, style)
    label.name:SetText(record.name:GetText())
    matchFont(label, record.name)
    label.name:SetTextColor(style.NameColor(unit))
    -- The level goes on one side of the name and the icons on the other. The name then shifts by
    -- half the difference, so the whole row is centered over the bar. The subtitle stays centered.
    local where = style.db.level
    local levelWidth = placeLevel(label, record, unit, where)
    local iconsLeft = where == "after"
    local fontSize = label.nameSize or 12
    local iconsWidth = placeIcons(label.icons, label.name, iconsLeft, fontSize, unit, style)
    -- With the bar up: our bar-view name centered on the plate just above the bar, its icons after
    -- it, and the pair shifted so they're centered together. Blizzard's level stays on the bar.
    label.barName:SetText(record.name:GetText())
    label.barName:SetTextColor((style.BarNameColor or style.NameColor)(unit))
    local barIconsWidth = placeIcons(label.barIcons, label.barName, false, fontSize, unit, style)
    local barRow = label.barRow
    barRow:ClearAllPoints()
    barRow:SetPoint("TOP", record.container, "TOP")
    barRow:SetPoint("BOTTOM", record.container, "BOTTOM")
    barRow:SetPoint("LEFT", label, "LEFT")
    barRow:SetPoint("RIGHT", label, "RIGHT")
    label.barName:ClearAllPoints()
    label.barName:SetPoint("BOTTOM", barRow, "TOP", -barIconsWidth / 2, 2)
    local leftWidth, rightWidth = levelWidth, iconsWidth
    if iconsLeft then
        leftWidth, rightWidth = iconsWidth, levelWidth
    end
    placeSubtitle(label, record, unit, style, (leftWidth - rightWidth) / 2)
end
