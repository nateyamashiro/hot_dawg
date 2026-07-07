# HANDOFF — Steal a Glizzy 🌭

**Last updated:** 2026-07-08 (**Mutations-on-cook SHIPPED** — first scaffolded feature made real:
composite-key inventory is now fully variant-aware end-to-end and `MutationService.maybeMint` is
wired into `doCook`. Scaffold context below still applies for the rest of M3-remainder → M7.)
**For:** the next Claude Code session (and Nate)

## 🏗️ The scaffold (read this before implementing anything new)

The **entire remaining game (M3-remainder → M7) is planned + skeleton-scaffolded** as of 2026-07-07.
Every new system is a **compiling stub** — architecture in place, real logic marked `TODO(<milestone>)`.
Implement feature by feature; don't re-architect. Key facts:

- **Inventory is composite-key stacks, and mutations are LIVE.** `data.hotDogs` is still
  `{ [string]: number }`, but a key MAY encode a mutation: `"Chicago Dog"` = base,
  `"Chicago Dog#Gold"` = Gold variant. All encode/decode/income-multiplier math lives in
  **`src/shared/Variants.luau`**; `HotDogDex.getByKey` is the variant-aware lookup and
  `HotDogDex.sortedUnits` now returns `{Unit}` (each carries the inventory KEY + variant-scaled
  income + display label). **Mutations-on-cook shipped 2026-07-08:** every read path is variant-aware
  (income, pedestals/vault, steal transfer, dex-completion collapses composite keys to base names),
  and `MutationService.maybeMint` is wired into `Main.doCook`. **Pattern to copy:** any future code
  that touches `data.hotDogs` keys must decode via `Variants`/`getByKey`, never assume a key is a bare
  dog name. Still TODO: steal-path minting (`GameConfig.MutateOnSteal`, off by default) and a real
  `luckBonus` into `maybeMint` (needs PrestigeShop to bank a `mutationLuck` field).
- **DataStore is `_v5`** (`DataManager.luau`) — one migration batching every later field
  (`vaultPins`, `defenses.trap`, `achievements`, `redeemedCodes`, `eventPoints`, `vip`,
  `bonus*Slots`, `receiptHistory`, `tradeCooldownUntil`, `cosmetics`, `shopBuys`). All optional +
  back-filled from defaults, so `_v4`/`_v3` upgrade cleanly. Prefer adding future fields to THIS
  back-fill over a new `_vN`.
- **Bottom-row UI is centralized in `src/shared/MenuLayout.luau`.** No more hand-editing `-370`:
  `primaryPosition(slot)` auto-centres the row; secondary panels use `makeTrayToggle` + `makePanel`
  and hide behind the "⋯ More" button (`More.client`) via the `GlizzyTrayOpen` player attribute.
- **`RateLimit`** (`src/server/RateLimit.luau`) guards new remotes; the FULL hardening pass (wrap
  every `OnServerEvent`) is scheduled **before trading (M6) and before soft launch** — do it then.
- **Handshake:** new initial-state pushes are already in `Main.pushAllState` (prestige/event/
  leaderboard/achievement/cosmetic/purchase). Any NEW one must go there too + be `RequestState`-fired.
- **Build order** (retention before content): M3-remainder (~~mutations✅~~ → prestige spend → fusion →
  manual vault → traps) → M4 (events/leaderboards/achievements/codes) → hardening pass → M5
  (passes/products/cosmetics) → M6 (trading/parties/emotes/clips) → M7 (art/audio/onboarding/launch).

---

## 👉 What the NEXT session should do

**Next CODE feature → Prestige spending** (`PrestigeShopService` + `PrestigeShop.client`). See
`docs/NEXT_SESSION_PROMPT.md` for the step-by-step — it's the next item in the build order now that
mutations are done, is self-contained, and implementing its `mutationLuck` effect closes the
`luckBonus` loop the mutations feature left stubbed.

**Still owed (needs a human): playtest & tune Milestones 2 + 3 in a real 2-player Studio session.**
Everything through M3 (plus mutations) is BUILT and passes static checks (rojo build + selene +
stylua all clean) but has **not been playtested with two live players** — that's the outstanding
validation for M2 *and* the M3 progression layer.

1. **Two-player Studio playtest** (Test → **Clients and Servers**, 2 players; enable
   **Game Settings → Security → API Services** for DataStore). Confirm the M2 loop (plots assign,
   cook fills pedestals with top dogs vaulted, steal-carry-deposit transfers permanently, Net/guard
   drop carriers, newbie shield blocks steals) **and** the new M3 systems:
   - Spawn beside your own stand; it's highlighted + "🏠 YOUR STAND"; rival stands hide
     Vault/Deposit labels; no Steal prompt on your own dogs.
   - Buy grill/display/vault upgrades (🛒 Upgrades) → odds improve, more pedestals/vault fill.
   - Rebirth (✨) resets coins, keeps dogs + upgrades, bumps income & the `Rebirths` leaderstat.
   - Rejoin after time away → capped offline coins + "welcome back" popup.
   - 📖 Dex fills as you collect (completion reward once); 🍳 Cook ×10 + pity + odds shown.
   - 📅 Daily streak claim + 3 missions track and pay out.
   - 🛒 Shop shows 6 dogs (same set for both players), buy adds the dog + charges coins, countdown
     ticks; rejoin/new day rotates the set. **NEW 2026-07-07** — added since the last handoff.
2. **Tune** the reasoned numbers in `GAME_DESIGN §6` (`GameConfig.luau` / `HotDogDex.luau`) to feel —
   none are playtest-confirmed yet.
3. Then pick up the **M3 remainder / M4** (rotating shop, prestige spending, events, leaderboards,
   achievements). See `docs/ROADMAP.md` and `docs/BACKLOG.md`.

**Fast-follows still open inside M2:** traps, manual vault selection.
Do NOT re-ask what's already locked (see below / CLAUDE.md / `GAME_DESIGN.md §2, §4`).

## ⚠️ M3-specific gotchas / notes

- **DataStore is `_v5`** (`DataManager.luau`); `_v4`/`_v3` saves back-fill cleanly. Prefer adding
  new PlayerData fields to the existing `_v5` back-fill over bumping `_vN` again (keep `defaultData()`
  building fresh tables). Mutations added **no** new field — they ride the existing `hotDogs` map as
  composite keys.
- **Join-race handshake:** the server pushes per-player state on join, but every client script also
  fires a `RequestState` remote after its handlers connect, and the server re-sends all state (see
  `Main.pushAllState`). Offline earnings are stashed in `pendingWelcome` and delivered via that path
  so the popup can't be lost. Any new server→client "initial state" push should be added to
  `pushAllState` and requested the same way.
- **Slot capacity is upgrade-derived.** `PlotManager.buildPlot` pre-builds `MaxDisplaySlots` /
  `MaxVaultSlots` anchors; `syncDisplay` only fills up to the player's current level. Empty extra
  pedestals are intentional "buy to unlock" slots.
- **Grill feeds the roll:** `HotDogDex.roll(grillLvl, guaranteeRare)` — pity passes `guaranteeRare`.
  `HotDogDex.odds(grillLvl)` and `HotDogDex.all()` back the cook-odds UI and the dex.

## ✅ Already locked (don't re-litigate)

- Genre: steal-and-defend idle tycoon · Theme: hot dogs, 7 rarity tiers · Title: "Steal a Glizzy"
- Ambition: **go big / commercial** · Audience: **everyone / Gen Alpha core**
- Monetization: passes/dev-products/cosmetics OK, but **gacha rolls are coin-only, never Robux**
- Art: **AI-generated in Studio** (mesh/4D generation)

## 🧱 What's built (Milestone 1)

A working cook-and-collect vertical slice, all server-authoritative:

- **`HotDogDex.luau`** — 7 rarity tiers (Common→Secret), 14 hot dogs, weighted `roll()`,
  income-per-second per tier, rarity colors.
- **Cook loop** — client fires `CookHotDog` RemoteEvent → server charges `CookCost` (10 coins),
  rolls, adds to `data.hotDogs` inventory, fires `CookResult` back → client shows a
  rarity-colored reveal.
- **Idle income** — passive coins/sec = sum of owned dogs' rates, ticked in `Main.server.luau`.
- **Persistence** — `DataManager.luau` saves `{coins, hotDogs={name=count}}` per player via
  DataStore (pcall-guarded; needs "Enable Studio Access to API Services" to persist in Studio).
- **UI** — coins/dogs HUD + cook button, built entirely in code.

Commit: `4928f7c` "Milestone 1: hot dog cook-and-collect...".

## ▶️ How to run / test

1. In the project root: `~/.rokit/bin/rojo.exe serve default.project.json`
   (a server may already be running on port 34872 — that's fine, it live-watches the folder).
2. Roblox Studio → open a **Baseplate**.
3. If the Rojo Studio plugin isn't installed: VS Code → `Ctrl+Shift+P` → **"Rojo: Open Menu"** → install plugin.
4. Studio → Plugins tab → **Rojo** → **Connect**.
5. Press **Play**. Expect `💰 50  🌭 0`, a Cook button, rarity-colored reveals, coins ticking.

## 🔧 Validate before committing

```
~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx   # must succeed
~/.rokit/bin/selene.exe src/                                            # must be 0/0
~/.rokit/bin/stylua.exe src/                                            # auto-format
```

## ⚠️ Gotchas / lessons learned

- **luau-lsp false errors:** the PostToolUse diagnostic snapshot often reports plain-Lua parse
  errors (flags `:` type annotations, `::` casts) taken *before* the LSP re-parses. If
  `rojo build` + `selene` pass, the code is fine. `Ctrl+Shift+P → "Developer: Reload Window"`
  clears lingering squiggles.
- **Rokit + non-TTY shell:** `rokit add <tool>` refuses until trusted. Run `rokit trust owner/repo`
  first (there IS a `rokit trust` subcommand), then `rokit add`.
- **`rojo plugin install` fails** here ("Couldn't find registry keys") — install the Studio
  plugin via the VS Code Rojo extension instead.
- **DataStore data-shape changes:** bump the `_vN` suffix in `DataManager.luau`'s store name to
  avoid loading incompatible old data.
- **Shallow-copy bug avoided:** `DataManager.defaultData()` builds a fresh table each call so no
  two players alias the same `hotDogs` table. Keep it that way.

## 🌐 Git / remote

- Local repo: `C:\Users\jwgri\roblox\tycoon-sim`
- Remote: `origin` → `https://github.com/nateyamashiro/hot_dawg.git` (branch `main`)
- Commits are **local only** unless the user asks to push. Confirm before `git push`.

## 📚 Reference docs

`docs/roblox-reference/` holds offline Roblox docs (DataStores, RemoteEvents, ProximityPrompt,
Humanoid, monetization, Luau, UI, etc.). See its `README.md`. Any other Roblox page can be
fetched by appending `.md` to its `create.roblox.com/docs/...` URL; the full index is in
`docs/roblox-reference/00-indexes/`.
