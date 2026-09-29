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
L.CVARBROWSER_COUNT = "%d of %d" -- shown, total
L.CVARBROWSER_CHANGED_ONLY = "Changed Only"
L.CVARBROWSER_NAME = "Name"
L.CVARBROWSER_VALUE = "Value"
L.CVARBROWSER_DEFAULT = "Default"
L.CVARBROWSER_VALUE_IS = "Value: %s"
L.CVARBROWSER_DEFAULT_IS = "Default: %s"
L.CVARBROWSER_ACCOUNT = "Saved for your account."
L.CVARBROWSER_CHARACTER = "Saved for this character."
L.CVARBROWSER_READ_ONLY = "Can't be changed."
L.CVARBROWSER_SECURE = "Protected: changes wait until combat ends."
