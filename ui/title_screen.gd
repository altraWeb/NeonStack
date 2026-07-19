extends Control

signal start_pressed(mode: GameMode)
signal scores_pressed

@onready var brand: Label = %Brand
@onready var subtitle: Label = %Subtitle
@onready var marathon_btn: Button = %MarathonButton
@onready var sprint_btn: Button = %SprintButton
@onready var ultra_btn: Button = %UltraButton
@onready var scores_btn: Button = %ScoresButton
@onready var exit_btn: Button = %ExitButton
@onready var footer: Label = %Footer
@onready var pulse_line: ColorRect = %PulseLine
@onready var pulse_line_amber: ColorRect = %PulseLineAmber
@onready var brand_ghost: Label = %BrandGhost
@onready var brand_stack: Control = $Center/BrandStack

var _glitch_t: float = 0.0
var _breath_ready: bool = false


func _ready() -> void:
	_style_buttons()
	marathon_btn.pressed.connect(func(): start_pressed.emit(GameMode.standard_marathon()))
	sprint_btn.pressed.connect(func(): start_pressed.emit(GameMode.sprint_40()))
	ultra_btn.pressed.connect(func(): start_pressed.emit(GameMode.ultra_180()))
	scores_btn.pressed.connect(func(): scores_pressed.emit())
	exit_btn.pressed.connect(_quit)
	var version := str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
	footer.text = "v%s" % version
	marathon_btn.grab_focus()

	# Pivot at stack center so scale punches from the title core
	await get_tree().process_frame
	if not is_inside_tree():
		return
	brand_stack.pivot_offset = brand_stack.size * 0.5

	brand_stack.scale = Vector2(1.28, 1.28)
	brand.modulate.a = 0.0
	brand_ghost.modulate.a = 0.0
	var intro := create_tween()
	intro.set_parallel(true)
	intro.tween_property(brand_stack, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(brand, "modulate:a", 1.0, 0.28)
	intro.tween_property(brand_ghost, "modulate:a", 0.4, 0.55).set_delay(0.08)
	intro.chain().tween_callback(func(): _breath_ready = true)

	var pulse := create_tween().set_loops()
	pulse.tween_property(pulse_line, "modulate:a", 0.15, 0.75).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(pulse_line, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE)

	var pulse_a := create_tween().set_loops()
	pulse_a.tween_property(pulse_line_amber, "modulate:a", 0.85, 0.55).set_trans(Tween.TRANS_SINE)
	pulse_a.tween_property(pulse_line_amber, "modulate:a", 0.12, 0.9).set_trans(Tween.TRANS_SINE)

	# Slow magenta↔cyan drift — skip the amber rainbow lap.
	var brand_tween := create_tween().set_loops()
	brand_tween.tween_method(_set_brand_color, Color(0.95, 0.28, 0.72), Color(0.25, 0.85, 0.95), 2.8)
	brand_tween.tween_method(_set_brand_color, Color(0.25, 0.85, 0.95), Color(0.95, 0.28, 0.72), 2.8)

	var sub := create_tween().set_loops()
	sub.tween_property(subtitle, "modulate:a", 0.65, 1.8).set_trans(Tween.TRANS_SINE)
	sub.tween_property(subtitle, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_glitch_t -= delta
	if _glitch_t <= 0.0:
		_glitch_t = randf_range(5.5, 11.0)
		_do_brand_glitch()

	if _breath_ready:
		var breath := 1.0 + sin(Time.get_ticks_msec() * 0.0016) * 0.008
		brand_stack.scale = Vector2(breath, breath)


func _do_brand_glitch() -> void:
	# Rare, small nudge — not a constant seizure.
	var ox := randf_range(-3.0, 3.0)
	var oy := randf_range(-1.5, 1.5)
	brand.position = Vector2(ox, oy)
	brand_ghost.position = Vector2(-ox * 0.8, oy * 0.4)
	var snap := create_tween()
	snap.tween_property(brand, "position", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_CUBIC)
	snap.parallel().tween_property(brand_ghost, "position", Vector2(1, -1), 0.14)


func _set_brand_color(c: Color) -> void:
	brand.add_theme_color_override("font_color", c)
	var ghost := Color(0.15, 0.95, 1.0, 0.45)
	if c.b > c.r:
		ghost = Color(1.0, 0.25, 0.7, 0.4)
	elif c.g > 0.6 and c.r > 0.7:
		ghost = Color(1.0, 0.2, 0.65, 0.35)
	brand_ghost.add_theme_color_override("font_color", ghost)


func _quit() -> void:
	get_tree().quit()


func _style_buttons() -> void:
	for btn: Button in [marathon_btn, sprint_btn, ultra_btn, scores_btn, exit_btn]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.72, 0.18, 0.48, 0.9)
		normal.set_corner_radius_all(2)
		normal.border_width_left = 1
		normal.border_width_right = 1
		normal.border_width_top = 1
		normal.border_width_bottom = 1
		normal.border_color = Color(0.45, 0.85, 0.95, 0.75)
		normal.content_margin_left = 16
		normal.content_margin_right = 16
		normal.content_margin_top = 8
		normal.content_margin_bottom = 8
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.15, 0.9, 1.0, 0.95)
		hover.border_color = Color(1.0, 0.75, 0.2, 1.0)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color(1.0, 0.85, 0.15, 0.95)
		pressed.border_color = Color(1.0, 0.2, 0.6, 1.0)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_color_override("font_color", Color(0.05, 0.02, 0.08, 1))
		btn.add_theme_color_override("font_hover_color", Color(0.02, 0.05, 0.08, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.05, 0.02, 1))

	var sprint_normal := marathon_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	sprint_normal.bg_color = Color(0.14, 0.42, 0.62, 0.92)
	sprint_normal.border_color = Color(0.55, 0.8, 0.95, 0.85)
	sprint_btn.add_theme_stylebox_override("normal", sprint_normal)

	var ultra_normal := marathon_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	ultra_normal.bg_color = Color(0.62, 0.38, 0.12, 0.92)
	ultra_normal.border_color = Color(0.95, 0.75, 0.35, 0.9)
	ultra_btn.add_theme_stylebox_override("normal", ultra_normal)

	var exit_normal := marathon_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	exit_normal.bg_color = Color(0.18, 0.14, 0.22, 0.9)
	exit_normal.border_color = Color(0.55, 0.5, 0.6, 0.7)
	exit_btn.add_theme_stylebox_override("normal", exit_normal)
	exit_btn.add_theme_color_override("font_color", Color(0.85, 0.8, 0.9, 1))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("hard_drop"):
		start_pressed.emit(GameMode.standard_marathon())
		get_viewport().set_input_as_handled()
