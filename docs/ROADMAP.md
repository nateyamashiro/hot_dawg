# Roadmap — Steal a Glizzy 🌭

Milestones are ordered by what proves the game out fastest for a **go-big commercial** target.
Each should be independently testable in Studio. `✅ done · 🔜 next · ⏳ later · 🏗️ scaffolded (stub)`.

> **2026-07-07:** the entire remaining game (M3-remainder → M7) is **planned + scaffolded as
> compiling stubs** (DataStore `_v5`, `Variants`/`MenuLayout` shared modules, 11 new server services
> + `RateLimit`, 10 client tray panels, all wired into `Main`; real logic `TODO(<milestone>)`-marked).
> The `🏗️` items below now have skeletons to fill in — see `docs/HANDOFF.md` for the build order.
>
> **2026-07-08/09 shipped:** mutations-on-cook · prestige spending · fusion · then a **VISUAL OVERHAUL +
> CLASSIC-TYCOON pivot** (Nate, post-Studio look): bigger plots, walk-on-pad tycoon loop (cook station,
> passive stove, green/red upgrade pads), cook now gated (free single cook / 5-min cooldown; cook-10 =
> paid bypass), starting Common glizzy.
>
> **2026-07-09 shipped — THE DESIGN SYSTEM + BUILDING SHELL (plan
> `~/.claude/plans/i-want-you-to-wild-abelson.md`, phases P-A→P-E, all executed):** `Theme` tokens ·
> procedural `GlizzyModel` hot dogs (rarity fx ladder, variant looks, AI-mesh swap slot) ·
> `EnvironmentService` (noon lighting + street map + glizzy-land horizon) · 15-entry `BuildCatalog`
> + `BuildGrants` + `BuildService` end-to-end (🏗️/🎪 walk-on pads; DefenseService wall retired +
> grandfathered) · juice pass (`Celebrate` remote, `Sfx`, sounds config) · themed window UI
> (`MenuLayout` + `Build.client`).
>
> **2026-07-09 shipped — OVERHAUL PHASES 4+5 (playtest WAIVED by Nate):** conveyor street buy-lane
> (belt + prompt-to-buy glizzies at shop prices) · cooker upgrader (⚙️ pad → stove output mult) ·
> condiment blasters (🔫 buy/equip Tool; server-authoritative slow/knockback/stun near your own
> plot; never damage) · prestige zone expansion (🌍 pad; bigger pad + extra slots). **The whole
> visual overhaul + tycoon layer is code-complete.**
>
> **2026-07-09 shipped (same day) — M4 RETENTION + VAULT PINS + HARDENING:** weekly events real
> (deterministic week-index rotation; modifiers live in the actual math — income2x, cook-10 half
> price, Dog Rain free rolls; points from cooks/steals; reward-track claims) · leaderboards real
> (OrderedDataStore top-N coins/steals/rarest with name mapping + tabbed panel) · achievements real
> (validated one-time claims) · manual vault selection (📌 Dex pin toggle; pinned keys fill the
> vault first) · **the anti-exploit hardening pass** (RateLimit + arg guards on every legacy
> `OnServerEvent`; RequestState bursts coalesce).
>
> **2026-07-09 shipped — VISUAL POLISH + DEPLOYMENT READINESS:** grass z-fight fix · world-text
> de-soup to genre conventions · neon tamed (matte rule + softer bloom) · vendor-stand pedestals +
> 1.35× display glizzies · pick-up-and-hold (hand dogs snatchable through the full steal pipeline)
> · **data-safety criticals** (load-failure wipe → retry+kick; `_v5` back-fill de-nest; autosave;
> UpdateAsync stale guard; ProcessReceipt Robux-eater) · Telemetry (funnel + error logs) · shop
> daily cap · world podium · event-exclusive dogs (per-occurrence tracks). Launch checklist in
> `HANDOFF.md`.
>
> **2026-07-11 shipped — DEV CODE + STRETCH SESSION (Nate picked the full menu):** `NATE` dev code
> (1B coins, open + once-ever — ⚠️ delete before launch) · codes non-coin rewards (component
> tables: coins/dogs/prestige/mutation luck; `FREEGLIZZY` demo) · **steal-path mutations ON**
> (base dogs mint at deposit with the thief's luck) · traps polish + UI (🪤 buy button; Touched
> trigger; armed/re-arm visuals) · Tool.Grip initial pose (live tuning round with Nate owed) ·
> **onboarding first-60s** (server-derived stage; ring arrow + Highlight + tip banner) ·
> **M5 PurchaseService REAL** (Extra-slots + VIP passes, refund-safe `data.passes` derive-at-read
> model, ProcessReceipt product dispatch, Studio test overrides, panel real; ids still 0 —
> Nate's dashboard).
>
> **2026-07-11/12 shipped — THE ADDITIONS SESSION (all 17 `additions.txt` items):** plots grown to
> **76×58** (full relayout: 12-tall shell, floor2 y13/floor3 y26, 1.8× display dogs, 1240×60
> street) · real grill/stove models + a cosmetic spatula-flipping **chef** · **roofs** above the
> topmost floor · physical **odds board** per grill (HUD sidebar removed) + **spinner-strip cook
> reveal** landing on the server's roll · new top rarity **Forbidden** (15,000/s @ 0.01) ·
> income ladder steepened (payback falls with rarity) · **7 named floor-gated stove tiers**
> (→ Glizzy Factory 350/s) · cook cooldown **120s** + ready notify · storage-fraction HUD ·
> comma formatting everywhere (`Format.comma`) · rarity auto-sort (best dogs on the top floor) ·
> ⚠️ two locked-rule OVERRIDES (GDD §7): **Security Field** timed full-block (30s open / 300s,
> telegraphed) + **Vault Breaker** coin consumable (10s loud drill extracts ONE vault dog) ·
> full-street conveyor (≤18) + podium to the east plaza · **Glizzy Run obby** paying 100s of
> live income · `docs/CONTENT_PLAN.md` (clipfarm hookup plan). **NEXT: Studio smoke pass of the
> additions → M5 remainder (cosmetics + doubleCoins/autoCollect effects + offlineRefill) → M6
> trading + the published-place 2-account loop test.** See `docs/NEXT_SESSION_PROMPT.md`.

---

## ✅ Milestone 0 — Pro setup
VS Code + Rojo + Git + Rokit toolchain; server-authoritative project skeleton. *(Done.)*

## ✅ Milestone 1 — Cook & collect core
Coin-only gacha cook, 7 rarity tiers, idle income, DataStore persistence, HUD. *(Done, commit `4928f7c`.)*

## ✅ Design deep-dive (interview)
Worked through `docs/design/DISCOVERY_QUESTIONS.md`; answers recorded in `GAME_DESIGN.md §4`.
*(Done 2026-07-03.)*

## ✅ Milestone 2 — Steal & defend (THE hook)
The retention engine. Built 2026-07-03 (needs a 2-player Studio playtest to validate feel).
- Code-generated plots in a ring; dogs displayed as stealable pedestal units + safe vault
  (`PlotManager.luau`).
- Raid mechanic: approach → hold "Steal" ProximityPrompt → carry back to your own deposit pad
  (`StealService.luau`).
- Carry risk: slowed + red Highlight/glow + "🚨 THIEF!" marker; owner alerted with a directional
  arrow (`StealHud.client.luau`).
- Permanent ownership transfer on deposit; abort paths (death/leave/net) return the dog to the victim.
- Defense: default Net tool (tag a carrier → drop), buyable wall (adds steal hold-time), buyable
  NPC guard (auto-nets raiders even while away) (`DefenseService.luau`).
- Anti-grief: steal charges (recharge over time), per-target cooldown + diminishing returns,
  timed newbie shield.
- **Fast-follows:** ✅ Traps complete 2026-07-11 (🪤 buy button, Touched trigger, armed/re-arm
  visuals). ✅ Manual vault selection shipped 2026-07-09 (📌 pin in the Dex; `syncDisplay` fills
  pins first).
- *Ref: `docs/roblox-reference/gameplay/` (ProximityPrompt, Humanoid, CollectionService).*

## ✅ Milestone 3 — Progression & economy depth
Built 2026-07-03 (Top-10 items 5–10; static-clean, needs a Studio playtest to validate feel).
- **Buyable upgrades** — grill tiers (better roll odds), display slots (more stealable pedestals),
  vault slots (more safe storage). Cost curves + effect tables in `GameConfig`; capacity is now
  upgrade-derived and PlotManager pre-builds the max anchors (`UpgradeService.luau`).
- **Rebirth/prestige** — reset coins, keep dogs + upgrades, +25%/rebirth permanent income multiplier,
  bank prestige currency; `Rebirths` leaderstat (`RebirthService.luau`).
- **Capped offline earnings** — up to 8h of idle income granted on rejoin with a "welcome back" popup.
- **Dex UI** — grid of all dogs, locked silhouettes for undiscovered, one-time completion reward
  (`Dex.client.luau` + `InventoryUpdate` snapshot).
- **Cook-10 + pity + disclosed odds** — multi-roll, guaranteed Rare+ by `PityCooks`, full odds shown
  in the cook UI.
- **Daily streak + missions** — escalating login reward + 3 rotating missions (cook/steal/earn)
  (`DailyService.luau` + `Daily.client.luau`).
- **UI:** new bottom menu row (🛒 Upgrades · ✨ Rebirth · 📖 Dex · 📅 Daily) + a `RequestState`
  handshake so clients reliably get initial state past the join race.
- **Rotating shop** (2026-07-07) — buy specific dogs for coins; daily UTC rotation chosen
  deterministically server-side (same shop for everyone), per-rarity premium pricing, unlimited
  buys in v1 (`ShopService.luau` + `Shop.client.luau`). *(needs playtest.)*
- ✅ **Mutations / variants (2026-07-08)** — composite-key stacks (`Variants` + `MutationService`);
  `MutationChance` roll on cook mints Gold/Rainbow/Giant with income multipliers. Every read path is
  variant-aware (income, pedestals/vault, steal transfer, dex credit); the variant rides `CookResult`
  for a bigger reveal. *(static-clean; ✅ steal-path minting shipped 2026-07-11 — base dogs mint
  at deposit with the thief's luck.)*
- ✅ **Prestige spending (2026-07-08)** — first `prestige` sink (`PrestigeShopService`/`PrestigeShop.client`).
  One-time premium unlocks bought with banked prestige (never Robux): +10% permanent income, +1
  display slot, +1 vault slot, +50% mutation luck. Effects bank into `_v5` fields
  (`prestigeIncomeMult` → income loop, `bonus*Slots` → PlotManager capacity, `mutationLuck` →
  `maybeMint` — **closing the mutations `luckBonus` loop**). *(static-clean; needs playtest.)*
- 🏗️ **Scaffolded (stubs, 2026-07-07):** duplicates→fusion, manual vault selection, traps,
  shop per-day cap.
- **Data:** DataStore now `_v5` (2026-07-07 scaffold; batches all later fields, back-fills from
  `_v4`/`_v3`). Earlier M3 was `_v4`; shop itself added no fields.

## ✅ Milestone 4 — Retention systems ⭐ (shipped 2026-07-09; static-clean, not playtested)
- Daily login + daily missions. *(shipped early in M3 — see above.)*
- ✅ Weekly limited-time events — deterministic week-index rotation (all servers agree), modifiers
  wired into the REAL math (`income2x` → `Main.incomeMultiplier`, live + offline; `cookHalfPrice` →
  cook-10 batch price; `freeCookBursts` → Dog Rain: everyone online gets a free roll every 4 min),
  points from cooks (+10) and steals (+40), 4-tier reward track with batched claims
  (`EventService`/`Events.client` — banner, blurb, live countdown, tier rows).
  ✅ **Event-only dogs shipped 2026-07-09** — 3 exclusive Legendaries granted by final reward
  tiers; tracks keyed per occurrence so returning events are fresh.
- ✅ Achievements / milestone rewards — validated one-time claims (progress from existing
  counters/inventory), coin payouts, claim gated client-side + revalidated server-side
  (`AchievementService`/`Achievements.client` with progress bars).
- ✅ Leaderboards (coins / steals / rarest) via OrderedDataStore — periodic submit + cached top-N,
  UserId→name mapping (session-cached), rarest = best variant-scaled unit income
  (`LeaderboardService`/`Leaderboards.client` with three tabs + own-rank highlight).
- ✅ Codes system — complete 2026-07-11: non-coin rewards (component tables: coins / dogs /
  prestige / mutation luck, plain-number back-compat), `FREEGLIZZY` demo, `NATE` 1B dev code
  (⚠️ delete before launch).

## 🔨 Milestone 5 — Monetization (core SHIPPED 2026-07-11; cosmetics remain)
- ✅ Game passes — **Extra slots + VIP live** (refund-safe `data.passes` cache of
  `UserOwnsGamePassAsync`, effects derived at read time: capacity + VIP income; Studio test
  overrides while ids are 0; anchors bumped 18/8 so pass slots render). doubleCoins/autoCollect:
  detected, effects TODO(M5).
- ✅ Dev products via `ProcessReceipt` — coinsSmall/coinsLarge/stealCharges grant → mark receipt →
  PurchaseGranted; unmapped (incl. `offlineRefill`, bespoke logic pending) stay NotProcessedYet.
  **No paid gacha.** Both in `PurchaseService`/`Passes.client` (panel real: owned greys out,
  product buttons live). **Blocked on Nate:** dashboard ids.
- 🏗️ Cosmetics (stand skins, trails, titles) — `CosmeticService`/`Cosmetics.client`. **Next up.**
- ✅ **Anti-exploit hardening pass done early (2026-07-09):** every legacy `OnServerEvent`
  (cook/cook-10, daily claims, rebirth, shop, upgrades, defenses, vault pins) now behind
  `RateLimit.check` + arg guards; `RequestState` join bursts coalesce instead of dropping.
  *Ref: `docs/roblox-reference/monetization/`.*

## 🏗️ Milestone 6 — Social & virality (scaffolded — stubs to fill in)
- 🏗️ Trading (baseline safeguards: confirm + cooldown + log) — `TradeService`/`Trade.client`.
- 🏗️ Emotes/taunts (preset, no free text) — `EmoteService`. · Parties (join-friend) — later.
- Shareable "big steal / rare pull" moments engineered for clips (client juice on existing events).

## ⏳ Milestone 7 — Polish & soft launch
- AI-generated art pass, audio/SFX, UI polish. ✅ Onboarding first-60-seconds shipped 2026-07-11
  (guided arrows cook → stove → build; server-derived stage, zero UI for veterans).
- Icon + thumbnail (huge for CTR), store description, genre tags.
- Analytics goals, playtest with friends → public soft launch.
- *Ref: `docs/roblox-reference/publishing/`.*

---

### Guiding principle
Ship the **steal loop (M2)** before piling on content — it's what makes or breaks retention. Everything
after M2 is amplification. Validate fun with real players early and often.
