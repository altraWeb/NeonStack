class_name LocalHighscoreStore
extends HighscoreStore

const PATH := "user://highscores.json"
const MAX_ENTRIES := 20

var _entries: Array = []


func _init() -> void:
	_load()


func get_top(limit: int = 10) -> Array:
	var result: Array = []
	for i in range(mini(limit, _entries.size())):
		result.append(_entries[i])
	return result


func submit(name: String, score: int, lines: int, level: int) -> void:
	var entry := {
		"name": name.substr(0, 12) if name.length() > 0 else "PILOT",
		"score": score,
		"lines": lines,
		"level": level,
		"at": Time.get_datetime_string_from_system(),
	}
	_entries.append(entry)
	_entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if _entries.size() > MAX_ENTRIES:
		_entries.resize(MAX_ENTRIES)
	_save()


func is_highscore(score: int) -> bool:
	if score <= 0:
		return false
	if _entries.size() < MAX_ENTRIES:
		return true
	return score > int(_entries[_entries.size() - 1]["score"])


func _load() -> void:
	_entries.clear()
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Array:
		_entries = data


func _save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_entries, "\t"))
