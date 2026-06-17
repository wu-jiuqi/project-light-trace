extends CanvasLayer
class_name FTUEOverlay

const HIDE_OFFSET := 90.0

var _panel: PanelContainer
var _label: Label
var _pulse_target: Control = null
var _pulse_tween: Tween = null
var _hide_tween: Tween = null


func _ready() -> void:
	layer = 90
	_panel = PanelContainer.new()
	_panel.name = "HintPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 280.0
	_panel.offset_right = -280.0
	_panel.offset_top = -104.0
	_panel.offset_bottom = -34.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.035, 0.78)
	style.border_color = Color(0.9, 0.72, 0.38, 0.74)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.58, 0.96))
	_label.add_theme_constant_override("outline_size", 3)
	_panel.add_child(_label)
	hide_hint(false)


func show_hint(text: String, duration: float = 0.0) -> void:
	_kill_tween(_hide_tween)
	_label.text = text
	_panel.visible = true
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	if duration > 0.0:
		_hide_tween = create_tween()
		_hide_tween.tween_interval(duration)
		_hide_tween.tween_callback(hide_hint)


func hide_hint(animated: bool = true) -> void:
	_kill_tween(_hide_tween)
	if _panel == null:
		return
	if not animated:
		_panel.visible = false
		_panel.modulate.a = 0.0
		return
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.16)
	tween.tween_callback(func() -> void:
		_panel.visible = false
	)


func pulse_control(control: Control) -> void:
	clear_pulse()
	if control == null:
		return
	_pulse_target = control
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(control, "modulate", Color(1.0, 0.88, 0.46, 1.0), 0.45)
	_pulse_tween.tween_property(control, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)


func clear_pulse() -> void:
	_kill_tween(_pulse_tween)
	if is_instance_valid(_pulse_target):
		_pulse_target.modulate = Color.WHITE
	_pulse_target = null


func _kill_tween(tween) -> void:
	if tween != null and tween is Tween and tween.is_valid():
		tween.kill()
