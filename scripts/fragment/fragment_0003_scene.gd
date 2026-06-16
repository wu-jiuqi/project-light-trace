extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const DIALOGUE_BOX_SCENE: PackedScene = preload("res://scenes/ui/DialogueBox.tscn")
const CLUE_PANEL_SCENE: PackedScene = preload("res://scenes/ui/CluePanel.tscn")
const INTERACTABLE_SCRIPT: Script = preload("res://scripts/fragment/fragment_0003_interactable.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const PLAYER_VISUAL_SCALE := Vector2(2.2, 2.2)
const DEPTH_LAYER_FADED_ALPHA := 0.2
const DEPTH_LAYER_TRANSITION_SPEED := 4.0
const FRAGMENT_ID := "0003"
const MAIN_SCENE := "res://scenes/fragments/fragment_0003.tscn"
const LOFT_SCENE := "res://scenes/rooms/id0003/loft.tscn"
const END_SCENE := "res://scenes/cinematic/fragment_0003_end.tscn"
const BOX_CLOSED_TEXTURE := "res://assets/papercraft/fragments/id0003/environment/box_02.png"
const BOX_OPEN_TEXTURE := "res://assets/papercraft/fragments/id0003/environment/box_01.png"
const JADE_TEXTURE := "res://assets/papercraft/fragments/id0003/environment/jade.png"
const BGM_FRAGMENT_0003 = preload("res://assets/audio/0003.mp3")

const STEP_ORDER: Array[String] = ["wash", "burn", "offer", "clap", "moon"]
const STEP_STATE_KEYS := {
	"wash": "wash_hands",
	"burn": "lantern_lit",
	"offer": "jade_offered",
	"clap": "clapped",
	"moon": "moon_viewed",
}
const STEP_NAMES := {
	"wash": "净手",
	"burn": "燃灯",
	"offer": "献玉",
	"clap": "击掌",
	"moon": "望月",
}
const STEP_HINTS := {
	"wash": "尘意未去，水声仍在等你。去净一净手，再试一次。",
	"burn": "水已洗去尘意，路旁的字还缺一点光。去灯下再试试。",
	"offer": "灯已认得你的手，井中的月却仍在等一件旧物。再去试试。",
	"clap": "井水收下了祭物，石前仍缺一声回应。再去试试。",
	"moon": "掌声已经散去，天上的月还没有被真正望见。再去试试。",
}
const INSCRIPTION_CHARS := {
	"L1": "净", "L2": "手", "L3": "燃", "L4": "灯",
	"L5": "献", "L6": "玉", "L7": "击", "L8": "掌",
	"L9": "望", "L10": "月", "L11": "启", "L12": "镜",
}
const INSCRIPTION_TEXTURES := {
	"L1": "res://assets/papercraft/fragments/id0003/environment/jing.png",
	"L2": "res://assets/papercraft/fragments/id0003/environment/shou.png",
	"L3": "res://assets/papercraft/fragments/id0003/environment/ran.png",
	"L4": "res://assets/papercraft/fragments/id0003/environment/deng.png",
	"L5": "res://assets/papercraft/fragments/id0003/environment/xian.png",
	"L6": "res://assets/papercraft/fragments/id0003/environment/yu.png",
	"L7": "res://assets/papercraft/fragments/id0003/environment/ji.png",
	"L8": "res://assets/papercraft/fragments/id0003/environment/zhang.png",
	"L9": "res://assets/papercraft/fragments/id0003/environment/wang.png",
	"L10": "res://assets/papercraft/fragments/id0003/environment/yue.png",
	"L11": "res://assets/papercraft/fragments/id0003/environment/qi.png",
	"L12": "res://assets/papercraft/fragments/id0003/environment/jing2.png",
}

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _layer_marker: Marker2D = null
var _depth_layer_1: CanvasItem = null
var _ui_root: CanvasLayer = null
var _interact_hint: Label = null
var _clue_panel: CluePanel = null
var _message_label: Label = null
var _message_token: int = 0
var _viewer: Control = null
var _viewer_image: TextureRect = null
var _viewer_hint: Label = null
var _viewer_mode: String = ""
var _viewer_id: String = ""
var _viewer_ready_to_collect := false
var _viewer_block_until_msec := 0
var _pending_ritual_reset := false
var _completion_started := false
var _lantern_material: ShaderMaterial = null
var _lantern_glow_material: CanvasItemMaterial = null
var _bgm_player: AudioStreamPlayer = null


func _enter_tree() -> void:
	add_to_group("fragment_state")


func _ready() -> void:
	_prepare_fragment_context()
	_ensure_state_defaults()
	_ensure_ui()
	_spawn_player()
	_configure_scene_interactions()
	_restore_scene_visuals()
	_setup_camera()
	_apply_lantern_state()
	_fit_world_to_viewport()
	if not get_viewport().size_changed.is_connected(_fit_world_to_viewport):
		get_viewport().size_changed.connect(_fit_world_to_viewport)
	if not ChatDialogue.dialogue_closed.is_connected(_on_dialogue_closed):
		ChatDialogue.dialogue_closed.connect(_on_dialogue_closed)
	SceneFader.fade_in()
	_start_bgm()


func _process(delta: float) -> void:
	_update_camera_zoom()
	_update_depth_layer_transparency(delta)


func _input(event: InputEvent) -> void:
	if _viewer != null and _viewer.visible:
		if event.is_action_pressed("interact") and Time.get_ticks_msec() >= _viewer_block_until_msec:
			_collect_from_viewer()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_close_viewer()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_focus_next") and not ChatDialogue.is_open:
		_toggle_clue_panel()
		get_viewport().set_input_as_handled()


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null or FragmentManager.current_fragment.id != FRAGMENT_ID:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id(FRAGMENT_ID)
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _ensure_state_defaults() -> void:
	var defaults := {
		"jade_collected": 0,
		"jade_gallery_collected": 0,
		"wash_hands": 0,
		"lantern_lit": 0,
		"jade_offered": 0,
		"clapped": 0,
		"moon_viewed": 0,
		"mirror_opened": 0,
		"ritual_sequence": [],
		"ritual_sequence_invalid": false,
		"inscription_order": [],
		"completed": false,
	}
	for key in defaults:
		if FragmentManager.get_fragment_state(FRAGMENT_ID, key) == null:
			FragmentManager.set_fragment_state(FRAGMENT_ID, key, defaults[key])


func _ensure_ui() -> void:
	_ui_root = get_node_or_null("UIRoot") as CanvasLayer
	if _ui_root == null:
		_ui_root = CanvasLayer.new()
		_ui_root.name = "UIRoot"
		add_child(_ui_root)

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
		_interact_hint.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
		_interact_hint.add_theme_constant_override("outline_size", 3)
		_ui_root.add_child(_interact_hint)

	_clue_panel = _ui_root.get_node_or_null("CluePanel") as CluePanel
	if _clue_panel == null:
		_clue_panel = CLUE_PANEL_SCENE.instantiate() as CluePanel
		_clue_panel.name = "CluePanel"
		_clue_panel.visible = false
		_ui_root.add_child(_clue_panel)

	_message_label = Label.new()
	_message_label.name = "FragmentMessage"
	_message_label.visible = false
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.position = Vector2(-360, 210)
	_message_label.size = Vector2(720, 70)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 24)
	_message_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.72))
	_message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_message_label.add_theme_constant_override("shadow_offset_x", 2)
	_message_label.add_theme_constant_override("shadow_offset_y", 2)
	_ui_root.add_child(_message_label)
	_ensure_viewer()


func _ensure_viewer() -> void:
	if _viewer != null:
		return
	_viewer = Control.new()
	_viewer.name = "CollectionViewer"
	_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer.visible = false
	_ui_root.add_child(_viewer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.01, 0.015, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer.add_child(dim)

	_viewer_image = TextureRect.new()
	_viewer_image.set_anchors_preset(Control.PRESET_CENTER)
	_viewer_image.position = Vector2(-460, -285)
	_viewer_image.size = Vector2(920, 540)
	_viewer_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(_viewer_image)

	_viewer_hint = Label.new()
	_viewer_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_viewer_hint.offset_top = -72.0
	_viewer_hint.offset_bottom = -28.0
	_viewer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer_hint.add_theme_font_size_override("font_size", 22)
	_viewer_hint.add_theme_color_override("font_color", Color(0.95, 0.82, 0.58))
	_viewer_hint.add_theme_constant_override("outline_size", 3)
	_viewer.add_child(_viewer_hint)


func _spawn_player() -> void:
	if _player != null:
		return
	var world_root := get_node_or_null("WorldRoot") as Node2D
	var player_parent: Node = get_node_or_null("WorldRoot/DepthLayer")
	if player_parent == null:
		player_parent = world_root if world_root != null else self

	var spawn_marker := _resolve_spawn_marker()
	var spawn_position := spawn_marker.global_position if spawn_marker != null else DESIGN_SIZE * 0.5
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D
	_player.name = "Player"
	player_parent.add_child(_player)
	var visual_root := _player.get_node_or_null("Visual Node2D") as Node2D
	if visual_root != null:
		visual_root.scale = PLAYER_VISUAL_SCALE
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
	if name == "Loft":
		_configure_interactable(get_node_or_null("WorldRoot/LoftExit"), "exit_loft", "返回参道")
		_configure_interactable(get_node_or_null("WorldRoot/Box"), "box", "木盒")
		_configure_interactable(get_node_or_null("WorldRoot/StoneTip"), "clap", "石碑")
		return

	_configure_interactable(get_node_or_null("WorldRoot/DepthLayer/DepthLayer_2/WashHands"), "wash", "净手")
	_configure_interactable(get_node_or_null("WorldRoot/DepthLayer/DepthLayer_3/AncientWell"), "well", "古井")
	for lamp_name in INSCRIPTION_CHARS:
		var lamp := find_child(lamp_name, true, false) as Node2D
		_configure_interactable(lamp, "inscription:%s" % lamp_name, "石灯刻字")
	_configure_jump_area()
	_configure_moon_area()


func _restore_scene_visuals() -> void:
	if name != "Loft":
		return
	var box := get_node_or_null("WorldRoot/Box") as Node2D
	if box != null:
		box.visible = _state_int("jade_collected") == 0


func _configure_interactable(node: Node, action_id: String, label: String) -> void:
	if node == null:
		return
	if node.get_script() == null:
		node.set_script(INTERACTABLE_SCRIPT)
	if node.has_method("configure"):
		node.configure(action_id, label)


func _configure_jump_area() -> void:
	var area := get_node_or_null("WorldRoot/Interaction/JumpInteractionArea") as Area2D
	if area == null:
		return
	var proxy := Node2D.new()
	proxy.name = "JumpToLoft"
	area.get_parent().add_child(proxy)
	area.reparent(proxy, true)
	_configure_interactable(proxy, "enter_loft", "进入阁楼")


func _configure_moon_area() -> void:
	var area := get_node_or_null("WorldRoot/Interaction/MoonInteractionArea") as Area2D
	if area == null:
		return
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = true
	area.monitorable = true
	area.input_pickable = true
	if not area.input_event.is_connected(_on_moon_input_event):
		area.input_event.connect(_on_moon_input_event)


func _setup_camera() -> void:
	if _player == null:
		return
	_camera = get_node_or_null("WorldRoot/CameraRig/Camera2D") as Camera2D
	if _camera == null:
		_camera = Camera2D.new()
		_camera.name = "Camera2D"
		_player.add_child(_camera)
	else:
		_camera.reparent(_player, false)
	_camera.position = Vector2.ZERO
	_camera.enabled = true
	_camera.position_smoothing_enabled = false
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = 1280
	_camera.limit_bottom = 720
	_camera.limit_smoothed = false
	_layer_marker = get_node_or_null("WorldRoot/LayerMarker/Layer1_2") as Marker2D
	_depth_layer_1 = get_node_or_null("WorldRoot/DepthLayer/DepthLayer_1") as CanvasItem
	_update_camera_zoom()
	_update_depth_layer_transparency(999.0)


func _update_camera_zoom() -> void:
	if _camera == null or _player == null:
		return
	var target_zoom := 0.8
	if _layer_marker != null:
		var feet := _player.get_node_or_null("FeetMarker Marker2D") as Marker2D
		var feet_y := feet.global_position.y if feet != null else _player.global_position.y
		target_zoom = 1.1 if feet_y < _layer_marker.global_position.y else 0.8
	_camera.zoom = Vector2(target_zoom, target_zoom)


func _update_depth_layer_transparency(delta: float) -> void:
	if _depth_layer_1 == null or _player == null or _layer_marker == null:
		return
	var feet := _player.get_node_or_null("FeetMarker Marker2D") as Marker2D
	var feet_y := feet.global_position.y if feet != null else _player.global_position.y
	var target_alpha := DEPTH_LAYER_FADED_ALPHA if feet_y < _layer_marker.global_position.y else 1.0
	_depth_layer_1.modulate.a = move_toward(
		_depth_layer_1.modulate.a,
		target_alpha,
		DEPTH_LAYER_TRANSITION_SPEED * delta
	)


func handle_0003_interaction(action_id: String, _source: Node = null) -> void:
	if _completion_started or (_viewer != null and _viewer.visible):
		return
	if action_id.begins_with("inscription:"):
		_open_inscription(action_id.trim_prefix("inscription:"))
		return
	match action_id:
		"enter_loft":
			SceneManager.change_scene(LOFT_SCENE, "Default")
		"exit_loft":
			SceneManager.change_scene(MAIN_SCENE, "FromLoft")
		"box":
			_open_box()
		"wash":
			_attempt_ritual_step("wash")
		"clap":
			_attempt_ritual_step("clap")
		"well":
			_interact_with_well()


func _open_inscription(lamp_id: String) -> void:
	var texture_path := str(INSCRIPTION_TEXTURES.get(lamp_id, ""))
	if texture_path.is_empty():
		return
	_open_viewer(texture_path, "inscription", lamp_id, "按 E 收集刻字 | 按 Esc 关闭")


func _open_box() -> void:
	if _state_int("jade_collected") == 1:
		_show_message("木盒已经空了。")
		return
	_open_viewer(BOX_CLOSED_TEXTURE, "box", "Box", "木盒正在开启……")
	_viewer_ready_to_collect = false
	_reveal_box_contents()


func _reveal_box_contents() -> void:
	await get_tree().create_timer(0.5).timeout
	if _viewer == null or not _viewer.visible or _viewer_mode != "box":
		return
	_viewer_image.texture = load(BOX_OPEN_TEXTURE) as Texture2D
	_viewer_hint.text = "按 E 收集玉 | 按 Esc 关闭"
	_viewer_ready_to_collect = true


func _open_viewer(texture_path: String, mode: String, item_id: String, hint: String) -> void:
	if not ResourceLoader.exists(texture_path):
		push_warning("[Fragment0003] Missing viewer texture: %s" % texture_path)
		return
	_viewer_image.texture = load(texture_path) as Texture2D
	_viewer_mode = mode
	_viewer_id = item_id
	_viewer_ready_to_collect = mode != "box"
	_viewer_hint.text = hint
	_viewer_block_until_msec = Time.get_ticks_msec() + 220
	_viewer.visible = true
	_set_player_locked(true)


func _collect_from_viewer() -> void:
	if not _viewer_ready_to_collect:
		return
	if _viewer_mode == "inscription":
		_collect_inscription(_viewer_id)
	elif _viewer_mode == "box":
		_collect_jade()
	_close_viewer()


func _close_viewer() -> void:
	if _viewer != null:
		_viewer.visible = false
	_viewer_mode = ""
	_viewer_id = ""
	_viewer_ready_to_collect = false
	_set_player_locked(false)


func _collect_inscription(lamp_id: String) -> void:
	var order: Array = _state_array("inscription_order")
	if lamp_id not in order:
		order.append(lamp_id)
		FragmentManager.set_fragment_state(FRAGMENT_ID, "inscription_order", order)
		_show_message("你记下了刻字：%s" % INSCRIPTION_CHARS.get(lamp_id, ""))
	if _state_int("wash_hands") == 1 and _state_int("lantern_lit") == 0:
		_attempt_ritual_step("burn")
	_update_clue_panel()


func _collect_jade() -> void:
	FragmentManager.set_fragment_state(FRAGMENT_ID, "jade_collected", 1)
	FragmentManager.set_fragment_state(FRAGMENT_ID, "jade_gallery_collected", 1)
	_show_message("你收起了玉。")
	_update_clue_panel()
	var box := get_node_or_null("WorldRoot/Box") as Node2D
	if box != null:
		box.visible = false


func _interact_with_well() -> void:
	if _state_int("jade_collected") == 1:
		_show_message("你将玉投入了古井")
		_attempt_ritual_step("offer")
	else:
		_show_message("你看到了井中怪诞的月亮")


func _attempt_ritual_step(action: String) -> void:
	var key := str(STEP_STATE_KEYS.get(action, ""))
	if key.is_empty() or _state_int(key) == 1:
		return
	var sequence: Array = _state_array("ritual_sequence")
	sequence.append(action)
	var progress := _ritual_progress()
	var expected := STEP_ORDER[progress] if progress < STEP_ORDER.size() else ""
	if action == expected:
		FragmentManager.set_fragment_state(FRAGMENT_ID, key, 1)
		_show_message("仪式回应了：%s" % STEP_NAMES.get(action, action))
	else:
		FragmentManager.set_fragment_state(FRAGMENT_ID, "ritual_sequence_invalid", true)
		_show_message("月光轻轻一颤，又恢复了沉默。")
	FragmentManager.set_fragment_state(FRAGMENT_ID, "ritual_sequence", sequence)
	_apply_lantern_state()


func _ritual_progress() -> int:
	var count := 0
	for action in STEP_ORDER:
		if _state_int(str(STEP_STATE_KEYS[action])) == 1:
			count += 1
		else:
			break
	return count


func _reset_ritual_round() -> void:
	for action in STEP_ORDER:
		FragmentManager.set_fragment_state(FRAGMENT_ID, str(STEP_STATE_KEYS[action]), 0)
	FragmentManager.set_fragment_state(FRAGMENT_ID, "ritual_sequence", [])
	FragmentManager.set_fragment_state(FRAGMENT_ID, "ritual_sequence_invalid", false)
	_pending_ritual_reset = false
	_apply_lantern_state()
	_show_message("镜中的微光散去了。仪式需要重新开始。")


func handle_npc_interaction(npc: Node2D) -> bool:
	if npc == null or not ("npc_kb_id" in npc):
		return false
	var npc_id := str(npc.npc_kb_id)
	if npc_id not in ["taoist", "mirrorspirit"]:
		return false
	if npc_id == "mirrorspirit" and _ritual_progress() == STEP_ORDER.size() \
			and not bool(FragmentManager.get_fragment_state(FRAGMENT_ID, "ritual_sequence_invalid")):
		_start_mirror_completion(npc)
		return true
	if npc_id == "mirrorspirit" and bool(FragmentManager.get_fragment_state(FRAGMENT_ID, "ritual_sequence_invalid")):
		_pending_ritual_reset = true
	ChatDialogue.open(npc, get_0003_npc_greeting(npc_id))
	if ChatDialogue.is_open and npc.has_method("start_dialogue"):
		npc.start_dialogue()
	return true


func get_0003_npc_greeting(npc_id: String) -> String:
	if npc_id == "taoist":
		return _get_taoist_greeting()
	if npc_id == "mirrorspirit":
		return _get_mirror_greeting()
	return "月光落在沉默的道观里。"


func _get_taoist_greeting() -> String:
	var progress := _ritual_progress()
	if bool(FragmentManager.get_fragment_state(FRAGMENT_ID, "ritual_sequence_invalid")):
		return "不对。次序里有一道回声走在了前面。镜会记得。"
	if progress == 0:
		return "步骤。顺序。哪里不对。灯沿路排着，由南至北，两灯一句。"
	if progress < STEP_ORDER.size():
		return "仪式在向前。下一句——不要听我，去听灯与月。"
	return "净——灯——玉——掌——月。五步。都对。最后一步，在镜前。"


func _get_mirror_greeting() -> String:
	if bool(FragmentManager.get_fragment_state(FRAGMENT_ID, "ritual_sequence_invalid")):
		var next_action := STEP_ORDER[_ritual_progress()] if _ritual_progress() < STEP_ORDER.size() else "wash"
		return "倒影里的次序断了。%s" % STEP_HINTS.get(next_action, "回到最初，再去试试。")
	var progress := _ritual_progress()
	if progress == 0:
		return "镜面映出你空着的双手。参道上的字，似乎在等待被依次读懂。"
	if progress < STEP_ORDER.size():
		var next_action := STEP_ORDER[progress]
		return "镜面浮起%d道微光。%s" % [progress, STEP_HINTS.get(next_action, "再去试试。")]
	return "镜中五道微光已经相连。只差你亲手启镜。"


func handle_npc_player_message(npc: Node, _message: String) -> bool:
	if npc == null or not ("npc_kb_id" in npc):
		return false
	var npc_id := str(npc.npc_kb_id)
	if npc_id not in ["taoist", "mirrorspirit"]:
		return false
	ChatDialogue.add_npc_msg(get_0003_npc_greeting(npc_id))
	return true


func _start_mirror_completion(npc: Node) -> void:
	if _completion_started:
		return
	_completion_started = true
	_set_player_locked(true)
	_run_mirror_completion(npc)


func _run_mirror_completion(npc: Node) -> void:
	ChatDialogue.open(npc, "")
	if ChatDialogue.is_open and npc.has_method("start_dialogue"):
		npc.start_dialogue()
	if ChatDialogue.is_open:
		await ChatDialogue.stream_local_npc_msg("你替她走完了无法完成的仪式。镜已醒，月光会记得你的倒影。")
		await ChatDialogue.wait_for_continue("点击或按 E 启镜")
	ChatDialogue.close()
	_stop_bgm()
	FragmentManager.set_fragment_state(FRAGMENT_ID, "mirror_opened", 1)
	SceneFader.fade_out_and_switch(END_SCENE)


func _on_dialogue_closed() -> void:
	if _pending_ritual_reset and not _completion_started:
		_reset_ritual_round()


func _on_moon_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attempt_ritual_step("moon")
		get_viewport().set_input_as_handled()


func _apply_lantern_state() -> void:
	if _lantern_material == null:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
uniform float brightness = 1.0;
uniform float warmth = 0.0;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 warmed = mix(color.rgb * brightness, vec3(1.0, 0.75, 0.38), warmth * color.a);
	COLOR = vec4(warmed, color.a) * COLOR;
}
"""
		_lantern_material = ShaderMaterial.new()
		_lantern_material.shader = shader
	if _lantern_glow_material == null:
		_lantern_glow_material = CanvasItemMaterial.new()
		_lantern_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var lit := _state_int("lantern_lit") == 1
	_lantern_material.set_shader_parameter("brightness", 1.42 if lit else 1.0)
	_lantern_material.set_shader_parameter("warmth", 0.34 if lit else 0.0)
	for lamp_name in INSCRIPTION_CHARS:
		var lamp := find_child(lamp_name, true, false)
		if lamp == null:
			continue
		var body := lamp.get_node_or_null("Visual/Body") as Sprite2D
		if body != null:
			body.material = _lantern_material
			_update_lantern_glow(body, lit)


func _update_lantern_glow(body: Sprite2D, lit: bool) -> void:
	var visual := body.get_parent()
	if visual == null:
		return
	var glow := visual.get_node_or_null("LanternGlow") as Sprite2D
	if glow == null:
		glow = Sprite2D.new()
		glow.name = "LanternGlow"
		glow.material = _lantern_glow_material
		glow.z_index = body.z_index + 1
		visual.add_child(glow)
	glow.texture = body.texture
	glow.centered = body.centered
	glow.offset = body.offset
	glow.region_enabled = body.region_enabled
	glow.region_rect = body.region_rect
	glow.position = body.position
	glow.rotation = body.rotation
	glow.scale = body.scale * 1.04
	glow.flip_h = body.flip_h
	glow.flip_v = body.flip_v
	glow.self_modulate = Color(1.0, 0.72, 0.32, 0.38)
	glow.visible = lit


func _toggle_clue_panel() -> void:
	if _clue_panel == null:
		return
	if _clue_panel.is_open:
		_clue_panel.close()
	else:
		_update_clue_panel()
		_clue_panel.open()


func _update_clue_panel() -> void:
	if _clue_panel == null:
		return
	var clues: Array[Dictionary] = []
	var order: Array = _state_array("inscription_order")
	if not order.is_empty():
		var text := ""
		for lamp_id in order:
			text += str(INSCRIPTION_CHARS.get(str(lamp_id), ""))
		clues.append({
			"id": clues.size(),
			"name": "这些刻字之间似乎有联系",
			"type": "observation",
			"description": text,
			"location": "参道石灯",
			"is_discovered": true,
		})
	if _state_int("jade_collected") == 1:
		clues.append({
			"id": clues.size(),
			"name": "玉",
			"type": "item",
			"description": "从阁楼木盒中取得的玉，表面留着冷淡的月光。",
			"location": "阁楼木盒",
			"image": JADE_TEXTURE,
			"is_discovered": true,
		})
	_clue_panel.set_clues_from_dictionaries(clues)


func _show_message(text: String, duration: float = 2.2) -> void:
	if _message_label == null:
		return
	_message_token += 1
	var token := _message_token
	_message_label.text = text
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


func _fit_world_to_viewport() -> void:
	var world_root := get_node_or_null("WorldRoot") as Node2D
	if world_root == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	var scale_factor := _get_cover_scale(viewport_size)
	var scaled_size := DESIGN_SIZE * scale_factor
	world_root.scale = Vector2(scale_factor, scale_factor)
	world_root.position = (viewport_size - scaled_size) * 0.5


func _get_cover_scale(viewport_size: Vector2) -> float:
	return maxf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)


func _state_int(key: String) -> int:
	var value = FragmentManager.get_fragment_state(FRAGMENT_ID, key)
	if value is bool:
		return 1 if value else 0
	if value is int or value is float:
		return int(value)
	return 0


func _state_array(key: String) -> Array:
	var value = FragmentManager.get_fragment_state(FRAGMENT_ID, key)
	return value.duplicate(true) if value is Array else []


func uses_alert_system() -> bool:
	return false


func has_player_for_test() -> bool:
	return _player != null and is_instance_valid(_player)


func get_ritual_progress_for_test() -> int:
	return _ritual_progress()


func get_cover_scale_for_test(viewport_size: Vector2) -> float:
	return _get_cover_scale(viewport_size)


func _start_bgm() -> void:
	AudioManager.play_bgm(BGM_FRAGMENT_0003, "fragment_0003", 0.45, -10.0, true)
	print("[Fragment0003] BGM 已开始循环播放")


func _stop_bgm() -> void:
	AudioManager.stop_bgm(0.25)
	print("[Fragment0003] BGM 已停止")
