extends Node2D

const Data = preload("res://scripts/fragment/fragment_0004_data.gd")
const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const DIALOGUE_BOX_SCENE: PackedScene = preload("res://scenes/ui/DialogueBox.tscn")
const INTERACTABLE_SCRIPT: Script = preload("res://scripts/fragment/fragment_0004_interactable.gd")
const DESKTOP_SCENE: PackedScene = preload("res://scenes/buildings/id0004/Desktop.tscn")
const CAMERA_RIG_SCRIPT: Script = preload("res://scripts/stage/camera_rig.gd")
const BGM_PATH_0004 := "res://assets/audio/bgm/bgm_fragment_0004_loop.ogg"
var _bgm_stream_0004: AudioStream = null
const SFX_PICKUP := preload("res://assets/audio/sfx/ui_item_pickup.wav")
const SFX_PICKUP_VOLUME_DB: float = -4.0

const DEPTH_LAYER_FADED_ALPHA := 0.25
const DEPTH_LAYER_TRANSITION_SPEED := 4.0
const VIEWER_BLOCK_MSEC := 180
const DESKTOP_STAGE_ZOOM := 0.7
const DESKTOP_BLUEPRINT_THUMB_SIZE := Vector2(96.0, 72.0)
const DESKTOP_BLUEPRINT_THUMB_STEP := 84.0
const DESKTOP_MATERIAL_THUMB_SIZE := Vector2(64.0, 64.0)
const DESKTOP_MATERIAL_THUMB_STEP := Vector2(76.0, 76.0)
const DESKTOP_MATERIAL_THUMB_COLUMNS := 6
const DESKTOP_MATERIAL_THUMB_ORIGIN := Vector2(760.0, 58.0)
const DESKTOP_ANALYZER_FONT_SIZE := 28
const DESKTOP_ANALYZER_OUTLINE_SIZE := 5
const DESKTOP_ANALYZER_LINE_SPACING := 4
const DESKTOP_ANALYZER_FONT_COLOR := Color(1.0, 0.96, 0.78)
const DESKTOP_ANALYZER_OUTLINE_COLOR := Color(0.03, 0.035, 0.02, 0.96)
const DESKTOP_ANALYZER_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.85)
const DESKTOP_ANALYZER_SHADOW_OFFSET := Vector2i(2, 2)
const MAIN_CAMERA_ZOOM := Vector2(1.9, 1.9)
const DESKTOP_STAGE_OFFSET := Vector2(0.0, -72.0)

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _ui_root: CanvasLayer = null
var _interact_hint: Label = null
var _message_label: Label = null
var _message_token: int = 0
var _layer_marker: Marker2D = null
var _depth_layer_1: CanvasItem = null

var _viewer: Control = null
var _viewer_content: Node2D = null
var _viewer_hint: Label = null
var _viewer_block_until_msec: int = 0
var _viewer_open := false

var _desktop: Control = null
var _desktop_stage: Control = null
var _desktop_analyzer: Control = null
var _desktop_analysis_label: Label = null
var _drag_item_id: String = ""
var _drag_item_type: String = ""
var _drag_thumb: TextureRect = null
var _drag_offset_stage := Vector2.ZERO
var _desktop_item_positions: Dictionary = {}

var _preview: Control = null
var _preview_image: TextureRect = null
var _preview_hint: Label = null
var _preview_pages: Array[String] = []
var _preview_page_index := 0
var _bgm_player: AudioStreamPlayer = null
var _completion_started := false


func _enter_tree() -> void:
	add_to_group("fragment_state")


func _ready() -> void:
	_prepare_fragment_context()
	_ensure_state_defaults()
	_ensure_ui()
	_spawn_player()
	_configure_scene_interactions()
	_setup_camera()
	_fit_world_to_viewport()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	SceneFader.fade_in()
	_start_bgm()
	call_deferred("_try_progress_broadcasts")


func _process(delta: float) -> void:
	_update_depth_layer_transparency(delta)


func _input(event: InputEvent) -> void:
	if _preview != null and _preview.visible:
		if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_close_preview()
			get_viewport().set_input_as_handled()
		elif _preview_pages.size() > 1 and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")):
			_flip_preview_page(-1 if event.is_action_pressed("ui_left") else 1)
			get_viewport().set_input_as_handled()
		return

	if _viewer_open:
		if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_close_cabinet_viewer()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Time.get_ticks_msec() >= _viewer_block_until_msec:
				if _collect_material_at_screen_point(event.position):
					get_viewport().set_input_as_handled()
					return

	if _desktop != null and _desktop.visible:
		if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_close_desktop()
			get_viewport().set_input_as_handled()
			return
		if _handle_desktop_drag_input(event):
			get_viewport().set_input_as_handled()
			return


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

	_message_label = _ui_root.get_node_or_null("FragmentMessage") as Label
	if _message_label == null:
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
		_ui_root.add_child(_message_label)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.z_index = 300

	_ensure_cabinet_viewer()
	_ensure_desktop()
	_ensure_preview()


func _spawn_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var player_parent: Node = get_node_or_null("WorldRoot/DepthLayer")
	if player_parent == null:
		player_parent = get_node_or_null("WorldRoot")
	if player_parent == null:
		player_parent = self

	var spawn_marker := _resolve_spawn_marker()
	var spawn_position := spawn_marker.global_position if spawn_marker != null else Data.DESIGN_SIZE * 0.5
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D
	_player.name = "Player"
	player_parent.add_child(_player)
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
	_configure_area_proxy("WorldRoot/Intereaction/Passage", "passage", "走廊")
	for cabinet_name in Data.CABINET_SCENES.keys():
		var cabinet_label := str(Data.CABINET_DISPLAY_NAMES.get(str(cabinet_name), "材料柜"))
		_configure_area_proxy("WorldRoot/Intereaction/%s" % cabinet_name, "cabinet:%s" % cabinet_name, cabinet_label)
	_configure_interactable(get_node_or_null("WorldRoot/DepthLayer/DepthLayer_1/WorkBench"), "desktop", "工作台")


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
	if _player == null:
		return
	var camera_rig := _ensure_camera_rig()
	_camera = camera_rig.get_node_or_null("Camera2D") as Camera2D if camera_rig != null else null
	if _camera == null:
		_camera = Camera2D.new()
		_camera.name = "Camera2D"
		if camera_rig != null:
			camera_rig.add_child(_camera)
		else:
			add_child(_camera)
	_camera.position = Vector2.ZERO
	_camera.offset = Vector2.ZERO
	_camera.enabled = true
	_camera.position_smoothing_enabled = false
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(Data.DESIGN_SIZE.x)
	_camera.limit_bottom = int(Data.DESIGN_SIZE.y)
	_camera.limit_smoothed = false
	_update_camera_zoom()
	_layer_marker = get_node_or_null("WorldRoot/LayerMarker/Layer1_2") as Marker2D
	_depth_layer_1 = get_node_or_null("WorldRoot/DepthLayer/DepthLayer_1") as CanvasItem
	_update_depth_layer_transparency(999.0)
	if camera_rig != null and camera_rig.has_method("snap_to_target"):
		camera_rig.snap_to_target(_player)


func _ensure_camera_rig() -> Node2D:
	var world_root := get_node_or_null("WorldRoot") as Node2D
	if world_root == null:
		return null
	var camera_rig := world_root.get_node_or_null("CameraRig") as Node2D
	if camera_rig == null:
		camera_rig = Node2D.new()
		camera_rig.name = "CameraRig"
		world_root.add_child(camera_rig)
	if camera_rig.get_script() == null:
		camera_rig.set_script(CAMERA_RIG_SCRIPT)
	return camera_rig


func _update_depth_layer_transparency(delta: float) -> void:
	if _depth_layer_1 == null or _player == null or _layer_marker == null:
		return
	var feet := _player.get_node_or_null("FeetMarker Marker2D") as Marker2D
	var feet_y := feet.global_position.y if feet != null else _player.global_position.y
	var target_alpha := DEPTH_LAYER_FADED_ALPHA if feet_y < _layer_marker.global_position.y else 1.0
	_depth_layer_1.modulate.a = move_toward(_depth_layer_1.modulate.a, target_alpha, DEPTH_LAYER_TRANSITION_SPEED * delta)
	_player.modulate.a = 1.0 / maxf(_depth_layer_1.modulate.a, 0.01) if _player.get_parent() == _depth_layer_1 else 1.0


func _update_camera_zoom() -> void:
	if _camera == null:
		return
	_camera.zoom = MAIN_CAMERA_ZOOM


func handle_0004_interaction(action_id: String, _source: Node = null) -> void:
	if _viewer_open or (_desktop != null and _desktop.visible) or (_preview != null and _preview.visible):
		return
	if action_id == "passage":
		SceneManager.change_scene(Data.PASSAGE_SCENE, "Default")
	elif action_id == "desktop":
		_open_desktop()
	elif action_id.begins_with("cabinet:"):
		_open_cabinet(action_id.trim_prefix("cabinet:"))


func handle_npc_interaction(npc: Node2D) -> bool:
	if npc == null or not ("npc_kb_id" in npc):
		return false
	var npc_id := str(npc.npc_kb_id)
	if npc_id not in ["gearleft", "springright"]:
		return false
	ChatDialogue.open(npc, get_0004_npc_greeting(npc_id))
	if ChatDialogue.is_open and npc.has_method("start_dialogue"):
		npc.start_dialogue()
	return true


func get_0004_npc_greeting(npc_id: String) -> String:
	match npc_id:
		"gearleft":
			return _gearleft_guidance()
		"springright":
			return str(Data.SPRINGRIGHT_PROMPTS.get("default", "请输入六个材料编号。"))
		_:
			return "工坊里只剩下纸、金属，和被暂停的呼吸。"


func handle_0004_npc_player_message(npc_id: String, message: String) -> String:
	if npc_id == "springright":
		return _judge_material_combination(message)
	if npc_id == "gearleft":
		return _gearleft_guidance()
	return get_0004_npc_greeting(npc_id)


func _gearleft_guidance() -> String:
	if bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
		return str(Data.GEARLEFT_GUIDANCE.get("solved", "——嘎。合格了。"))
	var blueprint_count := _count_state_entries("collected_blueprints")
	var material_count := _count_state_entries("collected_materials")
	if blueprint_count <= 0:
		return str(Data.GEARLEFT_GUIDANCE.get("need_blueprints", "图纸在楼上。"))
	if blueprint_count < Data.BLUEPRINT_PAGES.size():
		return str(Data.GEARLEFT_GUIDANCE.get("partial_blueprints", "还缺图纸。"))
	if material_count < Data.MATERIAL_DATA.size():
		return str(Data.GEARLEFT_GUIDANCE.get("need_materials", "去材料柜找材料。"))
	return str(Data.GEARLEFT_GUIDANCE.get("ready_for_judgement", "去找弹簧·右提交六个编号。"))


func _judge_material_combination(message: String) -> String:
	if bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
		return str(Data.SPRINGRIGHT_PROMPTS.get("success", "判定：合格。——确定。"))
	var ids := _extract_material_ids(message)
	if ids.size() != Data.CORRECT_COMBINATION.size() or _unique_strings(ids).size() != ids.size():
		_note_wrong_combination()
		return str(Data.SPRINGRIGHT_PROMPTS.get("invalid_count", "判定：不合格。"))
	for id in ids:
		if not Data.MATERIAL_DATA.has(id):
			_note_wrong_combination()
			return str(Data.SPRINGRIGHT_PROMPTS.get("unknown", "判定：不合格。"))
	if _is_correct_combination(ids):
		FragmentManager.set_fragment_state(Data.FRAGMENT_ID, "assembly_solved", true)
		FragmentManager.set_fragment_state(Data.FRAGMENT_ID, "wrong_combination_count", 0)
		_show_pendulum_broadcast("solved")
		return str(Data.SPRINGRIGHT_PROMPTS.get("success", "判定：合格。——确定。"))
	_note_wrong_combination()
	return _combination_hint(ids)


func start_0004_completion_after_dialogue() -> void:
	if _completion_started:
		return
	_completion_started = true
	call_deferred("_run_0004_completion_after_dialogue")


func _run_0004_completion_after_dialogue() -> void:
	while ChatDialogue.is_open and ChatDialogue.has_method("is_streaming_response") and ChatDialogue.is_streaming_response():
		await get_tree().create_timer(0.1).timeout
	if ChatDialogue.is_open:
		await get_tree().create_timer(1.15).timeout
		if ChatDialogue.is_open:
			ChatDialogue.close()
	await SceneFader.fade_out_and_switch(Data.END_SCENE)


func _extract_material_ids(message: String) -> Array[String]:
	var ids: Array[String] = []
	var normalized := message.to_upper()
	for index in range(maxi(0, normalized.length() - 1)):
		var material_id := normalized.substr(index, 2)
		if Data.MATERIAL_DATA.has(material_id):
			ids.append(material_id)
	return ids


func _unique_strings(values: Array[String]) -> Array[String]:
	var seen := {}
	var unique: Array[String] = []
	for value in values:
		if seen.has(value):
			continue
		seen[value] = true
		unique.append(value)
	return unique


func _is_correct_combination(ids: Array[String]) -> bool:
	if ids.size() != Data.CORRECT_COMBINATION.size():
		return false
	for required_id in Data.CORRECT_COMBINATION:
		if not ids.has(str(required_id)):
			return false
	return true


func _note_wrong_combination() -> void:
	var wrong_count := int(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "wrong_combination_count")) + 1
	FragmentManager.set_fragment_state(Data.FRAGMENT_ID, "wrong_combination_count", wrong_count)
	if wrong_count >= 3:
		_show_pendulum_broadcast("repeated_wrong")


func _combination_hint(ids: Array[String]) -> String:
	var required_by_family := {
		"M": ["M3", "heart"],
		"L": ["L3", "head"],
		"T": ["T2", "left_arm"],
		"P": ["P1", "right_arm"],
		"W": ["W2", "left_leg"],
		"B": ["B1", "right_leg"],
	}
	for family in ["M", "L", "T", "P", "W", "B"]:
		var rule: Array = required_by_family[family]
		if not ids.has(str(rule[0])):
			return str(Data.SPRINGRIGHT_PROMPTS.get(str(rule[1]), Data.SPRINGRIGHT_PROMPTS.get("invalid_count", "判定：不合格。")))
	return str(Data.SPRINGRIGHT_PROMPTS.get("invalid_count", "判定：不合格。"))


func _ensure_cabinet_viewer() -> void:
	if _viewer != null:
		return
	_viewer = Control.new()
	_viewer.name = "CabinetViewer"
	_viewer.visible = false
	_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_viewer)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(dim)

	_viewer_hint = Label.new()
	_viewer_hint.name = "Hint"
	_viewer_hint.text = "点击材料收集 | Esc 关闭"
	_viewer_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_viewer_hint.offset_top = -58.0
	_viewer_hint.offset_bottom = -24.0
	_viewer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer_hint.add_theme_font_size_override("font_size", 18)
	_viewer_hint.add_theme_color_override("font_color", Color(0.95, 0.84, 0.58))
	_viewer_hint.add_theme_constant_override("outline_size", 3)
	_viewer_hint.z_index = 100
	_viewer.add_child(_viewer_hint)


func _open_cabinet(cabinet_name: String) -> void:
	var scene_path := str(Data.CABINET_SCENES.get(cabinet_name, ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("[Fragment0004] Missing cabinet scene: %s" % cabinet_name)
		return
	_clear_cabinet_content()
	_viewer_content = load(scene_path).instantiate() as Node2D
	_viewer_content.name = "CabinetContent"
	_viewer.add_child(_viewer_content)
	_configure_material_areas(_viewer_content)
	_fit_node2d_content_to_view(_viewer_content)
	_viewer.move_child(_viewer_hint, _viewer.get_child_count() - 1)
	_viewer_block_until_msec = Time.get_ticks_msec() + VIEWER_BLOCK_MSEC
	_viewer.visible = true
	_viewer_open = true
	_set_player_locked(true)


func _clear_cabinet_content() -> void:
	if _viewer_content != null and is_instance_valid(_viewer_content):
		_viewer_content.queue_free()
	_viewer_content = null


func _configure_material_areas(root: Node) -> void:
	for child in root.get_children():
		if child is Area2D:
			var area := child as Area2D
			area.collision_layer = 2
			area.collision_mask = 0
			area.monitoring = true
			area.monitorable = true
			area.input_pickable = true
			if not area.input_event.is_connected(_on_material_area_input_event):
				area.input_event.connect(_on_material_area_input_event.bind(area))
		_configure_material_areas(child)


func _on_material_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, area: Area2D) -> void:
	if not _viewer_open or Time.get_ticks_msec() < _viewer_block_until_msec:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_collect_material(str(area.name))
		get_viewport().set_input_as_handled()


func _collect_material_at_screen_point(screen_point: Vector2) -> bool:
	if _viewer_content == null:
		return false
	for area in _find_areas(_viewer_content):
		if _area_contains_screen_point(area, screen_point):
			_collect_material(str(area.name))
			return true
	return false


func _collect_material(material_id: String) -> void:
	if not Data.MATERIAL_DATA.has(material_id):
		return
	var collected := _state_dict("collected_materials")
	var first_time := int(collected.get(material_id, 0)) == 0
	if first_time:
		collected[material_id] = 1
		FragmentManager.set_fragment_state(Data.FRAGMENT_ID, "collected_materials", collected)
		_play_pickup_sfx()
	_show_message("已收集材料：%s" % Data.material_label(material_id) if first_time else "这个材料已经收集过了：%s" % Data.material_label(material_id))
	_try_progress_broadcasts()


func _close_cabinet_viewer() -> void:
	_viewer.visible = false
	_viewer_open = false
	_clear_cabinet_content()
	_set_player_locked(false)


func _fit_node2d_content_to_view(node: Node2D) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Data.DESIGN_SIZE
	var bounds := _get_node2d_bounds(node)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		node.position = viewport_size * 0.5
		node.scale = Vector2.ONE
		return
	var max_size := viewport_size * 0.9
	var scale_factor := minf(max_size.x / bounds.size.x, max_size.y / bounds.size.y)
	node.scale = Vector2(scale_factor, scale_factor)
	node.position = viewport_size * 0.5 - (bounds.position + bounds.size * 0.5) * scale_factor


func _get_node2d_bounds(root: Node) -> Rect2:
	var has_rect := false
	var rect := Rect2()
	for child in root.get_children():
		var child_rect := Rect2()
		var valid := false
		if child is Sprite2D:
			var sprite := child as Sprite2D
			if sprite.texture != null:
				var size := sprite.texture.get_size()
				var origin := sprite.position - size * 0.5 if sprite.centered else sprite.position
				child_rect = Rect2(origin, size).abs()
				valid = true
		elif child is CollisionPolygon2D:
			var polygon := child as CollisionPolygon2D
			for point in polygon.polygon:
				var local_point := polygon.transform * point
				if not valid:
					child_rect = Rect2(local_point, Vector2.ZERO)
					valid = true
				else:
					child_rect = child_rect.expand(local_point)
		elif child is CollisionShape2D:
			var shape_node := child as CollisionShape2D
			if shape_node.shape is RectangleShape2D:
				var half_size := (shape_node.shape as RectangleShape2D).size * 0.5
				child_rect = Rect2(shape_node.position - half_size, half_size * 2.0)
				valid = true
		var nested := _get_node2d_bounds(child)
		if nested.size.x > 0.0 and nested.size.y > 0.0:
			child_rect = child_rect.merge(nested) if valid else nested
			valid = true
		if valid:
			rect = rect.merge(child_rect) if has_rect else child_rect
			has_rect = true
	return rect if has_rect else Rect2()


func _area_contains_screen_point(area: Area2D, screen_point: Vector2) -> bool:
	for child in area.get_children():
		if child is CollisionPolygon2D:
			var polygon := child as CollisionPolygon2D
			var local_point := polygon.get_global_transform_with_canvas().affine_inverse() * screen_point
			if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
				return true
		elif child is CollisionShape2D:
			var shape_node := child as CollisionShape2D
			var shape := shape_node.shape
			var local_point := shape_node.get_global_transform_with_canvas().affine_inverse() * screen_point
			if shape is RectangleShape2D:
				var half_size := (shape as RectangleShape2D).size * 0.5
				if absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y:
					return true
	return false


func _find_areas(root: Node) -> Array[Area2D]:
	var areas: Array[Area2D] = []
	for child in root.get_children():
		if child is Area2D:
			areas.append(child as Area2D)
		areas.append_array(_find_areas(child))
	return areas


func _ensure_desktop() -> void:
	if _desktop != null:
		return
	_desktop = Control.new()
	_desktop.name = "DesktopOverlay"
	_desktop.visible = false
	_desktop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desktop.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_desktop)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.008, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desktop.add_child(dim)

	_desktop_stage = Control.new()
	_desktop_stage.name = "Stage"
	_desktop_stage.size = Data.DESIGN_SIZE
	_desktop_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desktop.add_child(_desktop_stage)

	var desktop_content := DESKTOP_SCENE.instantiate()
	desktop_content.name = "DesktopContent"
	_desktop_stage.add_child(desktop_content)
	_configure_desktop_analyzer(desktop_content)
	if _desktop_analysis_label == null:
		return

	_desktop_analysis_label.text = "将材料拖入分析仪"

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "拖拽图纸/材料 | 材料拖入分析仪 | 双击查看 | Esc 关闭"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -48.0
	hint.offset_bottom = -18.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.95, 0.84, 0.58))
	hint.add_theme_constant_override("outline_size", 3)
	_desktop.add_child(hint)
	_layout_desktop_to_viewport()


func _configure_desktop_analyzer(desktop_content: Node) -> void:
	_desktop_analysis_label = desktop_content.get_node_or_null("Pad/Control/Label") as Label
	if _desktop_analysis_label == null:
		push_warning("[Fragment0004] Desktop Pad analyzer Label not found.")
		return
	_desktop_analyzer = _desktop_analysis_label
	_desktop_analysis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desktop_analysis_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_desktop_analysis_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_desktop_analysis_label.add_theme_font_size_override("font_size", DESKTOP_ANALYZER_FONT_SIZE)
	_desktop_analysis_label.add_theme_color_override("font_color", DESKTOP_ANALYZER_FONT_COLOR)
	_desktop_analysis_label.add_theme_color_override("font_outline_color", DESKTOP_ANALYZER_OUTLINE_COLOR)
	_desktop_analysis_label.add_theme_color_override("font_shadow_color", DESKTOP_ANALYZER_SHADOW_COLOR)
	_desktop_analysis_label.add_theme_constant_override("outline_size", DESKTOP_ANALYZER_OUTLINE_SIZE)
	_desktop_analysis_label.add_theme_constant_override("line_spacing", DESKTOP_ANALYZER_LINE_SPACING)
	_desktop_analysis_label.add_theme_constant_override("shadow_offset_x", DESKTOP_ANALYZER_SHADOW_OFFSET.x)
	_desktop_analysis_label.add_theme_constant_override("shadow_offset_y", DESKTOP_ANALYZER_SHADOW_OFFSET.y)
	_desktop_analysis_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _open_desktop() -> void:
	_refresh_desktop_items()
	_layout_desktop_to_viewport()
	_desktop.visible = true
	_set_player_locked(true)
	_try_progress_broadcasts()


func _close_desktop() -> void:
	_clear_desktop_drag()
	_desktop.visible = false
	_set_player_locked(false)


func _refresh_desktop_items() -> void:
	_clear_desktop_drag()
	for child in _desktop_stage.get_children():
		if str(child.name).begins_with("BlueprintThumb_") or str(child.name).begins_with("MaterialThumb_"):
			_desktop_stage.remove_child(child)
			child.queue_free()
	var blueprints := _state_dict("collected_blueprints")
	var materials := _state_dict("collected_materials")
	var blueprint_ids := blueprints.keys()
	blueprint_ids.sort()
	var material_ids := materials.keys()
	material_ids.sort()

	var index := 0
	for blueprint_id in blueprint_ids:
		if int(blueprints[blueprint_id]) != 1:
			continue
		var pages: Array = Data.BLUEPRINT_PAGES.get(str(blueprint_id), [])
		if pages.is_empty():
			continue
		var thumb := _create_thumb(
			str(blueprint_id),
			"blueprint",
			str(pages[0]),
			Vector2(78, 82 + index * DESKTOP_BLUEPRINT_THUMB_STEP),
			DESKTOP_BLUEPRINT_THUMB_SIZE
		)
		thumb.name = "BlueprintThumb_%s" % blueprint_id
		index += 1

	index = 0
	for material_id in material_ids:
		if int(materials[material_id]) != 1:
			continue
		var texture_path := str(Data.MATERIAL_TEXTURES.get(str(material_id), ""))
		if texture_path.is_empty():
			continue
		var col := index % DESKTOP_MATERIAL_THUMB_COLUMNS
		var row := index / DESKTOP_MATERIAL_THUMB_COLUMNS
		var thumb := _create_thumb(
			str(material_id),
			"material",
			texture_path,
			DESKTOP_MATERIAL_THUMB_ORIGIN + Vector2(col * DESKTOP_MATERIAL_THUMB_STEP.x, row * DESKTOP_MATERIAL_THUMB_STEP.y),
			DESKTOP_MATERIAL_THUMB_SIZE
		)
		thumb.name = "MaterialThumb_%s" % material_id
		index += 1


func _create_thumb(item_id: String, item_type: String, texture_path: String, position: Vector2, size: Vector2) -> TextureRect:
	var thumb := TextureRect.new()
	var texture := load(texture_path) as Texture2D if ResourceLoader.exists(texture_path) else null
	thumb.texture = texture
	var position_key := _desktop_position_key(item_id, item_type)
	thumb.position = _desktop_item_positions.get(position_key, position)
	thumb.custom_minimum_size = size
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_SCALE
	if texture != null and texture.get_size().x > 0.0 and texture.get_size().y > 0.0:
		thumb.size = texture.get_size()
		thumb.scale = size / texture.get_size()
	else:
		thumb.size = size
		thumb.scale = Vector2.ONE
	thumb.mouse_filter = Control.MOUSE_FILTER_STOP
	thumb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	thumb.set_meta("item_id", item_id)
	thumb.set_meta("item_type", item_type)
	thumb.gui_input.connect(_on_desktop_thumb_gui_input.bind(thumb))
	_desktop_stage.add_child(thumb)
	return thumb


func _on_desktop_thumb_gui_input(event: InputEvent, thumb: TextureRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			_open_item_preview(str(thumb.get_meta("item_type", "")), str(thumb.get_meta("item_id", "")))
			get_viewport().set_input_as_handled()
			return
		if event.pressed:
			_begin_item_drag(thumb)
			get_viewport().set_input_as_handled()


func _begin_item_drag(thumb: TextureRect) -> void:
	_clear_desktop_drag()
	_drag_thumb = thumb
	_drag_item_id = str(thumb.get_meta("item_id", ""))
	_drag_item_type = str(thumb.get_meta("item_type", ""))
	var stage_mouse := _screen_to_desktop_stage_position(get_viewport().get_mouse_position())
	_drag_offset_stage = stage_mouse - thumb.position
	thumb.z_index = 50
	_desktop_stage.move_child(thumb, _desktop_stage.get_child_count() - 1)


func _handle_desktop_drag_input(event: InputEvent) -> bool:
	if _drag_thumb == null or not is_instance_valid(_drag_thumb):
		return false
	if event is InputEventMouseMotion:
		_drag_thumb.position = _screen_to_desktop_stage_position(event.position) - _drag_offset_stage
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var dropped := _is_screen_point_inside_control(_desktop_analyzer, event.position)
		if dropped and _drag_item_type == "material":
			_analyze_material(_drag_item_id)
		_remember_desktop_thumb_position()
		_clear_desktop_drag()
		return true
	return false


func _clear_desktop_drag() -> void:
	if _drag_thumb != null and is_instance_valid(_drag_thumb):
		_drag_thumb.z_index = 0
	_drag_thumb = null
	_drag_item_id = ""
	_drag_item_type = ""
	_drag_offset_stage = Vector2.ZERO


func _remember_desktop_thumb_position() -> void:
	if _drag_thumb == null or not is_instance_valid(_drag_thumb):
		return
	_desktop_item_positions[_desktop_position_key(_drag_item_id, _drag_item_type)] = _drag_thumb.position


func _desktop_position_key(item_id: String, item_type: String) -> String:
	return "%s:%s" % [item_type, item_id]


func _screen_to_desktop_stage_position(screen_position: Vector2) -> Vector2:
	if _desktop_stage == null:
		return screen_position
	return _desktop_stage.get_global_transform_with_canvas().affine_inverse() * screen_position


func _is_screen_point_inside_control(control: Control, screen_position: Vector2) -> bool:
	if control == null:
		return false
	var local_point := control.get_global_transform_with_canvas().affine_inverse() * screen_position
	return Rect2(Vector2.ZERO, control.size).has_point(local_point)


func _analyze_material(material_id: String) -> void:
	if _desktop_analysis_label == null:
		return
	_desktop_analysis_label.text = Data.material_parameters_text(material_id)
	_show_pendulum_broadcast("first_analysis")


func _ensure_preview() -> void:
	if _preview != null:
		return
	_preview = Control.new()
	_preview.name = "ItemPreview"
	_preview.visible = false
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_preview)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(dim)

	_preview_image = TextureRect.new()
	_preview_image.name = "Image"
	_preview_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(_preview_image)

	_preview_hint = Label.new()
	_preview_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_preview_hint.offset_top = -58.0
	_preview_hint.offset_bottom = -24.0
	_preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_hint.add_theme_font_size_override("font_size", 18)
	_preview_hint.add_theme_color_override("font_color", Color(0.95, 0.84, 0.58))
	_preview_hint.add_theme_constant_override("outline_size", 3)
	_preview.add_child(_preview_hint)


func _open_item_preview(item_type: String, item_id: String) -> void:
	if item_type == "blueprint":
		_preview_pages = []
		for path in Data.BLUEPRINT_PAGES.get(item_id, []):
			_preview_pages.append(str(path))
	else:
		_preview_pages = [str(Data.MATERIAL_TEXTURES.get(item_id, ""))]
	_preview_pages = _preview_pages.filter(func(path: String) -> bool: return ResourceLoader.exists(path))
	if _preview_pages.is_empty():
		return
	_preview_page_index = 0
	_update_preview_image()
	_preview.visible = true


func _flip_preview_page(delta: int) -> void:
	if _preview_pages.is_empty():
		return
	_preview_page_index = posmod(_preview_page_index + delta, _preview_pages.size())
	_update_preview_image()


func _update_preview_image() -> void:
	var texture := load(_preview_pages[_preview_page_index]) as Texture2D
	_preview_image.texture = texture
	var viewport_size := get_viewport_rect().size
	var max_size := viewport_size * Vector2(0.68, 0.62)
	var scale_factor := minf(0.82, minf(max_size.x / texture.get_size().x, max_size.y / texture.get_size().y))
	_preview_image.size = texture.get_size() * scale_factor
	_preview_image.position = (viewport_size - _preview_image.size) * 0.5
	_preview_hint.text = "A/D 或 ←/→ 翻页 | Esc 关闭" if _preview_pages.size() > 1 else "Esc 关闭"


func _close_preview() -> void:
	_preview.visible = false


func _layout_desktop_to_viewport() -> void:
	if _desktop_stage == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Data.DESIGN_SIZE
	var scale_factor := maxf(viewport_size.x / Data.DESIGN_SIZE.x, viewport_size.y / Data.DESIGN_SIZE.y) * DESKTOP_STAGE_ZOOM
	var scaled_size := Data.DESIGN_SIZE * scale_factor
	_desktop_stage.position = (viewport_size - scaled_size) * 0.5 + DESKTOP_STAGE_OFFSET
	_desktop_stage.scale = Vector2(scale_factor, scale_factor)


func _on_viewport_size_changed() -> void:
	_fit_world_to_viewport()
	_update_camera_zoom()
	_layout_desktop_to_viewport()
	if _viewer_open and _viewer_content != null:
		_fit_node2d_content_to_view(_viewer_content)
	if _preview != null and _preview.visible:
		_update_preview_image()


func _fit_world_to_viewport() -> void:
	var world_root := get_node_or_null("WorldRoot") as Node2D
	if world_root == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Data.DESIGN_SIZE
	world_root.scale = Vector2.ONE
	world_root.position = Vector2.ZERO


func _show_message(text: String, duration: float = 2.0) -> void:
	if _message_label == null:
		return
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	if _message_label.get_parent() != null:
		_message_label.get_parent().move_child(_message_label, _message_label.get_parent().get_child_count() - 1)
	_message_label.visible = true
	await get_tree().create_timer(duration).timeout
	if token == _message_token and _message_label != null and is_instance_valid(_message_label):
		_message_label.visible = false


func _set_player_locked(locked: bool) -> void:
	if _player != null and _player.has_method("set_controls_locked"):
		_player.set_controls_locked(locked)


func _on_interact_hint_changed(show: bool, hint_text: String) -> void:
	if _interact_hint == null:
		return
	_interact_hint.visible = show
	_interact_hint.text = hint_text


func _state_dict(key: String) -> Dictionary:
	var value = FragmentManager.get_fragment_state(Data.FRAGMENT_ID, key)
	return value.duplicate(true) if value is Dictionary else {}


func _count_state_entries(key: String) -> int:
	var state := _state_dict(key)
	var count := 0
	for entry_key in state.keys():
		if int(state.get(entry_key, 0)) == 1:
			count += 1
	return count


func _try_progress_broadcasts() -> void:
	if bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
		return
	if _count_state_entries("collected_blueprints") >= Data.BLUEPRINT_PAGES.size():
		_show_pendulum_broadcast("blueprints_ready")
	else:
		_show_pendulum_broadcast("intro")


func _show_pendulum_broadcast(key: String) -> void:
	var broadcasts := _state_dict("pendulum_broadcasts")
	if bool(broadcasts.get(key, false)):
		return
	var text := str(Data.PENDULUM_BROADCASTS.get(key, ""))
	if text.is_empty():
		return
	broadcasts[key] = true
	FragmentManager.set_fragment_state(Data.FRAGMENT_ID, "pendulum_broadcasts", broadcasts)
	_show_message(text, 3.2)


func uses_alert_system() -> bool:
	return false


func is_completion_started_for_test() -> bool:
	return _completion_started


func has_player_for_test() -> bool:
	return _player != null and is_instance_valid(_player)


func get_material_data_for_test() -> Dictionary:
	return Data.MATERIAL_DATA


func collect_material_for_test(material_id: String) -> void:
	_collect_material(material_id)


func open_cabinet_for_test(cabinet_name: String) -> void:
	_open_cabinet(cabinet_name)


func open_desktop_for_test() -> void:
	_open_desktop()


func analyze_material_for_test(material_id: String) -> void:
	_analyze_material(material_id)


func _play_pickup_sfx() -> void:
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx(SFX_PICKUP, AudioManager.PRIORITY_NORMAL, SFX_PICKUP_VOLUME_DB)


func get_analysis_text_for_test() -> String:
	return _desktop_analysis_label.text if _desktop_analysis_label != null else ""


func get_analyzer_font_size_for_test() -> int:
	return DESKTOP_ANALYZER_FONT_SIZE


func get_analyzer_outline_size_for_test() -> int:
	return DESKTOP_ANALYZER_OUTLINE_SIZE


func get_material_thumb_layout_for_test() -> Dictionary:
	var layout := {}
	if _desktop_stage == null:
		return layout
	for child in _desktop_stage.get_children():
		if not str(child.name).begins_with("MaterialThumb_"):
			continue
		if child is TextureRect:
			var thumb := child as TextureRect
			layout[str(thumb.get_meta("item_id", ""))] = {
				"position": thumb.position,
				"visual_size": DESKTOP_MATERIAL_THUMB_SIZE,
			}
	return layout


func get_cabinet_display_name_for_test(cabinet_name: String) -> String:
	var proxy := get_node_or_null("WorldRoot/Intereaction/%sProxy" % cabinet_name)
	if proxy != null and "display_name" in proxy:
		return str(proxy.display_name)
	return ""


func judge_material_combination_for_test(message: String) -> String:
	return _judge_material_combination(message)


func get_fragment_state_value_for_test(key: String):
	return FragmentManager.get_fragment_state(Data.FRAGMENT_ID, key)


func get_depth_layer_alpha_for_test() -> float:
	return _depth_layer_1.modulate.a if _depth_layer_1 != null else -1.0


func _start_bgm() -> void:
	if _bgm_stream_0004 == null:
		if ResourceLoader.exists(BGM_PATH_0004):
			_bgm_stream_0004 = load(BGM_PATH_0004) as AudioStream
		else:
			push_warning("[Fragment0004] BGM file not found: %s" % BGM_PATH_0004)
			return
	AudioManager.play_bgm(_bgm_stream_0004, "fragment_0004", 0.45, -10.0, true)
	print("[Fragment0004] BGM started")


func _stop_bgm() -> void:
	AudioManager.stop_bgm(0.25)
	print("[Fragment0004] BGM stopped")
