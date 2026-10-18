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
swing your sword. Creatures drop coins, materials, and eggs. Hatch eggs from
the Bag (Items tab) and equip pets in the Pets tab.

Saving needs **Game Settings → Security → Enable Studio Access to API
Services** turned on (and the place published). Without it the game
still runs, it just doesn't save.

If `default.project.json` changes in a pull, stop `rojo serve` (Ctrl+C)
and start it again so Rojo picks up the new folders.

Only scripts are synced. Parts, terrain, and models built in Studio stay in the
place file on Roblox, so publish the place from Studio as usual.
