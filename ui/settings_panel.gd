extends VBoxContainer
## Compact cyberpunk settings cluster for pause / title.

signal changed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var ghost_check: CheckButton = %GhostCheck
@onready var das_slider: HSlider = %DasSlider
@onready var arr_slider: HSlider = %ArrSlider
@onready var soft_slider: HSlider = %SoftSlider
@onready var lock_slider: HSlider = %LockSlider
@onready var das_value: Label = %DasValue
@onready var arr_value: Label = %ArrValue
@onready var soft_value: Label = %SoftValue
@onready var lock_value: Label = %LockValue
@onready var reset_btn: Button = %ResetFeelButton


func _ready() -> void:
	_configure_audio_sliders()
	_configure_feel_sliders()
	_load_into_controls()
	music_slider.value_changed.connect(_on_music)
	sfx_slider.value_changed.connect(_on_sfx)
	ghost_check.toggled.connect(_on_ghost)
	das_slider.value_changed.connect(_on_das)
	arr_slider.value_changed.connect(_on_arr)
	soft_slider.value_changed.connect(_on_soft)
	lock_slider.value_changed.connect(_on_lock)
	reset_btn.pressed.connect(_on_reset_feel)
	_style_reset_button()


func _configure_audio_sliders() -> void:
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05


func _configure_feel_sliders() -> void:
	das_slider.min_value = SettingsService.DAS_MIN
	das_slider.max_value = SettingsService.DAS_MAX
	das_slider.step = 1.0
	arr_slider.min_value = SettingsService.ARR_MIN
	arr_slider.max_value = SettingsService.ARR_MAX
	arr_slider.step = 1.0
	soft_slider.min_value = SettingsService.SOFT_ARR_MIN
	soft_slider.max_value = SettingsService.SOFT_ARR_MAX
	soft_slider.step = 1.0
	lock_slider.min_value = SettingsService.LOCK_MIN
	lock_slider.max_value = SettingsService.LOCK_MAX
	lock_slider.step = 10.0


func _style_reset_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.75, 0.4, 0.08, 0.9)
	normal.set_corner_radius_all(2)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(1.0, 0.85, 0.25, 0.95)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.75, 0.2, 0.95)
	reset_btn.add_theme_stylebox_override("normal", normal)
	reset_btn.add_theme_stylebox_override("hover", hover)
	reset_btn.add_theme_stylebox_override("pressed", hover)
	reset_btn.add_theme_color_override("font_color", Color(0.08, 0.04, 0.02, 1))


func _load_into_controls() -> void:
	music_slider.value = SettingsService.music_volume
	sfx_slider.value = SettingsService.sfx_volume
	ghost_check.button_pressed = SettingsService.show_ghost
	das_slider.value = SettingsService.das_ms
	arr_slider.value = SettingsService.arr_ms
	soft_slider.value = SettingsService.soft_drop_arr_ms
	lock_slider.value = SettingsService.lock_delay_ms
	_refresh_feel_labels()


func _refresh_feel_labels() -> void:
	das_value.text = "%d" % int(round(SettingsService.das_ms))
	arr_value.text = "%d" % int(round(SettingsService.arr_ms))
	soft_value.text = "%d" % int(round(SettingsService.soft_drop_arr_ms))
	lock_value.text = "%d" % int(round(SettingsService.lock_delay_ms))


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


func _on_das(v: float) -> void:
	SettingsService.das_ms = v
	SettingsService.save_settings()
	_refresh_feel_labels()
	_pulse_value(das_value)
	changed.emit()


func _on_arr(v: float) -> void:
	SettingsService.arr_ms = v
	SettingsService.save_settings()
	_refresh_feel_labels()
	_pulse_value(arr_value)
	changed.emit()


func _on_soft(v: float) -> void:
	SettingsService.soft_drop_arr_ms = v
	SettingsService.save_settings()
	_refresh_feel_labels()
	_pulse_value(soft_value)
	changed.emit()


func _on_lock(v: float) -> void:
	SettingsService.lock_delay_ms = v
	SettingsService.save_settings()
	_refresh_feel_labels()
	_pulse_value(lock_value)
	changed.emit()


func _on_reset_feel() -> void:
	SettingsService.reset_feel_defaults()
	SettingsService.save_settings()
	das_slider.value = SettingsService.das_ms
	arr_slider.value = SettingsService.arr_ms
	soft_slider.value = SettingsService.soft_drop_arr_ms
	lock_slider.value = SettingsService.lock_delay_ms
	_refresh_feel_labels()
	_pulse_value(das_value)
	_pulse_value(arr_value)
	_pulse_value(soft_value)
	_pulse_value(lock_value)
	changed.emit()


func _pulse_value(label: Label) -> void:
	label.modulate = Color(0.2, 1.0, 1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(label, "modulate", Color(1, 0.85, 0.35, 0.95), 0.28)
