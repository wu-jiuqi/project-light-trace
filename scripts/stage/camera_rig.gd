extends Node2D
## CameraRig 跟随控制器
## 挂载到 CameraRig 节点，实现差异化速率的平滑跟随 + 深度层推进效果

## 垂直偏移：镜头目标位置比玩家脚底偏上，对准身体中部偏上（避免镜头中心对准脚底）
@export var vertical_offset: float = 64.0
## 水平跟随速度（越大越快，横向跟随更及时）
@export var horizontal_follow_speed: float = 5.0
## 垂直跟随速度（比水平慢，纵向更柔和，减少上下晃动的眩晕感）
@export var vertical_follow_speed: float = 2.5
## 每深一层（更远的 DepthLayer），镜头额外偏上多少，实现"镜头整体推进"效果
@export var depth_layer_y_push: float = 50.0

## Camera2D 子节点引用
var _camera: Camera2D = null
## 当前玩家所在深度层编号（1=前景, 2=中景, 3=远景）
var _current_depth_layer: int = 1
## 上一次检测到的深度层（避免重复计算）
var _last_detected_layer: int = 1
## DepthLayer Y 阈值（与 fragment_0001.gd 保持一致）
const LAYER_1_Y: float = 450.0
const LAYER_2_Y: float = 250.0


func _ready() -> void:
	# 获取 Camera2D 子节点
	_camera = get_node_or_null("Camera2D") as Camera2D
	if _camera:
		# 禁用 Camera2D 自带的平滑，由脚本控制
		_camera.position_smoothing_enabled = false
		print("[CameraRig] Camera2D 已就绪，自带平滑已关闭")
	else:
		printerr("[CameraRig] 未找到 Camera2D 子节点")


func _process(delta: float) -> void:
	var player = _find_player()
	if not player:
		return

	# 检测玩家当前深度层
	_detect_depth_layer(player.global_position.y)

	# 计算目标位置 = 玩家位置 + 垂直偏移 + 深度层推进
	var layer_push: float = 0.0
	if _current_depth_layer == 2:
		layer_push = depth_layer_y_push
	elif _current_depth_layer == 3:
		layer_push = depth_layer_y_push * 2.0

	var target_pos: Vector2 = Vector2(
		player.global_position.x,
		player.global_position.y - vertical_offset - layer_push
	)

	# 差异化速率平滑跟随
	var new_x: float = lerp(global_position.x, target_pos.x, horizontal_follow_speed * delta)
	var new_y: float = lerp(global_position.y, target_pos.y, vertical_follow_speed * delta)

	global_position = Vector2(new_x, new_y)


## 检测玩家当前所在的深度层
func _detect_depth_layer(player_y: float) -> void:
	if player_y > LAYER_1_Y:
		_current_depth_layer = 1
	elif player_y > LAYER_2_Y:
		_current_depth_layer = 2
	else:
		_current_depth_layer = 3

	if _current_depth_layer != _last_detected_layer:
		var layer_names: Dictionary = {1: "前景", 2: "中景", 3: "远景"}
		print("[CameraRig] 深度层变化: %s → %s (%s)" % [
			_last_detected_layer, _current_depth_layer,
			layer_names.get(_current_depth_layer, "?")
		])
		_last_detected_layer = _current_depth_layer


## 查找玩家节点（通过 group "player"）
func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
