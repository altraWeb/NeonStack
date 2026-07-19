extends VBoxContainer
## Compact cyberpunk settings cluster for pause / title.

signal changed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var ghost_check: CheckButton = %GhostCheck


func _ready() -> void:
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	_load_into_controls()
	music_slider.value_changed.connect(_on_music)
	sfx_slider.value_changed.connect(_on_sfx)
	ghost_check.toggled.connect(_on_ghost)


func _load_into_controls() -> void:
	music_slider.value = SettingsService.music_volume
	sfx_slider.value = SettingsService.sfx_volume
	ghost_check.button_pressed = SettingsService.show_ghost


func _on_music(v: float) -> void:
	SettingsService.music_volume = v
	SettingsService.save_settings()
	changed.emit()


func _on_sfx(v: float) -> void:
	SettingsService.sfx_volume = v
	SettingsService.save_settings()
	changed.emit()


func _on_ghost(pressed: bool) -> void:
	SettingsService.show_ghost = pressed
	SettingsService.save_settings()
	changed.emit()
