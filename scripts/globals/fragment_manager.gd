extends Node
## 碎片管理器
## 管理所有碎片的开放、进入、修复与星图归位状态。
##
## 碎片专属状态存储于 _fragment_states 字典中，按 fragment_id 命名空间隔离。


class FragmentData:
	var id: String
	var name: String
	var world_name: String
	var hint: String
	var source_mark_name: String
	var difficulty: int
	var is_story_critical: bool
	var scene_path: String
	var implemented: bool
	var unlocked: bool = false
	var completed: bool = false

	func _init(
		p_id: String,
		p_name: String,
		p_world: String,
		p_hint: String,
		p_source: String,
		p_difficulty: int,
		p_critical: bool,
		p_scene: String,
		p_implemented: bool = false
	) -> void:
		id = p_id
		name = p_name
		world_name = p_world
		hint = p_hint
		source_mark_name = p_source
		difficulty = p_difficulty
		is_story_critical = p_critical
		scene_path = p_scene
		implemented = p_implemented


# === 碎片列表 ===
var fragments: Array[FragmentData] = []
var current_fragment: FragmentData = null
var pending_completion_animation_id: String = ""
var pending_unlocked_fragment_id: String = ""

const LINEAR_UNLOCK_ORDER: Array[String] = [
	"0001", "0002", "0003", "0004", "0047",
	"0915", "1138", "2049", "3015", "3333", "4096",
]

# === 碎片专属状态存储 ===
## 格式: { "0002": { "seat_selection": {...} }, ... }
var _fragment_states: Dictionary = {}

# === 重玩模式标记 ===
## 当进入一个已完成的碎片时为 true，表示当前为重玩模式
var is_replay_mode: bool = false

# === 信号 ===
signal fragment_entered(fragment_id: String)
signal fragment_completed(fragment_id: String)


func _ready() -> void:
	_initialize_fragments()
	_ensure_default_fragment_states()
	print("[FragmentManager] 碎片系统初始化完成，共 %d 个碎片" % fragments.size())


func _initialize_fragments() -> void:
	fragments = [
		FragmentData.new("0001", "启程之镇", "晨曦镇", "「白日依山尽」", "晨曦之印", 1, false, "res://scenes/fragments/fragment_0001.tscn", true),
		FragmentData.new("0002", "黄昏驿站", "落霞驿站", "「黄河入海流」", "归途之印", 1, false, "res://scenes/fragments/fragment_0002.tscn", true),
		FragmentData.new("0003", "月下道观", "玉兔道观", "「举头望明月」", "月光之印", 1, false, "res://scenes/fragments/fragment_0003.tscn", true),
		FragmentData.new("0004", "工坊物语", "齿轮工坊", "「匠心」", "匠魂之印", 2, false, "res://scenes/fragments/fragment_0004.tscn", true),
		FragmentData.new("0047", "倒悬图书馆", "知识之塔", "「知识就是力量」", "真理之印", 3, true, "res://scenes/fragments/fragment_0047.tscn"),
		FragmentData.new("0915", "遗忘庭院", "记忆庭院", "「遗忘」", "记忆之印", 2, false, "res://scenes/fragments/fragment_0915.tscn"),
		FragmentData.new("1138", "时钟停摆的车站", "永驻站", "「再见」", "时间之印", 3, true, "res://scenes/fragments/fragment_1138.tscn"),
		FragmentData.new("2049", "镜中人", "双面町", "「我是谁」", "自我之印", 4, true, "res://scenes/fragments/fragment_2049.tscn"),
		FragmentData.new("3015", "零时档案馆", "零时回廊", "「3:15」", "溯源之印", 5, true, "res://scenes/fragments/fragment_3015.tscn"),
		FragmentData.new("3333", "诸神黄昏", "终焉之谷", "「终即是始」", "轮回之印", 5, true, "res://scenes/fragments/fragment_3333.tscn"),
		FragmentData.new("4096", "万象归源", "万象之心", "「归源」", "归源之印", 5, true, "res://scenes/fragments/fragment_4096.tscn"),
	]
	_apply_initial_unlocks()


func _apply_initial_unlocks() -> void:
	for fragment in fragments:
		fragment.unlocked = fragment.id == LINEAR_UNLOCK_ORDER[0]


func _ensure_default_fragment_states() -> void:
	## 初始化所有已知碎片的默认专属状态
	if not _fragment_states.has("0002"):
		_fragment_states["0002"] = {
			"seat_selection": {},
			"left_npc_id": "",
			"source_mark_ticket_collected": false,
			"completed": false,
		}
	if not _fragment_states.has("0003"):
		_fragment_states["0003"] = {
			"jade_collected": 0,
			"jade_gallery_collected": 0,
			"wash_hands": 0,
			"lantern_lit": 0,
			"jade_offered": 0,
			"clapped": 0,
			"moon_viewed": 0,
			"mirror_opened": 0,
			"ritual_sequence": [],
			"ritual_sequence_invalid": false,
			"inscription_order": [],
			"completed": false,
		}
	if not _fragment_states.has("0004"):
		_fragment_states["0004"] = {
			"collected_materials": {},
			"collected_blueprints": {},
			"completed": false,
			"assembly_solved": false,
			"forgeheart_collected": false,
			"wrong_combination_count": 0,
			"pendulum_broadcasts": {},
		}


# ============================================================
# 碎片查询
# ============================================================

func get_fragment_by_id(id: String) -> FragmentData:
	for fragment in fragments:
		if fragment.id == id:
			return fragment
	return null


func get_available_fragments() -> Array[FragmentData]:
	var available: Array[FragmentData] = []
	for fragment in fragments:
		if fragment.implemented and fragment.unlocked:
			available.append(fragment)
	return available


# ============================================================
# 碎片进入 / 完成
# ============================================================

func enter_fragment(fragment: FragmentData, reset_run: bool = false) -> bool:
	if not fragment.unlocked:
		return false
	if not fragment.implemented:
		return false
	
	# 在切换碎片前自动存档（如果存在活跃槽位）
	var current_slot: int = -1
	if SaveManager:
		current_slot = SaveManager.get_current_slot()
	if current_slot >= 0:
		SaveManager.save_game(current_slot)
	
	# 保存当前碎片的 completed 状态（GameManager.reset_fragment 会重置 fragment_states）
	var was_completed: bool = fragment.completed
	
	current_fragment = fragment
	if reset_run:
		reset_fragment_run(fragment.id)
	
	# 设置重玩标记（在 reset_fragment 之后，避免被重置）
	is_replay_mode = was_completed
	
	fragment_entered.emit(fragment.id)
	print("[FragmentManager] 进入碎片 %s: %s (replay=%s)" % [fragment.id, fragment.name, is_replay_mode])
	return true


func reset_fragment_run(fragment_id: String = "") -> void:
	var target_id := fragment_id
	if target_id.is_empty() and current_fragment != null:
		target_id = current_fragment.id
	if target_id.is_empty():
		return
	if GameManager:
		GameManager.items_used.clear()
	reset_fragment_states(target_id)


func complete_fragment(fragment: FragmentData) -> bool:
	if fragment == null or fragment.completed:
		return false
	fragment.completed = true
	pending_completion_animation_id = fragment.id
	unlock_next_fragment(fragment.id)
	fragment_completed.emit(fragment.id)
	print("[FragmentManager] 碎片 %s 修复完成" % fragment.id)
	return true


func consume_completion_animation_id() -> String:
	var fragment_id = pending_completion_animation_id
	pending_completion_animation_id = ""
	return fragment_id


func unlock_next_fragment(completed_id: String) -> String:
	var index := LINEAR_UNLOCK_ORDER.find(completed_id)
	if index < 0 or index >= LINEAR_UNLOCK_ORDER.size() - 1:
		return ""
	var next_id := LINEAR_UNLOCK_ORDER[index + 1]
	var next_fragment := get_fragment_by_id(next_id)
	if next_fragment == null:
		return ""
	if not next_fragment.unlocked:
		next_fragment.unlocked = true
		pending_unlocked_fragment_id = next_id
		print("[FragmentManager] Linear unlock: %s -> %s" % [completed_id, next_id])
		if WebPackManager and WebPackManager.has_method("prefetch_pack"):
			WebPackManager.prefetch_pack(next_id)
	return next_id


func consume_pending_unlocked_fragment_id() -> String:
	var fragment_id := pending_unlocked_fragment_id
	pending_unlocked_fragment_id = ""
	return fragment_id


func ensure_linear_unlocks_from_completed() -> void:
	var highest_unlocked_index := 0
	for i in LINEAR_UNLOCK_ORDER.size():
		var fragment := get_fragment_by_id(LINEAR_UNLOCK_ORDER[i])
		if fragment != null and fragment.completed:
			highest_unlocked_index = mini(i + 1, LINEAR_UNLOCK_ORDER.size() - 1)
	for i in LINEAR_UNLOCK_ORDER.size():
		var fragment := get_fragment_by_id(LINEAR_UNLOCK_ORDER[i])
		if fragment != null:
			fragment.unlocked = i <= highest_unlocked_index


# ============================================================
# 碎片状态重置
# ============================================================

func reset_all_fragments() -> void:
	## 重置所有碎片的 completed 标记为 false，并清除所有碎片专属状态
	for fragment in fragments:
		fragment.completed = false
		fragment.unlocked = false
	pending_completion_animation_id = ""
	pending_unlocked_fragment_id = ""
	is_replay_mode = false
	_apply_initial_unlocks()
	# 清除碎片专属状态，防止跨存档泄露（如线索数据）
	_fragment_states.clear()
	_ensure_default_fragment_states()
	print("[FragmentManager] 所有 %d 个碎片已重置为未修复状态" % fragments.size())


func reset_fragment_states(fragment_id: String) -> void:
	## 重置指定碎片的专属状态为默认值
	match fragment_id:
		"0002":
			_fragment_states["0002"] = {
				"seat_selection": {},
				"left_npc_id": "",
				"source_mark_ticket_collected": false,
				"completed": false,
			}
			print("[FragmentManager] 碎片 %s 的专属状态已重置" % fragment_id)
		"0003":
			_fragment_states["0003"] = {
				"jade_collected": 0,
				"jade_gallery_collected": 0,
				"wash_hands": 0,
				"lantern_lit": 0,
				"jade_offered": 0,
				"clapped": 0,
				"moon_viewed": 0,
				"mirror_opened": 0,
				"ritual_sequence": [],
				"ritual_sequence_invalid": false,
				"inscription_order": [],
				"completed": false,
			}
			print("[FragmentManager] Fragment %s state reset" % fragment_id)
		"0004":
			_fragment_states["0004"] = {
				"collected_materials": {},
				"collected_blueprints": {},
				"completed": false,
				"assembly_solved": false,
				"forgeheart_collected": false,
				"wrong_combination_count": 0,
				"pendulum_broadcasts": {},
			}
			print("[FragmentManager] Fragment %s state reset" % fragment_id)
		_:
			_fragment_states.erase(fragment_id)
			print("[FragmentManager] 碎片 %s 无专属默认状态，已清除运行态" % fragment_id)


# ============================================================
# 碎片专属状态存取
# ============================================================

func get_fragment_state(fragment_id: String, key: String):
	## 获取某碎片的专属状态值
	## 如果碎片不存在于 _fragment_states 中，返回对应类型的默认值
	if not _fragment_states.has(fragment_id):
		return null
	
	var states: Dictionary = _fragment_states[fragment_id]
	if not states.has(key):
		return null
	
	var value = states[key]
	# 数组和字典类型返回副本，防止外部修改
	if value is Array:
		return value.duplicate()
	if value is Dictionary:
		return value.duplicate(true)
	return value


func set_fragment_state(fragment_id: String, key: String, value) -> void:
	## 设置某碎片的专属状态值
	if not _fragment_states.has(fragment_id):
		_fragment_states[fragment_id] = {}
	
	var states: Dictionary = _fragment_states[fragment_id]
	# 数组和字典类型存储副本
	if value is Array:
		states[key] = value.duplicate()
	elif value is Dictionary:
		states[key] = value.duplicate(true)
	else:
		states[key] = value


# ============================================================
# 序列化接口 — 供 SaveManager 调用
# ============================================================

func get_fragments_list() -> Array[Dictionary]:
	## 返回所有碎片的 id 和 completed 状态列表
	var result: Array[Dictionary] = []
	for f in fragments:
		result.append({
			"id": f.id,
			"completed": f.completed,
			"unlocked": f.unlocked,
		})
	return result


func get_fragment_states_dict() -> Dictionary:
	## 收集所有有专属状态的碎片状态，深拷贝后返回
	var result: Dictionary = {}
	for fragment_id in _fragment_states:
		result[fragment_id] = _fragment_states[fragment_id].duplicate(true)
	return result


func apply_fragment_states(states: Dictionary) -> void:
	## 将 fragment_states 字典应用到对应碎片的专属状态
	## 先清除旧状态再应用，防止跨存档状态泄露
	_fragment_states.clear()
	_ensure_default_fragment_states()
	
	if states.is_empty():
		return
	
	for fragment_id in states:
		var clean_fragment_id := str(fragment_id)
		if get_fragment_by_id(clean_fragment_id) == null:
			continue
		var state_data = states[fragment_id]
		if state_data is Dictionary:
			_fragment_states[clean_fragment_id] = state_data.duplicate(true)
	
	print("[FragmentManager] 已应用 %d 个碎片的专属状态" % states.size())
