class_name GameMode
extends Resource
## Extensible mode definition — Marathon, Sprint, and Ultra (timed score attack).

@export var id: String = "standard_marathon"
@export var display_name: String = "Marathon"
@export var next_preview_count: int = 5
@export var enable_hold: bool = true
@export var enable_ghost: bool = true
## 0 = no line target (endless).
@export var target_lines: int = 0
@export var win_on_target: bool = false
## 0 = no time limit. Ultra uses a countdown duration in seconds.
@export var duration_sec: float = 0.0


func has_time_limit() -> bool:
	return duration_sec > 0.0


static func standard_marathon() -> GameMode:
	var mode := GameMode.new()
	mode.id = "standard_marathon"
	mode.display_name = "Marathon"
	mode.target_lines = 0
	mode.win_on_target = false
	mode.duration_sec = 0.0
	return mode


static func sprint_40() -> GameMode:
	var mode := GameMode.new()
	mode.id = "sprint_40"
	mode.display_name = "Sprint 40"
	mode.target_lines = 40
	mode.win_on_target = true
	mode.duration_sec = 0.0
	return mode


static func ultra_180() -> GameMode:
	var mode := GameMode.new()
	mode.id = "ultra_180"
	mode.display_name = "Ultra"
	mode.target_lines = 0
	mode.win_on_target = false
	mode.duration_sec = 180.0
	return mode
