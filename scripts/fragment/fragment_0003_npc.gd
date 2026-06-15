extends CharacterBody2D

const SoftShadow = preload("res://scripts/fragment/soft_shadow.gd")

@export var npc_name: String = "未命名"
@export var npc_role: String = "道观住民"
@export var npc_kb_id: String = ""
@export_multiline var default_greeting: String = ""

var current_state: int = 0


func _ready() -> void:
	add_to_group("npc")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shadow := get_node_or_null("Visual Node2D/Shadow Sprite2D") as Sprite2D
	var visual := get_node_or_null("Visual Node2D/Visual") as Sprite2D
	SoftShadow.apply_to(shadow, visual)
	_configure_interaction_area()


func _configure_interaction_area() -> void:
	var area := get_node_or_null("InteractionArea Area2D") as Area2D
	if area == null:
		return
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = true
	area.monitorable = true


func get_greeting() -> String:
	var state := _find_fragment_state()
	if state != null and state.has_method("get_0003_npc_greeting"):
		return str(state.get_0003_npc_greeting(npc_kb_id))
	return default_greeting


func get_fallback_response() -> String:
	return get_greeting()


func start_dialogue() -> void:
	current_state = 1


func end_dialogue() -> void:
	current_state = 0


func send_player_message(message: String) -> void:
	var state := _find_fragment_state()
	if state != null and state.has_method("handle_npc_player_message"):
		if state.handle_npc_player_message(self, message):
			return
	ChatDialogue.add_npc_msg(get_greeting())


func can_give_item() -> bool:
	return false


func _find_fragment_state() -> Node:
	for state in get_tree().get_nodes_in_group("fragment_state"):
		if state != null and state.has_method("get_0003_npc_greeting"):
			return state
	return null
