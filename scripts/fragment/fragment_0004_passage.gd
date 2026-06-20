extends Node2D

const Data = preload("res://scripts/fragment/fragment_0004_data.gd")
const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const DIALOGUE_BOX_SCENE: PackedScene = preload("res://scenes/ui/DialogueBox.tscn")
const INTERACTABLE_SCRIPT: Script = preload("res://scripts/fragment/fragment_0004_interactable.gd")
const BGM_PATH_0004 := "res://assets/audio/0004.mp3"
var _bgm_stream_0004: AudioStream = null
const SFX_PICKUP := preload("res://assets/audio/sfx/ui_item_pickup.wav")
const SFX_PICKUP_VOLUME_DB: float = -4.0

const BLUEPRINT_LABELS := {
	"Head": "头部图纸",
	"Heart": "心脏图纸",
	"LeftArm": "左臂图纸",
	"RightArm": "右臂图纸",
	"LeftLeg": "左腿图纸",
	"RightLeg": "右腿图纸",
}

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _ui_root: CanvasLayer = null
var _interact_hint: Label = null
var _message_label: Label = null
var _message_token: int = 0

var _viewer: Control = null
var _viewer_image: TextureRect = null
var _viewer_hint: Label = null
var _viewer_blueprint_id: String = ""
var _viewer_pages: Array[String] = []
var _viewer_page_index := 0
var _viewer_block_until_msec := 0


func _enter_tree() -> void:
	add_to_group("fragment_state")


func _ready() -> void:
	_prepare_fragment_context()
	_ensure_state_defaults()
	_ensure_ui()
	_spawn_player()
	_configure_scene_interactions()
	_setup_camera()
	_fit_background_to_design()
	_fit_world_to_viewport()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	SceneFader.fade_in()
	_start_bgm()


func _input(event: InputEvent) -> void:
	if _viewer != null and _viewer.visible:
		if event.is_action_pressed("interact") and Time.get_ticks_msec() >= _viewer_block_until_msec:
			_collect_current_blueprint()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Time.get_ticks_msec() >= _viewer_block_until_msec:
			_collect_current_blueprint()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_close_viewer()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_flip_page(-1 if event.is_action_pressed("ui_left") else 1)
			get_viewport().set_input_as_handled()


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null or FragmentManager.current_fragment.id != Data.FRAGMENT_ID:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id(Data.FRAGMENT_ID)
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _ensure_state_defaults() -> void:
	for key in Data.default_state():
		if FragmentManager.get_fragment_state(Data.FRAGMENT_ID, key) == null:
			FragmentManager.set_fragment_state(Data.FRAGMENT_ID, key, Data.default_state()[key])


func _ensure_ui() -> void:
	_ui_root = get_node_or_null("UIRoot") as CanvasLayer
	if _ui_root == null:
		_ui_root = CanvasLayer.new()
		_ui_root.name = "UIRoot"
		add_child(_ui_root)
	_ui_root.layer = max(_ui_root.layer, 70)

	if _ui_root.get_node_or_null("DialogueBox") == null:
		var dialogue_box := DIALOGUE_BOX_SCENE.instantiate()
		dialogue_box.name = "DialogueBox"
		dialogue_box.visible = false
		_ui_root.add_child(dialogue_box)

	_interact_hint = _ui_root.get_node_or_null("InteractHint") as Label
	if _interact_hint == null:
		_interact_hint = Label.new()
		_interact_hint.name = "InteractHint"
		_interact_hint.visible = false
		_interact_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_interact_hint.offset_top = -64.0
		_interact_hint.offset_bottom = -28.0
		_interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_interact_hint.add_theme_font_size_override("font_size", 18)
		_interact_hint.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 0.95))
		_interact_hint.add_theme_constant_override("outline_size", 3)
		_interact_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_root.add_child(_interact_hint)

	_message_label = Label.new()
	_message_label.name = "FragmentMessage"
	_message_label.visible = false
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.position = Vector2(-360.0, 214.0)
	_message_label.size = Vector2(720.0, 64.0)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 22)
	_message_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.72))
	_message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_message_label.add_theme_constant_override("shadow_offset_x", 2)
	_message_label.add_theme_constant_override("shadow_offset_y", 2)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.z_index = 300
	_ui_root.add_child(_message_label)
	_ensure_viewer()


func _ensure_viewer() -> void:
	if _viewer != null:
		return
	_viewer = Control.new()
	_viewer.name = "BlueprintViewer"
	_viewer.visible = false
	_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_viewer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(dim)

	_viewer_image = TextureRect.new()
	_viewer_image.name = "Image"
	_viewer_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(_viewer_image)

	_viewer_hint = Label.new()
	_viewer_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_viewer_hint.offset_top = -62.0
	_viewer_hint.offset_bottom = -24.0
	_viewer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer_hint.add_theme_font_size_override("font_size", 18)
	_viewer_hint.add_theme_color_override("font_color", Color(0.95, 0.84, 0.58))
	_viewer_hint.add_theme_constant_override("outline_size", 3)
	_viewer.add_child(_viewer_hint)


func _spawn_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var parent := get_node_or_null("WorldRoot") as Node2D
	if parent == null:
		parent = self
	var spawn_marker := _resolve_spawn_marker()
	var spawn_position := spawn_marker.global_position if spawn_marker != null else Data.DESIGN_SIZE * 0.5
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D
	_player.name = "Player"
	parent.add_child(_player)
	var visual_root := _player.get_node_or_null("Visual Node2D") as Node2D
	if visual_root != null:
		visual_root.scale = Data.PLAYER_VISUAL_SCALE
	_player.global_position = spawn_position
	if _player.has_signal("interact_hint_changed"):
		_player.interact_hint_changed.connect(_on_interact_hint_changed)


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
	if marker == null:
		marker = spawn_points.get_node_or_null("Default") as Marker2D
	return marker


func _configure_scene_interactions() -> void:
	_configure_area_proxy("WorldRoot/Interaction/JumpInteractionArea", "return_main", "返回工坊")
	for blueprint_id in Data.BLUEPRINT_PAGES.keys():
		_configure_blueprint_interaction(str(blueprint_id))


func _configure_blueprint_interaction(blueprint_id: String) -> void:
	var area := get_node_or_null("WorldRoot/%s" % blueprint_id) as Area2D
	if area == null:
		return
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = true
	area.monitorable = true
	area.input_pickable = true
	if not area.input_event.is_connected(_on_blueprint_area_input_event):
		area.input_event.connect(_on_blueprint_area_input_event.bind(blueprint_id))
	_configure_area_proxy("WorldRoot/%s" % blueprint_id, "blueprint:%s" % blueprint_id, _blueprint_label(blueprint_id))


func _on_blueprint_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, blueprint_id: String) -> void:
	if _viewer != null and _viewer.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_open_blueprint(blueprint_id)
		get_viewport().set_input_as_handled()


func _configure_area_proxy(area_path: String, action_id: String, label: String) -> void:
	var area := get_node_or_null(area_path) as Area2D
	if area == null:
		return
	if area.get_parent() != null and area.get_parent().is_in_group("interactable"):
		return
	var old_parent := area.get_parent()
	if old_parent == null:
		return
	var proxy := Node2D.new()
	proxy.name = "%sProxy" % area.name
	old_parent.add_child(proxy)
	proxy.global_position = _area_global_center(area)
	area.reparent(proxy, true)
	_configure_interactable(proxy, action_id, label)


func _configure_interactable(node: Node, action_id: String, label: String) -> void:
	if node == null:
		return
	if node.get_script() == null:
		node.set_script(INTERACTABLE_SCRIPT)
	if node.has_method("configure"):
		node.configure(action_id, label)


func _area_global_center(area: Area2D) -> Vector2:
	var points: Array[Vector2] = []
	for child in area.get_children():
		if child is CollisionShape2D:
			points.append((child as CollisionShape2D).global_position)
		elif child is CollisionPolygon2D:
			var polygon := child as CollisionPolygon2D
			for point in polygon.polygon:
				points.append(polygon.global_transform * point)
	if points.is_empty():
		return area.global_position
	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())


func _setup_camera() -> void:
	_camera = null


func handle_0004_interaction(action_id: String, _source: Node = null) -> void:
	if _viewer != null and _viewer.visible:
		return
	if action_id == "return_main":
		SceneManager.change_scene(Data.MAIN_SCENE, "Default")
	elif action_id.begins_with("blueprint:"):
		_open_blueprint(action_id.trim_prefix("blueprint:"))


func _open_blueprint(blueprint_id: String) -> void:
	var pages: Array = Data.BLUEPRINT_PAGES.get(blueprint_id, [])
	if pages.is_empty():
		return
	_viewer_blueprint_id = blueprint_id
	_viewer_pages.clear()
	for path in pages:
		if ResourceLoader.exists(str(path)):
			_viewer_pages.append(str(path))
	if _viewer_pages.is_empty():
		return
	_viewer_page_index = 0
	_update_viewer_image()
	_viewer_block_until_msec = Time.get_ticks_msec() + 180
	_viewer.visible = true
	_set_player_locked(true)


func _flip_page(delta: int) -> void:
	if _viewer_pages.is_empty():
		return
	_viewer_page_index = posmod(_viewer_page_index + delta, _viewer_pages.size())
	_update_viewer_image()


func _update_viewer_image() -> void:
	var texture := load(_viewer_pages[_viewer_page_index]) as Texture2D
	_viewer_image.texture = texture
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Data.DESIGN_SIZE
	var max_size := viewport_size * Vector2(0.68, 0.62)
	var scale_factor := minf(0.82, minf(max_size.x / texture.get_size().x, max_size.y / texture.get_size().y))
	_viewer_image.size = texture.get_size() * scale_factor
	_viewer_image.position = (viewport_size - _viewer_image.size) * 0.5
	_viewer_hint.text = "A/D 或 ←/→ 翻页 | 点击或按 E 收集 | Esc 关闭  (%d/%d)" % [_viewer_page_index + 1, _viewer_pages.size()]


func _collect_current_blueprint() -> void:
	if _viewer_blueprint_id.is_empty():
		return
	var collected := _state_dict("collected_blueprints")
	var first_time := int(collected.get(_viewer_blueprint_id, 0)) == 0
	if first_time:
		collected[_viewer_blueprint_id] = 1
		FragmentManager.set_fragment_state(Data.FRAGMENT_ID, "collected_blueprints", collected)
		_play_pickup_sfx()
	_show_message("已收集图纸：%s" % _blueprint_label(_viewer_blueprint_id) if first_time else "这张图纸已经收集过了：%s" % _blueprint_label(_viewer_blueprint_id))
	_close_viewer()


func _close_viewer() -> void:
	_viewer.visible = false
	_viewer_blueprint_id = ""
	_viewer_pages.clear()
	_viewer_page_index = 0
	_set_player_locked(false)


func _fit_world_to_viewport() -> void:
	var world_root := get_node_or_null("WorldRoot") as Node2D
	if world_root == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Data.DESIGN_SIZE
	var scale_factor := maxf(viewport_size.x / Data.DESIGN_SIZE.x, viewport_size.y / Data.DESIGN_SIZE.y)
	var scaled_size := Data.DESIGN_SIZE * scale_factor
	world_root.scale = Vector2(scale_factor, scale_factor)
	world_root.position = (viewport_size - scaled_size) * 0.5


func _fit_background_to_design() -> void:
	var bg := get_node_or_null("WorldRoot/Background/BG") as Sprite2D
	if bg == null or bg.texture == null:
		return
	var texture_size := bg.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale_factor := maxf(Data.DESIGN_SIZE.x / texture_size.x, Data.DESIGN_SIZE.y / texture_size.y)
	bg.centered = true
	bg.position = Data.DESIGN_SIZE * 0.5
	bg.scale = Vector2(scale_factor, scale_factor)


func _on_viewport_size_changed() -> void:
	_fit_world_to_viewport()
	if _viewer != null and _viewer.visible:
		_update_viewer_image()


func _show_message(text: String, duration: float = 1.8) -> void:
	if _message_label == null:
		return
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	if _message_label.get_parent() != null:
		_message_label.get_parent().move_child(_message_label, _message_label.get_parent().get_child_count() - 1)
	_message_label.visible = true
	await get_tree().create_timer(duration).timeout
	if token == _message_token and _message_label != null:
		_message_label.visible = false


func _set_player_locked(locked: bool) -> void:
	if _player != null and _player.has_method("set_controls_locked"):
		_player.set_controls_locked(locked)


func _on_interact_hint_changed(show: bool, hint_text: String) -> void:
	if _interact_hint == null:
		return
	_interact_hint.visible = show
	_interact_hint.text = hint_text


func _play_pickup_sfx() -> void:
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx(SFX_PICKUP, AudioManager.PRIORITY_NORMAL, SFX_PICKUP_VOLUME_DB)


func _state_dict(key: String) -> Dictionary:
	var value = FragmentManager.get_fragment_state(Data.FRAGMENT_ID, key)
	return value.duplicate(true) if value is Dictionary else {}


func _blueprint_label(blueprint_id: String) -> String:
	return str(BLUEPRINT_LABELS.get(blueprint_id, "%s 图纸" % blueprint_id))


func uses_alert_system() -> bool:
	return false


func has_player_for_test() -> bool:
	return _player != null and is_instance_valid(_player)


func open_blueprint_for_test(blueprint_id: String) -> void:
	_open_blueprint(blueprint_id)


func collect_blueprint_for_test(blueprint_id: String) -> void:
	_viewer_blueprint_id = blueprint_id
	_collect_current_blueprint()


func get_blueprint_pages_for_test(blueprint_id: String) -> Array:
	return Data.BLUEPRINT_PAGES.get(blueprint_id, [])


func _start_bgm() -> void:
	if _bgm_stream_0004 == null:
		if ResourceLoader.exists(BGM_PATH_0004):
			_bgm_stream_0004 = load(BGM_PATH_0004) as AudioStream
		else:
			push_warning("[Fragment0004Passage] BGM file not found: %s" % BGM_PATH_0004)
			return
	AudioManager.play_bgm(_bgm_stream_0004, "fragment_0004", 0.45, -10.0, true)
	print("[Fragment0004Passage] BGM started")
