extends Control

signal play_again
signal back_to_title

@onready var title_label: Label = %Title
@onready var score_label: Label = %FinalScore
@onready var detail_label: Label = %Detail
@onready var name_edit: LineEdit = %NameEdit
@onready var submit_btn: Button = %SubmitButton
@onready var again_btn: Button = %AgainButton
@onready var title_btn: Button = %TitleButton
@onready var status_label: Label = %Status

var _store: LocalHighscoreStore
var _score: int = 0
var _lines: int = 0
var _level: int = 1
var _submitted: bool = false


func _ready() -> void:
	_store = LocalHighscoreStore.new()
	submit_btn.pressed.connect(_submit)
	again_btn.pressed.connect(func(): play_again.emit())
	title_btn.pressed.connect(func(): back_to_title.emit())
	name_edit.text_submitted.connect(func(_t): _submit())


func show_result(
	score: int,
	lines: int,
	level: int,
	is_win: bool = false,
	elapsed_sec: float = 0.0,
	mode: GameMode = null
) -> void:
	_score = score
	_lines = lines
	_level = level
	_submitted = false
	score_label.text = "%06d" % score

	if is_win:
		title_label.text = "PROTOCOL COMPLETE"
		title_label.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 1.0))
		var time_txt := _format_time(elapsed_sec)
		var target := mode.target_lines if mode != null and mode.target_lines > 0 else lines
		detail_label.text = "SPRINT CLEAR  ·  %d/%d  ·  %s" % [lines, target, time_txt]
		status_label.text = "Grid purged · time locked"
		again_btn.text = "RE-RUN SPRINT"
	else:
		# Top-out is a normal end state — avoid "CRASH" wording that reads like an engine failure.
		title_label.text = "TOP OUT"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.65, 1.0))
		if mode != null and mode.win_on_target and mode.target_lines > 0:
			var time_txt := _format_time(elapsed_sec)
			detail_label.text = "SPRINT  ·  %d/%d  ·  %s" % [lines, mode.target_lines, time_txt]
			again_btn.text = "RE-RUN SPRINT"
		else:
			detail_label.text = "LINES %03d  ·  LEVEL %02d" % [lines, level]
			again_btn.text = "RELAUNCH"
		status_label.text = "New log entry available" if _store.is_highscore(score) else "Transmission complete"

	var can_log := _store.is_highscore(score)
	if is_win and not can_log:
		status_label.text = "Grid purged · time locked"
	elif is_win and can_log:
		status_label.text = "Personal best uplink ready"

	submit_btn.disabled = not can_log
	name_edit.editable = can_log
	name_edit.text = "PILOT"
	if name_edit.editable:
		name_edit.grab_focus()
		name_edit.select_all()
	else:
		again_btn.grab_focus()


func _format_time(sec: float) -> String:
	var total_ms := int(sec * 1000.0)
	var minutes := total_ms / 60000
	var seconds := (total_ms % 60000) / 1000
	var millis := (total_ms % 1000) / 10
	return "%d:%02d.%02d" % [minutes, seconds, millis]


func _submit() -> void:
	if _submitted or not _store.is_highscore(_score):
		return
	_store.submit(name_edit.text.strip_edges(), _score, _lines, _level)
	_submitted = true
	submit_btn.disabled = true
	name_edit.editable = false
	status_label.text = "Logged to local dock"
