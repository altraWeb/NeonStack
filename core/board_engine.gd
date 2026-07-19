class_name BoardEngine
extends RefCounted

signal started
signal piece_spawned(piece_id: int)
signal piece_locked(piece_id: int, cells: Array)
signal piece_held(piece_id: int)
signal lines_cleared(rows: Array, count: int)
signal hard_dropped(distance: int)
signal score_changed(score: int, lines: int, level: int)
signal leveled_up(level: int)
signal ended(final_score: int)
signal won(final_score: int, elapsed_sec: float)
signal timed_out(final_score: int, elapsed_sec: float)

const COLS := 10
const ROWS := 22
const VISIBLE_ROWS := 20
const HIDDEN_ROWS := 2

## 0 = empty, 1..7 = piece ids stored as id+1
var grid: Array = []

var active: ActivePiece
var hold_id: int = -1
var hold_used: bool = false
var bag: BagRandomizer
var next_queue: Array[PieceType.Id] = []
var score: ScoreState
var mode: GameMode

var lock_timer: float = 0.0
var locking: bool = false
var move_resets: int = 0
var lock_delay: float = 0.5
const LOCK_DELAY := 0.5 ## default; runtime uses `lock_delay`
const MAX_MOVE_RESETS := 15

var is_game_over: bool = false
var is_won: bool = false
var is_timed_out: bool = false
var elapsed_sec: float = 0.0
var _gravity_accum: float = 0.0
var _seed: int = -1


func _init(seed_value: int = -1) -> void:
	_seed = seed_value
	mode = GameMode.standard_marathon()
	score = ScoreState.new()
	score.leveled_up.connect(func(lv: int): leveled_up.emit(lv))
	bag = BagRandomizer.new(_seed)
	_clear_grid()
	_fill_next(5)


func configure_mode(game_mode: GameMode) -> void:
	mode = game_mode if game_mode != null else GameMode.standard_marathon()


func start() -> void:
	_clear_grid()
	hold_id = -1
	hold_used = false
	is_game_over = false
	is_won = false
	is_timed_out = false
	elapsed_sec = 0.0
	_gravity_accum = 0.0
	score.reset()
	bag = BagRandomizer.new(_seed)
	next_queue.clear()
	_fill_next(5)
	_spawn_next()
	started.emit()


## Test seam: replace upcoming pieces (active piece unchanged).
func set_next_queue_for_test(ids: Array) -> void:
	next_queue.clear()
	for id in ids:
		next_queue.append(id as PieceType.Id)


## Test seam: force the active piece identity/pose.
func set_active_for_test(id: PieceType.Id, origin: Vector2i, rotation: int = 0) -> void:
	active = ActivePiece.new(id, origin)
	active.rotation = rotation
	locking = false
	lock_timer = 0.0
	move_resets = 0
	_gravity_accum = 0.0


func _clear_grid() -> void:
	grid.clear()
	for _y in ROWS:
		var row: Array = []
		row.resize(COLS)
		row.fill(0)
		grid.append(row)


func _fill_next(count: int) -> void:
	while next_queue.size() < count:
		next_queue.append(bag.next())


func peek_next(count: int = 5) -> Array[PieceType.Id]:
	_fill_next(count)
	var result: Array[PieceType.Id] = []
	for i in range(mini(count, next_queue.size())):
		result.append(next_queue[i])
	return result


func _spawn_next(reset_hold_lock: bool = true) -> bool:
	_fill_next(1)
	var id: PieceType.Id = next_queue.pop_front()
	_fill_next(5)
	active = ActivePiece.new(id)
	if reset_hold_lock:
		hold_used = false
	locking = false
	lock_timer = 0.0
	move_resets = 0
	if not _fits(active):
		is_game_over = true
		ended.emit(score.score)
		return false
	piece_spawned.emit(id)
	return true


func _fits(piece: ActivePiece) -> bool:
	for cell: Vector2i in piece.cells():
		if cell.x < 0 or cell.x >= COLS or cell.y >= ROWS:
			return false
		if cell.y < 0:
			continue
		if grid[cell.y][cell.x] != 0:
			return false
	return true


func is_play_stopped() -> bool:
	return is_game_over or is_won or is_timed_out


func time_remaining() -> float:
	if mode == null or not mode.has_time_limit():
		return -1.0
	return maxf(0.0, mode.duration_sec - elapsed_sec)


func try_move(dx: int, dy: int) -> bool:
	if active == null or is_play_stopped():
		return false
	var test := active.clone()
	test.origin += Vector2i(dx, dy)
	if not _fits(test):
		return false
	active.origin = test.origin
	_on_successful_move(dy == 0 and dx != 0)
	return true


func try_rotate(dir: int) -> bool:
	if active == null or is_play_stopped():
		return false
	if active.id == PieceType.Id.O:
		return true

	var from_rot := active.rotation
	var to_rot := posmod(from_rot + dir, 4)
	for kick: Vector2i in Srs.kicks(active.id, from_rot, to_rot):
		var test := active.clone()
		test.rotation = to_rot
		# SRS Y is up-positive in docs; our grid Y grows downward → flip kick.y
		test.origin += Vector2i(kick.x, -kick.y)
		if _fits(test):
			active.rotation = to_rot
			active.origin = test.origin
			_on_successful_move(true)
			return true
	return false


func hard_drop() -> int:
	if active == null or is_play_stopped():
		return 0
	var distance := 0
	while try_move(0, 1):
		distance += 1
	score.add_hard_drop(distance)
	hard_dropped.emit(distance)
	_lock_piece()
	return distance


func soft_drop_step() -> bool:
	if try_move(0, 1):
		score.add_soft_drop(1)
		return true
	return false


func hold() -> bool:
	if active == null or is_play_stopped() or hold_used:
		return false
	hold_used = true
	var current := active.id
	if hold_id < 0:
		hold_id = current
		# Keep hold locked for the incoming piece until it locks.
		if not _spawn_next(false):
			return true
	else:
		var swap: PieceType.Id = hold_id as PieceType.Id
		hold_id = current
		active = ActivePiece.new(swap)
		locking = false
		lock_timer = 0.0
		move_resets = 0
		if not _fits(active):
			is_game_over = true
			ended.emit(score.score)
	piece_held.emit(hold_id)
	return true


func ghost_cells() -> Array[Vector2i]:
	if active == null:
		return []
	var ghost := active.clone()
	while true:
		var test := ghost.clone()
		test.origin += Vector2i(0, 1)
		if not _fits(test):
			break
		ghost.origin = test.origin
	return ghost.cells()


func tick_gravity(delta: float, soft_dropping: bool) -> void:
	if is_play_stopped():
		return
	elapsed_sec += delta
	if _try_declare_timeout():
		return
	if active == null:
		return

	# On ground: always advance lock delay (even while soft-dropping).
	if _on_ground():
		locking = true
		lock_timer += delta
		if lock_timer >= lock_delay:
			_lock_piece()
		return

	locking = false
	lock_timer = 0.0

	# Soft drop movement is driven by RepeatInput ARR in GameController.
	if soft_dropping:
		return

	var interval := score.gravity_seconds()
	_gravity_accum += delta
	while _gravity_accum >= interval:
		_gravity_accum -= interval
		if not try_move(0, 1):
			break


func _on_ground() -> bool:
	if active == null:
		return false
	var test := active.clone()
	test.origin += Vector2i(0, 1)
	return not _fits(test)


func _on_successful_move(resets_lock: bool) -> void:
	if resets_lock and locking and move_resets < MAX_MOVE_RESETS:
		lock_timer = 0.0
		move_resets += 1


func _lock_piece() -> void:
	if active == null:
		return
	var locked_cells: Array = []
	for cell: Vector2i in active.cells():
		if cell.y >= 0 and cell.y < ROWS and cell.x >= 0 and cell.x < COLS:
			grid[cell.y][cell.x] = int(active.id) + 1
			locked_cells.append(cell)
	var piece_id := active.id
	active = null
	piece_locked.emit(piece_id, locked_cells)

	var cleared_rows := _clear_lines()
	if cleared_rows.size() > 0:
		score.add_line_clear(cleared_rows.size())
		lines_cleared.emit(cleared_rows, cleared_rows.size())
	score_changed.emit(score.score, score.lines, score.level)

	_gravity_accum = 0.0
	locking = false
	lock_timer = 0.0
	move_resets = 0

	if _try_declare_win():
		return
	_spawn_next()


func _try_declare_win() -> bool:
	if mode == null or not mode.win_on_target:
		return false
	if mode.target_lines <= 0 or score.lines < mode.target_lines:
		return false
	is_won = true
	active = null
	won.emit(score.score, elapsed_sec)
	return true


func _try_declare_timeout() -> bool:
	if mode == null or not mode.has_time_limit():
		return false
	if elapsed_sec < mode.duration_sec:
		return false
	elapsed_sec = mode.duration_sec
	is_timed_out = true
	active = null
	timed_out.emit(score.score, elapsed_sec)
	return true


func _clear_lines() -> Array:
	var cleared: Array = []
	var new_grid: Array = []
	for y in range(ROWS):
		var full := true
		for x in range(COLS):
			if grid[y][x] == 0:
				full = false
				break
		if full:
			cleared.append(y)
		else:
			new_grid.append(grid[y])

	while new_grid.size() < ROWS:
		var empty: Array = []
		empty.resize(COLS)
		empty.fill(0)
		new_grid.push_front(empty)

	grid = new_grid
	return cleared
