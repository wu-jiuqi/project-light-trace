extends Control
class_name SourceMarkTicketOverlay

const Content = preload("res://scripts/fragment/fragment_0002_content.gd")
const DESIGN_SIZE := Vector2(1280.0, 720.0)

signal collected()

@onready var _stage: Control = $Stage
@onready var _ticket_texture: TextureRect = $Stage/TicketTexture

var _active := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	get_viewport().size_changed.connect(_layout_to_viewport)
	_layout_to_viewport()


func open_overlay() -> void:
	_apply_texture()
	_active = true
	visible = true


func close_overlay() -> void:
	_active = false
	visible = false


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact"):
		FragmentManager.set_fragment_state("0002", "source_mark_ticket_collected", true)
		close_overlay()
		collected.emit()
		get_viewport().set_input_as_handled()


func _apply_texture() -> void:
	var path := str(Content.TICKET_IMAGE_PATHS.get("player", "")).strip_edges()
	_ticket_texture.texture = null
	var placeholder := _ticket_texture.get_node_or_null("Placeholder")
	if placeholder is CanvasItem:
		(placeholder as CanvasItem).visible = true
	if path != "" and ResourceLoader.exists(path):
		_ticket_texture.texture = load(path) as Texture2D
		if placeholder is CanvasItem:
			(placeholder as CanvasItem).visible = false


func _layout_to_viewport() -> void:
	if _stage == null:
		return
	var vs := get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		vs = DESIGN_SIZE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var scale_factor := minf(vs.x / DESIGN_SIZE.x, vs.y / DESIGN_SIZE.y)
	var scaled_size := DESIGN_SIZE * scale_factor
	_stage.position = (vs - scaled_size) * 0.5
	_stage.size = DESIGN_SIZE
	_stage.scale = Vector2(scale_factor, scale_factor)
