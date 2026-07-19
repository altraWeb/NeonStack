class_name HighscoreStore
extends RefCounted
## Interface seam for local / future online leaderboards (mode-keyed).


func get_top(_mode_id: String, _limit: int = 10) -> Array:
	return []


func submit_marathon(_name: String, _score: int, _lines: int, _level: int) -> void:
	pass


func submit_sprint(_name: String, _score: int, _lines: int, _level: int, _elapsed_sec: float) -> void:
	pass


func is_marathon_highscore(_score: int) -> bool:
	return _score > 0


func is_sprint_highscore(_elapsed_sec: float) -> bool:
	return _elapsed_sec > 0.0
