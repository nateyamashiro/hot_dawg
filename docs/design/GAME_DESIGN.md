# Game Design Document — Steal a Glizzy 🌭

> **Living doc.** Update as decisions get made. `✅` = locked, `❓ TBD` = open (see
> `DISCOVERY_QUESTIONS.md`). Keep this the single source of truth for *what* we're building;
> `CLAUDE.md` covers *how* (tech/workflow).

**Last updated:** 2026-07-02 · **Status:** Milestone 1 built; design deep-dive pending.

---

## 1. Pitch

A **steal-and-defend idle tycoon**: cook and collect absurd hot dogs across rarity tiers, watch
them generate coins, and **raid rival stands** to steal their best dogs — while defending your own.
Same proven loop as *Steal a Brainrot* (acquire → grow → defend → steal), wrapped in an ownable
hot-dog theme riding the "hot dog summer" TikTok wave.

## 2. Locked decisions ✅

| Area | Decision |
|---|---|
| Genre | Steal-and-defend idle tycoon |
| Theme | Hot dogs; 7 rarity tiers Common → Secret |
| Working title | "Steal a Glizzy" (❓ final name TBD) |
| Ambition | Go big / commercial — optimize for growth, retention, monetization |
| Audience | Everyone / Gen Alpha core (all-ages content) |
| Monetization stance | Passes + dev products + cosmetics OK; **gacha "cook" rolls are coin-only, never Robux** |
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

## 4. Systems status

### Built (Milestone 1) ✅
- **Rarity roster** — 7 tiers, 14 dogs, weighted roll (`HotDogDex.luau`).
- **Cook/gacha** — coin-only roll, server-authoritative, rarity reveal.
- **Idle income** — coins/sec = Σ owned dogs' rates.
- **Persistence** — per-player DataStore save/load.
- **HUD** — coins + dogs count, cook button.

### Designed but not built ❓ TBD (needs the deep-dive)
- **Steal-and-defend** — the whole raiding layer (see DISCOVERY §2). *Highest priority.*
- **Bases/plots** — layout, capacity, display of stealable dogs (§3).
- **Progression** — upgrades, rebirth/prestige, walls, offline earnings (§4).
- **Collection depth** — dex UI, limited dogs, mutations, fusion (§5).
- **Retention** — dailies, events, missions, leaderboards, codes (§8).
- **Social** — trading, parties, chat/taunts (§9).
- **Monetization** — which passes/products/cosmetics (§11).
- **Onboarding** — first 60 seconds (§10).
- **Art/audio direction** — visual style, palette, music (§13).
- **Branding** — final name, icon, thumbnail (§14).

## 5. Current tuning values (from `GameConfig.luau` / `HotDogDex.luau`)

- Tick interval: 1s · Starting coins: 50 · Cook cost: 10 (flat, coin-only)
- Rarity → income/sec: Common 1, Uncommon 3, Rare 8, Epic 20, Legendary 55, Mythic 150, Secret 500
- Rarity → roll weight: 100 / 45 / 20 / 8 / 3 / 0.9 / 0.1

*(All placeholder — rebalance once progression & walls are designed.)*

## 6. Open questions

See **`DISCOVERY_QUESTIONS.md`**. Answer 🎯 items first (they unblock Milestone 2).

## 7. Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-02 | Hot dog theme, not brainrot clone | Ownable IP; brainrot saturated & moderation-risky |
| 2026-07-02 | Gacha rolls coin-only | Sidesteps Roblox paid-random-item rules; keeps it fair |
| 2026-07-02 | AI-generated art | Fast, on-theme, low art-skill barrier |
| 2026-07-02 | Go-big commercial ambition | Prioritize retention/virality systems in roadmap |
