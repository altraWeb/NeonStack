extends RefCounted


func run() -> TestSuite:
	var t := TestSuite.new("BagRandomizer")

	_test_seven_unique_per_bag(t)
	_test_seed_is_deterministic(t)
	_test_peek_matches_next(t)
	_test_refills_after_seven(t)

	return t


func _test_seven_unique_per_bag(t: TestSuite) -> void:
	var bag := BagRandomizer.new(42)
	var seen: Dictionary = {}
	for _i in 7:
		var id: PieceType.Id = bag.next()
		seen[id] = true
	t.assert_eq(seen.size(), 7, "first bag contains all 7 piece types")


func _test_seed_is_deterministic(t: TestSuite) -> void:
	var a := BagRandomizer.new(99)
	var b := BagRandomizer.new(99)
	var seq_a: Array = []
	var seq_b: Array = []
	for _i in 14:
		seq_a.append(a.next())
		seq_b.append(b.next())
	t.assert_eq(seq_a, seq_b, "same seed yields same sequence")


func _test_peek_matches_next(t: TestSuite) -> void:
	var bag := BagRandomizer.new(7)
	var preview := bag.peek(3)
	t.assert_eq(preview.size(), 3, "peek returns requested count")
	t.assert_eq(bag.next(), preview[0], "next matches peek[0]")
	t.assert_eq(bag.next(), preview[1], "second next matches peek[1]")


func _test_refills_after_seven(t: TestSuite) -> void:
	var bag := BagRandomizer.new(1)
	for _i in 7:
		bag.next()
	var eighth: PieceType.Id = bag.next()
	t.assert_true(int(eighth) >= 0 and int(eighth) <= 6, "bag refills and keeps yielding pieces")
