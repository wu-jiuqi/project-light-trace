extends Node2D
## 碎片世界基类
## 所有碎片世界场景的基础模板，提供通用功能

# 预加载依赖脚本（非单例，按需实例化）
const WantedSystemScript = preload("res://scripts/systems/wanted_system.gd")
const ClueSystemScript = preload("res://scripts/systems/clue_system.gd")

# 警觉等级常量（对齐 WantedSystem.AlertLevel）
const ALERT_SAFE = 0
const ALERT_SUSPICIOUS = 1
const ALERT_INVESTIGATING = 2
const ALERT_ALERTED = 3
const ALERT_HUNTING = 4
const ALERT_LOCKDOWN = 5

@onready var player: CharacterBody2D = $Player
@onready var npc_container: Node2D = $NPCs
@onready var ui_layer: CanvasLayer = $UILayer
@onready var dialogue_ui: Control = $UILayer/DialogueUI
@onready var wanted_indicator: Control = $UILayer/WantedIndicator
@onready var clue_notification: Control = $UILayer/ClueNotification

var wanted_system: Node = null
var clue_system: Node = null
var current_fragment: FragmentManager.FragmentData

signal fragment_loaded(fragment_id: String)
signal source_mark_found()
signal fragment_exited()

func _ready() -> void:
	_init_systems()
	_load_fragment_data()
	if current_fragment == null:
		printerr("[FragmentWorld] 未指定碎片数据，模板场景不会启动玩法逻辑")
		return
	print("[FragmentWorld] 碎片世界加载完成: %s" % current_fragment.world_name)
	fragment_loaded.emit(current_fragment.id)

func _init_systems() -> void:
	# 初始化通缉系统
	wanted_system = WantedSystemScript.new()
	wanted_system.name = "WantedSystem"
	add_child(wanted_system)
	wanted_system.alert_level_changed.connect(_on_alert_changed)
	wanted_system.suspicion_changed.connect(_on_suspicion_changed)
	
	# 初始化线索系统
	clue_system = ClueSystemScript.new()
	clue_system.name = "ClueSystem"
	add_child(clue_system)
	clue_system.clue_discovered.connect(_on_clue_discovered)
	clue_system.source_mark_located.connect(_on_source_mark_located)
	clue_system.source_mark_decoded.connect(_on_source_mark_decoded)

func _load_fragment_data() -> void:
	current_fragment = FragmentManager.current_fragment
	# 子类重写以加载特定碎片数据

func _on_alert_changed(new_level: int, _old_level: int) -> void:
	match new_level:
		ALERT_SAFE:
			wanted_indicator.modulate = Color(0, 0, 0, 0)
		ALERT_SUSPICIOUS:
			_update_wanted_indicator("可疑", Color.YELLOW)
		ALERT_INVESTIGATING:
			_update_wanted_indicator("调查中", Color.ORANGE)
		ALERT_ALERTED:
			_update_wanted_indicator("警戒!", Color.RED)
		ALERT_HUNTING:
			_update_wanted_indicator("追捕!!", Color.CRIMSON)
		ALERT_LOCKDOWN:
			wanted_indicator.modulate = Color.DARK_RED
			# 全城锁定效果
			_on_lockdown()

func _update_wanted_indicator(text: String, color: Color) -> void:
	wanted_indicator.modulate = color
	var label = wanted_indicator.get_node_or_null("Label")
	if label:
		label.text = text

func _on_suspicion_changed(current: float, _max_val: float) -> void:
	var bar = wanted_indicator.get_node_or_null("ProgressBar")
	if bar:
		bar.value = current

func _on_lockdown() -> void:
	print("[FragmentWorld] 全城锁定！")
	# 子类可重写以实现专门的锁定效果

func _on_clue_discovered(clue: Dictionary) -> void:
	clue_notification.show()
	await get_tree().create_timer(2.0).timeout
	clue_notification.hide()

func _on_source_mark_located(mark_name: String) -> void:
	print("[FragmentWorld] 源印定位: %s" % mark_name)
	source_mark_found.emit()

func _on_source_mark_decoded(mark_name: String) -> void:
	print("[FragmentWorld] 源印解码: %s" % mark_name)
	_on_fragment_completed()

func _on_fragment_completed() -> void:
	var was_completed = current_fragment.decrypt_state == FragmentManager.DecryptState.COMPLETED

	if not was_completed:
		# 首次修复：记录源印 + 增加修复进度
		var random_hint = _get_random_other_clue()
		GameManager.record_source_mark(
			current_fragment.id,
			current_fragment.source_mark_name,
			random_hint
		)
		print("[FragmentWorld] 首次修复碎片 %s，修复进度 +%.1f%%" % [current_fragment.id, 100.0 / GameManager.total_fragments])
	else:
		print("[FragmentWorld] 重玩碎片 %s，不增加修复进度" % current_fragment.id)

	FragmentManager.complete_fragment(current_fragment)
	SaveManager.save_game()
	# 返回星图
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")

func _get_random_other_clue() -> String:
	# 随机获取一个其它碎片的线索
	var other_fragments: Array[FragmentManager.FragmentData] = []
	for f in FragmentManager.fragments:
		if f.id != current_fragment.id and f.decrypt_state != FragmentManager.DecryptState.COMPLETED:
			other_fragments.append(f)
	
	if other_fragments.is_empty():
		return "「归源终章」"
	
	var random_f = other_fragments[randi() % other_fragments.size()]
	return random_f.hint_full

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("escape"):
		_confirm_exit()

func _try_interact() -> void:
	## 检测玩家附近是否有NPC，有则触发对话
	if not player or not dialogue_ui:
		return
	
	var npcs = get_tree().get_nodes_in_group("npc")
	var closest: Node2D = null
	var closest_dist: float = 80.0
	
	for npc in npcs:
		if npc is CharacterBody2D:
			var dist = player.global_position.distance_to(npc.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = npc
	
	if closest and closest.has_method("start_dialogue"):
		# 使用动态开场白（如果可用）
		var greeting = ""
		if closest.has_method("get_greeting"):
			greeting = closest.get_greeting()
		elif closest.has_method("get_fallback_response"):
			greeting = closest.get_fallback_response()
		
		closest.start_dialogue()
		if closest.has_method("get_dialogue_options"):
			dialogue_ui.start_dialogue(closest.npc_name, closest.get_dialogue_options())

func _confirm_exit() -> void:
	# 确认退出碎片
	fragment_exited.emit()
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")
