extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const Content = preload("res://scripts/fragment/fragment_0002_content.gd")
const MONOLOGUE_SCENE: PackedScene = preload("res://scenes/ui/Monologue.tscn")
const SEAT_TABLE_SCENE: PackedScene = preload("res://scenes/buildings/id0002/seat_table.tscn")
const SOURCE_MARK_TICKET_SCENE: PackedScene = preload("res://scenes/ui/SourceMarkTicketOverlay.tscn")
const BGM_FRAGMENT_0002 = preload("res://assets/audio/0002.mp3")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const PLAYER_VISUAL_SCALE := Vector2(2.2, 2.2)
const CONTINUE_PROMPT := "点击任意位置继续"

enum FlowState {
	WAITING_FOR_DECISION,
	SEATING,
	ASKING_REASON,
	REVEALING_TRUTH,
	SOURCE_MARK_TICKET,
	FINAL_WORDS,
	COMPLETED,
}

var _player: CharacterBody2D = null
var _interact_hint_label: Label = null
var _monologue_panel: MonologuePanel = null
var _seat_table_panel: SeatTablePanel = null
var _source_mark_overlay: SourceMarkTicketOverlay = null
var _completion_label: Label = null
var _active_monologue_npc: Node = null
var _flow_state: int = FlowState.WAITING_FOR_DECISION
var _bgm_player: AudioStreamPlayer = null
var _final_words_playing := false


func _enter_tree() -> void:
	add_to_group("fragment_state")


func _ready() -> void:
	_prepare_fragment_context()
	_ensure_interact_hint()
	_ensure_fragment_ui()
	_restore_flow_state()
	_spawn_player()
	_connect_player_ui()
	_fit_world_to_viewport()
	_start_bgm()
	if not get_viewport().size_changed.is_connected(_fit_world_to_viewport):
		get_viewport().size_changed.connect(_fit_world_to_viewport)
	SceneFader.fade_in()
	print("[Fragment0002Scene] Ready: %s" % name)


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id("0002")
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _restore_flow_state() -> void:
	var completed = FragmentManager.get_fragment_state("0002", "completed")
	if completed == true:
		_flow_state = FlowState.COMPLETED
		return
	var source_collected = FragmentManager.get_fragment_state("0002", "source_mark_ticket_collected")
	if source_collected == true:
		_flow_state = FlowState.FINAL_WORDS
		return
	var selection = FragmentManager.get_fragment_state("0002", "seat_selection")
	if selection is Dictionary and not selection.is_empty():
		_flow_state = FlowState.ASKING_REASON
	else:
		_flow_state = FlowState.WAITING_FOR_DECISION


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


func _ensure_fragment_ui() -> void:
	var ui_root := get_node_or_null("UIRoot") as CanvasLayer
	if ui_root == null:
		ui_root = CanvasLayer.new()
		ui_root.name = "UIRoot"
		add_child(ui_root)

	_monologue_panel = ui_root.get_node_or_null("Monologue") as MonologuePanel
	if _monologue_panel == null:
		_monologue_panel = MONOLOGUE_SCENE.instantiate() as MonologuePanel
		ui_root.add_child(_monologue_panel)
	_monologue_panel.visible = false
	if not _monologue_panel.monologue_finished.is_connected(_on_monologue_finished):
		_monologue_panel.monologue_finished.connect(_on_monologue_finished)

	_seat_table_panel = ui_root.get_node_or_null("SeatTable") as SeatTablePanel
	if _seat_table_panel == null:
		_seat_table_panel = SEAT_TABLE_SCENE.instantiate() as SeatTablePanel
		ui_root.add_child(_seat_table_panel)
	_seat_table_panel.visible = false
	if not _seat_table_panel.seating_saved.is_connected(_on_seating_saved):
		_seat_table_panel.seating_saved.connect(_on_seating_saved)

	_source_mark_overlay = ui_root.get_node_or_null("SourceMarkTicketOverlay") as SourceMarkTicketOverlay
	if _source_mark_overlay == null:
		_source_mark_overlay = SOURCE_MARK_TICKET_SCENE.instantiate() as SourceMarkTicketOverlay
		ui_root.add_child(_source_mark_overlay)
	_source_mark_overlay.visible = false
	if not _source_mark_overlay.collected.is_connected(_on_source_mark_ticket_collected):
		_source_mark_overlay.collected.connect(_on_source_mark_ticket_collected)

	_completion_label = ui_root.get_node_or_null("CompletionLabel") as Label
	if _completion_label == null:
		_completion_label = Label.new()
		_completion_label.name = "CompletionLabel"
		_completion_label.visible = false
		_completion_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_completion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_completion_label.add_theme_font_size_override("font_size", 46)
		_completion_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.56, 1.0))
		_completion_label.text = "通关"
		ui_root.add_child(_completion_label)


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


func _set_player_locked(locked: bool) -> void:
	if _player != null and _player.has_method("set_controls_locked"):
		_player.set_controls_locked(locked)


func uses_alert_system() -> bool:
	return false


func handle_npc_interaction(npc: Node2D) -> bool:
	if npc == null or not ("npc_kb_id" in npc):
		return false
	if _is_fragment_ui_open():
		return true

	var npc_id := str(npc.npc_kb_id)
	if npc_id == "conductor":
		if _flow_state == FlowState.FINAL_WORDS:
			_play_conductor_final()
			return true
		_open_conductor_dialogue(npc)
		return true
	if npc_id in Content.NPC_IDS:
		_open_monologue(npc)
		return true
	return false


func handle_npc_player_message(npc: Node, message: String) -> bool:
	if npc == null or not ("npc_kb_id" in npc) or str(npc.npc_kb_id) != "conductor":
		return false

	var clean_message := message.strip_edges()
	if _flow_state == FlowState.WAITING_FOR_DECISION and clean_message == "我想好了":
		_flow_state = FlowState.SEATING
		call_deferred("_open_seat_table_after_dialogue")
		return true
	if _flow_state == FlowState.ASKING_REASON and not clean_message.is_empty():
		_flow_state = FlowState.REVEALING_TRUTH
		call_deferred("_play_conductor_reveal")
		return true
	return false


func _is_fragment_ui_open() -> bool:
	return (_monologue_panel != null and _monologue_panel.visible) \
		or (_seat_table_panel != null and _seat_table_panel.visible) \
		or (_source_mark_overlay != null and _source_mark_overlay.visible)


func _open_conductor_dialogue(npc: Node) -> void:
	_set_player_locked(false)
	var greeting := ""
	match _flow_state:
		FlowState.WAITING_FOR_DECISION:
			greeting = Content.CONDUCTOR_OPENING
		FlowState.ASKING_REASON:
			greeting = Content.CONDUCTOR_ASK_REASON
		FlowState.FINAL_WORDS:
			greeting = ""
		_:
			greeting = ""

	ChatDialogue.open(npc, greeting)
	if ChatDialogue.is_open and npc.has_method("start_dialogue"):
		npc.start_dialogue()


func _open_monologue(npc: Node) -> void:
	var npc_id := str(npc.npc_kb_id)
	var pages: Array = Content.MONOLOGUE_PAGES.get(npc_id, [])
	if pages.is_empty():
		pages = [{"text": "【%s 独白占位】" % Content.NPC_DISPLAY_NAMES.get(npc_id, npc_id), "image_path": ""}]

	_active_monologue_npc = npc
	if npc.has_method("start_dialogue"):
		npc.start_dialogue()
	_set_player_locked(true)
	_monologue_panel.open_for_npc(npc_id, pages)


func _on_monologue_finished(_npc_id: String) -> void:
	if _active_monologue_npc != null and is_instance_valid(_active_monologue_npc):
		if _active_monologue_npc.has_method("end_dialogue"):
			_active_monologue_npc.end_dialogue()
	_active_monologue_npc = null
	_set_player_locked(false)


func _open_seat_table_after_dialogue() -> void:
	ChatDialogue.close()
	_set_player_locked(true)
	_seat_table_panel.open_table()


func _on_seating_saved(_selection: Dictionary, _left_npc_id: String) -> void:
	_flow_state = FlowState.ASKING_REASON
	_set_player_locked(false)
	var conductor := _find_npc_by_id("conductor")
	if conductor != null:
		_open_conductor_dialogue(conductor)


func _play_conductor_reveal() -> void:
	await ChatDialogue.stream_local_npc_msg(Content.CONDUCTOR_REVEAL)
	if ChatDialogue.is_open:
		await ChatDialogue.wait_for_continue(CONTINUE_PROMPT)
	ChatDialogue.close()
	_open_source_mark_ticket()


func _open_source_mark_ticket() -> void:
	_flow_state = FlowState.SOURCE_MARK_TICKET
	_set_player_locked(true)
	_source_mark_overlay.open_overlay()


func _on_source_mark_ticket_collected() -> void:
	_set_player_locked(false)
	_flow_state = FlowState.FINAL_WORDS
	_play_conductor_final()


func _play_conductor_final() -> void:
	if _final_words_playing:
		return
	_final_words_playing = true
	var conductor := _find_npc_by_id("conductor")
	if conductor == null:
		_final_words_playing = false
		_complete_fragment_0002()
		return
	_open_conductor_dialogue(conductor)
	await ChatDialogue.stream_local_npc_msg(Content.CONDUCTOR_FINAL)
	if ChatDialogue.is_open:
		await ChatDialogue.wait_for_continue(CONTINUE_PROMPT)
	ChatDialogue.close()
	_final_words_playing = false
	_complete_fragment_0002()


func _complete_fragment_0002() -> void:
	if _flow_state == FlowState.COMPLETED:
		return
	_flow_state = FlowState.COMPLETED
	FragmentManager.set_fragment_state("0002", "completed", true)
	var fragment = FragmentManager.current_fragment
	if fragment == null:
		fragment = FragmentManager.get_fragment_by_id("0002")
	if fragment != null:
		FragmentManager.complete_fragment(fragment)
	GameManager.record_source_mark("0002", Content.SOURCE_MARK_NAME, Content.SOURCE_MARK_HINT)
	SaveManager.save_game()
	_show_completion_and_return()


func _show_completion_and_return() -> void:
	_set_player_locked(true)
	if _completion_label != null:
		_completion_label.visible = true
	await get_tree().create_timer(1.2).timeout
	_stop_bgm()
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _find_npc_by_id(npc_id: String) -> Node:
	for node in get_tree().get_nodes_in_group("npc"):
		if "npc_kb_id" in node and str(node.npc_kb_id) == npc_id:
			return node
	return null


func _start_bgm() -> void:
	if _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.name = "BGMPlayer_Fragment0002"
		_bgm_player.bus = "Master"
		_bgm_player.volume_db = -10.0
		add_child(_bgm_player)
	_bgm_player.stream = BGM_FRAGMENT_0002
	_bgm_player.stream.loop = true
	_bgm_player.play()
	print("[Fragment0002] BGM 已开始循环播放")


func _stop_bgm() -> void:
	if _bgm_player != null and _bgm_player.playing:
		_bgm_player.stop()
		print("[Fragment0002] BGM 已停止")


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
