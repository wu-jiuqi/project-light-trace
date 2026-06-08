extends RefCounted
## 存档版本迁移框架
## 管理存档格式的版本升级，支持逐版本迁移
## 旧版本存档加载时自动检测并执行迁移链

class_name SaveMigration


## 版本字符串 → 迁移函数名的映射表
## 键为旧版本号，值为迁移函数名（私有静态方法）
const MIGRATIONS: Dictionary = {
	"0.3.0": "_migrate_0_3_0_to_1_0_0",
}


## 对存档数据执行版本迁移
## 循环检查版本号，依次调用迁移函数，直到版本为 SAVE_VERSION
## 如果当前版本不在 MIGRATIONS 中且不等于 SAVE_VERSION，则返回空字典
static func migrate(data: Dictionary) -> Dictionary:
	if data.is_empty():
		printerr("[SaveMigration] 迁移失败: 输入数据为空")
		return {}

	var current_version: String = str(data.get("version", "0.0.0"))

	# 已经是目标版本，无需迁移
	if _version_eq(current_version, SaveConstants.SAVE_VERSION):
		return data

	var max_iterations: int = 20  # 防止无限循环
	var iteration: int = 0

	while not _version_eq(current_version, SaveConstants.SAVE_VERSION):
		iteration += 1
		if iteration > max_iterations:
			printerr("[SaveMigration] 超过最大迁移迭代次数 (%d)" % max_iterations)
			return {}

		if not MIGRATIONS.has(current_version):
			printerr("[SaveMigration] 无可用的迁移函数: 版本 %s → 下一个版本" % current_version)
			return {}

		var func_name: String = MIGRATIONS[current_version]
		var migration_callable := Callable(SaveMigration, func_name)
		if not migration_callable.is_valid():
			printerr("[SaveMigration] 迁移函数不存在: %s" % func_name)
			return {}

		print("[SaveMigration] 执行迁移: %s (版本 %s → ...)" % [func_name, current_version])
		data = migration_callable.call(data)

		if data.is_empty():
			printerr("[SaveMigration] 迁移函数 %s 返回空数据" % func_name)
			return {}

		current_version = str(data.get("version", "0.0.0"))

	print("[SaveMigration] 迁移完成: 版本 %s" % current_version)
	return data


## 判断存档数据是否需要版本迁移
static func needs_migration(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	var current_version: String = str(data.get("version", "0.0.0"))
	return _version_lt(current_version, SaveConstants.SAVE_VERSION)


## 语义化版本号比较: v1 < v2
## 拆分版本字符串为整数数组，逐段比较
static func _version_lt(v1: String, v2: String) -> bool:
	var parts1: PackedStringArray = v1.split(".")
	var parts2: PackedStringArray = v2.split(".")

	var max_len: int = maxi(parts1.size(), parts2.size())
	for i in range(max_len):
		var n1: int = int(parts1[i]) if i < parts1.size() else 0
		var n2: int = int(parts2[i]) if i < parts2.size() else 0
		if n1 < n2:
			return true
		if n1 > n2:
			return false
	return false  # 相等


## 语义化版本号比较: v1 == v2
static func _version_eq(v1: String, v2: String) -> bool:
	return not _version_lt(v1, v2) and not _version_lt(v2, v1)


## 迁移: 0.3.0 → 1.0.0
## 将旧格式的扁平字段映射到新的 global / fragments / fragment_states 三层结构
static func _migrate_0_3_0_to_1_0_0(data: Dictionary) -> Dictionary:
	print("[SaveMigration] 开始迁移 0.3.0 → 1.0.0")

	var result: Dictionary = {
		"version": "1.0.0",
		"slot": data.get("slot", 0),
		"timestamp": data.get("timestamp", 0),
		"timestamp_readable": data.get("timestamp_readable", ""),
		"save_name": data.get("save_name", "溯光档案 01"),
		"checksum": "",  # 稍后由 SaveManager 填充
		"global": {},
		"fragments": [],
		"fragment_states": {},
	}

	# === 构建 global 子字典 ===
	var global: Dictionary = {
		"play_time_seconds": float(data.get("play_time_seconds", 0.0)),
		"repair_progress": float(data.get("repair_progress", 0.0)),
		"current_phase": int(data.get("current_phase", 0)),
		"player_name": str(data.get("player_name", "溯光者-07")),
		"company_trust": float(data.get("company_trust", 1.0)),
		"darkline_a_revealed": bool(data.get("darkline_a", false)),
		"darkline_b_revealed": bool(data.get("darkline_b", false)),
		"darkline_c_unlocked": bool(data.get("darkline_c", false)),
		"collected_clues": _duplicate_array(data.get("collected_clues", [])),
		"source_mark_log": _duplicate_dict_array(data.get("source_mark_log", [])),
		"items_used": _duplicate_dict(data.get("items_used", {})),
		"inventory": _duplicate_array(data.get("inventory", [])),
		"npc_state_cache": _duplicate_dict(data.get("npc_state_cache", {})),
		"npc_visit_count": _duplicate_dict(data.get("npc_visit_count", {})),
	}

	result["global"] = global

	# === 构建 fragments 数组 ===
	var old_fragments: Array = data.get("fragments", [])
	var fragments: Array = []
	for f in old_fragments:
		if f is Dictionary:
			fragments.append({
				"id": str(f.get("id", "")),
				"completed": bool(f.get("completed", false)),
			})
	result["fragments"] = fragments

	# === 构建 fragment_states 子字典（碎片 #0762 专属状态） ===
	var fragment_states: Dictionary = {}

	var state_0762: Dictionary = {}
	state_0762["awakened_colors"] = _duplicate_array(data.get("awakened_colors", [false, false, false, false, false, false]))
	state_0762["melody_triggered"] = bool(data.get("melody_triggered", false))
	state_0762["source_mark_revealed"] = bool(data.get("source_mark_revealed", false))
	state_0762["fragment_completed"] = bool(data.get("fragment_completed", false))
	state_0762["white_ready"] = bool(data.get("white_ready", false))
	state_0762["gray_cloth_uncovered"] = bool(data.get("gray_cloth_uncovered", false))
	state_0762["oldpainter_trust"] = float(data.get("oldpainter_trust", 0.0))

	fragment_states["0762"] = state_0762

	# 检查是否已有 fragment_states 字段（避免覆盖）
	if data.has("fragment_states") and data["fragment_states"] is Dictionary:
		var existing_states: Dictionary = data["fragment_states"]
		for fragment_id in existing_states:
			if not fragment_states.has(fragment_id):
				fragment_states[fragment_id] = existing_states[fragment_id]

	result["fragment_states"] = fragment_states

	print("[SaveMigration] 迁移 0.3.0 → 1.0.0 完成")
	return result


## 安全复制数组
static func _duplicate_array(arr) -> Array:
	if arr is Array:
		return arr.duplicate(true)
	return []


## 安全复制字典
static func _duplicate_dict(d) -> Dictionary:
	if d is Dictionary:
		return d.duplicate(true)
	return {}


## 安全复制字典数组
static func _duplicate_dict_array(arr) -> Array:
	if not arr is Array:
		return []
	var result: Array = []
	for item in arr:
		if item is Dictionary:
			result.append(item.duplicate(true))
		else:
			result.append(item)
	return result
