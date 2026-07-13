# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle **tycoon** (repo `hot_dawg`). The game is **feature-complete through M5
(one Nate design call open: the autoCollect pass effect), M6 TRADING is live, and the ADDITIONS
SESSION (all 17 `additions.txt` items) shipped 2026-07-11/12.** The 2026-07-12 batch: cosmetics
(6-item prestige wardrobe — shell-repaint skins, character trails, sign-title chips), the 2×
Coins pass effect (multiplicative), the offlineRefill dev product (banks cap-truncated offline
seconds, pays at the buyer's live rate — its dashboard id may NOW be configured), and trading
(invite→accept, stack offers, both-confirm with commit-gate re-validation, 30s cooldown,
`tradeLog_v1` server log). Launch checklist: `docs/HANDOFF.md §Launch checklist`.
**No live validation has EVER run** — neither the old 2-player loop test nor any Studio look at
anything shipped since 2026-07-11.

## Step 0 — Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, full code map + status. READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, the smoke checklist (additions + 07-12 batch),
  launch checklist, gotchas. READ FULLY.
- **`docs/design/GAME_DESIGN.md`** — §4 locked decisions · §5 built (incl. the 07-12 batch
  inventory) · §6 tuning (all reasoned-not-observed) · §7 decision log (incl. the trade/refill/
  cosmetics rows and the two override rows).
- Offline Roblox docs in `docs/roblox-reference/` — use them instead of guessing APIs.

## Step 1 — This session's work, in order

1. **If Nate is in Studio: run the smoke pass FIRST** (checklist in
   `docs/HANDOFF.md §What the NEXT session should do`). Everything since 2026-07-11 is
   static-clean but has never rendered: the additions (76×58 layout, chef, odds board, spinner
   reveal, conveyor/podium/obby, commas) AND the 07-12 batch (buy/equip each cosmetic kind —
   repaint/trail/chip + reset-on-leave; welcome-back refill line after a capped absence).
   2-account items: Security Field cycle, Vault Breaker drill, floor-sorted steal reach, and a
   FULL TRADE end-to-end (invite → accept → steppers → both confirm → transfer + cooldown +
   the offer-changed re-confirm path). Also owed in the same sitting: Tool.Grip tuning
   (`PickupService.buildTool`), `StudioTestPasses` flips (incl. doubleCoins doubling the tick),
   onboarding arrows on a fresh profile.
2. **M6 remainder** (the build-order head):
   - **Emotes** — `EmoteService`/the client side are stubs; presets in `GameConfig.Emotes`
     (5, no free text). Validated relay/broadcast (RateLimit + preset-index guard); render as a
     chat bubble/billboard over the character (small, near-fade — world-text rules). Keep it
     tiny; it's a taunt layer for steals.
   - **Parties (join-friend)** — NO scaffold exists; design first (GDD §4.8 wants co-op raiding
     later). Confirm scope with Nate before building anything beyond a design note.
3. **Then M7 polish:** clip-moment juice on big steals/rare pulls (`docs/CONTENT_PLAN.md` §1
   moments), then launch-checklist remainder.
4. Keep an eye on balance knobs once seen live: blocker cycle (300/30), breaker (50k/10s), obby
   (100s), trade cooldown/distance (30s/40), cosmetic prices (12–40 ✨) — §6 flags them all
   reasoned-not-observed.

## Step 2 — Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/build/trade logic in
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
- **Grants derive at read time** (`BuildGrants` / `displayCapacity` / `data.passes` /
  `data.cosmetics.equipped` pattern); `bonus*Slots` is exclusively the prestige shop's ledger.
  **All numbers render via `Format.comma`** — keep new UI on it.
- **Inventory is composite-key stacks** (`"Name#Gold"`); decode via `Variants`/`getByKey`.
  Trades/steals/fusions all move stacks; validate ownership at the COMMIT moment, not just at
  request time (see `TradeService.completeTrade` for the pattern).
- **New server→client initial-state pushes** go in `Main.pushAllState` + ride `RequestState`
  (which COALESCES bursts). Yielding work NEVER inline in a push path.
- **Telemetry:** new funnel steps append with the NEXT number (never renumber); one-line
  `Telemetry.funnelStep/event(player, name)` calls at the success point (the player arg is
  required — ObbyComplete was silently dropped for a while).
- **Reuse, don't reinvent:** service shape = `BuildService`/`ZoneService`/`TradeService`; buy
  paths = `tryBuy`/`tryUpgrade`; income payouts = Main's `computeLiveIncome` closure; world juice
  = the `Celebrate` remote; timers = os.time-derived cycles (blocker) or absolute-deadline client
  ticking (shield/cook countdown); alarms = the StealAlert/VaultBreach banner+arrow in StealHud.

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
- **No live validation has ever run.** The single-player smoke pass and the 2-account loop test
  on the PUBLISHED place are the human gates before public (HANDOFF).
- **⚠️ The `NATE` code is OPEN and grants 1B coins once to anyone** — launch-checklist delete.
  (Capture clipfarm footage BEFORE deleting it; see `docs/CONTENT_PLAN.md §5`.)
- **autoCollect pass: detection live, EFFECT unbuilt — needs Nate's design call** (income is
  already automatic; candidate = auto-claim daily streak/missions). Don't sell that pass until
  it does something; don't build a guess.
- The Security Field + Vault Breaker deliberately override old locked rules — their §7 rows are
  the record; don't "fix" them back without Nate.
- All `GAME_DESIGN §6` numbers are reasoned-not-observed — including trading (30s/6/40/60) and
  cosmetic prices.
- **M5 end-to-end testing needs real pass/product ids** from Nate's dashboard; until then use
  `GameConfig.StudioTestPasses`. **ALL ids may be configured now, incl. `offlineRefill`.**
- Nate asset passes still open (zero code): `GameConfig.Sounds` ids (incl. `CookReady`,
  `BlockerOpen`, `VaultDrill`) · `GlizzyMeshIds` · `SkyboxAssetId`.
