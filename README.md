# Neon Stack

Cyberpunk, guideline-inspired Tetris built with **Godot 4.7** (GDScript).  
Neon magenta / cyan grid, rain city backdrop, glitch post-FX, procedural street synth BGM.

## Requirements

- Godot **4.7.x** (tested with `4.7.1.stable`)
- macOS (desktop-portable; Windows/Linux should run as-is)

Godot install used for this project: `/Applications/Godot.app`.

## Run

```bash
open -n /Applications/Godot.app --args --path /Users/altrano/Desktop/Projects/Tetris
```

Or open the project folder in the Godot Project Manager.

## Modes

| Mode | Goal | Ranks by | Notes |
|---|---|---|---|
| **Marathon** | Endless stack | Highest score | Classic top-out end |
| **Sprint 40** | Clear 40 lines | Fastest time | Incomplete runs are not logged |
| **Ultra** | Score in **180 seconds** | Highest score | Timeout or top-out both log score |

Street Log (`STREET LOG` on the title) keeps separate boards per mode.

## Controls

| Action | Keys | Gamepad |
|---|---|---|
| Move | A/D or ←/→ | D-pad |
| Soft drop | S or ↓ | D-pad down |
| Hard drop | Space or ↑ | A |
| Rotate CW | X or W | B |
| Rotate CCW | Z or Q | X |
| Hold | C or Shift | Y |
| Pause | P or Esc | Start |

## Feel / settings (PROTOCOL TUNING)

Available on the title screen and in the pause menu. Values persist in `user://settings.cfg`.

| Control | Meaning | Default |
|---|---|---|
| **MUSIC / SFX** | Volumes | — |
| **GHOST PIECE** | Show landing preview | on |
| **DAS** | *Delayed Auto Shift* — hold delay before left/right auto-repeat starts | 167 ms |
| **ARR** | *Auto Repeat Rate* — step interval while holding left/right after DAS | 33 ms |
| **SOFT** | Soft-drop repeat interval (no DAS; starts immediately) | 50 ms |
| **LOCK** | Lock delay on the ground before the piece locks | 500 ms |
| **SNAP TO GUIDELINE** | Reset DAS / ARR / SOFT / LOCK to the defaults above | — |

Tips:

- Lower **DAS/ARR** → snappier sideways movement (more competitive).
- Higher **LOCK** → more time to finesse after touching the stack.
- Changes in pause apply live (`PAUSED · TUNE LIVE`).

## Audio

- **SFX:** procedural blips (move / rotate / lock / clear / timeout / Street Record)
- **BGM:** looping dark synth bed (generated at runtime)
- Volumes: `SettingsService` → `user://settings.cfg`

## Highscores

Local only (`user://highscores.json`), mode-keyed:

- Marathon / Ultra → sort by score (descending)
- Sprint → sort by clear time (ascending)

Personal bests auto-save on the end screen (callsign defaults to `PILOT`; you can re-log under another name).

## Tests

TAD baseline for the core; **new gameplay work is TDD** (see [`AGENTS.md`](AGENTS.md)).

```bash
./scripts/test.sh
```

## Architecture (C-ready)

```
core/        BoardEngine, SRS, 7-bag, scoring, RepeatInput (no nodes)
game/        GameController + BoardView + play scene
ui/          Title, game over, street log, settings panel
data/        ThemePack (Cyberpunk Neon), GameMode
services/    HighscoreStore + LocalHighscoreStore, SettingsService
audio/       AudioDirector (SFX + BGM)
vfx/         Cyber city, post glitch, block glow
tests/       Headless suite (`./scripts/test.sh`)
```
