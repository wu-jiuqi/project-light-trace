extends Node2D
## 钟楼暗室 — 全屏静态视角，无 Player，纯鼠标点击
## 所有 UI 节点在 darkroom.tscn 中，可手动调整位置/大小/颜色

const EXIT_SCENE: String = "res://scenes/fragments/fragment_0001.tscn"

# 节点引用（在 tscn 中手动调整）
@onready var _camera: Camera2D = $StaticCamera
@onready var _note_area: Area2D = $Note
@onready var _emblem_area: Area2D = $Emblem
@onready var _exit_area: Area2D = $ExitArea
@onready var _hint_layer: CanvasLayer = $HintLayer
@onready var _exit_hint: Label = $HintLayer/ExitHint
@onready var _hover_hint: Label = $HintLayer/HoverHint
@onready var _entry_guide: Label = $HintLayer/EntryGuide
@onready var _note_overlay: CanvasLayer = $NoteOverlay
@onready var _note_bg: ColorRect = $NoteOverlay/NoteBg
@onready var _note_image: TextureRect = $NoteOverlay/NoteImage


func _ready() -> void:
	print("[Darkroom] 钟楼暗室 — 全屏静态视角就绪")

	SceneFader.ensure_black()

	_camera.make_current()
	_connect_signals()
	_animate_entry_guide()
	_animate_exit_hint()

	SceneFader.fade_in()


# ============================================================
# 信号连接
# ============================================================

func _connect_signals() -> void:
	_note_area.input_event.connect(_on_note_clicked)
	_note_area.mouse_entered.connect(func(): _on_mouse_enter("查看石台上的便笺"))
	_note_area.mouse_exited.connect(_on_mouse_exit)

	_emblem_area.input_event.connect(_on_emblem_clicked)
	_emblem_area.mouse_entered.connect(func(): _on_mouse_enter("触碰晨曦之印"))
	_emblem_area.mouse_exited.connect(_on_mouse_exit)

	_exit_area.input_event.connect(_on_exit_clicked)
	_exit_area.mouse_entered.connect(func(): _on_mouse_enter("返回启程之镇"))
	_exit_area.mouse_exited.connect(_on_mouse_exit)

	_note_bg.gui_input.connect(_on_note_bg_clicked)

	# 动态调整 NoteImage 尺寸
	_adjust_note_image_size()


func _adjust_note_image_size() -> void:
	if not _note_image.texture:
		return
	var tex_size = _note_image.texture.get_size()
	var max_width = 1280 * 0.60
	var max_height = 720 * 0.67
	var scale_x = min(1.0, max_width / tex_size.x)
	var scale_y = min(1.0, max_height / tex_size.y)
	var scale = min(scale_x, scale_y)
	var display_size = tex_size * scale
	_note_image.size = display_size
	_note_image.position = Vector2(
		(1280 - display_size.x) / 2,
		80
	)


# ============================================================
# 入场引导渐隐
# ============================================================

func _animate_entry_guide() -> void:
	var tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property(_entry_guide, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_entry_guide.queue_free)


# ============================================================
# 底部返回提示闪烁
# ============================================================

func _animate_exit_hint() -> void:
	var blink = create_tween()
	blink.set_loops()
	blink.tween_property(_exit_hint, "modulate:a", 0.45, 1.2)
	blink.tween_property(_exit_hint, "modulate:a", 0.95, 1.2)


# ============================================================
# 鼠标交互
# ============================================================

func _on_mouse_enter(hint: String) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	_hover_hint.text = hint
	_hover_hint.visible = true


func _on_mouse_exit() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_hover_hint.visible = false


# ============================================================
# Note — 显示便笺
# ============================================================

func _on_note_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_note_overlay.visible = true


func _on_note_bg_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_note_overlay.visible = false


# ============================================================
# Emblem — 源印完成
# ============================================================

func _on_emblem_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_complete_fragment()


func _complete_fragment() -> void:
	for entry in GameManager.source_mark_log:
		if entry.get("fragment_id", "") == "0001":
			print("[Darkroom] 碎片 #0001 已记录源印，跳过")
			return

	_emblem_area.input_pickable = false

	GameManager.record_source_mark("0001", "晨曦之印", "钟楼暗室便笺：所有答案都可能被修改过。")
	var fragment = FragmentManager.current_fragment
	if fragment == null:
		fragment = FragmentManager.get_fragment_by_id("0001")
	FragmentManager.complete_fragment(fragment)
	SaveManager.save_game()

	print("[Darkroom] 源印归位！晨曦之印 — 碎片 #0001 完成")
	_show_completion_overlay()


func _show_completion_overlay() -> void:
	var overlay = CanvasLayer.new()
	overlay.name = "CompletionOverlay"
	overlay.layer = 200
	add_child(overlay)

	var bg = ColorRect.new()
	bg.name = "CompletionBg"
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var panel = Panel.new()
	panel.position = Vector2(340, 180)
	panel.size = Vector2(600, 360)
	overlay.add_child(panel)

	var title = Label.new()
	title.text = "晨曦之印"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.22, 0.50, 0.78, 1.0))
	title.position = Vector2(20, 30)
	title.size = Vector2(560, 40)
	panel.add_child(title)

	var body = Label.new()
	body.text = "源印归位。星图已更新。\n碎片 #0001「启程之镇」— 完成。"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.position = Vector2(30, 90)
	body.size = Vector2(540, 140)
	panel.add_child(body)

	var hint = Label.new()
	hint.text = "即将返回星图..."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	hint.position = Vector2(30, 280)
	hint.size = Vector2(540, 30)
	panel.add_child(hint)

	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		get_tree().change_scene_to_file("res://scenes/star_map.tscn")
	)


# ============================================================
# Exit — 返回启程之镇
# ============================================================

func _on_exit_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_back()


func _go_back() -> void:
	print("[Darkroom] 返回启程之镇 (OutDoor)")
	SceneManager.change_scene(EXIT_SCENE, "OutDoor")


# ============================================================
# 键盘输入
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if _note_overlay.visible:
			_note_overlay.visible = false
			get_viewport().set_input_as_handled()
			return
		_go_back()
		get_viewport().set_input_as_handled()
