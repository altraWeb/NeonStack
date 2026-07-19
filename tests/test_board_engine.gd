extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("BoardEngine")

	_test_start_spawns_piece_and_next(t)
	_test_move_blocked_by_wall(t)
	_test_hard_drop_locks_and_spawns_next(t)
	_test_hold_swaps_once_per_piece(t)
	_test_line_clear_single(t)
	_test_ghost_below_active(t)
	_test_lock_delay_locks_on_ground(t)
	_test_game_over_when_spawn_blocked(t)
	_test_rotate_o_stays_valid(t)

	return t


func _make_engine(seed_value: int = 1) -> BoardEngine:
	var engine := BoardEngine.new(seed_value)
	engine.start()
	return engine


func _fill_row(engine: BoardEngine, y: int, fill_cols: Array = []) -> void:
	var cols: Array = fill_cols
	if cols.is_empty():
		for x in BoardEngine.COLS:
			cols.append(x)
	for x in cols:
		engine.grid[y][x] = 1


func _test_start_spawns_piece_and_next(t: TestSuite) -> void:
	var engine := _make_engine(11)
	t.assert_ne(engine.active, null, "active piece after start")
	t.assert_eq(engine.peek_next(5).size(), 5, "next queue prefilled")
	t.assert_false(engine.is_game_over, "not game over at start")


func _test_move_blocked_by_wall(t: TestSuite) -> void:
	var engine := _make_engine(2)
	engine.set_active_for_test(PieceType.Id.O, Vector2i(0, 10))
	t.assert_false(engine.try_move(-1, 0), "cannot move past left wall")
	engine.set_active_for_test(PieceType.Id.O, Vector2i(8, 10))
	t.assert_false(engine.try_move(1, 0), "cannot move past right wall")
	t.assert_true(engine.try_move(-1, 0), "can move left when space exists")


func _test_hard_drop_locks_and_spawns_next(t: TestSuite) -> void:
	var engine := _make_engine(3)
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.I, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 0))
	var before_score := engine.score.score
	var distance := engine.hard_drop()
	t.assert_gt(distance, 0, "hard drop travels downward")
	t.assert_gt(engine.score.score, before_score, "hard drop awards points")
	t.assert_ne(engine.active, null, "new piece spawned after lock")
	t.assert_eq(engine.active.id, PieceType.Id.T, "next queue piece becomes active")


func _test_hold_swaps_once_per_piece(t: TestSuite) -> void:
	var engine := _make_engine(4)
	engine.set_next_queue_for_test([
		PieceType.Id.I, PieceType.Id.T, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.J, Vector2i(3, 0))
	t.assert_true(engine.hold(), "first hold succeeds")
	t.assert_eq(engine.hold_id, int(PieceType.Id.J), "held piece stored")
	t.assert_eq(engine.active.id, PieceType.Id.I, "next piece spawned into play")
	t.assert_false(engine.hold(), "second hold blocked until lock")
	engine.hard_drop()
	# After lock, hold_used resets on spawn — can hold again
	var can_hold := engine.hold()
	t.assert_true(can_hold, "hold available again after lock/spawn")


func _test_line_clear_single(t: TestSuite) -> void:
	var engine := _make_engine(5)
	# Gap of 4 for a horizontal I on the bottom row.
	var y := BoardEngine.ROWS - 1
	_fill_row(engine, y, [0, 1, 2, 7, 8, 9])
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z, PieceType.Id.J,
	])
	# I spawn orientation occupies row origin.y + 1.
	engine.set_active_for_test(PieceType.Id.I, Vector2i(3, 0), 0)
	var cleared := []
	engine.lines_cleared.connect(func(rows: Array, count: int): cleared.append(count))
	engine.hard_drop()
	t.assert_eq(cleared, [1], "exactly one line cleared")
	t.assert_eq(engine.score.lines, 1, "score lines == 1")
	for x in BoardEngine.COLS:
		t.assert_eq(engine.grid[y][x], 0, "bottom row empty after clear")


func _test_ghost_below_active(t: TestSuite) -> void:
	var engine := _make_engine(6)
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 2))
	var ghost := engine.ghost_cells()
	t.assert_eq(ghost.size(), 4, "ghost has 4 cells")
	var active_cells := engine.active.cells()
	var max_active_y := -999
	var max_ghost_y := -999
	for c in active_cells:
		max_active_y = maxi(max_active_y, c.y)
	for c in ghost:
		max_ghost_y = maxi(max_ghost_y, c.y)
	t.assert_gt(max_ghost_y, max_active_y, "ghost rests below active piece")


func _test_lock_delay_locks_on_ground(t: TestSuite) -> void:
	var engine := _make_engine(7)
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.I, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, BoardEngine.ROWS - 2))
	var lock_count := [0]
	engine.piece_locked.connect(func(_id, _cells): lock_count[0] += 1)
	# One frame arms lock; second frame with full delay should commit.
	engine.lock_delay = 0.5
	engine.tick_gravity(0.01, false)
	engine.tick_gravity(0.5, false)
	t.assert_eq(lock_count[0], 1, "lock delay expires into lock")
	t.assert_eq(engine.active.id, PieceType.Id.T, "next queue piece spawned after lock")


func _test_game_over_when_spawn_blocked(t: TestSuite) -> void:
	var engine := _make_engine(8)
	engine.set_next_queue_for_test([
		PieceType.Id.O, PieceType.Id.I, PieceType.Id.T, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 8))
	# Block O spawn cells without completing full lines (full lines would clear on lock).
	for cell in [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)]:
		engine.grid[cell.y][cell.x] = 1
	var end_count := [0]
	engine.ended.connect(func(_score): end_count[0] += 1)
	engine.hard_drop()
	t.assert_eq(end_count[0], 1, "ended signal on blocked spawn")
	t.assert_true(engine.is_game_over, "is_game_over after blocked spawn")


func _test_rotate_o_stays_valid(t: TestSuite) -> void:
	var engine := _make_engine(9)
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 8))
	var origin_before := engine.active.origin
	t.assert_true(engine.try_rotate(1), "O rotate reports success")
	t.assert_eq(engine.active.origin, origin_before, "O rotate does not move origin")
