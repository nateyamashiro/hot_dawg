# Next-session prompt — Steal a Glizzy 🌭 (copy/paste into a new Claude Code session)

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
steal-and-defend idle tycoon (repo `hot_dawg`). **Milestones 1–3 are built and pass static checks**
(cook & collect, steal & defend, and the full M3 progression layer) but have **not been playtested
with two live players**. Your job this session: **run/validate a 2-player playtest, tune to feel,
then start the M3 remainder / M4.**

## Read these first (all the context lives here)
- **`CLAUDE.md`** — architecture rules, workflow, toolchain, "where things are". READ FULLY.
- **`docs/HANDOFF.md`** — start-here status, the playtest checklist, and the **M3-specific gotchas**
  (DataStore `_v4`, the `RequestState` join-race handshake, upgrade-derived slot capacity).
- **`docs/design/GAME_DESIGN.md §4`** — locked design decisions; **§6** — every current tuning value
  (all "reasoned, not playtest-confirmed").
- **`docs/ROADMAP.md`** / **`docs/BACKLOG.md`** — what's done and what's next.
- Code map in `CLAUDE.md`. Offline Roblox docs in `docs/roblox-reference/`.

## Non-negotiable flow (how we work)
- **Server authoritative, client untrusted.** All economy/inventory/steal/upgrade/rebirth/daily logic
  in `src/server`; `src/client` only displays state and fires RemoteEvents. Shared config/data in
  `src/shared`.
- `--!strict` at the top of every file; format with StyLua (tabs, 100 col); keep Selene clean.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Rojo** live-syncs `src/*.luau` into Studio (`~/.rokit/bin/rojo.exe serve default.project.json`).
  Test via **Test → Clients and Servers → 2 players**; turn on **Game Settings → Security → Enable
  Studio Access to API Services** for DataStore persistence + offline earnings.
- **PlayerData changes:** bump the `_vN` suffix (`_v4` → `_v5`) AND back-fill new fields from defaults
  in `DataManager.load`. Keep `defaultData()` building fresh tables (no aliasing).
- **Any new server→client "initial state" push** must be added to `Main.pushAllState` and requested
  via the client's `RequestState` fire, or it'll be lost to the join race.
- **Lua gotcha:** never start a line with `(` — resolve remotes into named locals in `init()`.
- Commits are **local only** unless the user asks to push. For larger new systems use **EnterPlanMode**
  first; ask questions (AskUserQuestion) when a design choice is genuinely ambiguous.

---

## This session, in order

### 1. Two-player Studio playtest (the outstanding validation for M2 **and** M3)
Run the checklist in `HANDOFF.md §"What the NEXT session should do"`. In short, confirm end-to-end:
spawn-at-your-own-stand + owner-only presentation; steal-carry-deposit + defense + shield; **buy
grill/display/vault upgrades** (odds improve, pedestals/vault fill); **rebirth** (resets coins, keeps
dogs+upgrades, bumps income & `Rebirths`); **rejoin** → capped offline coins + welcome-back popup;
**dex** fills + completion reward once; **cook-10 + pity + odds**; **daily** streak + 3 missions.
Fix any bugs you find; note anything that can't be verified without real players.

### 2. Tuning pass to feel
Adjust the reasoned numbers in `GAME_DESIGN §6` (`GameConfig.luau` / `HotDogDex.luau`): grill/slot
cost curves, rebirth cost growth + income bonus, offline cap, pity length, daily rewards, and the
M2 knobs (steal hold, charges, cooldowns, defense costs). Re-document chosen values in §6.

### 3. Then pick the next feature (see `BACKLOG.md` "Top of the list")
Strong candidates, roughly in priority order:
- **Rotating shop** — buy specific dogs for coins (targeted goal, dampens pure-RNG frustration; M3).
- **Spend prestige currency** — first premium-unlock sink (prestige is banked but unused today).
- **Leaderboards UI** (richest / most steals / rarest) — `Coins`/`Steals`/`Rebirths` already tracked.
- **Achievements/milestones**, or **weekly events + event-only dogs** (M4 retention, FOMO).
- **M2 fast-follows:** traps (placeable stun zones), manual vault selection.

## After the session
Update `docs/BACKLOG.md`, `docs/HANDOFF.md`, `docs/ROADMAP.md`, `GAME_DESIGN.md`, and write a fresh
`NEXT_SESSION_PROMPT.md`. **Anti-exploit hardening** (server-side validation + rate-limiting) is still
deferred but must land before public launch / before trading ships (GDD §4.11).
