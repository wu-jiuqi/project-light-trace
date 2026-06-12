class_name ItemSlot
extends Button

var item_id: int = -1
var count: int = 0

@onready var icon_rect: TextureRect = $IconRect
@onready var icon_label: Label = $IconLabel
@onready var name_label: Label = $NameLabel
@onready var count_badge: Label = $CountBadge

signal give_requested(item_id: int)


func set_item(data: Dictionary) -> void:
	item_id = int(data.get("id", -1))
	count = int(data.get("count", 1))
	disabled = false
	var icon = data.get("icon", "?")
	if icon is Texture2D:
		icon_rect.texture = icon
		icon_rect.visible = true
		icon_label.visible = false
	else:
		icon_rect.texture = null
		icon_rect.visible = false
		icon_label.visible = true
		icon_label.text = str(icon)
	name_label.text = str(data.get("name", ""))
	count_badge.text = "x%d" % count
	count_badge.visible = count > 1
	modulate = Color.WHITE


func clear() -> void:
	item_id = -1
	count = 0
	icon_rect.texture = null
	icon_rect.visible = false
	icon_label.visible = true
	icon_label.text = ""
	name_label.text = ""
	count_badge.text = ""
	count_badge.visible = false
	modulate = Color(1.0, 1.0, 1.0, 0.38)


func highlight(on: bool) -> void:
	modulate = Color(1.16, 1.08, 0.86, 1.0) if on else Color.WHITE
