# Gardenbound — Project Context

Roblox farming-adventure RPG by ABYLON_01 (Justin Dave). Solo for now.
Design and phase plan: `docs/ROADMAP.md` (from the game proposal).

## Setup
- Scripts are Luau, synced into Studio with Rojo (`default.project.json`).
  Rojo version is pinned in `rokit.toml`.
- `src/server` → ServerScriptService.Server, `src/client` →
  StarterPlayerScripts.Client, `src/shared` → ReplicatedStorage.Shared,
  `src/first` → ReplicatedFirst (the loading screen).
- Suffixes: `.server.luau` Script, `.client.luau` LocalScript, `.luau` ModuleScript.
- Only code lives here. Parts/terrain/models live in the Studio place file.
- Studio's built-in MCP server is connected to Claude Desktop on Justin
  Dave's PC, so a local Claude can edit the open place directly. Cloud
  sessions can only edit files in this repo.
- Local copy: `C:\Users\Pc\Documents\gardenbound`. Workflow there:
  `git pull`, `rojo serve`, then Rojo → Connect in Studio.

## Code layout
- `src/server/init.server.luau` starts each system module in order.
- `PlayerData` owns all saved player state (see the `Data` type) and
  mirrors it to `leaderstats.Coins` and player attributes
  `Seed_<Crop>`, `Crop_<Crop>`, `Item_<ItemId>`. Systems either use its
  helpers (`addItem`, `pay`, ...) or edit `PlayerData.get(player)` and
  then call `PlayerData.changed(player)`. Extra client-visible state is
  published with `PlayerData.onSync`. New fields go in `defaultData()`;
  old saves get the default.
- `MapLayout` holds every map position: the sea, the Central Plaza at
  the origin, shop angles on its outer ring, the ring of 6 player
  islands, and the Dungeon Portal / Wilderness Gate islands to the
  north. Angles are degrees clockwise from north (-Z).
- `Islands` shapes the terrain (water, sea floor, an island under the
  plaza and every other island) and removes the template Baseplate. It
  runs first.
- `Plots` generates plots at runtime in `workspace.Plots` and assigns
  one per player (`OwnerId` attribute on the plot). Front gardens face
  the plaza. Houses, fences, and trees go in each plot's `Decor` folder.
- `Plaza` builds `workspace.Plaza` (floor, fountain, lamps, 4 shop
  stalls, a bridge to every island) and handles the Sell Shop prompt.
  Shops with a menu have an `OpenShop` prompt (attribute `Shop`); the
  client `ShopMenu` opens it from `shared/ShopCatalog`, and server
  `Shops` handles `ShopBuy` (checks distance, charges, grants). New
  entry types: `Shops.registerType` + `ShopMenu.registerOwnedText`.
- `Homestead`: house upgrades (`HouseUpgrade` prompt, needs blueprint +
  wood), decorations on `BuildSpots`, and unlocking parts with a
  `RequiredLevel` attribute (sets `Locked` on the part and `Hidden` on its
  prompt). `HomeBuilder` builds house levels and decorations.
- `Forestry`: back-garden `TreeSpots`; saplings grow on real time
  (saved in `trees`), chop for Wood.
- `Notify.send(player, text, kind)` shows a toast; `Remotes.event(name)`
  gets or creates a RemoteEvent.
- Plot reset on leave: register with `Plots.onRelease`.
- `Farming` handles soil-tile prompts (plant, grow, harvest). Growth is
  real-time and saved per tile (`garden`), so crops keep growing offline.
  `Farming.growthMultiplier` / `harvestAmount` are hooks for bonuses.
  The server always checks plot ownership; the client `PlotPrompts`
  just hides other players' prompts.
- `Landmarks` builds the Dungeon Portal and Wilderness Gate islands
  (decoration only for now).
- `Spawning` turns off `CharacterAutoLoads`. While the loading screen is
  up, the player's ReplicationFocus is their spawn point so their island
  streams in; the client fires `ClientReady` once it has ground there,
  then the server spawns the character at home. Respawns go home too.
  (StreamingEnabled is on, so never move a character somewhere the
  client may not have streamed yet without waiting for it.)
- `src/first/LoadingScreen.client.luau` shows the loading screen and
  drives the steps above.
- `Build` has the shared part/prompt/sign/tree/lamp/fence helpers.
- Shared definitions: `Crops`, `Items` (stackables), `Trees`,
  `Blueprints`, `ShopCatalog`. Balance numbers live there.
- Client UI: `UI` helpers, `Toasts`, `ShopMenu`, `Inventory` (Bag, tabs
  via `Inventory.addTab`), `SeedBar` (crops + saplings), `PlotPrompts`.
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
- Run `scripts/check.sh` before pushing. It downloads the tools on first
  run, syntax-checks every file, and type-checks against the Roblox API
  (luau-lsp + Rojo sourcemap). Fix every TypeError it reports. The
  `LoadCharacter` deprecation warning is expected.
