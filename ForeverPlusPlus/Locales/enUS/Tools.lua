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

-- Profiler
L.PROFILER_TITLE = "Profiler"
L.PROFILER_DESC = "See how much CPU each module takes, on a page in Settings, to find what's slow."
L.PROFILER_COMMAND = "open the Profiler page"
L.PROFILER_NO_PAGE = "This client's Settings can't open the Profiler page."
L.PROFILER_RECORD = "Record"
L.PROFILER_STOP = "Stop"
L.PROFILER_RESET = "Clear"
L.PROFILER_IDLE = "Press Record and play as usual. The modules that take the most CPU rise to the top."
L.PROFILER_RECORDING = "Recording for %s." -- time, such as 1:23
L.PROFILER_STOPPED = "Recorded %s." -- time, such as 1:23
L.PROFILER_ADDON_CPU = "All of Forever++: %.3f ms a frame lately, %.1f ms at most." -- ms, ms
L.PROFILER_ADDON_MEMORY = "Memory: %.1f MB." -- megabytes
L.PROFILER_MODULE = "Module"
L.PROFILER_PER_SECOND = "ms a second"
L.PROFILER_PEAK = "Worst frame (ms)"
L.PROFILER_CALLS = "Calls a second"
L.PROFILER_SHARED = "Shared code" -- time in Forever++'s libraries not traced to one module
L.PROFILER_OWN = "everything else" -- under a module's parts: its time outside them
L.PROFILER_EMPTY = "Nothing recorded yet."
L.PROFILER_COUNTED = "Counted, not timed: a stopwatch around each of thousands a second would cost "
    .. "more than the call." -- a part's tooltip on the Profiler page
L.PROFILER_NOTE = "Only Forever++'s own code is timed, and timing it adds a little cost of its own "
    .. "while recording. Memory can only be read for the whole addon, not for each module."
