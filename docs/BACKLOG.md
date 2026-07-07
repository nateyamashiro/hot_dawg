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

- **Spend prestige currency** — next code feature; first premium-unlock sink (banked but unused today).
  Also closes the `mutationLuck` `luckBonus` loop the mutations feature stubbed.
- **2-player Studio playtest** of M2 + M3 + mutations (validate feel; tune the numbers in `GAME_DESIGN §6`).

## ✅ Shipped since the Top 10 (static-clean; playtest owed)

- **Mutations / variants** (2026-07-08) — random Gold/Rainbow/Giant mint on cook (`GameConfig.MutationChance`),
  composite-key inventory (`"Name#Gold"` in the existing `hotDogs` map). Made every read path
  variant-aware: `HotDogDex.getByKey`, `sortedUnits→{Unit}` (carries the key), `Main.incomePerSecond`,
  dex-completion (collapses keys to base names), `PlotManager`/`StealService` (key-based transfer +
  variant labels/tint), and a variant-coloured `CookResult` reveal. No DataStore bump.
  **Still open:** steal-path minting (`MutateOnSteal`, off) + real `luckBonus` (needs a `mutationLuck` field).
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
- 🏗️ Traps (`DefenseService` trap case + `PlotManager.trapModel`) — ~complete, needs polish/UI.
- 🏗️ Manual vault selection (`Main` `SetVaultPin` handler + `PlotManager.syncDisplay` TODO; needs a
  Dex pin UI + honoring `vaultPins` in the vault fill).

**M3 remainder** (rotating shop + mutations shipped; per-day cap scaffolded via `shopBuys`/`ShopDailyBuyCap`)
- 🏗️ Prestige-currency spending (`PrestigeShopService`/`PrestigeShop.client`) — **next up.**
- 🏗️ Duplicates → fusion (`FusionService`/`Fusion.client`) — note `GameConfig.FusionForcesMutation`
  can reuse `Variants.pickMint`/`MutationService` now that the variant layer is live.

**M4 retention** (daily streak/missions already shipped in M3)
- 🏗️ Weekly events + event-only dogs (`EventService`/`Events.client`).
- 🏗️ Achievements/milestones (`AchievementService`/`Achievements.client`).
- 🏗️ Leaderboards via OrderedDataStore (`LeaderboardService`/`Leaderboards.client`).
- 🏗️ Codes system (`CodesService`/`Codes.client`) — mostly complete. · Free battle-pass track — later.

**M5 monetization** (all non-pay-to-win; gacha stays coin-only)
- 🏗️ Game passes — **Extra slots + VIP first**, then 2× coins / auto-collect (`PurchaseService`).
- 🏗️ Dev products via `ProcessReceipt` (`receiptHistory` dedup in `_v5`).
- 🏗️ Cosmetics: stand skins, trails/auras, titles (`CosmeticService`/`Cosmetics.client`).

**Social (later)** — 🏗️ trading (baseline safeguards, `TradeService`/`Trade.client`), 🏗️ emotes
(`EmoteService`), parties/co-op, clans.

**Hardening / infra** — 🏗️ `RateLimit` spine exists + guards new remotes; do the **FULL** pass (wrap
every `OnServerEvent`) before trading ships / before public launch. Then AI-gen art pass,
icon/thumbnail, soft-launch prep.
