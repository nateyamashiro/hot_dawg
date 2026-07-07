# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle tycoon (repo `hot_dawg`). **Milestones 1–3 are built and static-clean**, the
**entire remaining game (M3-remainder → M7) has been planned and scaffolded as compiling stubs**
(DataStore `_v5`; `Variants`/`MenuLayout` shared modules; 11 new server services + `RateLimit`; 10
client tray panels; all wired into `Main`), and the **first scaffolded feature — mutations-on-cook —
is now shipped for real** (2026-07-08). Your job: **keep implementing the scaffolded features one at
a time, in build order** — fill in the `TODO(<milestone>)` markers, don't re-architect.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status + the **🏗️ scaffold section** (composite-key/mutation
  model, `_v5` fields, `MenuLayout` tray, `RateLimit`, handshake, build order). READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — **§4** locked decisions · **§5** what's built (incl. mutations)
  · **§6** every tuning value · **§7** decision log (the 4 forks).
- **`docs/ROADMAP.md`** / **`docs/BACKLOG.md`** — the `🏗️` items are the stubs left to fill in.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — Pick the next feature (build order: retention depth before content)
Do the **top unimplemented item**, then stop and hand off (see Step 3). Order:
1. **M3 remainder:** ~~mutations ✅~~ → **prestige spending (← next)** → fusion → manual vault
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
> assume a key is a bare dog name. Two small follow-ups remain if you want them: steal-path minting
> (`GameConfig.MutateOnSteal`, off) and feeding a real `luckBonus` into `maybeMint` — the latter
> depends on prestige (below) banking a `mutationLuck` field, so **do prestige first**.

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

## Current top of the build order → **Prestige spending** (`PrestigeShopService` + `PrestigeShop.client`)
The first prestige-currency sink (`data.prestige` is banked from rebirths + the dex reward but has
nothing to spend on today). Self-contained, and implementing its `mutationLuck` effect closes the
`luckBonus` loop the mutations feature left stubbed. The catalog already exists —
`GameConfig.PrestigeShopItems` (income +10%, +1 display slot, +1 vault slot, +50% mutation luck).

Fill in the `TODO(M3-prestige)` markers in `PrestigeShopService`:
- On `BuyPrestige(itemId)`: validate the item exists + `data.prestige >= item.cost`, deduct the cost,
  then apply the `effect`:
  - `incomeMult` → a persistent income bonus. **Design fork to resolve:** there's no `prestigeIncomeMult`
    field yet — either add one to the `_v5` back-fill and fold it into `Main.incomeMultiplier`, or map
    the effect onto an existing knob. Pick the simplest correct option and note it in the decision log.
  - `bonusDisplay` / `bonusVault` → bump `data.bonusDisplaySlots` / `data.bonusVaultSlots` (fields
    already exist in `_v5`) and call `PlotManager.syncDisplay`. **Note:** `PlotManager` has a
    `TODO(M5-mon)` to actually add `bonus*Slots` on top of the coin-upgrade capacity — wire that here.
  - `mutationLuck` → add a `mutationLuck` field to `_v5` and pass it as the `luckBonus` arg of
    `MutationService.maybeMint` in `Main.doCook` (this is the stubbed loop; closing it is the point).
- After any change: `updateLeaderstats` + `pushProgression` + re-push the prestige shop
  (`PrestigeShopService.pushShop`, already in `Main.pushAllState`).
- Client `PrestigeShop.client`: render the catalog + the player's prestige balance, wire buy buttons,
  reflect owned/afforded state. Follow the `MenuLayout` tray pattern the other panels use.

Then follow the order in Step 1 (fusion next — and note `GameConfig.FusionForcesMutation` can now
reuse `Variants.pickMint` / `MutationService`).
