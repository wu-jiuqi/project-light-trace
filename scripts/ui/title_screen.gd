extends Control
## RPG经典标题画面
## 四个选项框：继续游戏 / 开始新游戏 / 加载存档 / 退出游戏
## 键盘：↑↓导航  Enter确认

const UITheme = preload("res://scripts/ui/ui_theme.gd")

@export var menu_items: Array[String] = ["继续游戏", "开始新游戏", "加载存档", "退出游戏"]
var _selected: int = 0
var _has_saves: bool = false
var _save_slots_visible: bool = false
var _slot_containers: Array[Control] = []
var _load_btn: Button
var _new_game_btn: Button
var _delete_btn: Button
var _back_btn: Button
var _slot_scroll: ScrollContainer
var _slot_list: VBoxContainer
var _slot_selected: int = -1
var _slot_mode: String = ""  # "load" 或 "new_game"
var _slot_title: Label

@onready var _title_label: Label = $TitleLabel
@onready var _menu_vbox: VBoxContainer = $MenuVBox
@onready var _menu_buttons: Array[Button] = []
@onready var _bg: TextureRect = $BG
@onready var _menu_panel: Panel = $MenuPanel
@onready var _version_label: Label = $VersionLabel


func _ready() -> void:
	_apply_skin()
	_setup_menu()
	
	# 检测是否有可继续的存档（槽位中是否有已占用的）
	_has_saves = SaveManager.get_last_active_slot() >= 0
	
	if _has_saves:
		_selected = 0  # 默认选中"继续游戏"
	else:
		_selected = 1  # 无存档时默认选中"开始新游戏"
	
	_update_selection()


func _apply_skin() -> void:
	_menu_panel.add_theme_stylebox_override("panel", UITheme.panel_style())


func _setup_menu() -> void:
	for i in menu_items.size():
		var btn = Button.new()
		btn.text = menu_items[i]
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7, 1))
		btn.custom_minimum_size = Vector2(260, 52)
		
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color(0.1, 0.1, 0.13, 0)
		bs.set_corner_radius_all(6)
		bs.border_width_left = 2; bs.border_width_right = 2
		bs.border_width_top = 2; bs.border_width_bottom = 2
		bs.border_color = Color(0.3, 0.3, 0.35, 0)
		btn.add_theme_stylebox_override("normal", bs)
		
		var hs = StyleBoxFlat.new()
		hs.bg_color = Color(0.2, 0.22, 0.28, 0.3)
		hs.set_corner_radius_all(6)
		hs.border_width_left = 2; hs.border_width_right = 2
		hs.border_width_top = 2; hs.border_width_bottom = 2
		hs.border_color = Color(0.5, 0.55, 0.65, 0.3)
		btn.add_theme_stylebox_override("hover", hs)
		UITheme.apply_button(btn)
		
		btn.pressed.connect(_on_menu_pressed.bind(i))
		_menu_vbox.add_child(btn)
		_menu_buttons.append(btn)


func _input(event: InputEvent) -> void:
	if _save_slots_visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
			_hide_save_slots()
			get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_up"):
		_selected = wrapi(_selected - 1, 0, menu_items.size())
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_selected = wrapi(_selected + 1, 0, menu_items.size())
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_execute_selection()
		get_viewport().set_input_as_handled()


func _update_selection() -> void:
	for i in _menu_buttons.size():
		var btn = _menu_buttons[i]
		if i == _selected:
			btn.text = ">  %s" % menu_items[i]
			btn.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
			var ss = StyleBoxFlat.new()
			ss.bg_color = Color(0.15, 0.18, 0.25, 0.5)
			ss.set_corner_radius_all(6)
			ss.border_width_left = 2; ss.border_width_right = 2
			ss.border_width_top = 2; ss.border_width_bottom = 2
			ss.border_color = Color(0.6, 0.5, 0.2, 0.5)
			btn.add_theme_stylebox_override("normal", ss)
			UITheme.apply_button(btn, true)
			btn.grab_focus()
		else:
			btn.text = "     %s" % menu_items[i]
			# "继续游戏"无存档时灰显
			if i == 0 and not _has_saves:
				btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1))
			else:
				btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7, 1))
			var ds = StyleBoxFlat.new()
			ds.bg_color = Color(0.1, 0.1, 0.13, 0)
			ds.set_corner_radius_all(6)
			ds.border_width_left = 2; ds.border_width_right = 2
			ds.border_width_top = 2; ds.border_width_bottom = 2
			ds.border_color = Color(0.3, 0.3, 0.35, 0)
			btn.add_theme_stylebox_override("normal", ds)
			UITheme.apply_button(btn)


func _on_menu_pressed(index: int) -> void:
	_selected = index
	_update_selection()
	_execute_selection()


func _execute_selection() -> void:
	match _selected:
		0: _continue_game()
		1: _start_new_game()
		2: _show_save_slots()
		3: _quit_game()


func _continue_game() -> void:
	var slot = SaveManager.get_last_active_slot()
	if slot < 0:
		_show_no_saves_hint()
		return
	print("[TitleScreen] 继续游戏 (slot %d)" % slot)
	SaveManager.load_game(slot)
	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _start_new_game() -> void:
	print("[TitleScreen] 选择新游戏槽位")
	_show_save_slots("new_game")


func _start_new_game_in_slot() -> void:
	if _slot_selected < 0:
		return
	var slot = _slot_selected
	print("[TitleScreen] 在槽位 %d 开始新游戏" % slot)
	
	# 重置全部状态（包括碎片完成状态）
	GameManager.new_game()
	
	# 设置当前存档槽位
	SaveManager.set_current_slot(slot)
	
	# 清除该槽位的旧聊天记录（确保新游戏从零开始）
	ChatDatabase.clear_all_history()
	
	# 立即保存初始状态
	SaveManager.save_game(slot)
	
	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _quit_game() -> void:
	get_tree().quit()


# ============================================================
# 存档加载界面
# ============================================================

func _show_save_slots(mode: String = "load") -> void:
	_slot_mode = mode
	var slots = SaveManager.list_slots()
	
	# 加载模式：检查是否有已占用槽位
	if mode == "load":
		var has_any = false
		for s in slots:
			if s["occupied"]:
				has_any = true
				break
		if not has_any:
			_show_no_saves_hint()
			return
	
	_save_slots_visible = true
	_slot_selected = -1
	
	# 隐藏主菜单
	_title_label.visible = false
	_menu_vbox.visible = false
	
	# 创建或显示存档面板
	if not _slot_scroll:
		_build_save_slot_panel()
	else:
		_slot_scroll.visible = true
		_back_btn.visible = true
	
	# 根据模式显示不同按钮和标题
	if mode == "load":
		_slot_title.text = "加载存档"
		_load_btn.visible = true
		_delete_btn.visible = true
		if _new_game_btn:
			_new_game_btn.visible = false
	else:  # "new_game"
		_slot_title.text = "新游戏 — 选择槽位"
		_load_btn.visible = false
		_delete_btn.visible = false
		if _new_game_btn:
			_new_game_btn.visible = true
	
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
	
	_title_label.visible = true
	_menu_vbox.visible = true
	_update_selection()


func _build_save_slot_panel() -> void:
	var vs = get_viewport_rect().size
	
	# 标题
	_slot_title = Label.new()
	_slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_title.position = Vector2(0, 60)
	_slot_title.size = Vector2(vs.x, 40)
	_slot_title.add_theme_color_override("font_color", Color(0.5, 0.85, 1, 1))
	_slot_title.add_theme_font_size_override("font_size", 22)
	add_child(_slot_title)
	
	# 滚动区域
	_slot_scroll = ScrollContainer.new()
	_slot_scroll.position = Vector2(vs.x / 2 - 230, 120)
	_slot_scroll.size = Vector2(460, vs.y - 240)
	var scs = StyleBoxFlat.new()
	scs.bg_color = Color(0.08, 0.08, 0.1, 0.6)
	scs.set_corner_radius_all(8)
	_slot_scroll.add_theme_stylebox_override("panel", scs)
	_slot_scroll.add_theme_stylebox_override("panel", UITheme.panel_style())
	add_child(_slot_scroll)
	
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 8)
	_slot_scroll.add_child(_slot_list)
	
	# 底部按钮
	var btn_y = vs.y - 90
	_back_btn = _make_slot_button("返回", Vector2(vs.x / 2 - 230, btn_y))
	_back_btn.pressed.connect(_hide_save_slots)
	add_child(_back_btn)
	
	_delete_btn = _make_slot_button("删除", Vector2(vs.x / 2 - 80, btn_y))
	_delete_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3, 1))
	_delete_btn.pressed.connect(_delete_selected_slot)
	add_child(_delete_btn)
	
	_load_btn = _make_slot_button("加载", Vector2(vs.x / 2 + 70, btn_y))
	_load_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1))
	_load_btn.pressed.connect(_load_selected_slot)
	add_child(_load_btn)
	
	# 新游戏专用按钮（初始隐藏）
	_new_game_btn = _make_slot_button("新游戏", Vector2(vs.x / 2 + 70, btn_y))
	_new_game_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1))
	_new_game_btn.pressed.connect(_start_new_game_in_slot)
	_new_game_btn.visible = false
	add_child(_new_game_btn)


func _make_slot_button(text: String, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(140, 44)
	btn.add_theme_font_size_override("font_size", 15)
	UITheme.apply_button(btn)
	return btn


func _refresh_slot_list(slots: Array[Dictionary]) -> void:
	## 统一的槽位列表刷新（支持"加载"和"新游戏"两种模式）
	for c in _slot_list.get_children():
		c.queue_free()
	_slot_containers.clear()
	
	for i in slots.size():
		var s = slots[i]
		var slot_num = s["slot"]  # 0-based 内部索引
		var occupied: bool = s["occupied"]
		var container = Panel.new()
		container.custom_minimum_size = Vector2(440, 60)
		
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(0.12, 0.12, 0.15, 0.7)
		cs.set_corner_radius_all(6)
		var final_slot = slot_num
		if occupied or _slot_mode == "new_game":
			container.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					_select_slot(final_slot)
			)
		container.add_theme_stylebox_override("panel", cs)
		container.add_theme_stylebox_override("panel", UITheme.panel_style(true))
		
		if occupied:
			# 已有存档
			var label = Label.new()
			label.position = Vector2(16, 6)
			label.text = "存档 %d  —  %s" % [slot_num + 1, s.get("timestamp_readable", "")]
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1))
			label.add_theme_font_size_override("font_size", 14)
			container.add_child(label)
			
			var info = Label.new()
			info.position = Vector2(16, 30)
			var phase_names = ["初始", "探索", "危机A", "危机B", "论坛", "终局"]
			var phase = s.get("phase", 0)
			var phase_name = phase_names[min(phase, phase_names.size() - 1)]
			info.text = "角色: %s  |  进度: %.0f%%  |  阶段: %s" % [s.get("player_name", "?"), s.get("progress", 0) * 100, phase_name]
			info.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6, 1))
			info.add_theme_font_size_override("font_size", 11)
			container.add_child(info)
			
			# 新游戏模式：已被占用的槽位显示覆盖警告
			if _slot_mode == "new_game":
				var warn = Label.new()
				warn.position = Vector2(360, 40)
				warn.text = "[注意] 将被覆盖"
				warn.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2, 1))
				warn.add_theme_font_size_override("font_size", 10)
				container.add_child(warn)
		else:
			# 空槽位
			var label = Label.new()
			label.position = Vector2(16, 18)
			if _slot_mode == "load":
				label.text = "存档 %d  —  [ 空 ]" % (slot_num + 1)
				label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3, 1))
			else:
				label.text = "存档 %d  —  [ 空槽位 ]" % (slot_num + 1)
				label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 1))
			label.add_theme_font_size_override("font_size", 14)
			container.add_child(label)
		
		_slot_list.add_child(container)
		_slot_containers.append(container)
	
	_slot_selected = -1


func _select_slot(index: int) -> void:
	_slot_selected = index
	for i in _slot_containers.size():
		var container = _slot_containers[i]
		var cs = StyleBoxFlat.new()
		if i == _slot_selected:
			cs.bg_color = Color(0.15, 0.2, 0.3, 0.8)
			cs.set_corner_radius_all(6)
			cs.border_width_left = 2; cs.border_width_right = 2
			cs.border_width_top = 2; cs.border_width_bottom = 2
			cs.border_color = Color(0.6, 0.5, 0.2, 0.6)
		else:
			cs.bg_color = Color(0.12, 0.12, 0.15, 0.7)
			cs.set_corner_radius_all(6)
		container.add_theme_stylebox_override("panel", cs)


func _load_selected_slot() -> void:
	if _slot_selected < 0:
		return
	# 检查该槽位是否被占用
	var slots = SaveManager.list_slots()
	if _slot_selected >= slots.size() or not slots[_slot_selected]["occupied"]:
		_show_no_saves_hint()
		return
	var slot = _slot_selected
	print("[TitleScreen] 加载存档 slot %d" % slot)
	SaveManager.load_game(slot)
	SceneManager.pending_spawn_point = "from_cutscene"
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _delete_selected_slot() -> void:
	if _slot_selected < 0:
		return
	var slot = _slot_selected
	SaveManager.delete_slot(slot)
	# 刷新列表（list_slots 返回全部槽位含 empty 标记，基于磁盘文件）
	_refresh_slot_list(SaveManager.list_slots())


func _show_no_saves_hint() -> void:
	var hint = AcceptDialog.new()
	hint.title = "提示"
	hint.dialog_text = "没有找到存档文件。"
	hint.ok_button_text = "好的"
	add_child(hint)
	hint.popup_centered()
