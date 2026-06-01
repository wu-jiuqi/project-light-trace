extends Node
## 碎片 #0762 游戏状态管理器
## 所有颜色状态委托给 GameManager（全局单例，跨场景共享）

# 别名：方便 NPC 通过 group 找到 fragment_state
# 实际数据在 GameManager 中

func awaken_color(color_type: int) -> void:
	GameManager.awaken_color(color_type)

func is_color_awakened(color_type: int) -> bool:
	return GameManager.is_color_awakened(color_type)

func _count_awakened() -> int:
	return GameManager._count_awakened()

func record_npc_visit(npc_kb_id: String) -> void:
	GameManager.record_npc_visit(npc_kb_id)

func get_visit_count(npc_kb_id: String) -> int:
	return GameManager.get_visit_count(npc_kb_id)

# ============================================================
# 六色触发条件检查
# ============================================================

func check_trigger(npc_kb_id: String, _msg: String = "") -> bool:
	if npc_kb_id == "blacksmith": return _check_red()
	if npc_kb_id == "florist": return _check_blue()
	if npc_kb_id == "baker": return _check_yellow()
	if npc_kb_id == "gravekeeper": return _check_green()
	if npc_kb_id == "violinist": return _check_purple()
	return false

func _check_red() -> bool:
	if is_color_awakened(GameManager.ColorType.RED): return false
	if not InventoryManager.has_item(InventoryManager.ItemID.FORGE_LOG): return false
	awaken_color(GameManager.ColorType.RED)
	InventoryManager.remove_item(InventoryManager.ItemID.FORGE_LOG)
	GameManager.mark_item_used("forge_log")
	InventoryManager.add_item(InventoryManager.ItemID.FIRE_SEED)
	return true

func _check_blue() -> bool:
	if is_color_awakened(GameManager.ColorType.BLUE): return false
	if not InventoryManager.has_item(InventoryManager.ItemID.CORNFLOWER): return false
	awaken_color(GameManager.ColorType.BLUE)
	InventoryManager.remove_item(InventoryManager.ItemID.CORNFLOWER)
	GameManager.mark_item_used("cornflower")
	return true

func _check_yellow() -> bool:
	if is_color_awakened(GameManager.ColorType.YELLOW): return false
	if not is_color_awakened(GameManager.ColorType.RED): return false
	if not InventoryManager.has_item(InventoryManager.ItemID.FIRE_SEED): return false
	awaken_color(GameManager.ColorType.YELLOW)
	InventoryManager.remove_item(InventoryManager.ItemID.FIRE_SEED)
	return true

func _check_green() -> bool:
	if is_color_awakened(GameManager.ColorType.GREEN): return false
	if _count_awakened() < 3: return false
	if get_visit_count("gravekeeper") < 3: return false
	awaken_color(GameManager.ColorType.GREEN)
	return true

func _check_purple() -> bool:
	if is_color_awakened(GameManager.ColorType.PURPLE): return false
	if _count_awakened() < 4: return false
	if not GameManager.melody_triggered: return false  # 需要老画家的旋律（全局状态）
	awaken_color(GameManager.ColorType.PURPLE)
	return true

func _check_white() -> bool:
	## 白色不再自动解锁
	## 改为：五色集齐后，玩家与老画家交互时解锁
	if is_color_awakened(GameManager.ColorType.WHITE): return false
	if _count_awakened() < 5: return false
	# 不自动觉醒，只标记 white_ready
	GameManager.white_ready = true
	print("[FragmentState] 五色已集齐，白色等待老画家解锁")
	return false

func check_global() -> void:
	## 五色集齐后标记 white_ready，不再自动解锁白色
	if _count_awakened() >= 5 and not GameManager.white_ready:
		GameManager.white_ready = true
		print("[FragmentState] 五色已集齐——白色可由老画家解锁")

func try_unlock_white_from_painter() -> bool:
	## 老画家交互时调用：五色集齐后解锁白色
	if is_color_awakened(GameManager.ColorType.WHITE): return false
	if _count_awakened() < 5: return false
	awaken_color(GameManager.ColorType.WHITE)
	GameManager.white_ready = false  # 已消费

	# 如果画室灰布已存在，更新标签为可交互
	var root = get_parent()
	if root and root.name == "Studio":
		var cloth = root.get_node_or_null("GrayCloth")
		if cloth:
			var label = cloth.get_node_or_null("ClothLabel")
			if label:
				label.text = "[E] 揭开灰布"

	print("[FragmentState] 白色觉醒——老画家引导完成")
	return true

# ============================================================
# memory_stage 映射
# ============================================================

func get_memory_stage() -> String:
	var c = _count_awakened()
	if c == 0: return "initial"
	if c <= 3: return "partial_awake"
	if c <= 5: return "advanced_awake"
	return "full_awake"

func get_npc_memory_stage(npc_id: String) -> String:
	var base = get_memory_stage()
	var color_awake = false
	if npc_id == "blacksmith": color_awake = GameManager.awakened_colors[GameManager.ColorType.RED]
	elif npc_id == "florist": color_awake = GameManager.awakened_colors[GameManager.ColorType.BLUE]
	elif npc_id == "baker": color_awake = GameManager.awakened_colors[GameManager.ColorType.YELLOW]
	elif npc_id == "gravekeeper": color_awake = GameManager.awakened_colors[GameManager.ColorType.GREEN]
	elif npc_id == "violinist": color_awake = GameManager.awakened_colors[GameManager.ColorType.PURPLE]
	if color_awake and base in ["initial", "partial_awake"]:
		if npc_id == "blacksmith": return "red_awakened"
		elif npc_id == "florist": return "blue_awakened"
		elif npc_id == "baker": return "yellow_awakened"
		elif npc_id == "gravekeeper": return "green_awakened"
		elif npc_id == "violinist": return "purple_awakened"
	return base

signal trust_changed(npc_id: String, val: float, delta: float)

func modify_trust(_id: String, delta: float) -> void:
	GameManager.oldpainter_trust = clampf(GameManager.oldpainter_trust + delta, -100, 100)
	trust_changed.emit("oldpainter", GameManager.oldpainter_trust, delta)

func get_trust(_id: String) -> float:
	return GameManager.oldpainter_trust

func get_game_state(npc_id: String = "") -> Dictionary:
	var stage = get_npc_memory_stage(npc_id) if npc_id != "" else get_memory_stage()
	return { "memory_stage":stage, "alert_level":0, "trust_level":int(get_trust(npc_id)), "awakened_colors":GameManager.awakened_colors.duplicate(), "awakened_count":_count_awakened() }

# ============================================================
# 拾取物品初始化（场景加载时）
# ============================================================

func _ready() -> void:
	add_to_group("fragment_state")
	print("[FragmentState] 碎片0762就绪 (已觉醒: %d/6)" % _count_awakened())
	await get_tree().process_frame
	_init_room_pickup()

func _init_room_pickup() -> void:
	var root = get_parent()
	if root == null: return
	var rn = root.name

	if rn == "Square":
		# 广场不再自动出现源印
		# 源印改在画室自画像处，由玩家揭灰布后显现
		pass

	elif rn == "Studio":
		# 老画家：检查是否需要触发旋律（4色觉醒后）
		if _count_awakened() >= 4:
			_trigger_oldpainter_melody()

		# 画室场景初始化：根据进度创建灰布或源印
		var white_awake = GameManager.is_color_awakened(GameManager.ColorType.WHITE)

		if white_awake and not GameManager.gray_cloth_uncovered:
			# 白色已觉醒但灰布未揭 → 创建灰布（等待玩家揭开）
			_create_gray_cloth()
		elif white_awake and GameManager.gray_cloth_uncovered:
			# 灰布已揭 → 直接创建源印
			_create_studio_source_mark()
		elif GameManager.white_ready and not GameManager.gray_cloth_uncovered:
			# 五色集齐但白色未解锁 → 老画家会引导，但灰布要先准备好
			_create_gray_cloth()


# ============================================================
# 老画家老顾逻辑
# ============================================================

var _near_source_mark: bool = false
var _near_gray_cloth: bool = false

func get_oldpainter_hint() -> String:
	## 根据当前觉醒进度和信任度，返回老画家的提示
	var c = _count_awakened()
	var trust = int(GameManager.oldpainter_trust)
	if c < 1: return "先去看那些颜色。不是我的颜色——是他们的。"
	if c < 3: return "颜色们在互相寻找对方——只是他们还不会说话。帮他们说吧。"
	if c < 4: return "还差一点。那个整天对着面包笑的——他需要火。"
	if c < 5:
		var bonus = "。你在广场上看到那个拉琴的了吗？她听的曲子不在琴里。" if trust < 0 else "。去找拉琴的——她需要一段旋律。但你得先让我想起它。"
		return "四种颜色已经回来了。快了" + bonus
	if not GameManager.is_color_awakened(GameManager.ColorType.WHITE):
		# 五色集齐但白色未解锁 → 引导玩家来画室
		return "五种颜色……还差最后一种。来我的画室——角落里有一幅画。它被灰布盖着很多年了。也许该是你揭开的时候了。"
	return "六色全齐了。去画室角落——那幅自画像的灰布下面。它一直在等你。"

func _trigger_oldpainter_melody() -> void:
	## 4色觉醒后，老画家哼出旋律，为紫色触发做准备
	if GameManager.melody_triggered: return
	GameManager.melody_triggered = true
	print("[OldPainter] 老画家哼出了旋律——紫色触发条件已解锁")


func _create_gray_cloth() -> void:
	## 在Studio场景创建被灰布覆盖的自画像
	var root = get_parent()
	if root == null or root.name != "Studio": return

	# 检查是否已存在
	if root.get_node_or_null("GrayCloth"): return

	# 先创建一个"自画像"背景（画框）
	var portrait_frame = ColorRect.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.offset_left = -40; portrait_frame.offset_top = -55
	portrait_frame.offset_right = 40; portrait_frame.offset_bottom = 55
	portrait_frame.color = Color(0.25, 0.2, 0.15, 0.9)  # 深棕色画框
	var frame_node = Node2D.new()
	frame_node.name = "PortraitNode"
	frame_node.position = Vector2(340, 180)
	frame_node.add_child(portrait_frame)
	root.add_child(frame_node)

	# 创建灰布 Area2D（覆盖在自画像上）
	var cloth = Area2D.new()
	cloth.name = "GrayCloth"
	cloth.position = Vector2(340, 180)

	var s = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(85, 115)
	s.shape = rect
	cloth.add_child(s)

	# 视觉：灰布
	var visual = ColorRect.new()
	visual.name = "ClothVisual"
	visual.offset_left = -42; visual.offset_top = -57
	visual.offset_right = 42; visual.offset_bottom = 57
	visual.color = Color(0.45, 0.45, 0.45, 0.92)  # 灰色布料
	cloth.add_child(visual)

	# 标签
	var label = Label.new()
	label.name = "ClothLabel"
	label.position = Vector2(-45, 60)
	label.size = Vector2(90, 24)
	label.text = "一幅被灰布盖住的画"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
	label.add_theme_font_size_override("font_size", 10)
	cloth.add_child(label)

	cloth.body_entered.connect(_on_gray_cloth_entered)
	cloth.body_exited.connect(_on_gray_cloth_exited)
	cloth.collision_layer = 0
	cloth.collision_mask = 1

	root.add_child(cloth)
	print("[GrayCloth] 灰布已覆盖自画像 (340,180)")

	# 如果白色已觉醒，更新标签提示
	if GameManager.is_color_awakened(GameManager.ColorType.WHITE):
		label.text = "[E] 揭开灰布"


func _on_gray_cloth_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_gray_cloth = true
		var root = get_parent()
		if root:
			var n = root.get_node_or_null("GrayCloth/ClothLabel")
			if n: n.text = "[E] 揭开灰布"


func _on_gray_cloth_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_gray_cloth = false
		var root = get_parent()
		if root:
			var n = root.get_node_or_null("GrayCloth/ClothLabel")
			if n:
				if GameManager.gray_cloth_uncovered:
					n.text = "情感之印"
				else:
					n.text = "一幅被灰布盖住的画"


func _uncover_gray_cloth() -> void:
	## 玩家揭开灰布 → 灰色布料消失 → 源印显现
	var root = get_parent()
	if root == null: return

	_near_gray_cloth = false
	GameManager.gray_cloth_uncovered = true

	# 移除灰布
	var cloth = root.get_node_or_null("GrayCloth")
	if cloth:
		cloth.queue_free()

	print("[GrayCloth] 玩家揭开了灰布——源印显现")

	# 显示揭开动画文字
	_display_uncover_message()

	# 短暂延迟后创建源印
	await get_tree().create_timer(1.0).timeout
	_create_studio_source_mark()


func _display_uncover_message() -> void:
	## 显示揭开灰布后的叙事文字
	var msg = """灰布滑落。

画框中的自画像显露出来——那是老画家的脸，但又不全是。

画中的眼睛不是灰色的。

六种颜色在瞳孔深处旋转，形成一个熟悉的符号。

「情感之印」——她留在这个碎片里的签名。"""
	ChatDialogue.add_npc_msg(msg)


func _create_studio_source_mark() -> void:
	## 在Studio场景的画框位置创建可交互的源印
	var root = get_parent()
	if root == null or root.name != "Studio": return

	# 检查是否已存在
	if root.get_node_or_null("SourceMark"): return

	# 创建源印 Area2D（在自画像位置）
	var mark = Area2D.new()
	mark.name = "SourceMark"
	mark.position = Vector2(340, 180)

	var s = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30
	s.shape = circle
	mark.add_child(s)

	# 视觉：六色旋转发光效果（简化为白色发光圆）
	var visual = ColorRect.new()
	visual.name = "MarkVisual"
	visual.offset_left = -28; visual.offset_top = -28
	visual.offset_right = 28; visual.offset_bottom = 28
	visual.color = Color(1, 1, 1, 0.9)
	mark.add_child(visual)

	# 标签
	var label = Label.new()
	label.name = "MarkLabel"
	label.position = Vector2(-40, 35)
	label.size = Vector2(80, 20)
	label.text = "情感之印"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 0.9))
	label.add_theme_font_size_override("font_size", 10)
	mark.add_child(label)

	mark.body_entered.connect(_on_source_mark_entered)
	mark.body_exited.connect(_on_source_mark_exited)
	mark.collision_layer = 0
	mark.collision_mask = 1

	root.add_child(mark)
	GameManager.source_mark_revealed = true
	print("[SourceMark] 源印「情感之印」已在画室自画像中显现")


func _on_source_mark_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_source_mark = true
		var n = get_parent().get_node_or_null("SourceMark/MarkLabel")
		if n: n.text = "[E] 解码源印"

func _on_source_mark_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_source_mark = false
		var n = get_parent().get_node_or_null("SourceMark/MarkLabel")
		if n: n.text = "情感之印"

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if _near_source_mark:
			_decode_source_mark()
		elif _near_gray_cloth:
			_uncover_gray_cloth()

func _decode_source_mark() -> void:
	## 解码源印 → 触发胜利序列
	_near_source_mark = false
	print("[SourceMark] 源印解码开始")

	# 记录源印
	var root = get_parent()
	if root:
		var mark = root.get_node_or_null("SourceMark")
		if mark:
			var label = mark.get_node_or_null("MarkLabel")
			if label: label.text = "解码中..."

	await get_tree().create_timer(1.5).timeout

	# 触发胜利
	_trigger_victory()

func _trigger_victory() -> void:
	## 游戏胜利序列
	print("═══════════════════════════════════════")
	print("  [Fragment 0762] 颜色的葬礼 — 完成")
	print("  六色齐聚 · 源印解码")
	print("═══════════════════════════════════════")

	# 通过 ChatDialogue 显示胜利信息（如果没打开也会作为系统消息显示）
	var victory_text = """六种颜色在广场汇聚。

红色不再愤怒——它在铁砧上找到了温度。
蓝色不再悲伤——它在花瓣上记起了一个名字。
黄色不再等待——它在面包的香气里重新定义了明天。
绿色不再恐惧——它在裂痕的边缘看到了光。
紫色不再沉默——它在一段旋律的延长音里学会了想念。
白色——白色是所有遗忘的终结。

六色齐聚之处，源印显现。

「情感之印」——她留下的签名。

你不是在收集颜色。你是在帮她把自己拼回来。"""

	ChatDialogue.add_npc_msg(victory_text)

	await get_tree().create_timer(2.0).timeout

	# === 修复进度防护：检查碎片是否已标记为完成 ===
	var was_completed = GameManager.fragment_completed
	if FragmentManager.current_fragment and FragmentManager.current_fragment.decrypt_state == FragmentManager.DecryptState.COMPLETED:
		was_completed = true

	if was_completed:
		# 重玩模式：不增加修复进度
		print("[Fragment 0762] 碎片已完成，重玩模式 — 不增加修复进度")
		ChatDialogue.add_npc_msg("[回忆] 你再次见证了六色的汇聚。\n\n记忆不会因为重复而变得更完整——但重温它，也许能让你看到之前错过的东西。")
		await get_tree().create_timer(2.0).timeout
		FragmentManager.complete_fragment(FragmentManager.current_fragment)
		get_tree().change_scene_to_file("res://scenes/star_map.tscn")
		return

	# 首次完成：标记 fragment 完成 + 记录源印 + 增加修复进度
	FragmentManager.complete_fragment(FragmentManager.current_fragment)
	GameManager.record_source_mark(
		FragmentManager.current_fragment.id,
		"情感之印",
		"颜色是记忆的容器——她把自己的情感打碎藏进了六个不会互相说话的人里"
	)
	GameManager.fragment_completed = true
	SaveManager.save_game()

	# 返回星图
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")
