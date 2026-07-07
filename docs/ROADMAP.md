# Roadmap — Steal a Glizzy 🌭

Milestones are ordered by what proves the game out fastest for a **go-big commercial** target.
Each should be independently testable in Studio. `✅ done · 🔜 next · ⏳ later`.

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
- **Still deferred:** rotating shop, duplicates→fusion, mutations/variants.
- **Data:** DataStore bumped to `_v4` (back-fills all new fields from `_v3`).

## ⏳ Milestone 4 — Retention systems ⭐
- Daily login + daily missions. *(shipped early in M3 — see above.)*
- Weekly limited-time events + event-only dogs (FOMO).
- Quests/achievements, milestone rewards.
- Leaderboards (coins / rarest / most steals).
- Codes system (creator marketing lever).

## ⏳ Milestone 5 — Monetization
- Game passes (e.g. 2× coins, extra slots, auto-collect, VIP) — keep non-pay-to-win.
- Dev products (coin packs, refills). **No paid gacha.**
- Cosmetics (stand skins, trails, titles).
- *Ref: `docs/roblox-reference/monetization/`.*

## ⏳ Milestone 6 — Social & virality
- Friends/parties, trading (with dupe/scam safeguards), chat/emotes/taunts.
- Shareable "big steal / rare pull" moments engineered for clips.

## ⏳ Milestone 7 — Polish & soft launch
- AI-generated art pass, audio/SFX, UI polish, onboarding/first-60-seconds.
- Icon + thumbnail (huge for CTR), store description, genre tags.
- Analytics goals, playtest with friends → public soft launch.
- *Ref: `docs/roblox-reference/publishing/`.*

---

### Guiding principle
Ship the **steal loop (M2)** before piling on content — it's what makes or breaks retention. Everything
after M2 is amplification. Validate fun with real players early and often.
