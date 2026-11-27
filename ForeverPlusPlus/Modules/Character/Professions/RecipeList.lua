-- Professions' recipe list: the one place that gives Blizzard's recipe list a tree of our own, for
-- the parts that change what it holds or its order. Unlearned Recipes adds the recipes not known yet
-- (`List.adder`); Crafting Costs' Sort Recipe List orders each category's recipes by profit or cost
-- (`List.order`). Either works alone, and both at once build one tree.
--
-- How: Blizzard's list code already draws, sorts, collapses, and selects whatever its tree holds
-- (Professions.GenerateCraftingDataProvider, Blizzard_ProfessionsTemplates). After Blizzard sets the
-- list's data provider, this builds a tree of its own in Blizzard's node shapes, whole and off
-- screen, and gives it to the list once: a tree data provider makes the scroll box watching it
-- update in full after every insert, so adding to the tree the list watches would redraw it for
-- each of hundreds of rows. Blizzard's tree is only read, never changed, and goes back to the list
-- when nothing of ours applies.
local _, ns = ...

local _G, ipairs, pairs, type = _G, ipairs, pairs, type
local C_TradeSkillUI = C_TradeSkillUI

local Professions = ns.Professions -- ours; Blizzard's global of the same name is _G.Professions

local professions = ns.modules.Professions
local internal = professions.internal

local List = {
    -- Set by Unlearned Recipes: { wants = fn(): bool, add = fn(has): spec|nil, clear = fn() }.
    -- `add` gets what Blizzard's tree holds (see read) and returns nil to add nothing, or
    -- `{ learned = keep Blizzard's learned recipes, recipes = infos to add, searching = bool }`.
    -- `clear` is called whenever a build adds nothing of its.
    adder = nil,
    -- Set by Crafting Costs: fn() -> a comparator of recipe infos (Professions.RecipeOrder), or nil
    -- for Blizzard's order.
    order = nil,
}
internal.RecipeList = List

-- Blizzard's groups for the list's top nodes (the local Group enum in Blizzard_Professions.lua:
-- Favorite, Learned, UnlearnedDivider, Unlearned).
local GROUP_FAVORITE, GROUP_LEARNED = 1, 2
List.GROUP_LEARNED = GROUP_LEARNED

local function craftingPage()
    local frame = _G.ProfessionsFrame
    return frame and frame.CraftingPage
end
List.Page = craftingPage

local function recipeList()
    local page = craftingPage()
    return page and page.RecipeList
end

---Whether the open list is one of the player's own professions: not a guild's, an NPC's, a link,
---or runeforging. Probe: each call is Mainline's.
---@return boolean
function List.OwnList()
    local T = C_TradeSkillUI
    if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo and internal.ListHasSkillUps()) then
        return false
    end
    if T.IsTradeSkillLinked and T.IsTradeSkillLinked() then
        return false
    end
    return not (T.IsTradeSkillGuildMember and T.IsTradeSkillGuildMember())
end

local theirs -- the provider Blizzard last gave the list, which stays as Blizzard built it
local ours -- the provider we gave the list in its place, or nil while the list has Blizzard's
local swapping -- true while we set ours, so our own hook leaves it alone
local categories = {} -- category ID -> Blizzard's own info for it, from the tree it built

-- A category's info for a tree of ours: Blizzard's own where its tree has the category, so its
-- header is the same one, and otherwise our own copy in the Learned group, drawn like any other.
local function categoryOf(id)
    if categories[id] then
        return categories[id]
    end
    local T = C_TradeSkillUI
    local info = T.GetCategoryInfo and T.GetCategoryInfo(id)
    if type(info) ~= "table" then
        return nil
    end
    local own = {}
    for key, value in pairs(info) do
        own[key] = value
    end
    own.group, own.unlearned = GROUP_LEARNED, false
    if type(own.uiOrder) ~= "number" then
        own.uiOrder = 0
    end
    return own
end

local function recipeOf(node)
    local data = node:GetData()
    return data and data.recipeInfo
end

-- A node of Blizzard's tree and what's under it, again in ours, with the same data: its recipes
-- in `order` when there is one, everything else where it was.
local function copyNode(parent, source, order)
    local node = parent:Insert(source:GetData())
    if source:IsCollapsed() then
        node:SetCollapsed(true, false, true)
    end
    local children = source:GetNodes()
    if order then
        children = Professions.OrderAmong(children, recipeOf, order)
    end
    for _, child in ipairs(children) do
        copyNode(node, child, order)
    end
end

-- Our nodes for one category, in Blizzard's shapes (AttachTreeDataRecursive): its subcategories,
-- then its recipes between a top and a bottom padding. In the order they're given: our tree has
-- no sort comparators, since Professions.RecipeTree already put them in order.
local function attach(parent, branch, collapses)
    local info = branch.info
    local node = parent:Insert({ categoryInfo = info, group = GROUP_LEARNED })
    if collapses and collapses[info.categoryID] then
        node:SetCollapsed(true, false, true)
    end
    for _, child in ipairs(branch.categories) do
        attach(node, child, collapses)
    end
    if #branch.recipes > 0 then
        node:Insert({ topPadding = true, order = -1 })
        for _, recipe in ipairs(branch.recipes) do
            node:Insert({ recipeInfo = recipe, order = 0 })
        end
        node:Insert({ bottomPadding = true, order = 1 })
    end
end

-- What Blizzard's tree holds, read without changing it: its Favorites nodes, its learned recipes'
-- infos with their IDs and names (the game's data has some recipes twice, one learned), and its
-- categories' infos. Nil when it lists unlearned recipes itself: then nothing is added to it.
local function read(provider)
    local favorites, learned, ids, names = {}, {}, {}, {}
    categories = {}
    local function walk(node)
        local data = node:GetData()
        local category, info = data and data.categoryInfo, data and data.recipeInfo
        if category and category.categoryID then
            categories[category.categoryID] = category
        end
        if info then
            if not info.learned then
                return false
            end
            learned[#learned + 1] = info
            ids[info.recipeID] = true
            if type(info.name) == "string" then
                names[info.name] = true
            end
        end
        for _, child in ipairs(node:GetNodes()) do
            if walk(child) == false then
                return false
            end
        end
    end
    for _, top in ipairs(provider:GetRootNode():GetNodes()) do
        local data = top:GetData()
        if data and data.group == GROUP_FAVORITE then
            favorites[#favorites + 1] = top
        elseif walk(top) == false then
            return nil
        end
    end
    return { favorites = favorites, learned = learned, ids = ids, names = names }
end

-- Blizzard's "no results" text follows its own tree, which ours may differ from either way: it
-- goes by whichever tree the list has now (theirs again after ours was empty, too).
local function noResults()
    local list = recipeList()
    local provider = ours or theirs
    if provider and list and list.NoResultsText then
        list.NoResultsText:SetShown(provider:IsEmpty())
    end
end

-- Gives the list `provider` (ours, or Blizzard's back) without our hook taking it for Blizzard's.
local function give(box, provider, retain)
    swapping = true
    box:SetDataProvider(provider, retain)
    swapping = false
end

-- The list as the parts ask for it: Blizzard's own while nothing of ours applies; a copy of
-- Blizzard's tree with each category's recipes in our order while only a sort does; and a tree
-- built from its learned recipes and the added ones while Unlearned Recipes adds some.
local function build(box, retain)
    local was = ours
    ours = nil
    local own = theirs and List.OwnList()
    local order = own and List.order and List.order() or nil
    local adder = List.adder
    local spec, has
    if own and adder and adder.wants() then
        has = read(theirs)
        spec = has and adder.add(has)
    end
    if adder and not spec then
        adder.clear()
    end
    if not (own and (spec or order)) then
        if was and theirs and box:GetDataProvider() == was then
            give(box, theirs, retain) -- back to Blizzard's
            noResults()
        end
        return
    end
    local provider = CreateTreeDataProvider()
    local root = provider:GetRootNode()
    if spec then
        local recipes = {}
        if spec.learned then
            for i, info in ipairs(has.learned) do
                recipes[i] = info
            end
            for _, favorite in ipairs(has.favorites) do
                copyNode(root, favorite, order)
            end
        end
        for _, info in ipairs(spec.recipes) do
            recipes[#recipes + 1] = info
        end
        local page = craftingPage()
        local collapses = page.GetCollapses and page:GetCollapses()
        -- Not searching, Blizzard leaves out categories without recipes of their own; searching it
        -- keeps them (discardRootCategories).
        for _, branch in ipairs(Professions.RecipeTree(recipes, categoryOf, spec.searching, order)) do
            attach(root, branch, collapses)
        end
    else
        for _, top in ipairs(theirs:GetRootNode():GetNodes()) do
            copyNode(root, top, order)
        end
    end
    ours = provider
    give(box, provider, retain)
    noResults()
end

-- After Blizzard sets the list's data provider (ProfessionsCraftingPageMixin:Init, and a rebuild).
local function onSetDataProvider(box, provider, retain)
    if swapping or not provider then
        return
    end
    if provider == ours then
        return -- ours set again (ScrollBox:Rebuild)
    end
    theirs = provider
    build(box, retain)
end

---Builds the list again from Blizzard's last tree, after a part's filter, sort, or option changed,
---or the part turned on or off (with nothing of ours left, the list gets Blizzard's tree back).
function List.Refresh()
    local list = recipeList()
    local box = list and list.ScrollBox
    if not box then
        return
    end
    -- A provider that isn't ours is Blizzard's newest: it may have set one while our hook slept.
    local current = box.GetDataProvider and box:GetDataProvider()
    if current and current ~= ours then
        theirs = current
    end
    if theirs then
        build(box, ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
    elseif List.adder then
        List.adder.clear()
    end
end

---Hooks the list once Blizzard_Professions has loaded, for a part that changes it: false while the
---list isn't there yet. Hooked through the Professions module, so it runs while any part is on;
---a part that's off adds nothing to what it builds.
---@return boolean
function List.Hook()
    local page = craftingPage()
    local box = page and page.RecipeList and page.RecipeList.ScrollBox
    if not box then
        return false
    end
    professions:Hook(box, "SetDataProvider", onSetDataProvider)
    -- Blizzard sets its "no results" text after the provider, from its own tree.
    professions:Hook(page, "Init", noResults)
    return true
end
