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
	{
		"id": "darkroom_emblem",
		"title": "晨曦之印",
		"description": "暗室中的源印。触碰它时，启程之镇的碎片回顾被记录下来。",
		"thumbnail": "res://assets/papercraft/fragments/id0001/environment2/0001_prop_dawn_seal.png",
		"fragment_id": "0001",
		"state_key": "darkroom_emblem_collected",
		"order": 50,
	},
	{
		"id": "book",
		"title": "老教师的书",
		"description": "老教师留在长椅上的书。它记录的不是页码，而是那些被等待压得很轻、又很重的岁月。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_14.png",
		"fragment_id": "0002",
		"state_key": "book_collected",
		"order": 110,
	},
	{
		"id": "box",
		"title": "年轻士兵的空弹夹",
		"description": "年轻士兵交出的空弹夹。空掉以后，里面要填进什么，就只能靠记忆回答。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_10.png",
		"fragment_id": "0002",
		"state_key": "box_collected",
		"order": 120,
	},
	{
		"id": "flower",
		"title": "卖花女的矢车菊",
		"description": "卖花女留下的蓝色矢车菊。有缺口，也照样开。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_10.png",
		"fragment_id": "0002",
		"state_key": "flower_collected",
		"order": 130,
	},
	{
		"id": "briefcase",
		"title": "商人的公文包",
		"description": "商人终于放下的公文包。合同、客户和出差的故事都停在 17:47。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_15.png",
		"fragment_id": "0002",
		"state_key": "briefcase_collected",
		"order": 140,
	},
	{
		"id": "candy",
		"title": "小女孩的糖",
		"description": "小女孩交给你的糖。只要糖还没有化，等待就还可以被称作很快。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_12.png",
		"fragment_id": "0002",
		"state_key": "candy_collected",
		"order": 150,
	},
	{
		"id": "ticket_oldteacher",
		"title": "老教师的车票",
		"description": "座位表上属于老教师的车票。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/seat_ticket/t1.png",
		"fragment_id": "0002",
		"state_key": "ticket_oldteacher_collected",
		"order": 210,
	},
	{
		"id": "ticket_youngsoldier",
		"title": "年轻士兵的车票",
		"description": "座位表上属于年轻士兵的车票。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/seat_ticket/t2.png",
		"fragment_id": "0002",
		"state_key": "ticket_youngsoldier_collected",
		"order": 220,
	},
	{
		"id": "ticket_flowergirl",
		"title": "卖花女的车票",
		"description": "座位表上属于卖花女的车票。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/seat_ticket/t4.png",
		"fragment_id": "0002",
		"state_key": "ticket_flowergirl_collected",
		"order": 230,
	},
	{
		"id": "ticket_merchant",
		"title": "商人的车票",
		"description": "座位表上属于商人的车票。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/seat_ticket/t3.png",
		"fragment_id": "0002",
		"state_key": "ticket_merchant_collected",
		"order": 240,
	},
	{
		"id": "ticket_littlegirl",
		"title": "小女孩的车票",
		"description": "座位表上属于小女孩的车票。",
		"thumbnail": "res://assets/papercraft/fragments/id0002/seat_ticket/t5.png",
		"fragment_id": "0002",
		"state_key": "ticket_littlegirl_collected",
		"order": 250,
	},
	{
		"id": "source_mark_ticket",
		"title": "归途之票",
		"description": "承载着归途源印的车票。你等的是谁? 你的归途又在何方? ",
		"thumbnail": "res://assets/papercraft/fragments/id0002/seat_ticket/t6.png",
		"fragment_id": "0002",
		"state_key": "source_mark_ticket_collected",
		"order": 300,
	},
	{
		"id": "jade_0003",
		"title": "藏玉木盒",
		"description": "阁楼木盒中藏着的玉。盒盖开启时，月光在玉面上停留了片刻。",
		"thumbnail": "res://assets/papercraft/fragments/id0003/environment/box_01.png",
		"image": "res://assets/papercraft/fragments/id0003/environment/box_01.png",
		"fragment_id": "0003",
		"state_key": "jade_gallery_collected",
		"order": 310,
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
