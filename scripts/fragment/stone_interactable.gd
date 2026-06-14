extends Node2D

@export var display_name: String = "石碑"
@export var fallback_interact_size: Vector2 = Vector2(120, 120)


func _ready() -> void:
	add_to_group("interactable")
	_ensure_interactable_area()


func interact() -> void:
	var fragment := _find_fragment_scene()
	if fragment and fragment.has_method("show_stone"):
		fragment.show_stone()


func _ensure_interactable_area() -> void:
	var area := get_node_or_null("InteractableArea") as Area2D
	if area == null:
		area = Area2D.new()
		area.name = "InteractableArea"
		add_child(area)
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = true
	area.monitorable = true

	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		area.add_child(shape)
	if shape.shape == null:
		var rect := RectangleShape2D.new()
		rect.size = fallback_interact_size
		shape.shape = rect


func _find_fragment_scene() -> Node:
	var current: Node = self
	while current:
		if current.has_method("show_stone"):
			return current
		if current.is_in_group("fragment_state"):
			return current
		current = current.get_parent()
	return null
