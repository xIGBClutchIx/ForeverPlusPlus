-- Who a unit is to the player: in their group, on their friends list, a recent ally, in their guild,
-- and an NPC's title. Friends and guildmates can also be checked by name. Identity can be secret (mostly in instances), and a value we can't read counts
-- as "no".
local _, ns = ...

local UnitInParty, UnitInRaid, UnitGUID, UnitIsInMyGuild = UnitInParty, UnitInRaid, UnitGUID, UnitIsInMyGuild
local C_FriendList, C_BattleNet, C_TooltipInfo, type = C_FriendList, C_BattleNet, C_TooltipInfo, type
local C_RecentAllies, C_GuildInfo, IsInGuild = C_RecentAllies, C_GuildInfo, IsInGuild
local BNGetNumFriends, GetNumGuildMembers, GetGuildRosterInfo = BNGetNumFriends, GetNumGuildMembers, GetGuildRosterInfo

local readable = ns.IsReadable

local Units = {}
ns.Units = Units

---Whether the unit is in the player's party or raid.
---@param unit string
---@return boolean
function Units.InGroup(unit)
    local party, raid = UnitInParty(unit), UnitInRaid(unit)
    return (readable(party) and party) or (readable(raid) and raid ~= nil) or false
end

---Whether the unit is on the player's friends list or a Battle.net friend.
---@param unit string
---@return boolean
function Units.IsFriend(unit)
    local guid = UnitGUID(unit)
    if not (readable(guid) and guid) then
        return false
    end
    if C_FriendList and C_FriendList.IsFriend and C_FriendList.IsFriend(guid) then
        return true
    end
    return C_BattleNet and C_BattleNet.GetAccountInfoByGUID
        and C_BattleNet.GetAccountInfoByGUID(guid) ~= nil or false
end

-- Fire when the recent allies list loads or changes. We can't ask for the list ourselves:
-- TryRequestRecentAlliesData is protected on Forever, so we use whatever the client has loaded
-- (it loads when the Recent Allies tab opens) and recolor when these fire.
Units.RECENT_ALLY_EVENTS = { "RECENT_ALLIES_CACHE_UPDATE", "RECENT_ALLIES_DATA_READY" }

---Whether the recent allies list is on this client. Call before listening to RECENT_ALLY_EVENTS.
---@return boolean
function Units.HasRecentAllies()
    return C_RecentAllies and C_RecentAllies.IsRecentAllyByGUID and true or false
end

---Whether the unit is on the player's Recent Allies list (players they've recently grouped or
---played with), which the game shows in light blue (ns.Colors.RECENT_ALLY).
---@param unit string
---@return boolean
function Units.IsRecentAlly(unit)
    if not Units.HasRecentAllies() then
        return false
    end
    local guid = UnitGUID(unit)
    if not (readable(guid) and guid) then
        return false
    end
    local ally = C_RecentAllies.IsRecentAllyByGUID(guid)
    return readable(ally) and ally or false
end

---Whether the unit is in the player's guild.
---@param unit string
---@return boolean
function Units.IsGuildmate(unit)
    local mate = UnitIsInMyGuild and UnitIsInMyGuild(unit)
    return readable(mate) and mate or false
end

-- By name, for events that give a player's name but no unit (a duel or group invite). Names are
-- compared without any "-Realm" part, and lowercased.
local function bare(name)
    if not (readable(name) and type(name) == "string") then
        return nil
    end
    return (name:match("^([^%-]+)") or name):lower()
end

---Whether a player by this name is on the player's friends list or an online Battle.net friend.
---@param name string
---@return boolean
function Units.IsFriendName(name)
    local want = bare(name)
    if not want then
        return false
    end
    if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and bare(info.name) == want then
                return true
            end
        end
    end
    if BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
        for i = 1, (BNGetNumFriends()) do
            local info = C_BattleNet.GetFriendAccountInfo(i)
            local game = info and info.gameAccountInfo
            if game and bare(game.characterName) == want then
                return true
            end
        end
    end
    return false
end

---Asks the server for the guild roster, so IsGuildmateName has names to check.
function Units.RequestGuildRoster()
    if IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    end
end

---Whether a player by this name is in the player's guild, from the roster the client has.
---@param name string
---@return boolean
function Units.IsGuildmateName(name)
    local want = bare(name)
    if not (want and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then
        return false
    end
    for i = 1, (GetNumGuildMembers()) do
        if bare((GetGuildRosterInfo(i))) == want then
            return true
        end
    end
    return false
end

---An NPC's title ("Innkeeper", "Weapon Merchant"), without brackets, or nil. It's the tooltip's
---second line; NPCs without a title have their level there instead ("Level 30 Humanoid"), which
---is told apart by its number (or "??").
---@param unit string
---@return string?
function Units.Title(unit)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then
        return nil
    end
    local data = C_TooltipInfo.GetUnit(unit)
    local line = data and data.lines and data.lines[2]
    local text = line and line.leftText
    if not (readable(text) and type(text) == "string") then
        return nil
    end
    text = text:gsub("^<", ""):gsub(">$", "")
    if text == "" or text:find("%d") or text:find("%?%?") then
        return nil
    end
    return text
end
