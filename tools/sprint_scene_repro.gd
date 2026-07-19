extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== Scene sprint repro ===")
	var main_ps := load("res://ui/main.tscn") as PackedScene
	var main := main_ps.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# Find title and press sprint via signal path
	var host: Node = main.get_node("ScreenHost")
	var title = host.get_child(0)
	print("title=", title)
	if title.has_signal("start_pressed"):
		title.start_pressed.emit(GameMode.sprint_40())
	await process_frame
	await process_frame

	var play = host.get_child(0)
	print("play=", play, " start_mode=", play.start_mode.id if play.get("start_mode") else "?")
	var controller = play.controller
	print("state=", controller.state, " engine_mode=", controller.engine.mode.id, " timer_visible=", play.timer_box.visible)

	# Simulate several hard drops via engine
	for i in 12:
		if controller.engine.is_play_stopped():
			break
		controller.engine.try_move((i % 3) - 1, 0)
		controller.engine.try_rotate(1 if i % 2 == 0 else -1)
		controller.engine.hard_drop()
		# mimic process ticks
		for _j in 3:
			controller.engine.tick_gravity(0.016, false)
			controller.board_updated.emit()
		await process_frame
		print("move", i, " lines=", controller.engine.score.lines, " time=", play.timer_label.text, " err_check_ok")

	print("SCENE_SPRINT_OK score=", controller.engine.score.score)
	quit(0)
