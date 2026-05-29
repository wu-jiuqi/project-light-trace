extends Node2D
## 碎片 #0762 房间基类 — 832×512 地图，传送点全部位于边缘中点
## 自动挂载 FragmentState、创建 Player、配置 SpawnPoints 和 TransitionArea

const TSA = preload("res://scripts/globals/transition_area.gd")
const FSS = preload("res://scripts/fragment/fragment_0762_state.gd")
const PlayerScene = preload("res://scenes/characters/id0762/player.tscn")
const EXIT_SIZE := Vector2(20, 20)

## 地图边缘中点坐标
const EDGE_TOP    := Vector2(416, 0)
const EDGE_BOTTOM := Vector2(416, 512)
const EDGE_LEFT   := Vector2(0, 256)
const EDGE_RIGHT  := Vector2(832, 256)

## 对应出生点（向内偏移 128px，黑屏过渡已覆盖瞬移视觉）
const SPAWN_TOP    := Vector2(416, 128)
const SPAWN_BOTTOM := Vector2(416, 384)
const SPAWN_LEFT   := Vector2(128, 256)
const SPAWN_RIGHT  := Vector2(704, 256)

static var ROOM_PATHS := {
	"Square":    "res://scenes/rooms/id0762/Square.tscn",
	"Market":    "res://scenes/rooms/id0762/Market.tscn",
	"Smithy":    "res://scenes/rooms/id0762/Smithy.tscn",
	"Townhall":  "res://scenes/rooms/id0762/Townhall.tscn",
	"Graveyard": "res://scenes/rooms/id0762/Graveyard.tscn",
	"Studio":    "res://scenes/rooms/id0762/Studio.tscn",
}


func _ready() -> void:
	# 入场先强制全黑，防止新场景闪现
	SceneFader.ensure_black()

	print("[RoomBase] 初始化 %s" % name)
	_ensure_fragment_state()
	_ensure_spawn_points()
	_setup_exits()
	# 无入站出生点时（直接运行场景/编辑器测试），兜底到 from_cutscene
	if SceneManager.pending_spawn_point.is_empty():
		_set_default_spawn()
	# Player 必须最后创建 —— 其 _ready() 触发 _try_spawn() 时
	# SpawnPoints 必须已存在且包含所有标记点
	_ensure_player()
	_setup_npcs()
	print("[RoomBase] %s 就绪" % name)

	# 淡入，交出控制权
	SceneFader.fade_in()


func _ensure_fragment_state() -> void:
	if has_node("FragmentState"):
		return
	var n = Node.new()
	n.name = "FragmentState"
	n.set_script(FSS)
	add_child(n)


func _ensure_player() -> void:
	if has_node("Player"):
		print("[%s] Player 已存在" % name)
		_ensure_camera($Player)
		return
	var p = PlayerScene.instantiate()
	p.name = "Player"
	p.position = _default_player_position()
	add_child(p)
	_ensure_camera(p)
	print("[%s] Player 创建于默认位置 %s，等待 _try_spawn 修正" % [name, p.position])


func _ensure_camera(player: Node2D) -> void:
	# 清除旧相机（可能由 player.tscn 自带或残留）
	var old = player.get_node_or_null("Camera2D")
	if old:
		old.queue_free()

	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(2.0, 2.0)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0

	# 地图边界 832×512，视口 1280×720，zoom 2x 可视 640×360
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 832
	cam.limit_bottom = 512

	player.add_child(cam)
	cam.make_current()
	print("[%s] 相机已绑定 Player (zoom=%.1f)" % [name, cam.zoom.x])


func _ensure_spawn_points() -> void:
	if not has_node("SpawnPoints"):
		var sp = Node2D.new()
		sp.name = "SpawnPoints"
		add_child(sp)


# ============================================================
# 子类重写
# ============================================================

func _setup_exits() -> void:
	pass


func _setup_npcs() -> void:
	pass


func _default_player_position() -> Vector2:
	return Vector2(416, 256)


## 无入站出生点时的兜底逻辑（直接运行场景/编辑器测试）
## 子类可重写来指定不同的默认出生点
func _set_default_spawn() -> void:
	if $SpawnPoints.has_node("from_cutscene"):
		SceneManager.pending_spawn_point = "from_cutscene"
		print("[%s] 无入站出生点，兜底使用 from_cutscene" % name)


# ============================================================
# 工具方法
# ============================================================

## 创建连接出口：my_side → target_room
## side: "top"/"bottom"/"left"/"right"
func _exit(side: String, to_room: String) -> void:
	var path = ROOM_PATHS.get(to_room, "")
	assert(not path.is_empty(), "未知房间: %s" % to_room)

	var room_name = self.name  # 显式捕获房间名，避免歧义
	var target_spawn = "from_%s" % room_name.to_lower()
	var name_str = "exit_%s" % side
	var pos: Vector2
	match side:
		"top":    pos = EDGE_TOP
		"bottom": pos = EDGE_BOTTOM
		"left":   pos = EDGE_LEFT
		"right":  pos = EDGE_RIGHT

	var area = Area2D.new()
	area.name = name_str
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = EXIT_SIZE
	shape.shape = rect
	area.add_child(shape)

	area.set_script(TSA)
	area.target_scene = path
	area.target_spawn_point = target_spawn

	add_child(area)
	print("[%s] 出口 %s → %s (出生点: %s)" % [room_name, side, to_room, target_spawn])


## 创建出生点标记
## side: "top"/"bottom"/"left"/"right"
func _spawn(side: String, by_room: String) -> void:
	var pos: Vector2
	match side:
		"top":    pos = SPAWN_TOP
		"bottom": pos = SPAWN_BOTTOM
		"left":   pos = SPAWN_LEFT
		"right":  pos = SPAWN_RIGHT

	var m = Marker2D.new()
	m.name = "from_%s" % by_room.to_lower()
	m.position = pos
	$SpawnPoints.add_child(m)
	print("[%s] 出生点 %s → %s" % [self.name, m.name, pos])
