-- Class Colors: players' health bars and names in their class color on the player, target, focus,
-- party, and target-of-target frames, and NPCs' health bars by reaction: red when hostile, yellow
-- when neutral, gray when tapped by someone else. Friendly NPCs, and units whose class or
-- reaction can't be read, keep Blizzard's green. Idea from MiniClassColors; none of its code.
-- With Friends and Who List on, online friends' names in the friends list and names in the who
-- list are in their class color too (the guild roster already does this itself).
--
-- Blizzard's health bars are a green texture with lockColor set, so Blizzard never colors them
-- except party frames, which desaturate the bar for a disconnected member. The bar is
-- desaturated and tinted to show a class color. Every call Blizzard makes to a bar's color or
-- desaturation is remembered and then painted over again, so turning a part off puts back
-- exactly what Blizzard last set.
local _, ns = ...

local _G, setmetatable, hooksecurefunc = _G, setmetatable, hooksecurefunc
local pairs, ipairs, format, wipe = pairs, ipairs, string.format, wipe
local C_ClassColor, C_FriendList, GetPlayerInfoByGUID = C_ClassColor, C_FriendList, GetPlayerInfoByGUID
local UnitIsPlayer, UnitIsConnected, UnitReaction = UnitIsPlayer, UnitIsConnected, UnitReaction
local UnitIsTapDenied, UnitPlayerControlled, CreateColor = UnitIsTapDenied, UnitPlayerControlled, CreateColor

local L = ns.L
local readable = ns.IsReadable
local classColor = ns.Colors.Class

local module = ns.NewModule("ClassColors", L.CLASSCOLORS_DESC, {
    enabled = true,
    healthBars = true,
    npcBars = true,
    nameColor = "default",
    nameBackgrounds = true,
    socialNames = true,
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
    { key = "npcBars", name = L.CLASSCOLORS_NPC_BARS, description = L.CLASSCOLORS_NPC_BARS_DESC, section = PARTS },
    {
        key = "nameColor", name = L.CLASSCOLORS_NAMES, description = L.CLASSCOLORS_NAMES_DESC, section = PARTS,
        choices = {
            { "default", L.CLASSCOLORS_NAMES_DEFAULT },
            { "white", L.CLASSCOLORS_NAMES_WHITE },
            { "class", L.CLASSCOLORS_NAMES_CLASS },
        },
    },
    { key = "nameBackgrounds", name = L.CLASSCOLORS_NAME_BG, description = L.CLASSCOLORS_NAME_BG_DESC, section = PARTS },
    { key = "socialNames", name = L.CLASSCOLORS_SOCIAL, description = L.CLASSCOLORS_SOCIAL_DESC, section = PARTS,
        added = "0.8.0" },
    { key = "player", name = L.CLASSCOLORS_PLAYER, description = L.CLASSCOLORS_PLAYER_DESC, section = FRAMES },
    { key = "target", name = L.CLASSCOLORS_TARGET, description = L.CLASSCOLORS_TARGET_DESC, section = FRAMES },
    { key = "focus", name = L.CLASSCOLORS_FOCUS, description = L.CLASSCOLORS_FOCUS_DESC, section = FRAMES },
    { key = "party", name = L.CLASSCOLORS_PARTY, description = L.CLASSCOLORS_PARTY_DESC, section = FRAMES },
    { key = "targetOfTarget", name = L.CLASSCOLORS_TOT, description = L.CLASSCOLORS_TOT_DESC, section = FRAMES },
}

local MAX_PARTY = 4
-- Blizzard's own hostile, neutral, and tapped colors (UnitSelectionColor, Classic's tapped bar).
local HOSTILE, NEUTRAL, TAPPED = CreateColor(1, 0, 0), CreateColor(1, 1, 0), CreateColor(0.5, 0.5, 0.5)
local WHITE = CreateColor(1, 1, 1)
local NEUTRAL_REACTION = 4 -- UnitReaction: 1-3 hostile, 4 neutral, 5-8 friendly
local weak = { __mode = "k" }
local barHooked = setmetatable({}, weak) -- StatusBar -> true once its setters are hooked
local applying = setmetatable({}, weak) -- StatusBar -> true while we set its color ourselves
local painted = setmetatable({}, weak) -- StatusBar or FontString -> true while in our color
local blizzardColor = setmetatable({}, weak) -- StatusBar -> { r, g, b, a } Blizzard last set
local blizzardDesaturated = setmetatable({}, weak) -- StatusBar -> what Blizzard last set
local nameColor = setmetatable({}, weak) -- FontString -> { r, g, b, a } before we colored it
local backgroundHooked = setmetatable({}, weak) -- Texture -> true once SetVertexColor is hooked
local blizzardBackground = setmetatable({}, weak) -- Texture -> { r, g, b, a } Blizzard last set

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

-- Whether the module colors this frame at all.
local function frameOn(frame, unit)
    local part = partOf(frame)
    return module.enabled and part and module.db[part] and unit and true or false
end

-- The NPC's reaction color, or nil for friendly NPCs and ones we can't read.
local function reactionColor(unit)
    local controlled = UnitPlayerControlled(unit)
    local tapped = UnitIsTapDenied(unit)
    if readable(controlled) and not controlled and readable(tapped) and tapped then
        return TAPPED
    end
    local reaction = UnitReaction("player", unit)
    if not (readable(reaction) and reaction) then
        return nil
    elseif reaction < NEUTRAL_REACTION then
        return HOSTILE
    elseif reaction == NEUTRAL_REACTION then
        return NEUTRAL
    end
end

-- The color for `unit`'s health bar or name (`setting` healthBars or names) on `frame`, else
-- nil for Blizzard's. Players get their class color; NPCs' bars get their reaction color with
-- npcBars on. Disconnected players keep Blizzard's gray.
local function wanted(frame, unit, setting)
    if not frameOn(frame, unit) then
        return nil
    end
    local player = UnitIsPlayer(unit)
    if not readable(player) then
        return nil
    elseif not player then
        return setting == "healthBars" and module.db.npcBars and reactionColor(unit) or nil
    elseif setting ~= "names" and not module.db[setting] then
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

-- Puts a font string in `color`, or back in the color it had before we first colored it.
local function colorText(text, color)
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

local function paintName(frame)
    local text = frame.name
    if not text then
        return
    end
    local color
    local choice = module.db.nameColor
    if choice == "white" then
        color = frameOn(frame, frame.unit) and WHITE or nil
    elseif choice == "class" then
        color = wanted(frame, frame.unit, "names")
    end
    colorText(text, color)
end

-- The bar behind a target or focus name that Blizzard tints by faction. The field name differs
-- between builds, so probe both; frames without one (player, party) return nil.
local function backgroundOf(frame)
    if frame.nameBackground then
        return frame.nameBackground
    end
    local content = frame.TargetFrameContent
    local main = content and content.TargetFrameContentMain
    return main and main.ReputationColor
end

local function restoreBackground(texture)
    local color = blizzardBackground[texture]
    applying[texture] = true
    if color then
        texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
    applying[texture] = nil
    painted[texture] = nil
end

local function paintBackground(texture, frame)
    local color = wanted(frame, frame.unit, "nameBackgrounds")
    if not color then
        if painted[texture] then
            restoreBackground(texture)
        end
        return
    end
    applying[texture] = true
    texture:SetVertexColor(color:GetRGB())
    applying[texture] = nil
    painted[texture] = true
end

local function hookBackground(texture, frame)
    if backgroundHooked[texture] then
        return
    end
    backgroundHooked[texture] = true
    hooksecurefunc(texture, "SetVertexColor", function(self, r, g, b, a)
        if applying[self] then
            return
        end
        blizzardBackground[self] = { r, g, b, a }
        paintBackground(self, frame)
    end)
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
    local texture = backgroundOf(frame)
    if texture then
        hookBackground(texture, frame)
        paintBackground(texture, frame)
    end
end

-- Blizzard calls UnitFrame_Update whenever a frame's unit changes (a new target, the party
-- roster, the target's target), so the colors follow it.
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

-- The friends list and the who list. Their rows are scroll box buttons, so we listen for the
-- scroll box's OnInitializedFrame, which it sends for addons after Blizzard's own initializer has
-- filled a row, and recolor the row then.

local FRIENDS_ADDON, WHO_ADDON = "Blizzard_FriendsFrame", "Blizzard_GroupFinder_VanillaStyle"
local lists = {} -- scroll box -> its paint function, while the module is on
local classTokens -- localized class name -> class token, filled on first use
local friendPainted = setmetatable({}, weak) -- friend button -> true while its name is colored

local function socialOn()
    return module.enabled and module.db.socialNames
end

local function classColorOf(class)
    return class and C_ClassColor and C_ClassColor.GetClassColor(class)
end

-- A friend's class token: from their GUID when the client knows it, else from the localized
-- class name the friend info carries.
local function friendClass(info)
    if info.guid and GetPlayerInfoByGUID then
        local _, class = GetPlayerInfoByGUID(info.guid)
        if readable(class) and class then
            return class
        end
    end
    if not classTokens then
        classTokens = {}
        for _, names in ipairs({ _G.LOCALIZED_CLASS_NAMES_MALE or {}, _G.LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
            for token, name in pairs(names) do
                classTokens[name] = token
            end
        end
    end
    return info.className and classTokens[info.className]
end

-- Blizzard draws an online WoW friend as "Name, Level 60 Warrior" in one flat color, so we write
-- the same line with only the name in its class color. Without `color` it's Blizzard's line.
local function friendText(info, color)
    local name = color and ns.Colors.Text(color, info.name) or info.name
    return name .. ", " .. format(_G.FRIENDS_LEVEL_TEMPLATE, info.level, info.className)
end

local function paintFriend(_, button, elementData)
    local info
    if elementData and elementData.buttonType == _G.FRIENDS_BUTTON_TYPE_WOW and button.name then
        info = C_FriendList.GetFriendInfoByIndex(elementData.id)
    end
    if not (info and info.connected and info.name) then
        friendPainted[button] = nil -- a different kind of row now, which Blizzard has redrawn
        return
    end
    local color = socialOn() and classColorOf(friendClass(info))
    if color then
        button.name:SetText(friendText(info, color))
        friendPainted[button] = true
    elseif friendPainted[button] then
        button.name:SetText(friendText(info))
        friendPainted[button] = nil
    end
end

-- The who list colors only the Class column; this colors the name too.
local function paintWho(_, button, elementData)
    local info = elementData and elementData.info
    if button.Name then
        colorText(button.Name, socialOn() and info and classColorOf(info.filename) or nil)
    end
end

local function repaint(scrollBox, paint)
    scrollBox:ForEachFrame(function(frame, elementData)
        paint(module, frame, elementData)
    end)
end

local function watchList(scrollBox, paint)
    if not scrollBox or lists[scrollBox] then
        return
    end
    lists[scrollBox] = paint
    scrollBox:RegisterCallback(_G.ScrollBoxListMixin.Event.OnInitializedFrame, paint, module)
    repaint(scrollBox, paint)
end

local function watchFriends()
    local frame = _G.FriendsListFrame
    watchList(frame and frame.ScrollBox, paintFriend)
end

local function watchWho()
    local frame = _G.LFGWhoListFrame
    watchList(frame and frame.ScrollBox, paintWho)
end

local function repaintLists()
    for scrollBox, paint in pairs(lists) do
        repaint(scrollBox, paint)
    end
end

function module:OnEnable()
    if _G.UnitFrame_Update then
        self:Hook("UnitFrame_Update", update)
    end
    -- A reaction or tap can change without a new unit (a mob turns hostile, someone tags it).
    self:On("UNIT_FACTION", updateAll)
    updateAll()
    if _G.ScrollBoxListMixin then
        ns.AddOns.WhenLoaded(FRIENDS_ADDON, watchFriends)
        ns.AddOns.WhenLoaded(WHO_ADDON, watchWho)
    end
end

-- module.enabled is already false here, so every painted bar and name goes back to Blizzard's.
function module:OnDisable()
    updateAll()
    ns.AddOns.Cancel(FRIENDS_ADDON, watchFriends)
    ns.AddOns.Cancel(WHO_ADDON, watchWho)
    repaintLists()
    for scrollBox in pairs(lists) do
        scrollBox:UnregisterCallback(_G.ScrollBoxListMixin.Event.OnInitializedFrame, module)
    end
    wipe(lists)
end

function module:OnOptionChanged()
    updateAll()
    repaintLists()
end
