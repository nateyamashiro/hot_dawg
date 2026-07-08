# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). Milestones 1–3 + M3-remainder features
(mutations, prestige spending, fusion) are built, and the **entire visual design system + building
shell just shipped** (design plan phases P-A→P-E): Theme tokens, procedural glizzy models, world
lighting/street, the 15-entry build catalog with walk-on 🏗️/🎪 pads, the juice pass (Celebrate
remote), and the themed window UI. Everything is static-clean but **none of it has been seen live**.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, scaffold facts, tycoon-layer gotchas. READ FULLY.
- **The design plan:** `C:\Users\jwgri\.claude\plans\i-want-you-to-wild-abelson.md` — the executed
  visual roadmap (palette, builders' exact geometry, balance rules §2.7, phase gates). The earlier
  overhaul plan is `inherited-hugging-alpaca.md` (Phases 4–5 still pending).
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §6 tuning numbers (playtest-unconfirmed).
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — What's DONE, and what's NEXT

**DONE this stretch (static-clean; NOT playtested, NOT pushed):**
- **P-A facelift:** `Theme.luau` (single source for world palette/semantic/lighting/UI/VFX budgets);
  `GlizzyModel.luau` real hot dogs on pedestals/vault/carries (rarity aura ladder, Gold/Rainbow/Giant;
  AI-mesh swap slot `GameConfig.GlizzyMeshIds` — SpecialMesh on purpose, don't "upgrade" to MeshPart);
  `EnvironmentService` bright-noon lighting + grass/street/sidewalks/lamps; `GlizzyFx.client`
  Rainbow hue-cycling + emitter culling.
- **P-B building shell:** walk onto the 🏗️ pad → the stall grows (floor2→stairs→wall→floor3→gate→
  elevator); 🎪 pad → income decors (+27% total). `BuildGrants` derives ALL grants from `data.built`
  at read time (rebuild-on-join can't double-apply). Old DefenseService wall RETIRED + grandfathered.
  Balance rules are LOCKED (§2.7): ground route always open, gates slow never block, every floor has
  a free theft route (truss/jumpable rails/everyone-elevator).
- **P-C juice:** `Celebrate` remote (cook burst/purchase pop/build dust/steal alarm/Giant shake),
  `Sfx.luau` (silence-safe until `GameConfig.Sounds` ids are filled), coin sparkle, reveal viewport.
- **P-D UI:** every panel is now a draggable Cream window with a ketchup-gradient title bar via
  `MenuLayout` (makePanel = makeWindow); NEW `Build.client` window; tray gained "Build".
- **P-E:** bun hills / mustard river / ketchup geyser horizon props.

**NEXT (in order):**
1. **2-player Studio playtest** (see "Still owed" below) — Nate drives; everything gates on this.
   Fix whatever it surfaces (geometry overlaps, pad feel, steal pathing on floors 2/3, contrast).
2. **Overhaul Phase 4 — conveyor lane + cooker upgraders** (`ConveyorService`/`UpgraderService`
   stubs): hot dogs ride the central street belt, step to buy; upgraders multiply stove output.
   Visuals REUSE `Theme` + `GlizzyModel` (that's why they shipped first).
3. **Overhaul Phase 5 — weapons + zones** (`WeaponService`/`ZoneService` stubs; weapons are
   slow/knockback/stun only — locked all-ages tone).
4. **Nate's asset passes (non-blocking, zero code):** fill `GameConfig.Sounds` (10 ids) and
   `GameConfig.GlizzyMeshIds` (per-dog meshes); optionally `SkyboxAssetId`.

## Step 2 — Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/build logic in
  `src/server`; `src/client` displays + fires RemoteEvents; shared config/tokens in `src/shared`.
  Guard new remotes with `RateLimit.check` + type checks.
- `--!strict` atop every file; StyLua (tabs, 100 col); Selene clean. **Lua gotcha:** never start a
  line with `(` — resolve remotes into named locals in `init()`.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Design-system rules:** world colors come from `Theme.Palette`, gameplay states from
  `Theme.Semantic`, UI from `MenuLayout`'s tokens/helpers (styleButton/makeWindow/addChrome).
  Rarity colors stay in `HotDogDex.RARITY`; variant colors in `Variants.DEFS`. VFX must fit a
  `Theme.VFX` budget row. New structures follow the chunk rules (Theme §1.3 comments) and the
  §2.7 theft-access rules — never remove access, sell TIME.
- **Building grants:** always derive from `data.built` via `BuildGrants` at read time. Never bank a
  building effect into another field.
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
- **PlayerData changes:** add fields to the existing **`_v5`** back-fill in `DataManager.load`.
- **New server→client initial-state push** goes in `Main.pushAllState` + rides `RequestState`.
- **New walk-on pads:** `PlotManager.PAD_LAYOUT` + route in `Main.setPadHandler` + label from
  `Main.syncPads`.
- **Reuse, don't reinvent:** service shape = `BuildService`/`FusionService`; buy paths =
  `UpgradeService.tryBuy`/`AutoCookerService.tryUpgrade`; world juice = the `Celebrate` remote.

## Step 3 — Handoff ritual (DO THIS at each milestone / when you hand off) ⭐
**Nate's cadence note:** DON'T run the full doc-update ritual after every feature — only near a real
context/agent handoff. Batch it. When you do hand off:
1. **Validate** — stylua + selene + `rojo build` all clean (0/0). Never hand off a red build.
2. **Update docs** — `docs/HANDOFF.md`, `docs/ROADMAP.md`, `docs/BACKLOG.md`,
   `docs/design/GAME_DESIGN.md` (§5/§6/§7), and `CLAUDE.md`'s code map + status.
3. **Rewrite THIS file** for the next session (point it at the new top-of-build-order work; keep this
   Step 3 ritual intact so it self-perpetuates).
4. **Push only when Nate asks.** Commit locally is fine; Nate's standing instruction this stretch is
   **don't push**.

That's the loop: **implement a phase → validate → (at handoff) update docs + rewrite this prompt.**

## Still owed (needs a human) — THE playtest
**2-player Studio playtest** (Test → Clients and Servers, 2 players; enable Game Settings →
Security → API Services for DataStore). This now covers M2/M3 **and** the whole new look + shell:
- World reads: bright noon, clouds, street/sidewalks/lamps, bun-hill horizon; plots are cream/brown
  stalls with counters + posts; real hot dogs on pedestals (rarity glow ladder visible), vault gold.
- New player: spawns at their stand with 1 Common glizzy showing; pads green/red; FREE cook 5-min
  gate works; stove builds + ticks un-stealable coins.
- **Build chain:** 🏗️ pad offers floor2 first → stairs → wall → floor3 → gate → elevator; 🎪 pad
  walks the decors; pedestals appear on floors 2/3 and FILL after cooks; income % rises with decor;
  **rejoin rebuilds everything exactly once** (watch for double income / double structures).
- **Steal pathing:** player 2 climbs the stairs/truss and steals from floor 2/3; wall gap + gate slow
  but never block; carry rig is a welded glizzy; alarm flashes on the victim sign; Giant steals shake.
- UI: bottom row + tray toggles all mustard-styled; windows drag/minimize/pop; Build window lists
  ✅/🏗️/🔒 correctly; Upgrades/Rebirth windows still work.
- Then **tune `GAME_DESIGN §6`** numbers (costs, cooldown, catalog prices) to feel.
