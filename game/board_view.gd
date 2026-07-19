class_name BoardView
extends Control

@export var cell_size: float = 28.0

var controller: GameController
var theme_pack: ThemePack
var flash_rows: Array = []
var flash_t: float = 0.0
var lock_pulse: float = 0.0
var clear_burst: float = 0.0
var tetris_kick: float = 0.0
var shake: float = 0.0

var _shards: Array = []


func setup(game_controller: GameController) -> void:
	controller = game_controller
	theme_pack = controller.theme
	GameEvents.lines_cleared.connect(_on_lines_cleared)
	GameEvents.piece_locked.connect(_on_locked)
	GameEvents.hard_dropped.connect(_on_hard_dropped)
	queue_redraw()


func _exit_tree() -> void:
	if GameEvents.lines_cleared.is_connected(_on_lines_cleared):
		GameEvents.lines_cleared.disconnect(_on_lines_cleared)
	if GameEvents.piece_locked.is_connected(_on_locked):
		GameEvents.piece_locked.disconnect(_on_locked)
	if GameEvents.hard_dropped.is_connected(_on_hard_dropped):
		GameEvents.hard_dropped.disconnect(_on_hard_dropped)


func _on_hard_dropped(_distance: int) -> void:
	lock_pulse = 1.0


func _process(delta: float) -> void:
	if flash_t > 0.0:
		flash_t = maxf(0.0, flash_t - delta * 3.0)
	if lock_pulse > 0.0:
		lock_pulse = maxf(0.0, lock_pulse - delta * 3.5)
	if clear_burst > 0.0:
		clear_burst = maxf(0.0, clear_burst - delta * 2.0)
	if tetris_kick > 0.0:
		tetris_kick = maxf(0.0, tetris_kick - delta * 1.45)
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 4.5)

	var alive: Array = []
	for shard in _shards:
		shard.life -= delta
		shard.pos += shard.vel * delta
		shard.vel.y += 480.0 * delta
		shard.vel *= 0.982
		shard.spin += shard.spin_rate * delta
		if shard.life > 0.0:
			alive.append(shard)
	_shards = alive
	queue_redraw()


func _on_lines_cleared(rows: Array, count: int) -> void:
	flash_rows = rows.duplicate()
	flash_t = 1.0
	clear_burst = 1.0
	if count >= 4:
		tetris_kick = 1.0
		shake = 1.0
	elif count >= 2:
		shake = 0.35
	_spawn_shards(rows, count)


func _on_locked(_id: int, _cells: Array) -> void:
	lock_pulse = 0.85


func _spawn_shards(rows: Array, count: int) -> void:
	var origin := _board_origin()
	var board_w := BoardEngine.COLS * cell_size
	for row in rows:
		var ry: int = int(row) - BoardEngine.HIDDEN_ROWS
		if ry < 0 or ry >= BoardEngine.VISIBLE_ROWS:
			continue
		var n := 14 + count * 6
		for i in n:
			var hot := theme_pack.accent_hot
			var amber := theme_pack.accent_amber
			var cyan := theme_pack.bezel_color
			var pick := i % 3
			var col: Color = hot if pick == 0 else (amber if pick == 1 or count >= 4 else cyan)
			var shard := {
				"pos": Vector2(
					origin.x + randf() * board_w,
					origin.y + ry * cell_size + cell_size * 0.5
				),
				"vel": Vector2(randf_range(-280.0, 280.0), randf_range(-360.0, -60.0)),
				"life": randf_range(0.4, 1.05),
				"max_life": 1.05,
				"color": col,
				"size": randf_range(2.0, 6.5),
				"spin": randf() * TAU,
				"spin_rate": randf_range(-10.0, 10.0),
			}
			shard.max_life = shard.life
			_shards.append(shard)


func _draw() -> void:
	if controller == null or controller.engine == null:
		return

	var engine := controller.engine
	var origin := _board_origin()
	if shake > 0.0:
		origin += Vector2(
			sin(Time.get_ticks_msec() * 0.08) * shake * 5.0,
			cos(Time.get_ticks_msec() * 0.11) * shake * 3.0
		)
	var board_w := BoardEngine.COLS * cell_size
	var board_h := BoardEngine.VISIBLE_ROWS * cell_size
	var phase := Time.get_ticks_msec() * 0.001

	# Outer neon halo
	var halo := Rect2(origin - Vector2(18, 18), Vector2(board_w + 36, board_h + 36))
	var halo_col := theme_pack.glow_outer
	halo_col.a = 0.12 + lock_pulse * 0.2 + tetris_kick * 0.35
	draw_rect(halo, halo_col, true)
	if tetris_kick > 0.0:
		var amber_halo := theme_pack.accent_amber
		amber_halo.a = tetris_kick * 0.18
		draw_rect(halo.grow(6.0 * tetris_kick), amber_halo, true)

	# Chrome / neon bezel
	var bezel := Rect2(origin - Vector2(10, 10), Vector2(board_w + 20, board_h + 20))
	draw_rect(bezel, Color(0.08, 0.02, 0.12, 0.75), true)
	var edge_a := 0.55 + 0.35 * sin(phase * 3.0) + lock_pulse * 0.4
	var cyan := Color(theme_pack.bezel_color.r, theme_pack.bezel_color.g, theme_pack.bezel_color.b, edge_a)
	var mag := Color(theme_pack.accent_hot.r, theme_pack.accent_hot.g, theme_pack.accent_hot.b, edge_a * 0.85)
	draw_rect(bezel.grow(2.0), mag, false, 2.0)
	draw_rect(bezel, cyan, false, 2.0 + lock_pulse * 2.5 + tetris_kick * 2.0)

	# Corner ticks
	var corners := [
		bezel.position,
		Vector2(bezel.end.x, bezel.position.y),
		Vector2(bezel.position.x, bezel.end.y),
		bezel.end,
	]
	for c in corners:
		draw_circle(c, 3.0 + tetris_kick * 2.0, theme_pack.accent_hot if tetris_kick < 0.5 else theme_pack.accent_amber)

	# Inner playfield
	draw_rect(Rect2(origin, Vector2(board_w, board_h)), Color(0.06, 0.02, 0.1, 0.72), true)

	# Animated micro-grid
	var grid_a := theme_pack.grid_color
	for x in BoardEngine.COLS + 1:
		var px := origin.x + x * cell_size
		var a := grid_a.a * (0.55 + 0.45 * sin(phase * 2.0 + x * 0.5))
		draw_line(Vector2(px, origin.y), Vector2(px, origin.y + board_h), Color(grid_a.r, grid_a.g, grid_a.b, a), 1.0)
	for y in BoardEngine.VISIBLE_ROWS + 1:
		var py := origin.y + y * cell_size
		var a2 := grid_a.a * (0.45 + 0.55 * sin(phase * 1.6 + y * 0.4))
		var row_col := Color(0.15, 0.85, 1.0, a2 * 0.7) if int(y) % 2 == 0 else Color(grid_a.r, grid_a.g, grid_a.b, a2)
		draw_line(Vector2(origin.x, py), Vector2(origin.x + board_w, py), row_col, 1.0)

	# Locked cells
	for y in range(BoardEngine.HIDDEN_ROWS, BoardEngine.ROWS):
		for x in range(BoardEngine.COLS):
			var value: int = engine.grid[y][x]
			if value == 0:
				continue
			var vy := y - BoardEngine.HIDDEN_ROWS
			var color := theme_pack.color_for_cell(value)
			_draw_block(origin + Vector2(x, vy) * cell_size, color)

	# Ghost
	if SettingsService.show_ghost and controller.mode.enable_ghost and engine.active:
		for cell: Vector2i in engine.ghost_cells():
			if cell.y < BoardEngine.HIDDEN_ROWS:
				continue
			var gpos := origin + Vector2(cell.x, cell.y - BoardEngine.HIDDEN_ROWS) * cell_size
			var gc := theme_pack.ghost_color
			draw_rect(Rect2(gpos + Vector2(3, 3), Vector2(cell_size - 6, cell_size - 6)), gc, false, 2.0)

	# Active piece
	if engine.active:
		var col := theme_pack.color_for_piece(engine.active.id)
		for cell: Vector2i in engine.active.cells():
			if cell.y < BoardEngine.HIDDEN_ROWS:
				continue
			_draw_block(origin + Vector2(cell.x, cell.y - BoardEngine.HIDDEN_ROWS) * cell_size, col, true)

	# Line clear flash + digital shred
	if flash_t > 0.0:
		for row in flash_rows:
			var ry: int = int(row) - BoardEngine.HIDDEN_ROWS
			if ry < 0 or ry >= BoardEngine.VISIBLE_ROWS:
				continue
			var flash_col := theme_pack.accent_amber if tetris_kick > 0.0 else theme_pack.accent_hot
			flash_col.a = flash_t * 0.92
			draw_rect(Rect2(origin + Vector2(0, ry * cell_size), Vector2(board_w, cell_size)), flash_col, true)
			# RGB shred slices
			for i in 12:
				var sx := origin.x + board_w * (i / 11.0)
				var sy := origin.y + ry * cell_size + cell_size * 0.5
				var spread := 42.0 * clear_burst
				var jitter := sin(phase * 55.0 + i * 1.7) * 4.0
				draw_line(
					Vector2(sx - spread, sy + jitter),
					Vector2(sx + spread, sy - jitter * 0.5),
					Color(1, 1, 1, flash_t * 0.85),
					2.0
				)
				if tetris_kick > 0.0:
					draw_line(
						Vector2(sx - spread * 0.6, sy + 2.0),
						Vector2(sx + spread * 0.6, sy + 2.0),
						Color(0.15, 0.95, 1.0, flash_t * 0.55),
						1.0
					)

	# Particle shards
	for shard in _shards:
		var a: float = clampf(shard.life / shard.max_life, 0.0, 1.0)
		var c: Color = shard.color
		c.a = a
		var half: float = shard.size * 0.5
		var p: Vector2 = shard.pos
		var ang: float = shard.spin
		var tip: Vector2 = Vector2(cos(ang), sin(ang)) * shard.size
		draw_rect(Rect2(p, Vector2(shard.size, shard.size * 0.55)), c, true)
		draw_line(p + Vector2(half, half * 0.5), p + tip, Color(1, 1, 1, a * 0.5), 1.0)

	# Tetris chromatic fringe + danger bars + shock rings
	if tetris_kick > 0.0:
		var fringe := Color(theme_pack.accent_amber.r, theme_pack.accent_amber.g, theme_pack.accent_amber.b, tetris_kick * 0.5)
		draw_rect(Rect2(origin + Vector2(-5, -5), Vector2(board_w + 10, board_h + 10)), fringe, false, 4.0)
		var mag_fringe := Color(theme_pack.accent_hot.r, theme_pack.accent_hot.g, theme_pack.accent_hot.b, tetris_kick * 0.4)
		draw_rect(Rect2(origin + Vector2(-8, 0), Vector2(board_w + 16, board_h)), mag_fringe, false, 2.0)
		var cyan_fringe := Color(theme_pack.bezel_color.r, theme_pack.bezel_color.g, theme_pack.bezel_color.b, tetris_kick * 0.35)
		draw_rect(Rect2(origin + Vector2(4, -8), Vector2(board_w - 8, board_h + 16)), cyan_fringe, false, 1.5)

		var cx := origin.x + board_w * 0.5
		var cy := origin.y + board_h * 0.5
		for ring_i in 3:
			var radius := (40.0 + ring_i * 28.0) * (1.15 - tetris_kick) + 20.0
			var rc := theme_pack.accent_amber if ring_i % 2 == 0 else theme_pack.bezel_color
			rc.a = tetris_kick * (0.35 - ring_i * 0.08)
			draw_arc(Vector2(cx, cy), radius, 0.0, TAU, 48, rc, 2.0)

		# Horizontal glitch bars
		for i in 5:
			var by := origin.y + board_h * (0.15 + i * 0.16)
			var ba := tetris_kick * (0.2 + 0.1 * sin(phase * 30.0 + i))
			draw_rect(
				Rect2(origin.x - 12.0, by, board_w + 24.0, 2.0 + i % 2),
				Color(1.0, 0.2, 0.7, ba),
				true
			)


func _board_origin() -> Vector2:
	var board_w := BoardEngine.COLS * cell_size
	var board_h := BoardEngine.VISIBLE_ROWS * cell_size
	return size * 0.5 - Vector2(board_w, board_h) * 0.5


func _draw_block(pos: Vector2, color: Color, active: bool = false) -> void:
	var pad := 1.2
	var rect := Rect2(pos + Vector2(pad, pad), Vector2(cell_size - pad * 2, cell_size - pad * 2))

	# Soft outer glow
	var glow := color
	glow.a = 0.22 if active else 0.14
	draw_rect(rect.grow(3.0), glow, true)

	var edge := color.darkened(0.35)
	var core := color.lightened(0.2)
	draw_rect(rect, Color(edge.r, edge.g, edge.b, 0.95), true)
	draw_rect(rect.grow(-2.5), Color(core.r, core.g, core.b, 0.98), true)

	# Neon rim
	draw_rect(rect, Color(color.r, color.g, color.b, 0.95), false, 1.4)
	# Specular slash
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x * 0.4, 2.5)), Color(1, 1, 1, 0.45), true)
	if active:
		draw_rect(rect.grow(1.0), Color(1, 1, 1, 0.2 + 0.15 * sin(Time.get_ticks_msec() * 0.02)), false, 1.0)
