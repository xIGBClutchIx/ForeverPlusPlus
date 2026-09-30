-- Already Known: marks items you can't learn again, such as recipes you know and mounts, pets,
-- and toys you already have, with Blizzard's green ready-check mark on the item's icon (or a
-- green tint). It shows on merchants, the auction house, bags, the inbox, and the loot window,
-- each with its own checkbox.
--
-- "Known" is what the game's own item tooltip says: its "Already known" line, or the pet
-- line's "Collected (1/3)". A pet in the auction house is asked of the pet journal by species.
-- Nothing is written onto Blizzard's frames: our own textures sit on the icons, and the icon's
-- color is put back when the mark goes.
local _, ns = ...

local _G, ipairs, type, strfind, gsub = _G, ipairs, type, strfind, gsub
local setmetatable, pairs = setmetatable, pairs
local C_Item, C_TooltipInfo, C_PetJournal, C_Container = C_Item, C_TooltipInfo, C_PetJournal, C_Container
local C_Timer, GetTime = C_Timer, GetTime

local L = ns.L

local module = ns.NewModule("AlreadyKnown", L.ALREADYKNOWN_DESC, {
    enabled = true,
    style = "check", -- "check" mark, "tint" the icon green, or "both"
    merchant = true,
    auction = true,
    bags = true,
    mail = true,
    loot = true,
})
module.title = L.ALREADYKNOWN_TITLE
module.category = "items"

module.options = {
    {
        key = "style", name = L.ALREADYKNOWN_STYLE, description = L.ALREADYKNOWN_STYLE_DESC,
        section = L.ALREADYKNOWN_SECTION_LOOK,
        choices = {
            { "check", L.ALREADYKNOWN_STYLE_CHECK },
            { "tint", L.ALREADYKNOWN_STYLE_TINT },
            { "both", L.ALREADYKNOWN_STYLE_BOTH },
        },
    },
    {
        key = "merchant", name = L.ALREADYKNOWN_MERCHANT, description = L.ALREADYKNOWN_MERCHANT_DESC,
        section = L.ALREADYKNOWN_SECTION_SHOW,
    },
    {
        key = "auction", name = L.ALREADYKNOWN_AUCTION, description = L.ALREADYKNOWN_AUCTION_DESC,
        section = L.ALREADYKNOWN_SECTION_SHOW,
    },
    {
        key = "bags", name = L.ALREADYKNOWN_BAGS, description = L.ALREADYKNOWN_BAGS_DESC,
        section = L.ALREADYKNOWN_SECTION_SHOW,
    },
    {
        key = "mail", name = L.ALREADYKNOWN_MAIL, description = L.ALREADYKNOWN_MAIL_DESC,
        section = L.ALREADYKNOWN_SECTION_SHOW,
    },
    {
        key = "loot", name = L.ALREADYKNOWN_LOOT, description = L.ALREADYKNOWN_LOOT_DESC,
        section = L.ALREADYKNOWN_SECTION_SHOW,
    },
}

local TINT = { 0.45, 1, 0.45 }
local CHECK_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready" -- Blizzard's ready check mark
local RECHECK = 10 -- seconds an item that isn't known is believed before it's looked at again
local PET_ITEM_ID = 82800 -- the stand-in item for a caged pet in the auction house

-- Is it known ---------------------------------------------------------------------------------

-- The pet line's "Collected (%d/%d)" as a pattern. Probe: the string is the client's.
local petKnown
if _G.ITEM_PET_KNOWN then
    petKnown = gsub(_G.ITEM_PET_KNOWN, "%p", "%%%0")
    petKnown = "^" .. gsub(petKnown, "%%%%d", "%%d+")
end

-- Nil while the game has no tooltip for the item yet (not cached), so that isn't taken for "no".
local function tooltipKnown(link)
    local data = C_TooltipInfo and C_TooltipInfo.GetHyperlink(link)
    local lines = data and data.lines
    if not lines or #lines == 0 then
        return nil
    end
    local alreadyKnown = _G.ITEM_SPELL_KNOWN
    for i = 1, #lines do
        local text = lines[i].leftText
        if ns.IsReadable(text) and type(text) == "string"
            and (text == alreadyKnown or (petKnown and strfind(text, petKnown))) then
            return true
        end
    end
    return false
end

local known = {} -- key -> true, once known (you don't forget a recipe)
local checked = {} -- key -> GetTime() it was last found not known

-- Whether `test(arg)` says known, remembering it so a full bag isn't looked up on every update.
-- Not known is remembered only briefly, since learning something makes it known.
local function check(key, test, arg)
    if known[key] then
        return true
    end
    local now = GetTime()
    local last = checked[key]
    if last and now - last < RECHECK then
        return false
    end
    local result = test(arg)
    if result then
        known[key] = true
        return true
    elseif result == false then
        checked[key] = now
    end
    return false
end

local function speciesKnown(speciesID)
    return C_PetJournal.GetNumCollectedInfo(speciesID) > 0
end

---Whether an item link (or "item:123") is one the player already has.
local function itemKnown(link)
    if not link then
        return false
    end
    local itemID = C_Item.GetItemInfoInstant(link)
    if not itemID then
        return false
    end
    return check(itemID, tooltipKnown, link)
end

local function petKnownBySpecies(speciesID)
    return speciesID and C_PetJournal and check("pet" .. speciesID, speciesKnown, speciesID) or false
end

-- Marks -----------------------------------------------------------------------------------------

local marks = setmetatable({}, { __mode = "k" }) -- icon texture -> { check = texture, tinted = bool }

-- Shows or clears our mark on an icon, as the Look option says. Does nothing for an icon that
-- was never marked. `size` is the mark's size, chosen per place since the icons differ.
local function setMark(icon, on, size)
    if not icon then
        return
    end
    local state = marks[icon]
    if not on and not state then
        return
    end
    if not state then
        state = {}
        marks[icon] = state
    end
    local style = module.db.style
    local tint = on and style ~= "check"
    if tint then
        icon:SetVertexColor(TINT[1], TINT[2], TINT[3])
        state.tinted = true
    elseif state.tinted then
        icon:SetVertexColor(1, 1, 1)
        state.tinted = false
    end
    if on and style ~= "tint" then
        local check = state.check
        if not check then
            check = icon:GetParent():CreateTexture(nil, "OVERLAY", nil, 7)
            check:SetTexture(CHECK_TEXTURE)
            check:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 1, 1)
            state.check = check
        end
        check:SetSize(size, size)
        check:Show()
    elseif state.check then
        state.check:Hide()
    end
end

local function clearMarks()
    for icon in pairs(marks) do
        setMark(icon, false)
    end
end

-- Merchants -------------------------------------------------------------------------------------

local function merchantIcon(i)
    local button = _G["MerchantItem" .. i .. "ItemButton"]
    return button and (button.icon or _G["MerchantItem" .. i .. "ItemButtonIconTexture"])
end

local function updateMerchant()
    local frame = _G.MerchantFrame
    if not (frame and _G.GetMerchantItemLink) then
        return
    end
    local perPage = _G.MERCHANT_ITEMS_PER_PAGE or 10
    local on = module.db.merchant
    for i = 1, perPage do
        local index = ((frame.page or 1) - 1) * perPage + i
        setMark(merchantIcon(i), on and itemKnown(_G.GetMerchantItemLink(index)), 16)
    end
end

-- The buyback tab reuses the same buttons.
local function clearMerchant()
    for i = 1, _G.MERCHANT_ITEMS_PER_PAGE or 10 do
        setMark(merchantIcon(i), false)
    end
end

-- Auction house ---------------------------------------------------------------------------------

local function browseList()
    local frame = _G.AuctionHouseFrame
    local results = frame and frame.BrowseResultsFrame
    return results and results.ItemList and results.ItemList.ScrollBox
end

local function updateAuction()
    local box = browseList()
    if not (box and box.ScrollTarget) then
        return
    end
    local on = module.db.auction
    for _, row in ipairs({ box.ScrollTarget:GetChildren() }) do
        local itemKey = row.rowData and row.rowData.itemKey
        local cell = row.cells and row.cells[2]
        if itemKey and cell and cell.Icon then
            local isKnown = false
            if on and itemKey.itemID then
                if itemKey.itemID == PET_ITEM_ID then
                    isKnown = petKnownBySpecies(itemKey.battlePetSpeciesID)
                else
                    isKnown = itemKnown("item:" .. itemKey.itemID)
                end
            end
            setMark(cell.Icon, isKnown, 12)
        end
    end
end

local function hookAuction()
    local box = browseList()
    if box and type(box.Update) == "function" then
        module:Hook(box, "Update", updateAuction)
        updateAuction()
    end
end

-- Bags ------------------------------------------------------------------------------------------

local function bagFrames()
    local list = { _G.ContainerFrameCombinedBags }
    for i = 1, _G.NUM_CONTAINER_FRAMES or 13 do
        list[#list + 1] = _G["ContainerFrame" .. i]
    end
    return list
end

local function updateBag(frame)
    if not frame.EnumerateValidItems then
        return
    end
    local on = module.db.bags
    for _, button in frame:EnumerateValidItems() do
        local bag = button.GetBagID and button:GetBagID() or button:GetParent():GetID()
        local link = on and C_Container.GetContainerItemLink(bag, button:GetID())
        setMark(button.icon or button.Icon, link and itemKnown(link), 14)
    end
end

local function hookBags()
    for _, frame in ipairs(bagFrames()) do
        if type(frame.UpdateItems) == "function" then
            module:Hook(frame, "UpdateItems", updateBag)
            if frame:IsShown() then
                updateBag(frame)
            end
        end
    end
end

-- Mail ------------------------------------------------------------------------------------------

local function mailLink(mailIndex, attachment)
    local get = _G.GetInboxItemLink or (_G.C_Mail and _G.C_Mail.GetInboxItemLink)
    return get and get(mailIndex, attachment)
end

-- Known when the mail has attachments and every one of them is.
local function mailKnown(mailIndex)
    local any = false
    for n = 1, _G.ATTACHMENTS_MAX_RECEIVE or 16 do
        local link = mailLink(mailIndex, n)
        if link then
            if not itemKnown(link) then
                return false
            end
            any = true
        end
    end
    return any
end

local function updateInbox()
    local inbox = _G.InboxFrame
    if not inbox then
        return
    end
    local perPage = _G.INBOXITEMS_TO_DISPLAY or 7
    local on = module.db.mail
    for i = 1, perPage do
        local icon = _G["MailItem" .. i .. "ButtonIcon"]
        setMark(icon, on and mailKnown(((inbox.pageNum or 1) - 1) * perPage + i), 14)
    end
end

local function updateOpenMail()
    local inbox = _G.InboxFrame
    local mailIndex = inbox and inbox.openMailID
    local on = module.db.mail and mailIndex
    for n = 1, _G.ATTACHMENTS_MAX_RECEIVE or 16 do
        local icon = _G["OpenMailAttachmentButton" .. n .. "IconTexture"]
        local link = on and mailLink(mailIndex, n)
        setMark(icon, link and itemKnown(link), 14)
    end
end

-- Loot ------------------------------------------------------------------------------------------

local lootHooked = false

local function onLootFrame(_, frame, elementData)
    if not module.enabled then
        return
    end
    local item = frame.Item
    local icon = item and (item.icon or item.Icon)
    local slot = elementData and elementData.slotIndex
    local getLink = _G.GetLootSlotLink
    local link = module.db.loot and getLink and type(slot) == "number" and getLink(slot)
    setMark(icon, link and itemKnown(link), 14)
end

-- Once: the callback can't come off, so it checks module.enabled. Probe: the scroll box and the
-- callback are Mainline's, and this is unverified on Forever.
local function hookLoot()
    local box = _G.LootFrame and _G.LootFrame.ScrollBox
    if lootHooked or not (box and _G.ScrollUtil and _G.ScrollUtil.AddAcquiredFrameCallback) then
        return
    end
    lootHooked = true
    _G.ScrollUtil.AddAcquiredFrameCallback(box, onLootFrame, module, true)
end

-- Module ----------------------------------------------------------------------------------------

local function refresh()
    local merchant = _G.MerchantFrame
    if merchant and merchant:IsShown() then
        updateMerchant()
    end
    updateAuction()
    for _, frame in ipairs(bagFrames()) do
        if frame:IsShown() then
            updateBag(frame)
        end
    end
    local mail = _G.MailFrame
    if mail and mail:IsShown() then
        updateInbox()
        updateOpenMail()
    end
end

local refreshTimer

-- Item data arrives a little after a window opens; look again once it has.
local function onItemInfo()
    if refreshTimer then
        return
    end
    refreshTimer = C_Timer.NewTimer(0.5, function()
        refreshTimer = nil
        if module.enabled then
            refresh()
        end
    end)
end

local function hookGlobal(name, fn)
    if type(_G[name]) == "function" then
        module:Hook(name, fn)
    end
end

function module:OnEnable()
    hookGlobal("MerchantFrame_UpdateMerchantInfo", updateMerchant)
    hookGlobal("MerchantFrame_UpdateBuybackInfo", clearMerchant)
    hookGlobal("InboxFrame_Update", updateInbox)
    hookGlobal("OpenMail_Update", updateOpenMail)
    hookBags()
    hookLoot()
    ns.AddOns.WhenLoaded("Blizzard_AuctionHouseUI", hookAuction)
    self:On("LOOT_OPENED", hookLoot)
    self:On("GET_ITEM_INFO_RECEIVED", onItemInfo)
    refresh()
end

function module:OnDisable()
    ns.AddOns.Cancel("Blizzard_AuctionHouseUI", hookAuction)
    if refreshTimer then
        refreshTimer:Cancel()
        refreshTimer = nil
    end
    clearMarks()
end

function module:OnOptionChanged()
    if self.enabled then
        refresh()
    end
end
