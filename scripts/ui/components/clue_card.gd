class_name ClueCard
extends TextureRect

signal pressed(clue_id: int)

var clue_id: int = -1
var is_discovered: bool = false

@onready var icon_label: Label = $CardHBox/ClueIcon
@onready var name_label: Label = $CardHBox/CardInfo/ClueName
@onready var snippet_label: Label = $CardHBox/CardInfo/ClueSnippet
@onready var status_badge: Label = $CardHBox/StatusBadge


func set_clue(data) -> void:
	_ensure_label_refs()
	if data is ClueData:
		clue_id = data.id
		_set_label_text(name_label, data.name)
		_set_label_text(snippet_label, _trim_snippet(data.description))
		_set_label_text(icon_label, "线")
		set_discovered(data.is_discovered)
		return

	if data is Dictionary:
		clue_id = int(data.get("id", clue_id))
		_set_label_text(name_label, str(data.get("name", "未知线索")))
		_set_label_text(snippet_label, _trim_snippet(str(data.get("description", ""))))
		_set_label_text(icon_label, _type_icon(str(data.get("type", "线索"))))
		set_discovered(bool(data.get("is_discovered", true)))


func set_discovered(state: bool) -> void:
	_ensure_label_refs()
	is_discovered = state
	_set_label_text(status_badge, "已获" if state else "???")
	if status_badge:
		status_badge.add_theme_color_override("font_color", Color(0.18, 0.12, 0.075, 1.0))
	modulate.a = 1.0 if state else 0.45
	mouse_filter = Control.MOUSE_FILTER_STOP if state else Control.MOUSE_FILTER_IGNORE


func _ensure_label_refs() -> void:
	if icon_label == null:
		icon_label = get_node_or_null("CardHBox/ClueIcon") as Label
	if name_label == null:
		name_label = get_node_or_null("CardHBox/CardInfo/ClueName") as Label
	if snippet_label == null:
		snippet_label = get_node_or_null("CardHBox/CardInfo/ClueSnippet") as Label
	if status_badge == null:
		status_badge = get_node_or_null("CardHBox/StatusBadge") as Label


func _set_label_text(label: Label, text: String) -> void:
	if label:
		label.text = text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_discovered:
			pressed.emit(clue_id)


func _trim_snippet(text: String) -> String:
	return text.left(50) + "..." if text.length() > 50 else text


func _type_icon(type_text: String) -> String:
	match type_text:
		"observation":
			return "观"
		"hint":
			return "提"
		"dialogue":
			return "谈"
		"item":
			return "物"
		"source_mark":
			return "印"
		_:
			return "线"
