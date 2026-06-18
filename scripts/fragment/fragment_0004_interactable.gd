extends Node

var action_id: String = ""
var display_name: String = ""


func configure(new_action_id: String, new_display_name: String = "") -> void:
	action_id = new_action_id
	display_name = new_display_name if not new_display_name.is_empty() else name
	add_to_group("interactable")
	_configure_areas(self)


func interact(_actor: Node = null) -> void:
	var state := _find_fragment_state()
	if state != null and state.has_method("handle_0004_interaction"):
		state.handle_0004_interaction(action_id, self)


func _find_fragment_state() -> Node:
	for state in get_tree().get_nodes_in_group("fragment_state"):
		if state != null and state.has_method("handle_0004_interaction"):
			return state
	return null


func _configure_areas(node: Node) -> void:
	if node is Area2D:
		var area := node as Area2D
		area.collision_layer = 2
		area.collision_mask = 0
		area.monitoring = true
		area.monitorable = true
	for child in node.get_children():
		_configure_areas(child)
