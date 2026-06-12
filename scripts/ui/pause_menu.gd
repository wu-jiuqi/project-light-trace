extends Control
## ESC pause menu autoload. Hosts the scene-based PauseMenu panel.

const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/SettingsPanel.tscn")
const SAVE_SLOT_GOLD := Color(0.92, 0.70, 0.30, 0.98)
const SAVE_SLOT_OUTLINE := Color(0.0, 0.0, 0.0, 1.0)
const SAVE_SLOT_OUTLINE_SIZE := 3

signal menu_opened
signal menu_closed

var is_open: bool = false
var _save_slots_visible: bool = false
var _canvas: CanvasLayer
var _menu: Control
var _settings_panel: SettingsPanel
var _overlay: ColorRect
var _pause_container: Control
var _save_slots_overlay: Control
var _resume_button: BaseButton
var _settings_button: BaseButton
var _save_button: BaseButton
var _star_map_button: BaseButton
var _title_button: BaseButton
var _slot_buttons: Array[BaseButton] = []
var _back_button: BaseButton
var _in_fragment: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	_canvas.name = "PauseMenuLayer"
	_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas)
	set_process_input(true)
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	if FragmentManager and FragmentManager.has_signal("fragment_entered"):
		FragmentManager.fragment_entered.connect(func(_id: String): _in_fragment = true)


func _ensure_ui() -> void:
	if is_instance_valid(_menu):
		return
	_slot_buttons.clear()
	_menu = PAUSE_MENU_SCENE.instantiate() as Control
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas.add_child(_menu)
	_overlay = _menu.get_node("Overlay") as ColorRect
	_pause_container = _menu.get_node("Stage/PauseContainer") as Control
	_save_slots_overlay = _menu.get_node("Stage/SaveSlotsOverlay") as Control
	_resume_button = _menu.get_node_or_null("Stage/PauseContainer/MenuButtons/ResumeButton") as BaseButton
	_settings_button = _menu.get_node_or_null("Stage/PauseContainer/MenuButtons/SettingsButton") as BaseButton
	_save_button = _menu.get_node_or_null("Stage/PauseContainer/MenuButtons/SaveButton") as BaseButton
	_star_map_button = _menu.get_node_or_null("Stage/PauseContainer/MenuButtons/StarMapButton") as BaseButton
	_title_button = _menu.get_node_or_null("Stage/PauseContainer/MenuButtons/TitleButton") as BaseButton
	_back_button = _menu.get_node_or_null("Stage/SaveSlotsOverlay/BackButton") as BaseButton
	_slot_buttons = [
		_menu.get_node_or_null("Stage/SaveSlotsOverlay/SlotButtons/Slot1Button") as BaseButton,
		_menu.get_node_or_null("Stage/SaveSlotsOverlay/SlotButtons/Slot2Button") as BaseButton,
		_menu.get_node_or_null("Stage/SaveSlotsOverlay/SlotButtons/Slot3Button") as BaseButton,
	]
	_connect_button_pressed(_resume_button, close, "Stage/PauseContainer/MenuButtons/ResumeButton")
	_connect_button_pressed(_settings_button, _show_settings, "Stage/PauseContainer/MenuButtons/SettingsButton")
	_connect_button_pressed(_save_button, _show_save_slots, "Stage/PauseContainer/MenuButtons/SaveButton")
	_connect_button_pressed(_star_map_button, _return_to_star_map, "Stage/PauseContainer/MenuButtons/StarMapButton")
	_connect_button_pressed(_title_button, _return_to_title, "Stage/PauseContainer/MenuButtons/TitleButton")
	_connect_button_pressed(_back_button, _hide_save_slots, "Stage/SaveSlotsOverlay/BackButton")
	for i in _slot_buttons.size():
		_connect_button_pressed(_slot_buttons[i], _do_save.bind(i), "Stage/SaveSlotsOverlay/SlotButtons/Slot%dButton" % (i + 1))
	_menu.visible = false


func _connect_button_pressed(button: BaseButton, callback: Callable, node_path: String) -> bool:
	if button == null:
		push_error("[PauseMenu] Missing BaseButton node: %s" % node_path)
		return false
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	return true


func _ensure_settings() -> void:
	if is_instance_valid(_settings_panel):
		return
	_settings_panel = SETTINGS_SCENE.instantiate() as SettingsPanel
	_settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_panel.visible = false
	_settings_panel.panel_closed.connect(_on_settings_closed)
	_canvas.add_child(_settings_panel)


func _input(event: InputEvent) -> void:
	if not (event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape")):
		return
	if _is_on_title_screen():
		return
	if ChatDialogue and ChatDialogue.is_open:
		return
	if is_instance_valid(_settings_panel) and _settings_panel.is_open:
		_settings_panel.cancel()
		get_viewport().set_input_as_handled()
		return
	if _save_slots_visible:
		_hide_save_slots()
		get_viewport().set_input_as_handled()
		return
	toggle()
	get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	_ensure_ui()
	is_open = true
	_save_slots_visible = false
	_refresh_slot_buttons()
	_star_map_button.visible = _in_fragment
	_menu.visible = true
	_overlay.visible = true
	_pause_container.visible = true
	_save_slots_overlay.visible = false
	menu_opened.emit()
	get_tree().paused = true
	print("[PauseMenu] 打开")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_save_slots_visible = false
	if is_instance_valid(_settings_panel) and _settings_panel.is_open:
		_settings_panel.close()
	if is_instance_valid(_menu):
		_menu.visible = false
		_pause_container.visible = false
		_save_slots_overlay.visible = false
	get_tree().paused = false
	menu_closed.emit()
	print("[PauseMenu] 关闭")


func _show_settings() -> void:
	_ensure_settings()
	_menu.visible = false
	_settings_panel.open()


func _on_settings_closed() -> void:
	if is_open and is_instance_valid(_menu):
		_menu.visible = true


func _show_save_slots() -> void:
	_save_slots_visible = true
	_refresh_slot_buttons()
	_pause_container.visible = false
	_save_slots_overlay.visible = true


func _hide_save_slots() -> void:
	_save_slots_visible = false
	_save_slots_overlay.visible = false
	_pause_container.visible = true


func _do_save(slot: int) -> void:
	if _slot_has_data(slot):
		_confirm_overwrite(slot)
		return
	_save_and_refresh(slot)


func _confirm_overwrite(slot: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.title = "覆盖存档"
	dialog.dialog_text = "存档 %d 已有记录，是否覆盖？" % (slot + 1)
	dialog.ok_button_text = "覆盖"
	dialog.cancel_button_text = "取消"
	dialog.confirmed.connect(func():
		_save_and_refresh(slot)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	_canvas.add_child(dialog)
	dialog.popup_centered()


func _save_and_refresh(slot: int) -> void:
	SaveManager.set_current_slot(slot)
	SaveManager.save_game(slot)
	_refresh_slot_buttons()
	_show_saved_notification(slot + 1)


func _refresh_slot_buttons() -> void:
	if _slot_buttons.is_empty():
		return
	var current := SaveManager.get_current_slot()
	for i in _slot_buttons.size():
		if not is_instance_valid(_slot_buttons[i]):
			continue
		var info := _get_slot_info(i)
		var suffix := " [当前]" if i == current else ""
		if info.is_empty():
			_set_button_text(_slot_buttons[i], "存档 %d - [空]%s" % [i + 1, suffix])
		else:
			_set_button_text(_slot_buttons[i], "存档 %d - %s%s" % [i + 1, info, suffix])


func _set_button_text(button: BaseButton, text: String) -> void:
	if button is Button:
		(button as Button).text = text
		return

	var label := button.get_node_or_null("TextLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "TextLabel"
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(label)
	label.add_theme_color_override("font_color", SAVE_SLOT_GOLD)
	label.add_theme_color_override("font_outline_color", SAVE_SLOT_OUTLINE)
	label.add_theme_color_override("font_shadow_color", Color(0.95, 0.72, 0.28, 0.35))
	label.add_theme_constant_override("outline_size", SAVE_SLOT_OUTLINE_SIZE)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 18)
	label.text = text


func _get_slot_info(slot: int) -> String:
	for s in SaveManager.list_slots():
		if int(s.get("slot", -1)) == slot:
			return str(s.get("timestamp_readable", ""))
	return ""


func _slot_has_data(slot: int) -> bool:
	return not _get_slot_info(slot).is_empty()


func _return_to_title() -> void:
	close()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _return_to_star_map() -> void:
	close()
	await get_tree().process_frame
	_in_fragment = false
	SceneManager.pending_spawn_point = ""
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _is_on_title_screen() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == "res://scenes/ui/title_screen.tscn"


func _show_saved_notification(slot: int) -> void:
	var label := Label.new()
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	label.text = "已保存到存档 %d" % slot
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport_rect().size.x / 2 - 100, 96)
	label.size = Vector2(200, 40)
	label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.075, 1))
	label.add_theme_font_size_override("font_size", 17)
	_canvas.add_child(label)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(1.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)
