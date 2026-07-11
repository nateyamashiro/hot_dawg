# Backlog — Steal a Glizzy 🌭

Living list of remaining work, most-impactful first. Milestones 1 & 2 are built (see
`ROADMAP.md` / `GAME_DESIGN.md §4-5`). This is the running "items that need to be completed."

**Legend:** ✅ = shipped (static-clean; playtest owed). Priority reflects the chosen focus.

---

## 🔨 VISUAL OVERHAUL + CLASSIC-TYCOON LAYER (current focus, 2026-07-09)

Approved plan: `~/.claude/plans/inherited-hugging-alpaca.md` · phase order in `docs/NEXT_SESSION_PROMPT.md`.
- ✅ Enlarged plots · ✅ starting Common glizzy · ✅ Phase-0 scaffold (config + `_v5` fields + 6 stub
  services + `makeWindow`).
- ✅ Walk-on **pad framework** + **🌭 cook station** + **🔥 stove (passive income)** + grill/display/vault
  **upgrade pads** (green/red by affordability).
- ✅ Cook **gated**: free single cook on a 5-min cooldown; cook-10 = paid bypass.
- ✅ **Design system + facelift (P-A):** `Theme.luau` tokens · procedural `GlizzyModel` hot dogs
  (rarity fx ladder, Gold/Rainbow/Giant, `GlizzyMeshIds` AI-mesh swap slot) · `EnvironmentService`
  (noon lighting + street/ground) · `GlizzyFx.client` (Rainbow cycle + culling) · plot recolor.
- ✅ **Building shell (`BuildService`, P-B):** 15-entry catalog (structural chain + 9 income decors),
  `BuildGrants` read-time grants, floor-1 stall shell, per-id BUILDERS (truss theft access, teleport
  elevator, slow-only gate), 🏗️/🎪 pads, wall moved from DefenseService (grandfathered).
- ✅ **Juice (P-C):** `Celebrate` remote (bursts/pops/alarm/Giant shake) · `Sfx` + `GameConfig.Sounds`
  (ids owed by Nate) · coin sparkle · cook-reveal viewport.
- ✅ **UI restyle (P-D):** themed `MenuLayout` windows everywhere · `Build.client` window · old
  Upgrades menu restyled + kept as fallback (locked decision #6).
- ✅ **Glizzy-land horizon (P-E):** bun hills · mustard river · ketchup geyser.
- ✅ **Phase 4 conveyor + upgrader:** street belt with prompt-to-buy glizzies (shop weights/prices)
  · ⚙️ upgrader pad multiplying stove output.
- ✅ **Phase 5 weapons + zones:** 🔫 blaster tray window + Tool (server-authoritative slow/knockback/
  stun near your own plot, never damage) · 🌍 prestige zone pad (bigger pad + extra slots).
- ⚠️ **Playtest WAIVED by Nate 2026-07-09** — no live validation has run; all §6 tuning is
  reasoned-not-observed. Revisit if anything feels off in Studio later.
- ⏳ Nate asset passes (zero code): `GameConfig.Sounds` ids · `GlizzyMeshIds` meshes · `SkyboxAssetId`.

---

## ✅ Done — the 2026-07-03 Top 10 (M2 clarity + M3 progression)

All ten shipped and pass `stylua`/`selene`/`rojo build`. Still owe a live 2-player Studio playtest.

1. ✅ Spawn at your own stand + owner-only highlight + "🏠 YOUR STAND" banner.
2. ✅ Owner-only structural info (rival Vault/Deposit labels hidden; stealable dogs still visible).
3. ✅ Hide the "Steal" prompt on your own dogs.
4. ✅ Balance/tuning pass (`GameConfig` + `HotDogDex` weights; documented in `GAME_DESIGN §6`).
5. ✅ Buyable upgrades — grill / display slots / vault slots (`UpgradeService.luau`).
6. ✅ Rebirth / prestige loop (`RebirthService.luau`, `Rebirths` leaderstat).
7. ✅ Capped offline earnings + welcome-back popup.
8. ✅ Dex / collection UI + one-time completion reward (`Dex.client.luau`).
9. ✅ Cook-10 + pity + disclosed odds.
10. ✅ Daily login streak + daily missions (`DailyService.luau`, `Daily.client.luau`).

New files: `src/client/PlotPresentation.client.luau`, `src/client/Menu.client.luau`,
`src/client/Dex.client.luau`, `src/client/Daily.client.luau`, `src/server/UpgradeService.luau`,
`src/server/RebirthService.luau`, `src/server/DailyService.luau`. DataStore bumped `_v3` → `_v4`.

---

## 🔜 Top of the list now

- **M5 remainder** — cosmetics (`CosmeticService`/`Cosmetics.client`; catalog in
  `GameConfig.Cosmetics`) · doubleCoins/autoCollect pass EFFECTS (detection already runs) ·
  `offlineRefill` dev product (bespoke offline-cap refill; keep its dashboard id unset until then).
- **M6 trading** (`TradeService`; baseline safeguards locked: confirm + cooldown + log).
- **Nate:** create pass/product ids on the Creator Dashboard (unblocks end-to-end M5 testing) ·
  Tool.Grip live tuning round in Studio · the published-place 2-account loop test ·
  ⚠️ delete the `NATE` code before public launch.

## ✅ Shipped 2026-07-11 (dev code + stretch session; static-clean)

- **`NATE` dev code** — 1B coins for progression testing (open + once-ever by Nate's call;
  flagged delete-before-launch in config + the HANDOFF launch checklist).
- **Codes non-coin rewards** — `GameConfig.Codes` entries may be
  `{ coins?, dogs?, prestige?, mutationLuck? }` tables (plain numbers back-compat); dogs ride
  composite keys; empty/invalid rewards refund the redemption mark; `FREEGLIZZY` demo code.
- **Steal-path mutations ON** — `MutateOnSteal = true`; stolen BASE dogs roll `maybeMint` at
  deposit with the THIEF's mutation luck; mutated loot transfers as-is; upgraded mint toast.
- **Traps polish + UI** — 🪤 buy button beside Guard in StealHud; `Touched` trigger replaces the
  poll (owner-exempt, carriers only); sprung pad greys for 6s (`TrapRearmSeconds`) then re-arms
  Neon red; `TrapRange` retired.
- **Tool.Grip initial pose** — held glizzies point forward, settled in the palm (was sideways
  default); live tuning round with Nate owed.
- **Onboarding first-60s** — server-derived stage (cook → stove → build → done) from existing
  fields, `OnboardingUpdate` push; `Onboarding.client` ring arrow + Highlight + tip banner.
- **M5 monetization core** — see the M5 section below.

## ✅ Shipped since the Top 10 (static-clean; playtest owed)

- **Prestige spending** (2026-07-08) — first `prestige`-currency sink (`PrestigeShopService`/`PrestigeShop.client`).
  One-time premium unlocks bought with banked prestige (never Robux): +10% permanent income, +1 display
  slot, +1 vault slot, +50% mutation luck. Effects bank into new `_v5` fields — `prestigeUnlocks`
  (owned set), `prestigeIncomeMult` (folded into `Main.incomeMultiplier`), `mutationLuck` (fed to
  `MutationService.maybeMint`, **closing the mutations `luckBonus` loop**); slot effects bump the
  existing `bonus*Slots` fields, now honoured by `PlotManager` capacity. Client renders the catalog +
  live prestige balance + owned/afforded state (tray panel). No `_vN` bump (fields batch into `_v5`).
- **Mutations / variants** (2026-07-08) — random Gold/Rainbow/Giant mint on cook (`GameConfig.MutationChance`),
  composite-key inventory (`"Name#Gold"` in the existing `hotDogs` map). Made every read path
  variant-aware: `HotDogDex.getByKey`, `sortedUnits→{Unit}` (carries the key), `Main.incomePerSecond`,
  dex-completion (collapses keys to base names), `PlotManager`/`StealService` (key-based transfer +
  variant labels/tint), and a variant-coloured `CookResult` reveal. No DataStore bump.
  ✅ **Steal-path minting shipped 2026-07-11.** *(Real `luckBonus` wired — prestige banks `mutationLuck`.)*
- **Rotating shop** (2026-07-07) — buy specific dogs for coins (targeted goal, dampens pure-cook RNG).
  Daily UTC-rotating offer set chosen deterministically server-side (same shop for everyone),
  per-rarity premium pricing, unlimited buys in v1. New: `src/server/ShopService.luau`,
  `src/client/Shop.client.luau`; `BuyFromShop`/`ShopUpdate` remotes; bottom menu row now 5 buttons.
  **No DataStore bump** (buying just adds to `hotDogs`). **Fast-follow:** per-rotation purchase cap
  (needs a `_v5` field to track buys/day) + a "featured" jumbo slot.

---

## 🏗️ Scaffolded 2026-07-07 — stubs exist for everything below

The full **M3-remainder → M7** build is planned + skeleton-scaffolded (compiling stubs, real logic
`TODO(<milestone>)`-marked; DataStore `_v5`; static-clean). Each item below now has a service/client
to fill in — see `docs/HANDOFF.md` for the build order + the composite-key/mutation gotcha. Implement
feature by feature, don't re-architect.

**M2 fast-follows**
- ✅ Traps **complete 2026-07-11** — buy button + Touched trigger + armed/re-arm visuals.
- ✅ Manual vault selection **shipped 2026-07-09** — `PlotManager.syncDisplay` fills pinned keys
  into the vault first, then tops up by value; 📌 toggle on owned Dex tiles flips the whole dog
  family (base + variants) with an explicit desired state; pins ride `InventoryUpdate`; only owned
  keys are pinnable.

**M3 remainder** (rotating shop + mutations + prestige spending shipped; ✅ per-day cap **shipped
2026-07-09** — 3/offer/day, lazy `shopBuys` reset, "X/3 today" in-panel)
- ✅ Duplicates → fusion **shipped 2026-07-08** (`FusionService`/`Fusion.client`) — 5 dupes of a
  key → same base dog one variant up the ladder (`Variants.nextVariant`; Giant = top).

**M4 retention** (daily streak/missions already shipped in M3)
- ✅ Weekly events **shipped 2026-07-09** — deterministic week rotation; modifiers live (income2x /
  cook-10 half price / Dog Rain free rolls every 4 min); points per cook (+10) & steal (+40);
  4-tier reward track, claims batched. ✅ **Event-only dogs shipped same day** — 3 exclusive
  Legendaries via final tiers; points/claims now keyed per OCCURRENCE (`"id@week"`), so returning
  events offer fresh tracks (+ re-earnable dog = fusion food).
- ✅ Achievements/milestones **shipped 2026-07-09** — validated one-time claims + coin payouts;
  panel gates claims + shows progress bars.
- ✅ Leaderboards **shipped 2026-07-09** — OrderedDataStore top-N (coins/steals/rarest), rarest =
  best variant-scaled unit income ×100, session name cache; tabbed panel, own-rank highlight.
- ✅ Codes system **complete 2026-07-11** — non-coin rewards + `FREEGLIZZY` + `NATE` dev code
  (⚠️ delete before launch). · Free battle-pass track — later.

**M5 monetization** (all non-pay-to-win; gacha stays coin-only)
- ✅ Game passes **shipped 2026-07-11** — Extra slots + VIP live (refund-safe `data.passes`
  derive-at-read model; Studio overrides while ids are 0; anchors 18/8). doubleCoins/autoCollect
  effects still TODO.
- ✅ Dev products via `ProcessReceipt` **shipped 2026-07-11** — coin packs + steal charges;
  `offlineRefill` bespoke logic still TODO (keep its id unset).
- 🏗️ Cosmetics: stand skins, trails/auras, titles (`CosmeticService`/`Cosmetics.client`) — **next.**

**Social (later)** — 🏗️ trading (baseline safeguards, `TradeService`/`Trade.client`), 🏗️ emotes
(`EmoteService`), parties/co-op, clans.

**Hardening / infra** — ✅ the **FULL** pass **shipped 2026-07-09**: every `OnServerEvent` in the
codebase is behind `RateLimit.check` + type/length arg guards (cook, cook-10, daily claims,
rebirth, shop, upgrades, defenses, vault pins); `RequestState` join bursts COALESCE into one
deferred push instead of being dropped (the ~15-scripts-fire-on-join handshake stays intact).
Trading (M6) is now unblocked on this front.
✅ **Deployment readiness shipped 2026-07-09** — data-safety criticals (load-retry+kick, `_v5`
de-nest, autosave, UpdateAsync stale guard, ProcessReceipt fix), `Telemetry` (onboarding funnel +
error logs), world podium; launch checklist in `HANDOFF.md §Launch checklist`.
Still later: anomaly logging (`RateLimit` TODO), full session locking, StreamingEnabled
evaluation, AI-gen art pass, icon/thumbnail (Nate), onboarding first-60s (design), soft launch.
