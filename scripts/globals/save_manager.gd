extends Node
## 存档管理器 — v1.0.0 重构版
##
## 核心变更（相对于 v0.3.0）:
##   - 原子写入策略（.tmp → rename .json → .bak 兜底）
##   - SHA-256 校验和（SaveChecksum）
##   - 版本迁移框架（SaveMigration）
##   - 通过 Manager.to_dict()/from_dict() 序列化，解除硬编码耦合
##   - 槽位使用 SaveConstants.MAX_SLOTS（当前 3 槽位）
##   - 聊天数据仅存于 chat_{slot}.json，不再内嵌于 save_{slot}.json

const TITLE_SCREEN_PATH: String = "res://scenes/ui/title_screen.tscn"

var save_data: Dictionary = {}
var _auto_timer: Timer = null
var _current_slot: int = -1  ## 当前槽位；-1 表示尚未选择槽位


# ============================================================
# 信号
# ============================================================

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_corrupted(slot: int)
signal save_recovered(slot: int)


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_ensure_save_dir()
	
	var last_slot = _read_last_slot()
	
	if last_slot >= 0 and last_slot < SaveConstants.MAX_SLOTS and load_game(last_slot):
		print("[SaveManager] 存档自动加载成功 (slot %d)" % last_slot)
		_setup_auto_save()
	else:
		print("[SaveManager] 未找到存档 (slot %d)，等待用户选择" % last_slot)
		_current_slot = -1


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SaveConstants.save_dir()):
		DirAccess.make_dir_recursive_absolute(SaveConstants.save_dir())


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
	_auto_timer.wait_time = SaveConstants.AUTO_SAVE_INTERVAL
	_auto_timer.autostart = true
	_auto_timer.timeout.connect(_on_auto_save)
	add_child(_auto_timer)
	print("[SaveManager] 自动存档就绪，间隔 %.0f 秒" % SaveConstants.AUTO_SAVE_INTERVAL)


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
	if not FileAccess.file_exists(SaveConstants.slot_path(_current_slot)):
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
# 存档核心 — save_game
# ============================================================

func save_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = _current_slot
	if slot < 0 or slot >= SaveConstants.MAX_SLOTS:
		printerr("[SaveManager] 存档失败: 无效槽位 %d" % slot)
		save_completed.emit(slot, false)
		return false

	# 1. 刷新聊天数据到磁盘
	ChatDatabase.flush_to_disk()

	# 2. 组装存档字典
	_ensure_save_dir()
	var save_dict: Dictionary = _assemble_save_dict(slot)
	if save_dict.is_empty():
		printerr("[SaveManager] 存档失败: 无法组装存档字典")
		save_completed.emit(slot, false)
		return false

	# 3. 序列化为 JSON（先序列化，再基于 JSON 字符串计算校验和）
	var json_str: String = JSON.stringify(save_dict, "\t")
	if json_str.is_empty():
		printerr("[SaveManager] 存档失败: JSON 序列化返回空")
		save_completed.emit(slot, false)
		return false

	# 4. 基于 JSON 字符串计算校验和（消除 JSON 往返导致的差异）
	var checksum: String = SaveChecksum.compute_raw(json_str)
	if checksum.is_empty():
		printerr("[SaveManager] 存档失败: 无法计算校验和")
		save_completed.emit(slot, false)
		return false

	# 5. 将校验和嵌入 JSON 字符串
	json_str = SaveChecksum.embed_checksum(json_str, checksum)

	# 6. 原子写入
	var write_ok: bool = _atomic_write(slot, json_str)
	if write_ok:
		save_data = save_dict
		print("[SaveManager] 存档保存成功 (slot %d)" % slot)

	save_completed.emit(slot, write_ok)
	return write_ok


# ============================================================
# 存档字典组装 / 拆解
# ============================================================

func _assemble_save_dict(slot: int) -> Dictionary:
	## 组装完整存档字典（version + checksum + global + fragments + fragment_states）
	var ts: float = Time.get_unix_time_from_system()
	var save_name: String = _resolve_save_name(slot)

	var global_dict: Dictionary = GameManager.to_dict()

	var fragments: Array = FragmentManager.get_fragments_list()
	var fragment_states: Dictionary = FragmentManager.get_fragment_states_dict()

	return {
		"version": SaveConstants.SAVE_VERSION,
		"slot": slot,
		"timestamp": ts,
		"timestamp_readable": Time.get_datetime_string_from_system(),
		"save_name": save_name,
		"checksum": "",  # 稍后由 save_game() 填充
		"global": global_dict,
		"fragments": fragments,
		"fragment_states": fragment_states,
	}


func _disassemble_save_dict(data: Dictionary) -> void:
	## 从存档字典恢复所有游戏状态
	# 恢复全局状态
	var global_data: Dictionary = data.get("global", {})
	GameManager.from_dict(global_data)

	# 恢复碎片完成状态和专属状态
	FragmentManager.reset_all_fragments()
	_apply_fragments_list(data.get("fragments", []))
	FragmentManager.apply_fragment_states(data.get("fragment_states", {}))
	if FragmentManager.has_method("ensure_linear_unlocks_from_completed"):
		FragmentManager.ensure_linear_unlocks_from_completed()
	if TutorialManager and TutorialManager.has_method("infer_from_fragments"):
		var completed_ids: Array[String] = []
		var unlocked_ids: Array[String] = []
		for fragment in FragmentManager.fragments:
			if fragment.completed:
				completed_ids.append(fragment.id)
			if fragment.unlocked:
				unlocked_ids.append(fragment.id)
		TutorialManager.infer_from_fragments(completed_ids, unlocked_ids)

	print("[SaveManager] 存档状态恢复完成")


func _apply_fragments_list(saved: Array) -> void:
	## 将 fragments 数组中的 completed 状态应用到对应 FragmentData
	for s in saved:
		if not s is Dictionary:
			continue
		var fragment_id: String = str(s.get("id", ""))
		if fragment_id.is_empty():
			continue
		var f = FragmentManager.get_fragment_by_id(fragment_id)
		if f:
			f.completed = bool(s.get("completed", false))
			f.unlocked = bool(s.get("unlocked", f.unlocked))


# ============================================================
# 原子写入
# ============================================================

func _atomic_write(slot: int, json_str: String) -> bool:
	## 原子写入策略：
	##   1. 写入 save_{slot}.tmp
	##   2. rename save_{slot}.json → save_{slot}.bak（如果存在）
	##   3. rename save_{slot}.tmp → save_{slot}.json
	##   4. 验证新文件可解析且 checksum 正确
	##   5. 验证通过 → 删除 .bak；验证失败 → 恢复 .bak → .json

	var json_path: String = SaveConstants.slot_path(slot)
	var tmp_path: String = SaveConstants.tmp_path(slot)
	var bak_path: String = SaveConstants.bak_path(slot)

	# 步骤 1: 写入临时文件
	var tmp_file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not tmp_file:
		printerr("[SaveManager] 原子写入失败: 无法创建临时文件 %s" % tmp_path)
		return false
	tmp_file.store_string(json_str)
	tmp_file.close()

	# 步骤 2: 原文件 → .bak
	var had_original: bool = FileAccess.file_exists(json_path)
	if had_original:
		var rename_err: int = DirAccess.rename_absolute(json_path, bak_path)
		if rename_err != OK:
			printerr("[SaveManager] 原子写入: 无法将 %s 重命名为 %s (err=%d)" % [json_path, bak_path, rename_err])
			# .tmp 已写入，尝试直接覆盖（降级策略）
			DirAccess.remove_absolute(json_path)

	# 步骤 3: .tmp → .json
	var final_rename_err: int = DirAccess.rename_absolute(tmp_path, json_path)
	if final_rename_err != OK:
		printerr("[SaveManager] 原子写入: 无法将 %s 重命名为 %s (err=%d)" % [tmp_path, json_path, final_rename_err])
		# 恢复 .bak
		if had_original and FileAccess.file_exists(bak_path):
			DirAccess.rename_absolute(bak_path, json_path)
		# 清理 .tmp
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		return false

	# 步骤 4: 验证新文件
	var verification_ok: bool = _verify_save_file(slot)
	if verification_ok:
		# 验证通过 → 删除 .bak
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		return true
	else:
		# 验证失败 → 恢复 .bak
		printerr("[SaveManager] 原子写入验证失败，回滚到备份")
		DirAccess.remove_absolute(json_path)
		if had_original and FileAccess.file_exists(bak_path):
			DirAccess.rename_absolute(bak_path, json_path)
			print("[SaveManager] 已从备份恢复 slot %d" % slot)
		else:
			printerr("[SaveManager] 无备份可恢复，slot %d 存档丢失" % slot)
		# 清理 .tmp
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		return false


func _verify_save_file(slot: int) -> bool:
	## 验证指定槽位的存档文件可解析且校验和正确
	## 基于原始文件内容计算校验和，避免 JSON 往返导致的不匹配
	var path: String = SaveConstants.slot_path(slot)
	if not FileAccess.file_exists(path):
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var raw_text: String = file.get_as_text()
	file.close()

	if raw_text.is_empty():
		return false

	return SaveChecksum.verify_raw(raw_text)


# ============================================================
# 读档核心 — load_game
# ============================================================

func load_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= SaveConstants.MAX_SLOTS:
		save_data = {}
		printerr("[SaveManager] 无效存档槽位: %d" % slot)
		load_completed.emit(slot, false)
		return false

	# 1. 读取原始文件内容
	var raw_text: String = _read_raw_file(slot)
	if raw_text.is_empty():
		# 尝试从备份恢复
		print("[SaveManager] slot %d 存档不存在或无法读取，尝试备份恢复" % slot)
		if _restore_from_backup(slot):
			raw_text = _read_raw_file(slot)
			if raw_text.is_empty():
				load_completed.emit(slot, false)
				return false
		else:
			load_completed.emit(slot, false)
			return false

	# 2. 基于原始文件内容验证校验和（消除 JSON 往返差异）
	if not SaveChecksum.verify_raw(raw_text):
		printerr("[SaveManager] slot %d 校验和不匹配，尝试备份恢复" % slot)
		if _restore_from_backup(slot):
			raw_text = _read_raw_file(slot)
			if raw_text.is_empty() or not SaveChecksum.verify_raw(raw_text):
				save_corrupted.emit(slot)
				load_completed.emit(slot, false)
				return false
		else:
			save_corrupted.emit(slot)
			load_completed.emit(slot, false)
			return false

	# 3. 解析 JSON 为字典
	var data: Dictionary = _parse_json_text(raw_text)
	if data.is_empty():
		printerr("[SaveManager] slot %d JSON 解析失败" % slot)
		load_completed.emit(slot, false)
		return false

	# 4. 版本迁移
	if SaveMigration.needs_migration(data):
		print("[SaveManager] slot %d 需要版本迁移" % slot)
		data = SaveMigration.migrate(data)
		if data.is_empty():
			printerr("[SaveManager] slot %d 版本迁移失败" % slot)
			load_completed.emit(slot, false)
			return false

	# 5. 恢复状态
	_disassemble_save_dict(data)

	# 6. 加载聊天数据
	ChatDatabase.set_slot(slot)

	# 7. 更新当前槽位
	_current_slot = slot
	save_data = data
	_write_last_slot(slot)
	_setup_auto_save()

	print("[SaveManager] 存档加载成功 (slot %d)" % slot)
	load_completed.emit(slot, true)
	return true


func _read_raw_file(slot: int) -> String:
	## 读取指定槽位存档文件的原始文本内容
	var path: String = SaveConstants.slot_path(slot)
	if not FileAccess.file_exists(path):
		return ""

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""

	var text: String = file.get_as_text()
	file.close()

	return text


func _parse_json_text(text: String) -> Dictionary:
	## 将 JSON 文本解析为字典
	if text.is_empty():
		return {}

	var json: JSON = JSON.new()
	var parse_err: int = json.parse(text)
	if parse_err != OK:
		printerr("[SaveManager] JSON 解析失败: 第 %d 行" % json.get_error_line())
		return {}

	var data = json.get_data()
	if not data is Dictionary:
		return {}

	return data


func _read_raw_bak_file(slot: int) -> String:
	## 读取指定槽位备份文件的原始文本内容
	var bak_path: String = SaveConstants.bak_path(slot)
	if not FileAccess.file_exists(bak_path):
		return ""

	var file: FileAccess = FileAccess.open(bak_path, FileAccess.READ)
	if not file:
		return ""

	var text: String = file.get_as_text()
	file.close()

	return text


func _atomic_read(slot: int) -> Dictionary:
	## 安全读取指定槽位的存档文件（返回解析后的字典）
	var text: String = _read_raw_file(slot)
	return _parse_json_text(text)


# ============================================================
# 备份恢复
# ============================================================

func _restore_from_backup(slot: int) -> bool:
	## 尝试从 .bak 备份恢复存档（使用原始文本校验，避免 JSON 往返差异）
	var bak_path: String = SaveConstants.bak_path(slot)
	var json_path: String = SaveConstants.slot_path(slot)

	if not FileAccess.file_exists(bak_path):
		print("[SaveManager] slot %d 无备份文件可用" % slot)
		return false

	# 读取备份原始文本
	var bak_raw: String = _read_raw_bak_file(slot)
	if bak_raw.is_empty():
		printerr("[SaveManager] slot %d 备份文件无效" % slot)
		return false

	# 验证备份文件完整性（基于原始文本）
	if not SaveChecksum.verify_raw(bak_raw):
		printerr("[SaveManager] slot %d 备份文件校验和失败 — 仍尝试恢复" % slot)

	# 移除当前的损坏文件
	if FileAccess.file_exists(json_path):
		DirAccess.remove_absolute(json_path)

	# 将备份重命名为正式文件
	var rename_err: int = DirAccess.rename_absolute(bak_path, json_path)
	if rename_err != OK:
		printerr("[SaveManager] 备份恢复失败: 重命名错误 %d" % rename_err)
		return false

	save_recovered.emit(slot)
	print("[SaveManager] 已从备份恢复 slot %d" % slot)
	return true


func _read_file_dict(path: String) -> Dictionary:
	## 读取 JSON 文件并解析为字典
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var text: String = file.get_as_text()
	file.close()

	if text.is_empty():
		return {}

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}

	var data = json.get_data()
	if not data is Dictionary:
		return {}

	return data


# ============================================================
# 槽位管理
# ============================================================

func list_slots() -> Array[Dictionary]:
	## 返回全部槽位信息（含空槽位），occupied 标记是否已占用
	## 适配新 JSON 结构路径: data["global"]["play_time_seconds"]
	var slots: Array[Dictionary] = []
	for i in range(SaveConstants.MAX_SLOTS):
		var path: String = SaveConstants.slot_path(i)
		if FileAccess.file_exists(path):
			var data: Dictionary = _read_file_dict(path)
			if not data.is_empty():
				var global: Dictionary = data.get("global", {})
				slots.append({
					"slot": i,
					"occupied": true,
					"timestamp": data.get("timestamp", 0),
					"timestamp_readable": data.get("timestamp_readable", ""),
					"save_name": data.get("save_name", _default_save_name(i)),
					"play_time_seconds": float(global.get("play_time_seconds", 0.0)),
					"player_name": str(global.get("player_name", "")),
					"progress": float(global.get("repair_progress", 0.0)),
					"phase": int(global.get("current_phase", 0))
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
	if slot < 0 or slot >= SaveConstants.MAX_SLOTS:
		return

	var json_path: String = SaveConstants.slot_path(slot)
	var bak_path: String = SaveConstants.bak_path(slot)
	var tmp_path: String = SaveConstants.tmp_path(slot)

	# 删除主存档文件
	if FileAccess.file_exists(json_path):
		var wipe := FileAccess.open(json_path, FileAccess.WRITE)
		if wipe:
			wipe.store_string("{}")
			wipe.close()
		DirAccess.remove_absolute(json_path)

	# 删除备份文件
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)

	# 删除临时文件
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

	print("[SaveManager] 存档已删除 (slot %d)" % slot)

	if slot == _current_slot:
		_stop_auto_save()
		ChatDatabase.clear_all_history()
		_current_slot = -1
		save_data = {}
		if FileAccess.file_exists(SaveConstants.last_slot_path()):
			DirAccess.remove_absolute(SaveConstants.last_slot_path())

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
	if FileAccess.file_exists(SaveConstants.last_slot_path()):
		DirAccess.remove_absolute(SaveConstants.last_slot_path())
	FragmentManager.reset_all_fragments()


func set_current_slot(slot: int) -> void:
	if slot < 0 or slot >= SaveConstants.MAX_SLOTS:
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
	if not FileAccess.file_exists(SaveConstants.last_slot_path()):
		return _current_slot
	var file = FileAccess.open(SaveConstants.last_slot_path(), FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				var slot := int(data.get("slot", -1))
				file.close()
				if slot >= 0 and slot < SaveConstants.MAX_SLOTS and FileAccess.file_exists(SaveConstants.slot_path(slot)):
					return slot
				return _current_slot
		file.close()
	return _current_slot


func _write_last_slot(slot: int) -> void:
	_ensure_save_dir()
	var file = FileAccess.open(SaveConstants.last_slot_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"slot": slot}))
		file.close()


func get_last_active_slot() -> int:
	## 扫描所有存档槽位，返回时间戳最新的那个。无存档返回 -1
	var best_slot = -1
	var best_ts: float = 0.0
	for i in range(SaveConstants.MAX_SLOTS):
		var path: String = SaveConstants.slot_path(i)
		if FileAccess.file_exists(path):
			var data: Dictionary = _read_file_dict(path)
			if not data.is_empty():
				var ts: float = float(data.get("timestamp", 0))
				if ts > best_ts:
					best_ts = ts
					best_slot = i
	return best_slot


# ============================================================
# 存档名称
# ============================================================

func _default_save_name(slot: int) -> String:
	return "溯光档案 %02d" % (slot + 1)


func _resolve_save_name(slot: int) -> String:
	## 解析存档名称：优先使用内存中的名称，其次读取磁盘上的现有名称
	if int(save_data.get("slot", -1)) == slot \
			and save_data.has("save_name") \
			and str(save_data.get("save_name", "")).strip_edges() != "":
		return str(save_data["save_name"]).strip_edges()

	var path: String = SaveConstants.slot_path(slot)
	if FileAccess.file_exists(path):
		var data: Dictionary = _read_file_dict(path)
		if not data.is_empty():
			var existing_name := str(data.get("save_name", "")).strip_edges()
			if existing_name != "":
				return existing_name

	return _default_save_name(slot)


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
