extends Area2D
## 可拾取物品 — 绕过 Godot 4.6.2 Area2D+Label tscn Bug
## Label 在 _ready() 中动态创建

@export var item_id: int = 0
@export var item_name: String = "物品"
@export var item_color: Color = Color(1, 0.5, 0.5, 1)
@export var item_pos_x: float = 0.0
@export var item_pos_y: float = 0.0

var _player_nearby: bool = false
var _label: Label


func _ready() -> void:
	if item_pos_x != 0.0 or item_pos_y != 0.0:
		position = Vector2(item_pos_x, item_pos_y)
	collision_layer = 0
	collision_mask = 1
	set_process(true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_visual()


func _create_visual() -> void:
	# 碰撞体（必需！否则 body_entered 不会触发）
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	shape.position = Vector2.ZERO
	add_child(shape)
	
	# 圆形占位块
	var sprite = ColorRect.new()
	sprite.name = "ItemSprite"
	sprite.offset_left = -12; sprite.offset_top = -12
	sprite.offset_right = 12; sprite.offset_bottom = 12
	sprite.color = item_color
	add_child(sprite)
	
	# 标签
	_label = Label.new()
	_label.name = "ItemLabel"
	_label.offset_left = -40; _label.offset_top = -44
	_label.offset_right = 40; _label.offset_bottom = -20
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_label.add_theme_font_size_override("font_size", 10)
	_label.text = item_name
	_label.visible = true
	add_child(_label)


func _process(_delta: float) -> void:
	if not _player_nearby: return
	if Input.is_action_just_pressed("interact"):
		_pickup()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if _label:
			_label.text = "[E] %s" % item_name


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if _label:
			_label.text = item_name


func _pickup() -> void:
	if not InventoryManager.has_method("add_item"): return
	if InventoryManager.add_item(item_id):
		print("[PickupItem] 拾取: %s" % item_name)
		queue_free()
