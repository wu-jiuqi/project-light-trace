extends Node2D
## 钟楼暗室 — 全屏静态视角，无 Player，纯鼠标点击
## 所有 UI 节点在 darkroom.tscn 中，可手动调整位置/大小/颜色

const EXIT_SCENE: String = "res://scenes/fragments/fragment_0001.tscn"
const SFX_PICKUP := preload("res://assets/audio/sfx/ui_item_pickup.wav")
const SFX_PICKUP_VOLUME_DB: float = -4.0

@export_range(0, 1, 1) var darkroom_note_collected: int = 0

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
@onready var _note_hint: Label = $NoteOverlay/CloseHint
@onready var _note_image: TextureRect = $NoteOverlay/NoteImage

var _note_hovered: bool = false


func _ready() -> void:
	print("[Darkroom] 钟楼暗室 — 全屏静态视角就绪")

	SceneFader.ensure_black()

	_camera.make_current()
	_prepare_note_hint_layout()
	_restore_note_collection_state()
	_connect_signals()
	_animate_entry_guide()
	_animate_exit_hint()

	SceneFader.fade_in()


# ============================================================
# 信号连接
# ============================================================

func _connect_signals() -> void:
	_note_area.input_event.connect(_on_note_clicked)
	_note_area.mouse_entered.connect(_on_note_mouse_entered)
	_note_area.mouse_exited.connect(_on_note_mouse_exited)

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
	_note_image.scale = Vector2.ONE
	var tex_size = _note_image.texture.get_size()
	var viewport_size := get_viewport_rect().size
	var max_width = viewport_size.x * 0.60
	var max_height = viewport_size.y * 0.67
	var scale_x = min(1.0, max_width / tex_size.x)
	var scale_y = min(1.0, max_height / tex_size.y)
	var scale = min(scale_x, scale_y)
	var display_size = tex_size * scale
	_note_image.size = display_size
	_note_image.position = Vector2(
		(viewport_size.x - display_size.x) / 2,
		max(64.0, (viewport_size.y - display_size.y) * 0.45)
	)
	_prepare_note_hint_layout()


func _prepare_note_hint_layout() -> void:
	if _note_hint == null or _note_overlay == null:
		return
	_note_overlay.move_child(_note_hint, _note_overlay.get_child_count() - 1)
	_note_hint.z_index = 20
	_note_hint.anchor_left = 0.0
	_note_hint.anchor_right = 1.0
	_note_hint.anchor_top = 1.0
	_note_hint.anchor_bottom = 1.0
	_note_hint.offset_left = 0.0
	_note_hint.offset_right = 0.0
	_note_hint.offset_top = -72.0
	_note_hint.offset_bottom = -32.0
	_note_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_note_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
		_show_note_overlay()


func _on_note_bg_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_note_overlay.visible = false


func _on_note_mouse_entered() -> void:
	_note_hovered = true
	_on_mouse_enter(_get_note_hover_hint())


func _on_note_mouse_exited() -> void:
	_note_hovered = false
	_on_mouse_exit()


func _show_note_overlay() -> void:
	if darkroom_note_collected == 1:
		_on_mouse_enter("你已经收集过了")
		return
	_refresh_note_collect_hint()
	_note_overlay.visible = true


func _restore_note_collection_state() -> void:
	var saved_note_collected = FragmentManager.get_fragment_state("0001", "darkroom_note_collected")
	if typeof(saved_note_collected) == TYPE_INT:
		darkroom_note_collected = clampi(saved_note_collected, 0, 1)
	elif typeof(saved_note_collected) == TYPE_BOOL:
		darkroom_note_collected = 1 if saved_note_collected else 0
	_refresh_note_collect_hint()


func _get_note_hover_hint() -> String:
	if darkroom_note_collected == 1:
		return "你已经收集过了"
	return "按 E 查看便签 | 打开后按 E 收集"


func _refresh_note_collect_hint() -> void:
	if _note_hint == null:
		return
	_note_hint.add_theme_font_size_override("font_size", 16)
	_note_hint.add_theme_constant_override("outline_size", 3)
	if darkroom_note_collected == 1:
		_note_hint.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 0.9))
		_note_hint.text = "你已经收集过了 | 点击或按 Esc 关闭"
	else:
		_note_hint.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68, 0.95))
		_note_hint.text = "按 E 收集暗室便签 | 点击任意位置或按 Esc 关闭"


func _collect_darkroom_note() -> void:
	if darkroom_note_collected == 1:
		return
	darkroom_note_collected = 1
	FragmentManager.set_fragment_state("0001", "darkroom_note_collected", darkroom_note_collected)
	_play_pickup_sfx()
	_refresh_note_collect_hint()
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	print("[Darkroom] Note collected")


# ============================================================
# Emblem — 源印完成
# ============================================================

func _on_emblem_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_complete_fragment()


func _complete_fragment() -> void:
	_collect_darkroom_emblem()
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


func _collect_darkroom_emblem() -> void:
	if FragmentManager.get_fragment_state("0001", "darkroom_emblem_collected") == true:
		return
	FragmentManager.set_fragment_state("0001", "darkroom_emblem_collected", true)
	_play_pickup_sfx()
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()


func _show_completion_overlay() -> void:
	var overlay = CanvasLayer.new()
	overlay.name = "CompletionOverlay"
	overlay.layer = 200
	add_child(overlay)

	var bg = ColorRect.new()
	bg.name = "CompletionBg"
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	var panel = Panel.new()
	panel.name = "VictoryPanel"
	panel.position = Vector2(340, 120)
	panel.size = Vector2(600, 480)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# 暗色半透明背景 + 金色边框
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.102, 0.102, 0.18, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.85, 0.72, 0.28, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	# VBox 主布局
	var vbox := VBoxContainer.new()
	vbox.name = "VictoryVBox"
	vbox.position = Vector2(40, 30)
	vbox.size = Vector2(520, 420)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# 标题 — 源印解码成功
	var title := Label.new()
	title.name = "VictoryTitle"
	title.text = "◇ 源印解码成功 ◇"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35, 1.0))  # 金色
	title.size = Vector2(520, 40)
	vbox.add_child(title)

	# 源印信息行
	var source_row := HBoxContainer.new()
	source_row.name = "SourceInfoRow"
	source_row.add_theme_constant_override("separation", 8)
	source_row.size = Vector2(520, 30)
	vbox.add_child(source_row)

	var source_icon := Label.new()
	source_icon.text = "✦"
	source_icon.add_theme_font_size_override("font_size", 22)
	source_icon.add_theme_color_override("font_color", Color(1.0, 0.72, 0.24, 1.0))
	source_row.add_child(source_icon)

	var source_name := Label.new()
	source_name.text = "晨曦之印"
	source_name.add_theme_font_size_override("font_size", 18)
	source_name.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82, 1.0))
	source_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	source_row.add_child(source_name)

	var source_status := Label.new()
	source_status.text = "已解析"
	source_status.add_theme_font_size_override("font_size", 14)
	source_status.add_theme_color_override("font_color", Color(0.35, 0.78, 0.55, 1.0))  # 绿色
	source_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	source_row.add_child(source_status)

	# 修复进度 8.3%
	var progress_label := Label.new()
	progress_label.text = "修复进度：8.3%  —  已修复碎片：1/12"
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.size = Vector2(520, 24)
	vbox.add_child(progress_label)

	var progress_bg := ColorRect.new()
	progress_bg.name = "ProgressBg"
	progress_bg.color = Color(0.2, 0.2, 0.24, 1.0)
	progress_bg.size = Vector2(520, 16)
	vbox.add_child(progress_bg)

	var progress_fill := ColorRect.new()
	progress_fill.name = "ProgressFill"
	progress_fill.color = Color(0.22, 0.48, 0.84, 1.0)  # 蓝色填充
	progress_fill.size = Vector2(520 * 0.083, 16)  # 8.3%
	progress_bg.add_child(progress_fill)

	# 林指导通关祝贺
	var congrats := Label.new()
	congrats.name = "CongratsText"
	congrats.text = "溯光者——恭喜完成第一阶段训练。\n您接下来可以进入黄昏驿站继续任务。\n\n\"最后一个训练提示，不在脚本里：\n在公司里，不是所有问题都有答案。\n但所有答案——都可能被修改过。\""
	congrats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	congrats.add_theme_font_size_override("font_size", 14)
	congrats.add_theme_color_override("font_color", Color(0.85, 0.83, 0.78, 1.0))
	congrats.size = Vector2(520, 0)
	congrats.custom_minimum_size = Vector2(520, 120)
	vbox.add_child(congrats)

	# 分隔间距
	var spacer := Control.new()
	spacer.size = Vector2(520, 10)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 按钮横排
	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 40)
	button_row.size = Vector2(520, 44)
	vbox.add_child(button_row)

	var return_btn := Button.new()
	return_btn.name = "ReturnBtn"
	return_btn.text = "返回星图"
	return_btn.size = Vector2(180, 44)
	return_btn.add_theme_font_size_override("font_size", 16)
	return_btn.pressed.connect(func() -> void:
		SceneManager.change_scene("res://scenes/star_map.tscn")
	)
	return_btn.pressed.connect(UISoundManager.play_click)
	button_row.add_child(return_btn)

	var continue_btn := Button.new()
	continue_btn.name = "ContinueBtn"
	continue_btn.text = "继续游玩"
	continue_btn.size = Vector2(180, 44)
	continue_btn.add_theme_font_size_override("font_size", 16)
	continue_btn.pressed.connect(func() -> void:
		print("[Darkroom] 玩家选择继续游玩 — 返回启程之镇 (OutDoor)")
		SceneManager.change_scene(EXIT_SCENE, "OutDoor")
	)
	continue_btn.pressed.connect(UISoundManager.play_click)
	button_row.add_child(continue_btn)

	# 面板淡入动画
	panel.modulate = Color(1, 1, 1, 0)
	var fade_tween := create_tween()
	fade_tween.tween_property(panel, "modulate:a", 1.0, 0.4)


# ============================================================
# Exit — 返回启程之镇
# ============================================================

func _on_exit_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_back()


func _go_back() -> void:
	print("[Darkroom] 返回启程之镇 (OutDoor)")
	SceneManager.change_scene(EXIT_SCENE, "OutDoor")


func _play_pickup_sfx() -> void:
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx(SFX_PICKUP, AudioManager.PRIORITY_NORMAL, SFX_PICKUP_VOLUME_DB)


# ============================================================
# 键盘输入
# ============================================================

func _input(event: InputEvent) -> void:
	if _note_overlay.visible and event.is_action_pressed("interact"):
		if darkroom_note_collected == 0:
			_collect_darkroom_note()
		else:
			_note_overlay.visible = false
		get_viewport().set_input_as_handled()
		return
	if _note_hovered and event.is_action_pressed("interact"):
		_show_note_overlay()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("escape"):
		if _note_overlay.visible:
			_note_overlay.visible = false
			get_viewport().set_input_as_handled()
			return
		_go_back()
		get_viewport().set_input_as_handled()
