extends BasePanel

const ITEMS_PER_PAGE := 8

const GALLERY_ITEMS: Array[Dictionary] = [
	{
		"id": "lin_note",
		"title": "林指导的便笺",
		"description": "林指导留给溯光者的私人提示。它不像培训脚本的一部分，更像某个人越过规则留下的提醒。",
		"thumbnail": "res://assets/papercraft/fragments/id0001/environment2/LinNote.png",
		"fragment_id": "0001",
		"state_key": "lin_note_collected",
		"order": 10,
	},
	{
		"id": "stone",
		"title": "石碑",
		"description": "启程之镇中异常醒目的石碑。上一个你?",
		"thumbnail": "res://assets/papercraft/fragments/id0001/environment2/stone_tablet.png",
		"fragment_id": "0001",
		"state_key": "stone_collected",
		"order": 20,
	},
	{
		"id": "tv",
		"title": "TV",
		"description": "天枢公司的电视广告。明亮、标准、可信，不知为何里面会有王主管和女儿的合照。",
		"thumbnail": "res://assets/papercraft/fragments/id0001/environment2/tianshu_monitor.png",
		"fragment_id": "0001",
		"state_key": "tv_collected",
		"order": 30,
	},
	{
		"id": "darkroom_note",
		"title": "钟楼暗室便笺",
		"description": "暗室中的手写便笺。她?是谁?。",
		"thumbnail": "res://assets/papercraft/fragments/id0001/environment2/0001_prop_handwritten_note.png",
		"fragment_id": "0001",
		"state_key": "darkroom_note_collected",
		"order": 40,
		"image": "res://assets/papercraft/fragments/id0001/environment2/note.png",
	},
]

@onready var _gallery_card: Control = $Stage/GalleryPanel/Gallery/GalleryCard
@onready var _close_button: TextureButton = $Stage/GalleryPanel/TitleBar/CloseButton
@onready var _prev_button: TextureButton = $Stage/GalleryPanel/ButtonBar/UpButton
@onready var _next_button: TextureButton = $Stage/GalleryPanel/ButtonBar/NextButton
@onready var _page_label: Label = $Stage/GalleryPanel/ButtonBar/Spacer/PageLabel

var _current_page: int = 0
var _items: Array[Dictionary] = []


func _on_ready() -> void:
	_items = GALLERY_ITEMS.duplicate(true)
	_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	_close_button.pressed.connect(_close)
	_prev_button.pressed.connect(_go_prev_page)
	_next_button.pressed.connect(_go_next_page)
	_close_button.pressed.connect(UISoundManager.play_click)
	_prev_button.pressed.connect(UISoundManager.play_click)
	_next_button.pressed.connect(UISoundManager.play_click)
	_refresh_page()


func _layout_stage() -> void:
	if not stage:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	stage.position = Vector2.ZERO
	stage.size = DESIGN_SIZE
	stage.scale = Vector2(
		viewport_size.x / DESIGN_SIZE.x,
		viewport_size.y / DESIGN_SIZE.y
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _refresh_page() -> void:
	var max_page := _get_max_page()
	_current_page = clampi(_current_page, 0, max_page - 1)

	var start := _current_page * ITEMS_PER_PAGE
	var end := mini(start + ITEMS_PER_PAGE, _items.size())
	var page_items: Array[Dictionary] = []
	for i in range(start, end):
		page_items.append(_items[i])

	_gallery_card.bind_page(page_items, _get_unlocks(page_items))
	_page_label.text = "%d / %d" % [_current_page + 1, max_page]
	_update_page_buttons(max_page)


func _get_unlocks(items: Array[Dictionary]) -> Dictionary:
	var unlocks := {}
	for item in items:
		var fragment_id := str(item.get("fragment_id", ""))
		var state_key := str(item.get("state_key", ""))
		var value = FragmentManager.get_fragment_state(fragment_id, state_key)
		unlocks[str(item.get("id", ""))] = _is_collected_value(value)
	return unlocks


func _is_collected_value(value) -> bool:
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value) == 1
	return false


func _get_max_page() -> int:
	return maxi(1, int(ceil(float(_items.size()) / float(ITEMS_PER_PAGE))))


func _update_page_buttons(max_page: int) -> void:
	_prev_button.disabled = _current_page <= 0
	_next_button.disabled = _current_page >= max_page - 1
	_prev_button.modulate.a = 0.45 if _prev_button.disabled else 1.0
	_next_button.modulate.a = 0.45 if _next_button.disabled else 1.0


func _go_prev_page() -> void:
	if _current_page <= 0:
		return
	_current_page -= 1
	_refresh_page()


func _go_next_page() -> void:
	if _current_page >= _get_max_page() - 1:
		return
	_current_page += 1
	_refresh_page()


func _close() -> void:
	queue_free()
