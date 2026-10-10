-- Slash commands a module adds and takes away live, like /way and /rl. A command is the
-- SLASH_<key>1 global and SlashCmdList[key]. A slash another addon already answers to (TomTom's
-- /way) is left to that addon. Chat caches a command's function the first time it's typed
-- (hash_SlashCmdList), so taking one away clears that too, like AceConsole does.
local _, ns = ...

local pairs, type, _G = pairs, type, _G

local Slash = {}
ns.Slash = Slash

local added = {} -- key -> true while our command is registered

-- Whether a command other than `key` already answers to `slash`.
local function taken(slash, key)
    slash = slash:upper()
    for name in pairs(SlashCmdList) do
        if name ~= key then
            local i = 1
            local text = _G["SLASH_" .. name .. i]
            while text do
                if type(text) == "string" and text:upper() == slash then
                    return true
                end
                i = i + 1
                text = _G["SLASH_" .. name .. i]
            end
        end
    end
    return false
end

---Adds `slash` as command `key`, unless another addon already has that slash.
---@param key string the SlashCmdList key, FOREVERPLUSPLUS_<NAME>
---@param slash string like "/way"
---@param fn fun(message: string, editBox: table?)
function Slash.Add(key, slash, fn)
    if added[key] or taken(slash, key) then
        return
    end
    _G["SLASH_" .. key .. "1"] = slash
    SlashCmdList[key] = fn
    added[key] = true
end

---Takes away command `key`, if we added it.
---@param key string
---@param slash string
function Slash.Remove(key, slash)
    if not added[key] then
        return
    end
    SlashCmdList[key] = nil
    _G["SLASH_" .. key .. "1"] = nil
    -- Probe: Mainline keeps the cache in this global; without it there's nothing cached to clear.
    local hash = _G.hash_SlashCmdList
    if type(hash) == "table" then
        hash[slash:upper()] = nil
    end
    added[key] = nil
end
