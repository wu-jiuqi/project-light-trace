extends Node2D
## fragment_0001 场景脚本 — 玩家实例化 + 深度层切换 + 日晷交互 + 线索系统 + Tab面板
## E 键交互日晷 → 线索写入 ClueSystem → Tab 面板查看 → 钟楼校准 → 源印显现

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const ClueSystemScript = preload("res://scripts/systems/clue_system.gd")

## DepthLayer Y 范围阈值
const LAYER_1_Y: float = 450.0
const LAYER_2_Y: float = 250.0

## 日晷数据（与 Sundial 场景 export 变量对齐）
const SUNDIAL_DATA := {
	"A": { "angle": 12, "place": "广场中央喷泉旁", "desc": "白石日晷投下 12° 阴影。底座编号 TP-2077-03-A。", "name": "观测点A · 广场日晷" },
	"B": { "angle": 24, "place": "钟楼底部东侧", "desc": "青铜日晷投下 24° 阴影。氧化铜面上有一道新的手指印。", "name": "观测点B · 钟楼日晷" },
	"C": { "angle": 36, "place": "市集橱窗前", "desc": "黑石日晷投下 36° 阴影。橱窗里的七个面包排列得一动不动。", "name": "观测点C · 市集日晷" },
	"D": { "angle": 48, "place": "研究所门口", "desc": "灰岗岩日晷投下 48° 阴影。日晷上方的摄像头没有转动。", "name": "观测点D · 研究所日晷" },
	"E": { "angle": 66, "place": "边界光墙前", "desc": "第五个日晷被砸碎了。碎片被整齐排成一条线，像有人替你留下了缺失项。", "name": "观测点E · 边界残晷" },
}
const OBSERVATION_ORDER: Array[String] = ["A", "B", "C", "D", "E"]
const TARGET_CLOCK_ANGLE: int = 66

## 玩家引用
var _player: CharacterBody2D = null
var _current_layer: int = 0
var _depth_layers: Dictionary = {}

## 日晷状态
var observed_sundials: Dictionary = {}
var compliance: int = 100
var clock_angle: int = 12
var source_mark_revealed: bool = false
var completed: bool = false

## 线索系统
var _clue_system: Node = null

## UI 引用
var _collection_panel: CanvasLayer = null
var _clue_list_container: VBoxContainer = null
var _progress_label: Label = null
var _message_panel: Panel = null
var _message_title: Label = null
var _message_body: Label = null
var _message_timer = null
var _angle_panel: Panel = null
var _angle_value: Label = null
var _angle_bg: ColorRect = null
var _interact_hint_label: Label = null

## UIRoot — 统一新增UI容器（所有新增UI均挂在此节点下）
var _ui_root: CanvasLayer = null

## 合规度条组件
var _compliance_bar_bg: ColorRect = null
var _compliance_bar_fill: ColorRect = null
var _compliance_label: Label = null
var _compliance_value_label: Label = null
var _compliance_warning_icon: Label = null
var _compliance_pulse_tween: Tween = null

## 林指导幕间事件追踪
var _player_idle_time: float = 0.0
var _intermission_triggered: bool = false

## 边界光墙触碰追踪
var _boundary_warning_triggered: bool = false
var _boundary_cooldown: float = 0.0

## 合规度归零一次性标记（防重复创建 timer）
var _compliance_zero_triggered: bool = false

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("fragment_state")
	_create_clue_system()
	_cache_depth_layers()
	_spawn_player()
	_setup_ui_root()          # 创建 UIRoot CanvasLayer + 合规度条
	_setup_interact_hint()
	_setup_collection_panel()
	_setup_message_panel()
	_setup_angle_panel()
	_prepare_fragment_context()
	# 恢复之前的探索进度（从暗室返回等情况）
	_try_restore_state()
	_show_opening_message()
	# 从暗室等场景返回时 SceneFader 处于黑屏状态，需要淡入
	SceneFader.fade_in()
	print("[Fragment0001] 启程之镇就绪 — E键观测日晷 | Tab键查看线索")


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id("0001")
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _create_clue_system() -> void:
	_clue_system = ClueSystemScript.new()
	_clue_system.name = "ClueSystem0001"
	add_child(_clue_system)
	print("[Fragment0001] ClueSystem 已创建")


func _show_opening_message() -> void:
	_show_message(
		"林指导",
		"溯光者，编号确认通过。欢迎来到溯光计划第一阶段训练场。\n先观察五个日晷，记录阴影角度，再回钟楼校准指针。",
		6.0
	)


func _process(delta: float) -> void:
	_update_player_z()
	_update_player_depth_layer()
	_check_lin_intermission(delta)
	_check_boundary(delta)


# ============================================================
# UIRoot 初始化（所有新增UI统一挂载点）
# ============================================================

func _setup_ui_root() -> void:
	"""创建 UIRoot CanvasLayer，作为所有新增UI的父节点"""
	_ui_root = CanvasLayer.new()
	_ui_root.name = "UIRoot"
	_ui_root.layer = 70
	add_child(_ui_root)
	_setup_compliance_bar()
	print("[Fragment0001] UIRoot 已创建")


# ============================================================
# 玩家管理
# ============================================================

func _cache_depth_layers() -> void:
	var depth_layer_root = get_node_or_null("WorldRoot/DepthLayer")
	if not depth_layer_root:
		printerr("[Fragment0001] 未找到 WorldRoot/DepthLayer 节点")
		return
	for i in range(1, 4):
		var layer_name = "DepthLayer_%d" % i
		var layer_node = depth_layer_root.get_node_or_null(layer_name)
		if layer_node:
			_depth_layers[i] = layer_node
		else:
			printerr("[Fragment0001] 未找到 %s 节点" % layer_name)


func _get_layer_by_y(y: float) -> int:
	if y > LAYER_1_Y:
		return 1
	elif y > LAYER_2_Y:
		return 2
	else:
		return 3


func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D

	var spawn_marker: Marker2D = null
	var spawn_points = get_node_or_null("WorldRoot/SpawnPoints")
	if spawn_points:
		# 优先使用 SceneManager 指定的出生点（如从暗室返回的 "OutDoor"）
		var pending = SceneManager.pending_spawn_point
		if not pending.is_empty():
			spawn_marker = spawn_points.get_node_or_null(pending) as Marker2D
			if spawn_marker:
				SceneManager.pending_spawn_point = ""  # 消费掉
				print("[Fragment0001] 使用指定出生点 '%s'" % pending)
		# 回退到默认
		if not spawn_marker:
			spawn_marker = spawn_points.get_node_or_null("Default") as Marker2D

	var spawn_pos: Vector2 = Vector2(644, 655)
	if spawn_marker:
		spawn_pos = spawn_marker.global_position
		print("[Fragment0001] 出生位置: %s" % str(spawn_pos))
	else:
		print("[Fragment0001] 未找到出生点，使用默认位置")

	var target_layer = _get_layer_by_y(spawn_pos.y)
	var layer_node = _depth_layers.get(target_layer) as Node2D

	if layer_node:
		layer_node.add_child(_player)
		_player.global_position = spawn_pos
		_current_layer = target_layer
		print("[Fragment0001] 玩家已实例化到 DepthLayer_%d，位置: %s" % [target_layer, str(spawn_pos)])
	else:
		var world_root = get_node_or_null("WorldRoot")
		if world_root:
			world_root.add_child(_player)
		else:
			add_child(_player)
		_player.global_position = spawn_pos
		_current_layer = 0
		printerr("[Fragment0001] DepthLayer_%d 节点不存在，玩家降级添加到 WorldRoot" % target_layer)


func _update_player_z() -> void:
	if not _player:
		return
	if _player.z_index != 0:
		_player.z_index = 0


func _update_player_depth_layer() -> void:
	if not _player or _depth_layers.is_empty():
		return

	var player_y: float = _player.global_position.y
	var target_layer: int = _get_layer_by_y(player_y)

	if target_layer == _current_layer:
		return

	var layer_node = _depth_layers.get(target_layer) as Node2D
	if not layer_node:
		return

	var saved_global_pos: Vector2 = _player.global_position
	_player.reparent(layer_node)
	_player.global_position = saved_global_pos

	var old_layer: int = _current_layer
	_current_layer = target_layer
	print("[Fragment0001] 玩家从 DepthLayer_%d 切换到 DepthLayer_%d (Y=%.0f)" % [old_layer, target_layer, player_y])


# ============================================================
# E 键 : 日晷交互回调（由 Sundial.interact() → PlayerController 调用）
# ============================================================

func on_sundial_interact(sundial: Node2D) -> void:
	## 日晷 E 键交互处理入口
	var id: String = "A"
	if "sundial_id" in sundial:
		id = str(sundial.sundial_id)
	elif "sundial_id" in sundial.get_meta_list():
		id = str(sundial.get_meta("sundial_id", "A"))
	else:
		# 从节点名称推断（SundialA → A）
		id = sundial.name.right(1)

	if not SUNDIAL_DATA.has(id):
		return

	# 已观测
	if observed_sundials.has(id):
		_show_message(
			SUNDIAL_DATA[id]["name"],
			"这条观测数据已记录：%d°。" % observed_sundials[id],
			3.0
		)
		return

	# 残晷 E 需先观测 A-D 全部
	if id == "E" and _count_observed() < 4:
		_show_message(
			"观测点E · 边界残晷",
			"日晷已经碎了，看不出角度。也许先把其他四个角度记全。",
			4.5
		)
		return

	# 首次观测
	var data = SUNDIAL_DATA[id]
	observed_sundials[id] = data["angle"]

	# 标记 Sundial 节点已观测
	if sundial.has_method("mark_observed"):
		sundial.mark_observed()

	# 写入线索系统
	_clue_system.discover_clue(
		data["name"], "observation",
		"%s：%d°" % [data["place"], data["angle"]],
		data["place"]
	)

	# 刷新 Tab 面板线索列表
	_update_clue_list()

	# 额外叙事提示
	var extra := ""
	if id == "E":
		extra = "\n四个已知角度是 12、24、36、48。第五项不是看到的，是推出来的：66。"
	elif observed_sundials.size() == 2:
		extra = "\n陈技术的终端亮了一下：阴影角度之间存在稳定间隔。"
	elif observed_sundials.size() == 4:
		extra = "\n林指导放低声音：第五个，不是用眼睛。"

	_show_message(
		data["name"],
		"%s\n已写入观测日志。%s" % [data["desc"], extra],
		5.5
	)

	print("[Fragment0001] 日晷%s 观测完成: %d° (%d/5)" % [id, data["angle"], observed_sundials.size()])

	# ——— 消息弹窗触发清单 ———
	# 延迟一小段时间，让观测消息先显示再替换为提示消息
	var obs_count: int = observed_sundials.size()

	if obs_count == 1:
		# #2 首次观测日晷后 — await 后再次确认状态有效
		await get_tree().create_timer(2.0).timeout
		if observed_sundials.size() >= 1:
			_show_message(
				"观测记录",
				"你注意到日晷的阴影角度各不相同。也许这些数字之间存在某种规律。按 Tab 可以查看已收集的线索。",
				5.0
			)
	elif obs_count == 3:
		# #3 观测到 3/5 日晷时 — await 后再次确认状态有效
		await get_tree().create_timer(2.0).timeout
		if observed_sundials.size() >= 3:
			_show_message(
				"进展",
				"你已经观测了三个日晷。继续探索镇子——还有更多线索等着你。",
				4.0
			)
	elif obs_count == 5:
		# #5 观测到 5/5 日晷时 — await 后再次确认状态有效
		await get_tree().create_timer(2.0).timeout
		if observed_sundials.size() >= 5:
			_show_message(
				"全部收集",
				"五个日晷全部记录完毕。数据之间的间隔似乎有规律——前往钟楼试试你的推断。",
				5.0
			)


# ============================================================
# E 键 : 钟楼交互回调（由 BellTower.interact() → PlayerController 调用）
# ============================================================

func on_bell_tower_interact(bell_tower: Node2D) -> void:
	## 钟楼 E 键交互处理入口（仅在门锁定时调用）
	if observed_sundials.size() < 5:
		_show_message(
			"钟楼观测台",
			"观测台被锁定。需要五个日晷数据，包含第五个残晷的推断角度。\n已记录：%d/5" % observed_sundials.size(),
			4.0
		)
		return

	# 打开校准面板
	clock_angle = 12  # 重置初始角度
	if _angle_bg:
		_angle_bg.visible = true
	_angle_panel.visible = true
	_update_angle_value()
	print("[Fragment0001] 钟楼校准面板已打开")


## E 键 : 源印交互回调（由 SourceMark.interact() → PlayerController 调用）
func on_source_mark_interact() -> void:
	_complete_fragment()


# ============================================================
# 日晷校准面板
# ============================================================

func _setup_angle_panel() -> void:
	var panel_layer = CanvasLayer.new()
	panel_layer.name = "AnglePanelLayer"
	panel_layer.layer = 80
	add_child(panel_layer)

	# 半透明遮罩（默认隐藏，校准面板打开时才显示）
	_angle_bg = ColorRect.new()
	_angle_bg.name = "AngleBg"
	_angle_bg.color = Color(0, 0, 0, 0.55)
	_angle_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_angle_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_angle_bg.visible = false
	panel_layer.add_child(_angle_bg)

	_angle_panel = Panel.new()
	_angle_panel.name = "CalibrationPanel"
	_angle_panel.position = Vector2(438, 178)
	_angle_panel.size = Vector2(404, 280)
	_angle_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_angle_panel.visible = false
	panel_layer.add_child(_angle_panel)

	var title = Label.new()
	title.position = Vector2(24, 18)
	title.size = Vector2(356, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "钟楼日晷校准"
	title.add_theme_font_size_override("font_size", 18)
	_angle_panel.add_child(title)

	var hint = Label.new()
	hint.position = Vector2(30, 58)
	hint.size = Vector2(344, 52)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "用已记录的角度推断第五项。每次调整 6°。"
	hint.add_theme_font_size_override("font_size", 13)
	_angle_panel.add_child(hint)

	_angle_value = Label.new()
	_angle_value.position = Vector2(138, 116)
	_angle_value.size = Vector2(128, 44)
	_angle_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_angle_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_angle_value.text = "12°"
	_angle_value.add_theme_font_size_override("font_size", 26)
	_angle_panel.add_child(_angle_value)

	var minus_btn = Button.new()
	minus_btn.position = Vector2(56, 120)
	minus_btn.size = Vector2(64, 40)
	minus_btn.text = "-6°"
	minus_btn.pressed.connect(_on_clock_minus_pressed)
	_angle_panel.add_child(minus_btn)

	var plus_btn = Button.new()
	plus_btn.position = Vector2(284, 120)
	plus_btn.size = Vector2(64, 40)
	plus_btn.text = "+6°"
	plus_btn.pressed.connect(_on_clock_plus_pressed)
	_angle_panel.add_child(plus_btn)

	var submit_btn = Button.new()
	submit_btn.position = Vector2(56, 196)
	submit_btn.size = Vector2(132, 42)
	submit_btn.text = "验证"
	submit_btn.pressed.connect(_submit_clock_angle)
	_angle_panel.add_child(submit_btn)

	var close_btn = Button.new()
	close_btn.position = Vector2(216, 196)
	close_btn.size = Vector2(132, 42)
	close_btn.text = "关闭"
	close_btn.pressed.connect(_close_angle_panel)
	_angle_panel.add_child(close_btn)


func _on_clock_minus_pressed() -> void:
	clock_angle = wrapi(clock_angle - 6, 0, 360)
	_update_angle_value()


func _on_clock_plus_pressed() -> void:
	clock_angle = wrapi(clock_angle + 6, 0, 360)
	_update_angle_value()


func _update_angle_value() -> void:
	if _angle_value:
		_angle_value.text = "%d°" % clock_angle


func _submit_clock_angle() -> bool:
	if clock_angle == TARGET_CLOCK_ANGLE:
		# 正确校准 — 金色光扩散效果
		var bell_pos: Vector2 = _get_bell_tower_position()
		_create_light_spread_effect(bell_pos, Color(1.0, 0.72, 0.24, 0.9), 1.5)
		_close_angle_panel()
		# 等待光效展现后再解锁
		await get_tree().create_timer(0.6).timeout
		_unlock_bell_tower_door()
		return true

	if abs(clock_angle - TARGET_CLOCK_ANGLE) <= 6:
		# 差 6° — 橙色回光效果
		var bell_pos: Vector2 = _get_bell_tower_position()
		_create_orange_flash_effect(bell_pos)
		_modify_compliance(-4, "校准接近但未通过")
		_show_message("钟楼观测台", "指针发出橙色回光。很接近，但还不是正确的缺失角度。", 3.5)
	else:
		_modify_compliance(-8, "错误校准")
		_show_message("钟楼观测台", "齿轮轻响一声后回弹。系统提示：训练误差已记录。", 3.5)
	return false


func _get_bell_tower_position() -> Vector2:
	"""获取钟楼节点的全局位置，用于视觉特效定位"""
	var bell_tower: Node2D = _find_bell_tower_node()
	if bell_tower:
		return bell_tower.global_position
	# 回退：钟楼默认位置
	return Vector2(650, 360)


func _create_orange_flash_effect(at_position: Vector2) -> void:
	"""在指定位置创建橙色回光闪烁效果（差 6° 校准失败时）"""
	if not _ui_root:
		return
	var flash: ColorRect = ColorRect.new()
	flash.name = "OrangeFlashEffect"
	flash.color = Color(1.0, 0.45, 0.0, 0.7)
	flash.size = Vector2(120, 120)
	flash.position = at_position - Vector2(60, 60)
	flash.pivot_offset = Vector2(60, 60)
	flash.scale = Vector2(0.3, 0.3)
	_ui_root.add_child(flash)

	var tween: Tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(flash, "scale", Vector2(0.5, 0.5), 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)


func _create_light_spread_effect(at_position: Vector2, glow_color: Color, duration: float) -> void:
	"""在指定位置创建金色光扩散效果（校准正确时）"""
	if not _ui_root:
		return
	var glow: ColorRect = ColorRect.new()
	glow.name = "GoldenSpreadEffect"
	glow.color = glow_color
	glow.size = Vector2(80, 80)
	glow.position = at_position - Vector2(40, 40)
	glow.pivot_offset = Vector2(40, 40)
	glow.scale = Vector2(0.5, 0.5)
	_ui_root.add_child(glow)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow, "scale", Vector2(2.5, 2.5), duration)
	tween.tween_property(glow, "modulate:a", 0.0, duration).from(1.0)
	tween.finished.connect(func() -> void:
		if is_instance_valid(glow):
			glow.queue_free()
	)


func _close_angle_panel() -> void:
	if _angle_bg:
		_angle_bg.visible = false
	if _angle_panel:
		_angle_panel.visible = false


# ============================================================
# 源印显现与通关
# ============================================================

func _unlock_bell_tower_door() -> void:
	## 校准正确后解锁钟楼门
	var bell_tower = _find_bell_tower_node()
	if bell_tower and bell_tower.has_method("unlock_door"):
		bell_tower.unlock_door()
	else:
		printerr("[Fragment0001] 未找到 BellTower 节点，无法解锁门")

	source_mark_revealed = true

	_clue_system.locate_source_mark("晨曦之印", "钟楼底层暗室")

	# #10 源印显现后 — 已有处理
	_show_message(
		"钟楼暗室",
		"66°。指针落下，钟楼下方传来齿轮咬合声。\n暗门已打开，可再次靠近钟楼进入暗室。",
		5.0
	)

	print("[Fragment0001] 钟楼门已解锁，暗室可进入")


func _find_bell_tower_node() -> Node2D:
	var root = get_node_or_null("WorldRoot")
	if not root:
		root = self
	# 在 DepthLayer 中递归查找 BellTower
	var nodes = find_children("BellTower*", "Node2D", true, false)
	if nodes.size() > 0:
		return nodes[0] as Node2D
	# 备用：模糊匹配
	for child in get_tree().current_scene.get_children():
		if child.name.begins_with("BellTower"):
			return child as Node2D
	return null


# ============================================================
# 探索进度保存/恢复（跨暗室场景往返）
# ============================================================

func save_state() -> void:
	## 将当前探索进度保存到 FragmentManager，供重新进入时恢复
	var clues_data: Array[Dictionary] = []
	if _clue_system and "discovered_clues" in _clue_system:
		clues_data = _clue_system.discovered_clues.duplicate(true)

	FragmentManager.set_fragment_state("0001", "observed_sundials", observed_sundials)
	FragmentManager.set_fragment_state("0001", "compliance", compliance)
	FragmentManager.set_fragment_state("0001", "source_mark_revealed", source_mark_revealed)
	FragmentManager.set_fragment_state("0001", "discovered_clues", clues_data)
	print("[Fragment0001] 探索进度已保存 — 日晷(%d/5) 合规度(%d) 源印(%s)" % [observed_sundials.size(), compliance, source_mark_revealed])


func _try_restore_state() -> void:
	## 尝试从 FragmentManager 恢复之前的探索进度
	var saved_sundials = FragmentManager.get_fragment_state("0001", "observed_sundials")
	if saved_sundials is Dictionary and not saved_sundials.is_empty():
		observed_sundials = saved_sundials
		# 重新标记场景中对应 Sundial 节点为已观测
		for id in observed_sundials:
			_mark_sundial_observed(id)

	var saved_compliance = FragmentManager.get_fragment_state("0001", "compliance")
	if typeof(saved_compliance) == TYPE_INT:
		compliance = saved_compliance

	var saved_revealed = FragmentManager.get_fragment_state("0001", "source_mark_revealed")
	if typeof(saved_revealed) == TYPE_BOOL:
		source_mark_revealed = saved_revealed

	# 恢复线索系统
	var saved_clues = FragmentManager.get_fragment_state("0001", "discovered_clues")
	if saved_clues is Array and not saved_clues.is_empty():
		_clue_system.discovered_clues = saved_clues.duplicate(true)
		_update_clue_list()

	# 恢复合规度条
	if _compliance_bar_fill:
		_update_compliance_bar()

	if observed_sundials.size() > 0:
		print("[Fragment0001] 探索进度已恢复 — 日晷(%d/5) 合规度(%d) 源印(%s)" % [observed_sundials.size(), compliance, source_mark_revealed])
	else:
		pass  # 首次进入，无需恢复


func _mark_sundial_observed(id: String) -> void:
	## 将场景中对应 Sundial 节点标记为已观测状态
	var root = get_node_or_null("WorldRoot")
	if not root:
		root = self
	var patterns := ["Sundial%s" % id, "Sundial_%s" % id]
	for pattern in patterns:
		var nodes = root.find_children(pattern + "*", "Node2D", true, false)
		for node in nodes:
			if node.has_method("mark_observed"):
				node.mark_observed()
				return


# ============================================================
# P0：完整胜利画面 — 替换 _complete_fragment()
# ============================================================

func _complete_fragment() -> void:
	if completed:
		return
	completed = true

	# 1. 自动保存
	SaveManager.save_game()

	# 2. 标记源印与碎片完成
	_clue_system.decode_source_mark("晨曦之印", "晨曦镇训练场完成校准，钟楼暗室已开启。")
	GameManager.record_source_mark("0001", "晨曦之印", "钟楼暗室便笺：所有答案都可能被修改过。")

	var fragment = FragmentManager.current_fragment
	if fragment == null:
		fragment = FragmentManager.get_fragment_by_id("0001")
	FragmentManager.complete_fragment(fragment)

	print("[Fragment0001] 碎片完成！显示胜利画面")

	# 3. 创建胜利画面面板（在 UIRoot 下）
	if not _ui_root:
		_setup_ui_root()

	var victory_bg: ColorRect = ColorRect.new()
	victory_bg.name = "VictoryBg"
	victory_bg.color = Color(0, 0, 0, 0.6)
	victory_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(victory_bg)

	var victory_panel: Panel = Panel.new()
	victory_panel.name = "VictoryPanel"
	victory_panel.position = Vector2(240, 100)
	victory_panel.size = Vector2(800, 520)
	victory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# 暗色半透明背景 + 金色边框
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.102, 0.102, 0.18, 0.92)  # #1a1a2e alpha 0.92
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.85, 0.72, 0.28, 1.0)  # 金色
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	victory_panel.add_theme_stylebox_override("panel", panel_style)
	_ui_root.add_child(victory_panel)

	# VBox 主布局
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VictoryVBox"
	vbox.position = Vector2(40, 30)
	vbox.size = Vector2(720, 460)
	vbox.add_theme_constant_override("separation", 16)
	victory_panel.add_child(vbox)

	# 标题
	var title_label: Label = Label.new()
	title_label.name = "VictoryTitle"
	title_label.text = "碎片 #0001 完成"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35, 1.0))
	title_label.size = Vector2(720, 40)
	vbox.add_child(title_label)

	# 源印信息行：图标 + "晨曦之印" + 状态 "已解析"
	var source_row: HBoxContainer = HBoxContainer.new()
	source_row.name = "SourceInfoRow"
	source_row.add_theme_constant_override("separation", 10)
	source_row.size = Vector2(720, 36)
	vbox.add_child(source_row)

	var source_icon: Label = Label.new()
	source_icon.text = "✦"
	source_icon.add_theme_font_size_override("font_size", 22)
	source_icon.add_theme_color_override("font_color", Color(1.0, 0.72, 0.24, 1.0))
	source_row.add_child(source_icon)

	var source_name: Label = Label.new()
	source_name.text = "晨曦之印"
	source_name.add_theme_font_size_override("font_size", 18)
	source_name.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82, 1.0))
	source_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	source_row.add_child(source_name)

	var source_status: Label = Label.new()
	source_status.text = "已解析"
	source_status.add_theme_font_size_override("font_size", 14)
	source_status.add_theme_color_override("font_color", Color(0.35, 0.78, 0.55, 1.0))
	source_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	source_row.add_child(source_status)

	# 进度条：修复进度 8.3%
	var progress_vbox: VBoxContainer = VBoxContainer.new()
	progress_vbox.name = "ProgressSection"
	progress_vbox.add_theme_constant_override("separation", 6)
	progress_vbox.size = Vector2(720, 50)
	vbox.add_child(progress_vbox)

	var progress_label: Label = Label.new()
	progress_label.text = "修复进度：8.3%"
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
	progress_vbox.add_child(progress_label)

	var progress_bg: ColorRect = ColorRect.new()
	progress_bg.name = "ProgressBg"
	progress_bg.color = Color(0.2, 0.2, 0.24, 1.0)
	progress_bg.size = Vector2(720, 18)
	progress_vbox.add_child(progress_bg)

	var progress_fill: ColorRect = ColorRect.new()
	progress_fill.name = "ProgressFill"
	progress_fill.color = Color(0.22, 0.48, 0.84, 1.0)  # 蓝色填充
	progress_fill.size = Vector2(720 * 0.083, 18)  # 8.3% 宽
	progress_bg.add_child(progress_fill)

	# 林指导祝贺文本
	var congrats_label: Label = Label.new()
	congrats_label.name = "CongratsText"
	congrats_label.text = "训练通过。你的校准很接近标准——虽然还有偏差。这是第一块碎片，后面的路会更难。但你已经踏出了重要的一步。"
	congrats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	congrats_label.add_theme_font_size_override("font_size", 15)
	congrats_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.78, 1.0))
	congrats_label.size = Vector2(720, 0)
	congrats_label.custom_minimum_size = Vector2(720, 72)
	vbox.add_child(congrats_label)

	# 分隔间距
	var spacer: Control = Control.new()
	spacer.size = Vector2(720, 20)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 按钮横排
	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 40)
	button_row.size = Vector2(720, 48)
	vbox.add_child(button_row)

	var return_btn: Button = Button.new()
	return_btn.name = "ReturnBtn"
	return_btn.text = "返回星图"
	return_btn.size = Vector2(180, 44)
	return_btn.add_theme_font_size_override("font_size", 16)
	return_btn.pressed.connect(_on_return_to_star_map)
	button_row.add_child(return_btn)

	var continue_btn: Button = Button.new()
	continue_btn.name = "ContinueBtn"
	continue_btn.text = "继续游玩"
	continue_btn.size = Vector2(180, 44)
	continue_btn.add_theme_font_size_override("font_size", 16)
	continue_btn.pressed.connect(_on_continue_playing)
	button_row.add_child(continue_btn)

	# 4. 面板淡入动画（0 → 1 alpha，Tween 0.4s）
	victory_panel.modulate = Color(1, 1, 1, 0)
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(victory_panel, "modulate:a", 1.0, 0.4)


func _on_return_to_star_map() -> void:
	"""胜利画面 [返回星图] 按钮回调"""
	print("[Fragment0001] 玩家选择返回星图")
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _on_continue_playing() -> void:
	"""胜利画面 [继续游玩] 按钮回调 — 关闭面板，留在当前场景"""
	print("[Fragment0001] 玩家选择继续游玩")
	if _ui_root:
		var victory_bg := _ui_root.get_node_or_null("VictoryBg") as ColorRect
		if victory_bg:
			victory_bg.queue_free()
		var victory_panel := _ui_root.get_node_or_null("VictoryPanel") as Panel
		if victory_panel:
			victory_panel.modulate = Color(1, 1, 1, 1)  # 终止淡入动画，防止 Tween 竞争
			victory_panel.queue_free()


# ============================================================
# 合规度系统
# ============================================================

func _modify_compliance(delta: int, reason: String) -> void:
	compliance = clampi(compliance + delta, 0, 100)
	var sign = "+" if delta >= 0 else ""
	print("[Fragment0001] 合规度 %s%d -> %d | %s" % [sign, delta, compliance, reason])

	# 更新合规度条UI
	_update_compliance_bar()

	# #8 合规度 ≤ 50：警告
	if compliance <= 50 and compliance > 30:
		_show_message(
			"系统提示",
			"合规度降低。注意：持续违规可能触发强制回训。",
			4.0
		)

	# #9 合规度 ≤ 30：严重警告
	if compliance <= 30 and compliance > 0:
		_show_message(
			"⚠ 系统提示",
			"合规度已进入临界区。如降至 0，将触发强制回归。",
			5.0
		)

	# L6 强制返回：合规度归零（仅触发一次）
	if compliance <= 0 and not _compliance_zero_triggered:
		_compliance_zero_triggered = true
		_show_message(
			"系统协议",
			"合规度归零。系统启动强制回归协议。",
			3.0
		)
		# 等待 3 秒后跳转星图
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/star_map.tscn")
		)


# ============================================================
# P1：合规度完整UI联动
# ============================================================

func _setup_compliance_bar() -> void:
	"""在 UIRoot 下创建合规度条UI"""
	if not _ui_root:
		return

	# 位置：右上角 (860, 20)，尺寸 (240, 32)
	var bar_container: Control = Control.new()
	bar_container.name = "ComplianceBarContainer"
	bar_container.position = Vector2(860, 20)
	bar_container.size = Vector2(280, 36)
	_ui_root.add_child(bar_container)

	# ⚠/⛔ 警告图标（合规度低时显示，位于条左侧）
	_compliance_warning_icon = Label.new()
	_compliance_warning_icon.name = "ComplianceWarningIcon"
	_compliance_warning_icon.position = Vector2(0, 4)
	_compliance_warning_icon.size = Vector2(24, 28)
	_compliance_warning_icon.add_theme_font_size_override("font_size", 18)
	_compliance_warning_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_compliance_warning_icon.text = ""
	bar_container.add_child(_compliance_warning_icon)

	# 标签 "合规度"（图标右侧）
	_compliance_label = Label.new()
	_compliance_label.name = "ComplianceLabel"
	_compliance_label.position = Vector2(28, 0)
	_compliance_label.size = Vector2(60, 16)
	_compliance_label.text = "合规度"
	_compliance_label.add_theme_font_size_override("font_size", 12)
	_compliance_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	bar_container.add_child(_compliance_label)

	# 数值标签
	_compliance_value_label = Label.new()
	_compliance_value_label.name = "ComplianceValue"
	_compliance_value_label.position = Vector2(88, 0)
	_compliance_value_label.size = Vector2(48, 16)
	_compliance_value_label.text = "100%"
	_compliance_value_label.add_theme_font_size_override("font_size", 12)
	_compliance_value_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	bar_container.add_child(_compliance_value_label)

	# 背景条（灰色 #333）
	_compliance_bar_bg = ColorRect.new()
	_compliance_bar_bg.name = "ComplianceBarBg"
	_compliance_bar_bg.position = Vector2(0, 20)
	_compliance_bar_bg.size = Vector2(240, 12)
	_compliance_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)  # #333
	bar_container.add_child(_compliance_bar_bg)

	# 填充条
	_compliance_bar_fill = ColorRect.new()
	_compliance_bar_fill.name = "ComplianceBarFill"
	_compliance_bar_fill.position = Vector2(0, 0)
	_compliance_bar_fill.size = Vector2(240, 12)  # 初始100%
	_compliance_bar_fill.color = Color(0.227, 0.482, 0.835, 1.0)  # #3a7bd5 蓝色
	_compliance_bar_bg.add_child(_compliance_bar_fill)

	print("[Fragment0001] 合规度条已创建")


func _update_compliance_bar() -> void:
	"""更新合规度条的颜色、宽度、图标和数值"""
	if not _compliance_bar_fill or not _compliance_value_label:
		return

	# 更新数值标签
	_compliance_value_label.text = "%d%%" % compliance

	# 计算填充宽度
	var max_width: float = 240.0
	var fill_width: float = max_width * (float(compliance) / 100.0)
	_compliance_bar_fill.size.x = fill_width

	# 停止之前的脉冲动画
	if _compliance_pulse_tween and _compliance_pulse_tween.is_valid():
		_compliance_pulse_tween.kill()
		_compliance_pulse_tween = null

	# 颜色动态切换
	if compliance >= 70:
		_compliance_bar_fill.color = Color(0.227, 0.482, 0.835, 1.0)  # 蓝色 #3a7bd5
		if _compliance_warning_icon:
			_compliance_warning_icon.text = ""
	elif compliance >= 50:
		_compliance_bar_fill.color = Color(0.831, 0.627, 0.09, 1.0)  # 琥珀色 #d4a017
		if _compliance_warning_icon:
			_compliance_warning_icon.text = ""
	else:
		_compliance_bar_fill.color = Color(0.8, 0.2, 0.2, 1.0)  # 红色 #cc3333
		# 合规度 ≤ 50：显示 ⚠ 图标；≤ 30 显示 ⛔
		if _compliance_warning_icon:
			if compliance <= 30:
				_compliance_warning_icon.text = "⛔"
			else:
				_compliance_warning_icon.text = "⚠"

		# 红色脉冲动画（透明度在 0.3~1.0 循环）
		_compliance_pulse_tween = create_tween()
		_compliance_pulse_tween.set_loops()
		_compliance_pulse_tween.tween_property(_compliance_bar_fill, "modulate:a", 0.3, 0.6)
		_compliance_pulse_tween.tween_property(_compliance_bar_fill, "modulate:a", 1.0, 0.6)


func _count_observed() -> int:
	var count := 0
	for id in ["A", "B", "C", "D"]:
		if observed_sundials.has(id):
			count += 1
	return count


# ============================================================
# 交互提示（底部居中 "[E] 观察 xxx"）
# ============================================================

func _setup_interact_hint() -> void:
	var hint_layer = CanvasLayer.new()
	hint_layer.name = "InteractHintLayer"
	hint_layer.layer = 40
	add_child(hint_layer)

	_interact_hint_label = Label.new()
	_interact_hint_label.name = "InteractHint"
	_interact_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interact_hint_label.size = Vector2(320, 32)
	_interact_hint_label.position = Vector2(480, 660)
	_interact_hint_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.50, 1.0))
	_interact_hint_label.add_theme_font_size_override("font_size", 16)
	_interact_hint_label.text = ""
	_interact_hint_label.visible = false
	hint_layer.add_child(_interact_hint_label)

	# 连接到 PlayerController 的交互提示信号
	if _player and _player.has_signal("interact_hint_changed"):
		if not _player.interact_hint_changed.is_connected(_on_interact_hint_changed):
			_player.interact_hint_changed.connect(_on_interact_hint_changed)


func _on_interact_hint_changed(show: bool, hint_text: String) -> void:
	if _interact_hint_label:
		_interact_hint_label.text = hint_text
		_interact_hint_label.visible = show and not hint_text.is_empty()


# ============================================================
# 消息面板（底部弹出提示）
# ============================================================

func _setup_message_panel() -> void:
	var msg_layer = CanvasLayer.new()
	msg_layer.name = "MessageLayer"
	msg_layer.layer = 60
	add_child(msg_layer)

	_message_panel = Panel.new()
	_message_panel.name = "MessagePanel"
	_message_panel.position = Vector2(300, 520)
	_message_panel.size = Vector2(680, 148)
	_message_panel.visible = false
	msg_layer.add_child(_message_panel)

	_message_title = Label.new()
	_message_title.name = "MessageTitle"
	_message_title.position = Vector2(18, 14)
	_message_title.size = Vector2(640, 24)
	_message_title.add_theme_font_size_override("font_size", 16)
	_message_title.add_theme_color_override("font_color", Color(0.22, 0.50, 0.78, 1.0))
	_message_panel.add_child(_message_title)

	_message_body = Label.new()
	_message_body.name = "MessageBody"
	_message_body.position = Vector2(18, 44)
	_message_body.size = Vector2(640, 88)
	_message_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_body.add_theme_font_size_override("font_size", 14)
	_message_panel.add_child(_message_body)


func _show_message(title: String, body: String, duration: float = 4.0) -> void:
	if not _message_title or not _message_body:
		return
	_message_title.text = title
	_message_body.text = body
	_message_panel.visible = true

	# 清除之前的定时器
	if _message_timer and _message_timer.timeout.is_connected(_hide_message):
		_message_timer.timeout.disconnect(_hide_message)

	_message_timer = get_tree().create_timer(duration)
	_message_timer.timeout.connect(_hide_message)


func _hide_message() -> void:
	if _message_panel:
		_message_panel.visible = false


# ============================================================
# Tab 键 : 收集信息面板（显示 ClueSystem 线索列表）
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):  # Tab 键
		# 校准面板打开时不响应 Tab
		if _angle_panel and _angle_panel.visible:
			return
		_toggle_collection_panel()

	# 校准面板快捷键
	if event.is_action_pressed("escape"):
		if _angle_panel and _angle_panel.visible:
			_close_angle_panel()
			get_viewport().set_input_as_handled()


func _setup_collection_panel() -> void:
	var layer = CanvasLayer.new()
	layer.name = "CollectionPanelLayer"
	layer.layer = 64
	add_child(layer)

	var bg = ColorRect.new()
	bg.name = "PanelBg"
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)

	var panel = ColorRect.new()
	panel.name = "CollectionPanel"
	panel.color = Color(0.08, 0.08, 0.12, 0.95)
	panel.size = Vector2(640, 440)
	panel.position = Vector2(320, 140)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(panel)

	var title = Label.new()
	title.name = "Title"
	title.text = "收集信息 — 碎片 #0001 启程之镇"
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1))
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(620, 36)
	title.position = Vector2(10, 12)
	panel.add_child(title)

	# 观测进度
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.text = "日晷观测：0/5"
	_progress_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1))
	_progress_label.add_theme_font_size_override("font_size", 15)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.size = Vector2(620, 24)
	_progress_label.position = Vector2(10, 50)
	panel.add_child(_progress_label)

	# 线索滚动区域
	var scroll = ScrollContainer.new()
	scroll.name = "ClueScroll"
	scroll.position = Vector2(16, 84)
	scroll.size = Vector2(608, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_clue_list_container = VBoxContainer.new()
	_clue_list_container.name = "ClueList"
	_clue_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_clue_list_container)

	var hint = Label.new()
	hint.name = "TabHint"
	hint.text = "按 Tab 关闭  |  靠近日晷按 E 观测  |  收集全部后前往钟楼校准"
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1))
	hint.add_theme_font_size_override("font_size", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(620, 30)
	hint.position = Vector2(10, 398)
	panel.add_child(hint)

	_collection_panel = layer
	_collection_panel.hide()
	print("[Fragment0001] 收集信息面板已创建")


func _toggle_collection_panel() -> void:
	if not _collection_panel:
		return
	_collection_panel.visible = not _collection_panel.visible
	if _collection_panel.visible:
		_update_clue_list()
	print("[Fragment0001] 收集面板: %s" % ("打开" if _collection_panel.visible else "关闭"))


func _update_clue_list() -> void:
	"""刷新 Tab 面板中的线索列表和进度标签"""
	if not _clue_list_container:
		return

	# 清空旧列表
	for child in _clue_list_container.get_children():
		child.queue_free()

	# 更新进度标签
	if _progress_label:
		_progress_label.text = "日晷观测：%d/5" % observed_sundials.size()

	# 显示已发现线索
	var clues: Array = []
	if _clue_system:
		clues = _clue_system.discovered_clues

	if clues.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无线索。靠近场景中的日晷，按 E 键观测。"
		empty_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 1))
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_clue_list_container.add_child(empty_label)
		return

	for clue in clues:
		var item = _create_clue_item(clue)
		_clue_list_container.add_child(item)

	# P2：当观测到 3+ 日晷时，在列表底部添加规律提示
	if observed_sundials.size() >= 3:
		var hint_label := Label.new()
		hint_label.name = "PatternHint"
		hint_label.text = "数据之间的间隔似乎有规律——这些角度应该不是随机的。"
		hint_label.add_theme_color_override("font_color", Color(0.5, 0.75, 0.85, 0.8))
		hint_label.add_theme_font_size_override("font_size", 13)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# 斜体：在 Godot 4 中通过添加字体变体实现
		_clue_list_container.add_child(hint_label)


func _create_clue_item(clue: Dictionary) -> Control:
	"""创建单条线索的 UI 行"""
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 8)

	# 类型标签
	var type_icon = Label.new()
	var type_text: String = clue.get("type", "?")
	match type_text:
		"observation": type_text = "[观测]"
		"hint": type_text = "[提示]"
		"dialogue": type_text = "[对话]"
		"item": type_text = "[物品]"
		"source_mark": type_text = "[源印]"
		_: type_text = "[%s]" % type_text
	type_icon.text = type_text
	type_icon.add_theme_color_override("font_color", Color(0.35, 0.65, 0.85, 1))
	type_icon.add_theme_font_size_override("font_size", 13)
	type_icon.custom_minimum_size = Vector2(56, 0)
	container.add_child(type_icon)

	# 线索名称
	var name_label = Label.new()
	name_label.text = str(clue.get("name", "未知"))
	name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82, 1))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.custom_minimum_size = Vector2(180, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(name_label)

	# 描述
	var desc_label = Label.new()
	desc_label.text = str(clue.get("description", ""))
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 1))
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(desc_label)

	return container


# ============================================================
# P1：林指导幕间事件
# ============================================================

func _find_lin_npc_position() -> Vector2:
	"""查找林指导NPC的全局位置，回退到默认位置"""
	var world_root := get_node_or_null("WorldRoot")
	if world_root:
		# 搜索名称包含 "Lin" 或 "linguide" 或 "林" 的节点
		var patterns: Array[String] = ["Lin", "linguide", "林"]
		for pattern in patterns:
			var nodes: Array[Node] = world_root.find_children("*" + pattern + "*", "", true, false)
			for node in nodes:
				if node is Node2D:
					return (node as Node2D).global_position
	# 回退：从设计稿中林指导的默认位置
	return Vector2(356, 300)


func _check_lin_intermission(delta: float) -> void:
	"""在 _process 中追踪林指导幕间事件触发条件"""
	if _intermission_triggered or not _player:
		return

	# 条件1：玩家停留不动（无移动输入 → velocity ≈ 0）
	var player_velocity: Vector2 = _player.velocity if "velocity" in _player else Vector2.ZERO
	if player_velocity.length() < 1.0:
		_player_idle_time += delta
	else:
		_player_idle_time = 0.0

	# 需要至少空闲 90 秒
	if _player_idle_time < 90.0:
		return

	# 条件2：玩家靠近林指导 NPC（距离 < 200px）
	var lin_pos: Vector2 = _find_lin_npc_position()
	var dist_to_lin: float = _player.global_position.distance_to(lin_pos)
	if dist_to_lin >= 200.0:
		return

	# 两个条件同时满足 — 触发幕间事件（仅一次）
	_intermission_triggered = true
	print("[Fragment0001] 林指导幕间事件触发 — 玩家空闲 %.1fs，距林 %.0fpx" % [_player_idle_time, dist_to_lin])

	_show_message(
		"林指导的低语",
		"（通讯器里传来一阵微弱的声音。林指导的语调比平时慢了一些，像是在回忆什么。）\n\n" +
		"\"你见过凌晨四点的训练场吗？我见过——很多次。不是因为勤奋。是因为睡不着。\"\n\n" +
		"停顿。然后通讯器又恢复了平时的冷漠。",
		8.0
	)

	# 降低合规度 -3
	_modify_compliance(-3, "林指导情绪波动——系统判定为异常")


# ============================================================
# P1：边界光墙触碰事件
# ============================================================

func _check_boundary(delta: float) -> void:
	"""在 _process 中追踪玩家是否靠近场景边界"""
	if not _player:
		return

	# 冷却倒计时
	if _boundary_cooldown > 0.0:
		_boundary_cooldown -= delta
		return

	var pos: Vector2 = _player.global_position
	var near_boundary: bool = false

	if pos.x < 50.0 or pos.x > 1150.0 or pos.y < 50.0 or pos.y > 750.0:
		near_boundary = true

	if not near_boundary:
		return

	# 边界触碰 — 触发（冷却 30 秒）
	_boundary_warning_triggered = true
	_boundary_cooldown = 30.0

	print("[Fragment0001] 边界光墙触碰 — 玩家位置: (%d, %d)" % [int(pos.x), int(pos.y)])

	_show_message(
		"边界警告",
		"你触碰到了训练场的边缘。光墙在你指尖泛起涟漪——不是阻拦，是提醒。前方不在本次训练范围之内。",
		5.5
	)

	_modify_compliance(-2, "触碰训练场边界")
