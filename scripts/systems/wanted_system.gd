extends Node
## 通缉/警觉系统
## 管理玩家在碎片世界中的暴露程度，驱动NPC追捕行为

# === 警觉等级 ===
enum AlertLevel {
	SAFE,           # 安全 - NPC对你无感知
	SUSPICIOUS,     # 可疑 - 个别NPC开始注意你（对应一星通缉）
	INVESTIGATING,  # 调查中 - NPC主动向你靠近试探（二星）
	ALERTED,        # 警戒 - 区域内NPC保持警惕（三星）
	HUNTING,        # 追捕 - NPC主动追逐你（四星）
	LOCKDOWN        # 锁定 - 全区域封禁，精英NPC出动（五星）
}

# === 警觉度数值 ===
var alert_level: int = AlertLevel.SAFE
var suspicion_value: float = 0.0       # 0.0 ~ 100.0
var max_suspicion: float = 100.0

# === 警觉衰减 ===
var decay_rate: float = 2.0             # 每秒衰减量（安全时）
var decay_delay: float = 5.0            # 警觉上升后多久开始衰减
var time_since_last_alert: float = 0.0

# === 各等级配置 ===
var level_thresholds: Dictionary = {
	AlertLevel.SAFE: 0.0,
	AlertLevel.SUSPICIOUS: 15.0,     # >15 进入可疑
	AlertLevel.INVESTIGATING: 35.0,   # >35 进入调查
	AlertLevel.ALERTED: 55.0,         # >55 进入警戒
	AlertLevel.HUNTING: 75.0,         # >75 进入追捕
	AlertLevel.LOCKDOWN: 95.0,        # >95 进入锁定
}

# === 行为对应警觉度增值 ===
const SUSPICION_SAY_WRONG: float = 12.0     # 说错话
const SUSPICION_ACT_STRANGE: float = 8.0     # 行为怪异
const SUSPICION_FOUND_INTRUDING: float = 15.0 # 闯入禁区
const SUSPICION_CAUGHT_STEALING: float = 25.0 # 偷窃被看见
const SUSPICION_ATTACKED: float = 35.0        # 攻击NPC
const SUSPICION_DEBUNKED_LIE: float = 5.0    # 撒谎圆过去（小幅）
const SUSPICION_EXPOSED: float = 60.0         # 身份暴露

# === 信号 ===
signal alert_level_changed(new_level: int, old_level: int)
signal suspicion_changed(current: float, max_val: float)
signal npc_approaching(npc_name: String, level: int)
signal lockdown_started()
signal lockdown_ended()

func _ready() -> void:
	print("[WantedSystem] 警觉系统初始化")
	reset()

func reset() -> void:
	alert_level = AlertLevel.SAFE
	suspicion_value = 0.0
	time_since_last_alert = 0.0

func add_suspicion(amount: float, reason: String = "") -> void:
	var old_level = alert_level
	suspicion_value = clampf(suspicion_value + amount, 0.0, max_suspicion)
	time_since_last_alert = 0.0
	
	var new_level = _calculate_level()
	if new_level != old_level:
		alert_level = new_level
		alert_level_changed.emit(new_level, old_level)
		print("[WantedSystem] 警觉等级变更: %d -> %d (原因: %s)" % [old_level, new_level, reason])
	
	suspicion_changed.emit(suspicion_value, max_suspicion)

func reduce_suspicion(amount: float) -> void:
	var old_level = alert_level
	suspicion_value = maxf(0.0, suspicion_value - amount)
	
	var new_level = _calculate_level()
	if new_level != old_level:
		alert_level = new_level
		alert_level_changed.emit(new_level, old_level)
	
	suspicion_changed.emit(suspicion_value, max_suspicion)

func _calculate_level() -> int:
	for level in range(AlertLevel.LOCKDOWN, AlertLevel.SAFE - 1, -1):
		if suspicion_value >= level_thresholds.get(level, 0.0):
			return level
	return AlertLevel.SAFE

func _process(delta: float) -> void:
	# 警觉衰减
	if suspicion_value > 0:
		time_since_last_alert += delta
		if time_since_last_alert >= decay_delay:
			reduce_suspicion(decay_rate * delta)

func get_alert_description() -> String:
	match alert_level:
		AlertLevel.SAFE:
			return "安全"
		AlertLevel.SUSPICIOUS:
			return "可疑 - NPC开始注意你的言行"
		AlertLevel.INVESTIGATING:
			return "调查中 - NPC主动靠近试探"
		AlertLevel.ALERTED:
			return "警戒 - 保持警惕，小心行事"
		AlertLevel.HUNTING:
			return "追捕中 - 快逃！"
		AlertLevel.LOCKDOWN:
			return "全城锁定 - 无处可逃"
	return "未知"

func is_safe() -> bool:
	return alert_level <= AlertLevel.SUSPICIOUS

func is_danger() -> bool:
	return alert_level >= AlertLevel.ALERTED
