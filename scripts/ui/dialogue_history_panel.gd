class_name DialogueHistoryPanel
extends BasePanel

const HISTORY_PAGE_SIZE := 30
const BUTTON_NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const BUTTON_HOVER_MODULATE := Color(1.12, 1.06, 0.88, 1.0)
const BUTTON_PRESSED_MODULATE := Color(0.78, 0.66, 0.48, 1.0)
const BUTTON_DISABLED_MODULATE := Color(0.54, 0.50, 0.44, 0.48)

@onready var page_info: Label = get_node_or_null("Stage/DialogPanel/TitleBar/PageInfo") as Label
@onready var history_display: RichTextLabel = get_node_or_null("Stage/DialogPanel/HistoryScroll/HistoryDisplay") as RichTextLabel
@onready var back_button: BaseButton = get_node_or_null("Stage/DialogPanel/TitleBar/BackButton") as BaseButton
@onready var prev_button: BaseButton = get_node_or_null("Stage/DialogPanel/ButtonRow/PrevButton") as BaseButton
@onready var next_button: BaseButton = get_node_or_null("Stage/DialogPanel/ButtonRow/NextButton") as BaseButton

var _npc_id: String = ""
var _npc_name: String = ""
var _page: int = 0
var _total_pages: int = 0


func _on_ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_button_pressed(back_button, close, "Stage/DialogPanel/TitleBar/BackButton")
	_connect_button_pressed(prev_button, _prev_page, "Stage/DialogPanel/ButtonRow/PrevButton")
	_connect_button_pressed(next_button, _next_page, "Stage/DialogPanel/ButtonRow/NextButton")
	_setup_button_feedback(back_button)
	_setup_button_feedback(prev_button)
	_setup_button_feedback(next_button)
	_sync_all_button_feedback()


func open_for_npc(npc_id: String, npc_name: String) -> void:
	_npc_id = npc_id
	_npc_name = npc_name
	_page = 0
	_load_page()
	open()
	_sync_all_button_feedback()


func add_message(speaker: String, text: String) -> void:
	if history_display == null:
		return
	history_display.text += "[b]%s[/b] %s\n" % [_escape_bbcode(speaker), _escape_bbcode(text)]
	scroll_to_bottom()


func clear() -> void:
	if history_display:
		history_display.text = ""
	if page_info:
		page_info.text = ""


func scroll_to_bottom() -> void:
	if history_display == null:
		return
	await get_tree().process_frame
	history_display.scroll_to_line(history_display.get_line_count())


func _load_page() -> void:
	if page_info == null or history_display == null:
		return
	if _npc_id.is_empty():
		clear()
		return

	var result := ChatDatabase.get_page(_npc_id, _page, HISTORY_PAGE_SIZE)
	_total_pages = maxi(int(result.get("total_pages", 1)), 1)
	_page = clampi(int(result.get("page", 0)), 0, _total_pages - 1)
	var total := int(result.get("total", 0))
	var messages: Array = result.get("messages", [])
	page_info.text = "第 %d/%d 页 · 共 %d 条%s" % [
		_page + 1,
		_total_pages,
		total,
		" · 最新" if _page == 0 else ""
	]
	if prev_button:
		prev_button.disabled = _page <= 0
	if next_button:
		next_button.disabled = _page >= _total_pages - 1
	_sync_all_button_feedback()

	if messages.is_empty():
		history_display.text = "[center][color=#7A6B5C]暂无对话历史[/color][/center]"
		return

	var output := ""
	for msg in messages:
		if msg is not Dictionary:
			continue
		var role := str(msg.get("role", ""))
		var content := _sanitize_content(msg.get("content", ""))
		if content.is_empty():
			continue
		var time_str := _format_time(int(msg.get("timestamp", 0)))
		if role == "player":
			output += "[right][color=#7A6B5C]%s[/color] [color=#4f79a8]You[/color]: %s[/right]\n\n" % [time_str, _escape_bbcode(content)]
		else:
			output += "[color=#7A6B5C]%s[/color] [color=#B28E51]%s[/color]: %s\n\n" % [time_str, _escape_bbcode(_npc_name), _escape_bbcode(content)]
	history_display.text = output


func _prev_page() -> void:
	if _page <= 0:
		return
	_page -= 1
	_load_page()


func _next_page() -> void:
	if _page >= _total_pages - 1:
		return
	_page += 1
	_load_page()


func _setup_button_feedback(button: BaseButton) -> void:
	if button == null:
		return
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not button.mouse_entered.is_connected(_on_history_button_mouse_entered.bind(button)):
		button.mouse_entered.connect(_on_history_button_mouse_entered.bind(button))
	if not button.mouse_exited.is_connected(_on_history_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_history_button_mouse_exited.bind(button))
	if not button.button_down.is_connected(_on_history_button_down.bind(button)):
		button.button_down.connect(_on_history_button_down.bind(button))
	if not button.button_up.is_connected(_on_history_button_up.bind(button)):
		button.button_up.connect(_on_history_button_up.bind(button))


func _sync_all_button_feedback() -> void:
	_sync_button_feedback(back_button)
	_sync_button_feedback(prev_button)
	_sync_button_feedback(next_button)


func _sync_button_feedback(button: BaseButton) -> void:
	if button == null:
		return
	if button.disabled:
		button.modulate = BUTTON_DISABLED_MODULATE
		button.set_meta("history_pressed", false)
	elif bool(button.get_meta("history_pressed", false)):
		button.modulate = BUTTON_PRESSED_MODULATE
	elif button.is_hovered():
		button.modulate = BUTTON_HOVER_MODULATE
	else:
		button.modulate = BUTTON_NORMAL_MODULATE


func _on_history_button_mouse_entered(button: BaseButton) -> void:
	_sync_button_feedback(button)


func _on_history_button_mouse_exited(button: BaseButton) -> void:
	if button:
		button.set_meta("history_pressed", false)
	_sync_button_feedback(button)


func _on_history_button_down(button: BaseButton) -> void:
	if button and not button.disabled:
		button.set_meta("history_pressed", true)
	_sync_button_feedback(button)


func _on_history_button_up(button: BaseButton) -> void:
	if button:
		button.set_meta("history_pressed", false)
	_sync_button_feedback(button)


func _format_time(ts: int) -> String:
	if ts <= 0:
		return "--:--"
	var dt := Time.get_datetime_dict_from_unix_time(ts)
	return "%02d:%02d" % [dt["hour"], dt["minute"]]


func _sanitize_content(value: Variant) -> String:
	if value == null:
		return ""
	return str(value).replace("<null>", "").strip_edges()


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")
