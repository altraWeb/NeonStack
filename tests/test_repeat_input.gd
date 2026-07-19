extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("RepeatInput")

	_test_no_steps_while_inactive(t)
	_test_das_then_one_step(t)
	_test_arr_repeats(t)
	_test_release_resets(t)
	_test_skip_das_for_soft_drop(t)

	return t


func _test_no_steps_while_inactive(t: TestSuite) -> void:
	var r := RepeatInput.new(0.167, 0.033)
	t.assert_eq(r.tick(1.0), 0, "inactive produces no steps")


func _test_das_then_one_step(t: TestSuite) -> void:
	var r := RepeatInput.new(0.167, 0.033)
	r.begin()
	t.assert_eq(r.tick(0.100), 0, "before DAS charged: no steps")
	t.assert_eq(r.tick(0.070), 1, "crossing DAS yields one step")


func _test_arr_repeats(t: TestSuite) -> void:
	var r := RepeatInput.new(0.10, 0.05)
	r.begin()
	r.tick(0.10) # charge + first repeat step
	t.assert_eq(r.tick(0.12), 2, "ARR can fire multiple steps in one tick")


func _test_release_resets(t: TestSuite) -> void:
	var r := RepeatInput.new(0.10, 0.05)
	r.begin()
	r.tick(0.10)
	r.end()
	t.assert_eq(r.tick(1.0), 0, "after end: no steps")
	r.begin()
	t.assert_eq(r.tick(0.05), 0, "DAS clock restarts after re-begin")


func _test_skip_das_for_soft_drop(t: TestSuite) -> void:
	var r := RepeatInput.new(0.20, 0.05)
	r.begin(true)
	t.assert_eq(r.tick(0.05), 1, "skip_das enters ARR immediately")
	t.assert_eq(r.tick(0.05), 1, "subsequent ARR step")
