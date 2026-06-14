extends Node2D

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn_point: String = "Default"
@export var display_name: String = ""


func _ready() -> void:
	add_to_group("interactable")
	_configure_areas(self)
	if display_name.is_empty():
		display_name = name


func interact(_actor: Node = null) -> void:
	if target_scene.is_empty():
		push_error("[InteractionSceneExit] target_scene is empty on %s" % name)
		return
	var spawn := target_spawn_point
	if spawn.is_empty():
		spawn = "Default"
	SceneManager.change_scene(target_scene, spawn)


func _configure_areas(node: Node) -> void:
	if node is Area2D:
		var area := node as Area2D
		area.collision_layer = 2
		area.collision_mask = 0
		area.monitoring = true
		area.monitorable = true
	for child in node.get_children():
		_configure_areas(child)
