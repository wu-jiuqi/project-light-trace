extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const PLAYER_VISUAL_SCALE := Vector2(2.2, 2.2)

var _player: CharacterBody2D = null
var _interact_hint_label: Label = null


func _enter_tree() -> void:
	add_to_group("fragment_state")


func _ready() -> void:
	_prepare_fragment_context()
	_ensure_interact_hint()
	_spawn_player()
	_connect_player_ui()
	_fit_world_to_viewport()
	if not get_viewport().size_changed.is_connected(_fit_world_to_viewport):
		get_viewport().size_changed.connect(_fit_world_to_viewport)
	SceneFader.fade_in()
	print("[Fragment0002Scene] Ready: %s" % name)


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id("0002")
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _ensure_interact_hint() -> void:
	var ui_root := get_node_or_null("UIRoot") as CanvasLayer
	if ui_root == null:
		return

	_interact_hint_label = ui_root.get_node_or_null("InteractHint") as Label
	if _interact_hint_label != null:
		return

	_interact_hint_label = Label.new()
	_interact_hint_label.name = "InteractHint"
	_interact_hint_label.visible = false
	_interact_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_interact_hint_label.offset_left = 0.0
	_interact_hint_label.offset_right = 0.0
	_interact_hint_label.offset_top = -64.0
	_interact_hint_label.offset_bottom = -28.0
	_interact_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_hint_label.add_theme_font_size_override("font_size", 18)
	_interact_hint_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 0.95))
	_interact_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_interact_hint_label)


func _spawn_player() -> void:
	if _player != null and is_instance_valid(_player):
		return

	var world_root := get_node_or_null("WorldRoot") as Node2D
	var parent := world_root if world_root != null else self
	var spawn_marker := _resolve_spawn_marker()
	var spawn_pos := spawn_marker.global_position if spawn_marker != null else DESIGN_SIZE * 0.5

	_player = PLAYER_SCENE.instantiate() as CharacterBody2D
	_player.name = "Player"
	_player.scale = Vector2.ONE
	parent.add_child(_player)
	_apply_player_visual_scale()
	_player.global_position = spawn_pos
	print("[Fragment0002Scene] Player spawned at %s" % str(spawn_pos))


func _apply_player_visual_scale() -> void:
	if _player == null:
		return

	var visual_root := _player.get_node_or_null("Visual Node2D") as Node2D
	if visual_root != null:
		visual_root.scale = PLAYER_VISUAL_SCALE


func _resolve_spawn_marker() -> Marker2D:
	var spawn_points := get_node_or_null("WorldRoot/SpawnPoints")
	if spawn_points == null:
		return null

	var spawn_name := SceneManager.pending_spawn_point
	if spawn_name.is_empty():
		spawn_name = "Default"
	else:
		SceneManager.pending_spawn_point = ""

	var marker := spawn_points.get_node_or_null(spawn_name) as Marker2D
	if marker == null and spawn_name != "Default":
		marker = spawn_points.get_node_or_null("Default") as Marker2D
	return marker


func _connect_player_ui() -> void:
	if _player == null or _interact_hint_label == null:
		return
	if _player.has_signal("interact_hint_changed") and not _player.interact_hint_changed.is_connected(_on_interact_hint_changed):
		_player.interact_hint_changed.connect(_on_interact_hint_changed)


func _on_interact_hint_changed(show: bool, hint_text: String) -> void:
	if _interact_hint_label == null:
		return
	_interact_hint_label.visible = show
	_interact_hint_label.text = hint_text


func _fit_world_to_viewport() -> void:
	var world_root := get_node_or_null("WorldRoot") as Node2D
	if world_root == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE

	var scale_factor := maxf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var scaled_size := DESIGN_SIZE * scale_factor
	world_root.scale = Vector2(scale_factor, scale_factor)
	world_root.position = (viewport_size - scaled_size) * 0.5


func get_game_state(_npc_kb_id: String) -> Dictionary:
	return {
		"fragment_id": "0002",
		"scene_name": name,
		"memory_stage": "initial",
		"alert_level": 0,
		"trust_level": 0,
		"awakened_colors": [],
		"awakened_count": 0,
	}


func has_player_for_test() -> bool:
	return _player != null and is_instance_valid(_player)


func get_player_position_for_test() -> Vector2:
	return _player.global_position if has_player_for_test() else Vector2.ZERO


func get_player_scale_for_test() -> Vector2:
	return _player.scale if has_player_for_test() else Vector2.ZERO


func get_player_visual_scale_for_test() -> Vector2:
	if not has_player_for_test():
		return Vector2.ZERO
	var visual_root := _player.get_node_or_null("Visual Node2D") as Node2D
	return visual_root.scale if visual_root != null else Vector2.ZERO
