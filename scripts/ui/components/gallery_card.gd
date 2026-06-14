class_name GalleryCard
extends Control

signal slot_selected(item: Dictionary, unlocked: bool)

@onready var _grid: GridContainer = $VBoxContainer/GalleryGrid
@onready var _detail_label: Label = $VBoxContainer/DetailPanel/Detail
@onready var _preview_overlay: Control = $PreviewOverlay
@onready var _large_preview: TextureRect = $PreviewOverlay/LargePreview

var _slots: Array[Control] = []


func _ready() -> void:
	for child in _grid.get_children():
		if child.has_signal("selected") and child.has_method("bind_item"):
			var slot := child as Control
			_slots.append(slot)
			slot.selected.connect(_on_slot_selected)
	_clear_detail()


func bind_page(items: Array[Dictionary], unlocks: Dictionary) -> void:
	for i in range(_slots.size()):
		if i < items.size():
			var item := items[i]
			var item_id := str(item.get("id", ""))
			_slots[i].bind_item(item, bool(unlocks.get(item_id, false)))
		else:
			_slots[i].bind_empty()
	_clear_detail()


func _on_slot_selected(item: Dictionary, unlocked: bool) -> void:
	if unlocked:
		var title := str(item.get("title", "未知剧情物品"))
		var description := str(item.get("description", "暂无简介。"))
		_detail_label.text = "%s\n%s" % [title, description]
		_show_preview(item)
	else:
		var locked_title := str(item.get("title", "未收集剧情物品"))
		_detail_label.text = "%s\n尚未收集。继续探索对应碎片后，这里会显示完整简介。" % locked_title
		_clear_preview("未收集")
	slot_selected.emit(item, unlocked)


func _clear_detail() -> void:
	_detail_label.text = "点击已收集的剧情物品，查看回顾简介。"
	_clear_preview("未选择")


func _show_preview(item: Dictionary) -> void:
	var image_path := str(item.get("image", item.get("thumbnail", "")))
	var texture := load(image_path) as Texture2D if not image_path.is_empty() else null
	_large_preview.texture = texture
	_preview_overlay.visible = texture != null


func _clear_preview(_placeholder_text: String) -> void:
	_large_preview.texture = null
	_preview_overlay.visible = false
