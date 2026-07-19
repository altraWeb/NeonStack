extends Node
## Autoload event bus — VFX, audio, analytics, and future online submit subscribe here.

signal piece_spawned(piece_id: int)
signal piece_locked(piece_id: int, cells: Array)
signal piece_held(piece_id: int)
signal lines_cleared(rows: Array, count: int)
signal hard_dropped(distance: int)
signal level_up(level: int)
signal score_changed(score: int, lines: int, level: int)
signal game_started
signal game_paused(paused: bool)
signal game_over(final_score: int)
signal game_won(final_score: int, elapsed_sec: float)
signal game_timed_out(final_score: int, elapsed_sec: float)
