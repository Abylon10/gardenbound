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

## What's built so far (code placeholders)
Positions are in `src/server/MapLayout.luau`.

| Thing | Where |
|---|---|
| Plaza | radius 60, centered on the origin |
| Shops | ring radius 48: Seed NE (45°), Sell SE (135°), Gear SW (225°), Blueprint NW (315°) |
| Plots | ring radius 180 at 70°–290°, front garden facing the plaza, stone path to each |
| Free for later | north arc (0° ± 60°) for the Dungeon Portal and Wilderness Gate |

Islands, water, bridges, and detailed shop/house models are still to be
built in Studio.
