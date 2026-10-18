# Gardenbound — Project Context

Roblox farming-adventure RPG by ABYLON_01 (Justin Dave). Solo for now.
Design and phase plan: `docs/ROADMAP.md` (from the game proposal).

## Setup
- Scripts are Luau, synced into Studio with Rojo (`default.project.json`).
  Rojo version is pinned in `rokit.toml`.
- `src/server` → ServerScriptService.Server, `src/client` →
  StarterPlayerScripts.Client, `src/shared` → ReplicatedStorage.Shared.
- Suffixes: `.server.luau` Script, `.client.luau` LocalScript, `.luau` ModuleScript.
- Only code lives here. Parts/terrain/models live in the Studio place file.
- Studio's built-in MCP server is connected to Claude Desktop on Justin
  Dave's PC, so a local Claude can edit the open place directly. Cloud
  sessions can only edit files in this repo.
- Local copy: `C:\Users\Pc\Documents\gardenbound`. Workflow there:
  `git pull`, `rojo serve`, then Rojo → Connect in Studio.

## Code layout
- `src/server/init.server.luau` starts each system module in order.
- `PlayerData` owns all saved player state (coins, seeds, crops) and
  mirrors it to `leaderstats.Coins` and player attributes
  `Seed_<Crop>` / `Crop_<Crop>`. Other systems change state only
  through its functions.
- `MapLayout` holds every map position: the Central Plaza at the
  origin, shop angles on its outer ring, and the ring of 6 player plots.
  Angles are degrees clockwise from north (-Z). North is reserved for
  the Dungeon Portal and Wilderness Gate.
- `Plots` generates plots at runtime in `workspace.Plots` and assigns
  one per player (`OwnerId` attribute on the plot). Front gardens face
  the plaza.
- `Plaza` builds `workspace.Plaza` (floor, 4 shop stalls, paths to each
  plot) and handles shop prompts. Seed and Sell shops work; Gear and
  Blueprint are placeholders.
- `Farming` handles soil-tile prompts (plant, grow, harvest). The server
  always checks plot ownership.
- `Build` has the shared part/prompt/sign helpers.
- `src/shared/Crops.luau` is the single list of crops and their numbers.
- Remotes live in `ReplicatedStorage.Remotes`, created by the server.
  Validate every remote argument on the server.

## Conventions
- Map art (islands, water, bridges, real shop models) is planned to be
  built in Studio; the code-built parts are placeholders. Keep gameplay
  objects (prompts, tiles) findable by name so art can replace the rest.
- Map reference: `docs/map-design.md`.
- Tabs for indentation. Each module has a short header comment.
- Prefer server-authoritative logic; the client only shows UI and sends
  requests.
- No syntax checker in Studio-free environments by default; cloud
  sessions can download `luau-compile` from luau-lang/luau releases and
  run `luau-compile --null <file>` to catch syntax errors.
