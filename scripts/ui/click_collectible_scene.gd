extends Node
class_name ClickCollectibleScene

signal collected()
signal state_triggered()

@export var collect_once := true
@export var disable_after_collect := true
@export var cursor_on_hover := true
@export var collect_hint := "点击物品收集"
@export var collected_hint := "已收集，点击继续"
@export var show_hint := true

var _collected := false
var _areas: Array[Area2D] = []
var _hint_label: Label = null


func _ready() -> void:
	_areas = _find_area_nodes(self)
	for area in _areas:
		_connect_area(area)
	_ensure_hint_label()
	set_process_input(true)


func _find_area_nodes(root: Node) -> Array[Area2D]:
	var areas: Array[Area2D] = []
	for child in root.get_children():
		if child is Area2D:
			areas.append(child as Area2D)
		areas.append_array(_find_area_nodes(child))
	return areas


func _connect_area(area: Area2D) -> void:
	area.input_pickable = true
	if not area.input_event.is_connected(_on_area_input_event):
		area.input_event.connect(_on_area_input_event.bind(area))
	if cursor_on_hover:
		if not area.mouse_entered.is_connected(_on_area_mouse_entered):
			area.mouse_entered.connect(_on_area_mouse_entered)
		if not area.mouse_exited.is_connected(_on_area_mouse_exited):
			area.mouse_exited.connect(_on_area_mouse_exited)


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, area: Area2D) -> void:
	if collect_once and _collected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_collect(area)


func _input(event: InputEvent) -> void:
	if collect_once and _collected:
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	for area in _areas:
		if _area_contains_point(area, event.position):
			_collect(area)
			return


func _area_contains_point(area: Area2D, screen_point: Vector2) -> bool:
	if area == null or not area.input_pickable:
		return false
	for child in area.get_children():
		if child is CollisionPolygon2D:
			var polygon := child as CollisionPolygon2D
			if polygon.disabled:
				continue
			var local_point := polygon.get_global_transform_with_canvas().affine_inverse() * screen_point
			if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
				return true
		elif child is CollisionShape2D:
			var shape_node := child as CollisionShape2D
			if shape_node.disabled or shape_node.shape == null:
				continue
			if _shape_contains_point(shape_node, screen_point):
				return true
	return false


func _shape_contains_point(shape_node: CollisionShape2D, screen_point: Vector2) -> bool:
	var local_point := shape_node.get_global_transform_with_canvas().affine_inverse() * screen_point
	var shape := shape_node.shape
	if shape is RectangleShape2D:
		var half_size := (shape as RectangleShape2D).size * 0.5
		return absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y
	if shape is CircleShape2D:
		return local_point.length() <= (shape as CircleShape2D).radius
	return false


func _collect(area: Area2D) -> void:
	if collect_once and _collected:
		return
	_collected = true
	if disable_after_collect:
		for candidate in _areas:
			candidate.input_pickable = false
	if _hint_label != null:
		_hint_label.text = collected_hint
	collected.emit()
	state_triggered.emit()
	get_viewport().set_input_as_handled()


func _on_area_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_area_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _ensure_hint_label() -> void:
	if not show_hint:
		return
	_hint_label = Label.new()
	_hint_label.name = "CollectHint"
	_hint_label.position = Vector2(0.0, 620.0)
	_hint_label.size = Vector2(1280.0, 48.0)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 24)
	_hint_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.58, 0.95))
	_hint_label.add_theme_constant_override("outline_size", 3)
	_hint_label.text = collect_hint
	add_child(_hint_label)


func is_collected_for_test() -> bool:
	return _collected
