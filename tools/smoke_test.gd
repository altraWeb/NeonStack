extends SceneTree
## Run: godot --headless --path . -s res://tools/smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var engine := BoardEngine.new()
	engine.start()
	assert(engine.active != null, "active piece after start")
	assert(engine.peek_next(5).size() == 5, "next queue size")

	engine.try_move(1, 0)
	engine.try_rotate(1)
	engine.hard_drop()
	assert(engine.active != null or engine.is_game_over, "piece after hard drop")

	if not engine.is_game_over:
		engine.hold()
		assert(engine.hold_id >= 0, "hold occupied")

	print("SMOKE_OK score=", engine.score.score, " lines=", engine.score.lines)
	quit(0)
