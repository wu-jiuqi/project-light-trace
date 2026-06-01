extends Control
class_name StarShardCanvas
## 用同一张玻璃四芒星母图裁切 12 个可点击碎片。

const STAR_TEXTURE = preload("res://assets/ui/glass_four_point_star.png")
const ATLAS_RECT := Rect2(160, 25, 400, 400)
const TEXTURE_UV_MIN := Vector2(0.055, 0.02)
const TEXTURE_UV_MAX := Vector2(0.945, 0.98)
const CENTER := Vector2(360, 225)
const BOUNDARY: Array[Vector2] = [
	Vector2(360, 25), Vector2(389, 116), Vector2(410, 165),
	Vector2(560, 225), Vector2(410, 285), Vector2(389, 334),
	Vector2(360, 425), Vector2(331, 334), Vector2(310, 285),
	Vector2(160, 225), Vector2(310, 165), Vector2(331, 116),
]
const MIDPOINTS: Array[Vector2] = [
	Vector2(354, 134), Vector2(381, 166), Vector2(426, 190),
	Vector2(454, 231), Vector2(414, 266), Vector2(384, 291),
	Vector2(364, 316), Vector2(335, 292), Vector2(303, 263),
	Vector2(269, 218), Vector2(308, 184), Vector2(339, 163),
]
const SCATTER_OFFSETS: Array[Vector2] = [
	Vector2(-250, -55), Vector2(216, -86), Vector2(170, 86),
	Vector2(-132, 164), Vector2(220, 150), Vector2(-236, 88),
	Vector2(68, -172), Vector2(-78, -157), Vector2(278, 14),
	Vector2(-284, 14), Vector2(140, -138), Vector2(-176, -130),
]
const DEBRIS: Array[Vector2] = [
	Vector2(116, 92), Vector2(612, 118), Vector2(92, 358),
	Vector2(648, 344), Vector2(216, 402), Vector2(548, 60),
]

var fragments: Array = []
var shard_offsets: Array[Vector2] = []
var hovered_index := -1
var selected_index := -1

signal fragment_selected(index: int)
signal empty_clicked()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var additive = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	for offset in SCATTER_OFFSETS:
		shard_offsets.append(offset)
	queue_redraw()


func configure(fragment_data: Array, animate_fragment_id: String = "") -> void:
	fragments = fragment_data
	for index in range(mini(fragments.size(), shard_offsets.size())):
		shard_offsets[index] = Vector2.ZERO if fragments[index].completed else SCATTER_OFFSETS[index]
	queue_redraw()
	if not animate_fragment_id.is_empty():
		var index = _find_fragment_index(animate_fragment_id)
		if index >= 0:
			shard_offsets[index] = SCATTER_OFFSETS[index]
			_animate_home(index)


func shard_count() -> int:
	return BOUNDARY.size()


func is_fragment_home(index: int) -> bool:
	return index >= 0 and index < shard_offsets.size() and shard_offsets[index].is_zero_approx()


func select_fragment(index: int) -> void:
	if index < 0 or index >= fragments.size():
		return
	selected_index = index
	fragment_selected.emit(index)
	queue_redraw()


func _draw() -> void:
	_draw_target_outline()
	_draw_debris()
	for index in range(BOUNDARY.size()):
		_draw_shard(index)


func _draw_target_outline() -> void:
	var outline = BOUNDARY.duplicate()
	outline.append(BOUNDARY[0])
	draw_polyline(outline, Color(0.2, 0.66, 0.9, 0.24), 2.0, true)
	for point in BOUNDARY:
		draw_line(CENTER, point, Color(0.26, 0.68, 0.9, 0.1), 1.0, true)


func _draw_debris() -> void:
	for index in range(DEBRIS.size()):
		var point = DEBRIS[index]
		var radius = 4.0 + float(index % 3) * 2.0
		var shard = PackedVector2Array([
			point + Vector2(-radius, radius * 0.3),
			point + Vector2(radius * 0.4, -radius),
			point + Vector2(radius, radius),
		])
		draw_colored_polygon(shard, Color(0.34, 0.84, 1.0, 0.36))
		draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[0]]), Color(0.82, 0.94, 1.0, 0.7), 1.0, true)


func _draw_shard(index: int) -> void:
	var offset = shard_offsets[index] + _hover_offset(index)
	var polygon = _polygon_for(index, offset)
	var base_alpha = 0.98 if is_fragment_home(index) else 0.72
	if index == hovered_index or index == selected_index:
		base_alpha = 1.0
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for point in _polygon_for(index):
		colors.append(Color(0.78, 0.94, 1.0, base_alpha))
		uvs.append(_uv_for(point))
	draw_polygon(polygon, colors, uvs, STAR_TEXTURE)
	var outline_color = Color(0.95, 0.82, 0.5, 0.95) if index == selected_index else Color(0.66, 0.92, 1.0, 0.86)
	var closed = polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, outline_color, 2.2 if index == hovered_index else 1.2, true)


func _polygon_for(index: int, offset: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var next_index = (index + 1) % BOUNDARY.size()
	return PackedVector2Array([
		CENTER + offset,
		MIDPOINTS[index] + offset,
		BOUNDARY[index] + offset,
		BOUNDARY[next_index] + offset,
		MIDPOINTS[next_index] + offset,
	])


func _uv_for(point: Vector2) -> Vector2:
	var relative = (point - ATLAS_RECT.position) / ATLAS_RECT.size
	return Vector2(
		lerpf(TEXTURE_UV_MIN.x, TEXTURE_UV_MAX.x, relative.x),
		lerpf(TEXTURE_UV_MIN.y, TEXTURE_UV_MAX.y, relative.y)
	)


func _hover_offset(index: int) -> Vector2:
	if index != hovered_index:
		return Vector2.ZERO
	return (BOUNDARY[index] - CENTER).normalized() * 8.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var next_hover = _index_at(event.position)
		if next_hover != hovered_index:
			hovered_index = next_hover
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var index = _index_at(event.position)
		if index >= 0:
			select_fragment(index)
		else:
			selected_index = -1
			empty_clicked.emit()
			queue_redraw()


func _index_at(position: Vector2) -> int:
	for index in range(BOUNDARY.size() - 1, -1, -1):
		var polygon = _polygon_for(index, shard_offsets[index] + _hover_offset(index))
		if Geometry2D.is_point_in_polygon(position, polygon):
			return index
	return -1


func _find_fragment_index(fragment_id: String) -> int:
	for index in range(fragments.size()):
		if fragments[index].id == fragment_id:
			return index
	return -1


func _animate_home(index: int) -> void:
	var start = shard_offsets[index]
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(weight: float) -> void:
		shard_offsets[index] = start.lerp(Vector2.ZERO, weight)
		queue_redraw()
	, 0.0, 1.0, 1.2)
