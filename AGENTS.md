# Neon Stack — Agent Notes

## Testing policy

- **Existing core:** covered by a TAD baseline under `tests/`.
- **From now on: TDD** for gameplay/core changes.
  1. Write a failing test in `tests/`
  2. Run the suite and confirm it fails for the right reason
  3. Implement the minimal fix
  4. Re-run until green

UI/VFX polish without rule changes does not require new tests, but must not break the suite.

## Run tests

```bash
./scripts/test.sh
# or:
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tests/run_tests.gd
```

Exit code `0` + `TEST_OK` means green; `1` + `TEST_FAIL` means red.

## Test seams on BoardEngine

- `BoardEngine.new(seed)` — deterministic bag
- `set_next_queue_for_test(ids)`
- `set_active_for_test(id, origin, rotation)`
- `configure_mode(GameMode)` — Marathon vs Sprint win rules / timer

## Launch preference

After gameplay/feel/UI changes (and when the user wants to try the build), **start the game for them**:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/altrano/Desktop/Projects/Tetris
```

(`open -a Godot` is unreliable — prefer the binary path above, backgrounded.)

Do not assume they will launch Godot themselves unless they ask to.

### Never kill a healthy play session

- **Do not** `pkill` / `killall` Godot (or `kill` a PID) just to relaunch.
- Mid-play kills look exactly like an abrupt crash (window vanishes, no Game Over UI).
- Before launching: `pgrep -lf Godot`. If a Godot process is already running with this project, **skip relaunch** and note that in the summary.
- Headless test / repro scripts may `quit()` themselves — that is fine. Interactive player windows must stay untouched.
- Gameplay code must never call `get_tree().quit()` / `OS.kill` on top-out, win, or timeout — only swap to the end screen (`ui/main.gd`).

## Current focus

- **B — Sprint 40-line mode:** done; await playtest feedback (title mode pick, HUD timer/lines, win screen)

## Backlog

- _(empty — pick next surprise / polish from playtest)_

## Done

- **A — Feel:** DAS/ARR, soft-drop repeat, settings (music/SFX/ghost)
- **C — Cyberpunk AV polish:** richer BGM, heavier glitch/clear FX, title punch
- **B — Sprint mode (TDD):** `GameMode.sprint_40()`, `won` signal, timer freeze, Marathon unchanged
