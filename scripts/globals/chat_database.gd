extends Node
## 聊天记录混合存储（按存档槽位隔离）
##   _cache: 每 NPC 最近 N 条（deque，LLM 用），纯内存
##   _data: 每 NPC 全部消息，持久化到独立 chat_{slot}.json

const CACHE_SIZE: int = 20

var _cache: Dictionary = {}
var _data: Dictionary = {}
var _current_slot: int = 0


func _ready() -> void:
	# 不在 _ready 中自动加载，由 SaveManager 通过 set_slot() 控制加载时机。
	print("[ChatDatabase] 就绪 | 等待 SaveManager 指定槽位")


func set_slot(slot: int) -> void:
	if slot == _current_slot and not _data.is_empty():
		return

	_save()
	_current_slot = slot
	_data.clear()
	_cache.clear()

	_load()
	print("[ChatDatabase] 切换到槽位 %d | 文件: %s | NPC数: %d" % [slot, _data_path(), _data.size()])


func _data_path() -> String:
	return SaveConstants.chat_path(_current_slot)


func _load() -> void:
	var path = _data_path()
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()
	if text.is_empty():
		return
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var parsed = json.get_data()
	if parsed is Dictionary:
		_data = parsed
		if _sanitize_loaded_data():
			_save()
		_rebuild_cache()


func _rebuild_cache() -> void:
	_cache.clear()
	for npc_id in _data:
		var entries: Array = _data[npc_id]
		if entries.is_empty():
			continue
		var start = max(0, entries.size() - CACHE_SIZE)
		_cache[npc_id] = entries.slice(start, entries.size())


func _save() -> void:
	if _data.is_empty():
		return
	if not DirAccess.dir_exists_absolute(SaveConstants.save_dir()):
		DirAccess.make_dir_recursive_absolute(SaveConstants.save_dir())
	var path = _data_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		printerr("[ChatDatabase] 写入失败: %s" % path)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


func log_message(npc_id: String, role: String, content: String, alert_phase: int = 0, suspicion: float = 0.0) -> void:
	var clean_content := _sanitize_content(content)
	if clean_content.is_empty() or npc_id.is_empty():
		return

	var entry = {
		"role": role,
		"content": clean_content,
		"timestamp": Time.get_unix_time_from_system(),
		"alert_phase": alert_phase,
		"suspicion": snapped(suspicion, 0.01)
	}

	if not _data.has(npc_id):
		_data[npc_id] = []
	_data[npc_id].append(entry)

	if not _cache.has(npc_id):
		_cache[npc_id] = []
	var cache_arr: Array = _cache[npc_id]
	cache_arr.append(entry)
	if cache_arr.size() > CACHE_SIZE:
		cache_arr.pop_front()

	_save()


func get_history_as_text(npc_id: String, max_messages: int = 10) -> String:
	var cache_arr: Array = _cache.get(npc_id, [])
	if cache_arr.is_empty():
		return ""

	var start = max(0, cache_arr.size() - max_messages)
	var lines: Array[String] = ["## 最近对话"]
	for i in range(start, cache_arr.size()):
		var row = cache_arr[i]
		if row is not Dictionary:
			continue
		var role := str(row.get("role", ""))
		var content := _sanitize_content(_value_to_string(row.get("content", "")))
		if content.is_empty():
			continue
		if role == "player":
			lines.append("玩家: %s" % content)
		else:
			lines.append("%s: %s" % [_display_name(npc_id), content])

	return "\n".join(lines)


func get_history_messages(npc_id: String, max_messages: int = 10) -> Array:
	var cache_arr: Array = _cache.get(npc_id, [])
	if cache_arr.is_empty():
		return []

	var start = max(0, cache_arr.size() - max_messages)
	var messages: Array = []
	for i in range(start, cache_arr.size()):
		var row = cache_arr[i]
		if row is not Dictionary:
			continue
		var role := str(row.get("role", ""))
		var content := _sanitize_content(_value_to_string(row.get("content", "")))
		if content.is_empty():
			continue
		if role == "player":
			messages.append({"role": "user", "content": content})
		elif role == "npc":
			messages.append({"role": "assistant", "content": content})
	return messages


func get_page(npc_id: String, page: int = 0, page_size: int = 20) -> Dictionary:
	var all: Array = _data.get(npc_id, [])
	var total = all.size()
	var total_pages = max(1, ceili(float(total) / page_size))
	page = clamp(page, 0, total_pages - 1)

	var end_idx = total - page * page_size
	var start_idx = max(0, end_idx - page_size)
	var page_messages: Array = []
	for i in range(start_idx, end_idx):
		page_messages.append(all[i])

	return {
		"messages": page_messages,
		"total": total,
		"page": page,
		"total_pages": total_pages
	}


func get_all_npc_history(npc_id: String) -> Array[Dictionary]:
	return (_data.get(npc_id, []) as Array).duplicate()


func get_statistics() -> Dictionary:
	var stats: Dictionary = {"total_messages": 0, "per_npc": {}}
	for npc_id in _data:
		var count = (_data[npc_id] as Array).size()
		stats["total_messages"] += count
		stats["per_npc"][npc_id] = count
	return stats


func clear_npc_history(npc_id: String) -> void:
	if _data.has(npc_id):
		_data.erase(npc_id)
	if _cache.has(npc_id):
		_cache.erase(npc_id)
	_save()


func clear_all_history() -> void:
	_data.clear()
	_cache.clear()
	var path = _data_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	print("[ChatDatabase] 已清空槽位 %d 的全部聊天记录" % _current_slot)


func clear_memory_only() -> void:
	_data.clear()
	_cache.clear()


func flush_to_disk() -> void:
	_save()


func has_any_data() -> bool:
	return not _data.is_empty()


func delete_slot_file(slot: int) -> void:
	var path = SaveConstants.chat_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[ChatDatabase] 已删除槽位 %d 的聊天记录文件" % slot)


func _display_name(npc_id: String) -> String:
	match npc_id:
		"linguide": return "林指导"
		"chentechnology": return "陈技术"
		"wangdirector": return "王主管"
		"zhaosecurity": return "赵安保"
		"conductor": return "检票员"
		"gearleft": return "齿轮·左"
		"springright": return "弹簧·右"
	return npc_id


func _sanitize_loaded_data() -> bool:
	var changed := false
	for npc_id in _data.keys():
		var entries = _data[npc_id]
		if entries is not Array:
			_data[npc_id] = []
			changed = true
			continue
		var cleaned_entries: Array = []
		for entry in entries:
			if entry is not Dictionary:
				changed = true
				continue
			var clean_content := _sanitize_content(_value_to_string(entry.get("content", "")))
			if clean_content.is_empty():
				changed = true
				continue
			if clean_content != entry.get("content", ""):
				entry["content"] = clean_content
				changed = true
			cleaned_entries.append(entry)
		if cleaned_entries.size() != entries.size():
			changed = true
		_data[npc_id] = cleaned_entries
	return changed


func _value_to_string(value: Variant) -> String:
	if value == null:
		return ""
	return str(value)


func _sanitize_content(content: String) -> String:
	return content.replace("<null>", "").strip_edges()
