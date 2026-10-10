-- English text for the map modules and the map helpers. Locales/enUS/Core.lua says how locale files work.
local _, ns = ...

local L = ns.NewLocale("enUS")
if not L then
    return
end

-- Instances (Lib), shown in map tooltips and panels
L.INSTANCES_LEVEL = "Level %d"
L.INSTANCES_LEVELS = "Level %d-%d" -- lowest, highest
L.INSTANCES_RANGE = "%d-%d" -- lowest, highest

-- WorldMap: one module, a part each for Points of Interest, Zone Info, Unexplored Areas, and
-- Coordinates. Each part's title heads its section in Settings, over its Enabled checkbox.
L.WORLDMAP_TITLE = "World Map"
L.WORLDMAP_DESC = "Add to the world map: points of interest, a zone info panel, unexplored areas, "
    .. "and coordinates. Each has its own Enabled checkbox below."

-- PointsOfInterest. Place names on the map come from the game, or from Data.lua.
L.POI_TITLE = "Points of Interest"
-- Smaller headers over its options in Settings
L.POI_SECTION_INSTANCES = "Dungeons and Raids"
L.POI_SECTION_TRAVEL = "Cities and Travel"
L.POI_SECTION_OTHER = "Other"
L.POI_DESC = "Show dungeons, raids, capital cities, flight masters, boats, zeppelins, spirit "
    .. "healers, and Skyborne ley lines on the world map."
L.POI_DUNGEONS = "Dungeons"
L.POI_DUNGEONS_DESC = "Dungeon entrances, with their level range colored against yours."
L.POI_RAIDS = "Raids"
L.POI_RAIDS_DESC = "Raid entrances."
L.POI_CAPITALS = "Capital Cities"
L.POI_CAPITALS_DESC = "Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, and the "
    .. "Undercity: our icons, with the city's dungeons in the tooltip (Blizzard's are then "
    .. "hidden), Blizzard's own city icons, or neither."
L.POI_CAPITALS_OURS = "Forever++"
L.POI_CAPITALS_BLIZZARD = "Blizzard"
L.POI_CAPITALS_OFF = "Off"
L.POI_FLIGHT = "Flight Masters"
L.POI_FLIGHT_DESC = "Flight masters of your faction, and ones that fly for both."
L.POI_SHIPS = "Boats"
L.POI_SHIPS_DESC = "Boat docks, with where the boat goes."
L.POI_ZEPPELINS = "Zeppelins"
L.POI_ZEPPELINS_DESC = "Zeppelin towers, with where the zeppelin goes."
L.POI_SPIRIT = "Spirit Healers"
L.POI_SPIRIT_DESC = "Spirit healers, where you can come back to life after dying."
L.POI_SIZE = "Icon Size"
L.POI_SIZE_DESC = "How big the icons are, compared with their normal size."
L.POI_WORLD = "On Continent Maps"
L.POI_WORLD_DESC = "Also show them on the continent and world maps, not just zone maps."
L.POI_OTHER_FACTION = "Other Faction"
L.POI_OTHER_FACTION_DESC = "Also show the other faction's flight masters, boats, and zeppelins."
L.POI_LEYLINES = "Ley Lines"
L.POI_LEYLINES_DESC = "Ley lines (High Order Skyborne) and elemental convergences (Windshaper "
    .. "Skyborne), saved where a Skyborne on this account got the 15-minute buff from Read Ley "
    .. "Line or Skysight. Shown to a Skyborne for their own kind, to every character, or to none."
L.POI_LEYLINES_SKYBORNE = "Skyborne"
L.POI_LEYLINES_EVERYONE = "Everyone"
L.POI_LEYLINES_OFF = "None"
L.POI_CHAT_DESC = "Say in chat when a new ley line is saved."
L.POI_LEYLINES_FORGET = "Saved Ley Lines"
L.POI_LEYLINES_FORGET_BUTTON = "Forget"
L.POI_LEYLINES_FORGET_DESC = "Forget every ley line and elemental convergence saved on this account."
L.POI_LEYLINES_FORGET_CONFIRM = "Forget every saved ley line and elemental convergence?"
L.POI_LEYLINES_FORGET_DONE = "Saved ley lines forgotten."
L.POI_LEYLINE_SAVED = "Ley line saved on the map in %s." -- a zone
L.POI_CONVERGENCE_SAVED = "Elemental convergence saved on the map in %s." -- a zone
-- Tooltips
L.POI_DUNGEON = "Dungeon"
L.POI_RAID = "Raid"
L.POI_CAPITAL = "Capital City"
L.POI_PART = "%s (%s)" -- an instance, which entrance
L.POI_MAIN_GATE = "Main Gate"
L.POI_SERVICE_GATE = "Service Gate"
L.POI_NORTH = "North"
L.POI_EAST = "East"
L.POI_WEST = "West"
L.POI_FLIGHT_MASTER = "Flight Master"
L.POI_FLIGHT_UNLEARNED = "Not learned yet"
L.POI_SHIP_TO = "Boat to %s" -- a place
L.POI_ZEPPELIN_TO = "Zeppelin to %s" -- a place
L.POI_VIA = "Stops at %s first" -- a place, on a boat's way
L.POI_SPIRIT_HEALER = "Spirit Healer"
L.POI_LEYLINE = "Ley Line"
L.POI_CONVERGENCE = "Elemental Convergence"
L.POI_LEYLINE_CAST = "Cast %s here" -- a spell

-- ZoneInfo
L.ZONEINFO_TITLE = "Zone Info"
-- Smaller headers over its options in Settings
L.ZONEINFO_SECTION_GENERAL = "General"
L.ZONEINFO_SECTION_ZONE = "Zone"
L.ZONEINFO_SECTION_PROFESSIONS = "Professions"
L.ZONEINFO_DESC = "Show a zone's level range, fishing skill, and the herbs, ore, and skinning in "
    .. "it for your professions, in a corner of the world map."
L.ZONEINFO_CORNER = "Corner"
L.ZONEINFO_CORNER_DESC = "Which corner of the world map the panel sits in. In a right corner the icons move to the right and the text lines up on the right."
L.ZONEINFO_BOTTOMLEFT = "Bottom Left"
L.ZONEINFO_BOTTOMRIGHT = "Bottom Right"
L.ZONEINFO_TOPLEFT = "Top Left"
L.ZONEINFO_TOPRIGHT = "Top Right"
L.ZONEINFO_HOVER = "On Continent Maps"
L.ZONEINFO_HOVER_DESC = "On a continent map, show the zone under the cursor."
L.ZONEINFO_HIDE_LABEL = "Hide the Map's Zone Name"
L.ZONEINFO_HIDE_LABEL_DESC = "On a continent map, hide the zone name the game shows at the top of "
    .. "the map while this panel shows the same zone. Names of dungeons and other icons still show."
L.ZONEINFO_LEVELS = "Level Range"
L.ZONEINFO_LEVELS_DESC = "The zone's level range, colored against your level like quests."
L.ZONEINFO_FISHING = "Fishing"
L.ZONEINFO_FISHING_DESC = "The Fishing skill the zone's waters need: red while yours is lower, green once "
    .. "it's enough."
L.ZONEINFO_HERBS = "Herbs"
L.ZONEINFO_HERBS_DESC = "The herbs in the zone. With Herbalism they're colored against your skill "
    .. "like Profession Tooltips."
L.ZONEINFO_ORE = "Ore"
L.ZONEINFO_ORE_DESC = "The ore in the zone. With Mining it's colored against your skill."
L.ZONEINFO_SKINNING = "Skinning"
L.ZONEINFO_SKINNING_DESC = "The Skinning the zone's beasts need, from its level range."
L.ZONEINFO_SHOW_OFF = "Off"
L.ZONEINFO_SHOW_KNOWN = "With the Profession"
L.ZONEINFO_SHOW_ALWAYS = "Always"
L.ZONEINFO_SHOW_KEY = "Hold Detail Key"
L.ZONEINFO_DETAIL_KEY = "Detail Key"
L.ZONEINFO_DETAIL_KEY_DESC = "The key that shows the rows set to Hold Detail Key while you hold it. Herbs, ore, and skinning still need the profession."
L.ZONEINFO_KEY_SHIFT = "Shift"
L.ZONEINFO_KEY_ALT = "Alt"
L.ZONEINFO_KEY_CTRL = "Ctrl"
L.ZONEINFO_FACTION = "Territory"
L.ZONEINFO_FACTION_DESC = "Who holds the zone, in the colors the game uses when you enter it: green "
    .. "for your faction, red for the other, orange for contested. On the zone's name, or on a "
    .. "line of its own."
L.ZONEINFO_FACTION_NAME = "Name Color"
L.ZONEINFO_FACTION_LINE = "Own Line"
L.ZONEINFO_TERRITORY = "%s Territory" -- a faction
L.ZONEINFO_CONTESTED = "Contested Territory"
L.ZONEINFO_DUNGEONS = "Dungeons"
L.ZONEINFO_DUNGEONS_DESC = "The dungeons and raids whose entrance is in the zone, with their level "
    .. "range colored against yours."
L.ZONEINFO_SIZE = "Size"
L.ZONEINFO_SIZE_DESC = "How big the panel is, compared with its normal size."
L.ZONEINFO_TITLE_LEVELS = "%s  %s" -- zone, its levels ("10-20")
L.ZONEINFO_RANGE = "%s-%s" -- lowest, highest
L.ZONEINFO_SKILL = "%s %s" -- profession, skill needed ("Fishing 55")
L.ZONEINFO_FISHING_NAME = "Fishing" -- until the client gives its own name
L.ZONEINFO_SKINNING_NAME = "Skinning"
L.ZONEINFO_LIST_SEPARATOR = ", "

-- UnexploredAreas
L.UNEXPLORED_TITLE = "Unexplored Areas"
L.UNEXPLORED_DESC = "Show the parts of zone maps you haven't explored yet, on the world map and "
    .. "the zone map."
L.UNEXPLORED_TINT = "Tint"
L.UNEXPLORED_TINT_DESC = "Tint unexplored areas so they stand apart from the ones you've "
    .. "explored. Off shows them just like explored areas."
L.UNEXPLORED_STRENGTH = "Tint Strength"
L.UNEXPLORED_STRENGTH_DESC = "How strong the tint is."
L.UNEXPLORED_COLOR = "Tint Color"
L.UNEXPLORED_COLOR_DESC = "The color of the tint."
L.UNEXPLORED_BLUE = "Blue"
L.UNEXPLORED_GRAY = "Gray"
L.UNEXPLORED_GOLD = "Gold"
L.UNEXPLORED_GREEN = "Green"
L.UNEXPLORED_RED = "Red"
L.UNEXPLORED_PURPLE = "Purple"

-- Coordinates
L.COORDS_TITLE = "Coordinates"
L.COORDS_DESC = "Show your coordinates and the cursor's in the world map's title bar."
L.COORDS_PLAYER = "Player"
L.COORDS_PLAYER_DESC = "Your coordinates, with your zone's name when the map shows another."
L.COORDS_CURSOR = "Cursor"
L.COORDS_CURSOR_DESC = "The coordinates under the cursor, while it's on the map."
L.COORDS_TENTHS = "Tenths"
L.COORDS_TENTHS_DESC = "Coordinates to a tenth, like 45.2, instead of whole numbers."
L.COORDS_MINIMAP = "On the Minimap"
L.COORDS_MINIMAP_DESC = "Your coordinates on the minimap too."
L.COORDS_TITLEBAR = "In the Title Bar"
L.COORDS_TITLEBAR_DESC = "Your coordinates on the left of the map's title bar and the cursor's "
    .. "on the right. Off shows them in the map's bottom left corner, as the game does."

-- HideFilterReset
L.HIDEFILTERRESET_TITLE = "Hide Filter Reset"
L.HIDEFILTERRESET_DESC = "Hide the reset button on the world map's filter dropdown, which shows "
    .. "whenever a filter is off."


-- FlightTimer
L.FLIGHTTIMER_TITLE = "Flight Timer"
L.FLIGHTTIMER_DESC = "Time every flight you take, then show how long a flight takes: a bar that "
    .. "counts it down as you fly, and the time on the flight map's tooltip."
L.FLIGHTTIMER_BAR = "Timer Bar"
L.FLIGHTTIMER_BAR_DESC = "A bar with the time left while you fly. Move and resize it in Edit Mode. A flight "
    .. "you haven't taken before counts up instead, and is timed for next time."
L.FLIGHTTIMER_TOOLTIP = "Flight Map Tooltip"
L.FLIGHTTIMER_TOOLTIP_DESC = "How long the flight takes, on a flight point's tooltip on the flight "
    .. "map, once you have flown it. Each route is timed on its own."
L.FLIGHTTIMER_TIME = "Flight time: %s" -- a time like 2:05
L.FLIGHTTIMER_RESET_TIMES = "Flight Times"
L.FLIGHTTIMER_RESET_TIMES_BUTTON = "Reset"
L.FLIGHTTIMER_RESET_TIMES_DESC = "Forgets every flight time. They are timed again as you fly."
L.FLIGHTTIMER_RESET_TIMES_CONFIRM = "Forget every flight time Flight Timer has recorded?"
L.FLIGHTTIMER_RESET_TIMES_DONE = "Flight times forgotten."

-- Waypoints
L.WAYPOINTS_TITLE = "Waypoints"
L.WAYPOINTS_DESC = "Put the game's map pin on a spot with /way, and follow it with an arrow on "
    .. "screen that turns toward it as you turn."
L.WAYPOINTS_WAY = "/way"
L.WAYPOINTS_WAY_DESC = "/way [zone] x y puts the game's map pin on a spot and tracks it, in your "
    .. "zone or the one named. /way clear takes it away. Left to TomTom or another addon that "
    .. "already has /way."
L.WAYPOINTS_ARROW = "Waypoint Arrow"
L.WAYPOINTS_ARROW_DESC = "An arrow that points to your map pin, from /way or a click on the map, "
    .. "with how far it is. It goes away when you get there. Move and resize it in Edit Mode."
L.WAYPOINTS_USAGE = "/way [zone] x y, such as /way 45.2 67.8 or /way Elwynn Forest 45 67. "
    .. "/way clear takes the pin away."
L.WAYPOINTS_SET = "Waypoint set in %s at %.1f, %.1f." -- zone, x, y
L.WAYPOINTS_CLEARED = "Waypoint cleared."
L.WAYPOINTS_RANGE = "Coordinates go from 0 to 100."
L.WAYPOINTS_NO_ZONE = "No zone called %s." -- what was typed
L.WAYPOINTS_NO_MAP = "There's no map here. Name a zone: /way Elwynn Forest 45 67."
L.WAYPOINTS_NOT_HERE = "Can't put a waypoint on the %s map." -- zone
L.WAYPOINTS_UNAVAILABLE = "This client has no map waypoints."
L.WAYPOINTS_YARDS = "%s yds" -- a distance; the game's own words are used when it has them
