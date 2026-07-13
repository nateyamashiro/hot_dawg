# HANDOFF — Steal a Glizzy 🌭

**Last updated:** 2026-07-12 (**M5 REMAINDER + M6 TRADING SHIPPED** — the monetization milestone
is now COMPLETE except one Nate design call, and trading is live; two commits
`433433e`/`d4be72c` + this docs commit, all static-clean:
**Cosmetics** — `CosmeticService`/`Cosmetics.client` real: 6-item prestige catalog (2 stand
skins / 2 trails / 2 titles, 10–40 ✨), ONE equipped per kind (`data.cosmetics.equipped`
reshaped string→per-kind map BEFORE first ship — no live save affected), buy auto-equips;
skin = shell repaint via `PlotManager.applyStandSkin` (reset on release), trail = character
`Trail` re-applied each respawn, title = gold chip under the owner sign (`PlotManager.setTitle`,
same post — one-far-label rule holds); visuals re-derive from data on join ·
**2× Coins pass EFFECT** — `DoubleCoinsMult` MULTIPLIES `Main.incomeMultiplier` (income2x
pattern; read-time derive from `data.passes`, refund-safe; tick/offline/obby inherit);
**autoCollect deliberately unbuilt** — needs Nate (income is already automatic; candidate =
auto-claim daily streak/missions) ·
**offlineRefill dev product** — the join-time offline calc banks cap-truncated seconds into new
`_v5` field `offlineMissedSeconds` (≤ `OfflineRefillMaxSeconds` 7d); `ProcessReceipt` pays the
bank at the buyer's LIVE rate via Main's `computeLiveIncome` closure (now shared with the obby),
zeroes it; empty bank → NotProcessedYet (never eats Robux); `PromptPurchase` blocks empty
refills; the welcome-back popup grows a "⏰ Nh past the cap" line. **Its dashboard id may now be
configured** ·
**M6 TRADING** — `TradeService`/`Trade.client` real per the locked safeguards: invite→accept
handshake (mutual `TradeRequest` within 60s, 40-stud `TradeMaxDistance`), composite-key stack
offers (≤6/side) validated on SET and RE-validated at the both-confirmed COMMIT gate (any change
clears both confirms), atomic transfer, both sides stamped +30s `tradeCooldownUntil`,
fire-and-forget `tradeLog_v1` DataStore append, `TradeCompleted` telemetry; items only NEVER
coins; sessions die on cancel/leave; hand-held dogs traded away are force-returned (new
`PickupService.heldKeyOf`/`forceReturn`) ·
Drive-by: ObbyComplete telemetry fixed (missing player arg = silent no-op).
Data: `_v5` +`offlineMissedSeconds`; `WelcomeBack` +missed arg; `CosmeticUpdate` +prestige arg;
no new remotes. Previous session summary follows.)

**Previously (2026-07-12, earlier):** (**THE ADDITIONS SESSION SHIPPED** — all 17 items from Nate's
`additions.txt`, interviewed → planned (`~/.claude/plans/bright-jumping-comet.md`, approved) →
implemented in 5 batch commits + this docs commit, every batch static-clean:
**A geometry** — plots 60×46→**76×58** (spacing 120 / separation 140 / street 1240×60), stall
shell 60×27×12 with floor2 y13 / floor3 y26, ALL BUILDERS re-laid (wall+gate config-derived),
display dogs **1.8×** (pitch 3.0), real kettle-grill + range-with-burners stations, cosmetic
spatula-flipping **chef** at the stove, striped **roof** above the topmost floor (y13/26/39,
recomputed on build), physical **odds board** beside each grill fed by `pushCookStats` ·
**B economy** — shared `Format.comma` swept ~30 render sites; new top rarity **Forbidden**
(0.01 w, 15,000/s, violet, 3 dogs); income ladder steepened so payback FALLS with rarity
(C1/U4/R16/E60/L250/M1,000/S4,500; event dogs 250); **7 named stove tiers** (Camp Stove→Glizzy
Factory, Lv4-5 need floor2, Lv6-7 floor3 — upgrade-gated only); cook cooldown **300→120s** with
a button countdown + ready glow/toast/`CookReady` sfx (CookStats carries cookRemaining);
storage-fraction HUD via new `StorageUpdate` ·
**C display** — rarity auto-sort fills anchors floor-DESC (best dogs HIGH; 📌 pins still own the
vault); HUD odds sidebar REMOVED; single-cook reveal is a case-opening **spinner strip** landing
on the server's pre-decided rarity (near-miss seeded; cook-10 summary untouched) ·
**D overrides (GDD §7 rows)** — **Security Field** (BuildCatalog, 25k, prereq gate): force-field
panels seal the plot to y14, DOWN 30s/300s phase-staggered + telegraphed (countdown/color/sfx),
owner passes via client-side collision exemption, anti-cage valve ejects trapped raiders;
**Vault Breaker** (coin consumable 50k/cap 3 on the StealHud bar): 10s drill on ONE vault dog
with victim alarm+arrow countdown, cancels on stun/death/leave/step-away (no refund), success
detaches into the normal carry pipeline, 600s per-pair cooldown ·
**E world** — conveyor spans ±560 (speed 14, ≤18, 4s), podium → east plaza x=660; **Glizzy Run
obby** at the west end (ObbyService): pays 100s of the runner's LIVE income, 300s cooldown
(`obbyReadyAt`), ordered checkpoints + 25s min-run anti-teleport ·
**F docs** — GDD §5/§6/§7 (incl. both override rows), `docs/CONTENT_PLAN.md` (clipfarm hookup,
#17), this file, ROADMAP/BACKLOG, CLAUDE.md, NEXT_SESSION_PROMPT rewritten.
Data: `_v5` back-fill adds `vaultBreakers` + `obbyReadyAt` (no `_vN` bump). New remotes
`StorageUpdate`/`VaultBreach`; extended `CookStats`/`StatsUpdate`/`BuyDefense`. Previous
session summary follows.)

**Previously (2026-07-11):** (**DEV CODE + STRETCH SESSION SHIPPED** — Nate picked the full menu,
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
   `DevProductIds` — the M5 logic is live and id-agnostic (0 = "not available yet" toast).
   **ALL products may be configured now, including `offlineRefill`** (its bespoke grant shipped
   2026-07-12).
9. Known-accepted gaps at launch: silent audio (`GameConfig.Sounds` all `""`), procedural dogs
   (no AI meshes yet), autoCollect pass effect awaiting Nate's design call (ownership detection
   works; don't sell that pass until it does something), emotes/parties still stubs.

## 👉 What the NEXT session should do

**Everything through M5 is code-complete (one Nate design call open: autoCollect), M6 TRADING is
live, and the ADDITIONS SESSION (all 17 `additions.txt` items) shipped earlier on 2026-07-12** —
see the header blocks above and GDD §5 for the full inventory. `additions.txt` is fully consumed
(it can be deleted or archived whenever Nate likes).

⚠️ **Nothing shipped since 2026-07-11 has been seen in Studio.** Before (or alongside) new work,
run the single-player smoke pass: plots/street/roof render sane at the new 76×58 footprint, chef
at the stove, spinner-strip reveal lands on the toast'd rarity, 120s cook countdown + ready glow,
odds board updates on grill upgrade, storage HUD fractions, stove tier gating message, conveyor
spans the street with the podium at the east plaza, Glizzy Run pays ~100× income, commas
everywhere — PLUS the 2026-07-12 batch: buy/equip a cosmetic of each kind (shell repaints, trail
follows the character through a respawn, title chip under the sign, all reset on leave), and the
welcome-back popup's refill line after a capped absence (shorten `OfflineCapSeconds` to test).
The 2-account published-place test additionally covers: Security Field cycle + owner passage +
inside-eject, Vault Breaker drill + victim alarm + cancel-on-net, floor-sorted steal reach, and
**a full trade end-to-end** (invite → accept → stepper offers → both confirm → transfer, cooldown
toast on immediate re-request, offer-changed re-confirm path if a steal lands mid-trade).

The build order then resumes:
1. **M6 remainder:** emotes (`EmoteService` stub; presets in `GameConfig.Emotes`; validated
   relay/broadcast, no free text) · parties (join-friend; design first — no scaffold exists).
2. **M7 polish:** clip-moment juice on big steals/rare pulls (`docs/CONTENT_PLAN.md` moments) ·
   remaining launch-checklist items.
3. **Interactive round with Nate in Studio (needs his eyes):** Tool.Grip tuning (initial pose is
   in; nudge `PickupService.buildTool`'s `tool.Grip` live) · flip `StudioTestPasses` to verify
   pass effects (incl. doubleCoins doubling the tick) · watch the onboarding arrows on a fresh
   profile.
4. **Nate decisions/assets (zero code):** autoCollect pass effect design (candidate: auto-claim
   daily streak/missions) · `GameConfig.Sounds` ids · `GlizzyMeshIds` meshes · `SkyboxAssetId` ·
   **game-pass/dev-product ids on the Creator Dashboard — ALL of them now, incl. offlineRefill**.

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
