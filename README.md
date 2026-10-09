# Gardenbound

A Roblox game. Scripts live in this repo and sync into Roblox Studio with [Rojo](https://rojo.space).

## Folder layout

| Folder        | Shows up in Studio as                             | Runs on |
|---------------|---------------------------------------------------|---------|
| `src/server`  | `ServerScriptService.Server`                      | server  |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`       | client  |
| `src/shared`  | `ReplicatedStorage.Shared`                        | both    |

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
press **E** to harvest, then sell at the stand on the right. Buy more seeds
from the crates on the left. Pick which seed to plant in the bar at the
bottom of the screen.

Saving needs **Game Settings → Security → Enable Studio Access to API
Services** turned on (and the place published). Without it the game
still runs, it just doesn't save.

Only scripts are synced. Parts, terrain, and models built in Studio stay in the
place file on Roblox, so publish the place from Studio as usual.
