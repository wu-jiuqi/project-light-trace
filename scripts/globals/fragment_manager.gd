extends Node
## 碎片管理器
## 管理所有碎片的开放、进入、修复与星图归位状态。


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


var fragments: Array[FragmentData] = []
var current_fragment: FragmentData = null
var pending_completion_animation_id: String = ""

signal fragment_entered(fragment_id: String)
signal fragment_completed(fragment_id: String)


func _ready() -> void:
	_initialize_fragments()
	print("[FragmentManager] 碎片系统初始化完成，共 %d 个碎片" % fragments.size())


func _initialize_fragments() -> void:
	fragments = [
		FragmentData.new("0001", "启程之镇", "晨露镇", "「白日依山尽」", "晨曦之印", 1, false, "res://scenes/fragments/fragment_0001.tscn"),
		FragmentData.new("0002", "黄昏驿站", "落霞驿站", "「黄河入海流」", "归途之印", 1, false, "res://scenes/fragments/fragment_0002.tscn"),
		FragmentData.new("0003", "月下神社", "玉兔神社", "「举头望明月」", "月光之印", 1, false, "res://scenes/fragments/fragment_0003.tscn"),
		FragmentData.new("0004", "工坊物语", "齿轮工坊", "「匠心」", "匠魂之印", 2, false, "res://scenes/fragments/fragment_0004.tscn"),
		FragmentData.new("0047", "倒悬图书馆", "知识之塔", "「知识就是力量」", "真理之印", 3, true, "res://scenes/fragments/fragment_0047.tscn"),
		FragmentData.new("0762", "颜色的葬礼", "灰白小镇", "「蓝是悲，红是怒，黄是望，绿是惧，紫是念，白是忘」", "情感之印", 3, true, "res://scenes/fragments/fragment_0762.tscn", true),
		FragmentData.new("0915", "遗忘庭院", "记忆庭院", "「遗忘」", "记忆之印", 2, false, "res://scenes/fragments/fragment_0915.tscn"),
		FragmentData.new("1138", "时钟停摆的车站", "永驻站", "「再见」", "时间之印", 3, true, "res://scenes/fragments/fragment_1138.tscn"),
		FragmentData.new("2049", "镜中人", "双面町", "「我是谁」", "自我之印", 4, true, "res://scenes/fragments/fragment_2049.tscn"),
		FragmentData.new("3015", "零时档案馆", "零时回廊", "「3:15」", "溯源之印", 5, true, "res://scenes/fragments/fragment_3015.tscn"),
		FragmentData.new("3333", "诸神黄昏", "终焉之谷", "「终即是始」", "轮回之印", 5, true, "res://scenes/fragments/fragment_3333.tscn"),
		FragmentData.new("4096", "万象归源", "万象之心", "「归源」", "归源之印", 5, true, "res://scenes/fragments/fragment_4096.tscn"),
	]


func get_fragment_by_id(id: String) -> FragmentData:
	for fragment in fragments:
		if fragment.id == id:
			return fragment
	return null


func get_available_fragments() -> Array[FragmentData]:
	var available: Array[FragmentData] = []
	for fragment in fragments:
		if fragment.implemented:
			available.append(fragment)
	return available


func enter_fragment(fragment: FragmentData) -> bool:
	if not fragment.implemented:
		return false
	current_fragment = fragment
	GameManager.reset_fragment()
	fragment_entered.emit(fragment.id)
	print("[FragmentManager] 进入碎片 %s: %s" % [fragment.id, fragment.name])
	return true


func complete_fragment(fragment: FragmentData) -> bool:
	if fragment == null or fragment.completed:
		return false
	fragment.completed = true
	pending_completion_animation_id = fragment.id
	fragment_completed.emit(fragment.id)
	print("[FragmentManager] 碎片 %s 修复完成" % fragment.id)
	return true


func consume_completion_animation_id() -> String:
	var fragment_id = pending_completion_animation_id
	pending_completion_animation_id = ""
	return fragment_id


func reset_all_fragments() -> void:
	for fragment in fragments:
		fragment.completed = false
	pending_completion_animation_id = ""
	print("[FragmentManager] 所有 %d 个碎片已重置为未修复状态" % fragments.size())
