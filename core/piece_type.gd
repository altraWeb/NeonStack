class_name PieceType
extends RefCounted

enum Id { I, O, T, S, Z, J, L }

const NAMES := {
	Id.I: "I",
	Id.O: "O",
	Id.T: "T",
	Id.S: "S",
	Id.Z: "Z",
	Id.J: "J",
	Id.L: "L",
}

## Spawn origin on a 10-wide board (hidden rows at top).
const SPAWN := {
	Id.I: Vector2i(3, 0),
	Id.O: Vector2i(4, 0),
	Id.T: Vector2i(3, 0),
	Id.S: Vector2i(3, 0),
	Id.Z: Vector2i(3, 0),
	Id.J: Vector2i(3, 0),
	Id.L: Vector2i(3, 0),
}


## Four rotation states (0, R, 2, L). Cells relative to piece origin.
static func cells(id: Id) -> Array:
	match id:
		Id.I:
			return [
				[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
				[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
				[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
				[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],
			]
		Id.O:
			var box := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
			return [box, box, box, box]
		Id.T:
			return [
				[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
				[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
				[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
				[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
			]
		Id.S:
			return [
				[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
				[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
				[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
				[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
			]
		Id.Z:
			return [
				[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
				[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
				[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
				[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
			]
		Id.J:
			return [
				[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
				[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
				[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
				[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
			]
		Id.L:
			return [
				[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
				[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
				[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],
				[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
			]
	return []


static func absolute_cells(id: Id, rotation: int, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var states: Array = cells(id)
	var rot := posmod(rotation, 4)
	for cell: Vector2i in states[rot]:
		result.append(origin + cell)
	return result
