-- Who a unit is to the player: in their group, on their friends list, a recent ally, in their guild,
-- and an NPC's title. Identity can be secret (mostly in instances), and a value we can't read counts
-- as "no".
local _, ns = ...

local UnitInParty, UnitInRaid, UnitGUID, UnitIsInMyGuild = UnitInParty, UnitInRaid, UnitGUID, UnitIsInMyGuild
local C_FriendList, C_BattleNet, C_TooltipInfo, type = C_FriendList, C_BattleNet, C_TooltipInfo, type
local C_RecentAllies = C_RecentAllies

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

-- Fire when the recent allies list loads or changes.
Units.RECENT_ALLY_EVENTS = { "RECENT_ALLIES_CACHE_UPDATE", "RECENT_ALLIES_DATA_READY" }

---Whether the recent allies list is on this client. Call before listening to RECENT_ALLY_EVENTS.
---@return boolean
function Units.HasRecentAllies()
    return C_RecentAllies and C_RecentAllies.IsRecentAllyByGUID and true or false
end

---Asks the server for the recent allies list if the client doesn't have it yet. Blizzard does this
---when the Recent Allies tab opens; RECENT_ALLY_EVENTS fire when it arrives.
function Units.RequestRecentAllies()
    if C_RecentAllies and C_RecentAllies.IsRecentAllyDataReady and C_RecentAllies.TryRequestRecentAlliesData
        and not C_RecentAllies.IsRecentAllyDataReady() then
        C_RecentAllies.TryRequestRecentAlliesData()
    end
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
