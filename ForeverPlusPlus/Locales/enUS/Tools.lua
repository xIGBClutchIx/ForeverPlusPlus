-- English text for the tool pages. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- CVarBrowser
L.CVARBROWSER_TITLE = "Console Variables"
L.CVARBROWSER_DESC = "Browse the game's console variables (CVars) on a page in Settings, and "
    .. "change them."
L.CVARBROWSER_COMMAND = "open Console Variables, searching for [search]"
L.CVARBROWSER_NO_PAGE = "This client's Settings can't open the Console Variables page."
L.CVARBROWSER_AFTER_COMBAT = "%s changes after combat." -- CVar name
L.CVARBROWSER_REFUSED = "%s can't be changed." -- CVar name
L.CVARBROWSER_SEARCH = "Search console variables" -- gray text in the empty search box
L.CVARBROWSER_CHANGED = "Changed" -- the group of CVars not at their default
L.CVARBROWSER_ALL = "All"
-- The client's own CVar categories (Enum.ConsoleCategory). Default, Gm, Reveal, and None read badly
-- to players, so they get plainer names.
L.CVARBROWSER_CATEGORY_DEBUG = "Debug"
L.CVARBROWSER_CATEGORY_GRAPHICS = "Graphics"
L.CVARBROWSER_CATEGORY_CONSOLE = "Console"
L.CVARBROWSER_CATEGORY_COMBAT = "Combat"
L.CVARBROWSER_CATEGORY_GAME = "Game"
L.CVARBROWSER_CATEGORY_DEFAULT = "General" -- Default
L.CVARBROWSER_CATEGORY_NET = "Network"
L.CVARBROWSER_CATEGORY_SOUND = "Sound"
L.CVARBROWSER_CATEGORY_GM = "Game Master" -- Gm
L.CVARBROWSER_CATEGORY_REVEAL = "Revealed" -- Reveal
L.CVARBROWSER_CATEGORY_NONE = "Other" -- None
L.CVARBROWSER_NO_MATCH = "No console variables match \"%s\"." -- the search text
L.CVARBROWSER_NONE_CHANGED = "Every console variable is at its default."
L.CVARBROWSER_NO_LIST = "This client doesn't list its console variables. Search for one's full "
    .. "name to find it."
L.CVARBROWSER_DEFAULT = "Default"
L.CVARBROWSER_VALUE_IS = "Value: %s"
L.CVARBROWSER_DEFAULT_IS = "Default: %s"
L.CVARBROWSER_ACCOUNT = "Saved for your account."
L.CVARBROWSER_CHARACTER = "Saved for this character."
L.CVARBROWSER_READ_ONLY = "Can't be changed."
L.CVARBROWSER_SECURE = "Protected: changes wait until combat ends."

-- SelfTest
L.SELFTEST_TITLE = "Self Test"
L.SELFTEST_DESC = "Probe the client APIs Forever++ depends on and save what they do, for debugging."
L.SELFTEST_COMMAND = "run the self test, then /reload to save its log"
L.SELFTEST_BUTTON = "Run"
L.SELFTEST_BUTTON_DESC = "Probe the client APIs Forever++ relies on, then record flights, deaths and "
    .. "other events until you /reload. The results are saved to Forever++'s SavedVariables file."
L.SELFTEST_DONE = "Self test wrote %d lines. Type /reload to save them." -- number of lines
