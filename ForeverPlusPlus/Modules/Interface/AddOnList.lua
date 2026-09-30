-- AddOns List: a plainer AddOns list on the character screen and the game menu. Blizzard's list
-- sorts addons under category headers; this builds the same kind of rows without the headers,
-- with addons you have enabled first and the disabled ones after, each group in name order. It
-- changes only which rows the list's scroll box shows, so the rows, the checkboxes, and the
-- Enable All / Disable All buttons are still Blizzard's. Turning it off gives Blizzard's own list
-- back at once.
local _, ns = ...

local _G, ipairs, type, pcall, sort, lower, gsub, find, format, tostring =
    _G, ipairs, type, pcall, table.sort, string.lower, string.gsub, string.find, string.format, tostring
local C_AddOns, UnitName, CreateTreeDataProvider, geterrorhandler =
    C_AddOns, UnitName, CreateTreeDataProvider, geterrorhandler

local L = ns.L

local module = ns.NewModule("AddOnList", L.ADDONLIST_DESC, {
    enabled = false,
    enabledFirst = true, -- enabled addons above the disabled ones
    ungroup = false, -- disabled addons leave their group and sit with the other disabled ones
    notes = true, -- the search box also looks in an addon's notes
})
module.title = L.ADDONLIST_TITLE
module.category = "interface"

module.options = {
    { key = "enabledFirst", name = L.ADDONLIST_ENABLEDFIRST, description = L.ADDONLIST_ENABLEDFIRST_DESC },
    { key = "ungroup", name = L.ADDONLIST_UNGROUP, description = L.ADDONLIST_UNGROUP_DESC },
    { key = "notes", name = L.ADDONLIST_NOTES, description = L.ADDONLIST_NOTES_DESC },
}

-- Blizzard_AddOnList makes AddonList with a ScrollBox of tree rows (each row's data is
-- `{ addonIndex = n }`) and a SearchBox, and runs AddonList_Update to fill it. Read from the
-- Mainline UI this client is built on; the row shape is Unverified here, so every piece is probed.
local ADDON = "Blizzard_AddOnList"

local busy = false
local rebuilds = 0 -- for /fpp addons

local function plain(text)
    local stripped = gsub(text or "", "|c%x%x%x%x%x%x%x%x", "")
    stripped = gsub(stripped, "|r", "")
    return lower(stripped)
end

local function addList()
    local list = _G.AddonList
    if type(list) == "table" and list.ScrollBox and list.SearchBox and list.ScrollBox.SetDataProvider then
        return list
    end
end

---Everything the list needs to know about one addon, read once per rebuild.
local function readAddOn(index, character)
    local name, title, notes, _, infoReason = C_AddOns.GetAddOnInfo(index)
    local group = C_AddOns.GetAddOnMetadata(index, "Group")
    local state = C_AddOns.GetAddOnEnableState(index, character)
    local _, reason = C_AddOns.IsAddOnLoadable(index, character)
    local none = Enum and Enum.AddOnEnableState and Enum.AddOnEnableState.None or 0
    -- The enable state for the player's name came back "on" for addons the list shows as
    -- Disabled (Forever, 2026-09-30), so the load reasons count too.
    return {
        index = index,
        name = name,
        group = group,
        key = plain(title ~= "" and title or name),
        text = plain(title or name),
        notes = plain(notes),
        -- A dependency that's switched off counts as disabled, like its own checkbox would.
        disabled = state <= none or reason == "DISABLED" or reason == "DEP_DISABLED"
            or infoReason == "DISABLED" or infoReason == "DEP_DISABLED",
    }
end

local function byKey(a, b)
    if a.key ~= b.key then
        return a.key < b.key
    end
    return a.index < b.index
end

local function matches(info, filter, withNotes)
    if filter == "" then
        return true
    end
    if find(info.text, filter, 1, true) or find(plain(info.name), filter, 1, true) then
        return true
    end
    if info.group and find(plain(info.group), filter, 1, true) then
        return true
    end
    return withNotes and find(info.notes, filter, 1, true) ~= nil
end

-- Builds the tree: a row for each group's parent with its addons under it, enabled groups first
-- when asked, no category rows.
local function build(list)
    local db = module.db
    local character = (UnitName("player"))
    local filter = plain(list.SearchBox:GetText())

    local infos, byName = {}, {}
    for index = 1, C_AddOns.GetNumAddOns() do
        local info = readAddOn(index, character)
        infos[#infos + 1] = info
        byName[info.name] = info
    end

    -- A group is its parent's name in the "Group" metadata; an addon whose parent isn't installed
    -- stands alone.
    local roots, children = {}, {}
    for _, info in ipairs(infos) do
        local parent = info.group and info.group ~= info.name and byName[info.group]
        if parent and not (db.ungroup and info.disabled) then
            children[parent] = children[parent] or {}
            children[parent][#children[parent] + 1] = info
        else
            roots[#roots + 1] = info
        end
    end

    local shown, hidden = {}, {}
    for _, root in ipairs(roots) do
        local kids = children[root]
        local rootMatch = matches(root, filter, db.notes)
        local keep
        if kids then
            keep = {}
            for _, kid in ipairs(kids) do
                if rootMatch or matches(kid, filter, db.notes) then
                    keep[#keep + 1] = kid
                end
            end
            sort(keep, byKey)
        end
        if rootMatch or (keep and #keep > 0) then
            root.keep = keep
            local bucket = db.enabledFirst and root.disabled and hidden or shown
            bucket[#bucket + 1] = root
        end
    end
    sort(shown, byKey)
    sort(hidden, byKey)

    local provider = CreateTreeDataProvider()
    local function insert(root)
        local node = provider:Insert({ addonIndex = root.index })
        if root.keep then
            for _, kid in ipairs(root.keep) do
                node:Insert({ addonIndex = kid.index })
            end
        end
    end
    for _, root in ipairs(shown) do
        insert(root)
    end
    for _, root in ipairs(hidden) do
        insert(root)
    end
    return provider
end

local function rebuild()
    local list = addList()
    if busy or not list or not list:IsShown() or not (C_AddOns and CreateTreeDataProvider) then
        return
    end
    busy = true
    local ok, provider = pcall(build, list)
    rebuilds = rebuilds + 1
    if ok then
        list.ScrollBox:SetDataProvider(provider, ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
    else
        -- Leave Blizzard's list as it is rather than show half of ours, and report the error.
        geterrorhandler()(provider)
    end
    busy = false
end

local pending = false

local function later()
    pending = false
    if module.enabled then
        rebuild()
    end
end

-- Rebuilds now, and once more next frame in case Blizzard fills the list again after its own
-- hooks ran (it does when the window opens), which would put its order back.
local function refresh()
    rebuild()
    if not pending and C_Timer then
        pending = true
        C_Timer.After(0, later)
    end
end

local function start()
    local list = addList()
    if not list then
        return
    end
    module:Hook("AddonList_Update", refresh)
    module:HookScript(list.SearchBox, "OnTextChanged", refresh)
    module:HookScript(list, "OnShow", refresh)
    refresh()
end

function module:OnEnable()
    if addList() then
        start()
    else
        ns.AddOns.WhenLoaded(ADDON, start)
    end
end

function module:OnDisable()
    ns.AddOns.Cancel(ADDON, start)
    -- Blizzard's own update puts its categories back.
    if addList() and type(_G.AddonList_Update) == "function" then
        _G.AddonList_Update()
    end
end

function module:OnOptionChanged()
    if self.enabled then
        rebuild()
    end
end

-- Reports what the module sees, to check it against what the list shows.
ns.AddCommand("addons", "", L.ADDONLIST_COMMAND, function()
    local character = (UnitName("player"))
    local total, off, first = 0, 0, "-"
    for index = 1, C_AddOns.GetNumAddOns() do
        local info = readAddOn(index, character)
        total = total + 1
        if info.disabled then
            off = off + 1
            if first == "-" then
                first = info.name
            end
        end
    end
    ns.Print(format(L.ADDONLIST_REPORT, tostring(addList() ~= nil), rebuilds, off, total, first))
end)
