-- The recipe list in an order the player picks (Crafting Costs' Sort Recipe List): recipes with a
-- value first, by it, high or low first; those without one after; Blizzard's order within a tie;
-- the order kept through the category tree; and a node's recipes reordered among its other
-- children, which stay where they were.
local T = ...
local ns, eq, ok = T.ns, T.eq, T.ok

local Professions = ns.Professions

local function recipe(id, name, gray)
    return { recipeID = id, categoryID = 1, name = name, maxTrivialLevel = gray or 50, itemLevel = 10 }
end

local axe = recipe(1, "Copper Axe")
local mace = recipe(2, "Copper Mace")
local belt = recipe(3, "Copper Belt")
local enchant = recipe(4, "Enchant Bracer", 90)
local helm = recipe(5, "Bronze Helm", 120)
local values = { [1] = 500, [2] = -200, [3] = 500, [4] = nil, [5] = nil }
local asked = {}
local function valueOf(info)
    asked[info] = (asked[info] or 0) + 1
    return values[info.recipeID]
end

local function sorted(list, order)
    local copy = {}
    for i, item in ipairs(list) do
        copy[i] = item
    end
    table.sort(copy, order)
    local out = {}
    for i, item in ipairs(copy) do
        out[i] = item.name
    end
    return table.concat(out, ", ")
end

local all = { enchant, mace, axe, helm, belt }
eq(sorted(all, Professions.RecipeOrder(valueOf, true)),
    "Copper Axe, Copper Belt, Copper Mace, Bronze Helm, Enchant Bracer",
    "order: highest first, a tie and those without a value in Blizzard's order")
eq(sorted(all, Professions.RecipeOrder(valueOf, false)),
    "Copper Mace, Copper Axe, Copper Belt, Bronze Helm, Enchant Bracer",
    "order: lowest first, and those without a value still last")
local most = 0
for _, count in pairs(asked) do
    most = math.max(most, count)
end
eq(most, 2, "order: each recipe's value asked once per comparator")

-- What isn't a number counts as no value.
local odd = Professions.RecipeOrder(function(info)
    if info == axe then
        return 0 / 0
    elseif info == mace then
        return "12"
    end
    return 1
end, true)
eq(sorted({ axe, mace, belt }, odd), "Copper Belt, Copper Axe, Copper Mace", "order: NaN and text are no value")
ok(not odd(axe, axe), "order: a recipe isn't before itself")

-- Through the category tree: the categories keep their order, the recipes in each take ours.
local categories = {
    [1] = { categoryID = 1, name = "Weapons", uiOrder = 1 },
    [2] = { categoryID = 2, name = "Armor", uiOrder = 0 },
}
local tree = Professions.RecipeTree({ axe, mace, belt, helm, enchant }, function(id)
    return categories[id]
end, false, Professions.RecipeOrder(valueOf, false))
eq(#tree, 1, "tree: one category")
eq(tree[1].recipes[1].name, "Copper Mace", "tree: the order given, lowest first")
eq(tree[1].recipes[5].name, "Enchant Bracer", "tree: no value last")
local plain = Professions.RecipeTree({ axe, mace, helm }, function(id)
    return categories[id]
end, false)
eq(plain[1].recipes[1].name, "Bronze Helm", "tree: Blizzard's order without one")

-- A node's children: a subcategory and the paddings stay put, the recipes are reordered in the
-- recipes' places.
local children = {
    { kind = "category" },
    { kind = "top" },
    { kind = "recipe", info = mace },
    { kind = "recipe", info = enchant },
    { kind = "recipe", info = axe },
    { kind = "bottom" },
}
local function recipeOf(item)
    return item.info
end
local out = Professions.OrderAmong(children, recipeOf, Professions.RecipeOrder(valueOf, true))
eq(#out, 6, "among: as many as given")
eq(out[1].kind, "category", "among: a subcategory stays first")
eq(out[2].kind, "top", "among: the top padding stays")
eq(out[3].info, axe, "among: the highest first")
eq(out[4].info, mace, "among: then the lower")
eq(out[5].info, enchant, "among: then the one without a value")
eq(out[6].kind, "bottom", "among: the bottom padding stays last")
eq(children[3].info, mace, "among: the list given isn't changed")
eq(#Professions.OrderAmong({}, recipeOf, Professions.RecipeOrder(valueOf, true)), 0, "among: nothing")
