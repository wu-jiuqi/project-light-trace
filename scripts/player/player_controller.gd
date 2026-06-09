extends CharacterBody2D
class_name PlayerController
## 玩家移动控制器 + 跨场景出生点自定位 + NPC/物品交互

## 交互提示变更信号，供 HUD/UI 层监听显示提示文字
signal interact_hint_changed(show: bool, hint_text: String)

@export var speed: float = 200.0

## 当前在交互范围内的NPC列表
var _nearby_npcs: Array[Node2D] = []
## 最近的可交互NPC
var _closest_npc: Node2D = null
## 当前在交互范围内的可拾取物品列表
var _nearby_pickups: Array[Area2D] = []
## 最近的可拾取物品
var _closest_pickup: Area2D = null
## 当前在交互范围内的可交互物件（日晷等）
var _nearby_interactables: Array[Node2D] = []
## 最近的可交互物件
var _closest_interactable: Node2D = null
## 交互区域引用（场景中已有的 InteractionArea）
var _interaction_area: Area2D = null
## 帧计数器，用于定期清理过期引用
var _frame_counter: int = 0

# ============================================================
# 视觉动画
# ============================================================
## Visual Node2D — 控制走路摇摆旋转的根节点
@onready var _visual_root: Node2D = get_node("Visual Node2D")
## Visual Sprite2D — 控制镜像翻转的精灵节点
@onready var _visual_sprite: Sprite2D = get_node("Visual Node2D/Visual")
## Shadow Sprite2D — 脚底圆形阴影
@onready var _shadow_sprite: Sprite2D = get_node("Visual Node2D/Shadow Sprite2D")

## 走路摇摆
var _sway_time: float = 0.0
const SWAY_AMPLITUDE: float = 2.5   ## 摇摆幅度（度）
const SWAY_SPEED: float = 10.0      ## 摇摆振荡速度

## 镜像翻转
var _facing_right: bool = true      ## 当前朝向（true=右，false=左）
var _is_flipping: bool = false
const FLIP_DURATION: float = 0.18   ## 翻转动画时长（秒）


func _ready() -> void:
	add_to_group("player")

	# 俯视角游戏使用 FLOATING 模式，避免地板检测导致NPC被粘在玩家头上
	motion_mode = MOTION_MODE_FLOATING

	# 设置脚底圆形阴影
	_setup_shadow()

	# 使用场景中已有的 InteractionArea，而非动态创建
	_setup_interaction_area()

	# 跨场景出生点定位（由 SceneManager 设定）
	var spawn_name = SceneManager.pending_spawn_point
	if not spawn_name.is_empty():
		SceneManager.pending_spawn_point = ""  # 消费掉
		_try_spawn(spawn_name)

	print("[PlayerController] 就绪，速度: %.0f 位置: %s" % [speed, global_position])


## 初始化场景中已有的 InteractionArea，设置形状并连接信号
func _setup_interaction_area() -> void:
	# 查找场景中已有的 InteractionArea Area2D 节点
	_interaction_area = get_node_or_null("InteractionArea Area2D") as Area2D
	if not _interaction_area:
		# 备用：尝试不带空格的名称（以防节点名不同）
		_interaction_area = get_node_or_null("InteractionArea") as Area2D

	if _interaction_area:
		# 设置 collision_layer 和 collision_mask
		_interaction_area.collision_layer = 0  # 不占用任何层
		_interaction_area.collision_mask = 2 | 4 | 8  # 检测 layer 2 (可交互物件/日晷) + layer 4 (NPC) + layer 8 (物品)

		# 为 InteractionArea/CollisionShape2D 赋予形状
		var shape_node = _interaction_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node:
			var circle = CircleShape2D.new()
			circle.radius = 35.0  # 交互检测半径
			shape_node.shape = circle
		else:
			# 若子节点不存在，动态创建
			var new_shape = CollisionShape2D.new()
			var circle = CircleShape2D.new()
			circle.radius = 35.0
			new_shape.shape = circle
			_interaction_area.add_child(new_shape)

		# 连接信号
		if not _interaction_area.area_entered.is_connected(_on_interaction_zone_entered):
			_interaction_area.area_entered.connect(_on_interaction_zone_entered)
		if not _interaction_area.area_exited.is_connected(_on_interaction_zone_exited):
			_interaction_area.area_exited.connect(_on_interaction_zone_exited)

		print("[PlayerController] InteractionArea 已就绪 (layer=0 mask=%d radius=35)" % _interaction_area.collision_mask)
	else:
		printerr("[PlayerController] 未找到 InteractionArea 节点，交互功能不可用")


func _try_spawn(spawn_name: String) -> void:
	# 从当前节点向上查找 SpawnPoints 节点
	# Player 可能在 DepthLayer_N 下，需要向上遍历到 WorldRoot
	var spawns: Node2D = null
	var current: Node = get_parent()
	while current:
		var found = current.get_node_or_null("SpawnPoints")
		if found:
			spawns = found as Node2D
			break
		# 也检查当前节点自身是否就是 SpawnPoints
		if current.name == "SpawnPoints":
			spawns = current as Node2D
			break
		current = current.get_parent()

	if not spawns:
		print("[PlayerController] 未找到 SpawnPoints 节点")
		return

	var marker = spawns.get_node_or_null(spawn_name)
	if not marker:
		var names: Array[String] = [] as Array[String]
		for child in spawns.get_children():
			names.append(child.name)
		print("[PlayerController] 出生点 '%s' 未找到，可用: %s" % [spawn_name, names])
		return

	global_position = marker.global_position
	print("[PlayerController] 已放置于出生点: %s" % spawn_name)


func _physics_process(delta: float) -> void:
	# 对话或背包打开时锁定移动
	if ChatDialogue.is_open or InventoryManager.backpack_open:
		velocity = Vector2.ZERO
		move_and_slide()
		_settle_sway(delta)
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	# 检测水平方向变化 → 触发镜像翻转
	_detect_flip(direction.x)

	# 走路时左右小幅度摇晃
	var is_moving = velocity.length() > 10.0
	_update_sway(delta, is_moving)

	# 定期清理已失效的交互引用（每30帧）
	_frame_counter += 1
	if _frame_counter % 30 == 0:
		_cleanup_nearby_lists()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# 对话已打开时不重复触发
		if ChatDialogue.is_open:
			return
		print("══════════ [Player] E键按下 ══════════")
		print("  附近NPC: %d 个 | 最近: %s" % [
			_nearby_npcs.size(),
			_closest_npc.npc_name if _closest_npc and is_instance_valid(_closest_npc) else "无"
		])
		print("  附近物品: %d 个 | 最近: %s" % [
			_nearby_pickups.size(),
			_closest_pickup.item_name if _closest_pickup and is_instance_valid(_closest_pickup) and "item_name" in _closest_pickup else "无"
		])
		print("  附近物件: %d 个 | 最近: %s" % [
			_nearby_interactables.size(),
			_closest_interactable.name if _closest_interactable and is_instance_valid(_closest_interactable) else "无"
		])

		# 优先 NPC → 可交互物件（日晷等）→ 拾取物品 → 通用
		if _closest_npc and is_instance_valid(_closest_npc) and not _closest_npc.is_queued_for_deletion():
			_interact_with_nearest_npc()
		elif _closest_interactable and is_instance_valid(_closest_interactable) and not _closest_interactable.is_queued_for_deletion():
			_interact_with_interactable(_closest_interactable)
		elif _closest_pickup and is_instance_valid(_closest_pickup) and not _closest_pickup.is_queued_for_deletion():
			_interact_with_pickup(_closest_pickup)
		else:
			# 尝试通用交互
			_try_generic_interact()

	# DEBUG: F1 测试RAG检索器
	if event.is_action_pressed("ui_focus_next") and OS.is_debug_build():
		_debug_test_rag()


# ============================================================
# 交互区域信号回调
# ============================================================

func _on_interaction_zone_entered(zone: Area2D) -> void:
	if not is_instance_valid(zone) or zone.is_queued_for_deletion():
		return

	# 判断是 NPC InteractionZone、可交互物件 还是可拾取物品
	var parent = zone.get_parent()

	if parent and is_instance_valid(parent) and parent.has_method("start_dialogue"):
		# NPC 交互区域
		if parent not in _nearby_npcs:
			_nearby_npcs.append(parent)
			_update_closest_npc()
			print("[Player] 进入 %s 交互范围" % parent.npc_name)
	elif parent and is_instance_valid(parent) and parent.is_in_group("interactable"):
		# 可交互物件（日晷等），layer 2
		if parent not in _nearby_interactables:
			_nearby_interactables.append(parent)
			_update_closest_interactable()
			print("[Player] 进入可交互物件范围: %s" % parent.name)
	elif _is_pickup_item(zone):
		# 可拾取物品
		if zone not in _nearby_pickups:
			_nearby_pickups.append(zone)
			_update_closest_pickup()
			var pname: String = zone.item_name if "item_name" in zone else "物品"
			print("[Player] 进入物品交互范围: %s" % pname)


func _on_interaction_zone_exited(zone: Area2D) -> void:
	if not is_instance_valid(zone):
		return

	var parent = zone.get_parent()

	# NPC
	if parent and is_instance_valid(parent) and parent in _nearby_npcs:
		_nearby_npcs.erase(parent)
		_update_closest_npc()
		var npc_name_str: String = parent.npc_name if "npc_name" in parent else parent.name
		print("[Player] 离开 %s 交互范围" % npc_name_str)

	# 可交互物件
	if parent and is_instance_valid(parent) and parent in _nearby_interactables:
		_nearby_interactables.erase(parent)
		_update_closest_interactable()
		print("[Player] 离开可交互物件范围: %s" % parent.name)

	# 可拾取物品
	if zone in _nearby_pickups:
		var item_name_str: String = zone.item_name if "item_name" in zone else "物品"
		_nearby_pickups.erase(zone)
		_update_closest_pickup()
		print("[Player] 离开物品交互范围: %s" % item_name_str)


## 判断一个 Area2D 是否为可拾取物品
func _is_pickup_item(zone: Area2D) -> bool:
	# 方式1: 在 pickup 分组中
	if zone.is_in_group("pickup"):
		return true
	# 方式2: 有 item_name 属性（pickup_item.gd 的特征）
	if "item_name" in zone:
		return true
	# 方式3: 父节点是 PickupItem 类型
	var parent = zone.get_parent()
	if parent and parent.is_in_group("pickup"):
		return true
	return false


# ============================================================
# NPC 交互
# ============================================================

func _update_closest_npc() -> void:
	var closest: Node2D = null
	var closest_dist: float = INF

	for npc in _nearby_npcs:
		var dist = global_position.distance_to(npc.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = npc

	if _closest_npc != closest:
		# 隐藏旧最近NPC的提示
		if _closest_npc and _closest_npc.has_method("hide_interact_hint"):
			_closest_npc.hide_interact_hint()
		# 显示新最近NPC的提示
		if closest and closest.has_method("show_interact_hint"):
			closest.show_interact_hint()
		_closest_npc = closest

	# 更新交互提示显示
	_update_interact_hint()


func _interact_with_nearest_npc() -> void:
	if _closest_npc == null:
		return

	if _closest_npc.has_method("start_dialogue"):
		var greeting = ""
		# 优先使用动态开场白（基于颜色激活状态）
		if _closest_npc.has_method("get_greeting"):
			greeting = _closest_npc.get_greeting()
		elif _closest_npc.has_method("get_fallback_response"):
			greeting = _closest_npc.get_fallback_response()

		print("[Player] 与 %s 对话" % _closest_npc.npc_name)
		ChatDialogue.open(_closest_npc, greeting)
		_closest_npc.start_dialogue()


## 获取最近的NPC（供UI/HUD使用，显示"[E] 交谈"提示）
func get_closest_npc() -> Node2D:
	return _closest_npc


# ============================================================
# 可交互物件（日晷等）
# ============================================================

func _update_closest_interactable() -> void:
	var closest: Node2D = null
	var closest_dist: float = INF

	for obj in _nearby_interactables:
		if not is_instance_valid(obj):
			continue
		var dist = global_position.distance_to(obj.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = obj

	_closest_interactable = closest
	_update_interact_hint()


func _interact_with_interactable(obj: Node2D) -> void:
	if not is_instance_valid(obj):
		return

	# 优先调用对象的 interact 方法
	if obj.has_method("interact"):
		obj.interact()
		print("[Player] 与 %s 交互 (interact)" % obj.name)
		return

	# 其次发送 interacted 信号
	if obj.has_signal("interacted"):
		obj.interacted.emit()
		print("[Player] 触发 %s 的 interacted 信号" % obj.name)
		return

	# 默认行为：发送交互信号
	print("[Player] 与 %s 交互（默认）" % obj.name)


# ============================================================
# 可拾取物品交互
# ============================================================

func _update_closest_pickup() -> void:
	var closest: Area2D = null
	var closest_dist: float = INF

	for pickup in _nearby_pickups:
		if not is_instance_valid(pickup):
			continue
		var dist = global_position.distance_to(pickup.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = pickup

	if _closest_pickup != closest:
		_closest_pickup = closest

	# 更新交互提示显示
	_update_interact_hint()


func _interact_with_pickup(pickup: Area2D) -> void:
	if not is_instance_valid(pickup) or pickup.is_queued_for_deletion():
		_closest_pickup = null
		return

	# 优先调用 PickupItem 自身的 _pickup() 方法（pickup_item.gd）
	if pickup.has_method("_pickup"):
		var pname: String = pickup.item_name if "item_name" in pickup else "物品"
		pickup._pickup()
		print("[Player] 拾取物品: %s" % pname)
		return

	# 降级：手动通过 InventoryManager 拾取
	if "item_id" in pickup:
		var item_id: int = pickup.item_id
		var pname: String = pickup.item_name if "item_name" in pickup else "物品"
		if InventoryManager.add_item(item_id):
			print("[Player] 拾取物品: %s (id=%d)" % [pname, item_id])
			pickup.queue_free()
		return

	# 检查父节点（某些物品 Area2D 是子节点）
	var parent = pickup.get_parent()
	if parent and is_instance_valid(parent) and parent.has_method("_pickup"):
		parent._pickup()
		print("[Player] 通过父节点拾取物品: %s" % parent.name)
		return


# ============================================================
# 通用交互（其他可交互对象）
# ============================================================

func _try_generic_interact() -> void:
	## 当附近没有 NPC 和 pickup 时，尝试向场景中的可交互对象发送交互信号
	# 查找 _interaction_area 范围内所有重叠的 Area2D
	if not _interaction_area:
		return

	var overlapping_areas = _interaction_area.get_overlapping_areas()
	for area in overlapping_areas:
		if not is_instance_valid(area):
			continue
		var parent = area.get_parent()

		# 跳过已处理的 NPC 和 pickup
		if parent and parent.has_method("start_dialogue"):
			continue
		if _is_pickup_item(area):
			continue

		# 通用交互：检查对象是否有 interact 方法或信号
		if parent and parent.has_method("interact"):
			parent.interact(self)
			print("[Player] 与 %s 交互 (interact)" % parent.name)
			return
		if parent and parent.has_signal("interacted"):
			parent.interacted.emit(self)
			print("[Player] 触发 %s 的 interacted 信号" % parent.name)
			return
		if area.has_method("interact"):
			area.interact(self)
			print("[Player] 与 %s 交互 (interact)" % area.name)
			return


# ============================================================
# 交互提示 UI 更新
# ============================================================

## 定期清理已回收（queue_free）的 NPC / pickup 引用
func _cleanup_nearby_lists() -> void:
	var needs_update: bool = false

	# 清理已失效的 NPC 引用
	var valid_npcs: Array[Node2D] = []
	for npc in _nearby_npcs:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion():
			valid_npcs.append(npc)
	if valid_npcs.size() != _nearby_npcs.size():
		_nearby_npcs = valid_npcs
		needs_update = true

	# 清理已失效的物品引用
	var valid_pickups: Array[Area2D] = []
	for pickup in _nearby_pickups:
		if is_instance_valid(pickup) and not pickup.is_queued_for_deletion():
			valid_pickups.append(pickup)
	if valid_pickups.size() != _nearby_pickups.size():
		_nearby_pickups = valid_pickups
		needs_update = true

	# 清理已失效的可交互物件引用
	var valid_interactables: Array[Node2D] = []
	for obj in _nearby_interactables:
		if is_instance_valid(obj) and not obj.is_queued_for_deletion():
			valid_interactables.append(obj)
	if valid_interactables.size() != _nearby_interactables.size():
		_nearby_interactables = valid_interactables
		needs_update = true

	# 检查最近目标是否失效
	if _closest_npc and (not is_instance_valid(_closest_npc) or _closest_npc.is_queued_for_deletion()):
		_closest_npc = null
		needs_update = true
	if _closest_interactable and (not is_instance_valid(_closest_interactable) or _closest_interactable.is_queued_for_deletion()):
		_closest_interactable = null
		needs_update = true
	if _closest_pickup and (not is_instance_valid(_closest_pickup) or _closest_pickup.is_queued_for_deletion()):
		_closest_pickup = null
		needs_update = true

	if needs_update:
		_update_closest_npc()
		_update_closest_interactable()
		_update_closest_pickup()
		_update_interact_hint()

func _update_interact_hint() -> void:
	## 根据最近的交互目标更新提示标签，通过信号通知 HUD
	# 优先级：NPC > 可交互物件 > 物品
	if _closest_npc:
		# NPC 的提示由 _update_closest_npc 管理（show_interact_hint / hide_interact_hint）
		pass
	elif _closest_interactable and is_instance_valid(_closest_interactable) and not _closest_interactable.is_queued_for_deletion():
		interact_hint_changed.emit(true, "[E] 观察 %s" % _closest_interactable.name)
	elif _closest_pickup and is_instance_valid(_closest_pickup) and not _closest_pickup.is_queued_for_deletion():
		var item_name_str: String = _closest_pickup.item_name if "item_name" in _closest_pickup else "物品"
		interact_hint_changed.emit(true, "[E] 拾取 %s" % item_name_str)
	else:
		interact_hint_changed.emit(false, "")


# ============================================================
# 视觉动画
# ============================================================

## 生成脚底圆形阴影纹理并应用到 Shadow Sprite2D
func _setup_shadow() -> void:
	if not _shadow_sprite:
		return

	var size: int = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: float = size / 2.0
	var radius: float = center - 2

	for y in size:
		for x in size:
			var dist = Vector2(x - center, y - center).length()
			var alpha: float = 0.0
			if dist < radius:
				# 中心 50% 不透明，边缘渐变到透明
				alpha = max(0.0, 1.0 - dist / radius) * 0.5
			image.set_pixel(x, y, Color(0, 0, 0, alpha))

	_shadow_sprite.texture = ImageTexture.create_from_image(image)
	_shadow_sprite.scale = Vector2(0.7, 0.7)
	_shadow_sprite.position = Vector2(0, -4)
	print("[PlayerController] 圆形阴影已生成")


## 检测水平输入方向变化（A↔D），触发镜像翻转动画
func _detect_flip(h_input: float) -> void:
	if _is_flipping or h_input == 0.0:
		return

	var new_facing_right: bool = h_input > 0.0
	if new_facing_right != _facing_right:
		_start_flip(new_facing_right)


## 启动镜像翻转 Tween 动画
func _start_flip(to_right: bool) -> void:
	_facing_right = to_right
	_is_flipping = true

	# 目标 scale.x：0.5 = 朝右，-0.5 = 朝左（镜像）
	var target_x: float = 0.5 if to_right else -0.5

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)  # 轻微过冲 → 弹性翻转效果
	tween.tween_property(_visual_sprite, "scale:x", target_x, FLIP_DURATION)
	tween.tween_callback(func(): _is_flipping = false)


## 更新走路左右摇摆（正弦振荡 rotation）
func _update_sway(delta: float, is_moving: bool) -> void:
	if is_moving:
		_sway_time += delta * SWAY_SPEED
		_visual_root.rotation_degrees = sin(_sway_time) * SWAY_AMPLITUDE
	else:
		_settle_sway(delta)


## 静止时摇摆逐渐归零
func _settle_sway(delta: float) -> void:
	_visual_root.rotation_degrees = lerpf(_visual_root.rotation_degrees, 0.0, delta * 6.0)


# ============================================================
# DEBUG: RAG 检索器测试
# ============================================================

func _debug_test_rag() -> void:
	if not _closest_npc:
		print("[DEBUG] 附近无NPC")
		return

	var npc = _closest_npc
	if npc.npc_kb_id == "":
		print("[DEBUG] %s 没有kb_id，跳过RAG测试" % npc.npc_name)
		return

	print("")
	print("╔" + "═".repeat(58) + "╗")
	print("║  RAG 检索器测试 — %s (%s)" % [npc.npc_name, npc.npc_kb_id])
	print("╚" + "═".repeat(58) + "╝")

	# 测试不同输入场景
	var test_inputs = [
		"你好",
		"你在这里多久了？",
		"火为什么烧不起来？",
		"你还记得那天发生了什么吗？",
		"你是NPC吗？这是游戏吗？",
		"老唐最近怎么样？"
	]

	# 获取当前游戏状态
	var state = {}
	if npc.has_method("_collect_game_state"):
		state = npc._collect_game_state()

	for input_text in test_inputs:
		print("")
		print("─".repeat(40))
		print("  玩家: \"%s\"" % input_text)
		print("─".repeat(40))
		NPCRagRetriever.debug_print_retrieval(npc.npc_kb_id, input_text, state)
