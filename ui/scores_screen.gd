extends Control

signal back_pressed

@onready var list_label: Label = %List
@onready var back_btn: Button = %BackButton
@onready var marathon_btn: Button = %MarathonButton
@onready var sprint_btn: Button = %SprintButton
@onready var ultra_btn: Button = %UltraButton
@onready var subtitle: Label = %Subtitle

var _mode_id: String = GameMode.standard_marathon().id


func _ready() -> void:
	back_btn.pressed.connect(func(): back_pressed.emit())
	marathon_btn.pressed.connect(func(): _select(GameMode.standard_marathon().id))
	sprint_btn.pressed.connect(func(): _select(GameMode.sprint_40().id))
	ultra_btn.pressed.connect(func(): _select(GameMode.ultra_180().id))
	refresh()


func _select(mode_id: String) -> void:
	_mode_id = mode_id
	refresh()


func refresh() -> void:
	var store := LocalHighscoreStore.new()
	var top := store.get_top(_mode_id, 10)
	var sprint := _mode_id == GameMode.sprint_40().id
	var ultra := _mode_id == GameMode.ultra_180().id

	if sprint:
		subtitle.text = "Sprint — fastest clears"
		subtitle.add_theme_color_override("font_color", Color(0.45, 0.8, 0.95, 0.85))
	elif ultra:
		subtitle.text = "Ultra — best scores in 180s"
		subtitle.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35, 0.9))
	else:
		subtitle.text = "Marathon — highest scores"
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.45, 0.7, 0.8))

	marathon_btn.disabled = _mode_id == GameMode.standard_marathon().id
	sprint_btn.disabled = sprint
	ultra_btn.disabled = ultra

	if top.is_empty():
		list_label.text = "No scores yet."
		back_btn.grab_focus()
		return

	var lines: PackedStringArray = []
	for i in top.size():
		var e: Dictionary = top[i]
		var name := str(e.get("name", "?"))
		if sprint:
			var sec := float(e.get("elapsed_sec", 0.0))
			lines.append("%2d  %-12s  %s" % [i + 1, name, _format_time(sec)])
		else:
			lines.append("%2d  %-12s  %06d  L%02d" % [
				i + 1, name, int(e.get("score", 0)), int(e.get("level", 1))
			])
	list_label.text = "\n".join(lines)
	back_btn.grab_focus()


func _format_time(sec: float) -> String:
	var total_ms := int(sec * 1000.0)
	var minutes := total_ms / 60000
	var seconds := (total_ms % 60000) / 1000
	var millis := (total_ms % 1000) / 10
	return "%d:%02d.%02d" % [minutes, seconds, millis]
