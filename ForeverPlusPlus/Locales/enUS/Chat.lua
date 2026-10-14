-- English text for the chat modules. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- ChatCopy
L.CHATCOPY_TITLE = "Chat Copy"
L.CHATCOPY_DESC = "Add a button beside the chat window that opens the chat as text you can "
    .. "select and copy."
L.CHATCOPY_TOOLTIP = "Copy Chat"
L.CHATCOPY_TOOLTIP_DESC = "Open the chat as text you can select and copy."
L.CHATCOPY_STAMPS = "Click Timestamps"
L.CHATCOPY_STAMPS_DESC = "Click a chat line's timestamp to copy that line. Needs the game's chat "
    .. "timestamps turned on."
L.CHATCOPY_STAMPS_PROMPT = "Press Ctrl+C to copy this chat line."
L.CHATCOPY_HIDDEN = "(hidden by the game)"
L.CHATCOPY_EMPTY = "(no chat yet)"

-- ShortChannelNames
L.SHORTCHANNELNAMES_TITLE = "Short Channel Names"
L.SHORTCHANNELNAMES_DESC = "Show chat channels as [1], [G], or [1. G] instead of [1. General]."
L.SHORTCHANNELNAMES_STYLE = "Style"
L.SHORTCHANNELNAMES_STYLE_DESC = "How a channel shows: its number, its first letter, its initials "
    .. "(LFG for LookingForGroup), its name without the zone, or the number with one of those."
L.SHORTCHANNELNAMES_NUMBER = "Number: [1]"
L.SHORTCHANNELNAMES_LETTER = "Letter: [G]"
L.SHORTCHANNELNAMES_INITIALS = "Initials: [LFG]"
L.SHORTCHANNELNAMES_NAME = "Name: [General]"
L.SHORTCHANNELNAMES_BOTH = "Number and Letter: [1. G]"
L.SHORTCHANNELNAMES_NUMBER_INITIALS = "Number and Initials: [1. LFG]"
L.SHORTCHANNELNAMES_NUMBER_NAME = "Number and Name: [1. General]"
L.SHORTCHANNELNAMES_CHAT_TYPES = "Guild, Party, and Raid"
L.SHORTCHANNELNAMES_CHAT_TYPES_DESC = "Also shorten [Guild], [Officer], [Party], [Raid], [Raid "
    .. "Warning], and [Instance] to [GD], [O], [P], [R], [RW], and [I], and their leaders' to [PL], "
    .. "[RL], and [IL]."
L.SHORTCHANNELNAMES_GUILD = "GD"
L.SHORTCHANNELNAMES_OFFICER = "O"
L.SHORTCHANNELNAMES_PARTY = "P"
L.SHORTCHANNELNAMES_PARTY_LEADER = "PL"
L.SHORTCHANNELNAMES_PARTY_GUIDE = "PG"
L.SHORTCHANNELNAMES_RAID = "R"
L.SHORTCHANNELNAMES_RAID_LEADER = "RL"
L.SHORTCHANNELNAMES_RAID_WARNING = "RW"
L.SHORTCHANNELNAMES_INSTANCE = "I"
L.SHORTCHANNELNAMES_INSTANCE_LEADER = "IL"

-- ChatHistory
L.CHATHISTORY_TITLE = "Chat History"
L.CHATHISTORY_DESC = "Keep the chat windows' latest lines when you log out or reload, and "
    .. "show them again when you log in. Whispers aren't kept."
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

-- PersistentChat
L.PERSISTENTCHAT_TITLE = "Persistent Chat"
L.PERSISTENTCHAT_DESC = "Keep chat text on screen instead of fading it out after a while. Turning "
    .. "this off gives Blizzard's fading back."
