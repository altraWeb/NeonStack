extends SceneTree
## Sprint top-out + win transitions through main.gd (deferred present).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_ps := load("res://ui/main.tscn") as PackedScene
	var main := main_ps.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var host: Node = main.get_node("ScreenHost")
	host.get_child(0).start_pressed.emit(GameMode.sprint_40())
	await process_frame
	await process_frame

	var play: Node = host.get_child(0)
	print("play=", play.name, " timer=", play.timer_box.visible, " mode=", play.start_mode.id)
	if not play.timer_box.visible:
		printerr("TIMER_NOT_VISIBLE")
		quit(2)
		return

	# Several locks
	var engine: BoardEngine = play.controller.engine
	for i in 8:
		if engine.is_play_stopped():
			break
		engine.try_move((i % 3) - 1, 0)
		engine.try_rotate(1)
		engine.hard_drop()
		await process_frame
	print("after_locks lines=", engine.score.lines, " state=", play.controller.state, " child=", host.get_child(0).name)

	# Top-out
	engine.set_next_queue_for_test([
		PieceType.Id.O, PieceType.Id.I, PieceType.Id.T, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 8))
	for cell in [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)]:
		engine.grid[cell.y][cell.x] = 1
	engine.hard_drop()
	await process_frame
	await process_frame
	await process_frame

	var after_top: Node = host.get_child(0)
	print("after_top=", after_top.name, " count=", host.get_child_count())
	if after_top.name != "GameOverScreen" or host.get_child_count() != 1:
		printerr("TOPOUT_SWAP_FAIL")
		quit(3)
		return

	after_top.play_again.emit()
	await process_frame
	await process_frame
	play = host.get_child(0)
	print("replay=", play.name, " timer=", play.timer_box.visible)
	engine = play.controller.engine
	engine.mode.target_lines = 1
	var y := BoardEngine.ROWS - 1
	for x in BoardEngine.COLS:
		if x < 3 or x > 6:
			engine.grid[y][x] = 1
	engine.set_next_queue_for_test([
		PieceType.Id.T, PieceType.Id.O, PieceType.Id.S, PieceType.Id.Z, PieceType.Id.J,
	])
	engine.set_active_for_test(PieceType.Id.I, Vector2i(3, 0), 0)
	engine.hard_drop()
	await process_frame
	await process_frame
	await process_frame

	var after_win: Node = host.get_child(0)
	print("after_win=", after_win.name, " count=", host.get_child_count())
	if after_win.name != "GameOverScreen" or host.get_child_count() != 1:
		printerr("WIN_SWAP_FAIL")
		quit(4)
		return

	print("TRANSITION_OK")
	quit(0)
