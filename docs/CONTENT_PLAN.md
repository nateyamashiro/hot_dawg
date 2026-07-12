# CONTENT_PLAN — Steal a Glizzy × ClipForge 🌭🎬

> Additions #17 (2026-07-12): the plan for pumping game content onto YouTube through the
> **ClipForge** pipeline at `C:\Users\jwgri\clipfarm`. This session ships the PLAN only —
> no tooling was built; a future session (or Nate by hand) executes it.

## 1. What ClipForge is (as of this writing)

Local, $0/video YouTube-Shorts farm (FastAPI backend :8000 + React frontend :5173, PM2,
Ollama + Edge-TTS + faster-whisper + FFmpeg + yt-dlp). Three pipelines behind a 2-slot queue:

| Pipeline | Input | Output |
|---|---|---|
| **Clip Maker** | a YouTube URL (+ `highlights`/`parts` mode) | viral 20-45s cuts, 9:16 reframe, burned captions |
| **Story Generator** | a text prompt (+ voice) | TTS story over **looped gameplay footage** from `backend/footage/<category>/` |
| **Video Recapper** | a long-form YouTube URL | narrated recap split into "Part X of Y" Shorts |

Key facts: raw gameplay goes in as **MP4 files** dropped into `backend/footage/<category>/`
(any resolution; FFmpeg auto-crops to 1080×1920). Outputs land in `backend/outputs/`.
Upload is via YouTube Data API — **currently OFF** (`AUTO_UPLOAD=false`, no OAuth tokens,
all 5 accounts inactive). Prompt seeds live in `backend/prompts/acct_*.txt` (placeholders).

## 2. The connection, in one line

**Record Steal a Glizzy sessions → drop MP4s into `backend/footage/glizzy/` (new category)
→ Story Generator makes glizzy-backed Shorts; once real gameplay videos are on YouTube,
Clip Maker/Recapper feed on those URLs → scheduler auto-posts once OAuth + AUTO_UPLOAD go live.**

## 3. Clip-worthy moments (engineered into the game already)

Rank-ordered by expected hook strength; every one is capturable solo or with 2 accounts:

1. **Forbidden/Secret wheel pull** — the spinner strip decelerating into a violet Forbidden
   cell (0.01 weight = genuine jackpot footage), then the glizzy reveal. The near-miss seeding
   also makes "SO close" clips farmable on ordinary pulls.
2. **Vault-breach drill** — both POVs: the thief sweating a 10s countdown next to the vault,
   and the victim's "💥 X is DRILLING YOUR VAULT!" alarm sprint-back. Natural 15-25s arc with
   a built-in timer overlay.
3. **Security Field window raid** — waiting at a rival's force field as the countdown hits
   zero, panels flash green, rush in, grab, and race the 30s window before it seals.
4. **Giant mutation steal** — the giantShake camera punch + carrying a huge glizzy at 10
   walkspeed with the whole street chasing.
5. **Glizzy Run obby PB attempts** — short, loopable parkour fails/wins with the income-scaled
   payout toast as the punchline.
6. **Podium flex / tower tour** — top-3 statue reveal at the east plaza; a floor-3 stand tour
   where the BEST dogs literally sit on top (rarity auto-sort).
7. **NPC chef b-roll** — the spatula-flipping chef + smoke makes an idle-friendly background
   loop for Story Generator segments.

## 4. Capture workflow (zero new code)

1. Record in Roblox Studio play sessions or the live place (Win+G Game Bar / OBS, 1080p+,
   game audio only — ClipForge lays its own TTS/music for Story mode). Portrait not required.
2. Trim nothing — drop raw MP4s into `C:\Users\jwgri\clipfarm\backend\footage\glizzy\`
   (create the folder; empty categories fall back to yt-dlp downloads, so seeding it matters).
3. For Story Generator: write 3-5 glizzy-flavoured premises into the `acct_*.txt` prompt seeds
   ("the day I stole a Forbidden Glizzy", "my hot dog stand got robbed at 3am", …).
4. Once real gameplay uploads exist on YouTube: feed their URLs to Clip Maker (highlights mode)
   and Recapper for derivative Shorts.

## 5. Cadence + gates

- **Pre-launch:** build a 10-15 clip backlog from Studio sessions (the moments in §3 are all
  reachable solo with `StudioTestPasses` + the `NATE` code for fast progression — capture BEFORE
  deleting the code).
- **Launch week:** 1-2 Shorts/day per active account via the scheduler.
- **Gates that sit with Nate:** YouTube OAuth per account, `AUTO_UPLOAD=true`, activating
  accounts in `backend/accounts/accounts.json`, and (optionally) royalty-free MP3s in `music/`.
- **Future session candidates:** an in-game "clip mode" (hide HUD, cinematic camera), a
  highlight auto-recorder around Forbidden pulls/vault breaches, per-moment kill-cam framing.
