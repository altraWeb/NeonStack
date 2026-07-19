class_name ActivePiece
extends RefCounted

var id: PieceType.Id
var origin: Vector2i
var rotation: int = 0


func _init(piece_id: PieceType.Id, spawn: Vector2i = Vector2i(-1, -1)) -> void:
	id = piece_id
	origin = spawn if spawn != Vector2i(-1, -1) else PieceType.SPAWN[piece_id]
	rotation = 0


func cells() -> Array[Vector2i]:
	return PieceType.absolute_cells(id, rotation, origin)


func clone() -> ActivePiece:
	var copy := ActivePiece.new(id, origin)
	copy.rotation = rotation
	return copy
