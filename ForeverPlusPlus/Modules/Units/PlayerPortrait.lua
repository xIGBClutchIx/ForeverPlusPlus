-- Player Portrait: the dragon chain the target frame puts around an elite or rare mob's portrait,
-- around your own, and a smaller level circle on the player frame.
--
-- Forever's player frame is Mainline's (Blizzard_UnitFrame/Mainline/PlayerFrame.xml) with
-- Camelot's overrides (Camelot/PlayerFrame.lua): the portrait is 60x60 at TOPLEFT 24, -19 of
-- PlayerFrame.PlayerFrameContainer, and the level is PlayerLevelText centered on
-- PlayerFrameContentMain.LevelBackgroundCircle (UI-HUD-UnitFrame-SmallCircle, BOTTOMLEFT 13, 7),
-- which Camelot always shows. The target frame draws its dragon as BossPortraitFrameTexture at
-- TOPRIGHT of its container, with the atlas and offsets of Camelot/TargetFrameUtils.lua's
-- GetBossPortraitFrameData (Gethe `forever` branch, checked 2026-11-27).
--
-- Everything shown is ours: a texture on the container for the chain, and a circle and a font
-- string on the content frame for the level, while Blizzard's circle and level text are faded
-- with SetAlpha(0). Nothing of Blizzard's is moved, sized, shown, hidden, or reparented, so the
-- secure player frame is never touched. Our own regions are laid out out of combat
-- (ns.AfterCombat); in combat they only change text, color, and alpha.
local _, ns = ...

local C_Texture = C_Texture

local L = ns.L

local module = ns.NewModule("PlayerPortrait", L.PLAYERPORTRAIT_DESC, {
    enabled = false,
    chain = "elite",
    levelSize = 80, -- percent of Blizzard's level circle and number; 100 leaves Blizzard's alone
})
module.title = L.PLAYERPORTRAIT_TITLE
module.category = "units"
module.added = "1.10.0"

module.options = {
    {
        key = "chain",
        name = L.PLAYERPORTRAIT_CHAIN,
        description = L.PLAYERPORTRAIT_CHAIN_DESC,
        choices = {
            { "off", L.PLAYERPORTRAIT_CHAIN_OFF },
            { "elite", L.PLAYERPORTRAIT_CHAIN_ELITE },
            { "rare", L.PLAYERPORTRAIT_CHAIN_RARE },
            { "rareelite", L.PLAYERPORTRAIT_CHAIN_RAREELITE },
        },
    },
    {
        key = "levelSize",
        name = L.PLAYERPORTRAIT_LEVEL_SIZE,
        description = L.PLAYERPORTRAIT_LEVEL_SIZE_DESC,
        min = 50, max = 200, step = 10, format = "%d%%",
    },
}

-- The target frame's dragons, by the atlas names Blizzard's own code uses (Forever draws them
-- from its `-c60` sheet: Gold and Rare-Silver 100x100, Rare-Silver-Winged 110x89; wago.tools
-- UiTextureAtlasMember, build 1.60.1.71139). Camelot's target uses Gold for an elite and the winged
-- silver for a rare or rare elite; Mainline's plain silver, at Gold's place, is Rare here, as the
-- silver dragon without wings is Classic's rare. The offsets are TOPLEFT of the player frame's
-- container: Camelot's TOPRIGHT ones for the target mirrored, x -1 - x and y - 1, since the
-- player's portrait sits 1 further in and 1 lower than the target's.
local CHAINS = {
    elite = { "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold", -1, 0 },
    rare = { "ui-hud-unitframe-target-portraiton-boss-rare-silver", -1, 0 },
    rareelite = { "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged", -9, -8 },
}
local CIRCLE = "UI-HUD-UnitFrame-SmallCircle"

local chain -- our dragon, made the first time it's laid out
local circle, level -- our level circle and number
local circleWidth, circleHeight, fontPath, fontSize, fontFlags -- Blizzard's, read when ours are made
-- What ours were last laid out as, so a change made in combat shows only once it's laid out.
local chainStyle, levelSize

-- What Blizzard last did to its own level, mirrored onto ours.
local textShown, circleShown = true, true

-- The parts of Blizzard's player frame we sit in, or nil on a client without them.
local function playerFrame()
    local frame = PlayerFrame
    local container = frame and frame.PlayerFrameContainer
    local content = frame and frame.PlayerFrameContent
    local main = content and content.PlayerFrameContentMain
    if container and main and main.LevelBackgroundCircle and PlayerLevelText then
        return frame, container, main
    end
end

function module:IsAvailable()
    return playerFrame() ~= nil
end

-- An atlas drawn left to right, through its file and coordinates, so it doesn't depend on how
-- this client treats tex coords set over an atlas. False when the client hasn't the atlas.
local function setMirrored(texture, atlas)
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    local file = info and (info.file or info.filename)
    if not file then
        return false
    end
    texture:SetTexture(file)
    texture:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
    texture:SetSize(info.width, info.height)
    return true
end

-- Whether the frame shows the player's own art: in a vehicle Blizzard swaps it for the vehicle's
-- ring and portrait (PlayerFrame_ToVehicleArt), which the chain doesn't fit.
local function playerArt()
    local frame = playerFrame()
    return frame ~= nil and (frame.state == nil or frame.state == "player")
end

local function levelOn()
    return module.enabled and circle ~= nil and module.db.levelSize ~= 100
        and levelSize == module.db.levelSize
end

-- Our number and color from Blizzard's level text.
local function copyLevel()
    if not level then
        return
    end
    level:SetText(PlayerLevelText:GetText())
    if PlayerLevelText.GetVertexColor then
        level:SetVertexColor(PlayerLevelText:GetVertexColor())
    end
end

-- Alpha only, so this is safe in combat.
local function updateShown()
    local _, _, main = playerFrame()
    if not main then
        return
    end
    if chain then
        local wanted = module.enabled and chainStyle ~= nil and chainStyle == module.db.chain
            and playerArt()
        chain:SetAlpha(wanted and 1 or 0)
    end
    local on = levelOn()
    if circle then
        circle:SetAlpha(on and circleShown and 1 or 0)
        level:SetAlpha(on and textShown and 1 or 0)
    end
    main.LevelBackgroundCircle:SetAlpha(on and 0 or 1)
    PlayerLevelText:SetAlpha(on and 0 or 1)
end

-- Ours, once: added to Blizzard's frames, never set on them.
local function build(container, main)
    if chain then
        return
    end
    -- Above the frame art and the combat glow, as the target frame's dragon is.
    chain = container:CreateTexture(nil, "OVERLAY", nil, 1)
    chain:SetAlpha(0)

    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(CIRCLE)
    local font = WhiteLargeNumberFont -- PlayerLevelTextTemplate's font (Camelot)
    if not (info and font) then
        return -- the level is left as Blizzard draws it
    end
    circleWidth, circleHeight = info.width, info.height
    fontPath, fontSize, fontFlags = font:GetFont()
    -- In Blizzard's circle's layer, centered where its circle is.
    circle = main:CreateTexture(nil, "OVERLAY", nil, 3)
    circle:SetAtlas(CIRCLE)
    circle:SetPoint("CENTER", main.LevelBackgroundCircle, "CENTER", 0, 0)
    circle:SetAlpha(0)
    level = main:CreateFontString(nil, "OVERLAY", "WhiteLargeNumberFont")
    level:SetDrawLayer("OVERLAY", 4)
    level:SetPoint("CENTER", circle, "CENTER", 0, -0.5) -- as Camelot's PlayerFrame_OnLoad
    level:SetAlpha(0)
    copyLevel()
end

-- Sizes and places ours. Out of combat only, though they're our own regions: they sit on the
-- secure player frame.
local function layout()
    local _, container, main = playerFrame()
    if not (module.enabled and main) then
        return
    end
    build(container, main)
    local style = CHAINS[module.db.chain]
    if style and setMirrored(chain, style[1]) then
        chain:ClearAllPoints()
        chain:SetPoint("TOPLEFT", container, "TOPLEFT", style[2], style[3])
        chainStyle = module.db.chain
    else
        chainStyle = nil
    end
    if circle and module.db.levelSize ~= 100 then
        local scale = module.db.levelSize / 100
        circle:SetSize(circleWidth * scale, circleHeight * scale)
        level:SetFont(fontPath, fontSize * scale, fontFlags)
        levelSize = module.db.levelSize
    end
    updateShown()
end

local function onText(_, text)
    if level then
        level:SetText(text)
    end
end

local function onColor(_, r, g, b, a)
    if level then
        level:SetVertexColor(r, g, b, a)
    end
end

local function textShow()
    textShown = true
    updateShown()
end

local function textHide()
    textShown = false
    updateShown()
end

local function textSetShown(_, shown)
    textShown = shown and true or false
    updateShown()
end

local function circleShow()
    circleShown = true
    updateShown()
end

local function circleHide()
    circleShown = false
    updateShown()
end

local function circleSetShown(_, shown)
    circleShown = shown and true or false
    updateShown()
end

function module:OnEnable()
    local _, _, main = playerFrame()
    -- Blizzard hides the level in a vehicle and where a role icon takes its place
    -- (PlayerFrame_ToVehicleArt, PlayerFrame_UpdateRolesAssigned), and sets its number and color
    -- in PlayerFrame_UpdateLevel: ours follow each.
    textShown, circleShown = PlayerLevelText:IsShown(), main.LevelBackgroundCircle:IsShown()
    self:Hook(PlayerLevelText, "SetText", onText)
    self:Hook(PlayerLevelText, "SetVertexColor", onColor)
    self:Hook(PlayerLevelText, "Show", textShow)
    self:Hook(PlayerLevelText, "Hide", textHide)
    self:Hook(PlayerLevelText, "SetShown", textSetShown)
    self:Hook(main.LevelBackgroundCircle, "Show", circleShow)
    self:Hook(main.LevelBackgroundCircle, "Hide", circleHide)
    self:Hook(main.LevelBackgroundCircle, "SetShown", circleSetShown)
    -- Vehicle art in and out.
    self:Hook("PlayerFrame_UpdateArt", updateShown)
    copyLevel()
    ns.AfterCombat(layout)
end

-- What was turned off goes at once; what was turned on or resized shows once laid out.
function module:OnOptionChanged()
    updateShown()
    ns.AfterCombat(layout)
end

-- module.enabled is already false: ours fade out and Blizzard's level comes back.
function module:OnDisable()
    updateShown()
end
