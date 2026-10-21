# Gardenbound

A Roblox game. Scripts live in this repo and sync into Roblox Studio with [Rojo](https://rojo.space).

## Folder layout

| Folder        | Shows up in Studio as                             | Runs on |
|---------------|---------------------------------------------------|---------|
| `src/server`  | `ServerScriptService.Server`                      | server  |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`       | client  |
| `src/shared`  | `ReplicatedStorage.Shared`                        | both    |
| `src/first`   | `ReplicatedFirst` (loading screen)                | client  |

File suffixes: `.server.luau` = Script, `.client.luau` = LocalScript, plain `.luau` = ModuleScript.

## Setup (Windows, once per PC)

1. Install [Rokit](https://github.com/rojo-rbx/rokit) (toolchain manager), then in this folder run:
   ```
   rokit install
   ```
2. Install the Rojo Studio plugin:
   ```
   rojo plugin install
   ```
3. Optional: install the **Rojo** extension in VS Code.

## Daily use

1. `git pull`
2. In this folder: `rojo serve`
3. In Studio, open the place, then **Plugins → Rojo → Connect**.
4. Edit `.luau` files here. Changes appear in Studio live.
5. `git add` / `git commit` / `git push` when done.

## Try the current build

Press Play in Studio. You spawn on your own plot with 20 coins and 3 carrot
seeds. Walk to a soil tile and press **E** to plant, wait for it to grow,
press **E** to harvest, then follow the path to the Central Plaza and sell
at the **Sell Shop**. Buy more seeds from the crates in the **Seed Shop**. Pick which seed to plant in the bar at the
bottom of the screen.

Back garden: buy saplings at the Seed Shop, plant them on the spots in your
back garden, and chop grown trees for wood. Buy blueprints at the Blueprint
Shop, then build them at home: the house upgrade prompt is by the door and
decorations go on the yellow pads around the house. Open the **Bag** button
on the left to see everything you have.

Wilderness: cross the Wilderness Gate island to reach the Meadow. Click to
swing your sword. Slimes and goblins drop coins and materials. Look around the
Meadow for glowing eggs (rarer further from the entrance and behind rocks).
Hatch eggs from the Bag (Items tab) and equip pets in the Pets tab.

Dungeon: walk into the purple Dungeon Portal (north) to enter the
Abandoned Mine. Mine copper and iron veins and fight slimes and bats. Craft and upgrade gear at the Forge (Gear Shop) and
equip it from the Bag's Gear tab. Brew potions at the cauldron by your house
and drink them from the Bag.

## Editing the map in Studio

The world is built by the scripts when the game starts, so in edit mode
Studio is empty. To get the map into the place so you can see and edit it:

1. Make sure the game is **not** running, and Rojo is connected.
2. Open **View > Command Bar** and run:
   ```
   require(game.ServerScriptService.Server.World).bake()
   ```
3. Save the place (**File > Save to Roblox**).

Now the islands, plaza, shops, plots, docks, landmarks, Meadow, mine, and
NPCs are real parts in the Explorer. Move, recolor, delete, or replace
anything and save. The game uses your saved version; anything you delete
is rebuilt by code when the game starts. Egg spots in the Meadow are
invisible `EggSpot` parts (in `Wilderness > Meadow > EggSpots`) that you can
move; `Hidden` ones hold Epic/Special eggs. Houses are still rebuilt by
code (they change when you upgrade).

When an update changes the map's code, your baked map won't change
automatically. Either re-bake (this replaces your edits) or ask for the
change to be made by hand. To go back to the code's version:
`require(game.ServerScriptService.Server.World).clear()` (also erases all
terrain), then bake again.

Short grass: the animated grass blades on terrain can't be changed from a
script. In Studio, select **Terrain** in the Explorer and, in Properties,
turn off **Decoration** (or lower the grass length if your Studio shows
that option). Save the place afterwards.

Saving needs **Game Settings → Security → Enable Studio Access to API
Services** turned on (and the place published). Without it the game
still runs, it just doesn't save.

If `default.project.json` changes in a pull, stop `rojo serve` (Ctrl+C)
and start it again so Rojo picks up the new folders.

Only scripts are synced. Parts, terrain, and models built in Studio stay in the
place file on Roblox, so publish the place from Studio as usual.
