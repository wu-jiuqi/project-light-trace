class_name BackpackPanel
extends BasePanel

const ItemSlotScene: PackedScene = preload("res://scenes/ui/components/ItemSlot.tscn")

@onready var item_grid: GridContainer = $"Stage/MainNotebook/ContentArea/ItemGridSection/ItemGrid"
@onready var detail_panel: Panel = $"Stage/MainNotebook/ContentArea/DetailPanel"
@onready var empty_hint_label: Label = $"Stage/MainNotebook/ContentArea/ItemGridSection/EmptyHint"
@onready var filter_bar: HBoxContainer = $"Stage/MainNotebook/FilterBar"
@onready var item_name_label: Label = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemName"
@onready var item_desc_label: RichTextLabel = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemDesc"
@onready var item_icon_label: Label = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemIconLabel"
@onready var item_icon_rect: TextureRect = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemIconRect"
@onready var item_count_label: Label = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemCount"
@onready var action_button: Button = $"Stage/MainNotebook/ContentArea/DetailPanel/ActionButton"
@onready var close_button: Button = $"Stage/MainNotebook/TitleBar/CloseButton"

var current_filter: String = "all"
var filter_mode: String = "default"
var selected_item_id: int = -1


func _on_ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_button_pressed(close_button, close, "Stage/MainNotebook/TitleBar/CloseButton")
	_connect_button_pressed(action_button, _on_action_pressed, "Stage/MainNotebook/ContentArea/DetailPanel/ActionButton")
	for child in filter_bar.get_children():
		if child is Button:
			child.pressed.connect(_on_filter_changed.bind(child))
			child.pressed.connect(UISoundManager.play_click)
	hide_item_detail()


func open(p_filter_mode: String = "default") -> void:
	filter_mode = p_filter_mode
	refresh_items()
	super.open()


func refresh_items() -> void:
	for child in item_grid.get_children():
		child.queue_free()

	var filtered := _get_filtered_items()
	if filtered.is_empty():
		empty_hint_label.visible = true
		item_grid.visible = false
		hide_item_detail()
	else:
		empty_hint_label.visible = false
		item_grid.visible = true
		for data in filtered:
			var slot := ItemSlotScene.instantiate() as ItemSlot
			slot.set_item(data)
			slot.pressed.connect(show_item_detail.bind(int(data.get("id", -1))))
			slot.pressed.connect(UISoundManager.play_click)
			item_grid.add_child(slot)

	for i in range(filtered.size(), 8):
		var slot := ItemSlotScene.instantiate() as ItemSlot
		slot.clear()
		slot.disabled = true
		item_grid.add_child(slot)


func show_item_detail(item_id: int) -> void:
	selected_item_id = item_id
	var meta := InventoryManager.get_item_meta(item_id)
	if meta.is_empty():
		hide_item_detail()
		return
	detail_panel.visible = true
	item_name_label.text = str(meta.get("name", "Unknown Item"))
	item_desc_label.text = str(meta.get("desc", "No description."))
	var icon_texture := _load_item_texture(meta)
	if icon_texture:
		item_icon_rect.texture = icon_texture
		item_icon_rect.visible = true
		item_icon_label.visible = false
	else:
		item_icon_rect.texture = null
		item_icon_rect.visible = false
		item_icon_label.visible = true
		item_icon_label.text = str(meta.get("icon", "?"))
	item_count_label.text = "Count: 1"
	action_button.disabled = filter_mode != "give"
	action_button.text = "Give" if filter_mode == "give" else "View"


func hide_item_detail() -> void:
	selected_item_id = -1
	if item_icon_rect:
		item_icon_rect.texture = null
	detail_panel.visible = false


func set_filter(mode: String) -> void:
	current_filter = mode
	refresh_items()


func _get_filtered_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in InventoryManager.get_all_items():
		var meta := InventoryManager.get_item_meta(item_id)
		if meta.is_empty():
			continue
		if current_filter == "give" and not bool(meta.get("givable", true)):
			continue
		if current_filter == "usable" and not bool(meta.get("usable", true)):
			continue
		var icon_texture := _load_item_texture(meta)
		result.append({
			"id": item_id,
			"name": meta.get("name", "Unknown Item"),
			"icon": icon_texture if icon_texture else meta.get("icon", "?"),
			"icon_path": meta.get("icon_path", ""),
			"count": 1,
			"color": meta.get("color", Color(0.7, 0.56, 0.32, 1.0)),
		})
	return result


func _load_item_texture(meta: Dictionary) -> Texture2D:
	var icon_path := str(meta.get("icon_path", ""))
	if icon_path == "":
		return null
	if ResourceLoader.exists(icon_path):
		return load(icon_path) as Texture2D
	if not FileAccess.file_exists(icon_path):
		return null
	var image := Image.new()
	if image.load(icon_path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _on_filter_changed(btn: Button) -> void:
	var filter_map := {
		"All": "all",
		"Usable": "usable",
		"Give": "give",
		"全部": "all",
		"可用": "usable",
		"可给予": "give",
	}
	set_filter(filter_map.get(btn.text, "all"))


func _on_action_pressed() -> void:
	if selected_item_id < 0:
		return
	if filter_mode == "give":
		print("[BackpackPanel] give requested: %d" % selected_item_id)
