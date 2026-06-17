extends Node2D
## fragment_0001 场景脚本 — 玩家实例化 + 深度层切换 + 日晷交互 + 线索系统 + Tab面板
## E 键交互日晷 → 线索写入 ClueSystem → Tab 面板查看 → 钟楼校准 → 源印显现

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")
const ClueSystemScript = preload("res://scripts/systems/clue_system.gd")
const CLUE_PANEL_SCENE: PackedScene = preload("res://scenes/ui/CluePanel.tscn")
const BGM_FRAGMENT_0001 = preload("res://assets/audio/bgm/bgm_fragment_0001_loop.ogg")
const LIN_NOTE_TEXTURE: Texture2D = preload("res://assets/papercraft/fragments/id0001/environment2/LinNote.png")
const LIN_NOTE_SCRIPT: Script = preload("res://scripts/fragment/lin_note_interactable.gd")
const TV_SCENE: PackedScene = preload("res://scenes/buildings/id0001/TV.tscn")
const TV_VIDEO_STREAM: VideoStream = preload("res://assets/papercraft/fragments/id0001/environment2/ad.ogv")
const STONE_TEXTURE: Texture2D = preload("res://assets/papercraft/fragments/id0001/environment2/stone_tablet.png")
const SFX_SOURCE_MARK_REVEAL := preload("res://assets/audio/ui/ui_source_mark_reveal.wav")

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
const LIN_INTERMISSION_DIALOGUE := "\"17个。这17个月——我在镇子里送了17批人。\"\n" + \
	"\"只有3个人走到过边界墙。\"\n" + \
	"\"你知道边界那边是什么吗？我不知道。\"\n" + \
	"\"但赵安保知道——他从来不说。\"\n" + \
	"\"别告诉任何人我说了这些。\"\n" + \
	"\"因为这些话——不在培训脚本里。\"\n" + \
	"（通讯器发出一声刺耳的杂音。）\n" + \
	"\"哦。时间到了。\""

## 玩家引用
var _player: CharacterBody2D = null
var _current_layer: int = 0
var _depth_layers: Dictionary = {}

## BGM 播放
var _bgm_player: AudioStreamPlayer = null

## SFX 音效播放器（SFX 总线，用于 UI/谜题反馈音效）
var _sfx_player: AudioStreamPlayer = null

## 日晷状态
var observed_sundials: Dictionary = {}
var compliance: int = 100
var clock_angle: int = 12
var source_mark_revealed: bool = false
var completed: bool = false

## 线索系统
var _clue_system: Node = null

## UI @onready 引用（节点预置于 fragment_0001.tscn 的 UIRoot 下）
@onready var _ui_root: CanvasLayer = $UIRoot
@onready var _interact_hint_label: Label = $UIRoot/InteractHint
@onready var _message_panel_bg: ColorRect = $UIRoot/MessagePanelBg
@onready var _message_panel: Panel = $UIRoot/MessagePanel
@onready var _message_title: Label = $UIRoot/MessagePanel/MessageTitle
@onready var _message_body: Label = $UIRoot/MessagePanel/MessageBody
@onready var _angle_bg: ColorRect = $UIRoot/CalibrationBg
@onready var _angle_panel: Panel = $UIRoot/CalibrationPanel
@onready var _angle_value: Label = $UIRoot/CalibrationPanel/AngleValue
@onready var _calibration_minus_btn: Button = $UIRoot/CalibrationPanel/MinusBtn
@onready var _calibration_plus_btn: Button = $UIRoot/CalibrationPanel/PlusBtn
@onready var _calibration_submit_btn: Button = $UIRoot/CalibrationPanel/SubmitBtn
@onready var _calibration_close_btn: Button = $UIRoot/CalibrationPanel/CloseBtn
@onready var _compliance_bar_bg: ColorRect = $UIRoot/ComplianceBarContainer/ComplianceBarBg
@onready var _compliance_bar_fill: ColorRect = $UIRoot/ComplianceBarContainer/ComplianceBarBg/ComplianceBarFill
@onready var _compliance_label: Label = $UIRoot/ComplianceBarContainer/ComplianceLabel
@onready var _compliance_value_label: Label = $UIRoot/ComplianceBarContainer/ComplianceValueLabel
@onready var _compliance_warning_icon: Label = $UIRoot/ComplianceBarContainer/ComplianceWarningIcon

var _message_timer = null
var _compliance_pulse_tween: Tween = null
var _clue_panel: CluePanel = null

## 林指导幕间事件追踪
var _player_idle_time: float = 0.0
var _intermission_triggered: bool = false
var _lin_intermission_playing: bool = false
var _lin_note_unlocked: bool = false
@export_range(0, 1, 1) var lin_note_collected: int = 0
var _lin_note_sprite: Sprite2D = null
var _lin_note_viewer: Control = null
var _lin_note_close_block_until_msec: int = 0
@export_range(0, 1, 1) var tv_collected: int = 0
var _tv_node: Node2D = null
var _tv_viewer: Control = null
var _tv_viewer_tv: Node2D = null
var _tv_close_block_until_msec: int = 0
@export_range(0, 1, 1) var stone_collected: int = 0
var _stone_node: Node2D = null
var _stone_viewer: Control = null
var _stone_close_block_until_msec: int = 0

## 边界光墙触碰追踪
var _boundary_warning_triggered: bool = false
var _boundary_cooldown: float = 0.0

## 合规度归零一次性标记（防重复创建 timer）
var _compliance_zero_triggered: bool = false

## L6 强制回归一次性标记（合规度 < 25% 触发）
var _compliance_l6_triggered: bool = false

## 边界光墙多级触碰计数
var _boundary_touch_count: int = 0

## 日晷E 首次接近标记
var _sundial_e_proximity_triggered: bool = false

## LayerMarker 引用（透明度控制）
var _layer_marker_1_2: Marker2D = null
var _layer_marker_2_3: Marker2D = null

# ============================================================
# 初始化
# ============================================================

func _enter_tree() -> void:
	add_to_group("fragment_state")


func _ready() -> void:
	_create_clue_system()
	_cache_depth_layers()
	_spawn_player()
	_configure_ui_theme()       # 对预置节点应用字体/颜色/信号连接
	_ensure_clue_panel()
	_prepare_fragment_context()
	# 恢复之前的探索进度（从暗室返回等情况）
	_try_restore_state()
	_show_opening_message()
	# 从暗室等场景返回时 SceneFader 处于黑屏状态，需要淡入
	SceneFader.fade_in()
	# 连接光墙 InteractionArea 信号 + 缓存 LayerMarker
	_connect_light_wall_signals()
	_cache_layer_markers()
	# 播放碎片探索 BGM（循环版本，淡入淡出处理）
	_start_bgm()
	if TutorialManager and TutorialManager.has_method("start_fragment_0001"):
		TutorialManager.start_fragment_0001()
	print("[Fragment0001] 启程之镇就绪 — E键观测日晷 | Tab键查看线索")


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id("0001")
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _create_clue_system() -> void:
	_clue_system = ClueSystemScript.new()
	_clue_system.name = "ClueSystem0001"
	add_child(_clue_system)
	if _clue_system.has_signal("clue_discovered") and not _clue_system.clue_discovered.is_connected(_on_clue_discovered):
		_clue_system.clue_discovered.connect(_on_clue_discovered)
	print("[Fragment0001] ClueSystem 已创建")


func _ensure_clue_panel() -> void:
	if is_instance_valid(_clue_panel):
		return
	_clue_panel = CLUE_PANEL_SCENE.instantiate() as CluePanel
	_clue_panel.name = "CluePanel"
	_clue_panel.visible = false
	_ui_root.add_child(_clue_panel)


func _show_opening_message() -> void:
	_show_message(
		"林指导",
		"溯光者，编号确认通过。欢迎来到溯光计划第一阶段训练场。\n先观察五个日晷，记录阴影角度，再回钟楼校准指针。",
		6.0
	)


# ============================================================
# 光墙 InteractionArea 信号连接 — 触碰光墙扣合规度
# ============================================================

## 缓存所有光墙 InteractionArea（用于碰撞检测）
var _light_wall_areas: Array[Area2D] = []

func _connect_light_wall_signals() -> void:
	"""查找所有 LightWall 节点的 InteractionArea 并缓存"""
	var world_root := get_node_or_null("WorldRoot")
	if not world_root:
		return
	var light_walls: Array[Node] = world_root.find_children("LightWall*", "Node2D", true, false)
	for wall in light_walls:
		var ia := wall.get_node_or_null("InteractionArea") as Area2D
		if ia:
			_light_wall_areas.append(ia)
	print("[Fragment0001] 已缓存 %d 个光墙 InteractionArea" % _light_wall_areas.size())


func _is_inside_light_wall() -> bool:
	"""检查玩家是否与任何光墙 InteractionArea 重叠"""
	if not _player:
		return false
	for ia in _light_wall_areas:
		if not is_instance_valid(ia):
			continue
		if ia.overlaps_body(_player):
			return true
	return false


# ============================================================
# LayerMarker 透明度控制
# ============================================================

func _cache_layer_markers() -> void:
	"""缓存 LayerMarker 节点下的两个 Marker2D"""
	var layer_marker := get_node_or_null("WorldRoot/LayerMarker")
	if not layer_marker:
		printerr("[Fragment0001] 未找到 WorldRoot/LayerMarker 节点")
		return
	_layer_marker_1_2 = layer_marker.get_node_or_null("Layer1_2") as Marker2D
	_layer_marker_2_3 = layer_marker.get_node_or_null("Layer2_3") as Marker2D
	if not _layer_marker_1_2 or not _layer_marker_2_3:
		printerr("[Fragment0001] LayerMarker 子节点缺失")


func _update_layer_transparency() -> void:
	"""根据玩家 Y 与 LayerMarker 的位置关系，调整深度层透明度"""
	if not _player or not _layer_marker_1_2 or not _layer_marker_2_3:
		return

	var player_y: float = _player.global_position.y
	const TARGET_ALPHA: float = 0.35
	const TRANSITION_SPEED: float = 4.0

	# DepthLayer_1: 玩家 Y 小于 Layer1_2 时降低透明度（玩家在近景层前方/上方）
	var dl1 := _depth_layers.get(1) as CanvasItem
	if dl1:
		var behind_1: bool = player_y < _layer_marker_1_2.global_position.y
		var target_a: float = TARGET_ALPHA if behind_1 else 1.0
		dl1.modulate.a = move_toward(dl1.modulate.a, target_a, TRANSITION_SPEED * get_process_delta_time())

	# DepthLayer_2: 玩家 Y 小于 Layer2_3 时降低透明度
	var dl2 := _depth_layers.get(2) as CanvasItem
	if dl2:
		var behind_2: bool = player_y < _layer_marker_2_3.global_position.y
		var target_a: float = TARGET_ALPHA if behind_2 else 1.0
		dl2.modulate.a = move_toward(dl2.modulate.a, target_a, TRANSITION_SPEED * get_process_delta_time())

	# 补偿玩家透明度：player 是深度层的子节点，层透明度会影响 player，
	# 需要反向补偿让 player 始终保持不透明
	if _player:
		var parent_node := _player.get_parent()
		if parent_node and parent_node is CanvasItem:
			var parent_modulate := (parent_node as CanvasItem).modulate
			if parent_modulate.a < 0.999:
				_player.modulate.a = 1.0 / max(parent_modulate.a, 0.01)
			else:
				_player.modulate.a = 1.0


func _process(delta: float) -> void:
	_update_player_z()
	_update_player_depth_layer()
	_check_boundary(delta)
	_check_sundial_e_proximity(delta)
	_update_layer_transparency()


# ============================================================
# UIRoot 初始化（所有新增UI统一挂载点）
# ============================================================

func _configure_ui_theme() -> void:
	"""连接 .tscn 预置 UI 节点的信号（样式在编辑器中直接设置）"""
	# --- 交互提示信号 ---
	if _player and _player.has_signal("interact_hint_changed"):
		if not _player.interact_hint_changed.is_connected(_on_interact_hint_changed):
			_player.interact_hint_changed.connect(_on_interact_hint_changed)

	# --- 校准面板按钮信号 ---
	_connect_button_pressed(_calibration_minus_btn, _on_clock_minus_pressed, "UIRoot/CalibrationPanel/MinusBtn")
	_connect_button_pressed(_calibration_plus_btn, _on_clock_plus_pressed, "UIRoot/CalibrationPanel/PlusBtn")
	_connect_button_pressed(_calibration_submit_btn, _submit_clock_angle, "UIRoot/CalibrationPanel/SubmitBtn")
	_connect_button_pressed(_calibration_close_btn, _close_angle_panel, "UIRoot/CalibrationPanel/CloseBtn")

	print("[Fragment0001] UI 信号连接完成")


# ============================================================
# 玩家管理
# ============================================================

func _connect_button_pressed(button: Button, callback: Callable, node_path: String) -> bool:
	if button == null:
		push_error("[Fragment0001] Missing Button node: %s" % node_path)
		return false
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if not button.pressed.is_connected(UISoundManager.play_click):
		button.pressed.connect(UISoundManager.play_click)
	return true


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
		extra = "\n这个日晷被砸碎了。碎片被整齐排列——或许缺失的角度可以从其他数据推导。"
	elif observed_sundials.size() == 2:
		extra = "\n陈技术的终端亮了一下：阴影角度之间存在稳定间隔。"
	elif observed_sundials.size() == 4:
		extra = "\n林指导放低声音：第五个，不是用眼睛。五组数据，找规律不难。"

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
		# #2 首次观测日晷后 — 日志提示
		await get_tree().create_timer(2.0).timeout
		if observed_sundials.size() >= 1:
			_show_message(
				"观测记录",
				"观测数据已记录。日志可在Tab面板查看。",
				3.0
			)
	elif obs_count == 3:
		# #3 观测到 3/5 日晷时 — 规律提示
		await get_tree().create_timer(2.0).timeout
		if observed_sundials.size() >= 3:
			_show_message(
				"系统",
				"数据之间的间隔似乎有规律。",
				3.0
			)
	elif obs_count == 5:
		# #4 收集全部4个可观测日晷后 — 返回钟楼提示
		await get_tree().create_timer(2.0).timeout
		if observed_sundials.size() >= 5:
			_show_message(
				"系统",
				"所有观测数据已收集。请返回钟楼。",
				4.0
			)


# ============================================================
# E 键 : 钟楼交互回调（由 BellTower.interact() → PlayerController 调用）
# ============================================================

func on_bell_tower_interact(bell_tower: Node2D) -> void:
	## 钟楼 E 键交互处理入口（仅在门锁定时调用）
	_resolve_ui_refs()
	if observed_sundials.size() < 5:
		_show_message(
			"钟楼观测台",
			"观测台被锁定。需要五个日晷数据，包含第五个残晷的推断角度。\n已记录：%d/5" % observed_sundials.size(),
			4.0
		)
		return

	# 打开校准面板
	if _angle_bg:
		_angle_bg.visible = true
	if _angle_panel:
		_angle_panel.visible = true
		_set_player_controls_locked(true)
	else:
		push_warning("[Fragment0001] 缺少 UIRoot/CalibrationPanel，无法打开校准面板")
		return
	_update_angle_value()
	print("[Fragment0001] 钟楼校准面板已打开")


## E 键 : 源印交互回调（由 SourceMark.interact() → PlayerController 调用）
func on_source_mark_interact() -> void:
	if TutorialManager and TutorialManager.has_method("mark_interaction"):
		TutorialManager.mark_interaction("source_mark", "0001")
	_complete_fragment()


# ============================================================
# 日晷校准面板
# ============================================================

func _on_clock_minus_pressed() -> void:
	clock_angle = wrapi(clock_angle - 6, 0, 360)
	_persist_clock_angle()
	_update_angle_value()


func _on_clock_plus_pressed() -> void:
	clock_angle = wrapi(clock_angle + 6, 0, 360)
	_persist_clock_angle()
	_update_angle_value()


func _persist_clock_angle() -> void:
	FragmentManager.set_fragment_state("0001", "clock_angle", clock_angle)


func _update_angle_value() -> void:
	_resolve_ui_refs()
	if _angle_value:
		_angle_value.text = "%d°" % clock_angle


func _submit_clock_angle() -> bool:
	_persist_clock_angle()
	if clock_angle == TARGET_CLOCK_ANGLE:
		# 正确校准 — 金色光扩散效果
		var bell_pos: Vector2 = _get_bell_tower_position()
		_create_light_spread_effect(bell_pos, Color(1.0, 0.72, 0.24, 0.9), 1.5)
		_play_sfx(SFX_SOURCE_MARK_REVEAL)
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


func _set_player_controls_locked(locked: bool) -> void:
	if _player and _player.has_method("set_controls_locked"):
		_player.set_controls_locked(locked)


func _close_angle_panel() -> void:
	_resolve_ui_refs()
	if _angle_bg:
		_angle_bg.visible = false
	if _angle_panel:
		_angle_panel.visible = false
	_set_player_controls_locked(false)


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
	save_state()

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
	FragmentManager.set_fragment_state("0001", "clock_angle", clock_angle)
	FragmentManager.set_fragment_state("0001", "source_mark_revealed", source_mark_revealed)
	FragmentManager.set_fragment_state("0001", "completed", completed)
	FragmentManager.set_fragment_state("0001", "discovered_clues", clues_data)
	FragmentManager.set_fragment_state("0001", "boundary_touch_count", _boundary_touch_count)
	FragmentManager.set_fragment_state("0001", "intermission_triggered", _intermission_triggered)
	FragmentManager.set_fragment_state("0001", "lin_note_unlocked", _lin_note_unlocked)
	FragmentManager.set_fragment_state("0001", "lin_note_collected", lin_note_collected)
	FragmentManager.set_fragment_state("0001", "tv_collected", tv_collected)
	FragmentManager.set_fragment_state("0001", "stone_collected", stone_collected)
	FragmentManager.set_fragment_state("0001", "sundial_e_proximity_triggered", _sundial_e_proximity_triggered)
	print("[Fragment0001] 探索进度已保存 — 日晷(%d/5) 合规度(%d) 源印(%s)" % [observed_sundials.size(), compliance, source_mark_revealed])


func _on_clue_discovered(_clue: Dictionary) -> void:
	## 线索发现后立即同步到 FragmentManager，确保下一次自动/手动存档能拿到最新线索。
	save_state()
	_update_clue_list()


# ============================================================
# memory_stage 映射（供 NPC RAG 系统调用）
# ============================================================

func get_memory_stage() -> String:
	## 根据当前游戏进度返回 RAG memory_stage
	## 阶段递进: initial(探索) → crack_showing(裂缝显现) → script_reset(幕间)
	if _intermission_triggered:
		return "script_reset"
	if observed_sundials.size() >= 2:
		return "crack_showing"
	return "initial"


func get_game_state(npc_id: String = "") -> Dictionary:
	## 供 npc_controller 调用，返回 RAG 检索所需的游戏状态
	var stage = get_memory_stage()
	return {
		"memory_stage": stage,
		"alert_level": 0,
		"trust_level": 0,
		"awakened_colors": [],
		"awakened_count": 0
	}


func uses_compliance_mode() -> bool:
	## 碎片 #0001 使用 MONITORED 合规度模式，不接入通用 NPC 警觉度。
	return true


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
	var saved_clock_angle = FragmentManager.get_fragment_state("0001", "clock_angle")
	if typeof(saved_clock_angle) == TYPE_INT:
		clock_angle = saved_clock_angle

	var saved_revealed = FragmentManager.get_fragment_state("0001", "source_mark_revealed")
	if typeof(saved_revealed) == TYPE_BOOL:
		source_mark_revealed = saved_revealed
	if source_mark_revealed:
		call_deferred("_sync_bell_tower_unlock_state")
	var saved_completed = FragmentManager.get_fragment_state("0001", "completed")
	if typeof(saved_completed) == TYPE_BOOL:
		completed = saved_completed

	# 恢复线索系统
	var saved_clues = FragmentManager.get_fragment_state("0001", "discovered_clues")
	if saved_clues is Array and not saved_clues.is_empty():
		_clue_system.discovered_clues.clear()
		for entry in saved_clues:
			if entry is Dictionary:
				_clue_system.discovered_clues.append(entry.duplicate(true))
		_update_clue_list()

	# 恢复合规度条
	if _compliance_bar_fill:
		_update_compliance_bar()

	# 恢复新增状态
	var saved_boundary = FragmentManager.get_fragment_state("0001", "boundary_touch_count")
	if typeof(saved_boundary) == TYPE_INT:
		_boundary_touch_count = saved_boundary
	var saved_intermission = FragmentManager.get_fragment_state("0001", "intermission_triggered")
	if typeof(saved_intermission) == TYPE_BOOL:
		_intermission_triggered = saved_intermission
	var saved_lin_note = FragmentManager.get_fragment_state("0001", "lin_note_unlocked")
	if typeof(saved_lin_note) == TYPE_BOOL:
		_lin_note_unlocked = saved_lin_note
	if _lin_note_unlocked:
		call_deferred("_spawn_lin_note")
	var saved_lin_note_collected = FragmentManager.get_fragment_state("0001", "lin_note_collected")
	if typeof(saved_lin_note_collected) == TYPE_INT:
		lin_note_collected = clampi(saved_lin_note_collected, 0, 1)
	elif typeof(saved_lin_note_collected) == TYPE_BOOL:
		lin_note_collected = 1 if saved_lin_note_collected else 0
	var saved_tv_collected = FragmentManager.get_fragment_state("0001", "tv_collected")
	if typeof(saved_tv_collected) == TYPE_INT:
		tv_collected = clampi(saved_tv_collected, 0, 1)
	elif typeof(saved_tv_collected) == TYPE_BOOL:
		tv_collected = 1 if saved_tv_collected else 0
	call_deferred("_refresh_tv_collection_state")
	var saved_stone_collected = FragmentManager.get_fragment_state("0001", "stone_collected")
	if typeof(saved_stone_collected) == TYPE_INT:
		stone_collected = clampi(saved_stone_collected, 0, 1)
	elif typeof(saved_stone_collected) == TYPE_BOOL:
		stone_collected = 1 if saved_stone_collected else 0
	call_deferred("_refresh_stone_collection_state")
	var saved_e_proximity = FragmentManager.get_fragment_state("0001", "sundial_e_proximity_triggered")
	if typeof(saved_e_proximity) == TYPE_BOOL:
		_sundial_e_proximity_triggered = saved_e_proximity

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

func _sync_bell_tower_unlock_state() -> void:
	var bell_tower = _find_bell_tower_node()
	if bell_tower and bell_tower.has_method("unlock_door"):
		bell_tower.unlock_door()


func _complete_fragment() -> void:
	if completed:
		return
	completed = true

	# 1. 标记源印与碎片完成
	_clue_system.decode_source_mark("晨曦之印", "晨曦镇训练场完成校准，钟楼暗室已开启。")
	GameManager.record_source_mark("0001", "晨曦之印", "钟楼暗室便笺：所有答案都可能被修改过。")

	var fragment = FragmentManager.current_fragment
	if fragment == null:
		fragment = FragmentManager.get_fragment_by_id("0001")
	FragmentManager.complete_fragment(fragment)
	save_state()

	# 2. 自动保存：必须在源印线索和碎片完成状态写入之后执行
	SaveManager.save_game()

	print("[Fragment0001] 碎片完成！显示胜利画面")

	# 3. 创建胜利画面面板（UIRoot 已在 .tscn 中预置）
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
	return_btn.pressed.connect(UISoundManager.play_click)
	button_row.add_child(return_btn)

	var continue_btn: Button = Button.new()
	continue_btn.name = "ContinueBtn"
	continue_btn.text = "继续游玩"
	continue_btn.size = Vector2(180, 44)
	continue_btn.add_theme_font_size_override("font_size", 16)
	continue_btn.pressed.connect(_on_continue_playing)
	continue_btn.pressed.connect(UISoundManager.play_click)
	button_row.add_child(continue_btn)

	# 4. 面板淡入动画（0 → 1 alpha，Tween 0.4s）
	victory_panel.modulate = Color(1, 1, 1, 0)
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(victory_panel, "modulate:a", 1.0, 0.4)


func _on_return_to_star_map() -> void:
	"""胜利画面 [返回星图] 按钮回调"""
	print("[Fragment0001] 玩家选择返回星图")
	_stop_bgm()
	SceneManager.change_scene("res://scenes/star_map.tscn")


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
	if delta < 0:
		_show_compliance_penalty(delta, reason)
	save_state()

	# L6 强制回归：合规度 < 25%（仅触发一次）
	if compliance < 25 and not _compliance_l6_triggered:
		_compliance_l6_triggered = true
		_trigger_l6_forced_return()
		return

	# #8 合规度降至 70% 以下（L3 警告区）
	if compliance <= 70 and compliance >= 55:
		# 仅在首次进入 L3 区间时弹一次消息
		if not _compliance_zero_triggered and compliance > 54:
			_show_message(
				"⚠ 系统提示",
				"您的训练行为正受到关注。请保持在指定活动区域内。",
				4.0
			)

	# #9 合规度降至 40% 以下（L4 限制 / L5 封锁）
	if compliance <= 40 and compliance >= 25:
		_show_message(
			"⛔ 系统警告",
			"最终警告：您的训练权限即将受限。",
			4.0
		)

	# 合规度归零备选（理论上由 L6 在 <25% 接管）
	if compliance <= 0 and not _compliance_zero_triggered:
		_compliance_zero_triggered = true
		_show_message(
			"系统协议",
			"合规度归零。系统启动强制回归协议。",
			3.0
		)
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func() -> void:
			_stop_bgm()
			SceneManager.change_scene("res://scenes/star_map.tscn")
		)


func _show_compliance_penalty(delta: int, reason: String) -> void:
	_resolve_ui_refs()
	if _ui_root == null:
		return

	for child in _ui_root.get_children():
		if child is Control and child.has_meta("compliance_penalty_popup"):
			child.queue_free()

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0:
		viewport_size = Vector2(1280, 720)

	var popup := Panel.new()
	popup.name = "CompliancePenaltyPopup"
	popup.set_meta("compliance_penalty_popup", true)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.size = Vector2(340, 86)
	popup.position = Vector2(viewport_size.x - 370, 86)
	popup.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.55, 0.07, 0.06, 0.92)
	style.border_color = Color(1.0, 0.78, 0.35, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(6)
	popup.add_theme_stylebox_override("panel", style)
	_ui_root.add_child(popup)

	var title := Label.new()
	title.position = Vector2(14, 10)
	title.size = Vector2(312, 26)
	title.text = "合规度扣除 %d%%" % abs(delta)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	popup.add_child(title)

	var detail := Label.new()
	detail.position = Vector2(14, 42)
	detail.size = Vector2(312, 34)
	detail.text = "%s\n当前合规度：%d%%" % [reason, compliance]
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.86))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup.add_child(detail)

	if _compliance_bar_fill:
		var original_color := _compliance_bar_fill.color
		var flash_tween := create_tween()
		flash_tween.tween_property(_compliance_bar_fill, "color", Color(1.0, 0.2, 0.12, 1.0), 0.08)
		flash_tween.tween_property(_compliance_bar_fill, "color", original_color, 0.22)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:x", viewport_size.x - 360, 0.18).from(viewport_size.x + 20)
	tween.tween_property(popup, "modulate:a", 1.0, 0.12)

	var exit_tween := create_tween()
	exit_tween.tween_interval(2.8)
	exit_tween.tween_property(popup, "modulate:a", 0.0, 0.35)
	exit_tween.tween_callback(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)


# ============================================================
# P1：合规度完整UI联动
# ============================================================

func _update_compliance_bar() -> void:
	"""更新合规度条的颜色、宽度、图标和数值（对齐UX L1-L6等级）"""
	_resolve_ui_refs()
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

	# L1 良好 100-85% — 蓝色 #4A90D9
	# L2 注意   84-70% — 蓝色（与L1相同色，无额外警告图标）
	# L3 警告   69-55% — 琥珀色 + ⚠
	# L4 限制   54-40% — 琥珀色 + ⚠ 闪烁
	# L5 封锁   39-25% — 红色脉冲 + ⛔
	# L6 强制  <25%     — 全屏红色边框（在 _trigger_l6_forced_return 中处理）

	if compliance >= 70:
		# L1/L2: 蓝色 #4A90D9
		_compliance_bar_fill.color = Color(0.29, 0.565, 0.851, 1.0)  # #4A90D9
		if _compliance_warning_icon:
			_compliance_warning_icon.text = ""
	elif compliance >= 55:
		# L3: 琥珀色 #E8A838 + ⚠
		_compliance_bar_fill.color = Color(0.91, 0.66, 0.22, 1.0)  # #E8A838
		if _compliance_warning_icon:
			_compliance_warning_icon.text = "⚠"
	elif compliance >= 40:
		# L4: 琥珀色 + ⚠ 闪烁（通过透明度脉冲实现）
		_compliance_bar_fill.color = Color(0.91, 0.66, 0.22, 1.0)  # #E8A838
		if _compliance_warning_icon:
			_compliance_warning_icon.text = "⚠"
		# ⚠ 闪烁动画
		if _compliance_warning_icon:
			_compliance_pulse_tween = create_tween()
			_compliance_pulse_tween.set_loops()
			_compliance_pulse_tween.tween_property(_compliance_warning_icon, "modulate:a", 0.25, 0.5)
			_compliance_pulse_tween.tween_property(_compliance_warning_icon, "modulate:a", 1.0, 0.5)
	else:
		# L5: 红色 #D94A4A 脉冲 + ⛔
		_compliance_bar_fill.color = Color(0.851, 0.29, 0.29, 1.0)  # #D94A4A
		if _compliance_warning_icon:
			_compliance_warning_icon.text = "⛔"
		# 红色脉冲动画
		_compliance_pulse_tween = create_tween()
		_compliance_pulse_tween.set_loops()
		_compliance_pulse_tween.tween_property(_compliance_bar_fill, "modulate:a", 0.3, 0.6)
		_compliance_pulse_tween.tween_property(_compliance_bar_fill, "modulate:a", 1.0, 0.6)


func _trigger_l6_forced_return() -> void:
	"""L6 强制回归事件 — 全屏红色脉冲 → 黑屏 → 重生广场 → 合规度重置 85%"""
	print("[Fragment0001] L6 强制回归触发 — 合规度 %d%%" % compliance)

	# 阶段1：全屏红色边框脉冲 (0.3s 循环)
	var red_border: ColorRect = ColorRect.new()
	red_border.name = "L6RedBorder"
	red_border.color = Color(0.85, 0.1, 0.1, 0.0)
	red_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	red_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(red_border)

	var warning_label: Label = Label.new()
	warning_label.name = "L6WarningText"
	warning_label.text = "⚠ 训练行为偏离标准轨道"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 20)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	warning_label.set_anchors_preset(Control.PRESET_CENTER)
	warning_label.size = Vector2(500, 40)
	_ui_root.add_child(warning_label)

	# 红色边框脉冲动画
	var pulse_tween := create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(red_border, "modulate:a", 0.5, 0.3)
	pulse_tween.tween_property(red_border, "modulate:a", 0.15, 0.3)

	# 阶段2：1.5s 后画面从边缘向中心淡出（黑色）
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(pulse_tween):
		pulse_tween.kill()

	# 创建黑屏遮罩
	var dark_overlay: ColorRect = ColorRect.new()
	dark_overlay.name = "L6DarkOverlay"
	dark_overlay.color = Color(0, 0, 0, 0.0)
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(dark_overlay)

	var fade_tween := create_tween()
	fade_tween.tween_property(dark_overlay, "color:a", 1.0, 1.0)

	# 阶段3：黑屏中间文字停留 2s
	await fade_tween.finished
	if is_instance_valid(red_border):
		red_border.queue_free()
	if is_instance_valid(warning_label):
		warning_label.queue_free()

	var center_text: Label = Label.new()
	center_text.name = "L6CenterText"
	center_text.text = "您的训练行为已偏离标准轨道。\n我们需要重新开始。"
	center_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_text.add_theme_font_size_override("font_size", 20)
	center_text.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
	center_text.set_anchors_preset(Control.PRESET_CENTER)
	center_text.size = Vector2(500, 80)
	dark_overlay.add_child(center_text)

	await get_tree().create_timer(2.0).timeout

	# 阶段4：重置合规度 + 移动玩家到广场中央
	compliance = 85
	_compliance_l6_triggered = false  # 允许再次触发
	_update_compliance_bar()
	save_state()

	if _player:
		# 移动到默认出生点位置
		var default_spawn: Marker2D = null
		var spawn_points = get_node_or_null("WorldRoot/SpawnPoints")
		if spawn_points:
			default_spawn = spawn_points.get_node_or_null("Default") as Marker2D
		if default_spawn:
			_player.global_position = default_spawn.global_position
			# 同步深度层
			var target_layer = _get_layer_by_y(_player.global_position.y)
			if target_layer != _current_layer:
				var layer_node = _depth_layers.get(target_layer) as Node2D
				if layer_node:
					var saved_pos = _player.global_position
					_player.reparent(layer_node)
					_player.global_position = saved_pos
					_current_layer = target_layer

	# 淡入
	fade_tween = create_tween()
	fade_tween.tween_property(dark_overlay, "color:a", 0.0, 0.5)
	await fade_tween.finished

	if is_instance_valid(dark_overlay):
		dark_overlay.queue_free()

	# 阶段5：林指导消息弹窗
	_show_message(
		"林指导",
		"请跟好我。我们重新来过。",
		5.0
	)

	print("[Fragment0001] L6 强制回归完成 — 合规度重置为 85%%，进度保留")


func _count_observed() -> int:
	var count := 0
	for id in ["A", "B", "C", "D"]:
		if observed_sundials.has(id):
			count += 1
	return count


# ============================================================
# 交互提示（底部居中“按 E 观察 xxx”）
# ============================================================

func _on_interact_hint_changed(show: bool, hint_text: String) -> void:
	if _interact_hint_label:
		_interact_hint_label.text = hint_text
		_interact_hint_label.visible = show and not hint_text.is_empty()


# ============================================================
# 消息面板（底部弹出提示）
# ============================================================

func _show_message(title: String, body: String, duration: float = 4.0) -> void:
	_resolve_ui_refs()
	if not _message_title or not _message_body:
		push_warning("[Fragment0001] 缺少消息面板文本节点，跳过提示：%s" % title)
		return
	_message_title.text = title
	_message_body.text = body
	_message_panel.visible = true
	if _message_panel_bg:
		_message_panel_bg.visible = true

	# 清除之前的定时器
	if _message_timer and _message_timer.timeout.is_connected(_hide_message):
		_message_timer.timeout.disconnect(_hide_message)

	_message_timer = get_tree().create_timer(duration)
	_message_timer.timeout.connect(_hide_message)


func _hide_message() -> void:
	if _message_panel:
		_message_panel.visible = false
	if _message_panel_bg:
		_message_panel_bg.visible = false


func _resolve_ui_refs() -> void:
	if _ui_root == null:
		_ui_root = get_node_or_null("UIRoot") as CanvasLayer
	if _ui_root == null:
		return
	if _interact_hint_label == null:
		_interact_hint_label = _ui_root.get_node_or_null("InteractHint") as Label
	if _message_panel_bg == null:
		_message_panel_bg = _ui_root.get_node_or_null("MessagePanelBg") as ColorRect
	if _message_panel == null:
		_message_panel = _ui_root.get_node_or_null("MessagePanel") as Panel
	if _message_title == null:
		_message_title = _ui_root.get_node_or_null("MessagePanel/MessageTitle") as Label
	if _message_body == null:
		_message_body = _ui_root.get_node_or_null("MessagePanel/MessageBody") as Label
	if _angle_bg == null:
		_angle_bg = _ui_root.get_node_or_null("CalibrationBg") as ColorRect
	if _angle_panel == null:
		_angle_panel = _ui_root.get_node_or_null("CalibrationPanel") as Panel
	if _angle_value == null:
		_angle_value = _ui_root.get_node_or_null("CalibrationPanel/AngleValue") as Label
	if _compliance_bar_bg == null:
		_compliance_bar_bg = _ui_root.get_node_or_null("ComplianceBarContainer/ComplianceBarBg") as ColorRect
	if _compliance_bar_fill == null:
		_compliance_bar_fill = _ui_root.get_node_or_null("ComplianceBarContainer/ComplianceBarBg/ComplianceBarFill") as ColorRect
	if _compliance_label == null:
		_compliance_label = _ui_root.get_node_or_null("ComplianceBarContainer/ComplianceLabel") as Label
	if _compliance_value_label == null:
		_compliance_value_label = _ui_root.get_node_or_null("ComplianceBarContainer/ComplianceValueLabel") as Label
	if _compliance_warning_icon == null:
		_compliance_warning_icon = _ui_root.get_node_or_null("ComplianceBarContainer/ComplianceWarningIcon") as Label


# ============================================================
# Tab 键 : 收集信息面板（显示 ClueSystem 线索列表）
# ============================================================

func _input(event: InputEvent) -> void:
	if _tv_viewer and _tv_viewer.visible:
		if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_hide_tv_viewer()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") and Time.get_ticks_msec() >= _tv_close_block_until_msec:
			if tv_collected == 0:
				_collect_tv()
			else:
				_hide_tv_viewer()
			get_viewport().set_input_as_handled()
		return

	if _stone_viewer and _stone_viewer.visible:
		if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_hide_stone_viewer()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") and Time.get_ticks_msec() >= _stone_close_block_until_msec:
			if stone_collected == 0:
				_collect_stone()
			else:
				_hide_stone_viewer()
			get_viewport().set_input_as_handled()
		return

	if _lin_note_viewer and _lin_note_viewer.visible:
		if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
			_hide_lin_note_viewer()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") and Time.get_ticks_msec() >= _lin_note_close_block_until_msec:
			if lin_note_collected == 0:
				_collect_lin_note()
			else:
				_hide_lin_note_viewer()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_focus_next"):  # Tab 键
		# 校准面板打开时不响应 Tab
		if _angle_panel and _angle_panel.visible:
			return
		_toggle_collection_panel()
		get_viewport().set_input_as_handled()

	# 校准面板快捷键
	if event.is_action_pressed("escape"):
		if _angle_panel and _angle_panel.visible:
			_close_angle_panel()
			get_viewport().set_input_as_handled()


func _toggle_collection_panel() -> void:
	_ensure_clue_panel()
	if not is_instance_valid(_clue_panel):
		return
	if _clue_panel.is_open:
		_clue_panel.close()
		print("[Fragment0001] 线索面板: 关闭")
	else:
		_update_clue_list()
		_clue_panel.open()
		print("[Fragment0001] 线索面板: 打开")


func _update_clue_list() -> void:
	"""刷新预置 CluePanel 中的线索卡片。"""
	_ensure_clue_panel()
	if not is_instance_valid(_clue_panel):
		return

	var clues: Array[Dictionary] = []
	var discovered_clues = _clue_system.get("discovered_clues") if _clue_system else []
	if discovered_clues is Array:
		for i in range(discovered_clues.size()):
			if discovered_clues[i] is not Dictionary:
				continue
			var clue: Dictionary = discovered_clues[i].duplicate(true)
			clue["id"] = i
			clue["is_discovered"] = true
			clues.append(clue)

	if observed_sundials.size() >= 3:
		clues.append({
			"id": clues.size(),
			"name": "日晷间隔规律",
			"type": "hint",
			"description": "数据之间的间隔似乎有规律，这些角度应该不是随机的。",
			"location": "线索簿",
			"is_discovered": true,
		})

	_clue_panel.set_clues_from_dictionaries(clues)


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


func try_start_lin_intermission_dialogue(npc: Node) -> bool:
	if _intermission_triggered or _lin_intermission_playing:
		return false
	if observed_sundials.size() < 5:
		return false
	if not _is_linguide_npc(npc):
		return false

	_lin_intermission_playing = true
	print("[Fragment0001] 林指导幕间事件触发 — 五个日晷后与林指导对话")
	_play_lin_intermission_dialogue(npc)
	return true


func _play_lin_intermission_dialogue(npc: Node) -> void:
	if ChatDialogue.is_open:
		ChatDialogue.close()
	ChatDialogue.open(npc, "")
	if ChatDialogue.is_open and npc.has_method("start_dialogue"):
		npc.start_dialogue()

	_modify_compliance(-3, "林指导情绪波动——系统判定为异常")
	await ChatDialogue.stream_local_npc_msg(LIN_INTERMISSION_DIALOGUE)

	_lin_intermission_playing = false
	_intermission_triggered = true
	_unlock_lin_note()
	print("[Fragment0001] 林指导幕间事件结束 — LinNote 已解锁")


func _is_linguide_npc(npc: Node) -> bool:
	if not npc:
		return false
	if "npc_kb_id" in npc and str(npc.npc_kb_id) == "linguide":
		return true
	if "npc_name" in npc and str(npc.npc_name) == "林指导":
		return true
	return npc.name.to_lower().contains("linguide")


func _unlock_lin_note() -> void:
	if _lin_note_unlocked:
		return
	_lin_note_unlocked = true
	_spawn_lin_note()
	save_state()


func _spawn_lin_note() -> void:
	if lin_note_collected == 1:
		_despawn_lin_note()
		return
	if is_instance_valid(_lin_note_sprite):
		_lin_note_sprite.visible = _lin_note_unlocked and lin_note_collected == 0
		return
	var layer := _depth_layers.get(1) as Node2D
	if layer == null:
		layer = get_node_or_null("WorldRoot/DepthLayer/DepthLayer_1") as Node2D
	if layer == null:
		push_warning("[Fragment0001] 缺少 DepthLayer_1，无法创建 LinNote")
		return

	var note := Sprite2D.new()
	note.name = "LinNote"
	note.texture = LIN_NOTE_TEXTURE
	note.scale = Vector2(0.055, 0.055)
	note.visible = _lin_note_unlocked and lin_note_collected == 0
	note.z_index = 2
	note.set_script(LIN_NOTE_SCRIPT)
	layer.add_child(note)
	note.global_position = _find_lin_npc_position() + Vector2(42, 8)
	_lin_note_sprite = note


func _despawn_lin_note() -> void:
	if is_instance_valid(_lin_note_sprite):
		_lin_note_sprite.remove_from_group("interactable")
		_lin_note_sprite.queue_free()
	_lin_note_sprite = null


func show_lin_note() -> void:
	_ensure_lin_note_viewer()
	if _lin_note_viewer == null:
		return
	_update_lin_note_viewer_size()
	_refresh_lin_note_collect_hint()
	_lin_note_viewer.visible = true
	_lin_note_close_block_until_msec = Time.get_ticks_msec() + 250
	_set_player_controls_locked(true)


func _ensure_lin_note_viewer() -> void:
	if is_instance_valid(_lin_note_viewer):
		return
	_resolve_ui_refs()
	if _ui_root == null:
		return

	var overlay := Control.new()
	overlay.name = "LinNoteViewer"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_lin_note_viewer_gui_input)
	_ui_root.add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var image := TextureRect.new()
	image.name = "LinNoteImage"
	image.texture = LIN_NOTE_TEXTURE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(image)

	var hint := Label.new()
	hint.name = "CollectHint"
	hint.text = ""
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 0
	hint.offset_right = 0
	hint.offset_top = -54
	hint.offset_bottom = -22
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68, 0.92))
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	_lin_note_viewer = overlay
	_update_lin_note_viewer_size()
	_refresh_lin_note_collect_hint()


func _on_lin_note_viewer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_lin_note_viewer()


func _update_lin_note_viewer_size() -> void:
	if not is_instance_valid(_lin_note_viewer):
		return
	var image := _lin_note_viewer.get_node_or_null("Center/LinNoteImage") as TextureRect
	if image == null or image.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var tex_size := image.texture.get_size()
	var max_size := Vector2(viewport_size.x * 0.86, viewport_size.y * 0.74)
	var scale: float = minf(1.0, minf(max_size.x / tex_size.x, max_size.y / tex_size.y))
	var display_size := tex_size * scale
	image.custom_minimum_size = display_size
	image.size = display_size
	image.position = (viewport_size - display_size) * 0.5


func _refresh_lin_note_collect_hint() -> void:
	if not is_instance_valid(_lin_note_viewer):
		return
	var hint := _lin_note_viewer.get_node_or_null("CollectHint") as Label
	if hint == null:
		return
	if lin_note_collected == 1:
		hint.text = "已收集 | 点击、按 E 或按 Esc 关闭"
	else:
		hint.text = "按 E 收集便签 | 点击或按 Esc 关闭"


func _collect_lin_note() -> void:
	if lin_note_collected == 1:
		return
	lin_note_collected = 1
	FragmentManager.set_fragment_state("0001", "lin_note_collected", lin_note_collected)
	_refresh_lin_note_collect_hint()
	_despawn_lin_note()
	save_state()
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	print("[Fragment0001] LinNote collected")


func _hide_lin_note_viewer() -> void:
	if _lin_note_viewer:
		_lin_note_viewer.visible = false
	_set_player_controls_locked(false)


func show_tv() -> void:
	_ensure_tv_viewer()
	if _tv_viewer == null:
		return
	_update_tv_viewer_size()
	_refresh_tv_collect_hint()
	_tv_viewer.visible = true
	_tv_close_block_until_msec = Time.get_ticks_msec() + 250
	_set_player_controls_locked(true)
	_play_tv_video_once()


func _ensure_tv_viewer() -> void:
	if is_instance_valid(_tv_viewer):
		return
	_resolve_ui_refs()
	if _ui_root == null:
		return

	var overlay := Control.new()
	overlay.name = "TVViewer"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_tv_viewer_gui_input)
	_ui_root.add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var tv := TV_SCENE.instantiate() as Node2D
	tv.name = "TVLarge"
	tv.z_index = 2
	overlay.add_child(tv)
	_disable_viewer_tv_interaction(tv)
	_tv_viewer_tv = tv

	var hint := Label.new()
	hint.name = "CollectHint"
	hint.text = ""
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 0
	hint.offset_right = 0
	hint.offset_top = -54
	hint.offset_bottom = -22
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68, 0.92))
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	_tv_viewer = overlay
	_update_tv_viewer_size()
	_refresh_tv_collect_hint()


func _disable_viewer_tv_interaction(root: Node) -> void:
	root.remove_from_group("interactable")
	if root is Area2D:
		var area := root as Area2D
		area.monitoring = false
		area.monitorable = false
	if root is CollisionShape2D:
		(root as CollisionShape2D).disabled = true
	for child in root.get_children():
		_disable_viewer_tv_interaction(child)


func _on_tv_viewer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_tv_viewer()


func _update_tv_viewer_size() -> void:
	if not is_instance_valid(_tv_viewer_tv):
		return
	var viewport_size := get_viewport_rect().size
	var body := _tv_viewer_tv.get_node_or_null("Visual/Body") as Sprite2D
	if body == null or body.texture == null:
		_tv_viewer_tv.position = viewport_size * 0.5
		_tv_viewer_tv.scale = Vector2(0.45, 0.45)
		return
	var texture_size := body.texture.get_size()
	var body_scale := Vector2(absf(body.scale.x), absf(body.scale.y))
	var body_size := texture_size * body_scale
	var max_size := Vector2(viewport_size.x * 0.88, viewport_size.y * 0.78)
	var fit_scale: float = minf(max_size.x / body_size.x, max_size.y / body_size.y)
	_tv_viewer_tv.scale = Vector2(fit_scale, fit_scale)
	_tv_viewer_tv.position = viewport_size * 0.5 - body.position * fit_scale


func _refresh_tv_collect_hint() -> void:
	if not is_instance_valid(_tv_viewer):
		return
	var hint := _tv_viewer.get_node_or_null("CollectHint") as Label
	if hint == null:
		return
	if tv_collected == 1:
		hint.text = "已收集 | 点击、按 E 或按 Esc 关闭"
	else:
		hint.text = "按 E 收集电视广告 | 点击或按 Esc 关闭"


func _play_tv_video_once() -> void:
	var video_player := _get_tv_video_player()
	if video_player == null:
		return
	video_player.stream = TV_VIDEO_STREAM
	video_player.loop = false
	video_player.stop()
	video_player.stream_position = 0.0
	video_player.play()


func _stop_tv_video() -> void:
	var video_player := _get_tv_video_player()
	if video_player:
		video_player.stop()


func _get_tv_video_player() -> VideoStreamPlayer:
	if not is_instance_valid(_tv_viewer_tv):
		return null
	return _tv_viewer_tv.get_node_or_null("ScreenClip/VideoPlayer") as VideoStreamPlayer


func _collect_tv() -> void:
	if tv_collected == 1:
		return
	tv_collected = 1
	FragmentManager.set_fragment_state("0001", "tv_collected", tv_collected)
	_refresh_tv_collect_hint()
	_refresh_tv_collection_state()
	save_state()
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	print("[Fragment0001] TV collected")


func _hide_tv_viewer() -> void:
	if _tv_viewer:
		_tv_viewer.visible = false
	_stop_tv_video()
	_set_player_controls_locked(false)


func _refresh_tv_collection_state() -> void:
	_tv_node = get_node_or_null("WorldRoot/DepthLayer/DepthLayer_3/Tv") as Node2D
	if not is_instance_valid(_tv_node):
		var world_root := get_node_or_null("WorldRoot")
		if world_root:
			var nodes := world_root.find_children("Tv", "Node2D", true, false)
			if nodes.size() > 0:
				_tv_node = nodes[0] as Node2D
	if not is_instance_valid(_tv_node):
		return
	var collected := tv_collected == 1
	_tv_node.visible = not collected
	if collected:
		_tv_node.remove_from_group("interactable")
	else:
		_tv_node.add_to_group("interactable")
	var area := _tv_node.get_node_or_null("InteractableArea") as Area2D
	if area:
		area.monitoring = not collected
		area.monitorable = not collected
	var body := _tv_node.get_node_or_null("StaticBody2D") as StaticBody2D
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				var collision_shape := child as CollisionShape2D
				collision_shape.disabled = collected


func show_stone() -> void:
	if stone_collected == 1:
		return
	_ensure_stone_viewer()
	if _stone_viewer == null:
		return
	_update_stone_viewer_size()
	_refresh_stone_collect_hint()
	_stone_viewer.visible = true
	_stone_close_block_until_msec = Time.get_ticks_msec() + 250
	_set_player_controls_locked(true)


func _ensure_stone_viewer() -> void:
	if is_instance_valid(_stone_viewer):
		return
	_resolve_ui_refs()
	if _ui_root == null:
		return

	var overlay := Control.new()
	overlay.name = "StoneViewer"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_stone_viewer_gui_input)
	_ui_root.add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var image := TextureRect.new()
	image.name = "StoneImage"
	image.texture = STONE_TEXTURE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(image)

	var hint := Label.new()
	hint.name = "CollectHint"
	hint.text = ""
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 0
	hint.offset_right = 0
	hint.offset_top = -54
	hint.offset_bottom = -22
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68, 0.92))
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	_stone_viewer = overlay
	_update_stone_viewer_size()
	_refresh_stone_collect_hint()


func _on_stone_viewer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_stone_viewer()


func _update_stone_viewer_size() -> void:
	if not is_instance_valid(_stone_viewer):
		return
	var image := _stone_viewer.get_node_or_null("Center/StoneImage") as TextureRect
	if image == null or image.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var tex_size := image.texture.get_size()
	var max_size := Vector2(viewport_size.x * 0.92, viewport_size.y * 0.82)
	var scale: float = minf(1.0, minf(max_size.x / tex_size.x, max_size.y / tex_size.y))
	var display_size := tex_size * scale
	image.custom_minimum_size = display_size
	image.size = display_size
	image.position = (viewport_size - display_size) * 0.5


func _refresh_stone_collect_hint() -> void:
	if not is_instance_valid(_stone_viewer):
		return
	var hint := _stone_viewer.get_node_or_null("CollectHint") as Label
	if hint == null:
		return
	if stone_collected == 1:
		hint.text = "已收集 | 点击、按 E 或按 Esc 关闭"
	else:
		hint.text = "按 E 收集石碑 | 点击或按 Esc 关闭"


func _collect_stone() -> void:
	if stone_collected == 1:
		return
	stone_collected = 1
	FragmentManager.set_fragment_state("0001", "stone_collected", stone_collected)
	_refresh_stone_collect_hint()
	_refresh_stone_collection_state()
	save_state()
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	print("[Fragment0001] 石碑已收集")


func _hide_stone_viewer() -> void:
	if _stone_viewer:
		_stone_viewer.visible = false
	_set_player_controls_locked(false)


func _refresh_stone_collection_state() -> void:
	_stone_node = get_node_or_null("WorldRoot/DepthLayer/DepthLayer_3/Stone") as Node2D
	if not is_instance_valid(_stone_node):
		return
	var collected := stone_collected == 1
	_stone_node.visible = not collected
	if collected:
		_stone_node.remove_from_group("interactable")
	else:
		_stone_node.add_to_group("interactable")
	var area := _stone_node.get_node_or_null("InteractableArea") as Area2D
	if area:
		area.monitoring = not collected
		area.monitorable = not collected
	var body := _stone_node.get_node_or_null("StaticBody2D") as StaticBody2D
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				var collision_shape := child as CollisionShape2D
				collision_shape.disabled = collected


func _find_camera_rig() -> Node2D:
	"""查找 CameraRig 节点（用于幕间运镜）"""
	var world_root := get_node_or_null("WorldRoot")
	if not world_root:
		return null
	var rig := world_root.get_node_or_null("CameraRig")
	if rig is Node2D:
		return rig as Node2D
	return null


# ============================================================
# P1：边界光墙触碰事件
# ============================================================

func _check_boundary(delta: float) -> void:
	"""在 _process 中追踪玩家是否靠近场景边界 — 三级触碰系统 + 光墙区域检测"""
	if not _player:
		return

	# 冷却倒计时
	if _boundary_cooldown > 0.0:
		_boundary_cooldown -= delta
		return

	var pos: Vector2 = _player.global_position
	var near_boundary: bool = false

	# 边界范围（与 AirWall 对齐）
	if pos.x < 50.0 or pos.x > 1250.0 or pos.y < 50.0 or pos.y > 750.0:
		near_boundary = true

	# 也检查光墙 InteractionArea 重叠（额外检测）
	if not near_boundary and _is_inside_light_wall():
		near_boundary = true

	if not near_boundary:
		return

	# 触碰计数递增
	_boundary_touch_count += 1
	_boundary_cooldown = 30.0  # 冷却 30 秒

	print("[Fragment0001] 边界光墙触碰 #%d — 玩家位置: (%d, %d)" % [_boundary_touch_count, int(pos.x), int(pos.y)])

	# 光墙波纹视觉特效
	_create_boundary_ripple_effect(pos)

	match _boundary_touch_count:
		1:
			_modify_compliance(-5, "触碰边界光墙一次")
			_show_message(
				"赵安保",
				"触碰边界光墙一次——警告。合规度扣除5%。",
				4.0
			)
		2:
			_modify_compliance(-10, "触碰边界光墙两次")
			_show_message(
				"赵安保",
				"触碰第二次——限制令。请立即回到指定区域。",
				4.5
			)
		3:
			# 第三次直接触发 L6 强制回归
			_compliance_l6_triggered = false  # 确保 L6 可以被触发
			compliance = 24  # 设置合规度到 L6 阈值以下
			_update_compliance_bar()
			save_state()
			_show_message(
				"赵安保",
				"别碰第三次。为了您的——",
				3.0
			)
			await get_tree().create_timer(1.5).timeout
			_trigger_l6_forced_return()
			_boundary_touch_count = 0  # 重置计数（L6 回归后）


func _check_sundial_e_proximity(_delta: float) -> void:
	"""检测玩家是否首次接近观测点E（边界残晷）"""
	if _sundial_e_proximity_triggered or not _player:
		return

	# 查找 SundialE 节点
	var sundial_e: Node2D = _find_sundial_e_node()
	if not sundial_e:
		return

	var dist: float = _player.global_position.distance_to(sundial_e.global_position)
	if dist < 120.0:
		_sundial_e_proximity_triggered = true
		_show_message(
			"系统",
			"这个日晷被砸碎了。碎片被整齐排列——或许缺失的角度可以从其他数据推导。",
			5.0
		)
		print("[Fragment0001] 首次接近观测点E（边界残晷），自动触发提示")


func _find_sundial_e_node() -> Node2D:
	"""查找 SundialE 节点"""
	var world_root := get_node_or_null("WorldRoot")
	if not world_root:
		return null
	var nodes: Array[Node] = world_root.find_children("SundialE", "Node2D", true, false)
	if nodes.size() > 0:
		return nodes[0] as Node2D
	return null


func _create_boundary_ripple_effect(at_position: Vector2) -> void:
	"""在触碰点创建光墙水波光晕效果（0.2s 透明波纹扩散）"""
	if not _ui_root:
		return

	var ripple: ColorRect = ColorRect.new()
	ripple.name = "BoundaryRipple"
	ripple.color = Color(0.35, 0.6, 0.9, 0.4)  # 光墙蓝色
	ripple.size = Vector2(40, 40)
	ripple.position = at_position - Vector2(20, 20)
	ripple.pivot_offset = Vector2(20, 20)
	ripple.scale = Vector2(0.5, 0.5)
	_ui_root.add_child(ripple)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2(3.0, 3.0), 0.4)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.4).from(0.5)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ripple):
			ripple.queue_free()
	)

	# 光墙短暂透明效果：在触碰点模拟"透过光墙看到外面"
	var transparency_glimpse: ColorRect = ColorRect.new()
	transparency_glimpse.name = "BoundaryGlimpse"
	# 在触碰点附近显示一个小范围的外景颜色提示
	transparency_glimpse.color = Color(0.25, 0.55, 0.25, 0.35)  # 绿色（草地外景）
	transparency_glimpse.size = Vector2(60, 60)
	transparency_glimpse.position = at_position - Vector2(30, 30)
	transparency_glimpse.pivot_offset = Vector2(30, 30)
	_ui_root.add_child(transparency_glimpse)

	var glimpse_tween := create_tween()
	glimpse_tween.tween_interval(0.15)
	glimpse_tween.tween_property(transparency_glimpse, "modulate:a", 0.0, 0.15)
	glimpse_tween.finished.connect(func() -> void:
		if is_instance_valid(transparency_glimpse):
			transparency_glimpse.queue_free()
	)


# ============================================================
# SFX 音效播放
# ============================================================

func _ensure_sfx_player() -> void:
	"""确保 SFX 播放器已创建（使用 SFX 总线，受音量设置控制）"""
	if _sfx_player == null:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.name = "SFXPlayer_Fragment0001"
		_sfx_player.bus = "SFX"
		_sfx_player.volume_db = 0.0
		add_child(_sfx_player)


func _play_sfx(stream: AudioStream) -> void:
	"""播放指定音效流（使用 SFX 总线）"""
	if stream == null:
		printerr("[Fragment0001] _play_sfx: stream is null")
		return
	AudioManager.play_sfx(stream, AudioManager.PRIORITY_HIGH, 0.0)


# ============================================================
# BGM 播放
# ============================================================

func _start_bgm() -> void:
	AudioManager.play_bgm(BGM_FRAGMENT_0001, "fragment_0001", 0.45, -10.0, true)
	print("[Fragment0001] 探索 BGM 已开始播放")

func _stop_bgm() -> void:
	AudioManager.stop_bgm(0.25)
	print("[Fragment0001] 探索 BGM 已停止")


# ============================================================
# 测试钩子（供 scripts/tests/test_fragment_0001_smoke.gd 驱动正式场景）
# ============================================================

func has_player_for_test() -> bool:
	return _player != null


func observe_sundial_for_test(id: String) -> void:
	var sundial := _find_sundial_node_for_test(id)
	if sundial:
		on_sundial_interact(sundial)


func set_clock_angle_for_test(value: int) -> void:
	clock_angle = value
	_update_angle_value()


func submit_clock_angle_for_test() -> bool:
	return await _submit_clock_angle()


func get_observed_count_for_test() -> int:
	return observed_sundials.size()


func get_compliance_for_test() -> int:
	return compliance


func is_source_mark_revealed_for_test() -> bool:
	return source_mark_revealed


func _find_sundial_node_for_test(id: String) -> Node2D:
	var world_root := get_node_or_null("WorldRoot")
	var search_root: Node = world_root if world_root else self
	var patterns := ["Sundial%s" % id, "Sundial_%s" % id]
	for pattern in patterns:
		var nodes := search_root.find_children(pattern, "Node2D", true, false)
		if not nodes.is_empty():
			return nodes[0] as Node2D
	return null
