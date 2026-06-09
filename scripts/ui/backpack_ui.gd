extends Control
## 背包 UI — Autoload
## 按 B 打开/关闭，展示收集的物品，支持点击查看详情

const UITheme = preload("res://scripts/ui/ui_theme.gd")

var _canvas: CanvasLayer
var _panel: Panel
var _title_label: Label
var _grid: GridContainer
var _hint_label: Label
var _is_open: bool = false
var _item_cells: Array[Panel] = []
var _ui_built: bool = false


func _ready() -> void:
	add_to_group("backpack_ui")
	
	_canvas = CanvasLayer.new()
	_canvas.name = "BackpackLayer"
	_canvas.layer = 127
	add_child(_canvas)
	
	# 连接物品变化信号
	InventoryManager.item_added.connect(_on_item_changed)
	InventoryManager.item_removed.connect(_on_item_changed)
	
	call_deferred("_ensure_ui")
	
	set_process_input(true)
	print("[BackpackUI] 就绪")


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	_build_ui()


func _build_ui() -> void:
	var vs = get_viewport_rect().size
	if vs.x <= 0:
		vs = Vector2(1280, 720)
	
	# 面板居中
	var pw = 500
	var ph = 420
	_panel = Panel.new()
	_panel.position = Vector2((vs.x - pw) / 2, (vs.y - ph) / 2)
	_panel.size = Vector2(pw, ph)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.15, 0.15, 0.18, 0.92)
	ps.set_corner_radius_all(12)
	ps.border_width_left = 2; ps.border_width_right = 2
	ps.border_width_top = 2; ps.border_width_bottom = 2
	ps.border_color = Color(0.4, 0.4, 0.5, 0.5)
	_panel.add_theme_stylebox_override("panel", ps)
	_panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	_panel.visible = false
	_canvas.add_child(_panel)
	
	# 标题
	_title_label = Label.new()
	_title_label.position = Vector2(20, 16)
	_title_label.text = "[背包]"
	_title_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1, 1))
	_title_label.add_theme_font_size_override("font_size", 22)
	_panel.add_child(_title_label)
	
	# 物品网格
	_grid = GridContainer.new()
	_grid.position = Vector2(30, 60)
	_grid.size = Vector2(440, 280)
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_panel.add_child(_grid)
	
	# 提示
	_hint_label = Label.new()
	_hint_label.position = Vector2(150, 380)
	_hint_label.size = Vector2(200, 24)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.text = "按 B 关闭"
	_hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.8))
	_hint_label.add_theme_font_size_override("font_size", 13)
	_panel.add_child(_hint_label)


func _refresh_grid() -> void:
	# 清除旧格子
	for cell in _item_cells:
		if is_instance_valid(cell):
			cell.queue_free()
	_item_cells.clear()
	
	var items = InventoryManager.get_all_items()
	var all_meta = InventoryManager.ITEM_META
	
	# 已有的物品
	for item_id in items:
		var meta = all_meta.get(item_id, {})
		var cell = _make_item_cell(item_id, meta, false)
		_grid.add_child(cell)
		_item_cells.append(cell)
	
	# 空格子（总6格）
	for i in range(items.size(), 6):
		var cell = _make_empty_cell()
		_grid.add_child(cell)
		_item_cells.append(cell)


func _make_item_cell(item_id: int, meta: Dictionary, _empty: bool) -> Panel:
	var cell = Panel.new()
	cell.custom_minimum_size = Vector2(90, 90)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	cs.set_corner_radius_all(8)
	cs.border_width_left = 1; cs.border_width_right = 1
	cs.border_width_top = 1; cs.border_width_bottom = 1
	cs.border_color = meta.get("color", Color(0.4, 0.4, 0.5, 0.5))
	cell.add_theme_stylebox_override("panel", cs)
	cell.add_theme_stylebox_override("panel", UITheme.panel_style(true))
	
	# 图标
	var icon = Label.new()
	icon.position = Vector2(10, 8)
	icon.size = Vector2(70, 40)
	icon.text = meta.get("icon", "?")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32)
	cell.add_child(icon)
	
	# 名称
	var name_label = Label.new()
	name_label.position = Vector2(4, 50)
	name_label.size = Vector2(82, 34)
	name_label.text = meta.get("name", "?")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	name_label.add_theme_font_size_override("font_size", 12)
	cell.add_child(name_label)
	
	return cell


func _make_empty_cell() -> Panel:
	var cell = Panel.new()
	cell.custom_minimum_size = Vector2(90, 90)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.12, 0.15, 0.4)
	cs.set_corner_radius_all(8)
	cs.border_width_left = 1; cs.border_width_right = 1
	cs.border_width_top = 1; cs.border_width_bottom = 1
	cs.border_color = Color(0.2, 0.2, 0.25, 0.3)
	cell.add_theme_stylebox_override("panel", cs)
	cell.add_theme_stylebox_override("panel", UITheme.panel_style(true, Color(0.7, 0.78, 0.9, 0.55)))
	return cell


func open() -> void:
	if not _ui_built:
		_ensure_ui()
	if _is_open:
		return
	_is_open = true
	_refresh_grid()
	_panel.visible = true
	InventoryManager.backpack_toggled.emit(true)
	print("[Backpack] 打开 (%d 物品)" % InventoryManager.get_item_count())


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_panel.visible = false
	InventoryManager.backpack_toggled.emit(false)


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("backpack"):
		# 对话打开时不触发背包
		if ChatDialogue.is_open:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if _is_open:
			close()
			get_viewport().set_input_as_handled()


# 物品变化时自动刷新
func _on_item_changed(_id: int) -> void:
	if _is_open:
		_refresh_grid()
