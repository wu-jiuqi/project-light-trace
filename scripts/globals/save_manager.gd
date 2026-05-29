extends Node
## 存档管理器
## - 手动存档：按 F5 触发
## - 自动存档：每 3 分钟自动保存
## - 多槽位支持（默认槽位 0）
## - 保存内容：GameManager 全局状态 + NPC 持久化 + ChatDatabase 聊天记录

const SAVE_DIR: String = "user://saves/"
const AUTO_SAVE_INTERVAL: float = 180.0  ## 自动存档间隔（秒）

var save_data: Dictionary = {}
var _auto_timer: Timer = null
var _current_slot: int = 0  ## 当前槽位


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_ensure_save_dir()
	_setup_auto_save()
	
	if load_game(0):
		print("[SaveManager] 存档自动加载成功 (slot 0)")
	else:
		print("[SaveManager] 未找到存档，使用默认状态")


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ============================================================
# 自动存档
# ============================================================

func _setup_auto_save() -> void:
	_auto_timer = Timer.new()
	_auto_timer.name = "AutoSaveTimer"
	_auto_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_timer.autostart = true
	_auto_timer.timeout.connect(_on_auto_save)
	add_child(_auto_timer)
	print("[SaveManager] 自动存档就绪，间隔 %.0f 秒" % AUTO_SAVE_INTERVAL)


func _on_auto_save() -> void:
	save_game(_current_slot)
	print("[SaveManager] 自动存档完成 (slot %d)" % _current_slot)


# ============================================================
# 手动存档
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_save"):
		manual_save()


func manual_save() -> void:
	## 手动存档（F5）—— 覆盖当前槽位
	save_game(_current_slot)
	_show_save_notification()


func quick_save(slot: int = 0) -> void:
	save_game(slot)


# ============================================================
# 存档 / 读档
# ============================================================

func save_game(slot: int = 0) -> void:
	var ts = Time.get_unix_time_from_system()
	
	save_data = {
		"version": "0.2.0",
		"slot": slot,
		"timestamp": ts,
		"timestamp_readable": Time.get_datetime_string_from_system(),
		
		# GameManager 全局状态
		"repair_progress": GameManager.repair_progress,
		"repaired_count": GameManager.repaired_fragments,
		"current_phase": GameManager.current_phase,
		"collected_clues": GameManager.collected_clues,
		"source_mark_log": GameManager.source_mark_log,
		"company_trust": GameManager.company_trust,
		"darkline_a": GameManager.darkline_a_revealed,
		"darkline_b": GameManager.darkline_b_revealed,
		"darkline_c": GameManager.darkline_c_unlocked,
		"player_name": GameManager.player_name,
		
		# NPC 跨场景状态
		"npc_state_cache": GameManager.npc_state_cache,
		
		# 碎片 #0762 六色觉醒
		"awakened_colors": GameManager.awakened_colors,
		"npc_visit_count": GameManager.npc_visit_count,
		"melody_triggered": GameManager.melody_triggered,
		"source_mark_revealed": GameManager.source_mark_revealed,
		"fragment_completed": GameManager.fragment_completed,
		
		# 物品使用记录
		"items_used": GameManager.items_used,
		
		# 碎片解密状态
		"fragments": _serialize_fragments(),
		
		# 聊天记录
		"chat_history": ChatDatabase.get_raw_data(),
	}
	
	var path = _slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] 存档保存成功 (slot %d | %s)" % [slot, path])


func load_game(slot: int = 0) -> bool:
	_load_save_file(slot)
	if save_data.is_empty():
		return false
	
	# 恢复全局状态
	GameManager.repair_progress = save_data.get("repair_progress", 0.0)
	GameManager.repaired_fragments = save_data.get("repaired_count", 0)
	GameManager.current_phase = save_data.get("current_phase", 0)
	GameManager.collected_clues.assign(save_data.get("collected_clues", []))
	GameManager.source_mark_log.assign(save_data.get("source_mark_log", []))
	GameManager.company_trust = save_data.get("company_trust", 1.0)
	GameManager.darkline_a_revealed = save_data.get("darkline_a", false)
	GameManager.darkline_b_revealed = save_data.get("darkline_b", false)
	GameManager.darkline_c_unlocked = save_data.get("darkline_c", false)
	GameManager.player_name = save_data.get("player_name", "溯光者-07")
	
	# 恢复 NPC 状态
	var npc_cache = save_data.get("npc_state_cache", {})
	if npc_cache is Dictionary:
		GameManager.npc_state_cache = npc_cache
	
	# 恢复六色觉醒
	var colors = save_data.get("awakened_colors", [])
	if colors is Array and colors.size() == 6:
		GameManager.awakened_colors.assign(colors)
	
	var visits = save_data.get("npc_visit_count", {})
	if visits is Dictionary:
		GameManager.npc_visit_count = visits
	
	GameManager.melody_triggered = save_data.get("melody_triggered", false)
	GameManager.source_mark_revealed = save_data.get("source_mark_revealed", false)
	GameManager.fragment_completed = save_data.get("fragment_completed", false)
	
	# 恢复物品
	var items = save_data.get("items_used", {})
	if items is Dictionary:
		GameManager.items_used = items
	
	# 恢复碎片
	_deserialize_fragments(save_data.get("fragments", []))
	_resume_decrypt_timers()
	
	# 恢复聊天记录
	var chat = save_data.get("chat_history", {})
	if chat is Dictionary:
		ChatDatabase.restore_from(chat)
	
	_current_slot = slot
	print("[SaveManager] 存档加载成功 (slot %d)" % slot)
	return true


func _load_save_file(slot: int) -> void:
	var path = _slot_path(slot)
	if not FileAccess.file_exists(path):
		save_data = {}
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			save_data = json.get_data()
		file.close()


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot


# ============================================================
# 槽位管理
# ============================================================

func list_slots() -> Array[Dictionary]:
	## 返回所有存档槽信息 [{slot, timestamp, timestamp_readable, player_name, progress}, ...]
	var slots: Array[Dictionary] = []
	for i in range(5):  # 最多 5 个槽位
		var path = _slot_path(i)
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data = json.get_data()
					slots.append({
						"slot": i,
						"timestamp": data.get("timestamp", 0),
						"timestamp_readable": data.get("timestamp_readable", ""),
						"player_name": data.get("player_name", ""),
						"progress": data.get("repair_progress", 0.0),
						"phase": data.get("current_phase", 0)
					})
				file.close()
	return slots


func delete_slot(slot: int) -> void:
	var path = _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveManager] 存档已删除 (slot %d)" % slot)


# ============================================================
# 序列化
# ============================================================

func _serialize_fragments() -> Array:
	var result: Array = []
	for f in FragmentManager.fragments:
		result.append({
			"id": f.id,
			"decrypt_state": f.decrypt_state,
			"decrypt_progress": f.decrypt_progress,
			"decrypt_start_time": f.decrypt_start_time,
			"hint_visible": f.hint_visible,
		})
	return result


func _deserialize_fragments(saved: Array) -> void:
	for s in saved:
		var f = FragmentManager.get_fragment_by_id(s["id"])
		if f:
			f.decrypt_state = s["decrypt_state"]
			f.decrypt_progress = s["decrypt_progress"]
			f.decrypt_start_time = s["decrypt_start_time"]
			f.hint_visible = s["hint_visible"]


func _resume_decrypt_timers() -> void:
	for f in FragmentManager.fragments:
		if f.decrypt_state == FragmentManager.DecryptState.DECRYPTING:
			FragmentManager.check_decrypt_progress(f)


# ============================================================
# 提示
# ============================================================

func _show_save_notification() -> void:
	## 在屏幕上方显示存档提示
	if not has_node("/root/ChatDialogue"):
		return
	var label = Label.new()
	label.name = "SaveNotification"
	label.text = "已存档"
	label.add_theme_color_override("font_color", Color(0.4, 1, 0.5, 1))
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -60
	label.offset_top = 80
	label.offset_right = 60
	label.offset_bottom = 100
	
	var root = get_tree().root
	root.add_child(label)
	
	# 2 秒后自动消失
	var t = get_tree().create_timer(2.0)
	t.timeout.connect(func(): 
		if is_instance_valid(label): 
			label.queue_free()
	)
