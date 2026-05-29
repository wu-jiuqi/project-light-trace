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
	InventoryManager.add_item(InventoryManager.ItemID.FIRE_SEED)
	return true

func _check_blue() -> bool:
	if is_color_awakened(GameManager.ColorType.BLUE): return false
	if not InventoryManager.has_item(InventoryManager.ItemID.CORNFLOWER): return false
	awaken_color(GameManager.ColorType.BLUE)
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
	if is_color_awakened(GameManager.ColorType.WHITE): return false
	if _count_awakened() < 5: return false
	awaken_color(GameManager.ColorType.WHITE)
	# 白色觉醒后：源印在广场出现
	# 玩家需要去广场 → FragmentState 的 _ready() 检测到 6色 后 _create_source_mark()
	return true

func check_global() -> void: _check_white()

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

var npc_alerts = { "blacksmith":0,"florist":0,"baker":0,"gravekeeper":0,"violinist":0,"oldpainter":0 }
var oldpainter_trust: float = 0.0
signal alert_changed(npc_id: String, val: float, delta: float)
signal trust_changed(npc_id: String, val: float, delta: float)

func modify_alert(npc_id: String, delta: float) -> void:
	if not npc_alerts.has(npc_id): return
	var v = npc_alerts[npc_id]; npc_alerts[npc_id] = clampf(v + delta, 0, 100)
	if npc_alerts[npc_id] != v: alert_changed.emit(npc_id, npc_alerts[npc_id], delta)

func get_alert(npc_id: String) -> float: return npc_alerts.get(npc_id, 0)
func modify_trust(_id: String, delta: float) -> void: oldpainter_trust = clampf(oldpainter_trust + delta, -100, 100); trust_changed.emit("oldpainter", oldpainter_trust, delta)
func get_trust(_id: String) -> float: return oldpainter_trust

func get_game_state(npc_id: String = "") -> Dictionary:
	var stage = get_npc_memory_stage(npc_id) if npc_id != "" else get_memory_stage()
	return { "memory_stage":stage, "alert_level":int(get_alert(npc_id)), "trust_level":int(get_trust(npc_id)), "awakened_colors":GameManager.awakened_colors.duplicate(), "awakened_count":_count_awakened() }

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
	var s = load("res://scripts/items/pickup_item.gd")
	var rn = root.name
	
	if rn == "Townhall":
		var n = root.get_node_or_null("ForgeLog")
		if n == null: return
		if InventoryManager.has_item(InventoryManager.ItemID.FORGE_LOG):
			n.queue_free(); print("[PickupInit] 铸造日志: 已收集，移除"); return
		if n is Area2D and n.get_script() == null:
			n.set_script(s)
			n.item_id = 0; n.item_name = "铸造日志"
			n.item_color = Color(0.9, 0.3, 0.3, 1); n.item_pos_x = 550.0; n.item_pos_y = 400.0
			n._ready()
			print("[PickupInit] 铸造日志 就绪")
	
	elif rn == "Market":
		var n = root.get_node_or_null("Cornflower")
		if n == null: return
		if InventoryManager.has_item(InventoryManager.ItemID.CORNFLOWER):
			n.queue_free(); print("[PickupInit] 矢车菊: 已收集，移除"); return
		print("[PickupInit] 矢车菊 已配置 (tscn)")
	
	elif rn == "Square":
		# 检查是否应该显示源印（6色觉醒后）
		if _count_awakened() >= 6 or GameManager.is_color_awakened(GameManager.ColorType.WHITE):
			_create_source_mark()
	
	elif rn == "Studio":
		# 老画家：检查是否需要触发旋律（4色觉醒后）
		if _count_awakened() >= 4:
			_trigger_oldpainter_melody()


# ============================================================
# 老画家老顾逻辑
# ============================================================

var _near_source_mark: bool = false

func get_oldpainter_hint() -> String:
	## 根据当前觉醒进度和信任度，返回老画家的提示
	var c = _count_awakened()
	var trust = int(oldpainter_trust)
	if c < 1: return "先去看那些颜色。不是我的颜色——是他们的。"
	if c < 3: return "颜色们在互相寻找对方——只是他们还不会说话。帮他们说吧。"
	if c < 4: return "还差一点。那个整天对着面包笑的——他需要火。"
	if c < 5:
		var bonus = "。你在广场上看到那个拉琴的了吗？她听的曲子不在琴里。" if trust < 0 else "。去找拉琴的——她需要一段旋律。但你得先让我想起它。"
		return "四种颜色已经回来了。快了" + bonus
	if c < 6: return "最后一种了——不是我。去广场。那个雕像底下有东西。那是她留给自己的——不，是留给你看的。"
	return "全齐了。去雕像那里——那下面不是空的。那是唯一能证明她来过的东西。"

func _trigger_oldpainter_melody() -> void:
	## 4色觉醒后，老画家哼出旋律，为紫色触发做准备
	if GameManager.melody_triggered: return
	GameManager.melody_triggered = true
	print("[OldPainter] 老画家哼出了旋律——紫色触发条件已解锁")


func _create_source_mark() -> void:
	## 在Square场景创建可交互的源印
	var root = get_parent()
	if root == null or root.name != "Square": return
	
	# 移除纯装饰雕像，换成可交互的源印
	var statue = root.get_node_or_null("Buildings/Statue")
	if statue:
		statue.queue_free()
	
	# 创建源印 Area2D
	var mark = Area2D.new()
	mark.name = "SourceMark"
	mark.position = Vector2(400, 200)
	
	var s = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(60, 80)
	s.shape = rect
	mark.add_child(s)
	
	# 视觉：白色发光六边形
	var visual = ColorRect.new()
	visual.offset_left = -25; visual.offset_top = -35
	visual.offset_right = 25; visual.offset_bottom = 35
	visual.color = Color(1, 1, 1, 0.85)
	mark.add_child(visual)
	
	# 标签
	var label = Label.new()
	label.name = "MarkLabel"
	label.position = Vector2(-40, 42)
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
	mark.set_process(true)
	
	root.add_child(mark)
	GameManager.source_mark_revealed = true
	print("[SourceMark] 源印「情感之印」已在广场显现")


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
	if not _near_source_mark: return
	if Input.is_action_just_pressed("interact"):
		_decode_source_mark()

func _decode_source_mark() -> void:
	## 解码源印 → 触发胜利序列
	_near_source_mark = false
	set_process(false)
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
		ChatDialogue.add_npc_msg("💎 你再次见证了六色的汇聚。\n\n记忆不会因为重复而变得更完整——但重温它，也许能让你看到之前错过的东西。")
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
