extends Node
## Autoload settings — DAS/ARR feel, ghost, volumes.

const PATH := "user://settings.cfg"

var master_volume: float = 0.85
var sfx_volume: float = 0.9
var music_volume: float = 0.65
var show_ghost: bool = true
var das_ms: float = 167.0
var arr_ms: float = 33.0
var soft_drop_arr_ms: float = 50.0
var lock_delay_ms: float = 500.0


func _ready() -> void:
	load_settings()
	_apply_volumes()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	show_ghost = bool(cfg.get_value("gameplay", "ghost", show_ghost))
	das_ms = float(cfg.get_value("gameplay", "das_ms", das_ms))
	arr_ms = float(cfg.get_value("gameplay", "arr_ms", arr_ms))
	soft_drop_arr_ms = float(cfg.get_value("gameplay", "soft_drop_arr_ms", soft_drop_arr_ms))
	lock_delay_ms = float(cfg.get_value("gameplay", "lock_delay_ms", lock_delay_ms))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("gameplay", "ghost", show_ghost)
	cfg.set_value("gameplay", "das_ms", das_ms)
	cfg.set_value("gameplay", "arr_ms", arr_ms)
	cfg.set_value("gameplay", "soft_drop_arr_ms", soft_drop_arr_ms)
	cfg.set_value("gameplay", "lock_delay_ms", lock_delay_ms)
	cfg.save(PATH)
	_apply_volumes()


func _apply_volumes() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
