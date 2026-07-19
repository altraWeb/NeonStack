extends RefCounted
## End states must swap to GameOverScreen and keep the main shell alive.


func run() -> TestSuite:
	var t := TestSuite.new("EndScreenFlow")
	await _test_top_out_swaps_to_game_over(t)
	await _test_win_swaps_to_game_over(t)
	return t


func _test_top_out_swaps_to_game_over(t: TestSuite) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var main := (load("res://ui/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	await tree.process_frame

	var host: Node = main.get_node("ScreenHost")
	host.get_child(0).start_pressed.emit(GameMode.sprint_40())
	await tree.process_frame
	await tree.process_frame

	var play: Node = host.get_child(0)
	t.assert_eq(play.name, "PlayScene", "sprint starts PlayScene")
	var engine: BoardEngine = play.controller.engine

	for i in 6:
		if engine.is_play_stopped():
			break
		engine.hard_drop()
		await tree.process_frame

	engine.set_next_queue_for_test([
		PieceType.Id.O, PieceType.Id.I, PieceType.Id.T, PieceType.Id.S, PieceType.Id.Z,
	])
	engine.set_active_for_test(PieceType.Id.O, Vector2i(4, 8))
	for cell in [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)]:
		engine.grid[cell.y][cell.x] = 1
	engine.hard_drop()
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	var after: Node = host.get_child(0)
	t.assert_eq(after.name, "GameOverScreen", "top-out shows GameOverScreen")
	t.assert_eq(host.get_child_count(), 1, "exactly one screen after top-out")
	t.assert_true(is_instance_valid(main), "main shell still alive after top-out")
	t.assert_true(tree.root.is_inside_tree(), "root still inside tree after top-out")

	main.queue_free()
	await tree.process_frame


func _test_win_swaps_to_game_over(t: TestSuite) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var main := (load("res://ui/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	await tree.process_frame

	var host: Node = main.get_node("ScreenHost")
	host.get_child(0).start_pressed.emit(GameMode.sprint_40())
	await tree.process_frame
	await tree.process_frame

	var play: Node = host.get_child(0)
	var engine: BoardEngine = play.controller.engine
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
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	var after: Node = host.get_child(0)
	t.assert_eq(after.name, "GameOverScreen", "win shows GameOverScreen")
	t.assert_eq(host.get_child_count(), 1, "exactly one screen after win")
	t.assert_true(is_instance_valid(main), "main shell still alive after win")

	main.queue_free()
	await tree.process_frame
