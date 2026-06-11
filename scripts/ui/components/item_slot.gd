class_name ItemSlot
extends Button

var item_id: int = -1
var count: int = 0

@onready var icon_rect: TextureRect = $IconRect
@onready var count_badge: Label = $CountBadge

signal give_requested(item_id: int)


func set_item(data: Dictionary) -> void:
	item_id = data.get("id", -1)
	count = data.get("count", 1)
	if data.has("icon"):
		icon_rect.texture = data["icon"]
	count_badge.text = "×%d" % count
	count_badge.visible = count > 1


func clear() -> void:
	item_id = -1
	count = 0
	icon_rect.texture = null
	count_badge.text = ""
	count_badge.visible = false


func highlight(on: bool) -> void:
	modulate = Color(1.3, 1.2, 0.9, 1.0) if on else Color(1.0, 1.0, 1.0, 1.0)
