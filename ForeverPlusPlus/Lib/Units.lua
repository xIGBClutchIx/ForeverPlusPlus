-- Who a unit is to the player: in their group, on their friends list, in their guild. Identity can
-- be secret (mostly in instances), and a value we can't read counts as "no".
local _, ns = ...

local UnitInParty, UnitInRaid, UnitGUID, UnitIsInMyGuild = UnitInParty, UnitInRaid, UnitGUID, UnitIsInMyGuild
local C_FriendList, C_BattleNet = C_FriendList, C_BattleNet

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

---Whether the unit is in the player's guild.
---@param unit string
---@return boolean
function Units.IsGuildmate(unit)
    local mate = UnitIsInMyGuild and UnitIsInMyGuild(unit)
    return readable(mate) and mate or false
end
