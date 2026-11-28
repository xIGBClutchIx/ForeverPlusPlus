-- Player Portrait: the dragon the target frame puts around an elite or rare mob's portrait,
-- around your own and around a player you target, and a smaller level circle on either frame.
--
-- Forever's player frame is Mainline's (Blizzard_UnitFrame/Mainline/PlayerFrame.xml) with
-- Camelot's overrides (Camelot/PlayerFrame.lua): the portrait is 60x60 at TOPLEFT 24, -19 of
-- PlayerFrame.PlayerFrameContainer, and the level is PlayerLevelText centered on
-- PlayerFrameContentMain.LevelBackgroundCircle (UI-HUD-UnitFrame-SmallCircle, BOTTOMLEFT 13, 7),
-- which Camelot always shows.
--
-- The target frame is its mirror (Mainline/TargetFrame.xml with Camelot/TargetFrame.lua): the
-- level is TargetFrameContentMain.LevelText centered on its LevelBackgroundCircle (BOTTOMRIGHT
-- -13, 7), and the skull of a target too high to tell, TargetFrameContentContextual's
-- HighLevelTexture, is centered on the same circle. It draws its dragon as
-- TargetFrameContainer.BossPortraitFrameTexture at TOPRIGHT of its container, with the atlas and
-- offsets of Camelot/TargetFrameUtils.lua's GetBossPortraitFrameData, and only for a mob: a
-- player's classification is "normal", so ours and Blizzard's never show together (Gethe
-- `forever` branch, checked 2026-11-27).
--
-- Everything shown is ours: a texture on the container for the dragon, and a circle, a number,
-- and on the target a skull for the level, while Blizzard's are faded with SetAlpha(0). Nothing
-- of Blizzard's is moved, sized, shown, hidden, or reparented, so the secure frames are never
-- touched. Our own regions are laid out out of combat (ns.AfterCombat); in combat they only
-- change text, color, and alpha, which is all a new target needs.
local _, ns = ...

local C_Texture, UnitIsPlayer = C_Texture, UnitIsPlayer

local L = ns.L

local module = ns.NewModule("PlayerPortrait", L.PLAYERPORTRAIT_DESC, {
    enabled = false,
    chain = "elite",
    levelSize = 80, -- percent of Blizzard's level circle and number; 100 leaves Blizzard's alone
    targetChain = "off", -- around a player you target
    targetLevelSize = 100, -- the target frame's, whoever the target is
})
module.title = L.PLAYERPORTRAIT_TITLE
module.category = "units"
module.added = "1.10.0"

-- The target frame's dragons, by the atlas names Blizzard's own code uses (Forever draws them
-- from its `-c60` sheet: Gold and Rare-Silver 100x100, Rare-Silver-Winged 110x89; wago.tools
-- UiTextureAtlasMember, build 1.60.1.71139). Camelot's target uses Gold for an elite and the winged
-- silver for a rare or rare elite; Mainline's plain silver, at Gold's place, is Rare here, as the
-- silver dragon without wings is Classic's rare.
local ATLAS = {
    elite = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",
    rare = "ui-hud-unitframe-target-portraiton-boss-rare-silver",
    rareelite = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged",
}
-- Where each goes, { x, y }. On the target, TOPRIGHT of its container, as Camelot's code places
-- them. On the player, TOPLEFT of its container with those mirrored: x -1 - x and y - 1, since the
-- player's portrait sits 1 further in and 1 lower than the target's.
local TARGET_OFFSETS = { elite = { 0, 1 }, rare = { 0, 1 }, rareelite = { 8, -7 } }
local PLAYER_OFFSETS = { elite = { -1, 0 }, rare = { -1, 0 }, rareelite = { -9, -8 } }
local CIRCLE = "UI-HUD-UnitFrame-SmallCircle"
local SKULL = "UI-HUD-UnitFrame-Target-HighLevelTarget_Icon"

-- The two frames. Each holds its option keys and where its dragon goes, what's ours on it once
-- laid out (chain, circle, level, skull), what ours were last laid out as (chainStyle,
-- levelSize), so a change made in combat shows only once it's laid out, and what Blizzard last
-- did to its own level (textShown, circleShown, skullShown), mirrored onto ours.
local player = {
    chainKey = "chain", sizeKey = "levelSize",
    offsets = PLAYER_OFFSETS, point = "TOPLEFT", mirrored = true,
    -- Above the frame art and the combat glow, as the target frame's dragon is.
    layer = "OVERLAY", sublevel = 1,
    textShown = true, circleShown = true, skullShown = false, follows = {},
}
local target = {
    chainKey = "targetChain", sizeKey = "targetLevelSize",
    offsets = TARGET_OFFSETS, point = "TOPRIGHT",
    -- BossPortraitFrameTexture's own layer, over the threat glow.
    layer = "ARTWORK", sublevel = 2,
    textShown = true, circleShown = true, skullShown = false, follows = {},
}

-- Whether the target is a player: only then does the target frame get our dragon.
local targetPlayer = false

-- The parts of Blizzard's player frame we sit in, or nil on a client without them: the
-- container, the content frame, its level circle, and its level text.
function player.parts()
    local frame = PlayerFrame
    local container = frame and frame.PlayerFrameContainer
    local content = frame and frame.PlayerFrameContent
    local main = content and content.PlayerFrameContentMain
    if container and main and main.LevelBackgroundCircle and PlayerLevelText then
        return container, main, main.LevelBackgroundCircle, PlayerLevelText
    end
end

-- The same of the target frame, and its skull.
function target.parts()
    local frame = _G.TargetFrame
    local container = frame and frame.TargetFrameContainer
    local content = frame and frame.TargetFrameContent
    local main = content and content.TargetFrameContentMain
    local contextual = content and content.TargetFrameContentContextual
    if container and main and main.LevelBackgroundCircle and main.LevelText then
        return container, main, main.LevelBackgroundCircle, main.LevelText,
            contextual and contextual.HighLevelTexture
    end
end

-- Whether the frame shows the player's own art: in a vehicle Blizzard swaps it for the vehicle's
-- ring and portrait (PlayerFrame_ToVehicleArt), which the dragon doesn't fit.
function player.wanted()
    local frame = PlayerFrame
    return frame ~= nil and (frame.state == nil or frame.state == "player")
end

function target.wanted()
    return targetPlayer
end

function module:IsAvailable()
    return player.parts() ~= nil
end

local function hasTargetFrame()
    return target.parts() ~= nil
end

local CHAIN_CHOICES = {
    { "off", L.PLAYERPORTRAIT_CHAIN_OFF },
    { "elite", L.PLAYERPORTRAIT_CHAIN_ELITE },
    { "rare", L.PLAYERPORTRAIT_CHAIN_RARE },
    { "rareelite", L.PLAYERPORTRAIT_CHAIN_RAREELITE },
}

module.options = {
    {
        key = "chain",
        name = L.PLAYERPORTRAIT_CHAIN,
        description = L.PLAYERPORTRAIT_CHAIN_DESC,
        choices = CHAIN_CHOICES,
    },
    {
        key = "levelSize",
        name = L.PLAYERPORTRAIT_LEVEL_SIZE,
        description = L.PLAYERPORTRAIT_LEVEL_SIZE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
    {
        key = "targetChain",
        name = L.PLAYERPORTRAIT_TARGET_CHAIN,
        description = L.PLAYERPORTRAIT_TARGET_CHAIN_DESC,
        choices = CHAIN_CHOICES,
        available = hasTargetFrame, needs = L.SETTINGS_NEEDS_CLIENT,
    },
    {
        key = "targetLevelSize",
        name = L.PLAYERPORTRAIT_TARGET_LEVEL_SIZE,
        description = L.PLAYERPORTRAIT_TARGET_LEVEL_SIZE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
        available = hasTargetFrame, needs = L.SETTINGS_NEEDS_CLIENT,
    },
}

local function atlasInfo(atlas)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
end

-- Draws one of the dragons on a frame's own texture. The target's as Blizzard's code does, at the
-- atlas's size. The player's left to right, through the atlas's file and coordinates, so it
-- doesn't depend on how this client treats tex coords set over an atlas. False when the client
-- hasn't the atlas.
local function drawChain(side, atlas)
    local info = atlasInfo(atlas)
    if not info then
        return false
    end
    if not side.mirrored then
        side.chain:SetAtlas(atlas, true)
        return true
    end
    local file = info.file or info.filename
    if not file then
        return false
    end
    side.chain:SetTexture(file)
    side.chain:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
    side.chain:SetSize(info.width, info.height)
    return true
end

-- Alpha only, so this is safe in combat.
local function updateShown(side)
    local _, _, blizzCircle, blizzText, blizzSkull = side.parts()
    if not blizzCircle then
        return
    end
    if side.chain then
        local wanted = module.enabled and side.chainStyle ~= nil
            and side.chainStyle == module.db[side.chainKey] and side.wanted()
        side.chain:SetAlpha(wanted and 1 or 0)
    end
    local on = module.enabled and side.circle ~= nil and module.db[side.sizeKey] ~= 100
        and side.levelSize == module.db[side.sizeKey]
    if side.circle then
        side.circle:SetAlpha(on and side.circleShown and 1 or 0)
        side.level:SetAlpha(on and side.textShown and 1 or 0)
    end
    if side.skull then
        side.skull:SetAlpha(on and side.skullShown and 1 or 0)
        blizzSkull:SetAlpha(on and 0 or 1)
    end
    blizzCircle:SetAlpha(on and 0 or 1)
    blizzText:SetAlpha(on and 0 or 1)
end

-- Our number and color from Blizzard's level text. A color can carry an alpha, so ours is set
-- again after it.
local function copyLevel(side)
    local _, _, _, blizzText = side.parts()
    if not (side.level and blizzText) then
        return
    end
    side.level:SetText(blizzText:GetText())
    if blizzText.GetVertexColor then
        local r, g, b = blizzText:GetVertexColor()
        side.level:SetVertexColor(r, g, b)
    end
    updateShown(side)
end

-- Ours, once: added to Blizzard's frames, never set on them.
local function build(side, container, main, blizzCircle, blizzSkull)
    if side.chain then
        return
    end
    side.chain = container:CreateTexture(nil, side.layer, nil, side.sublevel)
    side.chain:SetAlpha(0)

    local info = atlasInfo(CIRCLE)
    local font = WhiteLargeNumberFont -- the level text template's font (Camelot), on both frames
    if not (info and font) then
        return -- the level is left as Blizzard draws it
    end
    side.circleWidth, side.circleHeight = info.width, info.height
    side.fontPath, side.fontSize, side.fontFlags = font:GetFont()
    -- In Blizzard's circle's layer, centered where its circle is.
    side.circle = main:CreateTexture(nil, "OVERLAY", nil, 3)
    side.circle:SetAtlas(CIRCLE)
    side.circle:SetPoint("CENTER", blizzCircle, "CENTER", 0, 0)
    side.circle:SetAlpha(0)
    side.level = main:CreateFontString(nil, "OVERLAY", "WhiteLargeNumberFont")
    side.level:SetDrawLayer("OVERLAY", 4)
    -- As Camelot's PlayerFrame_OnLoad and TargetFrameMixin:OnLoad place theirs.
    side.level:SetPoint("CENTER", side.circle, "CENTER", 0, -0.5)
    side.level:SetAlpha(0)
    -- The skull, on the frame and in the layer Blizzard's is, so it sorts as Blizzard's does.
    local skull = blizzSkull and atlasInfo(SKULL)
    if skull then
        side.skullWidth, side.skullHeight = skull.width, skull.height
        side.skull = blizzSkull:GetParent():CreateTexture(nil, "OVERLAY", nil, 1)
        side.skull:SetAtlas(SKULL)
        side.skull:SetPoint("CENTER", side.circle, "CENTER", 0, 0)
        side.skull:SetAlpha(0)
    end
    copyLevel(side)
end

-- Sizes and places ours. Out of combat only, though they're our own regions: they sit on a
-- secure frame.
local function layout(side)
    local container, main, blizzCircle, _, blizzSkull = side.parts()
    if not (module.enabled and container) then
        return
    end
    build(side, container, main, blizzCircle, blizzSkull)
    local style = module.db[side.chainKey]
    local offset = side.offsets[style]
    if offset and drawChain(side, ATLAS[style]) then
        side.chain:ClearAllPoints()
        side.chain:SetPoint(side.point, container, side.point, offset[1], offset[2])
        side.chainStyle = style
    else
        side.chainStyle = nil
    end
    local size = module.db[side.sizeKey]
    if side.circle and size ~= 100 then
        local scale = size / 100
        side.circle:SetSize(side.circleWidth * scale, side.circleHeight * scale)
        side.level:SetFont(side.fontPath, side.fontSize * scale, side.fontFlags)
        if side.skull then
            side.skull:SetSize(side.skullWidth * scale, side.skullHeight * scale)
        end
        side.levelSize = size
    end
    updateShown(side)
end

local function layoutAll()
    layout(player)
    layout(target)
end

local function updateAll()
    updateShown(player)
    updateShown(target)
end

-- Follows one of Blizzard's regions as it's shown and hidden, into side[field]. The hooks are
-- made once for a side and field, as module:Hook knows a hook by its function.
local function follow(side, region, field)
    if not region then
        return
    end
    side[field] = ns.IsTrue(region:IsShown())
    local hooks = side.follows[field]
    if not hooks then
        hooks = {
            show = function()
                side[field] = true
                updateShown(side)
            end,
            hide = function()
                side[field] = false
                updateShown(side)
            end,
            set = function(_, shown)
                side[field] = ns.IsTrue(shown)
                updateShown(side)
            end,
        }
        side.follows[field] = hooks
    end
    module:Hook(region, "Show", hooks.show)
    module:Hook(region, "Hide", hooks.hide)
    module:Hook(region, "SetShown", hooks.set)
end

-- Blizzard sets the level's number and color (PlayerFrame_UpdateLevel, TargetFrameMixin's
-- CheckLevel), hides it in a vehicle and where a role icon takes its place
-- (PlayerFrame_ToVehicleArt, PlayerFrame_UpdateRolesAssigned), and swaps it for the skull on a
-- target too high to tell: ours follow each. The number may be secret, and goes straight on.
local function watch(side)
    local _, _, blizzCircle, blizzText, blizzSkull = side.parts()
    if not blizzCircle then
        return
    end
    side.onText = side.onText or function(_, text)
        if side.level then
            side.level:SetText(text)
        end
    end
    side.onColor = side.onColor or function(_, r, g, b)
        if side.level then
            side.level:SetVertexColor(r, g, b)
            updateShown(side)
        end
    end
    module:Hook(blizzText, "SetText", side.onText)
    module:Hook(blizzText, "SetVertexColor", side.onColor)
    follow(side, blizzText, "textShown")
    follow(side, blizzCircle, "circleShown")
    follow(side, blizzSkull, "skullShown")
    copyLevel(side)
end

local function updatePlayer()
    updateShown(player)
end

local function onTarget()
    targetPlayer = ns.IsTrue(UnitIsPlayer("target"))
    updateShown(target)
end

function module:OnEnable()
    watch(player)
    watch(target)
    -- Vehicle art in and out.
    self:Hook("PlayerFrame_UpdateArt", updatePlayer)
    self:On("PLAYER_TARGET_CHANGED", onTarget)
    targetPlayer = ns.IsTrue(UnitIsPlayer("target"))
    ns.AfterCombat(layoutAll)
end

-- What was turned off goes at once; what was turned on or resized shows once laid out.
function module:OnOptionChanged()
    updateAll()
    ns.AfterCombat(layoutAll)
end

-- module.enabled is already false: ours fade out and Blizzard's level comes back.
function module:OnDisable()
    updateAll()
end
