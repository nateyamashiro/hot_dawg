# Game Design Document — Steal a Glizzy 🌭

> **Living doc.** Update as decisions get made. `✅` = locked. Keep this the single source of
> truth for *what* we're building; `CLAUDE.md` covers *how* (tech/workflow).

**Last updated:** 2026-07-09 · **Status:** Milestones 1–3 + M3-remainder (rotating shop,
**mutations-on-cook**, **prestige spending**, **fusion**) BUILT & static-clean. Now mid **VISUAL
OVERHAUL + CLASSIC-TYCOON LAYER** (Nate's post-Studio direction; approved plan at
`~/.claude/plans/inherited-hugging-alpaca.md`): bigger plots, a **walk-on-pad tycoon loop** (cook
station, passive **stove**, upgrade pads coloured green/red by affordability), **cook now gated** (free
single cook on a 5-min cooldown; cook-10 = paid bypass), starting Common glizzy. **M4–M7 still
scaffolded as compiling stubs.** Awaiting a 2-player Studio playtest. NEXT: the building shell —
build pads that grow the plot INTO a stand (`BuildService`/Phase 3).

---

## 1. Pitch

A **steal-and-defend idle tycoon**: cook and collect absurd hot dogs across rarity tiers, watch
them generate coins, and **raid rival stands** to steal their best dogs — while defending your own.
Same proven loop as *Steal a Brainrot* (acquire → grow → defend → steal), wrapped in an ownable
hot-dog theme riding the "hot dog summer" TikTok wave.

**Core fantasy:** *"I hoard absurd hot dogs, flex my stand, and sprint off with my rival's rarest
glizzy while they chase me."* Emotion sold = **greed / hoarding**, with a **silly-but-competitive**
tone. The signature TikTok clip we design toward = **the big steal** (grab a rival's Secret-tier
dog and escape the chase).

## 2. Locked decisions ✅

| Area | Decision |
|---|---|
| Genre | Steal-and-defend idle tycoon |
| Theme | Hot dogs; 7 rarity tiers Common → Secret |
| Name | **"Steal a Glizzy"** (locked as working+launch title; recheck moderation/availability pre-launch) |
| Ambition | Go big / commercial — optimize for growth, retention, monetization |
| Audience | Everyone / Gen Alpha core (all-ages content) |
| Monetization stance | Passes + dev products + cosmetics OK; **gacha "cook" rolls are coin-only, never Robux** |
| Pay line | **All dogs & real power stay free-earnable.** Robux buys convenience/cosmetics only (non-pay-to-win). |
| Art pipeline | AI-generated in Studio (mesh / 4D generation) |
| Core retention bet | The **steal-and-defend loop** (theme is marketing, loop is retention) |

## 3. Core loop

```
        cook / earn                     raid rivals
   coins ─────────► hot dogs ──────────────────────► steal better dogs
     ▲                 │                                     │
     └──── idle income ◄── dogs generate coins/sec ◄─────────┘
                          (and you must DEFEND them)
```

Cooking and stealing are **co-equal** paths to rare dogs — players can lean either way.

---

## 4. Design decisions (from 2026-07-03 deep-dive)

### 4.1 Steal & defend loop ⭐ (the retention engine)
- **Steal mechanic:** walk up → hold a **ProximityPrompt** to grab the dog → **physically carry it
  back to your base**. (Classic Steal-a-Brainrot.)
- **Carry risk:** thief is **slowed**, has a **visible marker/glow**, and the **owner is alerted**
  (with location).
- **Defense (all of these):** buyable **walls/locks**, placeable **traps**, hired **NPC guards**
  (work while away), and **presence + tagging** (be there to tag/stop thieves).
- **Conflict style:** **light non-lethal tools** — nets, freeze rays, banana peels to slow/stun.
  No knockout combat. All-ages friendly, on-theme silly.
- **Unattended bases ARE raidable**, but a **vault protects your best dogs** (limited safe slots);
  everything on display is exposed, and defenses still function while you're away.
- **Stolen dog = permanent transfer** (thief keeps it, victim loses it). Highest stakes/drama.
- **Anti-grief:** **per-target cooldown** (can't re-farm one victim) + **steal energy/charges**
  (recharge over time) + **diminishing returns** on repeat-raiding the same base.
- **Newbie protection:** **timed shield** — new players un-raidable for an early playtime window.

### 4.2 Bases / plots
- **Shared map with roaming spawns** — bases placed around one shared world (raidable live);
  layout can shift per session. (Required for live steal-and-defend.)
- **Base form:** starts as a humble **hot dog stand** (evolves visually as you upgrade).
- **Display capacity:** **limited visible display slots (stealable) + a protected vault** of hidden
  safe slots. Display slots are a deliberate upgrade wall.
- **Customization:** **light cosmetics** (a few unlockable skins/colors) — monetization + flex hook.

### 4.3 Economy & progression
- **Currency:** **coins** (everyday) **+ a prestige currency** (from rebirths/events → premium unlocks).
- **Rebirth:** **classic rebirth** — reset coins, **keep dogs/collection**, gain a permanent income
  multiplier + prestige currency.
- **Offline earnings:** **yes, capped** (earn while away up to a cap).
- **Coin sinks:** cook rolls, base/slot upgrades, defenses, better grills.

### 4.4 Collection & rarity
- **Keep 7 tiers** (Common → Secret). Already built.
- **Duplicates stack for income** (no fusion at launch).
- **Mutations/variants** (Gold, Rainbow, Giant) — **later milestone**, not launch.
- **Roster:** **~30 dogs at launch** (up from 14), growing steadily via content drops.
- **Limited dogs:** **mix** — permanent core roster + rotating **event/seasonal** dogs (FOMO).
- **Dex:** **full dex UI** with locked silhouettes for undiscovered dogs + completion rewards.
- **Naming:** **food puns + meme mix** (e.g. "Glizzy Gladiator", "Rizz Dog"). Shareable, on-trend.

### 4.5 Cook / gacha (coin-only, locked)
- **Flat cook cost + grill upgrades** — better grills improve odds / unlock higher tiers
  (grills = a key coin sink + progression axis).
- **Single roll + multi-roll (cook 10) + pity** (guaranteed rare after N cooks).
- **Odds disclosed** openly in-UI (trust; coin-only so no legal issue).
- **Cook + rotating shop** — mostly cook, but a rotating shop sells specific dogs for coins
  (targeted goal + reduces pure-RNG frustration).

### 4.6 Map & world
- **~15–20 players per server** (lively raiding without chaos).
- **World theme:** **surreal "glizzy-land"** (mustard rivers, bun mountains) — distinctive/shareable.
- **World mechanic:** periodic **rush events** (double income / dog rain / discount cook) to spike activity.

### 4.7 Retention systems ⭐
- **Daily login streak + daily missions** (cook X, steal Y, earn Z).
- **Leaderboards:** rarest dog/best collection, most steals, most coins (richest).
- **Weekly themed events** with event-only dogs, modifiers, and leaderboards (core live-ops + FOMO).
- **Battle-pass-style track — free lane only** at launch (add premium lane later).
- **Achievements/milestones** (collect N, 100 steals, rebirth X) with rewards — non-RNG goals.
- **Codes system** — yes, but **later** (when marketing/creator outreach starts).

### 4.8 Social & multiplayer
- **Trading — yes, but LATER**, with confirm screens, trade logs, dupe/scam safeguards. Not day one.
- **Parties:** launch with simple **"join friend's server"**; formal co-op raid/defense later.
- **Expression:** **preset emotes + taunts** (no free-text risk; celebrate steals, rib rivals).
- **Clans/alliances:** **later milestone.**

### 4.9 Onboarding — first 60 seconds
- New player is **gifted a starter dog** on spawn (stand isn't empty; instant ownership), then
  learns to cook.
- **Guided tutorial** — short scripted first run (cook → place → steal) with prompts, then let go.
- **First steal opportunity within the first few minutes** (guided first steal in tutorial, then
  real PvP after the newbie shield).

### 4.10 Monetization (passes/products OK; gacha stays coin-only; nothing pay-to-win)
- **Game passes:** 2× coins, auto-collect, extra base slots, VIP perks.
- **Dev products:** coin packs, offline-cap refill/boost, extra steal charges, name/cosmetic tokens.
- **Cosmetics:** stand skins, trails/auras, cosmetic pets/followers.
- **Fairness:** every dog and all real power is **earnable free**; Robux = convenience + cosmetics only.

### 4.11 Fairness & anti-exploit
- Server stays **authoritative** (architecture rule, non-negotiable). **Heavier anti-cheat
  hardening** (deep validation, rate-limits, anomaly logging) is **deferred** — do features first,
  harden **before public launch / before trading ships**.
  > ⚠️ Flag: because the economy + trading are central, plan at least *basic* server-side sanity
  > checks as we build, so hardening later isn't a rewrite.

### 4.12 Art & audio direction (AI-generated art, locked)
- **Visual style:** **blocky/voxel** (native Roblox feel, cheap, thumbnail-friendly).
- **Palette:** **bright & poppy** (ketchup-and-mustard, high CTR).
- **Audio:** **goofy & hype** — playful loops, punchy SFX, hype stingers on rare pulls/steals.
- **UI:** **sticker-bomb meme** — chunky, colorful, emoji/sticker-heavy, bouncy buttons.

### 4.13 Branding & scope
- **Name:** **"Steal a Glizzy"** (locked).
- **Thumbnail/icon concept:** **big steal action shot** — character sprinting off with a giant
  glowing hot dog, rival chasing. (Finalize in polish; A/B later.)
- **Soft-launch MVP:** **core loop + steal + basics** — cook, ~30 dogs, shared-map plots,
  steal-and-defend, dex, dailies, rebirth, a couple of game passes. Enough to prove retention.
- **Team:** **solo** (Nate + Claude). Simple main-branch workflow, no PR overhead.

---

## 5. Built so far ✅
**Milestone 1 — cook & collect**
- **Rarity roster** — 7 tiers, now ~30 dogs, weighted roll (`HotDogDex.luau`).
- **Cook/gacha** — coin-only roll, server-authoritative, rarity reveal.
- **Idle income** — coins/sec = Σ owned dogs' rates.
- **Persistence** — per-player DataStore save/load (now `_v3` with steal/defense fields).
- **HUD** — coins + dogs count, cook button.

**Milestone 2 — steal & defend** (2026-07-03; see ROADMAP for detail)
- **Plots** — code-generated ring of stands with stealable pedestals + safe vault (`PlotManager.luau`).
- **Steal loop** — grab-carry-deposit, permanent transfer, all abort paths (`StealService.luau`).
- **Defense** — Net tool, buyable wall + NPC guard (`DefenseService.luau`).
- **Anti-grief** — steal charges, per-target cooldown + diminishing returns, newbie shield.
- **Steal HUD** — carry banner, charge/shield meter, robbed alert + directional arrow,
  buy-defense buttons (`StealHud.client.luau`).
- **M2 clarity polish** (2026-07-03) — spawn beside your own stand; owner-only highlight +
  "🏠 YOUR STAND" banner; rival stands hide Vault/Deposit labels (keep stealable dogs visible);
  Steal prompt hidden on your own dogs (`PlotPresentation.client.luau`).

**Milestone 3 — progression & economy depth** (2026-07-03; static-clean, playtest owed)
- **Buyable upgrades** — grill tiers (roll odds), display + vault slots (`UpgradeService.luau`);
  capacity is upgrade-derived, PlotManager pre-builds max anchors.
- **Rebirth/prestige** — reset coins, keep dogs + upgrades, +25%/rebirth income, prestige currency
  (`RebirthService.luau`); `Rebirths` leaderstat.
- **Capped offline earnings** — up to 8h idle granted on rejoin with a welcome-back popup.
- **Dex** — full grid, locked silhouettes, one-time completion reward (`Dex.client.luau`).
- **Cook-10 + pity + disclosed odds** — multi-roll, guaranteed Rare+ by pity, odds shown in-UI.
- **Daily streak + missions** — escalating login reward + 3 rotating missions (`DailyService.luau`,
  `Daily.client.luau`).
- **Menu UI** — bottom row (Upgrades/Rebirth/Dex/Daily) + `RequestState` join-race handshake.
- **Persistence** — DataStore now `_v4` (all new fields back-filled from `_v3`).

**Milestone 3-remainder — mutations / variants** (2026-07-08; first scaffolded feature made real)
- **Composite-key inventory** — a hot dog is stored under a key that may encode a mutation
  (`"Chicago Dog"` base, `"Chicago Dog#Gold"` variant); `hotDogs` stays `{ [string]: number }`, so
  old saves are valid and no DataStore bump was needed (`src/shared/Variants.luau`).
- **Random mint on cook** — each cook has a `GameConfig.MutationChance` to mint Gold/Rainbow/Giant
  (weighted by `Variants` mint weights) instead of base, via `MutationService.maybeMint` in `doCook`.
- **Variant income** — Gold ×2 / Rainbow ×3.5 / Giant ×5 on top of the base dog's rate; all read
  paths are variant-aware (`HotDogDex.getByKey`/`sortedUnits`, income, pedestal/vault sort + labels,
  steal transfer, dex-completion collapses keys to base names).
- **Reveal** — the variant rides `CookResult`; the client plays a bigger, variant-coloured reveal and
  a "✨ N mutations!" note on cook-10.
- *Still open:* steal-path minting (`MutateOnSteal`, off by default). *(Mutation-luck now wired via prestige.)*

**Milestone 3-remainder — prestige spending** (2026-07-08; `PrestigeShopService`/`PrestigeShop.client`)
- **First `prestige` sink** — rebirths (+1 each) and the dex reward (+3) bank prestige; this is the
  first thing to spend it on. Catalog is `GameConfig.PrestigeShopItems` (one-time premium unlocks,
  **coin/prestige only, never Robux**): +10% permanent income, +1 display slot, +1 vault slot,
  +50% mutation luck.
- **One-time unlocks** — tracked in the new `prestigeUnlocks` set; the server validates the item +
  balance, charges prestige, marks it owned, and applies the persistent effect. Client greys out
  owned rows and shows the live prestige balance + afford state (tray panel).
- **Effects bank into `_v5` fields** — `prestigeIncomeMult` (folded additively into
  `Main.incomeMultiplier` alongside the rebirth bonus), `bonusDisplaySlots`/`bonusVaultSlots` (now
  honoured by `PlotManager` capacity, re-synced on buy), and `mutationLuck` (passed as the `luckBonus`
  arg of `MutationService.maybeMint` — **closing the loop the mutations feature stubbed**).
- No DataStore `_vN` bump — the three new fields batch into the existing `_v5` back-fill.

**Milestone 3-remainder — fusion** (2026-07-08; `FusionService`/`Fusion.client`)
- **Duplicate sink** — `Fuse(key)` consumes `GameConfig.FusionInputs` (5) of one inventory key and
  grants ONE of the same base dog **one variant up the mutation ladder**: `base → Gold → Rainbow →
  Giant`. So 5 plain → 1 Gold, 5 Gold → 1 Rainbow, etc. Gives spare dupes a purpose + a second path
  to mutations besides the cook roll.
- **Composite-key aware** — operates on keys via the live `Variants` layer, so already-mutated stacks
  fuse too. The ladder step is a new shared helper `Variants.nextVariant`; **Giant is the top** (no
  higher variant → server refuses, client hides the row).
- **Server-authoritative** — validates the player owns ≥`FusionInputs` of the key, consumes them
  (clearing an emptied stack to nil), grants the result, then `updateLeaderstats` + `syncDisplay` +
  `pushInventory`. Rate-limited (`RateLimit.check`, 5/win). Client previews the result per fusable key
  in the "⋯ More" tray panel; single-click fuses.
- No DataStore change at all — fusion only moves counts inside the existing `hotDogs` map.
- **Design fork (see §7):** shipped the *force-mutation ladder*; the alternative (upgrade one rarity
  tier) is deferred — it needs a `HotDogDex` "next dog up a tier" helper that doesn't exist yet.

**Scaffolded 2026-07-07 (compiling STUBS — architecture only, real logic is `TODO`-marked)**
The full M3-remainder → M7 build is planned + skeleton-laid: `Variants` (composite-key mutation
layer) + `MenuLayout` (shared bottom-row/"⋯ More" tray) shared modules; `RateLimit` anti-exploit
util; server stubs for prestige-spend, fusion, mutation-mint, events, leaderboards (OrderedDataStore),
achievements, codes, purchases (passes+products), cosmetics, trading, emotes; matching client tray
panels; `defenses.trap` (4th defense, ~complete) + `vaultPins` (manual vault, handler in `Main`).
DataStore bumped `_v4` → `_v5` (one migration batching every later field; `hotDogs` unchanged).
Static-clean; each stub names where real logic goes. See `docs/HANDOFF.md` for the build order.

**Visual overhaul + classic-tycoon layer — IN PROGRESS 2026-07-09** (approved plan at
`~/.claude/plans/inherited-hugging-alpaca.md`; Nate's direction after a Studio look). The game is
being reshaped from menu-driven into a **physical walk-on-pad tycoon**:
- **Bigger plots** (60×46 pad) with a front apron of walk-on pads; **new players start with 1 random
  Common glizzy** (granted only on first join in `DataManager.load`, so a dog-less returning player is
  never re-granted).
- **Walk-on pad framework** (`PlotManager.makeBuyPad`/`PAD_LAYOUT`/`updatePads`): owner-only, debounced
  Touched pads that show a cost and are **GREEN when affordable / RED when too expensive** (live each
  tick). `Main.syncPads` computes labels/affordability; `setPadHandler` routes the purchase.
- **🌭 Cook Station** — a ProximityPrompt grill on the stand; cooking is now a *place*, not just a
  button (both share `Main.cookOne`).
- **🔥 Stove (passive income)** — a SEPARATE machine from the gacha cook that emits **un-stealable
  coins** (never dogs). Starts UNBUILT (`autoCookerLvl 0`); built + upgraded via a walk-on pad
  (`AutoCookerService.tryUpgrade`); income folded into the tick loop AND offline earnings.
- **Grill/display/vault upgrades are now walk-on pads too** (reuse `UpgradeService.tryBuy`; the old
  on-screen menu stays as a redundant fallback).
- **Cook gated:** the single cook is FREE but on a **5-min cooldown** (`CookCooldownSeconds` /
  `data.cookReadyAt`) — the "wall" that slows glizzy acquisition and rewards longer/returning play.
  **Cook-10 stays PAID** (`CookCost`×10) as the "pay to skip the wait / bulk" bypass.
- Scaffolded-but-stubbed for the remaining phases: `BuildService` (the building shell — floors/stairs/
  elevator/walls/gate via build pads, **NEXT**), `ConveyorService`, `UpgraderService`, `WeaponService`
  (non-damaging), `ZoneService`, and `MenuLayout.makeWindow` (drag/minimize/close, for the UI migration).

## 6. Current tuning values (from `GameConfig.luau` / `HotDogDex.luau`)

**Economy**
- Tick interval: 1s · **Starting coins: 100** · Cook cost: 10 (flat, coin-only)
- Rarity → income/sec: Common 1, Uncommon 3, Rare 8, Epic 20, Legendary 55, Mythic 150, Secret 500
- Rarity → roll weight: **100 / 40 / 12 / 4 / 1.5 / 0.4 / 0.06** (total ≈ 157.96)
  - P(Rare-or-better) per cook ≈ **11.4%** → expected first Rare in ~9 cooks. With 100
    starting coins (~10 cooks) + early idle income, a fresh player should hit their first Rare
    inside the opening minute or two — "earned, not guaranteed."

**Steal / defend**
- Steal hold: 3s (+2s with a wall) · Carry speed: **10** vs normal 16 (slow enough to chase,
  fast enough that a clean getaway feels earnable)
- Steal charges: 5 max, one back every 45s (full refill ~225s)
- Per-target cooldown: 120s + diminishing returns (×1.5 hold per repeat raid) · Newbie shield: 600s
- Net: 3s stun, 12-stud range · Wall: 250 coins (+2s hold) · Guard: 600 coins, scans every 1.5s

**Plots**
- 20 plots, two rows, 42-stud spacing, 128-stud street · 8 display (stealable) + 3 vault slots

> ⚠️ **These are reasoned values, not yet playtest-confirmed.** The 2026-07-03 tuning pass adjusted
> starting coins (50→100), carry speed (9→10), and the rare-tier roll weights to hit the "first Rare
> in a couple minutes / satisfying-but-not-trivial steal" targets *by math*. A live 2-player Studio
> playtest is still owed to confirm the loop *feels* right (esp. steal hold vs. chase distance,
> charge/cooldown cadence, and defense costs relative to income).

**Progression (M3, `GameConfig.luau`) — also reasoned, playtest owed**
- Grill Lv1–6: cost 0 / 500 / 2.5k / 10k / 40k / 150k; Rare+ weight ×1.0 / 1.4 / 1.9 / 2.6 / 3.6 / 5.0
- Display slots Lv1–5: 8 / 10 / 12 / 14 / 16 (cost 0 / 750 / 3k / 12k / 50k) · max anchors 16
- Vault slots Lv1–4: 3 / 4 / 5 / 6 (cost 0 / 1.5k / 8k / 35k) · max anchors 6
- Rebirth: cost `5000 × 2.5^rebirths`; +25% income per rebirth; +1 prestige each
- Offline cap: 8h · Cook-10: 10 rolls · Pity: guaranteed Rare+ after 20 cooks without one
- Dex completion: +25,000 coins, +3 prestige (one-time)
- Daily streak rewards: 100→2500 over 7 days · 3 missions/day from a 6-mission pool

**Rotating shop (M3 remainder, `GameConfig.luau`) — also reasoned, playtest owed**
- 6 distinct dogs per rotation · refresh every 24h (UTC), chosen deterministically by day index
  so every player/server sees the same shop that day
- Shop rarity draw weights (flatter than cook odds): Common 30 · Uncommon 30 · Rare 20 · Epic 12 ·
  Legendary 5 · Mythic 2 · Secret 0.5
- Prices by rarity: Common 150 · Uncommon 500 · Rare 1.8k · Epic 6k · Legendary 22k · Mythic 75k ·
  Secret 300k. Payback (price ÷ income/s) rises 150s→600s with rarity, so the shop is a
  "pay for certainty" premium, never the coin-efficient path (cooking stays cheaper per coin).
- v1 = unlimited buys, no new persisted fields. Per-rotation purchase cap deferred (would need `_v5`).

**New scaffold config (all reasoned placeholders, `GameConfig.luau`) — tune when each feature lands**
- Mutations: `MutationChance` 0.04 · variant income mults Gold ×2 / Rainbow ×3.5 / Giant ×5
  (mint weights 100/30/8 in `Variants.luau`) · `MutateOnSteal` false
- Prestige shop (**shipped 2026-07-08**): 4 one-time unlocks 5–15 prestige (income +10% / +1 display /
  +1 vault / +50% mut-luck). Effects are permanent + additive; income folds into the rebirth multiplier.
- Fusion: `FusionInputs` 5, forces a mutation · Trap: 450 coins, 4s stun, 10-stud range
- Events: weekly rotation, 3 modifiers, reward tiers 100/300/700/1500 · Leaderboards: top-25, 60s refresh
- Achievements: 5 goals (collect 10/30, steal 25/100, rebirth 3) · Codes: LAUNCH 1000, GLIZZY 500
- Passes/products: ids 0 (unconfigured) · extra-slots +2 display/+1 vault · VIP +10% income · 2× coins
- Cosmetics: 3 items (10–25 prestige) · Trade: 30s cooldown, ≤6 items · Emotes: 5 presets

**Tycoon layer (overhaul, all reasoned placeholders — tune in playtest)**
- Plot pad: 60×46 · row spacing 96 · row separation (street) 124
- Cook cooldown: **300s (5 min)** free single cook · cook-10 stays `CookCost`×10 = 100 coins
- Auto-cooker stove tiers (cost / coins-sec): **0/1**, 400/3, 2000/8, 9000/20, 35000/50
- Cooker upgrader tiers (cost / output×): 0/1.0, 2500/1.25, 12000/1.6, 60000/2.0
- Build catalog: floor2 1500, stairs 400, floor3 6000, elevator 8000, wall 1200, gate 3000
- Weapons (non-damaging): mustard-slow 800, ketchup-knockback 4000, relish-stun 15000
- Conveyor: spawn every 6s, ≤8 on belt · Zones (prestige): 0, 5, 15

## 7. Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-02 | Hot dog theme, not brainrot clone | Ownable IP; brainrot saturated & moderation-risky |
| 2026-07-02 | Gacha rolls coin-only | Sidesteps Roblox paid-random-item rules; keeps it fair |
| 2026-07-02 | AI-generated art | Fast, on-theme, low art-skill barrier |
| 2026-07-02 | Go-big commercial ambition | Prioritize retention/virality systems in roadmap |
| 2026-07-03 | Full design deep-dive locked (§4) | Answered the discovery bank; unblocks Milestone 2 |
| 2026-07-03 | Steal = grab & carry back, permanent transfer, vault-protected best dogs | Proven Steal-a-Brainrot loop + clear stakes with a fairness relief valve |
| 2026-07-03 | Shared map, roaming spawns, ~15–20/server | Required for live raiding at a lively-not-chaotic density |
| 2026-07-03 | Rebirth keeps dogs, resets coins | Long-term retention without nuking the collection chase |
| 2026-07-03 | MVP = core loop + steal + basics | Prove retention before piling on content |
| 2026-07-03 | M3 built: upgrades, rebirth (keeps upgrades too), offline cap, dex, cook-10+pity, dailies | Progression depth + retention loops; DataStore → `_v4` |
| 2026-07-03 | Prestige currency banked but not yet spendable | Premium unlocks are a later milestone; field exists so rebirth already feels rewarding |
| 2026-07-08 | **Prestige unlocks are ONE-TIME** (not repeatable/stacking) | Matches "owned/afforded" UI; bounded bonuses (esp. slots stay within the pre-built anchor cap); simplest correct first sink — deeper/repeatable sinks can be added to the catalog later |
| 2026-07-08 | **Prestige income unlock = new additive `prestigeIncomeMult` field** folded into `Main.incomeMultiplier` | No existing knob fit (rebirth mult is derived from the rebirth count); a dedicated field is cheap in the income loop and keeps a player's purchased bonus stable if config changes |
| 2026-07-07 | Rotating shop: daily, deterministic-by-UTC-day offers, coin-only, premium priced, unlimited buys v1 | Targeted goal that dampens pure-cook RNG; same shop for everyone = fair + shareable; premium prices keep cooking the coin-efficient path; unlimited-buy avoided a DataStore migration (cap is a fast-follow) |
| 2026-07-07 | **Mutations = composite-key stacks** (`"Name#Gold"` inside the existing `{name→count}` map) | Lowest-risk model: `hotDogs` type unchanged, old saves valid as base dogs, tested steal/shop/dex/income keep working on strings — interpretation isolated in `Variants.luau`. Serves mutations + fusion + manual-vault + stack-trading without per-unit IDs |
| 2026-07-07 | **Mutations minted randomly on cook** (small weighted chance; steal opt-in via `MutateOnSteal`) | Slot-machine excitement folded into the existing roll; no new currency. Gold/Rainbow/Giant chosen by `Variants` mint weights |
| 2026-07-07 | **First game passes = Extra slots + VIP** (then 2× coins + auto-collect) | Clear non-p2w convenience; sequences `PurchaseService` work |
| 2026-07-07 | **Trading safeguards = baseline** (two-sided confirm + post-trade cooldown + server trade log) | Solid anti-scam floor; value-diff warning / escrow deferred as later hardening |
| 2026-07-07 | **One `_v5` migration batches ALL later fields** (M3-remainder → M6) | Single migration beats five; empty defaults are harmless; keeps `defaultData()` authoritative |
| 2026-07-07 | Whole M3-remainder → M7 **scaffolded as compiling stubs** (no full logic) | Establishes the architecture so later sessions implement feature-by-feature against a stable, static-clean skeleton |
| 2026-07-08 | **Fusion = force-mutation ladder** (5 dupes of a key → 1 same base dog one variant up: base→Gold→Rainbow→Giant) over "upgrade a rarity tier" | Self-contained, reuses the live `Variants` layer, deterministic (enables a client result preview), handles already-mutated stacks; tier-upgrade needs a `HotDogDex` "next dog up" helper that doesn't exist yet |
| 2026-07-09 | **Pivot to a physical walk-on-pad TYCOON** (Nate, after a Studio look): plot starts bare → walk-on pads build/upgrade → it grows into a stand; cook/upgrades become physical stations | The game "looked bad" + lacked genre-standard tycoon dopamine (droppers, base-building). Matches Steal-a-Brainrot/classic-tycoon leaders; pads are more legible + satisfying than menus |
| 2026-07-09 | **Auto-cooker stove = COINS only, un-stealable, SEPARATE from the gacha cook**; starts unbuilt | Gives a passive income FLOOR without touching the steal-defend loop (only display dogs are stealable); building it via a pad is the first satisfying tycoon purchase |
| 2026-07-09 | **Single cook FREE but on a 5-min cooldown** (the "wall"); **cook-10 stays PAID + ungated** (the bypass) | Slows glizzy spam → rewards return visits / long sessions (Nate's ask); cook-10 gives impatient/rich players a coin-priced skip, so coins still matter. Open: revisit cook-10 if cook is rebalanced |
| 2026-07-09 | **Walk-on pads coloured green (affordable) / red (too expensive)**, refreshed each income tick | Immediate legibility of what you can buy; server-authoritative (affordability computed in `Main.syncPads`), cheap for ~4 pads |
| 2026-07-09 | **Weapons will be NON-DAMAGING** (slow/knockback/stun), never HP/damage | All-ages / Gen-Alpha tone + lower moderation risk; still adds defense-loop counterplay |
| 2026-07-09 | **UI overhaul = shared-window upgrade** (`makeWindow` drag/minimize/close + toolbar), NOT a full rebuild | Reuses working panels; incremental + lower regression risk than retiring all 16 GUIs at once |
