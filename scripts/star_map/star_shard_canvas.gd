extends Control
class_name StarShardCanvas
## Draws 12 interactive shadow masks over the star-map background.

const TEXTURE_SIZE := Vector2(1672, 941)
const MASK_ALPHA := 0.58
const MASK_COLOR := Color(0.08, 0.08, 0.08, MASK_ALPHA)
const HOVER_COLOR := Color(0.58, 0.48, 0.28, 0.24)
const SELECTED_COLOR := Color(0.95, 0.72, 0.32, 0.32)
const LINE_COLOR := Color(0.95, 0.72, 0.32, 0.8)
const LINE_SOFT_COLOR := Color(1.0, 0.88, 0.52, 0.24)
const REVEAL_DURATION := 1.2

const ROW_POINTS: Array = [
	[
		Vector2(0, 0), Vector2(390, 0), Vector2(835, 0), Vector2(1285, 0), Vector2(1672, 0),
	],
	[
		Vector2(0, 288), Vector2(455, 245), Vector2(790, 308), Vector2(1205, 260), Vector2(1672, 300),
	],
	[
		Vector2(0, 630), Vector2(400, 590), Vector2(905, 660), Vector2(1288, 603), Vector2(1672, 650),
	],
	[
		Vector2(0, 941), Vector2(430, 941), Vector2(815, 941), Vector2(1248, 941), Vector2(1672, 941),
	],
]

var fragments: Array = []
var mask_alphas: Array[float] = []
var hovered_index := -1
var selected_index := -1
var flash_index: int = -1
var flash_alpha: float = 0.0

signal fragment_selected(index: int)
signal empty_clicked()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_mask_alphas()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func configure(fragment_data: Array, animate_fragment_id: String = "") -> void:
	fragments = fragment_data
	_ensure_mask_alphas()
	for index in range(shard_count()):
		var fragment = fragments[index] if index < fragments.size() else null
		mask_alphas[index] = 0.0 if fragment != null and fragment.completed else MASK_ALPHA
	queue_redraw()

	if not animate_fragment_id.is_empty():
		var index = _find_fragment_index(animate_fragment_id)
		if index >= 0:
			mask_alphas[index] = MASK_ALPHA
			_animate_reveal(index)


func shard_count() -> int:
	return 12


func is_fragment_revealed(index: int) -> bool:
	return index >= 0 and index < mask_alphas.size() and mask_alphas[index] <= 0.01


func select_fragment(index: int) -> void:
	if index < 0 or index >= fragments.size():
		return
	selected_index = index
	fragment_selected.emit(index)
	queue_redraw()


func _draw() -> void:
	for index in range(shard_count()):
		_draw_mask(index)
	_draw_separators()


func _draw_mask(index: int) -> void:
	var polygon := _polygon_for(index)
	var alpha := mask_alphas[index] if index < mask_alphas.size() else MASK_ALPHA
	var fragment = fragments[index] if index < fragments.size() else null
	if fragment != null and not fragment.unlocked:
		alpha = maxf(alpha, 0.72)
	if alpha > 0.01:
		draw_colored_polygon(polygon, Color(MASK_COLOR.r, MASK_COLOR.g, MASK_COLOR.b, alpha))

	if index == selected_index:
		draw_colored_polygon(polygon, SELECTED_COLOR)
		_draw_outline(polygon, Color(1.0, 0.86, 0.48, 0.95), 3.0)
	elif index == hovered_index:
		draw_colored_polygon(polygon, HOVER_COLOR)
		_draw_outline(polygon, LINE_COLOR, 2.0)

	if index == flash_index and flash_alpha > 0.01:
		draw_colored_polygon(polygon, Color(1.0, 0.92, 0.4, flash_alpha * 0.55))

	if index == selected_index:
		_draw_outline(polygon, Color(1.0, 0.92, 0.58, 1.0), 3.4)


func _draw_separators() -> void:
	for row in ROW_POINTS:
		var points := _map_points(row)
		draw_polyline(points, LINE_SOFT_COLOR, 4.0, true)
		draw_polyline(points, LINE_COLOR, 1.35, true)

	for column in range(5):
		var points := PackedVector2Array()
		for row in range(ROW_POINTS.size()):
			points.append(_map_texture_point(ROW_POINTS[row][column]))
		draw_polyline(points, LINE_SOFT_COLOR, 4.0, true)
		draw_polyline(points, LINE_COLOR, 1.35, true)


func _draw_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, color, width, true)


func _polygon_for(index: int) -> PackedVector2Array:
	var row := int(index / 4)
	var column := index % 4
	return PackedVector2Array([
		_map_texture_point(ROW_POINTS[row][column]),
		_map_texture_point(ROW_POINTS[row][column + 1]),
		_map_texture_point(ROW_POINTS[row + 1][column + 1]),
		_map_texture_point(ROW_POINTS[row + 1][column]),
	])


func _map_points(points: Array) -> PackedVector2Array:
	var mapped := PackedVector2Array()
	for point in points:
		mapped.append(_map_texture_point(point))
	return mapped


func _map_texture_point(point: Vector2) -> Vector2:
	var cover_rect := _cover_rect(size, TEXTURE_SIZE)
	if TEXTURE_SIZE.x <= 0.0 or TEXTURE_SIZE.y <= 0.0:
		return point
	return cover_rect.position + point / TEXTURE_SIZE * cover_rect.size


func _cover_rect(container_size: Vector2, texture_size: Vector2) -> Rect2:
	if container_size.x <= 0.0 or container_size.y <= 0.0 \
			or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(Vector2.ZERO, container_size)

	var cover_scale: float = maxf(
		container_size.x / texture_size.x,
		container_size.y / texture_size.y
	)
	var drawn_size := texture_size * cover_scale
	return Rect2((container_size - drawn_size) * 0.5, drawn_size)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var next_hover := _index_at(event.position)
		if next_hover != hovered_index:
			hovered_index = next_hover
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var index := _index_at(event.position)
		if index >= 0:
			select_fragment(index)
		else:
			selected_index = -1
			empty_clicked.emit()
			queue_redraw()


func _index_at(position: Vector2) -> int:
	for index in range(shard_count() - 1, -1, -1):
		if Geometry2D.is_point_in_polygon(position, _polygon_for(index)):
			return index
	return -1


func _find_fragment_index(fragment_id: String) -> int:
	for index in range(fragments.size()):
		if fragments[index].id == fragment_id:
			return index
	return -1


func _animate_reveal(index: int) -> void:
	var start := mask_alphas[index]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(weight: float) -> void:
		mask_alphas[index] = lerpf(start, 0.0, weight)
		queue_redraw()
	, 0.0, 1.0, REVEAL_DURATION)


func flash_fragment(fragment_id: String, times: int = 3, interval: float = 0.35) -> void:
	## Plays a golden flash animation on the specified fragment.
	## [param times] Number of flash cycles (fade in → fade out).
	## [param interval] Duration in seconds for one full cycle.
	var index := _find_fragment_index(fragment_id)
	if index < 0:
		push_warning("[StarShardCanvas] flash_fragment: fragment '%s' not found." % fragment_id)
		return
	flash_index = index
	var half := interval * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops(times - 1)
	tween.tween_method(func(value: float) -> void:
		flash_alpha = value
		queue_redraw()
	, 0.0, 1.0, half)
	tween.tween_method(func(value: float) -> void:
		flash_alpha = 1.0 - value
		queue_redraw()
	, 0.0, 1.0, half)
	tween.finished.connect(func():
		flash_index = -1
		flash_alpha = 0.0
		queue_redraw()
	)


func _ensure_mask_alphas() -> void:
	while mask_alphas.size() < shard_count():
		mask_alphas.append(MASK_ALPHA)
