# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). The ENTIRE visual overhaul + tycoon layer is
code-complete: design system, procedural glizzies, world/lighting, the 15-entry building shell,
juice pass, themed window UI, conveyor buy-lane, cooker upgraders, condiment blasters, and
prestige zones. Nate **waived the 2-player playtest** ("act like it worked") — systems are
accepted; keep building down the retention-first build order. Note honestly: no live validation
has run, so `GAME_DESIGN §6` numbers are reasoned, not observed.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, scaffold facts, tycoon-layer gotchas. READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 built · §6 tuning · §7 decision log.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — What's NEXT (build order: retention before content)

1. **M4 retention systems — make the stubs real (the top priority):**
   - **`EventService`** — weekly deterministic event (week-index trick like the shop),
     apply the active `modifier` (income2x / freeCookBursts / cookHalfPrice) where income/cook
     math lives, track `data.eventPoints`, pay `EventRewardTiers` claims. Panel exists.
   - **`LeaderboardService`** — OrderedDataStore top-N for coins/steals/rarest
     (`LeaderboardTopN`, `LeaderboardRefreshSeconds`); render three boards in the panel.
   - **`AchievementService`** — track metrics (dogs/steals/rebirths already in PlayerData),
     validate + pay one-time claims (`data.achievements`). Panel exists.
2. **Manual vault selection** — honour `data.vaultPins` in `PlotManager.syncDisplay` (its TODO:
   pinned keys fill the vault before the top-by-value overflow) + a pin toggle in the Dex
   (`SetVaultPin` remote already handled in `Main`).
3. **Hardening pass** — wrap every LEGACY `OnServerEvent` (cook/steal-era remotes) with
   `RateLimit.check` + arg guards. REQUIRED before trading (M6) and soft launch.
4. **Then M5 monetization** (PurchaseService: Extra-slots + VIP passes first — locked).
5. Nate asset passes (zero code, whenever): `GameConfig.Sounds` ids · `GlizzyMeshIds` meshes ·
   `SkyboxAssetId`.

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
- **Design-system rules:** world colors from `Theme.Palette`, gameplay states from
  `Theme.Semantic`, UI via `MenuLayout` helpers (styleButton/makeWindow/addChrome). Rarity colors
  live in `HotDogDex.RARITY`; variant colors in `Variants.DEFS`. VFX must fit a `Theme.VFX` budget
  row; new structures follow the chunk rules + §2.7 theft-access rules (sell TIME, never remove
  access).
- **Grants derive at read time** — building/zone effects come from `data.built`/`data.zoneLvl`
  via `BuildGrants`/`displayCapacity`, never banked into other fields.
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
- **PlayerData changes:** add fields to the existing **`_v5`** back-fill in `DataManager.load`.
- **New server→client initial-state push** goes in `Main.pushAllState` + rides `RequestState`.
- **New walk-on pads:** `PlotManager.PAD_LAYOUT` + route in `Main.setPadHandler` + label from
  `Main.syncPads`.
- **Reuse, don't reinvent:** service shape = `BuildService`/`ZoneService`; buy paths =
  `UpgradeService.tryBuy`/`UpgraderService.tryUpgrade`; world juice = the `Celebrate` remote;
  event determinism = `ShopService`'s day-index trick.

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
- All `GAME_DESIGN §6` numbers (costs, cooldowns, catalog prices, conveyor prices) are
  reasoned-not-observed; tune when real sessions happen.
