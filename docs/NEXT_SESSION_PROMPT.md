# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). The game is **feature-complete through M4,
the M5 monetization CORE is live, and THE ADDITIONS SESSION shipped 2026-07-11/12** — all 17
items from Nate's `additions.txt` wishlist (76×58 plots + roofs + chef + real stations, the
Forbidden tier + steepened income curve, 7 floor-gated stove tiers, 120s cook + ready notify,
odds board + spinner-strip reveal, rarity auto-sort, commas + storage HUD, the **Security
Field** and **Vault Breaker** locked-rule overrides, full-street conveyor, the Glizzy Run obby,
and `docs/CONTENT_PLAN.md` for the clipfarm hookup). `additions.txt` is fully consumed.
Launch checklist: `docs/HANDOFF.md §Launch checklist`. **No live validation has EVER run** —
neither the old 2-player loop test nor any Studio look at the additions.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, the additions smoke checklist, launch checklist,
  gotchas. READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 built (incl. the additions
  inventory) · §6 tuning (all reasoned-not-observed) · §7 decision log (incl. the two override
  rows).
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — This session's work, in order

1. **If Nate is in Studio: run the additions smoke pass FIRST** (checklist in
   `docs/HANDOFF.md §What the NEXT session should do`). The whole 2026-07-11/12 batch is
   static-clean but has never rendered. Expect coordinate nits (chef pose, odds board size,
   roof overhangs, obby jump difficulty) — fix live, they're all constants in
   `PlotManager`/`ObbyService`. Also owed in the same sitting: Tool.Grip tuning
   (`PickupService.buildTool`), `StudioTestPasses` flips, onboarding arrows on a fresh profile.
2. **M5 remainder** (the build-order head):
   - **Cosmetics** — `CosmeticService`/`Cosmetics.client` are stubs; catalog + prestige prices
     already in `GameConfig.Cosmetics` (stand skins / trails / titles). Mirror the
     PrestigeShopService validate→charge→apply→push shape; persist in `data.cosmetics`
     (already in `_v5`). Stand skin = recolor pass over the plot shell; trail = attachment on
     the character; title = billboard chip on the owner sign.
   - **doubleCoins/autoCollect pass EFFECTS** — ownership detection already runs
     (`data.passes`). Fold `DoubleCoinsMult` in where `incomeMultiplier` composes (decide:
     multiplicative like income2x); design auto-collect (probably a no-op for now — income is
     already automatic — so it may become "auto-claim daily streak" or similar; confirm with
     Nate before building).
   - **`offlineRefill` dev product** — bespoke grant: re-run the offline calc ignoring the cap
     (or reset `lastSeen`?). Design first, then implement in `PurchaseService.ProcessReceipt`,
     and only THEN may Nate configure its dashboard id.
3. **Then M6 trading** — `TradeService`/`Trade.client` stubs; baseline safeguards locked
   (two-sided confirm + `TradeCooldownSeconds` + server log). Inventory moves are composite-key
   stack transfers; re-use `syncDisplay`/`pushInventory` after commit.
4. Keep an eye on the additions' balance knobs once seen live: blocker cycle (300/30), breaker
   price/drill (50k/10s), obby reward (100s) — §6 flags them reasoned-not-observed.

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
- **Data rules:** PlayerData fields go in the existing **`_v5`** back-fill (TOP level of the
  `type(result)=="table"` block — never nest). Failed load → nil → Main kicks (Studio falls back
  to a TEMP `unsaveable` profile — never weaken that split). Saves throttled + stale-write-guarded;
  autosave via `DataManager.startAutosave`.
- **Design-system rules:** world colors from `Theme.Palette`, states from `Theme.Semantic`, UI via
  `MenuLayout` helpers (`styleButton` is one-shot — flip colors directly for state changes).
  World text: ONE far label per plot; small/occludable/near-fade elsewhere. Neon only for small
  accents + gameplay signals. Rarity colors in `HotDogDex.RARITY`; variant colors in `Variants`.
- **Grants derive at read time** (`BuildGrants` / `displayCapacity` / `data.passes` pattern);
  `bonus*Slots` is exclusively the prestige shop's ledger. **All numbers render via
  `Format.comma`** — keep new UI on it.
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
  Event-only dogs live in `byName` but NOT `DOGS_BY_RARITY`; Forbidden IS a normal roster tier.
- **New server→client initial-state pushes** go in `Main.pushAllState` + ride `RequestState`
  (which COALESCES bursts). Yielding work NEVER inline in a push path.
- **Telemetry:** new funnel steps append with the NEXT number (never renumber); one-line
  `Telemetry.funnelStep/event` calls at the success point.
- **Reuse, don't reinvent:** service shape = `BuildService`/`ZoneService`/`ObbyService`; buy
  paths = `tryBuy`/`tryUpgrade`; world juice = the `Celebrate` remote; timers = os.time-derived
  cycles (blocker) or absolute-deadline client ticking (shield/cook countdown); alarms = the
  StealAlert/VaultBreach banner+arrow pattern in StealHud.

## Step 3 — Handoff ritual (DO THIS at each milestone / when you hand off) ⭐
**Nate's cadence:** batch the ritual — DON'T run the full doc-update after every feature, and
**DON'T commit after every feature**. Commit at coherent multi-feature checkpoints; do the docs
near a real context/agent handoff. When you do hand off:
1. **Validate** — stylua + selene + `rojo build` all clean (0/0). Never hand off a red build.
2. **Update docs** — `docs/HANDOFF.md`, `docs/ROADMAP.md`, `docs/BACKLOG.md`,
   `docs/design/GAME_DESIGN.md` (§5/§6/§7), and `CLAUDE.md`'s code map + status.
3. **Rewrite THIS file** for the next session (point it at the new top-of-build-order work; keep
   this Step 3 ritual intact so it self-perpetuates).
4. **Push only when Nate asks.** Commit locally at checkpoints; Nate's standing instruction is
   **don't push**.

That's the loop: **plan → implement in batches → validate → (at handoff) docs + rewrite this prompt.**

## Standing caveats
- **No live validation has ever run.** The additions smoke pass (single-player) and the
  2-account loop test on the PUBLISHED place are the human gates before public (HANDOFF).
- **⚠️ The `NATE` code is OPEN and grants 1B coins once to anyone** — launch-checklist delete.
  (Capture clipfarm footage BEFORE deleting it; see `docs/CONTENT_PLAN.md §5`.)
- The Security Field + Vault Breaker deliberately override old locked rules — their §7 rows are
  the record; don't "fix" them back without Nate.
- All `GAME_DESIGN §6` numbers are reasoned-not-observed — including the whole additions batch
  (new income ladder, stove tiers, blocker/breaker/obby knobs).
- **M5 end-to-end testing needs real pass/product ids** from Nate's dashboard; until then use
  `GameConfig.StudioTestPasses`. Do NOT configure `offlineRefill`'s id until its bespoke grant
  is implemented.
- Nate asset passes still open (zero code): `GameConfig.Sounds` ids (now incl. `CookReady`,
  `BlockerOpen`, `VaultDrill`) · `GlizzyMeshIds` · `SkyboxAssetId`.
