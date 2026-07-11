# HANDOFF — Steal a Glizzy 🌭

**Last updated:** 2026-07-11 (**DEV CODE + STRETCH SESSION SHIPPED** — Nate picked the full menu,
one commit per feature, all static-clean: **`NATE` dev code** (1B coins; open + once-ever by
Nate's call — ⚠️ DELETE before public launch, it's in the launch checklist) · **codes non-coin
rewards** (`GameConfig.Codes` entries may be `{ coins?, dogs?, prestige?, mutationLuck? }` tables;
plain numbers still work; `FREEGLIZZY` demo grants a Plain Dog; empty/invalid rewards refund the
redemption mark) · **steal-path mutations ON** (`MutateOnSteal = true`: a stolen BASE dog rolls
`maybeMint` with the THIEF's luck at deposit; mutated loot transfers as-is; upgraded toast) ·
**traps polished + discoverable** (🪤 StealHud buy button beside Guard; poll loop → `Touched`
trigger, owner-exempt carriers-only; sprung trap greys out for `TrapRearmSeconds` 6s then re-arms
Neon red; `TrapRange` retired) · **Tool.Grip initial pose** for held glizzies (needs a live
Studio tuning round with Nate) · **onboarding first-60s** (server derives stage 1/2/3/0 from
`cookReadyAt`/`autoCookerLvl`/`built` — no new field; `OnboardingUpdate` rides `pushAllState` +
tick-on-change; new `Onboarding.client` ring arrow + Highlight + tip banner; veterans see
nothing) · **M5 PurchaseService REAL** (Extra-slots + VIP first: new `_v5` field `data.passes`
caches `UserOwnsGamePassAsync` per pass — refreshed on join in its own thread + on
`PromptGamePassPurchaseFinished`, Studio falls back to `GameConfig.StudioTestPasses` while ids
are 0; effects DERIVE at read time — PlotManager capacity + `Main.incomeMultiplier` VIP term —
never banked into `bonus*Slots`; `ProcessReceipt` dispatches coinsSmall/coinsLarge/stealCharges,
unmapped incl. `offlineRefill` stay NotProcessedYet; `MaxDisplaySlots` 16→18 / `MaxVaultSlots`
6→8 so sold slots render; Passes panel real). Previous session summary follows.)

**Previously (2026-07-09):** (**VISUAL DESIGN SYSTEM + BUILDING SHELL SHIPPED** — the design plan
`~/.claude/plans/i-want-you-to-wild-abelson.md` executed end-to-end, phases **P-A → P-E**:
**P-A facelift** — `Theme.luau` token module (palette/semantic/materials/lighting/UI/VFX budgets);
procedural glizzies (`GlizzyModel.luau`: 6-part hot dog, rarity fx ladder Common→Secret,
Gold/Rainbow/Giant treatments, SpecialMesh escape hatch via `GameConfig.GlizzyMeshIds`);
`EnvironmentService` (bright-noon lighting + post fx + clouds + grass/street/dashes/sidewalks/lamps);
`GlizzyFx.client` (Rainbow hue-cycle ≤80 studs + emitter culling ≤60); plot recolor pass.
**P-B building shell** — 15-entry `BuildCatalog` (floor2→stairs2→wall→floor3→gate→elevator + 9
income decors), `BuildGrants.luau` (ALL grants derived at read time from `data.built` — rebuild can't
double-apply), static floor-1 stall shell on every plot, per-id `BUILDERS` in `PlotManager` (floor-3
climbable truss = theft-access guarantee; elevator = teleport pads for EVERYONE; gate slows never
blocks via `setGateHandler`), full `BuildService` (validate→charge→spawn→push + `applyLoaded`
rebuild-on-join), 🏗️ build + 🎪 decor walk-on pads (one offer each), **DefenseService wall RETIRED**
(old owners grandfathered `built.wall` in `DataManager.load`; StealHud wall button removed), decor
income folded into `Main.incomeMultiplier`, cooker slots = +15%/each on stove output.
**P-C juice** — `Celebrate` remote + `Celebrate.client` (cook burst by rarity, purchase pop, build
dust, 3-flash steal alarm, Giant camera shake), `Sfx.luau` + `GameConfig.Sounds` (all `""` —
silence-safe until Nate fills ids), coin-milestone 💰 sparkle, cook-reveal viewport spin (UI.client).
**P-D UI restyle** — `MenuLayout` applies Theme.UI (Cream windows, ketchup-gradient title bars,
FredokaOne, corner+stroke chrome, bounce + click/open sounds); `makePanel` now IS `makeWindow`, so
every tray panel became a draggable themed window for free; all panel clients swept off dark-slate;
NEW `Build.client` catalog window; TRAY gains "Build". **P-E** — bun-hill horizon, mustard river,
ketchup geyser.
**THEN (same day): OVERHAUL PHASES 4+5 SHIPPED** — conveyor street buy-lane (belt strip, spinning
priced glizzies, prompt-to-buy at shop weights/prices, base dogs only), cooker upgrader (⚙️ pad,
outputMult folded into stove income), condiment blasters (🔫 tray window, buy/equip, physical Tool,
server-picked target near YOUR plot only, slow/knockback/stun never damage, splat fx), and prestige
zone expansion (🌍 pad, pad physically swells, extraSlots derived read-time). All static checks
clean. **NOT pushed (Nate said don't push). The 2-player playtest was WAIVED by Nate** ("act like
it worked") — systems are accepted but no live validation has run; §6 tuning remains
reasoned-not-observed.
**THEN (same day): M4 RETENTION + VAULT PINS + HARDENING SHIPPED** — weekly events real
(deterministic week-index rotation; modifiers live in the real math: income2x →
`Main.incomeMultiplier` (tick + offline), cookHalfPrice → cook-10 batch price, freeCookBursts =
Dog Rain free rolls every 4 min via a Main-provided `grantFreeCook` closure; points +10/cook
+40/steal; 4-tier reward track with batched claims; claimed count persists as
`eventPoints["<id>:claimed"]`, no `_vN` bump) · leaderboards real (OrderedDataStore top-N
coins/steals/rarest, rarest = best variant-scaled unit income ×100, session-cached name lookups,
tabbed panel) · achievements real (validated one-time coin claims, gated claim UI + progress
bars) · **manual vault selection** (`syncDisplay` fills `vaultPins` first then tops up by value;
📌 Dex-tile family toggle; pins ride `InventoryUpdate`; fixed variant-only ownership not lighting
dex tiles) · **the FULL anti-exploit hardening pass, done early** (every `OnServerEvent` behind
`RateLimit.check` + arg guards; `RequestState` join bursts coalesce into one deferred push).
Commit `318f100`. Static checks clean; still not pushed; playtest still waived-not-passed.
**THEN (same day): VISUAL POLISH + FEEL PASSES** — grass z-fight fix (Studio Baseplate destroyed at
runtime), stand-text de-soup to Steal-a-Brainrot conventions (one far sign per plot; small
occludable labels; stacked unit plates; rival owner-facing labels hidden client-side), neon tamed
(matte big surfaces, Bloom 0.25/14/1.6, new Theme.Materials rule), vendor-stand pedestals + 1.35×
display glizzies, pick-up-and-hold (`PickupService`; hand dogs snatchable through the FULL steal
pipeline; unequip force-returns). Commits `be4dcdc`→`70670eb`→`c6bc43b`→`99fb04a`.
**THEN (same day): DEPLOYMENT AUDIT + FIXES + STRETCH** (plan
`~/.claude/plans/modular-crunching-starfish.md`): data-safety criticals fixed (load-failure wipe →
retry+kick; mis-nested `_v5` back-fill de-nested; autosave; UpdateAsync stale-write guard;
ProcessReceipt Robux-eater), `Telemetry.luau` (onboarding funnel + error logging), shop daily cap
(3/offer), world podium (coins top-3), event-exclusive dogs + per-occurrence event tracks.
Commits `34a1100`→`5dece79`→`306b164`→`a2fead9`→`8001e00`. See §Launch checklist below.)
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
  dog name. ✅ Steal-path minting shipped 2026-07-11 (`MutateOnSteal` on: base dogs mint at
  deposit with the thief's luck). *(The `luckBonus` loop is CLOSED — prestige banks
  `data.mutationLuck`, fed to `maybeMint`.)*
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
- **Build order** (retention before content): M3-remainder (~~mutations✅~~ → ~~prestige spend✅~~ →
  ~~fusion✅~~ → manual vault → traps) → M4 (events/leaderboards/achievements/codes) → hardening pass →
  M5 (passes/products/cosmetics) → M6 (trading/parties/emotes/clips) → M7 (art/audio/onboarding/launch).

---

## 🚀 Launch checklist (deployment readiness — mostly Nate)

Code-side readiness is DONE (data safety, telemetry, hardening, error logging). What remains:
1. **Publish the place** from Studio (File → Publish). API Services work automatically in
   production — the Studio toggle only affects Studio testing.
2. **Content maturity questionnaire** on the Creator Dashboard — REQUIRED for the game to get
   full visibility/recommendations. All-ages answers (no blood/gore; the blasters never damage).
3. **Genre + tags** (Tycoon / Simulation), **icon (512×512)** + **thumbnails** — huge for CTR.
4. **Server size**: set ~15–20 (GDD density target for live raiding).
5. **The 2-player loop test on the PUBLISHED place** (two accounts) — the waived playtest is now
   genuinely mandatory before public: cook/steal/deposit/snatch, DataStore persistence across
   rejoin (autosave + offline earnings), leaderboards filling, event claim granting the dog.
6. Watch the **Analytics dashboard** funnel (Joined→FirstCook→…) after launch — it's wired.
7. ⚠️ **DELETE the `NATE` dev code** from `GameConfig.Codes` before going public — it's open
   (no lockdown, Nate's call) and grants 1,000,000,000 coins to anyone who types it, once.
8. **Create the pass/product ids on the Creator Dashboard** and fill `GameConfig.GamePassIds` /
   `DevProductIds` — the M5 logic is live and id-agnostic (0 = "not available yet" toast; do
   NOT configure `offlineRefill`'s id until its bespoke grant is implemented).
9. Known-accepted gaps at launch: silent audio (`GameConfig.Sounds` all `""`), procedural dogs
   (no AI meshes yet), cosmetics still stubs, doubleCoins/autoCollect pass effects TODO(M5).

## 👉 What the NEXT session should do

**Everything through M4 is code-complete, the hardening pass is DONE, deployment audit SHIPPED
2026-07-09, and the 2026-07-11 stretch session closed every "loose end" (codes non-coin rewards,
traps, `MutateOnSteal`, onboarding first-60s, Tool.Grip initial pose) plus the M5 pass/product
core.**

**THE NEXT SESSION IS THE ADDITIONS SESSION:** Nate's 17-item wishlist lives in
**`additions.txt`** (project root) — quick polish (commas, roof, storage counter) through majors
(base-entry blocker, vault-unlock steal item, new top rarity, multi-floor stove tiers, map-wide
conveyor, obby, spin-wheel grill, clipfarm hookup). Flow: read `additions.txt` → interview Nate
on the open calls (seeded question list in `docs/NEXT_SESSION_PROMPT.md` Step 1) → plan mode →
implement. ⚠️ #4 and #7 consciously override locked decisions (theft-access guarantee /
vault-safety) — each confirmed override gets a GDD §7 row. **Commit cadence changed (Nate
2026-07-11): batch commits at checkpoints, NOT one per feature; still never push.**

After the additions, the build order resumes:
1. **M5 remainder:** cosmetics (`CosmeticService`/`Cosmetics.client` stubs; catalog + prestige
   prices already in `GameConfig.Cosmetics`) · doubleCoins/autoCollect pass EFFECTS (ownership
   detection already runs; fold `DoubleCoinsMult` into `Main.incomeMultiplier`-adjacent math,
   design auto-collect) · `offlineRefill` dev product (bespoke: refill the offline cap — do NOT
   let Nate configure its dashboard id before this lands).
2. **Then M6 social** — trading (`TradeService`, baseline safeguards locked: two-sided confirm +
   cooldown + log), parties, emotes.
3. **Interactive round with Nate in Studio (needs his eyes):** Tool.Grip tuning (initial pose is
   in; nudge `PickupService.buildTool`'s `tool.Grip` live) · flip `StudioTestPasses` to verify
   pass effects · watch the onboarding arrows on a fresh profile.
4. Nate asset passes (zero code): `GameConfig.Sounds` ids · `GlizzyMeshIds` meshes ·
   `SkyboxAssetId` · **game-pass/dev-product ids on the Creator Dashboard (unblocks M5 testing
   end-to-end)**.

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

## ⚠️ Tycoon-layer gotchas / notes (overhaul)

- **Walk-on pads:** `PlotManager` owns pad *instances* + owner-only debounced Touched; `Main` owns the
  *rules*. To add a pad: append `{ id, offset }` to `PlotManager.PAD_LAYOUT`, route the id in
  `Main.setPadHandler`, and emit its label/affordability from `Main.syncPads`. `updatePads` colours
  pads green/red and hides maxed ones. `syncPads` runs on join AND every income tick (keeps colours
  live) — keep it cheap.
- **Stove income is COINS, not dogs** — it lives in `data.autoCookerLvl` (0 = unbuilt) and is added to
  income via `AutoCookerService.coinsPerSecond` in BOTH `Main`'s tick loop and the offline calc. It is
  un-stealable by construction. `PlotManager.setStove` renders the physical model.
- **Cook is cooldown-gated:** `Main.cookOne` (shared by the Cook button + the physical station) is FREE
  but blocked until `os.time() >= data.cookReadyAt` (`GameConfig.CookCooldownSeconds`). **Cook-10 is
  deliberately still PAID + ungated** (the bypass) — if you rebalance cook, revisit that pairing.
- **`makeBillboard`/pads use `.CanTouch`/`.Transparency`/BillboardGui `.Enabled` to hide** — BaseParts
  have NO `.Visible` property (setting it errors). Follow `updatePads`/`makeBuyPad` for the pattern.
- The old on-screen **upgrade menu is redundant** with the pads now (kept as a fallback). Its labels
  can go briefly stale after a *menu* buy (pads re-sync on the next tick / pad touch). Ask Nate if he
  wants the menu removed.

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
