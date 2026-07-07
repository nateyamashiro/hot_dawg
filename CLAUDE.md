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
src/shared/GameConfig.luau     Tunables (economy + plots/steal/defense + M3 progression knobs)
src/shared/HotDogDex.luau      Roster (~30) + roll(grillLvl, guaranteeRare) + odds() + all() + sortedUnits
src/server/Main.server.luau    Orchestrator: remotes, leaderstats, income×rebirth, cook/cook-10,
                               offline earnings, dex reward, RequestState handshake, wires services
src/server/DataManager.luau    DataStore load/save + cache (PlayerData incl. M3 fields, _v4)
src/server/PlotManager.luau    Plots/stands, upgrade-derived pedestal/vault capacity, spawn CFrame, OwnerUserId attr
src/server/StealService.luau   Grab/carry/deposit/abort, charges, cooldowns, shield, alerts
src/server/DefenseService.luau Net tool, buyable wall + NPC guard
src/server/UpgradeService.luau Buy grill / display slots / vault slots
src/server/RebirthService.luau Rebirth: reset coins, keep dogs+upgrades, income multiplier + prestige
src/server/DailyService.luau   Daily login streak + rotating cook/steal/earn missions
src/client/UI.client.luau      Coins/dogs HUD, cook + cook-10, reveal, disclosed odds+pity, welcome-back
src/client/StealHud.client.luau  Carry banner, charge/shield meter, robbed alert + arrow, buy buttons
src/client/PlotPresentation.client.luau  Owner highlight/"YOUR STAND", rival label + own-prompt hiding
src/client/Menu.client.luau    Bottom menu row + Upgrades & Rebirth panels
src/client/Dex.client.luau     Collection grid (owned vs locked silhouettes)
src/client/Daily.client.luau   Streak + missions panel
docs/HANDOFF.md                Start-here handoff for a new session
docs/design/GAME_DESIGN.md     Living game design doc (GDD) — decisions in §4
docs/design/DISCOVERY_QUESTIONS.md  Question bank (COMPLETED; answers live in GDD §4)
docs/ROADMAP.md                Milestones
docs/roblox-reference/         Offline Roblox docs (see its README.md)
```

## Current status

**Milestones 1–3 built:** cook-and-collect core + steal-and-defend layer + the M3 progression
layer (buyable grill/display/vault upgrades, rebirth/prestige with an income multiplier, capped
offline earnings, dex UI, cook-10 + pity + disclosed odds, daily streak/missions), plus M2 clarity
polish (spawn-at-stand, owner-only presentation). DataStore is `_v4`. Static checks clean
(stylua/selene/rojo); **still needs a 2-player Studio playtest to validate feel + tune the reasoned
numbers in `GAME_DESIGN §6`.** Next up: playtest, then M3 remainder / M4 (rotating shop, prestige
spending, events, leaderboards, achievements). See HANDOFF.
