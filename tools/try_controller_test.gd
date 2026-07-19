extends SceneTree
func _init() -> void:
	call_deferred("r")
func r() -> void:
	var suite_script = load("res://tests/test_game_controller_compile.gd")
	print("loaded=", suite_script)
	var s = suite_script.new()
	var t = s.run()
	print(t.name, " ", t.passed, "/", t.failed)
	quit(0 if t.failed == 0 else 1)
