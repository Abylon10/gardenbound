# Gardenbound — Project Context

Roblox game by ABYLON_01 (Justin Dave). Solo for now.

- Scripts are Luau, synced into Studio with Rojo (`default.project.json`).
  Rojo version is pinned in `rokit.toml`.
- `src/server` → ServerScriptService.Server, `src/client` →
  StarterPlayerScripts.Client, `src/shared` → ReplicatedStorage.Shared.
- Suffixes: `.server.luau` Script, `.client.luau` LocalScript, `.luau` ModuleScript.
- Only code lives here. Parts/terrain/models live in the Studio place file.
- Studio's built-in MCP server is enabled, so a local Claude Code/Desktop
  can also edit the open place directly. Cloud sessions can only edit
  files in this repo.
- Use tabs for indentation in Luau.
