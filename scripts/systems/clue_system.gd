extends Node
## 线索收集系统
## 管理碎片内的线索发现、记录和提示推理

var discovered_clues: Array[Dictionary] = []     # 当前碎片中发现的线索
var clue_journal: Array[Dictionary] = []           # 线索日志（全程）

signal clue_discovered(clue: Dictionary)
signal source_mark_located(mark_name: String)
signal source_mark_decoded(mark_name: String)

func _ready() -> void:
	print("[ClueSystem] 线索系统就绪")

func reset_fragment_clues() -> void:
	discovered_clues.clear()

func discover_clue(clue_name: String, clue_type: String, description: String, location: String = "") -> void:
	var clue = {
		"name": clue_name,
		"type": clue_type,        # "hint" / "item" / "dialogue" / "observation" / "source_mark"
		"description": description,
		"location": location,
		"timestamp": Time.get_unix_time_from_system(),
		"fragment_id": FragmentManager.current_fragment.id if FragmentManager.current_fragment else "unknown"
	}
	
	discovered_clues.append(clue)
	clue_journal.append(clue)
	clue_discovered.emit(clue)
	
	GameManager.add_collected_clue("[%s] %s: %s" % [clue_type, clue_name, description])
	print("[ClueSystem] 发现线索: %s (%s)" % [clue_name, clue_type])

func locate_source_mark(mark_name: String, location_description: String) -> void:
	source_mark_located.emit(mark_name)
	discover_clue(mark_name, "source_mark", "源印定位: %s" % location_description, location_description)

func decode_source_mark(mark_name: String, decoded_text: String) -> void:
	source_mark_decoded.emit(mark_name)
	discover_clue(mark_name, "source_mark", "源印解码: %s" % decoded_text)

func get_fragment_clue_count() -> int:
	return discovered_clues.size()

func has_discovered(clue_name: String) -> bool:
	for clue in discovered_clues:
		if clue["name"] == clue_name:
			return true
	return false
