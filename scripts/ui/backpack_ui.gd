extends Control
## Backpack UI autoload. Handles input and hosts the scene-based panel.

const BACKPACK_SCENE: PackedScene = preload("res://scenes/ui/Backpack.tscn")

var _canvas: CanvasLayer
var _panel: BackpackPanel
var _is_open: bool = false


func _ready() -> void:
	add_to_group("backpack_ui")
	_canvas = CanvasLayer.new()
	_canvas.name = "BackpackLayer"
	_canvas.layer = 127
	add_child(_canvas)
	InventoryManager.item_added.connect(_on_item_changed)
	InventoryManager.item_removed.connect(_on_item_changed)
	set_process_input(true)


func _ensure_ui() -> void:
	if is_instance_valid(_panel):
		return
	_panel = BACKPACK_SCENE.instantiate() as BackpackPanel
	_panel.visible = false
	_panel.panel_closed.connect(func(): _is_open = false; InventoryManager.backpack_open = false; InventoryManager.backpack_toggled.emit(false))
	_canvas.add_child(_panel)


func open(filter_mode: String = "default") -> void:
	_ensure_ui()
	if _is_open:
		return
	_is_open = true
	InventoryManager.backpack_open = true
	_panel.open(filter_mode)
	InventoryManager.backpack_toggled.emit(true)
	print("[Backpack] 打开 (%d 物品)" % InventoryManager.get_item_count())


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	InventoryManager.backpack_open = false
	if is_instance_valid(_panel):
		_panel.close()


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("backpack"):
		if ChatDialogue and ChatDialogue.is_open:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if _is_open:
			close()
			get_viewport().set_input_as_handled()


func _on_item_changed(_id: int) -> void:
	if _is_open and is_instance_valid(_panel):
		_panel.refresh_items()
