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
> visual overhaul + tycoon layer is code-complete. NEXT: M4 retention (events/leaderboards/
> achievements real logic) + manual vault + the hardening pass.** See `docs/NEXT_SESSION_PROMPT.md`.

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
- **Fast-follows (deferred within M2):** traps, manual vault selection.
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
  for a bigger reveal. *(static-clean; steal-path minting still TODO — mutation-luck now wired.)*
- ✅ **Prestige spending (2026-07-08)** — first `prestige` sink (`PrestigeShopService`/`PrestigeShop.client`).
  One-time premium unlocks bought with banked prestige (never Robux): +10% permanent income, +1
  display slot, +1 vault slot, +50% mutation luck. Effects bank into `_v5` fields
  (`prestigeIncomeMult` → income loop, `bonus*Slots` → PlotManager capacity, `mutationLuck` →
  `maybeMint` — **closing the mutations `luckBonus` loop**). *(static-clean; needs playtest.)*
- 🏗️ **Scaffolded (stubs, 2026-07-07):** duplicates→fusion, manual vault selection, traps,
  shop per-day cap.
- **Data:** DataStore now `_v5` (2026-07-07 scaffold; batches all later fields, back-fills from
  `_v4`/`_v3`). Earlier M3 was `_v4`; shop itself added no fields.

## 🏗️ Milestone 4 — Retention systems ⭐ (scaffolded — stubs to fill in)
- Daily login + daily missions. *(shipped early in M3 — see above.)*
- 🏗️ Weekly limited-time events + event-only dogs (FOMO) — `EventService`/`Events.client`.
- 🏗️ Achievements / milestone rewards — `AchievementService`/`Achievements.client`.
- 🏗️ Leaderboards (coins / rarest / most steals) via OrderedDataStore — `LeaderboardService`/`Leaderboards.client`.
- 🏗️ Codes system (creator marketing lever) — `CodesService`/`Codes.client` (mostly complete).

## 🏗️ Milestone 5 — Monetization (scaffolded — stubs to fill in)
- 🏗️ Game passes — **Extra slots + VIP first**, then 2× coins / auto-collect (non-pay-to-win).
- 🏗️ Dev products (coin packs, refills, extra charges) via `ProcessReceipt`. **No paid gacha.**
  Both in `PurchaseService`/`Passes.client`.
- 🏗️ Cosmetics (stand skins, trails, titles) — `CosmeticService`/`Cosmetics.client`.
- **Do the anti-exploit hardening pass here (before M6 + launch).** *Ref: `docs/roblox-reference/monetization/`.*

## 🏗️ Milestone 6 — Social & virality (scaffolded — stubs to fill in)
- 🏗️ Trading (baseline safeguards: confirm + cooldown + log) — `TradeService`/`Trade.client`.
- 🏗️ Emotes/taunts (preset, no free text) — `EmoteService`. · Parties (join-friend) — later.
- Shareable "big steal / rare pull" moments engineered for clips (client juice on existing events).

## ⏳ Milestone 7 — Polish & soft launch
- AI-generated art pass, audio/SFX, UI polish, onboarding/first-60-seconds.
- Icon + thumbnail (huge for CTR), store description, genre tags.
- Analytics goals, playtest with friends → public soft launch.
- *Ref: `docs/roblox-reference/publishing/`.*

---

### Guiding principle
Ship the **steal loop (M2)** before piling on content — it's what makes or breaks retention. Everything
after M2 is amplification. Validate fun with real players early and often.
