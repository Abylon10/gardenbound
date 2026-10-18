# Gardenbound Roadmap

Source: *Gardenbound Game Concept & Development Proposal*.
Pitch: farming-adventure RPG. The homestead is the progression hub; the
wilderness gives eggs and risk; dungeons give equipment and forging
materials. Every system feeds the others.

## MVP, built in phases

Each phase should be playable on its own before the next starts.

### Phase 1: Front garden economy (done)
- [x] Plot per player (6 plots, generated at runtime)
- [x] Plant → grow → harvest → sell loop (Carrot, Tomato, Pumpkin)
- [x] Central Plaza with Seed, Sell, Gear, and Blueprint shops on its
      outer ring; plots in a ring around it (see `docs/map-design.md`)
- [x] Island map from the initial design: sea, plaza island with
      fountain, 6 player islands with house and both gardens, bridges,
      Dungeon Portal and Wilderness Gate islands (decoration)
- [x] Seed shop and sell shop work, coins on the leaderboard
- [x] Seed bar UI to pick the seed to plant
- [x] Save coins, seeds, and harvested crops (DataStore)
- [x] Save planted crops between sessions (they keep growing offline)
- [x] Hide other players' plot prompts on the client

### Phase 2: Back garden and building (done)
- [x] Saplings (Oak, Pine, Maple) from the Seed Shop → grow → chop → wood
- [x] Blueprint Shop: house upgrades II and III, five decorations
- [x] House level 2: porch, chimney, +4 garden tiles; level 3: second
      story, +2 tree spots
- [x] Decorations built with wood on spots by the house
- [x] Shop menus, Bag (inventory), toast messages
- [ ] Free placement of furniture inside the house (later)

### Phase 3: Wilderness and pets (done)
- [x] Meadow zone beyond the Wilderness Gate: slimes, rabbits, goblins
- [x] Combat: Wooden Sword tool, enemy health bars, respawn at home
- [x] Drops: coins, Slime Goo, Rabbit Fluff, Goblin Tooth, Common and
      Forest eggs
- [x] 10 pets (5 farm, 5 battle) in 4 rarities; hatch from the Bag, equip
      one of each; equipped pets follow you and give bonuses
- [ ] Pet levels (later)

### Phase 4: Dungeon, forging, potions
- One dungeon (Abandoned Mine): copper, iron, monster materials
- Forge: craft basic gear from recipes, upgrade +1 to +10
- Health and attack/defense potions

## Later (from the proposal)
More biomes (Deep Forest, Mountain, Corrupted Lands), more dungeons
(Ancient Ruins, Crystal Caverns, Demon Castle), rare crops, seasonal
events, trading, co-op dungeons, fishing/mining/cooking, neighborhoods,
roaming bosses.
