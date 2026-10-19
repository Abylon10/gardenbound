# Gardenbound Roadmap

Source: *Gardenbound Game Concept & Development Proposal*.
Pitch: farming-adventure RPG. The homestead is the progression hub; the
wilderness gives eggs and risk; dungeons give equipment and forging
materials. Every system feeds the others.

## MVP, built in phases

Each phase should be playable on its own before the next starts.

### Phase 1: Front garden economy (done)
- [x] Plot per player (6 plots, generated at runtime)
- [x] Plant → grow → harvest → sell loop (Carrot, Tomato, Eggplant,
      Cabbage, Chilli)
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
- [x] Saplings (Birch, Apple, Coconut) from the Seed Shop → grow → chop
      → wood
- [x] Blueprint Shop: house upgrades II and III, five decorations
- [x] House level 2: porch, chimney, +4 garden tiles; level 3: second
      story, +2 tree spots
- [x] Decorations built with wood on spots by the house
- [x] Shop menus, Bag (inventory), toast messages
- [ ] Free placement of furniture inside the house (later)

### Phase 3: Wilderness and pets (done)
- [x] Meadow zone beyond the Wilderness Gate: slimes and goblins
- [x] Combat: sword tool, enemy health bars, respawn at home
- [x] Drops: Slime → coins, Slime Gel, Wild Berries; Goblin → more coins,
      Goblin Fang, Rough Hide, rare Rusty Sword
- [x] Eggs are found in the world, not dropped: glowing eggs on spots
      beside trees, behind rocks, and in clearings; rarer further from the
      entrance and in hidden spots; respawn elsewhere after collection
- [x] Pets: Hen and Giant Earthworm (Common, farm), Dog and Cat
      (Uncommon, battle), Butterfly (Rare, farm); hatch from the Bag with
      a reveal, equip one of each; equipped pets follow you and give
      bonuses
- [x] Eggs in 5 tiers (Common, Uncommon, Rare, Epic, Special), each with
      its own look; rarity by distance, hidden nooks for Epic/Special
- [ ] Pets for Epic and Special eggs (to be designed)
- [ ] Pet levels (later)

### Phase 4: Dungeon, forging, potions (done)
- [x] Abandoned Mine through the Dungeon Portal: Entrance, Tunnels,
      Diggings, Deep Cavern; slimes (Slime Gel, Slime Core) and bats (Bat
      Wing, rare Shadow Essence)
- [x] Copper and iron ore veins (regrow after 45 s)
- [x] Forge at the Gear Shop: Copper/Iron swords, Shadow Blade, four
      armors; upgrade +1 to +10; equip from the Bag's Gear tab
- [x] Cauldron at home: Health (30% HP, 15 s cooldown), Swiftness (+25%
      speed for 10 s, 30 s cooldown), Strength (+15% damage for 15 s,
      30 s cooldown)

## MVP status
All four phases of the proposal's first playable version are in. Next
ideas: test and balance in Studio, pet levels, free furniture placement,
instanced/co-op dungeons, more zones (Deep Forest, Mountain, Corrupted
Lands) and dungeons, real art to replace the code-built placeholders.

## Later (from the proposal)
More biomes (Deep Forest, Mountain, Corrupted Lands), more dungeons
(Ancient Ruins, Crystal Caverns, Demon Castle), rare crops, seasonal
events, trading, co-op dungeons, fishing/mining/cooking, neighborhoods,
roaming bosses.
