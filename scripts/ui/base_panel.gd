class_name BasePanel
extends Control

const DESIGN_SIZE := Vector2(1280.0, 720.0)

signal panel_opened
signal panel_closed

var stage: Control
var is_open: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	stage = get_node_or_null("Stage")
	_setup_vignette()
	if stage:
		if not get_viewport().size_changed.is_connected(_layout_stage):
			get_viewport().size_changed.connect(_layout_stage)
		_layout_stage()
	_on_ready()


func _on_ready() -> void:
	pass


func _connect_button_pressed(button: BaseButton, callback: Callable, node_path: String) -> bool:
	if button == null:
		push_error("[%s] Missing BaseButton node: %s" % [name, node_path])
		return false
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if not button.pressed.is_connected(UISoundManager.play_click):
		button.pressed.connect(UISoundManager.play_click)
	return true


func _setup_vignette() -> void:
	var vignette := get_node_or_null("Vignette") as ColorRect
	if vignette:
		vignette.color = UIConstants.VIGNETTE_COLOR
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_stage() -> void:
	if not stage:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var scaled_size := DESIGN_SIZE * scale_factor
	stage.position = (viewport_size - scaled_size) * 0.5
	stage.size = DESIGN_SIZE
	stage.scale = Vector2(scale_factor, scale_factor)


func open() -> void:
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	is_open = true
	_on_open()
	panel_opened.emit()


func close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_open = false
	_on_close()
	panel_closed.emit()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func _on_open() -> void:
	pass


func _on_close() -> void:
	pass
