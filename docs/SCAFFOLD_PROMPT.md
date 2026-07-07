# Scaffold-the-rest-of-the-game prompt — Steal a Glizzy 🌭

> Copy everything below the line into a fresh Claude Code session opened in this repo.
> Supersedes `NEXT_SESSION_PROMPT.md` for this purpose (that one is the playtest-first prompt;
> this session **assumes the 2-player playtest is done** and focuses on building out the rest).

---

You are continuing development of **"Steal a Glizzy"**, a server-authoritative Roblox
**steal-and-defend idle tycoon** (repo `hot_dawg`, themed around collecting hot dogs across 7 rarity
tiers). **Milestones 1–3 are built and static-clean**, including the rotating shop. Your job this
session: **plan the ENTIRE remaining game — M3 remainder through M7 soft launch — then, after I
approve, scaffold compiling code skeletons for it.**

## Step 0 — Read before doing anything
Read these fully; all the context lives here. Do **not** re-ask what's already locked.
- **`CLAUDE.md`** — architecture rules, workflow/toolchain, the code map ("where things are").
- **`docs/HANDOFF.md`** — current status + the M3 gotchas (DataStore `_v4`, the `RequestState`
  join-race handshake, upgrade-derived slot capacity).
- **`docs/design/GAME_DESIGN.md`** — **§2/§4** locked decisions, **§5** what's built, **§6** every
  current tuning value, **§7** decision log.
- **`docs/ROADMAP.md`** (M0–M7) and **`docs/BACKLOG.md`** (what's shipped / what's next).
- Skim the existing services as **pattern references** you will mirror: `src/server/ShopService.luau`,
  `UpgradeService.luau`, `DailyService.luau`, `RebirthService.luau`, `DataManager.luau`,
  `Main.server.luau`; and clients `src/client/Shop.client.luau`, `Dex.client.luau`, `Menu.client.luau`.
- Offline Roblox docs are in `docs/roblox-reference/` (DataStores, OrderedDataStore, monetization,
  ProximityPrompt, etc.) — use them instead of guessing APIs.

## Step 1 — Enter plan mode and produce the full build-out plan
**Enter plan mode immediately.** Then write ONE comprehensive, milestone-ordered plan covering
everything below. This is a **planning + light-scaffolding** session, not a full-implementation one —
the plan should be detailed enough that later sessions can implement feature-by-feature.

For **every feature**, the plan must specify: what it is (one line), the **server/client split**, the
**new RemoteEvents** it needs, any **PlayerData shape change** (+ the `_vN` bump/back-fill strategy),
**GameConfig** additions, its **dependencies/ordering**, and **which existing file it mirrors**.

Scope to cover (roughly in this order — retention before content per ROADMAP's guiding principle):

- **M3 remainder & M2 fast-follows**
  - Spend prestige currency (first premium-unlock sink — prestige is banked but unused today).
  - Mutations/variants (Gold/Rainbow/Giant) with income multipliers. ⚠️ **This is the big
    architectural decision:** the inventory is currently `name → count`; per-unit mutations need
    per-unit identity. The plan MUST address how inventory/vault/steal/dex representation changes
    (and the DataStore migration that implies) before anything depends on it.
  - Duplicates → fusion. · Traps (placeable stun zones, a 4th defense). · Manual vault selection.
- **M4 — retention:** weekly limited-time events + event-only dogs (FOMO); leaderboards
  (richest / most steals / rarest — via **OrderedDataStore**); achievements/milestones; codes system.
- **M5 — monetization (all non-pay-to-win; gacha stays coin-only, never Robux):** game passes
  (2× coins, auto-collect, extra slots, VIP); dev products (coin packs, offline-refill/boost, extra
  steal charges); cosmetics (stand skins, trails/auras, titles).
- **M6 — social/virality:** trading (with dupe/scam safeguards), parties/co-op, shareable
  big-steal/rare-pull moments engineered for clips.
- **M7 — polish & soft launch:** AI-generated art pass, audio/SFX, onboarding/first-60-seconds,
  icon/thumbnail + store copy + genre tags, analytics goals, soft-launch checklist.

**Also call out these cross-cutting concerns in the plan:**
- **DataStore migration strategy** — prefer batching all new fields into a single `_v5` bump (keep
  `defaultData()` building fresh tables; back-fill every new field from defaults in `load`). Decide
  where the mutation/per-unit inventory change forces the shape and sequence around it.
- **Handshake:** any new server→client "initial state" push must be added to `Main.pushAllState`
  AND requested via the client's `RequestState:FireServer()`, or it's lost to the join race.
- **Anti-exploit hardening** (GDD §4.11): server-side validation + rate-limiting on all remotes —
  schedule it **before trading (M6) and before public launch**, not after.
- **Monetization compliance:** cook/gacha rolls stay **coin-only** (Roblox paid-random-item rules);
  passes/products/cosmetics are fine. (See `docs/roblox-reference/monetization/`.)
- **AI-generated art pipeline** (locked): where meshes/thumbnails get produced and slotted in.

Use **AskUserQuestion** (multiple choice) whenever a design fork genuinely changes the plan
(e.g. mutation data model, trade-safeguard model, which passes ship first). Don't ask about anything
already locked in GDD §4 / CLAUDE.md.

## Step 2 — After I approve the plan, scaffold the code
Once I approve via **ExitPlanMode**, lay down **compiling stub files** that establish the architecture
(do NOT implement full logic):
- One `src/server/<Feature>Service.luau` per new system and one `src/client/<Feature>.client.luau`
  per new UI, each mirroring the closest existing file's shape (`--!strict`, an `init(deps)` that
  resolves remotes into named locals, a `return`).
- Wire them into `Main.server.luau`: create their RemoteEvents, `require` + `init` each service, and
  add any state push to `pushAllState`.
- Add new `GameConfig` tables/tunables (values can be reasoned placeholders, documented like §6).
- Add new `PlayerData` fields + the `_v5` back-fill to `DataManager.luau` if the plan calls for it.
- Mark every place real logic goes with a clear `-- TODO(<milestone>): ...` comment.
- Keep the skeleton **rojo-clean**: no orphan remotes, no unused-variable warnings that break selene.
- New bottom-row menu buttons: remember the row is centered by a shared constant across
  `Menu`/`Dex`/`Daily`/`Shop` clients — re-center it (currently `-370` for 5 slots) if you add more.

## How we work (non-negotiable)
- **Server authoritative, client untrusted.** All economy/inventory/steal/upgrade/rebirth/daily/shop/
  monetization logic in `src/server`; `src/client` only displays state and fires RemoteEvents; shared
  config/data in `src/shared`.
- `--!strict` atop every file; format with StyLua (tabs, 100 col); keep Selene clean.
- **Validate before considering anything done** (AUTHORITATIVE over luau-lsp squiggles):
  ```
  ~/.rokit/bin/stylua.exe src/
  ~/.rokit/bin/selene.exe src/
  ~/.rokit/bin/rojo.exe build default.project.json --output build.rbxlx
  ```
- **Lua gotcha:** never start a line with `(` — resolve remotes into named locals in `init()`.
- **Assume the 2-player playtest is done / M2–M3 feel is validated** — do NOT block on it. You may
  still adjust §6 numbers as new features require; just don't gate the session on a live playtest.
- Commits are **local only** unless I ask. Update `docs/ROADMAP.md`, `docs/BACKLOG.md`,
  `docs/HANDOFF.md`, `GAME_DESIGN.md`, and `CLAUDE.md`'s code map as you add files.

## Already locked (don't re-litigate)
Steal-and-defend idle tycoon · hot dogs, 7 rarity tiers · title "Steal a Glizzy" · go-big/commercial ·
everyone / Gen Alpha core · passes/products/cosmetics OK but **gacha is coin-only, never Robux** ·
**AI-generated art** · server-authoritative. (Full detail: GDD §2/§4, CLAUDE.md.)
