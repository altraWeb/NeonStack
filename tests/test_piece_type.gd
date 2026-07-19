extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("PieceType")

	_test_each_piece_has_four_cells(t)
	_test_o_is_rotation_invariant(t)
	_test_absolute_cells_apply_origin(t)
	_test_spawn_origins_in_board(t)

	return t


func _test_each_piece_has_four_cells(t: TestSuite) -> void:
	for id in [
		PieceType.Id.I, PieceType.Id.O, PieceType.Id.T,
		PieceType.Id.S, PieceType.Id.Z, PieceType.Id.J, PieceType.Id.L,
	]:
		var states: Array = PieceType.cells(id)
		t.assert_eq(states.size(), 4, "%s has 4 rotation states" % PieceType.NAMES[id])
		for rot in 4:
			t.assert_eq(states[rot].size(), 4, "%s rot %d has 4 cells" % [PieceType.NAMES[id], rot])


func _test_o_is_rotation_invariant(t: TestSuite) -> void:
	var states: Array = PieceType.cells(PieceType.Id.O)
	for rot in 4:
		t.assert_eq(states[rot], states[0], "O rotation %d matches spawn shape" % rot)


func _test_absolute_cells_apply_origin(t: TestSuite) -> void:
	var cells := PieceType.absolute_cells(PieceType.Id.O, 0, Vector2i(3, 5))
	t.assert_true(cells.has(Vector2i(3, 5)), "origin cell present")
	t.assert_true(cells.has(Vector2i(4, 6)), "far corner present")
	t.assert_eq(cells.size(), 4, "absolute cell count")


func _test_spawn_origins_in_board(t: TestSuite) -> void:
	for id in PieceType.SPAWN.keys():
		var origin: Vector2i = PieceType.SPAWN[id]
		t.assert_true(origin.x >= 0 and origin.x < BoardEngine.COLS, "spawn x in board for %s" % id)
		t.assert_true(origin.y >= 0, "spawn y non-negative for %s" % id)
