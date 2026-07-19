class_name RepeatInput
extends RefCounted
## DAS/ARR-style repeat clock for horizontal move and soft drop.

var das_sec: float
var arr_sec: float

var _active: bool = false
var _charged: bool = false
var _das_timer: float = 0.0
var _arr_timer: float = 0.0


func _init(das_seconds: float = 0.167, arr_seconds: float = 0.033) -> void:
	das_sec = maxf(0.0, das_seconds)
	arr_sec = maxf(0.001, arr_seconds)


func begin(skip_das: bool = false) -> void:
	_active = true
	_charged = skip_das
	_das_timer = 0.0
	_arr_timer = 0.0


func end() -> void:
	_active = false
	_charged = false
	_das_timer = 0.0
	_arr_timer = 0.0


func is_active() -> bool:
	return _active


## Number of repeat steps to apply this frame (initial keypress is caller's job).
func tick(delta: float) -> int:
	if not _active:
		return 0

	var steps := 0
	if not _charged:
		_das_timer += delta
		if _das_timer >= das_sec:
			_charged = true
			_arr_timer = 0.0
			steps = 1
	else:
		_arr_timer += delta
		while _arr_timer >= arr_sec:
			_arr_timer -= arr_sec
			steps += 1
	return steps
