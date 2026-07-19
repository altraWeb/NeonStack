extends Node
## Autoload settings — DAS/ARR feel, ghost, volumes.

const PATH := "user://settings.cfg"

const DAS_MIN := 0.0
const DAS_MAX := 300.0
const ARR_MIN := 1.0
const ARR_MAX := 100.0
const SOFT_ARR_MIN := 10.0
const SOFT_ARR_MAX := 100.0
const LOCK_MIN := 100.0
const LOCK_MAX := 1000.0

const DEFAULT_DAS_MS := 167.0
const DEFAULT_ARR_MS := 33.0
const DEFAULT_SOFT_DROP_ARR_MS := 50.0
const DEFAULT_LOCK_DELAY_MS := 500.0

var master_volume: float = 0.85
var sfx_volume: float = 0.9
var music_volume: float = 0.65
var show_ghost: bool = true
var das_ms: float = DEFAULT_DAS_MS
var arr_ms: float = DEFAULT_ARR_MS
var soft_drop_arr_ms: float = DEFAULT_SOFT_DROP_ARR_MS
var lock_delay_ms: float = DEFAULT_LOCK_DELAY_MS

var _path: String = PATH


func _ready() -> void:
	load_settings()
	_apply_volumes()


func set_path_for_test(path: String) -> void:
	_path = path


func get_path_for_test() -> String:
	return _path


func reset_feel_defaults() -> void:
	das_ms = DEFAULT_DAS_MS
	arr_ms = DEFAULT_ARR_MS
	soft_drop_arr_ms = DEFAULT_SOFT_DROP_ARR_MS
	lock_delay_ms = DEFAULT_LOCK_DELAY_MS


func clamp_feel() -> void:
	das_ms = clampf(das_ms, DAS_MIN, DAS_MAX)
	arr_ms = clampf(arr_ms, ARR_MIN, ARR_MAX)
	soft_drop_arr_ms = clampf(soft_drop_arr_ms, SOFT_ARR_MIN, SOFT_ARR_MAX)
	lock_delay_ms = clampf(lock_delay_ms, LOCK_MIN, LOCK_MAX)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_path) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	show_ghost = bool(cfg.get_value("gameplay", "ghost", show_ghost))
	das_ms = float(cfg.get_value("gameplay", "das_ms", das_ms))
	arr_ms = float(cfg.get_value("gameplay", "arr_ms", arr_ms))
	soft_drop_arr_ms = float(cfg.get_value("gameplay", "soft_drop_arr_ms", soft_drop_arr_ms))
	lock_delay_ms = float(cfg.get_value("gameplay", "lock_delay_ms", lock_delay_ms))
	clamp_feel()


func save_settings() -> void:
	clamp_feel()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("gameplay", "ghost", show_ghost)
	cfg.set_value("gameplay", "das_ms", das_ms)
	cfg.set_value("gameplay", "arr_ms", arr_ms)
	cfg.set_value("gameplay", "soft_drop_arr_ms", soft_drop_arr_ms)
	cfg.set_value("gameplay", "lock_delay_ms", lock_delay_ms)
	cfg.save(_path)
	_apply_volumes()


func _apply_volumes() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
