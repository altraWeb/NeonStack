extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("GameMode")

	_test_standard_marathon_defaults(t)
	_test_sprint_40_factory(t)
	_test_ultra_180_factory(t)

	return t


func _test_standard_marathon_defaults(t: TestSuite) -> void:
	var mode := GameMode.standard_marathon()
	t.assert_eq(mode.id, "standard_marathon", "marathon id")
	t.assert_ne(mode.display_name, "", "marathon has display name")
	t.assert_false(mode.win_on_target, "marathon does not win on target")
	t.assert_eq(mode.target_lines, 0, "marathon has no line target")


func _test_sprint_40_factory(t: TestSuite) -> void:
	var mode := GameMode.sprint_40()
	t.assert_eq(mode.id, "sprint_40", "sprint id")
	t.assert_ne(mode.display_name, "", "sprint has display name")
	t.assert_true(mode.win_on_target, "sprint wins on target")
	t.assert_eq(mode.target_lines, 40, "sprint targets 40 lines")
	t.assert_false(mode.has_time_limit(), "sprint has no duration limit")


func _test_ultra_180_factory(t: TestSuite) -> void:
	var mode := GameMode.ultra_180()
	t.assert_eq(mode.id, "ultra_180", "ultra id")
	t.assert_eq(mode.duration_sec, 180.0, "ultra is 180 seconds")
	t.assert_true(mode.has_time_limit(), "ultra has time limit")
	t.assert_false(mode.win_on_target, "ultra is not win-on-target")
