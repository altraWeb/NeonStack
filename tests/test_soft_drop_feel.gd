extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("SoftDropFeel")

	_test_soft_drop_moves_one_row(t)
	_test_soft_drop_scores(t)
	_test_lock_delay_respects_setting(t)

	return t


func _test_soft_drop_moves_one_row(t: TestSuite) -> void:
	var engine := BoardEngine.new(1)
	engine.start()
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 5))
	var y0 := engine.active.origin.y
	t.assert_true(engine.soft_drop_step(), "soft drop succeeds in open space")
	t.assert_eq(engine.active.origin.y, y0 + 1, "soft drop moves one row")


func _test_soft_drop_scores(t: TestSuite) -> void:
	var engine := BoardEngine.new(2)
	engine.start()
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 5))
	var before := engine.score.score
	engine.soft_drop_step()
	t.assert_eq(engine.score.score, before + 1, "soft drop awards 1 point")


func _test_lock_delay_respects_setting(t: TestSuite) -> void:
	var engine := BoardEngine.new(3)
	engine.start()
	engine.lock_delay = 0.2
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.I, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, BoardEngine.ROWS - 2))
	var locks := [0]
	engine.piece_locked.connect(func(_id, _cells): locks[0] += 1)
	engine.tick_gravity(0.01, false)
	engine.tick_gravity(0.18, false)
	t.assert_eq(locks[0], 0, "not locked before custom delay")
	engine.tick_gravity(0.02, false)
	t.assert_eq(locks[0], 1, "locks once custom delay elapsed")
