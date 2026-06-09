extends Node2D
## fragment_0001 场景脚本 — 实例化玩家 + 深度层动态切换

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")

## DepthLayer Y 范围阈值
const LAYER_1_Y: float = 450.0  # Y > 450 → DepthLayer_1（前景）
const LAYER_2_Y: float = 250.0  # 250 < Y <= 450 → DepthLayer_2（中景）
								# Y <= 250 → DepthLayer_3（远景）

## 玩家引用
var _player: CharacterBody2D = null
## 当前玩家所在深度层编号（1/2/3）
var _current_layer: int = 0
## DepthLayer 节点缓存
var _depth_layers: Dictionary = {}
## 收集信息面板引用
var _collection_panel: CanvasLayer = null


func _ready() -> void:
	_cache_depth_layers()
	_spawn_player()
	_setup_collection_panel()


func _process(_delta: float) -> void:
	_update_player_z()
	_update_player_depth_layer()


## 缓存 DepthLayer 子节点引用
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


## 根据 Y 坐标确定应属于哪个 DepthLayer
func _get_layer_by_y(y: float) -> int:
	if y > LAYER_1_Y:
		return 1  # 前景
	elif y > LAYER_2_Y:
		return 2  # 中景
	else:
		return 3  # 远景


## 在场景中实例化玩家，根据 SpawnPoints/Default 标记放置到对应 DepthLayer 下
func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D

	# 查找 SpawnPoints/Default 标记
	var spawn_marker: Marker2D = null
	var spawn_points = get_node_or_null("WorldRoot/SpawnPoints")
	if spawn_points:
		spawn_marker = spawn_points.get_node_or_null("Default") as Marker2D

	# 确定生成位置
	var spawn_pos: Vector2 = Vector2(644, 655)  # 默认后备位置
	if spawn_marker:
		spawn_pos = spawn_marker.global_position
		print("[Fragment0001] 使用 SpawnPoints/Default 位置: %s" % str(spawn_pos))
	else:
		print("[Fragment0001] 未找到 Default 出生点，使用默认位置")

	# 根据生成位置 Y 坐标确定深度层
	var target_layer = _get_layer_by_y(spawn_pos.y)
	var layer_node = _depth_layers.get(target_layer) as Node2D

	if layer_node:
		# 将 Player 添加到对应 DepthLayer_N 下
		layer_node.add_child(_player)
		_player.global_position = spawn_pos
		_current_layer = target_layer
		print("[Fragment0001] 玩家已实例化到 DepthLayer_%d，位置: %s" % [target_layer, str(spawn_pos)])
	else:
		# 降级：直接添加到 WorldRoot
		var world_root = get_node_or_null("WorldRoot")
		if world_root:
			world_root.add_child(_player)
		else:
			add_child(_player)
		_player.global_position = spawn_pos
		_current_layer = 0
		printerr("[Fragment0001] DepthLayer_%d 节点不存在，玩家降级添加到 WorldRoot" % target_layer)


## 确保玩家 z_index=0，让 DepthLayer 的 y_sort_enabled 自动处理遮挡关系
## y_sort 按节点 Y 坐标排序：Y 越大越靠前（靠近镜头），Y 越小越靠后（被遮挡）
func _update_player_z() -> void:
	if not _player:
		_player = get_node_or_null("Player") as CharacterBody2D
		if not _player:
			return
	# z_index 必须为 0，否则 y_sort 失效
	if _player.z_index != 0:
		_player.z_index = 0


## 当玩家 Y 坐标变化到另一个层范围时，自动切换父节点到对应的 DepthLayer_N
func _update_player_depth_layer() -> void:
	if not _player or _depth_layers.is_empty():
		return

	var player_y: float = _player.global_position.y
	var target_layer: int = _get_layer_by_y(player_y)

	# 层未变化则跳过
	if target_layer == _current_layer:
		return

	var layer_node = _depth_layers.get(target_layer) as Node2D
	if not layer_node:
		return

	# 记录全局位置（reparent 前保存）
	var saved_global_pos: Vector2 = _player.global_position

	# 使用 reparent 保持全局位置不变
	_player.reparent(layer_node)
	_player.global_position = saved_global_pos

	var old_layer: int = _current_layer
	_current_layer = target_layer
	print("[Fragment0001] 玩家从 DepthLayer_%d 切换到 DepthLayer_%d (Y=%.0f)" % [old_layer, target_layer, player_y])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):  # Tab 键
		_toggle_collection_panel()


## 创建收集信息面板（CanvasLayer）
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
	panel.size = Vector2(600, 400)
	panel.position = Vector2(340, 160)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(panel)

	var title = Label.new()
	title.name = "Title"
	title.text = "收集信息"
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1))
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(600, 40)
	title.position = Vector2(0, 15)
	panel.add_child(title)

	var hint = Label.new()
	hint.name = "TabHint"
	hint.text = "按 Tab 关闭"
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1))
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(600, 30)
	hint.position = Vector2(0, 360)
	panel.add_child(hint)

	_collection_panel = layer
	_collection_panel.hide()
	print("[Fragment0001] 收集信息面板已创建")


## 切换收集信息面板显隐
func _toggle_collection_panel() -> void:
	if not _collection_panel:
		return
	_collection_panel.visible = not _collection_panel.visible
	print("[Fragment0001] 收集面板: %s" % ("打开" if _collection_panel.visible else "关闭"))
