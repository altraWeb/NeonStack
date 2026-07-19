class_name LocalHighscoreStore
extends HighscoreStore

const PATH := "user://highscores.json"
const MAX_ENTRIES := 20

var _path: String = PATH
## mode_id -> Array of entry dictionaries
var _boards: Dictionary = {}


func _init(path: String = PATH) -> void:
	_path = path
	_load()
	_migrate_legacy_orbital_if_needed()


func get_top(mode_id: String, limit: int = 10) -> Array:
	var board: Array = _board(mode_id)
	var result: Array = []
	for i in range(mini(limit, board.size())):
		result.append(board[i])
	return result


func submit_marathon(name: String, score: int, lines: int, level: int) -> void:
	if score <= 0:
		return
	var entry := {
		"name": _callsign(name),
		"score": score,
		"lines": lines,
		"level": level,
		"at": Time.get_datetime_string_from_system(),
	}
	var mode_id := GameMode.standard_marathon().id
	var board := _board(mode_id)
	board.append(entry)
	board.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	_trim(board)
	_boards[mode_id] = board
	_save()


func submit_sprint(name: String, score: int, lines: int, level: int, elapsed_sec: float) -> void:
	if elapsed_sec <= 0.0:
		return
	var entry := {
		"name": _callsign(name),
		"score": score,
		"lines": lines,
		"level": level,
		"elapsed_sec": elapsed_sec,
		"at": Time.get_datetime_string_from_system(),
	}
	var mode_id := GameMode.sprint_40().id
	var board := _board(mode_id)
	board.append(entry)
	board.sort_custom(func(a, b): return float(a["elapsed_sec"]) < float(b["elapsed_sec"]))
	_trim(board)
	_boards[mode_id] = board
	_save()


func is_marathon_highscore(score: int) -> bool:
	if score <= 0:
		return false
	var board := _board(GameMode.standard_marathon().id)
	if board.size() < MAX_ENTRIES:
		return true
	return score > int(board[board.size() - 1]["score"])


func is_sprint_highscore(elapsed_sec: float) -> bool:
	if elapsed_sec <= 0.0:
		return false
	var board := _board(GameMode.sprint_40().id)
	if board.size() < MAX_ENTRIES:
		return true
	return elapsed_sec < float(board[board.size() - 1]["elapsed_sec"])


func submit_ultra(name: String, score: int, lines: int, level: int, elapsed_sec: float) -> void:
	if score <= 0:
		return
	var entry := {
		"name": _callsign(name),
		"score": score,
		"lines": lines,
		"level": level,
		"elapsed_sec": elapsed_sec,
		"at": Time.get_datetime_string_from_system(),
	}
	var mode_id := GameMode.ultra_180().id
	var board := _board(mode_id)
	board.append(entry)
	board.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	_trim(board)
	_boards[mode_id] = board
	_save()


func is_ultra_highscore(score: int) -> bool:
	if score <= 0:
		return false
	var board := _board(GameMode.ultra_180().id)
	if board.size() < MAX_ENTRIES:
		return true
	return score > int(board[board.size() - 1]["score"])


func submit(name: String, score: int, lines: int, level: int) -> void:
	submit_marathon(name, score, lines, level)


func is_highscore(score: int) -> bool:
	return is_marathon_highscore(score)


func _callsign(name: String) -> String:
	var trimmed := name.strip_edges()
	if trimmed.is_empty():
		return "AAA"
	return trimmed.substr(0, 12)


func _board(mode_id: String) -> Array:
	if not _boards.has(mode_id):
		_boards[mode_id] = []
	return (_boards[mode_id] as Array).duplicate(true)


func _trim(board: Array) -> void:
	if board.size() > MAX_ENTRIES:
		board.resize(MAX_ENTRIES)


func _load() -> void:
	_boards.clear()
	if not FileAccess.file_exists(_path):
		return
	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		return
	_ingest_json_text(file.get_as_text())


func _ingest_json_text(text: String) -> void:
	var data = JSON.parse_string(text)
	if data is Array:
		_boards[GameMode.standard_marathon().id] = data
	elif data is Dictionary:
		for key in data.keys():
			var value = data[key]
			if value is Array:
				_boards[str(key)] = value


func _migrate_legacy_orbital_if_needed() -> void:
	# Project renamed Orbital Dock → Neon Stack; import old flat list once.
	if _path != PATH:
		return
	var marathon_id := GameMode.standard_marathon().id
	if _board(marathon_id).size() > 0:
		return
	var legacy := OS.get_user_data_dir().path_join("../Orbital Dock/highscores.json").simplify_path()
	if not FileAccess.file_exists(legacy):
		return
	var file := FileAccess.open(legacy, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var before := _board(marathon_id).size()
	_ingest_json_text(text)
	if _board(marathon_id).size() > before:
		_save()


func _save() -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		push_error("LocalHighscoreStore: failed to open %s for write" % _path)
		return
	file.store_string(JSON.stringify(_boards, "\t"))
	file.flush()
	file.close()
