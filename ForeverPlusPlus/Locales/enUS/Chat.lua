-- English text for the Chat modules.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "Chat Copy"
L.CHATCOPY_DESC = "Add a button beside the chat window that opens the chat as text you can "
    .. "select and copy."
L.CHATCOPY_LINES = "Lines"
L.CHATCOPY_LINES_DESC = "How many of the latest chat lines the window shows."
L.CHATCOPY_TOOLTIP = "Copy Chat"
L.CHATCOPY_TOOLTIP_DESC = "Open the chat as text you can select and copy."
L.CHATCOPY_HIDDEN = "(hidden by the game)"
L.CHATCOPY_EMPTY = "(no chat yet)"

-- ChannelNames
L.CHANNELNAMES_TITLE = "Short Channel Names"
L.CHANNELNAMES_DESC = "Show chat channels as [1], [G], or [1. G] instead of [1. General]."
L.CHANNELNAMES_STYLE = "Style"
L.CHANNELNAMES_STYLE_DESC = "Whether a channel shows as its number, its first letter, or both."
L.CHANNELNAMES_NUMBER = "Number"
L.CHANNELNAMES_LETTER = "Letter"
L.CHANNELNAMES_BOTH = "Number and Letter"

-- ChatHistory
L.CHATHISTORY_TITLE = "Chat History"
L.CHATHISTORY_DESC = "Keep the chat windows' latest lines when you log out or reload, and "
    .. "show them again when you log in."
L.CHATHISTORY_LINES = "Lines Saved"
L.CHATHISTORY_LINES_DESC = "How many of each chat window's latest lines are kept."
L.CHATHISTORY_DIVIDER = "-- Earlier chat --"
L.CHATHISTORY_DIVIDER_OPTION = "Earlier Chat Line"
L.CHATHISTORY_DIVIDER_DESC = "Show a gray line between the restored chat and new chat."

-- SocialButton
L.SOCIALBUTTON_TITLE = "Social Button"
L.SOCIALBUTTON_DESC = "Move the social (Quick Join) button down beside the chat window's other "
    .. "buttons."

-- ChatFont
L.CHATFONT_TITLE = "Chat Font"
L.CHATFONT_DESC = "Draw the chat windows in another of the game's fonts. The size stays as you "
    .. "set it, and turning this off gives Blizzard's font back."
L.CHATFONT_FONT = "Font"
L.CHATFONT_FONT_DESC = "The font the chat windows use."
L.CHATFONT_INPUT = "Chat Input"
L.CHATFONT_INPUT_DESC = "Use the font for the text you type into the chat box too. Its size stays as it is."
L.CHATFONT_FRIZQT ="Friz Quadrata"
L.CHATFONT_ARIALN = "Arial Narrow"
L.CHATFONT_SKURRI = "Skurri"
L.CHATFONT_MORPHEUS = "Morpheus"

-- ChatFading
L.CHATFADING_TITLE = "Persistent Chat"
L.CHATFADING_DESC = "Keep chat text on screen instead of fading it out after a while. Turning "
    .. "this off gives Blizzard's fading back."
