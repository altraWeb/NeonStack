# Neon Stack

Cyberpunk, guideline-inspired Tetris built with **Godot 4.7** (GDScript).  
Neon magenta / cyan grid, rain city backdrop, glitch post-FX, procedural street synth BGM.

## Requirements

- Godot **4.7.x** (tested with `4.7.1.stable`)
- macOS (desktop-portable; Windows/Linux should run as-is)

Godot install used for this project: `/Applications/Godot.app`.

## Run

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/altrano/Desktop/Projects/Tetris
```

Or open the project folder in the Godot Project Manager.

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

## Audio

- **SFX:** procedural blips (move / rotate / lock / clear)
- **BGM:** looping dark synth bed (generated at runtime)
- Volumes: `SettingsService.music_volume` / `sfx_volume` (`user://settings.cfg`)

## Tests

TAD baseline for the core; **new gameplay work is TDD** (see [`AGENTS.md`](AGENTS.md)).

```bash
./scripts/test.sh
```

## Architecture (C-ready)

```
core/        BoardEngine, SRS, 7-bag, scoring (no nodes)
game/        GameController + BoardView
ui/          Title, play host, game over, street log
data/        ThemePack (Cyberpunk Neon), GameMode
services/    HighscoreStore + LocalHighscoreStore, settings
audio/       AudioDirector (SFX + BGM)
vfx/         Cyber city, post glitch, block glow
```
