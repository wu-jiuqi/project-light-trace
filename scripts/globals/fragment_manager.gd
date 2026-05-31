extends Node
## 碎片管理器
## 管理所有碎片的解密状态、提示信息、进入/退出

# === 碎片解密状态 ===
enum DecryptState {
	LOCKED,         # 未解密（显示乱码）
	DECRYPTING,     # 解密中（现实时间计时）
	PARTIAL,        # 半解密（部分提示可见）
	FULL,           # 完全解密
	COMPLETED       # 已修复（透明碎片）
}

# === 碎片数据结构 ===
class FragmentData:
	var id: String
	var name: String
	var world_name: String
	var hint_full: String          # 完整解密提示
	var hint_visible: String       # 当前可见提示（可能半解密）
	var decrypt_state: int
	var decrypt_progress: float    # 0.0~1.0
	var decrypt_start_time: int
	var decrypt_duration: int      # 解密所需秒数
	var source_mark_name: String   # 源印名称
	var difficulty: int             # 1-5 难度
	var is_story_critical: bool     # 是否承载关键剧情
	var scene_path: String
	
	func _init(p_id: String, p_name: String, p_world: String, 
			   p_hint: String, p_duration: int, p_source: String,
			   p_difficulty: int, p_critical: bool, p_scene: String):
		id = p_id
		name = p_name
		world_name = p_world
		hint_full = p_hint
		hint_visible = ""
		decrypt_state = DecryptState.LOCKED
		decrypt_progress = 0.0
		decrypt_start_time = 0
		decrypt_duration = p_duration
		source_mark_name = p_source
		difficulty = p_difficulty
		is_story_critical = p_critical
		scene_path = p_scene

# === 所有碎片数据 ===
var fragments: Array[FragmentData] = []
var current_fragment: FragmentData = null

# === 信号 ===
signal fragment_decrypted(fragment_id: String)
signal fragment_entered(fragment_id: String)
signal fragment_completed(fragment_id: String)

func _ready() -> void:
	_initialize_fragments()
	print("[FragmentManager] 碎片系统初始化完成，共 %d 个碎片" % fragments.size())

func _initialize_fragments() -> void:
	# MVP 阶段：12个碎片，难度递增
	# 提示设计：借鉴《画怖》的模式——每个提示词暗示一个主题
	
	fragments = [
		# === 第1层：入门级碎片（难度1-2）===
		FragmentData.new("0001", "启程之镇", "晨露镇",
			"「白日依山尽」", 30, "晨曦之印", 1, false,
			"res://scenes/fragments/fragment_0001.tscn"),
		FragmentData.new("0002", "黄昏驿站", "落霞驿站",
			"「黄河入海流」", 30, "归途之印", 1, false,
			"res://scenes/fragments/fragment_0002.tscn"),
		FragmentData.new("0003", "月下神社", "玉兔神社",
			"「举头望明月」", 60, "月光之印", 1, false,
			"res://scenes/fragments/fragment_0003.tscn"),
		FragmentData.new("0004", "工坊物语", "齿轮工坊",
			"「匠心_」", 90, "匠魂之印", 2, false,
			"res://scenes/fragments/fragment_0004.tscn"),
		
		# === 第2层：进阶碎片（难度2-3）===
		FragmentData.new("0047", "倒悬图书馆", "知识之塔",
			"「知识就是_量」", 120, "真理之印", 3, true,
			"res://scenes/fragments/fragment_0047.tscn"),
		FragmentData.new("0762", "颜色的葬礼", "灰白小镇",
			"「蓝是_，红是_」", 180, "情感之印", 3, true,
			"res://scenes/fragments/fragment_0762.tscn"),
		FragmentData.new("0915", "遗忘庭院", "记忆庭院",
			"「_忘_」", 150, "记忆之印", 2, false,
			"res://scenes/fragments/fragment_0915.tscn"),
		FragmentData.new("1138", "时钟停摆的车站", "永驻站",
			"「再见_」", 180, "时间之印", 3, true,
			"res://scenes/fragments/fragment_1138.tscn"),
		
		# === 第3层：深层碎片（难度4-5）===
		FragmentData.new("2049", "镜中人", "双面町",
			"「我_谁_」", 240, "自我之印", 4, true,
			"res://scenes/fragments/fragment_2049.tscn"),
		FragmentData.new("3015", "零时档案馆", "零时回廊",
			"「3:15_」", 300, "溯源之印", 5, true,
			"res://scenes/fragments/fragment_3015.tscn"),
		FragmentData.new("3333", "诸神黄昏", "终焉之谷",
			"「_终_始」", 360, "轮回之印", 5, true,
			"res://scenes/fragments/fragment_3333.tscn"),
		FragmentData.new("4096", "万象归源", "万象之心",
			"「_归_」", 420, "归源之印", 5, true,
			"res://scenes/fragments/fragment_4096.tscn"),
	]

func get_fragment_by_id(id: String) -> FragmentData:
	for f in fragments:
		if f.id == id:
			return f
	return null

func get_available_fragments() -> Array[FragmentData]:
	var available: Array[FragmentData] = []
	for f in fragments:
		if f.decrypt_state == DecryptState.PARTIAL or f.decrypt_state == DecryptState.FULL:
			if f.decrypt_state != DecryptState.COMPLETED:
				available.append(f)
	return available

func start_decrypt(fragment: FragmentData) -> void:
	if fragment.decrypt_state != DecryptState.LOCKED:
		return
	
	fragment.decrypt_state = DecryptState.DECRYPTING
	fragment.decrypt_start_time = Time.get_unix_time_from_system()
	print("[FragmentManager] 开始解密碎片 %s: %s (预计 %d 秒)" % 
		  [fragment.id, fragment.name, fragment.decrypt_duration])

func check_decrypt_progress(fragment: FragmentData) -> void:
	if fragment.decrypt_state != DecryptState.DECRYPTING:
		return
	
	var elapsed = Time.get_unix_time_from_system() - fragment.decrypt_start_time
	fragment.decrypt_progress = clampf(float(elapsed) / fragment.decrypt_duration, 0.0, 1.0)
	
	if fragment.decrypt_progress >= 0.5 and fragment.decrypt_progress < 1.0:
		# 半解密
		if fragment.decrypt_state != DecryptState.PARTIAL:
			fragment.decrypt_state = DecryptState.PARTIAL
			fragment.hint_visible = _generate_partial_hint(fragment.hint_full)
			print("[FragmentManager] 碎片 %s 半解密完成: %s" % [fragment.id, fragment.hint_visible])
	
	if fragment.decrypt_progress >= 1.0:
		# 完全解密
		fragment.decrypt_state = DecryptState.FULL
		fragment.hint_visible = fragment.hint_full
		fragment_decrypted.emit(fragment.id)
		print("[FragmentManager] 碎片 %s 完全解密: %s" % [fragment.id, fragment.hint_full])

func _generate_partial_hint(full_hint: String) -> String:
	# 半解密：将hint中的下划线（_）部分保留为空白
	# 已有_的部分保持模糊，没有_的hint则随机遮挡50%的字符
	var result = full_hint
	if "_" in full_hint:
		return result  # 已经是半解密格式
	else:
		# 随机遮挡50%字符
		var chars = result.to_utf8_buffer()
		for i in range(0, chars.size(), 2):
			if randf() > 0.5:
				chars[i] = 95  # '_' 的UTF-8编码
		return chars.get_string_from_utf8()

func enter_fragment(fragment: FragmentData) -> void:
	current_fragment = fragment
	GameManager.reset_fragment()  # 重新挑战：清NPC/物品/对话
	fragment_entered.emit(fragment.id)
	print("[FragmentManager] 进入碎片 %s: %s" % [fragment.id, fragment.name])

func complete_fragment(fragment: FragmentData) -> void:
	fragment.decrypt_state = DecryptState.COMPLETED
	fragment_completed.emit(fragment.id)
	print("[FragmentManager] 碎片 %s 修复完成" % fragment.id)


func reset_all_fragments() -> void:
	## 将所有碎片重置为初始锁定状态（用于新游戏）
	for f in fragments:
		f.decrypt_state = DecryptState.LOCKED
		f.decrypt_progress = 0.0
		f.decrypt_start_time = 0
		f.hint_visible = ""
	print("[FragmentManager] 所有 %d 个碎片已重置为锁定状态" % fragments.size())
