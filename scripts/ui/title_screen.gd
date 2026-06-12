extends Control
## 溯光计划 — 标题画面（重构版）
## 五个交互热区垂直排列在画面右侧（背景图已包含按钮视觉）：
##   开始游戏 / 游戏存档 / 成就 / 剧情回顾 / 退出游戏
## 键盘导航：↑↓选择  Enter确认  Esc关闭（弹窗/存档界面中）
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
const PAPER_PANEL = preload("res://assets/papercraft/core/ui/dialogue_box/dialogue_panel.png")
const PAPER_BUTTON_NORMAL = preload("res://assets/papercraft/core/ui/dialogue_box/button_plate.png")
const PAPER_BUTTON_HOVER = preload("res://assets/papercraft/core/ui/extracted_buttons/hover_blank.png")
const PAPER_BUTTON_PRESSED = preload("res://assets/papercraft/core/ui/extracted_buttons/pressed_blank.png")
const PAPER_BUTTON_DISABLED = preload("res://assets/papercraft/core/ui/dialogue_box/button_plate.png")

# ============================================================
# 颜色常量
# ============================================================
const PAPER_INK := Color(0.18, 0.12, 0.075, 1.0)
const PAPER_INK_MUTED := Color(0.33, 0.25, 0.17, 0.95)
const PAPER_DIM := Color(0.36, 0.34, 0.30, 0.62)

# ============================================================
# 布局常量 — 热区坐标与背景图按钮精确对齐
# 基于设计稿（1280×720 参考分辨率），所有 5 个按钮 X 范围一致：735 ~ 1140
# 运行时按 viewport / REFERENCE_SIZE 等比缩放，适配任意窗口
# ============================================================
const REFERENCE_SIZE := Vector2(1280, 720)
const BTN_COUNT := 5
## 5 个热区的矩形区域（设计稿精确坐标，1280×720 基准下）
const HIT_RECTS: Array[Rect2] = [
	Rect2(735, 75, 405, 100),   # 按钮1：开始游戏
	Rect2(735, 195, 405, 85),   # 按钮2：游戏存档
	Rect2(735, 300, 405, 80),   # 按钮3：成就
	Rect2(735, 400, 405, 80),   # 按钮4：剧情回顾
	Rect2(735, 500, 405, 80),   # 按钮5：退出游戏
]
const DEFAULT_TITLE_BG_SIZE := Vector2(1672, 941)
const START_DIALOG_SIZE := Vector2(1659, 948)
const DIALOG_HIGHLIGHT_COLOR := Color(0.75, 0.50, 0.18, 0.24)
const SAVE_SLOT_HOVER_COLOR := Color(0.70, 0.46, 0.16, 0.22)
const SAVE_SLOT_SELECTED_COLOR := Color(0.95, 0.62, 0.16, 0.32)
const SAVE_SLOT_GOLD := Color(0.92, 0.70, 0.30, 0.98)
const SAVE_SLOT_GOLD_MUTED := Color(0.72, 0.55, 0.28, 0.72)
const SAVE_SLOT_OUTLINE := Color(0.0, 0.0, 0.0, 1.0)
const SAVE_SLOT_OUTLINE_SIZE := 3

# ============================================================
# 成员变量
# ============================================================
var _selected: int = 0
var _has_saves: bool = false

# 存档面板相关
var _save_slots_visible: bool = false
var _slot_selected: int = -1
var _slot_mode: String = ""  # "load" 或 "new_game"
var _save_slot_labels: Array[Dictionary] = []

# 活跃弹窗引用（防止同时弹出多个）
var _active_dialog: Node = null
var _start_dialog_selected: int = 0
var _overwrite_dialog_selected: int = 0
var _overwrite_target_slot: int = -1

@onready var _bg: TextureRect = $BG
@onready var _dark_wash: ColorRect = $DarkWash
@onready var _start_save_dialog: Control = $StartSaveDialog
@onready var _start_save_dialog_panel: Control = $StartSaveDialog/PanelRoot
@onready var _start_no_save_dialog: Control = $StartNoSaveDialog
@onready var _start_no_save_dialog_panel: Control = $StartNoSaveDialog/PanelRoot
@onready var _save_not_found_dialog: Control = $SaveNotFoundDialog
@onready var _save_not_found_dialog_panel: Control = $SaveNotFoundDialog/PanelRoot
@onready var _save_overwrite_dialog: Control = $SaveOverwriteDialog
@onready var _save_overwrite_dialog_panel: Control = $SaveOverwriteDialog/PanelRoot
@onready var _save_slots_screen: Control = $SaveSlotsScreen
@onready var _save_slots_panel: Control = $SaveSlotsScreen/PanelRoot
@onready var _hit_container: Control = $HitContainer
@onready var _selection_highlight: ColorRect = $HitContainer/SelectionHighlight
@onready var _hit_areas: Array[Control] = [$HitContainer/HitArea1, $HitContainer/HitArea2, $HitContainer/HitArea3, $HitContainer/HitArea4, $HitContainer/HitArea5]
@onready var _version_label: Label = $VersionLabel
@onready var _start_dialog_highlight: ColorRect = $StartSaveDialog/PanelRoot/DialogHighlight
@onready var _start_new_game_button: Button = $StartSaveDialog/PanelRoot/StartNewGameButton
@onready var _continue_game_button: Button = $StartSaveDialog/PanelRoot/ContinueGameButton
@onready var _no_save_dialog_highlight: ColorRect = $StartNoSaveDialog/PanelRoot/DialogHighlight
@onready var _no_save_new_game_button: Button = $StartNoSaveDialog/PanelRoot/StartNewGameButton
@onready var _save_not_found_dialog_highlight: ColorRect = $SaveNotFoundDialog/PanelRoot/DialogHighlight
@onready var _save_not_found_ok_button: Button = $SaveNotFoundDialog/PanelRoot/OkButton
@onready var _save_overwrite_dialog_highlight: ColorRect = $SaveOverwriteDialog/PanelRoot/DialogHighlight
@onready var _save_overwrite_yes_button: Button = $SaveOverwriteDialog/PanelRoot/YesButton
@onready var _save_overwrite_no_button: Button = $SaveOverwriteDialog/PanelRoot/NoButton
@onready var _save_slot_highlight: ColorRect = $SaveSlotsScreen/PanelRoot/SlotHighlight
@onready var _save_slot_selected_highlight: ColorRect = $SaveSlotsScreen/PanelRoot/SlotSelectedHighlight
@onready var _save_slot_buttons: Array[Button] = [$SaveSlotsScreen/PanelRoot/Slot1Button, $SaveSlotsScreen/PanelRoot/Slot2Button, $SaveSlotsScreen/PanelRoot/Slot3Button]
@onready var _save_slot_load_button: Button = $SaveSlotsScreen/PanelRoot/LoadButton
@onready var _save_slot_delete_button: Button = $SaveSlotsScreen/PanelRoot/DeleteButton
@onready var _settings_gear_button: BaseButton = $SettingsGearButton
@onready var _settings_panel: SettingsPanel = $SettingsPanel


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_apply_skin()
	_setup_hit_areas()
	_setup_start_save_dialog()
	_setup_no_save_dialog()
	_setup_save_not_found_dialog()
	_setup_save_overwrite_dialog()
	_setup_save_slots_screen()
	_setup_settings_panel()
	_layout_all()
	get_viewport().size_changed.connect(_layout_all)

	_has_saves = _has_occupied_save_slots()
	_selected = 0  # 默认选中「开始游戏」
	_update_selection()

	# 播放标题画面主题曲
	_start_bgm()


func _apply_skin() -> void:
	_bg.texture = PAPER_TITLE_BG
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dark_wash.color = Color(0.09, 0.07, 0.045, 0.1)


func _setup_hit_areas() -> void:
	## 连接场景中热区节点的信号（节点已在 tscn 中定义）
	for i in _hit_areas.size():
		var idx := i  # 捕获循环变量，避免 lambda 闭包引用同一变量
		var area := _hit_areas[i]
		area.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton \
					and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed:
				_on_button_pressed(idx)
		)
		area.mouse_entered.connect(func(): _on_button_hovered(idx))


func _setup_start_save_dialog() -> void:
	_start_save_dialog.visible = false
	_start_save_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_dialog_highlight.color = DIALOG_HIGHLIGHT_COLOR
	_start_dialog_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var buttons_ready := true
	buttons_ready = _connect_button_pressed(_start_new_game_button, _on_start_dialog_new_game, "StartSaveDialog/PanelRoot/StartNewGameButton") and buttons_ready
	buttons_ready = _connect_button_pressed(_continue_game_button, _on_start_dialog_continue_game, "StartSaveDialog/PanelRoot/ContinueGameButton") and buttons_ready
	if not buttons_ready:
		return
	_start_new_game_button.mouse_entered.connect(_select_start_dialog_button.bind(0))
	_continue_game_button.mouse_entered.connect(_select_start_dialog_button.bind(1))
	_start_new_game_button.focus_entered.connect(_select_start_dialog_button.bind(0))
	_continue_game_button.focus_entered.connect(_select_start_dialog_button.bind(1))
	_apply_transparent_button(_start_new_game_button)
	_apply_transparent_button(_continue_game_button)


func _setup_no_save_dialog() -> void:
	_start_no_save_dialog.visible = false
	_start_no_save_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_no_save_dialog_highlight.color = DIALOG_HIGHLIGHT_COLOR
	_no_save_dialog_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _connect_button_pressed(_no_save_new_game_button, _on_no_save_dialog_new_game, "StartNoSaveDialog/PanelRoot/StartNewGameButton"):
		return
	_no_save_new_game_button.mouse_entered.connect(_update_no_save_dialog_highlight)
	_no_save_new_game_button.focus_entered.connect(_update_no_save_dialog_highlight)
	_apply_transparent_button(_no_save_new_game_button)


func _setup_save_not_found_dialog() -> void:
	_save_not_found_dialog.visible = false
	_save_not_found_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_save_not_found_dialog_highlight.color = DIALOG_HIGHLIGHT_COLOR
	_save_not_found_dialog_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _connect_button_pressed(_save_not_found_ok_button, _hide_save_not_found_dialog, "SaveNotFoundDialog/PanelRoot/OkButton"):
		return
	_save_not_found_ok_button.mouse_entered.connect(_update_save_not_found_dialog_highlight)
	_save_not_found_ok_button.focus_entered.connect(_update_save_not_found_dialog_highlight)
	_apply_transparent_button(_save_not_found_ok_button)


func _setup_save_overwrite_dialog() -> void:
	_save_overwrite_dialog.visible = false
	_save_overwrite_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_save_overwrite_dialog_highlight.color = DIALOG_HIGHLIGHT_COLOR
	_save_overwrite_dialog_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var buttons_ready := true
	buttons_ready = _connect_button_pressed(_save_overwrite_yes_button, _confirm_overwrite_save, "SaveOverwriteDialog/PanelRoot/YesButton") and buttons_ready
	buttons_ready = _connect_button_pressed(_save_overwrite_no_button, _hide_save_overwrite_dialog, "SaveOverwriteDialog/PanelRoot/NoButton") and buttons_ready
	if not buttons_ready:
		return
	_save_overwrite_yes_button.mouse_entered.connect(_select_overwrite_dialog_button.bind(0))
	_save_overwrite_no_button.mouse_entered.connect(_select_overwrite_dialog_button.bind(1))
	_save_overwrite_yes_button.focus_entered.connect(_select_overwrite_dialog_button.bind(0))
	_save_overwrite_no_button.focus_entered.connect(_select_overwrite_dialog_button.bind(1))
	_apply_transparent_button(_save_overwrite_yes_button)
	_apply_transparent_button(_save_overwrite_no_button)


func _setup_save_slots_screen() -> void:
	_save_slots_screen.visible = false
	_save_slots_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_save_slot_highlight.color = SAVE_SLOT_HOVER_COLOR
	_save_slot_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_save_slot_selected_highlight.color = SAVE_SLOT_SELECTED_COLOR
	_save_slot_selected_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_save_slot_labels = [
		{
			"name": $SaveSlotsScreen/PanelRoot/Slot1Name,
			"time": $SaveSlotsScreen/PanelRoot/Slot1Time,
			"date": $SaveSlotsScreen/PanelRoot/Slot1Date,
			"progress": $SaveSlotsScreen/PanelRoot/Slot1Progress,
		},
		{
			"name": $SaveSlotsScreen/PanelRoot/Slot2Name,
			"time": $SaveSlotsScreen/PanelRoot/Slot2Time,
			"date": $SaveSlotsScreen/PanelRoot/Slot2Date,
			"progress": $SaveSlotsScreen/PanelRoot/Slot2Progress,
		},
		{
			"name": $SaveSlotsScreen/PanelRoot/Slot3Name,
			"time": $SaveSlotsScreen/PanelRoot/Slot3Time,
			"date": $SaveSlotsScreen/PanelRoot/Slot3Date,
			"progress": $SaveSlotsScreen/PanelRoot/Slot3Progress,
		},
	]

	for i in _save_slot_buttons.size():
		var idx := i
		var button := _save_slot_buttons[i]
		if button == null:
			push_error("[TitleScreen] Missing save slot button at index %d" % idx)
			continue
		_apply_transparent_button(button)
		button.mouse_entered.connect(_hover_save_slot.bind(idx))
		button.focus_entered.connect(_select_slot.bind(idx))
		_connect_button_pressed(button, _select_slot.bind(idx), "SaveSlotsScreen/PanelRoot/Slot%dButton" % (idx + 1))

	var controls_ready := true
	controls_ready = _connect_button_pressed(_save_slot_load_button, _activate_selected_slot, "SaveSlotsScreen/PanelRoot/LoadButton") and controls_ready
	controls_ready = _connect_button_pressed(_save_slot_delete_button, _delete_selected_slot, "SaveSlotsScreen/PanelRoot/DeleteButton") and controls_ready
	if not controls_ready:
		return
	_apply_transparent_button(_save_slot_load_button)
	_apply_transparent_button(_save_slot_delete_button)
	_save_slot_load_button.mouse_entered.connect(_highlight_save_control.bind(_save_slot_load_button))
	_save_slot_delete_button.mouse_entered.connect(_highlight_save_control.bind(_save_slot_delete_button))
	_save_slot_load_button.focus_entered.connect(_highlight_save_control.bind(_save_slot_load_button))
	_save_slot_delete_button.focus_entered.connect(_highlight_save_control.bind(_save_slot_delete_button))

	for label_set in _save_slot_labels:
		for key in label_set:
			var label := label_set[key] as Label
			label.add_theme_color_override("font_color", SAVE_SLOT_GOLD)
			label.add_theme_color_override("font_outline_color", SAVE_SLOT_OUTLINE)
			label.add_theme_color_override("font_shadow_color", Color(0.95, 0.72, 0.28, 0.35))
			label.add_theme_constant_override("outline_size", SAVE_SLOT_OUTLINE_SIZE)
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 1)


func _setup_settings_panel() -> void:
	if _settings_panel == null:
		push_error("[TitleScreen] Missing SettingsPanel node")
		return
	_settings_panel.visible = false
	if not _connect_button_pressed(_settings_gear_button, _show_settings_panel, "SettingsGearButton"):
		return
	_settings_panel.panel_opened.connect(func():
		_hit_container.visible = false
		_version_label.visible = false
	)
	_settings_panel.panel_closed.connect(func():
		if not _save_slots_visible:
			_hit_container.visible = true
			_version_label.visible = true
			_update_selection()
	)


func _show_settings_panel() -> void:
	_settings_panel.open()


func _connect_button_pressed(button: BaseButton, callback: Callable, node_path: String) -> bool:
	if button == null:
		push_error("[TitleScreen] Missing BaseButton node: %s" % node_path)
		return false
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	return true


# ============================================================
# BGM 播放
# ============================================================

var _bgm_player: AudioStreamPlayer = null

const BGM_MAIN_THEME = preload("res://assets/audio/bgm/bgm_main_theme.ogg")

func _start_bgm() -> void:
	if _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.name = "BGMPlayer"
		_bgm_player.bus = "Master"
		_bgm_player.volume_db = -6.0
		add_child(_bgm_player)
	_bgm_player.stream = BGM_MAIN_THEME
	var ogg_stream := _bgm_player.stream as AudioStreamOggVorbis
	if ogg_stream != null:
		ogg_stream.loop = true
	_bgm_player.play()

func _stop_bgm() -> void:
	if _bgm_player != null and _bgm_player.playing:
		_bgm_player.stop()

# ============================================================
# 响应式布局
# ============================================================

func _layout_all() -> void:
	_layout_hit_areas()
	_layout_version_label()
	_layout_start_save_dialog()
	_layout_no_save_dialog()
	_layout_save_not_found_dialog()
	_layout_save_overwrite_dialog()
	_layout_save_slots_screen()


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


func _layout_start_save_dialog() -> void:
	_layout_start_dialog_panel(_start_save_dialog_panel)
	if _start_save_dialog.visible:
		call_deferred("_update_start_dialog_highlight")


func _layout_no_save_dialog() -> void:
	_layout_start_dialog_panel(_start_no_save_dialog_panel)
	if _start_no_save_dialog.visible:
		call_deferred("_update_no_save_dialog_highlight")


func _layout_save_not_found_dialog() -> void:
	_layout_start_dialog_panel(_save_not_found_dialog_panel)
	if _save_not_found_dialog.visible:
		call_deferred("_update_save_not_found_dialog_highlight")


func _layout_save_overwrite_dialog() -> void:
	_layout_start_dialog_panel(_save_overwrite_dialog_panel)
	if _save_overwrite_dialog.visible:
		call_deferred("_update_save_overwrite_dialog_highlight")


func _layout_save_slots_screen() -> void:
	_layout_start_dialog_panel(_save_slots_panel)
	if _save_slots_visible:
		call_deferred("_update_save_slot_highlight")


func _layout_start_dialog_panel(panel: Control) -> void:
	var vs := _get_layout_size()
	var texture_size := START_DIALOG_SIZE

	var max_size := Vector2(vs.x * 0.82, vs.y * 0.74)
	var scale_factor: float = minf(
		max_size.x / texture_size.x,
		max_size.y / texture_size.y
	)
	scale_factor = minf(scale_factor, 0.62)

	var panel_size := texture_size * scale_factor
	panel.position = (vs - panel_size) * 0.5
	panel.size = panel_size


func _is_active_dialog_visible() -> bool:
	return _active_dialog != null \
			and is_instance_valid(_active_dialog) \
			and bool(_active_dialog.get("visible"))


func _select_start_dialog_button(index: int) -> void:
	_start_dialog_selected = clampi(index, 0, 1)
	_update_start_dialog_highlight()


func _update_start_dialog_highlight() -> void:
	var target := _start_new_game_button if _start_dialog_selected == 0 else _continue_game_button
	_start_dialog_highlight.visible = true
	_start_dialog_highlight.position = target.position
	_start_dialog_highlight.size = target.size
	_start_dialog_highlight.move_to_front()
	target.grab_focus()


func _update_no_save_dialog_highlight() -> void:
	_no_save_dialog_highlight.visible = true
	_no_save_dialog_highlight.position = _no_save_new_game_button.position
	_no_save_dialog_highlight.size = _no_save_new_game_button.size
	_no_save_dialog_highlight.move_to_front()
	_no_save_new_game_button.grab_focus()


func _update_save_not_found_dialog_highlight() -> void:
	_save_not_found_dialog_highlight.visible = true
	_save_not_found_dialog_highlight.position = _save_not_found_ok_button.position
	_save_not_found_dialog_highlight.size = _save_not_found_ok_button.size
	_save_not_found_dialog_highlight.move_to_front()
	_save_not_found_ok_button.grab_focus()


func _select_overwrite_dialog_button(index: int) -> void:
	_overwrite_dialog_selected = clampi(index, 0, 1)
	_update_save_overwrite_dialog_highlight()


func _update_save_overwrite_dialog_highlight() -> void:
	var target := _save_overwrite_yes_button if _overwrite_dialog_selected == 0 else _save_overwrite_no_button
	_save_overwrite_dialog_highlight.visible = true
	_save_overwrite_dialog_highlight.position = target.position
	_save_overwrite_dialog_highlight.size = target.size
	_save_overwrite_dialog_highlight.move_to_front()
	target.grab_focus()


func _highlight_save_control(control: Control, grab_focus := true) -> void:
	_save_slot_highlight.visible = true
	_save_slot_highlight.position = control.position
	_save_slot_highlight.size = control.size
	if grab_focus:
		control.grab_focus()


func _hover_save_slot(index: int) -> void:
	if index < 0 or index >= _save_slot_buttons.size():
		return
	_highlight_save_control(_save_slot_buttons[index], false)


func _update_selected_save_slot_highlight() -> void:
	if _slot_selected < 0 or _slot_selected >= _save_slot_buttons.size():
		_save_slot_selected_highlight.visible = false
		return
	var button := _save_slot_buttons[_slot_selected]
	_save_slot_selected_highlight.visible = true
	_save_slot_selected_highlight.position = button.position
	_save_slot_selected_highlight.size = button.size


func _update_save_slot_highlight() -> void:
	_update_selected_save_slot_highlight()


# ============================================================
# 键盘导航
# ============================================================

func _input(event: InputEvent) -> void:
	if _settings_panel and _settings_panel.is_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_settings_panel.cancel()
			get_viewport().set_input_as_handled()
		return

	if _save_overwrite_dialog.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_hide_save_overwrite_dialog()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			_select_overwrite_dialog_button(0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			_select_overwrite_dialog_button(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			if _overwrite_dialog_selected == 0:
				_confirm_overwrite_save()
			else:
				_hide_save_overwrite_dialog()
			get_viewport().set_input_as_handled()
		return

	if _save_not_found_dialog.visible:
		if event.is_action_pressed("ui_cancel") \
				or event.is_action_pressed("escape") \
				or event.is_action_pressed("ui_accept") \
				or event.is_action_pressed("interact"):
			_hide_save_not_found_dialog()
			get_viewport().set_input_as_handled()
		return

	# 存档面板打开时，Esc 关闭面板
	if _save_slots_visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_hide_save_slots()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_select_slot(wrapi(_slot_selected - 1, 0, _save_slot_buttons.size()))
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_select_slot(wrapi(_slot_selected + 1, 0, _save_slot_buttons.size()))
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_activate_selected_slot()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
			_delete_selected_slot()
			get_viewport().set_input_as_handled()
		return

	if _start_save_dialog.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_hide_start_game_dialog()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			_select_start_dialog_button(0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			_select_start_dialog_button(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			if _start_dialog_selected == 0:
				_on_start_dialog_new_game()
			else:
				_on_start_dialog_continue_game()
			get_viewport().set_input_as_handled()
		return

	if _start_no_save_dialog.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_hide_no_save_dialog()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_on_no_save_dialog_new_game()
			get_viewport().set_input_as_handled()
		return

	# 有弹窗打开时不响应键盘
	if _is_active_dialog_visible():
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
		_selection_highlight.visible = true
		_selection_highlight.position = target.position
		_selection_highlight.size = target.size
		target.grab_focus()


func _on_button_hovered(index: int) -> void:
	_selected = index
	_update_selection()


func _on_button_pressed(index: int) -> void:
	if _is_active_dialog_visible():
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
	return false


func _show_start_game_dialog() -> void:
	_layout_start_save_dialog()
	_start_save_dialog.visible = true
	_start_save_dialog.move_to_front()
	_active_dialog = _start_save_dialog
	_select_start_dialog_button(0)


func _hide_start_game_dialog() -> void:
	_start_save_dialog.visible = false
	_start_dialog_highlight.visible = false
	if _active_dialog == _start_save_dialog:
		_active_dialog = null


func _on_start_dialog_new_game() -> void:
	_hide_start_game_dialog()
	_show_save_slots("new_game")


func _on_start_dialog_continue_game() -> void:
	_hide_start_game_dialog()
	_continue_game()


func _show_no_save_dialog() -> void:
	_layout_no_save_dialog()
	_start_no_save_dialog.visible = true
	_start_no_save_dialog.move_to_front()
	_active_dialog = _start_no_save_dialog
	_update_no_save_dialog_highlight()


func _hide_no_save_dialog() -> void:
	_start_no_save_dialog.visible = false
	_no_save_dialog_highlight.visible = false
	if _active_dialog == _start_no_save_dialog:
		_active_dialog = null


func _on_no_save_dialog_new_game() -> void:
	_hide_no_save_dialog()
	_show_save_slots("new_game")


func _show_save_not_found_dialog() -> void:
	_layout_save_not_found_dialog()
	_save_not_found_dialog.visible = true
	_save_not_found_dialog.move_to_front()
	_active_dialog = _save_not_found_dialog
	_update_save_not_found_dialog_highlight()


func _hide_save_not_found_dialog() -> void:
	_save_not_found_dialog.visible = false
	_save_not_found_dialog_highlight.visible = false
	if _save_slots_visible:
		_active_dialog = _save_slots_screen
	elif _active_dialog == _save_not_found_dialog:
		_active_dialog = null


func _show_save_overwrite_dialog(slot: int) -> void:
	_overwrite_target_slot = slot
	_overwrite_dialog_selected = 1
	_layout_save_overwrite_dialog()
	_save_overwrite_dialog.visible = true
	_save_overwrite_dialog.move_to_front()
	_active_dialog = _save_overwrite_dialog
	_update_save_overwrite_dialog_highlight()


func _hide_save_overwrite_dialog() -> void:
	_save_overwrite_dialog.visible = false
	_save_overwrite_dialog_highlight.visible = false
	_overwrite_target_slot = -1
	if _save_slots_visible:
		_active_dialog = _save_slots_screen
	elif _active_dialog == _save_overwrite_dialog:
		_active_dialog = null


func _confirm_overwrite_save() -> void:
	var slot := _overwrite_target_slot
	if slot < 0:
		_hide_save_overwrite_dialog()
		return
	_hide_save_overwrite_dialog()
	_start_new_game_in_slot_unchecked(slot)


func _start_new_game_in_slot() -> void:
	if _slot_selected < 0:
		return
	var slot := _slot_selected
	var slots := SaveManager.list_slots()
	if slot < slots.size() and bool(slots[slot].get("occupied", false)):
		_show_save_overwrite_dialog(slot)
		return
	_start_new_game_in_slot_unchecked(slot)


func _start_new_game_in_slot_unchecked(slot: int) -> void:
	print("[TitleScreen] 在槽位 %d 开始新游戏，播放开场动画" % slot)

	GameManager.new_game()
	SaveManager.set_current_slot(slot)
	ChatDatabase.clear_all_history()
	SaveManager.save_game(slot)

	_stop_bgm()
	SceneManager.pending_spawn_point = "from_cutscene"
	# 新游戏 → 开场动画 → 星图
	get_tree().change_scene_to_file("res://scenes/cinematic/opening_cinematic.tscn")


func _continue_game() -> void:
	var slot := SaveManager.get_last_active_slot()
	if slot < 0:
		_show_save_not_found_dialog()
		return
	print("[TitleScreen] 继续游戏 (slot %d)" % slot)
	SaveManager.load_game(slot)
	_stop_bgm()
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
	dlg.close_requested.connect(func(): if _active_dialog == dlg: _active_dialog = null; dlg.queue_free())
	dlg.tree_exiting.connect(func(): if _active_dialog == dlg: _active_dialog = null; dlg.queue_free())

	add_child(dialog)
	_active_dialog = dialog
	dialog.popup_centered()


func _apply_dialog_panel_style(dialog: Window) -> void:
	if dialog.has_method("add_theme_stylebox_override"):
		dialog.add_theme_stylebox_override("panel", _paper_panel_style())


# ============================================================
# 存档加载界面
# 背景图内置存档视觉，只叠加三槽位/加载/删除透明交互热区
# ============================================================

func _show_save_slots(mode: String = "load") -> void:
	_slot_mode = mode
	var slots := SaveManager.list_slots()

	_save_slots_visible = true
	_slot_selected = 0

	# 隐藏主菜单热区和版本标签
	_hit_container.visible = false
	_version_label.visible = false

	_layout_save_slots_screen()
	_save_slots_screen.visible = true
	_save_slots_screen.move_to_front()
	_active_dialog = _save_slots_screen
	_refresh_slot_list(slots)
	_select_slot(0)


func _hide_save_slots() -> void:
	_save_slots_visible = false
	_slot_selected = -1
	_slot_mode = ""
	_save_slots_screen.visible = false
	_save_slot_highlight.visible = false
	_save_slot_selected_highlight.visible = false
	if _active_dialog == _save_slots_screen:
		_active_dialog = null

	_hit_container.visible = true
	_version_label.visible = true
	_update_selection()


func _refresh_slot_list(slots: Array) -> void:
	## 刷新场景内存档界面字段（支持"加载"和"新游戏"两种模式）
	for i in range(mini(SaveConstants.MAX_SLOTS, _save_slot_labels.size())):
		var s: Dictionary = slots[i] if i < slots.size() else {
			"slot": i,
			"occupied": false,
		}
		var labels: Dictionary = _save_slot_labels[i]
		var occupied: bool = s.get("occupied", false)
		var muted := SAVE_SLOT_GOLD_MUTED
		var ink := SAVE_SLOT_GOLD

		if occupied:
			(labels["name"] as Label).text = s.get("save_name", _default_save_name(i))
			(labels["time"] as Label).text = _format_play_time(float(s.get("play_time_seconds", 0.0)))
			(labels["date"] as Label).text = _format_save_date(s)
			(labels["progress"] as Label).text = "%.0f%%" % (float(s.get("progress", 0.0)) * 100.0)
			for key in labels:
				(labels[key] as Label).add_theme_color_override("font_color", ink)
		else:
			(labels["name"] as Label).text = "空槽位"
			(labels["time"] as Label).text = "--:--:--"
			(labels["date"] as Label).text = "----.--.--"
			(labels["progress"] as Label).text = "--%"
			for key in labels:
				(labels[key] as Label).add_theme_color_override("font_color", muted)


func _select_slot(index: int) -> void:
	_slot_selected = clampi(index, 0, _save_slot_buttons.size() - 1)
	_update_save_slot_highlight()


func _activate_selected_slot() -> void:
	if _slot_mode == "new_game":
		_start_new_game_in_slot()
	else:
		_load_selected_slot()


func _default_save_name(slot: int) -> String:
	return "溯光档案 %02d" % (slot + 1)


func _format_play_time(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]


func _format_save_date(slot_info: Dictionary) -> String:
	var readable: String = str(slot_info.get("timestamp_readable", ""))
	if readable.length() >= 10:
		return readable.substr(0, 10).replace("-", ".")

	var timestamp := int(slot_info.get("timestamp", 0))
	if timestamp <= 0:
		return "----.--.--"
	var date := Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d.%02d.%02d" % [date["year"], date["month"], date["day"]]


func _load_selected_slot() -> void:
	if _slot_selected < 0:
		return
	var slots := SaveManager.list_slots()
	if _slot_selected >= slots.size() or not slots[_slot_selected]["occupied"]:
		_show_save_not_found_dialog()
		return
	var slot := _slot_selected
	print("[TitleScreen] 加载存档 slot %d" % slot)
	SaveManager.load_game(slot)
	_stop_bgm()
	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _delete_selected_slot() -> void:
	if _slot_selected < 0:
		return
	var slot := _slot_selected
	SaveManager.delete_slot(slot)
	_has_saves = _has_occupied_save_slots()
	_refresh_slot_list(SaveManager.list_slots())
	_select_slot(slot)


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


func _apply_transparent_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
