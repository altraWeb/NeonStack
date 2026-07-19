extends Control

signal exit_to_title
signal game_ended(score: int, lines: int, level: int, is_win: bool, elapsed_sec: float, timed_out: bool)

@onready var board_view: BoardView = %BoardView
@onready var hud: Control = %HUD
@onready var pause_overlay: Control = %PauseOverlay
@onready var score_label: Label = %ScoreValue
@onready var level_label: Label = %LevelValue
@onready var lines_label: Label = %LinesValue
@onready var lines_title: Label = %LinesTitle
@onready var timer_box: Control = %TimerBox
@onready var timer_label: Label = %TimerValue
@onready var hold_panel: DockPanel = %HoldPanel
@onready var next_panel: DockPanel = %NextPanel
@onready var pause_label: Label = %PauseLabel
@onready var settings_panel: VBoxContainer = $PauseOverlay/PauseColumn/SettingsPanel

var controller: GameController
var start_mode: GameMode = GameMode.standard_marathon()
var _final_packet_shown: bool = false
var _override_active: bool = false


func _ready() -> void:
	controller = GameController.new()
	add_child(controller)
	board_view.setup(controller)
	hold_panel.setup(controller, DockPanel.Mode.HOLD)
	next_panel.setup(controller, DockPanel.Mode.NEXT)
	controller.state_changed.connect(_on_state_changed)
	controller.board_updated.connect(_refresh_hud)
	GameEvents.score_changed.connect(_on_score)
	GameEvents.lines_cleared.connect(_on_lines_cleared)
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.game_won.connect(_on_game_won)
	GameEvents.game_timed_out.connect(_on_game_timed_out)
	if settings_panel != null and settings_panel.has_signal("changed"):
		settings_panel.changed.connect(_on_settings_changed)
	pause_overlay.visible = false
	_configure_mode_hud()
	controller.start_game(start_mode)
	_refresh_hud()


func _exit_tree() -> void:
	if GameEvents.score_changed.is_connected(_on_score):
		GameEvents.score_changed.disconnect(_on_score)
	if GameEvents.lines_cleared.is_connected(_on_lines_cleared):
		GameEvents.lines_cleared.disconnect(_on_lines_cleared)
	if GameEvents.game_over.is_connected(_on_game_over):
		GameEvents.game_over.disconnect(_on_game_over)
	if GameEvents.game_won.is_connected(_on_game_won):
		GameEvents.game_won.disconnect(_on_game_won)
	if GameEvents.game_timed_out.is_connected(_on_game_timed_out):
		GameEvents.game_timed_out.disconnect(_on_game_timed_out)


func _configure_mode_hud() -> void:
	var show_timer := start_mode != null and (start_mode.win_on_target or start_mode.has_time_limit())
	timer_box.visible = show_timer
	lines_title.text = "LINES"
	_final_packet_shown = false
	_override_active = false
	timer_label.modulate = Color(1, 1, 1, 1)


func _on_state_changed(state: GameController.State) -> void:
	pause_overlay.visible = state == GameController.State.PAUSED
	if state == GameController.State.PAUSED:
		pause_label.text = "PAUSED"


func _on_settings_changed() -> void:
	# Feel changes in pause apply immediately so resume matches the dials.
	if controller != null:
		controller.apply_feel_settings()


func _on_score(score: int, lines: int, level: int) -> void:
	score_label.text = "%06d" % score
	level_label.text = "%02d" % level
	_update_lines_label(lines)
	_pulse_hud_value(score_label)
	_pulse_hud_value(lines_label)


func _on_lines_cleared(_rows: Array, _count: int) -> void:
	if start_mode == null or not start_mode.has_time_limit():
		return
	if controller == null or controller.engine == null:
		return
	# Last-second clear: brief score pulse only (no slogan stamp).
	if controller.engine.time_remaining() <= 1.0 and not _final_packet_shown:
		_final_packet_shown = true
		_pulse_hud_value(score_label)


func _pulse_hud_value(label: Label) -> void:
	label.modulate = Color(1.0, 0.85, 0.35, 1.0)
	var tw := create_tween()
	tw.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.28).set_trans(Tween.TRANS_SINE)


func _refresh_hud() -> void:
	if controller == null or controller.engine == null:
		return
	var s := controller.engine.score
	score_label.text = "%06d" % s.score
	level_label.text = "%02d" % s.level
	_update_lines_label(s.lines)
	if timer_box.visible:
		_update_timer_label()


func _update_timer_label() -> void:
	var engine := controller.engine
	if start_mode != null and start_mode.has_time_limit():
		var remaining := engine.time_remaining()
		timer_label.text = _format_time(remaining)
		_style_ultra_timer(remaining)
	else:
		timer_label.text = _format_time(engine.elapsed_sec)
		timer_label.modulate = Color(1, 1, 1, 1)
		_override_active = false


func _style_ultra_timer(remaining: float) -> void:
	if remaining <= 10.0:
		_override_active = true
		var pulse := 0.65 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.012))
		timer_label.modulate = Color(1.0, 0.25 + pulse * 0.15, 0.3, 1.0)
	elif remaining <= 30.0:
		_override_active = false
		timer_label.modulate = Color(1.0, 0.6, 0.3, 1.0)
	else:
		_override_active = false
		timer_label.modulate = Color(0.7, 0.9, 0.95, 1.0)


func _update_lines_label(lines: int) -> void:
	if start_mode != null and start_mode.win_on_target and start_mode.target_lines > 0:
		lines_label.text = "%d/%d" % [lines, start_mode.target_lines]
	else:
		lines_label.text = "%03d" % lines


func _format_time(sec: float) -> String:
	var clamped := maxf(0.0, sec)
	var total_ms := int(clamped * 1000.0)
	var minutes := total_ms / 60000
	var seconds := (total_ms % 60000) / 1000
	var millis := (total_ms % 1000) / 10
	return "%d:%02d.%02d" % [minutes, seconds, millis]


func _on_game_over(final_score: int) -> void:
	_emit_game_ended(final_score, false, -1.0, false)


func _on_game_won(final_score: int, elapsed_sec: float) -> void:
	_emit_game_ended(final_score, true, elapsed_sec, false)


func _on_game_timed_out(final_score: int, elapsed_sec: float) -> void:
	_emit_game_ended(final_score, false, elapsed_sec, true)


func _emit_game_ended(final_score: int, is_win: bool, elapsed_override: float, timed_out: bool) -> void:
	# End states hand off to Main for a screen swap; never quit the tree.
	if not is_inside_tree() or controller == null or controller.engine == null:
		return
	var s := controller.engine.score
	var elapsed := elapsed_override if elapsed_override >= 0.0 else controller.engine.elapsed_sec
	game_ended.emit(final_score, s.lines, s.level, is_win, elapsed, timed_out)


func _unhandled_input(event: InputEvent) -> void:
	if controller == null:
		return
	if controller.state == GameController.State.PAUSED and event.is_action_pressed("ui_confirm"):
		exit_to_title.emit()
		get_viewport().set_input_as_handled()
