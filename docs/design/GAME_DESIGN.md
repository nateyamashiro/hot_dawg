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
- ✅ *Steal-path minting shipped 2026-07-11* (`MutateOnSteal` on; base dogs only, thief's luck).
  *(Mutation-luck wired via prestige.)*

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
- Scaffolded-but-stubbed for the remaining phases: `ConveyorService`, `UpgraderService`,
  `WeaponService` (non-damaging), `ZoneService`.

**Design system + building shell — SHIPPED 2026-07-09** (plan
`~/.claude/plans/i-want-you-to-wild-abelson.md`, all phases P-A→P-E):
- **`Theme.luau` design tokens** — ketchup-and-mustard world palette (18 colors), semantic state
  colors, material/chunk rules, the bright-noon lighting recipe, UI tokens (Cream panels /
  ketchup-gradient bars / FredokaOne / bounce), VFX restraint budgets. Rarity colors stay in
  `HotDogDex`, variant colors in `Variants` (single sources preserved).
- **Procedural glizzies** (`GlizzyModel.luau`) — sausage + buns + mustard zigzag on every pedestal /
  vault slot / carry rig; rarity fx ladder (Neon drizzle → lights → sparkles/embers/smoke, ≤1
  emitter per dog, pedestals only, culled past 60 studs); Gold/Rainbow/Giant looks (Rainbow is
  hue-cycled client-side); `GameConfig.GlizzyMeshIds` = the zero-code AI-mesh swap slot
  (SpecialMesh deliberately — MeshPart.MeshId isn't runtime-scriptable).
- **World** (`EnvironmentService`) — noon lighting + Atmosphere/Bloom/ColorCorrection/SunRays/
  Clouds; grass/street/mustard dashes/sidewalks/lamps; glizzy-land horizon (bun hills, mustard
  river, ketchup geyser). Runs before `PlotManager.build()`.
- **Building shell** — 15-entry `BuildCatalog` (floor2→stairs2→wall→floor3→gate→elevator + 9 income
  decors totalling +27% for ~25,050 coins; full catalog ≈ 43,750). `BuildGrants` derives every grant
  from `data.built` at READ time (rebuild-on-join can't double-apply). Static floor-1 stall shell on
  every plot; structures rise via 🏗️ structural + 🎪 decor walk-on pads that each offer ONE next
  item (server re-derives; never trusts the pad). **Locked balance rules:** the ground route stays
  open (wall keeps a permanent 16-stud gap; the gate slows non-owners to walkspeed 9 for 2s, never
  blocks), and every display floor keeps a free theft route (jumpable rails, floor-3 climbable
  truss, elevator prompts work for everyone) — upper floors sell TIME, not immunity. The old $250
  DefenseService wall is retired; old owners are grandfathered `built.wall` on load.
- **Juice** — `Celebrate` remote: cook burst colored by rarity (+ stingers), purchase pad pop, build
  dust, 3-flash steal alarm, camera shake on Giant grabs; client coin-milestone 💰 sparkle; spinning
  cook-reveal viewport. `Sfx.luau` + `GameConfig.Sounds` are silence-safe until Nate picks ids.
- **UI restyle** — `MenuLayout` owns the Theme.UI chrome; every panel is now a draggable Cream
  window with a ketchup-gradient title bar (`makePanel` = `makeWindow`); new `Build.client` catalog
  window (✅/🏗️/🔒); tray gained "Build"; the old 🛒 Upgrades menu is restyled and kept as the pad
  fallback (locked decision #6).

**Overhaul Phases 4+5 — SHIPPED 2026-07-09** (playtest WAIVED by Nate — accepted without live
validation; §6 stays reasoned-not-observed):
- **Conveyor buy-lane** (`ConveyorService`) — a belt strip down the street centre; up to 8
  glizzies ride it spinning with price tags; prompt-to-buy (0.35s hold, deliberate — raw Touch
  would misfire on street-crossers). Offers roll from the SHOP's flatter weights + prices; buys
  grant base dogs (no mutation mint — cook stays the only mint source).
- **Cooker upgrader** (`UpgraderService`) — ⚙️ pad beside the stove (appears once it's built);
  `outputMult` multiplies `AutoCookerService.coinsPerSecond`, so tick/offline/label inherit it.
- **Condiment blasters** (`WeaponService` + `Weapons.client` tray window) — buy/equip; equip hands
  a colored Neon Tool (re-given each spawn). Fire = server picks the nearest CARRYING thief within
  24 studs AND within 45 studs of the firer's own plot (defense only). Effects: slow 2s /
  knockback / stun — NEVER damage (locked all-ages tone). Splat burst via Celebrate.
- **Zone expansion** (`ZoneService`) — 🌍 pad priced in PRESTIGE (green/red by prestige balance);
  charging physically swells the plot pad (`PlotManager.applyZone`; reset on release, re-applied
  on join) and adds display slots derived read-time in `displayCapacity`.

**Milestone 4 — retention systems + vault pins + hardening — SHIPPED 2026-07-09**
(static-clean; like Phases 4+5, accepted without live validation):
- **Weekly events** (`EventService`/`Events.client`) — the active event is a deterministic function
  of the week index (ShopService's trick), so every server agrees. Modifiers run in the REAL math:
  `income2x` doubles `Main.incomeMultiplier` (live tick + offline both call through it);
  `cookHalfPrice` halves the cook-10 batch price; `freeCookBursts` = **Dog Rain** — every
  `EventDogRainIntervalSeconds` (4 min) each online player gets a FREE roll with the full
  reveal/celebrate (Main hands the service a `grantFreeCook` closure). Points: +10/cook, +40/steal
  (`EventService.addPoints` from `doCook` + the steal callback). Reward track: 4 point tiers →
  coin payouts; one claim collects every reachable tier; the claimed-tier count persists as
  `eventPoints["<id>:claimed"]` — same `{string→number}` map, **no new field / no `_vN` bump**.
  Panel: banner + modifier blurb + live countdown + tier rows. *Event-only dogs deferred (content).*
- **Leaderboards** (`LeaderboardService`/`Leaderboards.client`) — three OrderedDataStores
  (coins/steals/rarest); every `LeaderboardRefreshSeconds` the server submits online players'
  scores, refetches top-N, caches, and pushes. **Rarest = the income/sec of the player's single
  best unit** (variant-scaled via `sortedUnits`, ×100 because OrderedDataStore is integer-only).
  UserId→display-name via `GetNameFromUserIdAsync`, session-cached. Panel: three tabs, top-10
  rows, own-rank highlighted.
- **Achievements** (`AchievementService`/`Achievements.client`) — progress read off existing
  counters/inventory (dogs/steals/rebirths), claims validated server-side (known id + unclaimed +
  target met) and paid once into `data.achievements`; panel gates the claim button client-side
  (server revalidates anyway) + progress bars.
- **Manual vault selection** (M2 fast-follow closed) — `data.vaultPins` honoured in
  `PlotManager.syncDisplay`: pinned keys fill the vault FIRST (value order), then the vault tops
  up with the best unpinned units; the rest overflow to pedestals. Dex tiles gain a 📌 toggle that
  flips a whole dog family (base + owned variants) with an explicit desired state (no half-flips);
  pins ride `InventoryUpdate`; only owned keys are pinnable. Also fixed: variant-only ownership
  (e.g. only `"X#Gold"`) now lights the dex tile + counts toward completion.
- **Anti-exploit hardening pass** (scheduled pre-M6, done early) — every `OnServerEvent` in the
  codebase now goes through `RateLimit.check` + type/length arg guards (cook, cook-10, daily
  claims, rebirth, shop, upgrades, defenses, vault pins, and all newer remotes which already had
  it). `RequestState` is special-cased: the ~15-scripts-fire-on-join handshake is NORMAL, so
  over-limit requests **coalesce into one deferred push** (2s) instead of being dropped — cheaper
  than before AND un-breakable. Trading (M6) is unblocked on this front.

**Visual polish + feel passes — SHIPPED 2026-07-09** (Nate-directed, post-Studio look):
- **Grass z-fight fix** — the default Studio Baseplate is destroyed at runtime (its top face was
  coplanar with our grass at y=0 = the flicker); lane dashes/river lifted off shared planes.
- **World-text de-soup** (matched to Steal a Brainrot): ONE far label per plot (the owner sign);
  everything else small, near-fading, occludable (no AlwaysOnTop through walls); per-unit stacked
  plates (name / rarity+variant / $-per-s); conveyor tags show name/rarity/price+rate; rival
  stands hide owner-facing labels (pads/cook/stove/vault/deposit) client-side; world font =
  FredokaOne with full stroke.
- **Neon tamed** — new `Theme.Materials` rule: interactive surfaces read through bright SEMANTIC
  COLORS, not emissive glow; Neon reserved for small accents + gameplay signals (rarity drizzle,
  sign drizzle, trap, blasters). Bloom 0.4/24/1.1 → 0.25/14/1.6.
- **Vendor-stand pedestals** (base + column + red tray; the TRAY is the anchor — steal/spawn
  plumbing unchanged) and **display glizzies at 1.35×** (vault copies stay compact).
- **Pick-up-and-hold** (`PickupService`): F-prompt on your own DISPLAY dogs → welded hand Tool;
  cosmetic hold (inventory/income unchanged; one held-key count excluded from the fill). The hand
  is NOT shelter: a Snatch prompt routes rivals through the FULL steal pipeline; unequipping
  force-returns the dog (no invisible backpack shelter); one held dog at a time.

**Deployment audit + readiness — SHIPPED 2026-07-09** (plan `modular-crunching-starfish`):
- **Data safety (critical fixes):** load failure now retries 3× then KICKS (a failed load can
  never save defaults over real progress); the `_v5` back-fill was accidentally nested inside the
  dailyMissions check (whole tycoon layer silently reset if that one field went missing) — fixed;
  autosave every 60s for >3-min-stale players (+5s double-save guard); saves use `UpdateAsync`
  keeping the newer `lastSeen` (stale-write guard); `ProcessReceipt` returns NotProcessedYet for
  unmapped products (was silently consuming receipts = eating Robux once ids exist).
- **Telemetry** (`Telemetry.luau`): onboarding funnel Joined→FirstCook→StoveBuilt→FirstBuild→
  FirstSteal→FirstRebirth (stable step numbers), HandSnatch counter, ScriptContext.Error dedup
  logging. All pcall-guarded.
- **Shop daily cap:** 3 buys per offer per day (`shopBuys` lazy day-reset; "X/3 today" in-panel).
- **World podium:** coins top-3 as gold/silver/bronze tiers + glizzy statues + name plates on the
  street past the conveyor; rebuilt only when the top-3 changes ("Unclaimed!" until boards fill).
- **Event-exclusive dogs:** 3 Legendaries (Payday Dog / Rainmaker Wiener / Half-Price Hero) —
  in `byName` but NOT `DOGS_BY_RARITY`, so rolls/shop/conveyor/dex-completion exclude them by
  construction; granted only by their event's FINAL reward tier. Event tracks now keyed
  **per occurrence** (`"id@week"`), so a returning event offers a fresh track + dog.
- **Launch checklist** (Nate-facing) lives in `docs/HANDOFF.md §Launch checklist`.

**Dev code + loose ends + onboarding + M5 passes — SHIPPED 2026-07-11** (Nate picked the full
stretch menu; one commit per feature):
- **`NATE` dev code** — 1,000,000,000 coins for progression-curve testing. Nate's calls: plain
  once-ever code, **no lockdown**, plain toast — so it's just a `GameConfig.Codes` entry.
  ⚠️ **Delete the line before public launch** (anyone who types it gets 1B once).
- **Codes: non-coin rewards** — a `GameConfig.Codes` entry may now be a table
  `{ coins?, dogs? (inventory keys, variants OK), prestige?, mutationLuck? }` (plain numbers stay
  valid). `CodesService` stays the single validator; each component reuses its normal grant path's
  pushes; empty/invalid rewards refund the redemption mark. Demo: `FREEGLIZZY` → 1 Plain Dog.
- **Steal-path mutations ON** (`MutateOnSteal = true`) — at deposit, a stolen BASE dog rolls
  `MutationService.maybeMint` with the THIEF's banked mutation luck; already-mutated loot
  transfers as-is; the victim always loses exactly the carried key; minted deposits get an
  upgraded toast ("…and it turned ✨ GOLD on the way out!").
- **Traps polished + discoverable** — 🪤 buy button joins Guard in StealHud (same `BuyDefense`
  remote/toast); the poll loop became a `Touched` trigger (owner-exempt, carriers only);
  springing the trap disarms it (grey matte) until `TrapRearmSeconds` (6s) re-arms it (Neon red
  = the armed signal). `TrapRange` retired with the poll.
- **Tool.Grip initial pose** for held glizzies (length forward, settled in the palm; was default
  identity = sideways through the fist). Needs a live Studio tuning round with Nate.
- **Onboarding first-60s** (§4.9) — guided arrows cook → stove → build. Server DERIVES the stage
  from existing data (`cookReadyAt`/`autoCookerLvl`/`built` — no new field) and pushes
  `OnboardingUpdate` (rides `pushAllState`; the tick re-pushes only on change, stops at done).
  New `Onboarding.client`: screen-edge ring arrow + target Highlight + tip banner on the
  player's own plot; veterans derive straight to done and see nothing.
- **M5 monetization — `PurchaseService` real** (Extra-slots + VIP first, locked order):
  refund-safe ownership via new `_v5` field `data.passes` (last-known `UserOwnsGamePassAsync`
  per pass, refreshed on join in its own thread + on `PromptGamePassPurchaseFinished`; pcall
  failure keeps the last answer; **Studio overrides** `GameConfig.StudioTestPasses` while ids
  are 0). Effects DERIVE at read time: PlotManager capacity adds the pass slots,
  `Main.incomeMultiplier` adds `VipIncomeBonus` (tick + offline inherit). `ProcessReceipt`
  dispatches coinsSmall/coinsLarge/stealCharges (grant → mark `receiptHistory` →
  `PurchaseGranted`); unmapped products (incl. `offlineRefill`, bespoke logic pending) stay
  `NotProcessedYet`. `MaxDisplaySlots` 16→18 / `MaxVaultSlots` 6→8 so sold slots render.
  Passes panel: config-driven labels, owned greys out, dev-product buttons.
  doubleCoins/autoCollect: detected, effects TODO(M5). Purchase telemetry via `Telemetry.event`.

**THE ADDITIONS SESSION — SHIPPED 2026-07-11/12** (Nate's 17-item `additions.txt` wishlist,
interviewed → planned → implemented in 5 code batches; two entries below consciously override
locked rules — see the §7 rows):
- **#3 Bigger everything:** plots 60×46 → **76×58** (row spacing 120, street separation 140,
  street 1240×60); the stall shell grew to 60w × 27d × **12 tall** (floor2 slab y13, floor3 y26);
  display glizzies render at **1.8×** (pedestal pitch 3.0). All BUILDERS re-laid; wall/gate now
  derive from the config footprint.
- **#2/#1 Stations look real + a chef works them:** the cook station is a kettle grill (legs,
  grate rods, charcoal glow, propped lid, shelf); the stove is a range (burners, oven door,
  handle) whose form steps up per tier band; a cosmetic parts-built **chef** flips a spatula at
  the stove (synced tweens — no Humanoid) with a griddle-smoke wisp.
- **#15 Roofs:** every stand is capped above its TOPMOST floor (y 13/26/39), striped
  ketchup-and-cream, recomputed as floors go up; sides stay open so raider access is preserved;
  the Rooftop Wiener now stands ON the roof.
- **#16 Odds sign + spin-wheel reveal:** the HUD odds sidebar is GONE — drop rates + pity render
  on a physical board beside each grill (updates with grill level/pity). The single-cook reveal
  is a case-opening **spinner strip** landing exactly on the server's pre-decided rarity (roll
  stays server-side + coin-only — locked), with a near-miss tier seeded next to the landing cell.
- **#8/#12 Economy:** new top tier **Forbidden** (weight 0.01, 15,000/s, electric violet, 3 dogs:
  The Forbidden Glizzy / Glizzy Prime / The Omega Wiener) and a steeper income ladder — payback
  now FALLS with rarity (see §6). Event dogs bumped to Legendary parity (250/s).
- **#10 Floor-gated stove tiers:** 7 named tiers (Camp Stove → **Glizzy Factory**, 1→350
  coins/s); Lv4-5 need floor 2, Lv6-7 need floor 3 (upgrade-gated only — existing levels
  grandfathered); the pad shows the tier name or "needs Nth Floor".
- **#5 Cook cadence:** free-cook cooldown 300s → **120s**; the Cook button counts down, then
  glows + toasts + plays `CookReady` (new silence-safe sound id). `CookStats` carries the
  remaining seconds.
- **#6 Rarity auto-sort:** displayed overflow fills anchors floor-DESC (floor 3 → 2 → ground) —
  best dogs sit HIGH and thieves pay climb time; 📌 vault pins still claim the vault first.
- **#9/#13 HUD polish:** storage fullness fractions on the HUD (`🌭 12/16 🔒 3/5`, new
  `StorageUpdate` push) and **every** number renders with thousands separators (new shared
  `Format.comma`, ~30 call-sites swept: panels, pads, plates, tags, toasts, podium).
- **#4 Security Field** (override — see §7): BuildCatalog defense (25k, prereq gate) that FULLY
  seals the plot in force-field panels up to y14, powering down 30s of every 300s on a
  phase-staggered clock, loudly telegraphed (countdown billboard, red/green, `BlockerOpen` sfx).
  Owner passes via client-side collision exemption; an anti-cage valve ejects raiders caught
  inside at close (never traps them).
- **#7 Vault Breaker** (override — see §7): coin consumable (50k, cap 3, bought on the StealHud
  defense bar) that starts a 10s DRILL on one vault dog — victim gets a countdown alarm +
  arrow, the sign flashes; any stun/death/leave/step-away cancels (breaker spent, no refund);
  survival detaches that ONE dog into the normal carry pipeline. 600s per-pair cooldown; one
  drill per vault; no steal charge spent.
- **#11 Full-street conveyor:** belt spans ±560 (speed 14, ≤18 riding, 4s spawns); the podium
  moved to the EAST street-end plaza (x=660).
- **#14 Glizzy Run obby:** parkour course at the WEST street end; finish pays **100 seconds of
  the runner's live income** (dogs + stove, multipliers — never obsolete); 300s cooldown
  persisted (`obbyReadyAt`); anti-teleport = ordered checkpoints + 25s minimum run; falls cost a
  walk-back, never a respawn.
- **#17 Clipfarm hookup:** content-plan doc only this session → `docs/CONTENT_PLAN.md` (game
  moments → capture → ClipForge pipeline inputs → cadence).
- Data: `_v5` back-fill adds `vaultBreakers` + `obbyReadyAt` (no `_vN` bump). New remotes:
  `StorageUpdate`, `VaultBreach`; extended: `CookStats` (+cookRemaining), `StatsUpdate`
  (+vaultBreakers), `BuyDefense` ("breaker").

## 6. Current tuning values (from `GameConfig.luau` / `HotDogDex.luau`)

**Economy** *(income ladder steepened 2026-07-11, additions #12 — reasoned, not observed)*
- Tick interval: 1s · **Starting coins: 100** · Cook cost: 10 (flat, coin-only)
- Rarity → income/sec: Common 1, Uncommon **4**, Rare **16**, Epic **60**, Legendary **250**,
  Mythic **1,000**, Secret **4,500**, **Forbidden 15,000** — against FIXED shop prices the
  payback time now FALLS with rarity (150s → ~67s; Forbidden ~80s as the chase tier), so rarer
  dogs are strictly better per coin. Event dogs: 250/s (Legendary parity).
- Rarity → roll weight: **100 / 40 / 12 / 4 / 1.5 / 0.4 / 0.06 / 0.01** (total ≈ 157.97)
  - P(Rare-or-better) per cook ≈ **11.4%** → expected first Rare in ~9 cooks. With 100
    starting coins (~10 cooks) + early idle income, a fresh player should hit their first Rare
    inside the opening minute or two — "earned, not guaranteed."

**Steal / defend**
- Steal hold: 3s (+2s with a wall) · Carry speed: **10** vs normal 16 (slow enough to chase,
  fast enough that a clean getaway feels earnable)
- Steal charges: 5 max, one back every 45s (full refill ~225s)
- Per-target cooldown: 120s + diminishing returns (×1.5 hold per repeat raid) · Newbie shield: 600s
- Net: 3s stun, 12-stud range · Wall: 250 coins (+2s hold) · Guard: 600 coins, scans every 1.5s

**Plots** *(footprint grown 2026-07-11, additions #3)*
- 20 plots, two rows · pad **76×58** · 120-stud row spacing · 140-stud row separation
  (street 1240×60) · 8 display (stealable) + 3 vault slots at level 1

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
  Legendary 5 · Mythic 2 · Secret 0.5 · Forbidden 0.1
- Prices by rarity: Common 150 · Uncommon 500 · Rare 1.8k · Epic 6k · Legendary 22k · Mythic 75k ·
  Secret 300k · Forbidden 1.2M. Since the #12 income ladder, payback (price ÷ income/s) FALLS
  with rarity (150s → ~67s) — the shop is "pay for certainty" and high tiers are worth chasing.
- v1 = unlimited buys, no new persisted fields. Per-rotation purchase cap deferred (would need `_v5`).

**New scaffold config (all reasoned placeholders, `GameConfig.luau`) — tune when each feature lands**
- Mutations: `MutationChance` 0.04 · variant income mults Gold ×2 / Rainbow ×3.5 / Giant ×5
  (mint weights 100/30/8 in `Variants.luau`) · `MutateOnSteal` **true** (2026-07-11; base dogs
  only, thief's luck applies)
- Prestige shop (**shipped 2026-07-08**): 4 one-time unlocks 5–15 prestige (income +10% / +1 display /
  +1 vault / +50% mut-luck). Effects are permanent + additive; income folds into the rebirth multiplier.
- Fusion: `FusionInputs` 5, forces a mutation · Trap: 450 coins, 4s stun, Touched-triggered,
  6s re-arm (`TrapRange` retired with the old poll)
- Events: weekly rotation, 3 modifiers, reward tiers 100/300/700/1500 pts → 250/750/2000/5000
  coins; points +10/cook +40/steal; Dog Rain every 240s; final tier grants the event dog
  (Legendary, 60/s); tracks reset per occurrence · Leaderboards: top-25, 60s refresh
- Shop daily cap: 3 buys per offer per day · Autosave: 60s sweep, >180s stale · Load: 3 retries
- Achievements: 5 goals (collect 10/30, steal 25/100, rebirth 3) · Codes: LAUNCH 1000, GLIZZY 500,
  FREEGLIZZY 1 Plain Dog, **NATE 1B (DEV — delete before launch)**; entries may be component
  tables `{ coins?, dogs?, prestige?, mutationLuck? }`
- Passes/products: ids 0 (unconfigured; `StudioTestPasses` overrides for testing) · extra-slots
  +2 display/+1 vault · VIP +10% income · 2× coins · anchors `MaxDisplaySlots` 18 /
  `MaxVaultSlots` 8 (headroom past coin-max 16/6 so pass slots render)
- Cosmetics: 3 items (10–25 prestige) · Trade: 30s cooldown, ≤6 items · Emotes: 5 presets

**Tycoon layer (overhaul + additions, all reasoned placeholders — tune in playtest)**
- Plot pad: **76×58** · row spacing 120 · row separation (street) 140
- Cook cooldown: **120s** free single cook (+ ready notify) · cook-10 stays `CookCost`×10 = 100
- Auto-cooker stove tiers (cost / coins-sec / gate): 0/1, 400/3, 2000/8, **9000/22 (floor2)**,
  **35000/55 (floor2)**, **120000/140 (floor3)**, **400000/350 (floor3)** — named Camp Stove →
  Glizzy Factory; gates apply to UPGRADES only (existing levels grandfathered)
- Cooker upgrader tiers (cost / output×): 0/1.0, 2500/1.25, 12000/1.6, 60000/2.0
- Build catalog: floor2 1500, stairs 400, floor3 6000, elevator 8000, wall 1200, gate 3000,
  **Security Field 25000 (prereq gate)**
- Security Field cycle: closed 270s / OPEN 30s per 300s, phase-staggered per plot (index×47)
- Vault Breaker: 50k coins · cap 3 · 10s drill · 12-stud hold range · 600s per-pair cooldown
- Obby: pays 100s of live income · 300s cooldown · 25s minimum run · 2 ordered checkpoints
- Weapons (non-damaging): mustard-slow 800, ketchup-knockback 4000, relish-stun 15000
- Conveyor: spawn every 4s, ≤18 on belt (±560 run at 14 studs/s) · Zones (prestige): 0, 5, 15

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
| 2026-07-09 | **Event modifiers live in the consumers, not the service** (income2x in `Main.incomeMultiplier`, cookHalfPrice in cook-10, Dog Rain via a Main-provided `grantFreeCook` closure) | `EventService` stays a pure "which event is it" oracle; the math changes where the math lives, so offline earnings/celebrates inherit for free and there's no duplicated income path |
| 2026-07-09 | **Event claimed-tier count persists as `eventPoints["<id>:claimed"]`** | The `_v5` back-fill already keeps any string→number pair in that map — zero migration for a per-event counter; a dedicated field can come later if events grow richer state |
| 2026-07-09 | **Dog Rain = free cook rolls on an interval** (not literal falling pickups) | Same excitement, no physics/pickup-race/exploit surface; reuses the entire cook reveal + celebrate path |
| 2026-07-09 | **Leaderboard "rarest" = income/sec of the single best unit ×100** | One integer that already encodes rarity AND variant (Gold outranks plain twin) via the live `sortedUnits` math; no new scoring table to tune |
| 2026-07-09 | **Vault pins toggle per dog FAMILY from the Dex** (explicit desired state per key; pins beyond capacity overflow back to display) | Per-key pinning is the correct data model (a Gold variant is worth pinning), but per-variant UI is clutter — one 📌 per tile covers the whole family without half-flipped states |
| 2026-07-09 | **`RequestState` is rate-limited by COALESCING, not dropping** | ~15 client scripts each fire it on join by design; dropping would randomly lose panels' initial state, so over-limit bursts merge into one deferred full push (fewer pushes than before, same guarantee) |
| 2026-07-09 | **World text: ONE far label per plot (the sign); all else small/occludable/near-fade** | Matches the genre leader's readability; AlwaysOnTop billboards at 120 studs stacked every plot's labels into soup |
| 2026-07-09 | **Neon reserved for small accents + gameplay signals; interactive surfaces = matte semantic colors** (+ Bloom threshold up) | Dozens of large emissive surfaces at bright noon were an eyesore; color carries the affordability/deposit signals fine |
| 2026-07-09 | **Pick-up-and-hold is COSMETIC (inventory/income unchanged) and the hand is NOT shelter** — snatchable via the same steal pipeline; unequip force-returns; display dogs only | Zero dupe/loss surface; closes both shelter tricks (backpack + vault-rotation); holding becomes a risk/reward flex |
| 2026-07-09 | **Load failure → retry 3× then KICK** (never cache defaults) | A failed load that saves is a progress WIPE; a playable-but-unsaved ghost session is confusing — kick with a rejoin message is the standard for economy games |
| 2026-07-09 | **Event points/claims keyed per OCCURRENCE (`"id@week"`)** | Id-forever keys meant a returning event offered nothing; occurrence keys make every run fresh (incl. re-earnable event dog = fusion food); old keys are pennies of residue |
| 2026-07-09 | **Event dogs excluded by construction** (in `byName`, not `DOGS_BY_RARITY`) | Rolls/shop/conveyor/dex-completion can't leak them and completion stays achievable off-event; no filter flags scattered across consumers |
| 2026-07-09 | **`ProcessReceipt` returns NotProcessedYet until grants exist** | Marking unmapped receipts PurchaseGranted would eat real Robux the moment a product id is configured; Roblox retries/refunds NotProcessedYet |
| 2026-07-11 | **`NATE` dev code = open + once-ever + plain toast** (Nate's explicit calls over the recommended allowlist/re-redeemable) | Keeps codes config a plain entry; accepted risk is bounded (1B once per guesser) and the line is flagged DELETE-BEFORE-LAUNCH in config + checklist |
| 2026-07-11 | **Code rewards = component tables** `{ coins?, dogs?, prestige?, mutationLuck? }` with plain-number back-compat | One validator (`CodesService`) grows without breaking LAUNCH/GLIZZY; dogs ride composite keys so promo codes can grant variants |
| 2026-07-11 | **Steal-path mint: BASE dogs only, thief's luck, at DEPOSIT** | Already-mutated loot must transfer losslessly (victim loses exactly the carried key); deposit is where the thief's ownership becomes permanent, so their `mutationLuck` is the fair input |
| 2026-07-11 | **Trap = Touched trigger + disarm/re-arm state** (was a poll; `TrapRange` retired) | Event-driven beats a per-plot poll loop; the grey "spent" pad telegraphs counterplay (sprint through while disarmed) and Neon-red-when-armed follows the Theme.Materials signal rule |
| 2026-07-11 | **Pass ownership = persisted `data.passes` + effects derived at read time** (never banked into `bonus*Slots`) | Refund-safe + re-check-safe (no double-grant); mirrors the BuildGrants philosophy; `bonus*Slots` stays exclusively the prestige shop's ledger |
| 2026-07-11 | **Anchor maxima bumped to 18 display / 8 vault** (coin-max stays 16/6) | The extra-slots pass + prestige vault unlock must physically render to be worth buying; stacked build/zone bonuses beyond anchors remain accepted-unshown at the extreme |
| 2026-07-11 | ⚠️ **OVERRIDE: Security Field may FULLY block entry** — supersedes "theft access is always possible" (wall gap permanent / gate slows-never-blocks) — but only on a telegraphed timer (30s open per 300s, phase-staggered, countdown + color + sfx) with an anti-cage eject valve | Nate confirmed the override (additions #4). Raiding becomes a TIMING game instead of impossible: the window is public knowledge, staggered across plots, and defenders pay 25k + the whole wall→gate chain for it. The valve keeps the one hard rule left: raiders can always LEAVE |
| 2026-07-11 | ⚠️ **OVERRIDE: the vault is no longer absolutely safe** — a coin-priced Vault Breaker consumable can extract ONE vault dog per successful 10s drill | Nate confirmed the override (additions #7). Counterplay is structural: the drill is loud (alarm + arrow + countdown), slow, cancels on any stun/death/step-away, spends the breaker with NO refund, and locks the pair for 600s — so defense is rewarded and vault-camping whales can't chain-drain. Coin-only keeps non-pay-to-win intact |
| 2026-07-11 | **Income-vs-cost curve inverted: payback FALLS with rarity** (prices fixed, incomes raised super-linearly; Forbidden = new chase tier above Secret) | Nate's ask (#12): "the boost should increase more than the cost." High tiers were prestige-only (600s payback); now the chase is also the economically correct play. Knock-on (accepted): earn-missions/build costs become trivial for Mythic+ owners — they're past that content anyway |
| 2026-07-11 | **Odds disclosure moved WORLD-side** (physical board at each grill replaces the HUD sidebar); the single-cook reveal is a spinner strip that lands on the server's pre-decided rarity | Disclosure stays permanent + glanceable at the point of use (coin-only gacha rule intact — the wheel is pure presentation, seeded from the same disclosed odds). A strip beats a literal pie wheel in Roblox GUI and sells near-misses better |
| 2026-07-11 | **Best dogs display HIGH** (rarity auto-sort fills floor 3 → 2 → ground; pins still own the vault) | Height = defense value: the climb time thieves pay for top loot is the same currency the floors already sell; also makes tall bases read as rich bases from the street |
| 2026-07-11 | **Obby reward = seconds-of-own-income, not flat coins** (100s worth, 300s cooldown, ordered checkpoints + minimum-run anti-teleport) | Nate's ask (#14): leveling must never make the obby obsolete. Income-scaled pay stays exactly "worth ~2 free cooks of time" at every progression stage; flat coins would be OP at minute 1 and pennies at hour 10 |
| 2026-07-12 | **Conveyor per-frame exception cap raised 8 → 18** (belt now spans the full 1240 street) | Still the ONE bounded per-frame server job; 18 anchored pivots/Heartbeat is trivial, and a full-length empty belt read as broken |
| 2026-07-11 | **Onboarding stage DERIVED from existing data** (`cookReadyAt`/`autoCookerLvl`/`built`), pushed as a number | No new `_v5` field, veterans auto-derive to done (zero UI), and the tick only re-pushes on change — the whole feature costs 3 field reads per tick until completed |
