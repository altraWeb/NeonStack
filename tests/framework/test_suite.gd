class_name TestSuite
extends RefCounted
## Tiny assertion helper for headless Godot tests.

var name: String
var passed: int = 0
var failed: int = 0
var errors: PackedStringArray = []


func _init(suite_name: String) -> void:
	name = suite_name


func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		var msg := message if message != "" else "expected true"
		errors.append("[%s] %s" % [name, msg])
		push_error("FAIL %s: %s" % [name, msg])


func assert_false(condition: bool, message: String = "") -> void:
	assert_true(not condition, message if message != "" else "expected false")


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		var msg := message if message != "" else "expected %s == %s" % [str(expected), str(actual)]
		errors.append("[%s] %s (got %s)" % [name, msg, str(actual)])
		push_error("FAIL %s: %s (got %s, expected %s)" % [name, msg, str(actual), str(expected)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assert_true(actual != unexpected, message if message != "" else "expected value != %s" % str(unexpected))


func assert_gt(actual: Variant, minimum: Variant, message: String = "") -> void:
	assert_true(actual > minimum, message if message != "" else "expected %s > %s" % [str(actual), str(minimum)])


func summary() -> String:
	return "%s: %d passed, %d failed" % [name, passed, failed]
