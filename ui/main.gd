extends Control
## Root shell. End states always swap screens — never quit the application.

const ScreenSwap := preload("res://ui/screen_swap.gd")

@onready var starfield: ColorRect = %Starfield
@onready var screen_host: Control = %ScreenHost
@onready var post_fx: ColorRect = %PostFX

var _title_scene := preload("res://ui/title_screen.tscn")
var _play_scene := preload("res://game/play_scene.tscn")
var _game_over_scene := preload("res://ui/game_over_screen.tscn")
var _scores_scene := preload("res://ui/scores_screen.tscn")
var _current: Node
var _post_mat: ShaderMaterial
var _active_mode: GameMode = GameMode.standard_marathon()
var _pending_end: Dictionary = {}
var _presenting_end: bool = false


func _ready() -> void:
	var city := load("res://vfx/cyber_city.gdshader") as Shader
	var city_mat := ShaderMaterial.new()
	city_mat.shader = city
	city_mat.set_shader_parameter("glitch_amount", 0.48)
	starfield.material = city_mat

	var post := load("res://vfx/post_glitch.gdshader") as Shader
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = post
	_post_mat.set_shader_parameter("chroma", 0.005)
	_post_mat.set_shader_parameter("scan_strength", 0.075)
	post_fx.material = _post_mat
	post_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_show_title()


func _process(_delta: float) -> void:
	if _post_mat and AudioDirector:
		var kick: float = AudioDirector.get_post_kick()
		_post_mat.set_shader_parameter("kick", kick)
		# Slight ambient chroma even when idle so the CRT feel never goes flat
		_post_mat.set_shader_parameter("chroma", 0.004 + kick * 0.002)


func _clear_screen() -> void:
	ScreenSwap.clear(screen_host, _current)
	_current = null


func _disconnect_play_signals(play: Node) -> void:
	if play == null or not is_instance_valid(play):
		return
	if play.has_signal("exit_to_title") and play.exit_to_title.is_connected(_show_title):
		play.exit_to_title.disconnect(_show_title)
	if play.has_signal("game_ended") and play.game_ended.is_connected(_on_game_ended):
		play.game_ended.disconnect(_on_game_ended)


func _show_title() -> void:
	_pending_end.clear()
	_presenting_end = false
	_disconnect_play_signals(_current)
	_clear_screen()
	var screen := _title_scene.instantiate()
	if screen == null:
		push_error("Failed to instantiate title screen")
		return
	_current = ScreenSwap.replace(screen_host, null, screen)
	screen.start_pressed.connect(_start_game)
	screen.scores_pressed.connect(_show_scores)


func _start_game(mode: GameMode = null) -> void:
	_pending_end.clear()
	_presenting_end = false
	if mode != null:
		_active_mode = mode
	_disconnect_play_signals(_current)
	_clear_screen()
	var play := _play_scene.instantiate()
	if play == null:
		push_error("Failed to instantiate play scene")
		_show_title()
		return
	play.start_mode = _active_mode
	_current = ScreenSwap.replace(screen_host, null, play)
	play.exit_to_title.connect(_show_title)
	play.game_ended.connect(_on_game_ended)


func _on_game_ended(score: int, lines: int, level: int, is_win: bool, elapsed_sec: float) -> void:
	# Defer presentation so we never mutate the tree mid-signal from PlayScene.
	# Top-out / win must only swap to the end screen — never quit the app.
	if _presenting_end:
		return
	_presenting_end = true
	_pending_end = {
		"score": score,
		"lines": lines,
		"level": level,
		"is_win": is_win,
		"elapsed_sec": elapsed_sec,
	}
	call_deferred("_present_game_over")


func _present_game_over() -> void:
	if _pending_end.is_empty():
		_presenting_end = false
		return
	var payload := _pending_end.duplicate()
	_pending_end.clear()

	_disconnect_play_signals(_current)
	_clear_screen()

	var go := _game_over_scene.instantiate()
	if go == null or not is_instance_valid(screen_host):
		push_error("Failed to present game over screen — returning to title")
		_presenting_end = false
		_show_title()
		return

	_current = ScreenSwap.replace(screen_host, null, go)
	if not is_instance_valid(go):
		push_error("Game over screen invalid after add — returning to title")
		_presenting_end = false
		_show_title()
		return

	go.show_result(
		int(payload["score"]),
		int(payload["lines"]),
		int(payload["level"]),
		bool(payload["is_win"]),
		float(payload["elapsed_sec"]),
		_active_mode
	)
	go.play_again.connect(func(): _start_game(_active_mode))
	go.back_to_title.connect(_show_title)
	_presenting_end = false


func _show_scores() -> void:
	_pending_end.clear()
	_presenting_end = false
	_disconnect_play_signals(_current)
	_clear_screen()
	var scores := _scores_scene.instantiate()
	if scores == null:
		push_error("Failed to instantiate scores screen")
		_show_title()
		return
	_current = ScreenSwap.replace(screen_host, null, scores)
	scores.back_pressed.connect(_show_title)
	scores.refresh()
