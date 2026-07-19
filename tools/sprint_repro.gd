extends SceneTree
## Reproduce Sprint play: many locks + HUD format + win path.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== Sprint repro start ===")
	var mode := GameMode.sprint_40()
	mode.target_lines = 4  # faster win for full flow
	var engine := BoardEngine.new(42)
	engine.configure_mode(mode)
	engine.start()
	print("started active=", engine.active != null, " mode=", engine.mode.id, " win_on_target=", engine.mode.win_on_target)

	var won_count := [0]
	var ended_count := [0]
	engine.won.connect(func(s, e):
		won_count[0] += 1
		print("WON score=", s, " elapsed=", e)
	)
	engine.ended.connect(func(s):
		ended_count[0] += 1
		print("ENDED score=", s)
	)

	# Simulate HUD timer formatting every frame-ish
	for i in 120:
		engine.tick_gravity(1.0 / 60.0, false)
		var t := _format_time(engine.elapsed_sec)
		if i % 30 == 0:
			print("t=", t, " lines=", engine.score.lines, " active=", engine.active != null)

	# Hard-drop several pieces with moves/rotates
	for piece_i in 20:
		if engine.is_play_stopped():
			print("stopped early at piece ", piece_i)
			break
		engine.try_move(-1, 0)
		engine.try_move(1, 0)
		engine.try_rotate(1)
		engine.try_rotate(-1)
		engine.hard_drop()
		var lines_txt := "%d/%d" % [engine.score.lines, mode.target_lines]
		var time_txt := _format_time(engine.elapsed_sec)
		print("lock#", piece_i, " lines=", lines_txt, " time=", time_txt, " score=", engine.score.score)

	# Force clear to win
	if not engine.is_won:
		engine.score.lines = mode.target_lines - 1
		_clear_one(engine)
		print("forced clear -> won=", engine.is_won, " lines=", engine.score.lines)

	print("won_count=", won_count[0], " ended_count=", ended_count[0])
	print("SPRINT_REPRO_OK")
	quit(0)

func _format_time(sec: float) -> String:
	var total_ms := int(sec * 1000.0)
	var minutes := total_ms / 60000
	var seconds := (total_ms % 60000) / 1000
	var millis := (total_ms % 1000) / 10
	return "%d:%02d.%02d" % [minutes, seconds, millis]

func _clear_one(engine: BoardEngine) -> void:
	var y := BoardEngine.ROWS - 1
	for x in BoardEngine.COLS:
		if x < 3 or x > 6:
			engine.grid[y][x] = 1
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z, PieceType.Id.J,
	])
	engine.set_active_for_test(PieceType.Id.I, Vector2i(3, 0), 0)
	engine.hard_drop()
