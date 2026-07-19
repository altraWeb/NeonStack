extends Control

signal exit_to_title
signal game_ended(score: int, lines: int, level: int, is_win: bool, elapsed_sec: float)

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

var controller: GameController
var start_mode: GameMode = GameMode.standard_marathon()


func _ready() -> void:
	controller = GameController.new()
	add_child(controller)
	board_view.setup(controller)
	hold_panel.setup(controller, DockPanel.Mode.HOLD)
	next_panel.setup(controller, DockPanel.Mode.NEXT)
	controller.state_changed.connect(_on_state_changed)
	controller.board_updated.connect(_refresh_hud)
	GameEvents.score_changed.connect(_on_score)
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.game_won.connect(_on_game_won)
	pause_overlay.visible = false
	_configure_mode_hud()
	controller.start_game(start_mode)
	_refresh_hud()


func _exit_tree() -> void:
	if GameEvents.score_changed.is_connected(_on_score):
		GameEvents.score_changed.disconnect(_on_score)
	if GameEvents.game_over.is_connected(_on_game_over):
		GameEvents.game_over.disconnect(_on_game_over)
	if GameEvents.game_won.is_connected(_on_game_won):
		GameEvents.game_won.disconnect(_on_game_won)


func _configure_mode_hud() -> void:
	timer_box.visible = start_mode != null and start_mode.win_on_target
	lines_title.text = "LINES"


func _on_state_changed(state: GameController.State) -> void:
	pause_overlay.visible = state == GameController.State.PAUSED
	if state == GameController.State.PAUSED:
		pause_label.text = "PAUSED"


func _on_score(score: int, lines: int, level: int) -> void:
	score_label.text = "%06d" % score
	level_label.text = "%02d" % level
	_update_lines_label(lines)
	_pulse_hud_value(score_label)
	_pulse_hud_value(lines_label)


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
		timer_label.text = _format_time(controller.engine.elapsed_sec)


func _update_lines_label(lines: int) -> void:
	if start_mode != null and start_mode.win_on_target and start_mode.target_lines > 0:
		lines_label.text = "%d/%d" % [lines, start_mode.target_lines]
	else:
		lines_label.text = "%03d" % lines


func _format_time(sec: float) -> String:
	var total_ms := int(sec * 1000.0)
	var minutes := total_ms / 60000
	var seconds := (total_ms % 60000) / 1000
	var millis := (total_ms % 1000) / 10
	return "%d:%02d.%02d" % [minutes, seconds, millis]


func _on_game_over(final_score: int) -> void:
	_emit_game_ended(final_score, false, -1.0)


func _on_game_won(final_score: int, elapsed_sec: float) -> void:
	_emit_game_ended(final_score, true, elapsed_sec)


func _emit_game_ended(final_score: int, is_win: bool, elapsed_override: float) -> void:
	# End states hand off to Main for a screen swap; never quit the tree.
	if not is_inside_tree() or controller == null or controller.engine == null:
		return
	var s := controller.engine.score
	var elapsed := elapsed_override if elapsed_override >= 0.0 else controller.engine.elapsed_sec
	game_ended.emit(final_score, s.lines, s.level, is_win, elapsed)


func _unhandled_input(event: InputEvent) -> void:
	if controller == null:
		return
	if controller.state == GameController.State.PAUSED and event.is_action_pressed("ui_confirm"):
		exit_to_title.emit()
		get_viewport().set_input_as_handled()
