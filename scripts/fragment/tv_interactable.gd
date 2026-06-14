extends Node2D

@export var display_name: String = "TV"


func _ready() -> void:
	add_to_group("interactable")
	_ensure_interactable_area()


func interact() -> void:
	var fragment := _find_fragment_scene()
	if fragment and fragment.has_method("show_tv"):
		fragment.show_tv()


func _ensure_interactable_area() -> void:
	var area := get_node_or_null("InteractableArea") as Area2D
	if area == null:
		return
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitorable = true


func _find_fragment_scene() -> Node:
	var current: Node = self
	while current:
		if current.has_method("show_tv"):
			return current
		if current.is_in_group("fragment_state"):
			return current
		current = current.get_parent()
	return null
