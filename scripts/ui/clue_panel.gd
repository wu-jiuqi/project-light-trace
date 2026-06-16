class_name CluePanel
extends BasePanel

const ClueCardScene: PackedScene = preload("res://scenes/ui/components/ClueCard.tscn")
const ESC_CLOSE_BEFORE_PAUSE_GROUP := "esc_close_before_pause"

@onready var clue_list: VBoxContainer = $"Stage/MainContainer/ClueListScroll/ClueList"
@onready var detail_overlay: Control = $"DetailOverlay"
@onready var undiscovered_hint: Label = $"Stage/MainContainer/UndiscoveredHint"
@onready var clue_title_label: Label = $"DetailOverlay/DetailContent/ClueTitleLabel"
@onready var clue_description: RichTextLabel = $"DetailOverlay/DetailContent/ClueDescription"
@onready var related_list: HBoxContainer = $"DetailOverlay/DetailContent/RelatedSection/RelatedContainer/RelatedList"
@onready var close_button: BaseButton = $"Stage/MainContainer/TitleBar/CloseButton"
@onready var close_detail_btn: BaseButton = $"DetailOverlay/DetailContent/CloseDetailBtn"

var clues: Array[Dictionary] = []
var _clue_image: TextureRect = null


func _on_ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	_connect_button_pressed(close_button, close, "Stage/MainContainer/TitleBar/CloseButton")
	_connect_button_pressed(close_detail_btn, hide_clue_detail, "DetailOverlay/DetailContent/CloseDetailBtn")
	hide_clue_detail()
	_ensure_clue_image()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		close_from_cancel_action()
		get_viewport().set_input_as_handled()


func close_from_cancel_action() -> void:
	if is_instance_valid(close_button):
		close_button.pressed.emit()
	else:
		close()


func _on_open() -> void:
	add_to_group(ESC_CLOSE_BEFORE_PAUSE_GROUP)


func _on_close() -> void:
	remove_from_group(ESC_CLOSE_BEFORE_PAUSE_GROUP)
	hide_clue_detail()


func set_clues_from_dictionaries(new_clues: Array[Dictionary]) -> void:
	clues = []
	for i in range(new_clues.size()):
		var entry := new_clues[i].duplicate(true)
		if not entry.has("id"):
			entry["id"] = i
		entry["is_discovered"] = entry.get("is_discovered", true)
		clues.append(entry)
	refresh_clues()


func refresh_clues() -> void:
	if clue_list == null:
		return
	for child in clue_list.get_children():
		child.queue_free()

	var discovered := clues.filter(func(c: Dictionary): return bool(c.get("is_discovered", true)))
	undiscovered_hint.visible = discovered.is_empty()
	if discovered.is_empty():
		hide_clue_detail()
		return

	for data in clues:
		var card := ClueCardScene.instantiate() as ClueCard
		clue_list.add_child(card)
		card.set_clue(data)
		card.pressed.connect(show_clue_detail)
		card.pressed.connect(UISoundManager.play_click)


func show_clue_detail(clue_id: int) -> void:
	var data := _find_clue(clue_id)
	if data.is_empty() or not bool(data.get("is_discovered", true)):
		return

	clue_title_label.text = str(data.get("name", "未知线索"))
	var body := str(data.get("description", "暂无描述。"))
	var type_text := str(data.get("type", ""))
	var location := str(data.get("location", ""))
	var collected_at := str(data.get("discovered_at", ""))
	if not type_text.is_empty():
		body += "\n\n类型：" + _type_to_label(type_text)
	if not location.is_empty():
		body += "\n来源：" + location
	if not collected_at.is_empty():
		body += "\n记录时间：" + collected_at
	clue_description.text = body
	_update_clue_image(str(data.get("image", "")))

	for child in related_list.get_children():
		child.queue_free()
	for related in data.get("related_clue_ids", []):
		var label := Label.new()
		label.text = str(related)
		label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
		related_list.add_child(label)
	detail_overlay.visible = true


func hide_clue_detail() -> void:
	detail_overlay.visible = false
	if _clue_image != null:
		_clue_image.visible = false


func _ensure_clue_image() -> void:
	if _clue_image != null:
		return
	var detail_content := get_node_or_null("DetailOverlay/DetailContent") as Control
	if detail_content == null:
		return
	_clue_image = TextureRect.new()
	_clue_image.name = "ClueImage"
	_clue_image.position = Vector2(620, 150)
	_clue_image.size = Vector2(270, 310)
	_clue_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_clue_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_clue_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clue_image.visible = false
	detail_content.add_child(_clue_image)


func _update_clue_image(image_path: String) -> void:
	_ensure_clue_image()
	if _clue_image == null:
		return
	if image_path.is_empty() or not ResourceLoader.exists(image_path):
		_clue_image.texture = null
		_clue_image.visible = false
		return
	_clue_image.texture = load(image_path) as Texture2D
	_clue_image.visible = _clue_image.texture != null


func _find_clue(id: int) -> Dictionary:
	for clue in clues:
		if int(clue.get("id", -1)) == id:
			return clue
	return {}


func _type_to_label(type_text: String) -> String:
	match type_text:
		"observation":
			return "观测"
		"hint":
			return "提示"
		"dialogue":
			return "对话"
		"item":
			return "物品"
		"source_mark":
			return "源印"
		_:
			return type_text
