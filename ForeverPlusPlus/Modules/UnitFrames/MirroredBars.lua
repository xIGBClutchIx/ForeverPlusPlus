-- Mirrored Bars: the target's and focus's health, power, and cast bars fill from the right, so
-- they empty from left to right, mirroring the player frame across the screen.
--
-- The bars are flipped with StatusBar:SetReverseFill. Blizzard draws heal prediction and absorbs
-- as segments whose mask it anchors to the right edge of the bar's fill, and an over-absorb glow
-- on the bar's right end, so those are mirrored too: each segment is re-anchored to the fill's
-- left edge after Blizzard places it, and the glows swap ends. The cast bar's spark is placed
-- from the bar's left edge every frame, so it's moved to the same distance from the right edge
-- after each. The bars' art is flipped too, so its shading isn't backwards. Turning off flips
-- everything back.
local _, ns = ...

local _G, setmetatable, ipairs, unpack, C_Texture = _G, setmetatable, ipairs, unpack, C_Texture

local L = ns.L
local readable = ns.IsReadable

local module = ns.NewModule("MirroredBars", L.MIRROREDBARS_DESC, {
    enabled = true,
    health = true,
    mana = true,
    castBar = true,
    flipArt = true,
    target = true,
    focus = true,
})
module.title = L.MIRROREDBARS_TITLE
module.category = "unitframes"

local BARS = L.MIRROREDBARS_SECTION_BARS
local FRAMES = L.MIRROREDBARS_SECTION_FRAMES
module.options = {
    { key = "health", name = L.MIRROREDBARS_HEALTH, description = L.MIRROREDBARS_HEALTH_DESC, section = BARS },
    { key = "mana", name = L.MIRROREDBARS_MANA, description = L.MIRROREDBARS_MANA_DESC, section = BARS },
    { key = "castBar", name = L.MIRROREDBARS_CAST, description = L.MIRROREDBARS_CAST_DESC, section = BARS },
    { key = "flipArt", name = L.MIRROREDBARS_ART, description = L.MIRROREDBARS_ART_DESC, section = BARS },
    { key = "target", name = L.MIRROREDBARS_TARGET, description = L.MIRROREDBARS_TARGET_DESC, section = FRAMES },
    { key = "focus", name = L.MIRROREDBARS_FOCUS, description = L.MIRROREDBARS_FOCUS_DESC, section = FRAMES },
}

-- The heal prediction and absorb segments Blizzard lays over a health bar.
local SEGMENTS = { "myHealPredictionBar", "otherHealPredictionBar", "healAbsorbBar", "totalAbsorbBar" }
-- How far Blizzard tucks the glows over the bar's end (UnitFrame_Initialize).
local GLOW_INSET = 7

local weak = { __mode = "k" }
local glowTexCoords = setmetatable({}, weak) -- Texture -> Blizzard's tex coords before we flipped it
local mirroredHealth = setmetatable({}, weak) -- unit frame -> true while its health bar is mirrored
local mirroredCast = setmetatable({}, weak) -- cast bar -> true while it's mirrored
local wantArt = setmetatable({}, weak) -- StatusBar -> true while its art should be flipped
local artFlipped = setmetatable({}, weak) -- StatusBar -> the atlas we flipped, or false for a file

-- The frames the module can mirror, with the setting each falls under.
local function frames()
    return {
        { _G.TargetFrame, "target" },
        { _G.FocusFrame, "focus" },
    }
end

local function wants(part, bar)
    local db = module.db
    return module.enabled and db[part] and db[bar] and true or false
end

-- Puts a segment's mask on the other side of whatever Blizzard anchored it to: from Blizzard's
-- "left edge on the previous texture's right edge" to "right edge on its left edge", or back.
-- Blizzard re-anchors it on every update, so this runs after each one.
local function flipSegment(mask, mirrored)
    if mask.IsAnchoringRestricted and mask:IsAnchoringRestricted() then
        return
    end
    local point, relativeTo, _, x = mask:GetPoint(1)
    if not point or not readable(x) then
        return -- hidden, or its offset is secret: Blizzard's own spot is masked off the bar anyway
    end
    local isMirrored = point == "TOPRIGHT" or point == "BOTTOMRIGHT"
    if isMirrored == mirrored then
        return
    end
    x = -(x or 0)
    mask:ClearAllPoints()
    if mirrored then
        mask:SetPoint("TOPRIGHT", relativeTo, "TOPLEFT", x, 0)
        mask:SetPoint("BOTTOMRIGHT", relativeTo, "BOTTOMLEFT", x, 0)
    else
        mask:SetPoint("TOPLEFT", relativeTo, "TOPRIGHT", x, 0)
        mask:SetPoint("BOTTOMLEFT", relativeTo, "BOTTOMRIGHT", x, 0)
    end
end

local function onSegmentUpdate(segment)
    local frame = segment.statusBar and segment.statusBar.unitFrame
    local mask = segment.FillMask
    if frame and mask then
        flipSegment(mask, mirroredHealth[frame] or false)
    end
end

local function flipTexCoords(texture, mirrored)
    if mirrored and not glowTexCoords[texture] then
        local c = { texture:GetTexCoord() }
        glowTexCoords[texture] = c
        texture:SetTexCoord(c[5], c[6], c[7], c[8], c[1], c[2], c[3], c[4])
    elseif not mirrored and glowTexCoords[texture] then
        texture:SetTexCoord(unpack(glowTexCoords[texture]))
        glowTexCoords[texture] = nil
    end
end

-- The over-absorb glow sits on the end of the bar where health is, and the over-heal-absorb glow
-- on the other. Blizzard sets their anchors once, so these are its anchors and their mirror.
local function placeGlows(frame, bar, mirrored)
    local absorb, healAbsorb = frame.overAbsorbGlow, frame.overHealAbsorbGlow
    local health, empty = "RIGHT", "LEFT"
    if mirrored then
        health, empty = "LEFT", "RIGHT"
    end
    local inset = mirrored and GLOW_INSET or -GLOW_INSET
    if absorb then
        absorb:ClearAllPoints()
        absorb:SetPoint("TOP" .. empty, bar, "TOP" .. health, inset, 0)
        absorb:SetPoint("BOTTOM" .. empty, bar, "BOTTOM" .. health, inset, 0)
        flipTexCoords(absorb, mirrored)
    end
    if healAbsorb then
        healAbsorb:ClearAllPoints()
        healAbsorb:SetPoint("TOP" .. health, bar, "TOP" .. empty, -inset, 0)
        healAbsorb:SetPoint("BOTTOM" .. health, bar, "BOTTOM" .. empty, -inset, 0)
        flipTexCoords(healAbsorb, mirrored)
    end
end

local function applyHealth(frame, mirrored)
    local bar = frame.healthbar
    if not bar or (mirroredHealth[frame] or false) == mirrored then
        return
    end
    mirroredHealth[frame] = mirrored or nil
    bar:SetReverseFill(mirrored)
    placeGlows(frame, bar, mirrored)
    for _, key in ipairs(SEGMENTS) do
        local segment = frame[key]
        if segment and segment.UpdateFillPosition then
            if mirrored then
                module:Hook(segment, "UpdateFillPosition", onSegmentUpdate)
            end
            if segment.FillMask then
                flipSegment(segment.FillMask, mirrored)
            end
        end
    end
end

-- Blizzard puts the spark's center a distance from the bar's left edge (CastingBarMixin:OnUpdate);
-- this moves it to that distance from the right edge, or back.
local function flipSpark(bar, mirrored)
    local spark = bar.Spark
    if not spark or (spark.IsAnchoringRestricted and spark:IsAnchoringRestricted()) then
        return
    end
    local point, relativeTo, relativePoint, x, y = spark:GetPoint(1)
    if point ~= "CENTER" or relativeTo ~= bar or not readable(x) then
        return
    end
    local from, to = "LEFT", "RIGHT"
    if not mirrored then
        from, to = "RIGHT", "LEFT"
    end
    if relativePoint == from then
        spark:ClearAllPoints()
        spark:SetPoint("CENTER", bar, to, -(x or 0), y)
    end
end

local function onCastUpdate(bar)
    if mirroredCast[bar] then
        flipSpark(bar, true)
    end
end

local function applyCast(bar, mirrored)
    if not bar or (mirroredCast[bar] or false) == mirrored then
        return
    end
    mirroredCast[bar] = mirrored or nil
    bar:SetReverseFill(mirrored)
    if mirrored then
        module:HookScript(bar, "OnUpdate", onCastUpdate)
    end
    flipSpark(bar, mirrored)
end

-- Draws a bar's art mirrored, so its shading runs the other way too: the atlas's file with its
-- left and right tex coords swapped, which the bar then crops as it fills. A bar drawn from a
-- whole file just swaps 0 and 1. Only once per texture Blizzard sets, since after this the
-- texture no longer reports its atlas.
local function flipArt(bar)
    if artFlipped[bar] ~= nil then
        return
    end
    local texture = bar:GetStatusBarTexture()
    if not texture then
        return
    end
    local atlas = texture:GetAtlas()
    if atlas then
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
        local file = info and (info.file or info.filename)
        if not file or info.tilesHorizontally then
            return
        end
        texture:SetTexture(file)
        texture:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
        artFlipped[bar] = atlas
    else
        texture:SetTexCoord(1, 0, 0, 1)
        artFlipped[bar] = false
    end
end

local function restoreArt(bar)
    local atlas = artFlipped[bar]
    local texture = bar:GetStatusBarTexture()
    artFlipped[bar] = nil
    if atlas then
        texture:SetAtlas(atlas)
    elseif atlas == false then
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

-- Blizzard changes some bars' art (the power bar by power type, the cast bar by cast type).
local function onBarTexture(bar)
    artFlipped[bar] = nil
    if wantArt[bar] then
        flipArt(bar)
    end
end

local function applyArt(bar, flipped)
    if not bar then
        return
    end
    wantArt[bar] = flipped or nil
    if flipped then
        module:Hook(bar, "SetStatusBarTexture", onBarTexture)
        flipArt(bar)
    else
        restoreArt(bar)
    end
end

local function apply()
    local art = module.db.flipArt
    for _, entry in ipairs(frames()) do
        local frame, part = entry[1], entry[2]
        if frame then
            local health, mana, cast = wants(part, "health"), wants(part, "mana"), wants(part, "castBar")
            applyHealth(frame, health)
            applyArt(frame.healthbar, health and art)
            if frame.manabar then
                frame.manabar:SetReverseFill(mana)
                applyArt(frame.manabar, mana and art)
            end
            applyCast(frame.spellbar, cast)
            applyArt(frame.spellbar, cast and art)
        end
    end
end

-- The bars belong to secure unit frames, so change them out of combat.
local function update()
    ns.AfterCombat(apply)
end

function module:OnEnable()
    update()
end

-- module.enabled is already false here, so every bar goes back to Blizzard's direction.
function module:OnDisable()
    update()
end

function module:OnOptionChanged()
    update()
end
