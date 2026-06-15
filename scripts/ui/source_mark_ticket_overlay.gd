extends Control
class_name SourceMarkTicketOverlay

const DESIGN_SIZE := Vector2(1280.0, 720.0)

signal collected()

@onready var _stage: Control = $Stage
@onready var _ticket_texture: TextureRect = $Stage/TicketTexture

var _active := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ticket_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	_ticket_texture.gui_input.connect(_on_ticket_texture_gui_input)
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
		_collect_ticket()
		get_viewport().set_input_as_handled()


func _on_ticket_texture_gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_collect_ticket()
		get_viewport().set_input_as_handled()


func _collect_ticket() -> void:
	FragmentManager.set_fragment_state("0002", "source_mark_ticket_collected", true)
	close_overlay()
	collected.emit()


func _apply_texture() -> void:
	# 车票图片在编辑器中手动设置，无需运行时操作
	# 如需运行时加载：取消注释并在 fragment_0002_content.gd 中填写路径
	# var path := str(Content.TICKET_IMAGE_PATHS.get("player", "")).strip_edges()
	# if path != "" and ResourceLoader.exists(path):
	# 	_ticket_texture.texture = load(path) as Texture2D
	pass


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
