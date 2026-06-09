extends Node2D
## fragment_0001 场景脚本 — 玩家实例化 + 深度层切换 + 日晷交互 + 线索系统 + Tab面板
## E 键交互日晷 → 线索写入 ClueSystem → Tab 面板查看 → 钟楼校准 → 源印显现

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const ClueSystemScript = preload("res://scripts/systems/clue_system.gd")
const SourceMarkScript = preload("res://scripts/buildings/source_mark.gd")

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

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("fragment_state")
	_create_clue_system()
	_cache_depth_layers()
	_spawn_player()
	_setup_interact_hint()
	_setup_collection_panel()
	_setup_message_panel()
	_setup_angle_panel()
	_prepare_fragment_context()
	_show_opening_message()
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


func _process(_delta: float) -> void:
	_update_player_z()
	_update_player_depth_layer()


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
		spawn_marker = spawn_points.get_node_or_null("Default") as Marker2D

	var spawn_pos: Vector2 = Vector2(644, 655)
	if spawn_marker:
		spawn_pos = spawn_marker.global_position
		print("[Fragment0001] 使用 SpawnPoints/Default 位置: %s" % str(spawn_pos))
	else:
		print("[Fragment0001] 未找到 Default 出生点，使用默认位置")

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


# ============================================================
# E 键 : 钟楼交互回调（由 BellTower.interact() → PlayerController 调用）
# ============================================================

func on_bell_tower_interact(bell_tower: Node2D) -> void:
	## 钟楼 E 键交互处理入口
	if source_mark_revealed:
		_show_message("钟楼暗门", "暗门已经打开。晨曦之印在暗室石台上发出淡金色光。", 3.5)
		return

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
		_close_angle_panel()
		_reveal_source_mark()
		return true

	if abs(clock_angle - TARGET_CLOCK_ANGLE) <= 6:
		_modify_compliance(-4, "校准接近但未通过")
		_show_message("钟楼观测台", "指针发出橙色回光。很接近，但还不是正确的缺失角度。", 3.5)
	else:
		_modify_compliance(-8, "错误校准")
		_show_message("钟楼观测台", "齿轮轻响一声后回弹。系统提示：训练误差已记录。", 3.5)
	return false


func _close_angle_panel() -> void:
	if _angle_bg:
		_angle_bg.visible = false
	if _angle_panel:
		_angle_panel.visible = false


# ============================================================
# 源印显现与通关
# ============================================================

func _reveal_source_mark() -> void:
	if source_mark_revealed:
		return
	source_mark_revealed = true

	_clue_system.locate_source_mark("晨曦之印", "钟楼底层暗室")

	_show_message(
		"钟楼暗室",
		"66°。指针落下，钟楼下方传来齿轮咬合声。\n暗门打开，石台上显出一枚铜色日晷徽章：晨曦之印。",
		6.0
	)

	print("[Fragment0001] 源印显现：晨曦之印")

	# 延迟创建源印可交互点（模拟暗室显现）
	await get_tree().create_timer(2.0).timeout
	_create_source_mark_interaction()
	_update_clue_list()


func _create_source_mark_interaction() -> void:
	# 查找钟楼节点位置
	var bell_tower = _find_bell_tower_node()
	var pos := Vector2(637, 672)  # 默认出生点附近
	if bell_tower:
		pos = bell_tower.global_position + Vector2(0, 80)

	# 创建源印交互区域（使用 SourceMark 脚本 + Area2D）
	var mark_root = Node2D.new()
	mark_root.name = "SourceMarkDawn"
	mark_root.position = pos
	mark_root.z_index = 0
	mark_root.add_to_group("interactable")
	mark_root.set_script(SourceMarkScript)
	add_child(mark_root)

	var area = Area2D.new()
	area.name = "InteractableArea"
	area.collision_layer = 2
	area.collision_mask = 0
	mark_root.add_child(area)

	var shape_node = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 50.0
	shape_node.shape = circle
	area.add_child(shape_node)

	# 发光视觉
	var glow = ColorRect.new()
	glow.name = "Glow"
	glow.position = Vector2(-30, -30)
	glow.size = Vector2(60, 60)
	glow.color = Color(1.0, 0.72, 0.24, 0.72)
	mark_root.add_child(glow)

	var label = Label.new()
	label.name = "Label"
	label.position = Vector2(-70, 34)
	label.size = Vector2(140, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "晨曦之印"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.30, 0.18, 0.04, 1.0))
	label.z_index = 1
	mark_root.add_child(label)

	print("[Fragment0001] 源印交互点已创建于 %s" % str(pos))


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


func _complete_fragment() -> void:
	if completed:
		return
	completed = true

	_clue_system.decode_source_mark("晨曦之印", "晨曦镇训练场完成校准，钟楼暗室已开启。")
	GameManager.record_source_mark("0001", "晨曦之印", "钟楼暗室便笺：所有答案都可能被修改过。")

	var fragment = FragmentManager.current_fragment
	if fragment == null:
		fragment = FragmentManager.get_fragment_by_id("0001")
	FragmentManager.complete_fragment(fragment)
	SaveManager.save_game()

	_show_message(
		"晨曦之印",
		"源印归位。星图已更新。\n碎片 #0001「启程之镇」— 完成。",
		4.0
	)

	print("[Fragment0001] 碎片完成！")
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


# ============================================================
# 合规度系统
# ============================================================

func _modify_compliance(delta: int, reason: String) -> void:
	compliance = clampi(compliance + delta, 0, 100)
	var sign = "+" if delta >= 0 else ""
	print("[Fragment0001] 合规度 %s%d -> %d | %s" % [sign, delta, compliance, reason])
	if compliance <= 20:
		_show_message(
			"系统提示",
			"合规度进入限制区。正式版本可在这里接入权限锁定、强制回训或公司监控反馈。",
			4.0
		)


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
