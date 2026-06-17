extends Control
class_name MonologuePanel

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const COVER_TARGET_ALPHA := 0.82
const COVER_FADE_SECONDS := 1.0
const STREAM_CHARS_PER_SECOND := 18.0
const HOLD_SKIP_SECONDS := 2.0
const DEFAULT_CONTINUE_HINT := "点击以继续"
const DEFAULT_COLLECT_HINT := "点击物品收集"
const DEFAULT_COLLECTED_HINT := "已收集，点击以继续"

signal monologue_finished(npc_id: String)

@onready var _stage: Control = $Stage
@onready var _body: Control = $Stage/Monologue
@onready var _text_label: RichTextLabel = $Stage/Monologue/Monologue
@onready var _cover: ColorRect = $Stage/Monologue/Cover
@onready var _texture_rect: TextureRect = $Stage/Monologue/MonologueTexture
@onready var _continue_hint: Label = $Stage/ContinueHint
@onready var _skip_hint: Label = $Stage/SkipHint

var _interactive_host: Control = null
var _pages: Array = []
var _npc_id := ""
var _page_index := -1
var _full_text := ""
var _visible_chars := 0
var _stream_progress := 0.0
var _streaming := false
var _page_ready := false
var _hold_time := 0.0
var _holding := false
var _interactive_collect_pending := false
var _suppress_release_after_collect := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	set_process_input(true)
	_interactive_host = _body.get_node_or_null("InteractiveHost") as Control
	if _interactive_host == null:
		_interactive_host = Control.new()
		_interactive_host.name = "InteractiveHost"
		_interactive_host.set_anchors_preset(Control.PRESET_FULL_RECT)
		_body.add_child(_interactive_host)
	get_viewport().size_changed.connect(_layout_to_viewport)
	_layout_to_viewport()


func open_for_npc(npc_id: String, pages: Array) -> void:
	_npc_id = npc_id
	_pages = pages.duplicate(true)
	_page_index = -1
	visible = true
	_continue_hint.visible = true
	_skip_hint.visible = true
	_continue_hint.text = DEFAULT_CONTINUE_HINT
	set_process(true)
	_layout_to_viewport()
	_show_next_page()


func close_monologue() -> void:
	var closing_id := _npc_id
	_clear_interactive()
	visible = false
	set_process(false)
	_streaming = false
	_page_ready = false
	_holding = false
	_hold_time = 0.0
	_text_label.text = ""
	_texture_rect.texture = null
	_continue_hint.visible = false
	_skip_hint.visible = false
	_interactive_collect_pending = false
	_suppress_release_after_collect = false
	_npc_id = ""
	_pages.clear()
	monologue_finished.emit(closing_id)


func is_streaming_for_test() -> bool:
	return _streaming


func get_page_index_for_test() -> int:
	return _page_index


func finish_current_page_for_test() -> void:
	_finish_stream()


func is_waiting_for_interactive_collect_for_test() -> bool:
	return _interactive_collect_pending


func _process(delta: float) -> void:
	if not visible:
		return
	if _holding:
		_hold_time += delta
		if _hold_time >= HOLD_SKIP_SECONDS:
			close_monologue()
			return
	if _streaming:
		_stream_progress += delta * STREAM_CHARS_PER_SECOND
		var next_chars := int(_stream_progress)
		if next_chars <= _visible_chars:
			return
		_visible_chars = mini(next_chars, _full_text.length())
		_text_label.text = _full_text.substr(0, _visible_chars)
		if _visible_chars >= _full_text.length():
			_finish_stream()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _suppress_release_after_collect and not event.pressed:
			_suppress_release_after_collect = false
			get_viewport().set_input_as_handled()
			return
		if _interactive_collect_pending:
			return
		if event.pressed:
			_holding = true
			_hold_time = 0.0
		else:
			var was_hold := _hold_time >= HOLD_SKIP_SECONDS
			_holding = false
			_hold_time = 0.0
			if not was_hold:
				_advance_or_finish()
		get_viewport().set_input_as_handled()


func _advance_or_finish() -> void:
	if _streaming:
		_finish_stream()
		return
	if _page_ready:
		_show_next_page()


func _show_next_page() -> void:
	_page_index += 1
	if _page_index >= _pages.size():
		close_monologue()
		return

	_clear_interactive()
	_text_label.text = ""
	_page_ready = false
	_streaming = false
	_stream_progress = 0.0
	_visible_chars = 0
	_interactive_collect_pending = false
	_suppress_release_after_collect = false
	_continue_hint.text = DEFAULT_CONTINUE_HINT

	var page: Dictionary = _pages[_page_index]
	_full_text = str(page.get("text", ""))
	_apply_page_texture(str(page.get("image_path", "")))
	_apply_interactive_scene(page)
	_fade_cover_then_stream()


func _fade_cover_then_stream() -> void:
	var color := _cover.color
	color.a = 0.0
	_cover.color = color
	var tween := create_tween()
	tween.tween_property(_cover, "color:a", COVER_TARGET_ALPHA, COVER_FADE_SECONDS)
	await tween.finished
	if visible:
		_start_stream()


func _start_stream() -> void:
	_streaming = true
	_page_ready = false
	_stream_progress = 0.0
	_visible_chars = 0
	_text_label.text = ""
	if _full_text.is_empty():
		_finish_stream()


func _finish_stream() -> void:
	_streaming = false
	_page_ready = true
	_visible_chars = _full_text.length()
	_stream_progress = float(_visible_chars)
	_text_label.text = _full_text


func _apply_page_texture(path: String) -> void:
	_texture_rect.texture = null
	if path.strip_edges().is_empty():
		return
	if ResourceLoader.exists(path):
		_texture_rect.texture = load(path) as Texture2D
	else:
		push_warning("[Monologue] Missing texture: %s" % path)


func _apply_interactive_scene(page: Dictionary) -> void:
	var scene_path := str(page.get("interactive_scene_path", "")).strip_edges()
	if scene_path.is_empty():
		return
	if not ResourceLoader.exists(scene_path):
		push_warning("[Monologue] Missing interactive scene: %s" % scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return
	var scene := packed.instantiate()
	if scene is Control:
		var control := scene as Control
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interactive_host.add_child(scene)

	var fragment_id := str(page.get("fragment_id", "0002")).strip_edges()
	if fragment_id.is_empty():
		fragment_id = "0002"
	var state_key := str(page.get("state_key", "")).strip_edges()
	var state_value = page.get("state_value", true)
	var current_value = FragmentManager.get_fragment_state(fragment_id, state_key) if state_key != "" else null
	_interactive_collect_pending = state_key != "" and not _state_values_match(current_value, state_value)
	_continue_hint.text = str(page.get("collect_hint", DEFAULT_COLLECT_HINT)) if _interactive_collect_pending else DEFAULT_CONTINUE_HINT
	if state_key != "":
		if scene.has_signal("state_triggered"):
			scene.state_triggered.connect(func() -> void:
				_mark_interactive_collected(fragment_id, state_key, state_value)
			)
		elif scene.has_signal("collected"):
			scene.collected.connect(func() -> void:
				_mark_interactive_collected(fragment_id, state_key, state_value)
			)


func _mark_interactive_collected(fragment_id: String, state_key: String, state_value) -> void:
	FragmentManager.set_fragment_state(fragment_id, state_key, state_value)
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	_interactive_collect_pending = false
	_suppress_release_after_collect = true
	_continue_hint.text = DEFAULT_COLLECTED_HINT


func _state_values_match(current_value, expected_value) -> bool:
	if current_value == null:
		return false
	if expected_value is bool:
		if current_value is bool:
			return current_value == expected_value
		if current_value is int or current_value is float:
			return (int(current_value) != 0) == expected_value
	if expected_value is int or expected_value is float:
		if current_value is bool:
			return current_value == (int(expected_value) != 0)
		if current_value is int or current_value is float:
			return int(current_value) == int(expected_value)
	return current_value == expected_value


func _clear_interactive() -> void:
	if _interactive_host == null:
		return
	for child in _interactive_host.get_children():
		child.queue_free()


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
