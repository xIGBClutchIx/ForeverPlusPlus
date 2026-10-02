-- English text for the unit frame modules. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- ClassColors
L.CLASSCOLORS_TITLE = "Class Colors"
L.CLASSCOLORS_DESC = "Show players' health bars and names in their class color on the player, "
    .. "target, focus, party, and target-of-target frames, and hostile and neutral NPCs' health "
    .. "bars in red and yellow."
L.CLASSCOLORS_SECTION_PARTS = "Color"
L.CLASSCOLORS_SECTION_FRAMES = "Frames"
L.CLASSCOLORS_BARS = "Health Bars"
L.CLASSCOLORS_BARS_DESC = "Color a player's health bar by their class."
L.CLASSCOLORS_NPC_BARS = "NPC Health Bars"
L.CLASSCOLORS_NPC_BARS_DESC = "Color an NPC's health bar red when it's hostile, yellow when it's "
    .. "neutral, and gray when someone else has tagged it. Friendly NPCs stay green."
L.CLASSCOLORS_NAMES = "Name Color"
L.CLASSCOLORS_NAMES_DESC = "The color of the name on these frames. Class color applies to players "
    .. "only; other names keep Blizzard's color."
L.CLASSCOLORS_NAMES_DEFAULT = "Default"
L.CLASSCOLORS_NAMES_WHITE = "White"
L.CLASSCOLORS_NAMES_CLASS = "Class Color"
L.CLASSCOLORS_NAME_BG = "Name Backgrounds"
L.CLASSCOLORS_NAME_BG_DESC = "Color the bar behind a player's name by their class instead of "
    .. "Blizzard's faction color. Target and focus frames only."
L.CLASSCOLORS_PLAYER = "Player"
L.CLASSCOLORS_PLAYER_DESC = "Your own frame."
L.CLASSCOLORS_TARGET = "Target"
L.CLASSCOLORS_TARGET_DESC = "Your target's frame."
L.CLASSCOLORS_FOCUS = "Focus"
L.CLASSCOLORS_FOCUS_DESC = "Your focus's frame."
L.CLASSCOLORS_PARTY = "Party"
L.CLASSCOLORS_PARTY_DESC = "Your party members' frames. Raid-style party frames have their own "
    .. "class color setting in Blizzard's options."
L.CLASSCOLORS_TOT = "Target of Target"
L.CLASSCOLORS_TOT_DESC = "The small frames for your target's target and your focus's target."

