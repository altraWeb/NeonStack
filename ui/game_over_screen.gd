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

## Created eagerly — show_result() can run before _ready() after add_child.
var _store: LocalHighscoreStore = LocalHighscoreStore.new()
var _score: int = 0
var _lines: int = 0
var _level: int = 1
var _elapsed_sec: float = 0.0
var _is_win: bool = false
var _timed_out: bool = false
var _mode: GameMode = GameMode.standard_marathon()
var _submitted: bool = false
var _can_log: bool = false


func _ready() -> void:
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
	mode: GameMode = null,
	timed_out: bool = false
) -> void:
	_score = score
	_lines = lines
	_level = level
	_elapsed_sec = elapsed_sec
	_is_win = is_win
	_timed_out = timed_out
	_mode = mode if mode != null else GameMode.standard_marathon()
	_submitted = false
	_can_log = false

	var sprint := _mode.win_on_target
	var ultra := _mode.has_time_limit()

	if is_win and sprint:
		title_label.text = "PROTOCOL COMPLETE"
		title_label.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 1.0))
		score_label.text = _format_time(elapsed_sec)
		detail_label.text = "SPRINT CLEAR  ·  %d/%d  ·  SCORE %06d" % [lines, _mode.target_lines, score]
		again_btn.text = "RE-RUN SPRINT"
		_can_log = _store.is_sprint_highscore(elapsed_sec)
		status_label.text = "Personal best — press LOG TIME" if _can_log else "Grid purged · time locked"
		submit_btn.text = "LOG TIME"
	elif sprint:
		title_label.text = "TOP OUT"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.65, 1.0))
		score_label.text = _format_time(elapsed_sec)
		detail_label.text = "SPRINT  ·  %d/%d  ·  incomplete" % [lines, _mode.target_lines]
		again_btn.text = "RE-RUN SPRINT"
		_can_log = false
		status_label.text = "No PB — finish 40 lines to log time"
		submit_btn.text = "LOG TIME"
	elif ultra and timed_out:
		title_label.text = "SIGNAL WINDOW CLOSED"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 1.0))
		score_label.text = "%06d" % score
		detail_label.text = "ULTRA · %ds · LINES %03d · L%02d" % [int(_mode.duration_sec), lines, level]
		again_btn.text = "RE-RUN ULTRA"
		_can_log = _store.is_ultra_highscore(score)
		status_label.text = "NEW STREET RECORD — LOG SCORE" if _can_log else "Window sealed · transmission complete"
		submit_btn.text = "LOG SCORE"
	elif ultra:
		title_label.text = "GRID BREACH"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.65, 1.0))
		score_label.text = "%06d" % score
		detail_label.text = "ULTRA · aborted · LINES %03d · L%02d" % [lines, level]
		again_btn.text = "RE-RUN ULTRA"
		_can_log = _store.is_ultra_highscore(score)
		status_label.text = "NEW STREET RECORD — LOG SCORE" if _can_log else "Breach logged · transmission complete"
		submit_btn.text = "LOG SCORE"
	else:
		title_label.text = "TOP OUT"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.65, 1.0))
		score_label.text = "%06d" % score
		detail_label.text = "MARATHON  ·  LINES %03d  ·  LEVEL %02d" % [lines, level]
		again_btn.text = "RELAUNCH"
		_can_log = _store.is_marathon_highscore(score)
		status_label.text = "Highscore — press LOG SCORE" if _can_log else "Transmission complete"
		submit_btn.text = "LOG SCORE"

	name_edit.text = "PILOT"
	if _can_log:
		_persist_entry()
		_submitted = false
		status_label.text = "Saved as PILOT — edit name & LOG to add another"
	submit_btn.disabled = not _can_log
	name_edit.editable = _can_log
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
	if not _can_log:
		return
	if _mode.win_on_target and (not _is_win or _elapsed_sec <= 0.0):
		return
	if not _mode.win_on_target and _score <= 0:
		return
	_persist_entry()
	_submitted = true
	submit_btn.disabled = true
	name_edit.editable = false
	status_label.text = "Logged to Street Log"


func _persist_entry() -> void:
	if _mode.win_on_target:
		_store.submit_sprint(name_edit.text, _score, _lines, _level, _elapsed_sec)
	elif _mode.has_time_limit():
		_store.submit_ultra(name_edit.text, _score, _lines, _level, _elapsed_sec)
	else:
		_store.submit_marathon(name_edit.text, _score, _lines, _level)
