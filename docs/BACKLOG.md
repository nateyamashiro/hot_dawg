# Backlog — Steal a Glizzy 🌭

Living list of remaining work, most-impactful first. Milestones 1 & 2 are built (see
`ROADMAP.md` / `GAME_DESIGN.md §4-5`). This is the running "items that need to be completed."

**Legend:** ✅ = shipped (static-clean; playtest owed). Priority reflects the chosen focus.

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

- **2-player Studio playtest** of M2 + M3 (validate feel; tune the reasoned numbers in `GAME_DESIGN §6`).
- **Rotating shop** — buy specific dogs for coins (targeted goal, less pure RNG) — M3 remainder.
- **Spend prestige currency** — first premium-unlock sink (it's banked but unused today).

---

## Beyond that (later)

**M2 fast-follows**
- Traps (placeable stun zones) — a 4th defense (walls/guards/tagging already in).
- Manual vault selection (let players choose which dogs are safe, vs. current auto-top-by-value).

**M3 remainder** (rotating shop moved up to "Top of the list")
- Mutations/variants (Gold, Rainbow, Giant) with income multipliers.
- Duplicates → fusion (deferred from launch).
- Prestige-currency spending / premium unlocks (banked but unused today).

**M4 retention** (daily streak/missions already shipped in M3)
- Weekly themed limited-time events + event-only dogs (FOMO).
- Achievements/milestones (collect N, 100 steals, rebirth X).
- Leaderboards UI (rarest / most steals / richest) — `Steals` + `Rebirths` leaderstats tracked.
- Free battle-pass-style track.
- Codes system (creator-marketing lever).

**M5 monetization** (all non-pay-to-win; gacha stays coin-only)
- Game passes: 2× coins, auto-collect, extra slots, VIP.
- Dev products: coin packs, offline-refill/boost, extra steal charges, name/cosmetic tokens.
- Cosmetics: stand skins, trails/auras, cosmetic pets.

**Social (later)** — trading (with dupe/scam safeguards), parties/co-op, clans.

**Hardening / infra** — server-side anti-exploit validation + rate-limiting (deferred, but do
before public launch / before trading ships), AI-gen art pass, icon/thumbnail, soft-launch prep.
