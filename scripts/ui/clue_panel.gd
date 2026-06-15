class_name CluePanel
extends BasePanel

const ClueCardScene: PackedScene = preload("res://scenes/ui/components/ClueCard.tscn")

@onready var clue_list: VBoxContainer = $"Stage/MainContainer/ClueListScroll/ClueList"
@onready var detail_overlay: Control = $"DetailOverlay"
@onready var undiscovered_hint: Label = $"Stage/MainContainer/UndiscoveredHint"
@onready var clue_title_label: Label = $"DetailOverlay/DetailContent/ClueTitleLabel"
@onready var clue_description: RichTextLabel = $"DetailOverlay/DetailContent/ClueDescription"
@onready var related_list: HBoxContainer = $"DetailOverlay/DetailContent/RelatedSection/RelatedContainer/RelatedList"
@onready var close_button: BaseButton = $"Stage/MainContainer/TitleBar/CloseButton"
@onready var close_detail_btn: BaseButton = $"DetailOverlay/DetailContent/CloseDetailBtn"

var clues: Array[Dictionary] = []


func _on_ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_button_pressed(close_button, close, "Stage/MainContainer/TitleBar/CloseButton")
	_connect_button_pressed(close_detail_btn, hide_clue_detail, "DetailOverlay/DetailContent/CloseDetailBtn")
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
