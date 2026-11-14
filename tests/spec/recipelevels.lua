-- Professions' recipe levels: where a recipe turns yellow, green, and gray, the color they give at
-- a skill, and Skill Bar's layout of them.
local T = ...
local ns, eq, ok, near = T.ns, T.eq, T.ok, T.near

local Professions = ns.Professions
local D = Professions.DIFFICULTY

-- The numbers match Enum.TradeskillRelativeDifficulty's.
eq(D.OPTIMAL, 0, "levels: orange is Optimal")
eq(D.MEDIUM, 1, "levels: yellow is Medium")
eq(D.EASY, 2, "levels: green is Easy")
eq(D.TRIVIAL, 3, "levels: gray is Trivial")

-- Rough Grinding Stone on build 70888: yellow 45, gray 85, so green at 65 (Classic's 25/45/65/85).
local stone = Professions.RecipeLevels(45, 85)
eq(stone.yellow, 45, "levels: yellow as given")
eq(stone.green, 65, "levels: green halfway")
eq(stone.gray, 85, "levels: gray as given")
-- An odd sum rounds down.
eq(Professions.RecipeLevels(45, 80).green, 62, "levels: green rounds down")
-- Yellow at gray: orange straight to gray.
local flat = Professions.RecipeLevels(100, 100)
eq(flat.green, 100, "levels: no yellow or green")
-- Numbers that don't make sense.
eq(Professions.RecipeLevels(90, 85), nil, "levels: yellow past gray")
eq(Professions.RecipeLevels(nil, 85), nil, "levels: no yellow")
eq(Professions.RecipeLevels(0, 85), nil, "levels: yellow of 0")
eq(Professions.RecipeLevels(45, nil), nil, "levels: no gray")

-- The color at a skill, at each edge.
eq(Professions.LevelDifficulty(stone, 1), D.OPTIMAL, "levels: orange at 1")
eq(Professions.LevelDifficulty(stone, 44), D.OPTIMAL, "levels: orange below yellow")
eq(Professions.LevelDifficulty(stone, 45), D.MEDIUM, "levels: yellow at yellow")
eq(Professions.LevelDifficulty(stone, 64), D.MEDIUM, "levels: yellow below green")
eq(Professions.LevelDifficulty(stone, 65), D.EASY, "levels: green at green")
eq(Professions.LevelDifficulty(stone, 84), D.EASY, "levels: green below gray")
eq(Professions.LevelDifficulty(stone, 85), D.TRIVIAL, "levels: gray at gray")
eq(Professions.LevelDifficulty(stone, 300), D.TRIVIAL, "levels: gray past it")
eq(Professions.LevelDifficulty(flat, 99), D.OPTIMAL, "levels: flat recipe orange")
eq(Professions.LevelDifficulty(flat, 100), D.TRIVIAL, "levels: flat recipe gray")

-- The bar: 20 points either side (half of yellow to gray), so 25 to 105, four equal parts.
local bar = Professions.LevelBar(stone, 55)
eq(bar.from, 25, "bar: starts before yellow")
eq(bar.to, 105, "bar: ends after gray")
eq(#bar.segments, 4, "bar: four colors")
local want = { { D.OPTIMAL, 0, 0.25, 25 }, { D.MEDIUM, 0.25, 0.5, 45 }, { D.EASY, 0.5, 0.75, 65 },
    { D.TRIVIAL, 0.75, 1, 85 } }
for i, segment in ipairs(want) do
    eq(bar.segments[i][1], segment[1], "bar: color " .. i)
    near(bar.segments[i][2], segment[2], "bar: left " .. i)
    near(bar.segments[i][3], segment[3], "bar: right " .. i)
    eq(bar.segments[i][4], segment[4], "bar: level " .. i)
end
near(bar.marker, 0.375, "bar: marker at the skill")
eq(Professions.LevelBar(stone, 1).marker, 0, "bar: marker held at the start")
eq(Professions.LevelBar(stone, 300).marker, 1, "bar: marker held at the end")
eq(Professions.LevelBar(stone).marker, nil, "bar: no skill, no marker")

-- A short recipe still shows a few points either side.
local short = Professions.LevelBar(Professions.RecipeLevels(50, 54), 52)
eq(short.from, 45, "bar: at least 5 before yellow")
eq(short.to, 59, "bar: at least 5 after gray")

-- Orange straight to gray: two parts, no yellow or green.
local two = Professions.LevelBar(flat, 100)
eq(#two.segments, 2, "bar: flat recipe has two colors")
eq(two.segments[1][1], D.OPTIMAL, "bar: flat recipe orange first")
eq(two.segments[2][1], D.TRIVIAL, "bar: flat recipe gray next")
near(two.segments[2][2], 0.5, "bar: flat recipe halves")
ok(two.marker == 0.5, "bar: flat recipe marker at gray")

-- More numbers that don't make sense, and the lowest that do.
eq(Professions.RecipeLevels("45", 85), nil, "levels: yellow as text")
eq(Professions.RecipeLevels(45, "85"), nil, "levels: gray as text")
eq(Professions.RecipeLevels(-5, 85), nil, "levels: yellow below 0")
eq(Professions.RecipeLevels(0.5, 85), nil, "levels: yellow below 1")
eq(Professions.RecipeLevels(nil, nil), nil, "levels: nothing")
local first = Professions.RecipeLevels(1, 1)
eq(first and first.green, 1, "levels: yellow of 1 is the lowest")
eq(Professions.LevelDifficulty(first, 1), D.TRIVIAL, "levels: gray from skill 1 then")

-- Gray one past yellow: green is yellow's own level, so the recipe is never yellow, in the color
-- and in the bar alike.
local close = Professions.RecipeLevels(50, 51)
eq(close.green, 50, "levels: green at yellow when gray is one past")
eq(Professions.LevelDifficulty(close, 49), D.OPTIMAL, "levels: close recipe orange below")
eq(Professions.LevelDifficulty(close, 50), D.EASY, "levels: close recipe green at yellow's level")
eq(Professions.LevelDifficulty(close, 51), D.TRIVIAL, "levels: close recipe gray one later")
local closeBar = Professions.LevelBar(close, 50)
eq(#closeBar.segments, 3, "bar: close recipe has three colors")
eq(closeBar.segments[2][1], D.EASY, "bar: close recipe skips yellow")

-- Two past: one point of each.
local pair = Professions.RecipeLevels(50, 52)
eq(Professions.LevelDifficulty(pair, 50), D.MEDIUM, "levels: yellow for one point")
eq(Professions.LevelDifficulty(pair, 51), D.EASY, "levels: then green for one")
eq(Professions.LevelDifficulty(pair, 52), D.TRIVIAL, "levels: then gray")

-- The bar's padding: half of yellow to gray rounded down, and never under 5.
eq(Professions.LevelBar(Professions.RecipeLevels(50, 60)).from, 45, "bar: 10 apart pads 5")
eq(Professions.LevelBar(Professions.RecipeLevels(50, 61)).from, 45, "bar: 11 apart still pads 5")
eq(Professions.LevelBar(Professions.RecipeLevels(50, 62)).from, 44, "bar: 12 apart pads 6")
eq(Professions.LevelBar(Professions.RecipeLevels(50, 62)).to, 68, "bar: and the same after gray")
-- A recipe from skill 1 starts its bar below 1; the marker is still held on it.
local low = Professions.LevelBar(Professions.RecipeLevels(1, 55), 1)
eq(low.from, -26, "bar: starts below skill 1 for a first recipe")
near(low.marker, 27 / 108, "bar: skill 1 on a first recipe")

-- The marker at each end and at each color's start, and what isn't a skill.
eq(Professions.LevelBar(stone, 25).marker, 0, "bar: marker at the bar's first skill")
eq(Professions.LevelBar(stone, 105).marker, 1, "bar: marker at the bar's last skill")
near(Professions.LevelBar(stone, 26).marker, 1 / 80, "bar: one point in")
near(Professions.LevelBar(stone, 104).marker, 79 / 80, "bar: one point from the end")
eq(Professions.LevelBar(stone, "55").marker, nil, "bar: text isn't a skill")
for i, level in ipairs({ 45, 65, 85 }) do
    near(Professions.LevelBar(stone, level).marker, bar.segments[i + 1][2],
        "bar: marker at a color's start is at its left edge " .. i)
end

-- Whatever the recipe, the colors fill the bar with no gap: each starts where the last ended, and
-- the color at a segment's level is the segment's.
for _, numbers in ipairs({ { 45, 85 }, { 45, 80 }, { 1, 1 }, { 50, 51 }, { 50, 52 }, { 1, 300 }, { 299, 300 } }) do
    local levels = Professions.RecipeLevels(numbers[1], numbers[2])
    local each = Professions.LevelBar(levels)
    local what = ("bar: %d to %d "):format(numbers[1], numbers[2])
    local joined, colored = true, true
    for i, segment in ipairs(each.segments) do
        local left = i == 1 and 0 or each.segments[i - 1][3]
        joined = joined and math.abs(segment[2] - left) < 1e-9 and segment[3] > segment[2]
        -- The first segment starts before yellow, where the recipe is orange.
        colored = colored and Professions.LevelDifficulty(levels, segment[4]) == segment[1]
    end
    eq(joined, true, what .. "has no gaps")
    near(each.segments[#each.segments][3], 1, what .. "ends at the bar's end")
    eq(colored, true, what .. "colors match the color at their level")
end
