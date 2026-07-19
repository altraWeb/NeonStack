extends SceneTree
## Headless test runner.
## Usage:
##   godot --headless --path . -s res://tests/run_tests.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Neon Stack tests (TAD baseline) ===")
	var suites: Array = [
		preload("res://tests/test_bag_randomizer.gd").new(),
		preload("res://tests/test_srs.gd").new(),
		preload("res://tests/test_score_state.gd").new(),
		preload("res://tests/test_piece_type.gd").new(),
		preload("res://tests/test_board_engine.gd").new(),
		preload("res://tests/test_repeat_input.gd").new(),
		preload("res://tests/test_soft_drop_feel.gd").new(),
		preload("res://tests/test_game_mode.gd").new(),
		preload("res://tests/test_sprint_mode.gd").new(),
		preload("res://tests/test_screen_swap.gd").new(),
		preload("res://tests/test_end_screen_flow.gd").new(),
		preload("res://tests/test_mode_highscores.gd").new(),
		preload("res://tests/test_ultra_mode.gd").new(),
	]

	var total_pass := 0
	var total_fail := 0
	var all_errors: PackedStringArray = []

	for suite_script in suites:
		# Await so suites that flush frames (deferred screen swaps) can complete.
		var result: TestSuite = await suite_script.run()
		print(result.summary())
		total_pass += result.passed
		total_fail += result.failed
		for err in result.errors:
			all_errors.append(err)

	print("---------------------------------------")
	print("TOTAL: %d passed, %d failed" % [total_pass, total_fail])
	if total_fail > 0:
		for err in all_errors:
			print("  • ", err)
		print("TEST_FAIL")
		quit(1)
	else:
		print("TEST_OK")
		quit(0)
