class_name GameController
extends Node

signal state_changed(state: State)
signal board_updated

enum State { READY, PLAYING, PAUSED, GAME_OVER, WON, TIMED_OUT }

var engine: BoardEngine
var mode: GameMode
var theme: ThemePack
var highscores: HighscoreStore

var state: State = State.READY

var _move_repeat: RepeatInput
var _soft_repeat: RepeatInput
var _move_dir: int = 0


func _ready() -> void:
	engine = BoardEngine.new()
	mode = GameMode.standard_marathon()
	theme = ThemePack.cyberpunk_default()
	highscores = LocalHighscoreStore.new()
	_move_repeat = RepeatInput.new()
	_soft_repeat = RepeatInput.new()
	apply_feel_settings()
	_wire_events()


func apply_feel_settings() -> void:
	SettingsService.clamp_feel()
	_move_repeat.das_sec = SettingsService.das_ms / 1000.0
	_move_repeat.arr_sec = maxf(0.001, SettingsService.arr_ms / 1000.0)
	_soft_repeat.das_sec = 0.0
	_soft_repeat.arr_sec = maxf(0.001, SettingsService.soft_drop_arr_ms / 1000.0)
	engine.lock_delay = SettingsService.lock_delay_ms / 1000.0


func _wire_events() -> void:
	engine.started.connect(func(): GameEvents.game_started.emit())
	engine.piece_spawned.connect(func(id: int): GameEvents.piece_spawned.emit(id))
	engine.piece_locked.connect(func(id: int, cells: Array): GameEvents.piece_locked.emit(id, cells))
	engine.piece_held.connect(func(id: int): GameEvents.piece_held.emit(id))
	engine.lines_cleared.connect(func(rows: Array, count: int): GameEvents.lines_cleared.emit(rows, count))
	engine.hard_dropped.connect(func(distance: int): GameEvents.hard_dropped.emit(distance))
	engine.score_changed.connect(func(s: int, lines: int, level: int): GameEvents.score_changed.emit(s, lines, level))
	engine.leveled_up.connect(func(level: int): GameEvents.level_up.emit(level))
	engine.ended.connect(_on_engine_ended)
	engine.won.connect(_on_engine_won)
	engine.timed_out.connect(_on_engine_timed_out)


func start_game(game_mode: GameMode = null) -> void:
	if game_mode != null:
		mode = game_mode
	engine.configure_mode(mode)
	apply_feel_settings()
	engine.start()
	_move_repeat.end()
	_soft_repeat.end()
	_move_dir = 0
	_set_state(State.PLAYING)
	board_updated.emit()


func toggle_pause() -> void:
	if state == State.PLAYING:
		_set_state(State.PAUSED)
		GameEvents.game_paused.emit(true)
	elif state == State.PAUSED:
		apply_feel_settings()
		_set_state(State.PLAYING)
		GameEvents.game_paused.emit(false)


func _set_state(next: State) -> void:
	state = next
	state_changed.emit(state)


func _on_engine_ended(final_score: int) -> void:
	if _is_terminal_state():
		return
	_stop_repeat_inputs()
	_set_state(State.GAME_OVER)
	GameEvents.game_over.emit(final_score)


func _on_engine_won(final_score: int, elapsed_sec: float) -> void:
	if _is_terminal_state():
		return
	_stop_repeat_inputs()
	_set_state(State.WON)
	GameEvents.game_won.emit(final_score, elapsed_sec)


func _on_engine_timed_out(final_score: int, elapsed_sec: float) -> void:
	if _is_terminal_state():
		return
	_stop_repeat_inputs()
	_set_state(State.TIMED_OUT)
	GameEvents.game_timed_out.emit(final_score, elapsed_sec)


func _is_terminal_state() -> bool:
	return state == State.GAME_OVER or state == State.WON or state == State.TIMED_OUT


func _stop_repeat_inputs() -> void:
	_move_repeat.end()
	_soft_repeat.end()
	_move_dir = 0


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	_tick_move_repeat(delta)
	var soft := Input.is_action_pressed("soft_drop")
	if soft:
		_tick_soft_repeat(delta)
	engine.tick_gravity(delta, soft)
	board_updated.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING or state == State.PAUSED:
			toggle_pause()
			get_viewport().set_input_as_handled()
		return

	if state != State.PLAYING:
		return

	if event.is_action_pressed("move_left"):
		_press_move(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_press_move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_released("move_left") or event.is_action_released("move_right"):
		_release_move()
	elif event.is_action_pressed("rotate_cw"):
		if engine.try_rotate(1):
			AudioDirector.play_rotate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotate_ccw"):
		if engine.try_rotate(-1):
			AudioDirector.play_rotate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hard_drop"):
		_soft_repeat.end()
		engine.hard_drop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hold"):
		if mode.enable_hold:
			engine.hold()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("soft_drop"):
		if engine.soft_drop_step():
			AudioDirector.play_move()
		_soft_repeat.begin(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_released("soft_drop"):
		_soft_repeat.end()


func _press_move(dir: int) -> void:
	_move_dir = dir
	_move_repeat.begin(false)
	if engine.try_move(dir, 0):
		AudioDirector.play_move()


func _release_move() -> void:
	if Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		_press_move(-1)
	elif Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		_press_move(1)
	else:
		_move_dir = 0
		_move_repeat.end()


func _tick_move_repeat(delta: float) -> void:
	if _move_dir == 0:
		return
	if not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		_move_dir = 0
		_move_repeat.end()
		return

	var steps := _move_repeat.tick(delta)
	for _i in steps:
		if not engine.try_move(_move_dir, 0):
			break
		AudioDirector.play_move()


func _tick_soft_repeat(delta: float) -> void:
	if not Input.is_action_pressed("soft_drop"):
		if _soft_repeat.is_active():
			_soft_repeat.end()
		return

	if not _soft_repeat.is_active():
		_soft_repeat.begin(true)

	var steps := _soft_repeat.tick(delta)
	for _i in steps:
		if not engine.soft_drop_step():
			break
