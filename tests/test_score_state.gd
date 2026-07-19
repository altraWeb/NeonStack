extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("ScoreState")

	_test_reset(t)
	_test_soft_and_hard_drop(t)
	_test_line_clear_table(t)
	_test_level_up_every_ten_lines(t)

	return t


func _test_reset(t: TestSuite) -> void:
	var s := ScoreState.new()
	s.add_soft_drop(5)
	s.add_line_clear(1)
	s.reset()
	t.assert_eq(s.score, 0, "reset clears score")
	t.assert_eq(s.lines, 0, "reset clears lines")
	t.assert_eq(s.level, 1, "reset restores level 1")


func _test_soft_and_hard_drop(t: TestSuite) -> void:
	var s := ScoreState.new()
	s.add_soft_drop(3)
	t.assert_eq(s.score, 3, "soft drop is 1 pt per cell")
	s.add_hard_drop(4)
	t.assert_eq(s.score, 11, "hard drop is 2 pts per cell")


func _test_line_clear_table(t: TestSuite) -> void:
	var cases := {
		1: 100,
		2: 300,
		3: 500,
		4: 800,
	}
	for cleared in cases.keys():
		var s := ScoreState.new()
		s.add_line_clear(int(cleared))
		t.assert_eq(s.score, int(cases[cleared]) * s.level, "clear %s scoring" % str(cleared))
		t.assert_eq(s.lines, int(cleared), "lines tracked for clear %s" % str(cleared))


func _test_level_up_every_ten_lines(t: TestSuite) -> void:
	var s := ScoreState.new()
	var leveled := []
	s.leveled_up.connect(func(lv: int): leveled.append(lv))
	# 10 singles → level 2
	for _i in 10:
		s.add_line_clear(1)
	t.assert_eq(s.level, 2, "level becomes 2 after 10 lines")
	t.assert_eq(leveled, [2], "leveled_up emitted once to 2")
	t.assert_gt(s.score, 0, "score accrued during clears")
