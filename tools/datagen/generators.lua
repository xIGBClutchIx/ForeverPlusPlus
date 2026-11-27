-- The generated files, one module each: its `path`, the `tables` it reads, `Build` to write it,
-- and `Entry` for summary.lua to tell its entries apart. One that compares with Classic lists
-- those tables in `classic`, and reads each as `tables["Classic.<name>"]`. One that reads a table in
-- every language the addon has lists it in `localized`, and reads each as `tables["<code>.<name>"]`
-- for the codes in `tables.languages`.
return {
    require("unexplored"),
    require("explorable"),
    require("skilllevels"),
    require("taxiroutes"),
    require("reference"),
    require("instancelevels"),
    require("disenchant"),
    require("lockboxes"),
    require("scrolls"),
    require("weaponbuffs"),
    require("newitems"),
    require("gametext"),
}
