extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("UltraMode")

	_test_factory(t)
	_test_remaining_starts_at_duration(t)
	_test_timeout_ends_run_and_freezes(t)
	_test_timeout_stops_mid_tick_before_lock(t)
	_test_top_out_before_timeout_is_not_timed_out(t)
	_test_marathon_and_sprint_unaffected(t)

	return t


func _make_engine(mode: GameMode, seed_value: int = 1) -> BoardEngine:
	var engine := BoardEngine.new(seed_value)
	engine.configure_mode(mode)
	engine.start()
	return engine


func _test_factory(t: TestSuite) -> void:
	var mode := GameMode.ultra_180()
	t.assert_eq(mode.id, "ultra_180", "ultra id")
	t.assert_eq(mode.display_name, "Ultra", "ultra display name")
	t.assert_eq(mode.duration_sec, 180.0, "ultra duration 180s")
	t.assert_true(mode.has_time_limit(), "ultra has time limit")
	t.assert_false(mode.win_on_target, "ultra is not sprint win-on-target")
	t.assert_eq(mode.target_lines, 0, "ultra has no line target")


func _test_remaining_starts_at_duration(t: TestSuite) -> void:
	var engine := _make_engine(GameMode.ultra_180())
	t.assert_eq(engine.elapsed_sec, 0.0, "elapsed starts at 0")
	t.assert_eq(engine.time_remaining(), 180.0, "remaining starts at duration")
	t.assert_false(engine.is_timed_out, "not timed out at start")


func _test_timeout_ends_run_and_freezes(t: TestSuite) -> void:
	var mode := GameMode.ultra_180()
	mode.duration_sec = 2.0
	var engine := _make_engine(mode)
	var timed: Array = []
	engine.timed_out.connect(func(score: int, elapsed: float):
		timed.append({"score": score, "elapsed": elapsed})
	)
	var won := [false]
	engine.won.connect(func(_s, _e): won[0] = true)
	var ended := [false]
	engine.ended.connect(func(_s): ended[0] = true)

	engine.tick_gravity(1.5, false)
	t.assert_false(engine.is_timed_out, "still playing before duration")
	t.assert_eq(timed.size(), 0, "no timeout yet")

	engine.tick_gravity(1.0, false)
	t.assert_true(engine.is_timed_out, "timed out at duration")
	t.assert_true(engine.is_play_stopped(), "play stopped on timeout")
	t.assert_eq(timed.size(), 1, "timed_out signal once")
	t.assert_eq(float(timed[0]["elapsed"]), 2.0, "elapsed clamped to duration")
	t.assert_eq(engine.time_remaining(), 0.0, "remaining is zero")
	t.assert_false(won[0], "timeout is not a sprint win")
	t.assert_false(ended[0], "timeout is not top-out ended")

	var frozen := engine.elapsed_sec
	engine.tick_gravity(3.0, false)
	t.assert_eq(engine.elapsed_sec, frozen, "elapsed frozen after timeout")
	t.assert_eq(timed.size(), 1, "timed_out does not re-fire")


func _test_timeout_stops_mid_tick_before_lock(t: TestSuite) -> void:
	var mode := GameMode.ultra_180()
	mode.duration_sec = 1.0
	var engine := _make_engine(mode)
	# Put piece on ground so a large delta would otherwise lock it after timeout.
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, BoardEngine.ROWS - 3), 0)
	var locked := [false]
	engine.piece_locked.connect(func(_id, _cells): locked[0] = true)

	engine.tick_gravity(5.0, false)
	t.assert_true(engine.is_timed_out, "timeout wins the overshooting tick")
	t.assert_false(locked[0], "no lock after time already expired")
	t.assert_eq(engine.elapsed_sec, 1.0, "elapsed clamped, not 5")


func _test_top_out_before_timeout_is_not_timed_out(t: TestSuite) -> void:
	var mode := GameMode.ultra_180()
	mode.duration_sec = 60.0
	var engine := _make_engine(mode)
	var timed := [false]
	engine.timed_out.connect(func(_s, _e): timed[0] = true)
	var ended := [false]
	engine.ended.connect(func(_s): ended[0] = true)

	# Block spawn cells so next spawn tops out.
	for cell in [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)]:
		engine.grid[cell.y][cell.x] = 1
	engine.set_next_queue_for_test([
		PieceType.Id.O, PieceType.Id.I, PieceType.Id.T, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 8), 0)
	engine.hard_drop()

	t.assert_true(engine.is_game_over, "top-out sets game over")
	t.assert_true(ended[0], "ended emitted on top-out")
	t.assert_false(engine.is_timed_out, "top-out is not timeout")
	t.assert_false(timed[0], "timed_out not emitted on top-out")


func _test_marathon_and_sprint_unaffected(t: TestSuite) -> void:
	var marathon := _make_engine(GameMode.standard_marathon())
	marathon.tick_gravity(200.0, false)
	t.assert_false(marathon.is_timed_out, "marathon never times out")
	t.assert_false(marathon.is_play_stopped(), "marathon still playing after long tick")

	var sprint := GameMode.sprint_40()
	sprint.target_lines = 1
	var engine := _make_engine(sprint)
	engine.tick_gravity(1.0, false)
	t.assert_false(engine.is_timed_out, "sprint does not use duration timeout")
	t.assert_eq(engine.time_remaining(), -1.0, "no remaining without time limit")
