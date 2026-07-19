extends Control

signal start_pressed(mode: GameMode)
signal scores_pressed

@onready var brand: Label = %Brand
@onready var subtitle: Label = %Subtitle
@onready var marathon_btn: Button = %MarathonButton
@onready var sprint_btn: Button = %SprintButton
@onready var scores_btn: Button = %ScoresButton
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
	scores_btn.pressed.connect(func(): scores_pressed.emit())
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

	var brand_tween := create_tween().set_loops()
	brand_tween.tween_method(_set_brand_color, Color(1.0, 0.22, 0.7), Color(0.15, 0.95, 1.0), 1.4)
	brand_tween.tween_method(_set_brand_color, Color(0.15, 0.95, 1.0), Color(1.0, 0.75, 0.2), 1.1)
	brand_tween.tween_method(_set_brand_color, Color(1.0, 0.75, 0.2), Color(1.0, 0.22, 0.7), 1.3)

	var sub := create_tween().set_loops()
	sub.tween_property(subtitle, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
	sub.tween_property(subtitle, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_glitch_t -= delta
	if _glitch_t <= 0.0:
		_glitch_t = randf_range(1.6, 3.8)
		_do_brand_glitch()

	if _breath_ready:
		var breath := 1.0 + sin(Time.get_ticks_msec() * 0.0022) * 0.014
		brand_stack.scale = Vector2(breath, breath)


func _do_brand_glitch() -> void:
	# Offset inner labels — BrandStack sits in a VBox so its position is owned by layout
	var ox := randf_range(-7.0, 7.0)
	var oy := randf_range(-3.0, 3.0)
	brand.position = Vector2(ox, oy)
	brand_ghost.position = Vector2(-ox * 1.1, oy * 0.5)
	var snap := create_tween()
	snap.tween_property(brand, "position", Vector2.ZERO, 0.09).set_trans(Tween.TRANS_CUBIC)
	snap.parallel().tween_property(brand_ghost, "position", Vector2(2, -1), 0.12)


func _set_brand_color(c: Color) -> void:
	brand.add_theme_color_override("font_color", c)
	var ghost := Color(0.15, 0.95, 1.0, 0.45)
	if c.b > c.r:
		ghost = Color(1.0, 0.25, 0.7, 0.4)
	elif c.g > 0.6 and c.r > 0.7:
		ghost = Color(1.0, 0.2, 0.65, 0.35)
	brand_ghost.add_theme_color_override("font_color", ghost)


func _style_buttons() -> void:
	for btn: Button in [marathon_btn, sprint_btn, scores_btn]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(1.0, 0.15, 0.55, 0.88)
		normal.set_corner_radius_all(2)
		normal.border_width_left = 1
		normal.border_width_right = 1
		normal.border_width_top = 1
		normal.border_width_bottom = 1
		normal.border_color = Color(0.2, 0.95, 1.0, 0.9)
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

	# Sprint gets a cooler cyan-leaning idle so modes read as distinct protocols
	var sprint_normal := marathon_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	sprint_normal.bg_color = Color(0.12, 0.55, 0.85, 0.9)
	sprint_normal.border_color = Color(1.0, 0.75, 0.2, 0.95)
	sprint_btn.add_theme_stylebox_override("normal", sprint_normal)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("hard_drop"):
		start_pressed.emit(GameMode.standard_marathon())
		get_viewport().set_input_as_handled()
