class_name HighscoreStore
extends RefCounted
## Interface seam for local / future online leaderboards.


func get_top(limit: int = 10) -> Array:
	return []


func submit(name: String, score: int, lines: int, level: int) -> void:
	pass


func is_highscore(score: int) -> bool:
	return score > 0
