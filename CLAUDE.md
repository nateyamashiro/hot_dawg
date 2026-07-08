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

## Handoff ritual (do this at every milestone / when you hand off) ⭐

This is a solo main-branch project (GDD §4.13). When you finish a coherent feature that leaves the
game in a **working, validated state** (or you're low on context), before ending the session:
1. **Validate** — stylua + selene + `rojo build` all clean (never hand off a red build).
2. **Update docs** — `HANDOFF.md`, `ROADMAP.md`, `BACKLOG.md`, `GAME_DESIGN.md` (§5/§6/§7), and this
   file's code map + status.
3. **Rewrite `docs/NEXT_SESSION_PROMPT.md`** for the next session (point it at the next feature; keep
   this ritual intact so it self-perpetuates).
4. **Commit and push to `main`** — pushing at milestone handoffs is **standing authorization** for
   this project. Commit locally as you go mid-feature; push at the handoff. (Full detail lives in
   `docs/NEXT_SESSION_PROMPT.md §"Handoff ritual"`.)

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
src/shared/GameConfig.luau     Tunables (economy + plots/steal/defense + M3 progression + tycoon-layer: PlotPad*, AutoCookerTiers, BuildCatalog, WeaponTiers, Conveyor*, UpgraderTiers, ZoneTiers, CookCooldownSeconds)
src/shared/HotDogDex.luau      Roster (~30) + roll(grillLvl, guaranteeRare) + odds() + all() + getByKey (variant-aware) + sortedUnits→{Unit} (key+variant income; drives pedestals/vault)
src/shared/Variants.luau       Mutations: composite-key encode/decode + income mult + pickMint (Gold/Rainbow/Giant)
src/shared/MenuLayout.luau     Bottom-row slot math + "⋯ More" tray + makeTrayToggle/makePanel + makeWindow (drag/minimize/close) client helpers
src/server/Main.server.luau    Orchestrator: remotes, leaderstats, income×rebirth (+stove), cook (cookOne=cooldown-gated FREE)/cook-10 (paid),
                               offline earnings, dex reward, RequestState handshake, SetVaultPin, syncPads/setPadHandler/setCookHandler, wires ALL services
src/server/DataManager.luau    DataStore load/save + cache (PlayerData incl. M3 + _v5 fields incl. autoCookerLvl/built/weapons/upgraderLvl/zoneLvl/cookReadyAt; first-join starting-glizzy grant)
src/server/PlotManager.luau    Plots/stands (config-sized), capacity = upgrade level + bonus*Slots; walk-on PAD framework (makeBuyPad/PAD_LAYOUT/updatePads green-red), cook station, setStove, spawn CFrame, OwnerUserId attr
src/server/StealService.luau   Grab/carry/deposit/abort, charges, cooldowns, shield, alerts
src/server/DefenseService.luau Net tool, buyable wall + NPC guard + trap (4th defense)
src/server/UpgradeService.luau Buy grill / display / vault slots — tryBuy() public (menu remote + walk-on pads share it)
src/server/RebirthService.luau Rebirth: reset coins, keep dogs+upgrades, income multiplier + prestige
src/server/DailyService.luau   Daily login streak + rotating cook/steal/earn missions
src/server/ShopService.luau    Rotating shop: deterministic daily offers, buy validation + coin charge
src/server/RateLimit.luau      Anti-exploit spine: per-player rate limiter + arg guards (used by new remotes)
src/server/MutationService.luau  maybeMint(name, luckBonus)→inventory key — random mutation on cook (WIRED into doCook; luckBonus fed from data.mutationLuck; steal path gated by MutateOnSteal, TODO)
src/server/PrestigeShopService.luau  Spend prestige on one-time premium unlocks (income%/±slots/mut-luck) — validate+charge, bank effects into _v5 fields
src/server/FusionService.luau  Combine N dupes → same dog one variant up the ladder (SHIPPED; Giant=top)
src/server/AutoCookerService.luau  Passive stove: coinsPerSecond + tryUpgrade (build 0→1 / upgrade); COINS only, never dogs (Phase 1 SHIPPED)
src/server/BuildService.luau   Base-building structures via walk-on pads (floors/stairs/elevator/walls/gate) (STUB — Phase 3, NEXT)
src/server/WeaponService.luau  Non-damaging condiment blasters (slow/knockback/stun a carrying thief) (STUB — Phase 5)
src/server/ConveyorService.luau  Street buy-lane: hot dogs ride a belt, step to buy (STUB — Phase 4)
src/server/UpgraderService.luau  Cooker upgrader: outputMultiplier on stove output (STUB — Phase 4)
src/server/ZoneService.luau    Prestige-gated plot/zone expansion (STUB — Phase 5)
src/server/EventService.luau   Weekly deterministic event + modifier + reward track (STUB)
src/server/LeaderboardService.luau  OrderedDataStore top-N (coins/steals/rarest) (STUB)
src/server/AchievementService.luau  Milestone goals + one-time rewards (STUB)
src/server/CodesService.luau   Redeem promo codes for coins (mostly complete)
src/server/PurchaseService.luau  Passes + dev products via ProcessReceipt (STUB; Extra-slots+VIP first)
src/server/CosmeticService.luau  Stand skins / trails / titles (STUB)
src/server/TradeService.luau   Two-sided confirm trade + cooldown + log (STUB; ships after hardening)
src/server/EmoteService.luau   Validated preset-emote relay/broadcast (STUB)
src/client/UI.client.luau      Coins/dogs HUD, cook + cook-10, reveal (variant-coloured mutation reveal), disclosed odds+pity, welcome-back
src/client/StealHud.client.luau  Carry banner, charge/shield meter, robbed alert + arrow, buy buttons
src/client/PlotPresentation.client.luau  Owner highlight/"YOUR STAND", rival label + own-prompt hiding
src/client/Menu.client.luau    Bottom menu row + Upgrades & Rebirth panels
src/client/Dex.client.luau     Collection grid (owned vs locked silhouettes)
src/client/Daily.client.luau   Streak + missions panel
src/client/Shop.client.luau    Rotating-shop panel: 6 offers, buy buttons, refresh countdown
src/client/More.client.luau    "⋯ More" primary button — toggles the secondary-panel tray
src/client/PrestigeShop.client.luau  Prestige-spend panel (tray): catalog + live balance + owned/afforded rows
src/client/Fusion.client.luau  Fuse-duplicates panel (tray; STUB)
src/client/Events.client.luau  Weekly-event panel (tray; STUB)
src/client/Leaderboards.client.luau  Top-N ranks panel (tray; STUB)
src/client/Achievements.client.luau  Milestone goals panel (tray; STUB)
src/client/Codes.client.luau   Promo-code entry panel (tray)
src/client/Passes.client.luau  Passes & perks panel (tray; STUB)
src/client/Cosmetics.client.luau  Cosmetics wardrobe panel (tray; STUB)
src/client/Trade.client.luau   Trade window panel (tray; STUB)
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
polish (spawn-at-stand, owner-only presentation) and the rotating shop.

**M3-remainder → M7 SCAFFOLD laid down 2026-07-07** (static-clean, stubs only — no full logic).
The full remaining game is planned (`docs/design/plan` mirror + GDD §7) and its architecture now
exists as compiling skeletons: `DataStore bumped to _v5` (all later fields batched, `hotDogs`
unchanged — **mutations use composite keys** `"Name#Gold"` via `Variants.luau`); new services
(Prestige/Fusion/Event/Leaderboard/Achievement/Codes/Purchase/Cosmetic/Trade/Emote/Mutation) +
`RateLimit`; new client tray panels behind "⋯ More"; all wired into `Main` (remotes + init +
pushAllState). **Real logic is TODO(<milestone>)-marked in each stub** — implement feature by
feature. Four forks locked this session: composite-key inventory · random mutations on cook/steal ·
Extra-slots+VIP passes first · baseline trade safeguards (GDD §7).

**Mutations-on-cook SHIPPED 2026-07-08** (first scaffolded feature made real): every inventory
read path is now variant-aware (`HotDogDex.getByKey`/`sortedUnits→{Unit}`, `Main.incomePerSecond`,
dex ownership collapses composite keys to base names, `PlotManager`/`StealService` carry the key +
show variant labels), and `MutationService.maybeMint` is wired into `doCook` so a `GameConfig.MutationChance`
roll mints Gold/Rainbow/Giant; the variant rides `CookResult` for a bigger reveal. Steal-path minting
(`MutateOnSteal`, off) remains TODO.

**Prestige spending SHIPPED 2026-07-08** (next scaffolded feature made real): `PrestigeShopService`
validates + charges banked `prestige` for one-time premium unlocks (`GameConfig.PrestigeShopItems`:
+10% income / +1 display / +1 vault / +50% mutation luck), banking effects into three new `_v5`
fields — `prestigeUnlocks` (owned set), `prestigeIncomeMult` (folded additively into
`Main.incomeMultiplier`), `mutationLuck` (now fed as `maybeMint`'s `luckBonus`, **closing the
mutations loop**); slot unlocks bump `bonus*Slots`, now honoured by `PlotManager` capacity. The client
tray panel renders catalog + live balance + owned/afforded rows. No `_vN` bump.

**Fusion SHIPPED 2026-07-08** (5 dupes of a key → 1 of the same base dog one variant up the ladder,
via `Variants.nextVariant`; Giant is the top; `Fusion.client` previews the result).

**VISUAL OVERHAUL + CLASSIC-TYCOON LAYER — IN PROGRESS 2026-07-09** (Nate's direction after a Studio
look; approved plan at `~/.claude/plans/inherited-hugging-alpaca.md`). Done so far: **enlarged plots**;
**new players start with 1 random Common glizzy** (first-join grant in `DataManager.load`); **Phase 0
scaffold** — overhaul `GameConfig` blocks + `_v5` fields (`autoCookerLvl`, `built`, `weaponsOwned`,
`weaponEquipped`, `upgraderLvl`, `zoneLvl`, `cookReadyAt`) + 6 compiling stub services
(AutoCooker/Build/Weapon/Conveyor/Upgrader/Zone) wired into `Main` + `MenuLayout.makeWindow`
(drag/minimize/close) skeleton; and the **physical tycoon stations** — a reusable **walk-on pad
framework** in `PlotManager` (`makeBuyPad`/`updatePads`/`setStove`/`setPadHandler`/`setCookHandler`),
a **🌭 Cook Station**, a **🔥 Stove** (passive un-stealable coins; starts unbuilt at `autoCookerLvl 0`;
built/upgraded via a pad; folded into tick + offline income), **walk-on grill/display/vault upgrade
pads** (reuse `UpgradeService.tryBuy`) coloured **green affordable / red too-expensive** live via
`Main.syncPads`. **Cook is now cooldown-gated:** single cook (button + station via `Main.cookOne`) is
FREE but 5-min-gated (`CookCooldownSeconds`/`cookReadyAt`); cook-10 stays the PAID bypass.

Static checks clean (stylua/selene/rojo). **NOT pushed. Still owes the 2-player Studio playtest** for
M2/M3 + the new tycoon layer + `GAME_DESIGN §6` tuning. **Next up: the building shell — walk-on build
pads that grow the plot INTO a stand (`BuildService`/Phase 3)**, then UI-window migration (Phase 2),
conveyor/upgraders (Phase 4), weapons/zones (Phase 5). See `docs/NEXT_SESSION_PROMPT.md` + HANDOFF.
