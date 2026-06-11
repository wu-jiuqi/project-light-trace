class_name BackpackPanel
extends BasePanel

@onready var item_grid: GridContainer = $"Stage/MainNotebook/ContentArea/ItemGridSection/ItemGrid"
@onready var detail_panel: Panel = $"Stage/MainNotebook/ContentArea/DetailPanel"
@onready var empty_hint_label: Label = $"Stage/MainNotebook/ContentArea/ItemGridSection/EmptyHint"
@onready var filter_bar: HBoxContainer = $"Stage/MainNotebook/FilterBar"
@onready var item_name_label: Label = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemName"
@onready var item_desc_label: RichTextLabel = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemDesc"
@onready var item_icon_rect: TextureRect = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemIcon"
@onready var item_count_label: Label = $"Stage/MainNotebook/ContentArea/DetailPanel/ItemCount"
@onready var action_button: Button = $"Stage/MainNotebook/ContentArea/DetailPanel/ActionButton"
@onready var close_button: Button = $"Stage/MainNotebook/TitleBar/CloseButton"

var current_filter: String = "all"
var filter_mode: String = "default"


func _on_ready() -> void:
	close_button.pressed.connect(close)
	action_button.pressed.connect(_on_action_pressed)
	for btn: Button in filter_bar.get_children().filter(func(c): return c is Button):
		btn.pressed.connect(_on_filter_changed.bind(btn))


func open(p_filter_mode: String = "default") -> void:
	filter_mode = p_filter_mode
	refresh_items()
	super.open()


func refresh_items() -> void:
	# Clear existing slots
	for child in item_grid.get_children():
		child.queue_free()

	# TODO: 从 InventorySystem 获取物品列表
	var items: Array = []
	if items.is_empty():
		empty_hint_label.visible = true
		item_grid.visible = false
		return

	empty_hint_label.visible = false
	item_grid.visible = true
	var ItemSlotScene: PackedScene = preload("res://scenes/ui/components/ItemSlot.tscn")
	for data: Dictionary in items:
		var slot: ItemSlot = ItemSlotScene.instantiate() as ItemSlot
		slot.set_item(data)
		slot.pressed.connect(show_item_detail.bind(data.get("id", -1)))
		item_grid.add_child(slot)


func show_item_detail(item_id: int) -> void:
	detail_panel.visible = true
	# TODO: 从数据源获取物品详情


func hide_item_detail() -> void:
	detail_panel.visible = false


func set_filter(mode: String) -> void:
	current_filter = mode
	refresh_items()


func _on_filter_changed(btn: Button) -> void:
	var filter_map: Dictionary = {"全部": "all", "可用": "usable", "可给予": "give"}
	set_filter(filter_map.get(btn.text, "all"))


func _on_action_pressed() -> void:
	pass  # TODO: 根据 filter_mode 执行"使用"或"给予"逻辑
