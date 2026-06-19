extends CharacterBody2D

const Data = preload("res://scripts/fragment/fragment_0004_data.gd")
const SoftShadow = preload("res://scripts/fragment/soft_shadow.gd")

@export var npc_name: String = "工坊住民"
@export var npc_role: String = "自动人偶"
@export var npc_kb_id: String = ""
@export_multiline var default_greeting: String = ""
@export var use_rag: bool = true

var current_state: int = 0
var _llm_fallback_response: String = ""
var _stream_suppress_asterisk_action: bool = false
var _stream_suppress_paren_action: bool = false


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
	if state != null and state.has_method("get_0004_npc_greeting"):
		return str(state.get_0004_npc_greeting(npc_kb_id))
	return default_greeting


func get_fallback_response() -> String:
	return get_greeting()


func start_dialogue() -> void:
	current_state = 1


func end_dialogue() -> void:
	current_state = 0


func send_player_message(message: String) -> void:
	if not use_rag:
		ChatDialogue.add_npc_msg(_local_response(message))
		_notify_completion_if_ready()
		return
	if LLMClient.has_method("is_busy") and LLMClient.is_busy():
		ChatDialogue.add_npc_msg(_local_response(message))
		_notify_completion_if_ready()
		return

	var state := _find_fragment_state()
	var game_state := _collect_game_state(message, state)
	_llm_fallback_response = str(game_state.get("_local_fallback", ""))
	if _llm_fallback_response == "":
		_llm_fallback_response = _local_response(message)

	var system_prompt := NPCRagRetriever.assemble_prompt(npc_kb_id, message, game_state)
	if system_prompt == "":
		ChatDialogue.add_npc_msg(_llm_fallback_response)
		_notify_completion_if_ready()
		return

	var history_messages: Array = game_state.get("history_messages", [])
	if not npc_kb_id.is_empty():
		ChatDatabase.log_message(npc_kb_id, "player", message, 0, 0.0)

	_disconnect_stream_signals()
	_stream_suppress_asterisk_action = false
	_stream_suppress_paren_action = false
	ChatDialogue.stream_begin()
	LLMClient.stream_token.connect(_on_stream_token)
	LLMClient.stream_completed.connect(_on_stream_completed)
	LLMClient.stream_failed.connect(_on_stream_failed)
	LLMClient.chat_stream(system_prompt, message, history_messages, Callable(), npc_kb_id)


func can_give_item() -> bool:
	return false


func _collect_game_state(message: String, state: Node) -> Dictionary:
	var blueprint_count := _count_state_entries("collected_blueprints")
	var material_count := _count_state_entries("collected_materials")
	_llm_fallback_response = ""
	var game_state := {
		"memory_stage": _get_memory_stage(blueprint_count, material_count),
		"alert_level": 0,
		"trust_level": 0,
		"npc_mood": _get_npc_mood(blueprint_count, material_count),
		"history_messages": ChatDatabase.get_history_messages(npc_kb_id, 8) if not npc_kb_id.is_empty() else [],
		"alert_context": _build_0004_context(message, state, blueprint_count, material_count),
		"_local_fallback": ""
	}
	game_state["_local_fallback"] = _llm_fallback_response
	return game_state


func _build_0004_context(message: String, state: Node, blueprint_count: int, material_count: int) -> String:
	var parts: Array[String] = []
	parts.append("## 当前工坊进度\n已收集图纸：%d/%d。已收集材料：%d/%d。组装是否已解开：%s。" % [
		blueprint_count,
		Data.BLUEPRINT_PAGES.size(),
		material_count,
		Data.MATERIAL_DATA.size(),
		str(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved"))
	])
	if npc_kb_id == "springright":
		var local_audit := ""
		if _message_contains_material_id(message) and state != null and state.has_method("handle_0004_npc_player_message"):
			local_audit = str(state.handle_0004_npc_player_message(npc_kb_id, message))
		else:
			local_audit = str(Data.SPRINGRIGHT_PROMPTS.get("default", "请输入六个材料编号。"))
		_llm_fallback_response = local_audit
		parts.append("## 系统材料审核结论\n%s\n弹簧·右必须保持这个合格/不合格结论一致。可以改写语气，但不要把不合格改成合格，也不要泄露完整正确配方。若玩家只问格式，示例必须是：M1 L1 T1 P1 W1 B1，并说明示例不是答案。" % local_audit)
		parts.append("## 材料编号速查\n心脏候选：M1赤铜、M2青铜合金、M3轻铜铝。头部候选：L1白桦木、L2陶铝复合、L3晶化竹。左臂候选：T1弹簧钢、T2碳化钨、T3竹钢。右臂候选：P1镜面钢、P2陶瓷合金、P3精密黄铜。左腿候选：W1锻钢、W2钛合金、W3硬铝。右腿候选：B1钛合金·右、B2硬铝·右、B3锻钢·右。")
		parts.append("## 备用本地回复\n%s" % local_audit)
		return "\n".join(parts)
	if npc_kb_id == "gearleft":
		var guidance := _local_response(message)
		_llm_fallback_response = guidance
		parts.append("## 齿轮·左当前任务提示\n%s" % guidance)
		parts.append("## 讲述要求\n玩家问材料要求时，把检测仪数值讲成工坊直觉。尤其心脏重量要用双腿承重来解释，不要逐项列数值，不要直接报完整正确组合。")
		parts.append("## 备用本地回复\n%s" % guidance)
		return "\n".join(parts)
	return ""


func _get_memory_stage(blueprint_count: int, material_count: int) -> String:
	if bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
		return "script_reset"
	if blueprint_count >= Data.BLUEPRINT_PAGES.size() and material_count >= Data.MATERIAL_DATA.size():
		return "late"
	if blueprint_count > 0 or material_count > 0:
		return "intermediate"
	return "initial"


func _get_npc_mood(blueprint_count: int, material_count: int) -> String:
	if npc_kb_id == "gearleft":
		if bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
			return "齿轮摩擦声短暂消失。你第一次觉得合格不是命令，而是结果。"
		if blueprint_count >= Data.BLUEPRINT_PAGES.size() and material_count >= Data.MATERIAL_DATA.size():
			return "图纸和材料都在桌上。你急得想骂人，但更怕这次真的能装对。"
		return "你暴躁、忙碌，用'——嘎——'掩盖自己其实在等玩家帮忙。"
	if npc_kb_id == "springright":
		if bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
			return "你已经给出合格判定。'——暂定'正在从句尾消失。"
		return "你处于审核模式。挑剔、精确、嘴毒，但必须保持系统审核结论一致。"
	return ""


func _count_state_entries(key: String) -> int:
	var value = FragmentManager.get_fragment_state(Data.FRAGMENT_ID, key)
	var state: Dictionary = value.duplicate(true) if value is Dictionary else {}
	var count := 0
	for entry_key in state.keys():
		if int(state.get(entry_key, 0)) == 1:
			count += 1
	return count


func _message_contains_material_id(message: String) -> bool:
	var normalized := message.to_upper()
	for index in range(maxi(0, normalized.length() - 1)):
		if Data.MATERIAL_DATA.has(normalized.substr(index, 2)):
			return true
	return false


func _local_response(message: String) -> String:
	var state := _find_fragment_state()
	if state != null and state.has_method("handle_0004_npc_player_message"):
		return str(state.handle_0004_npc_player_message(npc_kb_id, message))
	return get_greeting()


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
	clean_text = _guard_springright_audit_text(clean_text)
	if clean_text == "":
		clean_text = _llm_fallback_response
	ChatDialogue.stream_end(clean_text)
	if not npc_kb_id.is_empty():
		ChatDatabase.log_message(npc_kb_id, "npc", clean_text, 0, 0.0)
	_notify_completion_if_ready()


func _on_stream_failed(_error: String) -> void:
	_disconnect_stream_signals()
	ChatDialogue.stream_end("")
	ChatDialogue.add_npc_msg(_llm_fallback_response)
	_notify_completion_if_ready()


func _guard_springright_audit_text(text: String) -> String:
	if npc_kb_id != "springright":
		return text
	var local_audit := _llm_fallback_response.strip_edges()
	if local_audit == "":
		return text
	var model_text := text.strip_edges()
	if model_text == "":
		return local_audit
	if _leaks_full_correct_combination(model_text):
		return local_audit
	if _audit_conclusion_conflicts(local_audit, model_text):
		return local_audit
	return model_text


func _audit_conclusion_conflicts(local_audit: String, model_text: String) -> bool:
	var local_pass := _contains_pass_conclusion(local_audit)
	var local_fail := _contains_fail_conclusion(local_audit)
	var model_pass := _contains_pass_conclusion(model_text)
	var model_fail := _contains_fail_conclusion(model_text)
	return (local_pass and model_fail) or (local_fail and model_pass and not model_fail)


func _contains_pass_conclusion(text: String) -> bool:
	return "合格" in text and not ("不合格" in text)


func _contains_fail_conclusion(text: String) -> bool:
	return "不合格" in text


func _leaks_full_correct_combination(text: String) -> bool:
	var normalized := text.to_upper()
	for material_id in Data.CORRECT_COMBINATION:
		if not (str(material_id).to_upper() in normalized):
			return false
	return true


func _notify_completion_if_ready() -> void:
	if npc_kb_id != "springright":
		return
	if not bool(FragmentManager.get_fragment_state(Data.FRAGMENT_ID, "assembly_solved")):
		return
	var state := _find_fragment_state()
	if state != null and state.has_method("start_0004_completion_after_dialogue"):
		state.start_0004_completion_after_dialogue()


func _clean_model_dialogue_text(raw_text: String) -> String:
	var text := raw_text.strip_edges()
	if text.is_empty():
		return text
	var speaker_prefixes := [
		"[%s]" % npc_name,
		"%s：" % npc_name,
		"%s:" % npc_name,
		"[NPC]"
	]
	for prefix in speaker_prefixes:
		if text.begins_with(prefix):
			text = text.substr(prefix.length()).strip_edges()
	var paren_regex := RegEx.new()
	if paren_regex.compile("\\s*[（(][^（）()\\n]{1,120}[）)]\\s*") == OK:
		text = paren_regex.sub(text, "", true).strip_edges()
	var asterisk_regex := RegEx.new()
	if asterisk_regex.compile("\\s*\\*[^*\\n]{1,120}\\*\\s*") == OK:
		text = asterisk_regex.sub(text, "", true).strip_edges()
	text = text.replace("*", "").strip_edges()
	return text


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


func _find_fragment_state() -> Node:
	for state in get_tree().get_nodes_in_group("fragment_state"):
		if state != null and state.has_method("get_0004_npc_greeting"):
			return state
	return null
