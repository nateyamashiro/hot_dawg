# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle tycoon (repo `hot_dawg`). **Milestones 1–3 are built and static-clean**, the
**entire remaining game (M3-remainder → M7) has been planned and scaffolded as compiling stubs**
(DataStore `_v5`; `Variants`/`MenuLayout` shared modules; 11 new server services + `RateLimit`; 10
client tray panels; all wired into `Main`), and the **first two scaffolded features — mutations-on-cook
and prestige spending — are now shipped for real** (2026-07-08). Your job: **keep implementing the
scaffolded features one at a time, in build order** — fill in the `TODO(<milestone>)` markers, don't
re-architect.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status + the **🏗️ scaffold section** (composite-key/mutation
  model, `_v5` fields, `MenuLayout` tray, `RateLimit`, handshake, build order). READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — **§4** locked decisions · **§5** what's built (incl. mutations +
  prestige spending) · **§6** every tuning value · **§7** decision log (forks).
- **`docs/ROADMAP.md`** / **`docs/BACKLOG.md`** — the `🏗️` items are the stubs left to fill in.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — Pick the next feature (build order: retention depth before content)
Do the **top unimplemented item**, then stop and hand off (see Step 3). Order:
1. **M3 remainder:** ~~mutations ✅~~ → ~~prestige spending ✅~~ → **fusion (← next)** → manual vault
   selection → traps polish.
2. **M4 retention:** weekly events → achievements → leaderboards (OrderedDataStore) → codes.
3. **Anti-exploit hardening pass** (wrap every `OnServerEvent` in `RateLimit` + validation) — **before
   M5/M6 and launch.**
4. **M5 monetization:** passes (Extra-slots + VIP first) + dev products → cosmetics.
5. **M6 social:** trading (baseline safeguards) → emotes → parties → clip juice.
6. **M7 polish:** AI art, audio, onboarding, icon/thumbnail, analytics, soft-launch checklist.

Each feature's stub names exactly where the real logic goes. If a feature is large or has a genuine
design fork, **EnterPlanMode** and use **AskUserQuestion** before writing code.

> ✅ **Mutations are DONE — use them as the reference pattern.** `data.hotDogs` is composite-key
> stacks (`"Chicago Dog#Gold"`); `MutationService.maybeMint` is wired into `Main.doCook`; every read
> path decodes via `src/shared/Variants.luau` / `HotDogDex.getByKey` / `HotDogDex.sortedUnits→{Unit}`.
> **Any new code that touches `data.hotDogs` keys must go through `Variants`/`getByKey`** — never
> assume a key is a bare dog name. Prestige spending is also DONE (one-time unlocks bank into `_v5`
> fields; `mutationLuck` now feeds `maybeMint`, so the `luckBonus` loop is closed). One small mutations
> follow-up remains if you want it: steal-path minting (`GameConfig.MutateOnSteal`, off by default).

## Step 2 — Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/upgrade/monetization/trade
  logic in `src/server`; `src/client` only displays state + fires RemoteEvents; shared config/data in
  `src/shared`. Guard new remotes with `RateLimit.check` + type checks.
- `--!strict` atop every file; StyLua (tabs, 100 col); Selene clean. **Lua gotcha:** never start a
  line with `(` — resolve remotes into named locals in `init()`.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Inventory is composite-key stacks** (`"Name#Gold"`); all variant math lives in `src/shared/Variants.luau`.
- **PlayerData changes:** add fields to the existing **`_v5`** back-fill in `DataManager.load` (don't
  bump `_vN` again unless the shape truly breaks). Keep `defaultData()` building fresh tables.
- **Any new server→client initial-state push** must be added to `Main.pushAllState` AND requested via
  the client's `RequestState:FireServer()`, or it's lost to the join race.
- **New bottom-menu UI** uses `MenuLayout` (primary row `primaryPosition`, or a tray panel via
  `makeTrayToggle` + `makePanel`) — never hardcode positions.
- Assume M2/M3 feel is validated; you may still tune `GameConfig` numbers as features require.

## Step 3 — Handoff ritual (DO THIS EVERY TIME, at each milestone / when you hand off) ⭐
When you finish a coherent feature that leaves the game in a **working, validated state** (or you're
running low on context/time), before ending the session you MUST:
1. **Validate** — stylua + selene + `rojo build` all clean (0/0). Never hand off a red build.
2. **Update the docs** — `docs/HANDOFF.md` (status + any new gotcha), `docs/ROADMAP.md`,
   `docs/BACKLOG.md`, `docs/design/GAME_DESIGN.md` (§5 built / §6 tuning / §7 decision log for any new
   forks), and `CLAUDE.md`'s code map + status. Mark the feature done; move `🏗️` → shipped.
3. **Rewrite THIS file** (`docs/NEXT_SESSION_PROMPT.md`) for the next session — point it at the new
   top-of-build-order feature, carry forward any fresh gotchas, and **keep this Step 3 handoff ritual
   intact** so it self-perpetuates.
4. **Commit and push to `main`** — this project uses a simple solo main-branch workflow (GDD §4.13),
   and pushing at milestone handoffs is **standing authorization**. Commit with a clear message, then
   `git push origin main`. (Commit locally as you go mid-feature; push at the handoff.) End commit
   messages with the `Co-Authored-By: Claude` trailer.

That's the loop: **implement one feature → validate → update docs → rewrite this prompt → commit &
push to main → hand off.** Every subsequent session repeats it.

---

## Current top of the build order → **Duplicates → fusion** (`FusionService` + `Fusion.client`)
Combine N duplicates of one inventory KEY into a better outcome — the collection sink that gives
spare dupes a purpose. The stub already validates ownership of `GameConfig.FusionInputs` (5) of the
key + wires the `Fuse` remote (rate-limited). Because inventory is composite-key stacks, fusion
operates on keys, so Gold/Rainbow/etc. dupes fuse too — decode via `Variants` / `HotDogDex.getByKey`.

Fill in the `TODO(M3-fusion)` marker in `FusionService.onFuse`:
- Consume `GameConfig.FusionInputs` of `key` (decrement / clear the stack), then grant the result.
  **Design fork to resolve — what does fusion produce?** Two levers already exist in config:
  - `GameConfig.FusionForcesMutation` (true) → mint a mutation on the fused dog. You can reuse
    `Variants.pickMint()` / `Variants.encode(baseName, variant)` (or `MutationService`) to force a
    variant on the same base dog — the cleanest first version (turn 5 plain dupes into 1 mutated one).
  - Or "upgrade one rarity tier" → you'd need a `HotDogDex` helper to find the next dog up a tier
    (doesn't exist yet). **Recommend** starting with force-mutation (self-contained, reuses the live
    variant layer); note the choice in the GDD §7 decision log.
  - Decide the edge cases: fusing an already-mutated stack (bump to a rarer variant? refuse?), and
    what tier/variant the result lands on. Keep it server-authoritative + validated.
- After granting: `updateLeaderstats` + `PlotManager.syncDisplay` + `onInventoryChanged` (already in
  the stub tail) so the dex/pedestals refresh.
- Client `Fusion.client`: let the player pick a key with ≥`FusionInputs` dupes and fire `Fuse(key)`;
  reflect which stacks are fusable. Follow the `MenuLayout` tray pattern the other panels use. You'll
  likely want the `InventoryUpdate` snapshot (already pushed) to know stack counts client-side.

Then follow the order in Step 1 (manual vault selection next: honour `data.vaultPins` in
`PlotManager.syncDisplay` + a Dex pin UI; the `SetVaultPin` handler already exists in `Main`).
