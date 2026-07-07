# Game Design Document — Steal a Glizzy 🌭

> **Living doc.** Update as decisions get made. `✅` = locked. Keep this the single source of
> truth for *what* we're building; `CLAUDE.md` covers *how* (tech/workflow).

**Last updated:** 2026-07-07 · **Status:** Milestones 1–3 BUILT & static-clean (M2 clarity polish +
M3 progression added 2026-07-03). Awaiting a 2-player Studio playtest to validate feel/tuning.
Next: playtest, then M4 retention (events, leaderboards, achievements) + rotating shop.

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
