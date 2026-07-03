# CLAUDE.md — Steal a Glizzy 🌭

> Auto-loaded context for any Claude Code session working in this repo.
> **New session? Read `docs/HANDOFF.md` first, then this file.**

## What this is

A **steal-and-defend tycoon** for Roblox in the *Steal a Brainrot* mold, themed around
**collecting hot dogs** across rarity tiers. Working title **"Steal a Glizzy"**.
Repo name: `hot_dawg`. GitHub: `https://github.com/nateyamashiro/hot_dawg`.

The core insight driving every design choice: *the meme theme is the marketing, but the
**steal-and-defend loop** is the retention.* We copy that proven mechanical formula and wrap
it in an ownable hot-dog theme (deliberately NOT cloning brainrot IP — saturated & moderation-risky).

## Locked decisions (as of 2026-07-02)

| Decision | Value |
|---|---|
| Genre | Steal-and-defend idle tycoon |
| Theme | Hot dogs, 7 rarity tiers (Common → Secret) |
| Ambition | **Go big / commercial** — optimize for growth, retention, monetization |
| Monetization | Passes + dev products + cosmetics OK. **Gacha "cook" rolls are COIN-ONLY, never Robux** (avoids Roblox paid-random-item rules) |
| Art | **AI-generated in Studio** (mesh/4D generation) |
| Audience | Everyone / Gen Alpha core (all-ages content) |

## Workflow & tooling (already set up)

- **Editor:** VS Code + luau-lsp, StyLua, Selene, Rojo extensions.
- **Toolchain:** Rokit-managed, binaries at `~/.rokit/bin/` — `rojo` 7.7.0, `stylua`, `selene`. Run `rokit install` after a fresh clone.
- **Sync:** `rojo serve` (in project root) → Studio Rojo plugin → **Connect**. Live-syncs `src/*.luau`.
- **Validate before committing:** `~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx` and `~/.rokit/bin/selene.exe src/`. These are AUTHORITATIVE — the luau-lsp errors in PostToolUse diagnostic snapshots are often transient noise (it flags `:` type annotations before it re-parses; ignore if rojo build + selene pass).

## Architecture rules (enforce these)

- **Server is authoritative.** ALL economy/inventory/roll logic lives in `src/server`
  (→ `ServerScriptService`). The client NEVER decides coins, rolls, or ownership.
- **Client is untrusted UI.** `src/client` (→ `StarterPlayerScripts`) only displays state and
  fires RemoteEvents to request actions.
- **Shared code** in `src/shared` (→ `ReplicatedStorage`): config + data tables both sides read.
- Folder → Roblox service mapping lives in `default.project.json`.
- Format with StyLua (tabs, 100 col), keep Selene clean, `--!strict` at top of every file.

## Where things are

```
src/shared/GameConfig.luau     Tunables (tick rate, starting coins, cook cost)
src/shared/HotDogDex.luau      The hot dog roster + weighted rarity roll
src/server/Main.server.luau    Entry point: income loop, cook handler, leaderstats, remotes
src/server/DataManager.luau    DataStore load/save + in-memory cache
src/client/UI.client.luau      Coins/dogs HUD, cook button, rarity reveal
docs/HANDOFF.md                Start-here handoff for a new session
docs/design/GAME_DESIGN.md     Living game design doc (GDD)
docs/design/DISCOVERY_QUESTIONS.md  Question bank for the design deep-dive
docs/ROADMAP.md                Milestones
docs/roblox-reference/         Offline Roblox docs (see its README.md)
```

## Current status

**Milestone 1 done:** cook-and-collect core (idle income, coin-only gacha roll, rarity reveal,
DataStore persistence). **Next up is the design deep-dive interview** (see HANDOFF), THEN
Milestone 2 = the base-plot stealing layer.
