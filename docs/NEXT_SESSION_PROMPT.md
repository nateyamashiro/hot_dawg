# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). Milestones 1–3 + the M3-remainder features
(**mutations-on-cook, prestige spending, fusion**) are built and static-clean. The project is now
mid-way through a **VISUAL OVERHAUL + CLASSIC-TYCOON LAYER** (Nate's direction after a Studio look):
bigger stands, a physical walk-on-pad tycoon loop, passive income, and a de-cluttered UI. Your job:
**keep implementing that overhaul phase-by-phase** per the plan, don't re-architect.

## Step 0 — Read these first (all the context lives here)
- **The overhaul PLAN:** `C:\Users\jwgri\.claude\plans\inherited-hugging-alpaca.md` — the phased plan
  Nate approved (context, locked decisions, phases, key files). READ FIRST.
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status + the scaffold section (composite-key/mutation model,
  `_v5` fields, `MenuLayout`, `RateLimit`, handshake, build order). READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 what's built · §6 tuning · §7 decision log.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — What's DONE in the overhaul, and what's NEXT

**DONE this stretch (all static-clean; NOT yet 2-player-playtested):**
- **Fusion** shipped (5 dupes of a key → 1 of the same base dog one variant up the ladder).
- **Phase 0 scaffold + quick wins:** enlarged plots; brand-new players spawn with 1 random Common
  glizzy (gated on first-join in `DataManager.load`); ALL overhaul config blocks + `_v5` data fields
  added; compiling stubs for 6 new services (`AutoCooker`, `Build`, `Weapon`, `Conveyor`, `Upgrader`,
  `Zone`) wired into `Main`; `MenuLayout.makeWindow` (drag/minimize/close) skeleton added.
- **Physical tycoon stations (the big one):** a reusable **walk-on pad framework** in `PlotManager`
  (`makeBuyPad`/`updatePads`/`setStove`/`setPadHandler`/`setCookHandler`), a **🌭 Cook Station**
  (ProximityPrompt, reuses the cook roll), a **🔥 Stove** for passive un-stealable coins (starts
  UNBUILT at `autoCookerLvl 0`; built + upgraded via a walk-on pad; income folded into the tick loop
  AND offline earnings), and **walk-on upgrade pads** for grill/display/vault (reuse
  `UpgradeService.tryBuy`). Pads are **GREEN when affordable / RED when too expensive**, refreshed
  live each tick. `Main.syncPads` computes pad labels/affordability; `Main.cookOne` is the shared cook
  path for both the button and the station.
- **Cook is now GATED:** the single Cook (button + station) is **FREE but on a cooldown**
  (`GameConfig.CookCooldownSeconds`, 300s / 5 min) via `data.cookReadyAt` — the "wall" so glizzies
  can't be spammed (encourages longer sessions). **Cook-10 stays PAID** (`CookCost`×10) as the "pay
  coins to skip the wait / bulk" bypass.

**NEXT — finish the tycoon per the plan (in order):**
1. **Building shell / "plot → stand" (Phase 3, the top priority):** flesh out `BuildService` (stub)
   so walk-on **build pads** raise the actual structure — the bare plot visibly **grows into a stand**
   (floors/stairs/elevator, then walls/gate). `GameConfig.BuildCatalog` + `data.built` exist; you'll
   add `PlotManager.spawnStructure`/`rebuildStructures` hooks + the build pads (extend `PAD_LAYOUT` or
   add a second pad group). This is exactly what Nate asked to see next.
2. **Phase 2 — UI overhaul:** migrate the 16 client panels + HUD/steal widgets onto
   `MenuLayout.makeWindow` (drag/minimize/close) + a consolidated toolbar, so the screen is clean by
   default. (Approach locked: shared-window upgrade, NOT a full rebuild.)
3. **Phase 4 — Conveyor lane + cooker upgraders** (`ConveyorService`/`UpgraderService` stubs).
4. **Phase 5 — Non-damaging weapons + zone expansion** (`WeaponService`/`ZoneService` stubs; weapons
   are slow/knockback/stun only — locked all-ages tone).

> The **old on-screen upgrade menu is now redundant** with the walk-on pads (kept as a fallback). Nate
> may want it removed — ask.

## Step 2 — Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/upgrade/tycoon logic in
  `src/server`; `src/client` only displays + fires RemoteEvents; shared config/data in `src/shared`.
  Guard new remotes with `RateLimit.check` + type checks.
- `--!strict` atop every file; StyLua (tabs, 100 col); Selene clean. **Lua gotcha:** never start a
  line with `(` — resolve remotes into named locals in `init()`.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Inventory is composite-key stacks** (`"Name#Gold"`); all variant math in `src/shared/Variants.luau`.
- **PlayerData changes:** add fields to the existing **`_v5`** back-fill in `DataManager.load` (don't
  bump `_vN` unless the shape truly breaks). Keep `defaultData()` building fresh tables.
- **New server→client initial-state push** must be added to `Main.pushAllState` AND requested via the
  client's `RequestState:FireServer()`.
- **New walk-on pads:** add to `PlotManager.PAD_LAYOUT` (id + local offset) + route the id in
  `Main`'s `setPadHandler`; drive labels/affordability from `Main.syncPads`.
- **New bottom-menu UI** uses `MenuLayout` (`makeWindow` for panels, `makeTrayToggle` for the tray).
- **Reuse, don't reinvent:** service shape = `FusionService`/`PrestigeShopService`; buy paths =
  `UpgradeService.tryBuy` / `AutoCookerService.tryUpgrade`; carry state = `StealService`.

## Step 3 — Handoff ritual (DO THIS at each milestone / when you hand off) ⭐
**Nate's cadence note:** DON'T run the full doc-update ritual after every feature — only near a real
context/agent handoff (when usage/context is winding down). Batch it. When you do hand off:
1. **Validate** — stylua + selene + `rojo build` all clean (0/0). Never hand off a red build.
2. **Update docs** — `docs/HANDOFF.md`, `docs/ROADMAP.md`, `docs/BACKLOG.md`,
   `docs/design/GAME_DESIGN.md` (§5/§6/§7), and `CLAUDE.md`'s code map + status.
3. **Rewrite THIS file** for the next session (point it at the new top-of-build-order work; keep this
   Step 3 ritual intact so it self-perpetuates).
4. **Push only when Nate asks.** Commit locally is fine; this session Nate said **don't push**.

That's the loop: **implement a phase → validate → (at handoff) update docs + rewrite this prompt.**

## Still owed (needs a human)
- **2-player Studio playtest** of everything M2/M3 + the new tycoon layer (Test → Clients and Servers;
  enable Game Settings → Security → API Services for DataStore). Nate drives this; it's the outstanding
  validation and the source of `GAME_DESIGN §6` tuning. Confirm: bigger stands read well; new player
  spawns with 1 Common; Build-Stove pad (FREE) → stove ticks un-stealable coins; pads red/green; cook
  station works but is 5-min-gated; upgrade pads charge + recolor.
