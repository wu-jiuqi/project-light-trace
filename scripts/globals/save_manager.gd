extends Node
## 存档管理器
## 管理游戏存档、解密计时器持久化

const SAVE_PATH = "user://save_data.json"

var save_data: Dictionary = {}

func _ready() -> void:
	# 启动时自动加载存档（如果存在）
	if load_game():
		print("[SaveManager] 存档自动加载成功")
	else:
		print("[SaveManager] 未找到存档，使用默认状态")

func save_game() -> void:
	save_data = {
		"version": "0.1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"repair_progress": GameManager.repair_progress,
		"repaired_count": GameManager.repaired_fragments,
		"current_phase": GameManager.current_phase,
		"collected_clues": GameManager.collected_clues,
		"source_mark_log": GameManager.source_mark_log,
		"company_trust": GameManager.company_trust,
		"fragments": _serialize_fragments(),
		"darkline_a": GameManager.darkline_a_revealed,
		"darkline_b": GameManager.darkline_b_revealed,
		"darkline_c": GameManager.darkline_c_unlocked,
		"npc_state_cache": GameManager.npc_state_cache,  # NPC跨场景状态
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] 存档保存成功")

func load_game() -> bool:
	_load_save()
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
	
	# 恢复 NPC 持久化状态
	var cached = save_data.get("npc_state_cache", {})
	if cached is Dictionary:
		GameManager.npc_state_cache = cached
	
	_deserialize_fragments(save_data.get("fragments", []))
	_resume_decrypt_timers()
	
	print("[SaveManager] 存档加载成功")
	return true

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data = {}
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			save_data = json.get_data()
		file.close()

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
