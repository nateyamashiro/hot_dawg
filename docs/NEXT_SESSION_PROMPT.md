# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). Everything through **M4 retention is
code-complete**: the visual overhaul + tycoon layer (design system, procedural glizzies, building
shell, conveyor, upgraders, blasters, zones) AND the M4 systems — weekly events (modifiers live in
the real math), OrderedDataStore leaderboards, achievements, manual vault selection (📌 Dex pins),
plus the **full anti-exploit hardening pass** (every `OnServerEvent` rate-limited + arg-guarded).
Nate **waived the 2-player playtest** ("act like it worked") — systems are accepted; keep building
down the build order. Note honestly: no live validation has run, so `GAME_DESIGN §6` numbers are
reasoned, not observed.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, scaffold facts, tycoon-layer gotchas. READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 built · §6 tuning · §7 decision log.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs
  (`monetization/` covers MarketplaceService + ProcessReceipt).

## Step 1 — What's NEXT (build order)

1. **M5 monetization — make `PurchaseService` real (top priority):**
   - **Passes first, locked order: Extra-slots + VIP** (`GameConfig.GamePassIds.extraSlots`/`vip`).
     Ids are `0` until Nate creates them on the Creator Dashboard — build id-agnostic: check
     `UserOwnsGamePassAsync` on join (cache in `data.vip` / fold `ExtraSlotsPassDisplay/Vault`
     into `bonus*Slots`-style read paths), `PromptGamePassPurchasePrompt` flow, skip checks
     cleanly while an id is 0.
   - **Dev products** via `ProcessReceipt` (`coinsSmall/Large`, `offlineRefill`, `stealCharges` —
     grants in `GameConfig.ProductGrants`). `receiptHistory` dedup field already exists in `_v5`.
     ProcessReceipt MUST be idempotent + return `PurchaseGranted` only after the grant saves.
   - **Then cosmetics** (`CosmeticService`/`Cosmetics.client` stubs): stand skins/trails/titles,
     coin-priced first (Robux cosmetics can come later). `data.cosmetics` is in `_v5`.
   - **Never paid gacha** — cook rolls stay coin-only (locked).
2. **Loose ends (small, slot in anywhere):** `CodesService` finishing touches · traps polish/UI ·
   steal-path minting (`GameConfig.MutateOnSteal`) · event-only dogs (content) · shop per-day cap
   (`shopBuys`/`ShopDailyBuyCap`).
3. **Then M6 social** — trading is now UNBLOCKED (the hardening pass shipped 2026-07-09):
   `TradeService` two-sided confirm + cooldown + log (baseline safeguards locked, GDD §7).
4. Nate asset passes (zero code, whenever): `GameConfig.Sounds` ids · `GlizzyMeshIds` meshes ·
   `SkyboxAssetId` · **pass/product ids on the Creator Dashboard** (unblocks M5 end-to-end tests).

## Step 2 — Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/build logic in
  `src/server`; `src/client` displays + fires RemoteEvents; shared config/tokens in `src/shared`.
  EVERY `OnServerEvent` gets `RateLimit.check` + type/length arg guards (the codebase is now 100%
  covered — keep it that way).
- `--!strict` atop every file; StyLua (tabs, 100 col); Selene clean. **Lua gotcha:** never start a
  line with `(` — resolve remotes into named locals in `init()`.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Design-system rules:** world colors from `Theme.Palette`, gameplay states from
  `Theme.Semantic`, UI via `MenuLayout` helpers (styleButton/makeWindow/addChrome — note
  `styleButton` is one-shot: it stacks chrome/connections if re-called; flip colors directly for
  state changes). Rarity colors live in `HotDogDex.RARITY`; variant colors in `Variants.DEFS`.
- **Grants derive at read time** — building/zone effects come from `data.built`/`data.zoneLvl`
  via `BuildGrants`/`displayCapacity`, never banked. Pass effects should follow the same spirit
  (check ownership at read/join, don't bake grants into unrelated fields).
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
- **PlayerData changes:** add fields to the existing **`_v5`** back-fill in `DataManager.load`.
- **New server→client initial-state push** goes in `Main.pushAllState` + rides `RequestState`
  (which now COALESCES over-limit bursts — don't turn that back into a plain connect).
- **Event modifiers pattern:** consumers read `EventService.activeModifier()` where the math
  lives (income in `incomeMultiplier`, cook price in cook-10) — don't duplicate income paths.
- **Reuse, don't reinvent:** service shape = `BuildService`/`ZoneService`; buy paths =
  `UpgradeService.tryBuy`/`UpgraderService.tryUpgrade`; world juice = the `Celebrate` remote;
  determinism = ShopService's day-index / EventService's week-index trick.

## Step 3 — Handoff ritual (DO THIS at each milestone / when you hand off) ⭐
**Nate's cadence note:** DON'T run the full doc-update ritual after every feature — only near a real
context/agent handoff. Batch it. When you do hand off:
1. **Validate** — stylua + selene + `rojo build` all clean (0/0). Never hand off a red build.
2. **Update docs** — `docs/HANDOFF.md`, `docs/ROADMAP.md`, `docs/BACKLOG.md`,
   `docs/design/GAME_DESIGN.md` (§5/§6/§7), and `CLAUDE.md`'s code map + status.
3. **Rewrite THIS file** for the next session (point it at the new top-of-build-order work; keep
   this Step 3 ritual intact so it self-perpetuates).
4. **Push only when Nate asks.** Commit locally is fine; Nate's standing instruction is
   **don't push**.

That's the loop: **implement a phase → validate → (at handoff) update docs + rewrite this prompt.**

## Standing caveats
- **The 2-player playtest was waived, not passed.** If anything looks off in Studio later
  (geometry overlaps, steal pathing on floors 2/3, double income on rejoin, contrast), fix on
  sight — there is no live-validated baseline.
- All `GAME_DESIGN §6` numbers (costs, cooldowns, catalog/conveyor prices, event points/rewards)
  are reasoned-not-observed; tune when real sessions happen.
- **M5 needs Studio "API Services" enabled + real pass/product ids** for end-to-end testing;
  until Nate creates ids, validate logic with the ids-are-0 skip paths + unit-style reasoning.
