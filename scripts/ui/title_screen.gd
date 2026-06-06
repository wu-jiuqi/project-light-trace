extends Control
## 溯光计划 — 标题画面（重构版）
## 五个交互热区垂直排列在画面右侧（背景图已包含按钮视觉）：
##   开始游戏 / 游戏存档 / 成就 / 剧情回顾 / 退出游戏
## 键盘导航：↑↓选择  Enter确认  Esc返回（存档面板中）
##
## ============================================================
## 弹窗尺寸参考（供美术资产制作）
## ============================================================
## 开始游戏确认弹窗: 560×320 px，内边距 30px
##   两个操作按钮: 各 200×48 px，水平并排
##   标题: "开始游戏"，居中，字号 22
## 存档管理弹窗: 620×400 px（实际为全屏覆盖模式）
## 成就/剧情回顾提示弹窗: 标准 AcceptDialog 尺寸


# ============================================================
# 纸雕纹理预加载
# ============================================================
const PAPER_TITLE_BG = preload("res://assets/ui/title_start_bg.jpg")
const PAPER_PANEL = preload("res://assets/papercraft/core/ui/dialogue_panel.png")
const PAPER_SLOT = preload("res://assets/papercraft/core/ui/detail_card.png")
const PAPER_BUTTON_NORMAL = preload("res://assets/papercraft/core/ui/button_normal.png")
const PAPER_BUTTON_HOVER = preload("res://assets/papercraft/core/ui/button_hover.png")
const PAPER_BUTTON_PRESSED = preload("res://assets/papercraft/core/ui/button_pressed.png")
const PAPER_BUTTON_DISABLED = preload("res://assets/papercraft/core/ui/button_disabled.png")

# ============================================================
# 颜色常量
# ============================================================
const PAPER_INK := Color(0.18, 0.12, 0.075, 1.0)
const PAPER_INK_MUTED := Color(0.33, 0.25, 0.17, 0.95)
const PAPER_GOLD := Color(0.63, 0.42, 0.15, 1.0)
const PAPER_DIM := Color(0.36, 0.34, 0.30, 0.62)
const PAPER_WARNING := Color(0.66, 0.25, 0.16, 1.0)

# ============================================================
# 布局常量 — 热区坐标与背景图按钮精确对齐
# 基于设计稿（1280×720 参考分辨率），所有 5 个按钮 X 范围一致：735 ~ 1140
# 运行时按 viewport / REFERENCE_SIZE 等比缩放，适配任意窗口
# ============================================================
const REFERENCE_SIZE := Vector2(1280, 720)
const BTN_COUNT := 5
## 5 个热区的矩形区域（设计稿精确坐标，1280×720 基准下）
const HIT_RECTS: Array = [
	Rect2(735, 75, 405, 100),   # 按钮1：开始游戏
	Rect2(735, 195, 405, 85),   # 按钮2：继续游戏
	Rect2(735, 300, 405, 80),   # 按钮3：设置
	Rect2(735, 400, 405, 80),   # 按钮4：提示
	Rect2(735, 500, 405, 80),   # 按钮5：退出
]
const DEFAULT_TITLE_BG_SIZE := Vector2(1672, 941)

# ============================================================
# 成员变量
# ============================================================
var _selected: int = 0
var _has_saves: bool = false
var _hit_areas: Array[Control] = []
var _hit_container: Control  # 容纳所有热区的容器
var _selection_highlight: ColorRect  # 选中高亮指示器

# 版本标签
var _version_label: Label

# 存档面板相关
var _save_slots_visible: bool = false
var _slot_containers: Array[Control] = []
var _slot_selected: int = -1
var _slot_mode: String = ""  # "load" 或 "new_game"
var _slot_title_label: Label
var _slot_scroll: ScrollContainer
var _slot_list: VBoxContainer
var _load_btn: Button
var _new_game_btn: Button
var _delete_btn: Button
var _back_btn: Button

# 活跃弹窗引用（防止同时弹出多个）
var _active_dialog: Window = null

@onready var _bg: TextureRect = $BG
@onready var _dark_wash: ColorRect = $DarkWash


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_apply_skin()
	_create_hit_areas()
	_create_version_label()
	_layout_all()
	get_viewport().size_changed.connect(_layout_all)

	_has_saves = _has_occupied_save_slots()
	_selected = 0  # 默认选中「开始游戏」
	_update_selection()


func _apply_skin() -> void:
	_bg.texture = PAPER_TITLE_BG
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dark_wash.color = Color(0.09, 0.07, 0.045, 0.1)


# ============================================================
# 交互热区创建（替代原来的 Button 创建）
# 背景图 title_start_bg.jpg 已包含按钮视觉，
# 这里只放置透明的鼠标/键盘交互热区
# ============================================================

func _create_hit_areas() -> void:
	_hit_container = Control.new()
	_hit_container.name = "HitContainer"
	_hit_container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_hit_container)

	for i in BTN_COUNT:
		var idx := i  # 捕获循环变量，避免 lambda 闭包引用同一变量
		var rect: Rect2 = HIT_RECTS[i]
		var area := ColorRect.new()
		area.name = "HitArea%d" % (i + 1)
		area.color = Color(1, 1, 1, 0)  # 完全透明
		area.custom_minimum_size = rect.size
		area.position = rect.position
		area.size = rect.size
		area.mouse_filter = Control.MOUSE_FILTER_STOP
		area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		area.focus_mode = Control.FOCUS_ALL
		area.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton \
					and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed:
				_on_button_pressed(idx)
		)
		area.mouse_entered.connect(func(): _on_button_hovered(idx))
		_hit_container.add_child(area)
		_hit_areas.append(area)

	# 选中高亮指示器 — 半透明金色块，跟随当前选中热区
	# 尺寸在 _update_selection() / _layout_hit_areas() 中动态设置
	_selection_highlight = ColorRect.new()
	_selection_highlight.name = "SelectionHighlight"
	_selection_highlight.color = Color(0.63, 0.42, 0.15, 0.18)
	_selection_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
	_hit_container.add_child(_selection_highlight)
	_selection_highlight.move_to_front()


func _create_version_label() -> void:
	_version_label = Label.new()
	_version_label.text = "溯光计划 v0.2.0"
	_version_label.add_theme_font_size_override("font_size", 11)
	_version_label.add_theme_color_override("font_color", Color(0.32, 0.25, 0.17, 0.72))
	add_child(_version_label)


# ============================================================
# 响应式布局
# ============================================================

func _layout_all() -> void:
	_layout_hit_areas()
	_layout_version_label()


func _layout_hit_areas() -> void:
	var vs := _get_layout_size()
	var texture_size := _get_title_bg_size()

	# 按缩放因子定位每个热区
	for i in _hit_areas.size():
		var rect: Rect2 = HIT_RECTS[i]
		var area := _hit_areas[i]
		var mapped_rect := _map_reference_rect_to_layout(rect, vs, texture_size)
		area.position = mapped_rect.position
		area.size = mapped_rect.size

	_hit_container.position = Vector2.ZERO
	_hit_container.size = vs

	# 布局改变后同步高亮位置和尺寸
	_update_selection()


func _get_layout_size() -> Vector2:
	var layout_size := size
	if layout_size.x <= 0.0 or layout_size.y <= 0.0:
		layout_size = get_viewport_rect().size
	return layout_size


func _get_title_bg_size() -> Vector2:
	if _bg != null and _bg.texture != null:
		return _bg.texture.get_size()
	if PAPER_TITLE_BG != null:
		return PAPER_TITLE_BG.get_size()
	return DEFAULT_TITLE_BG_SIZE


func _get_cover_rect(container_size: Vector2, texture_size: Vector2) -> Rect2:
	if container_size.x <= 0.0 or container_size.y <= 0.0 \
			or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(Vector2.ZERO, container_size)

	var cover_scale: float = maxf(
		container_size.x / texture_size.x,
		container_size.y / texture_size.y
	)
	var drawn_size: Vector2 = texture_size * cover_scale
	var offset: Vector2 = (container_size - drawn_size) * 0.5
	return Rect2(offset, drawn_size)


func _map_reference_rect_to_layout(
		reference_rect: Rect2,
		layout_size: Vector2,
		texture_size: Vector2
) -> Rect2:
	var reference_bg_rect := _get_cover_rect(REFERENCE_SIZE, texture_size)
	var layout_bg_rect := _get_cover_rect(layout_size, texture_size)
	if texture_size.x <= 0.0 or reference_bg_rect.size.x <= 0.0:
		return Rect2(reference_rect.position, reference_rect.size)

	var reference_scale: float = reference_bg_rect.size.x / texture_size.x
	var layout_scale: float = layout_bg_rect.size.x / texture_size.x
	var texture_position: Vector2 = (reference_rect.position - reference_bg_rect.position) / reference_scale
	var texture_size_local: Vector2 = reference_rect.size / reference_scale
	return Rect2(
		layout_bg_rect.position + texture_position * layout_scale,
		texture_size_local * layout_scale
	)


func _layout_version_label() -> void:
	var vs := _get_layout_size()
	_version_label.position = Vector2(22, vs.y - 32)
	_version_label.size = Vector2(260, 22)


# ============================================================
# 键盘导航
# ============================================================

func _input(event: InputEvent) -> void:
	# 存档面板打开时，Esc 关闭面板
	if _save_slots_visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_hide_save_slots()
			get_viewport().set_input_as_handled()
		return

	# 有弹窗打开时不响应键盘
	if _active_dialog and is_instance_valid(_active_dialog) and _active_dialog.visible:
		return

	if event.is_action_pressed("ui_up"):
		_selected = wrapi(_selected - 1, 0, BTN_COUNT)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_selected = wrapi(_selected + 1, 0, BTN_COUNT)
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_execute_selection()
		get_viewport().set_input_as_handled()


# ============================================================
# 选择状态管理
# ============================================================

func _update_selection() -> void:
	# 移动选中高亮到当前选中热区的位置，并匹配其尺寸
	if _selected >= 0 and _selected < _hit_areas.size():
		var target := _hit_areas[_selected]
		_selection_highlight.position = target.position
		_selection_highlight.size = target.size
		target.grab_focus()


func _on_button_hovered(index: int) -> void:
	_selected = index
	_update_selection()


func _on_button_pressed(index: int) -> void:
	if _active_dialog and is_instance_valid(_active_dialog) and _active_dialog.visible:
		return
	_selected = index
	_update_selection()
	_execute_selection()


func _execute_selection() -> void:
	match _selected:
		0: _on_start_game()
		1: _on_save_slots()
		2: _on_achievements()
		3: _on_story_review()
		4: _on_quit()


# ============================================================
# 1. 开始游戏
#    弹窗尺寸参考: 560×320 px
# ============================================================

func _on_start_game() -> void:
	_has_saves = _has_occupied_save_slots()
	if _has_saves:
		_show_start_game_dialog()
	else:
		_show_no_save_dialog()


func _has_occupied_save_slots() -> bool:
	for slot in SaveManager.list_slots():
		if slot.get("occupied", false):
			return true
	SaveManager.clear_active_slot()
	print("[TitleScreen] _has_occupied_save_slots: 磁盘无存档，已清除活跃槽位")
	return false


func _show_start_game_dialog() -> void:
	## 弹窗: 560×320 px，内边距 30px，两个按钮各 200×48 px 水平并排
	var dialog := ConfirmationDialog.new()
	dialog.title = "开始游戏"
	dialog.dialog_text = "检测到已有游戏进度，请选择："
	dialog.ok_button_text = "开始新游戏"
	dialog.cancel_button_text = "继续当前游戏"
	dialog.get_ok_button().custom_minimum_size = Vector2(200, 48)
	dialog.get_cancel_button().custom_minimum_size = Vector2(200, 48)

	# 纸雕样式
	_apply_dialog_panel_style(dialog)
	_apply_title_button(dialog.get_ok_button())
	_apply_title_button(dialog.get_cancel_button())
	dialog.get_ok_button().add_theme_color_override("font_color", PAPER_GOLD)
	dialog.get_cancel_button().add_theme_color_override("font_color", Color(0.32, 0.45, 0.22, 1.0))

	dialog.confirmed.connect(_show_save_slots.bind("new_game"))
	# 直接连接 Cancel 按钮的 pressed 信号，而非 dialog.canceled。
	# Godot 4 的 ConfirmationDialog.canceled 会在 Cancel 按钮点击 AND/X 关闭/Escape 时都触发，
	# 如果连到 _continue_game() 会导致关闭弹窗时意外进入游戏。
	dialog.get_cancel_button().pressed.connect(_continue_game)
	var dlg := dialog
	dlg.close_requested.connect(func(): if _active_dialog == dlg: _active_dialog = null)
	dlg.tree_exiting.connect(func(): if _active_dialog == dlg: _active_dialog = null)

	add_child(dialog)
	_active_dialog = dialog
	dialog.popup_centered(Vector2i(560, 320))


func _show_no_save_dialog() -> void:
	## 无存档时弹出提示，引导用户开始新游戏
	var dialog := ConfirmationDialog.new()
	dialog.title = "提示"
	dialog.dialog_text = "未检测到存档"
	dialog.ok_button_text = "开始新游戏"
	# 隐藏取消按钮 — 无存档时只有"开始新游戏"一个选项
	dialog.get_cancel_button().visible = false
	dialog.get_ok_button().custom_minimum_size = Vector2(200, 48)

	_apply_dialog_panel_style(dialog)
	_apply_title_button(dialog.get_ok_button())
	dialog.get_ok_button().add_theme_color_override("font_color", PAPER_GOLD)

	dialog.confirmed.connect(_show_save_slots.bind("new_game"))
	var dlg := dialog
	dlg.close_requested.connect(func(): if _active_dialog == dlg: _active_dialog = null)
	dlg.tree_exiting.connect(func(): if _active_dialog == dlg: _active_dialog = null)

	add_child(dialog)
	_active_dialog = dialog
	dialog.popup_centered(Vector2i(420, 200))


func _start_new_game_in_slot() -> void:
	if _slot_selected < 0:
		return
	var slot := _slot_selected
	print("[TitleScreen] 在槽位 %d 开始新游戏" % slot)

	GameManager.new_game()
	SaveManager.set_current_slot(slot)
	ChatDatabase.clear_all_history()
	SaveManager.save_game(slot)

	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _continue_game() -> void:
	var slot := SaveManager.get_last_active_slot()
	if slot < 0:
		_show_hint_dialog("提示", "没有找到存档文件。")
		return
	print("[TitleScreen] 继续游戏 (slot %d)" % slot)
	SaveManager.load_game(slot)
	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


# ============================================================
# 2. 游戏存档
# ============================================================

func _on_save_slots() -> void:
	_show_save_slots("load")


# ============================================================
# 3. 成就
# ============================================================

func _on_achievements() -> void:
	_show_hint_dialog("成就", "成就系统即将开放，敬请期待。")


# ============================================================
# 4. 剧情回顾
# ============================================================

func _on_story_review() -> void:
	_show_hint_dialog("剧情回顾", "剧情回顾功能即将开放，敬请期待。")


# ============================================================
# 5. 退出游戏
# ============================================================

func _on_quit() -> void:
	get_tree().quit()


# ============================================================
# 通用提示弹窗
# ============================================================

func _show_hint_dialog(title_text: String, body_text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title_text
	dialog.dialog_text = body_text
	dialog.ok_button_text = "好的"
	_apply_dialog_panel_style(dialog)
	_apply_title_button(dialog.get_ok_button())
	var dlg := dialog
	dlg.close_requested.connect(func(): if _active_dialog == dlg: _active_dialog = null)
	dlg.tree_exiting.connect(func(): if _active_dialog == dlg: _active_dialog = null)

	add_child(dialog)
	_active_dialog = dialog
	dialog.popup_centered()


func _apply_dialog_panel_style(dialog: Window) -> void:
	if dialog.has_method("add_theme_stylebox_override"):
		dialog.add_theme_stylebox_override("panel", _paper_panel_style())


# ============================================================
# 存档加载面板
# 弹窗尺寸参考: 620×400 px（实际为全屏覆盖模式）
# 保留原有三槽位存档列表 + 加载/删除/返回按钮逻辑
# ============================================================

func _show_save_slots(mode: String = "load") -> void:
	_slot_mode = mode
	var slots := SaveManager.list_slots()

	# 加载模式：检查是否有已占用槽位
	if mode == "load":
		var has_any := false
		for s in slots:
			if s["occupied"]:
				has_any = true
				break
		if not has_any:
			_show_hint_dialog("提示", "没有找到存档文件。")
			return

	_save_slots_visible = true
	_slot_selected = -1

	# 隐藏主菜单热区和版本标签
	_hit_container.visible = false
	_version_label.visible = false

	# 创建或显示存档面板
	if not _slot_scroll:
		_build_save_slot_panel()
	else:
		_slot_scroll.visible = true
		_load_btn.visible = true
		_delete_btn.visible = true
		_back_btn.visible = true

	# 根据模式显示不同按钮和标题
	if mode == "load":
		_slot_title_label.text = "加载存档"
		_load_btn.visible = true
		_delete_btn.visible = true
		if _new_game_btn:
			_new_game_btn.visible = false
	else:  # "new_game"
		_slot_title_label.text = "新游戏 — 选择槽位"
		_load_btn.visible = false
		_delete_btn.visible = false
		if _new_game_btn:
			_new_game_btn.visible = true

	_slot_title_label.visible = true
	_refresh_slot_list(slots)


func _hide_save_slots() -> void:
	_save_slots_visible = false
	_slot_selected = -1
	_slot_mode = ""

	if _slot_scroll:
		_slot_scroll.visible = false
		_load_btn.visible = false
		_delete_btn.visible = false
		if _new_game_btn:
			_new_game_btn.visible = false
		_back_btn.visible = false
	if _slot_title_label:
		_slot_title_label.visible = false

	_hit_container.visible = true
	_version_label.visible = true
	_update_selection()


func _build_save_slot_panel() -> void:
	var vs := get_viewport_rect().size

	# 标题
	_slot_title_label = Label.new()
	_slot_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_title_label.position = Vector2(0, 60)
	_slot_title_label.size = Vector2(vs.x, 40)
	_slot_title_label.add_theme_color_override("font_color", PAPER_INK)
	_slot_title_label.add_theme_color_override(
		"font_shadow_color", Color(0.95, 0.84, 0.62, 0.7)
	)
	_slot_title_label.add_theme_constant_override("shadow_offset_x", 1)
	_slot_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_slot_title_label.add_theme_font_size_override("font_size", 22)
	add_child(_slot_title_label)

	# 滚动区域
	_slot_scroll = ScrollContainer.new()
	_slot_scroll.position = Vector2(vs.x / 2 - 260, 122)
	_slot_scroll.size = Vector2(520, vs.y - 244)
	_slot_scroll.add_theme_stylebox_override(
		"panel", _paper_panel_style(Color(1, 1, 1, 0.98))
	)
	add_child(_slot_scroll)

	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 10)
	_slot_scroll.add_child(_slot_list)

	# 底部按钮栏
	var btn_y := vs.y - 90

	_back_btn = _make_slot_button("返回", Vector2(vs.x / 2 - 260, btn_y))
	_back_btn.pressed.connect(_hide_save_slots)
	add_child(_back_btn)

	_delete_btn = _make_slot_button("删除", Vector2(vs.x / 2 - 74, btn_y))
	_delete_btn.add_theme_color_override("font_color", PAPER_WARNING)
	_delete_btn.pressed.connect(_delete_selected_slot)
	add_child(_delete_btn)

	_load_btn = _make_slot_button("加载", Vector2(vs.x / 2 + 112, btn_y))
	_load_btn.add_theme_color_override("font_color", Color(0.32, 0.45, 0.22, 1))
	_load_btn.pressed.connect(_load_selected_slot)
	add_child(_load_btn)

	# 新游戏专用按钮（初始隐藏）
	_new_game_btn = _make_slot_button("新游戏", Vector2(vs.x / 2 + 112, btn_y))
	_new_game_btn.add_theme_color_override("font_color", Color(0.32, 0.45, 0.22, 1))
	_new_game_btn.pressed.connect(_start_new_game_in_slot)
	_new_game_btn.visible = false
	add_child(_new_game_btn)


func _make_slot_button(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(148, 48)
	btn.add_theme_font_size_override("font_size", 15)
	_apply_title_button(btn)
	return btn


func _refresh_slot_list(slots: Array) -> void:
	## 统一刷新槽位列表（支持"加载"和"新游戏"两种模式）
	for c in _slot_list.get_children():
		c.queue_free()
	_slot_containers.clear()

	for i in slots.size():
		var s: Dictionary = slots[i]
		var slot_num: int = s["slot"]  # 0-based 内部索引
		var occupied: bool = s["occupied"]
		var container := Panel.new()
		container.custom_minimum_size = Vector2(480, 72)

		var final_slot := slot_num
		if occupied or _slot_mode == "new_game":
			container.gui_input.connect(
				func(event: InputEvent):
					if event is InputEventMouseButton and event.pressed:
						_select_slot(final_slot)
			)
		container.add_theme_stylebox_override(
			"panel",
			_paper_slot_style(false, not occupied and _slot_mode == "load")
		)

		if occupied:
			# 已有存档
			var label := Label.new()
			label.position = Vector2(28, 10)
			label.text = "存档 %d  —  %s" % [slot_num + 1, s.get("timestamp_readable", "")]
			label.add_theme_color_override("font_color", PAPER_INK)
			label.add_theme_font_size_override("font_size", 14)
			container.add_child(label)

			var info := Label.new()
			info.position = Vector2(28, 38)
			var phase_names: Array[String] = ["初始", "探索", "危机A", "危机B", "论坛", "终局"]
			var phase: int = s.get("phase", 0)
			var phase_name: String = phase_names[min(phase, phase_names.size() - 1)]
			info.text = "角色: %s  |  进度: %.0f%%  |  阶段: %s" % [
				s.get("player_name", "?"),
				s.get("progress", 0) * 100,
				phase_name,
			]
			info.add_theme_color_override("font_color", PAPER_INK_MUTED)
			info.add_theme_font_size_override("font_size", 11)
			container.add_child(info)

			# 新游戏模式：被占用的槽位显示覆盖警告
			if _slot_mode == "new_game":
				var warn := Label.new()
				warn.position = Vector2(350, 47)
				warn.text = "[注意] 将被覆盖"
				warn.add_theme_color_override("font_color", PAPER_WARNING)
				warn.add_theme_font_size_override("font_size", 10)
				container.add_child(warn)
		else:
			# 空槽位
			var label := Label.new()
			label.position = Vector2(28, 24)
			if _slot_mode == "load":
				label.text = "存档 %d  —  [ 空 ]" % (slot_num + 1)
				label.add_theme_color_override("font_color", PAPER_DIM)
			else:
				label.text = "存档 %d  —  [ 空槽位 ]" % (slot_num + 1)
				label.add_theme_color_override("font_color", PAPER_INK_MUTED)
			label.add_theme_font_size_override("font_size", 14)
			container.add_child(label)

		_slot_list.add_child(container)
		_slot_containers.append(container)

	_slot_selected = -1


func _select_slot(index: int) -> void:
	_slot_selected = index
	for i in _slot_containers.size():
		var container := _slot_containers[i]
		container.add_theme_stylebox_override(
			"panel", _paper_slot_style(i == _slot_selected)
		)


func _load_selected_slot() -> void:
	if _slot_selected < 0:
		return
	var slots := SaveManager.list_slots()
	if _slot_selected >= slots.size() or not slots[_slot_selected]["occupied"]:
		_show_hint_dialog("提示", "没有找到存档文件。")
		return
	var slot := _slot_selected
	print("[TitleScreen] 加载存档 slot %d" % slot)
	SaveManager.load_game(slot)
	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _delete_selected_slot() -> void:
	if _slot_selected < 0:
		return
	var slot := _slot_selected
	SaveManager.delete_slot(slot)
	_has_saves = _has_occupied_save_slots()
	_refresh_slot_list(SaveManager.list_slots())


# ============================================================
# 纸雕样式辅助方法（保留 — 弹窗按钮和存档面板按钮仍在使用）
# ============================================================

func _paper_style(texture: Texture2D, margin: float, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = margin * 0.55
	style.content_margin_top = margin * 0.45
	style.content_margin_right = margin * 0.55
	style.content_margin_bottom = margin * 0.45
	style.modulate_color = tint
	return style


func _paper_panel_style(tint := Color.WHITE) -> StyleBoxTexture:
	return _paper_style(PAPER_PANEL, 72.0, tint)


func _paper_slot_style(selected := false, unavailable := false) -> StyleBoxTexture:
	var tint := Color(1, 1, 1, 1)
	if selected:
		tint = Color(1.12, 1.03, 0.82, 1)
	elif unavailable:
		tint = Color(0.82, 0.80, 0.74, 0.82)
	return _paper_style(PAPER_SLOT, 32.0, tint)


func _apply_title_button(button: Button, selected := false, unavailable := false) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_paper_style(PAPER_BUTTON_DISABLED if unavailable else PAPER_BUTTON_NORMAL, 24.0)
	)
	button.add_theme_stylebox_override("hover", _paper_style(PAPER_BUTTON_HOVER, 24.0))
	button.add_theme_stylebox_override("focus", _paper_style(PAPER_BUTTON_HOVER, 24.0))
	button.add_theme_stylebox_override("pressed", _paper_style(PAPER_BUTTON_PRESSED, 24.0))
	button.add_theme_stylebox_override("disabled", _paper_style(PAPER_BUTTON_DISABLED, 24.0))
	button.add_theme_color_override(
		"font_color",
		PAPER_INK if selected else (PAPER_DIM if unavailable else PAPER_INK_MUTED)
	)
	button.add_theme_color_override("font_hover_color", PAPER_INK)
	button.add_theme_color_override("font_focus_color", PAPER_INK)
	button.add_theme_color_override("font_pressed_color", Color(0.92, 0.84, 0.62, 1.0))
	button.add_theme_color_override("font_disabled_color", PAPER_DIM)
