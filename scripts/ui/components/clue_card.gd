class_name ClueCard
extends Panel

var clue_id: int = -1
var is_discovered: bool = false

@onready var icon_rect: TextureRect = $CardHBox/ClueIcon
@onready var name_label: Label = $CardHBox/CardInfo/ClueName
@onready var snippet_label: Label = $CardHBox/CardInfo/ClueSnippet
@onready var status_badge: Label = $CardHBox/StatusBadge

signal pressed(clue_id: int)


func set_clue(data: ClueData) -> void:
	clue_id = data.id
	name_label.text = data.name
	snippet_label.text = data.description.left(50) + "..." if data.description.length() > 50 else data.description
	if data.icon:
		icon_rect.texture = data.icon
	set_discovered(data.is_discovered)


func set_discovered(state: bool) -> void:
	is_discovered = state
	if state:
		status_badge.text = "✓"
		status_badge.add_theme_color_override("font_color", Color.GREEN)
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		status_badge.text = "?"
		status_badge.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_LABEL)
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_discovered:
			pressed.emit(clue_id)
