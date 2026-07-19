class_name ScoreState
extends RefCounted

signal changed
signal leveled_up(level: int)

var score: int = 0
var lines: int = 0
var level: int = 1


func reset() -> void:
	score = 0
	lines = 0
	level = 1
	changed.emit()


func add_soft_drop(cells: int) -> void:
	if cells <= 0:
		return
	score += cells
	changed.emit()


func add_hard_drop(cells: int) -> void:
	if cells <= 0:
		return
	score += cells * 2
	changed.emit()


## Classic guideline-ish scoring: n-line clear * 100/300/500/800 * level
func add_line_clear(cleared: int) -> void:
	if cleared <= 0:
		return
	var table := {1: 100, 2: 300, 3: 500, 4: 800}
	score += table.get(cleared, 0) * level
	lines += cleared
	var new_level := mini(15, 1 + int(lines / 10))
	var did_level := new_level > level
	level = new_level
	changed.emit()
	if did_level:
		leveled_up.emit(level)


func gravity_seconds() -> float:
	# Approx guideline curve, capped for playability.
	var frames := pow(0.8 - ((level - 1) * 0.007), level - 1)
	return clampf(frames, 0.05, 1.0)
