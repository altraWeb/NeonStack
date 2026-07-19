extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("SprintMode")

	_test_sprint_wins_at_target_lines(t)
	_test_sprint_respects_custom_target(t)
	_test_marathon_does_not_win_at_forty(t)
	_test_elapsed_advances_and_freezes_on_win(t)
	_test_top_out_does_not_emit_won(t)
	_test_sprint_survives_many_locks_without_win(t)

	return t


func _make_engine(mode: GameMode, seed_value: int = 1) -> BoardEngine:
	var engine := BoardEngine.new(seed_value)
	engine.configure_mode(mode)
	engine.start()
	return engine


func _fill_row(engine: BoardEngine, y: int, fill_cols: Array = []) -> void:
	var cols: Array = fill_cols
	if cols.is_empty():
		for x in BoardEngine.COLS:
			cols.append(x)
	for x in cols:
		engine.grid[y][x] = 1


func _clear_one_line(engine: BoardEngine) -> void:
	var y := BoardEngine.ROWS - 1
	_fill_row(engine, y, [0, 1, 2, 7, 8, 9])
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z, PieceType.Id.J,
	])
	engine.set_active_for_test(PieceType.Id.I, Vector2i(3, 0), 0)
	engine.hard_drop()


func _test_sprint_wins_at_target_lines(t: TestSuite) -> void:
	var engine := _make_engine(GameMode.sprint_40())
	engine.score.lines = 39
	var won_payload: Array = []
	engine.won.connect(func(score: int, elapsed: float):
		won_payload.append({"score": score, "elapsed": elapsed})
	)
	var ended_count := [0]
	engine.ended.connect(func(_s): ended_count[0] += 1)

	_clear_one_line(engine)

	t.assert_eq(engine.score.lines, 40, "lines reach 40")
	t.assert_true(engine.is_won, "is_won after target")
	t.assert_eq(won_payload.size(), 1, "won signal once")
	t.assert_eq(ended_count[0], 0, "top-out ended not emitted on win")
	t.assert_true(engine.is_game_over or engine.is_won, "play stopped after win")


func _test_sprint_respects_custom_target(t: TestSuite) -> void:
	var mode := GameMode.sprint_40()
	mode.target_lines = 4
	var engine := _make_engine(mode)
	engine.score.lines = 3
	var won := [false]
	engine.won.connect(func(_s, _e): won[0] = true)
	_clear_one_line(engine)
	t.assert_true(won[0], "wins at custom target_lines")
	t.assert_eq(engine.score.lines, 4, "lines match custom target")


func _test_marathon_does_not_win_at_forty(t: TestSuite) -> void:
	var engine := _make_engine(GameMode.standard_marathon())
	engine.score.lines = 39
	var won := [false]
	engine.won.connect(func(_s, _e): won[0] = true)
	_clear_one_line(engine)
	t.assert_eq(engine.score.lines, 40, "marathon can reach 40 lines")
	t.assert_false(won[0], "marathon does not emit won at 40")
	t.assert_false(engine.is_won, "marathon is_won stays false")
	t.assert_ne(engine.active, null, "marathon keeps spawning after 40")


func _test_elapsed_advances_and_freezes_on_win(t: TestSuite) -> void:
	var mode := GameMode.sprint_40()
	mode.target_lines = 1
	var engine := _make_engine(mode)
	t.assert_eq(engine.elapsed_sec, 0.0, "elapsed starts at 0")

	engine.tick_gravity(1.25, false)
	t.assert_gt(engine.elapsed_sec, 1.0, "elapsed advances while playing")
	var frozen_at := engine.elapsed_sec

	_clear_one_line(engine)
	t.assert_true(engine.is_won, "won after one line")
	var after_win := engine.elapsed_sec

	engine.tick_gravity(2.0, false)
	t.assert_eq(engine.elapsed_sec, after_win, "elapsed frozen after win")
	t.assert_eq(after_win, frozen_at, "win clear does not add phantom time via hard_drop path")


func _test_top_out_does_not_emit_won(t: TestSuite) -> void:
	var engine := _make_engine(GameMode.sprint_40())
	engine.set_next_queue_for_test([
		PieceType.Id.O, PieceType.Id.I, PieceType.Id.T, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 8))
	for cell in [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)]:
		engine.grid[cell.y][cell.x] = 1
	var won := [false]
	var ended := [false]
	engine.won.connect(func(_s, _e): won[0] = true)
	engine.ended.connect(func(_s): ended[0] = true)
	engine.hard_drop()
	t.assert_true(ended[0], "top-out emits ended")
	t.assert_false(won[0], "top-out does not emit won")
	t.assert_true(engine.is_game_over, "is_game_over on top-out")
	t.assert_false(engine.is_won, "is_won false on top-out")


func _test_sprint_survives_many_locks_without_win(t: TestSuite) -> void:
	var engine := _make_engine(GameMode.sprint_40(), 99)
	var won := [false]
	engine.won.connect(func(_s, _e): won[0] = true)
	var locks := 0
	while locks < 12 and not engine.is_play_stopped():
		engine.try_move((locks % 5) - 2, 0)
		engine.try_rotate(1 if locks % 2 == 0 else -1)
		engine.tick_gravity(0.05, false)
		engine.hard_drop()
		locks += 1
	t.assert_gt(locks, 0, "performed locks")
	t.assert_false(won[0], "sprint does not win from a few locks")
	t.assert_true(engine.elapsed_sec >= 0.0, "elapsed remains valid")
	if not engine.is_play_stopped():
		t.assert_ne(engine.active, null, "still has active piece while playing")
