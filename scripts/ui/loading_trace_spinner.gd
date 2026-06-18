extends Control

@export_range(0.0, 100.0, 0.1) var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 100.0)
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var base_radius := minf(size.x, size.y) * 0.34
	var outer_radius := base_radius * 1.18
	var progress_angle := TAU * progress / 100.0
	var paper := Color(0.73, 0.64, 0.48, 0.26)
	var gold := Color(0.96, 0.77, 0.42, 0.82)
	var cyan := Color(0.55, 0.9, 1.0, 0.52)
	var ink := Color(0.05, 0.09, 0.14, 0.70)

	draw_circle(center, outer_radius * 0.9, Color(0.07, 0.11, 0.16, 0.12))
	draw_arc(center, outer_radius, 0.0, TAU, 120, Color(0.74, 0.66, 0.50, 0.24), 2.0, true)
	draw_arc(center, base_radius, 0.0, TAU, 120, Color(0.74, 0.66, 0.50, 0.18), 1.0, true)
	draw_arc(center, outer_radius, -PI * 0.5, -PI * 0.5 + progress_angle, 120, gold, 3.0, true)
	draw_arc(center, base_radius * 0.78, PI * 0.12 + _time * 0.18, PI * 1.25 + _time * 0.18, 56, cyan, 1.4, true)

	for i in 12:
		var angle := TAU * float(i) / 12.0 + _time * 0.16
		var point := center + Vector2(cos(angle), sin(angle)) * outer_radius
		var dot_alpha := 0.38 + 0.36 * sin(_time * 2.2 + float(i) * 0.7)
		draw_circle(point, 2.5 + 1.2 * maxf(0.0, sin(_time * 2.0 + i)), Color(0.96, 0.78, 0.48, dot_alpha))

	var diamond := PackedVector2Array([
		center + Vector2(0.0, -base_radius * 0.76),
		center + Vector2(base_radius * 0.64, 0.0),
		center + Vector2(0.0, base_radius * 0.76),
		center + Vector2(-base_radius * 0.64, 0.0),
	])
	var closed_diamond := PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]])
	draw_colored_polygon(diamond, paper)
	draw_circle(center, base_radius * 0.28, ink)
	draw_polyline(closed_diamond, Color(0.94, 0.78, 0.53, 0.58), 2.0, true)
	draw_line(diamond[0], diamond[2], Color(0.92, 0.76, 0.48, 0.45), 1.4, true)
	draw_line(diamond[1], diamond[3], Color(0.92, 0.76, 0.48, 0.45), 1.4, true)

	var sweep := -PI * 0.5 + _time * 1.18
	var sweep_end := center + Vector2(cos(sweep), sin(sweep)) * outer_radius * 0.98
	draw_line(center, sweep_end, Color(0.62, 0.95, 1.0, 0.30), 2.0, true)
	draw_circle(center, 8.0 + 3.0 * sin(_time * 3.4), Color(1.0, 0.78, 0.42, 0.54))
	draw_circle(center, 3.2, Color(1.0, 0.91, 0.62, 0.86))

	for i in 5:
		var a := _time * (0.7 + i * 0.08) + TAU * float(i) / 5.0
		var p := center + Vector2(cos(a), sin(a * 1.13)) * base_radius * (0.34 + i * 0.08)
		draw_line(center, p, Color(0.91, 0.70, 0.38, 0.18), 1.0, true)
		draw_circle(p, 2.0, Color(0.96, 0.78, 0.45, 0.50))
