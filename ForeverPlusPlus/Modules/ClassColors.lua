-- Class Colors: players' health bars and names in their class color on the player, target, focus,
-- party, and target-of-target frames. NPCs, and players whose class can't be read, keep
-- Blizzard's colors. Idea from MiniClassColors; none of its code.
--
-- Blizzard's health bars are a green texture with lockColor set, so Blizzard never colors them
-- except party frames, which desaturate the bar for a disconnected member. The bar is
-- desaturated and tinted to show a class color. Every call Blizzard makes to a bar's color or
-- desaturation is remembered and then painted over again, so turning a part off puts back
-- exactly what Blizzard last set.
local _, ns = ...

local _G, setmetatable, hooksecurefunc = _G, setmetatable, hooksecurefunc
local UnitIsPlayer, UnitIsConnected = UnitIsPlayer, UnitIsConnected

local L = ns.L
local readable = ns.IsReadable
local classColor = ns.Colors.Class

local module = ns.NewModule("ClassColors", L.CLASSCOLORS_DESC, {
    enabled = false,
    healthBars = true,
    names = false,
    player = true,
    target = true,
    focus = true,
    party = true,
    targetOfTarget = true,
})
module.title = L.CLASSCOLORS_TITLE
module.category = "unitframes"

local PARTS = L.CLASSCOLORS_SECTION_PARTS
local FRAMES = L.CLASSCOLORS_SECTION_FRAMES
module.options = {
    { key = "healthBars", name = L.CLASSCOLORS_BARS, description = L.CLASSCOLORS_BARS_DESC, section = PARTS },
    { key = "names", name = L.CLASSCOLORS_NAMES, description = L.CLASSCOLORS_NAMES_DESC, section = PARTS },
    { key = "player", name = L.CLASSCOLORS_PLAYER, description = L.CLASSCOLORS_PLAYER_DESC, section = FRAMES },
    { key = "target", name = L.CLASSCOLORS_TARGET, description = L.CLASSCOLORS_TARGET_DESC, section = FRAMES },
    { key = "focus", name = L.CLASSCOLORS_FOCUS, description = L.CLASSCOLORS_FOCUS_DESC, section = FRAMES },
    { key = "party", name = L.CLASSCOLORS_PARTY, description = L.CLASSCOLORS_PARTY_DESC, section = FRAMES },
    { key = "targetOfTarget", name = L.CLASSCOLORS_TOT, description = L.CLASSCOLORS_TOT_DESC, section = FRAMES },
}

local MAX_PARTY = 4
local weak = { __mode = "k" }
local barHooked = setmetatable({}, weak) -- StatusBar -> true once its setters are hooked
local applying = setmetatable({}, weak) -- StatusBar -> true while we set its color ourselves
local painted = setmetatable({}, weak) -- StatusBar or FontString -> true while in a class color
local blizzardColor = setmetatable({}, weak) -- StatusBar -> { r, g, b, a } Blizzard last set
local blizzardDesaturated = setmetatable({}, weak) -- StatusBar -> what Blizzard last set
local nameColor = setmetatable({}, weak) -- FontString -> { r, g, b, a } before we colored it

-- Which of the module's frame settings a Blizzard unit frame falls under, or nil.
local function partOf(frame)
    if not frame then
        return nil
    end
    local target, focus = _G.TargetFrame, _G.FocusFrame
    if frame == _G.PlayerFrame then
        return "player"
    elseif frame == target then
        return "target"
    elseif frame == focus then
        return "focus"
    elseif (target and frame == target.totFrame) or (focus and frame == focus.totFrame) then
        return "targetOfTarget"
    elseif _G.PartyFrame and frame:GetParent() == _G.PartyFrame then
        return "party"
    end
end

-- The class color for `unit` if `setting` (healthBars or names) is on for `frame`, else nil.
-- Disconnected players keep Blizzard's gray.
local function wanted(frame, unit, setting)
    local part = partOf(frame)
    if not (module.enabled and module.db[setting] and part and module.db[part] and unit) then
        return nil
    end
    local player = UnitIsPlayer(unit)
    if not (readable(player) and player) then
        return nil
    end
    local connected = UnitIsConnected(unit)
    if readable(connected) and not connected then
        return nil
    end
    return classColor(unit)
end

local function restoreBar(bar)
    local color = blizzardColor[bar]
    local desaturated = blizzardDesaturated[bar]
    applying[bar] = true
    bar:SetStatusBarDesaturated(desaturated or false)
    if color then
        bar:SetStatusBarColor(color[1], color[2], color[3], color[4])
    else
        bar:SetStatusBarColor(1, 1, 1) -- lockColor bars: Blizzard never tints them
    end
    applying[bar] = nil
    painted[bar] = nil
end

local function paintBar(bar)
    local color = wanted(bar.unitFrame, bar.unit, "healthBars")
    if not color then
        if painted[bar] then
            restoreBar(bar)
        end
        return
    end
    applying[bar] = true
    bar:SetStatusBarDesaturated(true)
    bar:SetStatusBarColor(color:GetRGB())
    applying[bar] = nil
    painted[bar] = true
end

-- Remember what Blizzard sets, then paint over it again.
local function onBarColor(bar, r, g, b, a)
    if applying[bar] then
        return
    end
    blizzardColor[bar] = { r, g, b, a }
    paintBar(bar)
end

local function onBarDesaturated(bar, desaturated)
    if applying[bar] then
        return
    end
    blizzardDesaturated[bar] = desaturated
    paintBar(bar)
end

local function hookBar(bar)
    if not bar or barHooked[bar] then
        return
    end
    barHooked[bar] = true
    hooksecurefunc(bar, "SetStatusBarColor", onBarColor)
    hooksecurefunc(bar, "SetStatusBarDesaturated", onBarDesaturated)
end

local function paintName(frame)
    local text = frame.name
    if not text then
        return
    end
    local color = wanted(frame, frame.unit, "names")
    if color then
        if not nameColor[text] then
            nameColor[text] = { text:GetTextColor() }
        end
        text:SetTextColor(color:GetRGB())
        painted[text] = true
    elseif painted[text] then
        local old = nameColor[text]
        text:SetTextColor(old[1], old[2], old[3], old[4])
        painted[text] = nil
    end
end

local function update(frame)
    if not partOf(frame) then
        return
    end
    local bar = frame.healthbar
    if bar then
        hookBar(bar)
        paintBar(bar)
    end
    paintName(frame)
end

-- Blizzard calls UnitFrame_Update whenever a frame's unit changes (a new target, the party
-- roster, the target's target), so the colors follow it.
local function onUnitFrameUpdate(frame)
    if module.enabled then
        update(frame)
    end
end

local function updateAll()
    local target, focus, party = _G.TargetFrame, _G.FocusFrame, _G.PartyFrame
    update(_G.PlayerFrame)
    update(target)
    update(focus)
    update(target and target.totFrame)
    update(focus and focus.totFrame)
    for i = 1, MAX_PARTY do
        update(party and party["MemberFrame" .. i])
    end
end

local hooked = false

function module:OnEnable()
    if not hooked and _G.UnitFrame_Update then
        hooked = true
        hooksecurefunc("UnitFrame_Update", onUnitFrameUpdate)
    end
    updateAll()
end

-- module.enabled is already false here, so every painted bar and name goes back to Blizzard's.
function module:OnDisable()
    updateAll()
end

function module:OnOptionChanged()
    updateAll()
end
