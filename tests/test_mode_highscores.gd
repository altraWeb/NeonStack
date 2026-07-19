extends RefCounted

const TMP := "user://test_highscores_mode.json"


func run() -> TestSuite:
	var t := TestSuite.new("ModeHighscores")
	_wipe()

	_test_marathon_ranks_by_score(t)
	_wipe()
	_test_sprint_ranks_by_time(t)
	_wipe()
	_test_sprint_only_accepts_wins(t)
	_wipe()
	_test_boards_are_isolated(t)
	_wipe()
	_test_migrates_legacy_array(t)
	_wipe()
	_test_save_creates_file(t)
	_wipe()

	return t


func _wipe() -> void:
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(TMP)


func _store() -> LocalHighscoreStore:
	return LocalHighscoreStore.new(TMP)


func _test_marathon_ranks_by_score(t: TestSuite) -> void:
	var s := _store()
	s.submit_marathon("A", 1000, 20, 3)
	s.submit_marathon("B", 3000, 40, 5)
	s.submit_marathon("C", 2000, 30, 4)
	var top := s.get_top(GameMode.standard_marathon().id, 10)
	t.assert_eq(top.size(), 3, "three marathon entries")
	t.assert_eq(str(top[0]["name"]), "B", "highest score first")
	t.assert_eq(int(top[0]["score"]), 3000, "top score value")
	t.assert_true(s.is_marathon_highscore(5000), "better score is highscore")
	t.assert_false(s.is_marathon_highscore(0), "zero score is not")


func _test_sprint_ranks_by_time(t: TestSuite) -> void:
	var s := _store()
	s.submit_sprint("SLOW", 100, 40, 5, 120.0)
	s.submit_sprint("FAST", 100, 40, 5, 45.5)
	s.submit_sprint("MID", 100, 40, 5, 80.0)
	var top := s.get_top(GameMode.sprint_40().id, 10)
	t.assert_eq(top.size(), 3, "three sprint entries")
	t.assert_eq(str(top[0]["name"]), "FAST", "fastest time first")
	t.assert_eq(float(top[0]["elapsed_sec"]), 45.5, "top time value")
	t.assert_true(s.is_sprint_highscore(40.0), "faster time is highscore")

	# Fill board then slower time should fail
	_wipe()
	s = _store()
	for i in LocalHighscoreStore.MAX_ENTRIES:
		s.submit_sprint("P%d" % i, 1, 40, 1, 10.0 + float(i))
	t.assert_false(s.is_sprint_highscore(999.0), "slower than worst is not highscore when full")
	t.assert_true(s.is_sprint_highscore(9.0), "faster than best still qualifies when full")


func _test_sprint_only_accepts_wins(t: TestSuite) -> void:
	var s := _store()
	t.assert_false(s.is_sprint_highscore(-1.0), "non-win elapsed rejected")
	t.assert_false(s.is_sprint_highscore(0.0), "zero time rejected")
	s.submit_sprint("X", 1, 10, 1, -1.0) # should no-op
	t.assert_eq(s.get_top(GameMode.sprint_40().id, 10).size(), 0, "non-win not stored")


func _test_boards_are_isolated(t: TestSuite) -> void:
	var s := _store()
	s.submit_marathon("M", 9000, 50, 8)
	s.submit_sprint("S", 100, 40, 5, 55.0)
	t.assert_eq(s.get_top(GameMode.standard_marathon().id, 10).size(), 1, "marathon board size")
	t.assert_eq(s.get_top(GameMode.sprint_40().id, 10).size(), 1, "sprint board size")
	t.assert_eq(str(s.get_top(GameMode.standard_marathon().id, 1)[0]["name"]), "M", "marathon name")
	t.assert_eq(str(s.get_top(GameMode.sprint_40().id, 1)[0]["name"]), "S", "sprint name")


func _test_migrates_legacy_array(t: TestSuite) -> void:
	var legacy: Array = [{
		"name": "OLD",
		"score": 1234,
		"lines": 12,
		"level": 2,
		"at": "2026-01-01T00:00:00",
	}]
	var file := FileAccess.open(TMP, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var s := _store()
	var top := s.get_top(GameMode.standard_marathon().id, 10)
	t.assert_eq(top.size(), 1, "legacy migrated to marathon")
	t.assert_eq(str(top[0]["name"]), "OLD", "legacy name preserved")
	t.assert_eq(s.get_top(GameMode.sprint_40().id, 10).size(), 0, "sprint empty after migrate")


func _test_save_creates_file(t: TestSuite) -> void:
	var s := _store()
	s.submit_marathon("SAVE", 42, 1, 1)
	t.assert_true(FileAccess.file_exists(TMP), "highscores file written")
	var s2 := _store()
	var top := s2.get_top(GameMode.standard_marathon().id, 1)
	t.assert_eq(top.size(), 1, "reload sees entry")
	t.assert_eq(str(top[0]["name"]), "SAVE", "reloaded name")
