extends Node
## 存档管理器
## - 手动存档：按 F5 触发
## - 自动存档：每 30 秒自动保存到当前槽位（仅活跃槽位有效时运行）
## - 多槽位支持（0-2）
## - 保存内容：GameManager 全局状态 + NPC 持久化 + ChatDatabase 聊天记录（按槽位独立）
## - 启动时自动加载最后一次活动的槽位

const SAVE_DIR: String = "user://saves/"
const AUTO_SAVE_INTERVAL: float = 30.0  ## 自动存档间隔（秒）
const LAST_SLOT_PATH: String = "user://saves/last_slot.json"  ## 最后活动槽位记录
const MAX_SLOTS: int = 3  ## 总槽位数
const TITLE_SCREEN_PATH: String = "res://scenes/ui/title_screen.tscn"

var save_data: Dictionary = {}
var _auto_timer: Timer = null
var _current_slot: int = -1  ## 当前槽位；-1 表示尚未选择槽位


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_ensure_save_dir()
	
	var last_slot = _read_last_slot()
	
	if last_slot >= 0 and last_slot < MAX_SLOTS and load_game(last_slot):
		print("[SaveManager] 存档自动加载成功 (slot %d)" % last_slot)
		_setup_auto_save()
	else:
		print("[SaveManager] 未找到存档 (slot %d)，等待用户选择" % last_slot)
		_current_slot = -1


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ============================================================
# 自动存档
# ============================================================

func _setup_auto_save() -> void:
	## 启动自动存档定时器（仅当 _current_slot 合法且定时器未运行时）
	if _current_slot < 0:
		return
	if _auto_timer and _auto_timer.is_inside_tree():
		return
	_auto_timer = Timer.new()
	_auto_timer.name = "AutoSaveTimer"
	_auto_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_timer.autostart = true
	_auto_timer.timeout.connect(_on_auto_save)
	add_child(_auto_timer)
	print("[SaveManager] 自动存档就绪，间隔 %.0f 秒" % AUTO_SAVE_INTERVAL)


func _stop_auto_save() -> void:
	if _auto_timer == null:
		return
	if _auto_timer.is_inside_tree():
		_auto_timer.stop()
		_auto_timer.queue_free()
	_auto_timer = null

func _on_auto_save() -> void:
	if _current_slot < 0:
		_stop_auto_save()
		return
	if _is_title_screen_active():
		return
	if get_tree().current_scene == null:
		return
	if not FileAccess.file_exists(_slot_path(_current_slot)):
		_current_slot = -1
		_stop_auto_save()
		return
	save_game(_current_slot)


func _is_title_screen_active() -> bool:
	return _is_title_screen_scene(get_tree().current_scene)


func _is_title_screen_scene(scene: Node) -> bool:
	if scene == null:
		return true
	return scene.scene_file_path == TITLE_SCREEN_PATH or scene.name == "TitleScreen"


# ============================================================
# 手动存档
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_save"):
		manual_save()


func manual_save() -> void:
	## 手动存档（F5）—— 覆盖当前槽位
	if _current_slot < 0:
		return
	save_game(_current_slot)
	_show_save_notification()


func quick_save(slot: int = -1) -> void:
	save_game(slot)


# ============================================================
# 存档 / 读档
# ============================================================

func save_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = _current_slot
	if slot < 0 or slot >= MAX_SLOTS:
		printerr("[SaveManager] 存档失败: 没有有效的活动槽位")
		return false
	if slot != _current_slot:
		printerr("[SaveManager] 存档失败: 目标槽位 %d 不是当前活动槽位 %d" % [slot, _current_slot])
		return false
	var ts = Time.get_unix_time_from_system()
	
	ChatDatabase.flush_to_disk()
	
	save_data = {
		"version": "0.3.0",
		"slot": slot,
		"timestamp": ts,
		"timestamp_readable": Time.get_datetime_string_from_system(),
		"save_name": _resolve_save_name(slot),
		"play_time_seconds": GameManager.play_time_seconds,
		
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
		
		"npc_state_cache": GameManager.npc_state_cache,
		
		"awakened_colors": GameManager.awakened_colors,
		"npc_visit_count": GameManager.npc_visit_count,
		"melody_triggered": GameManager.melody_triggered,
		"source_mark_revealed": GameManager.source_mark_revealed,
		"fragment_completed": GameManager.fragment_completed,
		"white_ready": GameManager.white_ready,
		"gray_cloth_uncovered": GameManager.gray_cloth_uncovered,
		"oldpainter_trust": GameManager.oldpainter_trust,
		
		"items_used": GameManager.items_used,
		
		"fragments": _serialize_fragments(),
		
		"chat_history": ChatDatabase.get_raw_data(),
	}
	
	var path = _slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] 存档保存成功 (slot %d)" % slot)
		return true
	printerr("[SaveManager] 存档写入失败: %s" % path)
	return false


func load_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		save_data = {}
		printerr("[SaveManager] Invalid save slot: %d" % slot)
		return false
	_load_save_file(slot)
	if save_data.is_empty():
		return false
	
	GameManager.repair_progress = save_data.get("repair_progress", 0.0)
	GameManager.repaired_fragments = save_data.get("repaired_count", 0)
	GameManager.current_phase = save_data.get("current_phase", 0)
	GameManager.play_time_seconds = float(save_data.get("play_time_seconds", 0.0))
	GameManager.collected_clues.assign(save_data.get("collected_clues", []))
	GameManager.source_mark_log.assign(save_data.get("source_mark_log", []))
	GameManager.company_trust = save_data.get("company_trust", 1.0)
	GameManager.darkline_a_revealed = save_data.get("darkline_a", false)
	GameManager.darkline_b_revealed = save_data.get("darkline_b", false)
	GameManager.darkline_c_unlocked = save_data.get("darkline_c", false)
	GameManager.player_name = save_data.get("player_name", "溯光者-07")
	
	var npc_cache = save_data.get("npc_state_cache", {})
	if npc_cache is Dictionary:
		GameManager.npc_state_cache = npc_cache
	
	var colors = save_data.get("awakened_colors", [])
	if colors is Array and colors.size() == 6:
		GameManager.awakened_colors.assign(colors)
	
	var visits = save_data.get("npc_visit_count", {})
	if visits is Dictionary:
		GameManager.npc_visit_count = visits
	
	GameManager.melody_triggered = save_data.get("melody_triggered", false)
	GameManager.source_mark_revealed = save_data.get("source_mark_revealed", false)
	GameManager.fragment_completed = save_data.get("fragment_completed", false)
	GameManager.white_ready = save_data.get("white_ready", false)
	GameManager.gray_cloth_uncovered = save_data.get("gray_cloth_uncovered", false)
	GameManager.oldpainter_trust = save_data.get("oldpainter_trust", 0.0)
	
	var items = save_data.get("items_used", {})
	if items is Dictionary:
		GameManager.items_used = items
	
	FragmentManager.reset_all_fragments()
	_deserialize_fragments(save_data.get("fragments", []))
	
	ChatDatabase.set_slot(slot)
	if not ChatDatabase.has_any_data():
		var chat_data = save_data.get("chat_history", {})
		if chat_data is Dictionary and not chat_data.is_empty():
			ChatDatabase.restore_from(chat_data)
	
	_current_slot = slot
	print("[SaveManager] 存档加载成功 (slot %d)" % slot)
	return true


func _load_save_file(slot: int) -> void:
	save_data = {}
	if slot < 0 or slot >= MAX_SLOTS:
		return
	var path = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary and not data.is_empty():
				save_data = data
		file.close()


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot


func _default_save_name(slot: int) -> String:
	return "溯光档案 %02d" % (slot + 1)


func _resolve_save_name(slot: int) -> String:
	if int(save_data.get("slot", -1)) == slot \
			and save_data.has("save_name") \
			and str(save_data.get("save_name", "")).strip_edges() != "":
		return str(save_data["save_name"]).strip_edges()
	var path = _slot_path(slot)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					var existing_name := str(data.get("save_name", "")).strip_edges()
					if existing_name != "":
						file.close()
						return existing_name
			file.close()
	return _default_save_name(slot)


# ============================================================
# 槽位管理
# ============================================================

func list_slots() -> Array[Dictionary]:
	## 返回全部槽位信息（含空槽位），occupied 标记是否已占用
	var slots: Array[Dictionary] = []
	for i in range(MAX_SLOTS):
		var path = _slot_path(i)
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var json = JSON.new()
				var parse_ok = json.parse(file.get_as_text()) == OK
				file.close()
				if parse_ok:
					var data = json.get_data()
					if data is Dictionary and not data.is_empty():
						slots.append({
							"slot": i,
							"occupied": true,
							"timestamp": data.get("timestamp", 0),
							"timestamp_readable": data.get("timestamp_readable", ""),
							"save_name": data.get("save_name", _default_save_name(i)),
							"play_time_seconds": data.get("play_time_seconds", 0.0),
							"player_name": data.get("player_name", ""),
							"progress": data.get("repair_progress", 0.0),
							"phase": data.get("current_phase", 0)
						})
						continue
		slots.append({
			"slot": i,
			"occupied": false,
			"timestamp": 0,
			"timestamp_readable": "",
			"save_name": "",
			"play_time_seconds": 0.0,
			"player_name": "",
			"progress": 0.0,
			"phase": 0
		})
	return slots


func delete_slot(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	var path = _slot_path(slot)
	if FileAccess.file_exists(path):
		# 先覆写为空JSON再删除
		var wipe := FileAccess.open(path, FileAccess.WRITE)
		if wipe:
			wipe.store_string("{}")
			wipe.close()
		DirAccess.remove_absolute(path)
		print("[SaveManager] 存档已删除 (slot %d)" % slot)
	
	if slot == _current_slot:
		_stop_auto_save()
		ChatDatabase.clear_all_history()
		_current_slot = -1
		save_data = {}
		if FileAccess.file_exists(LAST_SLOT_PATH):
			DirAccess.remove_absolute(LAST_SLOT_PATH)
	ChatDatabase.delete_slot_file(slot)
	if not has_any_save_files():
		clear_active_slot()


func has_any_save_files() -> bool:
	for slot in list_slots():
		if slot.get("occupied", false):
			return true
	return false


func clear_active_slot() -> void:
	## 清空内存中的活跃槽位，防止自动保存把已删除的存档重新写回磁盘。
	_stop_auto_save()
	_current_slot = -1
	save_data = {}
	if FileAccess.file_exists(LAST_SLOT_PATH):
		DirAccess.remove_absolute(LAST_SLOT_PATH)
	FragmentManager.reset_all_fragments()


func set_current_slot(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		printerr("[SaveManager] 无效存档槽位: %d" % slot)
		return
	_current_slot = slot
	_write_last_slot(slot)
	ChatDatabase.set_slot(slot)
	print("[SaveManager] 当前存档槽位设为 %d" % slot)
	_setup_auto_save()


func get_current_slot() -> int:
	## 返回当前活跃的槽位编号（-1 表示无活跃槽位）
	return _current_slot


func _read_last_slot() -> int:
	if not FileAccess.file_exists(LAST_SLOT_PATH):
		return _current_slot
	var file = FileAccess.open(LAST_SLOT_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				var slot := int(data.get("slot", -1))
				file.close()
				if slot >= 0 and slot < MAX_SLOTS and FileAccess.file_exists(_slot_path(slot)):
					return slot
				return _current_slot
		file.close()
	return _current_slot


func _write_last_slot(slot: int) -> void:
	var file = FileAccess.open(LAST_SLOT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"slot": slot}))
		file.close()


func get_last_active_slot() -> int:
	## 扫描所有存档槽位，返回时间戳最新的那个。无存档返回 -1
	var best_slot = -1
	var best_ts = 0
	for i in range(MAX_SLOTS):
		var path = _slot_path(i)
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data = json.get_data()
					if data is Dictionary and not data.is_empty():
						var ts := int(data.get("timestamp", 0))
						if ts > best_ts:
							best_ts = ts
							best_slot = i
				file.close()
	return best_slot


# ============================================================
# 序列化
# ============================================================

func _serialize_fragments() -> Array:
	var result: Array = []
	for f in FragmentManager.fragments:
		result.append({
			"id": f.id,
			"completed": f.completed,
		})
	return result


func _deserialize_fragments(saved: Array) -> void:
	for s in saved:
		var f = FragmentManager.get_fragment_by_id(s.get("id", ""))
		if f:
			f.completed = s.get("completed", s.get("decrypt_state", -1) == 4)


# ============================================================
# 提示
# ============================================================

func _show_save_notification() -> void:
	if not has_node("/root/ChatDialogue"):
		return
	var label = Label.new()
	label.name = "SaveNotification"
	label.text = "已存档"
	label.add_theme_color_override("font_color", Color(0.4, 1, 0.5, 1))
	label.add_theme_font_size_override("font_size", 17)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -60
	label.offset_top = 80
	label.offset_right = 60
	label.offset_bottom = 100
	
	var root = get_tree().root
	root.add_child(label)
	
	var t = get_tree().create_timer(2.0)
	t.timeout.connect(func(): 
		if is_instance_valid(label): 
			label.queue_free()
	)
