extends Control
## QQ风格聊天UI — autoload
## 底部半透明面板 + 消息气泡 + 输入栏 + 流式输出
## 使用 CanvasLayer 确保渲染在最上层

const UITheme = preload("res://scripts/ui/ui_theme.gd")
const DIALOGUE_BOX_SCENE = preload("res://scenes/ui/DialogueBox.tscn")
const DIALOGUE_HISTORY_SCENE = preload("res://scenes/ui/DialogueHistory.tscn")
const DIALOGUE_DESIGN_SIZE := Vector2(1280.0, 720.0)
const PORTRAIT_DIM: float = 0.45
const PORTRAIT_FULL: float = 1.0

signal dialogue_opened(npc_name: String)
signal dialogue_closed()
signal player_message_sent(message: String)
signal continue_requested()

# UI
var _canvas: CanvasLayer
var _overlay: ColorRect
var _dialogue_box: Control
var _dialogue_stage: Control
var _dialogue_host: Node
var _panel: Panel
var _name_label: Label
var _chat_display: RichTextLabel
var _input_bar: Panel
var _input_box: LineEdit
var _send_btn: Button
var _give_btn: Button
var _history_btn: Button
var _think_label: Label
var _player_portrait: TextureRect
var _npc_portrait: TextureRect

# 历史模式
var _history_mode: bool = false
var _history_panel: DialogueHistoryPanel

# 状态
var is_open: bool = false
var npc_name: String = ""
var _npc: Node = null
var _base_text: String = ""
var _stream_text: String = ""
var _stream_pending_text: String = ""
var _stream_final_text: String = ""
var _stream_finish_requested: bool = false
var _stream_flush_progress: float = 0.0
var _continue_prompt_active: bool = false
var _focus_retry_count: int = 0
var _ui_built: bool = false
const FOCUS_MAX_RETRIES: int = 8
const STREAM_CHARS_PER_SECOND: float = 46.0
const STREAM_MAX_CHARS_PER_FRAME: int = 3
const CONTINUE_PROMPT_TEXT_COLOR := Color(0.03, 0.025, 0.018, 1.0)


func _ready() -> void:
	add_to_group("dialogue_ui")
	
	# 创建 CanvasLayer —— 确保 UI 始终在游戏画面上层
	_canvas = CanvasLayer.new()
	_canvas.layer = 128  # 最高层
	_canvas.name = "ChatDialogueLayer"
	add_child(_canvas)
	
	
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)
	if not SceneManager.scene_changing.is_connected(_on_scene_changing):
		SceneManager.scene_changing.connect(_on_scene_changing)


func _on_scene_changing(_target_scene: String, _spawn_point: String) -> void:
	_reset_scene_ui_refs()
	_ui_built = false
	_npc = null
	npc_name = ""
	if is_instance_valid(_history_panel):
		_history_panel.visible = false


func _ensure_ui() -> void:
	if _ui_built and _has_live_ui():
		return
	_reset_scene_ui_refs()
	_build_ui()
	_ui_built = true
	_has_required_dialogue_nodes()
	print("[ChatDialogue] UI就绪 | 视口=%dx%d" % [get_viewport_rect().size.x, get_viewport_rect().size.y])


func _has_live_ui() -> bool:
	return is_instance_valid(_dialogue_box) \
		and is_instance_valid(_dialogue_stage) \
		and is_instance_valid(_panel) \
		and is_instance_valid(_chat_display) \
		and is_instance_valid(_input_box) \
		and is_instance_valid(_send_btn) \
		and is_instance_valid(_history_btn)


func _reset_scene_ui_refs() -> void:
	is_open = false
	_history_mode = false
	_focus_retry_count = 0
	_overlay = null
	_dialogue_box = null
	_dialogue_stage = null
	_dialogue_host = null
	_panel = null
	_name_label = null
	_chat_display = null
	_input_bar = null
	_input_box = null
	_send_btn = null
	_give_btn = null
	_history_btn = null
	_think_label = null
	_player_portrait = null
	_npc_portrait = null
	_base_text = ""
	_stream_text = ""
	_stream_pending_text = ""
	_stream_final_text = ""
	_stream_finish_requested = false
	_stream_flush_progress = 0.0
	_continue_prompt_active = false
	_clear_continue_prompt_style()


func _build_ui() -> void:
	var vs = get_viewport_rect().size
	if vs.x <= 0 or vs.y <= 0:
		vs = Vector2(1280, 720)  # 回退默认值
		print("[ChatDialogue] 视口无效，使用默认 1280x720")
	
	_dialogue_box = _find_scene_dialogue_box()
	if _dialogue_box:
		_dialogue_host = _dialogue_box.get_parent()
	else:
		_dialogue_host = _canvas

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.18)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_dialogue_host.add_child(_overlay)

	if _dialogue_box:
		_dialogue_host.move_child(_overlay, _dialogue_box.get_index())
	else:
		_dialogue_box = DIALOGUE_BOX_SCENE.instantiate() as Control
		_dialogue_box.visible = false
		_dialogue_host.add_child(_dialogue_box)

	_dialogue_stage = _dialogue_box.get_node_or_null("Stage") as Control
	if _dialogue_stage == null:
		_dialogue_stage = _dialogue_box

	_panel = _dialogue_stage.get_node_or_null("DialoguePanel") as Panel
	_player_portrait = _dialogue_stage.get_node_or_null("PlayerPortrait") as TextureRect
	_npc_portrait = _dialogue_stage.get_node_or_null("NpcPortrait") as TextureRect
	_name_label = _dialogue_stage.get_node_or_null("DialoguePanel/NamePlate/NameLabel") as Label
	if _name_label == null:
		_name_label = _dialogue_stage.get_node_or_null("DialoguePanel/NameLabel") as Label
	_chat_display = _dialogue_stage.get_node_or_null("DialoguePanel/ChatDisplay") as RichTextLabel
	_input_bar = _dialogue_stage.get_node_or_null("DialoguePanel/InputBar") as Panel
	_input_box = _dialogue_stage.get_node_or_null("DialoguePanel/InputBar/InputBox") as LineEdit
	_send_btn = _dialogue_stage.get_node_or_null("DialoguePanel/ButtonRow/SendButton") as Button
	_give_btn = _dialogue_stage.get_node_or_null("DialoguePanel/ButtonRow/GiveButton") as Button
	_history_btn = _dialogue_stage.get_node_or_null("DialoguePanel/ButtonRow/HistoryButton") as Button

	if _name_label == null and _panel != null:
		push_error("[ChatDialogue] DialogueBox.tscn 缺少 NameLabel，请放在 DialoguePanel/NamePlate/NameLabel 或 DialoguePanel/NameLabel")
		_name_label = Label.new()
		_name_label.name = "NameLabel"
		_name_label.position = Vector2(24, -44)
		_name_label.size = Vector2(220, 36)
		_name_label.add_theme_color_override("font_color", Color(0.41, 0.27, 0.08, 1.0))
		_name_label.add_theme_font_size_override("font_size", 22)
		_panel.add_child(_name_label)

	_think_label = Label.new()
	_think_label.name = "ThinkLabel"
	_think_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_think_label.position = Vector2(-220, 16)
	_think_label.size = Vector2(190, 28)
	_think_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_think_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.16, 0.72))
	_think_label.add_theme_font_size_override("font_size", 15)
	if _panel != null:
		_panel.add_child(_think_label)

	if _input_box:
		_input_box.text_submitted.connect(_do_send)
	_connect_button_pressed(_send_btn, _do_send.bind(""), "DialoguePanel/ButtonRow/SendButton")
	if _connect_button_pressed(_give_btn, _do_give, "DialoguePanel/ButtonRow/GiveButton"):
		_give_btn.visible = true
		_give_btn.disabled = true
	_connect_button_pressed(_history_btn, _show_history, "DialoguePanel/ButtonRow/HistoryButton")
	
	if not get_viewport().size_changed.is_connected(_layout_dialogue_box):
		get_viewport().size_changed.connect(_layout_dialogue_box)
	_layout_dialogue_box()
	_build_history_panel(vs)


func _has_required_dialogue_nodes() -> bool:
	var missing: Array[String] = []
	if not is_instance_valid(_dialogue_box):
		missing.append("DialogueBox")
	if not is_instance_valid(_dialogue_stage):
		missing.append("Stage")
	if not is_instance_valid(_panel):
		missing.append("DialoguePanel")
	if not is_instance_valid(_chat_display):
		missing.append("DialoguePanel/ChatDisplay")
	if not is_instance_valid(_input_box):
		missing.append("DialoguePanel/InputBar/InputBox")
	if not is_instance_valid(_send_btn):
		missing.append("DialoguePanel/ButtonRow/SendButton")
	if not is_instance_valid(_give_btn):
		missing.append("DialoguePanel/ButtonRow/GiveButton")
	if not is_instance_valid(_history_btn):
		missing.append("DialoguePanel/ButtonRow/HistoryButton")
	if not is_instance_valid(_name_label):
		missing.append("DialoguePanel/NameLabel")
	if not missing.is_empty():
		push_error("[ChatDialogue] UI节点缺失，已阻止写入空节点: %s" % ", ".join(missing))
		return false
	return true


func _ensure_required_dialogue_nodes(context: String) -> bool:
	_ensure_ui()
	if _has_required_dialogue_nodes():
		return true
	push_error("[ChatDialogue] %s 失败：对话UI未就绪" % context)
	return false


func _find_scene_dialogue_box() -> Control:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var found := scene.find_child("DialogueBox", true, false)
	if found is Control:
		return found as Control
	return null


func _connect_button_pressed(button: Button, callback: Callable, node_path: String) -> bool:
	if button == null:
		push_error("[ChatDialogue] Missing Button node: %s" % node_path)
		return false
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if not button.pressed.is_connected(UISoundManager.play_click):
		button.pressed.connect(UISoundManager.play_click)
	return true


func _layout_dialogue_box() -> void:
	if not _dialogue_box or not _dialogue_stage:
		return

	var vs: Vector2 = get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		vs = DIALOGUE_DESIGN_SIZE

	_dialogue_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_box.offset_left = 0.0
	_dialogue_box.offset_top = 0.0
	_dialogue_box.offset_right = 0.0
	_dialogue_box.offset_bottom = 0.0

	var scale_factor: float = min(vs.x / DIALOGUE_DESIGN_SIZE.x, vs.y / DIALOGUE_DESIGN_SIZE.y)
	var scaled_size: Vector2 = DIALOGUE_DESIGN_SIZE * scale_factor
	_dialogue_stage.position = (vs - scaled_size) * 0.5
	_dialogue_stage.size = DIALOGUE_DESIGN_SIZE
	_dialogue_stage.scale = Vector2(scale_factor, scale_factor)


func _build_history_panel(_vs: Vector2) -> void:
	if is_instance_valid(_history_panel):
		return
	_history_panel = DIALOGUE_HISTORY_SCENE.instantiate() as DialogueHistoryPanel
	_history_panel.visible = false
	_history_panel.panel_closed.connect(_on_history_panel_closed)
	_canvas.add_child(_history_panel)

func _process(delta: float) -> void:
	if not is_open:
		return
	_flush_stream_text(delta)
	if _focus_retry_count > 0:
		_focus_retry_count -= 1
		if _input_box:
			_input_box.grab_focus()
			if _input_box.has_focus():
				_focus_retry_count = 0


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if _continue_prompt_active and _is_continue_prompt_event(event):
		_finish_continue_prompt()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if _history_mode:
			_close_history()
		else:
			close()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if _continue_prompt_active and _is_continue_prompt_event(event):
		_finish_continue_prompt()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if _history_mode:
			_close_history()
		else:
			close()
		get_viewport().set_input_as_handled()


func open(npc_ctrl: Node, greeting: String = "") -> void:
	if not npc_ctrl:
		return
	
	# 确保UI已构建
	if not _ensure_required_dialogue_nodes("open"):
		return
	
	_npc = npc_ctrl
	npc_name = npc_ctrl.npc_name
	_chat_display.text = ""
	_base_text = ""
	_stream_text = ""
	_continue_prompt_active = false
	_clear_continue_prompt_style()
	
	_name_label.text = npc_name
	_think_label.text = ""
	_input_box.text = ""
	_input_box.editable = true
	_send_btn.disabled = false
	_give_btn.visible = true
	_give_btn.disabled = true
	_set_portraits(npc_ctrl)
	_set_portrait_state(true)
	_layout_dialogue_box()
	
	_overlay.visible = true
	_dialogue_box.visible = true
	_panel.visible = true
	is_open = true
	
	if greeting != "":
		stream_local_npc_msg(greeting)
	
	_focus_retry_count = FOCUS_MAX_RETRIES
	call_deferred("_grab_input_focus")
	
	# 检查是否可给予物品
	if _npc.has_method("can_give_item"):
		var givable = _npc.can_give_item()
		if givable:
			_give_btn.disabled = false
		else:
			_give_btn.disabled = true
	else:
		_give_btn.disabled = true
	
	dialogue_opened.emit(npc_name)
	print("[Chat] 打开: %s" % npc_name)


func close() -> void:
	if not is_open:
		return
	_history_mode = false
	if _history_panel and _history_panel.is_open:
		_history_panel.close()
	is_open = false
	_focus_retry_count = 0
	_overlay.visible = false
	_dialogue_box.visible = false
	_panel.visible = false
	
	if _npc and _npc.has_method("end_dialogue"):
		_npc.end_dialogue()
	
	var name = npc_name
	_npc = null
	npc_name = ""
	_chat_display.text = ""
	_stream_text = ""
	_stream_pending_text = ""
	_stream_final_text = ""
	_stream_finish_requested = false
	_stream_flush_progress = 0.0
	_continue_prompt_active = false
	_clear_continue_prompt_style()
	print("[Chat] 关闭: %s" % name)
	if _npc_portrait:
		_npc_portrait.texture = null
		_npc_portrait.visible = false
		_npc_portrait.modulate.a = PORTRAIT_FULL
	if _player_portrait:
		_player_portrait.modulate.a = PORTRAIT_FULL
	dialogue_closed.emit()


# ============================================================
# 历史对话查看
# ============================================================

func _show_history() -> void:
	if not _npc or npc_name == "":
		return
	if not _ensure_required_dialogue_nodes("_show_history"):
		return
	if not is_instance_valid(_history_panel):
		_build_history_panel(get_viewport_rect().size)
	var kb_id = _npc.npc_kb_id
	if kb_id == "":
		return
	
	_history_mode = true
	
	_dialogue_box.visible = false
	_panel.visible = false
	_overlay.visible = true
	_history_panel.open_for_npc(kb_id, npc_name)


func _close_history() -> void:
	if not _history_mode:
		return
	_history_mode = false
	if _history_panel and _history_panel.is_open:
		_history_panel.close()
	_restore_dialogue_after_history()


func _on_history_panel_closed() -> void:
	if not _history_mode:
		return
	_history_mode = false
	_restore_dialogue_after_history()


func _restore_dialogue_after_history() -> void:
	if is_open:
		_overlay.visible = true
		_dialogue_box.visible = true
		_panel.visible = true
		_focus_retry_count = FOCUS_MAX_RETRIES
		call_deferred("_grab_input_focus")


func _format_time(ts: int) -> String:
	var dt = Time.get_datetime_dict_from_unix_time(ts)
	return "%02d:%02d" % [dt["hour"], dt["minute"]]


func stream_begin() -> void:
	if not _ensure_required_dialogue_nodes("stream_begin"):
		return
	_stream_text = ""
	_stream_pending_text = ""
	_stream_final_text = ""
	_stream_finish_requested = false
	_stream_flush_progress = 0.0
	_continue_prompt_active = false
	_clear_continue_prompt_style()
	_base_text = _chat_display.text
	_think_label.text = "正在输入..."
	_input_box.editable = false
	_send_btn.disabled = true
	_set_portrait_state(false)


func stream_add(token: String) -> void:
	if not _ensure_required_dialogue_nodes("stream_add"):
		return
	_stream_pending_text += token
	if _stream_text.is_empty():
		_flush_stream_text(1.0 / STREAM_CHARS_PER_SECOND)


func stream_end(full_text: String) -> void:
	if not _ensure_required_dialogue_nodes("stream_end"):
		return
	_stream_final_text = full_text
	_stream_finish_requested = true
	if _stream_pending_text.is_empty():
		_finish_stream_text()


func is_streaming_response() -> bool:
	return _stream_finish_requested or not _stream_pending_text.is_empty()


func _flush_stream_text(delta: float) -> void:
	if _stream_pending_text.is_empty():
		if _stream_finish_requested:
			_finish_stream_text()
		return

	_stream_flush_progress += delta * STREAM_CHARS_PER_SECOND
	var chars_to_flush := int(_stream_flush_progress)
	if chars_to_flush <= 0:
		return
	chars_to_flush = mini(chars_to_flush, STREAM_MAX_CHARS_PER_FRAME)
	chars_to_flush = mini(chars_to_flush, _stream_pending_text.length())

	_stream_text += _stream_pending_text.substr(0, chars_to_flush)
	_stream_pending_text = _stream_pending_text.substr(chars_to_flush)
	_stream_flush_progress = maxf(0.0, _stream_flush_progress - float(chars_to_flush))
	if _stream_flush_progress > float(STREAM_MAX_CHARS_PER_FRAME):
		_stream_flush_progress = float(STREAM_MAX_CHARS_PER_FRAME)
	_chat_display.text = _base_text + "[outline_size=2][outline_color=black][color=#D4B86A][%s][/color][/outline_color][/outline_size] %s" % [npc_name, _stream_text]

	if _stream_pending_text.is_empty() and _stream_finish_requested:
		_finish_stream_text()


func _finish_stream_text() -> void:
	if _stream_final_text == "" and _stream_text != "":
		_stream_final_text = _stream_text
	_stream_text = ""
	_stream_pending_text = ""
	_stream_flush_progress = 0.0
	_chat_display.text = _base_text + "[outline_size=2][outline_color=black][color=#D4B86A][%s][/color][/outline_color][/outline_size] %s\n" % [npc_name, _stream_final_text]
	_base_text = _chat_display.text
	_stream_final_text = ""
	_stream_finish_requested = false
	_think_label.text = ""
	_set_portrait_state(true)
	_input_restore()


func add_npc_msg(text: String) -> void:
	if not _ensure_required_dialogue_nodes("add_npc_msg"):
		return
	_add_npc_msg(text)
	_input_restore()


func stream_local_npc_msg(text: String) -> void:
	if not _ensure_required_dialogue_nodes("stream_local_npc_msg"):
		return
	stream_begin()
	var index := 0
	var chunk_size := 1
	while is_open and index < text.length():
		var length: int = mini(chunk_size, text.length() - index)
		stream_add(text.substr(index, length))
		index += length
		await get_tree().create_timer(0.018).timeout
	if is_open:
		stream_end(text)
		while is_open and _stream_finish_requested:
			await get_tree().create_timer(0.02).timeout


func wait_for_continue(prompt_text: String = "点击任意位置继续") -> void:
	if not is_open:
		return
	if not _ensure_required_dialogue_nodes("wait_for_continue"):
		return
	_show_continue_prompt(prompt_text)
	await continue_requested


func _show_continue_prompt(prompt_text: String) -> void:
	_continue_prompt_active = true
	_focus_retry_count = 0
	_think_label.text = ""
	_input_box.text = prompt_text
	_input_box.add_theme_color_override("font_uneditable_color", CONTINUE_PROMPT_TEXT_COLOR)
	_input_box.editable = false
	_input_box.release_focus()
	_send_btn.disabled = true
	_give_btn.disabled = true


func _is_continue_prompt_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")


func _finish_continue_prompt() -> void:
	if not _continue_prompt_active:
		return
	_continue_prompt_active = false
	if _input_box != null:
		_input_box.text = ""
	_clear_continue_prompt_style()
	continue_requested.emit()


func _clear_continue_prompt_style() -> void:
	if _input_box != null:
		_input_box.remove_theme_color_override("font_uneditable_color")


func add_player_msg(text: String) -> void:
	if not _ensure_required_dialogue_nodes("add_player_msg"):
		return
	_chat_display.text += "[right][color=#5599cc][ 你 ][/color] %s[/right]\n" % text
	_base_text = _chat_display.text


func input_restore() -> void:
	if not _ensure_required_dialogue_nodes("input_restore"):
		return
	_set_portrait_state(true)
	_input_box.editable = true
	_send_btn.disabled = false
	_focus_retry_count = FOCUS_MAX_RETRIES
	call_deferred("_grab_input_focus")


func _grab_input_focus() -> void:
	if _input_box and is_open:
		_input_box.grab_focus()


func _do_send(text: String = "") -> void:
	if not _ensure_required_dialogue_nodes("_do_send"):
		return
	var msg = text.strip_edges()
	if msg == "":
		msg = _input_box.text.strip_edges()
	if msg == "":
		return
	
	_input_box.text = ""
	_input_box.editable = false
	_send_btn.disabled = true
	
	_chat_display.text += "[right][color=#5599cc][ 你 ][/color] %s[/right]\n" % msg
	_base_text = _chat_display.text
	
	player_message_sent.emit(msg)
	if _npc and _npc.has_method("send_player_message"):
		_npc.send_player_message(msg)
	else:
		printerr("[Chat] NPC 无效或缺少 send_player_message 方法")
		add_npc_msg("[系统] NPC响应模块不可用")


func _do_give() -> void:
	## 玩家点击给予按钮
	if not _npc or not _npc.has_method("send_give_item"):
		return
	var item = _npc.get_givable_item()
	if item.is_empty(): return
	
	_npc.send_give_item(item["item_id"])
	_give_btn.disabled = true


func _add_npc_msg(text: String) -> void:
	if _chat_display == null:
		push_error("[ChatDialogue] _add_npc_msg 失败：ChatDisplay 为空")
		return
	_chat_display.text += "[outline_size=2][outline_color=black][color=#D4B86A][%s][/color][/outline_color][/outline_size] %s\n" % [npc_name, text]
	_base_text = _chat_display.text


func _input_restore() -> void:
	input_restore()


func _set_portraits(npc_ctrl: Node) -> void:
	if _player_portrait:
		_player_portrait.visible = _player_portrait.texture != null
	if not _npc_portrait:
		return

	var portrait := _load_npc_portrait(npc_ctrl)
	_npc_portrait.texture = portrait
	_npc_portrait.visible = portrait != null


## 根据当前"谁在说话"调整两个立绘透明度
## player_active=true  → 玩家立绘完全显示，NPC 立绘半透明（玩家打字/输入状态）
## player_active=false → NPC 立绘完全显示，玩家立绘半透明（NPC 流式输出中）
func _set_portrait_state(player_active: bool) -> void:
	if _npc_portrait:
		_npc_portrait.modulate.a = PORTRAIT_DIM if player_active else PORTRAIT_FULL
	if _player_portrait:
		_player_portrait.modulate.a = PORTRAIT_FULL if player_active else PORTRAIT_DIM


func _load_npc_portrait(npc_ctrl: Node) -> Texture2D:
	if not npc_ctrl or not ("npc_kb_id" in npc_ctrl):
		return null

	var npc_id := String(npc_ctrl.npc_kb_id)
	if npc_id == "":
		return null

	var fragment_dir := _get_portrait_fragment_dir(npc_ctrl)
	var portrait_dir := "res://assets/papercraft/fragments/%s/characters" % fragment_dir
	var files := DirAccess.get_files_at(portrait_dir)
	for file_name in files:
		if file_name.ends_with("_l.png") and file_name.find(npc_id) != -1:
			var path := "%s/%s" % [portrait_dir, file_name]
			if ResourceLoader.exists(path):
				return load(path) as Texture2D

	push_warning("[ChatDialogue] No large portrait found for npc_id=%s in %s" % [npc_id, portrait_dir])
	return null


func _get_portrait_fragment_dir(npc_ctrl: Node) -> String:
	if FragmentManager.current_fragment != null:
		var current_id := String(FragmentManager.current_fragment.id)
		if current_id.begins_with("id"):
			return current_id
		return "id%s" % current_id

	var scene_path := npc_ctrl.scene_file_path
	for part in scene_path.split("/"):
		if String(part).begins_with("id"):
			return String(part)
	return "id0001"
