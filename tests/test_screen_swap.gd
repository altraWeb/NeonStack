extends RefCounted

const ScreenSwap := preload("res://ui/screen_swap.gd")


func run() -> TestSuite:
	var t := TestSuite.new("ScreenSwap")
	_test_replace_removes_old_from_tree(t)
	_test_clear_empties_host(t)
	return t


func _test_replace_removes_old_from_tree(t: TestSuite) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var host := Node.new()
	tree.root.add_child(host)

	var old := Node.new()
	old.name = "OldScreen"
	host.add_child(old)
	var next := Node.new()
	next.name = "NewScreen"

	var current: Node = ScreenSwap.replace(host, old, next)
	t.assert_eq(current, next, "replace returns next")
	t.assert_false(old.is_inside_tree(), "old detached immediately")
	t.assert_true(next.is_inside_tree(), "next is inside tree")
	t.assert_eq(host.get_child_count(), 1, "host has exactly one child")
	t.assert_eq(host.get_child(0), next, "host child is next")

	host.queue_free()


func _test_clear_empties_host(t: TestSuite) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var host := Node.new()
	tree.root.add_child(host)

	var a := Node.new()
	var b := Node.new()
	host.add_child(a)
	host.add_child(b)

	ScreenSwap.clear(host, a)

	t.assert_eq(host.get_child_count(), 0, "clear removes all host children")
	t.assert_false(a.is_inside_tree(), "tracked current detached")
	t.assert_false(b.is_inside_tree(), "straggler detached")

	host.queue_free()
