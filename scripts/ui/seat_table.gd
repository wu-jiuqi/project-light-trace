extends Control
class_name SeatTablePanel

const Content = preload("res://scripts/fragment/fragment_0002_content.gd")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const TICKET_COLLECTION_KEYS: Dictionary = {
	"oldteacher": "ticket_oldteacher_collected",
	"youngsoldier": "ticket_youngsoldier_collected",
	"flowergirl": "ticket_flowergirl_collected",
	"merchant": "ticket_merchant_collected",
	"littlegirl": "ticket_littlegirl_collected",
}

signal seating_saved(selection: Dictionary, left_npc_id: String)

@onready var _stage: Control = $Stage
@onready var _board_texture: TextureRect = $Stage/BoardTexture
@onready var _ticket_layer: Control = $Stage/TicketLayer
@onready var _seat_slots: Control = $Stage/SeatSlots
@onready var _save_button: BaseButton = $Stage/SaveButton
@onready var _hint_label: Label = $Stage/HintLabel

var _dragging_ticket: Control = null
var _drag_offset := Vector2.ZERO
var _ticket_home_positions: Dictionary = {}
var _seat_assignments: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_save_button.pressed.connect(_on_save_pressed)
	get_viewport().size_changed.connect(_layout_to_viewport)
	_layout_to_viewport()
	_setup_static_assets()
	_cache_ticket_homes()
	_update_save_state()


func open_table() -> void:
	visible = true
	_collect_ticket_gallery_items()
	_reset_layout()
	_update_save_state()


func close_table() -> void:
	visible = false
	_dragging_ticket = null


func assign_for_test(seated_ids: Array) -> void:
	_seat_assignments.clear()
	for i in range(mini(seated_ids.size(), 4)):
		_seat_assignments["SeatSlot%d" % (i + 1)] = str(seated_ids[i])
	_update_save_state()


func get_selection_for_test() -> Dictionary:
	return _build_selection()


func get_left_npc_id_for_test() -> String:
	return _resolve_left_npc_id()


func can_save_for_test() -> bool:
	return not _save_button.disabled


func _input(event: InputEvent) -> void:
	if _handle_drag_input(event):
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _handle_drag_input(event):
		get_viewport().set_input_as_handled()


func _handle_drag_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var stage_pos := _to_stage_position(event.position)
		if event.pressed:
			return _begin_drag(stage_pos)
		if _dragging_ticket != null:
			_end_drag(stage_pos)
			return true
		return false
	if event is InputEventMouseMotion and _dragging_ticket != null:
		_dragging_ticket.position = _to_stage_position(event.position) - _drag_offset
		return true
	return false


func _begin_drag(mouse_pos: Vector2) -> bool:
	_dragging_ticket = null
	for index in range(_ticket_layer.get_child_count() - 1, -1, -1):
		var ticket := _ticket_layer.get_child(index)
		if not (ticket is Control):
			continue
		var control := ticket as Control
		if not control.visible:
			continue
		if control.get_rect().has_point(mouse_pos):
			_dragging_ticket = control
			_drag_offset = mouse_pos - control.position
			_ticket_layer.move_child(control, _ticket_layer.get_child_count() - 1)
			return true
	return false


func _end_drag(mouse_pos: Vector2) -> void:
	if _dragging_ticket == null:
		return
	var ticket := _dragging_ticket
	_dragging_ticket = null
	var npc_id := str(ticket.get_meta("npc_id", ""))
	var target_slot := _slot_at(mouse_pos)
	if target_slot == null:
		_return_ticket_home(ticket)
		_remove_assignment_for(npc_id)
		_update_save_state()
		return

	_remove_assignment_for(npc_id)
	_clear_slot_assignment(target_slot.name)
	_seat_assignments[target_slot.name] = npc_id
	ticket.position = target_slot.position + (target_slot.size - ticket.size) * 0.5
	_update_save_state()


func _slot_at(mouse_pos: Vector2) -> Control:
	for slot in _seat_slots.get_children():
		if slot is Control and (slot as Control).get_rect().has_point(mouse_pos):
			return slot as Control
	return null


func _remove_assignment_for(npc_id: String) -> void:
	var to_remove: Array[String] = []
	for slot_name in _seat_assignments:
		if _seat_assignments[slot_name] == npc_id:
			to_remove.append(slot_name)
	for slot_name in to_remove:
		_seat_assignments.erase(slot_name)


func _clear_slot_assignment(slot_name: String) -> void:
	if not _seat_assignments.has(slot_name):
		return
	var old_npc := str(_seat_assignments[slot_name])
	_seat_assignments.erase(slot_name)
	var old_ticket := _ticket_layer.get_node_or_null("Ticket_%s" % old_npc) as Control
	if old_ticket != null:
		_return_ticket_home(old_ticket)


func _return_ticket_home(ticket: Control) -> void:
	if _ticket_home_positions.has(ticket.name):
		ticket.position = _ticket_home_positions[ticket.name]


func _on_save_pressed() -> void:
	if _save_button.disabled:
		return
	var selection := _build_selection()
	var left_npc_id := _resolve_left_npc_id()
	FragmentManager.set_fragment_state("0002", "seat_selection", selection)
	FragmentManager.set_fragment_state("0002", "left_npc_id", left_npc_id)
	SaveManager.save_game()
	close_table()
	seating_saved.emit(selection, left_npc_id)


func _build_selection() -> Dictionary:
	var selection := {}
	for npc_id in Content.NPC_IDS:
		selection[npc_id] = 1
	for slot_name in _seat_assignments:
		var npc_id := str(_seat_assignments[slot_name])
		selection[npc_id] = 0
	return selection


func _resolve_left_npc_id() -> String:
	var seated := {}
	for slot_name in _seat_assignments:
		seated[str(_seat_assignments[slot_name])] = true
	for npc_id in Content.NPC_IDS:
		if not seated.has(npc_id):
			return npc_id
	return ""


func _update_save_state() -> void:
	_save_button.disabled = _seat_assignments.size() != 4 or _resolve_left_npc_id().is_empty()
	if _save_button.disabled:
		_hint_label.text = "将四张车票拖到座位上，剩下的人会被留下。"
	else:
		var left_name := str(Content.NPC_DISPLAY_NAMES.get(_resolve_left_npc_id(), _resolve_left_npc_id()))
		_hint_label.text = "留下的人：%s。确认后点击保存。" % left_name


func _setup_static_assets() -> void:
	# 座位表和车票图片在编辑器中手动设置，运行时无需从路径加载。
	# 如需运行时加载：取消注释并在 fragment_0002_content.gd 中填写路径。
	# _apply_texture(_board_texture, Content.SEAT_TABLE_IMAGE_PATH)
	for npc_id in Content.NPC_IDS:
		var ticket := _ticket_layer.get_node_or_null("Ticket_%s/Texture" % npc_id) as TextureRect
		if ticket != null:
			pass
			# _apply_texture(ticket, str(Content.TICKET_IMAGE_PATHS.get(npc_id, "")))


func _apply_texture(texture_rect: TextureRect, path: String) -> void:
	if texture_rect == null or path.strip_edges().is_empty():
		return
	if ResourceLoader.exists(path):
		texture_rect.texture = load(path) as Texture2D
		var placeholder := texture_rect.get_node_or_null("Placeholder")
		if placeholder == null:
			placeholder = texture_rect.get_node_or_null("BoardPlaceholder")
		if placeholder is CanvasItem:
			(placeholder as CanvasItem).visible = false


func _collect_ticket_gallery_items() -> void:
	var changed := false
	for npc_id in Content.NPC_IDS:
		var state_key := str(TICKET_COLLECTION_KEYS.get(npc_id, ""))
		if state_key.is_empty():
			continue
		if FragmentManager.get_fragment_state("0002", state_key) == true:
			continue
		FragmentManager.set_fragment_state("0002", state_key, true)
		changed = true
	if changed and SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()


func _cache_ticket_homes() -> void:
	_ticket_home_positions.clear()
	for ticket in _ticket_layer.get_children():
		if ticket is Control:
			_ticket_home_positions[ticket.name] = (ticket as Control).position


func _reset_layout() -> void:
	_seat_assignments.clear()
	for ticket in _ticket_layer.get_children():
		if ticket is Control:
			_return_ticket_home(ticket as Control)


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


func _to_stage_position(local_pos: Vector2) -> Vector2:
	if _stage == null:
		return local_pos
	var scale_factor := _stage.scale.x
	if scale_factor <= 0.0:
		return local_pos
	return (local_pos - _stage.position) / scale_factor
