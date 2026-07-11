# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). The game is **feature-complete through M4,
deployment-ready on the code side, and the M5 monetization CORE is live** (Extra-slots + VIP
passes, dev products, all id-agnostic until Nate makes dashboard ids), plus every former loose
end (codes non-coin rewards + `NATE` dev code, traps, steal-path mutations, onboarding arrows,
Tool.Grip initial pose). Launch checklist: `docs/HANDOFF.md §Launch checklist`. No live
validation has ever run — the 2-player published-place test is still the human gate.

**THIS SESSION IS THE ADDITIONS SESSION.** Nate wrote **`additions.txt`** (project root) — 17
changes/features he wants, from quick polish to majors that consciously override locked design
decisions. Your job: understand them, interview Nate on the open calls, then plan and implement
the whole set. Flow is Step 1 below — follow it in order.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, launch checklist, gotchas. READ FULLY.
- **`additions.txt`** (project root) — Nate's 17-item wishlist. READ FULLY; it drives this session.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 built · §6 tuning · §7 decision log.
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — The additions flow (interview → plan mode → implement)

1. **Read `additions.txt`** and skim the relevant code so your questions are informed, not generic.
2. **Interview Nate (AskUserQuestion, batched — don't drip one at a time).** Ask about the calls
   only he can make. Seed list (numbers match `additions.txt`):
   - **#1 grill cook:** a cosmetic NPC chef standing/animating at the stove, or a second
     functional cooking station? What does "working" mean here?
   - **#3 bigger base + bigger display dogs:** roughly how much bigger (display dogs are already
     1.35×)? Interior only, or the whole footprint (plots are 60×46 with fixed row spacing)?
   - **#4 entry blocker (30s off every 5min):** ⚠️ this overrides the LOCKED "theft access is
     always possible" rules (wall gap permanent, gate slows-never-blocks — GDD §4/§7). Confirm
     Nate intends that override. Also: coin or prestige price? Where does it slot in the
     upgrade/build chain? Does the 30s-open window telegraph to raiders (alarm? color?)?
   - **#5 cook cooldown lower + ready notification:** new cooldown value (currently 300s)?
     Notification form — toast, button glow, sound, all three?
   - **#6 rarity auto-sort (vault > top floor > ground):** do manual 📌 vault pins still beat the
     rarity sort, or does pure rarity win now?
   - **#7 vault-unlock steal item:** ⚠️ this breaks the "vault = safe" fairness promise (locked)
     and, if Robux-priced, collides with the non-pay-to-win lock. Consumable dev product, coin
     item, or prestige item? One dog per use? Cooldown / per-target limit? How does the victim
     get counterplay (alert, timer, defense interaction)?
   - **#8 new top rarity above Secret:** name + income + odds — does Nate have a name in mind,
     or should the plan propose one (with the roster entries)?
   - **#10 more stove/grill tiers per floor ("Big", "Industrial"):** how many tiers, gated by
     floor builds? Should the plan draft the full name/cost/payout table for approval?
   - **#11 map-wide conveyor:** a loop around the whole map, or a longer straight run? Keep the
     ≤8-unit cap or scale with length?
   - **#12 steeper income-vs-cost curve:** shop prices stay, incomes rise? Or reprice everything?
     (Currently Common 150→1/s, Uncommon 500→3/s.) The plan can propose a curve for sign-off.
   - **#14 obby (pays 100s of your income/s):** repeatable on a cooldown or once per session?
     Rough difficulty/length? Checkpoints?
   - **#16 odds sign + spin-wheel grill:** sign by the grill replaces the sidebar — confirm
     removing the HUD odds panel. Wheel: cosmetic suspense on the SAME server roll (must stay
     server-authoritative + coin-only)? Does the wheel replace the current reveal or precede it?
   - **#17 clipfarm/clip forge hookup:** what does "connect" mean THIS session — in-game
     clip-worthy moment engineering, recording/export tooling, or just a content plan? (The
     clipfarm project lives at `C:\Users\jwgri\clipfarm` — its `outputs/` dir is an additional
     working directory.)
   - Items #2, #9, #13, #15 (grill/stove looks, storage-fraction counter, comma formatting,
     roof) are judgment calls — don't ask, just build them well.
3. **EnterPlanMode** with the answers in hand: research the touched systems (PlotManager builders,
   AutoCooker/Upgrader tiers, HotDogDex roster/odds, ShopService pricing, StealService/Defense
   rules, ConveyorService, UI.client odds panel, EnvironmentService map), then write ONE plan
   covering ALL additions — build order (quick wins early or grouped by system, your call),
   which locked decisions change (each needs a GDD §7 row), data/`_v5` impact, and a
   verification pass. Get the plan approved before touching code.
4. **Implement the approved plan.** Static gates (stylua/selene/rojo) clean between features.
   **Batch commits — do NOT commit after every feature** (Nate 2026-07-11: per-feature commits
   got redundant). Commit at coherent multi-feature checkpoints and at the handoff.
5. After the additions: M5 remainder (cosmetics · doubleCoins/autoCollect effects ·
   `offlineRefill`) → M6 trading remain the build-order backlog. Launch execution items
   (dashboard ids, delete `NATE`, published-place 2-account test) still sit with Nate.

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
  A failed load returns nil → Main kicks (PRODUCTION only; in Studio it falls back to a TEMP
  `unsaveable` profile so no-API test sessions still work — never weaken that split). Saves are
  throttled (5s guard) + stale-write-guarded; autosave runs via `DataManager.startAutosave`.
- **Design-system rules:** world colors from `Theme.Palette`, states from `Theme.Semantic`, UI via
  `MenuLayout` helpers (`styleButton` is one-shot — flip colors directly for state changes).
  World text: ONE far label per plot; everything else small/occludable/near-fade. Neon only for
  small accents + gameplay signals (the trap's armed state is the canonical example). Rarity
  colors in `HotDogDex.RARITY`; variant colors in `Variants.DEFS`.
- **Grants derive at read time** (`BuildGrants` / `displayCapacity` / `data.passes` pattern —
  check ownership at read/join, never bake into unrelated fields; `bonus*Slots` is exclusively
  the prestige shop's ledger).
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
  Event-only dogs live in `byName` but NOT `DOGS_BY_RARITY` — keep that invariant (a new top
  rarity tier from #8 DOES go in `DOGS_BY_RARITY`; it's a normal roster tier).
- **New server→client initial-state push** goes in `Main.pushAllState` + rides `RequestState`
  (which COALESCES over-limit bursts). Yielding work (e.g. `UserOwnsGamePassAsync`) NEVER goes
  inline in a push path — own thread, then re-push.
- **Telemetry:** new funnel steps append with the NEXT number (never renumber); one-line
  `Telemetry.funnelStep/event` calls at the success point.
- **Reuse, don't reinvent:** service shape = `BuildService`/`ZoneService`; buy paths =
  `UpgradeService.tryBuy`/`UpgraderService.tryUpgrade`; world juice = the `Celebrate` remote;
  determinism = day-index (shop) / week-index (events); screen-edge arrows = the
  StealHud/Onboarding ring pattern.

## Step 3 — Handoff ritual (DO THIS at each milestone / when you hand off) ⭐
**Nate's cadence notes:** batch the ritual — DON'T run the full doc-update after every feature,
and **DON'T commit after every feature** (got redundant). Commit at coherent multi-feature
checkpoints; do the docs near a real context/agent handoff. When you do hand off:
1. **Validate** — stylua + selene + `rojo build` all clean (0/0). Never hand off a red build.
2. **Update docs** — `docs/HANDOFF.md`, `docs/ROADMAP.md`, `docs/BACKLOG.md`,
   `docs/design/GAME_DESIGN.md` (§5/§6/§7), and `CLAUDE.md`'s code map + status.
3. **Rewrite THIS file** for the next session (point it at the new top-of-build-order work; keep
   this Step 3 ritual intact so it self-perpetuates).
4. **Push only when Nate asks.** Commit locally at checkpoints; Nate's standing instruction is
   **don't push**.

That's the loop: **plan → implement in batches → validate → (at handoff) docs + rewrite this prompt.**

## Standing caveats
- **No live validation has ever run.** The 2-account loop test on the PUBLISHED place is the
  mandatory human gate before public (checklist in HANDOFF).
- **⚠️ The `NATE` code is OPEN and grants 1B coins once to anyone.** Deleting it before public
  launch is a checklist item. In Studio without API Services the session is a temp profile, so
  NATE re-tests every Play session there.
- Several additions **consciously override locked decisions** (#4 blocks theft access, #7 opens
  the vault). Every override Nate confirms gets its own GDD §7 decision row — never silently
  flip a locked rule.
- All `GAME_DESIGN §6` numbers are reasoned-not-observed; #12's new curve will be reasoned too —
  say so in §6 when you write it.
- **M5 end-to-end testing needs real pass/product ids** from Nate's dashboard; until then use
  `GameConfig.StudioTestPasses` for effects. Do NOT configure `offlineRefill`'s id until its
  bespoke grant is implemented.
