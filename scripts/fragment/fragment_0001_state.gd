extends Node2D
## 碎片 #0001「启程之镇」核心玩法原型。
## 仅实现日晷观测、合规度、钟楼校准、源印显现与通关状态流转。

const ClueSystemScript = preload("res://scripts/systems/clue_system.gd")
const NPC_SCENES := {
	"linguide": preload("res://scenes/characters/id0001/npc_linguide.tscn"),
	"chentech": preload("res://scenes/characters/id0001/npc_chentechnology.tscn"),
	"wangdirector": preload("res://scenes/characters/id0001/npc_wangdirector.tscn"),
	"zhaosecurity": preload("res://scenes/characters/id0001/npc_zhaosecurity.tscn"),
}

const OBSERVATION_ORDER := ["A", "B", "C", "D", "E"]
const TARGET_CLOCK_ANGLE := 66
const PLAYER_INTERACT_DISTANCE := 78.0
const Z_BACKGROUND := -100
const Z_ROAD := -80
const Z_BUILDING := -40
const Z_PROP := -10
const Z_LABEL := 30
const Z_CHARACTER := 50
const PHYSICS_OBSTACLE_LAYER := 4
const SUNDIALS := {
	"A": {
		"title": "观测点A · 广场日晷",
		"place": "广场中央喷泉旁",
		"angle": 12,
		"body": "白石日晷投下 12° 阴影。底座编号 TP-2077-03-A。",
		"position": Vector2(420, 322),
		"color": Color(0.92, 0.85, 0.68, 1.0),
	},
	"B": {
		"title": "观测点B · 钟楼日晷",
		"place": "钟楼底部东侧",
		"angle": 24,
		"body": "青铜日晷投下 24° 阴影。氧化铜面上有一道新的手指印。",
		"position": Vector2(650, 432),
		"color": Color(0.60, 0.50, 0.34, 1.0),
	},
	"C": {
		"title": "观测点C · 市集日晷",
		"place": "市集橱窗前",
		"angle": 36,
		"body": "黑石日晷投下 36° 阴影。橱窗里的七个面包排列得一动不动。",
		"position": Vector2(510, 570),
		"color": Color(0.22, 0.21, 0.20, 1.0),
	},
	"D": {
		"title": "观测点D · 研究所日晷",
		"place": "研究所门口",
		"angle": 48,
		"body": "灰岗岩日晷投下 48° 阴影。日晷上方的摄像头没有转动。",
		"position": Vector2(850, 218),
		"color": Color(0.60, 0.62, 0.60, 1.0),
	},
	"E": {
		"title": "观测点E · 边界残晷",
		"place": "边界光墙前",
		"angle": 66,
		"body": "第五个日晷被砸碎了。碎片被整齐排成一条线，像有人替你留下了缺失项。",
		"position": Vector2(970, 104),
		"color": Color(0.84, 0.88, 0.90, 1.0),
	},
}

var player: CharacterBody2D
var clue_system: Node
var interactables: Array[Node2D] = []
var observed_sundials: Dictionary = {}
var compliance := 100
var clock_angle := 12
var source_mark_revealed := false
var completed := false
var _closest: Node2D = null
var _boundary_warning_given := false
var _quiet_time := 0.0
var _intermission_played := false

var hud_status: Label
var hud_objective: Label
var hud_observations: Label
var message_panel: Panel
var message_title: Label
var message_body: Label
var interact_hint: Label
var angle_panel: Panel
var angle_value: Label


func _ready() -> void:
	add_to_group("fragment_state")
	_prepare_fragment_context()
	_bind_player()
	_create_systems()
	_create_world()
	_create_hud()
	_update_hud()
	_show_message(
		"林指导",
		"溯光者，编号确认通过。欢迎来到溯光计划第一阶段训练场。\n先观察五个日晷，记录阴影角度，再回钟楼校准指针。",
		6.0
	)
	print("[Fragment0001] 启程之镇玩法原型就绪")


func _prepare_fragment_context() -> void:
	if FragmentManager.current_fragment == null:
		FragmentManager.current_fragment = FragmentManager.get_fragment_by_id("0001")
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)


func _bind_player() -> void:
	player = get_node_or_null("Player")
	if player == null:
		printerr("[Fragment0001] 场景缺少 Player")
		return
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	player.z_index = Z_CHARACTER
	player.collision_mask = 15
	player.collision_layer = 1
	if player.get_node_or_null("Camera2D") == null:
		var camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1280
		camera.limit_bottom = 720
		player.add_child(camera)


func _create_systems() -> void:
	clue_system = ClueSystemScript.new()
	clue_system.name = "ClueSystem0001"
	add_child(clue_system)


func _create_world() -> void:
	var bg = ColorRect.new()
	bg.name = "PaperDawnBG"
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.78, 0.74, 0.64, 1.0)
	bg.z_index = Z_BACKGROUND
	add_child(bg)
	move_child(bg, 0)

	_create_world_bounds()

	_create_rect("NorthRoad", Vector2(210, 86), Vector2(860, 54), Color(0.72, 0.68, 0.58, 1.0), "", Z_ROAD)
	_create_rect("CenterRoad", Vector2(250, 332), Vector2(760, 64), Color(0.68, 0.65, 0.56, 1.0), "", Z_ROAD)
	_create_rect("SouthRoad", Vector2(290, 560), Vector2(600, 56), Color(0.67, 0.61, 0.53, 1.0), "", Z_ROAD)
	_create_rect("VerticalRoad", Vector2(612, 80), Vector2(62, 540), Color(0.70, 0.66, 0.56, 1.0), "", Z_ROAD)

	_create_rect("AdminCenter", Vector2(760, 300), Vector2(190, 88), Color(0.54, 0.66, 0.72, 1.0), "行政中心", Z_BUILDING, true)
	_create_rect("Lab", Vector2(305, 428), Vector2(190, 86), Color(0.76, 0.78, 0.76, 1.0), "解密实验室", Z_BUILDING, true)
	_create_rect("Market", Vector2(390, 612), Vector2(245, 54), Color(0.74, 0.54, 0.42, 1.0), "市集", Z_BUILDING, true)
	_create_rect("ClockTower", Vector2(616, 352), Vector2(100, 138), Color(0.48, 0.43, 0.36, 1.0), "钟楼\n06:12", Z_BUILDING, true)
	_create_rect("BoundaryWall", Vector2(220, 54), Vector2(850, 18), Color(0.18, 0.62, 0.95, 0.62), "边界光墙", Z_PROP, true)

	_create_interactable("linguide", "npc", "林指导", Vector2(356, 300), Color(0.34, 0.54, 0.82, 1.0))
	_create_interactable("chentech", "npc", "陈技术", Vector2(342, 410), Color(0.87, 0.88, 0.84, 1.0))
	_create_interactable("wangdirector", "npc", "王主管", Vector2(812, 292), Color(0.18, 0.36, 0.58, 1.0))
	_create_interactable("zhaosecurity", "npc", "赵安保", Vector2(1036, 138), Color(0.22, 0.25, 0.28, 1.0))
	_create_interactable("clock_console", "clock", "钟楼观测台", Vector2(650, 360), Color(0.95, 0.70, 0.34, 1.0))
	_create_interactable("boundary", "boundary", "触碰光墙", Vector2(990, 72), Color(0.25, 0.78, 1.0, 0.9))

	for key in OBSERVATION_ORDER:
		var data = SUNDIALS[key]
		_create_sundial(key, data)

	# TODO: 正式美术接入时，将建筑、道路和日晷占位替换为纸工资源。


func _create_rect(node_name: String, pos: Vector2, size: Vector2, color: Color, label_text: String = "", z: int = 0, has_collision: bool = false) -> ColorRect:
	var rect = ColorRect.new()
	rect.name = node_name
	rect.position = pos
	rect.size = size
	rect.color = color
	rect.z_index = z
	add_child(rect)
	if has_collision:
		_create_collision_rect("%sCollision" % node_name, pos, size)
	if label_text != "":
		var label = Label.new()
		label.position = Vector2(8, 8)
		label.size = size - Vector2(16, 16)
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(0.12, 0.11, 0.10, 1.0))
		label.add_theme_font_size_override("font_size", 15)
		label.z_index = Z_LABEL
		rect.add_child(label)
	return rect


func _create_world_bounds() -> void:
	_create_collision_rect("WorldBoundTop", Vector2(-32, -32), Vector2(1344, 32))
	_create_collision_rect("WorldBoundBottom", Vector2(-32, 720), Vector2(1344, 32))
	_create_collision_rect("WorldBoundLeft", Vector2(-32, -32), Vector2(32, 784))
	_create_collision_rect("WorldBoundRight", Vector2(1280, -32), Vector2(32, 784))


func _create_collision_rect(node_name: String, pos: Vector2, size: Vector2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.name = node_name
	body.position = pos + size * 0.5
	body.collision_layer = PHYSICS_OBSTACLE_LAYER
	body.collision_mask = 1
	add_child(body)

	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	shape.shape = rect_shape
	body.add_child(shape)
	return body


func _create_interactable(id: String, kind: String, title: String, pos: Vector2, color: Color) -> Node2D:
	var node: Node2D
	if kind == "npc" and NPC_SCENES.has(id):
		node = NPC_SCENES[id].instantiate() as Node2D
	else:
		node = Node2D.new()
	node.name = "Interact_%s" % id
	node.position = pos
	node.z_index = Z_CHARACTER if kind == "npc" else Z_PROP
	node.set_meta("id", id)
	node.set_meta("kind", kind)
	node.set_meta("title", title)
	node.set_meta("radius", PLAYER_INTERACT_DISTANCE)
	add_child(node)
	interactables.append(node)

	if kind != "npc":
		var body = ColorRect.new()
		body.position = Vector2(-18, -24)
		body.size = Vector2(36, 48)
		body.color = color
		node.add_child(body)
		_create_collision_rect("%sBodyCollision" % node.name, pos + body.position, body.size)

	var label = Label.new()
	label.position = Vector2(-58, 6 if kind == "npc" else 28)
	label.size = Vector2(116, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = title
	label.add_theme_color_override("font_color", Color(0.10, 0.09, 0.08, 1.0))
	label.add_theme_font_size_override("font_size", 12)
	label.z_index = Z_LABEL
	node.add_child(label)
	return node


func _create_sundial(id: String, data: Dictionary) -> Node2D:
	var node = Node2D.new()
	node.name = "Sundial_%s" % id
	node.position = data["position"]
	node.z_index = Z_PROP
	node.set_meta("id", id)
	node.set_meta("kind", "sundial")
	node.set_meta("title", data["title"])
	node.set_meta("radius", PLAYER_INTERACT_DISTANCE)
	add_child(node)
	interactables.append(node)

	var plate = ColorRect.new()
	plate.position = Vector2(-24, -14)
	plate.size = Vector2(48, 28)
	plate.color = data["color"]
	node.add_child(plate)
	_create_collision_rect("%sCollision" % node.name, data["position"] + plate.position, plate.size)

	var needle = Line2D.new()
	needle.width = 3.0
	needle.default_color = Color(0.08, 0.07, 0.05, 1.0)
	needle.add_point(Vector2.ZERO)
	var visual_angle = deg_to_rad(float(data["angle"]))
	needle.add_point(Vector2(cos(visual_angle), -sin(visual_angle)) * 36.0)
	if id == "E":
		needle.visible = false
		for offset in [Vector2(-18, 8), Vector2(-4, -6), Vector2(12, 5)]:
			var shard = ColorRect.new()
			shard.position = offset
			shard.size = Vector2(12, 8)
			shard.color = data["color"]
			node.add_child(shard)
	else:
		node.add_child(needle)

	var label = Label.new()
	label.position = Vector2(-52, 20)
	label.size = Vector2(104, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "观测点%s" % id
	label.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08, 1.0))
	label.add_theme_font_size_override("font_size", 12)
	label.z_index = Z_LABEL
	node.add_child(label)
	return node


func _create_hud() -> void:
	var ui = CanvasLayer.new()
	ui.name = "PrototypeUILayer"
	ui.layer = 32
	add_child(ui)

	var top = Panel.new()
	top.position = Vector2(18, 16)
	top.size = Vector2(498, 112)
	ui.add_child(top)

	hud_status = Label.new()
	hud_status.position = Vector2(16, 12)
	hud_status.size = Vector2(468, 28)
	hud_status.add_theme_font_size_override("font_size", 16)
	top.add_child(hud_status)

	hud_objective = Label.new()
	hud_objective.position = Vector2(16, 40)
	hud_objective.size = Vector2(468, 34)
	hud_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_objective.add_theme_font_size_override("font_size", 13)
	top.add_child(hud_objective)

	hud_observations = Label.new()
	hud_observations.position = Vector2(16, 76)
	hud_observations.size = Vector2(468, 24)
	hud_observations.add_theme_font_size_override("font_size", 13)
	top.add_child(hud_observations)

	message_panel = Panel.new()
	message_panel.position = Vector2(300, 520)
	message_panel.size = Vector2(680, 148)
	message_panel.visible = false
	ui.add_child(message_panel)

	message_title = Label.new()
	message_title.position = Vector2(18, 14)
	message_title.size = Vector2(640, 24)
	message_title.add_theme_font_size_override("font_size", 16)
	message_title.add_theme_color_override("font_color", Color(0.22, 0.50, 0.78, 1.0))
	message_panel.add_child(message_title)

	message_body = Label.new()
	message_body.position = Vector2(18, 44)
	message_body.size = Vector2(640, 88)
	message_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_body.add_theme_font_size_override("font_size", 14)
	message_panel.add_child(message_body)

	interact_hint = Label.new()
	interact_hint.position = Vector2(482, 680)
	interact_hint.size = Vector2(316, 28)
	interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_hint.add_theme_font_size_override("font_size", 15)
	interact_hint.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52, 1.0))
	ui.add_child(interact_hint)

	_create_angle_panel(ui)


func _create_angle_panel(ui: CanvasLayer) -> void:
	angle_panel = Panel.new()
	angle_panel.position = Vector2(438, 178)
	angle_panel.size = Vector2(404, 260)
	angle_panel.visible = false
	ui.add_child(angle_panel)

	var title = Label.new()
	title.position = Vector2(24, 18)
	title.size = Vector2(356, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "钟楼日晷校准"
	title.add_theme_font_size_override("font_size", 18)
	angle_panel.add_child(title)

	var hint = Label.new()
	hint.position = Vector2(30, 58)
	hint.size = Vector2(344, 52)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "用已记录的角度推断第五项。每次调整 6°。"
	hint.add_theme_font_size_override("font_size", 13)
	angle_panel.add_child(hint)

	angle_value = Label.new()
	angle_value.position = Vector2(138, 116)
	angle_value.size = Vector2(128, 44)
	angle_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	angle_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	angle_value.add_theme_font_size_override("font_size", 26)
	angle_panel.add_child(angle_value)

	var minus_btn = Button.new()
	minus_btn.position = Vector2(56, 120)
	minus_btn.size = Vector2(64, 40)
	minus_btn.text = "-6°"
	minus_btn.pressed.connect(_on_clock_minus_pressed)
	angle_panel.add_child(minus_btn)

	var plus_btn = Button.new()
	plus_btn.position = Vector2(284, 120)
	plus_btn.size = Vector2(64, 40)
	plus_btn.text = "+6°"
	plus_btn.pressed.connect(_on_clock_plus_pressed)
	angle_panel.add_child(plus_btn)

	var submit_btn = Button.new()
	submit_btn.position = Vector2(56, 188)
	submit_btn.size = Vector2(132, 42)
	submit_btn.text = "验证"
	submit_btn.pressed.connect(_submit_clock_angle)
	angle_panel.add_child(submit_btn)

	var close_btn = Button.new()
	close_btn.position = Vector2(216, 188)
	close_btn.size = Vector2(132, 42)
	close_btn.text = "关闭"
	close_btn.pressed.connect(_close_angle_panel)
	angle_panel.add_child(close_btn)


func _process(delta: float) -> void:
	_update_closest_interactable()
	_track_quiet_intermission(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if angle_panel.visible:
			_close_angle_panel()
		else:
			get_tree().change_scene_to_file("res://scenes/star_map.tscn")
		get_viewport().set_input_as_handled()
	elif angle_panel.visible:
		if event.is_action_pressed("ui_left"):
			_on_clock_minus_pressed()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			_on_clock_plus_pressed()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_submit_clock_angle()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_interact_with_closest()
		get_viewport().set_input_as_handled()


func _update_closest_interactable() -> void:
	if player == null:
		return
	var closest: Node2D = null
	var closest_dist := INF
	for node in interactables:
		var radius = float(node.get_meta("radius", PLAYER_INTERACT_DISTANCE))
		var dist = player.global_position.distance_to(node.global_position)
		if dist <= radius and dist < closest_dist:
			closest = node
			closest_dist = dist
	_closest = closest
	if _closest == null:
		interact_hint.text = ""
	else:
		interact_hint.text = "[E] %s" % String(_closest.get_meta("title", "交互"))


func _interact_with_closest() -> void:
	if _closest == null:
		return
	var kind = String(_closest.get_meta("kind", ""))
	var id = String(_closest.get_meta("id", ""))
	match kind:
		"sundial":
			_observe_sundial(id)
		"clock":
			_open_clock_console()
		"boundary":
			_touch_boundary()
		"source_mark":
			_complete_fragment()
		"npc":
			_talk_to_npc(id)


func _observe_sundial(id: String) -> void:
	if observed_sundials.has(id):
		_show_message(SUNDIALS[id]["title"], "这条观测数据已记录：%s°。" % observed_sundials[id], 3.0)
		return
	if id == "E" and _count_visible_observations() < 4:
		_show_message("观测点E · 边界残晷", "日晷已经碎了，看不出角度。也许先把其他四个角度记全。", 4.5)
		return

	var data = SUNDIALS[id]
	observed_sundials[id] = int(data["angle"])
	clue_system.discover_clue(data["title"], "observation", "%s：%d°" % [data["place"], data["angle"]], data["place"])
	_update_hud()

	var extra = ""
	if id == "E":
		extra = "\n四个已知角度是 12、24、36、48。第五项不是看到的，是推出来的：66。"
	elif observed_sundials.size() == 2:
		extra = "\n陈技术的终端亮了一下：阴影角度之间存在稳定间隔。"
	elif observed_sundials.size() == 4:
		extra = "\n林指导放低声音：第五个，不是用眼睛。"
	_show_message(data["title"], "%s\n已写入观测日志。%s" % [data["body"], extra], 5.5)


func _count_visible_observations() -> int:
	var count := 0
	for id in ["A", "B", "C", "D"]:
		if observed_sundials.has(id):
			count += 1
	return count


func _open_clock_console() -> void:
	if source_mark_revealed:
		_show_message("钟楼暗门", "暗门已经打开。晨曦之印在暗室石台上发出淡金色光。", 3.5)
		return
	if observed_sundials.size() < 5:
		_show_message("钟楼观测台", "观测台被锁定。需要五个日晷数据，包含第五个残晷的推断角度。", 4.0)
		return
	angle_panel.visible = true
	_update_angle_value()


func _on_clock_minus_pressed() -> void:
	clock_angle = wrapi(clock_angle - 6, 0, 360)
	_update_angle_value()


func _on_clock_plus_pressed() -> void:
	clock_angle = wrapi(clock_angle + 6, 0, 360)
	_update_angle_value()


func _update_angle_value() -> void:
	angle_value.text = "%d°" % clock_angle


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
	angle_panel.visible = false


func _reveal_source_mark() -> void:
	if source_mark_revealed:
		return
	source_mark_revealed = true
	clue_system.locate_source_mark("晨曦之印", "钟楼底层暗室")
	_create_source_mark()
	_update_hud()
	_show_message(
		"钟楼暗室",
		"66°。指针落下，钟楼下方传来齿轮咬合声。\n暗门打开，石台上显出一枚铜色日晷徽章：晨曦之印。",
		6.0
	)


func _create_source_mark() -> void:
	var mark = Node2D.new()
	mark.name = "SourceMarkDawn"
	mark.position = Vector2(650, 455)
	mark.z_index = Z_PROP
	mark.set_meta("id", "source_mark")
	mark.set_meta("kind", "source_mark")
	mark.set_meta("title", "净化晨曦之印")
	mark.set_meta("radius", PLAYER_INTERACT_DISTANCE)
	add_child(mark)
	interactables.append(mark)

	var glow = ColorRect.new()
	glow.position = Vector2(-30, -30)
	glow.size = Vector2(60, 60)
	glow.color = Color(1.0, 0.72, 0.24, 0.72)
	mark.add_child(glow)
	_create_collision_rect("SourceMarkDawnCollision", mark.position + glow.position, glow.size)

	var label = Label.new()
	label.position = Vector2(-70, 34)
	label.size = Vector2(140, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "晨曦之印"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.30, 0.18, 0.04, 1.0))
	label.z_index = Z_LABEL
	mark.add_child(label)


func _touch_boundary() -> void:
	_modify_compliance(-12, "触碰边界光墙")
	var body = "蓝色光墙泛起水波。0.2 秒里，墙外闪过草地、树和远处的山。\n赵安保：为了您的安全，请回到指定活动区域。"
	if not _boundary_warning_given:
		_boundary_warning_given = true
		clue_system.discover_clue("边界光墙异常", "observation", "光墙外似乎是真实空间，不是空白背景。", "边界光墙")
		body += "\n石板上有一行刻痕：上一个你走到这里的时候，光墙是红色的。"
	_show_message("边界光墙", body, 5.5)


func _talk_to_npc(id: String) -> void:
	match id:
		"linguide":
			if observed_sundials.is_empty():
				_show_message("林指导", "请先观察广场日晷。观察、记录、推理、验证，这是溯光者的基础流程。", 4.5)
			elif observed_sundials.size() < 4:
				_show_message("林指导", "您已经开始怀疑了，这是好的。不要相信预期，相信你看到的。", 4.5)
			elif not source_mark_revealed:
				_show_message("林指导", "第五个残晷的角度需要推断。完成后回钟楼，把答案交给观测台。", 4.5)
			else:
				_show_message("林指导", "最后一个训练提示，不在脚本里：在公司里，不是所有问题都有答案。但所有答案都可能被修改过。", 6.0)
		"chentech":
			var hint = "半解密提示不是答案，是方向。比如：日晷的阴影在说话。"
			if observed_sundials.size() >= 2:
				hint += "\n两个角度足够看见间隔，四个角度足够推断缺项。"
			_show_message("陈技术", hint, 5.0)
		"wangdirector":
			_show_message("王主管", "天枢公司欢迎您的参与。请注意，训练系统中的所有异常现象均属于标准教学内容。", 4.5)
		"zhaosecurity":
			_show_message("赵安保", "边界区执行零容忍监控。为了您的安全，请勿持续接触光墙。", 4.0)


func _modify_compliance(delta: int, reason: String) -> void:
	compliance = clampi(compliance + delta, 0, 100)
	_update_hud()
	var sign = "+" if delta >= 0 else ""
	print("[Fragment0001] 合规度 %s%d -> %d | %s" % [sign, delta, compliance, reason])
	if compliance <= 20:
		_show_message("系统提示", "合规度进入限制区。正式版本可在这里接入权限锁定、强制回训或公司监控反馈。", 4.0)


func _track_quiet_intermission(delta: float) -> void:
	if _intermission_played or player == null:
		return
	if observed_sundials.size() < 5 or source_mark_revealed:
		_quiet_time = 0.0
		return
	var plaza_center = Vector2(420, 322)
	if player.global_position.distance_to(plaza_center) < 95.0 and player.velocity.length() < 1.0:
		_quiet_time += delta
	else:
		_quiet_time = 0.0
	if _quiet_time >= 60.0:
		_intermission_played = true
		clue_system.discover_clue("林指导幕间", "dialogue", "她提到17批溯光者，以及3个人走到过边界墙。", "广场")
		_show_message("林指导", "17个。这17个月，我在镇子里送了17批人。只有3个人走到过边界墙。\n别告诉任何人我说了这些。因为这些话，不在培训脚本里。", 7.0)


func _update_hud() -> void:
	var compliance_label = "优秀"
	if compliance < 80:
		compliance_label = "良好"
	if compliance < 60:
		compliance_label = "注意"
	if compliance < 40:
		compliance_label = "警告"
	if compliance < 20:
		compliance_label = "限制"
	hud_status.text = "碎片 #0001 启程之镇    合规度 %d%% · %s" % [compliance, compliance_label]
	if source_mark_revealed:
		hud_objective.text = "目标：进入钟楼暗室，净化晨曦之印。"
	elif observed_sundials.size() >= 5:
		hud_objective.text = "目标：回到钟楼观测台，校准日晷指针。"
	else:
		hud_objective.text = "目标：观察五个日晷，记录角度并找出缺失项。"
	var parts: Array[String] = [] as Array[String]
	for id in OBSERVATION_ORDER:
		if observed_sundials.has(id):
			parts.append("%s:%d°" % [id, observed_sundials[id]])
		else:
			parts.append("%s:--" % id)
	hud_observations.text = "观测日志  " + "  ".join(parts)


func _show_message(title: String, body: String, duration: float = 4.0) -> void:
	message_title.text = title
	message_body.text = body
	message_panel.visible = true
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void:
		if message_body.text == body:
			message_panel.visible = false
	)


func _complete_fragment() -> void:
	if completed:
		return
	completed = true
	clue_system.decode_source_mark("晨曦之印", "晨曦镇训练场完成校准，钟楼暗室已开启。")
	GameManager.record_source_mark("0001", "晨曦之印", "钟楼暗室便笺：所有答案都可能被修改过。")
	var fragment = FragmentManager.current_fragment
	if fragment == null:
		fragment = FragmentManager.get_fragment_by_id("0001")
	FragmentManager.complete_fragment(fragment)
	SaveManager.save_game()
	_show_message("晨曦之印", "源印归位。星图已更新。\n测试原型将在片刻后返回星图。", 4.0)
	await get_tree().create_timer(1.8).timeout
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func observe_sundial_for_test(id: String) -> void:
	_observe_sundial(id)


func set_clock_angle_for_test(value: int) -> void:
	clock_angle = value


func submit_clock_angle_for_test() -> bool:
	return _submit_clock_angle()


func get_observed_count_for_test() -> int:
	return observed_sundials.size()


func get_compliance_for_test() -> int:
	return compliance


func is_source_mark_revealed_for_test() -> bool:
	return source_mark_revealed
