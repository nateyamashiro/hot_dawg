# Roblox Reference Library 📚

Offline copies of the Roblox Creator docs most relevant to **Steal a Glizzy**, so agents can work
without network access. Pulled 2026-07-02 from `create.roblox.com` (each page's `.md` version).

## How to use / extend

- **Any** Roblox doc page is available as markdown: append `.md` to its URL, e.g.
  `https://create.roblox.com/docs/en-us/scripting/events/remote.md`.
- Full doc map: `00-indexes/roblox-docs-index.llms.txt` (~2,300 pages, the whole site).
- Engine API (Luau classes/methods) map: `00-indexes/engine-api-index.llms.txt`.
- To grab a class reference not stored here:
  `curl -sSL https://create.roblox.com/docs/en-us/reference/engine/classes/<Class>.md -o <file>`
- There's also a single-file dump of ALL docs at `/docs/llms-full.txt` (large) if you need to grep everything.

## What's here

| Folder | Use for |
|---|---|
| `00-indexes/` | The two doc-map indexes (find any other page) |
| `architecture/` | Client-server model & security, RemoteEvents/Functions, ModuleScripts, attributes, Players — **the server-authoritative patterns this project depends on** |
| `luau/` | Language fundamentals: variables, tables, functions, control structures, operators, scope, type-checking (`--!strict`) |
| `data/` | DataStores + best practices + limits (player persistence) |
| `gameplay/` | ProximityPrompt (grab mechanic), Humanoid (WalkSpeed for slowing thieves), CollectionService (tagging) — **the Milestone 2 stealing toolkit** |
| `ui/` | Buttons, labels, HUD meters, interactive UI |
| `monetization/` | Passes, dev products, monetization foundations, and **paid-random-items rules** (why our gacha is coin-only) |
| `publishing/` | Publishing places, experience genres |

## Priority reading for the current phase

1. `architecture/client-server-boundary-security.md` — never trust the client.
2. `architecture/remote-events-and-functions.md` — how the cook/steal requests flow.
3. `gameplay/proximity-prompts-guide.md` + `gameplay/ProximityPrompt-class.md` — the grab interaction for stealing.
4. `gameplay/Humanoid-class.md` — `WalkSpeed` to slow a carrying thief.
5. `data/data-stores-best-practices.md` — safe saves (sessions, retries, `UpdateAsync`).
