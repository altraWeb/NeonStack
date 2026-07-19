extends RefCounted

const TMP := "user://test_settings_feel.cfg"


func run() -> TestSuite:
	var t := TestSuite.new("SettingsFeel")
	_wipe()
	var ss := _settings()
	_backup_and_isolate(ss)

	_test_clamp_feel_ranges(t, ss)
	_test_reset_feel_defaults(t, ss)
	_test_roundtrip_persist(t, ss)
	await _test_controller_applies_feel(t, ss)

	_restore(ss)
	_wipe()
	return t


func _settings() -> Node:
	return Engine.get_main_loop().root.get_node("SettingsService")


func _wipe() -> void:
	var abs_path := ProjectSettings.globalize_path(TMP)
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(abs_path)


var _prev_path: String = ""
var _prev_das: float
var _prev_arr: float
var _prev_soft: float
var _prev_lock: float


func _backup_and_isolate(ss: Node) -> void:
	_prev_path = ss.get_path_for_test()
	_prev_das = ss.das_ms
	_prev_arr = ss.arr_ms
	_prev_soft = ss.soft_drop_arr_ms
	_prev_lock = ss.lock_delay_ms
	ss.set_path_for_test(TMP)
	ss.reset_feel_defaults()


func _restore(ss: Node) -> void:
	ss.set_path_for_test(_prev_path)
	ss.das_ms = _prev_das
	ss.arr_ms = _prev_arr
	ss.soft_drop_arr_ms = _prev_soft
	ss.lock_delay_ms = _prev_lock


func _test_clamp_feel_ranges(t: TestSuite, ss: Node) -> void:
	ss.das_ms = -10.0
	ss.arr_ms = 0.0
	ss.soft_drop_arr_ms = 999.0
	ss.lock_delay_ms = 50.0
	ss.clamp_feel()
	t.assert_eq(ss.das_ms, 0.0, "DAS floor 0")
	t.assert_eq(ss.arr_ms, 1.0, "ARR floor 1")
	t.assert_eq(ss.soft_drop_arr_ms, 100.0, "soft ARR ceiling 100")
	t.assert_eq(ss.lock_delay_ms, 100.0, "lock floor 100")


func _test_reset_feel_defaults(t: TestSuite, ss: Node) -> void:
	ss.das_ms = 12.0
	ss.arr_ms = 12.0
	ss.soft_drop_arr_ms = 12.0
	ss.lock_delay_ms = 12.0
	ss.reset_feel_defaults()
	t.assert_eq(ss.das_ms, 167.0, "DAS default")
	t.assert_eq(ss.arr_ms, 33.0, "ARR default")
	t.assert_eq(ss.soft_drop_arr_ms, 50.0, "soft default")
	t.assert_eq(ss.lock_delay_ms, 500.0, "lock default")


func _test_roundtrip_persist(t: TestSuite, ss: Node) -> void:
	ss.das_ms = 200.0
	ss.arr_ms = 40.0
	ss.soft_drop_arr_ms = 25.0
	ss.lock_delay_ms = 350.0
	ss.clamp_feel()
	ss.save_settings()

	ss.reset_feel_defaults()
	t.assert_eq(ss.das_ms, 167.0, "defaults before reload")
	ss.load_settings()
	t.assert_eq(ss.das_ms, 200.0, "DAS reloaded")
	t.assert_eq(ss.arr_ms, 40.0, "ARR reloaded")
	t.assert_eq(ss.soft_drop_arr_ms, 25.0, "soft reloaded")
	t.assert_eq(ss.lock_delay_ms, 350.0, "lock reloaded")


func _test_controller_applies_feel(t: TestSuite, ss: Node) -> void:
	# Runtime load avoids compile-order issues with the SettingsService autoload.
	var tree := Engine.get_main_loop() as SceneTree
	var script := load("res://game/game_controller.gd") as GDScript
	t.assert_true(script != null, "GameController script loads")
	var gc: Node = script.new()
	tree.root.add_child(gc)
	await tree.process_frame

	ss.das_ms = 180.0
	ss.arr_ms = 20.0
	ss.soft_drop_arr_ms = 30.0
	ss.lock_delay_ms = 450.0
	gc.call("apply_feel_settings")

	t.assert_true(is_equal_approx(gc.get("_move_repeat").das_sec, 0.18), "move DAS applied")
	t.assert_true(is_equal_approx(gc.get("_move_repeat").arr_sec, 0.02), "move ARR applied")
	t.assert_true(is_equal_approx(gc.get("_soft_repeat").arr_sec, 0.03), "soft ARR applied")
	t.assert_true(is_equal_approx(gc.get("engine").lock_delay, 0.45), "lock delay applied")

	gc.queue_free()
	await tree.process_frame
