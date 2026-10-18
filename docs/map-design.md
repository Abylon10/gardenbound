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
| Sea | Terrain water from y -30 to -3, sand floor, 720×720 studs |
| Central Plaza | Island radius 68, stone floor radius 60, fountain, 8 lamps, 3 planter trees |
| Shops | Ring radius 48: Seed NE (45°), Sell SE (135°), Gear SW (225°), Blueprint NW (315°) |
| Player islands | Ring radius 220 at 70°–290°, island radius 72. Each has a fenced Front Garden (12 soil tiles, yellow sign) facing the plaza, a house with a colored roof, a fenced Back Garden (green sign, saplings), and trees |
| Dungeon Portal | North (0°), island radius 42. Stone arch, purple glowing gateway, torches. Not usable yet |
| Wilderness Gate | North-east (27°), island radius 42. Log gate with banner. Not usable yet |
| Bridges | Wooden bridge with railings from the plaza to every island |

The template Baseplate is removed when the game starts, because it would
sit above the water. Detailed models (real shop and house art, docks,
banners) can replace the placeholder parts later in Studio.
