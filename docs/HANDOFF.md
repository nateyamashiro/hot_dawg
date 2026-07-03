# HANDOFF — Steal a Glizzy 🌭

**Last updated:** 2026-07-02
**For:** the next Claude Code session (and Nate)

---

## 👉 What the NEXT session should do

**Run the game-design deep-dive interview.** The user explicitly wants the next session to
ask **a large number of questions** to pin down exactly what game we're making before writing
more gameplay code.

1. Open **`docs/design/DISCOVERY_QUESTIONS.md`** — it's a categorized question bank.
2. Work through it **conversationally**, a few questions at a time (use the `AskUserQuestion`
   tool for batches of 2–4 related choices; go free-form for open-ended ones). Don't dump all
   ~70 questions at once.
3. As answers come in, **record them in `docs/design/GAME_DESIGN.md`** (the living GDD), moving
   items from "❓ TBD" to decided.
4. Only after the design is meaningfully filled in, start **Milestone 2** (see `docs/ROADMAP.md`).

Do NOT re-ask what's already locked (see below / CLAUDE.md).

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
