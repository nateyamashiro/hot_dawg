# tycoon-sim

A simulator/tycoon starter built with the professional Roblox workflow:
**VS Code + Rojo + Git**, with server-authoritative economy logic.

## What it does (the vertical slice)

- Passive coin income every second (`GameConfig.TickInterval`).
- A **Buy Upgrade** button that spends coins to boost income — validated
  entirely on the server, so it can't be exploited.
- Persistent saves via DataStore across sessions.
- Coins + upgrade level shown on the leaderboard (`leaderstats`) and in a
  simple on-screen UI.

## Toolchain (managed by Rokit — see `rokit.toml`)

| Tool | Purpose |
|------|---------|
| `rojo`   | Syncs `src/*.luau` into Roblox Studio live |
| `stylua` | Formats Luau on save |
| `selene` | Lints Luau |

Run `rokit install` after cloning to fetch pinned tool versions.

## Project layout

```
src/
  shared/   -> ReplicatedStorage.Shared   (code both sides use)
  server/   -> ServerScriptService.Server (authoritative logic)
  client/   -> StarterPlayerScripts.Client (UI only, untrusted)
```

The `src -> Roblox service` mapping lives in `default.project.json`.

## Daily workflow

1. In this folder, start the sync server:
   ```
   rojo serve
   ```
2. In Roblox Studio, open the **Rojo** plugin toolbar and click **Connect**.
3. Edit `.luau` files in VS Code. Save = instantly synced into Studio.
4. Press **Play** in Studio to test. Iterate.

## Testing DataStores in Studio

DataStore saves only work in Studio if you enable
**Game Settings → Security → Enable Studio Access to API Services**.
Until then the game runs fine but starts from default data each session.

## Enabling coins to actually save

Because saves fire on player-leave and server-shutdown, use Studio's **Stop**
button (not closing the window) to trigger `BindToClose` and persist data.
