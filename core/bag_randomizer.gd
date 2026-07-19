class_name BagRandomizer
extends RefCounted

var _bag: Array[PieceType.Id] = []
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_refill()


func next() -> PieceType.Id:
	if _bag.is_empty():
		_refill()
	return _bag.pop_back()


func peek(count: int) -> Array[PieceType.Id]:
	while _bag.size() < count:
		_append_bag()
	var result: Array[PieceType.Id] = []
	for i in range(count):
		result.append(_bag[_bag.size() - 1 - i])
	return result


func _refill() -> void:
	_bag.clear()
	_append_bag()


func _append_bag() -> void:
	var pieces: Array[PieceType.Id] = [
		PieceType.Id.I, PieceType.Id.O, PieceType.Id.T,
		PieceType.Id.S, PieceType.Id.Z, PieceType.Id.J, PieceType.Id.L,
	]
	for i in range(pieces.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := pieces[i]
		pieces[i] = pieces[j]
		pieces[j] = tmp
	# Stack so pop_back yields the first shuffled piece.
	for i in range(pieces.size() - 1, -1, -1):
		_bag.append(pieces[i])
