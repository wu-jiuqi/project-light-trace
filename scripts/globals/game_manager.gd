extends Node
## 游戏全局状态管理器
## 管理游戏核心状态：当前阶段、修复进度、暗线揭示状态等

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

# === 暗线状态 ===
var darkline_a_revealed: bool = false
var darkline_b_revealed: bool = false
var darkline_c_unlocked: bool = false
var company_trust: float = 1.0            # 公司信任度（影响暗线B）

# === 已收集的线索（跨副本） ===
var collected_clues: Array[String] = []
var source_mark_log: Array[Dictionary] = []  # 已解码的源印记录
var items_used: Dictionary = {}             # 已被消耗的物品（交给NPC后标记）

# === 碎片 #0762 六色觉醒系统（全局共享，跨场景） ===
enum ColorType { RED, BLUE, YELLOW, GREEN, PURPLE, WHITE }
const COLOR_NAME: Array = ["红", "蓝", "黄", "绿", "紫", "白"]
const COLOR_NPC: Array = ["blacksmith", "florist", "baker", "gravekeeper", "violinist", "statue"]

var awakened_colors: Array[bool] = [false, false, false, false, false, false]
var npc_visit_count: Dictionary = { "gravekeeper": 0 }
signal color_awakened(color_type: int, npc_id: String)

# === NPC 状态持久化（跨场景/重进房间不重置） ===
## 格式: { "scene_name:npc_kb_id": { "position_x":float, "position_y":float, "suspicion":float, "alert_phase":int, "doubts":bool } }
var npc_state_cache: Dictionary = {}

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
	var to_remove: Array[String] = []
	for key in npc_state_cache:
		if key.begins_with(scene_name + ":"):
			to_remove.append(key)
	for key in to_remove:
		npc_state_cache.erase(key)

func awaken_color(color_type: int) -> void:
	if color_type < 0 or color_type >= awakened_colors.size(): return
	if awakened_colors[color_type]: return
	awakened_colors[color_type] = true
	print("[GameManager] 颜色觉醒: %s → %s (%d/6)" % [COLOR_NAME[color_type], COLOR_NPC[color_type], _count_awakened()])
	color_awakened.emit(color_type, COLOR_NPC[color_type])

func is_color_awakened(color_type: int) -> bool: return awakened_colors[color_type]

func _count_awakened() -> int:
	var c = 0
	for a in awakened_colors: if a: c += 1
	return c

func mark_item_used(key: String) -> void:
	items_used[key] = true

func is_item_used(key: String) -> bool:
	return items_used.get(key, false)

func record_npc_visit(npc_kb_id: String) -> void:
	if not npc_visit_count.has(npc_kb_id): return
	npc_visit_count[npc_kb_id] += 1

func get_visit_count(npc_kb_id: String) -> int: return npc_visit_count.get(npc_kb_id, 0)

# === 碎片 #0762 进度标记（全局） ===
var melody_triggered: bool = false      # 老画家旋律（紫色前提）
var source_mark_revealed: bool = false   # 源印已显现
var fragment_completed: bool = false     # 碎片已完成

# === 信号 ===
signal phase_changed(new_phase: int)
signal progress_updated(progress: float)
signal fragment_repaired(fragment_id: String)
signal decryption_complete(fragment_id: String)
signal clue_collected(clue: String)

func _ready() -> void:
	print("[GameManager] 溯光计划启动 - 归源计划 V0.1.0")

func new_game() -> void:
	## 重置所有状态到初始值（开始新游戏/重新挑战）
	current_phase = GamePhase.INIT
	repair_progress = 0.0
	repaired_fragments = 0
	company_trust = 1.0
	darkline_a_revealed = false
	darkline_b_revealed = false
	darkline_c_unlocked = false
	collected_clues.clear()
	source_mark_log.clear()
	items_used.clear()
	awakened_colors = [false, false, false, false, false, false]
	npc_visit_count = {"gravekeeper": 0}
	npc_state_cache.clear()
	melody_triggered = false
	source_mark_revealed = false
	fragment_completed = false
	
	# 重置所有碎片解密/完成状态
	FragmentManager.reset_all_fragments()
	
	print("[GameManager] 状态已重置（新游戏）")

func reset_fragment() -> void:
	## 重新挑战关卡时重置关卡内进度（保留跨存档的对话历史与NPC信任/警觉状态）
	## 对话历史 (ChatDatabase) 和 NPC 状态缓存 (npc_state_cache) 跟随存档持久化，
	## 不会在重新进入关卡时清除——玩家可以通过加载存档找回之前的对话记录。
	items_used.clear()
	awakened_colors = [false, false, false, false, false, false]
	npc_visit_count = {"gravekeeper": 0}
	melody_triggered = false
	source_mark_revealed = false
	fragment_completed = false
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
