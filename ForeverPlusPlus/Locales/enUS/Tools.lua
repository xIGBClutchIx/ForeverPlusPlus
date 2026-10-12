-- English text for the tool pages. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- ConsoleVariables
L.CONSOLEVARIABLES_TITLE = "Console Variables"
L.CONSOLEVARIABLES_DESC = "Browse the game's console variables (CVars) on a page in Settings, and "
    .. "change them."
L.CONSOLEVARIABLES_COMMAND = "open Console Variables, searching for [search]"
L.CONSOLEVARIABLES_NO_PAGE = "This client's Settings can't open the Console Variables page."
L.CONSOLEVARIABLES_AFTER_COMBAT = "%s changes after combat." -- CVar name
L.CONSOLEVARIABLES_REFUSED = "%s can't be changed." -- CVar name
L.CONSOLEVARIABLES_SEARCH = "Search console variables" -- gray text in the empty search box
L.CONSOLEVARIABLES_CHANGED = "Changed" -- the group of CVars not at their default
L.CONSOLEVARIABLES_ALL = "All"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CONSOLEVARIABLES_CATEGORY_DEBUG = "Debug"
L.CONSOLEVARIABLES_CATEGORY_GRAPHICS = "Graphics"
L.CONSOLEVARIABLES_CATEGORY_CONSOLE = "Console"
L.CONSOLEVARIABLES_CATEGORY_COMBAT = "Combat"
L.CONSOLEVARIABLES_CATEGORY_GAME = "Game"
L.CONSOLEVARIABLES_CATEGORY_DEFAULT = "General" -- Default
L.CONSOLEVARIABLES_CATEGORY_NET = "Network"
L.CONSOLEVARIABLES_CATEGORY_SOUND = "Sound"
L.CONSOLEVARIABLES_CATEGORY_GM = "Game Master" -- Gm
L.CONSOLEVARIABLES_CATEGORY_REVEAL = "Revealed" -- Reveal
L.CONSOLEVARIABLES_CATEGORY_NONE = "Other" -- None
L.CONSOLEVARIABLES_NO_MATCH = "No console variables match \"%s\"." -- the search text
L.CONSOLEVARIABLES_NONE_CHANGED = "Every console variable is at its default."
L.CONSOLEVARIABLES_NO_LIST = "This client doesn't list its console variables. Search for one's full "
    .. "name to find it."
L.CONSOLEVARIABLES_DEFAULT = "Default"
L.CONSOLEVARIABLES_VALUE_IS = "Value: %s"
L.CONSOLEVARIABLES_DEFAULT_IS = "Default: %s"
L.CONSOLEVARIABLES_ACCOUNT = "Saved for your account."
L.CONSOLEVARIABLES_CHARACTER = "Saved for this character."
L.CONSOLEVARIABLES_READ_ONLY = "Can't be changed."
L.CONSOLEVARIABLES_SECURE = "Protected: changes wait until combat ends."

-- SelfTest
L.SELFTEST_TITLE = "Self Test"
L.SELFTEST_DESC = "Probe the client APIs Forever++ depends on and save what they do, for debugging."
L.SELFTEST_COMMAND = "run the self test, then /reload to save its log"
L.SELFTEST_BUTTON = "Run"
L.SELFTEST_BUTTON_DESC = "Probe the client APIs Forever++ relies on, then record flights, deaths and "
    .. "other events until you /reload. The results are saved to Forever++'s SavedVariables file."
L.SELFTEST_DONE = "Self test wrote %d lines. Type /reload to save them." -- number of lines
