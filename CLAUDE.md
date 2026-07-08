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
src/shared/GameConfig.luau     Tunables (economy + plots/steal/defense + M3 progression + tycoon-layer: PlotPad*, AutoCookerTiers, BuildCatalog(15), WeaponTiers, Conveyor*, UpgraderTiers, ZoneTiers, CookCooldownSeconds, GlizzyMeshIds, SkyboxAssetId, Sounds)
src/shared/Theme.luau          THE design system (P-A): Palette (18 world colors) + Semantic + Materials/chunk rules + Lighting recipe + UI tokens (applyBounce/popOpen) + VFX budgets. Rarity colors stay in HotDogDex; variant colors in Variants.
src/shared/GlizzyModel.luau    Procedural hot-dog builder: 6-part model, rarity fx ladder, Gold/Secret recolors, SpecialMesh escape hatch (GlizzyMeshIds). Serves pedestals/vault/carry/rooftop/reveal viewport.
src/shared/BuildGrants.luau    Pure math over BuildCatalog + data.built: entry/category/nextEntry + displaySlot/cookerSlot/income bonuses (ALL grants derived at read time — never banked)
src/shared/Sfx.luau            Sfx.play(name, parent?) + startAmbient — silence-safe (no-ops while GameConfig.Sounds ids are "")
src/shared/HotDogDex.luau      Roster (~30) + roll(grillLvl, guaranteeRare) + odds() + all() + getByKey (variant-aware) + sortedUnits→{Unit} (key+variant income; drives pedestals/vault)
src/shared/Variants.luau       Mutations: composite-key encode/decode + income mult + pickMint (Gold/Rainbow/Giant)
src/shared/MenuLayout.luau     Bottom-row slot math + "⋯ More" tray + THEMED chrome (P-D): tokens, addChrome/styleButton/makePrimaryButton/themePanel, makeWindow (drag/minimize/close, Cream + ketchup-gradient bar); makePanel = makeWindow now
src/server/Main.server.luau    Orchestrator: remotes (+Celebrate), leaderstats, income×(rebirth+prestige+decor), cook (cookOne=cooldown-gated FREE)/cook-10 (paid),
                               offline earnings, dex reward, RequestState handshake, SetVaultPin, syncPads (incl. 🏗️/🎪 build pads)/setPadHandler/setCookHandler, wires ALL services
src/server/EnvironmentService.luau  Applies Theme.Lighting (noon + post fx + clouds) + builds the map (grass/street/dashes/sidewalks/lamps + P-E bun hills/mustard river/geyser). init() BEFORE PlotManager.build()
src/server/DataManager.luau    DataStore load/save + cache (PlayerData incl. M3 + _v5 fields incl. autoCookerLvl/built/weapons/upgraderLvl/zoneLvl/cookReadyAt; first-join starting-glizzy grant; defenses.wall→built.wall grandfather)
src/server/PlotManager.luau    Plots/stands + static floor-1 stall shell; capacity = upgrade level + bonus*Slots + BuildGrants floor slots; walk-on PAD framework (PAD_LAYOUT incl. build/decor, updatePads green-red), BUILDERS per catalog id + spawnStructure/rebuildStructures/setGateHandler, cook station, setStove, spawnUnit = GlizzyModel, spawn CFrame, OwnerUserId attr
src/server/StealService.luau   Grab/carry/deposit/abort (carry rig = welded GlizzyModel), charges, cooldowns, shield, alerts + stealAlarm/giantShake celebrates
src/server/DefenseService.luau Net tool + NPC guard + trap (wall RETIRED → BuildCatalog perimeter wall)
src/server/UpgradeService.luau Buy grill / display / vault slots — tryBuy() public (menu remote + walk-on pads share it)
src/server/RebirthService.luau Rebirth: reset coins, keep dogs+upgrades, income multiplier + prestige
src/server/DailyService.luau   Daily login streak + rotating cook/steal/earn missions
src/server/ShopService.luau    Rotating shop: deterministic daily offers, buy validation + coin charge
src/server/RateLimit.luau      Anti-exploit spine: per-player rate limiter + arg guards (used by new remotes)
src/server/MutationService.luau  maybeMint(name, luckBonus)→inventory key — random mutation on cook (WIRED into doCook; luckBonus fed from data.mutationLuck; steal path gated by MutateOnSteal, TODO)
src/server/PrestigeShopService.luau  Spend prestige on one-time premium unlocks (income%/±slots/mut-luck) — validate+charge, bank effects into _v5 fields
src/server/FusionService.luau  Combine N dupes → same dog one variant up the ladder (SHIPPED; Giant=top)
src/server/AutoCookerService.luau  Passive stove: coinsPerSecond + tryUpgrade (build 0→1 / upgrade); COINS only, never dogs (Phase 1 SHIPPED)
src/server/BuildService.luau   Base building SHIPPED (P-B): tryBuild/tryBuildNext (validate→charge→spawn→push), applyLoaded rebuild-on-join, wall hold bonus, gate slow rule
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
src/client/UI.client.luau      Coins/dogs HUD, cook + cook-10, reveal (variant-coloured + spinning GlizzyModel viewport), disclosed odds+pity, welcome-back
src/client/GlizzyFx.client.luau  Rainbow hue-cycle (10 Hz, ≤80 studs) + rarity-emitter culling (≤60 studs @ 1 Hz) for every DogUnit
src/client/Celebrate.client.luau Juice renderer (P-C): cook burst / purchase pop / build dust / steal alarm / Giant shake + coin-milestone 💰 sparkle + ambient bed
src/client/Build.client.luau   Build window (tray): catalog owned ✅ / buildable 🏗️ / locked 🔒 on BuildUpdate
src/client/StealHud.client.luau  Carry banner, charge/shield meter, robbed alert + arrow, guard buy button (wall button removed — the wall is a build now)
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

**VISUAL OVERHAUL + CLASSIC-TYCOON LAYER 2026-07-09, part 1** (Nate's direction after a Studio look;
plan `~/.claude/plans/inherited-hugging-alpaca.md`): **enlarged plots**; **new players start with 1
random Common glizzy**; **Phase 0 scaffold** (overhaul `GameConfig` blocks + `_v5` fields + 6 stub
services wired into `Main`); the **physical tycoon stations** — walk-on pad framework in `PlotManager`,
🌭 Cook Station, 🔥 Stove (passive un-stealable coins, folded into tick + offline income), walk-on
grill/display/vault upgrade pads, green/red affordability live via `Main.syncPads`. **Cook is
cooldown-gated:** single cook (button + station via `Main.cookOne`) is FREE but 5-min-gated; cook-10
stays the PAID bypass.

**DESIGN SYSTEM + BUILDING SHELL SHIPPED 2026-07-09** (design plan
`~/.claude/plans/i-want-you-to-wild-abelson.md`, ALL phases P-A→P-E executed):
- **P-A facelift:** `Theme.luau` tokens; `GlizzyModel.luau` procedural hot dogs everywhere (pedestals,
  vault, welded carry rig, rarity fx ladder, Gold/Rainbow/Giant, SpecialMesh swap slot
  `GameConfig.GlizzyMeshIds` — deliberate: MeshPart.MeshId isn't runtime-scriptable);
  `EnvironmentService` (bright-noon lighting recipe + street/ground map); `GlizzyFx.client`
  (Rainbow hue-cycle + emitter culling); plot recolor pass onto `Theme.Palette`.
- **P-B building shell:** `BuildCatalog` 15 entries (structural chain + 9 income decors, +27% total
  for ~25,050); `BuildGrants.luau` (grants derived at READ time from `data.built` — rebuild-on-join
  can't double-apply); floor-1 stall shell static on every plot; `BUILDERS` in `PlotManager` obeying
  the locked theft-access rules (wall's 16-stud gap permanent, gate slows never blocks, floor-3 truss
  + everyone-elevator); `BuildService` full validate→charge→spawn→push; 🏗️/🎪 pads offer ONE item
  each; **DefenseService wall retired** (grandfathered `built.wall` in `DataManager.load`).
- **P-C juice:** `Celebrate` remote → `Celebrate.client` (cook burst by rarity + stingers, purchase
  pop, build dust, 3-flash steal alarm, Giant camera shake), `Sfx.luau` + `GameConfig.Sounds` (all ""
  = silence-safe until Nate picks ids), coin-milestone sparkle, cook-reveal viewport spin.
- **P-D UI restyle:** `MenuLayout` owns the Theme.UI chrome; `makePanel` = `makeWindow` (every tray
  panel became a draggable Cream window with ketchup-gradient bar); all panels swept off dark-slate
  onto MenuLayout tokens; old 🛒 Upgrades menu restyled + kept as the pad fallback; NEW
  `Build.client` window; `MenuLayout.TRAY` gains "Build".
- **P-E:** bun-hill horizon, mustard river, ketchup geyser (EnvironmentService).

Static checks clean (stylua/selene/rojo). **NOT pushed (Nate said don't push). Still owes the
2-player Studio playtest** for M2/M3 + tycoon layer + full build chain + `GAME_DESIGN §6` tuning —
that's the #1 next action, then conveyor/upgraders (Phase 4) and weapons/zones (Phase 5). See
`docs/NEXT_SESSION_PROMPT.md` + HANDOFF.
