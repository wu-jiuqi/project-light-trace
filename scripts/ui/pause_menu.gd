extends Control
## ESC暂停菜单 — autoload
## 三个选项框：返回星图(副本内可见) / 保存 / 返回菜单
## 三个存档位：0, 1, 2（显示为存档 1/2/3），与标题画面一致

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal menu_opened
signal menu_closed

var is_open: bool = false
var _save_slots_visible: bool = false
var _canvas: CanvasLayer
var _overlay: ColorRect
var _panel: Panel
var _title_label: Label
var _menu_vbox: VBoxContainer
var _menu_buttons: Array[Button] = []
var _in_fragment: bool = false

var _slot_overlay: Panel
var _slot_buttons: Array[Button] = []
var _back_btn: Button
var _ui_built: bool = false


func _ready() -> void:
	# 关键：paused=true 时菜单自身必须继续运行
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 根节点不拦截任何输入事件
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	_canvas.name = "PauseMenuLayer"
	add_child(_canvas)
	
	# 用 _input 而非 _unhandled_input（确保可靠触发）
	set_process_input(true)
	
	# 延迟连接 FragmentManager（autoload 加载顺序不确定）
	call_deferred("_connect_signals")
	call_deferred("_ensure_ui")


func _connect_signals() -> void:
	if FragmentManager and FragmentManager.has_signal("fragment_entered"):
		FragmentManager.fragment_entered.connect(func(_id: String): _in_fragment = true)


# ============================================================
# 输入处理
# ============================================================

func _input(event: InputEvent) -> void:
	if not (event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape")):
		return
	
	# 标题画面不需要 ESC 菜单
	if _is_on_title_screen():
		return
	
	# ChatDialogue 打开时 ESC 归它管
	if ChatDialogue and ChatDialogue.is_open:
		return
	
	toggle()
	get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open: return
	_ensure_ui()
	
	is_open = true
	_save_slots_visible = false
	
	_rebuild_menu()
	_refresh_slot_buttons()  # 强制刷新，确保与标题画面操作同步
	_overlay.visible = true
	_panel.visible = true
	if _slot_overlay: _slot_overlay.visible = false
	
	menu_opened.emit()
	get_tree().paused = true
	print("[PauseMenu] 打开")


func close() -> void:
	if not is_open: return
	is_open = false
	_save_slots_visible = false
	
	_overlay.visible = false
	_panel.visible = false
	if _slot_overlay: _slot_overlay.visible = false
	
	get_tree().paused = false
	menu_closed.emit()
	print("[PauseMenu] 关闭")


# ============================================================
# UI 构建
# ============================================================

func _ensure_ui() -> void:
	if _ui_built: return
	_ui_built = true
	_build_ui()


func _build_ui() -> void:
	var vs = get_viewport_rect().size
	if vs.x <= 0: vs = Vector2(1280, 720)
	
	# 全屏遮罩
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_canvas.add_child(_overlay)
	
	# 菜单面板
	var pw = 360; var ph = 460
	_panel = Panel.new()
	_panel.position = Vector2((vs.x - pw) / 2, (vs.y - ph) / 2)
	_panel.size = Vector2(pw, ph)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.08, 0.11, 0.92)
	ps.set_corner_radius_all(12)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 1
	ps.border_color = Color(0.35, 0.35, 0.4, 0.4)
	_panel.add_theme_stylebox_override("panel", ps)
	_panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	_panel.visible = false
	_canvas.add_child(_panel)
	
	# 标题
	_title_label = Label.new()
	_title_label.text = "菜单"
	_title_label.position = Vector2(0, 20)
	_title_label.size = Vector2(pw, 36)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1, 1))
	_title_label.add_theme_font_size_override("font_size", 23)
	_panel.add_child(_title_label)
	
	# 菜单项容器
	_menu_vbox = VBoxContainer.new()
	_menu_vbox.position = Vector2(50, 80)
	_menu_vbox.size = Vector2(pw - 100, 220)
	_menu_vbox.add_theme_constant_override("separation", 14)
	_menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_menu_vbox)
	
	# 构建存档槽位面板
	_build_save_slots_panel(vs, pw, ph)
	
	_rebuild_menu()
	print("[PauseMenu] UI构建完成")


func _rebuild_menu() -> void:
	for btn in _menu_buttons:
		btn.queue_free()
	_menu_buttons.clear()
	
	var items: Array[Dictionary] = []
	if _in_fragment:
		items.append({"text": "返回星图", "id": "star_map"})
	items.append({"text": "保存", "id": "save"})
	items.append({"text": "返回菜单", "id": "title"})
	
	for i in items.size():
		var btn = Button.new()
		btn.text = items[i]["text"]
		btn.add_theme_font_size_override("font_size", 19)
		btn.custom_minimum_size = Vector2(250, 48)
		btn.pressed.connect(_on_menu_pressed.bind(items[i]["id"]))
		
		var ns = StyleBoxFlat.new()
		ns.bg_color = Color(0.12, 0.12, 0.16, 0.5)
		ns.set_corner_radius_all(6)
		ns.border_width_left = 1; ns.border_width_right = 1
		ns.border_width_top = 1; ns.border_width_bottom = 1
		ns.border_color = Color(0.3, 0.3, 0.35, 0.3)
		btn.add_theme_stylebox_override("normal", ns)
		
		var hs = StyleBoxFlat.new()
		hs.bg_color = Color(0.18, 0.2, 0.26, 0.6)
		hs.set_corner_radius_all(6)
		hs.border_width_left = 1; hs.border_width_right = 1
		hs.border_width_top = 1; hs.border_width_bottom = 1
		hs.border_color = Color(0.5, 0.5, 0.2, 0.5)
		btn.add_theme_stylebox_override("hover", hs)
		UITheme.apply_button(btn)
		
		_menu_vbox.add_child(btn)
		_menu_buttons.append(btn)


func _build_save_slots_panel(vs: Vector2, pw: float, ph: float) -> void:
	# 安全清理：防止由于任何原因导致重复构建时按钮残留
	for btn in _slot_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_slot_buttons.clear()
	
	_slot_overlay = Panel.new()
	_slot_overlay.position = Vector2((vs.x - pw) / 2, (vs.y - ph) / 2)
	_slot_overlay.size = Vector2(pw, ph)
	_slot_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var ss = StyleBoxFlat.new()
	ss.bg_color = Color(0.08, 0.08, 0.11, 0.92)
	ss.set_corner_radius_all(12)
	ss.border_width_left = 1; ss.border_width_right = 1
	ss.border_width_top = 1; ss.border_width_bottom = 1
	ss.border_color = Color(0.35, 0.35, 0.4, 0.4)
	_slot_overlay.add_theme_stylebox_override("panel", ss)
	_slot_overlay.add_theme_stylebox_override("panel", UITheme.panel_style())
	_slot_overlay.visible = false
	_canvas.add_child(_slot_overlay)
	
	var st = Label.new()
	st.text = "选择存档位"
	st.position = Vector2(0, 20)
	st.size = Vector2(pw, 36)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_color_override("font_color", Color(0.5, 0.85, 1, 1))
	st.add_theme_font_size_override("font_size", 21)
	_slot_overlay.add_child(st)
	
	for i in range(SaveConstants.MAX_SLOTS):  # 0-based 槽位：0~4
		var slot = i  # 内部使用 0-based，和 title_screen / SaveManager 一致
		var btn = Button.new()
		btn.position = Vector2(50, 90 + i * 60)
		btn.size = Vector2(pw - 100, 48)
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_do_save.bind(slot))
		
		var info = _get_slot_info(slot)
		if info != "":
			btn.text = "存档 %d — %s" % [slot + 1, info]
		else:
			btn.text = "存档 %d — [ 空 ]" % (slot + 1)
		
		var bns = StyleBoxFlat.new()
		bns.bg_color = Color(0.12, 0.12, 0.16, 0.5)
		bns.set_corner_radius_all(6)
		bns.border_width_left = 1; bns.border_width_right = 1
		bns.border_width_top = 1; bns.border_width_bottom = 1
		bns.border_color = Color(0.3, 0.3, 0.35, 0.3)
		btn.add_theme_stylebox_override("normal", bns)
		UITheme.apply_button(btn)
		
		_slot_overlay.add_child(btn)
		_slot_buttons.append(btn)
	
	_back_btn = Button.new()
	_back_btn.position = Vector2((pw - 140) / 2, 400)
	_back_btn.size = Vector2(140, 44)
	_back_btn.text = "返回"
	_back_btn.add_theme_font_size_override("font_size", 16)
	UITheme.apply_button(_back_btn)
	_back_btn.pressed.connect(_hide_save_slots)
	_slot_overlay.add_child(_back_btn)


func _get_slot_info(slot: int) -> String:
	## slot: 0-based 内部槽位号
	## 返回时间戳字符串（非空表示有存档），空字符串表示槽位为空
	for s in SaveManager.list_slots():
		if s["slot"] == slot:
			return s.get("timestamp_readable", "")
	return ""


func _refresh_slot_buttons() -> void:
	var current = SaveManager.get_current_slot()
	for i in range(_slot_buttons.size()):
		var info = _get_slot_info(i)
		var is_current = (i == current)
		
		if info != "":
			var suffix = " [当前]" if is_current else ""
			_slot_buttons[i].text = "存档 %d — %s%s" % [i + 1, info, suffix]
		else:
			var suffix = " [当前]" if is_current else ""
			_slot_buttons[i].text = "存档 %d — [ 空 ]%s" % [i + 1, suffix]
		
		# 当前槽位使用高亮颜色
		if is_current:
			_slot_buttons[i].add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1))
			var cs = StyleBoxFlat.new()
			cs.bg_color = Color(0.15, 0.25, 0.18, 0.7)
			cs.set_corner_radius_all(6)
			cs.border_width_left = 2; cs.border_width_right = 2
			cs.border_width_top = 2; cs.border_width_bottom = 2
			cs.border_color = Color(0.4, 0.8, 0.4, 0.6)
			_slot_buttons[i].add_theme_stylebox_override("normal", cs)
			UITheme.apply_button(_slot_buttons[i], true)
		else:
			_slot_buttons[i].add_theme_color_override("font_color", Color(0.75, 0.75, 0.8, 1))
			var ns = StyleBoxFlat.new()
			ns.bg_color = Color(0.12, 0.12, 0.16, 0.5)
			ns.set_corner_radius_all(6)
			ns.border_width_left = 1; ns.border_width_right = 1
			ns.border_width_top = 1; ns.border_width_bottom = 1
			ns.border_color = Color(0.3, 0.3, 0.35, 0.3)
			_slot_buttons[i].add_theme_stylebox_override("normal", ns)
			UITheme.apply_button(_slot_buttons[i])


# ============================================================
# 菜单操作
# ============================================================

func _on_menu_pressed(id: String) -> void:
	match id:
		"star_map": _return_to_star_map()
		"save":     _show_save_slots()
		"title":    _return_to_title()


func _show_save_slots() -> void:
	_save_slots_visible = true
	_refresh_slot_buttons()
	_panel.visible = false
	_slot_overlay.visible = true


func _hide_save_slots() -> void:
	_save_slots_visible = false
	_slot_overlay.visible = false
	_panel.visible = true


func _do_save(slot: int) -> void:
	# 检查槽位是否已有存档
	if _slot_has_data(slot):
		_confirm_overwrite(slot)
		return
	
	_save_and_close(slot)


func _slot_has_data(slot: int) -> bool:
	return _get_slot_info(slot) != ""


func _confirm_overwrite(slot: int) -> void:
	var info = _get_slot_info(slot)
	var dialog = ConfirmationDialog.new()
	dialog.title = "覆盖存档"
	dialog.dialog_text = "存档 %d 已有存档\n(%s)\n\n是否覆盖？" % [slot + 1, info]
	dialog.ok_button_text = "是"
	dialog.cancel_button_text = "否"
	dialog.confirmed.connect(func():
		_save_and_close(slot)
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	_canvas.add_child(dialog)
	dialog.popup_centered()


func _save_and_close(slot: int) -> void:
	## slot: 0-based 内部槽位号
	SaveManager.set_current_slot(slot)
	SaveManager.save_game(slot)
	print("[PauseMenu] 手动存档到槽位 %d" % slot)
	_refresh_slot_buttons()  # 立即刷新，让用户看到存档已落盘
	_show_saved_notification(slot + 1)  # 用户看到的编号 = slot + 1
	# 保持面板打开，让用户确认存档状态后再返回
	await get_tree().create_timer(1.0).timeout
	_hide_save_slots()


func _return_to_title() -> void:
	close()   # 先关菜单（恢复 paused=false）
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _return_to_star_map() -> void:
	close()
	await get_tree().process_frame
	_in_fragment = false
	SceneManager.pending_spawn_point = ""
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _is_on_title_screen() -> bool:
	var path = get_tree().current_scene.scene_file_path
	return path == "res://scenes/ui/title_screen.tscn"


func _show_saved_notification(slot: int) -> void:
	## slot: 显示用的编号（1-based）
	var label = Label.new()
	label.text = "已保存到存档 %d" % slot
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport_rect().size.x / 2 - 100, 100)
	label.size = Vector2(200, 40)
	label.add_theme_color_override("font_color", Color(0.4, 1, 0.5, 1))
	label.add_theme_font_size_override("font_size", 17)
	_canvas.add_child(label)
	
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): if is_instance_valid(label): label.queue_free())
