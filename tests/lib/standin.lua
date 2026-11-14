-- The whole addon loaded offline, for a spec that needs every file and not only the pure-logic
-- Lib files: a stand-in for every WoW global the code reads that isn't stubbed, so each file's top
-- level runs without the client, and every file in the TOC loaded against it into a new `ns`.
-- Only loading is safe this way. Nothing here starts the addon or turns a module on: a spec calls
-- the functions it's testing itself, with the globals they use stubbed first.
local Standin = {}

-- The stand-in itself: calling it, indexing it, or calling a method on it gives it back.
local stub
local meta = {
    __index = function() return stub end,
    __call = function() return stub end,
    __concat = function(a, b)
        return (a == stub and "" or tostring(a)) .. (b == stub and "" or tostring(b))
    end,
    __tostring = function() return "<stub>" end,
}
for _, op in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm" }) do
    meta[op] = function() return 0 end
end
stub = setmetatable({}, meta)
Standin.stub = stub

-- Blizzard's colors (NORMAL_FONT_COLOR and the like): a ColorMixin's RGB and its fields.
local function color()
    local c = { r = 1, g = 0.82, b = 0, a = 1 }
    function c.GetRGB() return c.r, c.g, c.b end
    function c.GetRGBA() return c.r, c.g, c.b, c.a end
    function c.GenerateHexColor() return "ffffd100" end
    function c.WrapTextInColorCode(_, s) return s end
    return c
end

---A set of globals for the addon's files to load in: what `base` has, Blizzard's string and table
---helpers, the few functions whose answers files branch on, and the stand-in for the rest.
---@param base table the globals to fall back on (a spec's own, or Lua's)
---@return table env
function Standin.Env(base)
    local env = {}
    setmetatable(env, { __index = function(self, key)
        local value = base[key]
        if value ~= nil then
            return value
        end
        -- Blizzard's colors are ColorMixins, and its other all-caps globals are its strings.
        if type(key) == "string" and key:match("_COLOR$") then
            value = color()
        elseif type(key) == "string" and key:match("^[%u%d_]+$") and key:match("%u") then
            value = key
        else
            return stub
        end
        rawset(self, key, value)
        return value
    end })
    env._G = env

    env.format, env.strlower, env.strupper = string.format, string.lower, string.upper
    env.strsub, env.strfind, env.strmatch, env.strlen, env.strrep = string.sub, string.find, string.match,
        string.len, string.rep
    env.gsub, env.strbyte, env.strchar = string.gsub, string.byte, string.char
    env.tinsert, env.tremove, env.tconcat, env.sort = table.insert, table.remove, table.concat, table.sort
    env.floor, env.ceil, env.abs, env.max, env.min, env.mod = math.floor, math.ceil, math.abs, math.max,
        math.min, math.fmod
    env.wipe = function(t)
        for key in pairs(t) do
            t[key] = nil
        end
        return t
    end
    env.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
    env.strsplit = function(sep, s)
        local parts = {}
        for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do
            parts[#parts + 1] = piece
        end
        return unpack(parts)
    end
    env.Mixin = function(object, ...)
        for i = 1, select("#", ...) do
            for key, value in pairs((select(i, ...))) do
                object[key] = value
            end
        end
        return object
    end
    env.CreateFromMixins = function(...) return env.Mixin({}, ...) end
    env.CopyTable = function(t)
        local copy = {}
        for key, value in pairs(t) do
            copy[key] = type(value) == "table" and env.CopyTable(value) or value
        end
        return copy
    end
    env.GetLocale = function() return "enUS" end
    env.GetBuildInfo = function() return "1.60.1", "70790", "Nov 4 2026", 16001 end
    env.issecretvalue = function() return false end
    env.GetMoneyString = function(copper) return copper .. "c" end
    env.InCombatLockdown = function() return false end
    env.hooksecurefunc = function() end
    env.securecallfunction = function(fn, ...) return fn(...) end
    env.ForeverPlusPlusDB, env.ForeverPlusPlusPlayersDB, env.ForeverPlusPlusCharDB = nil, nil, nil
    return env
end

---Loads every file the TOC lists but Init.lua (which starts the addon at login) into a new `ns`.
---`before(env, stub)` runs first, to set the globals a spec's own checks need: files keep many of
---them at load, so they must be there by then.
---@param base table the globals to fall back on
---@param root string the addon's folder, with its slash
---@param addon string the addon's name, each file's first argument
---@param files string[] the TOC's files, in order
---@param before? fun(env: table, stub: table)
---@param around? fun(path: string, ns: table, loaded: boolean?) before each file (`loaded` nil) and after it
---@return table ns
---@return table env
---@return string[] broken a line for each file that didn't load
function Standin.Load(base, root, addon, files, before, around)
    local env = Standin.Env(base)
    if before then
        before(env, stub)
    end
    local ns, broken = {}, {}
    for _, path in ipairs(files) do
        if path ~= "Init.lua" then
            local chunk, err = loadfile(root .. path)
            local fine = chunk ~= nil
            if chunk then
                setfenv(chunk, env)
                if around then
                    around(path, ns)
                end
                fine, err = pcall(chunk, addon, ns)
                if around then
                    around(path, ns, fine)
                end
            end
            if not fine then
                broken[#broken + 1] = path .. ": " .. tostring(err)
            end
        end
    end
    return ns, env, broken
end

return Standin
