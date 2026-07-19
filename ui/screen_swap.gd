class_name ScreenSwap
extends RefCounted
## Safe screen replacement: detach before queue_free so the old screen
## cannot keep processing beside the new one for a frame.


static func replace(host: Node, current: Node, next: Node) -> Node:
	if current != null and is_instance_valid(current):
		var parent := current.get_parent()
		if parent != null:
			parent.remove_child(current)
		current.queue_free()
	host.add_child(next)
	return next


static func clear(host: Node, current: Node) -> void:
	if current != null and is_instance_valid(current):
		var parent := current.get_parent()
		if parent != null:
			parent.remove_child(current)
		current.queue_free()
	# Drop any stragglers still parented under the host.
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
