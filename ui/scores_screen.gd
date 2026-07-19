extends Control

signal back_pressed

@onready var list_label: Label = %List
@onready var back_btn: Button = %BackButton


func _ready() -> void:
	back_btn.pressed.connect(func(): back_pressed.emit())
	refresh()


func refresh() -> void:
	var store := LocalHighscoreStore.new()
	var top := store.get_top(10)
	if top.is_empty():
		list_label.text = "No transmissions logged yet."
		return
	var lines: PackedStringArray = []
	for i in top.size():
		var e: Dictionary = top[i]
		lines.append("%2d  %-12s  %06d  L%02d" % [i + 1, str(e.get("name", "?")), int(e.get("score", 0)), int(e.get("level", 1))])
	list_label.text = "\n".join(lines)
	back_btn.grab_focus()
