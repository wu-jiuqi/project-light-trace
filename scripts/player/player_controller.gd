extends CharacterBody2D
class_name PlayerController
## 玩家移动控制器 + 跨场景出生点自定位 + NPC交互

@export var speed: float = 200.0

## 当前在交互范围内的NPC列表
var _nearby_npcs: Array[Node2D] = []
## 最近的可交互NPC
var _closest_npc: Node2D = null

func _ready() -> void:
	add_to_group("player")
	
	# 俯视角游戏使用 FLOATING 模式，避免地板检测导致NPC被粘在玩家头上
	motion_mode = MOTION_MODE_FLOATING
	
	# 创建交互检测区域
	_create_interaction_detector()

	# 跨场景出生点定位（由 SceneManager 设定）
	var spawn_name = SceneManager.pending_spawn_point
	if not spawn_name.is_empty():
		SceneManager.pending_spawn_point = ""  # 消费掉
		_try_spawn(spawn_name)

	print("[PlayerController] 就绪，速度: %.0f 位置: %s" % [speed, global_position])


func _create_interaction_detector() -> void:
	## 动态创建交互检测Area2D
	var detector = Area2D.new()
	detector.name = "InteractionDetector"
	detector.collision_layer = 0
	detector.collision_mask = 4  # 匹配NPC InteractionZone的layer
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 35.0  # 比NPC交互半径(21)略大
	shape.shape = circle
	detector.add_child(shape)
	
	detector.area_entered.connect(_on_interaction_zone_entered)
	detector.area_exited.connect(_on_interaction_zone_exited)
	
	add_child(detector)


func _try_spawn(spawn_name: String) -> void:
	var root = get_parent()
	if not root:
		return

	var spawns = root.get_node_or_null("SpawnPoints")
	if not spawns:
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


func _physics_process(_delta: float) -> void:
	# 对话或背包打开时锁定移动
	if ChatDialogue.is_open or InventoryManager.backpack_open:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# 对话已打开时不重复触发
		if ChatDialogue.is_open:
			return
		print("══════════ [Player] E键按下 ══════════")
		print("  附近NPC: %d 个 | 最近: %s" % [_nearby_npcs.size(), _closest_npc.npc_name if _closest_npc else "无"])
		_interact_with_nearest_npc()
	
	# DEBUG: F1 测试RAG检索器
	if event.is_action_pressed("ui_focus_next") and OS.is_debug_build():
		_debug_test_rag()


# ============================================================
# NPC 交互
# ============================================================

func _on_interaction_zone_entered(zone: Area2D) -> void:
	var npc = zone.get_parent()
	if npc and npc.has_method("start_dialogue"):
		if npc not in _nearby_npcs:
			_nearby_npcs.append(npc)
			_update_closest_npc()
			print("[Player] 进入 %s 交互范围" % npc.npc_name)


func _on_interaction_zone_exited(zone: Area2D) -> void:
	var npc = zone.get_parent()
	if npc in _nearby_npcs:
		_nearby_npcs.erase(npc)
		_update_closest_npc()
		print("[Player] 离开 %s 交互范围" % npc.npc_name)


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
