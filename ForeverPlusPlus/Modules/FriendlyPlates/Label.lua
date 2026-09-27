-- Friendly Nameplates: our label. While the bar is hidden, Blizzard's name (which sits above
-- the bar) fades out and our label takes its place, centered on the plate at the bar's height: the name in
-- class color with "<Guild>" under it, or the name alone at the bar's middle when there's no
-- guild, with the level and icons beside it. While the bar is up, Blizzard's name is back and the
-- guild (and icons) sit with it instead.
local _, ns = ...

local pairs, setmetatable = pairs, setmetatable
local CreateFrame, C_ClassColor = CreateFrame, C_ClassColor
local UnitClass, UnitLevel, GetGuildInfo = UnitClass, UnitLevel, GetGuildInfo

local module = ns.modules.FriendlyPlates
local P = module.internal
local readable = ns.IsReadable
local Units, Nameplates = ns.Units, ns.Nameplates

local GUILD_SCALE = 0.9 -- the guild line is a touch smaller than the name
-- Guild Name Color choices. Highlighted guildmates get guild chat's green, or white when every
-- guild is already green, so they still stand out.
local GUILD_COLORS = {
    gray = { 0.65, 0.65, 0.65 },
    green = { 0.25, 1, 0.25 }, -- guild chat's green
}
local GUILDMATE_COLORS = {
    gray = GUILD_COLORS.green,
    green = { 0.9, 0.9, 0.9 },
}
local NPC_COLOR = { 0.1, 1, 0.1 } -- the green of friendly NPC names in the world

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
    label.name = newText(label)
    label.guild = newText(label)
    -- A separate frame so it can fade in with the bar while the rest of the label fades out.
    label.barFrame = CreateFrame("Frame", nil, frame)
    label.barFrame:SetAllPoints(frame)
    label.barGuild = newText(label.barFrame)
    -- Our copy of the level badge, which sits beside the name instead of at the bar's end.
    label.level = CreateFrame("Frame", nil, label)
    label.level.text = label.level:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label.level.text:SetPoint("CENTER")
    -- One set of icons for each view: beside our name, and beside Blizzard's while the bar is up.
    label.icons = P.CreateIcons(label)
    label.barIcons = P.CreateIcons(label.barFrame)
    return label
end

---Our label on a Blizzard unit frame, made the first time. Plates are pooled, so it's reused.
---@param frame table plate.UnitFrame
---@return table label
function P.GetLabel(frame)
    local label = labels[frame]
    if not label then
        label = createLabel(frame)
        labels[frame] = label
    end
    return label
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
local function matchFont(label, name)
    local file, size, flags = name:GetFont()
    if not (file and size) then
        return
    end
    label.name:SetFont(file, size, flags)
    label.nameSize = size
    label.guild:SetFont(file, size * GUILD_SCALE, flags)
    label.barGuild:SetFont(file, size * GUILD_SCALE, flags)
end

local function colorName(label, record, unit)
    local _, class = UnitClass(unit)
    local color = record.isPlayer and module.db.classColor and readable(class) and class
        and C_ClassColor and C_ClassColor.GetClassColor(class)
    if color then
        label.name:SetTextColor(color:GetRGB())
    elseif record.isPlayer then
        label.name:SetTextColor(1, 1, 1)
    else
        label.name:SetTextColor(NPC_COLOR[1], NPC_COLOR[2], NPC_COLOR[3])
    end
end

-- Puts the level beside the name; returns the width it takes.
local function placeLevel(label, record, unit)
    local badge = label.level
    local where = module.db.level
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
    width = readable(width) and width + P.GAP or 0
    badge:ClearAllPoints()
    if where == "after" then
        badge:SetPoint("LEFT", label.name, "RIGHT", P.GAP, 0)
    else
        badge:SetPoint("RIGHT", label.name, "LEFT", -P.GAP, 0)
    end
    badge:Show()
    return width
end

-- The row our label is centered on: the bar's height, but the whole plate's width. The bar sits
-- left of the plate's middle (the level badge takes its right end), so centering on the bar put
-- the name left of the player.
local function placeRow(label, container)
    local row = label.row
    row:ClearAllPoints()
    row:SetPoint("TOP", container, "TOP")
    row:SetPoint("BOTTOM", container, "BOTTOM")
    row:SetPoint("LEFT", label, "LEFT")
    row:SetPoint("RIGHT", label, "RIGHT")
    return row
end

local function placeGuild(label, record, unit, shift)
    local row = placeRow(label, record.container)
    local mode = module.db.guildNames
    local guild = mode ~= "off" and GetGuildInfo(unit)
    label.name:ClearAllPoints()
    label.guild:ClearAllPoints()
    label.barGuild:ClearAllPoints()
    if not (readable(guild) and guild and guild ~= "") then
        label.name:SetPoint("CENTER", row, "CENTER", shift, 0)
        label.guild:Hide()
        label.barGuild:Hide()
        return
    end
    local scheme = GUILD_COLORS[module.db.guildColor] and module.db.guildColor or "gray"
    local color = module.db.guildHighlight and Units.IsGuildmate(unit) and GUILDMATE_COLORS[scheme]
        or GUILD_COLORS[scheme]
    label.guild:SetTextColor(color[1], color[2], color[3])
    label.barGuild:SetTextColor(color[1], color[2], color[3])
    label.name:SetPoint("BOTTOM", row, "CENTER", shift, 1)
    -- While a cast bar is really showing (under the bar), the guild moves below it. Only then:
    -- friendly plates can hide cast bars, and a stale cast left a gap under the name.
    local castBar = record.castBar
    if Nameplates.IsCasting(unit) and Nameplates.IsCastBarShown(castBar) then
        -- Centered on the player like the row, at the cast bar's height.
        local castRow = label.castRow
        castRow:ClearAllPoints()
        castRow:SetPoint("TOP", castBar, "TOP")
        castRow:SetPoint("BOTTOM", castBar, "BOTTOM")
        castRow:SetPoint("LEFT", label, "LEFT")
        castRow:SetPoint("RIGHT", label, "RIGHT")
        label.guild:SetPoint("TOP", castRow, "BOTTOM", 0, -1)
        label.barGuild:SetPoint("TOP", castRow, "BOTTOM", 0, -1)
    else
        label.guild:SetPoint("TOP", row, "CENTER", 0, 0)
        label.barGuild:SetPoint("TOP", row, "BOTTOM", 0, -2)
    end
    label.guild:SetFormattedText("<%s>", guild)
    label.guild:Show()
    label.barGuild:SetFormattedText("<%s>", guild)
    label.barGuild:SetShown(mode == "always")
end

---Lays the label out for this unit: name, color, level, icons, guild.
---@param label table from P.GetLabel
---@param record table the plate's record
---@param unit string
function P.LayoutLabel(label, record, unit)
    label.name:SetText(record.name:GetText())
    matchFont(label, record.name)
    colorName(label, record, unit)
    -- The level goes on one side of the name and the icons on the other. The name then shifts by
    -- half the difference, so the whole row is centered over the bar. The guild stays centered.
    local levelWidth = placeLevel(label, record, unit)
    local iconsLeft = module.db.level == "after"
    local fontSize = label.nameSize or 12
    local iconsWidth = P.PlaceIcons(label.icons, label.name, iconsLeft, fontSize, record, unit)
    -- With the bar up, the icons follow Blizzard's own name.
    P.PlaceIcons(label.barIcons, record.name, false, fontSize, record, unit, P.BarIconOffset(record.name))
    local leftWidth, rightWidth = levelWidth, iconsWidth
    if iconsLeft then
        leftWidth, rightWidth = iconsWidth, levelWidth
    end
    placeGuild(label, record, unit, (leftWidth - rightWidth) / 2)
end
