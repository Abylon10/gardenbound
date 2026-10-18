# Server Map Design

Initial design: "Gardenbound Spawn Island". 6 islands, 1 community.
Shared hub, individual growth.

## Layout
- **Central Plaza** in the middle, with a statue/fountain.
- **4 shops on the plaza's outer ring:** Seed Shop, Sell Shop, Gear Shop,
  Blueprint Shop.
- **6 player islands** around the plaza, each joined to it by a bridge.
  Each island has a house, a front garden (crops), and a back garden
  (trees).
- **Dungeon Portal** to the north, shared by all players.
- **Wilderness Gate** to the north-east, open world (no portal).

## Shops
| Shop | Sells |
|---|---|
| Seed Shop | Seeds, tools, seasonal crops |
| Sell Shop | Buys crops, resources, and items for coins |
| Gear Shop | Weapons, armor, accessories |
| Blueprint Shop | House blueprints, crafting recipes, upgrades |

## What's built (code placeholders)
Positions are in `src/server/MapLayout.luau`.

| Thing | Where / what |
|---|---|
| Sea | Terrain water from y -30 to -3, sand floor, 1400×1400 studs |
| Central Plaza | Island radius 110, stone floor radius 100, fountain, two rings of lamps, 6 planter trees |
| Shops | Ring radius 82: Seed NE (45°), Sell SE (135°), Gear SW (225°), Blueprint NW (315°) |
| Player islands | Ring radius 280 at 70°–290°, island radius 95. Front garden, house, back garden, cauldron, trees |
| Dungeon Portal | North (0°), radius 280, island radius 60. Leads to the Abandoned Mine |
| Wilderness Gate | North-east (30°), radius 280, island radius 60. Bridge on to the Meadow |
| Meadow | 30°, radius 550, island radius 150. Slimes, goblins, eggs |
| Bridges | Wooden bridge from the plaza to every island, and from the gate to the Meadow |
| Teleports | "Plaza" and "My Garden" buttons: either end of your garden's bridge |

The template Baseplate is removed when the game starts, because it would
sit above the water. Detailed models (real shop and house art, docks,
banners) can replace the placeholder parts later in Studio.
