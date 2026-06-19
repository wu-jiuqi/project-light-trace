extends CharacterBody2D

const SoftShadow = preload("res://scripts/fragment/soft_shadow.gd")

## 通用 NPC 控制器
## 负责当前碎片的站立/巡逻、对话入口、RAG prompt 组装和 LLM 流式输出。
## 旧版六色情感、给予物品、追捕逻辑已移除。

enum NPCState {
	IDLE,
	PATROL,
	TALKING,
}

@export var npc_name: String = "未命名NPC"
@export var npc_role: String = "居民"
@export var walk_speed: float = 50.0
@export var dialogue_tree: Array[Dictionary] = []
@export_multiline var system_prompt: String = ""
@export var npc_kb_id: String = ""
@export var use_rag: bool = true

## 兼容聊天记录和旧存档字段。当前新版设计不再用它们驱动玩法。
var npc_suspicion: float = 0.0
var npc_alert_phase: int = 0
var doubts_player_identity: bool = false

var current_state: int = NPCState.IDLE
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var target_position: Vector2 = Vector2.ZERO
var idle_timer: float = 0.0

var _fragment_state: Node = null
var _last_greeting: String = ""
var _llm_last_input: String = ""
var _stream_suppress_asterisk_action: bool = false
var _stream_suppress_paren_action: bool = false
var _shadow_sprite: Sprite2D = null

const DIALOGUE_HISTORY_LIMIT: int = 10

signal npc_state_changed(new_state: int)


func _ready() -> void:
	add_to_group("npc")
	_resolve_fragment_state()
	_setup_interaction_zone()
	_setup_shadow()
	target_position = global_position
	print("[NPC] %s (%s) ready | kb=%s rag=%s" % [npc_name, npc_role, npc_kb_id, use_rag])


func _physics_process(delta: float) -> void:
	if current_state == NPCState.PATROL:
		_process_patrol(delta)


func _resolve_fragment_state() -> Node:
	if _fragment_state != null:
		return _fragment_state
	var states := get_tree().get_nodes_in_group("fragment_state")
	if not states.is_empty():
		_fragment_state = states[0]
	return _fragment_state


func _setup_interaction_zone() -> void:
	var zone := get_node_or_null("InteractionZone") as Area2D
	if zone == null:
		zone = Area2D.new()
		zone.name = "InteractionZone"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 50.0
		shape.shape = circle
		zone.add_child(shape)
		add_child(zone)
	zone.collision_layer = 4
	zone.collision_mask = 1


func _setup_shadow() -> void:
	var visual_sprite := _find_visual_sprite()
	if visual_sprite == null:
		return
	_shadow_sprite = visual_sprite.get_parent().get_node_or_null("Shadow Sprite2D") as Sprite2D
	if _shadow_sprite == null:
		_shadow_sprite = Sprite2D.new()
		_shadow_sprite.name = "Shadow Sprite2D"
		visual_sprite.get_parent().add_child(_shadow_sprite)
		visual_sprite.get_parent().move_child(_shadow_sprite, 0)
	SoftShadow.apply_to(_shadow_sprite, visual_sprite)


func _find_visual_sprite() -> Sprite2D:
	for child in find_children("*", "Sprite2D", true, false):
		var sprite := child as Sprite2D
		if sprite != null and sprite.name != "Shadow Sprite2D":
			return sprite
	return null


func _process_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		return
	var target := patrol_points[patrol_index]
	var direction := global_position.direction_to(target)
	velocity = direction * walk_speed
	move_and_slide()
	if global_position.distance_to(target) < 8.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()


func set_state(new_state: int) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	npc_state_changed.emit(new_state)


func start_dialogue() -> void:
	set_state(NPCState.TALKING)
	print("[NPC] %s dialogue start (kb=%s rag=%s)" % [npc_name, npc_kb_id, use_rag])


func end_dialogue() -> void:
	set_state(NPCState.IDLE)
	_save_passive_state()


func _save_passive_state() -> void:
	if npc_kb_id == "" or not GameManager:
		return
	var scene_name := ""
	if get_tree().current_scene != null:
		scene_name = get_tree().current_scene.name
	GameManager.save_npc_state(scene_name, npc_kb_id, global_position, 0.0, 0, false)


func get_greeting() -> String:
	if not dialogue_tree.is_empty():
		var first := dialogue_tree[0]
		var text := str(first.get("text", ""))
		if text != "":
			_last_greeting = text
			return text
	var fallback := get_fallback_response()
	_last_greeting = fallback
	return fallback


func get_fallback_response() -> String:
	if npc_kb_id != "" and NPCRagRetriever and NPCRagRetriever.has_method("get_fallback_response"):
		var response := NPCRagRetriever.get_fallback_response(npc_kb_id)
		if response != "":
			return response
	if system_prompt.strip_edges() != "":
		return "我在。你想问什么？"
	return "你好。"


func can_give_item() -> bool:
	return false


func get_givable_item() -> Dictionary:
	return {}


func send_give_item(_item_id: int) -> void:
	ChatDialogue.add_npc_msg("现在还没有可以交给我的东西。")


func get_alert_phase_text() -> String:
	return "平静"


func get_alert_context_for_rag() -> String:
	return ""


func send_player_message(message: String) -> void:
	var clean_message := message.strip_edges()
	if clean_message == "":
		return
	_llm_last_input = clean_message

	if LLMClient.is_busy():
		ChatDialogue.add_npc_msg("请稍等，我还在思考刚才的问题。")
		return

	var game_state := _build_game_state()
	var history_messages: Array = game_state.get("history_messages", [])
	var prompt := _build_prompt(clean_message, game_state)
	if prompt.strip_edges() == "":
		ChatDialogue.add_npc_msg(get_fallback_response())
		return
	ChatDatabase.log_message(npc_kb_id, "player", clean_message, 0, 0.0)

	_disconnect_stream_signals()
	LLMClient.stream_token.connect(_on_stream_token)
	LLMClient.stream_completed.connect(_on_stream_completed)
	LLMClient.stream_failed.connect(_on_stream_failed)
	ChatDialogue.stream_begin()
	LLMClient.chat_stream(prompt, clean_message, history_messages, Callable(), npc_kb_id)


func _build_prompt(player_input: String, game_state: Dictionary) -> String:
	if use_rag and npc_kb_id != "":
		return NPCRagRetriever.assemble_prompt(npc_kb_id, player_input, game_state)
	if system_prompt.strip_edges() != "":
		return system_prompt
	if npc_kb_id != "":
		return NPCRagRetriever.assemble_prompt(npc_kb_id, player_input, game_state)
	return ""


func _build_game_state() -> Dictionary:
	var state := {
		"fragment_id": "",
		"scene_name": "",
		"memory_stage": "initial",
		"trust_level": 0,
		"alert_level": 0,
		"alert_context": "",
		"history_messages": ChatDatabase.get_history_messages(npc_kb_id, DIALOGUE_HISTORY_LIMIT),
	}
	if get_tree().current_scene != null:
		state["scene_name"] = get_tree().current_scene.name
	var fragment_state := _resolve_fragment_state()
	if fragment_state != null and fragment_state.has_method("get_game_state"):
		var fragment_data = fragment_state.get_game_state(npc_kb_id)
		if fragment_data is Dictionary:
			for key in fragment_data:
				state[key] = fragment_data[key]
	return state


func _disconnect_stream_signals() -> void:
	if LLMClient.stream_token.is_connected(_on_stream_token):
		LLMClient.stream_token.disconnect(_on_stream_token)
	if LLMClient.stream_completed.is_connected(_on_stream_completed):
		LLMClient.stream_completed.disconnect(_on_stream_completed)
	if LLMClient.stream_failed.is_connected(_on_stream_failed):
		LLMClient.stream_failed.disconnect(_on_stream_failed)


func _on_stream_token(token: String) -> void:
	var visible_token := _filter_stream_action_markup(token)
	if visible_token != "":
		ChatDialogue.stream_add(visible_token)


func _on_stream_completed(full_text: String) -> void:
	_disconnect_stream_signals()
	var clean_text := _clean_model_dialogue_text(full_text)
	ChatDialogue.stream_end(clean_text)
	while ChatDialogue.has_method("is_streaming_response") and ChatDialogue.is_streaming_response():
		await get_tree().process_frame
	ChatDatabase.log_message(npc_kb_id, "npc", clean_text, 0, 0.0)
	print("[NPC] %s stream completed (%d chars)" % [npc_name, clean_text.length()])


func _on_stream_failed(error: String) -> void:
	_disconnect_stream_signals()
	ChatDialogue.stream_end("")
	var fallback := get_fallback_response()
	ChatDialogue.add_npc_msg(fallback)
	print("[NPC] %s stream failed: %s" % [npc_name, error.left(80)])


func _clean_model_dialogue_text(raw_text: String) -> String:
	var text := raw_text.strip_edges()
	if text.is_empty():
		return text

	var speaker_prefixes := [
		"[%s]" % npc_name,
		"【%s】" % npc_name,
		"%s：" % npc_name,
		"%s:" % npc_name,
		"[NPC]",
		"【NPC】",
	]
	for prefix in speaker_prefixes:
		if text.begins_with(prefix):
			text = text.substr(prefix.length()).strip_edges()

	var paren_regex := RegEx.new()
	if paren_regex.compile("\\s*[（(][^）)]*[）)]\\s*") == OK:
		text = paren_regex.sub(text, "", true).strip_edges()

	var asterisk_regex := RegEx.new()
	if asterisk_regex.compile("\\s*\\*[^*\\n]{1,120}\\*\\s*") == OK:
		text = asterisk_regex.sub(text, "", true).strip_edges()

	return text.replace("*", "").strip_edges()


func _filter_stream_action_markup(token: String) -> String:
	var visible := ""
	for ch in token:
		if ch == "*":
			_stream_suppress_asterisk_action = not _stream_suppress_asterisk_action
			continue
		if ch == "（" or ch == "(":
			_stream_suppress_paren_action = true
			continue
		if _stream_suppress_paren_action:
			if ch == "）" or ch == ")":
				_stream_suppress_paren_action = false
			continue
		if _stream_suppress_asterisk_action:
			continue
		visible += ch
	return visible
