extends Node
## 游戏全局状态管理器
## 管理游戏核心状态：当前阶段、修复进度、暗线揭示状态等
##
## 碎片 #0762 专属状态（awakened_colors, melody_triggered 等）
## 已迁移至 FragmentManager._fragment_states["0762"]
## GameManager 保留操作方法，内部委托给 FragmentManager

# === 游戏阶段 ===
enum GamePhase {
	INIT,           # 初始教程
	EXPLORATION,    # 自由探索碎片
	CRISIS_A,       # 暗线A揭示中
	CRISIS_B,       # 暗线B揭示中（公司断连）
	FORUM_UNLOCKED, # 跨维论坛已解锁
	ENDGAME         # 终局选择
}

# === 全局状态变量 ===
var current_phase: int = GamePhase.INIT
var repair_progress: float = 0.0          # 0.0 ~ 1.0 修复进度
var total_fragments: int = 12              # MVP：12个碎片
var repaired_fragments: int = 0
var player_name: String = "溯光者-07"
var company_name: String = "天枢公司"
var play_time_seconds: float = 0.0

# === 暗线状态 ===
var darkline_a_revealed: bool = false
var darkline_b_revealed: bool = false
var darkline_c_unlocked: bool = false
var company_trust: float = 1.0            # 公司信任度（影响暗线B）

# === 已收集的线索（跨副本） ===
var collected_clues: Array[String] = [] as Array[String]
var source_mark_log: Array[Dictionary] = []  # 已解码的源印记录
var items_used: Dictionary = {}             # 已被消耗的物品（交给NPC后标记）

# === 碎片 #0762 六色觉醒系统常量 ===
## 实际数据存储在 FragmentManager._fragment_states["0762"] 中
## GameManager 保留以下常量和操作方法，内部委托 FragmentManager
enum ColorType { RED, BLUE, YELLOW, GREEN, PURPLE, WHITE }
const COLOR_NAME: Array = ["红", "蓝", "黄", "绿", "紫", "白"]
const COLOR_NPC: Array = ["blacksmith", "florist", "baker", "gravekeeper", "violinist", "statue"]
signal color_awakened(color_type: int, npc_id: String)

# === NPC 状态持久化（跨场景/重进房间不重置） ===
## 格式: { "scene_name:npc_kb_id": { "position_x":float, "position_y":float, "suspicion":float, "alert_phase":int, "doubts":bool } }
var npc_state_cache: Dictionary = {}
var npc_visit_count: Dictionary = { "gravekeeper": 0 }

func save_npc_state(scene_name: String, npc_kb_id: String, pos: Vector2, suspicion: float, alert_phase: int, doubts: bool) -> void:
	var key = "%s:%s" % [scene_name, npc_kb_id]
	npc_state_cache[key] = {
		"position_x": pos.x, "position_y": pos.y,
		"suspicion": suspicion, "alert_phase": alert_phase, "doubts": doubts
	}

func load_npc_state(scene_name: String, npc_kb_id: String) -> Dictionary:
	var key = "%s:%s" % [scene_name, npc_kb_id]
	return npc_state_cache.get(key, {})

func clear_npc_state(scene_name: String) -> void:
	## 清除指定场景的所有NPC状态（用于颜色觉醒等重置场景）
	var to_remove: Array[String] = [] as Array[String]
	for key in npc_state_cache:
		if key.begins_with(scene_name + ":"):
			to_remove.append(key)
	for key in to_remove:
		npc_state_cache.erase(key)


# ============================================================
# 六色觉醒操作（委托 FragmentManager 存储）
# ============================================================

func get_awakened_colors() -> Array:
	## 返回 awakened_colors 数组的副本
	var colors = FragmentManager.get_fragment_state("0762", "awakened_colors")
	if colors is Array and colors.size() == 6:
		return colors.duplicate()
	return [false, false, false, false, false, false]

func awaken_color(color_type: int) -> void:
	if color_type < 0 or color_type >= 6: return
	var colors: Array = FragmentManager.get_fragment_state("0762", "awakened_colors")
	if colors.size() != 6:
		colors = [false, false, false, false, false, false]
	if colors[color_type]: return
	colors[color_type] = true
	FragmentManager.set_fragment_state("0762", "awakened_colors", colors)
	print("[GameManager] 颜色觉醒: %s → %s (%d/6)" % [COLOR_NAME[color_type], COLOR_NPC[color_type], _count_awakened()])
	color_awakened.emit(color_type, COLOR_NPC[color_type])

func is_color_awakened(color_type: int) -> bool:
	var colors: Array = FragmentManager.get_fragment_state("0762", "awakened_colors")
	if colors.size() != 6:
		return false
	return colors[color_type] if color_type >= 0 and color_type < colors.size() else false

func _count_awakened() -> int:
	var colors: Array = FragmentManager.get_fragment_state("0762", "awakened_colors")
	var c = 0
	for a in colors: if a: c += 1
	return c


# ============================================================
# 物品使用标记
# ============================================================

func mark_item_used(key: String) -> void:
	items_used[key] = true

func is_item_used(key: String) -> bool:
	return items_used.get(key, false)


# ============================================================
# NPC 拜访计数
# ============================================================

func record_npc_visit(npc_kb_id: String) -> void:
	if not npc_visit_count.has(npc_kb_id): return
	npc_visit_count[npc_kb_id] += 1

func get_visit_count(npc_kb_id: String) -> int: return npc_visit_count.get(npc_kb_id, 0)


# ============================================================
# 信号
# ============================================================

signal phase_changed(new_phase: int)
signal progress_updated(progress: float)
signal fragment_repaired(fragment_id: String)
signal decryption_complete(fragment_id: String)
signal clue_collected(clue: String)

func _ready() -> void:
	print("[GameManager] 溯光计划 V0.1.0")


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene.name == "TitleScreen" or scene.scene_file_path == "res://scenes/ui/title_screen.tscn":
		return
	play_time_seconds += delta


# ============================================================
# 游戏流程控制
# ============================================================

func new_game() -> void:
	## 重置所有状态到初始值（开始新游戏/重新挑战）
	current_phase = GamePhase.INIT
	repair_progress = 0.0
	repaired_fragments = 0
	play_time_seconds = 0.0
	company_trust = 1.0
	darkline_a_revealed = false
	darkline_b_revealed = false
	darkline_c_unlocked = false
	collected_clues.clear()
	source_mark_log.clear()
	items_used.clear()
	npc_visit_count = {"gravekeeper": 0}
	npc_state_cache.clear()
	
	# 重置碎片 #0762 专属状态（委托 FragmentManager）
	FragmentManager.reset_fragment_states("0762")
	
	# 重置所有碎片完成状态
	FragmentManager.reset_all_fragments()
	
	print("[GameManager] 状态已重置（新游戏）")


func reset_fragment() -> void:
	## 重新挑战关卡时重置关卡内进度（保留跨存档的对话历史与NPC信任/警觉状态）
	## 对话历史 (ChatDatabase) 和 NPC 状态缓存 (npc_state_cache) 跟随存档持久化，
	## 不会在重新进入关卡时清除——玩家可以通过加载存档找回之前的对话记录。
	items_used.clear()
	
	# 重置碎片 #0762 专属状态（委托 FragmentManager）
	FragmentManager.reset_fragment_states("0762")
	
	print("[GameManager] 碎片关卡内进度已重置（对话历史与NPC信任状态已保留）")


func set_phase(new_phase: int) -> void:
	if current_phase != new_phase:
		current_phase = new_phase
		phase_changed.emit(new_phase)
		print("[GameManager] 阶段变更: %d" % new_phase)

func add_repair_progress(amount: float) -> void:
	repair_progress = clampf(repair_progress + amount, 0.0, 1.0)
	progress_updated.emit(repair_progress)

func record_source_mark(fragment_id: String, mark_name: String, hint_clue: String) -> void:
	# 重复完成防护：检查是否已经记录过该碎片的源印
	for entry in source_mark_log:
		if entry.get("fragment_id", "") == fragment_id:
			print("[GameManager] 碎片 %s 的源印已记录，跳过重复增加进度" % fragment_id)
			return
	
	source_mark_log.append({
		"fragment_id": fragment_id,
		"mark_name": mark_name,
		"hint_clue": hint_clue,
		"timestamp": Time.get_unix_time_from_system()
	})
	repaired_fragments += 1
	add_repair_progress(1.0 / total_fragments)
	fragment_repaired.emit(fragment_id)
	print("[GameManager] 源印记录: %s -> %s | 跨副本线索: %s" % [fragment_id, mark_name, hint_clue])

func add_collected_clue(clue: String) -> void:
	if clue not in collected_clues:
		collected_clues.append(clue)
		clue_collected.emit(clue)
		print("[GameManager] 线索收集: %s" % clue)


# ============================================================
# 序列化接口 — 供 SaveManager 调用
# ============================================================

func to_dict() -> Dictionary:
	## 将全局状态序列化为字典（不含碎片专属状态）
	return {
		"play_time_seconds": play_time_seconds,
		"repair_progress": repair_progress,
		"current_phase": current_phase,
		"player_name": player_name,
		"company_trust": company_trust,
		"darkline_a_revealed": darkline_a_revealed,
		"darkline_b_revealed": darkline_b_revealed,
		"darkline_c_unlocked": darkline_c_unlocked,
		"collected_clues": collected_clues.duplicate(),
		"source_mark_log": source_mark_log.duplicate(true),
		"items_used": items_used.duplicate(),
		"npc_state_cache": npc_state_cache.duplicate(true),
		"npc_visit_count": npc_visit_count.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	## 从字典恢复所有全局状态，缺失字段使用默认值
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	repair_progress = float(data.get("repair_progress", 0.0))
	current_phase = int(data.get("current_phase", GamePhase.INIT))
	player_name = str(data.get("player_name", "溯光者-07"))
	company_trust = float(data.get("company_trust", 1.0))
	darkline_a_revealed = bool(data.get("darkline_a_revealed", false))
	darkline_b_revealed = bool(data.get("darkline_b_revealed", false))
	darkline_c_unlocked = bool(data.get("darkline_c_unlocked", false))
	
	collected_clues = (data.get("collected_clues", []) as Array).duplicate()
	
	var sml = data.get("source_mark_log", [])
	source_mark_log.clear()
	if sml is Array:
		for entry in sml:
			if entry is Dictionary:
				source_mark_log.append(entry.duplicate(true))
	
	var iu = data.get("items_used", {})
	if iu is Dictionary:
		items_used = iu.duplicate()
	else:
		items_used.clear()
	
	var npc_cache = data.get("npc_state_cache", {})
	if npc_cache is Dictionary:
		npc_state_cache = npc_cache.duplicate(true)
	else:
		npc_state_cache.clear()
	
	var visits = data.get("npc_visit_count", {})
	if visits is Dictionary:
		npc_visit_count = visits.duplicate()
	else:
		npc_visit_count = {"gravekeeper": 0}
