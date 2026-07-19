extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("Srs")

	_test_o_has_only_zero_kick(t)
	_test_jlstz_has_five_offsets(t)
	_test_i_has_five_offsets(t)
	_test_reverse_tables_exist(t)

	return t


func _test_o_has_only_zero_kick(t: TestSuite) -> void:
	var kicks := Srs.kicks(PieceType.Id.O, 0, 1)
	t.assert_eq(kicks.size(), 1, "O piece has a single kick")
	t.assert_eq(kicks[0], Vector2i.ZERO, "O kick is zero")


func _test_jlstz_has_five_offsets(t: TestSuite) -> void:
	var kicks := Srs.kicks(PieceType.Id.T, 0, 1)
	t.assert_eq(kicks.size(), 5, "JLSTZ 0>1 has 5 offsets")
	t.assert_eq(kicks[0], Vector2i.ZERO, "first kick is identity")


func _test_i_has_five_offsets(t: TestSuite) -> void:
	var kicks := Srs.kicks(PieceType.Id.I, 0, 1)
	t.assert_eq(kicks.size(), 5, "I 0>1 has 5 offsets")
	t.assert_eq(kicks[1], Vector2i(-2, 0), "I second kick matches SRS table")


func _test_reverse_tables_exist(t: TestSuite) -> void:
	for piece in [PieceType.Id.T, PieceType.Id.I]:
		for from_rot in 4:
			var to_rot := posmod(from_rot + 1, 4)
			var forward := Srs.kicks(piece, from_rot, to_rot)
			var back := Srs.kicks(piece, to_rot, from_rot)
			t.assert_eq(forward.size(), 5, "forward kicks for %s %d>%d" % [piece, from_rot, to_rot])
			t.assert_eq(back.size(), 5, "back kicks for %s %d>%d" % [piece, to_rot, from_rot])
