class_name DockPanel
extends Control
## Draws hold / next previews; assign mode from play scene.

enum Mode { HOLD, NEXT }

var mode: Mode = Mode.HOLD
var controller: GameController


func setup(game_controller: GameController, panel_mode: Mode) -> void:
	controller = game_controller
	mode = panel_mode
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if controller == null or controller.theme == null:
		return
	var theme := controller.theme
	var phase := Time.get_ticks_msec() * 0.001
	var pulse := 0.55 + 0.45 * sin(phase * 2.4)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.02, 0.12, 0.7), true)

	# Inner scan wash
	for y in range(0, int(size.y), 3):
		var a := 0.03 + 0.02 * sin(phase * 6.0 + y * 0.15)
		draw_line(Vector2(2, y), Vector2(size.x - 2, y), Color(0.2, 0.7, 1.0, a), 1.0)

	var border := theme.bezel_color
	border.a = 0.55 + 0.25 * pulse
	draw_rect(Rect2(Vector2.ZERO, size), border, false, 1.5)
	var hot := theme.accent_hot
	hot.a = 0.25 + 0.2 * pulse
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), hot, false, 1.0)

	# Corner brackets
	var tick := 8.0
	var amber := theme.accent_amber
	amber.a = 0.5 + 0.4 * pulse
	var corners := [
		[Vector2(0, 0), Vector2(tick, 0), Vector2(0, tick)],
		[Vector2(size.x, 0), Vector2(size.x - tick, 0), Vector2(size.x, tick)],
		[Vector2(0, size.y), Vector2(tick, size.y), Vector2(0, size.y - tick)],
		[Vector2(size.x, size.y), Vector2(size.x - tick, size.y), Vector2(size.x, size.y - tick)],
	]
	for c in corners:
		draw_line(c[0], c[1], amber, 1.5)
		draw_line(c[0], c[2], amber, 1.5)

	if mode == Mode.HOLD:
		_draw_hold(theme)
	else:
		_draw_next(theme)


func _draw_hold(theme: ThemePack) -> void:
	if controller.engine.hold_id < 0:
		return
	var id := controller.engine.hold_id as PieceType.Id
	var color := theme.color_for_piece(id)
	if controller.engine.hold_used:
		color.a = 0.35
	_draw_piece(id, color, Vector2(22, 36), 16.0)


func _draw_next(theme: ThemePack) -> void:
	var preview := controller.engine.peek_next(5)
	var mini := 14.0
	for i in preview.size():
		var id: PieceType.Id = preview[i]
		var color := theme.color_for_piece(id)
		color.a = 1.0 - i * 0.12
		_draw_piece(id, color, Vector2(18, 24 + i * 52), mini)


func _draw_piece(id: PieceType.Id, color: Color, at: Vector2, mini: float) -> void:
	for cell: Vector2i in PieceType.cells(id)[0]:
		var r := Rect2(at + Vector2(cell) * mini, Vector2(mini - 1, mini - 1))
		var glow := color
		glow.a *= 0.25
		draw_rect(r.grow(1.5), glow, true)
		draw_rect(r, color, true)
