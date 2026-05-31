extends Node
## 聊天记录混合存储（按存档槽位隔离）
##   _cache: 每NPC最近N条（deque，LLM用）—— 纯内存，不落盘
##   _data:  每NPC全部消息（持久化，按槽位独立文件）
##
## 文件 user://saves/chat_{slot}.json：{ "blacksmith": [{role,content,timestamp,...},...], ... }

const CACHE_SIZE: int = 20  ## LLM注入的最大历史条数
const SAVE_DIR: String = "user://saves/"

## 内存缓存（LLM用）：{ "npc_id": Array[Dictionary] }，上限 CACHE_SIZE
var _cache: Dictionary = {}

## 全量数据（磁盘）：{ "npc_id": Array[Dictionary] }
var _data: Dictionary = {}

## 当前绑定的存档槽位
var _current_slot: int = 0


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	# 不在 _ready 中自动加载，由 SaveManager 通过 set_slot() 控制加载时机
	print("[ChatDatabase] 就绪 | 等待 SaveManager 指定槽位")


# ============================================================
# 槽位切换
# ============================================================

func set_slot(slot: int) -> void:
	## 切换到指定槽位：保存当前槽位数据，清空内存，加载新槽位
	if slot == _current_slot and not _data.is_empty():
		return  # 同槽位且已有数据，无需重新加载
	
	# 保存当前槽位
	_save()
	
	# 切换到新槽位
	_current_slot = slot
	_data.clear()
	_cache.clear()
	
	# 尝试从该槽位的会话文件恢复（崩溃恢复）
	_load()
	print("[ChatDatabase] 切换到槽位 %d | 文件: %s | NPC数: %d" % [slot, _data_path(), _data.size()])


func _data_path() -> String:
	return SAVE_DIR + "chat_%d.json" % _current_slot


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
		_rebuild_cache()


func _rebuild_cache() -> void:
	## 从全量 _data 重建每个 NPC 的最近 N 条缓存
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
	var path = _data_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		printerr("[ChatDatabase] 写入失败: %s" % path)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


# ============================================================
# 写入
# ============================================================

func log_message(npc_id: String, role: String, content: String, alert_phase: int = 0, suspicion: float = 0.0) -> void:
	if content.is_empty() or npc_id.is_empty():
		return
	
	var entry = {
		"role": role,
		"content": content,
		"timestamp": Time.get_unix_time_from_system(),
		"alert_phase": alert_phase,
		"suspicion": snapped(suspicion, 0.01)
	}
	
	# 追加到全量数据
	if not _data.has(npc_id):
		_data[npc_id] = []
	_data[npc_id].append(entry)
	
	# 追加到内存缓存（保留最近 N 条）
	if not _cache.has(npc_id):
		_cache[npc_id] = []
	var cache_arr: Array = _cache[npc_id]
	cache_arr.append(entry)
	if cache_arr.size() > CACHE_SIZE:
		cache_arr.pop_front()
	
	_save()


# ============================================================
# 查询 —— LLM 上下文（走缓存，O(1)）
# ============================================================

func get_history_as_text(npc_id: String, max_messages: int = 10) -> String:
	## 从缓存取最近N条，组装为LLM可注入的纯文本
	var cache_arr: Array = _cache.get(npc_id, [])
	if cache_arr.is_empty():
		return ""
	
	var start = max(0, cache_arr.size() - max_messages)
	var lines: Array[String] = ["## 最近对话"]
	for i in range(start, cache_arr.size()):
		var row = cache_arr[i]
		var role = row["role"]
		var content = row["content"]
		if role == "player":
			lines.append("玩家: %s" % content)
		else:
			lines.append("%s: %s" % [_display_name(npc_id), content])
	
	return "\n".join(lines)


# ============================================================
# 查询 —— 历史翻看（走全量数据，分页）
# ============================================================

func get_page(npc_id: String, page: int = 0, page_size: int = 20) -> Dictionary:
	## 分页查询历史对话（翻"记事本"用）
	## 返回 { "messages": [...], "total": int, "page": int, "total_pages": int }
	var all: Array = _data.get(npc_id, [])
	var total = all.size()
	var total_pages = max(1, ceili(float(total) / page_size))
	page = clamp(page, 0, total_pages - 1)
	
	var start_idx = page * page_size
	var end_idx = min(start_idx + page_size, total)
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


# ============================================================
# 清理
# ============================================================

func clear_npc_history(npc_id: String) -> void:
	if _data.has(npc_id):
		_data.erase(npc_id)
	if _cache.has(npc_id):
		_cache.erase(npc_id)
	_save()


func clear_all_history() -> void:
	## 清空当前槽位的全部聊天记录（同时删除文件）
	_data.clear()
	_cache.clear()
	var path = _data_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	print("[ChatDatabase] 已清空槽位 %d 的全部聊天记录" % _current_slot)


# ============================================================
# 存档集成 —— 供 SaveManager 调用
# ============================================================

func flush_to_disk() -> void:
	## 强制将当前内存中的聊天数据写入独立文件
	## 供 SaveManager 在存档前调用，确保 chat_{slot}.json 与 save_{slot}.json 一致
	_save()


func get_raw_data() -> Dictionary:
	return _data.duplicate(true)


func has_any_data() -> bool:
	## 返回当前槽位是否有任何聊天数据（供 load_game 判断是否需要从存档快照恢复）
	return not _data.is_empty()


func restore_from(raw: Dictionary) -> void:
	## 从存档文件恢复聊天数据到内存（不影响该槽位独立文件的内容）
	_data = raw.duplicate(true)
	_rebuild_cache()
	print("[ChatDatabase] 从存档恢复数据到内存 | NPC数: %d | 总消息: %d" % [_data.size(), _count_total_messages()])


func delete_slot_file(slot: int) -> void:
	## 删除指定槽位的聊天记录文件
	var path = SAVE_DIR + "chat_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[ChatDatabase] 已删除槽位 %d 的聊天记录文件" % slot)


func _count_total_messages() -> int:
	var total = 0
	for npc_id in _data:
		total += (_data[npc_id] as Array).size()
	return total


# ============================================================
# 内部
# ============================================================

func _display_name(npc_id: String) -> String:
	match npc_id:
		"blacksmith": return "老霍"
		"florist": return "阿莲"
		"baker": return "老唐"
		"gravekeeper": return "老崔"
		"violinist": return "薇拉"
		"oldpainter": return "老顾"
		"innkeeper": return "冯婶"
	return npc_id
