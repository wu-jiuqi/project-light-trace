extends CharacterBody2D
## AI子体NPC控制器
## 驱动碎片世界中NPC的移动、对话、警觉行为
## 每个NPC维护独立的警觉值和个人档案

# === 全局警觉等级常量（对齐 WantedSystem.AlertLevel） ===
const ALERT_SAFE = 0
const ALERT_SUSPICIOUS = 1
const ALERT_INVESTIGATING = 2
const ALERT_ALERTED = 3
const ALERT_HUNTING = 4
const ALERT_LOCKDOWN = 5

# === NPC 独立警觉等级（每人自己的阈值） ===
enum NPCAlertPhase {
	TRUSTING,       # 信任——开放，乐于助人
	CAUTIOUS,       # 谨慎——简短回答，开始回避
	SUSPICIOUS,     # 怀疑——回避话题，回答含糊
	ALARMED,        # 警觉——敌意，拒绝回应
	HOSTILE,        # 敌对——呼救/逃跑/攻击
	SHUTDOWN        # 封闭——完全拒绝交互
}

# === NPC 行为状态 ===
enum NPCState {
	IDLE,           # 闲置
	PATROL,         # 巡逻
	TALKING,        # 对话中
	SUSPICIOUS,     # 警觉状态——眼神追踪
	INVESTIGATING,  # 调查玩家——主动靠近
	CHASING,        # 追捕玩家
	FLEEING         # 逃跑——远离玩家
}

@export var npc_name: String = "未命名NPC"
@export var npc_role: String = "居民"          # "居民"/"商人"/"守护者"/"隐藏者"
@export var walk_speed: float = 50.0
@export var chase_speed: float = 100.0

# === Per-NPC 警觉系统 ===
## 该NPC的独立警觉值 (0.0 ~ 100.0)
var npc_suspicion: float = 0.0
## 当前警觉阶段
var npc_alert_phase: int = NPCAlertPhase.TRUSTING
## 是否对玩家身份有怀疑（影响对话深层态度）
var doubts_player_identity: bool = false
## 上次警觉变化时间（用于衰减计时）
var _last_alert_change_time: float = 0.0
## 警觉衰减速率 (每秒)
var _alert_decay_rate: float = 1.0
## 警觉衰减延迟（秒）
var _alert_decay_delay: float = 10.0

# === 警觉档案：每个NPC的敏感话题和反应阈值 ===
## 格式：{ "thresholds": {TRUSTING:0, CAUTIOUS:20, SUSPICIOUS:40, ALARMED:60, HOSTILE:80, SHUTDOWN:95},
##         "hot_topics": ["关键词", ...],   # 触碰这些话题会大幅增加警觉
##         "personality": "性格描述",
##         "safe_actions": ["action", ...],  # 什么行为能降低警觉
##         "trust_modifier": float }         # 基础信任修正（越低越容易怀疑）
func _get_alert_profile() -> Dictionary:
	match npc_kb_id:
		"blacksmith":
			return {
				"thresholds": {0:0, 1:25, 2:50, 3:70, 4:88, 5:98},
				"hot_topics": ["火为什么", "那天发生", "你以前是做什么", "你在怕什么", "为什么没有颜色",
							  "源印", "天枢", "织女", "太一", "万象", "归源",
							  "不对劲", "奇怪", "怎么回事", "你是谁", "你不属于"],
				"personality": "暴躁但正直——你越躲躲藏藏他越怀疑。坦率说话反而能降低他的警觉。",
				"safe_actions": ["打铁", "买武器", "手艺不错", "老唐"],
				"trust_modifier": 0.0
			}
		"florist":
			return {
				"thresholds": {0:0, 1:15, 2:35, 3:55, 4:78, 5:95},
				"hot_topics": ["你还好吗", "你看起来不一样", "这个镇子", "有没有什么不对劲",
							  "为什么没有颜色", "源印", "天枢", "织女", "太一",
							  "奇怪", "怎么回事", "你是谁", "你不属于"],
				"personality": "温柔但敏感——容易被情绪感染。触及悲伤的话题会让她封闭自己。",
				"safe_actions": ["花很漂亮", "矢车菊", "天气", "温柔"],
				"trust_modifier": -5.0
			}
		"baker":
			return {
				"thresholds": {0:0, 1:18, 2:40, 3:60, 4:82, 5:96},
				"hot_topics": ["炉子为什么", "你一个人在这里多久", "有没有觉得镇上少了什么",
							  "为什么没有颜色", "源印", "天枢", "织女", "太一",
							  "不对劲", "奇怪", "怎么回事", "你是谁", "你不属于"],
				"personality": "乐观但不安——他总是在笑，但笑容下面藏着担忧。他不喜欢被追问过去。",
				"safe_actions": ["面包香", "学做面包", "老霍的打铁", "饿不饿"],
				"trust_modifier": -3.0
			}
		"gravekeeper":
			return {
				"thresholds": {0:0, 1:12, 2:28, 3:48, 4:72, 5:92},
				"hot_topics": ["铁门", "里面有什么", "你是谁", "你是死人还是活人", "你的呼吸",
							  "为什么没有颜色", "源印", "天枢", "织女", "太一", "冥府",
							  "不对劲", "奇怪", "怎么回事", "你不属于", "警觉"],
				"personality": "偏执但清醒——他是少数知道世界不对劲的NPC。恐惧让他极度戒备，但如果得到他的信任，他是最有价值的线人。",
				"safe_actions": ["不说话", "安静站", "点头", "矢车菊", "花"],
				"trust_modifier": 10.0
			}
		"violinist":
			return {
				"thresholds": {0:0, 1:10, 2:25, 3:45, 4:70, 5:90},
				"hot_topics": ["为什么不拉琴", "你在等谁", "弦为什么没声音", "那天", "零时",
							  "为什么没有颜色", "源印", "天枢", "织女", "太一",
							  "不对劲", "奇怪", "怎么回事", "你是谁", "你不属于"],
				"personality": "沉默而脆弱——她几乎不说话。问得太多会让她完全封闭。耐心和陪伴是唯一降低她警觉的方式。",
				"safe_actions": ["听琴", "坐在旁边", "等她开口", "点头"],
				"trust_modifier": 8.0
			}
		"oldpainter":
			return {
				"thresholds": {0:0, 1:20, 2:45, 3:65, 4:85, 5:98},
				"hot_topics": [],
				"personality": "觉醒者——他是唯一知道真相的NPC。他对玩家没有警觉，因为他知道玩家是来修复世界的。但他会测试玩家是否真心。",
				"safe_actions": [],
				"trust_modifier": -20.0
			}
		"innkeeper":
			return {
				"thresholds": {0:0, 1:10, 2:20, 3:30, 4:38, 5:45},
				"hot_topics": ["源印", "天枢", "织女", "太一", "万象", "归源",
							  "为什么没有颜色", "不对劲", "你是谁", "你不属于"],
				"personality": "冯婶——半睡半醒的旅店老板娘。她的警觉上限极低（40），且超过20就不再闲聊——你将失去情报来源。警觉每天衰减3点。",
				"safe_actions": ["付房钱", "天气", "饿了", "累了", "老唐"],
				"trust_modifier": -10.0
			}
		# --- 碎片0001 NPC（MONITORED合规度模式） ---
		"linguide":
			return {
				"thresholds": {0:0, 1:15, 2:35, 3:55, 4:75, 5:92},
				"hot_topics": ["脚本之外", "幕间", "记忆清除", "边界那边", "赵安保看到", "为什么骗"],
				"personality": "林指导——微笑的提线木偶。她知道自己在读脚本但无法停止。在脚本缝隙里说真话。用句尾音调和沉默表达真实态度。",
				"safe_actions": ["汇报进度", "日晷数据", "校准完成", "观测完毕"],
				"trust_modifier": 0.0
			}
		"chentechnology":
			return {
				"thresholds": {0:0, 1:12, 2:30, 3:50, 4:72, 5:90},
				"hot_topics": ["删除的信息", "碎片的便利贴", "0047", "为什么不让我看", "你在怕什么"],
				"personality": "陈技术——被命令删除信息的人。技术术语快/非脚本慢的双速切换，手指会发抖。每句以'没问题吧？'确认安全边界。",
				"safe_actions": ["观测数据", "角度规律", "等差数列", "调试设备"],
				"trust_modifier": 0.0
			}
		"wangdirector":
			return {
				"thresholds": {0:0, 1:20, 2:42, 3:62, 4:80, 5:94},
				"hot_topics": ["审查", "公关稿", "电子屏闪", "家人", "真相", "公司隐瞒"],
				"personality": "王主管——说公司的版本但知道真相不是这样。宣讲流畅如公关稿，摄像头死角压低声音。第47秒电子屏会闪家人照片。",
				"safe_actions": ["公共信息", "官方通告", "培训手册", "合规操作"],
				"trust_modifier": 0.0
			}
		"zhaosecurity":
			return {
				"thresholds": {0:0, 1:8, 2:22, 3:40, 4:60, 5:82},
				"hot_topics": ["光墙", "边界", "外面", "你看见了什么", "为什么不记录"],
				"personality": "赵安保——越过一次光墙看到了外面。话极少（≤8字），安保术语精准。以不记录代替反抗。站在侧后方不挡路。",
				"safe_actions": ["通过", "安全", "训练中", "无需协助"],
				"trust_modifier": 0.0
			}
	return {
		"thresholds": {0:0, 1:20, 2:40, 3:60, 4:80, 5:95},
		"hot_topics": ["为什么没有颜色", "源印", "天枢", "不对劲", "奇怪"],
		"personality": "普通居民",
		"safe_actions": [],
		"trust_modifier": 0.0
	}

## 警觉值变化量常量
const ALERT_TOPIC_HOT: float = 18.0       # 触碰敏感话题
const ALERT_TOPIC_MODERATE: float = 10.0   # 话题有些敏感
const ALERT_ASK_TRUTH: float = 22.0        # 直接追问真相
const ALERT_STAY_TOO_LONG: float = 3.0     # 停留太久（每秒）
const ALERT_IDENTITY_DOUBT: float = 8.0    # 身份引起怀疑
const ALERT_FORBIDDEN_WORD: float = 25.0   # 说出禁语（源印/天枢/织女等）
const ALERT_SAFE_ACTION: float = -8.0      # 安全行为（降低警觉）
const ALERT_GIVE_ITEM: float = -15.0       # 给予正确物品
const ALERT_COLOR_AWAKEN: float = -10.0    # 颜色觉醒（世界恢复）

@export var dialogue_tree: Array[Dictionary] = []

## system_prompt: 包含世界观、角色描述和行为约束，供后续大模型接入使用
@export_multiline var system_prompt: String = ""

## npc_kb_id: 对应知识库中的NPC ID（blacksmith/florist/baker/gravekeeper/violinist/oldpainter）
@export var npc_kb_id: String = ""

## use_rag: 是否使用RAG检索器动态组装prompt（替代静态system_prompt）
@export var use_rag: bool = true

var current_state: int = NPCState.IDLE
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var target_position: Vector2 = Vector2.ZERO
var idle_timer: float = 0.0

## RAG状态引用
var _fragment_state: Node = null

## 对话历史（通过ChatDatabase SQLite持久化，不再使用内存数组）
const DIALOGUE_HISTORY_LIMIT: int = 10  # 注入LLM的最大历史条数

## 情绪状态追踪
var _npc_mood: String = ""                # 当前情绪描述
var _last_greeting: String = ""           # 上次使用的开场白（避免连续重复）
var _greeting_phase: int = 0              # 开场白阶段
var _own_color_was_awakened: bool = false # 是否刚觉醒
var _llm_last_input: String = ""          # 上一轮玩家的输入（用于LLM回复后分析警觉）
var _stream_suppress_asterisk_action: bool = false

signal npc_state_changed(new_state: int)


func _uses_fragment_compliance_mode() -> bool:
	if _fragment_state == null:
		var states = get_tree().get_nodes_in_group("fragment_state")
		if states.size() > 0:
			_fragment_state = states[0]
	return _fragment_state != null \
		and _fragment_state.has_method("uses_compliance_mode") \
		and _fragment_state.uses_compliance_mode()


func _ready() -> void:
	add_to_group("npc")
	target_position = global_position
	
	# 查找碎片状态管理器
	var states = get_tree().get_nodes_in_group("fragment_state")
	if states.size() > 0:
		_fragment_state = states[0]
	
	# 初始化警觉系统
	var profile = _get_alert_profile()
	var base_trust = profile.get("trust_modifier", 0.0)
	var compliance_mode := _uses_fragment_compliance_mode()
	
	# 尝试从持久化缓存恢复状态（重进房间不重置位置和警觉）
	var scene_name = get_parent().name if get_parent() else ""
	var saved = GameManager.load_npc_state(scene_name, npc_kb_id)
	if compliance_mode:
		npc_suspicion = 0.0
		npc_alert_phase = NPCAlertPhase.TRUSTING
		doubts_player_identity = false
	elif not saved.is_empty():
		global_position = Vector2(saved.get("position_x", global_position.x), saved.get("position_y", global_position.y))
		npc_suspicion = saved.get("suspicion", 0.0)
		npc_alert_phase = saved.get("alert_phase", NPCAlertPhase.TRUSTING)
		doubts_player_identity = saved.get("doubts", false)
		target_position = global_position
		_own_color_was_awakened = _is_own_color_awakened()
		_update_behavior_from_alert()  # 恢复后同步行为状态（IDLE/SUSPICIOUS/SHUTDOWN等）
		print("[NPC] %s 从缓存恢复: pos=(%.0f,%.0f) sus=%.0f phase=%d" % 
			  [npc_name, global_position.x, global_position.y, npc_suspicion, npc_alert_phase])
	else:
		if base_trust > 0:
			npc_suspicion = base_trust
			npc_suspicion = clampf(npc_suspicion, 0.0, 100.0)
			_update_alert_phase()
			if npc_suspicion > 0:
				print("[NPC] %s 初始警觉: %.0f (天生多疑)" % [npc_name, npc_suspicion])
	
	print("[NPC] %s (%s) 已生成 | kb=%s rag=%s" % [npc_name, npc_role, npc_kb_id, use_rag])
	
	# 冯婶：更高的警觉衰减率（每天衰减3点，与其他NPC区别）
	if npc_kb_id == "innkeeper":
		_alert_decay_rate = 3.0
		_alert_decay_delay = 5.0  # 更快开始衰减
	
	if system_prompt != "":
		print("[NPC] %s 静态system_prompt 已加载 (%d 字符)" % [npc_name, system_prompt.length()])
	
	# 退出场景时保存状态到 GameManager
	tree_exiting.connect(_on_tree_exiting)


func _on_tree_exiting() -> void:
	## 节点从场景树移除前保存状态
	if npc_kb_id == "": return
	if _uses_fragment_compliance_mode():
		return
	var scene_name = get_parent().name if get_parent() else ""
	GameManager.save_npc_state(scene_name, npc_kb_id, global_position, npc_suspicion, npc_alert_phase, doubts_player_identity)
	print("[NPC] %s 状态已缓存: sus=%.0f phase=%d pos=(%.0f,%.0f)" % 
		  [npc_name, npc_suspicion, npc_alert_phase, global_position.x, global_position.y])

func _process(delta: float) -> void:
	# 警觉衰减（不说话时缓慢下降）
	_process_alert_decay(delta)
	
	match current_state:
		NPCState.IDLE:
			_process_idle(delta)
		NPCState.PATROL:
			_process_patrol(delta)
		NPCState.TALKING:
			_process_talking(delta)
		NPCState.SUSPICIOUS:
			_process_suspicious(delta)
		NPCState.INVESTIGATING:
			_process_investigating(delta)
		NPCState.CHASING:
			_process_chasing(delta)
		NPCState.FLEEING:
			_process_fleeing(delta)

func _physics_process(_delta: float) -> void:
	if current_state in [NPCState.PATROL, NPCState.INVESTIGATING, NPCState.CHASING, NPCState.FLEEING]:
		var direction = (target_position - global_position).normalized()
		var speed = chase_speed if current_state in [NPCState.CHASING, NPCState.FLEEING] else walk_speed
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()  # 始终调用——非移动状态也需处理物理碰撞（不穿透地形/TileMapLayer）

func _process_idle(delta: float) -> void:
	idle_timer -= delta
	if idle_timer <= 0:
		if patrol_points.size() > 0:
			set_state(NPCState.PATROL)
		else:
			idle_timer = randf_range(2.0, 5.0)

func _process_patrol(_delta: float) -> void:
	if global_position.distance_to(target_position) < 5.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		target_position = patrol_points[patrol_index]
		idle_timer = randf_range(1.0, 3.0)
		set_state(NPCState.IDLE)

func _process_talking(_delta: float) -> void:
	# 对话中——由对话系统管理
	pass

func _process_suspicious(_delta: float) -> void:
	# 警觉——眼神追踪玩家，但不主动接近
	pass

func _process_investigating(_delta: float) -> void:
	var player = _find_player()
	if player:
		target_position = player.global_position + (global_position - player.global_position).normalized() * 60.0

func _process_chasing(_delta: float) -> void:
	var player = _find_player()
	if player:
		target_position = player.global_position

func _process_fleeing(_delta: float) -> void:
	## 逃跑——远离玩家
	var player = _find_player()
	if player:
		var away_dir = (global_position - player.global_position).normalized()
		target_position = global_position + away_dir * 200.0

func set_state(new_state: int) -> void:
	if current_state != new_state:
		current_state = new_state
		npc_state_changed.emit(new_state)

func start_dialogue() -> void:
	set_state(NPCState.TALKING)
	# 记录拜访（老崔需要计数）
	if _fragment_state and _fragment_state.has_method("record_npc_visit") and npc_kb_id != "":
		_fragment_state.record_npc_visit(npc_kb_id)
	# 老画家：每次对话 +10 信任
	if npc_kb_id == "oldpainter" and _fragment_state:
		_fragment_state.modify_trust("oldpainter", 10.0)
	# 老画家：检查旋律触发
	if npc_kb_id == "oldpainter" and _fragment_state and _fragment_state.has_method("_trigger_oldpainter_melody"):
		_fragment_state._trigger_oldpainter_melody()
	# 老画家：五色集齐后解锁白色
	if npc_kb_id == "oldpainter" and _fragment_state and _fragment_state.has_method("try_unlock_white_from_painter"):
		var unlocked = _fragment_state.try_unlock_white_from_painter()
		if unlocked:
			print("[NPC:oldpainter] 白色解锁触发！")
			# 白色觉醒后更新情绪
			_npc_mood = "六种颜色全部回来了。你看着画室里那幅被灰布盖着的女人画像——是时候让她看看了。"
	print("[NPC] %s 进入对话 (kb=%s rag=%s)" % [npc_name, npc_kb_id, use_rag])

func end_dialogue() -> void:
	# 对话结束后根据警觉阶段决定行为状态
	var profile = _get_alert_profile()
	var thresholds = profile.get("thresholds", {})
	
	if npc_alert_phase >= NPCAlertPhase.HOSTILE:
		set_state(NPCState.FLEEING)
		print("[NPC] %s 对话后逃跑（警觉=%d）" % [npc_name, int(npc_suspicion)])
	elif npc_alert_phase >= NPCAlertPhase.ALARMED:
		set_state(NPCState.SUSPICIOUS)
		print("[NPC] %s 对话后保持警惕（警觉=%d）" % [npc_name, int(npc_suspicion)])
	else:
		set_state(NPCState.IDLE)
	
	# 对话结束后记录警觉变化时间
	_last_alert_change_time = Time.get_unix_time_from_system()
	print("[NPC] %s 结束对话 (sus=%.0f phase=%d)" % [npc_name, npc_suspicion, npc_alert_phase])

# ============================================================
# 独立警觉系统
# ============================================================

func _process_alert_decay(delta: float) -> void:
	## 警觉自然衰减（不对话时缓慢降低）
	if _uses_fragment_compliance_mode():
		return
	if current_state == NPCState.TALKING:
		return  # 对话中不衰减
	if npc_suspicion <= 0:
		return
	
	var elapsed = Time.get_unix_time_from_system() - _last_alert_change_time
	if elapsed < _alert_decay_delay:
		return
	
	npc_suspicion = maxf(0.0, npc_suspicion - _alert_decay_rate * delta)
	_update_alert_phase()

func modify_alert(amount: float, reason: String = "") -> void:
	## 修改NPC警觉值
	if _uses_fragment_compliance_mode():
		_modify_fragment_compliance_from_alert(amount, reason)
		return
	var old_phase = npc_alert_phase
	npc_suspicion = clampf(npc_suspicion + amount, 0.0, 100.0)
	_last_alert_change_time = Time.get_unix_time_from_system()
	_update_alert_phase()
	
	# 弹窗通知（变化量 > 0.5 才显示，过滤微小波动）
	if abs(amount) >= 0.5:
		ChatDialogue.show_alert_popup(amount, reason, npc_name, npc_alert_phase, npc_suspicion)
	
	if old_phase != npc_alert_phase:
		print("[NPC:%s] 警觉阶段变化: %d→%d (sus=%.0f 原因: %s)" % 
			  [npc_name, old_phase, npc_alert_phase, npc_suspicion, reason])
		# 阶段升级弹窗（更醒目）
		if npc_alert_phase > old_phase:
			ChatDialogue.show_alert_phase_change(npc_name, old_phase, npc_alert_phase, reason)
		if npc_alert_phase >= NPCAlertPhase.ALARMED and not doubts_player_identity:
			doubts_player_identity = true
			print("[NPC:%s] 开始怀疑玩家身份" % npc_name)

func _modify_fragment_compliance_from_alert(amount: float, reason: String = "") -> void:
	## MONITORED 模式把 NPC 警觉事件映射为碎片 #0001 的共享合规度扣减。
	if amount <= 0.0:
		return
	if not _fragment_state or not _fragment_state.has_method("_modify_compliance"):
		return
	var divisor := 6.0
	if reason.begins_with("LLM判断"):
		divisor = 12.0
	var compliance_delta := -maxi(1, ceili(amount / divisor))
	_fragment_state.call("_modify_compliance", compliance_delta, "NPC对话触发: %s" % reason)

func _update_alert_phase() -> void:
	## 根据当前警觉值更新警觉阶段
	var profile = _get_alert_profile()
	var thresholds = profile.get("thresholds", {0:0, 1:20, 2:40, 3:60, 4:80, 5:95})
	
	# 从高到低检查
	var new_phase = NPCAlertPhase.TRUSTING
	for phase in range(NPCAlertPhase.SHUTDOWN, NPCAlertPhase.TRUSTING - 1, -1):
		if npc_suspicion >= thresholds.get(phase, 100.0):
			new_phase = phase
			break
	
	if new_phase != npc_alert_phase:
		npc_alert_phase = new_phase
		# 同步行为状态
		_update_behavior_from_alert()

func _update_behavior_from_alert() -> void:
	## 根据警觉阶段更新NPC行为状态
	if current_state == NPCState.TALKING:
		return  # 对话中不改变状态
	
	match npc_alert_phase:
		NPCAlertPhase.TRUSTING:
			# 信任时正常
			if current_state in [NPCState.SUSPICIOUS, NPCState.INVESTIGATING, NPCState.FLEEING]:
				set_state(NPCState.IDLE)
		NPCAlertPhase.CAUTIOUS:
			# 谨慎——略微关注玩家
			if current_state == NPCState.IDLE:
				set_state(NPCState.SUSPICIOUS)
		NPCAlertPhase.SUSPICIOUS:
			# 怀疑——主动观察
			if current_state in [NPCState.IDLE, NPCState.SUSPICIOUS]:
				set_state(NPCState.INVESTIGATING)
		NPCAlertPhase.ALARMED:
			# 警觉——保持距离，随时准备行动
			set_state(NPCState.SUSPICIOUS)
		NPCAlertPhase.HOSTILE:
			# 敌对——逃跑（而非攻击）
			set_state(NPCState.FLEEING)
		NPCAlertPhase.SHUTDOWN:
			# 完全封闭——不移动，不回应
			set_state(NPCState.IDLE)

func check_player_input_for_alert(player_input: String) -> void:
	## 分析玩家输入，如果触及敏感话题则增加警觉
	var profile = _get_alert_profile()
	if npc_kb_id == "oldpainter":
		return  # 老画家完全信任玩家
	
	var input_lower = player_input.to_lower()
	var hot_topics: Array = profile.get("hot_topics", [])
	var triggered: Array[String] = [] as Array[String]
	
	# 检查是否触碰到敏感话题（子串匹配）
	for topic in hot_topics:
		if topic.to_lower() in input_lower:
			triggered.append(topic)
	
	if triggered.is_empty():
		return  # 没有触发
	
	print("[NPC:%s] ⚠ 触碰敏感话题: %s (输入: \"%s\")" % [npc_name, triggered, player_input])
	
	# 判断触发的严重程度
	var max_alert = 0.0
	var max_topic = ""
	for topic in triggered:
		# 禁语级的触发最严重
		if topic in ["源印", "天枢", "织女", "太一", "万象", "归源", "冥府"]:
			if ALERT_FORBIDDEN_WORD > max_alert:
				max_alert = ALERT_FORBIDDEN_WORD
				max_topic = topic
		# 直接追问真相
		elif topic in ["那天发生了什么", "你是谁", "你在怕什么", "有没有觉得镇上少了什么", 
					  "你是死人还是活人", "你在等谁", "铁门", "里面有什么"]:
			if ALERT_ASK_TRUTH > max_alert:
				max_alert = ALERT_ASK_TRUTH
				max_topic = topic
		else:
			if ALERT_TOPIC_HOT > max_alert:
				max_alert = ALERT_TOPIC_HOT
				max_topic = topic
	
	modify_alert(max_alert, "触碰敏感话题: %s" % max_topic)

func check_safe_action(player_input: String) -> void:
	## 检查玩家的行为是否能降低警觉
	if _uses_fragment_compliance_mode():
		return
	var profile = _get_alert_profile()
	if npc_suspicion <= 0:
		return
	
	var input_lower = player_input.to_lower()
	var safe_actions: Array = profile.get("safe_actions", [])
	
	for action in safe_actions:
		if action.to_lower() in input_lower:
			modify_alert(ALERT_SAFE_ACTION, "安全行为: %s" % action)
			return

func get_alert_phase_text() -> String:
	## 返回当前警觉阶段的文字描述
	match npc_alert_phase:
		NPCAlertPhase.TRUSTING:
			return "信任"
		NPCAlertPhase.CAUTIOUS:
			return "谨慎"
		NPCAlertPhase.SUSPICIOUS:
			return "怀疑"
		NPCAlertPhase.ALARMED:
			return "警觉"
		NPCAlertPhase.HOSTILE:
			return "敌对"
		NPCAlertPhase.SHUTDOWN:
			return "封闭"
	return "未知"

func get_alert_context_for_rag() -> String:
	## 为RAG检索生成警觉上下文 — 指导LLM以不同警觉等级回应
	if npc_alert_phase <= NPCAlertPhase.TRUSTING:
		return ""

	var parts: Array[String] = [] as Array[String]
	
	# 身份怀疑标记
	if doubts_player_identity:
		parts.append("【你对这个旅行者身份产生了怀疑。他的问题太精准——像是知道不该知道的事。】")
	
	match npc_alert_phase:
		NPCAlertPhase.CAUTIOUS:
			parts.append("你隐约觉得这个旅行者不太对劲，但说不上来哪里不对。")
			parts.append("你回答时会不自觉地简短一些——不是故意的，是一种直觉。")
		
		NPCAlertPhase.SUSPICIOUS:
			parts.append("你不太信任这个旅行者。他的问题让你感到不安，触及了一些你不愿谈论的事情。")
			parts.append("你说话时会下意识地含糊、回避，可能用反问来试探他的意图。")
		
		NPCAlertPhase.ALARMED:
			parts.append("你觉得这个旅行者很危险。他在追问那些不该被提起的事。你害怕了。")
			parts.append("你不会再认真回答他的问题了。你只想让他走——用警告的语气、冰冷的眼神。")
	
	if parts.size() > 0:
		return "\n".join(parts)
	return ""

func alert_react_to_player_action(action_type: String) -> String:
	## NPC对玩家特定行为的警觉反应（返回对话文本）
	match npc_alert_phase:
		NPCAlertPhase.CAUTIOUS:
			match npc_kb_id:
				"blacksmith": return "（老霍瞥了你一眼，但没有停下手里的活。）"
				"florist":    return "（阿莲稍微往后退了一小步——她可能自己都没注意到。）"
				"baker":      return "（老唐的笑容收了一点点。只是一点点。）"
				"gravekeeper":return "（老崔盯着你看了很久。他没说话——他不需要说话。）"
				"violinist":  return "（薇拉把琴盒往自己身边挪了挪。）"
				"innkeeper":  return "（冯婶托着腮帮子的手换了一边——她还在打瞌睡，但眼睛眯开了一条缝。）"
		NPCAlertPhase.SUSPICIOUS:
			match npc_kb_id:
				"blacksmith": return "（老霍停下锤子。沉默。）……你问这个干什么。"
				"florist":    return "（阿莲的手指停在花瓣上。）……你——你不是来买花的，对吧。"
				"baker":      return "（老唐没有笑。）……你问的东西——不是该问的。"
				"gravekeeper":return "（老崔往铁门靠了一步。）你最好走。现在。"
				"violinist":  return "（薇拉合上了琴盒。她没有看你。）"
				"innkeeper":  return "（冯婶睁开了眼睛。她没有抬头——但翻登记簿的手停了。）……你——不是来续房的，对吧。"
		NPCAlertPhase.ALARMED:
			match npc_kb_id:
				"blacksmith": return "（老霍把锤子举了起来——不是要打人，是防御。）不买东西就走。"
				"florist":    return "（阿莲的花洒掉在地上。）请离开。——我没有更多要说的。"
				"baker":      return "（老唐挡在烤炉前面。）面包还没好。——走吧。"
				"gravekeeper":return "（老崔打开了铁门——不是让你进去，是让自己能退进去。）够了。"
				"violinist":  return "（薇拉站起来，抱着琴盒，转身——）"
				"innkeeper":  return "（冯婶把登记簿合上了。她看着你——不是生气，是失望。）……早点睡吧。你累了。"
		NPCAlertPhase.HOSTILE:
			match npc_kb_id:
				"blacksmith": return "（老霍怒吼。）滚！——这不是你该来的地方！"
				"florist":    return "（阿莲的花瓶碎了。她退到墙角。）我喊人了——我真的会喊。"
				"baker":      return "（老唐抓起一根擀面杖。）走——别让我说第二遍。"
				"gravekeeper":return "（老崔消失在铁门后面。门砰地关上——从里面反锁了。）"
				"violinist":  return "（薇拉跑掉了。琴盒撞在门框上——她甚至没有回头。）"
				"innkeeper":  return "（冯婶站起来——慢慢地把椅子推进柜台下面。）……退房吧。今晚不留客了。"
	return ""

func on_alert_level_changed(alert_level: int) -> void:
	## 全局通缉系统警报（WantedSystem）的回调
	## 注意：全局警报和NPC独立警觉是两个不同的系统
	match alert_level:
		ALERT_SAFE:
			if npc_alert_phase <= NPCAlertPhase.CAUTIOUS:
				set_state(NPCState.IDLE)
		ALERT_SUSPICIOUS:
			if current_state not in [NPCState.TALKING, NPCState.FLEEING]:
				set_state(NPCState.SUSPICIOUS)
		ALERT_INVESTIGATING:
			if current_state not in [NPCState.TALKING, NPCState.FLEEING]:
				set_state(NPCState.INVESTIGATING)
		ALERT_ALERTED:
			set_state(NPCState.INVESTIGATING)
		ALERT_HUNTING:
			set_state(NPCState.CHASING)
		ALERT_LOCKDOWN:
			set_state(NPCState.CHASING)

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


# ============================================================
# LLM 回复分析 —— 由大模型自己判断警觉
# ============================================================

func _analyze_llm_response_for_alert(response: String, player_input: String) -> void:
	## 分析LLM的回复内容来判断NPC是否变得警觉
	## 不是关键词匹配——是观察NPC的自然反应
	## 如果NPC回复变得简短、抗拒、回避，说明玩家的问题让他不安
	var compliance_mode := _uses_fragment_compliance_mode()
	if response == "" or npc_kb_id == "oldpainter":
		return
	
	var response_lower = response.to_lower()
	var delta: float = 0.0
	var reasons: Array[String] = [] as Array[String]
	
	# === 信号1: 极度简短的回复（<20字符）—— NPC不想说话 ===
	if response.length() < 20 and not compliance_mode:
		delta += 15.0
		reasons.append("回复极短——NPC不想多谈")
	
	# === 信号2: 拒绝/警告词（NPC主动让玩家离开） ===
	var warn_words = ["走开", "滚", "离开", "出去", "够了", "别问了", "别问", "不想说", "不要问", "别过来", "停下"]
	for w in warn_words:
		if w in response_lower:
			delta += 25.0
			reasons.append("警告/拒绝: %s" % w)
			break
	
	# === 信号3: 回避词（NPC在搪塞） ===
	var evade_words = ["不知道", "不清楚", "不了解", "不好说", "说不清", "没听说过", "不记得", "忘了", "也许吧", "可能吧"]
	var evade_count = 0
	for w in evade_words:
		if w in response_lower:
			evade_count += 1
	if evade_count >= 2:
		delta += 18.0
		reasons.append("多次回避 (%d次)" % evade_count)
	elif evade_count == 1:
		delta += 8.0
		reasons.append("回避回答")
	
	# === 信号4: 反问（NPC把问题抛回给玩家） ===
	var counter_words = ["你问这个做什么", "你是什么人", "你到底想", "你来找什么", "你不该", "你怎么知道"]
	for w in counter_words:
		if w in response_lower:
			delta += 12.0
			reasons.append("反问玩家: %s" % w)
			break
	
	# === 信号5: 沉默/省略号（NPC语塞） ===
	if "……" in response or "..." in response:
		delta += 4.0
		reasons.append("语塞/沉默")
	
	# === 信号6: 长回复 + 友好词 = 降警觉 ===
	if response.length() > 80:
		var friendly = ["谢谢", "欢迎", "好的", "可以", "没问题", "来吧", "坐", "请"]
		for f in friendly:
			if f in response_lower:
				delta -= 5.0
				reasons.append("友好回应")
				break
	
	# === 信号7: 回答触及真相（暗示NPC开始信任） ===
	var truth_words = ["颜色", "恢复了", "醒过来", "变化", "不一样", "记起来", "想起来", "那天"]
	var truth_count = 0
	for t in truth_words:
		if t in response_lower:
			truth_count += 1
	if truth_count >= 2:
		delta -= 8.0
		reasons.append("主动谈及真相——信任提升")
	
	# 应用警觉变化
	if abs(delta) >= 1.0:
		modify_alert(delta, "LLM判断: %s" % " + ".join(reasons))
		print("[NPC:%s] LLM警觉分析: delta=%+.0f 原因=%s" % [npc_name, delta, reasons])

func get_dialogue_options() -> Array[Dictionary]:
	# 根据当前NPC状态和游戏进度返回对话选项
	return dialogue_tree


# ============================================================
# RAG 集成
# ============================================================

func get_rag_prompt(player_input: String) -> String:
	## 通过RAG检索器获取动态组装的System Prompt
	## 优先使用use_rag模式；降级到静态system_prompt
	if use_rag and npc_kb_id != "":
		var game_state = _collect_game_state()
		var prompt = NPCRagRetriever.assemble_prompt(npc_kb_id, player_input, game_state)
		if prompt != "":
			return prompt
		# RAG降级：使用静态prompt
		print("[NPC] %s RAG检索失败，降级到静态prompt" % npc_name)
	
	if system_prompt != "":
		return system_prompt
	
	# 最终降级：L0身份
	var l0 = NPCRagRetriever._l0_identities.get(npc_kb_id, {})
	return l0.get("content", "你是%s。" % npc_name)


func get_fallback_response() -> String:
	## 获取降级回复（检索失败或LLM超时时使用）
	# 老画家：显示游戏提示
	if npc_kb_id == "oldpainter" and _fragment_state and _fragment_state.has_method("get_oldpainter_hint"):
		return _fragment_state.get_oldpainter_hint()
	if npc_kb_id != "":
		return NPCRagRetriever.get_fallback_response(npc_kb_id)
	return "……"


# ============================================================
# 动态开场白系统（Task 3）
# ============================================================

func get_greeting() -> String:
	## 根据全局颜色激活状态生成动态开场白
	## 每次颜色激活后 NPC 的开场白都会改变
	var game_state = _collect_game_state()
	var awakened = game_state.get("awakened_colors", [])
	var count = game_state.get("awakened_count", 0)
	var own_awake = _is_own_color_awakened()
	
	# 如果自己的颜色刚觉醒 → 使用专属觉醒开场白
	if own_awake and not _own_color_was_awakened:
		_own_color_was_awakened = true
		_greeting_phase = 2
		var reaction = _get_awakening_reaction()
		return reaction
	
	# 如果全局觉醒数量变化 → 更新阶段
	if count >= 5:
		_greeting_phase = 3
	elif count >= 1 and _greeting_phase < 1:
		_greeting_phase = 1
	
	var greeting = ""
	
	if own_awake:
		greeting = _get_post_awakening_greeting(count)
	elif count >= 5:
		# 老画家：五色集齐但白色未解锁时，引导去画室
		if npc_kb_id == "oldpainter" and not GameManager.is_color_awakened(GameManager.ColorType.WHITE):
			greeting = "五种颜色都回来了。（他看向画室角落）那里——那幅画。灰布下面。这么些年，该有人去揭开它了。"
		else:
			greeting = _get_world_changed_greeting()
	elif count >= 1:
		greeting = _get_partial_awake_greeting(count)
	else:
		greeting = _get_initial_greeting()
	
	# 避免连续重复同一句
	if greeting == _last_greeting and _greeting_phase > 0:
		greeting = _get_alt_greeting(count)
	
	_last_greeting = greeting
	_update_npc_mood(count, own_awake)
	return greeting


func _is_own_color_awakened() -> bool:
	## 检查该 NPC 代表的颜色是否已觉醒
	match npc_kb_id:
		"blacksmith": return GameManager.is_color_awakened(GameManager.ColorType.RED)
		"florist":    return GameManager.is_color_awakened(GameManager.ColorType.BLUE)
		"baker":      return GameManager.is_color_awakened(GameManager.ColorType.YELLOW)
		"gravekeeper":return GameManager.is_color_awakened(GameManager.ColorType.GREEN)
		"violinist":  return GameManager.is_color_awakened(GameManager.ColorType.PURPLE)
		"innkeeper":  return false  # 冯婶不承载颜色
	return false


func _get_initial_greeting() -> String:
	## 初始状态（0色）的开场白
	match npc_kb_id:
		"blacksmith":
			return "你来了。铁砧是冷的——你最好别碰。"
		"florist":
			return "今天的天空……比昨天亮一些？还是我的错觉。"
		"baker":
			return "面包还不热。不过你可以等——如果你不急的话。"
		"gravekeeper":
			return "墓园里很少有活人进来。你是来找谁的？"
		"violinist":
			return "（她没有看你。琴弓停在半空中——一直没有放下。）"
		"oldpainter":
			return "你来了。坐。先去看那些颜色——不是我的颜色，是他们的。"
		"innkeeper":
			return "（冯婶托着腮帮子，头一点一点地在打瞌睡。听到脚步声，她迷迷糊糊地抬起眼皮。）……哦——醒了啊。没事吧现在？饿不饿？"
		"linguide":
			return "溯光者，编号确认通过。欢迎来到溯光计划第一阶段训练场。请先观察五个日晷，记录阴影角度。"
		"chentechnology":
			return "（终端屏幕闪了一下。）观测数据接口已开放。有任何技术问题——我可以协助。没问题吧？"
		"wangdirector":
			return "溯光者，欢迎来到启程之镇。天枢公司为您的训练体验提供了完善的公共信息服务。如有疑问，请查阅培训手册。"
		"zhaosecurity":
			return "（他站在侧后方，没有看你的眼睛。）训练区域安全。请保持在指定边界内。"
	return "……"


func _get_partial_awake_greeting(count: int) -> String:
	## 部分觉醒（1-4色）时的开场白
	match npc_kb_id:
		"blacksmith":
			if count <= 2: return "今天镇上有点不对劲。你感觉到了吗？"
			return "火还是没烧起来——但今天锤子没那么冷了。"
		"florist":
			if count <= 2: return "你今天也注意到了吧？有些花好像……不一样了。"
			return "矢车菊的颜色——我差点看见了。就一秒钟。"
		"baker":
			if count <= 2: return "今天的炉子好像没那么冷了。奇怪——明明没点火。"
			return "面团发了。我不知道为什么——我还没放酵母。"
		"gravekeeper":
			if count <= 2: return "你听到那个声音了吗？不——不是你听到的那种。"
			return "铁门后面——它在动。不是风。"
		"violinist":
			if count <= 2: return "……你有没有听到一段旋律？不——不是琴声。"
			return "琴盒里多了一根弦。不是我的。但我认识它。"
		"oldpainter":
			if count <= 2: return "颜色们在互相寻找对方——只是他们还不会说话。"
			return "四个了。还差两个——其中一个在等我。"
		"innkeeper":
			if count <= 2: return "（冯婶多翻了一页登记簿——虽然还是空的。）今天镇上好像不太一样——我说不上来。你也感觉到了？"
			return "登记簿有字的那页——墨好像深了一点。你说奇怪不奇怪。算了——管它呢。"
		"linguide", "chentechnology", "wangdirector", "zhaosecurity":
			return _get_initial_greeting()
	return "镇上有些不对劲——你感觉到了吗？"


func _get_post_awakening_greeting(count: int) -> String:
	## 自己的颜色觉醒后的开场白
	match npc_kb_id:
		"blacksmith":
			if count == 1: return "（他抬头看了你一眼。眼睛里有火——不是愤怒，是温度。）……谢谢。火以前燃过。"
			if count <= 3: return "锤子不冷了。你知道吗——铁砧上多了一种颜色。红的。"
			return "你听到了吗？镇上其他声音也变了。不只有我在变。"
		"florist":
			if count == 1: return "（她的睫毛上还有泪痕。）……你来了。花谢了一些——不是因为缺水。"
			if count <= 3: return "我今天浇了矢车菊。水落到花瓣上的时候——它闪了一下。蓝的。"
			return "不只是我的花在变——你闻到面包的香味了吗？老唐的炉子——"
		"baker":
			if count == 1: return "（烤炉发出了一声低鸣。火燃了。）我就知道。我就知道火不会一直灭着。"
			if count <= 3: return "面包是金色的。不是灰色——是金色。你看到了吗？"
			return "老霍今早送来一把锤子——他说打铁的时候看到了红色。我开始明白他在说什么了。"
		"gravekeeper":
			if count <= 3: return "（他站在铁门外——第一次没往里躲。）我今天没去关门。外面——比里面可怕，但我不跑了。"
			return "四个人醒过来了。阿莲昨天在墓园门口放了一朵花。蓝色的。"
		"violinist":
			if count <= 3: return "（她拉了一个音。只有一个——但它没有消失。）……你想听吗？"
			return "我在等第五个人——一个画画的。他知道一段旋律。不是琴声——但琴能听懂。"
		"linguide", "chentechnology", "wangdirector", "zhaosecurity":
			return _get_initial_greeting()
	return "你回来了。世界不一样了——你也感觉到了吧？"


func _get_world_changed_greeting() -> String:
	## 5-6色觉醒后的开场白
	match npc_kb_id:
		"blacksmith":
			return "六个了。铁砧上的火今天自己燃了——不，不是我点的。是她。"
		"florist":
			return "所有的花都开了。不是季节——是她们终于能在颜色里呼吸。"
		"baker":
			return "今早全镇的面包都变成了金色。自己变的——我没烤。"
		"gravekeeper":
			return "铁门自己打开了。里面没有可怕的东西——只有一个她留下的签名。"
		"violinist":
			return "琴弦响了。不是我拉的——是六个人的声音在弦上汇到了一起。"
		"oldpainter":
			return "六色齐全了。画布上的裂痕合上了——不是被我补的。是被她们拼好的。"
		"innkeeper":
			return "今早我打开旅店大门——街上的颜色多得晃眼。我活了六十多年，第一次知道这条街长什么样。登记簿上——多了一行字。不是我的笔迹。但我认识它。"
		"linguide", "chentechnology", "wangdirector", "zhaosecurity":
			return _get_initial_greeting()
	return "世界完整了——你做到了。"


func _get_alt_greeting(count: int) -> String:
	## 备用开场白（避免连续重复）
	match npc_kb_id:
		"blacksmith": return "打铁打到一半——你来得正好。"
		"florist":    return "今天的天空看起来不太一样……"
		"baker":      return "面包还没出炉——不过快了。真的快了。"
		"gravekeeper":return "你又来了。这次想听什么？"
		"violinist":  return "（她点了点头，没有说话。）"
		"oldpainter": return "颜色们在等你。进来吧。"
		"innkeeper":  return "（冯婶翻了一页登记簿。）嗯？——哦，是你。饿了没？"
		"linguide":   return "溯光者。你的观测进度还需要加速。需要教学提示吗？"
		"chentechnology": return "（手指在终端上停了一下。）……需要技术支持吗？没问题。"
		"wangdirector": return "关于启程之镇，天枢公司还有一些补充信息——你愿意听吗？"
		"zhaosecurity": return "（他没有说话。只是往后退了一步，让出路来。）"
	return "嗯？"


func _update_npc_mood(count: int, own_awake: bool) -> void:
	## 更新 NPC 情绪状态（注入到 RAG 检索的 L3 上下文）
	_npc_mood = ""
	if own_awake:
		match npc_kb_id:
			"blacksmith": _npc_mood = "你感到愤怒找到了出口。铁砧上的火让你觉得一切都有温度了。你想对这个旅行者说点什么——但你不知道该从哪里开始。"
			"florist":    _npc_mood = "你刚刚哭过——但你不想让这个旅行者看到。蓝色回来了，花有了名字。你想感谢他，但你不知道怎么开口。"
			"baker":      _npc_mood = "火燃了。真正的火。你激动得有点语无伦次——面团在烤箱里变成了金色，你想让所有人都尝一口。"
			"gravekeeper":_npc_mood = "你害怕了很多年。但现在你不再跑了。铁门后面不是怪物——是你的恐惧自己。你终于敢看它了。"
			"violinist":  _npc_mood = "你听到了旋律——不是琴声，是记忆里的。弦没有声音，但你在等那个听琴的人。你不再觉得孤单了。"
	elif count >= 1:
		match npc_kb_id:
			"blacksmith": _npc_mood = "你注意到镇上有些不对劲。锤子今天格外沉重。你胸口有个东西在烧——但你不确定那是什么。"
			"florist":    _npc_mood = "你今天多看了天空一眼。有些花好像不一样了——但你不敢确定。你不想让别人觉得你疯了。"
			"baker":      _npc_mood = "炉子还是冷的。但你摸到了一块奇怪的余温。你想点火——但你不确定该不该点。"
			"gravekeeper":_npc_mood = "铁门后面有声音。不是风。你又关了一次门——但你知道那东西还在等。"
			"violinist":  _npc_mood = "琴盒里多了一根弦。你不确定从哪来的——但你认识那根弦的颜色。"
			"oldpainter": _npc_mood = "画布上出现了裂痕。不像是画笔留下的——像是画布自己在告别什么。"
			"innkeeper":  _npc_mood = "你注意到镇上有些不对劲。有人从旅店门口经过时脚步比平时快了——不是急事，是心情。你很久没见过有'心情'的人了。"


func _collect_game_state() -> Dictionary:
	## 从碎片状态管理器收集当前游戏状态
	if _fragment_state and _fragment_state.has_method("get_game_state"):
		var state = _fragment_state.get_game_state(npc_kb_id)
		if not _uses_fragment_compliance_mode():
			# 使用 NPC 实际警觉值；该值已由 GameManager.npc_state_cache 跨房间持久化。
			state["alert_level"] = int(npc_suspicion)
		# 注入 NPC 情绪状态
		if _npc_mood != "":
			state["npc_mood"] = _npc_mood
		# 注入 警觉上下文
		if not _uses_fragment_compliance_mode():
			var alert_context = get_alert_context_for_rag()
			if alert_context != "":
				state["alert_context"] = alert_context
		return state
	
	# 降级：返回默认状态
	return {
		"memory_stage": "initial",
		"alert_level": 0,
		"trust_level": 0,
		"awakened_colors": [],
		"npc_mood": _npc_mood,
		"alert_context": "" if _uses_fragment_compliance_mode() else get_alert_context_for_rag()
	}


func send_player_message(message: String) -> void:
	## 玩家输入 → RAG → LLM流式 → 聊天UI逐字显示
	## 先用本地规则更新警觉/合规度，再让LLM按最新状态自然表现态度
	print("[NPC] %s 收到: \"%s\"" % [npc_name, message])
	_llm_last_input = message  # 记下玩家输入，等LLM回复后分析
	check_safe_action(message)
	check_player_input_for_alert(message)
	
	# 记录对话历史到SQLite数据库
	ChatDatabase.log_message(npc_kb_id, "player", message, npc_alert_phase, npc_suspicion)
	
	# 检查LLM是否繁忙
	if LLMClient.has_method("is_busy") and LLMClient.is_busy():
		printerr("[NPC] %s LLM繁忙，拒绝请求" % npc_name)
		ChatDialogue.add_npc_msg("[降级] 请稍等，我还在思考刚才的问题……")
		return
	
	# 收集游戏状态（包含当前警觉阶段作为LLM上下文）
	var game_state = _collect_game_state()
	game_state["chat_history"] = ChatDatabase.get_history_as_text(npc_kb_id, DIALOGUE_HISTORY_LIMIT)
	
	# 根据警觉等级决定回应方式——LLM会根据上下文自然地调整语气
	match npc_alert_phase:
		NPCAlertPhase.SHUTDOWN:
			ChatDialogue.add_npc_msg("（%s背对着你，没有任何回应。）" % npc_name)
			return
		NPCAlertPhase.HOSTILE:
			var warn = _get_hostile_warning()
			ChatDialogue.add_npc_msg(warn)
			if current_state != NPCState.FLEEING:
				set_state(NPCState.FLEEING)
				ChatDialogue.close()
			return
		_:
			# 信任/谨慎/怀疑/警觉 → 都走LLM，由LLM自己决定语气
			_send_to_llm(message, game_state)


func _send_to_llm(message: String, game_state: Dictionary) -> void:
	## 发送到LLM的公共方法
	var system_prompt = NPCRagRetriever.assemble_prompt(npc_kb_id, message, game_state)
	
	if system_prompt == "":
		printerr("[NPC] %s RAG组装prompt失败，使用降级" % npc_name)
		ChatDialogue.add_npc_msg("[降级] %s" % get_fallback_response())
		return
	
	print("══════ [RAG+STREAM] %s | prompt=%d chars | kb=%s | sus=%.0f | phase=%d ══════" % 
		  [npc_name, system_prompt.length(), npc_kb_id, npc_suspicion, npc_alert_phase])
	
	# 开始流式输出
	_stream_suppress_asterisk_action = false
	ChatDialogue.stream_begin()
	
	# 连接流式信号（先断开旧的）
	_disconnect_stream_signals()
	LLMClient.stream_token.connect(_on_stream_token)
	LLMClient.stream_completed.connect(_on_stream_completed)
	LLMClient.stream_failed.connect(_on_stream_failed)
	
	LLMClient.chat_stream(system_prompt, message)


# ============================================================
# 警觉升级反应 — NPC 在不同警觉阶段转换时的即时对话
# ============================================================

func _get_alert_escalation_reaction(old_phase: int, new_phase: int) -> String:
	## 警觉阶段升级时 NPC 的即时反应（插入在正常回应之前）
	if old_phase >= new_phase:
		return ""
	
	# 从信任到谨慎
	if old_phase == NPCAlertPhase.TRUSTING and new_phase == NPCAlertPhase.CAUTIOUS:
		match npc_kb_id:
			"blacksmith": return "（老霍的锤子停顿了一瞬——他看了你一眼，但没有说话。）"
			"florist":    return "（阿莲的手指在花瓣上停顿了一下。她抬起头——然后又低了下去。）"
			"baker":      return "（老唐的笑容收了一分。他的手在围裙上擦了擦。）"
			"gravekeeper":return "（老崔的呼吸变重了一拍。他没有动，但他的眼神锁定了你。）"
			"violinist":  return "（薇拉的琴弓停在半空中。她没有看你——但她不再看琴了。）"
			"innkeeper":  return "（冯婶的打鼾声停了一拍。她没睁眼——但你知道她醒着。）"
		return "（%s看了你一眼，没有说话。）" % npc_name
	
	# 从谨慎到怀疑
	if old_phase == NPCAlertPhase.CAUTIOUS and new_phase == NPCAlertPhase.SUSPICIOUS:
		match npc_kb_id:
			"blacksmith": return "（老霍放下了锤子。他的手慢慢握成了拳头。）……你问这个干什么。"
			"florist":    return "（阿莲后退了一小步。花瓶在她手里晃了一下。）……你——不是来买花的。"
			"baker":      return "（老唐不再笑了。他往烤炉靠了一步——不是取暖，是防备。）"
			"gravekeeper":return "（老崔的手放在了铁门上。不是推——是准备关。）你在找什么。"
			"violinist":  return "（薇拉合上了琴盒。她的手指在扣子上停留了很久。）……别问。"
			"innkeeper":  return "（冯婶终于抬起了头。她没有笑。）……你问的这些东西——不是一个旅客该问的。"
		return "（%s盯着你。空气突然变冷了。）" % npc_name
	
	# 从怀疑到警觉
	if old_phase == NPCAlertPhase.SUSPICIOUS and new_phase == NPCAlertPhase.ALARMED:
		match npc_kb_id:
			"blacksmith": return "（老霍把锤子举到了胸前——不是要打铁。）不买东西就走。——现在。"
			"florist":    return "（花洒从阿莲手里滑落。水溅了一地。）请离开。我没有更多要说的。"
			"baker":      return "（老唐挡在了烤炉前。他的声音不再带着笑意。）够了。——走吧。"
			"gravekeeper":return "（老崔拉开了铁门——不是请你进去。是准备自己退进去。）你最好走。"
			"violinist":  return "（薇拉站起来。琴盒紧紧抱在胸前。）……我喊人了。"
			"innkeeper":  return "（冯婶把登记簿往怀里收了收。她的声音比平时轻——不是在哄你睡觉，是在给自己壮胆。）……我这儿没什么好看的。"
		return "（%s的语气变得冰冷。）你在问不该问的东西。"
	
	# 从警报到敌对
	if old_phase == NPCAlertPhase.ALARMED and new_phase == NPCAlertPhase.HOSTILE:
		match npc_kb_id:
			"blacksmith": return "（老霍怒吼。）滚！这不是你该来的地方！"
			"florist":    return "（阿莲的声音在发抖。）你走——你走！我喊人了！"
			"baker":      return "（老唐抓起了擀面杖。）出去！别让我说第三遍！"
			"gravekeeper":return "（老崔消失在铁门后面。门砰地关上——里面传来反锁的声音。）"
			"violinist":  return "（薇拉跑了。琴盒撞在门框上——她甚至没有回头。）"
			"innkeeper":  return "（冯婶慢慢站起来。她没有喊——她只是把登记簿抱在胸前，看着你。那个眼神不是愤怒——是\"我早就知道会有这么一天\"。）……走吧。今晚不留客了。"
		return "（%s不再和你说话。他转身就走。）"
	
	return ""


func _get_hostile_warning() -> String:
	## NPC 在敌对阶段发出的最后警告（说完后逃跑/关门）
	match npc_kb_id:
		"blacksmith": return "（老霍把锤子往铁砧上一砸——不是打铁，是警告。）滚！——再说一个字我就喊巡夜的。"
		"florist":    return "（阿莲退到墙角。她的手在身后的架子上摸索着什么。）走——求你了。我真的会喊。"
		"baker":      return "（老唐把擀面杖往桌上一拍。）最后一次。——你走不走？"
		"gravekeeper":return "（老崔已经半身退入铁门。他只说了一句。）趁你还记得。走吧。"
		"violinist":  return "（薇拉已经不在原地了。琴盒也带走了——只剩一张空椅子。）"
		"innkeeper":  return "（冯婶把登记簿放进抽屉——慢慢地，像在安放什么东西。然后她转身走进了后面的房间。门没关——但你不会再进去了。）"
	return "（%s转身离开了——他不会回来了。）" % npc_name


# ============================================================
# 给予物品操作（Fix 3）
# ============================================================

## 可给予的物品映射: item_id → 触发函数
const GIVABLE_ITEMS: Dictionary = {
	0: { "check": "_check_red",    "npc": "blacksmith", "msg": "拿出铸造日志" },
	1: { "check": "_check_blue",   "npc": "florist",    "msg": "拿出矢车菊" },
	2: { "check": "_check_yellow", "npc": "baker",      "msg": "拿出火种" },
}

func can_give_item() -> bool:
	## 检查当前是否可以向该NPC给予物品
	if not _fragment_state or npc_kb_id == "": return false
	for item_id in GIVABLE_ITEMS:
		var cfg = GIVABLE_ITEMS[item_id]
		if cfg["npc"] == npc_kb_id and InventoryManager.has_item(item_id):
			return true
	return false

func get_givable_item() -> Dictionary:
	## 返回当前可给予的物品信息 {item_id, item_name, icon}
	if not _fragment_state or npc_kb_id == "": return {}
	for item_id in GIVABLE_ITEMS:
		var cfg = GIVABLE_ITEMS[item_id]
		if cfg["npc"] == npc_kb_id and InventoryManager.has_item(item_id):
			var meta = InventoryManager.get_item_meta(item_id)
			return { "item_id": item_id, "item_name": meta.get("name", "?"), "icon": meta.get("icon", "?") }
	return {}

func send_give_item(item_id: int) -> void:
	## 玩家主动给予物品 → 直接触发颜色觉醒检测 + 大幅降低警觉
	var cfg = GIVABLE_ITEMS.get(item_id, {})
	if cfg.is_empty(): return
	if cfg["npc"] != npc_kb_id:
		printerr("[NPC] %s 无法接收物品 #%d" % [npc_name, item_id])
		return
	
	var meta = InventoryManager.get_item_meta(item_id)
	var give_msg = "（玩家将%s交给了%s）" % [meta.get("name", "物品"), npc_name]
	ChatDialogue.add_player_msg("[给予] %s" % meta.get("icon", "?"))
	print("[NPC] %s 收到给予物品: %s (id=%d)" % [npc_name, meta.get("name", "?"), item_id])
	
	# 给予正确物品 → 信任大幅恢复
	modify_alert(ALERT_GIVE_ITEM, "收到正确的物品")
	if npc_alert_phase <= NPCAlertPhase.CAUTIOUS:
		doubts_player_identity = false
	
	# 直接触发颜色觉醒检测（使用物品）
	if _fragment_state and _fragment_state.has_method("check_trigger"):
		var triggered = _fragment_state.check_trigger(npc_kb_id, "[GIVE]%d" % item_id)
		if triggered:
			var c = _fragment_state._count_awakened()
			var reaction = _get_awakening_reaction()
			ChatDialogue.add_npc_msg(reaction)
			ChatDialogue.add_npc_msg("── 颜色恢复 %d/6 ──" % c)
			if _fragment_state.has_method("check_global"):
				_fragment_state.check_global()
		else:
			ChatDialogue.add_npc_msg(get_fallback_response())


func _disconnect_stream_signals() -> void:
	if LLMClient.stream_token.is_connected(_on_stream_token):
		LLMClient.stream_token.disconnect(_on_stream_token)
	if LLMClient.stream_completed.is_connected(_on_stream_completed):
		LLMClient.stream_completed.disconnect(_on_stream_completed)
	if LLMClient.stream_failed.is_connected(_on_stream_failed):
		LLMClient.stream_failed.disconnect(_on_stream_failed)


func _on_stream_token(token: String) -> void:
	var visible_token := _filter_stream_action_markup(token)
	if visible_token != "":
		ChatDialogue.stream_add(visible_token)


func _on_stream_completed(full_text: String) -> void:
	_disconnect_stream_signals()
	var clean_text := _clean_model_dialogue_text(full_text)
	ChatDialogue.stream_end(clean_text)
	while ChatDialogue.has_method("is_streaming_response") and ChatDialogue.is_streaming_response():
		await get_tree().process_frame
	# 记录NPC回复到SQLite数据库
	ChatDatabase.log_message(npc_kb_id, "npc", clean_text, npc_alert_phase, npc_suspicion)
	print("[NPC] %s 流式完成 (%d chars)" % [npc_name, clean_text.length()])
	
	# === LLM判断警觉：分析LLM的回复内容，而不是做关键词匹配 ===
	_analyze_llm_response_for_alert(clean_text, _llm_last_input)
	
	# 对话完成后检查颜色触发
	_check_color_trigger()


func _clean_model_dialogue_text(raw_text: String) -> String:
	var text := raw_text.strip_edges()
	if text.is_empty():
		return text

	var speaker_prefixes := [
		"[%s]" % npc_name,
		"【%s】" % npc_name,
		"%s：" % npc_name,
		"%s:" % npc_name,
		"[NPC]",
		"【NPC】"
	]
	for prefix in speaker_prefixes:
		if text.begins_with(prefix):
			text = text.substr(prefix.length()).strip_edges()

	var paren_regex := RegEx.new()
	if paren_regex.compile("\\s*[（(][^）)]*[）)]\\s*") == OK:
		text = paren_regex.sub(text, "", true).strip_edges()

	var asterisk_regex := RegEx.new()
	if asterisk_regex.compile("\\s*\\*[^*\\n]{1,120}\\*\\s*") == OK:
		text = asterisk_regex.sub(text, "", true).strip_edges()

	var bracket_narration_regex := RegEx.new()
	if bracket_narration_regex.compile("\\s*[【\\[]?(旁白|动作|表情|心理|内心|舞台指令)[：:][^】\\]\\n]*[】\\]]?\\s*") == OK:
		text = bracket_narration_regex.sub(text, "", true).strip_edges()

	text = text.replace("*", "").strip_edges()
	return text


func _filter_stream_action_markup(token: String) -> String:
	## 流式阶段先隐藏 *动作/旁白* 内容，最终文本仍由 _clean_model_dialogue_text 兜底清理。
	var visible := ""
	for ch in token:
		if ch == "*":
			_stream_suppress_asterisk_action = not _stream_suppress_asterisk_action
			continue
		if _stream_suppress_asterisk_action:
			continue
		visible += ch
	return visible


func _on_stream_failed(error: String) -> void:
	_disconnect_stream_signals()
	ChatDialogue.stream_end("")
	var fallback = get_fallback_response()
	ChatDialogue.add_npc_msg("[降级] %s" % fallback)
	print("[NPC] %s 流式失败 (err=%s) → 降级: \"%s\"" % [npc_name, error.left(80), fallback])
	# 仍然检查触发
	_check_color_trigger()


func _check_color_trigger() -> void:
	if not _fragment_state or not _fragment_state.has_method("check_trigger"):
		return
	
	var triggered = _fragment_state.check_trigger(npc_kb_id)
	if triggered:
		var c = _fragment_state._count_awakened()
		
		# 颜色觉醒 — 重置该NPC的警觉（他的记忆回来了）
		if _is_own_color_awakened():
			npc_suspicion = 0.0
			doubts_player_identity = false
			_update_alert_phase()
			print("[NPC:%s] 颜色觉醒 — 警觉重置为0 (信任恢复)" % npc_name)
		
		# NPC 专属觉醒反应
		var reaction = _get_awakening_reaction()
		ChatDialogue.add_npc_msg(reaction)
		
		# 全局进度提示
		ChatDialogue.add_npc_msg("── 颜色恢复 %d/6 ──" % c)
		
		print("[NPC] %s 触发颜色觉醒！ (总数=%d)" % [npc_name, c])
		
		# 全局检查
		if _fragment_state.has_method("check_global"):
			_fragment_state.check_global()
	# 如果其他NPC的颜色被唤醒 — 该NPC略微降低警觉（世界变得更"正确"了）
	elif GameManager._count_awakened() > 0 and npc_suspicion > 0:
		# 检查是否刚发生了觉醒（通过比较 n 秒内的觉醒数量变化）
		# 简化为：每次对话后如果全局有觉醒但自己没触发，略微降低警觉
		if npc_alert_phase <= NPCAlertPhase.SUSPICIOUS:
			modify_alert(-2.0, "世界在恢复——感觉好了一点")


func _get_awakening_reaction() -> String:
	## 返回该NPC觉醒时的专属对话
	var c = _fragment_state._count_awakened() if _fragment_state else 0
	match npc_kb_id:
		"blacksmith":
			return "（锤子停在半空中。沉默了很久。）\n\n“……火以前燃过。”\n\n他的声音在抖——不是害怕，是愤怒终于找到了出口。"
		"florist":
			return "（她盯着那朵矢车菊。眼泪自己流了下来。）\n\n“……这朵花……不一样。”\n\n这是她第一次哭。她不知道眼泪从哪里来——但她停不下来。"
		"baker":
			return "（烤炉发出一声闷响——火燃了。真正的火。）\n\n“我就知道——我就知道火不会灭的！”\n\n面团在烤炉里变成了金黄色。整个面包房弥漫着久违的麦香。"
		"gravekeeper":
			return "（他后退了一步。铁门发出刺耳的声响。）\n\n“……你看到了吗？裂开的地方——”\n\n他的恐惧不再是对外界的防御——他终于敢正视自己害怕的东西。"
		"violinist":
			return "（琴弓停在半空。她听到了什么——不是琴声，是记忆里的旋律。）\n\n“……紫色的。你听过这个词吗？”\n\n弦没声音，不是因为弦坏了——是因为她等的那个听琴的人还没来。"
	return "世界发生了一些变化——颜色恢复了。(%d/6)" % c
