extends SceneTree
## Long Sprint stress: many locks, then top-out through Main screen swap.
## Watches for SCRIPT ERROR while keeping the tree alive (no app quit).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://ui/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var host: Node = main.get_node("ScreenHost")
	host.get_child(0).start_pressed.emit(GameMode.sprint_40())
	await process_frame
	await process_frame

	var play: Node = host.get_child(0)
	var engine: BoardEngine = play.controller.engine
	print("LONG_SPRINT start mode=", play.start_mode.id)

	var locks := 0
	for i in 120:
		if engine.is_play_stopped():
			break
		engine.try_move((i % 5) - 2, 0)
		if i % 3 == 0:
			engine.try_rotate(1)
		if i % 7 == 0:
			engine.try_rotate(-1)
		engine.hard_drop()
		locks += 1
		# Mimic a few gravity ticks between drops
		for _j in 2:
			engine.tick_gravity(0.016, false)
		await process_frame
		if i % 20 == 19:
			print("progress locks=", locks, " lines=", engine.score.lines, " elapsed=", engine.elapsed_sec)

	print("after_stress locks=", locks, " lines=", engine.score.lines, " stopped=", engine.is_play_stopped())

	if not engine.is_play_stopped():
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

	var after: Node = host.get_child(0)
	print("after_end screen=", after.name, " count=", host.get_child_count())
	if after.name != "GameOverScreen" or host.get_child_count() != 1:
		printerr("LONG_SPRINT_FAIL")
		quit(2)
		return
	if not is_instance_valid(main):
		printerr("MAIN_DIED")
		quit(3)
		return

	print("LONG_SPRINT_OK")
	quit(0)
