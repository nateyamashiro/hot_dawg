# Roadmap — Steal a Glizzy 🌭

Milestones are ordered by what proves the game out fastest for a **go-big commercial** target.
Each should be independently testable in Studio. `✅ done · 🔜 next · ⏳ later`.

---

## ✅ Milestone 0 — Pro setup
VS Code + Rojo + Git + Rokit toolchain; server-authoritative project skeleton. *(Done.)*

## ✅ Milestone 1 — Cook & collect core
Coin-only gacha cook, 7 rarity tiers, idle income, DataStore persistence, HUD. *(Done, commit `4928f7c`.)*

## 🔜 Design deep-dive (interview)
Work through `docs/design/DISCOVERY_QUESTIONS.md`; fill in `GAME_DESIGN.md`. **Blocks Milestone 2.**
*(This is the next session's job.)*

## 🔜 Milestone 2 — Steal & defend (THE hook)
The retention engine. Depends on deep-dive answers to §2/§3.
- Per-player base/plot with dogs displayed as stealable objects (pedestals/grills).
- Raid mechanic: approach → grab (ProximityPrompt) → carry back to your base.
- Carry risk: slowed + marked + owner alerted; taggable by others.
- Ownership transfer on successful steal; defense options.
- Anti-grief: cooldowns, newbie protection.
- *Ref: `docs/roblox-reference/gameplay/` (ProximityPrompt, Humanoid, CollectionService).*

## ⏳ Milestone 3 — Progression & economy depth
- Base/slot upgrades, better grills, cost curves and deliberate walls.
- **Rebirth/prestige** loop (permanent multipliers).
- Offline earnings (capped).
- Collection "dex" UI; possibly duplicates→fusion and mutations.

## ⏳ Milestone 4 — Retention systems ⭐
- Daily login + daily missions.
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
