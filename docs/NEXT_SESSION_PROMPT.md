# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). The game is **feature-complete through M4
and deployment-ready on the code side**: tycoon layer + visual overhaul, M4 retention (events
with exclusive dogs, leaderboards + world podium, achievements), manual vault pins,
pick-up-and-hold (snatchable), the full anti-exploit hardening pass, **data-safety criticals
fixed** (load-retry+kick, `_v5` de-nest, autosave, stale-write guard), onboarding-funnel
telemetry + error logging, and the shop daily cap. The **launch checklist for Nate** lives in
`docs/HANDOFF.md §Launch checklist`. Note honestly: no live validation has run — the 2-player
test on the PUBLISHED place is the human gate before going public.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, launch checklist, gotchas. READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 built · §6 tuning · §7 decision log.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs
  (`monetization/` covers MarketplaceService + ProcessReceipt).

## Step 1 — What's NEXT (build order)

1. **M5 monetization — make `PurchaseService` real (top priority):**
   - **Passes first, locked order: Extra-slots + VIP** (`GameConfig.GamePassIds.extraSlots`/`vip`).
     Ids are `0` until Nate creates them on the Creator Dashboard — build id-agnostic: check
     `UserOwnsGamePassAsync` on join (cache into `data.vip` / fold `ExtraSlotsPassDisplay/Vault`
     into `bonus*Slots`), `PromptGamePassPurchase` flow, skip cleanly while an id is 0.
   - **Dev products** via `ProcessReceipt` (`coinsSmall/Large`, `offlineRefill`, `stealCharges` —
     grants in `GameConfig.ProductGrants`). `receiptHistory` dedup exists; the handler currently
     returns **NotProcessedYet for everything unmapped — keep that property**: only return
     `PurchaseGranted` AFTER a real grant persists.
   - **Then cosmetics** (`CosmeticService`/`Cosmetics.client` stubs), coin-priced first.
   - **Never paid gacha** — cook rolls stay coin-only (locked).
2. **Launch execution with Nate (checklist in HANDOFF):** publish → content questionnaire →
   icon/thumbnails → server size 15–20 → **2-account loop test on the published place** →
   watch the Analytics funnel.
3. **Loose ends (small, slot in anywhere):** `CodesService` non-coin rewards · traps polish/UI ·
   steal-path minting (`GameConfig.MutateOnSteal`) · Tool.Grip tune for held glizzies (visual,
   needs eyes in Studio).
4. **Then M6 social** — trading (unblocked: hardening shipped): `TradeService` two-sided confirm
   + cooldown + log (baseline safeguards locked, GDD §7).
5. Deferred: onboarding guided first-60s (GDD §4.9) · sounds/meshes/skybox (Nate assets) ·
   full session locking · StreamingEnabled evaluation (mobile memory).

## Step 2 — Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/build logic in
  `src/server`; `src/client` displays + fires RemoteEvents; shared config/tokens in `src/shared`.
  EVERY `OnServerEvent` gets `RateLimit.check` + type/length arg guards (100% covered — keep it).
- `--!strict` atop every file; StyLua (tabs, 100 col); Selene clean. **Lua gotcha:** never start a
  line with `(` — resolve remotes into named locals in `init()`.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Data rules:** PlayerData fields go in the existing **`_v5`** back-fill (NOTE: it sits at the
  TOP level of the `type(result)=="table"` block — never nest it inside another field's check).
  A failed load returns nil → Main kicks; never cache defaults on failure. Saves are throttled
  (5s guard) + stale-write-guarded; autosave runs via `DataManager.startAutosave`.
- **Design-system rules:** world colors from `Theme.Palette`, states from `Theme.Semantic`, UI via
  `MenuLayout` helpers (`styleButton` is one-shot — flip colors directly for state changes).
  World text: ONE far label per plot; everything else small/occludable/near-fade. Neon only for
  small accents + gameplay signals (Theme.Materials comment). Rarity colors in `HotDogDex.RARITY`;
  variant colors in `Variants.DEFS`.
- **Grants derive at read time** (`BuildGrants`/`displayCapacity` pattern); pass effects should
  follow the same spirit (check ownership at read/join, don't bake into unrelated fields).
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
  Event-only dogs live in `byName` but NOT `DOGS_BY_RARITY` — keep that invariant.
- **New server→client initial-state push** goes in `Main.pushAllState` + rides `RequestState`
  (which COALESCES over-limit bursts — don't turn that back into a plain connect).
- **Telemetry:** new funnel steps append to `Telemetry.luau`'s table with the NEXT number (never
  renumber); one-line `Telemetry.funnelStep/event` calls at the success point.
- **Reuse, don't reinvent:** service shape = `BuildService`/`ZoneService`; buy paths =
  `UpgradeService.tryBuy`/`UpgraderService.tryUpgrade`; world juice = the `Celebrate` remote;
  determinism = day-index (shop) / week-index (events) tricks.

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
- **No live validation has ever run.** The 2-account loop test on the PUBLISHED place is the
  mandatory human gate before public (checklist in HANDOFF): cook/steal/deposit/snatch, DataStore
  persistence across rejoin, autosave, leaderboards + podium filling, event tier-4 dog grant.
- All `GAME_DESIGN §6` numbers are reasoned-not-observed; tune when real sessions happen. The
  Analytics funnel (wired) is the tool for that once live.
- **M5 end-to-end testing needs Studio "API Services" + real pass/product ids** from Nate's
  dashboard; until then validate the ids-are-0 skip paths.
